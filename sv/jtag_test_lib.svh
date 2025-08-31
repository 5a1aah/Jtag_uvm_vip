//=============================================================================
// File: jtag_test_lib.svh
// Description: Comprehensive Test Library for Enhanced JTAG VIP
// Author: Enhanced JTAG VIP Team
// Date: 2024
// Version: 2.0
//=============================================================================

`ifndef JTAG_TEST_LIB_SVH
`define JTAG_TEST_LIB_SVH

//=============================================================================
// Base Test Class
//=============================================================================

class jtag_base_test extends uvm_test;
  `uvm_component_utils(jtag_base_test)
  
  // Environment and configuration
  jtag_env env;
  jtag_env_config env_cfg;
  jtag_agent_config agent_cfg;
  
  // Virtual interface
  virtual jtag_if vif;
  
  function new(string name = "jtag_base_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get virtual interface
    if (!uvm_config_db#(virtual jtag_if)::get(this, "", "jtag_vif", vif)) begin
      `uvm_fatal("NO_VIF", "Virtual interface must be set for test")
    end
    
    // Create configurations
    env_cfg = jtag_env_config::type_id::create("env_cfg");
    agent_cfg = jtag_agent_config::type_id::create("agent_cfg");
    
    // Configure default settings
    configure_agent();
    
    // Set configurations
    env_cfg.agent_cfg = agent_cfg;
    env_cfg.vif = vif;
    
    uvm_config_db#(jtag_env_config)::set(this, "*", "env_cfg", env_cfg);
    uvm_config_db#(jtag_agent_config)::set(this, "*", "agent_cfg", agent_cfg);
    uvm_config_db#(virtual jtag_if)::set(this, "*", "jtag_vif", vif);
    
    // Create environment
    env = jtag_env::type_id::create("env", this);
  endfunction
  
  virtual function void configure_agent();
    // Default configuration
    agent_cfg.is_active = UVM_ACTIVE;
    agent_cfg.enable_protocol_checking = 1;
    agent_cfg.enable_timing_validation = 1;
    agent_cfg.enable_coverage_collection = 1;
    agent_cfg.protocol_standard = IEEE_1149_1;
    agent_cfg.tck_period = 100.0; // 10MHz
    agent_cfg.setup_time = 10.0;
    agent_cfg.hold_time = 10.0;
  endfunction
  
  virtual function void end_of_elaboration_phase(uvm_phase phase);
    super.end_of_elaboration_phase(phase);
    uvm_top.print_topology();
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    phase.raise_objection(this, "Starting test");
    
    // Wait for reset deassertion
    wait(vif.trst_n === 1'b1);
    #100;
    
    // Execute test body
    test_body();
    
    // Wait for completion
    #1000;
    
    phase.drop_objection(this, "Test completed");
  endtask
  
  virtual task test_body();
    // Override in derived tests
    `uvm_info("BASE_TEST", "Base test body - override in derived tests", UVM_LOW)
  endtask
  
endclass

//=============================================================================
// Basic Functionality Test
//=============================================================================

class jtag_basic_test extends jtag_base_test;
  `uvm_component_utils(jtag_basic_test)
  
  jtag_reset_sequence reset_seq;
  jtag_ir_scan_sequence ir_seq;
  jtag_dr_scan_sequence dr_seq;
  
  function new(string name = "jtag_basic_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual task test_body();
    `uvm_info("BASIC_TEST", "Starting basic functionality test", UVM_LOW)
    
    // Reset sequence
    reset_seq = jtag_reset_sequence::type_id::create("reset_seq");
    reset_seq.start(env.agent.sequencer);
    
    // IDCODE test
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
    
    `uvm_info("BASIC_TEST", "Basic functionality test completed", UVM_LOW)
  endtask
  
endclass

//=============================================================================
// Boundary Scan Test
//=============================================================================

class jtag_boundary_scan_test extends jtag_base_test;
  `uvm_component_utils(jtag_boundary_scan_test)
  
  jtag_boundary_scan_sequence boundary_seq;
  
  function new(string name = "jtag_boundary_scan_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void configure_agent();
    super.configure_agent();
    agent_cfg.enable_boundary_scan = 1;
    agent_cfg.coverage_enable_boundary_scan = 1;
  endfunction
  
  virtual task test_body();
    `uvm_info("BOUNDARY_SCAN_TEST", "Starting boundary scan test", UVM_LOW)
    
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
    
    `uvm_info("BOUNDARY_SCAN_TEST", "Boundary scan test completed", UVM_LOW)
  endtask
  
endclass

//=============================================================================
// Error Injection Test
//=============================================================================

class jtag_error_injection_test extends jtag_base_test;
  `uvm_component_utils(jtag_error_injection_test)
  
  jtag_error_injection_sequence error_seq;
  
  function new(string name = "jtag_error_injection_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void configure_agent();
    super.configure_agent();
    agent_cfg.enable_error_injection = 1;
    agent_cfg.error_injection_mode = SYSTEMATIC;
    agent_cfg.error_injection_rate = 10; // 10% error rate
    agent_cfg.coverage_enable_error = 1;
  endfunction
  
  virtual task test_body();
    `uvm_info("ERROR_INJECTION_TEST", "Starting error injection test", UVM_LOW)
    
    error_seq = jtag_error_injection_sequence::type_id::create("error_seq");
    
    // Test different error types
    error_seq.error_type = SINGLE_BIT_ERROR;
    error_seq.error_location = 5;
    error_seq.start(env.agent.sequencer);
    
    error_seq.error_type = BURST_ERROR;
    error_seq.error_location = 10;
    error_seq.burst_length = 3;
    error_seq.start(env.agent.sequencer);
    
    error_seq.error_type = TIMING_ERROR;
    error_seq.start(env.agent.sequencer);
    
    error_seq.error_type = PROTOCOL_VIOLATION;
    error_seq.start(env.agent.sequencer);
    
    `uvm_info("ERROR_INJECTION_TEST", "Error injection test completed", UVM_LOW)
  endtask
  
endclass

//=============================================================================
// Compliance Test
//=============================================================================

class jtag_compliance_test extends jtag_base_test;
  `uvm_component_utils(jtag_compliance_test)
  
  jtag_compliance_sequence compliance_seq;
  jtag_ieee_standard_e test_standard;
  
  function new(string name = "jtag_compliance_test", uvm_component parent = null);
    super.new(name, parent);
    
    // Get test standard from command line
    if (!$value$plusargs("STANDARD=%s", test_standard)) begin
      test_standard = IEEE_1149_1; // Default
    end
  endfunction
  
  virtual function void configure_agent();
    super.configure_agent();
    agent_cfg.protocol_standard = test_standard;
    agent_cfg.compliance_level = STRICT_COMPLIANCE;
    agent_cfg.coverage_enable_compliance = 1;
  endfunction
  
  virtual task test_body();
    `uvm_info("COMPLIANCE_TEST", $sformatf("Starting compliance test for %s", test_standard.name()), UVM_LOW)
    
    compliance_seq = jtag_compliance_sequence::type_id::create("compliance_seq");
    compliance_seq.test_standard = test_standard;
    compliance_seq.test_all_instructions = 1;
    compliance_seq.test_state_machine = 1;
    compliance_seq.test_timing_requirements = 1;
    compliance_seq.test_boundary_scan = 1;
    compliance_seq.test_reset_behavior = 1;
    
    // Execute compliance tests based on standard
    case (test_standard)
      IEEE_1149_1: begin
        compliance_seq.test_1149_1_features = 1;
      end
      IEEE_1149_4: begin
        compliance_seq.test_1149_1_features = 1;
        compliance_seq.test_1149_4_features = 1;
      end
      IEEE_1149_6: begin
        compliance_seq.test_1149_1_features = 1;
        compliance_seq.test_1149_6_features = 1;
      end
    endcase
    
    compliance_seq.start(env.agent.sequencer);
    
    `uvm_info("COMPLIANCE_TEST", "Compliance test completed", UVM_LOW)
  endtask
  
endclass

//=============================================================================
// Performance Test
//=============================================================================

class jtag_performance_test extends jtag_base_test;
  `uvm_component_utils(jtag_performance_test)
  
  jtag_ir_scan_sequence ir_seq;
  jtag_dr_scan_sequence dr_seq;
  int num_transactions = 1000;
  
  function new(string name = "jtag_performance_test", uvm_component parent = null);
    super.new(name, parent);
    
    // Get number of transactions from command line
    if (!$value$plusargs("NUM_TRANS=%d", num_transactions)) begin
      num_transactions = 1000; // Default
    end
  endfunction
  
  virtual function void configure_agent();
    super.configure_agent();
    agent_cfg.enable_performance_monitoring = 1;
    agent_cfg.tck_period = 50.0; // 20MHz for performance test
  endfunction
  
  virtual task test_body();
    `uvm_info("PERFORMANCE_TEST", $sformatf("Starting performance test with %0d transactions", num_transactions), UVM_LOW)
    
    // High-frequency operations
    repeat(num_transactions) begin
      ir_seq = jtag_ir_scan_sequence::type_id::create("ir_seq");
      ir_seq.instruction = BYPASS;
      ir_seq.start(env.agent.sequencer);
      
      dr_seq = jtag_dr_scan_sequence::type_id::create("dr_seq");
      dr_seq.data_length = 32;
      dr_seq.start(env.agent.sequencer);
    end
    
    `uvm_info("PERFORMANCE_TEST", "Performance test completed", UVM_LOW)
  endtask
  
endclass

//=============================================================================
// Debug Access Test
//=============================================================================

class jtag_debug_test extends jtag_base_test;
  `uvm_component_utils(jtag_debug_test)
  
  jtag_debug_sequence debug_seq;
  
  function new(string name = "jtag_debug_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void configure_agent();
    super.configure_agent();
    agent_cfg.enable_debug_features = 1;
    agent_cfg.coverage_enable_debug = 1;
  endfunction
  
  virtual task test_body();
    `uvm_info("DEBUG_TEST", "Starting debug access test", UVM_LOW)
    
    debug_seq = jtag_debug_sequence::type_id::create("debug_seq");
    
    // Register access tests
    debug_seq.access_type = DEBUG_REGISTER_READ;
    debug_seq.address = 32'h1000;
    debug_seq.start(env.agent.sequencer);
    
    debug_seq.access_type = DEBUG_REGISTER_WRITE;
    debug_seq.address = 32'h1000;
    debug_seq.data = 32'hDEADBEEF;
    debug_seq.start(env.agent.sequencer);
    
    // Memory access tests
    debug_seq.access_type = DEBUG_MEMORY_READ;
    debug_seq.address = 32'h2000;
    debug_seq.length = 64;
    debug_seq.start(env.agent.sequencer);
    
    debug_seq.access_type = DEBUG_MEMORY_WRITE;
    debug_seq.address = 32'h2000;
    debug_seq.data = 32'hCAFEBABE;
    debug_seq.length = 32;
    debug_seq.start(env.agent.sequencer);
    
    // Breakpoint tests
    debug_seq.access_type = DEBUG_BREAKPOINT_SET;
    debug_seq.address = 32'h3000;
    debug_seq.start(env.agent.sequencer);
    
    debug_seq.access_type = DEBUG_BREAKPOINT_CLEAR;
    debug_seq.address = 32'h3000;
    debug_seq.start(env.agent.sequencer);
    
    `uvm_info("DEBUG_TEST", "Debug access test completed", UVM_LOW)
  endtask
  
endclass

//=============================================================================
// Stress Test
//=============================================================================

class jtag_stress_test extends jtag_base_test;
  `uvm_component_utils(jtag_stress_test)
  
  jtag_reset_sequence reset_seq;
  jtag_ir_scan_sequence ir_seq;
  jtag_dr_scan_sequence dr_seq;
  
  function new(string name = "jtag_stress_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void configure_agent();
    super.configure_agent();
    agent_cfg.enable_performance_monitoring = 1;
    agent_cfg.tck_period = 25.0; // 40MHz for stress test
  endfunction
  
  virtual task test_body();
    `uvm_info("STRESS_TEST", "Starting stress test", UVM_LOW)
    
    // Rapid reset cycles
    repeat(100) begin
      reset_seq = jtag_reset_sequence::type_id::create("reset_seq");
      reset_seq.start(env.agent.sequencer);
    end
    
    // Long data chains
    dr_seq = jtag_dr_scan_sequence::type_id::create("dr_seq");
    dr_seq.data_length = 2048; // Very long chain
    dr_seq.start(env.agent.sequencer);
    
    // Maximum instruction width
    ir_seq = jtag_ir_scan_sequence::type_id::create("ir_seq");
    ir_seq.instruction_width = 32;
    ir_seq.start(env.agent.sequencer);
    
    // Continuous operations
    repeat(500) begin
      ir_seq = jtag_ir_scan_sequence::type_id::create("ir_seq");
      ir_seq.instruction = BYPASS;
      ir_seq.start(env.agent.sequencer);
      
      dr_seq = jtag_dr_scan_sequence::type_id::create("dr_seq");
      dr_seq.data_length = $urandom_range(1, 256);
      dr_seq.start(env.agent.sequencer);
    end
    
    `uvm_info("STRESS_TEST", "Stress test completed", UVM_LOW)
  endtask
  
endclass

//=============================================================================
// Regression Test Suite
//=============================================================================

class jtag_regression_test extends jtag_base_test;
  `uvm_component_utils(jtag_regression_test)
  
  function new(string name = "jtag_regression_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual task test_body();
    `uvm_info("REGRESSION_TEST", "Starting regression test suite", UVM_LOW)
    
    // Run all test types in sequence
    run_basic_tests();
    run_boundary_scan_tests();
    run_debug_tests();
    run_error_injection_tests();
    run_performance_tests();
    run_compliance_tests();
    
    `uvm_info("REGRESSION_TEST", "Regression test suite completed", UVM_LOW)
  endtask
  
  virtual task run_basic_tests();
    jtag_basic_test basic_test;
    basic_test = jtag_basic_test::type_id::create("basic_test", this);
    basic_test.test_body();
  endtask
  
  virtual task run_boundary_scan_tests();
    jtag_boundary_scan_test bs_test;
    bs_test = jtag_boundary_scan_test::type_id::create("bs_test", this);
    bs_test.test_body();
  endtask
  
  virtual task run_debug_tests();
    jtag_debug_test debug_test;
    debug_test = jtag_debug_test::type_id::create("debug_test", this);
    debug_test.test_body();
  endtask
  
  virtual task run_error_injection_tests();
    jtag_error_injection_test error_test;
    error_test = jtag_error_injection_test::type_id::create("error_test", this);
    error_test.test_body();
  endtask
  
  virtual task run_performance_tests();
    jtag_performance_test perf_test;
    perf_test = jtag_performance_test::type_id::create("perf_test", this);
    perf_test.test_body();
  endtask
  
  virtual task run_compliance_tests();
    jtag_compliance_test comp_test;
    comp_test = jtag_compliance_test::type_id::create("comp_test", this);
    comp_test.test_body();
  endtask
  
endclass

`endif // JTAG_TEST_LIB_SVH