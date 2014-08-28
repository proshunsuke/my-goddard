#NS simulator object
set ns [new Simulator]

#Set random seed
global defaultRNG
$defaultRNG seed 15

# color
$ns color 1 Blue
$ns color 2 Red

# ゲートノード
set gate_node(1) [$ns node]
set gate_node(2) [$ns node]
set gate_node(3) [$ns node]

# 他のクラスタのゲートノード
set another_gate_node(1) [$ns node]
set another_gate_node(2) [$ns node]
set another_gate_node(3) [$ns node]

# セミゲートノード
set semi_gate_node(1) [$ns node]
set semi_gate_node(2) [$ns node]
set semi_gate_node(3) [$ns node]

# ダイジェスト保有ノード
set digest_node(1) [$ns node]
set digest_node(2) [$ns node]
set digest_node(3) [$ns node]

# ノーマルノード
set nomal_node(1) [$ns node]

# ゲートノードと他のクラスタのゲートノードをつなぐ
puts "ゲートノードと他のクラスタのゲートノードをつなぐ"
for {set i 1} {$i < 4} {incr i} {
    for {set j 1} {$j < 4} {incr j} {
        puts "$gate_node($i)と$another_gate_node($j)をつなぐ"
        $ns duplex-link $gate_node($i) $another_gate_node($j) 10Mb 5ms DropTail
    }
}

# ゲートノードとセミゲートノードをつなぐ
puts "ゲートノードとセミゲートノードをつなぐ"
for {set i 1} {$i < 4} {incr i} {
    puts "$gate_node($i)と$semi_gate_node($i)をつなぐ"
    $ns duplex-link $gate_node($i) $semi_gate_node($i) 1.6mb 10ms DropTail
}

# セミゲートノードとダイジェストノードとノーマルノードをつなぐ
puts "セミゲートノードとダイジェストノードとノーマルノードをつなぐ"
puts "$semi_gate_node(1)と$digest_node(1)をつなぐ"
$ns duplex-link $semi_gate_node(1) $digest_node(1) 1.6mb 10ms DropTail

puts "$semi_gate_node(2)と$nomal_node(1)をつなぐ"
$ns duplex-link $semi_gate_node(2) $nomal_node(1) 10mb 10ms DropTail

puts "$semi_gate_node(2)と$digest_node(2)をつなぐ"
$ns duplex-link $semi_gate_node(2) $digest_node(2) 10mb 10ms DropTail

puts "$digest_node(1)と$digest_node(2)をつなぐ"
$ns duplex-link $digest_node(1) $digest_node(2) 1.6mb 10ms DropTail

puts "$semi_gate_node(3)と$nomal_node(1)をつなぐ"
$ns duplex-link $semi_gate_node(3) $nomal_node(1) 1.6mb 10ms DropTail

puts "$semi_gate_node(2)と$digest_node(3)をつなぐ"
$ns duplex-link $semi_gate_node(2) $digest_node(3) 1.6mb 10ms DropTail

puts "$digest_node(3)と$nomal_node(1)をつなぐ"
$ns duplex-link $digest_node(3) $nomal_node(1) 1.6mb 10ms DropTail

# ネットワークリンクを作る（ココらへんよくわかっていない）
set fq [[$ns link $semi_gate_node(2) $gate_node(2)] queue]
$fq set limit_ 20
$fq set queue_in_bytes_ true
$fq set mean_pktsize_ 1000

# namファイルの設定
set f [open out.tr w]
$ns trace-all $f
set nf [open out.nam w]
$ns namtrace-all $nf

# トレースファイルの設定
set tfile_ [open out.tr w]
set clink [$ns link $semi_gate_node(2) $gate_node(2)]
$clink trace $ns $tfile_

# Setup Goddard Streaming（これだけでよいのかわからない）
 set gs(0) [new GoddardStreaming $ns $nomal_node(1) $another_gate_node(1) TCP 1000 0]
set goddard(0) [$gs(0) getobject goddard]
set gplayer(0) [$gs(0) getobject gplayer]
$gplayer(0) set upscale_interval_ 30.0
set sfile1_ [open stream-tcp.tr w]
$gplayer(0) attach $sfile1_

set gs(1) [new GoddardStreaming $ns $digest_node(2) $another_gate_node(2) UDP 1000 1]
set goddard(1) [$gs(1) getobject goddard]
set gplayer(1) [$gs(1) getobject gplayer]
$gplayer(1) set upscale_interval_ 30.0
set sfile2_ [open stream-udp.tr w]
$gplayer(1) attach $sfile2_

for {set i 0} {$i < 2} {incr i} {
    $ns at [expr 12.5 * $i] "$goddard($i) start"
    $ns at 240.0 "$goddard($i) stop"
}

$ns at 1000.0 "finish"

proc finish {} {
    global ns tfile_ sfile1_, sfile2_, f nf
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


