`timescale 1ns / 1ps

module x_axis_decoder(

input clk,
input rst_n,

input [9:0] frame_reader_x_axis_x_axis_decoder,
input [9:0] frame_reader_y_axis_x_axis_decoder,
input       sobel_frame_buffer_wdata_x_axis_decoder,

output reg       x_axis_decoder_start_dp_uart,
output reg [7:0] x_axis_decoder_tx_data_dp_uart

);

localparam Y_START = 10'd150;
localparam Y_END   = 10'd181;

localparam X_START = 10'd30;
localparam X_END   = 10'd289;

localparam IDLE       = 3'd0;
localparam LINE_ACC   = 3'd1;
localparam LINE_DONE  = 3'd2;
localparam WAIT_START = 3'd3;
localparam FINAL_AVG  = 3'd4;
localparam SEND       = 3'd5;

reg [2:0] state;

reg found_first;

reg [9:0] first_x;
reg [9:0] last_x;

reg [14:0] center_sum;
reg [9:0]  final_center;

always @(posedge clk or negedge rst_n) begin

    if(!rst_n) begin

        state <= IDLE;

        found_first <= 1'b0;

        first_x <= 10'd0;
        last_x  <= 10'd0;

        center_sum <= 15'd0;
        final_center <= 10'd0;

        x_axis_decoder_tx_data_dp_uart <= 8'd0;
        x_axis_decoder_start_dp_uart   <= 1'b0;

    end
    else begin

        x_axis_decoder_start_dp_uart <= 1'b0;

        case(state)

        IDLE:
        begin

            found_first <= 1'b0;

            first_x <= 10'd0;
            last_x  <= 10'd0;

            center_sum <= 15'd0;

            if(frame_reader_y_axis_x_axis_decoder == Y_START &&
               frame_reader_x_axis_x_axis_decoder == X_START)
            begin
                state <= LINE_ACC;
            end

        end

        LINE_ACC:
        begin

            if(frame_reader_x_axis_x_axis_decoder >= X_START &&
               frame_reader_x_axis_x_axis_decoder <= X_END)
            begin

                if(sobel_frame_buffer_wdata_x_axis_decoder) begin

                    if(!found_first) begin
                        first_x <= frame_reader_x_axis_x_axis_decoder;
                        found_first <= 1'b1;
                    end

                    last_x <= frame_reader_x_axis_x_axis_decoder;

                end

            end

            if(frame_reader_x_axis_x_axis_decoder == X_END)
                state <= LINE_DONE;

        end

        LINE_DONE:
        begin

            if(found_first)
                center_sum <= center_sum + ((first_x + last_x) >> 1);

            found_first <= 1'b0;

            first_x <= 10'd0;
            last_x  <= 10'd0;

            if(frame_reader_y_axis_x_axis_decoder == Y_END)
                state <= FINAL_AVG;
            else
                state <= WAIT_START;

        end

        WAIT_START:
        begin

            if(frame_reader_y_axis_x_axis_decoder >= Y_START &&
               frame_reader_y_axis_x_axis_decoder <= Y_END &&
               frame_reader_x_axis_x_axis_decoder == X_START)
            begin
                state <= LINE_ACC;
            end

        end

        FINAL_AVG:
        begin

            final_center <= center_sum >> 5;      // /32

            state <= SEND;

        end

        SEND:
        begin

            x_axis_decoder_tx_data_dp_uart <= final_center[9:1];
            x_axis_decoder_start_dp_uart   <= 1'b1;

            state <= IDLE;

        end

        default:
            state <= IDLE;

        endcase

    end

end

endmodule
