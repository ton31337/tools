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
#include <uapi/linux/ptrace.h>
#include <net/sock.h>
#include <bcc/proto.h>

#define SUN_PATH_LEN 108
#define MIN_USER_ID 30

BPF_RINGBUF_OUTPUT(events, 1 << 12);

struct event {
    char sun_path[SUN_PATH_LEN];
    u32 uid;
};

struct sockaddr_un {
    sa_family_t sun_family;
    char sun_path[SUN_PATH_LEN];
};

void schedule_spawn(struct pt_regs *ctx, int fd, struct sockaddr *uservaddr,
                    int addrlen)
{
    struct sockaddr_un *sock = NULL;
    struct event e = {};

    if (uservaddr->sa_family != AF_UNIX)
        return;

    e.uid = bpf_get_current_uid_gid();
    if (e.uid < MIN_USER_ID)
        return;

    sock = (struct sockaddr_un *)uservaddr;

    bpf_probe_read_user_str(&e.sun_path, sizeof(e.sun_path),
                            sock->sun_path);

    events.ringbuf_output(&e, sizeof(e), 0);
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
        self.seen_counter = {}
        self.thread_stop_event = threading.Event()
        self.log = logging.getLogger(__name__)
        self.log.setLevel(logging.DEBUG)

    def socket2username(self, path):
        """
        A helper method to validate if we got a valid socket path.
        """
        m = re.search(r"(u[0-9]{1,8})\.socket", path)
        if not m:
            self.log.error(f"can't parse socket path to username: {path}")
            return None
        return m[1]

    def terminate(self, pid_file, msg):
        """
        Send a termination signal for the pid that belongs to the
        php-fpm process we would like to terminate due to idle timeout.
        """
        with open(pid_file, "r") as f:
            pid = int(f.read())
            if pid > 1:
                self.log.info(msg)
                os.kill(pid, signal.SIGINT)

    def spawn(self, _cpu, data, _size):
        """
        When we receive `connect()`, we run `spawn.sh` command with an
        argument, which is in our case a socket's path.
        E.g.: `spawn.sh /tmp/u2.socket`.
        """
        output = b["events"].event(data)
        sun_path = output.sun_path.decode("utf-8")

        if self.socket_dir not in sun_path:
            return

        if not self.socket2username(sun_path):
            return

        if sun_path in self.seen_counter:
            self.seen_counter[sun_path] = self.seen_counter[sun_path] + 1
        else:
            self.seen_counter[sun_path] = 0

        now = int(time.time())

        # If we receive a burst of connect()s, we should avoid saturating
        # ring buffer for user-space/kernel-space communication.
        # With this limitation, we send only _legit_ requests down to the user-space,
        # and spawn.sh is doing the decent job.
        if (
            sun_path in self.last_seen
            and now - self.last_seen[sun_path] < self.idle_timeout / 2
        ):
            return

        self.last_seen[sun_path] = now

        subprocess.Popen(
            [os.path.join(self.bin_dir, "spawn.sh"), sun_path],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )

    def reap_timer(self):
        """
        Iterate over the `socket_dir` and check the existing/running
        php-fpm processes.
        If the socket didn't have any request during the idle timeout,
        then terminate php-fpm for that specific user.
        If php-fpm was running before we started this program, we should
        check how it long it was active by evaluating socket's file ATIME.
        """
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
        """
        The process reaping thread, that calls another function periodically.
        In our case `reap_timer()`.
        """

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
    b["events"].open_ring_buffer(h5g.spawn)
    h5g.reap(h5g.reap_timer, h5g.thread_stop_event)
    h5g.log.info("Running, and waiting for `connect()` events...")
    h5g.log.info(f"socket path: {h5g.socket_dir}")
    h5g.log.info(f"bin path: {h5g.bin_dir}")
    h5g.log.info(f"idle timeout: {h5g.idle_timeout}")

    while True:
        try:
            b.ring_buffer_poll()
        except KeyboardInterrupt:
            h5g.thread_stop_event.set()
            h5g.log.debug(h5g.last_seen)
            h5g.log.debug(h5g.seen_counter)
            exit()
