//`include "cache_define.sv"
import cache_def_pipe_data::*;

/*cache: data memory, single port, 1024 blocks*/
module dm_cache_data_bram #(parameter int unsigned SET_NUM = 32)
                      (input  logic  clk,
	                   input  logic  rst,
	                   input  logic  wea,
	                   input  logic  ena,
	                   input  logic  [$clog2(SET_NUM)-1:0] addra,
	                   input  cache_data_type  dina,
	                   output cache_data_type  douta);

     // xpm_memory_tdpram: True Dual Port RAM
     // Xilinx Parameterized Macro, Version 2019.2
     xpm_memory_spram #(
     	// Common module parameters
     	.MEMORY_SIZE($bits(cache_data_type) * SET_NUM),
     	.MEMORY_PRIMITIVE("block"),//<block> or <distributed>
     	.USE_MEM_INIT(0),
     	.WAKEUP_TIME("disable_sleep"),
     	.MESSAGE_CONTROL(0),
     	.MEMORY_INIT_FILE(),
     
     	// Port A module parameters
     	.WRITE_DATA_WIDTH_A($bits(cache_data_type)),
     	.READ_DATA_WIDTH_A($bits(cache_data_type)),
     	.READ_RESET_VALUE_A("0"),
     	.READ_LATENCY_A(1),//block: 1 while lut: 0
     	.WRITE_MODE_A("write_first")
     ) data_mem (
     	// Common module ports
     	.sleep          ( 1'b0  ),
     
     	// Port A module ports
     	.clka           ( clk   ),
     	.rsta           ( rst   ),
     	.ena            ( ena   ),
     	.regcea         ( 1'b0  ),
     	.wea            ( wea   ),
     	.addra          ( addra ),
     	.dina           ( dina  ),
     	.injectsbiterra ( 1'b0  ), // do not change
     	.injectdbiterra ( 1'b0  ), // do not change
     	.douta          ( douta ), // empty
     	.sbiterra       (       ), // do not change
     	.dbiterra       (       )  // do not change
     );
    
    /*timeunit 1ns; timeprecision 1ps;
    
    (*ram_style="block"*) cache_data_type data_mem [255:0] ;

    always_ff @(posedge clk)
    begin
        if (en)
        begin
            if (data_req.we)
                data_mem[data_req.index] <= data_write;
        end
    end
    
    always_ff @(posedge clk)
    begin
        if (en)
            data_read <= data_mem[data_req.index];
    end*/

endmodule