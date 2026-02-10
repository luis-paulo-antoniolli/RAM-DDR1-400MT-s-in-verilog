`timescale 1ns / 1ps

module ddr1_controller_tb;

    // Parameters
    parameter CLK_PERIOD = 10; // 100 MHz

    // Host Interface
    reg clk;
    reg rst_n;
    reg req_valid;
    reg req_rw;
    reg [24:0] req_addr;
    reg [15:0] req_wdata;
    wire req_ack;
    wire resp_valid;
    wire [15:0] resp_rdata;

    // DDR Interface
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
    wire clk_n = ~clk; // Simple differential clock

    // Instantiate Controller
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
        forever #(CLK_PERIOD/2) clk = ~clk;
    end

    // Test Sequence
    initial begin
        $dumpfile("ddr1_ctrl_tb.vcd");
        $dumpvars(0, ddr1_controller_tb);

        // Reset
        rst_n = 0;
        req_valid = 0;
        req_rw = 0;
        req_addr = 0;
        req_wdata = 0;
        
        #(CLK_PERIOD*10);
        rst_n = 1;
        $display("Reset Released");

        // Wait for initialization (Controller needs some time to run INIT sequence)
        // Controller state machine says: START -> PRE -> LMR -> IDLE
        // Each state takes at least a cycle or more.
        #(CLK_PERIOD*300);
        
        // Test Write: Bank 0, Row 0, Col 0, Data 0xABCD
        $display("Test 1: Write 0xABCD to Address 0");
        @(posedge clk);
        req_valid = 1;
        req_rw = 0; // Write
        req_addr = 25'd0;
        req_wdata = 16'hABCD;
        
        wait(req_ack);
        @(posedge clk);
        req_valid = 0;
        
        #(CLK_PERIOD*20); // Wait for operation to complete

        // Test Read: Bank 0, Row 0, Col 0, Expect 0xABCD
        $display("Test 2: Read from Address 0");
        @(posedge clk);
        req_valid = 1;
        req_rw = 1; // Read
        req_addr = 25'd0;
        
        wait(req_ack);
        @(posedge clk);
        req_valid = 0;

        // Wait for response
        wait(resp_valid);
        $display("Read Data: 0x%h", resp_rdata);
        if (resp_rdata === 16'hABCD) 
            $display("PASS: Data matches");
        else 
            $display("FAIL: Data mismatch, expected 0xABCD");

        #(CLK_PERIOD*20);
        $finish;
    end

endmodule
