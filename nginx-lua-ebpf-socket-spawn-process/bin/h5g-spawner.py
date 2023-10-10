#!/usr/bin/env python

from bcc import BPF
import ctypes as ct
import subprocess

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


def spawn_process(cpu, data, size):
    output = b["events"].event(data)
    process = subprocess.Popen(
        ["/opt/h5g/bin/spawn.sh", output.sun_path],
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )


b["events"].open_perf_buffer(spawn_process)

while True:
    try:
        b.perf_buffer_poll()
    except KeyboardInterrupt:
        exit()
