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

# 入力値(ユーザ数は必ず200の倍数)
set userNum [lindex $argv 0]

# ユーザ数に応じて変化
set clusterNum 0

# 実験用パラメータ
set digestUserRate 0
set gateBandWidthRate 0
set gateCommentRate 0
set semiGateBandWidthRate 0
set semiGateCommentRate 0
set notGetDigestRate 0
set connectNomalNodeRate 0.25

# ノード
set rootNode ""
set gateNode(0,0) ""
set semiGateNode(0,0) ""
set digestNode(0,0) ""
set nomalDigestNode(0,0) ""
set nomalNotDigestNode(0,0) ""

# ノードの数
set digestNodeNum 0
set gateNodeNum 0
set semiGateNodeNum 0
set nomalNodeNum  0
set notGetDigestNomalNum 0
set getDigestNomalNum 0

# ノードリスト
set nodeList(0) ""
set nodeListForBandwidth(0) ""

# 帯域幅ノードリスト(Mbps)
set bandwidthList(0) ""

# 一時退避帯域幅ノードリスト
set temporalBandwidthList(0) ""

# コメント数ノードリスト
set commentList(0) ""

# ダイジェスト以外のソートされた帯域幅ノードリスト
set sortedBandwidthList(0) ""

# 帯域幅割合
array set bandwidthRatio {
    3.000 30
    1.500 3
    1.024 56
    0.768 13
    0.640 3
    0.512 4
    0.448 25
    0.384 17
    0.320 29
    0.256 20
}

# コメント数割合
array set commentRatio {
    25 2
    22 2
    20 3
    17 5
    15 22
    12 28
    10 33
    7 36
    5 36
    2 33
}

# goddardのための変数宣言
set goddard(0) ""
set gplayer(0) ""
set sfile(0) ""
set gCount 0

# 処理のためのメソッド定義

proc decr { int { n 1 } } {
    if { [ catch {
        uplevel incr $int -$n
    } err ] } {
        return -code error "decr: $err"
    }
    return [ uplevel set $int ]
}

# 配列をコピー
proc copy {ary1 ary2} {
    upvar $ary1 from $ary2 to
    foreach {index value} [array get from *] {
        set to($index) $value
    }
}

# ノードの設定

proc setClusterNum { num } {
    global clusterNum
    if {$num == 200} {
        set clusterNum 7
    } elseif {$num == 400} {
        set clusterNum 10
    } elseif {$num == 600} {
        set clusterNum 14
    } elseif {$num == 800} {
        set clusterNum 18
    }
}

proc setNodeNum {} {
    global digestNodeNum gateNodeNum semiGateNodeNum nomalNodeNum notGetDigestNomalNum getDigestNomalNum userNum clusterNum digestUserRate gateCommentRate nomalNodeNum notGetDigestRate notGetDigestNomalNum semiGateNodeRate semiGateCommentRate
    set digestNodeNum [expr int(ceil([expr $userNum / $clusterNum * $digestUserRate]))]
    set gateNodeNum [expr int(ceil([expr $userNum / $clusterNum * $gateCommentRate]))]
    set semiGateNodeNum [expr int(ceil([expr $userNum / $clusterNum * ($semiGateCommentRate - $gateCommentRate)]))]
    set nomalNodeNum  [expr $userNum / $clusterNum - $digestNodeNum - $gateNodeNum - $semiGateNodeNum]
    set notGetDigestNomalNum  [expr int(ceil([expr $nomalNodeNum * $notGetDigestRate]))]
    set getDigestNomalNum [expr $nomalNodeNum - $notGetDigestNomalNum]
}

proc ratioSetting {} {
    global bandwidthRatio commentRatio clusterNum userNum

    set basicRatio [expr $userNum/200]
    foreach {index val} [array get bandwidthRatio] {
        set tempBandwidthRatio($index) [expr $val*$basicRatio]
    }
    copy tempBandwidthRatio bandwidthRatio

    foreach {index val} [array get commentRatio] {
        set tempCommentRatio($index) [expr $val*$basicRatio]
    }
    copy tempCommentRatio commentRatio
}

proc nodeListInit {} {
    global ns userNum nodeList nodeListForBandwidth
    for {set i 0} {$i < $userNum} {incr i} {
        set nodeList($i) [$ns node]
        set nodeListForBandwidth($i) $nodeList($i)
    }
}

proc bandwidthListInit {} {
    global ns userNum bandwidthRatio bandwidthList nodeListForBandwidth
    set j 0
    foreach {index val} [array get bandwidthRatio] {
        for {set i 0} {$i < $val} {incr i} {
            set bandwidthList($nodeListForBandwidth($j)) $index
            incr j
        }
    }
}

