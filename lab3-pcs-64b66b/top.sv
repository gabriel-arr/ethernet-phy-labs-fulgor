// ============================================================================
// File: top.sv
// Description: Back-to-Back MAC + PCS Architecture (Clause 49/82 64b/66b)
//              with Latch-Free IEEE 802.3 Scrambler/Descrambler
// Topology: Host A <-> MAC A <-> CGMII <-> PCS A <== Split 66b ==> PCS B <-> MAC B <-> Host B
// ============================================================================

module top #(
    parameter bit ENABLE_DEBUG = 1'b0
) (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable_scrambler,

    // Host A Interface
    input  logic [63:0] a_tx_data,
    input  logic [7:0]  a_tx_keep,
    input  logic        a_tx_valid,
    input  logic        a_tx_last,
    output logic        a_tx_ready,

    output logic [63:0] a_rx_data,
    output logic [7:0]  a_rx_keep,
    output logic        a_rx_valid,
    output logic        a_rx_last,

    // Host B Interface
    input  logic [63:0] b_tx_data,
    input  logic [7:0]  b_tx_keep,
    input  logic        b_tx_valid,
    input  logic        b_tx_last,
    output logic        b_tx_ready,

    output logic [63:0] b_rx_data,
    output logic [7:0]  b_rx_keep,
    output logic        b_rx_valid,
    output logic        b_rx_last
);

    // Internal CGMII Signals: MAC <-> PCS
    logic [63:0] cgmii_mac_a2pcs_txd, cgmii_pcs2mac_a_rxd;
    logic [7:0]  cgmii_mac_a2pcs_txc, cgmii_pcs2mac_a_rxc;

    logic [63:0] cgmii_mac_b2pcs_txd, cgmii_pcs2mac_b_rxd;
    logic [7:0]  cgmii_mac_b2pcs_txc, cgmii_pcs2mac_b_rxc;

    // Split Physical Interconnects (PCS A <-> PCS B)
    logic [1:0]  pcs_a2b_hdr;
    logic [63:0] pcs_a2b_payload;

    logic [1:0]  pcs_b2a_hdr;
    logic [63:0] pcs_b2a_payload;

    // ------------------------------------------------------------------------
    // Host Side A: MAC A & PCS A
    // ------------------------------------------------------------------------
    mac_tx #(.ENABLE_DEBUG(ENABLE_DEBUG)) mac_tx_a (
        .clk(clk), .rst_n(rst_n),
        .host_tx_data(a_tx_data), .host_tx_keep(a_tx_keep),
        .host_tx_valid(a_tx_valid), .host_tx_last(a_tx_last),
        .host_tx_ready(a_tx_ready),
        .cgmii_txd(cgmii_mac_a2pcs_txd), .cgmii_txc(cgmii_mac_a2pcs_txc)
    );

    mac_rx #(.ENABLE_DEBUG(ENABLE_DEBUG)) mac_rx_a (
        .clk(clk), .rst_n(rst_n),
        .cgmii_rxd(cgmii_pcs2mac_a_rxd), .cgmii_rxc(cgmii_pcs2mac_a_rxc),
        .host_rx_data(a_rx_data), .host_rx_keep(a_rx_keep),
        .host_rx_valid(a_rx_valid), .host_rx_last(a_rx_last)
    );

    pcs_top pcs_a (
        .clk(clk), .rst_n(rst_n),
        .enable_scrambler(enable_scrambler),
        .cgmii_txd(cgmii_mac_a2pcs_txd), .cgmii_txc(cgmii_mac_a2pcs_txc),
        .cgmii_rxd(cgmii_pcs2mac_a_rxd), .cgmii_rxc(cgmii_pcs2mac_a_rxc),
        .tx_hdr(pcs_a2b_hdr),
        .tx_payload(pcs_a2b_payload),
        .rx_hdr(pcs_b2a_hdr),
        .rx_payload(pcs_b2a_payload)
    );

    // ------------------------------------------------------------------------
    // Host Side B: MAC B & PCS B
    // ------------------------------------------------------------------------
    mac_tx #(.ENABLE_DEBUG(ENABLE_DEBUG)) mac_tx_b (
        .clk(clk), .rst_n(rst_n),
        .host_tx_data(b_tx_data), .host_tx_keep(b_tx_keep),
        .host_tx_valid(b_tx_valid), .host_tx_last(b_tx_last),
        .host_tx_ready(b_tx_ready),
        .cgmii_txd(cgmii_mac_b2pcs_txd), .cgmii_txc(cgmii_mac_b2pcs_txc)
    );

    mac_rx #(.ENABLE_DEBUG(ENABLE_DEBUG)) mac_rx_b (
        .clk(clk), .rst_n(rst_n),
        .cgmii_rxd(cgmii_pcs2mac_b_rxd), .cgmii_rxc(cgmii_pcs2mac_b_rxc),
        .host_rx_data(b_rx_data), .host_rx_keep(b_rx_keep),
        .host_rx_valid(b_rx_valid), .host_rx_last(b_rx_last)
    );

    pcs_top pcs_b (
        .clk(clk), .rst_n(rst_n),
        .enable_scrambler(enable_scrambler),
        .cgmii_txd(cgmii_mac_b2pcs_txd), .cgmii_txc(cgmii_mac_b2pcs_txc),
        .cgmii_rxd(cgmii_pcs2mac_b_rxd), .cgmii_rxc(cgmii_pcs2mac_b_rxc),
        .tx_hdr(pcs_b2a_hdr),
        .tx_payload(pcs_b2a_payload),
        .rx_hdr(pcs_a2b_hdr),
        .rx_payload(pcs_a2b_payload)
    );

