class sobel_module_env extends uvm_env;
    `uvm_component_utils(sobel_module_env)

    sobel_agent            agent;
    sobel_module_scoreboard scoreboard;
    sobel_coverage         coverage;

    function new(string name, uvm_component parent);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent      = sobel_agent::type_id::create("agent", this);
        scoreboard = sobel_module_scoreboard::type_id::create("scoreboard", this);
        coverage   = sobel_coverage::type_id::create("coverage", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        agent.monitor.item_collected_port.connect(scoreboard.item_export);
        agent.monitor.item_collected_port.connect(coverage.analysis_export);
    endfunction

endclass
