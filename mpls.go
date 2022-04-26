package main

import (
	"fmt"
	"net"
	"encoding/hex"
	"github.com/google/gopacket"
  "github.com/google/gopacket/layers"
)

func getMplsPacket() []byte {

   ipaddr := net.ParseIP("1.1.1.1")

   payload := gopacket.Payload("payload") 

   udp := &layers.UDP{SrcPort: layers.UDPPort(2000), DstPort: layers.UDPPort(3000)}
  
   ip := &layers.IPv4{Version: 4, DstIP: ipaddr, SrcIP: ipaddr, Protocol: layers.IPProtocolUDP}

   hw, _  := net.ParseMAC("c8:b3:02:c0:b9:1b")

   eth := &layers.Ethernet{SrcMAC: hw, DstMAC: hw, EthernetType: 0x8847} 

   mpls := &layers.MPLS{
           Label:        17,
           TrafficClass: 0,
           StackBottom:  true, 
           TTL:          64,
       }

   if err := udp.SetNetworkLayerForChecksum(ip); err != nil {
       return nil
   }

   buffer := gopacket.NewSerializeBuffer()
   if err := gopacket.SerializeLayers(buffer,
       gopacket.SerializeOptions{ComputeChecksums: true, FixLengths: true},
       eth, mpls, ip, udp, payload); err != nil {
       return nil
   }

   str := hex.EncodeToString(buffer.Bytes())
   fmt.Println(str)
   return buffer.Bytes()
}


func main() {
	fmt.Println(getMplsPacket())
}
