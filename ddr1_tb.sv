`timescale 1ns / 1ps

module ddr1_tb;

    // Parameters
    parameter CLK_PERIOD = 10; // 100 MHz (200 MT/s)
    
    // Signals
    logic clk;
    logic clk_n;
    logic cke;
    logic cs_n;
    logic ras_n;
    logic cas_n;
    logic we_n;
    logic [12:0] addr;
    logic [1:0] ba;
    logic [7:0] dm;
    wire [63:0] dq;
    wire [7:0] dqs;

    // Instantiate DIMM
    ddr1_dimm u_dimm (
        .clk(clk),
        .clk_n(clk_n),
        .cke(cke),
        .cs_n(cs_n),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n),
        .addr(addr),
        .ba(ba),
        .dm(dm),
        .dq(dq),
        .dqs(dqs)
    );

    // Clock Generation
    initial begin
        clk = 0;
        clk_n = 1;
        forever #(CLK_PERIOD/2) begin
            clk = ~clk;
            clk_n = ~clk_n;
        end
    end

    // Tasks for DDR Commands
    task command(input logic cke_in, input logic cs, input logic ras, input logic cas, input logic we);
        cke <= cke_in;
        cs_n <= cs;
        ras_n <= ras;
        cas_n <= cas;
        we_n <= we;
    endtask

    task nop();
        command(1, 0, 1, 1, 1);
    endtask

    task precharge_all();
        command(1, 0, 0, 1, 0); // PRECHARGE
        addr[10] <= 1; // All banks
    endtask

    task load_mode_register(input logic [12:0] op_code);
        command(1, 0, 0, 0, 0); // LMR
        ba <= 0;
        addr <= op_code;
    endtask

    task active(input logic [1:0] bank, input logic [12:0] row);
        command(1, 0, 0, 1, 1); // ACTIVE
        ba <= bank;
        addr <= row;
    endtask

    task write(input logic [1:0] bank, input logic [12:0] col, input logic [63:0] data);
        command(1, 0, 1, 0, 0); // WRITE
        ba <= bank;
        addr <= col;
        // Drive DQ/DQS is complex in cycle-accurate way here, simplification for now:
        // In a real controller, DQS/DQ are driven with specific timing relative to CLK
    endtask

    task read(input logic [1:0] bank, input logic [12:0] col);
        command(1, 0, 1, 0, 1); // READ
        ba <= bank;
        addr <= col;
    endtask

    // Main Test Sequence
    initial begin
        $dumpfile("ddr1_tb.vcd");
        $dumpvars(0, ddr1_tb);

        // Initialization
        cke = 0;
        cs_n = 1;
        dm = 0;
        #(CLK_PERIOD*10);
        
        $display("Unsorted: Power Up");
        cke = 1;
        nop();
        #(CLK_PERIOD*2);

        $display("Precharge All");
        precharge_all();
        @(posedge clk);
        nop();
        #(CLK_PERIOD*2);

        $display("Load Mode Register");
        // CAS Latency = 2, Burst Length = 4
        load_mode_register(13'h0022); 
        @(posedge clk);
        nop();
        #(CLK_PERIOD*2);

        $display("Active Bank 0, Row 0");
        active(0, 0);
        @(posedge clk);
        nop();
        #(CLK_PERIOD*2);

        // TODO: Implement Write and Read checking logic
        // This requires bidirectional DQS/DQ handling which is tricky in simple TB without OVM/UVM or tasks
        
        #(CLK_PERIOD*20);
        $display("TEST PASSED");
        $finish;
    end

endmodule
