######################################
# File:   test-goddard.tcl
# Author: Jae Chung (goos@cs.wpi.edu)
# Date:   May 2005
#
#  Goddard/TCP        Gplayer/TCP
#      o                 o
#       \               /
#        o-------------o
#       /    1.6Mbps    \
#      o                 o
#  Goddard/UDP        Gplayer/UDP
#

#NS simulator object
set ns [new Simulator]

#Set random seed
global defaultRNG
$defaultRNG seed 15

#setting number of flows ココ買えればエッジが増えるはず
set num_node 2

#Making the two network nodes
set n(1) [$ns node]
set n(2) [$ns node]

#Making edge nodes for num_node
for {set i 0} {$i < $num_node} {incr i} {
    set node_s($i) [$ns node]
    set node_r($i) [$ns node]
}

set f [open out.tr w]
$ns trace-all $f
set nf [open out.nam w]
$ns namtrace-all $nf

#Creating edge links for num_node
for {set i 0} {$i < $num_node} {incr i} {
    $ns duplex-link $node_s($i) $n(1) 10Mb 5ms DropTail
    $ns duplex-link $n(2) $node_r($i) 10Mb 5ms DropTail
}

#Creating the network link
$ns duplex-link $n(1) $n(2) 0.5Mb 10ms DropTail
set fq [[$ns link $n(1) $n(2)] queue]
$fq set limit_ 20
$fq set queue_in_bytes_ true
$fq set mean_pktsize_ 1000

#Open the trace files
set tfile_ [open out.tr w]
set clink [$ns link $n(1) $n(2)]
$clink trace $ns $tfile_

#Setup Goddard Streaming
set gs(0) [new GoddardStreaming $ns $node_s(0) $node_r(0) TCP 1000 0]
set goddard(0) [$gs(0) getobject goddard]
set gplayer(0) [$gs(0) getobject gplayer]
$gplayer(0) set upscale_interval_ 30.0
set sfile1_ [open stream-tcp.tr w]
$gplayer(0) attach $sfile1_

set gs(1) [new GoddardStreaming $ns $node_s(1) $node_r(1) UDP 1000 1]
set goddard(1) [$gs(1) getobject goddard]
set gplayer(1) [$gs(1) getobject gplayer]
$gplayer(1) set upscale_interval_ 30.0
set sfile2_ [open stream-udp.tr w]
$gplayer(1) attach $sfile2_

#Scehdule Simulation
for {set i 0} {$i < $num_node} {incr i} {
    $ns at [expr 12.5 * $i] "$goddard($i) start"
    $ns at 240.0 "$goddard($i) stop"
}
$ns at 1000.0 "finish"

#Define a 'finish' procedure
proc finish {} {
    global ns tfile_ sfile1_, sfile2_ f nf
    $ns flush-trace

    set awkCode {
        {
            if ($8 == 3000) {
                if ($2 >= t_end_tcp) {
                    tput_tcp = bytes_tcp * 8 / ($2 - t_start_tcp);
                    print $2, tput_tcp >> "tput-tcp.tr";
                    t_start_tcp = $2;
                    t_end_tcp   = $2 + 2;
                    bytes_tcp = 0;
                }
                if ($1 == "r") {
                    bytes_tcp += $6;
                }
            }
            else if ($8 == 3001) {
                if ($2 >= t_end_udp) {
                    tput_udp = bytes_udp * 8 / ($2 - t_start_udp);
                    print $2, tput_udp >> "tput-udp.tr";
                    t_start_udp = $2;
                    t_end_udp   = $2 + 2;
                    bytes_udp = 0;
                }
                if ($1 == "r") {
                    bytes_udp += $6;
                }
            }
        }
    }


    $ns flush-trace

    #Close the trace file
    if { [info exists tfile_] } {
        close $tfile_
    }
    if { [info exists sfile1_] } {
        close $sfile1_
    }
    if { [info exists sfile2_] } {
        close $sfile2_
    }

    close $f
    close $nf

    exec rm -f tput-tcp.tr tput-udp.tr
    exec touch tput-tcp.tr tput-udp.tr
    exec awk $awkCode out.tr
    exec xgraph -bb -tk -m -x Seconds -y "Throughput (bps)" tput-tcp.tr tput-udp.tr &
    exec nam out.nam &
    exit 0
}

$ns run
