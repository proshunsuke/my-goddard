# デフォルトの値はここで定義
#source my-goddard-default.tcl

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

# 低い方の帯域幅を返す
proc returnLowBandwidth {bandwidthList node1 node2} {
    upvar $bandwidthList bl
    if { $bl($node1) >= $bl($node2) } {
        return $bl($node2)
    } else {
        return $bl($node1)
    }
}

# ここからシミュレータの処理

# パケットの色設定
proc setPacketColor { ns } {
    $ns color 0 blue
    $ns color 1 red
    $ns color 2 white
}

# ノードの設定

proc setClusterNum {clusterNumArg userNum} {
    upvar $clusterNumArg clusterNum
    if {$userNum == 200} {
        set clusterNum 7
    } elseif {$userNum == 400} {
        set clusterNum 10
    } elseif {$userNum == 600} {
        set clusterNum 14
    } elseif {$userNum == 800} {
        set clusterNum 18
    }
}

proc setNodeNum {digestNodeNum gateNodeNum semiGateNodeNum nomalNodeNum notGetDigestNomalNum getDigestNomalNum userNum clusterNum digestUserRate gateCommentRate semiGateCommentRate gateCommentRate semiGateNodeNum notGetDigestRate} {
    upvar $digestNodeNum dnn $gateNodeNum gnn $semiGateNodeNum sgnn $nomalNodeNum nnn $notGetDigestNomalNum ngdn $getDigestNomalNum gdnn
    set dnn [expr int(ceil([expr $userNum / $clusterNum * $digestUserRate]))]
    set gnn [expr int(ceil([expr $userNum / $clusterNum * $gateCommentRate]))]
    set sgnn [expr int(ceil([expr $userNum / $clusterNum * ($semiGateCommentRate - $gateCommentRate)]))]
    set nnn  [expr $userNum / $clusterNum - $dnn - $gnn - $sgnn]
    set ngdn  [expr int(ceil([expr $nnn * $notGetDigestRate]))]
    set gdnn [expr $nnn - $ngdn]
}

proc ratioSetting {bandwidthRatio commentRatio clusterNum userNum} {
    upvar $bandwidthRatio br $commentRatio cr

    set basicRatio [expr $userNum/200]
    foreach {index val} [array get br] {
        set tempBandwidthRatio($index) [expr $val*$basicRatio]
    }
    copy tempBandwidthRatio br

    foreach {index val} [array get cr] {
        set tempCommentRatio($index) [expr $val*$basicRatio]
    }
    copy tempCommentRatio cr
}

proc nodeListInit {nodeList nodeListForBandwidth ns userNum} {
    upvar $nodeList nl $nodeListForBandwidth nlfb
    for {set i 0} {$i < $userNum} {incr i} {
        set nl($i) [$ns node]
        set nlfb($i) $nl($i)
    }
}

proc bandwidthListInit {bandwidthList bandwidthRatio nodeListForBandwidth ns userNum} {
    upvar $bandwidthList bl $bandwidthRatio br $nodeListForBandwidth nlfb
    set j 0
    foreach {index val} [array get br] {
        for {set i 0} {$i < $val} {incr i} {
            set bl($nlfb($j)) $index
            incr j
        }
    }
}

proc commentListInit {commentList commentRatio nodeList ns userNum } {
    upvar $commentList cl $commentRatio cr $nodeList nl
    set j 0
    foreach {index val} [array get cr] {
        for {set i 0} {$i < $val} {incr i} {
            set cl($nl($j)) $index
            incr j
        }
    }
}

proc nodeListForBandwidthShuffle {nodeListForBandwidth userNum} {
    upvar $nodeListForBandwidth nlfb
    for {set i 0} {$i < [expr $userNum*5]} {incr i} {
        set temp1 [expr int($userNum*rand())]
        set temp2 [expr int($userNum*rand())]
        set tempNode $nlfb($temp1)
        set nlfb($temp1) $nlfb($temp2)
        set nlfb($temp2) $tempNode
    }
}

proc rootNodeInit {rootNode ns} {
    upvar $rootNode rn
    set rn [$ns node]
    # 配信者ノードの色
    $rn color red
}

# この中で便宜上一時的に帯域幅リストからノードを削除している
proc digestNodeInit {digestNode bandwidthList temporalBandwidthList nodeListForBandwidth nodeList userNum clusterNum digestNodeNum} {
    upvar $digestNode dn $bandwidthList bl $temporalBandwidthList tbl $nodeListForBandwidth nlfb $nodeList nl

    copy bl tbl

    set commentI [expr $userNum-1]
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $digestNodeNum} {incr j} {
            set dn($i,$j) $nl($commentI)

            # 帯域幅リストからダイジェストノードを削除
            array unset bl $nl($commentI)

            # 帯域幅ノードリストからダイジェストノードを削除
            for {set k 0} {$k < [array size nlfb]} {incr k} {
                if {[array get nlfb $k] == []} {
                    continue
                }
                if {$nlfb($k) == $nl($commentI)} {
                    array unset nlfb $k
                    break
                }
            }

            # ダイジェストノードの色
            $dn($i,$j) color yellow

            decr commentI
        }
    }
    return
}

