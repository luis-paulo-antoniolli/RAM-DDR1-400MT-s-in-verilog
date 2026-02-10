`timescale 1ns / 1ps

module ddr1_robust_tb;

    parameter CLK_PERIOD = 10;
    
    reg clk, rst_n;
    reg req_valid, req_rw;
    reg [24:0] req_addr;
    reg [15:0] req_wdata;
    wire req_ack, resp_valid;
    wire [15:0] resp_rdata;

    // DDR Interface Signals
    wire cke;
    wire cs_n;
    wire ras_n;
    wire cas_n;
    wire we_n;
    wire [1:0] ba;
    wire [12:0] addr;
    wire [7:0] dm;
    wire [63:0] dq;
    wire [7:0] dqs;
    wire clk_n = ~clk;

    // Instantiate Controller with explicit mapping
    ddr1_controller u_ctrl (
        .clk(clk),
        .rst_n(rst_n),
        .req_valid(req_valid),
        .req_rw(req_rw),
        .req_addr(req_addr),
        .req_wdata(req_wdata),
        .req_ack(req_ack),
        .resp_valid(resp_valid),
        .resp_rdata(resp_rdata),
        .cke(cke),
        .cs_n(cs_n),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n),
        .ba(ba),
        .addr(addr),
        .dm(dm),
        .dq(dq),
        .dqs(dqs)
    );

    // Instantiate DIMM with explicit mapping
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

    // Scoreboard (Associative array replacement for compatibility)
    reg [15:0] memory_model [0:4095]; 
    reg [12:0] last_written_addr;

    initial begin
        clk = 0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Helper Task: Write
    task ddr_write(input [24:0] a, input [15:0] d);
        begin
            @(posedge clk);
            req_valid = 1; req_rw = 0; req_addr = a; req_wdata = d;
            wait(req_ack);
            @(posedge clk);
            req_valid = 0;
            memory_model[a[11:0]] = d; // Use lower bits for limited scoreboard
            $display("TB @%t: Requested WRITE [Addr: 0x%h, Data: 0x%h]", $time, a, d);
        end
    endtask

    // Helper Task: Read & Check
    task ddr_read(input [24:0] a);
        begin
            @(posedge clk);
            req_valid = 1; req_rw = 1; req_addr = a;
            wait(req_ack);
            @(posedge clk);
            req_valid = 0;
            wait(resp_valid);
            if (resp_rdata !== memory_model[a[11:0]]) begin
                $display("TB @%t: [FAIL] Read Error! Addr: 0x%h, Exp: 0x%h, Got: 0x%h", $time, a, memory_model[a[11:0]], resp_rdata);
                $finish;
            end else begin
                $display("TB @%t: [PASS] Read Success! Addr: 0x%h, Data: 0x%h", $time, a, resp_rdata);
            end
        end
    endtask

    initial begin
        $dumpfile("ddr1_robust.vcd");
        $dumpvars(0, ddr1_robust_tb);

        // Reset & JEDEC Init
        rst_n = 0; req_valid = 0;
        #(CLK_PERIOD*10);
        rst_n = 1;
        $display("TB: Reset Released. Waiting for JEDEC Initialization...");
        #(CLK_PERIOD*600); 

        // Scenario 1: Basic Sequential Access
        $display("\n--- SCENARIO 1: Sequential Multi-Bank Access ---");
        ddr_write(25'h0000000, 16'hAAAA);
        ddr_write(25'h0800000, 16'hBBBB);
        ddr_write(25'h1000000, 16'hCCCC);
        ddr_write(25'h1800000, 16'hDDDD);
        
        ddr_read(25'h0000000);
        ddr_read(25'h0800000);
        ddr_read(25'h1000000);
        ddr_read(25'h1800000);

        // Scenario 2: Stress Test (Pattern Access)
        $display("\n--- SCENARIO 2: Pattern Access Stress Test ---");
        for (integer i=0; i<10; i=i+1) begin
            ddr_write(i, 16'hFF00 + i);
            ddr_read(i);
        end

        $display("\n--- ALL ROBUST TESTS PASSED ---");
        #(CLK_PERIOD*100);
        $finish;
    end

endmodule
