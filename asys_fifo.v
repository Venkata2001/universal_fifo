`timescale 1ns / 1ps
//`define ASYNC
module asys_fifo#(
        parameter  DATA_WIDTH = 32,
        parameter  DATA_DEPTH = 128
)(
    `ifdef ASYNC 
        input       wr_clk,
        input       wr_reset_n,
        input       rd_reset_n,
        input       rd_clk,
    `else
        input       clk,
        input       reset_n, 
    `endif
    input [DATA_WIDTH-1:0]wr_data_i,
    input       wr_en_i,
    
    input       rd_en_i,
    output [DATA_WIDTH-1:0]rd_data_o,
    output       full_o,     
    output       empty_o     
    );
    
    reg [($clog2(DATA_DEPTH)):0]wr_ptr;
    reg [($clog2(DATA_DEPTH)):0]rd_ptr;
    wire full_w;
    wire empty_w;
    `ifdef ASYNC 
        wire [($clog2(DATA_DEPTH)):0]wr_ptr_gray;
        wire [($clog2(DATA_DEPTH)):0]rd_ptr_gray;
        
        wire [($clog2(DATA_DEPTH)):0]rd_ptr_sft;
        wire [($clog2(DATA_DEPTH)):0]wr_ptr_sft;
        //sync
        (* ASYNC_REG = "TRUE" *)reg [($clog2(DATA_DEPTH)):0] rd_ptr_gray_s0;
        (* ASYNC_REG = "TRUE" *)reg [($clog2(DATA_DEPTH)):0] rd_ptr_gray_s1;
        (* ASYNC_REG = "TRUE" *)reg [($clog2(DATA_DEPTH)):0] wr_ptr_gray_s0;
        (* ASYNC_REG = "TRUE" *)reg [($clog2(DATA_DEPTH)):0] wr_ptr_gray_s1;

        
        assign wr_ptr_sft = (wr_ptr >> 1);
        assign wr_ptr_gray = (wr_ptr_sft ^ wr_ptr);
        
        assign rd_ptr_sft = (rd_ptr >> 1);
        assign rd_ptr_gray = (rd_ptr_sft ^ rd_ptr);
        //wr_ptr incr
        always@(posedge wr_clk)begin
            if(!wr_reset_n)
                wr_ptr  <= 0;
            else if(wr_en_i && !full_w)
                wr_ptr <= wr_ptr + 1;            
        end
        
        //rd_ptr incr
        always@(posedge rd_clk)begin
            if(!rd_reset_n)
                rd_ptr  <= 0;
            else if(rd_en_i && !empty_w)
                rd_ptr <= rd_ptr + 1;            
        end
        
        //full condition and sync
        always@(posedge wr_clk)begin
            if(!wr_reset_n)begin
                rd_ptr_gray_s0 <= 0;
                rd_ptr_gray_s1 <= 0;
            end
            else begin
                rd_ptr_gray_s0 <= rd_ptr_gray;
                rd_ptr_gray_s1 <= rd_ptr_gray_s0;
            end
        end
        
        assign full_w =  (rd_ptr_gray_s1[($clog2(DATA_DEPTH))] != wr_ptr_gray[($clog2(DATA_DEPTH))]) &&
                           (rd_ptr_gray_s1[($clog2(DATA_DEPTH))-1] != wr_ptr_gray[($clog2(DATA_DEPTH))-1]) &&
                           (rd_ptr_gray_s1[($clog2(DATA_DEPTH))-2:0] == wr_ptr_gray[($clog2(DATA_DEPTH))-2:0]);

        
        //empty condition and sync
        always@(posedge rd_clk)begin
            if(!rd_reset_n)begin
                wr_ptr_gray_s0  <= 0;
                wr_ptr_gray_s1  <= 0;
            end
            else begin
                wr_ptr_gray_s0 <= wr_ptr_gray;
                wr_ptr_gray_s1 <= wr_ptr_gray_s0;
            end
        end
        assign empty_w = (wr_ptr_gray_s1 == rd_ptr_gray);
        assign empty_o  = empty_w;
        assign full_o   = full_w;
    `else
        always@(posedge clk)begin
            if(!reset_n)begin
                wr_ptr  <= 0;
            end
            else if(wr_en_i && !full_w)begin
                wr_ptr  <= wr_ptr + 1;
            end
        end
        
        always@(posedge clk)begin
            if(!reset_n)begin
                rd_ptr  <= 0;
            end
            else if(rd_en_i && !empty_w)begin
                rd_ptr  <= rd_ptr + 1;
            end
        end
        
        assign full_w = (wr_ptr[($clog2(DATA_DEPTH))] != rd_ptr[($clog2(DATA_DEPTH))]) &&
                        (wr_ptr[($clog2(DATA_DEPTH))-1:0] == rd_ptr[($clog2(DATA_DEPTH))-1:0]);
        assign empty_w = (wr_ptr == rd_ptr);
        assign full_o = full_w;
        assign empty_o = empty_w;
    `endif
    
    memory#(
        .DATA_WIDTH(DATA_WIDTH),
        .MEM_DEPTH(DATA_DEPTH)
    )mem(
        `ifdef ASYNC
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        `else
        .wr_clk(clk),
        .rd_clk(clk),
        `endif
        .wr_en_i(wr_en_i && !full_w),
        .wr_data_i(wr_data_i),
        .wr_addr_i(wr_ptr[($clog2(DATA_DEPTH))-1:0]),
        .rd_addr_i(rd_ptr[($clog2(DATA_DEPTH))-1:0]),
        .rd_en_i(rd_en_i && !empty_w),
        .rd_data_o(rd_data_o)
    );
    
endmodule
