#-------------------------------------------------------------------------
# Synopsys VCS run script for sobel_filter UVM testbench
#-------------------------------------------------------------------------
TEST      ?= sobel_module_test
DATA_FILE ?= ./random_0_255.txt
RESULT_FILE ?= ./sobel_result.txt

VCS_OPTS = -full64 -sverilog -ntb_opts uvm-1.2 \
           -timescale=1ns/1ps -debug_access+all -kdb \
           -cm line+cond+fsm+branch+tgl+assert \
           +vcs+lic+wait

all: compile run

compile:
	vcs $(VCS_OPTS) -f filelist.f -l compile.log

run:
	./simv +UVM_TESTNAME=$(TEST) +DATA_FILE=$(DATA_FILE) +RESULT_FILE=$(RESULT_FILE) \
	       -cm line+cond+fsm+branch+tgl+assert -cm_dir ./cm_$(TEST) -l run.log

clean:
	rm -rf simv* csrc *.log *.vcd *.vpd *.fsdb DVEfiles ucli.key vc_hdrs.h \
	       .vcs_lib_lock urgReport AN.DB cm_* *.vdb

