#!/usr/bin/env python

from bcc import BPF
from time import sleep

bcc_prog = """
#define KBUILD_MODNAME "cwnd"
#include <uapi/linux/ptrace.h>
#include <net/sock.h>
#include <bcc/proto.h>
#include <net/tcp.h>

BPF_HASH(stats);

int kprobe__tcp_ack(struct pt_regs *ctx, struct sock *sk)
{
    struct tcp_sock *tp = tcp_sk(sk);
    u64 *val, zero = 0;
    u32 cwnd = 0;

    bpf_probe_read(&cwnd, sizeof(cwnd), (u32 *)(&tp->snd_cwnd));
    val = stats.lookup_or_init((u64 *)&cwnd, &zero);
    (*val)++;

        return 0;
}
"""

b = BPF(text=bcc_prog)

print("Tracing sending cwnd size... Hit Ctrl-C to end.")

try:
    sleep(99999999)
except KeyboardInterrupt:
    pass

for k, v in b["stats"].items():
    print("%d %d" % (k.value, v.value))

