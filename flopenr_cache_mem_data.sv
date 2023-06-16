import cache_def_pipe_data::*;

module flopenr_cache_mem_data (input logic clk, reset, en,
                      input mem_data_type mem_data_pipe_in,
                      output mem_data_type mem_data_pipe_out);
    always_ff @(posedge clk, posedge reset) begin
        if (reset)
            mem_data_pipe_out <= 0;
        else if (en)
            mem_data_pipe_out <= mem_data_pipe_in;
    end
endmodule
