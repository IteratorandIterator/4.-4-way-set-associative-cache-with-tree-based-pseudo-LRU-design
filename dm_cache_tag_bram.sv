//`include "cache_define.sv"
import cache_def_pipe_data::*;

/*cache: data memory, single port, 1024 blocks*/
module dm_cache_tag_bram  #(parameter int unsigned SET_NUM = 128)
                      (input  logic  clk,
	                   input  logic  rst,
	                   input  logic  wea,
	                   input  logic  ena,
	                   input  logic  [$clog2(SET_NUM)-1:0] addra,
	                   input  cache_tag_type  dina,
	                   output cache_tag_type  douta);

     // xpm_memory_tdpram: True Dual Port RAM
     // Xilinx Parameterized Macro, Version 2019.2
     xpm_memory_spram #(
     	// Common module parameters
     	.MEMORY_SIZE($bits(cache_tag_type) * SET_NUM),
     	.MEMORY_PRIMITIVE("distributed"),//<block> or <distributed>
     	.USE_MEM_INIT(0),
     	.WAKEUP_TIME("disable_sleep"),
     	.MESSAGE_CONTROL(0),
     	.MEMORY_INIT_FILE(),
     
     	// Port A module parameters
     	.WRITE_DATA_WIDTH_A($bits(cache_tag_type)),
     	.READ_DATA_WIDTH_A($bits(cache_tag_type)),
     	.READ_RESET_VALUE_A("0"),
     	.READ_LATENCY_A(0),//block: 1 while lut: 0
     	.WRITE_MODE_A("read_first")
     ) tag_mem (
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
     	.dbiterra       (       ) // do not change
     );

    /*timeunit 1ns; timeprecision 1ps;

    (*ram_style="block"*) cache_tag_type tag_mem [255:0];

    always_ff @(posedge clk)
    begin
        if (en)
        begin
            if (tag_req.we)
                tag_mem[tag_req.index] <= tag_write;
        end
    end
    
    always_ff @(posedge clk)
    begin
        if (en)
            tag_read <= tag_mem[tag_req.index];
    end*/

endmodule