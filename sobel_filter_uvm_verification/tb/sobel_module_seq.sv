class sobel_module_seq extends uvm_sequence #(sobel_seq_item);
    `uvm_object_utils(sobel_module_seq)

    string file_path  = "random_0_255.txt";
    int    num_blocks = 11111;  

    function new(string name = "sobel_module_seq");
        super.new(name);
    endfunction

    task body();
        int       fd;
        int       code, val;
        bit [7:0] p[0:2][0:2];
        int       b, i, j;

        void'($value$plusargs("DATA_FILE=%s", file_path));

        fd = $fopen(file_path, "r");
        if (fd == 0)
            `uvm_fatal("SOBEL_MOD_SEQ", $sformatf("cannot open data file: %s", file_path))

        for (b = 0; b < num_blocks; b++) begin
            for (i = 0; i < 3; i++) begin
                for (j = 0; j < 3; j++) begin
                    code = $fscanf(fd, "%d", val);
                    if (code != 1)
                        `uvm_fatal("SOBEL_MOD_SEQ",
                            $sformatf("unexpected EOF while reading block %0d", b))
                    p[i][j] = val[7:0];
                end
            end

            drive_cycle(p[0][2], p[1][2], p[2][2], 1'b0);   // load col2
            drive_cycle(p[0][1], p[1][1], p[2][1], 1'b0);   // load col1
            drive_cycle(p[0][0], p[1][0], p[2][0], 1'b0);   // load col0
            drive_cycle(p[0][0], p[1][0], p[2][0], 1'b0);   // settle #1
            drive_cycle(p[0][0], p[1][0], p[2][0], 1'b1);   // settle #2 (compare here)
        end

        $fclose(fd);
        `uvm_info("SOBEL_MOD_SEQ",
            $sformatf("total %0d blocks (%0d cycles) sent from %s",
                       num_blocks, num_blocks * 5, file_path), UVM_LOW)
    endtask

    task drive_cycle(bit [7:0] d0, bit [7:0] d1, bit [7:0] d2, bit settle_point);
        sobel_seq_item item;
        item = sobel_seq_item::type_id::create("item");
        start_item(item);
        item.line_data0     = d0;
        item.line_data1     = d1;
        item.line_data2     = d2;
        item.swap           = 2'b00;
        item.is_settle_point = settle_point;
        finish_item(item);
    endtask

endclass
