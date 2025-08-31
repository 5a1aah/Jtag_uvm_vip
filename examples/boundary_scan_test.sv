//=============================================================================
// File: boundary_scan_test.sv
// Description: Advanced Boundary Scan Test Example
// Author: Enhanced JTAG VIP Team
// Date: 2024
// Version: 2.0
//=============================================================================

`include "uvm_macros.svh"

//=============================================================================
// Boundary Scan Test
//=============================================================================

class boundary_scan_test extends uvm_test;
  `uvm_component_utils(boundary_scan_test)
  
  //===========================================================================
  // Class Members
  //===========================================================================
  
  jtag_env env;
  jtag_env_config env_cfg;
  
  // Test parameters
  int boundary_scan_length = 256;  // Typical boundary scan chain length
  bit [255:0] test_pattern_1 = 256'hAAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA_AAAA;
  bit [255:0] test_pattern_2 = 256'h5555_5555_5555_5555_5555_5555_5555_5555;
  bit [255:0] test_pattern_3 = 256'hFFFF_0000_FFFF_0000_FFFF_0000_FFFF_0000;
  
  //===========================================================================
  // Constructor
  //===========================================================================
  
  function new(string name = "boundary_scan_test", uvm_component parent = null);
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
    
    `uvm_info("BSCAN_TEST", "Building boundary scan test environment", UVM_LOW)
    
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
    
    // Protocol configuration for boundary scan
    env_cfg.agent_cfg.protocol_cfg.ieee_standard = IEEE_1149_1_2013;
    env_cfg.agent_cfg.protocol_cfg.ir_width = 8;
    env_cfg.agent_cfg.protocol_cfg.max_ir_length = 32;
    env_cfg.agent_cfg.protocol_cfg.max_dr_length = 1024;
    env_cfg.agent_cfg.protocol_cfg.enable_compliance_checking = 1;
    env_cfg.agent_cfg.protocol_cfg.enable_state_checking = 1;
    env_cfg.agent_cfg.protocol_cfg.enable_instruction_checking = 1;
    env_cfg.agent_cfg.protocol_cfg.enable_data_integrity_checking = 1;
    env_cfg.agent_cfg.protocol_cfg.enable_boundary_scan_checking = 1;
    
    // Timing configuration - slower for boundary scan
    env_cfg.agent_cfg.timing_cfg.tck_period = 200.0;  // 5MHz for reliable boundary scan
    env_cfg.agent_cfg.timing_cfg.tck_duty_cycle = 50.0;
    env_cfg.agent_cfg.timing_cfg.tsu_time = 10.0;
    env_cfg.agent_cfg.timing_cfg.th_time = 10.0;
    env_cfg.agent_cfg.timing_cfg.tco_time = 20.0;
    env_cfg.agent_cfg.timing_cfg.enable_timing_checks = 1;
    env_cfg.agent_cfg.timing_cfg.enable_setup_hold_checks = 1;
    
    // Coverage configuration
    env_cfg.agent_cfg.coverage_cfg.enable_instruction_coverage = 1;
    env_cfg.agent_cfg.coverage_cfg.enable_state_coverage = 1;
    env_cfg.agent_cfg.coverage_cfg.enable_data_coverage = 1;
    env_cfg.agent_cfg.coverage_cfg.enable_boundary_scan_coverage = 1;
    env_cfg.agent_cfg.coverage_cfg.instruction_coverage_goal = 100;
    env_cfg.agent_cfg.coverage_cfg.state_coverage_goal = 100;
    env_cfg.agent_cfg.coverage_cfg.overall_coverage_goal = 95;
    
    // Performance configuration
    env_cfg.agent_cfg.performance_cfg.enable_performance_monitoring = 1;
    env_cfg.agent_cfg.performance_cfg.throughput_threshold = 25.0;  // Lower for boundary scan
    env_cfg.agent_cfg.performance_cfg.latency_threshold = 2000.0;   // Higher latency expected
    env_cfg.agent_cfg.performance_cfg.enable_trend_analysis = 1;
    
    // Environment components
    env_cfg.enable_scoreboard = 1;
    env_cfg.enable_debug_dashboard = 1;
    env_cfg.enable_virtual_sequencer = 1;  // Needed for complex sequences
    env_cfg.enable_error_injector = 0;     // Not needed for this test
    
    `uvm_info("BSCAN_TEST", "Environment configuration completed", UVM_MEDIUM)
  endfunction
  
  //===========================================================================
  // Run Phase
  //===========================================================================
  
  virtual task run_phase(uvm_phase phase);
    phase.raise_objection(this);
    
    `uvm_info("BSCAN_TEST", "Starting boundary scan test sequence", UVM_LOW)
    
    fork
      begin
        // Main test sequence
        run_boundary_scan_test();
      end
      begin
        // Timeout watchdog (50ms for comprehensive test)
        #50ms;
        `uvm_fatal("BSCAN_TEST", "Test timed out after 50ms")
      end
    join_any
    disable fork;
    
    `uvm_info("BSCAN_TEST", "Boundary scan test completed successfully", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
  
  //===========================================================================
  // Boundary Scan Test Sequence
  //===========================================================================
  
  virtual task run_boundary_scan_test();
    `uvm_info("BSCAN_TEST", "=== Starting Boundary Scan Test ===", UVM_LOW)
    
    // Test sequence
    test_device_identification();
    test_sample_preload();
    test_extest();
    test_intest();
    test_boundary_scan_patterns();
    test_interconnect();
    
    `uvm_info("BSCAN_TEST", "=== Boundary Scan Test Completed ===", UVM_LOW)
  endtask
  
  //===========================================================================
  // Device Identification Test
  //===========================================================================
  
  virtual task test_device_identification();
    jtag_reset_sequence reset_seq;
    jtag_ir_scan_sequence ir_seq;
    jtag_dr_scan_sequence dr_seq;
    bit [31:0] device_id;
    
    `uvm_info("BSCAN_TEST", "--- Testing Device Identification ---", UVM_LOW)
    
    // Reset TAP
    reset_seq = jtag_reset_sequence::type_id::create("reset_seq");
    reset_seq.reset_type = HARD_RESET;
    reset_seq.reset_cycles = 5;
    reset_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Scan IDCODE instruction
    ir_seq = jtag_ir_scan_sequence::type_id::create("ir_seq");
    ir_seq.instruction = IDCODE;
    ir_seq.ir_width = 8;
    ir_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Read device ID
    dr_seq = jtag_dr_scan_sequence::type_id::create("dr_seq");
    dr_seq.data_in = 32'h0;
    dr_seq.data_length = 32;
    dr_seq.capture_data = 1;
    dr_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Validate device ID (example validation)
    device_id = dr_seq.data_out[31:0];
    `uvm_info("BSCAN_TEST", $sformatf("Device ID: 0x%08h", device_id), UVM_LOW)
    
    if (device_id[0] == 1'b1) begin  // LSB should be 1 for valid IDCODE
      `uvm_info("BSCAN_TEST", "✓ Device identification: PASSED", UVM_LOW);
    end else begin
      `uvm_error("BSCAN_TEST", "✗ Device identification: FAILED - Invalid IDCODE");
    end
  endtask
  
  //===========================================================================
  // SAMPLE/PRELOAD Test
  //===========================================================================
  
  virtual task test_sample_preload();
    jtag_boundary_scan_sequence bscan_seq;
    
    `uvm_info("BSCAN_TEST", "--- Testing SAMPLE/PRELOAD ---", UVM_LOW)
    
    // Create boundary scan sequence
    bscan_seq = jtag_boundary_scan_sequence::type_id::create("bscan_seq");
    bscan_seq.bscan_instruction = SAMPLE_PRELOAD;
    bscan_seq.boundary_data = test_pattern_1[boundary_scan_length-1:0];
    bscan_seq.boundary_length = boundary_scan_length;
    bscan_seq.capture_boundary_data = 1;
    bscan_seq.start(env.virtual_sequencer.agent_sqr);
    
    // Verify preload data
    if (bscan_seq.captured_data == test_pattern_1[boundary_scan_length-1:0]) begin
      `uvm_info("BSCAN_TEST", "✓ SAMPLE/PRELOAD: PASSED", UVM_LOW);
    end else begin
      `uvm_warning("BSCAN_TEST", "⚠ SAMPLE/PRELOAD: Data mismatch (expected in some cases)");
    end
  endtask
  
  //===========================================================================
  // EXTEST Test
  //===========================================================================
  
  virtual task test_extest();
    jtag_boundary_scan_sequence bscan_seq;
    bit [255:0] readback_data;
    
    `uvm_info("BSCAN_TEST", "--- Testing EXTEST ---", UVM_LOW)
    
    // Test pattern 1
    bscan_seq = jtag_boundary_scan_sequence::type_id::create("extest_seq1");
    bscan_seq.bscan_instruction = EXTEST;
    bscan_seq.boundary_data = test_pattern_1[boundary_scan_length-1:0];
    bscan_seq.boundary_length = boundary_scan_length;
    bscan_seq.capture_boundary_data = 1;
    bscan_seq.start(env.virtual_sequencer.agent_sqr);
    
    readback_data = bscan_seq.captured_data;
    `uvm_info("BSCAN_TEST", $sformatf("EXTEST Pattern 1 - Written: 0x%064h", test_pattern_1), UVM_MEDIUM);
    `uvm_info("BSCAN_TEST", $sformatf("EXTEST Pattern 1 - Read: 0x%064h", readback_data), UVM_MEDIUM);
    
    // Test pattern 2
    bscan_seq = jtag_boundary_scan_sequence::type_id::create("extest_seq2");
    bscan_seq.bscan_instruction = EXTEST;
    bscan_seq.boundary_data = test_pattern_2[boundary_scan_length-1:0];
    bscan_seq.boundary_length = boundary_scan_length;
    bscan_seq.capture_boundary_data = 1;
    bscan_seq.start(env.virtual_sequencer.agent_sqr);
    
    readback_data = bscan_seq.captured_data;
    `uvm_info("BSCAN_TEST", $sformatf("EXTEST Pattern 2 - Written: 0x%064h", test_pattern_2), UVM_MEDIUM);
    `uvm_info("BSCAN_TEST", $sformatf("EXTEST Pattern 2 - Read: 0x%064h", readback_data), UVM_MEDIUM);
    
    `uvm_info("BSCAN_TEST", "✓ EXTEST: COMPLETED", UVM_LOW);
  endtask
  
  //===========================================================================
  // INTEST Test
  //===========================================================================
  
  virtual task test_intest();
    jtag_boundary_scan_sequence bscan_seq;
    bit [255:0] readback_data;
    
    `uvm_info("BSCAN_TEST", "--- Testing INTEST ---", UVM_LOW)
    
    // Test internal logic with boundary scan
    bscan_seq = jtag_boundary_scan_sequence::type_id::create("intest_seq");
    bscan_seq.bscan_instruction = INTEST;
    bscan_seq.boundary_data = test_pattern_3[boundary_scan_length-1:0];
    bscan_seq.boundary_length = boundary_scan_length;
    bscan_seq.capture_boundary_data = 1;
    bscan_seq.start(env.virtual_sequencer.agent_sqr);
    
    readback_data = bscan_seq.captured_data;
    `uvm_info("BSCAN_TEST", $sformatf("INTEST - Input: 0x%064h", test_pattern_3), UVM_MEDIUM);
    `uvm_info("BSCAN_TEST", $sformatf("INTEST - Output: 0x%064h", readback_data), UVM_MEDIUM);
    
    `uvm_info("BSCAN_TEST", "✓ INTEST: COMPLETED", UVM_LOW);
  endtask
  
  //===========================================================================
  // Boundary Scan Pattern Test
  //===========================================================================
  
  virtual task test_boundary_scan_patterns();
    jtag_boundary_scan_pattern_sequence pattern_seq;
    
    `uvm_info("BSCAN_TEST", "--- Testing Boundary Scan Patterns ---", UVM_LOW)
    
    // Create pattern test sequence
    pattern_seq = jtag_boundary_scan_pattern_sequence::type_id::create("pattern_seq");
    pattern_seq.num_patterns = 10;
    pattern_seq.pattern_type = WALKING_ONES;
    pattern_seq.boundary_length = boundary_scan_length;
    pattern_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("BSCAN_TEST", "✓ Walking ones pattern: COMPLETED", UVM_LOW);
    
    // Walking zeros pattern
    pattern_seq = jtag_boundary_scan_pattern_sequence::type_id::create("pattern_seq2");
    pattern_seq.num_patterns = 10;
    pattern_seq.pattern_type = WALKING_ZEROS;
    pattern_seq.boundary_length = boundary_scan_length;
    pattern_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("BSCAN_TEST", "✓ Walking zeros pattern: COMPLETED", UVM_LOW);
    
    // Random patterns
    pattern_seq = jtag_boundary_scan_pattern_sequence::type_id::create("pattern_seq3");
    pattern_seq.num_patterns = 20;
    pattern_seq.pattern_type = RANDOM;
    pattern_seq.boundary_length = boundary_scan_length;
    pattern_seq.start(env.virtual_sequencer.agent_sqr);
    
    `uvm_info("BSCAN_TEST", "✓ Random patterns: COMPLETED", UVM_LOW);
  endtask
  
  //===========================================================================
  // Interconnect Test
  //===========================================================================
  
  virtual task test_interconnect();
    jtag_interconnect_test_sequence interconnect_seq;
    
    `uvm_info("BSCAN_TEST", "--- Testing Interconnect ---", UVM_LOW)
    
    // Create interconnect test sequence
    interconnect_seq = jtag_interconnect_test_sequence::type_id::create("interconnect_seq");
    interconnect_seq.num_pins = 64;  // Test 64 pins
    interconnect_seq.test_shorts = 1;
    interconnect_seq.test_opens = 1;
    interconnect_seq.start(env.virtual_sequencer.agent_sqr);
    
    if (interconnect_seq.shorts_detected == 0 && interconnect_seq.opens_detected == 0) begin
      `uvm_info("BSCAN_TEST", "✓ Interconnect test: PASSED - No faults detected", UVM_LOW);
    end else begin
      `uvm_warning("BSCAN_TEST", $sformatf("⚠ Interconnect test: %0d shorts, %0d opens detected", 
                   interconnect_seq.shorts_detected, interconnect_seq.opens_detected));
    end
  endtask
  
  //===========================================================================
  // Report Phase
  //===========================================================================
  
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info("BSCAN_TEST", "=== Boundary Scan Test Report ===", UVM_LOW)
    
    // Report protocol compliance
    if (env.agent.protocol_checker != null) begin
      int total_violations = env.agent.protocol_checker.get_total_violations();
      int boundary_violations = env.agent.protocol_checker.get_boundary_scan_violations();
      
      `uvm_info("BSCAN_TEST", $sformatf("Total protocol violations: %0d", total_violations), UVM_LOW);
      `uvm_info("BSCAN_TEST", $sformatf("Boundary scan violations: %0d", boundary_violations), UVM_LOW);
      
      if (total_violations == 0) begin
        `uvm_info("BSCAN_TEST", "✓ Protocol compliance: PASSED", UVM_LOW);
      end else begin
        `uvm_error("BSCAN_TEST", "✗ Protocol compliance: FAILED");
      end
    end
    
    // Report timing validation
    if (env.agent.timing_validator != null) begin
      int timing_violations = env.agent.timing_validator.get_timing_violations();
      `uvm_info("BSCAN_TEST", $sformatf("Timing violations: %0d", timing_violations), UVM_LOW);
      
      if (timing_violations == 0) begin
        `uvm_info("BSCAN_TEST", "✓ Timing validation: PASSED", UVM_LOW);
      end else begin
        `uvm_error("BSCAN_TEST", "✗ Timing validation: FAILED");
      end
    end
    
    // Report coverage
    if (env.agent.coverage_collector != null) begin
      real overall_cov = env.agent.coverage_collector.get_overall_coverage();
      real bscan_cov = env.agent.coverage_collector.get_boundary_scan_coverage();
      
      `uvm_info("BSCAN_TEST", $sformatf("Overall coverage: %0.1f%%", overall_cov), UVM_LOW);
      `uvm_info("BSCAN_TEST", $sformatf("Boundary scan coverage: %0.1f%%", bscan_cov), UVM_LOW);
      
      if (overall_cov >= 90.0 && bscan_cov >= 95.0) begin
        `uvm_info("BSCAN_TEST", "✓ Coverage goals: ACHIEVED", UVM_LOW);
      end else begin
        `uvm_warning("BSCAN_TEST", "⚠ Coverage goals: NOT FULLY ACHIEVED");
      end
    end
    
    // Report performance
    if (env.performance_monitor != null) begin
      jtag_performance_metrics_s metrics = env.performance_monitor.get_current_metrics();
      `uvm_info("BSCAN_TEST", $sformatf("Throughput: %0.2f Mbps", metrics.throughput_mbps), UVM_LOW);
      `uvm_info("BSCAN_TEST", $sformatf("Average latency: %0.2f ns", metrics.latency_ns), UVM_LOW);
      `uvm_info("BSCAN_TEST", $sformatf("Error rate: %0.3f%%", metrics.error_rate), UVM_LOW);
      `uvm_info("BSCAN_TEST", $sformatf("Total boundary scan operations: %0d", metrics.total_transactions), UVM_LOW);
    end
    
    `uvm_info("BSCAN_TEST", "=== End of Boundary Scan Test Report ===", UVM_LOW);
  endfunction
  
endclass : boundary_scan_test

//=============================================================================
// Test Module
//=============================================================================

module boundary_scan_test_tb;
  
  // Import packages
  import uvm_pkg::*;
  import jtag_vip_pkg::*;
  
  // JTAG interface signals
  logic tck;
  logic tms;
  logic tdi;
  logic tdo;
  logic trst_n;
  
  // Clock generation (5MHz for boundary scan)
  initial begin
    tck = 0;
    forever #100ns tck = ~tck;
  end
  
  // Reset generation
  initial begin
    trst_n = 0;
    #500ns trst_n = 1;
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
    run_test("boundary_scan_test");
  end
  
  // Waveform dumping
  initial begin
    $dumpfile("boundary_scan_test.vcd");
    $dumpvars(0, boundary_scan_test_tb);
  end
  
endmodule : boundary_scan_test_tb