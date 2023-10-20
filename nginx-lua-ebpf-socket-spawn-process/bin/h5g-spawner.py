#!/usr/bin/env python

from bcc import BPF
import subprocess
import time
import threading
from datetime import datetime

bcc_prog = """
#define KBUILD_MODNAME "h5g process spawner"
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

last_seen = {}
stop_event = threading.Event()


def spawn_process(cpu, data, size):
    output = b["events"].event(data)
    sun_path = str(output.sun_path)
    last_seen[sun_path] = datetime.now().timestamp()

    if ".socket" not in sun_path:
        return

    print(f"Spawning f{sun_path}")
    subprocess.Popen(
        ["/opt/h5g/bin/spawn.sh", output.sun_path],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


def reap_process_timer():
    print("Checking idle php-fpm processes...")


def reap_process(interval, func, stop_event):
    def expired():
        while not stop_event.is_set():
            func()
            for _ in range(interval):
                if stop_event.is_set():
                    break
                time.sleep(1)

    thread = threading.Thread(target=expired)
    thread.start()


b["events"].open_perf_buffer(spawn_process)

reap_process(5, reap_process_timer, stop_event)

while True:
    try:
        b.perf_buffer_poll()
    except KeyboardInterrupt:
        print("Stopping...")
        stop_event.set()
        exit()
