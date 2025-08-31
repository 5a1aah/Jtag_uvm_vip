#=============================================================================
# Enhanced JTAG VIP Makefile
# Description: Comprehensive build system for Enhanced JTAG VIP
# Author: Enhanced JTAG VIP Team
# Date: 2024
# Version: 2.0
#=============================================================================

# Default simulator
SIM ?= questa

# Default test
TEST ?= basic_test

# Default verbosity
VERBOSITY ?= UVM_MEDIUM

# Default IEEE standard
IEEE_STANDARD ?= IEEE_1149_1_2013

# Source directories
SRC_DIR = src
TB_DIR = tb
EXAMPLES_DIR = examples
DOCS_DIR = docs

# Build directory
BUILD_DIR = build

# Coverage directory
COV_DIR = coverage

# Waveform directory
WAVE_DIR = waves

# Log directory
LOG_DIR = logs

# Common source files
COMMON_SRCS = \
	$(SRC_DIR)/jtag_vip_pkg.sv \
	$(SRC_DIR)/jtag_if.sv

# VIP source files
VIP_SRCS = \
	$(SRC_DIR)/jtag_config.svh \
	$(SRC_DIR)/jtag_sequence_item.svh \
	$(SRC_DIR)/jtag_sequencer.svh \
	$(SRC_DIR)/jtag_driver.svh \
	$(SRC_DIR)/jtag_monitor.svh \
	$(SRC_DIR)/jtag_collector.svh \
	$(SRC_DIR)/jtag_sequence_lib.svh \
	$(SRC_DIR)/jtag_protocol_checker.svh \
	$(SRC_DIR)/jtag_timing_validator.svh \
	$(SRC_DIR)/jtag_coverage_collector.svh \
	$(SRC_DIR)/jtag_performance_monitor.svh \
	$(SRC_DIR)/jtag_agent.svh \
	$(SRC_DIR)/jtag_scoreboard.svh \
	$(SRC_DIR)/jtag_error_injector.svh \
	$(SRC_DIR)/jtag_debug_dashboard.svh \
	$(SRC_DIR)/jtag_virtual_sequencer.svh \
	$(SRC_DIR)/jtag_env.svh

# Test files
TEST_SRCS = \
	$(EXAMPLES_DIR)/basic_test.sv \
	$(EXAMPLES_DIR)/boundary_scan_test.sv \
	$(EXAMPLES_DIR)/error_injection_test.sv \
	$(EXAMPLES_DIR)/compliance_test.sv

# All source files
ALL_SRCS = $(COMMON_SRCS) $(VIP_SRCS) $(TEST_SRCS)

# Simulator specific settings
ifeq ($(SIM),questa)
	COMP = vlog
	SIM_CMD = vsim
	COMP_OPTS = +incdir+$(SRC_DIR) +incdir+$(TB_DIR) +incdir+$(EXAMPLES_DIR) -sv -timescale=1ns/1ps
	SIM_OPTS = -c -do "run -all; quit -f"
	COV_OPTS = +cover=bcesf
	WAVE_OPTS = -wlf $(WAVE_DIR)/$(TEST).wlf
else ifeq ($(SIM),vcs)
	COMP = vcs
	SIM_CMD = ./simv
	COMP_OPTS = +incdir+$(SRC_DIR) +incdir+$(TB_DIR) +incdir+$(EXAMPLES_DIR) -sverilog -timescale=1ns/1ps -debug_access+all
	SIM_OPTS = +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY)
	COV_OPTS = -cm line+cond+fsm+branch+tgl
	WAVE_OPTS = -vpd $(WAVE_DIR)/$(TEST).vpd
else ifeq ($(SIM),xcelium)
	COMP = xrun
	SIM_CMD = xrun
	COMP_OPTS = +incdir+$(SRC_DIR) +incdir+$(TB_DIR) +incdir+$(EXAMPLES_DIR) -sv -timescale 1ns/1ps -access +rwc
	SIM_OPTS = +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY)
	COV_OPTS = -coverage all
	WAVE_OPTS = -input $(WAVE_DIR)/xcelium.tcl
else
	$(error Unsupported simulator: $(SIM). Supported: questa, vcs, xcelium)
endif

# UVM library path (adjust as needed)
UVM_HOME ?= /opt/uvm
UVM_OPTS = +incdir+$(UVM_HOME)/src $(UVM_HOME)/src/uvm_pkg.sv

