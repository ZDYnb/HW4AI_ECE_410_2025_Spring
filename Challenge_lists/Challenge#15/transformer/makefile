# Makefile for spi_top模块cocotb测试

# 设置仿真器 (可以选择 icarus, verilator, modelsim 等)
SIM ?= icarus

# Verilog源文件
VERILOG_SOURCES = spi_top.v

# 顶层模块名
TOPLEVEL = spi_top

# Python测试模块
MODULE = test_runner

# cocotb设置
COCOTB_REDUCED_LOG_FMT = 1

# 包含cocotb的makefile
include $(shell cocotb-config --makefiles)/Makefile.sim

# 清理目标
clean::
	rm -rf __pycache__
	rm -rf sim_build
	rm -f results.xml
	rm -f *.vcd
	rm -f *.fst

# 帮助信息
help:
	@echo "可用的make目标:"
	@echo "  make               - 运行所有测试 (使用icarus仿真器)"
	@echo "  make SIM=verilator - 使用Verilator仿真器"
	@echo "  make SIM=modelsim  - 使用ModelSim仿真器"
	@echo "  make clean         - 清理生成的文件"
	@echo "  make waves         - 使用GTKWave查看波形"
	@echo "  make quick         - 快速基本功能测试"
	@echo "  make matrix        - 运行所有矩阵显示测试"
	@echo "  make matrix_pattern- 测试有规律的16x16矩阵"
	@echo "  make matrix_random - 测试随机16x16矩阵"
	@echo "  make matrix_edge   - 测试边界情况矩阵"
	@echo ""
	@echo "环境变量:"
	@echo "  SIM=<simulator>    - 选择仿真器 (icarus/verilator/modelsim)"
	@echo "  GUI=1              - 启用图形界面 (适用于支持的仿真器)"

# 查看波形 (需要安装GTKWave)
waves:
	@if [ -f dump.vcd ]; then \
		gtkwave dump.vcd &; \
	else \
		echo "没有找到波形文件 dump.vcd"; \
		echo "请先运行测试生成波形文件"; \
	fi

# 快速测试 (只运行基本功能测试)
quick:
	$(MAKE) MODULE=test_runner TESTCASE=test_basic_functionality

# 矩阵显示测试
matrix:
	$(MAKE) MODULE=matrix_display_test

# 只测试有规律的矩阵
matrix_pattern:
	$(MAKE) MODULE=matrix_display_test TESTCASE=test_matrix_display

# 只测试随机矩阵  
matrix_random:
	$(MAKE) MODULE=matrix_display_test TESTCASE=test_random_matrix

# 只测试边界情况
matrix_edge:
	$(MAKE) MODULE=matrix_display_test TESTCASE=test_edge_cases

# 详细模式 (显示更多调试信息)
verbose:
	$(MAKE) COCOTB_LOG_LEVEL=DEBUG

.PHONY: clean help waves quick verbose