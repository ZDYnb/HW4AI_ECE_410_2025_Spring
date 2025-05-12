TOP_MODULE = normalize
RTL_DIR = ../../rtl
SIM_CPP = sim_main.cpp

all: sim

sim: $(SIM_CPP)
	verilator -Wall -Wno-WIDTHEXPAND -Wno-UNUSEDSIGNAL --cc $(RTL_DIR)/$(TOP_MODULE).sv --exe $(SIM_CPP) -o V$(TOP_MODULE)
	make -C obj_dir -f V$(TOP_MODULE).mk V$(TOP_MODULE)
	./obj_dir/V$(TOP_MODULE)

clean:
	rm -rf obj_dir V$(TOP_MODULE)
