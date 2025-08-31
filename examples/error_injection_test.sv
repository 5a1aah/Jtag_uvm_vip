//=============================================================================
// File: error_injection_test.sv
// Description: Error Injection and Recovery Test Example
// Author: Enhanced JTAG VIP Team
// Date: 2024
// Version: 2.0
//=============================================================================

`include "uvm_macros.svh"

//=============================================================================
// Error Injection Test
//=============================================================================

class error_injection_test extends uvm_test;
  `uvm_component_utils(error_injection_test)
  
  //===========================================================================
  // Class Members
  //===========================================================================
  
  jtag_env env;
  jtag_env_config env_cfg;
  
  // Test control
  int error_injection_cycles = 100;
  int recovery_test_cycles = 50;
  
  //===========================================================================
  // Constructor
  //===========================================================================
  
  function new(string name = "error_injection_test", uvm_component parent = null);
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
    
    `uvm_info("ERROR_TEST", "Building error injection test environment", UVM_LOW)
    
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
    env_cfg.agent_cfg.protocol_cfg.enable_error_recovery = 1;
    
    // Timing configuration
    env_cfg.agent_cfg.timing_cfg.tck_period = 100.0;  // 10MHz
    env_cfg.agent_cfg.timing_cfg.tck_duty_cycle = 50.0;
    env_cfg.agent_cfg.timing_cfg.tsu_time = 5.0;
    env_cfg.agent_cfg.timing_cfg.th_time = 5.0;
    env_cfg.agent_cfg.timing_cfg.tco_time = 10.0;
    env_cfg.agent_cfg.timing_cfg.enable_timing_checks = 1;
    env_cfg.agent_cfg.timing_cfg.enable_setup_hold_checks = 1;
    env_cfg.agent_cfg.timing_cfg.enable_error_injection = 1;
    
    // Error injection configuration
    env_cfg.agent_cfg.error_cfg.enable_error_injection = 1;
    env_cfg.agent_cfg.error_cfg.error_injection_mode = SYSTEMATIC;
    env_cfg.agent_cfg.error_cfg.error_injection_rate = 10.0;  // 10% error rate
    env_cfg.agent_cfg.error_cfg.enable_bit_flip_errors = 1;
    env_cfg.agent_cfg.error_cfg.enable_stuck_at_errors = 1;
    env_cfg.agent_cfg.error_cfg.enable_timing_errors = 1;
    env_cfg.agent_cfg.error_cfg.enable_protocol_errors = 1;
    env_cfg.agent_cfg.error_cfg.enable_instruction_corruption = 1;
    env_cfg.agent_cfg.error_cfg.enable_data_corruption = 1;
    env_cfg.agent_cfg.error_cfg.enable_state_machine_errors = 1;
    env_cfg.agent_cfg.error_cfg.enable_clock_glitch_errors = 1;
    env_cfg.agent_cfg.error_cfg.enable_reset_anomaly_errors = 1;
    env_cfg.agent_cfg.error_cfg.enable_recovery_testing = 1;
    
    // Coverage configuration
    env_cfg.agent_cfg.coverage_cfg.enable_instruction_coverage = 1;
    env_cfg.agent_cfg.coverage_cfg.enable_state_coverage = 1;
    env_cfg.agent_cfg.coverage_cfg.enable_data_coverage = 1;
    env_cfg.agent_cfg.coverage_cfg.enable_error_coverage = 1;
    env_cfg.agent_cfg.coverage_cfg.instruction_coverage_goal = 100;
    env_cfg.agent_cfg.coverage_cfg.state_coverage_goal = 100;
    env_cfg.agent_cfg.coverage_cfg.overall_coverage_goal = 95;
    
    // Performance configuration
    env_cfg.agent_cfg.performance_cfg.enable_performance_monitoring = 1;
    env_cfg.agent_cfg.performance_cfg.throughput_threshold = 30.0;  // Lower due to errors
    env_cfg.agent_cfg.performance_cfg.latency_threshold = 1500.0;   // Higher due to recovery
    env_cfg.agent_cfg.performance_cfg.enable_trend_analysis = 1;
    env_cfg.agent_cfg.performance_cfg.enable_error_rate_monitoring = 1;
    
    // Environment components
    env_cfg.enable_scoreboard = 1;
    env_cfg.enable_debug_dashboard = 1;
    env_cfg.enable_virtual_sequencer = 1;
    env_cfg.enable_error_injector = 1;  // Essential for this test
    
    `uvm_info("ERROR_TEST", "Environment configuration completed", UVM_MEDIUM)
  endfunction
  
  //===========================================================================
  // Run Phase
  //===========================================================================
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("ERROR_TEST", "Starting error injection test sequence", UVM_LOW)
    
    fork
      begin
        // Main test sequence
        run_error_injection_test();
      end
      begin
        // Timeout watchdog (100ms for comprehensive error testing)
        #100ms;
        `uvm_fatal("ERROR_TEST", "Test timed out after 100ms")
      end
    join_any
    disable fork;
    
    `uvm_info("ERROR_TEST", "Error injection test completed successfully", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
  //===========================================================================
  // Error Injection Test Sequence
  //===========================================================================
  
  virtual task run_error_injection_test();
    `uvm_info("ERROR_TEST", "=== Starting Error Injection Test ===", UVM_LOW)
    
    // Test sequence
    test_baseline_operation();
    test_bit_flip_errors();
    test_stuck_at_errors();
    test_timing_errors();
    test_protocol_errors();
    test_instruction_corruption();
    test_data_corruption();
    test_state_machine_errors();
    test_clock_glitch_errors();
    test_reset_anomaly_errors();
    test_error_recovery();
    test_systematic_error_injection();
    
    `uvm_info("ERROR_TEST", "=== Error Injection Test Completed ===", UVM_LOW)
  endtask
  
  //===========================================================================
  // Baseline Operation Test
  //===========================================================================
  
  virtual task test_baseline_operation();
    jtag_basic_operation_sequence basic_seq;
    
    `uvm_info("ERROR_TEST", "--- Testing Baseline Operation (No Errors) ---", UVM_LOW)
    
    // Disable error injection temporarily
    env.error_injector.disable_error_injection();
    
    // Run basic operations
    basic_seq = jtag_basic_operation_sequence::type_id::create("basic_seq");
    basic_seq.num_operations = 20;
    basic_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("ERROR_TEST", "✓ Baseline operation: COMPLETED", UVM_LOW);
  endtask
  
  //===========================================================================
  // Bit Flip Error Test
  //===========================================================================
  
  virtual task test_bit_flip_errors();
    jtag_error_injection_sequence error_seq;
    
    `uvm_info("ERROR_TEST", "--- Testing Bit Flip Errors ---", UVM_LOW)
    
    // Configure for bit flip errors only
    env.error_injector.configure_error_injection(
      .enable = 1,
      .mode = SYSTEMATIC,
      .rate = 20.0,
      .error_types = BIT_FLIP_ERROR
    );
    
    // Run error injection sequence
    error_seq = jtag_error_injection_sequence::type_id::create("bit_flip_seq");
    error_seq.error_type = BIT_FLIP_ERROR;
    error_seq.num_injections = 10;
    error_seq.target_signal = TDI_SIGNAL;
    error_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("ERROR_TEST", "✓ Bit flip error injection: COMPLETED", UVM_LOW);
  endtask
  
  //===========================================================================
  // Stuck-At Error Test
  //===========================================================================
  
  virtual task test_stuck_at_errors();
    jtag_error_injection_sequence error_seq;
    
    `uvm_info("ERROR_TEST", "--- Testing Stuck-At Errors ---", UVM_LOW)
    
    // Test stuck-at-0
    env.error_injector.configure_error_injection(
      .enable = 1,
      .mode = SYSTEMATIC,
      .rate = 15.0,
      .error_types = STUCK_AT_ERROR
    );
    
    error_seq = jtag_error_injection_sequence::type_id::create("stuck_at_0_seq");
    error_seq.error_type = STUCK_AT_ERROR;
    error_seq.stuck_value = 1'b0;
    error_seq.num_injections = 5;
    error_seq.target_signal = TDO_SIGNAL;
    error_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Test stuck-at-1
    error_seq = jtag_error_injection_sequence::type_id::create("stuck_at_1_seq");
    error_seq.error_type = STUCK_AT_ERROR;
    error_seq.stuck_value = 1'b1;
    error_seq.num_injections = 5;
    error_seq.target_signal = TDO_SIGNAL;
    error_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("ERROR_TEST", "✓ Stuck-at error injection: COMPLETED", UVM_LOW);
  endtask
  
  //===========================================================================
  // Timing Error Test
  //===========================================================================
  
  virtual task test_timing_errors();
    jtag_error_injection_sequence error_seq;
    
    `uvm_info("ERROR_TEST", "--- Testing Timing Errors ---", UVM_LOW)
    
    // Configure for timing errors
    env.error_injector.configure_error_injection(
      .enable = 1,
      .mode = RANDOM,
      .rate = 25.0,
      .error_types = TIMING_ERROR
    );
    
    // Setup time violations
    error_seq = jtag_error_injection_sequence::type_id::create("setup_error_seq");
    error_seq.error_type = TIMING_ERROR;
    error_seq.timing_error_type = SETUP_VIOLATION;
    error_seq.num_injections = 8;
    error_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Hold time violations
    error_seq = jtag_error_injection_sequence::type_id::create("hold_error_seq");
    error_seq.error_type = TIMING_ERROR;
    error_seq.timing_error_type = HOLD_VIOLATION;
    error_seq.num_injections = 8;
    error_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("ERROR_TEST", "✓ Timing error injection: COMPLETED", UVM_LOW);
  endtask
  
  //===========================================================================
  // Protocol Error Test
  //===========================================================================
  
  virtual task test_protocol_errors();
    jtag_error_injection_sequence error_seq;
    
    `uvm_info("ERROR_TEST", "--- Testing Protocol Errors ---", UVM_LOW)
    
    // Configure for protocol errors
    env.error_injector.configure_error_injection(
      .enable = 1,
      .mode = SYSTEMATIC,
      .rate = 30.0,
      .error_types = PROTOCOL_ERROR
    );
    
    // Invalid state transitions
    error_seq = jtag_error_injection_sequence::type_id::create("protocol_seq");
    error_seq.error_type = PROTOCOL_ERROR;
    error_seq.protocol_error_type = INVALID_STATE_TRANSITION;
    error_seq.num_injections = 6;
    error_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("ERROR_TEST", "✓ Protocol error injection: COMPLETED", UVM_LOW);
  endtask
  
  //===========================================================================
  // Instruction Corruption Test
  //===========================================================================
  
  virtual task test_instruction_corruption();
    jtag_error_injection_sequence error_seq;
    
    `uvm_info("ERROR_TEST", "--- Testing Instruction Corruption ---", UVM_LOW)
    
    // Configure for instruction corruption
    env.error_injector.configure_error_injection(
      .enable = 1,
      .mode = RANDOM,
      .rate = 20.0,
      .error_types = INSTRUCTION_CORRUPTION
    );
    
    error_seq = jtag_error_injection_sequence::type_id::create("instr_corrupt_seq");
    error_seq.error_type = INSTRUCTION_CORRUPTION;
    error_seq.num_injections = 10;
    error_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("ERROR_TEST", "✓ Instruction corruption: COMPLETED", UVM_LOW);
  endtask
  
  //===========================================================================
  // Data Corruption Test
  //===========================================================================
  
  virtual task test_data_corruption();
    jtag_error_injection_sequence error_seq;
    
    `uvm_info("ERROR_TEST", "--- Testing Data Corruption ---", UVM_LOW)
    
    // Configure for data corruption
    env.error_injector.configure_error_injection(
      .enable = 1,
      .mode = SYSTEMATIC,
      .rate = 25.0,
      .error_types = DATA_CORRUPTION
    );
    
    error_seq = jtag_error_injection_sequence::type_id::create("data_corrupt_seq");
    error_seq.error_type = DATA_CORRUPTION;
    error_seq.num_injections = 12;
    error_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("ERROR_TEST", "✓ Data corruption: COMPLETED", UVM_LOW);
  endtask
  
  //===========================================================================
  // State Machine Error Test
  //===========================================================================
  
  virtual task test_state_machine_errors();
    jtag_error_injection_sequence error_seq;
    
    `uvm_info("ERROR_TEST", "--- Testing State Machine Errors ---", UVM_LOW)
    
    // Configure for state machine errors
    env.error_injector.configure_error_injection(
      .enable = 1,
      .mode = RANDOM,
      .rate = 15.0,
      .error_types = STATE_MACHINE_ERROR
    );
    
    error_seq = jtag_error_injection_sequence::type_id::create("state_error_seq");
    error_seq.error_type = STATE_MACHINE_ERROR;
    error_seq.num_injections = 8;
    error_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("ERROR_TEST", "✓ State machine error injection: COMPLETED", UVM_LOW);
  endtask
  
  //===========================================================================
  // Clock Glitch Error Test
  //===========================================================================
  
  virtual task test_clock_glitch_errors();
    jtag_error_injection_sequence error_seq;
    
    `uvm_info("ERROR_TEST", "--- Testing Clock Glitch Errors ---", UVM_LOW)
    
    // Configure for clock glitch errors
    env.error_injector.configure_error_injection(
      .enable = 1,
      .mode = SYSTEMATIC,
      .rate = 10.0,
      .error_types = CLOCK_GLITCH_ERROR
    );
    
    error_seq = jtag_error_injection_sequence::type_id::create("clock_glitch_seq");
    error_seq.error_type = CLOCK_GLITCH_ERROR;
    error_seq.num_injections = 5;
    error_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("ERROR_TEST", "✓ Clock glitch error injection: COMPLETED", UVM_LOW);
  endtask
  
  //===========================================================================
  // Reset Anomaly Error Test
  //===========================================================================
  
  virtual task test_reset_anomaly_errors();
    jtag_error_injection_sequence error_seq;
    
    `uvm_info("ERROR_TEST", "--- Testing Reset Anomaly Errors ---", UVM_LOW)
    
    // Configure for reset anomaly errors
    env.error_injector.configure_error_injection(
      .enable = 1,
      .mode = SYSTEMATIC,
      .rate = 5.0,
      .error_types = RESET_ANOMALY_ERROR
    );
    
    error_seq = jtag_error_injection_sequence::type_id::create("reset_anomaly_seq");
    error_seq.error_type = RESET_ANOMALY_ERROR;
    error_seq.num_injections = 3;
    error_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("ERROR_TEST", "✓ Reset anomaly error injection: COMPLETED", UVM_LOW);
  endtask
  
  //===========================================================================
  // Error Recovery Test
  //===========================================================================
  
  virtual task test_error_recovery();
    jtag_error_recovery_sequence recovery_seq;
    
    `uvm_info("ERROR_TEST", "--- Testing Error Recovery ---", UVM_LOW)
    
    // Enable all error types for comprehensive recovery testing
    env.error_injector.configure_error_injection(
      .enable = 1,
      .mode = RANDOM,
      .rate = 40.0,
      .error_types = ALL_ERROR_TYPES
    );
    
    recovery_seq = jtag_error_recovery_sequence::type_id::create("recovery_seq");
    recovery_seq.num_recovery_cycles = recovery_test_cycles;
    recovery_seq.enable_automatic_recovery = 1;
    recovery_seq.recovery_timeout = 1000;  // 1000 ns timeout
    recovery_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("ERROR_TEST", $sformatf("✓ Error recovery: %0d/%0d successful recoveries", 
              recovery_seq.successful_recoveries, recovery_seq.total_recovery_attempts), UVM_LOW);
  endtask
  
  //===========================================================================
  // Systematic Error Injection Test
  //===========================================================================
  
  virtual task test_systematic_error_injection();
    jtag_systematic_error_sequence systematic_seq;
    
    `uvm_info("ERROR_TEST", "--- Testing Systematic Error Injection ---", UVM_LOW)
    
    // Configure for systematic testing
    env.error_injector.configure_error_injection(
      .enable = 1,
      .mode = SYSTEMATIC,
      .rate = 50.0,
      .error_types = ALL_ERROR_TYPES
    );
    
    systematic_seq = jtag_systematic_error_sequence::type_id::create("systematic_seq");
    systematic_seq.num_test_cycles = error_injection_cycles;
    systematic_seq.test_all_error_types = 1;
    systematic_seq.test_all_signals = 1;
    systematic_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("ERROR_TEST", "✓ Systematic error injection: COMPLETED", UVM_LOW);
  endtask
  
  //===========================================================================
  // Report Phase
  //===========================================================================
  
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info("ERROR_TEST", "=== Error Injection Test Report ===", UVM_LOW)
    
    // Report error injection statistics
    if (env.error_injector != null) begin
      jtag_error_statistics_s stats = env.error_injector.get_error_statistics();
      
      `uvm_info("ERROR_TEST", "--- Error Injection Statistics ---", UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Total errors injected: %0d", stats.total_errors_injected), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Bit flip errors: %0d", stats.bit_flip_errors), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Stuck-at errors: %0d", stats.stuck_at_errors), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Timing errors: %0d", stats.timing_errors), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Protocol errors: %0d", stats.protocol_errors), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Instruction corruption: %0d", stats.instruction_corruption), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Data corruption: %0d", stats.data_corruption), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("State machine errors: %0d", stats.state_machine_errors), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Clock glitch errors: %0d", stats.clock_glitch_errors), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Reset anomaly errors: %0d", stats.reset_anomaly_errors), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Errors detected: %0d", stats.errors_detected), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Errors recovered: %0d", stats.errors_recovered), UVM_LOW);
      
      real detection_rate = (stats.errors_detected * 100.0) / stats.total_errors_injected;
      real recovery_rate = (stats.errors_recovered * 100.0) / stats.errors_detected;
      
      `uvm_info("ERROR_TEST", $sformatf("Error detection rate: %0.1f%%", detection_rate), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Error recovery rate: %0.1f%%", recovery_rate), UVM_LOW);
      
      if (detection_rate >= 95.0) begin
        `uvm_info("ERROR_TEST", "✓ Error detection: EXCELLENT", UVM_LOW);
      end else if (detection_rate >= 80.0) begin
        `uvm_info("ERROR_TEST", "✓ Error detection: GOOD", UVM_LOW);
      end else begin
        `uvm_warning("ERROR_TEST", "⚠ Error detection: NEEDS IMPROVEMENT");
      end
      
      if (recovery_rate >= 90.0) begin
        `uvm_info("ERROR_TEST", "✓ Error recovery: EXCELLENT", UVM_LOW);
      end else if (recovery_rate >= 70.0) begin
        `uvm_info("ERROR_TEST", "✓ Error recovery: GOOD", UVM_LOW);
      end else begin
        `uvm_warning("ERROR_TEST", "⚠ Error recovery: NEEDS IMPROVEMENT");
      end
    end
    
    // Report protocol compliance under error conditions
    if (env.agent.protocol_checker != null) begin
      int total_violations = env.agent.protocol_checker.get_total_violations();
      int expected_violations = env.error_injector.get_expected_violations();
      
      `uvm_info("ERROR_TEST", "--- Protocol Compliance Under Errors ---", UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Total violations detected: %0d", total_violations), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Expected violations: %0d", expected_violations), UVM_LOW);
      
      if (total_violations >= expected_violations) begin
        `uvm_info("ERROR_TEST", "✓ Protocol violation detection: ADEQUATE", UVM_LOW);
      end else begin
        `uvm_warning("ERROR_TEST", "⚠ Protocol violation detection: INSUFFICIENT");
      end
    end
    
    // Report coverage under error conditions
    if (env.agent.coverage_collector != null) begin
      real overall_cov = env.agent.coverage_collector.get_overall_coverage();
      real error_cov = env.agent.coverage_collector.get_error_coverage();
      
      `uvm_info("ERROR_TEST", "--- Coverage Under Error Conditions ---", UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Overall coverage: %0.1f%%", overall_cov), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Error coverage: %0.1f%%", error_cov), UVM_LOW);
      
      if (overall_cov >= 85.0 && error_cov >= 90.0) begin
        `uvm_info("ERROR_TEST", "✓ Coverage goals: ACHIEVED", UVM_LOW);
      end else begin
        `uvm_warning("ERROR_TEST", "⚠ Coverage goals: NOT FULLY ACHIEVED");
      end
    end
    
    // Report performance under error conditions
    if (env.performance_monitor != null) begin
      jtag_performance_metrics_s metrics = env.performance_monitor.get_current_metrics();
      `uvm_info("ERROR_TEST", "--- Performance Under Error Conditions ---", UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Throughput: %0.2f Mbps", metrics.throughput_mbps), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Average latency: %0.2f ns", metrics.latency_ns), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Error rate: %0.3f%%", metrics.error_rate), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Total transactions: %0d", metrics.total_transactions), UVM_LOW);
      `uvm_info("ERROR_TEST", $sformatf("Failed transactions: %0d", metrics.failed_transactions), UVM_LOW);
    end
    
    `uvm_info("ERROR_TEST", "=== End of Error Injection Test Report ===", UVM_LOW);
  endfunction
  
endclass : error_injection_test

//=============================================================================
// Test Module
//=============================================================================

module error_injection_test_tb;
  
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
    run_test("error_injection_test");
  end
  
  // Waveform dumping
  initial begin
    $dumpfile("error_injection_test.vcd");
    $dumpvars(0, error_injection_test_tb);
  end
  
endmodule : error_injection_test_tb