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

# カラー
$ns color 0 blue
$ns color 1 red
$ns color 2 white

#Set random seed
global defaultRNG
$defaultRNG seed 15

# ゲートノード
set gate_node(0) [$ns node]
set gate_node(1) [$ns node]
set gate_node(2) [$ns node]

# 他のクラスタのゲートノード
set another_gate_node(0) [$ns node]
set another_gate_node(1) [$ns node]
set another_gate_node(2) [$ns node]

# セミゲートノード
set semi_gate_node(0) [$ns node]
set semi_gate_node(1) [$ns node]
set semi_gate_node(2) [$ns node]

# ダイジェスト保有ノード
set digest_node(0) [$ns node]
set digest_node(1) [$ns node]
set digest_node(2) [$ns node]

# ノーマルノード
set nomal_node(0) [$ns node]

# namファイルの設定
set f [open out.tr w]
$ns trace-all $f
set nf [open out.nam w]
$ns namtrace-all $nf

# ゲートノードと他のクラスタのゲートノードをつなぐ
puts "ゲートノードと他のクラスタのゲートノードをつなぐ"
for {set i 0} {$i < 3} {incr i} {
    for {set j 0} {$j < 3} {incr j} {
        puts "$gate_node($i)と$another_gate_node($j)をつなぐ"
        $ns duplex-link $gate_node($i) $another_gate_node($j) 10Mb 5ms DropTail
    }
}

$ns duplex-link $semi_gate_node(0) $gate_node(0) 10Mb 5ms DropTail
$ns duplex-link $semi_gate_node(1) $gate_node(1) 1.6Mb 10ms DropTail
$ns duplex-link $semi_gate_node(1) $gate_node(1) 10Mb 5ms DropTail
$ns duplex-link $semi_gate_node(2) $gate_node(2) 10Mb 5ms DropTail

$ns duplex-link $digest_node(0) $semi_gate_node(0) 10Mb 5ms DropTail
$ns duplex-link $digest_node(1) $semi_gate_node(1) 10Mb 5ms DropTail
$ns duplex-link $digest_node(1) $digest_node(0) 10Mb 5ms DropTail
$ns duplex-link $digest_node(2) $nomal_node(0) 10Mb 5ms DropTail
$ns duplex-link $digest_node(2) $semi_gate_node(2) 10Mb 5ms DropTail

$ns duplex-link $nomal_node(0) $semi_gate_node(1) 10Mb 5ms DropTail
$ns duplex-link $nomal_node(0) $semi_gate_node(2) 10Mb 5ms DropTail

#Creating the network linkf
set fq [[$ns link $semi_gate_node(0) $gate_node(0)] queue]
# set fq [[$ns link $gate_node(1) $another_gate_node(1)] queue]
$fq set limit_ 20
$fq set queue_in_bytes_ true
$fq set mean_pktsize_ 1000

#トレースファイルの設定(out.tr)
set tfile_ [open out.tr w]
set clink [$ns link $semi_gate_node(1) $gate_node(1)]
$clink trace $ns $tfile_

# Setup Goddard Streaming

# goddardのための変数宣言
set goddard(0) ""
set gplayer(0) ""
set sfile(0) ""
set g_count 0

# goddardストリーミング生成関数
proc create_goddard { l_node r_node count } {
    global ns goddard gplayer sfile g_count
    set gs($count) [new GoddardStreaming $ns $l_node $r_node UDP 1000 $count]
    set goddard($count) [$gs($count) getobject goddard]
    set gplayer($count) [$gs($count) getobject gplayer]
    $gplayer($count) set upscale_interval_ 30.0
    set sfile($count) [open stream-udp.tr w]
    $gplayer($count) attach $sfile($count)
    incr g_count
    return
}

# 関数の中に関数を書くと値が反映されない　なぜ
# proc create_goddard_two_way { l_node r_node count } {
#     create_goddard $l_node $r_node $count
#     create_goddard $r_node $l_node $count
#     return
# }

# gate_node to another_gate_node, another_gate_node to gate_node
for {set i 0} {$i < 3} {incr i} {
    for {set j 0} {$j < 3} {incr j} {
        create_goddard $gate_node($i) $another_gate_node($j) $g_count
        create_goddard $another_gate_node($i) $gate_node($j) $g_count
    }
}

# gate_node to semi_gate_node
for {set i 0} {$i < 3} {incr i} {
    create_goddard $gate_node($i) $semi_gate_node($i) $g_count
}

# semi_gate_node to digest_node, digest_node to semi_gate_node
for {set i 0} {$i < 3} {incr i} {
    create_goddard $semi_gate_node($i) $digest_node($i) $g_count
    create_goddard $digest_node($i) $semi_gate_node($i) $g_count
}

# digest_node to digest_node
create_goddard $digest_node(0) $digest_node(1) $g_count
create_goddard $digest_node(1) $digest_node(0) $g_count

# semi_gate_node to normal_node, nomal_node to semi_gate_node
create_goddard $semi_gate_node(1) $nomal_node(0) $g_count
create_goddard $nomal_node(0) $semi_gate_node(1) $g_count
create_goddard $semi_gate_node(2) $nomal_node(0) $g_count
create_goddard $nomal_node(0) $semi_gate_node(2) $g_count

# digest_node to nomal_node, nomal_node to digest_node
create_goddard $digest_node(2) $nomal_node(0) $g_count
create_goddard $nomal_node(0) $digest_node(2) $g_count

# create_goddard $semi_gate_node($i) $digest_gate_node($j) $g_count

#Scehdule Simulation
for {set i 0} {$i < $g_count} {incr i} {
    # $ns at [expr 12.5 * $i] "$goddard($i) start"
    $ns at 12.5 "$goddard($i) start"
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
