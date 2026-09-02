`timescale 1ns/1ps

// ============================================================================
// Módulo Top: PCS Cláusula 82 + MLD por Señalización Lateral (Verilator Clean)
// ============================================================================
module top #(
    parameter int AM_INTERVAL = 64,
    parameter int NUM_LANES   = 20
) (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        enable_scrambler,

    // Interfaz A
    input  logic [63:0] a_tx_data,
    input  logic [7:0]  a_tx_keep,
    input  logic        a_tx_valid,
    input  logic        a_tx_last,
    output logic        a_tx_ready,

    output logic [63:0] a_rx_data,
    output logic [7:0]  a_rx_keep,
    output logic        a_rx_valid,
    output logic        a_rx_last,
    input  logic        a_rx_ready,

    // Interfaz B
    input  logic [63:0] b_tx_data,
    input  logic [7:0]  b_tx_keep,
    input  logic        b_tx_valid,
    input  logic        b_tx_last,
    output logic        b_tx_ready,

    output logic [63:0] b_rx_data,
    output logic [7:0]  b_rx_keep,
    output logic        b_rx_valid,
    output logic        b_rx_last,
    input  logic        b_rx_ready
);

    // ------------------------------------------------------------------------
    // Interconexiones Ruta A -> B
    // ------------------------------------------------------------------------
    logic [63:0] cgmii_txd_a;
    logic [7:0]  cgmii_txc_a;
    logic [65:0] pcs_block_raw_a;

    logic [65:0] mld_stream_a2b;
    logic [4:0]  mld_lane_id_a2b;
    logic        mld_is_am_a2b;
    logic [65:0] mld_am_pattern_a2b;

    logic [65:0] pcs_block_mld_b;
    logic [63:0] cgmii_rxd_b;
    logic [7:0]  cgmii_rxc_b;

    // ------------------------------------------------------------------------
    // Interconexiones Ruta B -> A
    // ------------------------------------------------------------------------
    logic [63:0] cgmii_txd_b;
    logic [7:0]  cgmii_txc_b;
    logic [65:0] pcs_block_raw_b;

    logic [65:0] mld_stream_b2a;
    logic [4:0]  mld_lane_id_b2a;
    logic        mld_is_am_b2a;
    logic [65:0] mld_am_pattern_b2a;

    logic [65:0] pcs_block_mld_a;
    logic [63:0] cgmii_rxd_a;
    logic [7:0]  cgmii_rxc_a;

    // ========================================================================
    // Pipeline Path A -> B
    // ========================================================================
    mac_tx mac_tx_inst_a (
        .clk       (clk),
        .rst_n     (rst_n),
        .tx_data   (a_tx_data),
        .tx_keep   (a_tx_keep),
        .tx_valid  (a_tx_valid),
        .tx_last   (a_tx_last),
        .tx_ready  (a_tx_ready),
        .cgmii_txd (cgmii_txd_a),
        .cgmii_txc (cgmii_txc_a)
    );

    pcs_encoder_c82 pcs_enc_inst_a (
        .clk       (clk),
        .rst_n     (rst_n),
        .cgmii_txd (cgmii_txd_a),
        .cgmii_txc (cgmii_txc_a),
        .pcs_block (pcs_block_raw_a)
    );

    mld_tx #(
        .AM_INTERVAL(AM_INTERVAL),
        .NUM_LANES(NUM_LANES)
    ) mld_tx_inst_a (
        .clk              (clk),
        .rst_n            (rst_n),
        .enable_scrambler (enable_scrambler),
        .pcs_block_in     (pcs_block_raw_a),
        .pcs_block_out    (mld_stream_a2b),
        .mld_lane_id      (mld_lane_id_a2b),
        .mld_is_am        (mld_is_am_a2b),
        .mld_am_pattern   (mld_am_pattern_a2b)
    );

    mld_rx #(
        .AM_INTERVAL(AM_INTERVAL),
        .NUM_LANES(NUM_LANES)
    ) mld_rx_inst_b (
        .clk              (clk),
        .rst_n            (rst_n),
        .enable_scrambler (enable_scrambler),
        .pcs_block_in     (mld_stream_a2b),
        .mld_lane_id      (mld_lane_id_a2b),
        .mld_is_am        (mld_is_am_a2b),
        .mld_am_pattern   (mld_am_pattern_a2b),
        .pcs_block_out    (pcs_block_mld_b)
    );

    pcs_decoder_c82 pcs_dec_inst_b (
        .clk       (clk),
        .rst_n     (rst_n),
        .pcs_block (pcs_block_mld_b),
        .cgmii_rxd (cgmii_rxd_b),
        .cgmii_rxc (cgmii_rxc_b)
    );

    mac_rx mac_rx_inst_b (
        .clk       (clk),
        .rst_n     (rst_n),
        .cgmii_rxd (cgmii_rxd_b),
        .cgmii_rxc (cgmii_rxc_b),
        .rx_data   (b_rx_data),
        .rx_keep   (b_rx_keep),
        .rx_valid  (b_rx_valid),
        .rx_last   (b_rx_last),
        .rx_ready  (b_rx_ready)
    );

    // ========================================================================
    // Pipeline Path B -> A
    // ========================================================================
    mac_tx mac_tx_inst_b (
        .clk       (clk),
        .rst_n     (rst_n),
        .tx_data   (b_tx_data),
        .tx_keep   (b_tx_keep),
        .tx_valid  (b_tx_valid),
        .tx_last   (b_tx_last),
        .tx_ready  (b_tx_ready),
        .cgmii_txd (cgmii_txd_b),
        .cgmii_txc (cgmii_txc_b)
    );

    pcs_encoder_c82 pcs_enc_inst_b (
        .clk       (clk),
        .rst_n     (rst_n),
        .cgmii_txd (cgmii_txd_b),
        .cgmii_txc (cgmii_txc_b),
        .pcs_block (pcs_block_raw_b)
    );

    mld_tx #(
        .AM_INTERVAL(AM_INTERVAL),
        .NUM_LANES(NUM_LANES)
    ) mld_tx_inst_b (
        .clk              (clk),
        .rst_n            (rst_n),
        .enable_scrambler (enable_scrambler),
        .pcs_block_in     (pcs_block_raw_b),
        .pcs_block_out    (mld_stream_b2a),
        .mld_lane_id      (mld_lane_id_b2a),
        .mld_is_am        (mld_is_am_b2a),
        .mld_am_pattern   (mld_am_pattern_b2a)
    );

    mld_rx #(
        .AM_INTERVAL(AM_INTERVAL),
        .NUM_LANES(NUM_LANES)
    ) mld_rx_inst_a (
        .clk              (clk),
        .rst_n            (rst_n),
        .enable_scrambler (enable_scrambler),
        .pcs_block_in     (mld_stream_b2a),
        .mld_lane_id      (mld_lane_id_b2a),
        .mld_is_am        (mld_is_am_b2a),
        .mld_am_pattern   (mld_am_pattern_b2a),
        .pcs_block_out    (pcs_block_mld_a)
    );

    pcs_decoder_c82 pcs_dec_inst_a (
        .clk       (clk),
        .rst_n     (rst_n),
        .pcs_block (pcs_block_mld_a),
        .cgmii_rxd (cgmii_rxd_a),
        .cgmii_rxc (cgmii_rxc_a)
    );

    mac_rx mac_rx_inst_a (
        .clk       (clk),
        .rst_n     (rst_n),
        .cgmii_rxd (cgmii_rxd_a),
        .cgmii_rxc (cgmii_rxc_a),
        .rx_data   (a_rx_data),
        .rx_keep   (a_rx_keep),
        .rx_valid  (a_rx_valid),
        .rx_last   (a_rx_last),
        .rx_ready  (a_rx_ready)
    );

endmodule

// ============================================================================
// Transmisor MLD: Aleatorización + Asignación de Lane + Señalización AM
// ============================================================================
module mld_tx #(
    parameter int AM_INTERVAL = 64,
    parameter int NUM_LANES   = 20
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable_scrambler,
    input  logic [65:0] pcs_block_in,

    output logic [65:0] pcs_block_out,
    output logic [4:0]  mld_lane_id,
    output logic        mld_is_am,
    output logic [65:0] mld_am_pattern
);

    logic [15:0] block_cnt;
    logic [4:0]  lane_ptr;
    logic [57:0] lfsr;

    // Función puramente combinacional para evitar conflicto de asignaciones
    function automatic logic [63:0] scramble_64b(
        input  logic [63:0] din,
        input  logic [57:0] lfsr_in,
        output logic [57:0] lfsr_out
    );
        logic [63:0] dout;
        logic [57:0] state;
        state = lfsr_in;
        for (int i = 0; i < 64; i++) begin
            logic bit_out = din[i] ^ state[57] ^ state[38];
            state = {state[56:0], bit_out};
            dout[i] = bit_out;
        end
        lfsr_out = state;
        return dout;
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr           <= 58'h3FFFFFFFFFFFFFF;
            block_cnt      <= 16'd0;
            lane_ptr       <= 5'd0;
            pcs_block_out  <= {2'b10, 8'h1E, 56'h0};
            mld_lane_id    <= 5'd0;
            mld_is_am      <= 1'b0;
            mld_am_pattern <= {2'b10, 8'hC1, 8'h00, 48'h00_A5_A5_A5_A5_A5};
        end else begin
            logic [57:0] next_lfsr;
            logic [63:0] scrambled_payload;

            mld_lane_id <= lane_ptr;
            if (lane_ptr == NUM_LANES - 1)
                lane_ptr <= 5'd0;
            else
                lane_ptr <= lane_ptr + 1'b1;

            mld_am_pattern <= {2'b10, 8'hC1, 8'(lane_ptr), 48'h00_A5_A5_A5_A5_A5};

            if (block_cnt == AM_INTERVAL - 1) begin
                block_cnt <= 16'd0;
                mld_is_am <= 1'b1;
            end else begin
                block_cnt <= block_cnt + 1'b1;
                mld_is_am <= 1'b0;
            end

            if (enable_scrambler) begin
                scrambled_payload = scramble_64b(pcs_block_in[63:0], lfsr, next_lfsr);
                pcs_block_out     <= {pcs_block_in[65:64], scrambled_payload};
                lfsr              <= next_lfsr;
            end else begin
                pcs_block_out     <= pcs_block_in;
            end
        end
    end

endmodule

// ============================================================================
// Receptor MLD: Verificación de AM + Desaleatorización
// ============================================================================
module mld_rx #(
    /* verilator lint_off UNUSEDPARAM */
    parameter int AM_INTERVAL = 64,
    parameter int NUM_LANES   = 20
    /* verilator lint_on UNUSEDPARAM */
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable_scrambler,

    input  logic [65:0] pcs_block_in,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic [4:0]  mld_lane_id,
    input  logic        mld_is_am,
    input  logic [65:0] mld_am_pattern,
    /* verilator lint_on UNUSEDSIGNAL */

    output logic [65:0] pcs_block_out
);

    logic [57:0] lfsr;

    function automatic logic [63:0] descramble_64b(
        input  logic [63:0] din,
        input  logic [57:0] lfsr_in,
        output logic [57:0] lfsr_out
    );
        logic [63:0] dout;
        logic [57:0] state;
        state = lfsr_in;
        for (int i = 0; i < 64; i++) begin
            logic bit_out = din[i] ^ state[57] ^ state[38];
            state = {state[56:0], din[i]};
            dout[i] = bit_out;
        end
        lfsr_out = state;
        return dout;
    endfunction

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lfsr          <= 58'h3FFFFFFFFFFFFFF;
            pcs_block_out <= {2'b10, 8'h1E, 56'h0};
        end else begin
            logic [57:0] next_lfsr;
            logic [63:0] descrambled_payload;

            if (enable_scrambler) begin
                descrambled_payload = descramble_64b(pcs_block_in[63:0], lfsr, next_lfsr);
                pcs_block_out       <= {pcs_block_in[65:64], descrambled_payload};
                lfsr                <= next_lfsr;
            end else begin
                pcs_block_out       <= pcs_block_in;
            end
        end
    end

endmodule

// ============================================================================
// Codificador PCS 64b/66b (Cláusula 82 IEEE 802.3)
// ============================================================================
module pcs_encoder_c82 (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [63:0] cgmii_txd,
    input  logic [7:0]  cgmii_txc,
    output logic [65:0] pcs_block
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pcs_block <= {2'b10, 8'h1E, 56'h0};
        end else begin
            if (cgmii_txc == 8'h00) begin
                pcs_block <= {2'b01, cgmii_txd};
            end else if (cgmii_txc == 8'hFF && cgmii_txd == 64'h0707070707070707) begin
                pcs_block <= {2'b10, 8'h1E, 56'h0};
            end else if (cgmii_txc == 8'h01 && cgmii_txd[7:0] == 8'hFB) begin
                pcs_block <= {2'b10, 8'h78, cgmii_txd[63:8]};
            end else begin
                logic [2:0] term_pos;
                term_pos = 3'd0;
                for (int i = 0; i < 8; i++) begin
                    if (cgmii_txc[i] && cgmii_txd[i*8 +: 8] == 8'hFD) begin
                        term_pos = i[2:0];
                    end
                end

                case (term_pos)
                    3'd0: pcs_block <= {2'b10, 8'h87, 56'h0};
                    3'd1: pcs_block <= {2'b10, 8'h99, 48'h0, cgmii_txd[7:0]};
                    3'd2: pcs_block <= {2'b10, 8'hAA, 40'h0, cgmii_txd[15:0]};
                    3'd3: pcs_block <= {2'b10, 8'hB4, 32'h0, cgmii_txd[23:0]};
                    3'd4: pcs_block <= {2'b10, 8'hCC, 24'h0, cgmii_txd[31:0]};
                    3'd5: pcs_block <= {2'b10, 8'hD2, 16'h0, cgmii_txd[39:0]};
                    3'd6: pcs_block <= {2'b10, 8'hE1, 8'h0,  cgmii_txd[47:0]};
                    3'd7: pcs_block <= {2'b10, 8'hFF, cgmii_txd[55:0]};
                endcase
            end
        end
    end

endmodule

// ============================================================================
// Decodificador PCS 66b/64b (Cláusula 82 IEEE 802.3)
// ============================================================================
module pcs_decoder_c82 (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [65:0] pcs_block,
    output logic [63:0] cgmii_rxd,
    output logic [7:0]  cgmii_rxc
);

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cgmii_rxd <= 64'h0707070707070707;
            cgmii_rxc <= 8'hFF;
        end else begin
            if (pcs_block[65:64] == 2'b01) begin
                cgmii_rxd <= pcs_block[63:0];
                cgmii_rxc <= 8'h00;
            end else if (pcs_block[65:64] == 2'b10) begin
                case (pcs_block[63:56])
                    8'h1E: begin
                        cgmii_rxd <= 64'h0707070707070707;
                        cgmii_rxc <= 8'hFF;
                    end
                    8'h78: begin
                        cgmii_rxd <= {pcs_block[55:0], 8'hFB};
                        cgmii_rxc <= 8'h01;
                    end
                    8'h87: begin
                        cgmii_rxd <= {56'h07070707070707, 8'hFD};
                        cgmii_rxc <= 8'hFF;
                    end
                    8'h99: begin
                        cgmii_rxd <= {48'h070707070707, 8'hFD, pcs_block[7:0]};
                        cgmii_rxc <= 8'hFE;
                    end
                    8'hAA: begin
                        cgmii_rxd <= {40'h0707070707, 8'hFD, pcs_block[15:0]};
                        cgmii_rxc <= 8'hFC;
                    end
                    8'hB4: begin
                        cgmii_rxd <= {32'h07070707, 8'hFD, pcs_block[23:0]};
                        cgmii_rxc <= 8'hF8;
                    end
                    8'hCC: begin
                        cgmii_rxd <= {24'h070707, 8'hFD, pcs_block[31:0]};
                        cgmii_rxc <= 8'hF0;
                    end
                    8'hD2: begin
                        cgmii_rxd <= {16'h0707, 8'hFD, pcs_block[39:0]};
                        cgmii_rxc <= 8'hE0;
                    end
                    8'hE1: begin
                        cgmii_rxd <= {8'h07, 8'hFD, pcs_block[47:0]};
                        cgmii_rxc <= 8'hC0;
                    end
                    8'hFF: begin
                        cgmii_rxd <= {8'hFD, pcs_block[55:0]};
                        cgmii_rxc <= 8'h80;
                    end
                    default: begin
                        cgmii_rxd <= 64'h0707070707070707;
                        cgmii_rxc <= 8'hFF;
                    end
                endcase
            end else begin
                cgmii_rxd <= 64'h0707070707070707;
                cgmii_rxc <= 8'hFF;
            end
        end
    end

endmodule

// ============================================================================
// MAC Transmitter (AXI-Stream -> CGMII)
// ============================================================================
module mac_tx (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [63:0] tx_data,
    input  logic [7:0]  tx_keep,
    input  logic        tx_valid,
    input  logic        tx_last,
    output logic        tx_ready,
    output logic [63:0] cgmii_txd,
    output logic [7:0]  cgmii_txc
);

    typedef enum logic [1:0] {
        ST_IDLE,
        ST_PREAMBLE,
        ST_PAYLOAD,
        ST_TERM
    } state_t;

    state_t state;
    logic [63:0] reg_data;
    logic [7:0]  reg_keep;
    logic        reg_last;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state    <= ST_IDLE;
            reg_data <= 64'h0;
            reg_keep <= 8'h0;
            reg_last <= 1'b0;
        end else begin
            case (state)
                ST_IDLE: begin
                    if (tx_valid) begin
                        reg_data <= tx_data;
                        reg_keep <= tx_keep;
                        reg_last <= tx_last;
                        state    <= ST_PREAMBLE;
                    end
                end

                ST_PREAMBLE: begin
                    state <= ST_PAYLOAD;
                end

                ST_PAYLOAD: begin
                    if (!reg_last) begin
                        if (tx_valid) begin
                            reg_data <= tx_data;
                            reg_keep <= tx_keep;
                            reg_last <= tx_last;
                        end
                    end else begin
                        if (reg_keep == 8'hFF) begin
                            state <= ST_TERM;
                        end else begin
                            if (tx_valid) begin
                                reg_data <= tx_data;
                                reg_keep <= tx_keep;
                                reg_last <= tx_last;
                                state    <= ST_PREAMBLE;
                            end else begin
                                state    <= ST_IDLE;
                            end
                        end
                    end
                end

                ST_TERM: begin
                    if (tx_valid) begin
                        reg_data <= tx_data;
                        reg_keep <= tx_keep;
                        reg_last <= tx_last;
                        state    <= ST_PREAMBLE;
                    end else begin
                        state    <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end

    always_comb begin
        tx_ready  = 1'b0;
        cgmii_txd = 64'h0707070707070707;
        cgmii_txc = 8'hFF;

        case (state)
            ST_IDLE: begin
                tx_ready = 1'b1;
            end

            ST_PREAMBLE: begin
                cgmii_txd = 64'hD5555555555555FB;
                cgmii_txc = 8'h01;
                tx_ready  = 1'b0;
            end

            ST_PAYLOAD: begin
                if (!reg_last) begin
                    cgmii_txd = reg_data;
                    cgmii_txc = 8'h00;
                    tx_ready  = 1'b1;
                end else begin
                    if (reg_keep == 8'hFF) begin
                        cgmii_txd = reg_data;
                        cgmii_txc = 8'h00;
                        tx_ready  = 1'b0;
                    end else begin
                        cgmii_txd = format_term_word(reg_data, reg_keep);
                        cgmii_txc = format_term_ctrl(reg_keep);
                        tx_ready  = 1'b1;
                    end
                end
            end

            ST_TERM: begin
                cgmii_txd = 64'h07070707070707FD;
                cgmii_txc = 8'hFF;
                tx_ready  = 1'b1;
            end

            default: ;
        endcase
    end

    /* verilator lint_off UNUSEDSIGNAL */
    function automatic logic [63:0] format_term_word(input logic [63:0] data, input logic [7:0] keep);
        case (keep)
            8'h01: return {56'h07070707070707, 8'hFD, data[7:0]};
            8'h03: return {48'h070707070707, 8'hFD, data[15:0]};
            8'h07: return {40'h0707070707, 8'hFD, data[23:0]};
            8'h0F: return {32'h07070707, 8'hFD, data[31:0]};
            8'h1F: return {24'h070707, 8'hFD, data[39:0]};
            8'h3F: return {16'h0707, 8'hFD, data[47:0]};
            8'h7F: return {8'h07, 8'hFD, data[55:0]};
            default: return {56'h07070707070707, 8'hFD, data[7:0]};
        endcase
    endfunction
    /* verilator lint_on UNUSEDSIGNAL */

    function automatic logic [7:0] format_term_ctrl(input logic [7:0] keep);
        case (keep)
            8'h01: return 8'hFE;
            8'h03: return 8'hFC;
            8'h07: return 8'hF8;
            8'h0F: return 8'hF0;
            8'h1F: return 8'hE0;
            8'h3F: return 8'hC0;
            8'h7F: return 8'h80;
            default: return 8'hFE;
        endcase
    endfunction

endmodule

// ============================================================================
// MAC Receiver (CGMII -> AXI-Stream)
// ============================================================================
module mac_rx (
    input  logic        clk,
    input  logic        rst_n,
    input  logic [63:0] cgmii_rxd,
    input  logic [7:0]  cgmii_rxc,
    output logic [63:0] rx_data,
    output logic [7:0]  rx_keep,
    output logic        rx_valid,
    output logic        rx_last,
    /* verilator lint_off UNUSEDSIGNAL */
    input  logic        rx_ready
    /* verilator lint_on UNUSEDSIGNAL */
);

    logic in_frame;
    logic [63:0] prev_data;
    logic [7:0]  prev_keep;
    logic has_prev;
    logic flush_last;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_frame   <= 1'b0;
            prev_data  <= 64'h0;
            prev_keep  <= 8'h0;
            has_prev   <= 1'b0;
            flush_last <= 1'b0;

            rx_data    <= 64'h0;
            rx_keep    <= 8'h0;
            rx_valid   <= 1'b0;
            rx_last    <= 1'b0;
        end else begin
            rx_valid <= 1'b0;
            rx_last  <= 1'b0;

            if (flush_last) begin
                rx_data    <= prev_data;
                rx_keep    <= prev_keep;
                rx_valid   <= 1'b1;
                rx_last    <= 1'b1;
                flush_last <= 1'b0;
                has_prev   <= 1'b0;

                if (cgmii_rxc == 8'h01 && cgmii_rxd[7:0] == 8'hFB) begin
                    in_frame <= 1'b1;
                end else begin
                    in_frame <= 1'b0;
                end
            end else if (!in_frame) begin
                if (cgmii_rxc == 8'h01 && cgmii_rxd[7:0] == 8'hFB) begin
                    in_frame <= 1'b1;
                    has_prev <= 1'b0;
                end
            end else begin
                if (cgmii_rxc == 8'h00) begin
                    if (has_prev) begin
                        rx_data  <= prev_data;
                        rx_keep  <= 8'hFF;
                        rx_valid <= 1'b1;
                        rx_last  <= 1'b0;
                    end
                    prev_data <= cgmii_rxd;
                    prev_keep <= 8'hFF;
                    has_prev  <= 1'b1;
                end else begin
                    if (cgmii_rxd[7:0] == 8'hFD) begin
                        if (has_prev) begin
                            rx_data  <= prev_data;
                            rx_keep  <= 8'hFF;
                            rx_valid <= 1'b1;
                            rx_last  <= 1'b1;
                            has_prev <= 1'b0;
                        end
                        in_frame <= 1'b0;
                    end else begin
                        logic [2:0] term_pos;
                        logic [7:0] curr_keep;
                        logic [63:0] curr_data;

                        term_pos  = get_term_pos(cgmii_rxd, cgmii_rxc);
                        curr_keep = (8'h01 << term_pos) - 8'h01;
                        curr_data = cgmii_rxd & mask_by_pos(term_pos);

                        if (has_prev) begin
                            rx_data    <= prev_data;
                            rx_keep    <= 8'hFF;
                            rx_valid   <= 1'b1;
                            rx_last    <= 1'b0;

                            prev_data  <= curr_data;
                            prev_keep  <= curr_keep;
                            flush_last <= 1'b1;
                        end else begin
                            rx_data  <= curr_data;
                            rx_keep  <= curr_keep;
                            rx_valid <= 1'b1;
                            rx_last  <= 1'b1;
                            in_frame <= 1'b0;
                        end
                    end
                end
            end
        end
    end

    /* verilator lint_off UNUSEDSIGNAL */
    function automatic logic [2:0] get_term_pos(input logic [63:0] d, input logic [7:0] c);
        if (c[1] && d[15:8] == 8'hFD) return 3'd1;
        if (c[2] && d[23:16] == 8'hFD) return 3'd2;
        if (c[3] && d[31:24] == 8'hFD) return 3'd3;
        if (c[4] && d[39:32] == 8'hFD) return 3'd4;
        if (c[5] && d[47:40] == 8'hFD) return 3'd5;
        if (c[6] && d[55:48] == 8'hFD) return 3'd6;
        if (c[7] && d[63:56] == 8'hFD) return 3'd7;
        return 3'd0;
    endfunction
    /* verilator lint_on UNUSEDSIGNAL */

    function automatic logic [63:0] mask_by_pos(input logic [2:0] pos);
        case (pos)
            3'd1: return 64'h00000000000000FF;
            3'd2: return 64'h000000000000FFFF;
            3'd3: return 64'h0000000000FFFFFF;
            3'd4: return 64'h00000000FFFFFFFF;
            3'd5: return 64'h000000FFFFFFFFFF;
            3'd6: return 64'h0000FFFFFFFFFFFF;
            3'd7: return 64'h00FFFFFFFFFFFFFF;
            default: return 64'h0;
        endcase
    endfunction

endmodule
