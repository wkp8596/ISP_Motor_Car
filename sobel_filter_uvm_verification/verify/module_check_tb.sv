// Plain (non-UVM) testbench to validate the block-loading stimulus scheme
// (3x3 non-overlapping blocks, matching the user's C golden model) against
// the real sobel_filter RTL, and to pin down the exact cycle at which the
// settled sdata for each block becomes valid.
`timescale 1ns/1ps

module module_check_tb;

    localparam int THRESHOLD  = 95;
    localparam int NUM_BLOCKS = 11111;   // floor(100000/9), matches C golden model

    bit clk = 0;
    always #5 clk = ~clk;

    logic       resetn;
    logic [7:0] line_data0, line_data1, line_data2;
    logic [1:0] swap;
    logic       sdata;

    sobel_filter #(.THRESHOLD(THRESHOLD)) u_dut (
        .clk(clk), .resetn(resetn),
        .line_buffer_line_data0_sobel(line_data0),
        .line_buffer_line_data1_sobel(line_data1),
        .line_buffer_line_data2_sobel(line_data2),
        .buffer_controller_swap_sobel(swap),
        .sobel_sdata_sobel_frame_buffer(sdata)
    );

    int fd_in, fd_exp;
    int code, val;
    bit [7:0] p[0:2][0:2];
    int b, i, j;
    bit sdata_sample;
    int exp_val;
    int total, match_c, mismatch_c;

    task automatic step_cycle(input bit [7:0] d0, input bit [7:0] d1, input bit [7:0] d2);
        @(posedge clk);
        #1;
        line_data0 = d0;
        line_data1 = d1;
        line_data2 = d2;
        swap       = 2'b00;
        sdata_sample = sdata;   // post-edge sample (validated convention)
    endtask

    initial begin
        resetn = 1'b0;
        line_data0 = 0; line_data1 = 0; line_data2 = 0; swap = 0;
        total = 0; match_c = 0; mismatch_c = 0;

        repeat (5) @(posedge clk);
        resetn = 1'b1;
        repeat (2) @(posedge clk);

        fd_in  = $fopen("random_0_255.txt", "r");
        fd_exp = $fopen("sobel_result.txt", "r");
        if (fd_in == 0 || fd_exp == 0) begin
            $display("ERROR: cannot open input files");
            $finish;
        end

        for (b = 0; b < NUM_BLOCKS; b++) begin
            // read one 3x3 block, row-major, exactly like the C code
            for (i = 0; i < 3; i++) begin
                for (j = 0; j < 3; j++) begin
                    code = $fscanf(fd_in, "%d", val);
                    p[i][j] = val[7:0];
                end
            end
            code = $fscanf(fd_exp, "%d", exp_val);

            // 3 load cycles: feed column 2,1,0 in that order (reverse),
            // in parallel across the 3 row-channels (swap fixed at 0)
            step_cycle(p[0][2], p[1][2], p[2][2]);
            step_cycle(p[0][1], p[1][1], p[2][1]);
            step_cycle(p[0][0], p[1][0], p[2][0]);
            // 2 settle cycles needed:
            //  - settle #1: arrays finish shifting in the 3rd load column,
            //               dx/dy become combinationally correct during this
            //               cycle, but dx_r/dy_r have NOT registered it yet
            //  - settle #2: THIS edge registers dx_r/dy_r from the correct
            //               dx/dy computed during settle #1 -> sdata correct
            //               starting from this cycle's post-edge sample
            step_cycle(p[0][0], p[1][0], p[2][0]);
            step_cycle(p[0][0], p[1][0], p[2][0]);

            total++;
            if (sdata_sample === exp_val[0]) match_c++;
            else begin
                mismatch_c++;
                if (mismatch_c <= 20)
                    $display("MISMATCH block=%0d exp=%0d act=%0b p=[%0d,%0d,%0d / %0d,%0d,%0d / %0d,%0d,%0d]",
                        b, exp_val, sdata_sample,
                        p[0][0],p[0][1],p[0][2], p[1][0],p[1][1],p[1][2], p[2][0],p[2][1],p[2][2]);
            end
        end

        $fclose(fd_in);
        $fclose(fd_exp);

        $display("=== RESULT: total=%0d match=%0d mismatch=%0d ===", total, match_c, mismatch_c);
        if (mismatch_c == 0) $display("*** MODULE STIMULUS MATCHES C GOLDEN MODEL ***");
        else $display("*** MISMATCH DETECTED ***");

        $finish;
    end

endmodule
