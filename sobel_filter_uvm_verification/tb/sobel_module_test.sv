class sobel_module_test extends uvm_test;
    `uvm_component_utils(sobel_module_test)

    sobel_module_env env;

    function new(string name = "sobel_module_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = sobel_module_env::type_id::create("env", this);
    endfunction

    function void end_of_elaboration_phase(uvm_phase phase);
        super.end_of_elaboration_phase(phase);
        uvm_top.print_topology();
    endfunction

    task run_phase(uvm_phase phase);
        sobel_module_seq seq;

        phase.raise_objection(this, "sobel_module_test main sequence");

        seq = sobel_module_seq::type_id::create("seq");
        seq.start(env.agent.sequencer);

        #100;

        phase.drop_objection(this, "sobel_module_test main sequence");
    endtask

endclass
