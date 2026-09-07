`timescale 1ns / 1ps

module uart_rx (
    input  wire       clk,
    input  wire       resetn,
    input  wire       rx,
    input  wire       b_tick,
    output wire [7:0] rx_data,
    output wire       rx_done
);

    // wire b_tick;

    // baud_tick_gen_rx U_BAUD_TICK_GEN_RX (
    //     .clk(clk),
    //     .resetn(resetn),
    //     .o_b_tick(b_tick)
    // );

    parameter IDLE = 0, START = 1, DATA = 2, STOP = 3;
    reg [1:0] c_state, n_state;
    reg [4:0] b_tick_cnt_reg, b_tick_cnt_next;
    reg [2:0] bit_cnt_reg, bit_cnt_next;
    reg [7:0] shift_reg, shift_next;
    reg [7:0] rx_data_reg, rx_data_next;
    reg rx_done_reg, rx_done_next;
    reg rx_sync1, rx_sync2;

    assign rx_done = rx_done_reg;
    assign rx_data = rx_data_reg;

    always @(posedge clk or negedge resetn) begin // 매 상승엣지에 같은 타이밍에 처리하기 위함
        if (!resetn) begin
            c_state        <= IDLE;
            b_tick_cnt_reg <= 0;
            bit_cnt_reg    <= 0;
            shift_reg      <= 8'h00;
            rx_data_reg    <= 8'h00;
            rx_done_reg    <= 1'b0;
            rx_sync1       <= 1'b1;
            rx_sync2       <= 1'b1;
        end else begin
            c_state        <= n_state;
            b_tick_cnt_reg <= b_tick_cnt_next;
            bit_cnt_reg    <= bit_cnt_next;
            shift_reg      <= shift_next;
            rx_data_reg    <= rx_data_next;
            rx_done_reg    <= rx_done_next;
            rx_sync1       <= rx;
            rx_sync2       <= rx_sync1;
        end
    end

    always @(*) begin
        n_state = c_state;
        b_tick_cnt_next = b_tick_cnt_reg;
        bit_cnt_next = bit_cnt_reg;
        shift_next = shift_reg;
        rx_data_next = rx_data_reg;
        rx_done_next = 1'b0;
        case (c_state)
            IDLE: begin
                if (b_tick && (!rx_sync2)) begin  //!rx도 가능, &도 가능
                    b_tick_cnt_next = 0;
                    n_state         = START;
                end
            end
            START: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 7) begin // 싱크로나이저만 쓰면 상관없음
                        b_tick_cnt_next = 0;
                        bit_cnt_next    = 0;
                        if (!rx_sync2) begin
                            n_state = DATA;
                        end else begin
                            n_state = IDLE;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

            DATA: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        shift_next = {rx_sync2, shift_reg[7:1]};
                        b_tick_cnt_next = 0;
                        if (bit_cnt_reg == 7) begin
                            b_tick_cnt_next = 0;
                            bit_cnt_next = 0;  // 비트 카운트 초기화
                            n_state = STOP;
                        end else begin
                            bit_cnt_next = bit_cnt_reg + 1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end


            STOP: begin
                if (b_tick) begin
                    if (b_tick_cnt_reg == 15) begin
                        b_tick_cnt_next = 0;
                        n_state = IDLE;
                        if (rx_sync2) begin
                            rx_data_next = shift_reg;
                            rx_done_next = 1'b1;
                        end
                    end else begin
                        b_tick_cnt_next = b_tick_cnt_reg + 1;
                    end
                end
            end

        endcase
    end

endmodule
