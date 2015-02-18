add wave -position insertpoint -group TB sim:/system_tb/*
add wave -position insertpoint -group CM sim:/system_tb/DUT/CPU/CM/*
add wave -position insertpoint -group CCIF sim:/system_tb/DUT/CPU/CC/ccif/*
add wave -position insertpoint -group DP sim:/system_tb/DUT/CPU/DP/*
add wave -position insertpoint -group DCIF sim:/system_tb/DUT/CPU/dcif/*
add wave -position insertpoint -group DPIF sim:/system_tb/DUT/CPU/DP/dpif/*
add wave -position insertpoint -group CUIF sim:/system_tb/DUT/CPU/DP/cuif/*
add wave -position insertpoint -group ALUIF sim:/system_tb/DUT/CPU/DP/ALU/aluif/*
add wave -position insertpoint -group RF sim:/system_tb/DUT/CPU/DP/RF/rfif/*
add wave -position insertpoint -group RF sim:/system_tb/DUT/CPU/DP/RF/register
add wave -position insertpoint -group RAMIF  sim:/system_tb/DUT/RAM/ramif/*
add wave -position insertpoint -group PCIF sim:/system_tb/DUT/CPU/DP/pcif/*
add wave -position insertpoint -group HUIF sim:/system_tb/DUT/CPU/DP/huif/*
add wave -position insertpoint -group PLIF sim:/system_tb/DUT/CPU/DP/plif/*

