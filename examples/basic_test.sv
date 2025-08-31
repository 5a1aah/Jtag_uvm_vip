//=============================================================================
// File: basic_test.sv
// Description: Basic JTAG VIP Test Example
// Author: Enhanced JTAG VIP Team
// Date: 2024
// Version: 2.0
//=============================================================================

`include "uvm_macros.svh"

//=============================================================================
// Basic JTAG Test
//=============================================================================

class basic_jtag_test extends uvm_test;
  `uvm_component_utils(basic_jtag_test)
  
  //===========================================================================
  // Class Members
  //===========================================================================
  
  jtag_env env;
  jtag_env_config env_cfg;
  
  //===========================================================================
  // Constructor
  //===========================================================================
  
  function new(string name = "basic_jtag_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  //===========================================================================
  // Build Phase
  //===========================================================================
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Initialize JTAG VIP
    jtag_vip_init();
    jtag_vip_info();
    
    `uvm_info("BASIC_TEST", "Building basic JTAG test environment", UVM_LOW)
    
    // Create environment configuration
    env_cfg = jtag_env_config::type_id::create("env_cfg");
    configure_environment();
    
    // Set configuration in database
    uvm_config_db#(jtag_env_config)::set(this, "env", "config", env_cfg);
    
    // Create environment
    env = jtag_env::type_id::create("env", this);
  endfunction
  
  //===========================================================================
  // Environment Configuration
  //===========================================================================
  
  virtual function void configure_environment();
    // Agent configuration
    env_cfg.agent_cfg.is_active = UVM_ACTIVE;
    env_cfg.agent_cfg.has_driver = 1;
    env_cfg.agent_cfg.has_monitor = 1;
    env_cfg.agent_cfg.has_collector = 1;
    
    // Protocol configuration
    env_cfg.agent_cfg.protocol_cfg.ieee_standard = IEEE_1149_1_2013;
    env_cfg.agent_cfg.protocol_cfg.ir_width = 8;
    env_cfg.agent_cfg.protocol_cfg.max_ir_length = 32;
    env_cfg.agent_cfg.protocol_cfg.max_dr_length = 1024;
    env_cfg.agent_cfg.protocol_cfg.enable_compliance_checking = 1;
    env_cfg.agent_cfg.protocol_cfg.enable_state_checking = 1;
    env_cfg.agent_cfg.protocol_cfg.enable_instruction_checking = 1;
    env_cfg.agent_cfg.protocol_cfg.enable_data_integrity_checking = 1;
    
    // Timing configuration
    env_cfg.agent_cfg.timing_cfg.tck_period = 100.0;  // 10MHz
    env_cfg.agent_cfg.timing_cfg.tck_duty_cycle = 50.0;
    env_cfg.agent_cfg.timing_cfg.tsu_time = 5.0;
    env_cfg.agent_cfg.timing_cfg.th_time = 5.0;
    env_cfg.agent_cfg.timing_cfg.tco_time = 10.0;
    env_cfg.agent_cfg.timing_cfg.enable_timing_checks = 1;
    env_cfg.agent_cfg.timing_cfg.enable_setup_hold_checks = 1;
    
    // Coverage configuration
    env_cfg.agent_cfg.coverage_cfg.enable_instruction_coverage = 1;
    env_cfg.agent_cfg.coverage_cfg.enable_state_coverage = 1;
    env_cfg.agent_cfg.coverage_cfg.enable_data_coverage = 1;
    env_cfg.agent_cfg.coverage_cfg.instruction_coverage_goal = 100;
    env_cfg.agent_cfg.coverage_cfg.state_coverage_goal = 100;
    env_cfg.agent_cfg.coverage_cfg.overall_coverage_goal = 95;
    
    // Performance configuration
    env_cfg.agent_cfg.performance_cfg.enable_performance_monitoring = 1;
    env_cfg.agent_cfg.performance_cfg.throughput_threshold = 50.0;  // 50 Mbps
    env_cfg.agent_cfg.performance_cfg.latency_threshold = 1000.0;   // 1000 ns
    env_cfg.agent_cfg.performance_cfg.enable_trend_analysis = 1;
    
    // Environment components
    env_cfg.enable_scoreboard = 1;
    env_cfg.enable_debug_dashboard = 1;
    env_cfg.enable_virtual_sequencer = 0;  // Not needed for basic test
    env_cfg.enable_error_injector = 0;     // Not needed for basic test
    
    `uvm_info("BASIC_TEST", "Environment configuration completed", UVM_MEDIUM)
  endfunction
  
  //===========================================================================
  // Run Phase
  //===========================================================================
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("BASIC_TEST", "Starting basic JTAG test sequence", UVM_LOW)
    
    fork
      begin
        // Main test sequence
        run_basic_test_sequence();
      end
      begin
        // Timeout watchdog (10ms)
        #10ms;
        `uvm_fatal("BASIC_TEST", "Test timed out after 10ms")
      end
    join_any
    disable fork;
    
    `uvm_info("BASIC_TEST", "Basic JTAG test completed successfully", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
  //===========================================================================
  // Basic Test Sequence
  //===========================================================================
  
  virtual task run_basic_test_sequence();
    jtag_reset_sequence reset_seq;
    jtag_idle_sequence idle_seq;
    jtag_ir_scan_sequence ir_seq;
    jtag_dr_scan_sequence dr_seq;
    
    `uvm_info("BASIC_TEST", "=== Starting Basic JTAG Operations ===", UVM_LOW)
    
    // Step 1: Reset the JTAG TAP
    `uvm_info("BASIC_TEST", "Step 1: Resetting JTAG TAP", UVM_LOW)
    reset_seq = jtag_reset_sequence::type_id::create("reset_seq");
    reset_seq.reset_type = HARD_RESET;
    reset_seq.reset_cycles = 5;
    reset_seq.start(env.agent.sequencer);
    
    // Step 2: Go to idle state
    `uvm_info("BASIC_TEST", "Step 2: Moving to idle state", UVM_LOW)
    idle_seq = jtag_idle_sequence::type_id::create("idle_seq");
    idle_seq.idle_cycles = 10;
    idle_seq.start(env.agent.sequencer);
    
    // Step 3: Scan IDCODE instruction
    `uvm_info("BASIC_TEST", "Step 3: Scanning IDCODE instruction", UVM_LOW)
    ir_seq = jtag_ir_scan_sequence::type_id::create("ir_seq");
    ir_seq.instruction = IDCODE;
    ir_seq.ir_width = 8;
    ir_seq.start(env.agent.sequencer);
    
    // Step 4: Read device ID
    `uvm_info("BASIC_TEST", "Step 4: Reading device ID", UVM_LOW)
    dr_seq = jtag_dr_scan_sequence::type_id::create("dr_seq");
    dr_seq.data_in = 32'h0;  // Don't care for read
    dr_seq.data_length = 32;
    dr_seq.capture_data = 1;
    dr_seq.start(env.agent.sequencer);
    
    // Step 5: Scan BYPASS instruction
    `uvm_info("BASIC_TEST", "Step 5: Scanning BYPASS instruction", UVM_LOW)
    ir_seq = jtag_ir_scan_sequence::type_id::create("ir_seq2");
    ir_seq.instruction = BYPASS;
    ir_seq.ir_width = 8;
    ir_seq.start(env.agent.sequencer);
    
    // Step 6: Test bypass register
    `uvm_info("BASIC_TEST", "Step 6: Testing bypass register", UVM_LOW)
    dr_seq = jtag_dr_scan_sequence::type_id::create("dr_seq2");
    dr_seq.data_in = 1'b1;   // Single bit for bypass
    dr_seq.data_length = 1;
    dr_seq.capture_data = 1;
    dr_seq.start(env.agent.sequencer);
    
    // Step 7: Return to idle
    `uvm_info("BASIC_TEST", "Step 7: Returning to idle state", UVM_LOW)
    idle_seq = jtag_idle_sequence::type_id::create("idle_seq2");
    idle_seq.idle_cycles = 5;
    idle_seq.start(env.agent.sequencer);
    
    `uvm_info("BASIC_TEST", "=== Basic JTAG Operations Completed ===", UVM_LOW)
    
    // Wait for all transactions to complete
    #1us;
  endtask
  
  //===========================================================================
  // Report Phase
  //===========================================================================
  
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info("BASIC_TEST", "=== Basic Test Report ===", UVM_LOW)
    
    // Report protocol compliance
    if (env.agent.protocol_checker != null) begin
      int total_violations = env.agent.protocol_checker.get_total_violations();
      `uvm_info("BASIC_TEST", $sformatf("Protocol violations: %0d", total_violations), UVM_LOW);
      
      if (total_violations == 0) begin
        `uvm_info("BASIC_TEST", "✓ Protocol compliance: PASSED", UVM_LOW);
      end else begin
        `uvm_error("BASIC_TEST", "✗ Protocol compliance: FAILED");
      end
    end
    
    // Report timing validation
    if (env.agent.timing_validator != null) begin
      int timing_violations = env.agent.timing_validator.get_timing_violations();
      `uvm_info("BASIC_TEST", $sformatf("Timing violations: %0d", timing_violations), UVM_LOW);
      
      if (timing_violations == 0) begin
        `uvm_info("BASIC_TEST", "✓ Timing validation: PASSED", UVM_LOW);
      end else begin
        `uvm_error("BASIC_TEST", "✗ Timing validation: FAILED");
      end
    end
    
    // Report coverage
    if (env.agent.coverage_collector != null) begin
      real overall_cov = env.agent.coverage_collector.get_overall_coverage();
      `uvm_info("BASIC_TEST", $sformatf("Overall coverage: %0.1f%%", overall_cov), UVM_LOW);
      
      if (overall_cov >= 90.0) begin
        `uvm_info("BASIC_TEST", "✓ Coverage goal: ACHIEVED", UVM_LOW);
      end else begin
        `uvm_warning("BASIC_TEST", "⚠ Coverage goal: NOT ACHIEVED");
      end
    end
    
    // Report performance
    if (env.performance_monitor != null) begin
      jtag_performance_metrics_s metrics = env.performance_monitor.get_current_metrics();
      `uvm_info("BASIC_TEST", $sformatf("Throughput: %0.2f Mbps", metrics.throughput_mbps), UVM_LOW);
      `uvm_info("BASIC_TEST", $sformatf("Average latency: %0.2f ns", metrics.latency_ns), UVM_LOW);
      `uvm_info("BASIC_TEST", $sformatf("Error rate: %0.3f%%", metrics.error_rate), UVM_LOW);
    end
    
    `uvm_info("BASIC_TEST", "=== End of Basic Test Report ===", UVM_LOW);
  endfunction
  
endclass : basic_jtag_test

//=============================================================================
// Test Module
//=============================================================================

module basic_test_tb;
  
  // Import packages
  import uvm_pkg::*;
  import jtag_vip_pkg::*;
  
  // JTAG interface signals
  logic tck;
  logic tms;
  logic tdi;
  logic tdo;
  logic trst_n;
  
  // Clock generation
  initial begin
    tck = 0;
    forever #50ns tck = ~tck; // 10MHz clock
  end
  
  // Reset generation
  initial begin
    trst_n = 0;
    #200ns trst_n = 1;
  end
  
  // JTAG interface instance
  jtag_if jtag_interface(
    .tck(tck),
    .tms(tms),
    .tdi(tdi),
    .tdo(tdo),
    .trst_n(trst_n)
  );
  
  // Test execution
  initial begin
    // Set interface in config DB
    uvm_config_db#(virtual jtag_if)::set(null, "*", "jtag_vif", jtag_interface);
    
    // Run test
    run_test("basic_jtag_test");
  end
  
  // Waveform dumping
  initial begin
    $dumpfile("basic_test.vcd");
    $dumpvars(0, basic_test_tb);
  end
  
endmodule : basic_test_tb