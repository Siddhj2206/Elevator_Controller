TOPLEVEL_LANG = verilog
VERILOG_SOURCES = $(PWD)/elevator_control.v
TOPLEVEL = elevator_controller
COCOTB_TEST_MODULES = main
SIM = modelsim
include $(shell cocotb-config --makefiles)/Makefile.sim
