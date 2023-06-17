package cache_def_pipe_data;

    //data structure for cache memory request
    typedef struct packed {
        bit [8:0] index; //8-bit index
        bit we; //write enable
    } cache_req_type;

    // data structures for cache tag & data
    parameter int TAGMSB = 31; //tag msb
    parameter int TAGLSB = 13; //tag lsb
    //data structure for cache tag
    typedef struct packed {
        bit valid; //valid bit
        bit dirty; //dirty bit
        bit [TAGMSB:TAGLSB]tag; //tag bits
    } cache_tag_type;

    //255-bit cache line data
    typedef bit [127:0] cache_data_type;

    // data structures for CPU<->Cache controller interface
    // CPU request (CPU->cache controller)
    typedef struct packed {
        bit [31:0]addr; //32-bit request addr
        bit [31:0]data; //32-bit request data (used when write)
        bit rw; //request type : 0 = read, 1 = write
        bit valid; //request is valid
    } cpu_req_type;

    // Cache result (cache controller->cpu)
    typedef struct packed {
         bit [31:0]data; //32-bit data
         bit ready; //result is ready
    } cpu_result_type;

//----------------------------------------------------------------------

    // data structures for cache controller<->memory interface
    // memory request (cache controller->memory)
    typedef struct packed{
         bit [31:0]addr; //request byte addr
         bit [127:0]data; //255-bit request data (used when write)
         bit rw; //request type : 0 = read, 1 = write
         bit valid; //request is valid
    } mem_req_type;

    // memory controller response (memory -> cache controller)
    typedef struct packed{
         cache_data_type data; //255-bit read back data
         bit ready; //data is ready
    } mem_data_type;

    //data structure for cache-pipeline_non_read
    typedef struct packed {
        bit [1:0] access; //4-bits access
        cpu_req_type cpu_req; //cpu_req
    } cache_pipeline_non_read;

    //data structure for cache-pipeline_read
    typedef struct packed {
        cache_tag_type [3:0] tag_read; //tag_read
        cache_data_type [3:0] data_read; //data_read
    } cache_pipeline_read;

endpackage