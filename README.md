# 1x3 Router Design and Verification

## Overview

This project implements and verifies a **1x3 packet router** in Verilog. The router accepts serial packet data on a single 8-bit input interface and forwards each packet to one of **three output channels** based on the 2-bit destination field embedded in the packet header.

The design is organized as a small RTL subsystem with dedicated blocks for:

- packet capture and parity handling
- routing control using an FSM
- output-channel synchronization
- buffering through three independent FIFOs

The repository also includes **module-level testbenches** and a **top-level integration testbench** for functional verification.

## Key Features

- Single input, three output packet routing
- 8-bit input/output datapath
- Header-based destination decoding
- Separate FIFO for each output port
- Busy signaling during routing/control transitions
- Valid output indication per channel
- Parity collection and parity-check support
- Soft reset support for stalled output channels
- Standalone testbenches for `router_fifo`, `router_fsm`, `router_register`, `router_sync`, and `router_top`

## Packet Format

Packets are driven on `data_in[7:0]` and follow this format:

- **Header byte**
  - `data_in[7:2]`: payload length
  - `data_in[1:0]`: destination address
- **Payload bytes**
  - variable-length payload
- **Parity byte**
  - XOR of header and payload bytes

### Destination Encoding

- `2'b00` -> output channel 0
- `2'b01` -> output channel 1
- `2'b10` -> output channel 2
- `2'b11` -> reserved/invalid

## Top-Level Interface

Top module: [`rtl/router_top.v`](/D:/sem7/project/1x3_router_design_and_verification-main/rtl/router_top.v)

### Inputs

- `clock` : system clock
- `resetn` : active-low reset
- `pkt_valid` : indicates header/payload phase is active
- `data_in[7:0]` : incoming packet byte
- `read_enb_0`, `read_enb_1`, `read_enb_2` : read enables for the three output FIFOs

### Outputs

- `data_out_0[7:0]`, `data_out_1[7:0]`, `data_out_2[7:0]` : routed output bytes
- `vld_out_0`, `vld_out_1`, `vld_out_2` : output data valid flags
- `busy` : router busy indicator
- `err` : parity check status from the register block

## RTL Architecture

### 1. `router_top`

[`rtl/router_top.v`](/D:/sem7/project/1x3_router_design_and_verification-main/rtl/router_top.v)

Integrates the complete router by connecting the FIFO, FSM, synchronizer, and register blocks.

### 2. `router_fifo`

[`rtl/router_fifo.v`](/D:/sem7/project/1x3_router_design_and_verification-main/rtl/router_fifo.v)

- Parameterized FIFO with default depth of 16
- Stores routed packet bytes for each output channel
- Tracks empty/full conditions
- Supports soft reset
- Uses an extra bit internally to identify header information

### 3. `router_fsm`

[`rtl/router_fsm.v`](/D:/sem7/project/1x3_router_design_and_verification-main/rtl/router_fsm.v)

Controls routing flow through the main states:

- `DECODE_ADDRESS`
- `LOAD_FIRST_DATA`
- `WAIT_TILL_EMPTY`
- `LOAD_DATA`
- `LOAD_PARITY`
- `FIFO_FULL_STATE`
- `LOAD_AFTER_FULL`
- `CHECK_PARITY_ERR`

This block drives control signals such as `busy`, `detect_add`, `lfd_state`, `ld_state`, and `write_enb_reg`.

### 4. `router_register`

[`rtl/router_register.v`](/D:/sem7/project/1x3_router_design_and_verification-main/rtl/router_register.v)

- Captures header and payload bytes
- Stores a byte when FIFO backpressure occurs
- Generates router output data toward the selected FIFO
- Tracks packet parity and internal parity
- Generates parity-related status signals

### 5. `router_sync`

[`rtl/router_sync.v`](/D:/sem7/project/1x3_router_design_and_verification-main/rtl/router_sync.v)

- Decodes the destination address
- Selects the target FIFO write enable
- Generates `vld_out_x` signals
- Reports selected FIFO full status to the FSM
- Generates soft reset for an output channel if valid data remains unread for multiple cycles

## Verification Contents

### Integration Testbench

