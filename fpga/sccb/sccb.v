`timescale 1ns / 1ps

module sccb (
    input  clk,
    input  resetn,
    input  button_i_btn_sccb,
    output sccb_scl_ov7670,
    inout  sccb_sda_ov7670
);
  wire w_o_btn;
  wire cmd_start, cmd_write, cmd_read, cmd_stop;
  wire [7:0] tx_data, rx_data;
  wire ack_in, ack_out;
  wire i2c_busy, i2c_done;
  wire        start;
  wire [ 6:0] setup_addr;
  wire [15:0] setup_data;
  wire        tr_done;
  wire        config_done;
  // ov7670 Slave address
  parameter OV7670_ADDR = 7'h21;

  i2c_transaction U_i2c_transaction (
      .clk    (clk),
      .resetn (resetn),
      .start  (start),
      .addr   (OV7670_ADDR),
      .tdr    (setup_data),
      .tr_done(tr_done),
      .tr_busy(tr_busy),

      .cmd_start(cmd_start),
      .cmd_write(cmd_write),
      .cmd_read (cmd_read),
      .cmd_stop (cmd_stop),
      .ack_in   (ack_in),
      .ack_out  (ack_out),
      .tx_data  (tx_data),
      .rx_data  (rx_data),
      .done     (i2c_done),
      .busy     (i2c_busy)
  );

  I2C_Master_top U_I2C_Master_top (
      .clk   (clk),
      .resetn(resetn),

      .cmd_start(cmd_start),
      .cmd_write(cmd_write),
      .cmd_read (cmd_read),
      .cmd_stop (cmd_stop),

      .tx_data(tx_data),
      .rx_data(rx_data),
      .ack_in (ack_in),
      .ack_out(ack_out),
      .busy   (i2c_busy),
      .done   (i2c_done),

      .scl(sccb_scl_ov7670),
      .sda(sccb_sda_ov7670)
  );

  ov_setup_fsm U_ov_setup_fsm (
      .clk        (clk),
      .resetn     (resetn),
      .start_pulse(w_o_btn),
      .tr_done    (tr_done),

      .start      (start),
      .setup_addr (setup_addr),
      .config_done(config_done)
  );

  ov7670_setup_rom U_ov7670_setup_rom (
      .addr(setup_addr),
      .data(setup_data)
  );

  button_debounce U_button_debounce (
      .clk(clk),
      .resetn(resetn),
      .i_btn(button_i_btn_sccb),
      .o_btn(w_o_btn)
  );

endmodule
