class sobel_coverage extends uvm_subscriber #(sobel_seq_item);
    `uvm_component_utils(sobel_coverage)

    sobel_seq_item item;

    covergroup cg_sobel;
        option.per_instance = 1;

        cp_line_data0: coverpoint item.line_data0 {
            bins low  = {[0:63]};
            bins mid  = {[64:191]};
            bins high = {[192:255]};
        }

        cp_line_data1: coverpoint item.line_data1 {
            bins low  = {[0:63]};
            bins mid  = {[64:191]};
            bins high = {[192:255]};
        }

        cp_line_data2: coverpoint item.line_data2 {
            bins low  = {[0:63]};
            bins mid  = {[64:191]};
            bins high = {[192:255]};
        }

        cp_swap: coverpoint item.swap {
            bins s0        = {0};
            bins s1        = {1};
            bins s2        = {2};
            bins s3_unused = {3};
        }

        cp_sdata: coverpoint item.sdata {
            bins zero = {0};
            bins one  = {1};
        }

        cx_swap_sdata: cross cp_swap, cp_sdata;

    endgroup

    function new(string name, uvm_component parent);
        super.new(name, parent);
        cg_sobel = new();
    endfunction

    function void write(sobel_seq_item t);
        if (t.resetn) begin
            item = t;
            cg_sobel.sample();
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SOBEL_COV",
            $sformatf("functional coverage = %0.2f %%", cg_sobel.get_coverage()),
            UVM_LOW)
    endfunction

endclass
