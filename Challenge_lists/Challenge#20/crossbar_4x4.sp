* 4x4 Resistive Crossbar

* Input voltages (you can change these!)
V1 in1 0 DC 1.0
V2 in2 0 DC 0.5
V3 in3 0 DC 0.2
V4 in4 0 DC 0.8

* Row 1 connections
R11 in1 out1 1k
R12 in1 out2 1k
R13 in1 out3 1k
R14 in1 out4 1k

* Row 2 connections
R21 in2 out1 1k
R22 in2 out2 2k
R23 in2 out3 1k
R24 in2 out4 2k

* Row 3 connections
R31 in3 out1 1k
R32 in3 out2 1k
R33 in3 out3 3k
R34 in3 out4 1k

* Row 4 connections
R41 in4 out1 1k
R42 in4 out2 1k
R43 in4 out3 1k
R44 in4 out4 1k

* Dummy voltage sources to measure output current
VM1 out1 0 DC 0
VM2 out2 0 DC 0
VM3 out3 0 DC 0
VM4 out4 0 DC 0

* Simulation
.OP

* Control
.end
