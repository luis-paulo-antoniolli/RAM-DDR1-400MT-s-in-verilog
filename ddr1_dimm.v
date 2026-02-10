`timescale 1ns / 1ps

module ddr1_dimm (
    input clk,
    input clk_n,
    input cke,
    input cs_n,
    input ras_n,
    input cas_n,
    input we_n,
    input [12:0] addr,
    input [1:0] ba,
    input [7:0] dm,
    inout [63:0] dq,
    inout [7:0] dqs
);

    // Chip 0: DQ[15:0]
    ddr1_chip u_chip0 (
        .clk(clk),
        .clk_n(clk_n),
        .cke(cke),
        .cs_n(cs_n),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n),
        .ba(ba),
        .addr(addr),
        .dm(dm[1:0]),
        .dq(dq[15:0]),
        .dqs(dqs[1:0])
    );

    // Chip 1: DQ[31:16]
    ddr1_chip u_chip1 (
        .clk(clk),
        .clk_n(clk_n),
        .cke(cke),
        .cs_n(cs_n),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n),
        .ba(ba),
        .addr(addr),
        .dm(dm[3:2]),
        .dq(dq[31:16]),
        .dqs(dqs[3:2])
    );

    // Chip 2: DQ[47:32]
    ddr1_chip u_chip2 (
        .clk(clk),
        .clk_n(clk_n),
        .cke(cke),
        .cs_n(cs_n),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n),
        .ba(ba),
        .addr(addr),
        .dm(dm[5:4]),
        .dq(dq[47:32]),
        .dqs(dqs[5:4])
    );

    // Chip 3: DQ[63:48]
    ddr1_chip u_chip3 (
        .clk(clk),
        .clk_n(clk_n),
        .cke(cke),
        .cs_n(cs_n),
        .ras_n(ras_n),
        .cas_n(cas_n),
        .we_n(we_n),
        .ba(ba),
        .addr(addr),
        .dm(dm[7:6]),
        .dq(dq[63:48]),
        .dqs(dqs[7:6])
    );

endmodule
