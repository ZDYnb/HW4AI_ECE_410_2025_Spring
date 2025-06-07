# MAC单元测试Makefile

# 仿真器设置
SIM ?= icarus

# Verilog源文件
VERILOG_SOURCES = mac_unit.v

# 顶层模块
TOPLEVEL = mac_unit

# Python测试模块
MODULE = mac_unit_test

# 包含cocotb makefile
include $(shell cocotb-config --makefiles)/Makefile.sim

# 清理
clean::
	rm -rf __pycache__
	rm -rf sim_build
	rm -f results.xml
	rm -f *.vcd

# 运行特定测试
test_basic:
	$(MAKE) TESTCASE=test_mac_basic

test_accumulate:
	$(MAKE) TESTCASE=test_mac_accumulate

test_negative:
	$(MAKE) TESTCASE=test_mac_negative

test_control:
	$(MAKE) TESTCASE=test_mac_enable_clear

test_overflow:
	$(MAKE) TESTCASE=test_mac_overflow

# 帮助
help:
	@echo "可用测试:"
	@echo "  make              - 运行所有测试"
	@echo "  make test_basic   - 基本功能测试"
	@echo "  make test_accumulate - 累加测试"
	@echo "  make test_negative - 负数测试"
	@echo "  make test_control - 控制信号测试"
	@echo "  make test_overflow - 溢出测试"
	@echo "  make clean        - 清理文件"

.PHONY: clean help test_basic test_accumulate test_negative test_control test_overflow