proc commentListInit {} {
    global ns userNum commentRatio commentList nodeList
    set j 0
    foreach {index val} [array get commentRatio] {
        for {set i 0} {$i < $val} {incr i} {
            set commentList($nodeList($j)) $index
            incr j
        }
    }
}

proc nodeListForBandwidthShuffle {} {
    global userNum nodeListForBandwidth
    for {set i 0} {$i < [expr $userNum*5]} {incr i} {
        set temp1 [expr int($userNum*rand())]
        set temp2 [expr int($userNum*rand())]
        set tempNode $nodeListForBandwidth($temp1)
        set nodeListForBandwidth($temp1) $nodeListForBandwidth($temp2)
        set nodeListForBandwidth($temp2) $tempNode
    }
}

proc rootNodeInit {} {
    global ns rootNode
    set rootNode [$ns node]
    # 配信者ノードの色
    $rootNode color red
}

# この中で便宜上一時的に帯域幅リストからノードを削除している
proc digestNodeInit {} {
    global ns userNum clusterNum digestNode digestUserRate digestNodeNum nodeList commentList bandwidthList nodeListForBandwidth temporalBandwidthList

    copy bandwidthList temporalBandwidthList

    set commentI [expr $userNum-1]
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $digestNodeNum} {incr j} {
            set digestNode($i,$j) $nodeList($commentI)

            # 帯域幅リストからダイジェストノードを削除
            array unset bandwidthList $nodeList($commentI)

            # 帯域幅ノードリストからダイジェストノードを削除
            for {set k 0} {$k < [array size nodeListForBandwidth]} {incr k} {
                if {[array get nodeListForBandwidth $k] == []} {
                    continue
                }
                if {$nodeListForBandwidth($k) == $nodeList($commentI)} {
                    array unset nodeListForBandwidth $k
                    break
                }
            }

            # ダイジェストノードの色
            $digestNode($i,$j) color yellow

            decr commentI
        }
    }
    return
}

proc sortBandwidthList {} {
    global nodeListForBandwidth bandwidthList bandwidthRatio sortedBandwidthList

    # 帯域幅の種類のリスト
    set i 0
    foreach val [lsort -real [array names bandwidthRatio]] {
        set kindOfBandwidthList($i) $val
        incr i
    }

    set k 0
    for {set i [expr [array size kindOfBandwidthList]-1]} {$i >= 0} {decr i} {
        foreach {index val} [array get bandwidthList] {
            if {$val == $kindOfBandwidthList($i)} {
                set sortedBandwidthList($k) $index
                incr k
            }
        }
    }
}

proc gateNodeInit {} {
    global ns userNum clusterNum gateNode gateBandWidthRate gateCommentRate gateNodeNum sortedBandwidthList
    set k 0
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $gateNodeNum} {incr j} {
            set gateNode($i,$j) $sortedBandwidthList($k)

            # ゲートノードの色
            $gateNode($i,$j) color #006400

            incr k
        }
    }
    return
}

proc semiGateNodeInit {} {
    global ns userNum clusterNum gateNode gateBandWidthRate semiGateBandWidthRate gateCommentRate semiGateCommentRate semiGateNodeNum semiGateNode sortedBandwidthList
    set k [array size gateNode]
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $semiGateNodeNum} {incr j} {
            set semiGateNode($i,$j) $sortedBandwidthList($k)

            # セミゲートノードの色
            $semiGateNode($i,$j) color #00ff00

            incr k
        }
    }

    return
}


proc nomalNodeInit {} {
    global ns userNum clusterNum nomalDigestNode nomalNotDigestNode notGetDigestRate notGetDigestNomalNum getDigestNomalNum gateNode semiGateNode sortedBandwidthList

    # set k [expr [array size gateNode] + [array size semiGateNode]]
    set k 0

    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $notGetDigestNomalNum} {incr j} {
            set nomalNotDigestNode($i,$j) $sortedBandwidthList($k)

            # ダイジェスト未取得ノーマルノードの色
            $nomalNotDigestNode($i,$j) color pink

            incr k
        }
    }

    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $getDigestNomalNum} {incr j} {
            set nomalDigestNode($i,$j) $sortedBandwidthList($k)

            # ダイジェスト取得ノーマルノードの色
            $nomalDigestNode($i,$j) color orange

            incr k
        }
    }

    # 残りのノードはu全てダイジェスト取得済みノーマルノードへ
    set k [expr $k]
    set limit [expr [array size sortedBandwidthList]-$k]

    for {set i 0} {$i < $limit} {incr i} {
        set nomalDigestNode($i,$getDigestNomalNum) $sortedBandwidthList($k)

        # ダイジェスト取得ノーマルノードの色
        $nomalDigestNode($i,$getDigestNomalNum) color orange

        incr k
    }

    return
}

