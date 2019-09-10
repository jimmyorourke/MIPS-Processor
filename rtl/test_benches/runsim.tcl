# set the simulation step size as a global variable 
# step is used by both runSim and verifySim listed below 
set step 10 

proc runSimMem {} { 
   # a count of the elapsed runtime 
   set runtime 10000 
   # import the global variable step 
   global step 

   restart -force -nowave 
   add wave * 
   add wave -position insertpoint  \
sim:/main_memory/memory
add wave  \
sim:/main_memory/load_memory
  
	force -freeze enable 1 $runtime
	set i 0
	while {$i<$runtime} {
		force -freeze clock 1 $i
		force -freeze clock 0 [expr $i + $step]
		set i [expr $i + 2*$step]
	}	
	
   # run the full simulation 
   run $runtime 

   # after the simulation is complete, view the results 
   view wave 
} 