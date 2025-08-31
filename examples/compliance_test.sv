//=============================================================================
// File: compliance_test.sv
// Description: IEEE 1149.1/1149.4/1149.6 Compliance Test Example
// Author: Enhanced JTAG VIP Team
// Date: 2024
// Version: 2.0
//=============================================================================

`include "uvm_macros.svh"

//=============================================================================
// Compliance Test
//=============================================================================

class compliance_test extends uvm_test;
  `uvm_component_utils(compliance_test)
  
  //===========================================================================
  // Class Members
  //===========================================================================
  
  jtag_env env;
  jtag_env_config env_cfg;
  
  // Test control
  ieee_standard_e target_standard = IEEE_1149_1_2013;
  int compliance_test_cycles = 200;
  
  //===========================================================================
  // Constructor
  //===========================================================================
  
  function new(string name = "compliance_test", uvm_component parent = null);
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
    
    `uvm_info("COMPLIANCE_TEST", "Building IEEE compliance test environment", UVM_LOW)
    
    // Get target standard from command line
    if ($value$plusargs("IEEE_STANDARD=%s", target_standard)) begin
      `uvm_info("COMPLIANCE_TEST", $sformatf("Target IEEE standard: %s", target_standard.name()), UVM_LOW)
    end
    
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
    
    // Protocol configuration for compliance testing
    env_cfg.agent_cfg.protocol_cfg.ieee_standard = target_standard;
    env_cfg.agent_cfg.protocol_cfg.ir_width = 8;
    env_cfg.agent_cfg.protocol_cfg.max_ir_length = 32;
    env_cfg.agent_cfg.protocol_cfg.max_dr_length = 1024;
    env_cfg.agent_cfg.protocol_cfg.enable_compliance_checking = 1;
    env_cfg.agent_cfg.protocol_cfg.enable_state_checking = 1;
    env_cfg.agent_cfg.protocol_cfg.enable_instruction_checking = 1;
    env_cfg.agent_cfg.protocol_cfg.enable_data_integrity_checking = 1;
    env_cfg.agent_cfg.protocol_cfg.enable_boundary_scan_checking = 1;
    env_cfg.agent_cfg.protocol_cfg.enable_debug_access_checking = 1;
    env_cfg.agent_cfg.protocol_cfg.strict_compliance_mode = 1;
    env_cfg.agent_cfg.protocol_cfg.compliance_level = STRICT;
    
    // Configure supported instructions based on standard
    configure_instructions_for_standard(target_standard);
    
    // Timing configuration for compliance
    env_cfg.agent_cfg.timing_cfg.tck_period = 100.0;  // 10MHz
    env_cfg.agent_cfg.timing_cfg.tck_duty_cycle = 50.0;
    env_cfg.agent_cfg.timing_cfg.tsu_time = 5.0;
    env_cfg.agent_cfg.timing_cfg.th_time = 5.0;
    env_cfg.agent_cfg.timing_cfg.tco_time = 10.0;
    env_cfg.agent_cfg.timing_cfg.enable_timing_checks = 1;
    env_cfg.agent_cfg.timing_cfg.enable_setup_hold_checks = 1;
    env_cfg.agent_cfg.timing_cfg.strict_timing_mode = 1;
    env_cfg.agent_cfg.timing_cfg.timing_tolerance = 0.5;  // Strict tolerance
    
    // Error configuration (disabled for compliance testing)
    env_cfg.agent_cfg.error_cfg.enable_error_injection = 0;
    
    // Coverage configuration for compliance
    env_cfg.agent_cfg.coverage_cfg.enable_instruction_coverage = 1;
    env_cfg.agent_cfg.coverage_cfg.enable_state_coverage = 1;
    env_cfg.agent_cfg.coverage_cfg.enable_data_coverage = 1;
    env_cfg.agent_cfg.coverage_cfg.enable_boundary_scan_coverage = 1;
    env_cfg.agent_cfg.coverage_cfg.enable_compliance_coverage = 1;
    env_cfg.agent_cfg.coverage_cfg.instruction_coverage_goal = 100;
    env_cfg.agent_cfg.coverage_cfg.state_coverage_goal = 100;
    env_cfg.agent_cfg.coverage_cfg.overall_coverage_goal = 100;
    
    // Performance configuration
    env_cfg.agent_cfg.performance_cfg.enable_performance_monitoring = 1;
    env_cfg.agent_cfg.performance_cfg.throughput_threshold = 50.0;
    env_cfg.agent_cfg.performance_cfg.latency_threshold = 1000.0;
    env_cfg.agent_cfg.performance_cfg.enable_compliance_monitoring = 1;
    
    // Environment components
    env_cfg.enable_scoreboard = 1;
    env_cfg.enable_debug_dashboard = 1;
    env_cfg.enable_virtual_sequencer = 1;
    env_cfg.enable_error_injector = 0;  // Not needed for compliance testing
    
    `uvm_info("COMPLIANCE_TEST", "Environment configuration completed", UVM_MEDIUM)
  endfunction
  
  //===========================================================================
  // Configure Instructions for Standard
  //===========================================================================
  
  virtual function void configure_instructions_for_standard(ieee_standard_e standard);
    case (standard)
      IEEE_1149_1_2001, IEEE_1149_1_2013: begin
        // Basic IEEE 1149.1 instructions
        env_cfg.agent_cfg.protocol_cfg.supported_instructions.push_back(BYPASS);
        env_cfg.agent_cfg.protocol_cfg.supported_instructions.push_back(IDCODE);
        env_cfg.agent_cfg.protocol_cfg.supported_instructions.push_back(SAMPLE_PRELOAD);
        env_cfg.agent_cfg.protocol_cfg.supported_instructions.push_back(EXTEST);
        env_cfg.agent_cfg.protocol_cfg.supported_instructions.push_back(INTEST);
        env_cfg.agent_cfg.protocol_cfg.supported_instructions.push_back(RUNBIST);
        env_cfg.agent_cfg.protocol_cfg.supported_instructions.push_back(CLAMP);
        env_cfg.agent_cfg.protocol_cfg.supported_instructions.push_back(HIGHZ);
      end
      
      IEEE_1149_4: begin
        // IEEE 1149.4 mixed-signal instructions
        configure_instructions_for_standard(IEEE_1149_1_2013);  // Include base
        env_cfg.agent_cfg.protocol_cfg.supported_instructions.push_back(ANALOG_BYPASS);
        env_cfg.agent_cfg.protocol_cfg.supported_instructions.push_back(ANALOG_SAMPLE);
        env_cfg.agent_cfg.protocol_cfg.supported_instructions.push_back(ANALOG_EXTEST);
        env_cfg.agent_cfg.protocol_cfg.supported_instructions.push_back(ANALOG_INTEST);
      end
      
      IEEE_1149_6: begin
        // IEEE 1149.6 AC-coupled instructions
        configure_instructions_for_standard(IEEE_1149_1_2013);  // Include base
        env_cfg.agent_cfg.protocol_cfg.supported_instructions.push_back(AC_BYPASS);
        env_cfg.agent_cfg.protocol_cfg.supported_instructions.push_back(AC_SAMPLE);
        env_cfg.agent_cfg.protocol_cfg.supported_instructions.push_back(AC_EXTEST);
        env_cfg.agent_cfg.protocol_cfg.supported_instructions.push_back(AC_INTEST);
      end
      
      default: begin
        `uvm_warning("COMPLIANCE_TEST", $sformatf("Unknown IEEE standard: %s", standard.name()))
        configure_instructions_for_standard(IEEE_1149_1_2013);  // Default to basic
      end
    endcase
  endfunction
  
  //===========================================================================
  // Run Phase
  //===========================================================================
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("COMPLIANCE_TEST", "Starting IEEE compliance test sequence", UVM_LOW)
    
    fork
      begin
        // Main test sequence
        run_compliance_test();
      end
      begin
        // Timeout watchdog (200ms for comprehensive compliance testing)
        #200ms;
        `uvm_fatal("COMPLIANCE_TEST", "Test timed out after 200ms")
      end
    join_any
    disable fork;
    
    `uvm_info("COMPLIANCE_TEST", "IEEE compliance test completed successfully", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
  //===========================================================================
  // Compliance Test Sequence
  //===========================================================================
  
  virtual task run_compliance_test();
    `uvm_info("COMPLIANCE_TEST", $sformatf("=== Starting %s Compliance Test ===", target_standard.name()), UVM_LOW)
    
    // Test sequence based on standard
    case (target_standard)
      IEEE_1149_1_2001, IEEE_1149_1_2013: begin
        test_ieee_1149_1_compliance();
      end
      
      IEEE_1149_4: begin
        test_ieee_1149_1_compliance();  // Base compliance
        test_ieee_1149_4_compliance();  // Mixed-signal extensions
      end
      
      IEEE_1149_6: begin
        test_ieee_1149_1_compliance();  // Base compliance
        test_ieee_1149_6_compliance();  // AC-coupled extensions
      end
      
      default: begin
        `uvm_warning("COMPLIANCE_TEST", "Unknown standard, running basic compliance")
        test_ieee_1149_1_compliance();
      end
    endcase
    
    `uvm_info("COMPLIANCE_TEST", $sformatf("=== %s Compliance Test Completed ===", target_standard.name()), UVM_LOW)
  endtask
  
  //===========================================================================
  // IEEE 1149.1 Compliance Test
  //===========================================================================
  
  virtual task test_ieee_1149_1_compliance();
    `uvm_info("COMPLIANCE_TEST", "--- Testing IEEE 1149.1 Compliance ---", UVM_LOW)
    
    // Test mandatory instructions
    test_mandatory_instructions();
    
    // Test TAP controller state machine
    test_tap_state_machine();
    
    // Test boundary scan operations
    test_boundary_scan_compliance();
    
    // Test instruction register
    test_instruction_register();
    
    // Test data registers
    test_data_registers();
    
    // Test timing requirements
    test_timing_compliance();
    
    // Test reset behavior
    test_reset_compliance();
    
    `uvm_info("COMPLIANCE_TEST", "✓ IEEE 1149.1 compliance: COMPLETED", UVM_LOW);
  endtask
  
  //===========================================================================
  // Test Mandatory Instructions
  //===========================================================================
  
  virtual task test_mandatory_instructions();
    jtag_compliance_sequence compliance_seq;
    
    `uvm_info("COMPLIANCE_TEST", "Testing mandatory instructions", UVM_MEDIUM)
    
    // Test BYPASS instruction
    compliance_seq = jtag_compliance_sequence::type_id::create("bypass_compliance");
    compliance_seq.instruction = BYPASS;
    compliance_seq.test_type = INSTRUCTION_COMPLIANCE;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Test IDCODE instruction
    compliance_seq = jtag_compliance_sequence::type_id::create("idcode_compliance");
    compliance_seq.instruction = IDCODE;
    compliance_seq.test_type = INSTRUCTION_COMPLIANCE;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Test SAMPLE/PRELOAD instruction
    compliance_seq = jtag_compliance_sequence::type_id::create("sample_compliance");
    compliance_seq.instruction = SAMPLE_PRELOAD;
    compliance_seq.test_type = INSTRUCTION_COMPLIANCE;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Test EXTEST instruction
    compliance_seq = jtag_compliance_sequence::type_id::create("extest_compliance");
    compliance_seq.instruction = EXTEST;
    compliance_seq.test_type = INSTRUCTION_COMPLIANCE;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("COMPLIANCE_TEST", "✓ Mandatory instructions: VERIFIED", UVM_MEDIUM);
  endtask
  
  //===========================================================================
  // Test TAP State Machine
  //===========================================================================
  
  virtual task test_tap_state_machine();
    jtag_compliance_sequence compliance_seq;
    
    `uvm_info("COMPLIANCE_TEST", "Testing TAP controller state machine", UVM_MEDIUM)
    
    // Test all state transitions
    compliance_seq = jtag_compliance_sequence::type_id::create("state_machine_compliance");
    compliance_seq.test_type = STATE_MACHINE_COMPLIANCE;
    compliance_seq.test_all_transitions = 1;
    compliance_seq.verify_state_encoding = 1;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Test reset behavior
    compliance_seq = jtag_compliance_sequence::type_id::create("reset_state_compliance");
    compliance_seq.test_type = RESET_COMPLIANCE;
    compliance_seq.test_trst_reset = 1;
    compliance_seq.test_tms_reset = 1;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("COMPLIANCE_TEST", "✓ TAP state machine: VERIFIED", UVM_MEDIUM);
  endtask
  
  //===========================================================================
  // Test Boundary Scan Compliance
  //===========================================================================
  
  virtual task test_boundary_scan_compliance();
    jtag_compliance_sequence compliance_seq;
    
    `uvm_info("COMPLIANCE_TEST", "Testing boundary scan compliance", UVM_MEDIUM)
    
    // Test boundary scan register
    compliance_seq = jtag_compliance_sequence::type_id::create("bsr_compliance");
    compliance_seq.test_type = BOUNDARY_SCAN_COMPLIANCE;
    compliance_seq.test_bsr_length = 1;
    compliance_seq.test_bsr_connectivity = 1;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Test EXTEST operation
    compliance_seq = jtag_compliance_sequence::type_id::create("extest_operation");
    compliance_seq.instruction = EXTEST;
    compliance_seq.test_type = BOUNDARY_SCAN_COMPLIANCE;
    compliance_seq.test_external_test = 1;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Test INTEST operation
    compliance_seq = jtag_compliance_sequence::type_id::create("intest_operation");
    compliance_seq.instruction = INTEST;
    compliance_seq.test_type = BOUNDARY_SCAN_COMPLIANCE;
    compliance_seq.test_internal_test = 1;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("COMPLIANCE_TEST", "✓ Boundary scan compliance: VERIFIED", UVM_MEDIUM);
  endtask
  
  //===========================================================================
  // Test Instruction Register
  //===========================================================================
  
  virtual task test_instruction_register();
    jtag_compliance_sequence compliance_seq;
    
    `uvm_info("COMPLIANCE_TEST", "Testing instruction register compliance", UVM_MEDIUM)
    
    // Test IR length and encoding
    compliance_seq = jtag_compliance_sequence::type_id::create("ir_compliance");
    compliance_seq.test_type = INSTRUCTION_REGISTER_COMPLIANCE;
    compliance_seq.test_ir_length = 1;
    compliance_seq.test_ir_encoding = 1;
    compliance_seq.test_ir_capture = 1;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Test instruction decode
    compliance_seq = jtag_compliance_sequence::type_id::create("decode_compliance");
    compliance_seq.test_type = INSTRUCTION_DECODE_COMPLIANCE;
    compliance_seq.test_all_instructions = 1;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("COMPLIANCE_TEST", "✓ Instruction register: VERIFIED", UVM_MEDIUM);
  endtask
  
  //===========================================================================
  // Test Data Registers
  //===========================================================================
  
  virtual task test_data_registers();
    jtag_compliance_sequence compliance_seq;
    
    `uvm_info("COMPLIANCE_TEST", "Testing data register compliance", UVM_MEDIUM)
    
    // Test BYPASS register
    compliance_seq = jtag_compliance_sequence::type_id::create("bypass_dr_compliance");
    compliance_seq.instruction = BYPASS;
    compliance_seq.test_type = DATA_REGISTER_COMPLIANCE;
    compliance_seq.test_dr_length = 1;
    compliance_seq.test_dr_functionality = 1;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Test IDCODE register
    compliance_seq = jtag_compliance_sequence::type_id::create("idcode_dr_compliance");
    compliance_seq.instruction = IDCODE;
    compliance_seq.test_type = DATA_REGISTER_COMPLIANCE;
    compliance_seq.test_dr_length = 1;
    compliance_seq.test_idcode_format = 1;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Test boundary scan register
    compliance_seq = jtag_compliance_sequence::type_id::create("bsr_dr_compliance");
    compliance_seq.instruction = SAMPLE_PRELOAD;
    compliance_seq.test_type = DATA_REGISTER_COMPLIANCE;
    compliance_seq.test_dr_length = 1;
    compliance_seq.test_bsr_cells = 1;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("COMPLIANCE_TEST", "✓ Data registers: VERIFIED", UVM_MEDIUM);
  endtask
  
  //===========================================================================
  // Test Timing Compliance
  //===========================================================================
  
  virtual task test_timing_compliance();
    jtag_compliance_sequence compliance_seq;
    
    `uvm_info("COMPLIANCE_TEST", "Testing timing compliance", UVM_MEDIUM)
    
    // Test setup and hold times
    compliance_seq = jtag_compliance_sequence::type_id::create("timing_compliance");
    compliance_seq.test_type = TIMING_COMPLIANCE;
    compliance_seq.test_setup_times = 1;
    compliance_seq.test_hold_times = 1;
    compliance_seq.test_clock_requirements = 1;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Test frequency limits
    compliance_seq = jtag_compliance_sequence::type_id::create("frequency_compliance");
    compliance_seq.test_type = TIMING_COMPLIANCE;
    compliance_seq.test_max_frequency = 1;
    compliance_seq.test_min_frequency = 1;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("COMPLIANCE_TEST", "✓ Timing compliance: VERIFIED", UVM_MEDIUM);
  endtask
  
  //===========================================================================
  // Test Reset Compliance
  //===========================================================================
  
  virtual task test_reset_compliance();
    jtag_compliance_sequence compliance_seq;
    
    `uvm_info("COMPLIANCE_TEST", "Testing reset compliance", UVM_MEDIUM)
    
    // Test TRST reset
    compliance_seq = jtag_compliance_sequence::type_id::create("trst_compliance");
    compliance_seq.test_type = RESET_COMPLIANCE;
    compliance_seq.test_trst_reset = 1;
    compliance_seq.test_reset_state = 1;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Test TMS reset sequence
    compliance_seq = jtag_compliance_sequence::type_id::create("tms_reset_compliance");
    compliance_seq.test_type = RESET_COMPLIANCE;
    compliance_seq.test_tms_reset = 1;
    compliance_seq.test_reset_sequence = 1;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("COMPLIANCE_TEST", "✓ Reset compliance: VERIFIED", UVM_MEDIUM);
  endtask
  
  //===========================================================================
  // IEEE 1149.4 Compliance Test
  //===========================================================================
  
  virtual task test_ieee_1149_4_compliance();
    jtag_compliance_sequence compliance_seq;
    
    `uvm_info("COMPLIANCE_TEST", "--- Testing IEEE 1149.4 Extensions ---", UVM_LOW)
    
    // Test analog boundary scan
    compliance_seq = jtag_compliance_sequence::type_id::create("analog_compliance");
    compliance_seq.test_type = ANALOG_COMPLIANCE;
    compliance_seq.test_analog_instructions = 1;
    compliance_seq.test_mixed_signal = 1;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("COMPLIANCE_TEST", "✓ IEEE 1149.4 extensions: VERIFIED", UVM_LOW);
  endtask
  
  //===========================================================================
  // IEEE 1149.6 Compliance Test
  //===========================================================================
  
  virtual task test_ieee_1149_6_compliance();
    jtag_compliance_sequence compliance_seq;
    
    `uvm_info("COMPLIANCE_TEST", "--- Testing IEEE 1149.6 Extensions ---", UVM_LOW)
    
    // Test AC-coupled boundary scan
    compliance_seq = jtag_compliance_sequence::type_id::create("ac_compliance");
    compliance_seq.test_type = AC_COUPLED_COMPLIANCE;
    compliance_seq.test_ac_instructions = 1;
    compliance_seq.test_differential_signals = 1;
    compliance_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("COMPLIANCE_TEST", "✓ IEEE 1149.6 extensions: VERIFIED", UVM_LOW);
  endtask
  
  //===========================================================================
  // Report Phase
  //===========================================================================
  
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info("COMPLIANCE_TEST", $sformatf("=== %s Compliance Test Report ===", target_standard.name()), UVM_LOW)
    
    // Report protocol compliance results
    if (env.agent.protocol_checker != null) begin
      jtag_compliance_results_s results = env.agent.protocol_checker.get_compliance_results();
      
      `uvm_info("COMPLIANCE_TEST", "--- Protocol Compliance Results ---", UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Total compliance checks: %0d", results.total_checks), UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Passed checks: %0d", results.passed_checks), UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Failed checks: %0d", results.failed_checks), UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Warnings: %0d", results.warnings), UVM_LOW);
      
      real compliance_rate = (results.passed_checks * 100.0) / results.total_checks;
      `uvm_info("COMPLIANCE_TEST", $sformatf("Compliance rate: %0.1f%%", compliance_rate), UVM_LOW);
      
      // Detailed compliance breakdown
      `uvm_info("COMPLIANCE_TEST", "--- Detailed Compliance Breakdown ---", UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("State machine compliance: %0d/%0d", 
                results.state_compliance_passed, results.state_compliance_total), UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Instruction compliance: %0d/%0d", 
                results.instruction_compliance_passed, results.instruction_compliance_total), UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Data register compliance: %0d/%0d", 
                results.data_register_compliance_passed, results.data_register_compliance_total), UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Timing compliance: %0d/%0d", 
                results.timing_compliance_passed, results.timing_compliance_total), UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Boundary scan compliance: %0d/%0d", 
                results.boundary_scan_compliance_passed, results.boundary_scan_compliance_total), UVM_LOW);
      
      // Overall compliance assessment
      if (compliance_rate >= 100.0) begin
        `uvm_info("COMPLIANCE_TEST", "✓ FULL COMPLIANCE ACHIEVED", UVM_LOW);
      end else if (compliance_rate >= 95.0) begin
        `uvm_info("COMPLIANCE_TEST", "✓ SUBSTANTIAL COMPLIANCE (Minor issues)", UVM_LOW);
      end else if (compliance_rate >= 80.0) begin
        `uvm_warning("COMPLIANCE_TEST", "⚠ PARTIAL COMPLIANCE (Significant issues)");
      end else begin
        `uvm_error("COMPLIANCE_TEST", "✗ NON-COMPLIANT (Major violations)");
      end
    end
    
    // Report timing validation results
    if (env.agent.timing_validator != null) begin
      jtag_timing_results_s timing_results = env.agent.timing_validator.get_timing_results();
      
      `uvm_info("COMPLIANCE_TEST", "--- Timing Validation Results ---", UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Setup violations: %0d", timing_results.setup_violations), UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Hold violations: %0d", timing_results.hold_violations), UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Clock violations: %0d", timing_results.clock_violations), UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Total timing checks: %0d", timing_results.total_checks), UVM_LOW);
      
      if (timing_results.setup_violations == 0 && timing_results.hold_violations == 0 && 
          timing_results.clock_violations == 0) begin
        `uvm_info("COMPLIANCE_TEST", "✓ TIMING COMPLIANCE: PASSED", UVM_LOW);
      end else begin
        `uvm_warning("COMPLIANCE_TEST", "⚠ TIMING COMPLIANCE: VIOLATIONS DETECTED");
      end
    end
    
    // Report coverage results
    if (env.agent.coverage_collector != null) begin
      real overall_cov = env.agent.coverage_collector.get_overall_coverage();
      real instruction_cov = env.agent.coverage_collector.get_instruction_coverage();
      real state_cov = env.agent.coverage_collector.get_state_coverage();
      real compliance_cov = env.agent.coverage_collector.get_compliance_coverage();
      
      `uvm_info("COMPLIANCE_TEST", "--- Coverage Results ---", UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Overall coverage: %0.1f%%", overall_cov), UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Instruction coverage: %0.1f%%", instruction_cov), UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("State coverage: %0.1f%%", state_cov), UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Compliance coverage: %0.1f%%", compliance_cov), UVM_LOW);
      
      if (overall_cov >= 100.0 && instruction_cov >= 100.0 && state_cov >= 100.0) begin
        `uvm_info("COMPLIANCE_TEST", "✓ COVERAGE GOALS: ACHIEVED", UVM_LOW);
      end else begin
        `uvm_warning("COMPLIANCE_TEST", "⚠ COVERAGE GOALS: NOT FULLY ACHIEVED");
      end
    end
    
    // Report performance under compliance testing
    if (env.performance_monitor != null) begin
      jtag_performance_metrics_s metrics = env.performance_monitor.get_current_metrics();
      `uvm_info("COMPLIANCE_TEST", "--- Performance Results ---", UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Throughput: %0.2f Mbps", metrics.throughput_mbps), UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Average latency: %0.2f ns", metrics.latency_ns), UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Total transactions: %0d", metrics.total_transactions), UVM_LOW);
      `uvm_info("COMPLIANCE_TEST", $sformatf("Failed transactions: %0d", metrics.failed_transactions), UVM_LOW);
    end
    
    `uvm_info("COMPLIANCE_TEST", $sformatf("=== End of %s Compliance Test Report ===", target_standard.name()), UVM_LOW);
  endfunction
  
endclass : compliance_test

//=============================================================================
// Test Module
//=============================================================================

module compliance_test_tb;
  
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
    run_test("compliance_test");
  end
  
  // Waveform dumping
  initial begin
    $dumpfile("compliance_test.vcd");
    $dumpvars(0, compliance_test_tb);
  end
  
endmodule : compliance_test_tb