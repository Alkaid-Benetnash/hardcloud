// gaussian_csr.sv

import ccip_if_pkg::*;
import gaussian_pkg::*;

module gaussian_csr
(
  input  logic           clk,
  input  logic           reset,
  output t_hc_control    hc_control,
  output t_hc_address    hc_dsm_base,
  output t_hc_buffer     hc_buffer[HC_BUFFER_SIZE],
  cci_mpf_if.to_fiu      fiu,
  cci_mpf_if.to_afu      afu,

  input t_rd_state rd_state,
  input t_wr_state wr_state
);

  // register map to HardCloud
  localparam HC_DEVICE_HEADER    = 16'h000; // 64b - RO  Constant: 0x1000010000000000.
  localparam HC_AFU_ID_LOW       = 16'h008; // 64b - RO  Constant: 0xC000C9660D824272.
  localparam HC_AFU_ID_HIGH      = 16'h010; // 64b - RO  Constant: 0x9AEFFE5F84570612.
  localparam HC_AFU_CNT_C0TX     = 16'h030;
  localparam HC_AFU_CNT_C1TX     = 16'h038;
  localparam HC_AFU_RD_STATE     = 16'h040;
  localparam HC_AFU_WR_STATE     = 16'h048;

  t_if_ccip_c0_Rx rx_mmio_channel;
  t_if_ccip_c2_Tx tx_mmio_channel;

  t_ccip_c0_ReqMmioHdr mmio_req_hdr;

  logic is_csr_read;

  logic [127:0] afu_id = 128'hC000C966_0D82_4272_9AEF_FE5F84570612;

  assign afu.reset = fiu.reset;

  assign fiu.c0Tx = afu.c0Tx;
  assign afu.c0TxAlmFull = fiu.c0TxAlmFull;
  assign fiu.c1Tx = afu.c1Tx;
  assign afu.c1TxAlmFull = fiu.c1TxAlmFull;

  assign afu.c0Rx = fiu.c0Rx;
  assign afu.c1Rx = fiu.c1Rx;

  assign is_csr_read = rx_mmio_channel.mmioRdValid & (mmio_req_hdr.address < 'h100);

  assign mmio_req_hdr = t_ccip_c0_ReqMmioHdr'(rx_mmio_channel.hdr);

    logic [63:0] c0tx_cnt, c1tx_cnt;
    logic fiu_c0tx_valid_q, fiu_c1tx_valid_q;
    always_ff @(posedge clk) begin
        fiu_c0tx_valid_q <= fiu.c0Tx.valid;
        fiu_c1tx_valid_q <= fiu.c1Tx.valid;
        if (reset) begin
            c0tx_cnt <= 0;
            c1tx_cnt <= 0;
        end
        else begin
            c0tx_cnt <= c0tx_cnt + fiu_c0tx_valid_q;
            c1tx_cnt <= c1tx_cnt + fiu_c1tx_valid_q;
        end
    end


  // Register incoming messages
  always_ff @(posedge clk)
  begin
      rx_mmio_channel <= fiu.c0Rx;
  end

  // CSR reads
  always_ff @(posedge clk) begin
      fiu.c2Tx <= afu.c2Tx;

      if (tx_mmio_channel.mmioRdValid) begin
          fiu.c2Tx <= tx_mmio_channel;
      end
  end

  //
  // Implement the device feature list by responding to MMIO reads.
  //

  always_ff @(posedge clk) begin
    if (reset) begin
      tx_mmio_channel.mmioRdValid <= 1'b0;
    end
    else begin
      tx_mmio_channel.mmioRdValid <= is_csr_read;
      tx_mmio_channel.hdr.tid     <= mmio_req_hdr.tid;

      case (mmio_req_hdr.address)
        // AFU DFH (device feature header)
        HC_DEVICE_HEADER: tx_mmio_channel.data <= 'h1000000004000000;

        // AFU_ID_L
        (HC_AFU_ID_LOW >> 2): tx_mmio_channel.data <= afu_id[63:0];

        // AFU_ID_H
        (HC_AFU_ID_HIGH >> 2): tx_mmio_channel.data <= afu_id[127:64];

        // DFH_RSVD0
        6: tx_mmio_channel.data <= t_ccip_mmioData'(0);

        // DFH_RSVD1
        8: tx_mmio_channel.data <= t_ccip_mmioData'(0);

        (HC_AFU_CNT_C0TX >> 2): tx_mmio_channel.data <= c0tx_cnt;
        (HC_AFU_CNT_C1TX >> 2): tx_mmio_channel.data <= c1tx_cnt;
        (HC_AFU_RD_STATE >> 2): tx_mmio_channel.data <= rd_state;
        (HC_AFU_WR_STATE >> 2): tx_mmio_channel.data <= wr_state;

        default: tx_mmio_channel.data <= t_ccip_mmioData'('0);
      endcase
    end
  end

  //
  // CSR write handling.  Host software must tell the AFU the memory address
  // to which it should be writing.  The address is set by writing a CSR.
  //

  always_ff @(posedge clk) begin
    if (reset) begin
      hc_dsm_base <= '0;
    end
    else if (hc_dsm_sel(rx_mmio_channel)) begin
      hc_dsm_base <= t_hc_address'(rx_mmio_channel.data) >> 6;
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      hc_control <= '0;
    end
    else if (hc_control_sel(rx_mmio_channel)) begin
      hc_control <= t_hc_control'(rx_mmio_channel.data[31:0]);
    end
  end

  always_ff @(posedge clk) begin
    if (reset) begin
      for (int i = 0; i < HC_BUFFER_SIZE; i++) begin
        hc_buffer[i] <= '0;
      end
    end
    else begin
      logic [1:0] sel;

      sel = hc_buffer_sel(rx_mmio_channel);

      if (sel == 2'b01) begin
        hc_buffer[hc_buffer_which(rx_mmio_channel)].address <=
          t_hc_address'(rx_mmio_channel.data) >> 6;
      end
      else if (sel == 2'b11) begin
        hc_buffer[hc_buffer_which(rx_mmio_channel)].size <=
          rx_mmio_channel.data[31:0];
      end
    end
  end

endmodule : gaussian_csr

