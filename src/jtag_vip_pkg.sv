//=============================================================================
// File: jtag_vip_pkg.sv
// Description: Enhanced JTAG VIP Package - Complete SystemVerilog Package
// Author: Enhanced JTAG VIP Team
// Date: 2024
// Version: 2.0
//=============================================================================

package jtag_vip_pkg;

  // Import UVM package
  import uvm_pkg::*;
  `include "uvm_macros.svh"

  //===========================================================================
  // JTAG VIP Parameters and Types
  //===========================================================================
  
  // JTAG VIP version information
  parameter string JTAG_VIP_VERSION = "2.0";
  parameter string JTAG_VIP_BUILD_DATE = "2024-01-20";
  
  // JTAG Protocol Constants
  parameter int JTAG_IR_WIDTH_MIN = 2;
  parameter int JTAG_IR_WIDTH_MAX = 32;
  parameter int JTAG_DR_WIDTH_MIN = 1;
  parameter int JTAG_DR_WIDTH_MAX = 1024;
  parameter int JTAG_MAX_DEVICES = 32;
  
  // Timing Constants (in ns)
  parameter real JTAG_TCK_PERIOD_MIN = 10.0;   // 100MHz max
  parameter real JTAG_TCK_PERIOD_MAX = 1000.0; // 1MHz min
  parameter real JTAG_SETUP_TIME_MIN = 1.0;
  parameter real JTAG_HOLD_TIME_MIN = 1.0;
  
  // IEEE Standard Compliance
  typedef enum {
    IEEE_1149_1_2001,
    IEEE_1149_1_2013,
    IEEE_1149_4_2010,
    IEEE_1149_6_2003,
    IEEE_1149_7_2009
  } jtag_ieee_standard_e;
  
  // Note: Core type definitions are included from jtag_defs.svh
  // Additional package-specific types can be defined here if needed
  
  // Performance Metrics
  typedef struct {
    real throughput_mbps;
    real latency_ns;
    real jitter_ns;
    real bandwidth_utilization;
    int  transaction_count;
    real error_rate;
  } jtag_performance_metrics_s;
  
  //===========================================================================
  // Core Definitions and Interfaces
  //===========================================================================
  
  `include "../sv/jtag_defs.svh"
  `include "../sv/jtag_if.svh"
  `include "../sv/jtag_if_proxy.svh"
  
  //===========================================================================
  // Configuration Classes
  //===========================================================================
  
  `include "../sv/jtag_config.svh"
  
  //===========================================================================
  // Transaction and Sequence Items
  //===========================================================================
  
  `include "../sv/jtag_sequence_item.svh"
  
  //===========================================================================
  // Sequence Library
  //===========================================================================
  
  `include "../sv/jtag_sequence_lib.svh"
  
  //===========================================================================
  // Core VIP Components
  //===========================================================================
  
  `include "../sv/jtag_driver.svh"
  `include "../sv/jtag_monitor.svh"
  `include "../sv/jtag_collector.svh"
  `include "../sv/jtag_sequencer.svh"
  
  //===========================================================================
  // Enhanced Analysis Components
  //===========================================================================
  
  `include "../sv/jtag_protocol_checker.svh"
  `include "../sv/jtag_timing_validator.svh"
  `include "../sv/jtag_coverage_collector.svh"
  `include "../sv/jtag_performance_monitor.svh"
  
  //===========================================================================
  // Advanced Verification Components
  //===========================================================================
  
  `include "../sv/jtag_scoreboard.svh"
  `include "../sv/jtag_error_injector.svh"
  `include "../sv/jtag_debug_dashboard.svh"
  `include "../sv/jtag_virtual_sequencer.svh"
  
  //===========================================================================
  // Agent and Environment
  //===========================================================================
  
  `include "../sv/jtag_agent.svh"
  `include "../sv/jtag_env.svh"
  
  //===========================================================================
  // Test Library
  //===========================================================================
  
  `include "../sv/jtag_test_lib.svh"
  
  //===========================================================================
  // Utility Functions and Macros
  //===========================================================================
  
  // JTAG State Machine Utilities with Enhanced Error Handling
  function automatic jtag_tap_state_e get_next_state(jtag_tap_state_e current_state, bit tms);
    case (current_state)
      TEST_LOGIC_RESET: return tms ? TEST_LOGIC_RESET : RUN_TEST_IDLE;
      RUN_TEST_IDLE:    return tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
      SELECT_DR_SCAN:   return tms ? SELECT_IR_SCAN : CAPTURE_DR;
      CAPTURE_DR:       return tms ? EXIT1_DR : SHIFT_DR;
      SHIFT_DR:         return tms ? EXIT1_DR : SHIFT_DR;
      EXIT1_DR:         return tms ? UPDATE_DR : PAUSE_DR;
      PAUSE_DR:         return tms ? EXIT2_DR : PAUSE_DR;
      EXIT2_DR:         return tms ? UPDATE_DR : SHIFT_DR;
      UPDATE_DR:        return tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
      SELECT_IR_SCAN:   return tms ? TEST_LOGIC_RESET : CAPTURE_IR;
      CAPTURE_IR:       return tms ? EXIT1_IR : SHIFT_IR;
      SHIFT_IR:         return tms ? EXIT1_IR : SHIFT_IR;
      EXIT1_IR:         return tms ? UPDATE_IR : PAUSE_IR;
      PAUSE_IR:         return tms ? EXIT2_IR : PAUSE_IR;
      EXIT2_IR:         return tms ? UPDATE_IR : SHIFT_IR;
      UPDATE_IR:        return tms ? SELECT_DR_SCAN : RUN_TEST_IDLE;
      default: begin
        `JTAG_ERROR($sformatf("Invalid TAP state encountered: %s", current_state.name()))
        return TEST_LOGIC_RESET;
      end
    endcase
  endfunction
  
  // JTAG Instruction Validation
  function automatic bit is_valid_instruction(bit [31:0] instruction, int ir_width);
    if (ir_width <= 0 || ir_width > 32) return 0;
    bit [31:0] mask = (1 << ir_width) - 1;
    return (instruction & ~mask) == 0;
  endfunction
  
  // JTAG Data Validation
  function automatic bit is_valid_data_length(int length);
    return (length >= JTAG_DR_WIDTH_MIN && length <= JTAG_DR_WIDTH_MAX);
  endfunction
  
  // Timing Validation
  function automatic bit is_valid_timing(real setup_time, real hold_time, real clock_period);
    return (setup_time >= JTAG_SETUP_TIME_MIN && 
            hold_time >= JTAG_HOLD_TIME_MIN && 
            clock_period >= JTAG_TCK_PERIOD_MIN && 
            clock_period <= JTAG_TCK_PERIOD_MAX);
  endfunction
  
  // CRC Calculation for Data Integrity
  function automatic bit [31:0] calculate_crc32(bit data[], int length);
    bit [31:0] crc = 32'hFFFFFFFF;
    bit [31:0] polynomial = 32'h04C11DB7;
    
    for (int i = 0; i < length; i++) begin
      crc = crc ^ (data[i] << 31);
      for (int j = 0; j < 8; j++) begin
        if (crc[31]) crc = (crc << 1) ^ polynomial;
        else crc = crc << 1;
      end
    end
    return ~crc;
  endfunction
  
  // Performance Calculation Utilities
  function automatic real calculate_throughput(int bits_transferred, real time_elapsed_ns);
    if (time_elapsed_ns <= 0) return 0.0;
    return (bits_transferred * 1000.0) / time_elapsed_ns; // Mbps
  endfunction
  
  function automatic real calculate_bandwidth_utilization(real actual_throughput, real max_throughput);
    if (max_throughput <= 0) return 0.0;
    return (actual_throughput / max_throughput) * 100.0; // Percentage
  endfunction
  
  //===========================================================================
  // Debug and Reporting Macros
  //===========================================================================
  
  `define JTAG_INFO(msg) \
    `uvm_info("JTAG_VIP", msg, UVM_MEDIUM)
  
  `define JTAG_WARNING(msg) \
    `uvm_warning("JTAG_VIP", msg)
  
  `define JTAG_ERROR(msg) \
    `uvm_error("JTAG_VIP", msg)
  
  `define JTAG_FATAL(msg) \
    `uvm_fatal("JTAG_VIP", msg)
  
  `define JTAG_DEBUG(msg) \
    `uvm_info("JTAG_VIP_DEBUG", msg, UVM_HIGH)
  
  `define JTAG_PROTOCOL_CHECK(condition, msg) \
    if (!(condition)) begin \
      `uvm_error("JTAG_PROTOCOL", msg) \
    end
  
  `define JTAG_TIMING_CHECK(condition, msg) \
    if (!(condition)) begin \
      `uvm_error("JTAG_TIMING", msg) \
    end
  
  `define JTAG_PERFORMANCE_LOG(metric, value) \
    `uvm_info("JTAG_PERFORMANCE", $sformatf("%s: %0.2f", metric, value), UVM_LOW)
  
  //===========================================================================
  // Package Initialization
  //===========================================================================
  
  // Package initialization function
  function automatic void jtag_vip_init();
    `JTAG_INFO($sformatf("JTAG VIP Version %s initialized (Build: %s)", 
                         JTAG_VIP_VERSION, JTAG_VIP_BUILD_DATE))
  endfunction
  
  // Package information function
  function automatic void jtag_vip_info();
    `JTAG_INFO("=== Enhanced JTAG VIP Information ===")
    `JTAG_INFO($sformatf("Version: %s", JTAG_VIP_VERSION))
    `JTAG_INFO($sformatf("Build Date: %s", JTAG_VIP_BUILD_DATE))
    `JTAG_INFO("Features: Protocol Compliance, Timing Validation, Coverage, Performance Monitoring")
    `JTAG_INFO("Standards: IEEE 1149.1/1149.4/1149.6/1149.7")
    `JTAG_INFO("Components: Driver, Monitor, Checker, Validator, Scoreboard, Dashboard")
    `JTAG_INFO("========================================")
  endfunction

endpackage : jtag_vip_pkg