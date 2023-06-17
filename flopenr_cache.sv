import cache_def_pipe_data::*;

module flopenr_cache_non_read (input logic clk, reset, en,
                      input cache_pipeline_non_read cache_pipe_non_read_in,
                      output cache_pipeline_non_read cache_pipe_non_read_out);
    always_ff @(posedge clk, posedge reset)
        if (reset)
            cache_pipe_non_read_out <= 0;
        else if (en)
            cache_pipe_non_read_out <= cache_pipe_non_read_in;
endmodule
