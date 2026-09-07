`timescale 1ns / 1ps

module button_debounce (
    input  clk,
    input  resetn,
    input  i_btn,
    output o_btn
);

  // clk divider
  // 100Mhz -> 100khz
  parameter f_count = 100_000_000 / 100_000;
  reg [$clog2(f_count)-1 : 0] r_counter;
  reg clk_100khz;

  always @(posedge clk, negedge resetn) begin
    if (!resetn) begin
      r_counter  <= 0;
      clk_100khz <= 1'b0;
    end else begin
      r_counter <= r_counter + 1;
      if (r_counter == f_count - 1) begin
        r_counter  <= 0;
        clk_100khz <= 1'b1;
      end else begin
        clk_100khz <= 1'b0;
      end
    end

  end

  // synchronizer 
  reg [7:0] sync_reg, sync_next;
  wire debounce;

  always @(posedge clk_100khz, negedge resetn) begin
    if (!resetn) begin
      sync_reg <= 8'b0;
    end else begin
      sync_reg <= sync_next;
    end
  end

  always @(*) begin  //shift register
    sync_next = {i_btn, sync_reg[7:1]};
    // sync_next = {sync_reg[6:0], i_btn};
  end

  assign debounce = &sync_reg;  // 8x1 debouncer

  //rising edge detect
  reg edge_reg;
  always @(posedge clk, negedge resetn) begin
    if (!resetn) begin
      edge_reg <= 1'b0;
    end else begin
      edge_reg <= debounce;
    end
  end

  assign o_btn = debounce & ~(edge_reg);


endmodule

/*module clk_tick_gen (
    input      clk,
    input      rst,
    output reg o_tick
);
    // counter = 100_000_000 / 10 : 100Mhz -> 10hz 100Khz
    reg [$clog2(100_000_000/100_000)-1:0] counter_reg;


    always @(posedge clk, posedge rst) begin
        if (rst) begin
            counter_reg <= 24'd0;
            o_tick      <= 1'b0;
        end else begin
                counter_reg <= counter_reg + 1;
                o_tick      <= 1'b0;
                if (counter_reg == (1000 - 1)) begin
                    counter_reg <= 24'd0;
                    o_tick <= 1'b1;
                end
            end
        end
    
endmodule*/
