`timescale 1ns / 1ps

module ddr1_controller (
    input wire clk,
    input wire rst_n,
    input wire req_valid,
    input wire req_rw,
    input wire [24:0] req_addr,
    input wire [15:0] req_wdata,
    output reg req_ack,
    output reg resp_valid,
    output reg [15:0] resp_rdata,

    output reg cke,
    output reg cs_n, ras_n, cas_n, we_n,
    output reg [1:0] ba,
    output reg [12:0] addr,
    output reg [7:0] dm,
    inout [63:0] dq,
    inout [7:0] dqs
);

    // States
    localparam S_RESET      = 0;
    localparam S_INIT_PRE   = 1;
    localparam S_INIT_EMRS  = 2;
    localparam S_INIT_MRS_RST = 3;
    localparam S_INIT_WAIT  = 4;
    localparam S_INIT_REF   = 5;
    localparam S_INIT_MRS   = 6;
    localparam S_IDLE       = 7;
    localparam S_ACT        = 8;
    localparam S_READ       = 9;
    localparam S_READ_WAIT  = 10;
    localparam S_WRITE      = 11;
    localparam S_PRE        = 12;

    reg [3:0] state;
    integer cnt;
    reg [15:0] dq_out_reg;
    reg dq_oe;

    assign dq = dq_oe ? {48'h0, dq_out_reg} : 64'bz;
    assign dqs = dq_oe ? 8'h00 : 8'bz;

    task set_cmd(input c, input r, input a, input s);
        begin cs_n <= c; ras_n <= r; cas_n <= a; we_n <= s; end
    endtask

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= S_RESET;
            cnt <= 0;
            cke <= 0;
            req_ack <= 0;
            resp_valid <= 0;
            set_cmd(1,1,1,1);
        end else begin
            set_cmd(1,1,1,1); // Default NOP
            req_ack <= 0;      // Pulse ack
            case (state)
                S_RESET: begin
                    cke <= 1;
                    if (cnt < 10) cnt <= cnt + 1;
                    else begin state <= S_INIT_PRE; cnt <= 0; end
                end
                S_INIT_PRE: begin
                    set_cmd(0,0,1,0); // PRECHARGE ALL
                    addr[10] <= 1;
                    state <= S_INIT_EMRS;
                end
                S_INIT_EMRS: begin
                    set_cmd(0,0,0,0); // LMR
                    ba <= 2'b01; addr <= 0; // Enable DLL
                    state <= S_INIT_MRS_RST;
                end
                S_INIT_MRS_RST: begin
                    set_cmd(0,0,0,0); // LMR
                    ba <= 2'b00; addr <= 13'h122; // DLL Reset + CL=2 + BL=4
                    state <= S_INIT_WAIT;
                    cnt <= 0; // Ensure cnt is 0
                end
                S_INIT_WAIT: begin
                    if (cnt < 200) cnt <= cnt + 1;
                    else begin state <= S_INIT_REF; cnt <= 0; end
                end
                S_INIT_REF: begin
                    set_cmd(0,0,0,1); // REFRESH
                    if (cnt < 2) cnt <= cnt + 1;
                    else begin state <= S_INIT_MRS; cnt <= 0; end
                end
                S_INIT_MRS: begin
                    set_cmd(0,0,0,0); // LMR
                    ba <= 2'b00; addr <= 13'h022; // CL=2, BL=4
                    state <= S_IDLE;
                end
                S_IDLE: begin
                    if (req_valid) begin
                        state <= S_ACT;
                        req_ack <= 1;
                    end
                end
                S_ACT: begin
                    set_cmd(0,0,1,1);
                    ba <= req_addr[24:23];
                    addr <= req_addr[22:10];
                    state <= req_rw ? S_READ : S_WRITE;
                end
                S_READ: begin
                    set_cmd(0,1,0,1);
                    addr <= req_addr[9:0];
                    state <= S_READ_WAIT;
                    cnt <= 0;
                end
                S_READ_WAIT: begin
                    if (cnt < 2) cnt <= cnt + 1;
                    else begin
                        resp_valid <= 1;
                        resp_rdata <= dq[15:0];
                        state <= S_PRE;
                    end
                end
                S_WRITE: begin
                    set_cmd(0,1,0,0); // WR
                    addr <= req_addr[9:0];
                    dq_out_reg <= req_wdata;
                    dq_oe <= 1;
                    // Wait for write to complete before precharging
                    if (cnt < 2) cnt <= cnt + 1; // Assuming a small delay for write data to be driven
                    else begin
                        state <= S_PRE;
                        cnt <= 0;
                    end
                    $display("CTRL @%t: [WR] Data 0x%h", $time, req_wdata);
                end
                S_PRE: begin
                    set_cmd(0,0,1,0); // PRECHARGE
                    state <= S_IDLE;
                    resp_valid <= 0;
                end
            endcase
        end
    end

endmodule
