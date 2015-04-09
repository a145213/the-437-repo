add wave -position insertpoint -group TB sim:/system_tb/*
add wave -position insertpoint -group RAM  sim:/system_tb/DUT/RAM/ramif/*
add wave -position insertpoint -group RAM sim:/system_tb/DUT/RAM/count
add wave -position insertpoint -group RAM sim:/system_tb/DUT/RAM/addr
add wave -position insertpoint -group CCIF sim:/system_tb/DUT/CPU/CC/ccif/*
add wave -position insertpoint -group CCIF sim:/system_tb/DUT/CPU/CC/*

# Core 0
add wave -position insertpoint -group CM0 sim:/system_tb/DUT/CPU/CM0/*
add wave -position insertpoint -group IC0 sim:/system_tb/DUT/CPU/CM0/ICACHE/*
add wave -position insertpoint -group IC0 sim:/system_tb/DUT/CPU/CM0/ICACHE/sets
add wave -position insertpoint -group DC0 sim:/system_tb/DUT/CPU/CM0/DCACHE/*
add wave -position insertpoint -group DC0 sim:/system_tb/DUT/CPU/CM0/DCACHE/sets
add wave -position insertpoint -group DCIF0 sim:/system_tb/DUT/CPU/dcif0/*
add wave -position insertpoint -group DP0 sim:/system_tb/DUT/CPU/DP0/*
add wave -position insertpoint -group DP0 sim:/system_tb/DUT/CPU/DP0/dpif/*
add wave -position insertpoint -group PCIF0 sim:/system_tb/DUT/CPU/DP0/pcif/*
add wave -position insertpoint -group CU0 sim:/system_tb/DUT/CPU/DP0/cuif/*
add wave -position insertpoint -group ALU0 sim:/system_tb/DUT/CPU/DP0/ALU/aluif/*
add wave -position insertpoint -group RFIF0 sim:/system_tb/DUT/CPU/DP0/RF/rfif/*
add wave -position insertpoint -group RFIF0 sim:/system_tb/DUT/CPU/DP0/RF/register
add wave -position insertpoint -group HUIF0 sim:/system_tb/DUT/CPU/DP0/huif/*
add wave -position insertpoint -group FDIF0 sim:/system_tb/DUT/CPU/DP0/fdif/*
add wave -position insertpoint -group DEIF0 sim:/system_tb/DUT/CPU/DP0/deif/*
add wave -position insertpoint -group EMIF0 sim:/system_tb/DUT/CPU/DP0/emif/*
add wave -position insertpoint -group MWIF0 sim:/system_tb/DUT/CPU/DP0/mwif/*

# Core 1
add wave -position insertpoint -group CM1 sim:/system_tb/DUT/CPU/CM1/*
add wave -position insertpoint -group IC1 sim:/system_tb/DUT/CPU/CM1/ICACHE/*
add wave -position insertpoint -group IC1 sim:/system_tb/DUT/CPU/CM1/ICACHE/sets
add wave -position insertpoint -group DC1 sim:/system_tb/DUT/CPU/CM1/DCACHE/*
add wave -position insertpoint -group DC1 sim:/system_tb/DUT/CPU/CM1/DCACHE/sets
add wave -position insertpoint -group DCIF1 sim:/system_tb/DUT/CPU/dcif1/*
add wave -position insertpoint -group DP1 sim:/system_tb/DUT/CPU/DP1/*
add wave -position insertpoint -group DP1 sim:/system_tb/DUT/CPU/DP1/dpif/*
add wave -position insertpoint -group PCIF1 sim:/system_tb/DUT/CPU/DP1/pcif/*
add wave -position insertpoint -group CU1 sim:/system_tb/DUT/CPU/DP1/cuif/*
add wave -position insertpoint -group ALU1 sim:/system_tb/DUT/CPU/DP1/ALU/aluif/*
add wave -position insertpoint -group RFIF1 sim:/system_tb/DUT/CPU/DP1/RF/rfif/*
add wave -position insertpoint -group RFIF1 sim:/system_tb/DUT/CPU/DP1/RF/register
add wave -position insertpoint -group HUIF1 sim:/system_tb/DUT/CPU/DP1/huif/*
add wave -position insertpoint -group FDIF1 sim:/system_tb/DUT/CPU/DP1/fdif/*
add wave -position insertpoint -group DEIF1 sim:/system_tb/DUT/CPU/DP1/deif/*
add wave -position insertpoint -group EMIF1 sim:/system_tb/DUT/CPU/DP1/emif/*
add wave -position insertpoint -group MWIF1 sim:/system_tb/DUT/CPU/DP1/mwif/*









