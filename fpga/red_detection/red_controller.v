`timescale 1ns / 1ps
module red_controller #(
    parameter integer IMG_W = 320,
    parameter integer IMG_H = 240,
    parameter integer AW = $clog2(IMG_W * IMG_H + 6),
    parameter integer XW = $clog2(IMG_W)
) (
    input wire clk,
    input wire resetn,

    input wire ov_mem_controller_frame_end_red_controller,

    output wire [AW-1:0] red_controller_raddr_r_frame_buffer,

    output wire red_controller_start_roi,

    output wire       red_controller_we_line_buffer,
    output wire [XW-1:0] red_controller_waddr_line_buffer,
    output wire [XW-1:0] red_controller_raddr_line_buffer,
    output wire [1:0] red_controller_line_sel_line_buffer,

    output wire [ 1:0] red_controller_swap_noise_filter
);
    localparam IDLE = 1'b0;
    localparam MOVE = 1'b1;

    reg state, nstate;
    reg   we_lb;
    reg [AW-1:0] raddr_fb  ;
    reg [XW-1:0] waddr_lb  ;
    reg [XW-1:0] raddr_lb  ;
    reg [1:0] line_sel  ;
    reg [1:0] line_buffer_swap  ;
    reg [1:0] line_buffer_swap_b ;

    reg start;

    reg [XW-1:0] cnt_we   ;
    
    assign red_controller_raddr_r_frame_buffer     = raddr_fb;
    assign red_controller_we_line_buffer           = we_lb;
    assign red_controller_waddr_line_buffer        = waddr_lb;
    assign red_controller_raddr_line_buffer        = raddr_lb;
    assign red_controller_line_sel_line_buffer     = line_sel;
    assign red_controller_swap_noise_filter        = line_buffer_swap;

    assign red_controller_start_roi = start;

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            cnt_we <= 0;
        end else begin
            if (raddr_fb > (2 * IMG_W + 6)) begin
                if (cnt_we == IMG_W - 1) begin
                    cnt_we <= 0;
                end else begin
                    cnt_we <= cnt_we + 1;
                end
            end else begin
                cnt_we <= 0;
            end
        end
    end

    // start
    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            start <= 1'b0;
        end else begin
            start <= (state == MOVE) && (raddr_fb == (2 * IMG_W + 6));
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            line_buffer_swap_b <= 2'b00;
            line_buffer_swap   <= 2'b00;
        end else begin
            line_buffer_swap <= line_buffer_swap_b;
            if (state == IDLE) begin
                line_buffer_swap_b <= 2'b00;
            end else if (raddr_lb == IMG_W - 1) begin
                if (line_buffer_swap_b == 2'b10) begin
                    line_buffer_swap_b <= 2'b00;
                end else begin
                    line_buffer_swap_b <= line_buffer_swap_b + 1;
                end
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            raddr_lb <= 0;
        end else begin
            if (raddr_fb > (2 * IMG_W + 1)) begin
                if (raddr_lb == IMG_W - 1) begin
                    raddr_lb <= 0;
                end else begin
                    raddr_lb <= raddr_lb + 1;
                end
            end else begin
                raddr_lb <= 0;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            line_sel <= 2'b00;
        end else begin
            if (state == IDLE) begin
                line_sel <= 2'b00;
            end else if (we_lb && (waddr_lb == IMG_W - 1)) begin
                if (line_sel == 2'b10) begin
                    line_sel <= 2'b00;
                end else begin
                    line_sel <= line_sel + 1;
                end
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            waddr_lb <= 0;
        end else begin
            if (we_lb) begin
                if (waddr_lb == IMG_W - 1) begin
                    waddr_lb <= 0;
                end else begin
                    waddr_lb <= waddr_lb + 1;
                end
            end
        end
    end

    always @(*) begin
        if ((raddr_fb > 0) && (raddr_fb < (IMG_W * IMG_H + 1))) begin
            we_lb = 1'b1;
        end else begin
            we_lb = 1'b0;
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            raddr_fb <= 0;
        end else begin
            if (state == MOVE) begin
                raddr_fb <= raddr_fb + 1;
            end else begin
                raddr_fb <= 0;
            end
        end
    end

    always @(posedge clk or negedge resetn) begin
        if (!resetn) begin
            state <= IDLE;
        end else begin
            state <= nstate;
        end
    end

    always @(*) begin
        nstate = state;
        case (state)
            IDLE: begin
                if (ov_mem_controller_frame_end_red_controller) begin
                    nstate = MOVE;
                end
            end
            MOVE: begin
                if (raddr_fb == (IMG_W * IMG_H + 5)) begin
                    nstate = IDLE;
                end
            end
            default: begin
                nstate = IDLE;
            end
        endcase
    end
endmodule
