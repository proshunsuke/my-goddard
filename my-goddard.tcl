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
set connectNomalNodeRate 0.25

# ノード
set rootNode ""
set gateNode(0,0) ""
set semiGateNode(0,0) ""
set digestNode(0,0) ""
set nomalDigestNode(0,0) ""
set nomalNotDigestNode(0,0) ""

# ノードの数
set digestNodeNum [expr int(ceil([expr $userNum / $clusterNum * $digestUserRate]))]
set gateNodeNum [expr int(ceil([expr $userNum / $clusterNum * $gateCommentRate]))]
set semiGateNodeNum [expr int(ceil([expr $userNum / $clusterNum * ($semiGateCommentRate - $gateCommentRate)]))]
set nomalNodeNum  [expr $userNum / $clusterNum - $digestNodeNum - $gateNodeNum - $semiGateNodeNum]
set notGetDigestNomalNum  [expr int(ceil([expr $nomalNodeNum * $notGetDigestRate]))]
set getDigestNomalNum [expr $nomalNodeNum - $notGetDigestNomalNum]

puts "１クラスタ当たりのノードの数"
puts "ダイジェストノード: $digestNodeNum"
puts "ゲートノード: $gateNodeNum"
puts "セミゲートノード: $semiGateNodeNum"
puts "ノーマルノード: $nomalNodeNum"
puts "ダイジェスト未取得ノーマルノード: $notGetDigestNomalNum"
puts "ダイジェスト取得済みノーマルノード$getDigestNomalNum"

# ノードの設定

proc rootNodeInit {} {
    global ns rootNode
    set rootNode [$ns node]
    # 配信者ノードの色
    $rootNode color red
}

proc digestNodeInit {} {
    global ns userNum clusterNum digestNode digestUserRate digestNodeNum
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $digestNodeNum} {incr j} {
            set digestNode($i,$j) [$ns node]
            # ダイジェストノードの色
            $digestNode($i,$j) color yellow
        }
    }
    return
}

proc gateNodeInit {} {
    global ns userNum clusterNum gateNode gateBandWidthRate gateCommentRate gateNodeNum
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $gateNodeNum} {incr j} {
            set gateNode($i,$j) [$ns node]
            # ゲートノードの色
            $gateNode($i,$j) color #006400
        }
    }
    return
}

proc semiGateNodeInit {} {
    global ns userNum clusterNum gateNode gateBandWidthRate semiGateBandWidthRate gateCommentRate semiGateCommentRate semiGateNodeNum semiGateNode
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $semiGateNodeNum} {incr j} {
            set semiGateNode($i,$j) [$ns node]
            # セミゲートノードの色
            $semiGateNode($i,$j) color #00ff00
        }
    }
    return
}


proc nomalNodeInit {} {
    global ns userNum clusterNum nomalDigestNode nomalNotDigestNode notGetDigestRate notGetDigestNomalNum getDigestNomalNum
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $notGetDigestNomalNum} {incr j} {
            set nomalNotDigestNode($i,$j) [$ns node]
            # ダイジェスト未取得ノーマルノードの色
            $nomalNotDigestNode($i,$j) color black
        }
    }

    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $getDigestNomalNum} {incr j} {
            set nomalDigestNode($i,$j) [$ns node]
            # ダイジェスト取得ノーマルノードの色
            $nomalDigestNode($i,$j) color gray
        }
    }
    return
}

rootNodeInit
digestNodeInit
gateNodeInit
semiGateNodeInit
nomalNodeInit

#puts [parray semiGateNode]

# namファイルの設定
set f [open out.tr w]
$ns trace-all $f
set nf [open out.nam w]
$ns namtrace-all $nf

# ノード間の接続

# クラスタ内部
# 帯域幅の設定する必要あり
proc connectGateNodeInCluster { selfClusterNum } {
    global ns gateNodeNum gateNode semiGateNode clusterNum rootNode
    # ゲートノード同士：１→２　２→３　３→１
    for {set i 0} {$i < $gateNodeNum} {incr i} {
        if { [expr $i+1] >= $gateNodeNum } {
            $ns duplex-link $gateNode($selfClusterNum,$i) $gateNode($selfClusterNum,[expr $i+1-$gateNodeNum]) 10Mb 5ms DropTail
        } else {
            $ns duplex-link $gateNode($selfClusterNum,$i) $gateNode($selfClusterNum,[expr $i+1]) 10Mb 5ms DropTail
        }
    }
    # ゲートノードとセミゲートノード
    for {set i 0} {$i < $gateNodeNum} {incr i} {
        $ns duplex-link $gateNode($selfClusterNum,$i) $semiGateNode($selfClusterNum,$i) 10Mb 5ms DropTail
    }

    # 配信者ノード
    for {set i 0} {$i < $gateNodeNum} {incr i} {
        $ns duplex-link $gateNode($selfClusterNum,$i) $rootNode 10Mb 5ms DropTail
    }
}

