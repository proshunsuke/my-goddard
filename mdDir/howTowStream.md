# ストリームの流し方

## リンクを張る
以下のように

`$ns duplex-link $semi_gate_node(0) $gate_node(0) 10Mb 5ms DropTail`

これでノード間がつながる、ここでは`semi_gate_node(0)`と`gate_node(0)`が繋がっている

## ネットワークリンクを作成する
ココらへんよく意味わかっていない・・・
おそらく、パケットサイズなどの設定をしているのだろう
以下のように

```
set fq [[$ns link $semi_gate_node(0) $gate_node(0)] queue]
$fq set limit_ 20
$fq set queue_in_bytes_ true
$fq set mean_pktsize_ 1000
```

## goddardストリーミング
リンク間にストリームを流す

goddardがここで出てくる

以下のように

```
set gs(0) [new GoddardStreaming $ns $l_node $r_node UDP 1000 0]
set goddard(0) [$gs(0) getobject goddard]
```

`l_node`から`r_node`へ、udpでストリームを流す。`gs`がGoddardStreamingオブジェクト？。`goddard`にストリームの情報が渡される。単に流すだけならこれだけで良いはず。

その他、トレースファイルへの書き込みなどを考慮し、関数化すると以下になる。


```goddardストリーミング生成関数
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
```

`gplayer`にトレースファイルに書き込むための情報が渡され、`stream-udp.tr`へ書き込んでいる。


