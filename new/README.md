Dual-Mode Synchronous/Asynchronous FIFO
---------------------------------------
A highly configurable, parameterized Verilog FIFO supporting both Synchronous (single clock) and Asynchronous (dual clock) operation modes via compiler directives.

Architectural Block Diagram
---------------------------

Key Components:
Dual-Port Memory: Parameterized storage for data.
Gray Code Converters: Converts binary pointers to Gray code to ensure safe Clock Domain Crossing (CDC).
2-Stage Synchronizer: Mitigates metastability when passing pointers between wr_clk and rd_clk.
Flag Logic: Robust generation of full_o and empty_o status signals.

Features
--------
Configurable Mode: Toggle between Sync and Async logic using the `define ASYNC macro.
Parameterized Design: Easily adjust DATA_WIDTH and DATA_DEPTH.
CDC Safety: Uses (* ASYNC_REG = "TRUE" *) attributes for FPGA synthesis tools (like Vivado) to ensure proper placement of synchronizer registers.
Gray Coding: Pointers are synchronized in Gray code to prevent multi-bit transition errors.

