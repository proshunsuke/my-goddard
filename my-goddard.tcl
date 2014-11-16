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

# ノードリスト
set nodeList(0) ""

# ノードの帯域幅(Mbps)
set bandwidthList(0) ""

# ノードのコメント数
set commentList(0) ""

# 帯域幅割合
array set bandwidthRatio {
    3000 30
    1500 3
    1024 56
    768 13
    640 3
    512 4
    448 25
    384 17
    320 29
    256 20
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
# ノードの設定

proc nodeListInit {} {
    global ns userNum nodeList
    for {set i 0} {$i < $userNum} {incr i} {
        set nodeList($i) [$ns node]
    }
}


proc bandwidthListInit {} {
    global ns userNum bandwidthRatio bandwidthList nodeList
    set j 0
    foreach {index val} [array get bandwidthRatio] {
        for {set i 0} {$i < $val} {incr i} {
            set bandwidthList($nodeList($j)) $index
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

proc nodeListShuffle {} {
    global userNum nodeList
    puts [expr $userNum*5]
    puts [expr int($userNum*rand())]
    for {set i 0} {$i < [expr $userNum*5]} {incr i} {
        set temp1 [expr int($userNum*rand())]
        set temp2 [expr int($userNum*rand())]
        set nodeList($temp1) $temp2
        set nodeList($temp2) $temp1
    }
}
nodeListInit
commentListInit
nodeListShuffle
bandwidthListInit

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

# ノード間の接続

# 帯域幅の設定する必要あり
proc connectGateNodeInCluster { selfClusterNum } {
    global ns gateNodeNum gateNode semiGateNode clusterNum rootNode

    # 配信者ノード
    for {set i 0} {$i < $gateNodeNum} {incr i} {
        $ns duplex-link $gateNode($selfClusterNum,$i) $rootNode 8Mb 5ms DropTail
    }

    # ゲートノード同士：１→２　２→３　３→１
    for {set i 0} {$i < $gateNodeNum} {incr i} {
        if { [expr $i+1] >= $gateNodeNum } {
            $ns duplex-link $gateNode($selfClusterNum,$i) $gateNode($selfClusterNum,[expr $i+1-$gateNodeNum]) 1Mb 5ms DropTail
        } else {
            $ns duplex-link $gateNode($selfClusterNum,$i) $gateNode($selfClusterNum,[expr $i+1]) 1Mb 5ms DropTail
        }
    }

    # ゲートノードとセミゲートノード
    for {set i 0} {$i < $gateNodeNum} {incr i} {
        $ns duplex-link $gateNode($selfClusterNum,$i) $semiGateNode($selfClusterNum,$i) 1Mb 5ms DropTail
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
    global ns f gCount sfile
    $ns flush-trace

    for {set i 0} {$i < $gCount} {incr i} {
        if { [info exists sfile($i)] } {
            close $sfile($i)
        }
    }

    close $f

    exit 0
}

## 処理開始

puts "１クラスタ当たりのノードの数"
puts "ダイジェストノード: $digestNodeNum"
puts "ゲートノード: $gateNodeNum"
puts "セミゲートノード: $semiGateNodeNum"
puts "ノーマルノード: $nomalNodeNum"
puts "ダイジェスト未取得ノーマルノード: $notGetDigestNomalNum"
puts "ダイジェスト取得済みノーマルノード$getDigestNomalNum"

rootNodeInit
digestNodeInit
gateNodeInit
semiGateNodeInit
nomalNodeInit

# namファイルの設定
set f [open out.tr w]
$ns trace-all $f
set nf [open out.nam w]
$ns namtrace-all $nf

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

# namファイルは開けない、容量の問題で
# 雰囲気を知るためには1つのクラスタのみでやる（時間を１０にしたらその必要がなくなった）
createNomalNodeStream
#createNomalNodeStreamOneCluster

# Scehdule Simulation
for {set i 0} {$i < $gCount} {incr i} {
    $ns at 0 "$goddard($i) start"
    $ns at 10 "$goddard($i) stop"
}
$ns at 10.0 "finish"

$ns run
