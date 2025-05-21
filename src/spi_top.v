module spi_top (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] clk_div,
    input  wire        cpol,
    input  wire        cpha,
    input  wire        lsb_first,
    input  wire        wr_en,
    input  wire [7:0]  wr_data,
    output wire [7:0]  rd_data,
    input  wire        rd_en,
    output wire        full,
    output wire        empty,
    output wire        done,
    output wire        int_done,
    
    input  wire [7:0]  tx_data,  // Input directly from testbench
    output wire [7:0]  rx_data   // Output for testbench monitoring
);

    wire spi_sclk, spi_mosi, spi_miso, spi_cs;
    wire [7:0] slave_rx_data;

    // SPI Master
    spi_master #(
        .DATA_WIDTH(8),
        .FIFO_DEPTH(16)
    ) master (
        .clk(clk),
        .rst(rst),
        .clk_div(clk_div),
        .cpol(cpol),
        .cpha(cpha),
        .lsb_first(lsb_first),
        .wr_en(wr_en),
        .wr_data(wr_data),
        .rd_data(rd_data),
        .rd_en(rd_en),
        .full(full),
        .empty(empty),
        .done(done),
        .int_done(int_done),
        .sclk(spi_sclk),
        .mosi(spi_mosi),
        .miso(spi_miso),
        .cs(spi_cs)
    );

    // SPI Slave
    spi_slave #(
        .DATA_WIDTH(8)
    ) slave (
        .clk(clk),
        .rst(rst),
        .sclk(spi_sclk),
        .mosi(spi_mosi),
        .miso(spi_miso),
        .cs(spi_cs),
        .cpol(cpol),
        .cpha(cpha),
        .lsb_first(lsb_first),
        .tx_data(tx_data),       // Use tx_data from testbench
        .rx_data(slave_rx_data)
    );

    // Connect slave_rx_data to rx_data for testbench
    assign rx_data = slave_rx_data;

endmodule