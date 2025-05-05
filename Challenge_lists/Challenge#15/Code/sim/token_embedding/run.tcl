vlib work
vlog ../../rtl/token_embedding.v ../../tb/tb_token_embedding.v
vsim -c tb_token_embedding -do "run 100ns; quit"

