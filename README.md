Bitfury
=======

public git of the now open sourced Bitfury Bitstream and source code

===========================================================================
  As promised on public forums this bitstream that gained 300 Mh/s with
rolled round and anoter unrolled variant that given 270 Mh/s is disclosed
to public with first ASIC deployed that would make Spartan-based solutions
completely obsolete in short foreseable future. Author hopes that this
material still be valuable for those who are interested in advanced FPGA
usage.

  Here is brief description of source codes:

btcser - original rolled round bitstream where single core fits into 240
slices. It can be built without additional tools just with 14.2 Xilinx ISE.
With 13.2 Xilinx ISE it cannot be built and with older Xilinx ISE there
should be cumbersome path used with special XDL-level assembly tools.

duoclock_clkena, duoclock_par and sinfast are variants of unrolled cores
done in different ways. These typically would give about 250 - 270 MH/s,
theoretically they would give more performance, in practice however they
make less. There's three variants as author has not converged with final
conclusion how it is better to be done. Also good point that power
consumption per 1 Mh/s is lower with this unrolled design. So this could
be good for those whose boards cannot provide power required to run btcser.

tools - there's XDLParser.cpp/XDLParser.h/main.cpp source codes that allows
low-level manipulation of mapped / mapped+routed design, such as minor
fixing of design (altering cell values) or cloning design macros, or
generating hardmacros. 

then - how to build (example is btcser):

1) Open sha_top.ppr in PlanAhead tool.
2) Click Run button - it will assemble output sha_top.ncd file.
3) TIMING WILL NOT BE MET WITH FIRST LAUNCH! THIS IS NORMAL!
4) Then - copy sha_top.ncd and sha_top.pcf to btcser/repar subdirectory
5) rename sha_top.ncd and sha_top.pcf to s1.ncd and s1.pcf
6) run repar.sh (assuming that you have Linux OS, for windows - write .bat
   file that would launch multiple times PAR tool).
7) For Intel Core i7 2.3 Ghz it is normal to leave this step. 6 (PAR) to
   work for about 12-16 hours, it will gradually converge;
8) If result does not converge - open FPGA Editor, find traces where design
   not converged and REMOVE ALL ROUTING in 4x4 switching matrix components
   around point where convergence cannot be met and rerun PAR tool.
9) Finally you'll get s1.ncd with TIMING MET.

During testing (porting sha_top module) of course it is nonsence to run
long repar runs, so it should be avoided - first port it to your board with
your desired interface, test it on slower clocks, and then push it up using
repar step.

That's all. Hope you enjoy increased Mh/s performance. 

HOW TO UNDERSTAND SOURCES.

Best way would be to 1) read them; 2) open project in PlanAhead, get mapped
design and look carefully for block naming in PlanAhead's components and
compare them to components mentioned in source code - that way you could
capture well how placement algorithm works.
