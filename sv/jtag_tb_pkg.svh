//=============================================================================
// File: jtag_tb_pkg.svh
// Description: Enhanced JTAG VIP Testbench Package
// Author: Enhanced JTAG VIP Team
// Date: 2024
// Version: 2.0
//=============================================================================

`ifndef JTAG_TB_PKG_SVH
`define JTAG_TB_PKG_SVH

package jtag_tb_pkg;
  
  // Import UVM package
  import uvm_pkg::*;
  `include "uvm_macros.svh"
  
  // Virtual interface typedef
  typedef virtual jtag_if jtag_vif;
  
  // Include all VIP components
  `include "jtag_vip.svh"
  
endpackage : jtag_tb_pkg

`endif // JTAG_TB_PKG_SVH