# Test specific options
TEST_OPTS = +UVM_TESTNAME=$(TEST) +UVM_VERBOSITY=$(VERBOSITY) +IEEE_STANDARD=$(IEEE_STANDARD)

# Coverage options
COVERAGE_ENABLED ?= 1
ifeq ($(COVERAGE_ENABLED),1)
	COV_ENABLE = $(COV_OPTS)
else
	COV_ENABLE =
endif

# Wave dumping options
WAVES_ENABLED ?= 0
ifeq ($(WAVES_ENABLED),1)
	WAVE_ENABLE = $(WAVE_OPTS)
else
	WAVE_ENABLE =
endif

# Create directories
.PHONY: dirs
dirs:
	@mkdir -p $(BUILD_DIR) $(COV_DIR) $(WAVE_DIR) $(LOG_DIR)

# Default target
.PHONY: all
all: dirs compile run

# Compile target
.PHONY: compile
compile: dirs
	@echo "=== Compiling Enhanced JTAG VIP with $(SIM) ==="
	@echo "Test: $(TEST)"
	@echo "Verbosity: $(VERBOSITY)"
	@echo "IEEE Standard: $(IEEE_STANDARD)"
ifeq ($(SIM),questa)
	$(COMP) $(COMP_OPTS) $(UVM_OPTS) $(ALL_SRCS) -work $(BUILD_DIR)/work
else ifeq ($(SIM),vcs)
	$(COMP) $(COMP_OPTS) $(UVM_OPTS) $(ALL_SRCS) -o $(BUILD_DIR)/simv $(COV_ENABLE)
else ifeq ($(SIM),xcelium)
	$(COMP) $(COMP_OPTS) $(UVM_OPTS) $(ALL_SRCS) $(COV_ENABLE) -elaborate
endif
	@echo "=== Compilation completed ==="

# Run simulation
.PHONY: run
run: dirs
	@echo "=== Running $(TEST) with $(SIM) ==="
ifeq ($(SIM),questa)
	$(SIM_CMD) $(BUILD_DIR)/work.$(TEST)_tb $(SIM_OPTS) $(TEST_OPTS) $(WAVE_ENABLE) -l $(LOG_DIR)/$(TEST).log
else ifeq ($(SIM),vcs)
	$(SIM_CMD) $(SIM_OPTS) $(TEST_OPTS) $(WAVE_ENABLE) -l $(LOG_DIR)/$(TEST).log
else ifeq ($(SIM),xcelium)
	$(SIM_CMD) $(SIM_OPTS) $(TEST_OPTS) $(WAVE_ENABLE) -log $(LOG_DIR)/$(TEST).log
endif
	@echo "=== Simulation completed ==="

# Run specific tests
.PHONY: test_basic
test_basic:
	$(MAKE) TEST=basic_test run

.PHONY: test_boundary_scan
test_boundary_scan:
	$(MAKE) TEST=boundary_scan_test run

.PHONY: test_error_injection
test_error_injection:
	$(MAKE) TEST=error_injection_test run

.PHONY: test_compliance
test_compliance:
	$(MAKE) TEST=compliance_test run

# Run all tests
.PHONY: test_all
test_all: test_basic test_boundary_scan test_error_injection test_compliance
	@echo "=== All tests completed ==="

# IEEE standard specific tests
.PHONY: test_ieee_1149_1
test_ieee_1149_1:
	$(MAKE) TEST=compliance_test IEEE_STANDARD=IEEE_1149_1_2013 run

.PHONY: test_ieee_1149_4
test_ieee_1149_4:
	$(MAKE) TEST=compliance_test IEEE_STANDARD=IEEE_1149_4 run

.PHONY: test_ieee_1149_6
test_ieee_1149_6:
	$(MAKE) TEST=compliance_test IEEE_STANDARD=IEEE_1149_6 run

# Coverage targets
.PHONY: coverage
coverage:
	$(MAKE) COVERAGE_ENABLED=1 all
	@echo "=== Generating coverage report ==="
ifeq ($(SIM),questa)
	vcover report -html -htmldir $(COV_DIR)/html $(BUILD_DIR)/coverage.ucdb
else ifeq ($(SIM),vcs)
	urg -dir $(BUILD_DIR)/simv.vdb -report $(COV_DIR)
