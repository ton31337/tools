# Trivial example on how to send a plain BGP (malformed too) packets.
# Tested with FRR:
#
#router bgp 65001
# neighbor 127.0.0.1 remote-as external
# neighbor 127.0.0.1 passive
# neighbor 127.0.0.1 ebgp-multihop
# neighbor 127.0.0.1 disable-connected-check
# neighbor 127.0.0.1 update-source 127.0.0.2
# neighbor 127.0.0.1 timers 3 90
# neighbor 127.0.0.1 timers connect 1

import socket
import time

OPEN = (b"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff"
b"\xff\xff\x00\x62\x01\x04\xfd\xea\x00\x5a\x0a\x00\x00\x01\x45\x02"
b"\x06\x01\x04\x00\x01\x00\x01\x02\x02\x02\x00\x02\x02\x46\x00\x02"
b"\x06\x41\x04\x00\x00\xfd\xea\x02\x02\x06\x00\x02\x06\x45\x04\x00"
b"\x01\x01\x03\x02\x0e\x49\x0c\x0a\x64\x6f\x6e\x61\x74\x61\x73\x2d"
b"\x70\x63\x00\x02\x04\x40\x02\x00\x78\x02\x09\x47\x07\x00\x01\x01"
b"\x80\x00\x00\x00")

KEEPALIVE = (b"\xff\xff\xff\xff\xff\xff\xff\xff\xff\xff"
b"\xff\xff\xff\xff\xff\xff\x00\x13\x04")

#UPDATE = bytearray.fromhex("ffffffffffffffffffffffffffffffff002b0200000003c0ff00010100eb00ac100b0b001ad908ac100b0b")
UPDATE = bytearray.fromhex("ffffffffffffffffffffffffffffffff002c020000000a810f0700020202000000021602000040002400020f0f0f0f0f")
#UPDATE = bytearray.fromhex("ffffffffffffffffffffffffffffffff0064020000002e04280f003600031100010a0000290002001a0000200a000076400101005002000602010002fde9c0f50f030c000000ffffff0000080002fe110000400dc0160900060000ffffffffffffffffffffffffff004d0200000d0a00000003e800000000ff0010060400000a02068000ff0101010208490604000000f6ff00001000000003e87600000000ff00100604000000f6ff00006204")

s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
s.connect(('127.0.0.2', 179))
s.send(OPEN) 
data = s.recv(1024)
s.send(KEEPALIVE)
data = s.recv(1024)
s.send(UPDATE)
data = s.recv(1024)
time.sleep(100)
s.close()

