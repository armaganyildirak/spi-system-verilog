module spi_slave #(
    parameter DATA_WIDTH = 8
)(
    input  wire clk,
    input  wire rst,
    input  wire sclk,
    input  wire mosi,
    input  wire cs,
    input  wire cpol,
    input  wire cpha,
    input  wire lsb_first,
    output wire miso,
    output reg  [DATA_WIDTH-1:0] rx_data,
    input  wire [DATA_WIDTH-1:0] tx_data
);

    // Synchronize SPI signals to prevent metastability (3-stage synchronizer)
    reg [2:0] sclk_sync;
    reg [2:0] cs_sync;
    reg [2:0] mosi_sync;
    
    always @(posedge clk) begin
        sclk_sync <= {sclk_sync[1:0], sclk};
        cs_sync <= {cs_sync[1:0], cs};
        mosi_sync <= {mosi_sync[1:0], mosi};
    end
    
    // Edge detection
    wire sclk_rise = (sclk_sync[2:1] == 2'b01);
    wire sclk_fall = (sclk_sync[2:1] == 2'b10);
    wire cs_active = !cs_sync[2];
    wire mosi_bit = mosi_sync[2];

    // Determine sample and shift edges based on CPOL/CPHA
    wire sample_edge = cs_active && (
        (cpha == 0 && sclk_rise) || 
        (cpha == 1 && sclk_fall && state == ACTIVE) // Sample only in ACTIVE state
    );
    
    wire shift_edge = cs_active && (
        (cpha == 0 && sclk_fall) || 
        (cpha == 1 && sclk_rise)
    );

    // CS edge detection for loading initial tx_data
    wire cs_fall = (cs_sync[2:1] == 2'b10);

    // Shift registers and bit counter
    reg [DATA_WIDTH-1:0] shift_in;
    reg [DATA_WIDTH-1:0] shift_out;
    reg [$clog2(DATA_WIDTH):0] bit_cnt;
    
    // Debug signals
    reg last_bit;
    reg [2:0] state;
    localparam IDLE = 0, START = 1, ACTIVE = 2, COMPLETE = 3;

    // MISO output depends on MSB/LSB first configuration
    assign miso = lsb_first ? shift_out[0] : shift_out[DATA_WIDTH-1];

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_in <= 0;
            shift_out <= 0;
            bit_cnt <= 0;
            rx_data <= 0;
            last_bit <= 0;
            state <= IDLE;
        end else begin
            // State machine
            case (state)
                IDLE: begin
                    if (cs_fall) begin
                        shift_out <= tx_data;
                        bit_cnt <= 0;
                        state <= START;
                    end
                end
                
                START: begin
                    // Wait for first rising edge for CPHA=1 to ensure MOSI is stable
                    if (cpha == 1 && sclk_rise && cs_active) begin
                        state <= ACTIVE;
                    end else if (cpha == 0 && cs_active) begin
                        state <= ACTIVE; // For CPHA=0, proceed immediately
                    end else if (!cs_active) begin
                        state <= IDLE;
                    end
                end
                
                ACTIVE: begin
                    if (!cs_active) begin
                        state <= IDLE;
                    end else begin
                        // Handle shift out on appropriate edge
                        if (shift_edge) begin
                            if (lsb_first) begin
                                // LSB first - shift right
                                shift_out <= {1'b0, shift_out[DATA_WIDTH-1:1]};
                            end else begin
                                // MSB first - shift left
                                shift_out <= {shift_out[DATA_WIDTH-2:0], 1'b0};
                            end
                        end
                        
                        // Handle sample in on appropriate edge
                        if (sample_edge && bit_cnt < DATA_WIDTH) begin
                            last_bit <= mosi_bit;
                            if (lsb_first) begin
                                shift_in <= {mosi_bit, shift_in[DATA_WIDTH-1:1]};
                            end else begin
                                shift_in <= {shift_in[DATA_WIDTH-2:0], mosi_bit};
                            end
                            
                            bit_cnt <= bit_cnt + 1;
                            
                            // Complete byte received
                            if (bit_cnt == DATA_WIDTH-1) begin
                                if (lsb_first) begin
                                    rx_data <= {mosi_bit, shift_in[DATA_WIDTH-1:1]};
                                end else begin
                                    rx_data <= {shift_in[DATA_WIDTH-2:0], mosi_bit};
                                end
                                state <= COMPLETE;
                            end
                        end
                    end
                end
                
                COMPLETE: begin
                    if (!cs_active) begin
                        state <= IDLE;
                    end else begin
                        shift_out <= tx_data; // Preload next data
                    end
                end
            endcase
        end
    end
endmodule