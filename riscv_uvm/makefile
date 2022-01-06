UVM_HOME = /usr/synopsys/vcs-L-2016.06/etc/uvm
UVM_VERBOSITY = UVM_MEDIUM
TEST = riscv_test

VCS =	vcs -sverilog -timescale=1ns/1ns \
	+acc +vpi -PP \
	+define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR \
	+incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm.sv \
	-cm line+cond+fsm+branch+tgl -cm_dir ./coverage.vdb \
	$(UVM_HOME)/src/dpi/uvm_dpi.cc -CFLAGS -DVCS

DEBUG_VCS  =	vcs -sverilog -timescale=1ns/1ns \
	+acc +vpi -PP \
	+define+UVM_OBJECT_MUST_HAVE_CONSTRUCTOR \
	+incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm.sv \
	-cm line+cond+fsm+branch+tgl -cm_dir ./coverage.vdb \
	$(UVM_HOME)/src/dpi/uvm_dpi.cc -CFLAGS -DVCS -kdb -debug_all -lca

SIMV = ./simv +UVM_VERBOSITY=$(UVM_VERBOSITY) \
	+UVM_TESTNAME=$(TEST) +UVM_TR_RECORD +UVM_LOG_RECORD \
	+verbose=1 +ntb_random_seed=244 -l vcs.log

x:	comp run 

comp:
	$(VCS) +incdir+. riscv_tb_top.sv

run:
	$(SIMV)

debug:
	$(DEBUG_VCS) +incdir+. riscv_tb_top.sv

run_debug: 
	$(SIMV) -gui=verdi

clean:
	rm -rf coverage.vdb csrc DVEfiles inter.vpd simv simv.daidir ucli.key vc_hdrs.h vcs.log .inter.vpd.uvm