`timescale 1ns / 1ps

module memory#(
        parameter DATA_WIDTH = 32,
        parameter MEM_DEPTH  = 150
)(
    input    wr_clk,
    input    rd_clk,
    input    wr_en_i,
    input    [DATA_WIDTH-1:0]wr_data_i,
    input    [($clog2(MEM_DEPTH))-1:0]wr_addr_i,
    input    [($clog2(MEM_DEPTH))-1:0]rd_addr_i,
    input    rd_en_i,
    output reg[DATA_WIDTH-1:0]rd_data_o
    );
    (* ram_style = "block" *)
    reg [DATA_WIDTH-1:0]bram[MEM_DEPTH-1:0];
    
    always@(posedge wr_clk)begin
        if(wr_en_i)begin
            bram[wr_addr_i] <= wr_data_i;
        end
    end
    
    always@(posedge rd_clk)begin
        if(rd_en_i)begin
            rd_data_o  <= bram[rd_addr_i];
        end
    end
    
endmodule
