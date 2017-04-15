set val(rp)     DSDV
set val(chan)   Channel/WirelessChannel
set val(prop)   Propagation/TwoRayGround
set val(netif)  Phy/WirelessPhy
set val(mac)    Mac/802_11
set val(ifq)    Queue/DropTail/PriQueue
set val(ll)     LL
set val(ant)    Antenna/OmniAntenna
set val(x)              670   ;# X dimension of the topography
set val(y)              670   ;# Y dimension of the topography
set val(ifqlen)         50            ;# max packet in ifq
set val(seed)           0.0
set val(adhocRouting)   DSR
set val(nn)             50             ;# how many nodes are simulated
set val(stop)           2000.0           ;# simulation time
set val(speed)			25.0


set ns_    [new Simulator]
set tracefd     [open simple.tr w]
set namtrace    [open sample-out.nam w]

$ns_ trace-all $tracefd           
$ns_ namtrace-all-wireless $namtrace $val(x) $val(y)
set topo	[new Topography]
$topo load_flatgrid $val(x) $val(y)
create-god $val(nn)

#Configure nodes
$ns_ node-config -adhocRouting $val(rp) \
                         -llType $val(ll) \
                         -macType $val(mac) \
                         -ifqType $val(ifq) \
                         -ifqLen $val(ifqlen) \
                         -antType $val(ant) \
                         -propType $val(prop) \
                         -phyType $val(netif) \
                         -topoInstance $topo \
                         -channelType $val(chan) \
                         -agentTrace ON \
                         -routerTrace ON \
                         -macTrace OFF \
                         -movementTrace OFF

for {set i 0} {$i < $val(nn) } {incr i} {
                set node_($i) [$ns_ node ]
                $node_($i) random-motion 1       ;# disable random motion
        } 

for {set i 0} {$i < $val(nn)} {incr i} {
    $node_($i) set X_ [expr rand()*500]
    $node_($i) set Y_ [expr rand()*400]
    $node_($i) set Z_ 0
}

# set label
$ns_ at 0.0 "$node_(0) label Receiver"
$ns_ at 0.0 "$node_(1) label Sender"

# Generate movements and speed
for {set i 0} {$i < $val(nn)} {incr i} {
	set x_ [expr rand()*$val(x)]
	set y_ [expr rand()*$val(y)]
	set rng_time [expr rand()*$val(stop)]
	set mov_speed_ [expr rand()*$val(speed)]
	$ns_ at $rng_time "$node_($i) setdest $x_ $y_ $mov_speed_"
	# $ns_ at $rng_time "$node_($i) setdest $xx_ $yy_ 15.0"
}

# Node_(1) starts to move towards node_(0)
# $ns_ at 50.0 "$node_(1) setdest 25.0 20.0 15.0"
# $ns_ at 10.0 "$node_(0) setdest 20.0 18.0 1.0"

# Node_(1) then starts to move away from node_(0)
# $ns_ at 100.0 "$node_(1) setdest 490.0 480.0 15.0" 
# $ns_ at 50.0 "$node_(2) setdest 369 170 3"

# Define node initial position in nam
for {set i 0} {$i < $val(nn)} {incr i} {

        # 20 defines the node size in nam, must adjust it according to your
        # scenario size.
        # The function must be called after mobility model is defined
        $ns_ initial_node_pos $node_($i) 40
}  

# set TCP connections between node_(0) and node_(1)
set tcp [new Agent/TCP]
$tcp set class_ 2
set sink [new Agent/TCPSink]
$ns_ attach-agent $node_(0) $tcp
$ns_ attach-agent $node_(1) $sink
$ns_ connect $tcp $sink
set ftp [new Application/FTP]
$ftp attach-agent $tcp
$ns_ at 10.0 "$ftp start" 

# Tell nodes when the simulation ends
for {set i 0} {$i < $val(nn) } {incr i} {
    $ns_ at 150.0 "$node_($i) reset";
}
$ns_ at 150.0001 "stop"
$ns_ at 150.0002 "puts \"NS EXITING...\" ; $ns_ halt"
proc stop {} {
    global ns_ tracefd namtrace
    $ns_ flush-trace
    close $tracefd
    close $namtrace
    exec nam sample-out.nam &
}

proc finish {} {
exec xgraph simple.tr -geometry 1000*1000
exit 0
}

puts "Starting Simulation..."
$ns_ run