proc sortBandwidthList {sortedBandwidthList bandwidthRatio bandwidthList} {
    upvar $sortedBandwidthList sbl $bandwidthRatio br $bandwidthList bl

    # 帯域幅の種類のリスト
    set i 0
    foreach val [lsort -real [array names br]] {
        set kindOfBandwidthList($i) $val
        incr i
    }

    set k 0
    for {set i [expr [array size kindOfBandwidthList]-1]} {$i >= 0} {decr i} {
        foreach {index val} [array get bl] {
            if {$val == $kindOfBandwidthList($i)} {
                set sbl($k) $index
                incr k
            }
        }
    }
}

proc gateNodeInit {gateNode sortedBandwidthList clusterNum gateNodeNum} {
    upvar $gateNode gn $sortedBandwidthList sbl
    set k 0
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $gateNodeNum} {incr j} {
            set gn($i,$j) $sbl($k)

            # ゲートノードの色
            $gn($i,$j) color #006400

            incr k
        }
    }
    return
}

proc semiGateNodeInit {semiGateNode sortedBandwidthList gateNode clusterNum semiGateNodeNum} {
    upvar $semiGateNode sgn $sortedBandwidthList sbl $gateNode gn
    set k [array size gn]
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $semiGateNodeNum} {incr j} {
            set sgn($i,$j) $sbl($k)

            # セミゲートノードの色
            $sgn($i,$j) color #00ff00

            incr k
        }
    }

    return
}

proc nomalNodeInit {nomalNotDigestNode nomalDigestNode gateNode semiGateNode sortedBandwidthList clusterNum notGetDigestNomalNum getDigestNomalNum} {
    upvar $nomalNotDigestNode nndn $nomalDigestNode ndn $gateNode gn $semiGateNode sgn $sortedBandwidthList sbl

    set k [expr [array size gn] + [array size sgn]]
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $notGetDigestNomalNum} {incr j} {
            set nndn($i,$j) $sbl($k)

            # ダイジェスト未取得ノーマルノードの色
            $nndn($i,$j) color pink

            incr k
        }
    }

    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $getDigestNomalNum} {incr j} {
            set ndn($i,$j) $sbl($k)

            # ダイジェスト取得ノーマルノードの色
            $ndn($i,$j) color orange

            incr k
        }
    }

    # 残りのノードはu全てダイジェスト取得済みノーマルノードへ
    set limit [expr [array size sbl]-$k]

    for {set i 0} {$i < $limit} {incr i} {
        set ndn($i,$getDigestNomalNum) $sbl($k)

        # ダイジェスト取得ノーマルノードの色
        $ndn($i,$getDigestNomalNum) color orange

        incr k
    }
    return
}

proc connectGateNodeOutside {gateNode bandwidthList nsArg clusterNum gateNodeNum selfIndexNum} {
    upvar $gateNode gn $bandwidthList bl $nsArg ns
    # クラスタ外のゲートノード同士：１→２ ２→３... 7→１
    for {set i 0} {$i < $clusterNum} {incr i} {
        if { [expr $i+1] >= $clusterNum } {
            set bandwidth [returnLowBandwidth bl $gn($i,$selfIndexNum) $gn([expr $i+1-$clusterNum],$selfIndexNum)]
            $ns duplex-link $gn($i,$selfIndexNum) $gn([expr $i+1-$clusterNum],$selfIndexNum) [expr $bandwidth]Mb 100ms DropTail
        } else {
            set bandwidth [returnLowBandwidth bl $gn($i,$selfIndexNum) $gn([expr $i+1],$selfIndexNum)]
            $ns duplex-link $gn($i,$selfIndexNum) $gn([expr $i+1],$selfIndexNum) [expr $bandwidth]Mb 100ms DropTail
        }
    }
}

# Setup Goddard Streaming

# goddardストリーミング生成関数
proc createGoddard { goddard gplayer sfile gCount ns l_node r_node } {
    upvar $goddard gd $gplayer gp $sfile sf $gCount gc
    set gs($gc) [new GoddardStreaming $ns $l_node $r_node UDP 1000 $gc]
    set gd($gc) [$gs($gc) getobject goddard]
    set gp($gc) [$gs($gc) getobject gplayer]
    $gp($gc) set upscale_interval_ 30.0
    set sf($gc) [open stream-udp.tr w]
    $gp($gc) attach $sf($gc)
    incr gc
    return
}

# create goddard

proc createNomalNodeStream {nomalDigestNode nomalNotDigestNode digestNode goddard gplayer sfile gCount rootNode ns clusterNum getDigestNomalNum notGetDigestNomalNum digestNodeNum} {
    upvar $nomalDigestNode ndn $nomalNotDigestNode nndn $digestNode dn $goddard gd $gplayer gp $sfile sf $gCount gc
    for {set i 0} {$i < $clusterNum} {incr i} {
        for {set j 0} {$j < $getDigestNomalNum} {incr j} {
            createGoddard gd gp sf gc $ns $rootNode $ndn($i,$j)
        }
        for {set j 0} {$j < $notGetDigestNomalNum} {incr j} {
            createGoddard gd gp sf gc $ns $rootNode $nndn($i,$j)
        }
        for {set j 0} {$j < $digestNodeNum} {incr j} {
            createGoddard gd gp sf gc $ns $rootNode $dn($i,$j)
        }
    }
}