else ifeq ($(SIM),xcelium)
	imc -load $(BUILD_DIR)/cov_work/scope/test -execcmd "report -html -out $(COV_DIR)/html"
endif
	@echo "=== Coverage report generated in $(COV_DIR) ==="

# Regression testing
.PHONY: regression
regression: dirs
	@echo "=== Running regression tests ==="
	$(MAKE) test_all COVERAGE_ENABLED=1
	@echo "=== Regression completed ==="

# Performance testing
.PHONY: performance
performance:
	@echo "=== Running performance tests ==="
	$(MAKE) TEST=basic_test VERBOSITY=UVM_LOW run
	$(MAKE) TEST=boundary_scan_test VERBOSITY=UVM_LOW run
	@echo "=== Performance testing completed ==="

# Stress testing
.PHONY: stress
stress:
	@echo "=== Running stress tests ==="
	$(MAKE) TEST=error_injection_test VERBOSITY=UVM_LOW run
	@echo "=== Stress testing completed ==="

# Debug with waves
.PHONY: debug
debug:
	$(MAKE) WAVES_ENABLED=1 VERBOSITY=UVM_HIGH run

# Lint checking
.PHONY: lint
lint:
	@echo "=== Running lint checks ==="
ifeq ($(SIM),questa)
	vlog -lint $(COMP_OPTS) $(ALL_SRCS)
else ifeq ($(SIM),vcs)
	vlogan -lint $(COMP_OPTS) $(ALL_SRCS)
else ifeq ($(SIM),xcelium)
	xrun -elaborate -lint $(COMP_OPTS) $(ALL_SRCS)
endif
	@echo "=== Lint checking completed ==="

# Syntax checking
.PHONY: syntax
syntax:
	@echo "=== Running syntax checks ==="
ifeq ($(SIM),questa)
	vlog -sv $(COMP_OPTS) $(ALL_SRCS) -work $(BUILD_DIR)/syntax_work
else ifeq ($(SIM),vcs)
	vlogan -sv $(COMP_OPTS) $(ALL_SRCS)
else ifeq ($(SIM),xcelium)
	xrun -compile $(COMP_OPTS) $(ALL_SRCS)
endif
	@echo "=== Syntax checking completed ==="

# Documentation generation
.PHONY: docs
docs:
	@echo "=== Generating documentation ==="
	@if command -v doxygen >/dev/null 2>&1; then \
		doxygen Doxyfile; \
		echo "Documentation generated in docs/html"; \
	else \
		echo "Doxygen not found. Please install doxygen to generate documentation."; \
	fi

