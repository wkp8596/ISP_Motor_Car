class sobel_module_scoreboard extends uvm_scoreboard;
    `uvm_component_utils(sobel_module_scoreboard)

    uvm_analysis_imp #(sobel_seq_item, sobel_module_scoreboard) item_export;

    string result_file_path = "sobel_result.txt";
    int fd;

    int unsigned total_cnt;
    int unsigned match_cnt;
    int unsigned mismatch_cnt;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_export = new("item_export", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        void'($value$plusargs("RESULT_FILE=%s", result_file_path));

        fd = $fopen(result_file_path, "r");
        if (fd == 0)
            `uvm_fatal("SOBEL_MOD_SB",
                $sformatf("cannot open golden result file: %s", result_file_path))
    endfunction

    function void write(sobel_seq_item t);
        int code;
        int exp_val;

        if (!t.resetn || !t.is_settle_point) return;

        code = $fscanf(fd, "%d", exp_val);
        if (code != 1) begin
            `uvm_warning("SOBEL_MOD_SB",
                "golden result file exhausted - further compares skipped")
            return;
        end

        total_cnt++;

        if (exp_val[0] === t.sdata) begin
            match_cnt++;
            `uvm_info("SOBEL_MOD_SB",
                $sformatf("MATCH    block#%0d : exp=%0d act=%0b", total_cnt, exp_val, t.sdata),
                UVM_HIGH)
        end else begin
            mismatch_cnt++;
            `uvm_error("SOBEL_MOD_SB",
                $sformatf("MISMATCH block#%0d : exp=%0d act=%0b", total_cnt, exp_val, t.sdata))
        end
    endfunction

    function void report_phase(uvm_phase phase);
        real match_pct;
        real mismatch_pct;
        string status_line;

        if (total_cnt > 0) begin
            match_pct    = (real'(match_cnt)    / real'(total_cnt)) * 100.0;
            mismatch_pct = (real'(mismatch_cnt) / real'(total_cnt)) * 100.0;
        end else begin
            match_pct    = 0.0;
            mismatch_pct = 0.0;
        end

        status_line = (mismatch_cnt == 0 && total_cnt > 0) ?
                        "*** TEST PASSED ***" : "*** TEST FAILED ***";

        $display("");
        $display("========================================================");
        $display("  SOBEL MODULE TEST SUMMARY");
        $display("--------------------------------------------------------");
        $display("  total      : %0d", total_cnt);
        $display("  match      : %0d  (%0.2f%%)", match_cnt, match_pct);
        $display("  mismatch   : %0d  (%0.2f%%)", mismatch_cnt, mismatch_pct);
        $display("--------------------------------------------------------");
        $display("  %s", status_line);
        $display("========================================================");
        $display("");

        if (mismatch_cnt != 0)
            `uvm_error("SOBEL_MOD_SB", status_line)

        if (fd != 0) $fclose(fd);
    endfunction

endclass
