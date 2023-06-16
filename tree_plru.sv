// Tree-Based Pseudo-LRU generator
// Only supports SET_ASSOC = 4

module tree_plru #(parameter int unsigned SET_ASSOC = 4)
                   // normal inputs 
                  (input logic clk, rst,
                   // which of the four cache lines is selected
                   input logic [1:0] access,
                   // the input update indicates wether cache controller 
                   // update is not supposed to be an input signal, maybe they have 
                   // not understood this replacement policy deeply
                   input logic is_evicted,
                   // the output lru indicates which cache line should be replaced
                   output logic [SET_ASSOC-2:0] tplru);

    logic [SET_ASSOC-2:0] state, state_d;
    logic [1:0] access_reg;
    logic is_evicted_reg;

    // Assign output
    assign tplru = state;

    // Update
    always_comb begin
        //state_d <= state;

        case(access_reg)
            2'b11: begin
                state_d[2] <= 1'b1;
                state_d[1] <= 1'b1;
                //state_d[0] <= state_d[0];
                state_d[0] <= state[0];
            end
            2'b10: begin
                state_d[2] <= 1'b1;
                state_d[1] <= 1'b0;
                //state_d[0] <= state_d[0];
                state_d[0] <= state[0];
            end
            2'b01: begin
                state_d[2] <= 1'b0;
                //state_d[1] <= state_d[1];
                state_d[1] <= state[1];
                state_d[0] <= 1'b1;
            end
            2'b00: begin
                state_d[2] <= 1'b0;
                //state_d[1] <= state_d[1];
                state_d[1] <= state[1];
                state_d[0] <= 1'b0;
            end
        endcase
    end

    always_ff @(posedge clk) begin
        if      (rst) begin
            state <= '0;
        end
        else if (is_evicted_reg) begin
            state <= state_d;
        end
    end
    
    always_ff @(posedge clk) begin
        if      (rst) begin
            is_evicted_reg <= '0;
            access_reg <= '0;
        end
        else begin
            is_evicted_reg <= is_evicted;
            access_reg <= access;
        end
    end

endmodule