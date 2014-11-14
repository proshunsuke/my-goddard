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
# set fq [[$ns link $semi_gate_node(0) $gate_node(0)] queue]
# $fq set limit_ 20
# $fq set queue_in_bytes_ true
# $fq set mean_pktsize_ 1000

#トレースファイルの設定(out.tr)
# set tfile_ [open out.tr w]
# set clink [$ns link $semi_gate_node(1) $gate_node(1)]
# $clink trace $ns $tfile_

# Setup Goddard Streaming

# goddardのための変数宣言
set goddard(0) ""
set gplayer(0) ""
set sfile(0) ""
set gCount 0

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


# namファイルは開けない、容量の問題で
# 雰囲気を知るためには1つのクラスタのみでやる
createNomalNodeStream
# createNomalNodeStreamOneCluster


# Scehdule Simulation
for {set i 0} {$i < $gCount} {incr i} {
    $ns at 0 "$goddard($i) start"
    $ns at 100 "$goddard($i) stop"
}
$ns at 100.0 "finish"

#Define a 'finish' procedure
proc finish {} {
    global ns tfile_  f nf gCount sfile
    $ns flush-trace

    for {set i 0} {$i < $gCount} {incr i} {
        if { [info exists sfile($i)] } {
            close $sfile($i)
        }
    }

    close $f
    close $nf

    exit 0
}

$ns run
