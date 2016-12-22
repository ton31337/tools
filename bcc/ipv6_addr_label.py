#!/usr/bin/env python

from bcc import BPF

bcc_prog = """
#define KBUILD_MODNAME "enqueue_to_backlog"
#include <uapi/linux/ptrace.h>
#include <net/sock.h>
#include <bcc/proto.h>

int kretprobe__ipv6_addr_label(struct pt_regs *ctx,
                               struct net *net,
                               const struct in6_addr *addr,
                               int type,
                               int ifindex)
{
        int ret = PT_REGS_RC(ctx);
        bpf_trace_printk("ifindex: %d, label: %d\\n", ifindex, ret);

        return 0;
}
"""

b = BPF(text=bcc_prog)
b.trace_print()

"""
            sshd-5559  [000] d... 167843.542477: : ifindex: -1, label: 0
            sshd-5663  [000] dN.. 167863.327959: : ifindex: -1, label: 0
           ping6-5707  [000] d... 167873.402854: : ifindex: -1, label: 6
           ping6-5707  [000] d... 167873.404414: : ifindex: -1, label: 6
           ping6-5707  [000] d... 167874.406325: : ifindex: -1, label: 6
           ping6-5707  [000] d... 167875.408850: : ifindex: -1, label: 6
"""
