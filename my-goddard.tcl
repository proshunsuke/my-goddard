#NS simulator object
set ns [new Simulator]

# カラー
$ns color 0 blue
$ns color 1 red
$ns color 2 white

#Set random seed
global defaultRNG
$defaultRNG seed 15

# パラメータ設定

# 入力値
set userNum 200

# 実験用パラメータ
set clusterNum 7
set digestUserRate 0.2
set gateBandWidthRate 0.3
set gateCommentRate 0.1
set semiGateBandWidthRate 0.3
set semiGateCommentRate 0.2
set notGetDigestRate 0.2

# ノード
set gateNode(0,0) ""
set semiGateNode(0,0) ""
set digestNode(0,0) ""
set nomalDigestNode(0,0) ""
set nomalNotDigestNode(0,0) ""

# ノードの設定

proc digestNodeInit {} {
    global ns userNum clusterNum digestNode digestUserRate
    set digestNodeNum [expr int(ceil([expr $userNum * $digestUserRate]))]
    puts $digestNodeNum
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $digestNodeNum} {incr j} {
            set digestNode($i,$j) [$ns node]
            # ダイジェストノードの色
            $digestNode($i,$j) color green
        }
    }
    return
}

proc gateNodeInit {} {
    global ns userNum clusterNum gateNode gateBandWidthRate gateCommentRate
    set gateNodeNum [expr int(ceil([expr $userNum * $gateCommentRate]))]
    puts $gateNodeNum
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $gateNodeNum} {incr j} {
            set gateNode($i,$j) [$ns node]
            # ゲートノードの色
            $gateNode($i,$j) color green
        }
    }
    return
}

proc semiGateNodeInit {} {

}


digestNodeInit
gateNodeInit

#puts [parray digestNode]


# namファイルの設定
# set f [open out.tr w]
# $ns trace-all $f
# set nf [open out.nam w]
# $ns namtrace-all $nf

# ノード間の接続

#Creating the network linkf

#トレースファイルの設定(out.tr)

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

# create_goddard

# Scehdule Simulation
# for {set i 0} {$i < $g_count} {incr i} {
#     $ns at 12.5 "$goddard($i) start"
#     $ns at 240.0 "$goddard($i) stop"
# }
$ns at 1000.0 "finish"

#Define a 'finish' procedure
proc finish {} {
    # $ns flush-trace

    # # スループットawkコード
    # set awkCode {
    #     {
    #         if ($8 == 3000) {
    #             if ($2 >= t_end_tcp) {
    #                 tput_tcp = bytes_tcp * 8 / ($2 - t_start_tcp);
    #                 print $2, tput_tcp >> "tput-tcp.tr";
    #                 t_start_tcp = $2;
    #                 t_end_tcp   = $2 + 2;
    #                 bytes_tcp = 0;
    #             }
    #             if ($1 == "r") {
    #                 bytes_tcp += $6;
    #             }
    #         }
    #         else if ($8 == 3001) {
    #             if ($2 >= t_end_udp) {
    #                 tput_udp = bytes_udp * 8 / ($2 - t_start_udp);
    #                 print $2, tput_udp >> "tput-udp.tr";
    #                 t_start_udp = $2;
    #                 t_end_udp   = $2 + 2;
    #                 bytes_udp = 0;
    #             }
    #             if ($1 == "r") {
    #                 bytes_udp += $6;
    #             }
    #         }
    #     }
    # }


    # $ns flush-trace

    # for {set i 0} {$i < $g_count} {incr i} {
    #     if { [info exists sfile($i)] } {
    #         close $sfile($i)
    #     }
    # }

    # close $f
    # close $nf

    # exec rm -f tput-tcp.tr tput-udp.tr
    # exec touch tput-tcp.tr tput-udp.tr
    # exec awk $awkCode out.tr
    # exec xgraph -bb -tk -m -x Seconds -y "Throughput (bps)" tput-tcp.tr tput-udp.tr &
    # exec nam out.nam &
    # exit 0
}

# $ns run