proc returnLowBandwidth {node1 node2} {
    global bandwidthList
    if { $bandwidthList($node1) >= $bandwidthList($node2) } {
        return $bandwidthList($node2)
    } else {
        return $bandwidthList($node1)
    }
}

proc copyOriginalBandwidthList {} {
    global bandwidthList temporalBandwidthList
    copy temporalBandwidthList bandwidthList
}

# ノード間の接続
# 常に低いノード側の帯域幅で接続

# 帯域幅の設定する必要あり
proc connectGateNodeInCluster { selfClusterNum } {
    global ns gateNodeNum gateNode semiGateNode clusterNum rootNode sortedBandwidthList bandwidthList

    # 配信者ノード
    for {set i 0} {$i < $gateNodeNum} {incr i} {
        $ns duplex-link $gateNode($selfClusterNum,$i) $rootNode $bandwidthList($gateNode($selfClusterNum,$i))Mb 500ms DropTail
    }

    # ゲートノード同士：１→２　２→３　３→１
    for {set i 0} {$i < $gateNodeNum} {incr i} {
        if { [expr $i+1] >= $gateNodeNum } {
            set bandwidth [returnLowBandwidth $gateNode($selfClusterNum,$i) $gateNode($selfClusterNum,[expr $i+1-$gateNodeNum])]
            $ns duplex-link $gateNode($selfClusterNum,$i) $gateNode($selfClusterNum,[expr $i+1-$gateNodeNum]) [expr $bandwidth]Mb 100ms DropTail
        } else {
            set bandwidth [returnLowBandwidth $gateNode($selfClusterNum,$i) $gateNode($selfClusterNum,[expr $i+1])]
            $ns duplex-link $gateNode($selfClusterNum,$i) $gateNode($selfClusterNum,[expr $i+1]) [expr $bandwidth]Mb 100ms DropTail
        }
    }

    # ゲートノードとセミゲートノード
    for {set i 0} {$i < $gateNodeNum} {incr i} {
        set bandwidth [returnLowBandwidth $gateNode($selfClusterNum,$i) $semiGateNode($selfClusterNum,$i)]
        $ns duplex-link $gateNode($selfClusterNum,$i) $semiGateNode($selfClusterNum,$i) [expr $bandwidth]Mb 100ms DropTail
    }
}

proc connectGateNodeOutside { selfIndexNum } {
    global ns gateNodeNum gateNode semiGateNode clusterNum
    # クラスタ外のゲートノード同士：１→２ ２→３... 7→１
    for {set i 0} {$i < $clusterNum} {incr i} {
        if { [expr $i+1] >= $clusterNum } {
            set bandwidth [returnLowBandwidth $gateNode($i,$selfIndexNum) $gateNode([expr $i+1-$clusterNum],$selfIndexNum)]
            $ns duplex-link $gateNode($i,$selfIndexNum) $gateNode([expr $i+1-$clusterNum],$selfIndexNum) [expr $bandwidth]Mb 100ms DropTail
        } else {
            set bandwidth [returnLowBandwidth $gateNode($i,$selfIndexNum) $gateNode([expr $i+1],$selfIndexNum)]
            $ns duplex-link $gateNode($i,$selfIndexNum) $gateNode([expr $i+1],$selfIndexNum) [expr $bandwidth]Mb 100ms DropTail
        }
    }
}

