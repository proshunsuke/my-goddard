# Filename:test19.tcl

set ns [new Simulator -multicast on] ;# enable multicast routing

#============================ TRACE file2 TO RECORD THE ALL EVENTS =====================

set trace [open test19.tr w]
$ns trace-all $trace
#$ns use-newtrace

#============================= NAM WINDOW CREATION ====================================

set namtrace [open test19.nam w]
$ns namtrace-all $namtrace



set group [Node allocaddr] ;# allocate a multicast address

set node0 [$ns node] ;# create multicast capable nodes
set node1 [$ns node]
set node2 [$ns node]

$ns duplex-link $node0 $node1 1.5Mb 10ms DropTail
$ns duplex-link $node0 $node2 1.5Mb 10ms DropTail

set mproto DM ;# configure multicast protocol
set mrthandle [$ns mrtproto $mproto] ;# all nodes will contain multicast protocol agents

set udp [new Agent/UDP] ;# create a source agent at node 0
$ns attach-agent $node0 $udp
set src [new Application/Traffic/CBR]
$src attach-agent $udp
$udp set dst_addr_ $group
$udp set dst_port_ 0

set rcvr [new Agent/LossMonitor] ;# create a receiver agent at node 1
$ns attach-agent $node1 $rcvr
$ns at 0.3 "$node1 join-group $rcvr $group" ;# join the group at simulation time 0.3 (sec)

set rcvr2 [new Agent/LossMonitor] ;# create a receiver agent at node 1
$ns attach-agent $node2 $rcvr2
$ns at 0.3 "$node2 join-group $rcvr2 $group" ;# join the group at simulation time 0.3 (sec)

$ns at 3.3 "$node2 leave-group $rcvr2 $group" ;# join the group at simulation time 0.3 (sec)


$ns at 2.0 "$src start"
$ns at 5.0 "$src stop"


proc finish {} {
                 global ns namtrace trace
                 $ns flush-trace
                 close $namtrace ; close $trace
                 exec nam test19.nam &
                 exit 0
              }

$ns at 10.0 "finish"
$ns run