class sobel_monitor extends uvm_monitor;
    `uvm_component_utils(sobel_monitor)

    virtual sobel_if.MONITOR vif;

    uvm_analysis_port #(sobel_seq_item) item_collected_port;

    function new(string name, uvm_component parent);
        super.new(name, parent);
        item_collected_port = new("item_collected_port", this);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        if (!uvm_config_db#(virtual sobel_if.MONITOR)::get(this, "", "vif", vif))
            `uvm_fatal("SOBEL_MON", "virtual interface(vif) not set for monitor")
    endfunction

    task run_phase(uvm_phase phase);
        sobel_seq_item item;

        forever begin
            @(posedge vif.clk);
            #2;

            item = sobel_seq_item::type_id::create("item");
            item.resetn     = vif.resetn;
            item.line_data0 = vif.line_data0;
            item.line_data1 = vif.line_data1;
            item.line_data2 = vif.line_data2;
            item.swap       = vif.swap;
            item.sdata      = vif.sdata;
            item.is_settle_point = vif.is_settle_point;

            `uvm_info("SOBEL_MON", item.convert2string(), UVM_HIGH)

            item_collected_port.write(item);
        end
    endtask

endclass
