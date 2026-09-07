
`timescale 1 ns / 1 ps

module axi4_lite_uart_v1_0 #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line


    // Parameters of Axi Slave Bus Interface S00_AXI
    parameter integer C_S00_AXI_DATA_WIDTH = 32,
    parameter integer C_S00_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here
    input  wire u_rx,
    output wire u_tx,
    output wire u_intr,
    // User ports ends
    // Do not modify the ports beyond this line


    // Ports of Axi Slave Bus Interface S00_AXI
    input wire s00_axi_aclk,
    input wire s00_axi_aresetn,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_awaddr,
    input wire [2 : 0] s00_axi_awprot,
    input wire s00_axi_awvalid,
    output wire s00_axi_awready,
    input wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_wdata,
    input wire [(C_S00_AXI_DATA_WIDTH/8)-1 : 0] s00_axi_wstrb,
    input wire s00_axi_wvalid,
    output wire s00_axi_wready,
    output wire [1 : 0] s00_axi_bresp,
    output wire s00_axi_bvalid,
    input wire s00_axi_bready,
    input wire [C_S00_AXI_ADDR_WIDTH-1 : 0] s00_axi_araddr,
    input wire [2 : 0] s00_axi_arprot,
    input wire s00_axi_arvalid,
    output wire s00_axi_arready,
    output wire [C_S00_AXI_DATA_WIDTH-1 : 0] s00_axi_rdata,
    output wire [1 : 0] s00_axi_rresp,
    output wire s00_axi_rvalid,
    input wire s00_axi_rready
);
    wire [15:0] baud_div;

    wire        motor_fsm_tx_send_cu_uart;
    wire [ 7:0] motor_fsm_tx_data_cu_uart;

    wire        cu_uart_tx_busy_motor_fsm;
    wire [ 7:0] cu_uart_rx_data_motor_fsm;
    wire        cu_uart_rx_done_motor_fsm;

    // Instantiation of Axi Bus Interface S00_AXI
    axi4_lite_uart_v1_0_S00_AXI #(
        .C_S_AXI_DATA_WIDTH(C_S00_AXI_DATA_WIDTH),
        .C_S_AXI_ADDR_WIDTH(C_S00_AXI_ADDR_WIDTH)
    ) axi4_lite_uart_v1_0_S00_AXI_inst (

        // UART interface
        .motor_fsm_tx_send_cu_uart(motor_fsm_tx_send_cu_uart),
        .motor_fsm_tx_data_cu_uart(motor_fsm_tx_data_cu_uart),

        .cu_uart_tx_busy_motor_fsm(cu_uart_tx_busy_motor_fsm),
        .cu_uart_rx_data_motor_fsm(cu_uart_rx_data_motor_fsm),
        .cu_uart_rx_done_motor_fsm(cu_uart_rx_done_motor_fsm),

        .baud_div(baud_div),
        .intr(u_intr),

        .S_AXI_ACLK(s00_axi_aclk),
        .S_AXI_ARESETN(s00_axi_aresetn),
        .S_AXI_AWADDR(s00_axi_awaddr),
        .S_AXI_AWPROT(s00_axi_awprot),
        .S_AXI_AWVALID(s00_axi_awvalid),
        .S_AXI_AWREADY(s00_axi_awready),
        .S_AXI_WDATA(s00_axi_wdata),
        .S_AXI_WSTRB(s00_axi_wstrb),
        .S_AXI_WVALID(s00_axi_wvalid),
        .S_AXI_WREADY(s00_axi_wready),
        .S_AXI_BRESP(s00_axi_bresp),
        .S_AXI_BVALID(s00_axi_bvalid),
        .S_AXI_BREADY(s00_axi_bready),
        .S_AXI_ARADDR(s00_axi_araddr),
        .S_AXI_ARPROT(s00_axi_arprot),
        .S_AXI_ARVALID(s00_axi_arvalid),
        .S_AXI_ARREADY(s00_axi_arready),
        .S_AXI_RDATA(s00_axi_rdata),
        .S_AXI_RRESP(s00_axi_rresp),
        .S_AXI_RVALID(s00_axi_rvalid),
        .S_AXI_RREADY(s00_axi_rready)
    );

    // Add user logic here
    uart_top U_UART (
        .clk   (s00_axi_aclk),
        .resetn(s00_axi_aresetn),

        .motor_fsm_tx_send_cu_uart(motor_fsm_tx_send_cu_uart),
        .motor_fsm_tx_data_cu_uart(motor_fsm_tx_data_cu_uart),

        .cu_uart_tx_busy_motor_fsm(cu_uart_tx_busy_motor_fsm),
        .cu_uart_rx_data_motor_fsm(cu_uart_rx_data_motor_fsm),
        .cu_uart_rx_done_motor_fsm(cu_uart_rx_done_motor_fsm),
        .baud_div(baud_div),

        .dp_uart_rx_cu_uart(u_rx),
        .cu_uart_tx_dp_uart(u_tx)
    );
    // User logic ends

endmodule
