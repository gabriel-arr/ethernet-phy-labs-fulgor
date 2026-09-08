# Lab 4 Assignment: Multi-Lane Distribution (MLD) Waveform Analysis

In this assignment, you will focus strictly on analyzing the Multi-Lane Distribution (MLD) mechanism defined in IEEE 802.3 Clause 82 using GTKWave. (PCS 64b/66b encoding and scrambler functionality were covered in the previous lab).

---

## 🎯 Lab Objectives

1. **Virtual Lane Distribution**: Trace the 20 Virtual Lanes (VLs) distributed in a continuous round-robin sequence across the 66-bit block stream.
2. **Alignment Marker (AM) Timing**: Verify the periodicity of AM insertion and measure the interval between AM pulses.
3. **AM Pattern Decoding**: Extract lane-specific 66-bit Alignment Marker patterns and identify how the Virtual Lane ID is encoded.
4. **MLD Sideband Propagation**: Trace sideband MLD signaling (`mld_lane_id`, `mld_is_am`, `mld_am_pattern`) from transmitter to receiver.

---

## 📋 Assignment Tasks

### Task 1: Virtual Lane Round-Robin Sequence

1. Open GTKWave with the trace file generated during simulation:
   ```bash
   gtkwave dump.fst
   ```
2. Navigate to the transmitter module: `top.mld_tx_inst_a`.
3. Add the following signals to the waveform viewer:
   * `clk`
   * `rst_n`
   * `mld_lane_id[4:0]`
   * `pcs_block_out[65:0]`
4. **Verification**:
   * Format `mld_lane_id` as **Decimal**.
   * Observe `mld_lane_id` across at least 25 consecutive clock cycles.
   * **Question 1.1**: Does `mld_lane_id` increment sequentially from `0` to `19` and immediately wrap back to `0`?
   * **Question 1.2**: Is a block dispatched on every clock edge corresponding to the incrementing `mld_lane_id`?

---

### Task 2: Alignment Marker (AM) Insertion & Pattern Encoding

1. Add the following signals from `top.mld_tx_inst_a` to GTKWave:
   * `mld_is_am`
   * `mld_am_pattern[65:0]`
   * `mld_lane_id[4:0]`
2. Zoom out in GTKWave until you see periodic high pulses on `mld_is_am`.
3. **Verification**:
   * Measure the distance (in clock cycles) between two consecutive high pulses of `mld_is_am`.
   * **Question 2.1**: How many clock cycles elapse between AM pulses? Does this match the simulation parameter `-GAM_INTERVAL=64`?
   * Set `mld_am_pattern[65:0]` display format to **Hexadecimal**.
   * **Question 2.2**: Record the 66-bit value of `mld_am_pattern` when `mld_is_am = 1` for **Virtual Lane 0** (`mld_lane_id = 0`) and **Virtual Lane 5** (`mld_lane_id = 5`).
   * **Question 2.3**: Locate the specific byte field within `mld_am_pattern[65:0]` that changes dynamically as `mld_lane_id` increments.

---

### Task 3: MLD Transmitter-to-Receiver Sideband Tracking

1. Compare transmitter MLD sideband outputs with receiver MLD inputs by adding:
   * `top.mld_tx_inst_a.mld_lane_id[4:0]` (Transmitter output)
   * `top.mld_rx_inst_b.mld_lane_id[4:0]` (Receiver input)
   * `top.mld_tx_inst_a.mld_is_am` (Transmitter output)
   * `top.mld_rx_inst_b.mld_is_am` (Receiver input)
2. **Verification**:
   * Zoom in on an Alignment Marker event (`mld_is_am = 1`).
   * **Question 3.1**: What is the pipeline delay (in clock cycles) between `mld_is_am` asserting on `mld_tx_inst_a` and arriving at `mld_rx_inst_b`?
   * **Question 3.2**: Does `mld_rx_inst_b` maintain correct Virtual Lane alignment (`mld_lane_id`) relative to the incoming 66-bit block stream?

---

## 📤 Submission Deliverables

Submit a brief report containing:

1. **Answers to Questions 1.1 through 3.2**.
2. **Screenshot 1**: GTKWave capture showing `mld_lane_id` cycling through lanes 0 to 19 sequentially.
3. **Screenshot 2**: GTKWave capture zoomed in on `mld_is_am = 1`, highlighting the 66-bit `mld_am_pattern` value and corresponding `mld_lane_id`.
4. **Screenshot 3**: GTKWave capture showing the sideband signals (`mld_lane_id`, `mld_is_am`) propagating from `mld_tx_inst_a` to `mld_rx_inst_b`.
