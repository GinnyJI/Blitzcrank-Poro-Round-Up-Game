vlib work
vlog arm_gu.v
vsim blitz_arm_gu 
log {/*}
add wave {/*}
add wave -position insertpoint sim:/blitz_arm_gu/f1/*

force {clk} 0 0, 1 1ns -r 2ns

force {resetn} 0
force {plot} 0
#72
force {x_in[0]} 0
force {x_in[1]} 0
force {x_in[2]} 0
force {x_in[3]} 1
force {x_in[4]} 0
force {x_in[5]} 0
force {x_in[6]} 1
force {x_in[7]} 0
force {x_in[8]} 0
#42
force {y_in[0]} 0
force {y_in[1]} 1
force {y_in[2]} 0
force {y_in[3]} 1
force {y_in[4]} 0
force {y_in[5]} 1
force {y_in[6]} 0
force {y_in[7]} 0
run 20ns

force {resetn} 1
force {plot} 1
run 20000ns
