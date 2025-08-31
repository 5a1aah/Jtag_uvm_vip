//=============================================================================
// File: jtag_vip.svh
// Description: Enhanced JTAG VIP - Main Include File
// Author: Enhanced JTAG VIP Team
// Date: 2024
// Version: 2.0
//=============================================================================

`ifndef JTAG_VIP_SVH
`define JTAG_VIP_SVH

// Core definitions and data structures
`include "jtag_defs.svh"
`include "jtag_sequence_item.svh"
`include "jtag_config.svh"

// Interface and proxy
`include "jtag_if.svh"
`include "jtag_if_proxy.svh"

// Advanced components
`include "jtag_protocol_checker.svh"
`include "jtag_timing_validator.svh"
`include "jtag_error_injector.svh"
`include "jtag_performance_monitor.svh"
`include "jtag_coverage_collector.svh"
`include "jtag_debug_dashboard.svh"

// Sequence library
`include "jtag_sequence_lib.svh"

// Core UVM components
`include "jtag_sequencer.svh"
`include "jtag_virtual_sequencer.svh"
`include "jtag_driver.svh"
`include "jtag_collector.svh"
`include "jtag_monitor.svh"
`include "jtag_scoreboard.svh"

// Agent and environment
`include "jtag_agent.svh"
`include "jtag_env.svh"

// Test library
`include "jtag_test_lib.svh"

// Package
`include "jtag_tb_pkg.svh"

`endif // JTAG_VIP_SVH
