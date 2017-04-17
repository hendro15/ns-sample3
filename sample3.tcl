set val(rp)     DSR ;#routing protocol (DIFFUSION/RATE, DIFFUSION/PROB, DSDV, DSR, FLOODING, OMNIMCAST, AODV, TORA, M-DART, PUMA)
set val(chan)   Channel/WirelessChannel
set val(prop)   Propagation/TwoRayGround
set val(netif)  Phy/WirelessPhy
set val(mac)    Mac/802_11
set val(ifq)    Queue/DropTail/PriQueue
set val(ll)     LL
set val(ant)    Antenna/OmniAntenna
set val(x)              1000   ;# X dimension of the topography
set val(y)              1000   ;# Y dimension of the topography
set val(ifqlen)         50            ;# max packet in ifq
set val(seed)           0.0
set val(nn)             20             ;# how many nodes are simulated
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
                set node_($i) [$ns_ node]
                # $node_($i) random-motion 0       ;# disable random motion
        } 

# set color
$node_(0) color "#FF0000"

for {set i 0} {$i < $val(nn)} {incr i} {
    $node_($i) set X_ [expr rand()*500]
    $node_($i) set Y_ [expr rand()*500]
    $node_($i) set Z_ 0
}

# set label
$ns_ at 0.0 "$node_(0) label Sender"
$ns_ at 0.0 "$node_(10) label Sender"
$ns_ at 0.0 "$node_(1) label Receiver"
$ns_ at 0.0 "$node_(11) label Receiver"

# Generate movements and speed
for {set i 0} {$i < $val(nn)} {incr i} {
	set x_ [expr rand()*$val(x)]
	set y_ [expr rand()*$val(y)]
	set rng_time [expr rand()*$val(stop)]
	set mov_speed_ [expr rand()*$val(speed)]
	$ns_ at $rng_time "$node_($i) setdest $x_ $y_ $mov_speed_"
}

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
$ns_ at 5.0 "$ftp start" 

set tcp1 [new Agent/TCP]
$tcp1 set class_ 2
set sink1 [new Agent/TCPSink]
$ns_ attach-agent $node_(0) $tcp1
$ns_ attach-agent $node_(11) $sink1
$ns_ connect $tcp1 $sink1
set ftp1 [new Application/FTP]
$ftp1 attach-agent $tcp1
$ns_ at 7.0 "$ftp1 start"

set tcp2 [new Agent/TCP]
$tcp2 set class_ 2
set sink2 [new Agent/TCPSink]
$ns_ attach-agent $node_(10) $tcp2
$ns_ attach-agent $node_(11) $sink2
$ns_ connect $tcp2 $sink2
set ftp2 [new Application/FTP]
$ftp2 attach-agent $tcp2
$ns_ at 10.0 "$ftp2 start"

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
exec xgraph sample.tr -geometry 1000*1000
exit 0
}

puts "Starting Simulation..."
$ns_ run