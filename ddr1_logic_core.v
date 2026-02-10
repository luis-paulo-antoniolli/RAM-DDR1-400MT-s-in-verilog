`timescale 1ns / 1ps

/**
 * ddr1_logic_core
 * 
 * PARTE DIGITAL SINTETIZÁVEL DO CHIP
 */
module ddr1_logic_core (
    input clk,
    input cke,
    input cs_n,
    input ras_n,
    input cas_n,
    input we_n,
    input [1:0] ba,
    input [12:0] addr,
    
    // Interface com os Macros de Memória
    output reg [3:0] bank_ce_n,
    output reg [3:0] bank_we_n,
    output reg [3:0] bank_oe_n,
    output reg [9:0] bank_addr,
    output reg [15:0] bank_din,
    input [15:0] bank0_dout, // Simplificado para bank 0 no teste
    
    // Interface com I/O
    output reg [15:0] data_to_pads,
    output reg data_oe,
    input [15:0] data_from_pads
);

    // Command Decoding
    wire [3:0] cmd = {cs_n, ras_n, cas_n, we_n};
    localparam CMD_ACT  = 4'b0011;
    localparam CMD_WR   = 4'b0100;
    localparam CMD_RD   = 4'b0101;
    localparam CMD_PRE  = 4'b0010;

    // Estado interno (Row Tracking)
    reg [12:0] active_row [0:3];
    reg bank_active [0:3];
    
    // Pipeline de Leitura
    reg [2:0] rd_shreg;

    initial begin
        bank_ce_n = 4'b1111;
        bank_we_n = 4'b1111;
        bank_oe_n = 4'b1111;
        data_oe = 0;
        rd_shreg = 0;
    end

    always @(posedge clk) begin
        if (!cke) begin
            bank_ce_n <= 4'b1111;
            bank_we_n <= 4'b1111;
            bank_oe_n <= 4'b1111;
            rd_shreg <= 0;
            data_oe <= 0;
        end else begin
            // Default macro control
            bank_ce_n <= 4'b1111;
            bank_we_n <= 4'b1111;
            bank_oe_n <= 4'b1111;
            
            // Lógica de saída (Data Path)
            rd_shreg <= {rd_shreg[1:0], 1'b0};
            
            case (cmd)
                CMD_ACT: begin
                    active_row[ba] <= addr;
                    bank_active[ba] <= 1;
                end
                CMD_PRE: begin
                    bank_active[ba] <= 0;
                end
                CMD_WR: begin
                    if (bank_active[ba]) begin
                        bank_ce_n[ba] <= 0;
                        bank_we_n[ba] <= 0;
                        bank_addr <= {active_row[ba][5:0], addr[3:0]};
                        bank_din <= data_from_pads;
                        $display("CORE @%t: [WR] Bank=%d, Row=0x%h, Col=0x%h, Data=0x%h", $time, ba, active_row[ba], addr, data_from_pads);
                    end
                end
                CMD_RD: begin
                    if (bank_active[ba]) begin
                        bank_ce_n[ba] <= 0;
                        bank_oe_n[ba] <= 0;
                        bank_addr <= {active_row[ba][5:0], addr[3:0]};
                        rd_shreg <= 3'b001; 
                        $display("CORE @%t: [RD] Bank=%d, Row=0x%h, Col=0x%h", $time, ba, active_row[ba], addr);
                    end
                end
            endcase
            
            if (rd_shreg[0]) begin // Cycle 1 after command
                 data_to_pads <= bank0_dout;
                 data_oe <= 1;
                 $display("ASIC CORE @%t: Driving Bus with 0x%h", $time, bank0_dout);
            end else if (rd_shreg[1]) begin // Cycle 2 after command
                 data_oe <= 0;
            end
        end
    end

endmodule