endmodule


// ============================================================================
// PCS Top Module
// ============================================================================
module pcs_top (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable_scrambler,

    // CGMII Interface (MAC side)
    input  logic [63:0] cgmii_txd,
    input  logic [7:0]  cgmii_txc,
    output logic [63:0] cgmii_rxd,
    output logic [7:0]  cgmii_rxc,

    // Split Line Interface (Physical side)
    output logic [1:0]  tx_hdr,
    output logic [63:0] tx_payload,
    input  logic [1:0]  rx_hdr,
    input  logic [63:0] rx_payload
);

    pcs_tx encoder (
        .clk(clk), .rst_n(rst_n),
        .enable_scrambler(enable_scrambler),
        .cgmii_txd(cgmii_txd), .cgmii_txc(cgmii_txc),
        .hdr(tx_hdr),
        .payload(tx_payload)
    );

    pcs_rx decoder (
        .clk(clk), .rst_n(rst_n),
        .enable_scrambler(enable_scrambler),
        .hdr(rx_hdr),
        .payload(rx_payload),
        .cgmii_rxd(cgmii_rxd), .cgmii_rxc(cgmii_rxc)
    );

endmodule


// ============================================================================
// PCS Transmitter: Clause 49/82 Encoder with Configurable Scrambler
// ============================================================================
module pcs_tx (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable_scrambler,
    input  logic [63:0] cgmii_txd,
    input  logic [7:0]  cgmii_txc,
    output logic [1:0]  hdr,      // 2'b01 = Data, 2'b10 = Control
    output logic [63:0] payload
);

    logic [1:0]  raw_hdr;
    logic [63:0] raw_payload;
    logic [57:0] scram_state;

    // 64b/66b Block Encoder
    always_comb begin
        raw_hdr     = 2'b10;
        raw_payload = {7'h00, 7'h00, 7'h00, 7'h00, 7'h00, 7'h00, 7'h00, 7'h00, 8'h1E};

        if (cgmii_txc == 8'h00) begin
            raw_hdr     = 2'b01;
            raw_payload = cgmii_txd;
        end else if (cgmii_txc == 8'hFF && cgmii_txd[7:0] == 8'h07) begin
            raw_hdr     = 2'b10;
            raw_payload = {7'h00, 7'h00, 7'h00, 7'h00, 7'h00, 7'h00, 7'h00, 7'h00, 8'h1E};
        end else if (cgmii_txc[0] && (cgmii_txd[7:0] == 8'hFB)) begin
            raw_hdr     = 2'b10;
            raw_payload = {cgmii_txd[63:8], 8'h78};
        end else if (cgmii_txc != 8'h00) begin
            raw_hdr = 2'b10;
            if (cgmii_txc == 8'hFF && cgmii_txd[7:0] == 8'hFD)
                raw_payload = {56'h0, 8'h87};
            else if (cgmii_txc == 8'hFE && cgmii_txd[15:8] == 8'hFD)
                raw_payload = {48'h0, cgmii_txd[7:0], 8'h99};
            else if (cgmii_txc == 8'hFC && cgmii_txd[23:16] == 8'hFD)
                raw_payload = {40'h0, cgmii_txd[15:0], 8'hAA};
            else if (cgmii_txc == 8'hF8 && cgmii_txd[31:24] == 8'hFD)
                raw_payload = {32'h0, cgmii_txd[23:0], 8'hB4};
            else if (cgmii_txc == 8'hF0 && cgmii_txd[39:32] == 8'hFD)
                raw_payload = {24'h0, cgmii_txd[31:0], 8'hCC};
            else if (cgmii_txc == 8'hE0 && cgmii_txd[47:40] == 8'hFD)
                raw_payload = {16'h0, cgmii_txd[39:0], 8'hD2};
            else if (cgmii_txc == 8'hC0 && cgmii_txd[55:48] == 8'hFD)
                raw_payload = {8'h0, cgmii_txd[47:0], 8'hE1};
            else if (cgmii_txc == 8'h80 && cgmii_txd[63:56] == 8'hFD)
                raw_payload = {cgmii_txd[55:0], 8'hFF};
            else
                raw_payload = {7'h00, 7'h00, 7'h00, 7'h00, 7'h00, 7'h00, 7'h00, 7'h00, 8'h1E};
        end else begin
            raw_hdr     = 2'b01;
            raw_payload = cgmii_txd;
        end
    end

    // 64-bit Parallel Self-Synchronizing Scrambler: G(x) = x^58 + x^39 + 1
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hdr         <= 2'b10;
            payload     <= {7'h00, 7'h00, 7'h00, 7'h00, 7'h00, 7'h00, 7'h00, 7'h00, 8'h1E};
            scram_state <= 58'h3FF_FFFF_FFFF_FFFF;
        end else begin
            hdr <= raw_hdr;

            if (enable_scrambler) begin
                logic [57:0] history;
                logic [63:0] y;

                history = scram_state;
                for (int i = 0; i < 64; i++) begin
                    logic b39, b58;
                    b39 = (i < 39) ? history[19 + i] : y[i - 39];
                    b58 = (i < 58) ? history[i]      : y[i - 58];
                    y[i] = raw_payload[i] ^ b39 ^ b58;
                end

                payload     <= y;
                scram_state <= y[63:6];
            end else begin
                payload <= raw_payload;
            end
        end
    end
endmodule


// ============================================================================
// PCS Receiver: Clause 49/82 Decoder with Configurable Descrambler
// ============================================================================
module pcs_rx (
    input  logic        clk,
    input  logic        rst_n,
    input  logic        enable_scrambler,
    input  logic [1:0]  hdr,
    input  logic [63:0] payload,
    output logic [63:0] cgmii_rxd,
    output logic [7:0]  cgmii_rxc
);

    logic [57:0] descram_state;
    logic [63:0] descram_payload;
    logic [7:0]  block_type;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            descram_state <= 58'h3FF_FFFF_FFFF_FFFF;
        end else if (enable_scrambler) begin
            descram_state <= payload[63:6];
        end
    end

    // Direct combinational descrambler (Latch-Free)
    always_comb begin
        if (enable_scrambler) begin
            for (int i = 0; i < 64; i++) begin
                descram_payload[i] = payload[i] ^
                                     ((i < 39) ? descram_state[19 + i] : payload[i - 39]) ^
                                     ((i < 58) ? descram_state[i]      : payload[i - 58]);
            end
        end else begin
            descram_payload = payload;
        end
    end

    assign block_type = descram_payload[7:0];

    // PCS Block Decoder
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cgmii_rxd <= 64'h0707070707070707;
            cgmii_rxc <= 8'hFF;
        end else begin
            if (hdr == 2'b01) begin
                // Pure Data Block
                cgmii_rxd <= descram_payload;
                cgmii_rxc <= 8'h00;
            end else if (hdr == 2'b10) begin
                // Control / Mixed Block
                case (block_type)
                    8'h1E: begin // Idle Block
                        cgmii_rxd <= 64'h0707070707070707;
                        cgmii_rxc <= 8'hFF;
                    end
                    8'h78: begin // Start Block (/S/ in Byte 0)
                        cgmii_rxd <= {descram_payload[63:8], 8'hFB};
                        cgmii_rxc <= 8'h01;
                    end
                    8'h87: begin // Terminate Block k=0
                        cgmii_rxd <= 64'h07070707070707FD;
                        cgmii_rxc <= 8'hFF;
                    end
                    8'h99: begin // Terminate Block k=1
                        cgmii_rxd <= {48'h070707070707, 8'hFD, descram_payload[15:8]};
                        cgmii_rxc <= 8'hFE;
                    end
                    8'hAA: begin // Terminate Block k=2
                        cgmii_rxd <= {40'h0707070707, 8'hFD, descram_payload[23:8]};
                        cgmii_rxc <= 8'hFC;
                    end
                    8'hB4: begin // Terminate Block k=3
                        cgmii_rxd <= {32'h07070707, 8'hFD, descram_payload[31:8]};
                        cgmii_rxc <= 8'hF8;
                    end
                    8'hCC: begin // Terminate Block k=4
                        cgmii_rxd <= {24'h070707, 8'hFD, descram_payload[39:8]};
                        cgmii_rxc <= 8'hF0;
                    end
                    8'hD2: begin // Terminate Block k=5
                        cgmii_rxd <= {16'h0707, 8'hFD, descram_payload[47:8]};
                        cgmii_rxc <= 8'hE0;
                    end
                    8'hE1: begin // Terminate Block k=6
                        cgmii_rxd <= {8'h07, 8'hFD, descram_payload[55:8]};
                        cgmii_rxc <= 8'hC0;
                    end
                    8'hFF: begin // Terminate Block k=7
                        cgmii_rxd <= {8'hFD, descram_payload[63:8]};
                        cgmii_rxc <= 8'h80;
                    end
                    default: begin // Error Block (/E/)
                        cgmii_rxd <= 64'hFEFEFEFEFEFEFEFE;
                        cgmii_rxc <= 8'hFF;
                    end
                endcase
            end else begin
                // Invalid Sync Header
                cgmii_rxd <= 64'hFEFEFEFEFEFEFEFE;
                cgmii_rxc <= 8'hFF;
            end
        end
    end
endmodule


// ============================================================================
// MAC Transmitter Module
// ============================================================================
module mac_tx #(
    parameter bit ENABLE_DEBUG = 1'b0
) (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [63:0] host_tx_data,
    input  logic [7:0]  host_tx_keep,
    input  logic        host_tx_valid,
    input  logic        host_tx_last,
    output logic        host_tx_ready,

    output logic [63:0] cgmii_txd,
    output logic [7:0]  cgmii_txc
);

    function automatic logic [31:0] crc32_byte(input logic [31:0] crc_in, input logic [7:0] data_byte);
        logic [31:0] crc;
        crc = crc_in ^ {24'b0, data_byte};
        for (int j = 0; j < 8; j++) begin
            if (crc[0])
                crc = (crc >> 1) ^ 32'hEDB88320;
            else
                crc = crc >> 1;
        end
        return crc;
    endfunction

    function automatic int count_bytes(input logic [7:0] keep);
        int c = 0;
        for (int i = 0; i < 8; i++) if (keep[i]) c++;
        return c;
    endfunction

    typedef enum logic [1:0] {ST_IDLE, ST_INGEST, ST_START, ST_DATA} state_t;
    state_t state;

    logic [7:0] pkt_buf [0:2047];
    int         pkt_len;
    int         tx_pos;
    int         tx_frame_cnt /* verilator public_flat */;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= ST_IDLE;
            host_tx_ready <= 1'b1;
            cgmii_txd     <= 64'h0707070707070707;
            cgmii_txc     <= 8'hFF;
            pkt_len       <= 0;
            tx_pos        <= 0;
            tx_frame_cnt  <= 0;
        end else begin
            case (state)
                ST_IDLE: begin
                    cgmii_txd     <= 64'h0707070707070707;
                    cgmii_txc     <= 8'hFF;
                    host_tx_ready <= 1'b1;

                    if (host_tx_valid && host_tx_ready) begin
                        int b_cnt;
                        b_cnt = count_bytes(host_tx_keep);
                        /* verilator lint_off BLKSEQ */
                        for (int i = 0; i < 8; i++) begin
                            if (host_tx_keep[i]) pkt_buf[i] = host_tx_data[i*8 +: 8];
                        end
                        /* verilator lint_on BLKSEQ */
                        pkt_len <= b_cnt;

                        if (host_tx_last) begin
                            host_tx_ready <= 1'b0;
                            state         <= ST_START;
                        end else begin
                            state         <= ST_INGEST;
                        end
                    end
                end

                ST_INGEST: begin
                    host_tx_ready <= 1'b1;
                    if (host_tx_valid && host_tx_ready) begin
                        int b_cnt;
                        b_cnt = count_bytes(host_tx_keep);
                        /* verilator lint_off BLKSEQ */
                        for (int i = 0; i < 8; i++) begin
                            if (host_tx_keep[i]) pkt_buf[pkt_len + i] = host_tx_data[i*8 +: 8];
                        end
                        /* verilator lint_on BLKSEQ */
                        pkt_len <= pkt_len + b_cnt;

                        if (host_tx_last) begin
                            host_tx_ready <= 1'b0;
                            state         <= ST_START;
                        end
                    end
                end

                ST_START: begin
                    logic [31:0] crc_calc;
                    int final_len;
                    host_tx_ready <= 1'b0;

                    final_len = pkt_len;
                    if (final_len < 60) begin
                        /* verilator lint_off BLKSEQ */
                        for (int k = final_len; k < 60; k++) begin
                            pkt_buf[k] = 8'h00;
                        end
                        /* verilator lint_on BLKSEQ */
                        final_len = 60;
                    end

                    crc_calc = 32'hFFFFFFFF;
                    for (int i = 0; i < final_len; i++) begin
                        crc_calc = crc32_byte(crc_calc, pkt_buf[i]);
                    end
                    crc_calc = ~crc_calc;

                    pkt_buf[final_len]     <= crc_calc[7:0];
                    pkt_buf[final_len + 1] <= crc_calc[15:8];
                    pkt_buf[final_len + 2] <= crc_calc[23:16];
                    pkt_buf[final_len + 3] <= crc_calc[31:24];

                    pkt_len <= final_len + 4;

                    cgmii_txd    <= 64'hD5555555555555FB;
                    cgmii_txc    <= 8'h01;
                    tx_pos       <= 0;
                    tx_frame_cnt <= tx_frame_cnt + 1;

                    if (ENABLE_DEBUG) begin
                        $display("[MAC_TX DEBUG] [%0t ps] Transmitting Frame #%0d", $time, tx_frame_cnt + 1);
                    end

                    state <= ST_DATA;
                end

                ST_DATA: begin
                    int rem_len;
                    
                    logic [63:0] d_temp;
                    logic [7:0]  c_temp;

                    rem_len = pkt_len - tx_pos;
                    host_tx_ready <= 1'b0;

                    if (rem_len >= 8) begin
                        for (int b = 0; b < 8; b++) d_temp[b*8 +: 8] = pkt_buf[tx_pos + b];
                        c_temp    = 8'h00;
                        tx_pos    <= tx_pos + 8;
                        cgmii_txd <= d_temp;
                        cgmii_txc <= c_temp;
                    end else if (rem_len == 0) begin
                        cgmii_txd <= 64'h07070707070707FD;
                        cgmii_txc <= 8'hFF;
                        state     <= ST_IDLE;
                    end else begin
                        d_temp = 64'h0707070707070707;
                        c_temp = 8'h00;
                        for (int b = 0; b < 8; b++) begin
                            if (b < rem_len) begin
                                d_temp[b*8 +: 8] = pkt_buf[tx_pos + b];
                            end else if (b == rem_len) begin
                                d_temp[b*8 +: 8] = 8'hFD;
                                c_temp[b]        = 1'b1;
                            end else begin
                                d_temp[b*8 +: 8] = 8'h07;
                                c_temp[b]        = 1'b1;
                            end
                        end
                        cgmii_txd <= d_temp;
                        cgmii_txc <= c_temp;
                        state     <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule


// ============================================================================
// MAC Receiver Module
// ============================================================================
module mac_rx #(
    parameter bit ENABLE_DEBUG = 1'b0
) (
    input  logic        clk,
    input  logic        rst_n,

    input  logic [63:0] cgmii_rxd,
    input  logic [7:0]  cgmii_rxc,

    output logic [63:0] host_rx_data,
    output logic [7:0]  host_rx_keep,
    output logic        host_rx_valid,
    output logic        host_rx_last
);

    function automatic logic [31:0] crc32_byte(input logic [31:0] crc_in, input logic [7:0] data_byte);
        logic [31:0] crc;
        crc = crc_in ^ {24'b0, data_byte};
        for (int j = 0; j < 8; j++) begin
            if (crc[0])
                crc = (crc >> 1) ^ 32'hEDB88320;
            else
                crc = crc >> 1;
        end
        return crc;
    endfunction

    typedef enum logic [1:0] {ST_IDLE, ST_COLLECT, ST_OUTPUT} state_t;
    state_t state;

    logic [7:0] rx_buf [0:2047];
    int         rx_len;
    int         out_pos;
    int         rx_frame_cnt  /* verilator public_flat */;
    int         crc_error_cnt /* verilator public_flat */;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= ST_IDLE;
            host_rx_data  <= '0;
            host_rx_keep  <= '0;
            host_rx_valid <= 1'b0;
            host_rx_last  <= 1'b0;
            rx_len        <= 0;
            out_pos       <= 0;
            rx_frame_cnt  <= 0;
            crc_error_cnt <= 0;
        end else begin
            case (state)
                ST_IDLE: begin
                    host_rx_valid <= 1'b0;
                    host_rx_last  <= 1'b0;
                    if (cgmii_rxc[0] && (cgmii_rxd[7:0] == 8'hFB)) begin
                        rx_len <= 0;
                        state  <= ST_COLLECT;
                    end
                end

                ST_COLLECT: begin
                    if (cgmii_rxc == 8'h00) begin
                        /* verilator lint_off BLKSEQ */
                        for (int b = 0; b < 8; b++) begin
                            rx_buf[rx_len + b] = cgmii_rxd[b*8 +: 8];
                        end
                        /* verilator lint_on BLKSEQ */
                        rx_len <= rx_len + 8;
                    end else begin
                        int          valid_bytes;
                        
                        int          total_rx;
                        logic [31:0] calc_crc;
                        logic [31:0] rx_crc;
                        logic [7:0]  full_pkt [0:2047];

                        valid_bytes = 0;
                        for (int k = 0; k < rx_len; k++) full_pkt[k] = rx_buf[k];

                        /* verilator lint_off BLKSEQ */
                        for (int b = 0; b < 8; b++) begin
                            if (cgmii_rxc[b] == 1'b0) begin
                                full_pkt[rx_len + b] = cgmii_rxd[b*8 +: 8];
                                rx_buf[rx_len + b]   = cgmii_rxd[b*8 +: 8];
                                valid_bytes++;
                            end else begin
                                break;
                            end
                        end
                        /* verilator lint_on BLKSEQ */

                        total_rx = rx_len + valid_bytes;

                        if (total_rx >= 64) begin
                            calc_crc = 32'hFFFFFFFF;
                            for (int i = 0; i < total_rx - 4; i++) begin
                                calc_crc = crc32_byte(calc_crc, full_pkt[i]);
                            end
                            calc_crc = ~calc_crc;

                            rx_crc = {full_pkt[total_rx-1], full_pkt[total_rx-2], full_pkt[total_rx-3], full_pkt[total_rx-4]};

                            if (calc_crc == rx_crc) begin
                                rx_len       <= total_rx - 4;
                                out_pos      <= 0;
                                rx_frame_cnt <= rx_frame_cnt + 1;

                                if (ENABLE_DEBUG) begin
                                    $display("[MAC_RX DEBUG] [%0t ps] Received Valid Frame #%0d", $time, rx_frame_cnt + 1);
                                end

                                state <= ST_OUTPUT;
                            end else begin
                                crc_error_cnt <= crc_error_cnt + 1;

                                if (ENABLE_DEBUG) begin
                                    $display("[MAC_RX DEBUG] [%0t ps] CRC Error Detected! Calc: 0x%08h, Rx: 0x%08h",
                                             $time, calc_crc, rx_crc);
                                end

                                state <= ST_IDLE;
                            end
                        end else begin
                            state <= ST_IDLE;
                        end
                    end
                end

                ST_OUTPUT: begin
                    int rem_rx;
                    logic [63:0] d_rx_temp;
                    logic [7:0]  k_rx_temp;
                    rem_rx = rx_len - out_pos;

                    if (rem_rx > 8) begin
                        
                        d_rx_temp = '0;
                        
                        k_rx_temp = 8'hFF;
                        for (int b = 0; b < 8; b++) d_rx_temp[b*8 +: 8] = rx_buf[out_pos + b];
                        host_rx_data  <= d_rx_temp;
                        host_rx_keep  <= k_rx_temp;
                        host_rx_valid <= 1'b1;
                        host_rx_last  <= 1'b0;
                        out_pos       <= out_pos + 8;
                    end else if (rem_rx > 0) begin
                        
                        d_rx_temp = '0;
                        
                        k_rx_temp = '0;
                        for (int b = 0; b < rem_rx; b++) begin
                            d_rx_temp[b*8 +: 8] = rx_buf[out_pos + b];
                            k_rx_temp[b]        = 1'b1;
                        end
                        host_rx_data  <= d_rx_temp;
                        host_rx_keep  <= k_rx_temp;
                        host_rx_valid <= 1'b1;
                        host_rx_last  <= 1'b1;
                        out_pos       <= rx_len;
                        state         <= ST_IDLE;
                    end else begin
                        host_rx_valid <= 1'b0;
                        host_rx_last  <= 1'b0;
                        state         <= ST_IDLE;
                    end
                end

                default: state <= ST_IDLE;
            endcase
        end
    end
endmodule