# Clean targets
.PHONY: clean
clean:
	@echo "=== Cleaning build artifacts ==="
	rm -rf $(BUILD_DIR)/* $(LOG_DIR)/* $(WAVE_DIR)/*
	@echo "=== Clean completed ==="

.PHONY: clean_all
clean_all: clean
	@echo "=== Cleaning all generated files ==="
	rm -rf $(BUILD_DIR) $(COV_DIR) $(WAVE_DIR) $(LOG_DIR)
	rm -f *.log *.wlf *.vpd *.vcd *.fsdb
	rm -f transcript vsim.wlf
	rm -rf work
	@echo "=== Deep clean completed ==="

# Help target
.PHONY: help
help:
	@echo "Enhanced JTAG VIP Makefile Help"
	@echo "================================"
	@echo ""
	@echo "Usage: make [target] [options]"
	@echo ""
	@echo "Main Targets:"
	@echo "  all              - Compile and run default test"
	@echo "  compile          - Compile the VIP"
	@echo "  run              - Run simulation"
	@echo "  clean            - Clean build artifacts"
	@echo "  clean_all        - Deep clean all generated files"
	@echo "  help             - Show this help"
	@echo ""
	@echo "Test Targets:"
	@echo "  test_basic       - Run basic functionality test"
	@echo "  test_boundary_scan - Run boundary scan test"
	@echo "  test_error_injection - Run error injection test"
	@echo "  test_compliance  - Run IEEE compliance test"
	@echo "  test_all         - Run all tests"
	@echo ""
	@echo "IEEE Standard Tests:"
	@echo "  test_ieee_1149_1 - Test IEEE 1149.1 compliance"
	@echo "  test_ieee_1149_4 - Test IEEE 1149.4 compliance"
	@echo "  test_ieee_1149_6 - Test IEEE 1149.6 compliance"
	@echo ""
	@echo "Quality Targets:"
	@echo "  coverage         - Run with coverage collection"
	@echo "  regression       - Run regression test suite"
	@echo "  performance      - Run performance tests"
	@echo "  stress           - Run stress tests"
	@echo "  lint             - Run lint checks"
	@echo "  syntax           - Run syntax checks"
	@echo "  debug            - Run with waveforms and high verbosity"
	@echo ""
	@echo "Documentation:"
	@echo "  docs             - Generate documentation"
	@echo ""
	@echo "Options:"
	@echo "  SIM=<simulator>  - Simulator to use (questa, vcs, xcelium)"
	@echo "  TEST=<test>      - Test to run (basic_test, boundary_scan_test, etc.)"
	@echo "  VERBOSITY=<level> - UVM verbosity (UVM_LOW, UVM_MEDIUM, UVM_HIGH)"
	@echo "  IEEE_STANDARD=<std> - IEEE standard (IEEE_1149_1_2013, IEEE_1149_4, IEEE_1149_6)"
	@echo "  COVERAGE_ENABLED=<0|1> - Enable coverage collection"
	@echo "  WAVES_ENABLED=<0|1>    - Enable waveform dumping"
	@echo ""
	@echo "Examples:"
	@echo "  make SIM=questa TEST=basic_test"
	@echo "  make test_compliance IEEE_STANDARD=IEEE_1149_4"
	@echo "  make coverage SIM=vcs"
	@echo "  make debug TEST=error_injection_test"
	@echo "  make regression SIM=xcelium"
	@echo ""

# Version information
.PHONY: version
version:
	@echo "Enhanced JTAG VIP v2.0"
	@echo "Build System: GNU Make"
	@echo "Supported Simulators: Questa, VCS, Xcelium"
	@echo "Supported Standards: IEEE 1149.1, IEEE 1149.4, IEEE 1149.6"

# Environment check
.PHONY: env_check
env_check:
	@echo "=== Environment Check ==="
	@echo "Current simulator: $(SIM)"
	@echo "UVM_HOME: $(UVM_HOME)"
	@echo "Test: $(TEST)"
	@echo "Verbosity: $(VERBOSITY)"
	@echo "IEEE Standard: $(IEEE_STANDARD)"
	@echo "Coverage enabled: $(COVERAGE_ENABLED)"
	@echo "Waves enabled: $(WAVES_ENABLED)"
	@echo "========================="

# Quick test (basic functionality)
.PHONY: quick
quick:
	$(MAKE) TEST=basic_test VERBOSITY=UVM_LOW run

# Full test (all features)
.PHONY: full
full:
	$(MAKE) test_all COVERAGE_ENABLED=1 VERBOSITY=UVM_MEDIUM

# Continuous integration target
.PHONY: ci
ci: clean syntax lint regression
	@echo "=== CI pipeline completed ==="

# Development target (quick iteration)
.PHONY: dev
dev:
	$(MAKE) compile
	$(MAKE) quick

# Show file list
.PHONY: files
files:
	@echo "=== Source Files ==="
	@echo "Common sources:"
	@for file in $(COMMON_SRCS); do echo "  $$file"; done
	@echo "VIP sources:"
	@for file in $(VIP_SRCS); do echo "  $$file"; done
	@echo "Test sources:"
	@for file in $(TEST_SRCS); do echo "  $$file"; done

# Check dependencies
.PHONY: deps
deps:
	@echo "=== Checking Dependencies ==="
	@echo "Checking for $(SIM)..."
	@which $(COMP) >/dev/null 2>&1 && echo "✓ $(COMP) found" || echo "✗ $(COMP) not found"
ifeq ($(SIM),questa)
	@which vsim >/dev/null 2>&1 && echo "✓ vsim found" || echo "✗ vsim not found"
else ifeq ($(SIM),vcs)
	@which vcs >/dev/null 2>&1 && echo "✓ vcs found" || echo "✗ vcs not found"
else ifeq ($(SIM),xcelium)
	@which xrun >/dev/null 2>&1 && echo "✓ xrun found" || echo "✗ xrun not found"
endif
	@echo "Checking UVM..."
	@test -d "$(UVM_HOME)" && echo "✓ UVM found at $(UVM_HOME)" || echo "✗ UVM not found at $(UVM_HOME)"
	@echo "========================="