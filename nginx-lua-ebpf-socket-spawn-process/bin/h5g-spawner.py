#!/usr/bin/env python

from bcc import BPF
import subprocess
import time
import threading
import re
import os
import sys
import signal
import logging
from stat import *

bcc_prog = """
#define KBUILD_MODNAME "h5g spawner"
#include <uapi/linux/ptrace.h>
#include <net/sock.h>
#include <bcc/proto.h>

#define SUN_PATH_LEN 108

struct h5g {
    char sun_path[SUN_PATH_LEN];
};

BPF_PERF_OUTPUT(events);

struct sockaddr_un {
    sa_family_t sun_family;
    char sun_path[SUN_PATH_LEN];
};

void schedule_spawn(struct pt_regs *ctx, int fd, struct sockaddr *uservaddr,
                    int addrlen)
{
    struct sockaddr_un *sock = NULL;
    struct h5g h5g = {};

    if (uservaddr->sa_family != AF_UNIX)
        return;

    sock = (struct sockaddr_un *)uservaddr;

    __builtin_memcpy(&h5g.sun_path, sock->sun_path, sizeof(h5g.sun_path));
    events.perf_submit(ctx, &h5g, sizeof(h5g));
}
"""

b = BPF(text=bcc_prog)
b.attach_kprobe(event="__sys_connect", fn_name="schedule_spawn")


class Spawner:
    def __init__(self):
        logging.basicConfig(format="%(levelname)s: %(message)s", stream=sys.stdout)

        self.bin_dir = "/opt/h5g/bin"
        self.socket_dir = "/tmp/h5g"
        self.idle_timeout = 10
        self.last_seen = {}
        self.thread_stop_event = threading.Event()
        self.log = logging.getLogger(__name__)
        self.log.setLevel(logging.DEBUG)

    def socket2username(self, path):
        m = re.search(r"(u[0-9]{1,8})\.socket", path)
        if not m:
            return None
        return m[1]

    def terminate(self, pid_file, msg):
        with open(pid_file, "r") as f:
            pid = int(f.read())
            if pid > 1:
                self.log.info(msg)
                os.kill(pid, signal.SIGINT)

    def spawn(self, _cpu, data, _size):
        output = b["events"].event(data)
        sun_path = output.sun_path.decode("utf-8")

        if self.socket_dir not in sun_path:
            return

        if not self.socket2username(sun_path):
            return

        self.last_seen[sun_path] = int(time.time())

        subprocess.Popen(
            [os.path.join(self.bin_dir, "spawn.sh"), sun_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

    def reap_timer(self):
        self.log.debug("Checking idle php-fpm processes...")
        for f in os.listdir(self.socket_dir):
            sun_path = f"{self.socket_dir}/{f}"
            s = os.lstat(sun_path)
            if not S_ISSOCK(s.st_mode):
                continue

            username = self.socket2username(sun_path)
            if not username:
                continue

            pid_file = f"{self.socket_dir}/{username}.pid"

            if (
                sun_path in self.last_seen
                and int(time.time() - self.last_seen[sun_path]) > self.idle_timeout
            ):
                self.terminate(
                    pid_file,
                    f"Terminating php-fpm process (no requests during idle timeout) for {username}",
                )

            if (
                sun_path not in self.last_seen
                and int(time.time() - s.st_atime) > self.idle_timeout
            ):
                self.terminate(
                    pid_file,
                    f"Terminating php-fpm process (socket created, but no requests during idle timeout) for {username}",
                )

    def reap(self, func, stop_event):
        def expired():
            while not stop_event.is_set():
                for _ in range(self.idle_timeout):
                    if stop_event.is_set():
                        break
                    time.sleep(1)
                func()

        thread = threading.Thread(target=expired)
        thread.start()

if __name__ == "__main__":
    h5g = Spawner()
    b["events"].open_perf_buffer(h5g.spawn, page_cnt=2048)
    h5g.reap(h5g.reap_timer, h5g.thread_stop_event)
    h5g.log.info("Running, and waiting for `connect()` events...")

    while True:
        try:
            b.perf_buffer_poll()
        except KeyboardInterrupt:
            h5g.thread_stop_event.set()
            exit()