proc connectSemiGateNode { selfIndexNum } {
    global ns semiGateNode digestNode nomalDigestNode nomalNotDigestNode clusterNum semiGateNodeNum notGetDigestNomalNum getDigestNomalNum bandwidthList
    # ダイジェストノード
    for {set i 0} {$i < $semiGateNodeNum}  {incr i} {
        set bandwidth [returnLowBandwidth $semiGateNode($selfIndexNum,$i) $digestNode($selfIndexNum,[expr $i*2])]
        $ns duplex-link $semiGateNode($selfIndexNum,$i) $digestNode($selfIndexNum,[expr $i*2]) [expr $bandwidth]Mb 100ms DropTail
        if {[array get digestNode $selfIndexNum,[expr $i*2+1]] == []} {
                    continue
        }
        set bandwidth [returnLowBandwidth $semiGateNode($selfIndexNum,$i) $digestNode($selfIndexNum,[expr $i*2+1])]
        $ns duplex-link $semiGateNode($selfIndexNum,$i) $digestNode($selfIndexNum,[expr $i*2+1]) [expr $bandwidth]Mb 100ms DropTail
    }

    # ノーマルノード
    for {set i 0} {$i < $semiGateNodeNum}  {incr i} {
        set digestBorderNum [expr int(($notGetDigestNomalNum+$getDigestNomalNum)*rand())]
        if {$digestBorderNum >= $notGetDigestNomalNum} {
            set bandwidth [returnLowBandwidth $semiGateNode($selfIndexNum,$i) $nomalDigestNode($selfIndexNum,[expr $digestBorderNum-$notGetDigestNomalNum])]
            $ns duplex-link $semiGateNode($selfIndexNum,$i) $nomalDigestNode($selfIndexNum,[expr $digestBorderNum-$notGetDigestNomalNum]) [expr $bandwidth]Mb 100ms DropTail
        } else {
            set bandwidth [returnLowBandwidth $semiGateNode($selfIndexNum,$i) $nomalNotDigestNode($selfIndexNum,$digestBorderNum)]
            $ns duplex-link $semiGateNode($selfIndexNum,$i) $nomalNotDigestNode($selfIndexNum,$digestBorderNum) [expr $bandwidth]Mb 100ms DropTail
        }
    }
}

proc connectDigestNode { selfIndexNum } {
    global ns digestNode nomalDigestNode nomalNotDigestNode clusterNum notGetDigestNomalNum getDigestNomalNum nomalNodeNum digestNodeNum
    # ダイジェスト未取得ノーマルノード
    for {set i 0} {$i < $digestNodeNum}  {incr i} {
        for {set j 0} {$j < $notGetDigestNomalNum} {incr j} {
            set bandwidth [returnLowBandwidth $digestNode($selfIndexNum,$i) $nomalNotDigestNode($selfIndexNum,$j)]
            $ns duplex-link $digestNode($selfIndexNum,$i) $nomalNotDigestNode($selfIndexNum,$j) [expr $bandwidth]Mb 100ms DropTail
        }
    }
}

proc connectNomalNode { selfIndexNum } {
    global ns connectNomalNodeRate nomalDigestNode nomalNotDigestNode clusterNum notGetDigestNomalNum getDigestNomalNum nomalNodeNum rootNode bandwidthList

    # とりあえずリストに全部入れる
    for {set i 0} {$i < [expr $nomalNodeNum+1]} {incr i} {
        if {$i >= $notGetDigestNomalNum} {
            if {[array get nomalDigestNode $selfIndexNum,[expr $i-$notGetDigestNomalNum]] == []} {
                continue
            }
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
    for {set i 0} {$i < [expr $nomalNodeNum+1]} {incr i} {
        for {set j 0} {$j < $connectNomalNum} {incr j} {
            if { [expr $i+$j+1] >= $nomalNodeNum } {
                if {[array get nomalNodeList $i] == []} {
                    continue
                }
                set bandwidth [returnLowBandwidth $nomalNodeList($i) $nomalNodeList([expr $i+$j+1-$nomalNodeNum])]
                $ns duplex-link $nomalNodeList($i) $nomalNodeList([expr $i+$j+1-$nomalNodeNum]) [expr $bandwidth]Mb 100ms DropTail
            } else {
                set bandwidth [returnLowBandwidth $nomalNodeList($i) $nomalNodeList([expr $i+$j+1])]
                $ns duplex-link $nomalNodeList($i) $nomalNodeList([expr $i+$j+1]) [expr $bandwidth]Mb 100ms DropTail
            }
        }
    }

    # 配信者ノード
    $ns duplex-link $nomalNodeList(0) $rootNode $bandwidthList($nomalNodeList(0))Mb 500ms DropTail

}

# Setup Goddard Streaming

# goddardストリーミング生成関数
proc createGoddard { l_node r_node count } {
    global ns goddard gplayer sfile gCount
    set gs($count) [new GoddardStreaming $ns $l_node $r_node UDP 1000 $count]
    set goddard($count) [$gs($count) getobject goddard]
    set gplayer($count) [$gs($count) getobject gplayer]
    $gplayer($count) set upscale_interval_ 30.0
    set sfile($count) [open stream-udp.tr w]
    $gplayer($count) attach $sfile($count)
    incr gCount
    return
}

# create goddard

proc createNomalNodeStream {} {
    global nomalDigestNode nomalNotDigestNode rootNode clusterNum getDigestNomalNum notGetDigestNomalNum gCount digestNode digestNodeNum
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $getDigestNomalNum} {incr j} {
            createGoddard $rootNode $nomalDigestNode($i,$j) $gCount
        }
        for {set j 0} {$j < $notGetDigestNomalNum} {incr j} {
            createGoddard $rootNode $nomalNotDigestNode($i,$j) $gCount
        }
        for {set j 0} {$j < $digestNodeNum} {incr j} {
            createGoddard $rootNode $digestNode($i,$j) $gCount
        }
    }
}

