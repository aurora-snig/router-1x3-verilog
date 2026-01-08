# 1×3 Packet Router in Verilog HDL

## Overview
This project implements a **1×3 packet router** using Verilog HDL.  
The router accepts packets from a single input port and routes them to one of three output ports based on the destination address encoded in the packet header.

The design focuses on **modularity, flow control, and correctness**, and is fully verified through simulation.

---

## Architecture
The router is composed of the following modules:

- **router_fsm**  
  FSM-based controller that manages packet flow, state transitions, and control signals.

- **router_fifo**  
  Three independent FIFOs (one per output port) for buffering packets and handling backpressure.

- **router_sync**  
  Synchronizes FSM control with FIFO status and generates write enables, valid signals, and timeout-based soft resets.

- **router_reg**  
  Handles header storage, incremental parity calculation, packet parity capture, and error detection.

- **router_top**  
  Top-level module integrating all submodules.

---

## Packet Format
- **Header (8 bits)**  
  - Destination Address: 2 bits  
  - Payload Length: 6 bits

- **Payload**  
  - 1 to 63 bytes

- **Parity Byte**  
  - Bitwise XOR of header and payload bytes

---

## Key Features
- FSM-controlled packet routing
- Per-port FIFO buffering
- Flow control using `busy` signal
- Parity-based error detection
- Timeout-based soft reset per FIFO
- Fully synthesizable RTL

---

## Verification
- Self-checking testbench for top module
- Input driven on negative clock edge
- Outputs sampled on positive clock edge
- Waveform-based debugging using GTKWave

---

## Tools Used
- Verilog HDL
- Icarus Verilog
- GTKWave

---

## How to Run Simulation
```bash
iverilog -o sim router_top.v router_fsm.v router_fifo.v router_sync.v router_reg.v router_top_tb.v
vvp sim
gtkwave router_top.vcd
