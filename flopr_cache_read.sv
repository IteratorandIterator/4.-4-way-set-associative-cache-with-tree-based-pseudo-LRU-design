import cache_def_pipe_data::*;

module flopenr_cache_read (input logic clk, reset, en,
                      input cache_pipeline_read cache_pipe_read_in,
                      output cache_pipeline_read cache_pipe_read_out);
    always_ff @(posedge clk, posedge reset) begin
        if (reset)
            cache_pipe_read_out <= 0;
        else if (en)
            cache_pipe_read_out <= cache_pipe_read_in;
    /*end
    //write port
    always_ff @(posedge clk, posedge reset) begin
        if(en && we)
            RAM[addr] <= di;
    end
 
    //read port
    always_ff @(posedge clk, posedge reset) begin
    if(en)
        if(we)
            dout <= di;
        else
            dout <= RAM[addr];
    end*/
    end
endmodule