proc createNomalNodeStreamOneCluster {} {
    global nomalDigestNode nomalNotDigestNode rootNode clusterNum getDigestNomalNum notGetDigestNomalNum gCount digestNode digestNodeNum
    for {set j 0} {$j < $getDigestNomalNum} {incr j} {
        createGoddard $rootNode $nomalDigestNode(0,$j) $gCount
    }
    for {set j 0} {$j < $notGetDigestNomalNum} {incr j} {
        createGoddard $rootNode $nomalNotDigestNode(0,$j) $gCount
    }
    for {set j 0} {$j < $digestNodeNum} {incr j} {
        createGoddard $rootNode $digestNode(0,$j) $gCount
    }
}

#Define a 'finish' procedure
proc finish {} {
    global ns f gCount sfile userNum
    $ns flush-trace

    set awkCode {
        {
            if ($8 == 3000) {
                if ($2 >= t_end_tcp) {
                    tput_tcp = bytes_tcp * 8 / ($2 - t_start_tcp)/1000;
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
                    tput_udp = bytes_udp * 8 / ($2 - t_start_udp)/1000;
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

    for {set i 0} {$i < $gCount} {incr i} {
        if { [info exists sfile($i)] } {
            close $sfile($i)
        }
    }

    close $f

    exec rm -f tput-tcp.tr tput-udp.tr
    exec touch tput-tcp.tr tput-udp.tr
    exec awk $awkCode out.tr
    exec xgraph -bb -tk -m -x Seconds -y "Throughput (kbps)" tput-tcp.tr tput-udp.tr &
    exec cp out.nam [append outNamName "out" $userNum "-no-roll.nam"]
    exec cp out.tr [append outTrName "out" $userNum "-no-roll.tr"]
    exec cp tput-tcp.tr [append tputTcpName "tput-tcp" $userNum "-no-roll.tr"]
    exec cp tput-udp.tr [append tputUdpName "tput-udp" $userNum "-no-roll.tr"]
    exit 0
}

## 処理開始

setClusterNum $userNum
setNodeNum

puts "１クラスタ当たりのノードの数\n"
puts "ダイジェストノード: \t\t\t$digestNodeNum"
puts "ゲートノード: \t\t\t\t$gateNodeNum"
puts "セミゲートノード: \t\t\t$semiGateNodeNum"
puts "ノーマルノード: \t\t\t$nomalNodeNum"
puts "ダイジェスト未取得ノーマルノード: \t$notGetDigestNomalNum"
puts "ダイジェスト取得済みノーマルノード: \t$getDigestNomalNum"

ratioSetting

nodeListInit
commentListInit
nodeListForBandwidthShuffle
bandwidthListInit

rootNodeInit
digestNodeInit
sortBandwidthList
gateNodeInit
semiGateNodeInit
nomalNodeInit

puts "\nノードの数\n"
puts "ダイジェストノード: \t\t\t[array size digestNode]"
puts "ゲートノード: \t\t\t\t[array size gateNode]"
puts "セミゲートノード: \t\t\t[array size semiGateNode]"
puts "ダイジェスト未取得ノーマルノード: \t[array size nomalNotDigestNode]"
puts "ダイジェスト取得済みノーマルノード: \t[array size nomalDigestNode]"

# namファイルの設定
set f [open out.tr w]
$ns trace-all $f
set nf [open out.nam w]
$ns namtrace-all $nf

# 一時的にノードを削除していたので帯域幅リストを元に戻す
copyOriginalBandwidthList

# ゲートノードの数実行
for {set i 0} {$i < $gateNodeNum} {incr i} {
    connectGateNodeOutside $i
}

# クラスタの数実行
for {set i 0} {$i < $clusterNum} {incr i} {
    # connectGateNodeInCluster $i
    # connectSemiGateNode $i
    # connectDigestNode $i
    connectNomalNode $i
}

# namファイルは開けない、容量の問題で
# 雰囲気を知るためには1つのクラスタのみでやる（時間を１０にしたらその必要がなくなった）
createNomalNodeStream
#createNomalNodeStreamOneCluster

# Scehdule Simulation
for {set i 0} {$i < $gCount} {incr i} {
    $ns at 0 "$goddard($i) start"
    $ns at 240.0 "$goddard($i) stop"
}
$ns at 240.0 "finish"

$ns run
