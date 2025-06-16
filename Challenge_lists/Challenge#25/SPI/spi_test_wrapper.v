// SPI Test Wrapper - Includes Simple Memory Model
module spi_test_wrapper (
    // System clock domain
    input wire sys_clk,         
    input wire sys_rst_n,       
    
    // SPI clock domain  
    input wire spi_cs_n,        
    input wire spi_sclk,        
    input wire spi_mosi,        
    output wire spi_miso,        
    
    // Control and status interface
    output wire matrix_valid,    
    output wire [11:0] data_count, 
    input wire read_enable,     
    
    // Debug interface
    output wire [2:0] fsm_state,
    output wire [11:0] addr_debug,
    output wire spi_active
);

    // Memory interface signals
    wire mem_we;
    wire [11:0] mem_addr;
    wire [15:0] mem_wdata;
    wire [15:0] mem_rdata;

    // SPI interface instance
    spi_transformer_interface spi_if (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .spi_cs_n(spi_cs_n),
        .spi_sclk(spi_sclk),
        .spi_mosi(spi_mosi),
        .spi_miso(spi_miso),
        .mem_we(mem_we),
        .mem_addr(mem_addr),
        .mem_wdata(mem_wdata),
        .mem_rdata(mem_rdata),
        .matrix_valid(matrix_valid),
        .data_count(data_count),
        .read_enable(read_enable),
        .fsm_state(fsm_state),
        .addr_debug(addr_debug),
        .spi_active(spi_active)
    );

    // Simple memory model
    simple_memory mem_inst (
        .clk(spi_sclk),
        .we(mem_we),
        .addr(mem_addr),
        .din(mem_wdata),
        .dout(mem_rdata)
    );

endmodule

// Simple memory module
module simple_memory (
    input wire clk,
    input wire we,
    input wire [11:0] addr,
    input wire [15:0] din,
    output reg [15:0] dout
);

    // Memory array
    reg [15:0] memory [0:4095];
    
    // Initialize memory
    integer i;
    initial begin
        for (i = 0; i < 4096; i = i + 1) begin
            memory[i] = 16'h0000;
        end
    end

    // Read/write operations - fix width warning
    always @(posedge clk) begin
        if (we && (addr <= 12'd4095)) begin  // Fix width comparison
            memory[addr] <= din;
        end
        if (addr <= 12'd4095) begin
            dout <= memory[addr];
        end else begin
            dout <= 16'h0000;  // Return 0 if out of range
        end
    end

endmodule  