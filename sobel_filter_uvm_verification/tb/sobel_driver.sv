class sobel_driver extends uvm_driver #(sobel_seq_item);
    `uvm_component_utils(sobel_driver)

    virtual sobel_if.DRIVER vif;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual sobel_if.DRIVER)::get(this, "", "vif", vif))
            `uvm_fatal("SOBEL_DRV", "virtual interface(vif) not set for driver")
    endfunction

    task run_phase(uvm_phase phase);
        phase.raise_objection(this, "sobel_driver reset");
        reset_dut();
        phase.drop_objection(this, "sobel_driver reset");

        forever begin
            seq_item_port.get_next_item(req);
            drive_item(req);
            seq_item_port.item_done();
        end
    endtask

    task reset_dut();
        vif.resetn                 = 1'b0;
        vif.drv_cb.line_data0      <= 8'h00;
        vif.drv_cb.line_data1      <= 8'h00;
        vif.drv_cb.line_data2      <= 8'h00;
        vif.drv_cb.swap            <= 2'b00;
        vif.drv_cb.is_settle_point <= 1'b0;

        repeat (5) @(vif.drv_cb);

        vif.resetn = 1'b1;
        repeat (2) @(vif.drv_cb);

        `uvm_info("SOBEL_DRV", "reset released", UVM_LOW)
    endtask

    task drive_item(sobel_seq_item item);
        @(vif.drv_cb);
        vif.drv_cb.line_data0      <= item.line_data0;
        vif.drv_cb.line_data1      <= item.line_data1;
        vif.drv_cb.line_data2      <= item.line_data2;
        vif.drv_cb.swap            <= item.swap;
        vif.drv_cb.is_settle_point <= item.is_settle_point;
    endtask

endclass