vcom -refresh 
vsim work.mem_wb_tb -g X_FILE="SimpleAdd.x"
# reset the simulation
restart -force -nowave

# add signals to the wave file
add wave pr0c_t0p/clk
add wave pr0c_t0p/rst
add wave pr0c_t0p/reg0phile/regophile
add wave pr0c_t0p/mem0ry/dat_mem0ry/memory



# run the full simulation
run -all

# open the wave window
view wave