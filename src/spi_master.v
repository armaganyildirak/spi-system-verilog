module spi_master #(
    parameter DATA_WIDTH = 8,
    parameter FIFO_DEPTH = 16
)(
    input  wire                  clk,
    input  wire                  rst,
    input  wire [15:0]           clk_div,
    input  wire                  cpol,
    input  wire                  cpha,
    input  wire                  lsb_first,

    // Control
    input  wire                  wr_en,
    input  wire [DATA_WIDTH-1:0] wr_data,
    output wire                  full,

    // Status
    output reg                   done,
    output reg                   int_done,
    output wire                  empty,

    // SPI Interface
    output wire                  sclk,
    output reg                   mosi,
    input  wire                  miso,
    output reg                   cs,

    // Readback
    output wire [DATA_WIDTH-1:0] rd_data,
    input  wire                  rd_en
);

    localparam IDLE      = 0,
               ASSERT_CS = 1,
               TRANSFER  = 2,
               DONE      = 3;

    reg [1:0] state;
    reg [$clog2(DATA_WIDTH):0] bit_cnt;

    reg [DATA_WIDTH-1:0] shift_reg_in;
    reg [DATA_WIDTH-1:0] shift_reg_out;

    reg [15:0] clk_cnt;
    reg spi_clk;
    reg spi_clk_en;
    reg prev_spi_clk;

    assign sclk = cpol ^ spi_clk;

    // FIFO interface
    wire [DATA_WIDTH-1:0] fifo_dout;
    wire fifo_empty;
    wire fifo_full;

    assign full  = fifo_full;
    assign empty = fifo_empty;
    assign rd_data = shift_reg_in;

    // Added debug signals
    reg last_bit_sent;
    reg last_bit_received;

    // SPI clock generation with more precise edge control
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_cnt <= 0;
            spi_clk <= 0;
        end else if (spi_clk_en) begin
            if (clk_cnt == clk_div - 1) begin
                clk_cnt <= 0;
                spi_clk <= ~spi_clk;
            end else begin
                clk_cnt <= clk_cnt + 1;
            end
        end else begin
            clk_cnt <= 0;
            spi_clk <= cpol;
        end
    end

    // FSM + FIFO handling with improved bit tracking
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            cs <= 1;
            done <= 0;
            int_done <= 0;
            spi_clk_en <= 0;
            bit_cnt <= 0;
            mosi <= 0;
            shift_reg_in <= 0;
            shift_reg_out <= 0;
            last_bit_sent <= 0;
            last_bit_received <= 0;
        end else begin
            done <= 0;
            int_done <= 0;
            prev_spi_clk <= spi_clk;

            case (state)
                IDLE: begin
                    cs <= 1;
                    spi_clk_en <= 0;
                    if (!fifo_empty) begin
                        shift_reg_out <= fifo_dout;
                        bit_cnt <= DATA_WIDTH;
                        cs <= 0;
                        state <= ASSERT_CS;
                    end
                end

                ASSERT_CS: begin
                    spi_clk_en <= 1;
                    if (cpha == 0) begin
                        // For CPHA=0, set first bit immediately after CS assertion
                        mosi <= lsb_first ? shift_reg_out[0] : shift_reg_out[DATA_WIDTH-1];
                        last_bit_sent <= lsb_first ? shift_reg_out[0] : shift_reg_out[DATA_WIDTH-1];
                    end
                    
                    // Move to TRANSFER when the first clock edge happens
                    if ((cpha == 0 && spi_clk == ~cpol && prev_spi_clk == cpol) ||
                        (cpha == 1 && spi_clk == cpol && prev_spi_clk == ~cpol)) begin
                        if (cpha == 1) begin
                            // For CPHA=1, set first bit on first leading edge
                            mosi <= lsb_first ? shift_reg_out[0] : shift_reg_out[DATA_WIDTH-1];
                            last_bit_sent <= lsb_first ? shift_reg_out[0] : shift_reg_out[DATA_WIDTH-1];
                        end
                        state <= TRANSFER;
                    end
                end

                TRANSFER: begin
                    // Sample on appropriate edge based on CPHA
                    if ((cpha == 0 && spi_clk == cpol && prev_spi_clk == ~cpol) ||
                        (cpha == 1 && spi_clk == ~cpol && prev_spi_clk == cpol)) begin
                        
                        // Sample input bit
                        if (lsb_first) begin
                            shift_reg_in <= {miso, shift_reg_in[DATA_WIDTH-1:1]};
                        end else begin
                            shift_reg_in <= {shift_reg_in[DATA_WIDTH-2:0], miso};
                        end
                        last_bit_received <= miso;
                        
                        bit_cnt <= bit_cnt - 1;

                        // Setup next output bit or finish if done
                        if (bit_cnt > 1) begin
                            if (lsb_first) begin
                                shift_reg_out <= {1'b0, shift_reg_out[DATA_WIDTH-1:1]};
                                mosi <= shift_reg_out[1]; // Next bit
                                last_bit_sent <= shift_reg_out[1];
                            end else begin
                                shift_reg_out <= {shift_reg_out[DATA_WIDTH-2:0], 1'b0};
                                mosi <= shift_reg_out[DATA_WIDTH-2]; // Next bit
                                last_bit_sent <= shift_reg_out[DATA_WIDTH-2];
                            end
                        end else begin
                            // Ensure we maintain the last bit until end of transmission
                            state <= DONE;
                        end
                    end
                end

                DONE: begin
                    // Complete the SPI clock cycle before deactivating CS
                    if ((cpha == 0 && spi_clk == cpol) ||
                        (cpha == 1 && spi_clk == ~cpol)) begin
                        done <= 1;
                        int_done <= 1;
                        spi_clk_en <= 0;
                        cs <= 1; // Deactivate CS
                        state <= IDLE;
                    end
                end
            endcase
        end
    end

    // This redundant always block was part of the issue - removing it and integrating
    // its functionality in the main FSM above

    // FIFO instantiation
    fifo #(
        .DATA_WIDTH(DATA_WIDTH),
        .DEPTH(FIFO_DEPTH)
    ) tx_fifo (
        .clk(clk),
        .rst(rst),
        .wr_en(wr_en),
        .rd_en((state == IDLE && !fifo_empty)),
        .din(wr_data),
        .dout(fifo_dout),
        .full(fifo_full),
        .empty(fifo_empty)
    );
endmodule