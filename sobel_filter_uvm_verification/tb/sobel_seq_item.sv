class sobel_seq_item extends uvm_sequence_item;

    rand bit [7:0] line_data0;
    rand bit [7:0] line_data1;
    rand bit [7:0] line_data2;
    rand bit [1:0] swap;

    bit sdata;

    bit resetn;

    bit is_settle_point;

    `uvm_object_utils_begin(sobel_seq_item)
        `uvm_field_int(line_data0,     UVM_ALL_ON)
        `uvm_field_int(line_data1,     UVM_ALL_ON)
        `uvm_field_int(line_data2,     UVM_ALL_ON)
        `uvm_field_int(swap,           UVM_ALL_ON)
        `uvm_field_int(sdata,          UVM_ALL_ON)
        `uvm_field_int(resetn,         UVM_ALL_ON)
        `uvm_field_int(is_settle_point, UVM_ALL_ON)
    `uvm_object_utils_end

    constraint c_swap_valid {
        swap inside {[0:2]};
    }

    function new(string name = "sobel_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf(
            "d0=%0d d1=%0d d2=%0d swap=%0d resetn=%0b sdata=%0b settle=%0b",
            line_data0, line_data1, line_data2, swap, resetn, sdata, is_settle_point);
    endfunction

endclass
