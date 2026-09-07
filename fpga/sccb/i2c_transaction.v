`timescale 1ns / 1ps

module i2c_transaction (
    input             clk,
    input             resetn,

    // 상위 SCCB FSM 입력
    input             start,      // 1-clock pulse
    input      [ 6:0] addr,       // OV7670: 7'h21
    input      [15:0] tdr,        // {register_addr, register_data}

    output reg         tr_done,   // 전체 transaction 완료 pulse
    output             tr_busy,

    // I2C_Master_top command interface
    output reg         cmd_start,
    output reg         cmd_write,
    output reg         cmd_read,
    output reg         cmd_stop,
    output reg         ack_in,
    input              ack_out,
    output reg  [ 7:0] tx_data,
    input       [ 7:0] rx_data,   // 현재 write-only에서는 미사용
    input              done,
    input              busy
);

  localparam [3:0]
      IDLE       = 4'd0,
      START_CMD  = 4'd1,
      START_WAIT = 4'd2,
      DEV_CMD    = 4'd3,
      DEV_WAIT   = 4'd4,
      REG_CMD    = 4'd5,
      REG_WAIT   = 4'd6,
      DATA_CMD   = 4'd7,
      DATA_WAIT  = 4'd8,
      STOP_CMD   = 4'd9,
      STOP_WAIT  = 4'd10;

  reg [3:0] state;

  // 트랜잭션 도중 ROM 주소가 바뀌어도 현재 값을 안전하게 유지
  reg [6:0]  addr_r;
  reg [15:0] tdr_r;

  assign tr_busy = (state != IDLE);

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      state     <= IDLE;
      addr_r    <= 7'd0;
      tdr_r     <= 16'd0;

      cmd_start <= 1'b0;
      cmd_write <= 1'b0;
      cmd_read  <= 1'b0;
      cmd_stop  <= 1'b0;
      ack_in    <= 1'b1;
      tx_data   <= 8'd0;
      tr_done   <= 1'b0;
    end else begin
      // Master에 전달할 command는 모두 1-clock pulse
      cmd_start <= 1'b0;
      cmd_write <= 1'b0;
      cmd_read  <= 1'b0;
      cmd_stop  <= 1'b0;
      tr_done   <= 1'b0;

      case (state)
        IDLE: begin
          if (start) begin
            addr_r <= addr;
            tdr_r  <= tdr;
            state  <= START_CMD;
          end
        end

        // START
        START_CMD: begin
          cmd_start <= 1'b1;
          state     <= START_WAIT;
        end

        START_WAIT: begin
          if (done)
            state <= DEV_CMD;
        end

        // Slave address + Write bit
        DEV_CMD: begin
          cmd_write <= 1'b1;
          tx_data   <= {addr_r, 1'b0};  // OV7670: 8'h42
          state     <= DEV_WAIT;
        end

        DEV_WAIT: begin
          if (done) begin
            if (ack_out == 1'b0)  // slave ACK
              state <= REG_CMD;
            else                  // NACK여도 bus 해제는 해야 함
              state <= STOP_CMD;
          end
        end

        // Camera register address
        REG_CMD: begin
          cmd_write <= 1'b1;
          tx_data   <= tdr_r[15:8];
          state     <= REG_WAIT;
        end

        REG_WAIT: begin
          if (done) begin
            if (ack_out == 1'b0)
              state <= DATA_CMD;
            else
              state <= STOP_CMD;
          end
        end

        // Register data
        DATA_CMD: begin
          cmd_write <= 1'b1;
          tx_data   <= tdr_r[7:0];
          state     <= DATA_WAIT;
        end

        DATA_WAIT: begin
          if (done)
            state <= STOP_CMD;
        end

        // STOP
        STOP_CMD: begin
          cmd_stop <= 1'b1;
          state    <= STOP_WAIT;
        end

        STOP_WAIT: begin
          // I2C_Master_top의 STOP 완료 기준이 busy=0인 구조
          if (!busy) begin
            tr_done <= 1'b1;
            state   <= IDLE;
          end
        end

        default: state <= IDLE;
      endcase
    end
  end

endmodule