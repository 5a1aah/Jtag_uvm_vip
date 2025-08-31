//=============================================================================
// File: integration_test.sv
// Description: Comprehensive Integration Test for Enhanced JTAG VIP
// Author: Enhanced JTAG VIP Team
// Date: 2024
// Version: 2.0
//=============================================================================

`include "uvm_macros.svh"
import uvm_pkg::*;
import jtag_vip_pkg::*;

//=============================================================================
// Integration Test Class
//=============================================================================

class integration_test extends uvm_test;
  `uvm_component_utils(integration_test)
  
  // Environment and configuration
  jtag_env env;
  jtag_env_config env_cfg;
  jtag_agent_config agent_cfg;
  
  // Test sequences
  jtag_reset_sequence reset_seq;
  jtag_ir_scan_sequence ir_seq;
  jtag_dr_scan_sequence dr_seq;
  jtag_boundary_scan_sequence boundary_seq;
  jtag_debug_sequence debug_seq;
  jtag_error_injection_sequence error_seq;
  jtag_compliance_sequence compliance_seq;
  
  function new(string name = "integration_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    `uvm_info("INTEGRATION_TEST", "Building comprehensive integration test", UVM_LOW)
    
    // Create environment configuration
    env_cfg = jtag_env_config::type_id::create("env_cfg");
    
    // Create agent configuration
    agent_cfg = jtag_agent_config::type_id::create("agent_cfg");
    
    // Configure comprehensive testing
    agent_cfg.enable_protocol_checking = 1;
    agent_cfg.enable_timing_validation = 1;
    agent_cfg.enable_coverage_collection = 1;
    agent_cfg.enable_performance_monitoring = 1;
    agent_cfg.enable_error_injection = 1;
    agent_cfg.enable_debug_features = 1;
    
    // Configure protocol compliance
    agent_cfg.protocol_standard = IEEE_1149_1;
    agent_cfg.compliance_level = STRICT_COMPLIANCE;
    
    // Configure timing parameters
    agent_cfg.tck_period = 100.0; // 10MHz
    agent_cfg.setup_time = 10.0;
    agent_cfg.hold_time = 10.0;
    
    // Configure coverage
    agent_cfg.coverage_enable_instruction = 1;
    agent_cfg.coverage_enable_state = 1;
    agent_cfg.coverage_enable_boundary_scan = 1;
    agent_cfg.coverage_enable_debug = 1;
    agent_cfg.coverage_enable_error = 1;
    agent_cfg.coverage_enable_performance = 1;
    
    // Configure error injection
    agent_cfg.error_injection_mode = SYSTEMATIC;
    agent_cfg.error_injection_rate = 5; // 5% error rate
    
    // Set configurations
    env_cfg.agent_cfg = agent_cfg;
    uvm_config_db#(jtag_env_config)::set(this, "*", "env_cfg", env_cfg);
    uvm_config_db#(jtag_agent_config)::set(this, "*", "agent_cfg", agent_cfg);
    
    // Create environment
    env = jtag_env::type_id::create("env", this);
    
    `uvm_info("INTEGRATION_TEST", "Integration test build phase completed", UVM_LOW)
  endfunction
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    `uvm_info("INTEGRATION_TEST", "Integration test connect phase", UVM_LOW)
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    phase.raise_objection(this, "Starting comprehensive integration test");
    
    `uvm_info("INTEGRATION_TEST", "=== Starting Comprehensive JTAG VIP Integration Test ===", UVM_LOW)
    
    // Test 1: Basic functionality
    `uvm_info("INTEGRATION_TEST", "--- Test 1: Basic Functionality ---", UVM_LOW)
    test_basic_functionality();
    
    // Test 2: Protocol compliance
    `uvm_info("INTEGRATION_TEST", "--- Test 2: Protocol Compliance ---", UVM_LOW)
    test_protocol_compliance();
    
    // Test 3: Boundary scan operations
    `uvm_info("INTEGRATION_TEST", "--- Test 3: Boundary Scan Operations ---", UVM_LOW)
    test_boundary_scan();
    
    // Test 4: Debug access
    `uvm_info("INTEGRATION_TEST", "--- Test 4: Debug Access ---", UVM_LOW)
    test_debug_access();
    
    // Test 5: Error injection and recovery
    `uvm_info("INTEGRATION_TEST", "--- Test 5: Error Injection and Recovery ---", UVM_LOW)
    test_error_injection();
    
    // Test 6: Performance validation
    `uvm_info("INTEGRATION_TEST", "--- Test 6: Performance Validation ---", UVM_LOW)
    test_performance();
    
    // Test 7: Stress testing
    `uvm_info("INTEGRATION_TEST", "--- Test 7: Stress Testing ---", UVM_LOW)
    test_stress_scenarios();
    
    // Wait for all transactions to complete
    #1000;
    
    `uvm_info("INTEGRATION_TEST", "=== Integration Test Completed ===", UVM_LOW)
    
    phase.drop_objection(this, "Comprehensive integration test completed");
  endtask
  
  virtual task test_basic_functionality();
    // Reset sequence
    reset_seq = jtag_reset_sequence::type_id::create("reset_seq");
    reset_seq.start(env.agent.sequencer);
    
    // IDCODE read
    ir_seq = jtag_ir_scan_sequence::type_id::create("ir_seq");
    ir_seq.instruction = IDCODE;
    ir_seq.start(env.agent.sequencer);
    
    dr_seq = jtag_dr_scan_sequence::type_id::create("dr_seq");
    dr_seq.data_length = 32;
    dr_seq.start(env.agent.sequencer);
    
    // BYPASS test
    ir_seq = jtag_ir_scan_sequence::type_id::create("ir_seq");
    ir_seq.instruction = BYPASS;
    ir_seq.start(env.agent.sequencer);
    
    dr_seq = jtag_dr_scan_sequence::type_id::create("dr_seq");
    dr_seq.data_length = 1;
    dr_seq.data_in = 1'b1;
    dr_seq.start(env.agent.sequencer);
    
    `uvm_info("INTEGRATION_TEST", "Basic functionality test completed", UVM_MEDIUM)
  endtask
  
  virtual task test_protocol_compliance();
    compliance_seq = jtag_compliance_sequence::type_id::create("compliance_seq");
    compliance_seq.test_standard = IEEE_1149_1;
    compliance_seq.test_all_instructions = 1;
    compliance_seq.test_state_machine = 1;
    compliance_seq.test_timing_requirements = 1;
    compliance_seq.start(env.agent.sequencer);
    
    `uvm_info("INTEGRATION_TEST", "Protocol compliance test completed", UVM_MEDIUM)
  endtask
  
  virtual task test_boundary_scan();
    boundary_seq = jtag_boundary_scan_sequence::type_id::create("boundary_seq");
    
    // SAMPLE/PRELOAD test
    boundary_seq.instruction = SAMPLE_PREL;
    boundary_seq.test_pattern = WALKING_ONES;
    boundary_seq.boundary_length = 256;
    boundary_seq.start(env.agent.sequencer);
    
    // EXTEST
    boundary_seq.instruction = EXTEST;
    boundary_seq.test_pattern = ALTERNATING_01;
    boundary_seq.start(env.agent.sequencer);
    
    // INTEST
    boundary_seq.instruction = INTEST;
    boundary_seq.test_pattern = RANDOM_PATTERN;
    boundary_seq.start(env.agent.sequencer);
    
    `uvm_info("INTEGRATION_TEST", "Boundary scan test completed", UVM_MEDIUM)
  endtask
  
  virtual task test_debug_access();
    debug_seq = jtag_debug_sequence::type_id::create("debug_seq");
    
    // Register access
    debug_seq.access_type = DEBUG_REGISTER_READ;
    debug_seq.address = 32'h1000;
    debug_seq.start(env.agent.sequencer);
    
    debug_seq.access_type = DEBUG_REGISTER_WRITE;
    debug_seq.address = 32'h1000;
    debug_seq.data = 32'hDEADBEEF;
    debug_seq.start(env.agent.sequencer);
    
    // Memory access
    debug_seq.access_type = DEBUG_MEMORY_READ;
    debug_seq.address = 32'h2000;
    debug_seq.length = 64;
    debug_seq.start(env.agent.sequencer);
    
    `uvm_info("INTEGRATION_TEST", "Debug access test completed", UVM_MEDIUM)
  endtask
  
  virtual task test_error_injection();
    error_seq = jtag_error_injection_sequence::type_id::create("error_seq");
    
    // Test different error types
    error_seq.error_type = SINGLE_BIT_ERROR;
    error_seq.error_location = 10;
    error_seq.start(env.agent.sequencer);
    
    error_seq.error_type = TIMING_ERROR;
    error_seq.start(env.agent.sequencer);
    
    error_seq.error_type = PROTOCOL_VIOLATION;
    error_seq.start(env.agent.sequencer);
    
    `uvm_info("INTEGRATION_TEST", "Error injection test completed", UVM_MEDIUM)
  endtask
  
  virtual task test_performance();
    // High-frequency operations
    repeat(100) begin
      ir_seq = jtag_ir_scan_sequence::type_id::create("ir_seq");
      ir_seq.instruction = BYPASS;
      ir_seq.start(env.agent.sequencer);
      
      dr_seq = jtag_dr_scan_sequence::type_id::create("dr_seq");
      dr_seq.data_length = 32;
      dr_seq.start(env.agent.sequencer);
    end
    
    `uvm_info("INTEGRATION_TEST", "Performance test completed", UVM_MEDIUM)
  endtask
  
  virtual task test_stress_scenarios();
    // Rapid state transitions
    repeat(50) begin
      reset_seq = jtag_reset_sequence::type_id::create("reset_seq");
      reset_seq.start(env.agent.sequencer);
    end
    
    // Long data chains
    dr_seq = jtag_dr_scan_sequence::type_id::create("dr_seq");
    dr_seq.data_length = 1024;
    dr_seq.start(env.agent.sequencer);
    
    // Maximum instruction width
    ir_seq = jtag_ir_scan_sequence::type_id::create("ir_seq");
    ir_seq.instruction_width = 32;
    ir_seq.start(env.agent.sequencer);
    
    `uvm_info("INTEGRATION_TEST", "Stress test completed", UVM_MEDIUM)
  endtask
  
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info("INTEGRATION_TEST", "=== Integration Test Results ===", UVM_LOW)
    
    // Get results from various components
    if (env.protocol_checker != null) begin
      `uvm_info("INTEGRATION_TEST", "Protocol Checker Results:", UVM_LOW)
      env.protocol_checker.print_results();
    end
    
    if (env.timing_validator != null) begin
      `uvm_info("INTEGRATION_TEST", "Timing Validator Results:", UVM_LOW)
      env.timing_validator.print_results();
    end
    
    if (env.coverage_collector != null) begin
      `uvm_info("INTEGRATION_TEST", "Coverage Results:", UVM_LOW)
      env.coverage_collector.print_coverage();
    end
    
    if (env.performance_monitor != null) begin
      `uvm_info("INTEGRATION_TEST", "Performance Results:", UVM_LOW)
      env.performance_monitor.print_metrics();
    end
    
    if (env.error_injector != null) begin
      `uvm_info("INTEGRATION_TEST", "Error Injection Results:", UVM_LOW)
      env.error_injector.print_statistics();
    end
    
    `uvm_info("INTEGRATION_TEST", "=== Integration Test Report Complete ===", UVM_LOW)
  endfunction
  
endclass

//=============================================================================
// Integration Test Testbench
//=============================================================================

module integration_test_tb;
  
  // JTAG interface signals
  logic tck;
  logic tms;
  logic tdi;
  logic tdo;
  logic trst_n;
  
  // Clock generation
  initial begin
    tck = 0;
    forever #50 tck = ~tck; // 10MHz
  end
  
  // Reset generation
  initial begin
    trst_n = 0;
    #200;
    trst_n = 1;
  end
  
  // JTAG interface instance
  jtag_if jtag_if_inst (
    .tck(tck),
    .tms(tms),
    .tdi(tdi),
    .tdo(tdo),
    .trst_n(trst_n)
  );
  
  // Test execution
  initial begin
    // Set interface in config DB
    uvm_config_db#(virtual jtag_if)::set(null, "*", "jtag_vif", jtag_if_inst);
    
    // Enable comprehensive waveform dumping
    $dumpfile("integration_test.vcd");
    $dumpvars(0, integration_test_tb);
    
    // Run the test
    run_test("integration_test");
  end
  
  // Timeout watchdog
  initial begin
    #100ms;
    `uvm_fatal("TIMEOUT", "Integration test timeout - test did not complete in time")
  end
  
endmodule