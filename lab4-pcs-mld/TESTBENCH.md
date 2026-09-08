# Lab 4 Testbench Documentation (`TESTBENCH.md`)

This document describes the design, architecture, and verification strategy implemented in `wrapper.cpp` for validating the 100GBASE-R PCS and Multi-Lane Distribution (MLD) SystemVerilog module (`top.sv`).

---

## 🛠️ System Architecture & Inside `top.sv`

The testbench (`wrapper.cpp`) communicates with `top.sv` via AXI-Stream interfaces. Below is the detailed internal pipeline structure of `top.sv` for Path A $\rightarrow$ B (Path B $\rightarrow$ A is identical and symmetrical):

```
+-------------------------------------------------------------------------------------------------------------------------------------------------------+
|                                                                        top.sv                                                                         |
|                                                                                                                                                       |
|  [Path A -> B]                                                                                                                                        |
|                                                                                                                                                       |
|  +--------------+    cgmii_txd_a[63:0]    +------------------+   pcs_block_raw_a[65:0]   +---------------+   mld_stream_a2b[65:0]   +--------------+ |
|  |  mac_tx_a    | ----------------------> | pcs_encoder_c82  | ------------------------> |  mld_tx_a     | -----------------------> |  mld_rx_b    | |
|  |  (mac_tx)    |    cgmii_txc_a[7:0]     | (pcs_enc_inst_a) |                           |  (mld_tx)     |   mld_lane_id_a2b[4:0]   |  (mld_rx)    | |
|  +--------------+                         +------------------+                           +---------------+   mld_is_am_a2b            +--------------+ |
|        ^                                                                                         |          mld_am_pattern_a2b           |            |
|        |                                                                                         +-----------------------------------------+            |
|   a_tx_data[63:0]                                                                                                                              |            |
|   a_tx_keep[7:0]                                                                                                                    pcs_block_mld_b[65:0]
|   a_tx_valid / a_tx_last / a_tx_ready                                                                                                          |            |
|                                                                                                                                                v            |
|  +--------------+     cgmii_rxd_b[63:0]   +------------------+                             pcs_block_mld_b[65:0]                    +--------------+ |
|  |  mac_rx_b    | <---------------------- | pcs_decoder_c82  | <--------------------------------------------------------------------- |  mld_rx_b    | |
|  |  (mac_rx)    |     cgmii_rxc_b[7:0]    | (pcs_dec_inst_b) |                                                                        |  (mld_rx)    | |
|  +--------------+                         +------------------+                                                                        +--------------+ |
|        |                                                                                                                                              |
|        v                                                                                                                                              |
|   b_rx_data[63:0]                                                                                                                                     |
|   b_rx_keep[7:0]                                                                                                                                      |
|   b_rx_valid / b_rx_last / b_rx_ready                                                                                                                 |
+-------------------------------------------------------------------------------------------------------------------------------------------------------+
```

---

## 💡 Note on MLD Conceptual Implementation vs. Real Spec

To make the concepts of Clause 82 easily readable in simulation without unnecessary hardware overhead, this lab uses an **educational abstraction** of Multi-Lane Distribution (MLD):

* **Real Hardware Implementation (IEEE 802.3 Clause 82)**: A physical 100GBASE-R transmitter physically demultiplexes stream blocks across 20 distinct Virtual Lanes (VLs). It periodically replaces data blocks with 66-bit Alignment Markers (AMs) directly on each lane's bus, requiring complex deskew FIFOs and re-ordering logic on the receiver.
* **Lab Implementation Strategy**: To keep the focus on understanding *how* MLD functions without complex multi-lane buffer logic:
  * Blocks are not physically split into 20 separate FIFOs.
  * Virtual Lane identification (`mld_lane_id`), Alignment Marker pulses (`mld_is_am`), and expected marker values (`mld_am_pattern`) are transmitted as **explicit sideband signals** alongside the main 66-bit block stream.
  * This allows you to verify round-robin distribution and AM insertion timing directly in GTKWave while keeping the data path unified and easy to follow.

---

## 🎯 Verification Objectives

1. **Protocol Compliance**: Verify IEEE 802.3 Clause 82 64b/66b framing, CGMII conversion, payload scrambling, and Alignment Marker (AM) sideband signaling.
2. **End-to-End Data Integrity**: Ensure ICMP/IP packets sent over the Linux TAP interface travel through MAC $\rightarrow$ PCS Encoder $\rightarrow$ MLD TX $\rightarrow$ MLD RX $\rightarrow$ PCS Decoder $\rightarrow$ MAC without corruption or byte loss.
3. **Alignment & Deskewing Timing**: Confirm that periodic AM indication pulses (`mld_is_am`) trigger accurately without corrupting active packet transmissions.

---

## 🔍 Key Testbench Components (`wrapper.cpp`)

### 1. Clock and Reset Drive
* Generates a free-running system clock (`clk`) toggled at every half-step of the simulation loop.
* Asserts active-low reset (`rst_n = 0`) for initial clock cycles before enabling packet processing.

### 2. AXI-Stream Driver (Linux TAP to HDL)
* Reads raw Ethernet frames from the Linux `tap0` character device (`/dev/net/tun`).
* Converts frames into 64-bit AXI-Stream words (`tx_data`, `tx_keep`, `tx_valid`, `tx_last`) synchronized with `tx_ready` backpressure from `mac_tx`.

### 3. AXI-Stream Monitor (HDL to Linux TAP)
* Captures reconstructed AXI-Stream words (`rx_data`, `rx_keep`, `rx_valid`, `rx_last`) output by `mac_rx`.
* Reassembles frames and writes them back to the TAP interface so the Linux kernel networking stack receives valid Ethernet responses.

### 4. Waveform Tracing
* Instantiates `VerilatedFstC` to capture full hierarchy signal transitions.
* Dumps execution traces to `dump.fst` or `top.fst` for post-simulation debugging in GTKWave or Surfer.

---

## 📊 Internal Signals Reference

| Sub-Module | Output Signal | Width | Description |
| :--- | :--- | :--- | :--- |
| `mac_tx` | `cgmii_txd` / `cgmii_txc` | 64-bit / 8-bit | CGMII bus transmitting Ethernet frame delimiters (`FB`, `FD`) and payload. |
| `pcs_encoder_c82` | `pcs_block` | 66-bit | Clause 82 encoded block with `2'b01` (data) or `2'b10` (control) sync bits. |
| `mld_tx` | `pcs_block_out` | 66-bit | Scrambled payload block output stream. |
| `mld_tx` | `mld_lane_id` | 5-bit | Sideband Virtual Lane counter (0 to 19) updated in round-robin sequence. |
| `mld_tx` | `mld_is_am` | 1-bit | Sideband pulse signaling Alignment Marker occurrence for current lane. |
| `mld_tx` | `mld_am_pattern` | 66-bit | Expected 66-bit Alignment Marker pattern for active lane. |
| `mld_rx` | `pcs_block_out` | 66-bit | Descrambled 66-bit block delivered to the PCS decoder. |

---

## 🚀 Execution Flow

1. **Environment Setup**: `setup_netns.sh` configures namespace `ns0` and TAP device `tap0`.
2. **Simulation Run**: Executing `./obj_dir/emulator` starts `wrapper.cpp`, driving clock/reset and polling `tap0`.
3. **Traffic Injection**: Running `ping -c 2 -I tap0 10.0.0.2` sends ARP and ICMP Echo requests through `tap0` into the simulation.
4. **Pass Criteria**: Ping responses (`64 bytes from 10.0.0.2...`) received without packet loss indicate 100% data path correctness.
