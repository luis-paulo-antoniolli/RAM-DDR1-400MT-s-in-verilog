# DDR1 Memory Controller & Hardware Model

This project implements a complete DDR1 memory system, including a synchronous **Memory Controller** and a **DDR1 Chip** with a structural architecture following industrial memory standards.

## 🚀 Overview

The goal of this project was to evolve a behavioral DDR1 model into an implementation that reflects real hardware design challenges, JEDEC compliance, and the physical structure of dynamic memories.

### Project Highlights:
- **JEDEC Compliance**: Implementation of the rigorous initialization sequence and support for **MRS/EMRS** (Mode Register Set).
- **True Double Data Rate (DDR)**: Functional data bus that transfers information on both clock edges, doubling performance.
- **Synchronization via DLL**: Behavioral **Delay-Locked Loop** model for phase alignment between clock and data, requiring 200 cycles to lock.
- **Industrial Architecture**: Chip structured with digital decoders, command logic, and a simplified SSTL-2 interface.

---

## 🏗️ System Architecture

### 1. DDR1 Controller (`ddr1_controller.v`)
Acts as the bus master, managing the protocol and memory training.
- **JEDEC Init**: Full sequence of `Precharge All -> EMRS -> MRS(Reset) -> Wait -> Refresh -> MRS(Setup)`.
- **Robust FSM**: States for automating `ACT`, `READ`, `WRITE`, and `PRECHARGE`.
- **Protocolled Synchronous Handshake**: Host interface with `req_valid`/`req_ack`.

### 2. DDR1 Chip Structural Model (`ddr1_chip.v`)
Chip model focusing on the logic and timing integrity of the DDR standard:
- **Prefetch 2 Architecture**: Internal logic that prepares 32 bits of data to transfer 16 bits per half-cycle.
- **Mode Registers**: Real storage for CAS Latency (CL2, CL3) and Burst Length configuration.
- **DDR I/O Path**: Multiplexed logic for rising and falling clock edges.

---

## 📁 File Structure

| File | Description |
| :------- | :---------- |
| `ddr1_chip.v` | Top-level Chip (Industrial Structure) |
| `ddr1_controller.v` | Memory Controller with JEDEC Sequence |
| `ddr1_robust_tb.sv` | Robust testbench with Scoreboard and Random Tests |
| `ddr1_dimm.v` | DIMM module model (chip aggregator) |
| `walkthrough.md` | Detailed explanation of architecture and waveforms |

---

## 🛠️ How to Simulate

The project recommends using **Icarus Verilog** (v11 or higher) for SystemVerilog support.

1. **Compile the Robust Test:**
   ```bash
   iverilog -g2012 -o ddr1_robust ddr1_robust_tb.sv ddr1_controller.v ddr1_dimm.v ddr1_chip.v
   ```

2. **Run the Simulation:**
   ```bash
   vvp ddr1_robust
   ```

3. **Verify Results:**
   The robust testbench runs multi-bank access scenarios and random stress tests, verifying data against a reference model (Scoreboard).

---

## 🛣️ Roadmap for Physical Implementation

To transform this code into real hardware:
1. **Logic Synthesis**: Mapping the controller and chip logic to a standard cell library.
2. **Memory Macro Integration**: Replacing the behavioral array with real memory IPs from the silicon provider.
3. **Physical Design**: Floorplanning and signal/clock routing to ensure electrical integrity.

---

Developed with a focus on **Hardware Engineering** and technical rigor in memory protocols.
