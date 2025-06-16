# SPI接口cocotb测试Makefile

# 顶层模块
TOPLEVEL = spi_test_wrapper

# Verilog源文件
VERILOG_SOURCES = spi_transformer_interface.v spi_test_wrapper.v

# Python测试模块
MODULE = test_spi

# 仿真器选择（icarus比verilator宽容）
SIM ?= icarus

# Icarus特定选项
ifeq ($(SIM), icarus)
    COMPILE_ARGS += -g2012
    SIM_ARGS += -fst
endif

# Verilator特定选项（备用）
ifeq ($(SIM), verilator)
    COMPILE_ARGS += --trace --trace-structs
    COMPILE_ARGS += -Wno-PINMISSING
    COMPILE_ARGS += -Wno-BLKANDNBLK
    COMPILE_ARGS += -Wno-WIDTHTRUNC
    COMPILE_ARGS += -Wno-CMPCONST
    COMPILE_ARGS += -Wno-WIDTHEXPAND
    COMPILE_ARGS += -Wno-CASEINCOMPLETE
endif

# 测试选项
COCOTB_LOG_LEVEL ?= INFO
RANDOM_SEED ?= 12345

# 波形文件
WAVES ?= waves.vcd

# 包含cocotb的Makefile（必须在自定义目标之前）
include $(shell cocotb-config --makefiles)/Makefile.sim

# 快速测试（只运行基础测试）
test-quick:
	@echo "运行快速SPI测试..."
	$(MAKE) SIM=$(SIM) TESTCASE=test_spi_basic

# 完整测试（包括矩阵测试）  
test-full:
	@echo "运行完整SPI测试..."
	export FULL_TEST=1 && $(MAKE) SIM=$(SIM)

# 调试模式（生成波形）
test-debug:
	@echo "调试模式运行..."
	$(MAKE) SIM=$(SIM) WAVES=1 COCOTB_LOG_LEVEL=DEBUG

# 查看波形（需要安装gtkwave）
view-waves:
	gtkwave $(WAVES) &

# 帮助
help:
	@echo "可用的测试目标："
	@echo "  test-quick  - 快速基础功能测试"
	@echo "  test-full   - 完整矩阵功能测试"  
	@echo "  test-debug  - 调试模式（生成波形）"
	@echo "  clean       - 清理临时文件"
	@echo "  view-waves  - 查看波形文件"
	@echo ""
	@echo "仿真器选项："
	@echo "  SIM=verilator  - 使用Verilator（快速）"
	@echo "  SIM=icarus     - 使用Icarus Verilog"
	@echo "  SIM=questa     - 使用Questa"

.PHONY: test-quick test-full test-debug view-waves help