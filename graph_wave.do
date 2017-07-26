vlib work 
vlog graph.v poro_gu.v poro.v blitzcrank.v blitz_gu.v background_gu.v hook_gu.v arm_gu.v  grab_check.v poro_image.v 
vsim graph

vsim -L  altera_mf_ver  -L  altera_mf mymem

log {/*}
add wave {/*}

force {CLOCK_50} 0 0, 1 1ns -r 2ns

force {SW[0]}  1

force {KEY[0]} 0
force {KEY[1]} 1
force {KEY[2]} 1
force {KEY[3]} 1
run 2ns

force {KEY[0]} 0
force {KEY[1]} 1
force {KEY[2]} 0
force {KEY[3]} 1
run 116ns

force {KEY[0]} 1
force {KEY[1]} 0
force {KEY[2]} 1
force {KEY[3]} 1
run 2000ns