proc connectGateNodeOutside { selfIndexNum } {
    global ns gateNodeNum gateNode semiGateNode clusterNum
    # クラスタ外のゲートノード同士：１→２ ２→３... 7→１
    for {set i 0} {$i < $clusterNum} {incr i} {
        if { [expr $i+1] >= $clusterNum } {
            $ns duplex-link $gateNode($i,$selfIndexNum) $gateNode([expr $i+1-$clusterNum],$selfIndexNum) 10Mb 5ms DropTail
        } else {
            $ns duplex-link $gateNode($i,$selfIndexNum) $gateNode([expr $i+1],$selfIndexNum) 10Mb 5ms DropTail
        }
    }
}

proc connectSemiGateNode { selfIndexNum } {
    global ns semiGateNode digestNode nomalDigestNode nomalNotDigestNode clusterNum semiGateNodeNum notGetDigestNomalNum getDigestNomalNum
    # ダイジェストノード
    for {set i 0} {$i < $semiGateNodeNum}  {incr i} {
        $ns duplex-link $semiGateNode($selfIndexNum,$i) $digestNode($selfIndexNum,[expr $i*2]) 10Mb 5ms DropTail
        $ns duplex-link $semiGateNode($selfIndexNum,$i) $digestNode($selfIndexNum,[expr $i*2+1]) 10Mb 5ms DropTail
    }

    # ノーマルノード
    for {set i 0} {$i < $semiGateNodeNum}  {incr i} {
        set digestBorderNum [expr int(($notGetDigestNomalNum+$getDigestNomalNum)*rand())]
        if {$digestBorderNum >= $notGetDigestNomalNum} {
            $ns duplex-link $semiGateNode($selfIndexNum,$i) $nomalDigestNode($selfIndexNum,[expr $digestBorderNum-$notGetDigestNomalNum]) 10Mb 5ms DropTail
        } else {
            $ns duplex-link $semiGateNode($selfIndexNum,$i) $nomalNotDigestNode($selfIndexNum,$digestBorderNum) 10Mb 5ms DropTail
        }
    }
}

proc connectDigestNode { selfIndexNum } {
    global ns digestNode nomalDigestNode nomalNotDigestNode clusterNum notGetDigestNomalNum getDigestNomalNum nomalNodeNum digestNodeNum
    # ダイジェスト未取得ノーマルノード
    for {set i 0} {$i < $digestNodeNum}  {incr i} {
        for {set j 0} {$j < $notGetDigestNomalNum} {incr j} {
            $ns duplex-link $digestNode($selfIndexNum,$i) $nomalNotDigestNode($selfIndexNum,$j) 10Mb 5ms DropTail
        }
    }
}

proc connectNomalNode { selfIndexNum } {
    global ns connectNomalNodeRate nomalDigestNode nomalNotDigestNode clusterNum notGetDigestNomalNum getDigestNomalNum nomalNodeNum
    # とりあえずリストに全部入れる
    for {set i 0} {$i < $nomalNodeNum} {incr i} {
        if {$i >= $notGetDigestNomalNum} {
            set nomalNodeList($i) $nomalDigestNode($selfIndexNum,[expr $i-$notGetDigestNomalNum])
        } else {
            set nomalNodeList($i) $nomalNotDigestNode($selfIndexNum,$i)
        }
    }

    # 適当な回数リストの中身をシャッフル
    set temp ""
    for {set i 0} {$i < 100 } {incr i} {
        set randomNum1 [expr int(($nomalNodeNum)*rand())]
        set randomNum2 [expr int(($nomalNodeNum)*rand())]
        set temp $nomalNodeList($randomNum1)
        set $nomalNodeList($randomNum1) $nomalNodeList($randomNum2)
        set $nomalNodeList($randomNum2) $temp
    }

    set connectNomalNum [expr int(ceil($nomalNodeNum*$connectNomalNodeRate))]

    # ノーマルノード同士：０→１　０→２　０→３　０→４、１→２　１→３...１４→１５　１４→０　１４→１　１４→２
    for {set i 0} {$i < $nomalNodeNum} {incr i} {
        for {set j 0} {$j < $connectNomalNum} {incr j} {
            if { [expr $i+$j+1] >= $nomalNodeNum } {
                $ns duplex-link $nomalNodeList($i) $nomalNodeList([expr $i+$j+1-$nomalNodeNum]) 10Mb 5ms DropTail
            } else {
                $ns duplex-link $nomalNodeList($i) $nomalNodeList([expr $i+$j+1]) 10Mb 5ms DropTail
            }
        }
    }
}


# ゲートノードの数実行
for {set i 0} {$i < $gateNodeNum} {incr i} {
    connectGateNodeOutside $i
}

# クラスタの数実行
for {set i 0} {$i < $clusterNum} {incr i} {
    connectGateNodeInCluster $i
    connectSemiGateNode $i
    connectDigestNode $i
    connectNomalNode $i
}

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
     exec nam out.nam &
    # exit 0
}

$ns run
