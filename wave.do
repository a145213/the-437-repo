onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /system_tb/CLK
add wave -noupdate /system_tb/nRST
add wave -noupdate /system_tb/DUT/CPU/DP/pcif/PC_WEN
add wave -noupdate /system_tb/DUT/CPU/DP/pcif/pc_input
add wave -noupdate /system_tb/DUT/CPU/DP/pcif/pc_output
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/opcode
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/funct
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/halt
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/iREN
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/dWEN
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/dREN
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/RegDst
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/MemToReg
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/shamt
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/PCSrc
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/ALUSrc
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/Jal
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/Jump
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/RegWrite
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/MemWrite
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/MemRead
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/ExtOp
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/alu_zero
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/PC_WEN
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/alu_op
add wave -noupdate /system_tb/DUT/CPU/DP/cuif/overflow
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {0 ps} 0}
quietly wave cursor active 0
configure wave -namecolwidth 150
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {1310739050 ps} {1310740050 ps}
