#vcom -refresh 
vlog -refresh main_memory.sv fetch.sv reg_file.sv proc_top.sv writeback.sv decode.sv mem_stage.sv execute.sv pipeline_tb.sv
vsim work.pipeline_tb -g X_FILE="BubbleSort.x"
# reset the simulation
restart -force -nowave

# add signals to the wave file
add wave pr0c_t0p/clk
add wave pr0c_t0p/rst
add wave pr0c_t0p/pc_fd
add wave pr0c_t0p/insn_fd
add wave pr0c_t0p/rs_dx
add wave pr0c_t0p/rt_dx
add wave pr0c_t0p/alu_rs_val_in
add wave pr0c_t0p/alu_rt_val_in
add wave pr0c_t0p/exec_0/current_immed
add wave pr0c_t0p/alu_out_xm
add wave pr0c_t0p/alu_out_mw
add wave pr0c_t0p/rd_data

add wave pr0c_t0p/reg0phile/regophile
add wave pr0c_t0p/mem0ry/dat_mem0ry/memory



# run the full simulation
run -all

# open the wave window
view wave

echo "For SimpleAdd:"
echo "For pipelining, start at where the fetch stalls, PC=0x80020028, for the add 3+2 instruction and follow the 3 + 2 = 5 and writeback"
echo "For MX bypassing, look at the first alu_out_xm value, the next cycle shows alu_out_xm
getting the rs + current_immediate, but it is alu_out_xm bypassed back to alu_rs_val_in"
echo "For WX bypassing, in the next cycle, (1st cycle of rd_data), the add is in writeback and
bypasses rs back through alu_rs_val_in to add with rt_dx because rs_dx still not updated"
echo "Another good by pass insn 0x80020024 to insn 0x80020028 but the value being bypassed is the same value"