# Lab 4: 100GBASE-R PCS and Multi-Lane Distribution (MLD)

This repository implements a SystemVerilog model of the Physical Coding Sublayer (PCS) and Multi-Lane Distribution (MLD) mechanism for 100GBASE-R Ethernet, compliant with IEEE 802.3 Clause 82. The design is verified using a C++ CTest / Verilator harness and visualized in GTKWave.

---

## 📚 IEEE 802.3 Clause 82 Concepts

### 64b/66b Encoding
To guarantee adequate transition density and DC balance across high-speed serial links, Clause 82 encodes 64-bit data/control words into 66-bit blocks:
* **`2'b01` Sync Header**: Indicates a pure Data block (64 bits of payload).
* **`2'b10` Sync Header**: Indicates a Control block (8-bit block type field + 56-bit payload/control code).

### Multi-Lane Distribution (MLD)
Physical PMD layers for 100G Ethernet run over multiple physical channels (e.g., 4 x 25G or 10 x 10G optical/copper lanes). To abstract physical pin counts from the PCS layer, Clause 82 introduces **20 Virtual Lanes (VLs)**:
* **Round-Robin Distribution**: PCS 66-bit blocks are distributed sequentially across Virtual Lanes 0 through 19.
* **Lane Identification**: Each Virtual Lane carries a unique identifier embedded within periodic control structures.

### Alignment Markers (AM)
Because physical paths may introduce skew between lanes, the transmitter periodically replaces normal 66-bit blocks with **Alignment Markers**:
* **Interval**: Inserted once every `AM_INTERVAL` blocks per lane.
* **Pattern**: Unique 66-bit patterns per Virtual Lane (e.g., `66'h2_C1_XX_00A5A5A5A5A5` where `XX` is the 8-bit Lane ID).
* **Purpose**: Allows the receiver to perform lane identification, deskewing, and re-ordering independent of physical pin mappings.

### Payload Scrambling
To prevent repetitive bit patterns from creating spectral spikes, 64-bit block payloads are scrambled using polynomial $G(x) = x^{58} + x^{39} + 1$. Sync bits (`[65:64]`) are left un-scrambled to preserve block synchronization.

---

## 🏗️ System Architecture & File Structure

* **`top.sv`**: Top-level wrapper containing the bidirectional PCS/MLD pipeline (`mac_tx`, `pcs_encoder_c82`, `mld_tx`, `mld_rx`, `pcs_decoder_c82`, `mac_rx`).
* **`wrapper.cpp`**: C++ testbench for Verilator handling clocking, TAP interface instantiation, and FST trace generation.

---

## 🏃 How to Run

1. **Initialize Network Environment:**

```bash
sudo ../scripts/setup_netns.sh
```

2. **Compile and Run Emulation:**

```bash
verilator --cc --trace-fst --trace-structs --trace-max-array 1024 --trace-depth 99 --exe --build --top-module top -j 0 -GAM_INTERVAL=64 -GNUM_LANES=20 -CFLAGS "-DTRACE_ENABLE" -Wall -Wno-DECLFILENAME -Wno-BLKSEQ -Wno-WIDTHEXPAND -Wno-WIDTHTRUNC wrapper.cpp top.sv -o emulator
sudo ./obj_dir/emulator
```

3. **Generate Traffic (In a second terminal):**

```bash
ping -c 2 -I tap0 10.0.0.2
```

4. **Inspect Waveforms:**

```bash
gtkwave dump.fst
```
