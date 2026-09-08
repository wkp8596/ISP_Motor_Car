class sobel_sequencer extends uvm_sequencer #(sobel_seq_item);
    `uvm_component_utils(sobel_sequencer)

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

endclass