- [`tb/router_top_tb.v`](/D:/sem7/project/1x3_router_design_and_verification-main/tb/router_top_tb.v)

Exercises the complete router datapath by:

- applying reset
- generating a packet with random payload bytes
- targeting output channel 0
- enabling FIFO readout after packet injection
- dumping waveforms to `top.vcd`

### Module Testbenches

- [`tb/router_fifo_tb.v`](/D:/sem7/project/1x3_router_design_and_verification-main/tb/router_fifo_tb.v)
- [`tb/router_fsm_tb.v`](/D:/sem7/project/1x3_router_design_and_verification-main/tb/router_fsm_tb.v)
- [`tb/router_register_tb.v`](/D:/sem7/project/1x3_router_design_and_verification-main/tb/router_register_tb.v)
- [`tb/router_sync_tb.v`](/D:/sem7/project/1x3_router_design_and_verification-main/tb/router_sync_tb.v)

These benches cover FIFO behavior, FSM transitions, register/parity handling, and synchronization/soft-reset logic.

## Repository Structure

```text
.
|-- rtl/
|   |-- router_top.v
|   |-- router_fifo.v
|   |-- router_fsm.v
|   |-- router_register.v
|   `-- router_sync.v
|-- tb/
|   |-- router_top_tb.v
|   |-- router_fifo_tb.v
|   |-- router_fsm_tb.v
|   |-- router_register_tb.v
|   `-- router_sync_tb.v
|-- testing/
|   `-- synchronizer_test/        # Older simulator artifacts and waveform files
|-- project_1.xpr                 # Vivado project
`-- README.md
```

## How to Run Simulation

### Option 1: Icarus Verilog

The project was sanity-checked locally with `iverilog` and `vvp`.

#### Run top-level simulation

```powershell
iverilog -g2012 -o router_top_tb.out tb\router_top_tb.v rtl\router_top.v rtl\router_fifo.v rtl\router_register.v rtl\router_fsm.v rtl\router_sync.v
vvp router_top_tb.out
```

#### Run module-level simulations

```powershell
iverilog -g2012 -o router_fifo_tb.out tb\router_fifo_tb.v rtl\router_fifo.v
vvp router_fifo_tb.out

iverilog -g2012 -o router_fsm_tb.out tb\router_fsm_tb.v rtl\router_fsm.v
vvp router_fsm_tb.out

iverilog -g2012 -o router_register_tb.out tb\router_register_tb.v rtl\router_register.v
vvp router_register_tb.out

iverilog -g2012 -o router_sync_tb.out tb\router_sync_tb.v rtl\router_sync.v
vvp router_sync_tb.out
```

### Option 2: Xilinx Vivado

This repository also contains a Vivado project file:

- [`project_1.xpr`](/D:/sem7/project/1x3_router_design_and_verification-main/project_1.xpr)

Open the project in Vivado and run simulation or synthesis from the GUI if you want to work in the original FPGA project environment.

## Waveforms

The current testbenches generate VCD waveform files such as:

- `top.vcd`
- `dump.vcd`
- `fsm.vcd`
- `register.vcd`
- `sync.vcd`

These can be viewed with tools such as GTKWave.

## Notes

- The design uses **active-low reset** (`resetn`).
- Output reads are controlled independently through `read_enb_0/1/2`.
- `vld_out_x` indicates that the corresponding FIFO is not empty.
- The synchronizer includes a timeout-based soft reset mechanism for unread valid data.
- A PDF report is included in the repository as [`p16771coll2_607.pdf`](/D:/sem7/project/1x3_router_design_and_verification-main/p16771coll2_607.pdf).

## Future Improvements

- Add self-checking testbenches with automatic pass/fail criteria
- Add constrained-random packet generation for all destination ports
- Add assertion-based verification for protocol and parity checks
- Add functional coverage for routing scenarios and FIFO corner cases
- Clean up generated simulation artifacts from version control

## Summary

This project demonstrates the design and verification of a Verilog-based **1x3 packet router** with modular RTL structure, packet buffering, address-based routing, parity handling, and reusable verification benches. It is a solid academic mini-project for learning digital design partitioning, FSM-based control, FIFO-based buffering, and basic HDL verification flow.
