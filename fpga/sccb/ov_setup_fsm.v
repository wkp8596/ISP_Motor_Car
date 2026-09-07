`timescale 1ns / 1ps

module ov_setup_fsm (
    input clk,
    input resetn,

    input start_pulse,  // debounce/one-pulse를 거친 버튼
    input tr_done,      // i2c_transaction 완료 pulse

    output           start,       // i2c_transaction 시작 pulse
    output reg [6:0] setup_addr,  // ROM address
    output reg       config_done
);

  // ROM의 마지막 주소: rom[0:75]
  localparam [6:0] LAST_ROM_ADDR = 7'd75;

  // clk=100 MHz 기준 1 ms
  localparam [16:0] DELAY_CYCLES = 17'd100_000;

  localparam [2:0] IDLE = 3'd0, WAIT = 3'd1, DELAY = 3'd2, DONE = 3'd3;

  reg [2:0] c_state, n_state;
  reg start_reg, start_next;
  reg [6:0] setup_addr_next;
  reg [16:0] delay_cnt, delay_cnt_next;
  reg config_done_next;

  assign start = start_reg;

  // Register update
  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      c_state     <= IDLE;
      start_reg   <= 1'b0;
      setup_addr  <= 7'd0;
      delay_cnt   <= 17'd0;
      config_done <= 1'b0;
    end else begin
      c_state     <= n_state;
      start_reg   <= start_next;
      setup_addr  <= setup_addr_next;
      delay_cnt   <= delay_cnt_next;
      config_done <= config_done_next;
    end
  end

  // Next-state logic
  always @(*) begin
    n_state          = c_state;
    start_next       = 1'b0;  // 기본값: 1-clock pulse
    setup_addr_next  = setup_addr;
    delay_cnt_next   = delay_cnt;
    config_done_next = config_done;

    case (c_state)
      IDLE: begin
        config_done_next = 1'b0;

        if (start_pulse) begin
          setup_addr_next = 7'd0;
          start_next      = 1'b1;  // 첫 ROM 설정값 전송 요청
          n_state         = WAIT;
        end
      end

      // i2c_transaction이 START → 42 → reg → data → STOP을 끝낼 때까지 대기
      WAIT: begin
        if (tr_done) begin
          if (setup_addr == LAST_ROM_ADDR) begin
            config_done_next = 1'b1;
            n_state          = DONE;
          end else begin
            setup_addr_next = setup_addr + 1'b1;
            delay_cnt_next  = 17'd0;
            n_state         = DELAY;
          end
        end
      end

      DELAY: begin
        if (delay_cnt == DELAY_CYCLES - 1'b1) begin
          start_next = 1'b1;  // 다음 ROM 줄 전송 요청
          n_state    = WAIT;
        end else begin
          delay_cnt_next = delay_cnt + 1'b1;
        end
      end

      DONE: begin
        // 버튼을 다시 누르면 처음부터 재설정
        if (start_pulse) begin
          config_done_next = 1'b0;
          setup_addr_next  = 7'd0;
          start_next       = 1'b1;
          n_state          = WAIT;
        end
      end

      default: begin
        n_state = IDLE;
      end
    endcase
  end

endmodule
