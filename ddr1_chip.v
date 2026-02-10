`timescale 1ns / 1ps

module ddr1_chip (
    input clk, clk_n, cke, cs_n, ras_n, cas_n, we_n,
    input [1:0] ba,
    input [12:0] addr,
    input [1:0] dm,
    inout [15:0] dq,
    inout [1:0] dqs
);

    // --- 1. REGISTRADORES JEDEC (MRS / EMRS) ---
    reg [12:0] mode_reg;
    reg [12:0] ext_mode_reg;
    
    wire [1:0] cas_latency  = (mode_reg[6:4] == 3'b010) ? 2'd2 : 
                              (mode_reg[6:4] == 3'b011) ? 2'd3 : 2'd2;
    wire dll_enabled = !ext_mode_reg[0];

    // --- 2. BEHAVIORAL DLL ---
    reg dll_locked;
    integer dll_lock_cnt;
    always @(posedge clk) begin
        if (!cke || (cs_n==0 && ras_n==0 && cas_n==0 && we_n==0 && addr[8])) begin
            dll_locked <= 0;
            dll_lock_cnt <= 0;
        end else if (dll_enabled && !dll_locked) begin
            if (dll_lock_cnt < 200) dll_lock_cnt <= dll_lock_cnt + 1;
            else dll_locked <= 1;
        end
    end

    // --- 3. CORE (SIMPLIFIED STORAGE) ---
    reg [15:0] storage [0:1023]; // Bitcell Array
    reg [12:0] active_row [0:3];
    reg bank_active [0:3];
    
    reg [31:0] prefetch_reg;
    reg [3:0] rd_shreg;
    reg dq_oe;

    initial begin
        for (integer i=0; i<1024; i=i+1) storage[i] = i;
        for (integer b=0; b<4; b=b+1) bank_active[b] = 0;
        mode_reg = 0; ext_mode_reg = 1; dll_locked = 0; dq_oe = 0;
    end

    // Clocked Logic (Rising Edge)
    always @(posedge clk) begin
        rd_shreg <= {rd_shreg[2:0], 1'b0};
        
        if (cke) begin
            if (cs_n == 0) begin
                case ({ras_n, cas_n, we_n})
                    3'b000: if (ba==0) mode_reg <= addr; else ext_mode_reg <= addr;
                    3'b011: begin // ACT
                        active_row[ba] <= addr;
                        bank_active[ba] <= 1;
                    end
                    3'b101: if (bank_active[ba]) begin // RD
                        if (cas_latency == 2) rd_shreg[1] <= 1;
                        else rd_shreg[2] <= 1;
                        // Leitura direta do array (Simulando prefetch 2)
                        prefetch_reg[15:0]  <= storage[{ba, addr[3:0]}];
                        prefetch_reg[31:16] <= storage[{ba, addr[3:0]}] + 16'h1; 
                    end
                    3'b100: if (bank_active[ba]) begin // WR
                        storage[{ba, addr[3:0]}] <= dq[15:0]; 
                        $display("CHIP @%t: [WR] Bank %d, Addr 0x%h, Data 0x%h", $time, ba, {ba, addr[3:0]}, dq[15:0]);
                    end
                    3'b010: bank_active[ba] <= 0; // PRE
                endcase
            end
            
            // Output Enable Control
            if (rd_shreg[0]) dq_oe <= 1;
            else if (rd_shreg[1]) dq_oe <= 0;
        end
    end

    // --- 4. DDR OUTPUT LOGIC ---
    reg [15:0] dq_mux;
    always @(*) begin
        if (clk) dq_mux = prefetch_reg[15:0];
        else     dq_mux = prefetch_reg[31:16];
    end

    // --- 5. I/O PADS ---
    assign dq = dq_oe ? dq_mux : 16'bz;
    assign dqs = dq_oe ? (clk ? 2'b11 : 2'b00) : 2'bz;

endmodule
