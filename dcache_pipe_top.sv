`timescale 1ns / 1ps

import cache_def_pipe_data::*;

/*cache finite state machine*/
module dcache_pipe_top  #(parameter int unsigned SET_ASSOC = 4,
                    parameter int unsigned SET_NUM   = 512)
                   (input bit clk, input bit rst,
                    //CPU request input (CPU->cache)
                    input cpu_req_type cpu_req,
                    //memory result (memory -> cache)
                    input mem_data_type mem_data,
                    //memory request (cache->memory)
                    output mem_req_type mem_req,
                    //cache result (cache->CPU)
                    output cpu_result_type cpu_res,
                    output cache_stall);
    /*write clock*/
    timeunit 1ns; 
    timeprecision 1ps;
    
   // status of each cache set    
   logic [SET_NUM-1:0] [SET_ASSOC-2:0] tplru;
   // number of which line that had been selected
   logic [SET_ASSOC-3:0] access;
   //assign cpu_req.addr = cpu_req.addr + tmp;
       //tag read result
    cache_tag_type[SET_ASSOC-1:0]  tag_read;
    //tag write data
    cache_tag_type[SET_ASSOC-1:0] tag_write;
    //tag request
    cache_req_type [SET_ASSOC-1:0] tag_req;
    
   // valid array of four line in a same set
   logic [SET_ASSOC-1:0] tag_valid_array;
   // compare results 
   logic [SET_ASSOC-1:0] tag_results_array;
   logic [SET_ASSOC-1:0] [TAGLSB-1:4] tag_index;
   
   always_comb begin
        for (int i = 0; i < SET_ASSOC; ++i) begin
             tag_index[i] = cpu_req.addr[TAGLSB-1:4];
        end
        
        for (int j = 0; j < SET_ASSOC; ++j) begin
            tag_results_array[SET_ASSOC-1-j] = (tag_read[j].tag == cpu_req.addr[TAGMSB:TAGLSB]);
        end
        
        for (int k = 0; k < SET_ASSOC; ++k) begin
            tag_valid_array[SET_ASSOC-1-k] = tag_read[k].valid;
        end
   end

    /*FSM state register*/
    typedef enum {compare_tag, allocate, write_back} cache_state_type;

    /*interface signals to tag memory*/
    cache_state_type vstate, rstate;


    /*interface signals to cache data memory*/
    //cache line read data
    cache_data_type[SET_ASSOC-1:0] data_read;
    //cache line write data
    cache_data_type[SET_ASSOC-1:0] data_write;
    //data req
    cache_req_type [SET_ASSOC-1:0] data_req;

    /*temporary variable for cache controller result*/
    cpu_result_type v_cpu_res; 
    /*temporary variable for memory controller request*/
    mem_req_type    v_mem_req;

    //connect to output ports
    assign mem_req = v_mem_req;
    assign cpu_res = v_cpu_res;
    
    
    logic is_all_valid_and_donotmatch_in, is_all_valid_and_donotmatch_out;
    always_comb
    begin
        is_all_valid_and_donotmatch_in = 1'b0;
        //access = 2'b00;
        //if (r_or_w_diff_way) begin
        //*-------make sure which line will be used to read/write or  be evicted--------*/
        if (tag_results_array == 0 ||   //all tags in a cache line doesn't match input-tag
            (tag_results_array != 0     //one of tags in a cache line match input-tag
               && ((tag_results_array     //but its valid bit != 0
                & tag_valid_array) == 0)))
                begin
                    casez (tag_valid_array)   //tag match or its valid bit == 0
                        4'b0???: access = 2'b00;
                        4'b10??: access = 2'b01;
                        4'b110?: access = 2'b10;
                        4'b1110: access = 2'b11;
                        default: begin     //all tags doesn't match and need to evict one of way
                            /*if (mem_req_rw_1_latency) begin //第一次进入时v_mem_req.rw一定为0，此时先不更新tplru,
                                is_evicted = 1'b1;     //第二个时钟周期正在将新的tag写入cahce line，此时
                            end */                      //更新tplru
                            is_all_valid_and_donotmatch_in = 1'b1;
                            casez (tplru[cpu_req.addr[12:4]])
                                3'b00?: access = 2'b11; //第三个时钟周期读出的tag已经是更新过后的tag，因此不会再
                                3'b01?: access = 2'b10; //进入这里
                                3'b1?0: access = 2'b01;
                                3'b1?1: access = 2'b00;
                                default:access = 2'bxx;
                            endcase
                        end
                    endcase    
                end
        else
        begin                       //tag match and its valid bit == 1
            case (tag_results_array)
                4'b1000: access = 2'b00;
                4'b0100: access = 2'b01;
                4'b0010: access = 2'b10;
                4'b0001: access = 2'b11;
                default: access = 2'bxx;
            endcase
        end
        //end
        
    
    end

    //access, tag_read, data_read, cpu_req
    logic r_or_w_diff_way;
    logic stall, stall_1_latency;
    flopenr #(1) fer(clk, rst, (~r_or_w_diff_way)&(~stall_1_latency), 
        is_all_valid_and_donotmatch_in, is_all_valid_and_donotmatch_out);
    
    assign cache_stall = stall_1_latency | r_or_w_diff_way;
    cache_pipeline_non_read cache_pipe_non_read_in, cache_pipe_non_read_out;
    assign cache_pipe_non_read_in = {access, cpu_req};
    flopenr_cache_non_read fcache_non_read(clk, rst,(~r_or_w_diff_way)&(~stall_1_latency), 
        cache_pipe_non_read_in, cache_pipe_non_read_out);
    
    cache_pipeline_read cache_pipe_read_in, cache_pipe_read_out;
    assign cache_pipe_read_in = {tag_read, data_read};
    flopenr_cache_read fcache_read(clk, rst, ~stall, cache_pipe_read_in, cache_pipe_read_out);
    
    logic read_from_mem_direct, read_from_mem_direct_1_latency;
    logic read_from_cache_data_direct, read_from_cache_data_direct_1_latency;
    logic is_last_cpu_req_rw, is_last_cpu_req_rw_1_latency;
    logic [31:0] is_last_cpu_req_data, is_last_cpu_req_data_1_latency;
    
    mem_data_type mem_data_pipe_in, mem_data_pipe_out;
    assign mem_data_pipe_in = mem_data;
    flopenr_cache_mem_data fcache_mem_data(clk, rst,read_from_mem_direct, mem_data_pipe_in, mem_data_pipe_out);
    
    logic bk, bk_1_latency, is_assign_0;
    logic is_allocate_or_writeback;
    
    always_comb begin
     /*-------------------------default values for all signals------------*/
         /*no state change by default*/
         bk = 1'b0;
         stall <= 1'b0;
         r_or_w_diff_way <= 1'b0;
         read_from_mem_direct <= 1'b0;
         is_allocate_or_writeback <= 1'b0;
         read_from_cache_data_direct <= 1'b0;
         is_last_cpu_req_rw <= cache_pipe_non_read_out.cpu_req.rw;
         is_last_cpu_req_data <= cache_pipe_non_read_out.cpu_req.data;
         vstate <= rstate;
         is_assign_0 = 1'b0;
         v_cpu_res = {32'b0, 1'b0}; 
         tag_write = {4{1'b0, 1'b0, 19'b0}};
         /*read tag by default*/
         //tag_req[access].we = '0;
         /*direct map index for tag*/
         //tag_req[access].index = cpu_req.addr[12:5];
         tag_req = {4{cache_pipe_non_read_out.cpu_req.addr[12:4], 1'b0}};
         /*read current cache line by default*/
         //data_req[access].we = '0;
         /*direct map index for cache data*/
         //data_req[access].index = cpu_req.addr[12:5];
         data_req = {4{cache_pipe_non_read_out.cpu_req.addr[12:4], 1'b0}};
         /*modify correct word (32-bit) based on address*/
         //data_write[access] = data_read[access];
         data_write = cache_pipe_read_out.data_read;//cache_pipe_read_out.data_read;
         case(cache_pipe_non_read_out.cpu_req.addr[3:2])
             2'b00:data_write[cache_pipe_non_read_out.access][31:0]    
                = cache_pipe_non_read_out.cpu_req.data;
             2'b01:data_write[cache_pipe_non_read_out.access][63:32]   
                = cache_pipe_non_read_out.cpu_req.data;
             2'b10:data_write[cache_pipe_non_read_out.access][95:64]   
                = cache_pipe_non_read_out.cpu_req.data;
             2'b11:data_write[cache_pipe_non_read_out.access][127:96]  
                = cache_pipe_non_read_out.cpu_req.data;
         endcase

         /*read out correct word(32-bit) from cache (to CPU)*/
         if (read_from_cache_data_direct_1_latency & is_last_cpu_req_rw_1_latency) begin
            case(cache_pipe_non_read_out.cpu_req.addr[3:2])
                2'b00:v_cpu_res.data = is_last_cpu_req_data_1_latency ;
                2'b01:v_cpu_res.data = is_last_cpu_req_data_1_latency ;
                2'b10:v_cpu_res.data = is_last_cpu_req_data_1_latency ;
                2'b11:v_cpu_res.data = is_last_cpu_req_data_1_latency ;
            endcase
         end
         else if (read_from_mem_direct_1_latency) begin
            case(cache_pipe_non_read_out.cpu_req.addr[3:2])
                2'b00:v_cpu_res.data = mem_data_pipe_out.data[31:0]   ;
                2'b01:v_cpu_res.data = mem_data_pipe_out.data[63:32]  ;
                2'b10:v_cpu_res.data = mem_data_pipe_out.data[95:64]  ;
                2'b11:v_cpu_res.data = mem_data_pipe_out.data[127:96] ;
            endcase
         end
         else begin
            case(cache_pipe_non_read_out.cpu_req.addr[3:2])
                2'b00:v_cpu_res.data = cache_pipe_read_out.data_read[cache_pipe_non_read_out.access][31:0]   ;
                2'b01:v_cpu_res.data = cache_pipe_read_out.data_read[cache_pipe_non_read_out.access][63:32]  ;
                2'b10:v_cpu_res.data = cache_pipe_read_out.data_read[cache_pipe_non_read_out.access][95:64]  ;
                2'b11:v_cpu_res.data = cache_pipe_read_out.data_read[cache_pipe_non_read_out.access][127:96] ;
            endcase
         end

         /*memory request address (sampled from CPU request)*/
         //v_mem_req.addr = cpu_req.addr;
         /*memory request data (used in write)*/
         //v_mem_req.data = data_read[access];
         //v_mem_req.rw = '0;
         v_mem_req = {cache_pipe_non_read_out.cpu_req.addr, 
            cache_pipe_read_out.data_read[cache_pipe_non_read_out.access], 1'b0, 1'b0};
         //------------------------------------Cache FSM-------------------------
         case(rstate)
            /*idle state*/
            /*If there is a CPU request, then compare cache tag*/
            /*idle : begin
             if (cpu_req.valid)
                vstate <= compare_tag;
            end*/

            /*compare_tag state*/
            compare_tag : begin
                if (cache_pipe_non_read_out.cpu_req.valid) begin //***
                    if ((cache_pipe_non_read_out.cpu_req.addr[TAGMSB:TAGLSB] != cpu_req.addr[TAGMSB:TAGLSB]) && 
                        (cache_pipe_non_read_out.cpu_req.addr[TAGLSB:4] == cpu_req.addr[TAGLSB:4])) begin
                            is_assign_0 = 1'b1;
                            //bk = bk_1_latency;
                            if (bk_1_latency == 1'b0) begin
                                bk = 1'b1;
                                r_or_w_diff_way <= 1'b1;
                            end
                            else begin
                                bk = 1'b0;
                                r_or_w_diff_way <= 1'b0;
                            end
                    end
                    else begin
                            r_or_w_diff_way <= 1'b0;
                    end
                    /*cache hit (tag match and cache entry is valid)*/
                    if (cache_pipe_non_read_out.cpu_req.addr[TAGMSB:TAGLSB] == 
                        cache_pipe_read_out.tag_read[cache_pipe_non_read_out.access].tag 
                        && cache_pipe_read_out.tag_read[cache_pipe_non_read_out.access].valid) begin  
                                                         //cache hit——current way of a cache line
                        stall <= 1'b0;                  //is the way we want to operate
                        v_cpu_res.ready = '1;           //if operation is read, just return the value
                        /*write hit*/                   //if operation is write, just write back the 
                        if (cache_pipe_non_read_out.cpu_req.rw) begin //data and tag, set the dirty and valid to 1 at the same
                            /*read/modify cache line*/  //time
                            tag_req[cache_pipe_non_read_out.access].we = '1; 
                            data_req[cache_pipe_non_read_out.access].we = '1;
                            /*no change in tag*/        //ATTENTION:write back data, tag back to caceh
                            tag_write[cache_pipe_non_read_out.access].tag = 
                                cache_pipe_read_out.tag_read[cache_pipe_non_read_out.access].tag;
                            tag_write[cache_pipe_non_read_out.access].valid = '1;   // not write back to memory
                            /*cache line is dirty*/
                            tag_write[cache_pipe_non_read_out.access].dirty = '1;
                            read_from_cache_data_direct <= 1'b1;
                            //$display("write to cache");
                        end
                        /*xaction is finished*/
                        //vstate = idle;
                        //*****
                        vstate <= compare_tag;
                        $display("AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA");
                        //$display("compare_tag-if");
                    end
                
                    /*cache miss*/
                    else            //cache miss——store the current tag to cache first
                    begin           //store the data read from memory to cache later in
                        /*generate new tag*/    //the allocate state
                        stall <= 1'b1;
                        is_allocate_or_writeback <= 1'b1;
                        tag_req[cache_pipe_non_read_out.access].we = '1;
                        tag_write[cache_pipe_non_read_out.access].valid = '1;
                        /*new tag*/
                        tag_write[cache_pipe_non_read_out.access].tag = 
                            cache_pipe_non_read_out.cpu_req.addr[TAGMSB:TAGLSB];
                        /*cache line is dirty if write*/
                        tag_write[cache_pipe_non_read_out.access].dirty = 
                            cache_pipe_non_read_out.cpu_req.rw;
                        /*generate memory request on miss*/
                        v_mem_req.valid = '1;   //allow read from memory
                        /*compulsory miss or miss with clean block*/
                        if (cache_pipe_read_out.tag_read[cache_pipe_non_read_out.access].valid == 1'b0 || 
                            cache_pipe_read_out.tag_read[cache_pipe_non_read_out.access].dirty == 1'b0) begin
                            /*wait till a new block is allocated*/
                            vstate <= allocate;  //put the newly read data to current way
                            $display("BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB");
                        end
                        else 
                        begin
                            /*miss with dirty line*/
                            /*write back address*/
                            $display("CCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCCC");
                            v_mem_req.addr = 
                            {cache_pipe_read_out.tag_read[cache_pipe_non_read_out.access].tag, 
                            cache_pipe_non_read_out.cpu_req.addr[TAGLSB-1:0]};
                            v_mem_req.rw = '1;
                            /*wait till write is completed*/
                            vstate <= write_back;    //wirte back the data of current way, put the
                         end                        //newly read data to current way
                         //$display("compare_tag-else");
                    end
                end
            end //***

            /*wait for allocating a new cache line*/
            allocate: begin
                $display("DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDD");
                /*memory controller has responded*/
                if (mem_data.ready) begin   //read the new data from memory
                    /*re-compare tag for write miss (need modify correct word)*/
                    vstate <= compare_tag;
                    data_write[cache_pipe_non_read_out.access] = mem_data.data;
                    //cache_pipe_read_out.data_read[cache_pipe_non_read_out.access] = mem_data.data;
                    /*update cache line data*/
                    data_req[cache_pipe_non_read_out.access].we = '1;
                    stall <= 1'b0;
                    read_from_mem_direct <= 1'b1;
                    //$display("allocate-if");
                end
                else begin
                    stall <= 1'b1;
                end
                //$display("allocate-else");
            end

            /*wait for writing back dirty cache line*/
            write_back : begin
            $display("EEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEEE");
                stall <= 1'b1;
                /*write back is completed*/
                if (mem_data.ready) begin
                    /*issue new memory request (allocating a new line)*/
                    v_mem_req.valid = '1;
                    v_mem_req.rw = '0;
                    vstate <= allocate;
                end
                //$display("write-back");
            end
        endcase
    end

    always_ff @(posedge(clk)) begin
        if (rst) begin
            rstate <= compare_tag;
            stall_1_latency <= 1'b0;
            read_from_mem_direct_1_latency <= 1'b0;
            read_from_cache_data_direct_1_latency <= 1'b0;
            is_last_cpu_req_rw_1_latency <= 1'b0;
            is_last_cpu_req_data_1_latency <= 32'b0;
        end
        else begin
            rstate <= vstate;
            stall_1_latency <= stall;
            read_from_mem_direct_1_latency <= read_from_mem_direct;
            read_from_cache_data_direct_1_latency <= read_from_cache_data_direct;
            is_last_cpu_req_rw_1_latency <= is_last_cpu_req_rw;
            is_last_cpu_req_data_1_latency <= is_last_cpu_req_data;
        end
    end
    
    always_ff @(posedge(clk)) begin
        if (rst) begin
            bk_1_latency <= 1'b0;
        end
        else begin
            if (is_assign_0) begin
                bk_1_latency <= bk;
            end
        end
    end

                        
    for(genvar i = 0; i < SET_ASSOC; ++i) begin : gen_icache_mem
        dm_cache_tag_bram #(SET_NUM) tag_D
                           (.clk   (clk),
                            .rst   (rst),
                            .wea   (tag_req[i].we),
                            .ena   (1'b1),
                            .addra (stall_1_latency?tag_req[i].index:tag_index[i]),
                            .dina  (tag_write[i]),
                            .douta (tag_read[i]));
        
        
        dm_cache_data_bram #(SET_NUM) data_D
                             (.clk   (clk),
                              .rst   (rst),
                              .wea   (data_req[i].we),
                              .ena   (1'b1),
                              .addra (stall_1_latency?tag_req[i].index:tag_index[i]),
                              .dina  (data_write[i]),
                              .douta (data_read[i]));
    end

    // generate TPLRU
    for(genvar i = 0; i < SET_NUM; ++i) begin: gen_tplru
        tree_plru #(
            .SET_ASSOC (SET_ASSOC)
        ) tplru_inst (
            .clk           (clk),
            .rst           (rst),
            .access        (cache_pipe_non_read_out.access),
            .is_evicted ((is_allocate_or_writeback & is_all_valid_and_donotmatch_out) 
	&& (i[8:0] == cpu_req.addr[12:4])),
            .tplru         (tplru[i])
        );
    end

endmodule
