# SPI interface cocotb test Makefile

# Top-level module
TOPLEVEL = spi_test_wrapper

# Verilog source files
VERILOG_SOURCES = spi_transformer_interface.v spi_test_wrapper.v

# Python test module
MODULE = test_spi

# Simulator selection (icarus is more permissive than verilator)
SIM ?= icarus

# Icarus-specific options
ifeq ($(SIM), icarus)
	COMPILE_ARGS += -g2012
	SIM_ARGS += -fst
endif

# Verilator-specific options (alternative)
ifeq ($(SIM), verilator)
	COMPILE_ARGS += --trace --trace-structs
	COMPILE_ARGS += -Wno-PINMISSING
	COMPILE_ARGS += -Wno-BLKANDNBLK
	COMPILE_ARGS += -Wno-WIDTHTRUNC
	COMPILE_ARGS += -Wno-CMPCONST
	COMPILE_ARGS += -Wno-WIDTHEXPAND
	COMPILE_ARGS += -Wno-CASEINCOMPLETE
endif

# Test options
COCOTB_LOG_LEVEL ?= INFO
RANDOM_SEED ?= 12345

# Waveform file
WAVES ?= waves.vcd

# Include cocotb's Makefile (must be before custom targets)
include $(shell cocotb-config --makefiles)/Makefile.sim

# Quick test (run only basic test)
test-quick:
	@echo "Running quick SPI test..."
	$(MAKE) SIM=$(SIM) TESTCASE=test_spi_basic

# Full test (including matrix test)
test-full:
	@echo "Running full SPI test..."
	export FULL_TEST=1 && $(MAKE) SIM=$(SIM)

# Debug mode (generate waveform)
test-debug:
	@echo "Running in debug mode..."
	$(MAKE) SIM=$(SIM) WAVES=1 COCOTB_LOG_LEVEL=DEBUG

# View waveform (requires gtkwave)
view-waves:
	gtkwave $(WAVES) &

# Help
help:
	@echo "Available test targets:"
	@echo "  test-quick  - Quick basic functionality test"
	@echo "  test-full   - Full matrix functionality test"
	@echo "  test-debug  - Debug mode (generate waveform)"
	@echo "  clean       - Clean temporary files"
	@echo "  view-waves  - View waveform file"
	@echo ""
	@echo "Simulator options:"
	@echo "  SIM=verilator  - Use Verilator (fast)"
	@echo "  SIM=icarus     - Use Icarus Verilog"
	@echo "  SIM=questa     - Use Questa"

.PHONY: test-quick test-full test-debug view-waves help