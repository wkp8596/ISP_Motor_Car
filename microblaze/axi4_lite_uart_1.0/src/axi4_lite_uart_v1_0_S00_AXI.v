
`timescale 1 ns / 1 ps

module axi4_lite_uart_v1_0_S00_AXI #(
    // Users to add parameters here

    // User parameters ends
    // Do not modify the parameters beyond this line

    // Width of S_AXI data bus
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    // Width of S_AXI address bus
    parameter integer C_S_AXI_ADDR_WIDTH = 4
) (
    // Users to add ports here

    output wire       motor_fsm_tx_send_cu_uart,  // start trigger
    output wire [7:0] motor_fsm_tx_data_cu_uart,

    input wire       cu_uart_tx_busy_motor_fsm,
    input wire [7:0] cu_uart_rx_data_motor_fsm,
    input wire       cu_uart_rx_done_motor_fsm,

    output wire        intr,
    output wire [15:0] baud_div,
    // User ports ends
    // Do not modify the ports beyond this line

    // Global Clock Signal
    input wire S_AXI_ACLK,
    // Global Reset Signal. This Signal is Active LOW
    input wire S_AXI_ARESETN,
    // Write address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_AWADDR,
    // Write channel Protection type. This signal indicates the
    // privilege and security level of the transaction, and whether
    // the transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_AWPROT,
    // Write address valid. This signal indicates that the master signaling
    // valid write address and control information.
    input wire S_AXI_AWVALID,
    // Write address ready. This signal indicates that the slave is ready
    // to accept an address and associated control signals.
    output wire S_AXI_AWREADY,
    // Write data (issued by master, acceped by Slave) 
    input wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_WDATA,
    // Write strobes. This signal indicates which byte lanes hold
    // valid data. There is one write strobe bit for each eight
    // bits of the write data bus.    
    input wire [(C_S_AXI_DATA_WIDTH/8)-1 : 0] S_AXI_WSTRB,
    // Write valid. This signal indicates that valid write
    // data and strobes are available.
    input wire S_AXI_WVALID,
    // Write ready. This signal indicates that the slave
    // can accept the write data.
    output wire S_AXI_WREADY,
    // Write response. This signal indicates the status
    // of the write transaction.
    output wire [1 : 0] S_AXI_BRESP,
    // Write response valid. This signal indicates that the channel
    // is signaling a valid write response.
    output wire S_AXI_BVALID,
    // Response ready. This signal indicates that the master
    // can accept a write response.
    input wire S_AXI_BREADY,
    // Read address (issued by master, acceped by Slave)
    input wire [C_S_AXI_ADDR_WIDTH-1 : 0] S_AXI_ARADDR,
    // Protection type. This signal indicates the privilege
    // and security level of the transaction, and whether the
    // transaction is a data access or an instruction access.
    input wire [2 : 0] S_AXI_ARPROT,
    // Read address valid. This signal indicates that the channel
    // is signaling valid read address and control information.
    input wire S_AXI_ARVALID,
    // Read address ready. This signal indicates that the slave is
    // ready to accept an address and associated control signals.
    output wire S_AXI_ARREADY,
    // Read data (issued by slave)
    output wire [C_S_AXI_DATA_WIDTH-1 : 0] S_AXI_RDATA,
    // Read response. This signal indicates the status of the
    // read transfer.
    output wire [1 : 0] S_AXI_RRESP,
    // Read valid. This signal indicates that the channel is
    // signaling the required read data.
    output wire S_AXI_RVALID,
    // Read ready. This signal indicates that the master can
    // accept the read data and response information.
    input wire S_AXI_RREADY
);

    /*
	UART_CR[0] : RXNEIE // rxne interrupt enable, rw
    UART_CR[1] : UE // uart enable, rw

    UART_SR[0] : RXNE // rxne, w1c sticky
                        // rx_done 발생 시 set
                        // UART_SR[0]에 1 write 또는 UART_DR read 시 clear

    UART_SR[1] : TXE // txe, ro
                        // tx data가 비어있으면 1
                        // tx_busy 동안 0

    UART_SR[2] : TC // transmission complete, w1c sticky
                        // stop bit까지 송신 완료 시 set
                        // UART_SR[2]에 1 write 또는 UART_DR write 시 clear

    UART_DR[7:0] : Rx/Tx Data // data[7:0] rw
                                // write : tx_data 저장 + tx_start pulse 발생
                                // UE=0 또는 TXE=0일 때 write하면 SLVERR
                                // read  : rx_data 반환

    UART_BRR[15:0] : BAUD_DIV // baud rate divider, rw
                                    // baud tick 생성 주기 설정
                                    // baud_div = f_clk / (baudrate * 16)

	UART Interrupt
	1. intr = RXNEIE & RXNE
	*/

    // AXI4LITE signals
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_awaddr;
    reg axi_awready;
    reg axi_wready;
    reg [1 : 0] axi_bresp;
    reg axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1 : 0] axi_araddr;
    reg axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1 : 0] axi_rdata;
    reg [1 : 0] axi_rresp;
    reg axi_rvalid;

    // Example-specific design signals
    // local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
    // ADDR_LSB is used for addressing 32/64 bit registers/memories
    // ADDR_LSB = 2 for 32 bits (n downto 2)
    // ADDR_LSB = 3 for 64 bits (n downto 3)
    localparam integer ADDR_LSB = (C_S_AXI_DATA_WIDTH / 32) + 1;
    localparam integer OPT_MEM_ADDR_BITS = 1;
    //----------------------------------------------
    //-- Signals for user logic register space example
    //------------------------------------------------
    //-- Number of Slave Registers 4
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg0;  // cr
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg1;  // sr
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg2;  // dr
    reg [C_S_AXI_DATA_WIDTH-1:0] slv_reg3;
    wire slv_reg_rden;
    wire slv_reg_wren;
    reg [C_S_AXI_DATA_WIDTH-1:0] reg_data_out;
    integer i;
    reg aw_en;
    wire rxneie;
    wire ue;

    // I/O Connections assignments

    assign S_AXI_AWREADY = axi_awready;
    assign S_AXI_WREADY  = axi_wready;
    assign S_AXI_BRESP   = axi_bresp;
    assign S_AXI_BVALID  = axi_bvalid;
    assign S_AXI_ARREADY = axi_arready;
    assign S_AXI_RDATA   = axi_rdata;
    assign S_AXI_RRESP   = axi_rresp;
    assign S_AXI_RVALID  = axi_rvalid;
    // Implement axi_awready generation
    // axi_awready is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
    // de-asserted when reset is low.


    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awready <= 1'b0;
            aw_en <= 1'b1;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                // slave is ready to accept write address when 
                // there is a valid write address and write data
                // on the write address and data bus. This design 
                // expects no outstanding transactions. 
                axi_awready <= 1'b1;
                aw_en <= 1'b0;
            end else if (S_AXI_BREADY && axi_bvalid) begin
                aw_en <= 1'b1;
                axi_awready <= 1'b0;
            end else begin
                axi_awready <= 1'b0;
            end
        end
    end

    // Implement axi_awaddr latching
    // This process is used to latch the address when both 
    // S_AXI_AWVALID and S_AXI_WVALID are valid. 

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_awaddr <= 0;
        end else begin
            if (~axi_awready && S_AXI_AWVALID && S_AXI_WVALID && aw_en) begin
                // Write Address latching 
                axi_awaddr <= S_AXI_AWADDR;
            end
        end
    end

    // Implement axi_wready generation
    // axi_wready is asserted for one S_AXI_ACLK clock cycle when both
    // S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
    // de-asserted when reset is low. 

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_wready <= 1'b0;
        end else begin
            if (~axi_wready && S_AXI_WVALID && S_AXI_AWVALID && aw_en) begin
                // slave is ready to accept write data when 
                // there is a valid write address and write data
                // on the write address and data bus. This design 
                // expects no outstanding transactions. 
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end
        end
    end

    // Implement memory mapped register select and write logic generation
    // The write data is accepted and written to memory mapped registers when
    // axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
    // select byte enables of slave registers while writing.
    // These registers are cleared when reset (active low) is applied.
    // Slave register write enable is asserted when valid address and data are available
    // and the slave is ready to accept the write address and write data.
    assign slv_reg_wren = axi_wready && S_AXI_WVALID && axi_awready && S_AXI_AWVALID;
    reg start;

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            slv_reg0 <= 0;  // UART_CR
            // slv_reg1 <= 0; // UART_SR
            slv_reg2 <= 0;  // UART_DR
            slv_reg3 <= 0;
        end else begin
            if (slv_reg_wren) begin
                case (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
                    2'h0:
                    for (i = 0; i <= (C_S_AXI_DATA_WIDTH / 8) - 1; i = i + 1)
                    if (S_AXI_WSTRB[i] == 1) begin
                        // Respective byte enables are asserted as per write strobes 
                        // Slave register 0
                        slv_reg0[(i*8)+:8] <= S_AXI_WDATA[(i*8)+:8];
                    end
                    // 2'h1:
                    // for (i = 0; i <= (C_S_AXI_DATA_WIDTH / 8) - 1; i = i + 1)
                    // if (S_AXI_WSTRB[i] == 1) begin
                    //     // Respective byte enables are asserted as per write strobes 
                    //     // Slave register 1
                    //     slv_reg1[(i*8)+:8] <= S_AXI_WDATA[(i*8)+:8];
                    // end
                    2'h2:
                    if (ue && !cu_uart_tx_busy_motor_fsm) begin
                        for (i = 0; i <= (C_S_AXI_DATA_WIDTH / 8) - 1; i = i + 1)
                        if (S_AXI_WSTRB[i] == 1) begin
                            // Respective byte enables are asserted as per write strobes 
                            // Slave register 2
                            slv_reg2[(i*8)+:8] <= S_AXI_WDATA[(i*8)+:8];
                        end
                    end
                    2'h3:
                    for (i = 0; i <= (C_S_AXI_DATA_WIDTH / 8) - 1; i = i + 1)
                    if (S_AXI_WSTRB[i] == 1) begin
                        // Respective byte enables are asserted as per write strobes 
                        // Slave register 3
                        slv_reg3[(i*8)+:8] <= S_AXI_WDATA[(i*8)+:8];
                    end
                    default: begin
                        slv_reg0 <= slv_reg0;
                        // slv_reg1 <= slv_reg1;
                        slv_reg2 <= slv_reg2;
                        // slv_reg3 <= slv_reg3;
                    end
                endcase
            end
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            start <= 1'b0;
        end else begin
            start <= 1'b0;
            if (slv_reg_wren &&
            (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h2) &&
            S_AXI_WSTRB[0] && ue && !cu_uart_tx_busy_motor_fsm) begin
                start <= 1'b1;
            end
        end
    end


    assign rxneie = slv_reg0[0];
    assign ue = slv_reg0[1];

    assign motor_fsm_tx_send_cu_uart = ue & start;
    assign motor_fsm_tx_data_cu_uart = slv_reg2[7:0];
    assign baud_div = slv_reg3[15:0];

    // Implement write response logic generation
    // The write response and response valid signals are asserted by the slave 
    // when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
    // This marks the acceptance of address and indicates the status of 
    // write transaction.

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_bvalid <= 0;
            axi_bresp  <= 2'b0;
        end else begin
            if (axi_awready && S_AXI_AWVALID && ~axi_bvalid && axi_wready && S_AXI_WVALID)
	        begin
                // indicates a valid write response is available
                axi_bvalid <= 1'b1;
                if ((axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h2) &&
                    S_AXI_WSTRB[0] && (!ue || cu_uart_tx_busy_motor_fsm)) begin
                    axi_bresp <= 2'b10;  // SLVERR: UART disabled or transmitter busy
                end else begin
                    axi_bresp <= 2'b00;  // OKAY
                end
            end                   // work error responses in future
	      else
	        begin
                if (S_AXI_BREADY && axi_bvalid) 
	            //check if bready is asserted while bvalid is high) 
	            //(there is a possibility that bready is always asserted high)   
	            begin
                    axi_bvalid <= 1'b0;
                end
            end
        end
    end

    // Implement axi_arready generation
    // axi_arready is asserted for one S_AXI_ACLK clock cycle when
    // S_AXI_ARVALID is asserted. axi_awready is 
    // de-asserted when reset (active low) is asserted. 
    // The read address is also latched when S_AXI_ARVALID is 
    // asserted. axi_araddr is reset to zero on reset assertion.

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_arready <= 1'b0;
            axi_araddr  <= {C_S_AXI_ADDR_WIDTH{1'b0}};
        end else begin
            if (~axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                // indicates that the slave has acceped the valid read address
                axi_arready <= 1'b1;
                // Read address latching
                axi_araddr  <= S_AXI_ARADDR;
            end else begin
                axi_arready <= 1'b0;
            end
        end
    end

    // Implement axi_arvalid generation
    // axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
    // S_AXI_ARVALID and axi_arready are asserted. The slave registers 
    // data are available on the axi_rdata bus at this instance. The 
    // assertion of axi_rvalid marks the validity of read data on the 
    // bus and axi_rresp indicates the status of read transaction.axi_rvalid 
    // is deasserted on reset (active low). axi_rresp and axi_rdata are 
    // cleared to zero on reset (active low).  


    reg  rxne_sticky;
    reg  tc_sticky;
    reg  tx_busy_d;
    wire txe;
    wire tx_dr_write_accepted;
    wire rx_dr_read;

    assign txe  = ~cu_uart_tx_busy_motor_fsm;
    assign intr = rxneie & rxne_sticky;
    assign tx_dr_write_accepted = slv_reg_wren &&
        (axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h2) &&
        S_AXI_WSTRB[0] && ue && !cu_uart_tx_busy_motor_fsm;
    assign rx_dr_read = slv_reg_rden &&
        (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h2);

    always @(posedge S_AXI_ACLK) begin
        if (!S_AXI_ARESETN) begin
            rxne_sticky <= 1'b0;
            tc_sticky   <= 1'b0;
            tx_busy_d   <= 1'b0;
        end else begin
            tx_busy_d <= cu_uart_tx_busy_motor_fsm;
            if (slv_reg_wren && axi_awaddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB] == 2'h1 && S_AXI_WSTRB[0]) begin
                if (S_AXI_WDATA[0]) rxne_sticky <= 1'b0;
                if (S_AXI_WDATA[2]) tc_sticky <= 1'b0;
            end
            if (rx_dr_read) rxne_sticky <= 1'b0;
            if (ue && cu_uart_rx_done_motor_fsm) rxne_sticky <= 1'b1;
            if (tx_busy_d && !cu_uart_tx_busy_motor_fsm) tc_sticky <= 1'b1;
            if (tx_dr_write_accepted) tc_sticky <= 1'b0;
        end
    end

    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rvalid <= 0;
            axi_rresp  <= 0;
        end else begin
            if (axi_arready && S_AXI_ARVALID && ~axi_rvalid) begin
                // Valid read data is available at the read data bus
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b0;  // 'OKAY' response
            end else if (axi_rvalid && S_AXI_RREADY) begin
                // Read data is accepted by the master
                axi_rvalid <= 1'b0;
            end
        end
    end

    // Implement memory mapped register select and read logic generation
    // Slave register read enable is asserted when valid address is available
    // and the slave is ready to accept the read address.
    assign slv_reg_rden = axi_arready & S_AXI_ARVALID & ~axi_rvalid;
    always @(*) begin
        // Address decoding for reading registers
        case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
            2'h0   : reg_data_out = slv_reg0;
            2'h1   : reg_data_out = {29'd0, tc_sticky, txe, rxne_sticky};
            2'h2   : reg_data_out = {24'd0, cu_uart_rx_data_motor_fsm};
            2'h3   : reg_data_out = slv_reg3;
            default : reg_data_out = 0;
        endcase
    end

    // Output register or memory read data
    always @(posedge S_AXI_ACLK) begin
        if (S_AXI_ARESETN == 1'b0) begin
            axi_rdata <= 0;
        end else begin
            // When there is a valid read address (S_AXI_ARVALID) with 
            // acceptance of read address by the slave (axi_arready), 
            // output the read dada 
            if (slv_reg_rden) begin
                axi_rdata <= reg_data_out;  // register read data
            end
        end
    end

    // Add user logic here

    // User logic ends

endmodule
