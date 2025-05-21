module fifo #(
    parameter DATA_WIDTH = 8,
    parameter DEPTH = 16
)(
    input  wire clk,
    input  wire rst,
    input  wire wr_en,
    input  wire rd_en,
    input  wire [DATA_WIDTH-1:0] din,
    output wire [DATA_WIDTH-1:0] dout,
    output wire full,
    output wire empty
);

    // Memory array
    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    
    // Pointers and counter
    reg [$clog2(DEPTH):0] wr_ptr;
    reg [$clog2(DEPTH):0] rd_ptr;
    reg [$clog2(DEPTH)+1:0] count;

    // Status signals
    assign full  = (count == DEPTH);
    assign empty = (count == 0);
    
    // Data output
    assign dout  = mem[rd_ptr[$clog2(DEPTH)-1:0]];

    // Reset and pointer management
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= 0;
            rd_ptr <= 0;
            count  <= 0;
        end else begin
            // Write operation
            if (wr_en && !full) begin
                mem[wr_ptr[$clog2(DEPTH)-1:0]] <= din;
                wr_ptr <= wr_ptr + 1;
                if (!rd_en || empty)
                    count <= count + 1;
            end
            
            // Read operation
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1;
                if (!wr_en || full)
                    count <= count - 1;
            end
        end
    end
endmodule