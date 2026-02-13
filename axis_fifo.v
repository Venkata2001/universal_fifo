`timescale 1ns / 1ps
//axi stream fifo implementation


//`define KEEP
//`define USER
module axis_fifo#(
        parameter  DATA_WIDTH = 32,
        parameter  DATA_DEPTH = 128,
        parameter  USER_WIDTH = 16
)(
    input   s_axis_clk,
    input   s_axis_resetn,
    input   s_axis_tvalid,
    input   s_axis_tlast,
    input [DATA_WIDTH-1:0] s_axis_tdata,
    `ifdef KEEP
    input [(DATA_WIDTH/8)-1:0]s_axis_tkeep,
    `endif
    `ifdef USER
    input [USER_WIDTH-1:0]s_axis_tuser,
    `endif
    output  s_axis_tready,
    //output
    output reg m_axis_tvalid,
    output reg m_axis_tlast,
    output reg [DATA_WIDTH-1:0] m_axis_tdata,
    `ifdef KEEP
    output reg[(DATA_WIDTH/8)-1:0]m_axis_tkeep,
    `endif
    `ifdef USER
    output reg[USER_WIDTH-1:0]m_axis_tuser,
    `endif
    input m_axis_tready,
    output   full_o,
    output   empty_o
    );
    
    
    reg [$clog2(DATA_DEPTH):0]wr_ptr;
    reg [$clog2(DATA_DEPTH):0]rd_ptr;
    
    wire wr_en_i;
    wire rd_en_i;
    wire read_req;
    
    wire full_w ;
    wire empty_w;
    
    
    `ifdef KEEP
        `ifdef USER
            reg [(DATA_WIDTH+1+(DATA_WIDTH/8)+USER_WIDTH)-1:0]wr_data_i;
            wire [(DATA_WIDTH+1+(DATA_WIDTH/8)+USER_WIDTH)-1:0]rd_data_o;
            localparam MEM_DATA_WIDTH = DATA_WIDTH + 1 + (DATA_WIDTH/8) + USER_WIDTH;
        `else
            reg [(DATA_WIDTH+1+(DATA_WIDTH/8))-1:0]wr_data_i;
            wire [(DATA_WIDTH+1+(DATA_WIDTH/8))-1:0]rd_data_o;
            localparam MEM_DATA_WIDTH = DATA_WIDTH + 1 + (DATA_WIDTH/8);
        `endif
    `elsif USER
        reg [(DATA_WIDTH+1+USER_WIDTH)-1:0]wr_data_i;
        wire [(DATA_WIDTH+1+USER_WIDTH)-1:0]rd_data_o;
        localparam MEM_DATA_WIDTH = DATA_WIDTH + 1 + USER_WIDTH;
    `else
        reg [(DATA_WIDTH+1)-1:0]wr_data_i;
        wire [(DATA_WIDTH+1)-1:0]rd_data_o;
        localparam MEM_DATA_WIDTH = DATA_WIDTH + 1;
    `endif
    
    //write logic
    assign s_axis_tready = (full_w==0) ? 1'b1 : 1'b0;
    assign wr_en_i = (!full_w && s_axis_tvalid);
    
    always@(posedge s_axis_clk)begin
        if(!s_axis_resetn)begin
            wr_ptr  <= 0;
        end
        else begin
            if(!full_w && s_axis_tvalid) begin
                wr_ptr  <= wr_ptr + 1;
            end
        end
    end
    
    always@(*)begin
       `ifdef KEEP
            `ifdef USER
                wr_data_i  = {s_axis_tuser,s_axis_tkeep,s_axis_tlast,s_axis_tdata};
            `else
                wr_data_i  = {s_axis_tkeep,s_axis_tlast,s_axis_tdata};
            `endif
       `elsif USER
            wr_data_i  = {s_axis_tuser,s_axis_tlast,s_axis_tdata};
       `else
            wr_data_i  = {s_axis_tlast,s_axis_tdata};
       `endif
    end
    
    //read logic
    
    assign read_req = (!empty_w &&   m_axis_tready);
    always @(posedge s_axis_clk) begin
        if(!s_axis_resetn)
            rd_ptr <= 0;
        else if(read_req)
            rd_ptr <= rd_ptr + 1;
    end
    
    
    always @(posedge s_axis_clk) begin
        if(!s_axis_resetn)
            m_axis_tvalid <= 0;
        else if(read_req)
            m_axis_tvalid <= 1;
        else if(m_axis_tvalid && m_axis_tready)
            m_axis_tvalid <= 0;
    end
    assign rd_en_i = read_req;
    
    always@(*)begin
        `ifdef KEEP
             `ifdef USER
                if(m_axis_tvalid)begin
                    m_axis_tdata  = rd_data_o[DATA_WIDTH-1:0];
                    m_axis_tlast  = rd_data_o[DATA_WIDTH];
                    m_axis_tkeep  = rd_data_o[(MEM_DATA_WIDTH-USER_WIDTH)-1:DATA_WIDTH+1];
                    m_axis_tuser  = rd_data_o[MEM_DATA_WIDTH-1 : (MEM_DATA_WIDTH-USER_WIDTH)];
                 end
                 else begin
                    m_axis_tdata  = 0;
                    m_axis_tlast  = 0;
                    m_axis_tkeep  = 0;
                    m_axis_tuser  = 0;
                 end
              `else
                if(m_axis_tvalid)begin
                    m_axis_tdata  = rd_data_o[DATA_WIDTH-1:0];
                    m_axis_tlast  = rd_data_o[DATA_WIDTH];
                    m_axis_tkeep  = rd_data_o[(MEM_DATA_WIDTH-USER_WIDTH)-1:DATA_WIDTH+1];
                end
                else begin
                    m_axis_tdata  = 0;
                    m_axis_tlast  = 0;
                    m_axis_tkeep  = 0;
                end                
              `endif
        `elsif USER
            if(m_axis_tvalid)begin
                m_axis_tdata  = rd_data_o[DATA_WIDTH-1:0];
                m_axis_tlast  = rd_data_o[DATA_WIDTH];
                m_axis_tuser  = rd_data_o[MEM_DATA_WIDTH-1 : DATA_WIDTH+1];
             end
             else begin
                m_axis_tdata  = 0;
                m_axis_tlast  = 0;
                m_axis_tuser  = 0;
            end
        `else
            if(m_axis_tvalid)begin
                m_axis_tdata  = rd_data_o[DATA_WIDTH-1:0];
                m_axis_tlast  = rd_data_o[DATA_WIDTH];
            end
            else begin
                m_axis_tdata  = 0;
                m_axis_tlast  = 0;
            end
        `endif
    end
    
    assign full_w = ((wr_ptr[($clog2(DATA_DEPTH))] != rd_ptr[($clog2(DATA_DEPTH))]) &&
                    (wr_ptr[($clog2(DATA_DEPTH))-1:0] == rd_ptr[($clog2(DATA_DEPTH))-1:0]))? 1'b1:1'b0;
    assign empty_w = (wr_ptr == rd_ptr)? 1'b1:1'b0;
    assign full_o = full_w;
    assign empty_o = empty_w;
    
    memory#(
        .DATA_WIDTH(MEM_DATA_WIDTH),
        .MEM_DEPTH(DATA_DEPTH)
    )mem(
        `ifdef ASYNC
        .wr_clk(wr_clk),
        .rd_clk(rd_clk),
        `else
        .wr_clk(s_axis_clk),
        .rd_clk(s_axis_clk),
        `endif
        .wr_en_i(wr_en_i),
        .wr_data_i(wr_data_i),
        .wr_addr_i(wr_ptr[($clog2(DATA_DEPTH))-1:0]),
        .rd_addr_i(rd_ptr[($clog2(DATA_DEPTH))-1:0]),
        .rd_en_i(rd_en_i),
        .rd_data_o(rd_data_o)
    );
    
endmodule
