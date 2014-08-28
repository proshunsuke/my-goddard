#NS simulator object
set ns [new Simulator]

#Set random seed
global defaultRNG
$defaultRNG seed 15

set gate_node(1) [$ns node]
set gate_node(2) [$ns node]
set gate_node(3) [$ns node]

set another_gate_node(1) [$ns node]
set another_gate_node(2) [$ns node]
set another_gate_node(3) [$ns node]

set semi_gate_node(1) [$ns node]
set semi_gate_node(1) [$ns node]
set semi_gate_node(1) [$ns node]

set digest_node(1) [$ns node]
set digest_node(2) [$ns node]
set digest_node(3) [$ns node]

set nomal_node(1) [$ns node]

# ゲートノード同士をつなぐ
for {set i 0} {$i < 3} {incr i} {
    for {set j 0} {$j < 3} {incr j} {
        $ns duplex-link $gate_node(i) $another_gate_node(j) 10mb 5ms DropTail
    }
}

for {set i 0} {$i < 3} {incr i} {
    $ns simplex-link $gate_node(i) $semi_gate_node(i) 7mb 10ms DropTail
}

$ns duplex-link $semi_gate_node(1) $digest_node(1) 5mb 10ms DropTail

$ns duplex-link $semi_gate_node(2) $nomal_node(1) 3mb 10ms DropTail
$ns duplex-link $semi_gate_node(2) $digest_node(2) 5mb 10ms DropTail

$ns duplex-link $semi_gate_node(3) $nomal_node(1) 3mb 10ms DropTail
$ns duplex-link $semi_gate_node(2) $digest_node(3) 5mb 10ms DropTail

$ns duplex-link $digest_node(3) $nomal_node(1) 4mb 10ms DropTail




