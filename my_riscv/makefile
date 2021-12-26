VCS	=	vcs

SIMV	=	./simv

x:	comp run 

comp:
	$(VCS) -sverilog tb_riscv_pipeline.sv -kdb -debug_all -lca
run:
	$(SIMV) -gui=verdi

clean:
	rm -rf DVEfiles opendatabase.log simpleadder.dump.vpd csrc simpleadder.dump simv simv.daidir ucli.key .inter.vpd.uvm *.fsdb
