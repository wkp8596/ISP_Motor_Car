`timescale 1ns / 1ps

module I2C_Master_top (
    input        clk,
    input        resetn,
    // command port
    input        cmd_start,
    input        cmd_write,
    input        cmd_read,
    input        cmd_stop,
    // internal port
    input  [7:0] tx_data,
    output [7:0] rx_data,
    input        ack_in,     // read 시 master가 보낼 ACK(0)/NACK(1)
    output       ack_out,    // write 시 slave로부터 받은 ACK(0)/NACK(1)
    output       busy,
    output       done,
    // external i2c port
    output       scl,
    inout        sda
);
  wire sda_o, sda_i;

  assign sda_i = sda;
  assign sda   = sda_o ? 1'bz : 1'b0;

  I2C_Master u_i2c_master (
      .clk(clk),
      .resetn(resetn),
      .cmd_start(cmd_start),
      .cmd_write(cmd_write),
      .cmd_read(cmd_read),
      .cmd_stop(cmd_stop),
      .tx_data(tx_data),
      .rx_data(rx_data),
      .ack_in(ack_in),
      .ack_out(ack_out),
      .busy(busy),
      .done(done),
      .scl(scl),
      .sda_o(sda_o),
      .sda_i(sda_i)
  );
endmodule

module I2C_Master (
    input            clk,
    input            resetn,
    // command port
    input            cmd_start,
    input            cmd_write,
    input            cmd_read,
    input            cmd_stop,
    // internal port
    input      [7:0] tx_data,
    output reg [7:0] rx_data,
    input            ack_in,     // read 시 master가 보낼 ACK(0)/NACK(1)
    output reg       ack_out,    // write 시 slave로부터 받은 ACK(0)/NACK(1)
    output           busy,
    output reg       done,
    // external i2c port
    output           scl,
    output           sda_o,
    input            sda_i
);

  parameter IDLE = 0, START = 1, WAIT_CMD = 2, DATA = 3, DATA_ACK = 4, STOP = 5;
  reg [2:0] state;

  reg [7:0] div_cnt;
  reg       qtr_tick;  // 1/4 SCL 주기마다 1clk 펄스
  reg       scl_r;
  reg       sda_r;
  reg [1:0] step;  // 상태 내 쿼터 진행 단계 (0~3)
  reg [7:0] tx_shift_reg;
  reg [7:0] rx_shift_reg;
  reg [2:0] bit_cnt;
  reg       is_read;
  reg       ack_in_r;

  assign scl   = scl_r;
  assign sda_o = sda_r;
  assign busy  = (state != IDLE);

  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      div_cnt  <= 0;
      qtr_tick <= 1'b0;
    end else begin
      if (div_cnt == 250 - 1) begin
        div_cnt  <= 0;
        qtr_tick <= 1'b1;
      end else begin
        div_cnt  <= div_cnt + 1;
        qtr_tick <= 1'b0;
      end
    end
  end


  always @(posedge clk or negedge resetn) begin
    if (!resetn) begin
      state        <= IDLE;
      scl_r        <= 1'b1;  // idle: SCL High
      sda_r        <= 1'b1;  // idle: SDA High (Hi-Z, pull-up high)
      step         <= 0;
      done         <= 1'b0;
      tx_shift_reg <= 0;
      rx_shift_reg <= 0;
      is_read      <= 1'b0;
      bit_cnt      <= 0;
      ack_in_r     <= 1'b1;
    end else begin
      done <= 1'b0;

      case (state)
        IDLE: begin
          scl_r <= 1'b1;
          sda_r <= 1'b1;
          if (cmd_start) begin
            state <= START;
            step  <= 0;
          end
        end
        START: begin
          if (qtr_tick) begin
            case (step)
              2'd0: begin
                sda_r <= 1'b1;
                scl_r <= 1'b1;
                step  <= 2'd1;
              end
              2'd1: begin
                sda_r <= 1'b0;
                scl_r <= 1'b1;
                step  <= 2'd2;
              end
              2'd2: begin
                sda_r <= 1'b0;
                scl_r <= 1'b0;
                step  <= 2'd3;
              end
              2'd3: begin
                sda_r <= 1'b0;
                scl_r <= 1'b0;
                step  <= 2'd0;
                done  <= 1'b1;
                state <= WAIT_CMD;
              end
            endcase
          end
        end
        WAIT_CMD: begin
          if (cmd_write) begin
            tx_shift_reg <= tx_data;
            bit_cnt      <= 0;
            is_read      <= 1'b0;
            state        <= DATA;
          end else if (cmd_read) begin
            rx_shift_reg <= 0;
            bit_cnt      <= 0;
            is_read      <= 1'b1;
            ack_in_r     <= ack_in;
            state        <= DATA;
          end else if (cmd_stop) begin
            state <= STOP;
          end else if (cmd_start) begin
            state <= START;
          end
        end
        DATA: begin
          if (qtr_tick) begin
            case (step)
              2'd0: begin
                step  <= 2'd1;
                scl_r <= 1'b0;
                sda_r <= is_read ? 1'b1 : tx_shift_reg[7];
              end
              2'd1: begin
                step  <= 2'd2;
                scl_r <= 1'b1;
              end
              2'd2: begin
                step  <= 2'd3;
                scl_r <= 1'b1;
                if (is_read) begin
                  rx_shift_reg <= {rx_shift_reg[6:0], sda_i};
                end
              end
              2'd3: begin
                step  <= 2'd0;
                scl_r <= 1'b0;
                if (!is_read) begin
                  tx_shift_reg <= {tx_shift_reg[6:0], 1'b0};
                end
                if (bit_cnt == 7) begin
                  state <= DATA_ACK;
                end else begin
                  bit_cnt <= bit_cnt + 1;
                end
              end
            endcase
          end
        end
        DATA_ACK: begin
          if (qtr_tick) begin
            case (step)
              2'd0: begin
                step  <= 2'd1;
                scl_r <= 1'b0;
                if (is_read) begin
                  sda_r <= ack_in_r;
                end else begin
                  sda_r <= 1'b1;
                end
              end
              2'd1: begin
                step  <= 2'd2;
                scl_r <= 1'b1;
              end
              2'd2: begin
                step  <= 2'd3;
                scl_r <= 1'b1;
                if (!is_read) begin
                  ack_out <= sda_i;
                end else begin
                  rx_data <= rx_shift_reg;
                end
              end
              2'd3: begin
                step  <= 2'd0;
                scl_r <= 1'b0;
                done  <= 1'b1;
                state <= WAIT_CMD;
              end
            endcase
          end
        end
        STOP: begin
          if (qtr_tick) begin
            case (step)
              2'd0: begin
                sda_r <= 1'b0;
                scl_r <= 1'b0;
                step  <= 2'd1;
              end
              2'd1: begin
                sda_r <= 1'b0;
                scl_r <= 1'b1;
                step  <= 2'd2;
              end
              2'd2: begin
                sda_r <= 1'b1;
                scl_r <= 1'b1;
                step  <= 2'd3;
              end
              2'd3: begin
                sda_r <= 1'b1;
                scl_r <= 1'b1;
                step  <= 2'd0;
                done  <= 1'b1;
                state <= IDLE;
              end
            endcase
          end
        end
        default: state <= IDLE;
      endcase
    end
  end
endmodule
