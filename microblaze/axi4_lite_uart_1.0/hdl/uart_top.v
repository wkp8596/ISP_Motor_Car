`timescale 1ns / 1ps

/*
UART_CR[0] : RXNEIE // rxne interrupt enable, rw
UART_CR[1] : UE // uart enable, rw

UART_SR[0] : RXNE // rxne, w1c sticky(rx_done 발생 시 set, uart_dr read시 clear) 
UART_SR[1] : TXE // txe, ro(tx data가 비어있으면 1, uart_dr write시 0)
UART_SR[2] : TC // transmission complete, w1c sticky
                    stop bit까지 송신 완료 시 set, 다음 uart_dr write시 clear

UART_DR[7:0] : Rx/Tx Data // data[7:0] rw
                             write : tx_data 저장 + tx_start pulse 발생
                             read : rx_data 반환 + RXNE Clear
UART Interrupt
1. intr = RXNEIE & RXNE
*/

module uart_top (
    input  wire        clk,
    input  wire        resetn,
    input  wire [15:0] baud_div,

    input  wire        motor_fsm_tx_send_cu_uart,  // start trigger
    input  wire [ 7:0] motor_fsm_tx_data_cu_uart,
    output wire        cu_uart_tx_busy_motor_fsm,
    output wire [ 7:0] cu_uart_rx_data_motor_fsm,
    output wire        cu_uart_rx_done_motor_fsm,

    input  wire dp_uart_rx_cu_uart,
    output wire cu_uart_tx_dp_uart
);

    wire b_tick;

    uart_rx U_UART_RX (
        .clk    (clk),
        .resetn (resetn),
        .rx     (dp_uart_rx_cu_uart),
        .b_tick (b_tick),
        .rx_data(cu_uart_rx_data_motor_fsm),
        .rx_done(cu_uart_rx_done_motor_fsm)
    );

    uart_tx U_UART_TX (
        .clk(clk),
        .resetn(resetn),
        .tx_start(motor_fsm_tx_send_cu_uart),  // start trigger
        .tx_data(motor_fsm_tx_data_cu_uart),
        .b_tick(b_tick),
        .tx(cu_uart_tx_dp_uart),
        .tx_busy (cu_uart_tx_busy_motor_fsm) // cu uart에서 dp uart로 tx를 보내는 중
    );

    baud_tick_gen U_BAUD_TICK (
        .clk     (clk),
        .resetn  (resetn),
        .baud_div(baud_div),
        .o_b_tick(b_tick)
    );

endmodule
