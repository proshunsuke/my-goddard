# 研究で使われていたgoddardを使用したサンプル

#NS simulator object
set ns [new Simulator]
set nf [open out.nam w]
$ns namtrace-all $nf
#Set random seed
global defaultRNG
$defaultRNG seed 100
#setting number of flows
set num_node 10
#setting distribution number for flow speed
set dist 2
#Making the two network nodes
set node_server [$ns node]
$node_server color blue
set node_router [$ns node]
$node_router color red
#making random generator
set RND [new RNG]
set speed [expr round([$RND uniform 1 100])]
#Making edge nodes for num_node
for {set i 0} {$i < $num_node} {incr i} {
    set node_($i) [$ns node]
    $node_($i) color pink
}
#Creating edge links for num_node
for {set i 0} {$i < $num_node/2} {incr i} {
    set speed [expr round([$RND uniform 1 50])]
    $ns duplex-link $node_router $node_($i) [expr $speed]Mb 5ms DropTail
}
for {set i [expr ($num_node/2)]} {$i < $num_node} {
    incr i} {
    set speed [expr round([$RND uniform 50 100])]
    puts $speed
    $ns duplex-link $node_router $node_($i) [expr $speed]Mb 5ms DropTail
}
#Creating the network link
$ns duplex-link $node_server $node_router 10Mb 5ms DropTail
set fq [[$ns link $node_server $node_router] queue]
$fq set limit_ 20
$fq set queue_in_bytes_ true
$fq set mean_pktsize_ 1000
#Open the trace files
set tfile_ [open out.tr w]
set clink [$ns link $node_server $node_router]
$clink trace $ns $tfile_
#Setup Goddard Streaming[expr $speed]
for {set i 0} {$i < $num_node} {incr i} {
    set gs($i) [new GoddardStreaming $ns $node_server $node_($i) TCP 1000 $i]
    set goddard($i) [$gs($i) getobject goddard]
    set gplayer($i) [$gs($i) getobject gplayer]
    $gplayer($i) set upscale_interval_ 1.0
    set sfile1_ [open stream-tcp.tr w]
    $gplayer($i) attach $sfile1_
}
#Scehdule Simulation
for {set i 0} {$i < $num_node} {incr i} {
    set t [expr round([$RND uniform 1 50])]
    ##$ns at [expr 12.5 * $i] "$goddard($i) start"
    $ns at $t "$goddard($i) start"
    $ns at 200.0 "$goddard($i) stop"
}
$ns at 200.0 "finish"
#Define a 'finish' procedure
proc finish {} {
    global f0 f1 f2 nf ns
    #Close the output files
    $ns flush-trace
    close $nf
    #Call xgraph to display the results
    exec xgraph graph/out0.tr graph/out1.tr graph/out2.tr graph/out3.tr graph/out4.tr graph/out5.tr graph/out6.tr graph/out7.tr graph/out8.tr graph/out9.tr &
    exit 0
}
$ns run