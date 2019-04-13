//
// Copyright (c) 2017, Intel Corporation
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are met:
//
// Redistributions of source code must retain the above copyright notice, this
// list of conditions and the following disclaimer.
//
// Redistributions in binary form must reproduce the above copyright notice,
// this list of conditions and the following disclaimer in the documentation
// and/or other materials provided with the distribution.
//
// Neither the name of the Intel Corporation nor the names of its contributors
// may be used to endorse or promote products derived from this software
// without specific prior written permission.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
// AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
// IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
// ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
// LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
// CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
// SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
// INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
// CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
// POSSIBILITY OF SUCH DAMAGE.

// Include MPF data types, including the CCI interface pacakge.
`include "cci_mpf_if.vh"

import ccip_if_pkg::*;
import sobel_pkg::*;
`ifdef WITH_MUX
        `define TOP_IFC_NAME `AFU_WITHMUX_NAME
`else
        `define TOP_IFC_NAME `AFU_NOMUX_NAME
`endif
module `TOP_IFC_NAME
(
  // CCI-P Clocks and Resets
  input  logic         pClk,               // 400MHz - CCI-P clock domain. Primary interface clock
  input  logic         pClkDiv2,           // 200MHz - CCI-P clock domain.
  input  logic         pClkDiv4,           // 100MHz - CCI-P clock domain.
  input  logic         uClk_usr,           // User clock domain. Refer to clock programming guide  ** Currently provides fixed 300MHz clock **
  input  logic         uClk_usrDiv2,       // User clock domain. Half the programmed frequency  ** Currently provides fixed 150MHz clock **
  input  logic         pck_cp2af_softReset,// CCI-P ACTIVE HIGH Soft Reset
  input  logic [1:0]   pck_cp2af_pwrState, // CCI-P AFU Power State
  input  logic         pck_cp2af_error,    // CCI-P Protocol Error Detected

  // Interface structures
  input  t_if_ccip_Rx  pck_cp2af_sRx,      // CCI-P Rx Port
  output t_if_ccip_Tx  pck_af2cp_sTx       // CCI-P Tx Port
);

    logic async_softreset;
    t_if_ccip_Tx async_tx;
    t_if_ccip_Tx async_rx;

    ccip_async_shim async_shim(
        .bb_softreset(pck_cp2af_softReset),
        .bb_clk(pClk),
        .bb_tx(pck_af2cp_sTx),
        .bb_rx(pck_cp2af_sRx),
        .afu_softreset(async_softreset),
        .afu_clk(pClkDiv2),
        .afu_tx(async_tx),
        .afu_rx(async_rx)
        );

    sobel_top_async sobel_top_async(
        .pClk(pClkDiv2),
        .pClkDiv2(pClkDiv4),
        .pClkDiv4(pClkDiv4),
        .pck_cp2af_softReset(async_softreset),
        .pck_cp2af_pwrState(pck_cp2af_pwrState),
        .pck_cp2af_error(pck_cp2af_error),
        .pck_cp2af_sRx(async_rx),
        .pck_af2cp_sTx(async_tx)
        );

endmodule : `TOP_IFC_NAME
