`ifndef JTAG_COVERAGE_COLLECTOR_SVH
`define JTAG_COVERAGE_COLLECTOR_SVH

//=============================================================================
// Enhanced JTAG Coverage Collector
// Comprehensive functional coverage for JTAG protocol verification
//=============================================================================

class jtag_coverage_collector extends uvm_subscriber #(jtag_base_transaction);
  `uvm_component_utils(jtag_coverage_collector)
  
  // Configuration objects
  jtag_protocol_config protocol_cfg;
  jtag_coverage_config coverage_cfg;
  
  // Coverage groups
  covergroup jtag_instruction_cg;
    option.per_instance = 1;
    option.name = "jtag_instruction_coverage";
    
    // Instruction coverage
    instruction_cp: coverpoint current_transaction.instruction {
      bins mandatory_instructions[] = {IDCODE, BYPASS, SAMPLE_PRELOAD, EXTEST, INTEST};
      bins optional_instructions[] = {CLAMP, HIGHZ, RUNBIST, USERCODE};
      bins debug_instructions[] = {DEBUG_ENTER, DEBUG_EXIT, DEBUG_READ, DEBUG_WRITE};
      bins boundary_scan[] = {EXTEST, INTEST, SAMPLE_PRELOAD, CLAMP, HIGHZ};
      bins user_defined[] = {[16'h0010:16'h001F]}; // User-defined instruction range
      bins reserved[] = default;
    }
    
    // Instruction length coverage
    instruction_length_cp: coverpoint current_transaction.instruction_length {
      bins standard_length[] = {4, 5, 6, 7, 8};
      bins extended_length[] = {9, 10, 11, 12, 13, 14, 15, 16};
      bins custom_length[] = {[17:32]};
    }
    
    // Cross coverage: instruction vs length
    instruction_x_length: cross instruction_cp, instruction_length_cp;
  endgroup
  
  covergroup jtag_state_machine_cg;
    option.per_instance = 1;
    option.name = "jtag_state_machine_coverage";
    
    // TAP state coverage
    current_state_cp: coverpoint current_transaction.current_state {
      bins stable_states[] = {TEST_LOGIC_RESET, RUN_TEST_IDLE, SHIFT_DR, PAUSE_DR, SHIFT_IR, PAUSE_IR};
      bins transition_states[] = {SELECT_DR_SCAN, CAPTURE_DR, EXIT1_DR, EXIT2_DR, UPDATE_DR,
                                  SELECT_IR_SCAN, CAPTURE_IR, EXIT1_IR, EXIT2_IR, UPDATE_IR};
    }
    
    previous_state_cp: coverpoint current_transaction.previous_state {
      bins stable_states[] = {TEST_LOGIC_RESET, RUN_TEST_IDLE, SHIFT_DR, PAUSE_DR, SHIFT_IR, PAUSE_IR};
      bins transition_states[] = {SELECT_DR_SCAN, CAPTURE_DR, EXIT1_DR, EXIT2_DR, UPDATE_DR,
                                  SELECT_IR_SCAN, CAPTURE_IR, EXIT1_IR, EXIT2_IR, UPDATE_IR};
    }
    
    // State transition coverage
    state_transition: cross previous_state_cp, current_state_cp {
      // Valid transitions only
      bins valid_transitions = binsof(previous_state_cp) intersect {TEST_LOGIC_RESET} &&
                               binsof(current_state_cp) intersect {RUN_TEST_IDLE, TEST_LOGIC_RESET};
      // Add more valid transition bins as needed
    }
    
    // TMS sequence coverage
    tms_sequence_cp: coverpoint current_transaction.tms_sequence {
      bins reset_sequence = {5'b11111}; // 5 consecutive 1s for reset
      bins idle_to_shift_dr = {4'b0100};
      bins idle_to_shift_ir = {5'b01100};
      bins shift_to_idle = {3'b110};
      bins pause_resume = {2'b01};
    }
  endgroup
  
  covergroup jtag_data_patterns_cg;
    option.per_instance = 1;
    option.name = "jtag_data_patterns_coverage";
    
    // Data pattern coverage
    data_pattern_cp: coverpoint current_transaction.data_out {
      bins all_zeros = {64'h0000000000000000};
      bins all_ones = {64'hFFFFFFFFFFFFFFFF};
      bins alternating_01 = {64'h5555555555555555};
      bins alternating_10 = {64'hAAAAAAAAAAAAAAAA};
      bins walking_ones[] = {64'h0000000000000001, 64'h0000000000000002, 64'h0000000000000004,
                            64'h0000000000000008, 64'h0000000000000010, 64'h0000000000000020};
      bins walking_zeros[] = {64'hFFFFFFFFFFFFFFFE, 64'hFFFFFFFFFFFFFFFD, 64'hFFFFFFFFFFFFFFFB,
                             64'hFFFFFFFFFFFFFFF7, 64'hFFFFFFFFFFFFFFEF, 64'hFFFFFFFFFFFFFFDF};
      bins random_patterns[] = default;
    }
    
    // Data length coverage
    data_length_cp: coverpoint current_transaction.data_length {
      bins short_data[] = {[1:8]};
      bins medium_data[] = {[9:32]};
      bins long_data[] = {[33:64]};
      bins very_long_data[] = {[65:128]};
    }
    
    // Cross coverage: data pattern vs length
    data_pattern_x_length: cross data_pattern_cp, data_length_cp;
  endgroup
  
  covergroup jtag_timing_cg;
    option.per_instance = 1;
    option.name = "jtag_timing_coverage";
    
    // Clock frequency coverage
    tck_frequency_cp: coverpoint current_transaction.tck_frequency {
      bins low_freq[] = {[1:1000000]}; // 1Hz to 1MHz
      bins medium_freq[] = {[1000001:10000000]}; // 1MHz to 10MHz
      bins high_freq[] = {[10000001:50000000]}; // 10MHz to 50MHz
      bins very_high_freq[] = {[50000001:100000000]}; // 50MHz to 100MHz
    }
    
    // Setup time coverage
    setup_time_cp: coverpoint current_transaction.setup_time {
      bins minimal_setup[] = {[0.0:2.0]};
      bins normal_setup[] = {[2.1:5.0]};
      bins generous_setup[] = {[5.1:10.0]};
      bins excessive_setup[] = {[10.1:20.0]};
    }
    
    // Hold time coverage
    hold_time_cp: coverpoint current_transaction.hold_time {
      bins minimal_hold[] = {[0.0:1.0]};
      bins normal_hold[] = {[1.1:3.0]};
      bins generous_hold[] = {[3.1:6.0]};
      bins excessive_hold[] = {[6.1:12.0]};
    }
    
    // Cross coverage: frequency vs timing
    freq_x_setup: cross tck_frequency_cp, setup_time_cp;
    freq_x_hold: cross tck_frequency_cp, hold_time_cp;
  endgroup
  
  covergroup jtag_boundary_scan_cg;
    option.per_instance = 1;
    option.name = "jtag_boundary_scan_coverage";
    
    // Boundary scan instruction coverage
    bs_instruction_cp: coverpoint current_transaction.instruction {
      bins extest = {EXTEST};
      bins intest = {INTEST};
      bins sample_preload = {SAMPLE_PRELOAD};
      bins clamp = {CLAMP};
      bins highz = {HIGHZ};
    }
    
    // Boundary scan cell coverage
    bs_cell_type_cp: coverpoint current_transaction.boundary_cell_type {
      bins input_cell = {BC_INPUT};
      bins output_cell = {BC_OUTPUT};
      bins bidirectional_cell = {BC_BIDIR};
      bins control_cell = {BC_CONTROL};
      bins internal_cell = {BC_INTERNAL};
    }
    
    // Boundary scan operation coverage
    bs_operation_cp: coverpoint current_transaction.boundary_operation {
      bins capture = {BS_CAPTURE};
      bins shift = {BS_SHIFT};
      bins update = {BS_UPDATE};
      bins preload = {BS_PRELOAD};
    }
    
    // Cross coverage: instruction vs operation
    bs_instr_x_operation: cross bs_instruction_cp, bs_operation_cp;
  endgroup
  
  covergroup jtag_debug_cg;
    option.per_instance = 1;
    option.name = "jtag_debug_coverage";
    
    // Debug instruction coverage
    debug_instruction_cp: coverpoint current_transaction.instruction {
      bins debug_enter = {DEBUG_ENTER};
      bins debug_exit = {DEBUG_EXIT};
      bins debug_read = {DEBUG_READ};
      bins debug_write = {DEBUG_WRITE};
      bins debug_halt = {DEBUG_HALT};
      bins debug_resume = {DEBUG_RESUME};
    }
    
    // Debug register coverage
    debug_register_cp: coverpoint current_transaction.debug_register {
      bins control_reg = {DBG_CTRL};
      bins status_reg = {DBG_STATUS};
      bins data_reg = {DBG_DATA};
      bins address_reg = {DBG_ADDR};
      bins breakpoint_reg = {DBG_BREAKPOINT};
    }
    
    // Debug operation coverage
    debug_operation_cp: coverpoint current_transaction.debug_operation {
      bins read_operation = {DBG_READ};
      bins write_operation = {DBG_WRITE};
      bins halt_operation = {DBG_HALT};
      bins resume_operation = {DBG_RESUME};
      bins step_operation = {DBG_STEP};
    }
    
    // Cross coverage: instruction vs register vs operation
    debug_instr_x_reg_x_op: cross debug_instruction_cp, debug_register_cp, debug_operation_cp;
  endgroup
  
  covergroup jtag_error_injection_cg;
    option.per_instance = 1;
    option.name = "jtag_error_injection_coverage";
    
    // Error type coverage
    error_type_cp: coverpoint current_transaction.error_type {
      bins no_error = {NO_ERROR};
      bins timing_error = {TIMING_ERROR};
      bins protocol_error = {PROTOCOL_ERROR};
      bins data_error = {DATA_ERROR};
      bins state_error = {STATE_ERROR};
      bins instruction_error = {INSTRUCTION_ERROR};
    }
    
    // Error severity coverage
    error_severity_cp: coverpoint current_transaction.error_severity {
      bins info = {ERROR_INFO};
      bins warning = {ERROR_WARNING};
      bins error = {ERROR_ERROR};
      bins fatal = {ERROR_FATAL};
    }
    
    // Error injection phase coverage
    error_phase_cp: coverpoint current_transaction.error_injection_phase {
      bins setup_phase = {ERR_SETUP};
      bins hold_phase = {ERR_HOLD};
      bins clock_phase = {ERR_CLOCK};
      bins data_phase = {ERR_DATA};
      bins state_phase = {ERR_STATE};
    }
    
    // Cross coverage: error type vs severity vs phase
    error_type_x_severity_x_phase: cross error_type_cp, error_severity_cp, error_phase_cp;
  endgroup
  
  covergroup jtag_compliance_cg;
    option.per_instance = 1;
    option.name = "jtag_compliance_coverage";
    
    // IEEE standard compliance coverage
    ieee_standard_cp: coverpoint current_transaction.ieee_standard {
      bins ieee_1149_1 = {IEEE_1149_1};
      bins ieee_1149_4 = {IEEE_1149_4};
      bins ieee_1149_6 = {IEEE_1149_6};
      bins ieee_1149_7 = {IEEE_1149_7};
    }
    
    // Compliance test type coverage
    compliance_test_cp: coverpoint current_transaction.compliance_test_type {
      bins mandatory_instruction_test = {COMP_MANDATORY_INSTR};
      bins optional_instruction_test = {COMP_OPTIONAL_INSTR};
      bins state_machine_test = {COMP_STATE_MACHINE};
      bins timing_test = {COMP_TIMING};
      bins boundary_scan_test = {COMP_BOUNDARY_SCAN};
      bins debug_test = {COMP_DEBUG};
    }
    
    // Compliance result coverage
    compliance_result_cp: coverpoint current_transaction.compliance_result {
      bins pass = {COMP_PASS};
      bins fail = {COMP_FAIL};
      bins warning = {COMP_WARNING};
      bins not_applicable = {COMP_NA};
    }
    
    // Cross coverage: standard vs test type vs result
    standard_x_test_x_result: cross ieee_standard_cp, compliance_test_cp, compliance_result_cp;
  endgroup
  
  // Transaction storage
  jtag_base_transaction current_transaction;
  
  // Coverage statistics
  int total_transactions;
  int instruction_hits;
  int state_transition_hits;
  int data_pattern_hits;
  int timing_hits;
  int boundary_scan_hits;
  int debug_hits;
  int error_injection_hits;
  int compliance_hits;
  
  function new(string name = "jtag_coverage_collector", uvm_component parent = null);
    super.new(name, parent);
    
    // Initialize coverage groups
    jtag_instruction_cg = new();
    jtag_state_machine_cg = new();
    jtag_data_patterns_cg = new();
    jtag_timing_cg = new();
    jtag_boundary_scan_cg = new();
    jtag_debug_cg = new();
    jtag_error_injection_cg = new();
    jtag_compliance_cg = new();
    
    // Initialize statistics
    total_transactions = 0;
    instruction_hits = 0;
    state_transition_hits = 0;
    data_pattern_hits = 0;
    timing_hits = 0;
    boundary_scan_hits = 0;
    debug_hits = 0;
    error_injection_hits = 0;
    compliance_hits = 0;
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration objects
    if(!uvm_config_db#(jtag_protocol_config)::get(this, "", "protocol_cfg", protocol_cfg)) begin
      `uvm_info("JTAG_COVERAGE_COLLECTOR", "Using default protocol configuration", UVM_LOW)
      protocol_cfg = jtag_protocol_config::type_id::create("protocol_cfg");
    end
    
    if(!uvm_config_db#(jtag_coverage_config)::get(this, "", "coverage_cfg", coverage_cfg)) begin
      `uvm_info("JTAG_COVERAGE_COLLECTOR", "Using default coverage configuration", UVM_LOW)
      coverage_cfg = jtag_coverage_config::type_id::create("coverage_cfg");
    end
  endfunction
  
  virtual function void write(jtag_base_transaction t);
    current_transaction = t;
    total_transactions++;
    
    // Sample coverage groups based on transaction type and configuration
    if (coverage_cfg.enable_instruction_coverage) begin
      jtag_instruction_cg.sample();
      instruction_hits++;
    end
    
    if (coverage_cfg.enable_state_coverage) begin
      jtag_state_machine_cg.sample();
      state_transition_hits++;
    end
    
    if (coverage_cfg.enable_data_coverage) begin
      jtag_data_patterns_cg.sample();
      data_pattern_hits++;
    end
    
    if (coverage_cfg.enable_timing_coverage) begin
      jtag_timing_cg.sample();
      timing_hits++;
    end
    
    if (coverage_cfg.enable_boundary_scan_coverage && is_boundary_scan_transaction(t)) begin
      jtag_boundary_scan_cg.sample();
      boundary_scan_hits++;
    end
    
    if (coverage_cfg.enable_debug_coverage && is_debug_transaction(t)) begin
      jtag_debug_cg.sample();
      debug_hits++;
    end
    
    if (coverage_cfg.enable_error_coverage && has_error_injection(t)) begin
      jtag_error_injection_cg.sample();
      error_injection_hits++;
    end
    
    if (coverage_cfg.enable_compliance_coverage && is_compliance_transaction(t)) begin
      jtag_compliance_cg.sample();
      compliance_hits++;
    end
    
    // Log coverage sampling
    `uvm_info("JTAG_COVERAGE_COLLECTOR", 
      $sformatf("Sampled coverage for transaction %0d (type: %s)", 
                t.transaction_id, t.trans_type.name()), UVM_HIGH)
  endfunction
  
  //=============================================================================
  // Helper Functions
  //=============================================================================
  
  virtual function bit is_boundary_scan_transaction(jtag_base_transaction t);
    return (t.instruction inside {EXTEST, INTEST, SAMPLE_PRELOAD, CLAMP, HIGHZ});
  endfunction
  
  virtual function bit is_debug_transaction(jtag_base_transaction t);
    return (t.instruction inside {DEBUG_ENTER, DEBUG_EXIT, DEBUG_READ, DEBUG_WRITE, DEBUG_HALT, DEBUG_RESUME});
  endfunction
  
  virtual function bit has_error_injection(jtag_base_transaction t);
    return (t.error_type != NO_ERROR);
  endfunction
  
  virtual function bit is_compliance_transaction(jtag_base_transaction t);
    return (t.trans_type == JTAG_COMPLIANCE);
  endfunction
  
  //=============================================================================
  // Coverage Reporting Functions
  //=============================================================================
  
  virtual function real get_instruction_coverage();
    return jtag_instruction_cg.get_inst_coverage();
  endfunction
  
  virtual function real get_state_machine_coverage();
    return jtag_state_machine_cg.get_inst_coverage();
  endfunction
  
  virtual function real get_data_patterns_coverage();
    return jtag_data_patterns_cg.get_inst_coverage();
  endfunction
  
  virtual function real get_timing_coverage();
    return jtag_timing_cg.get_inst_coverage();
  endfunction
  
  virtual function real get_boundary_scan_coverage();
    return jtag_boundary_scan_cg.get_inst_coverage();
  endfunction
  
  virtual function real get_debug_coverage();
    return jtag_debug_cg.get_inst_coverage();
  endfunction
  
  virtual function real get_error_injection_coverage();
    return jtag_error_injection_cg.get_inst_coverage();
  endfunction
  
  virtual function real get_compliance_coverage();
    return jtag_compliance_cg.get_inst_coverage();
  endfunction
  
  virtual function real get_overall_coverage();
    real total_coverage = 0.0;
    int coverage_groups = 0;
    
    if (coverage_cfg.enable_instruction_coverage) begin
      total_coverage += get_instruction_coverage();
      coverage_groups++;
    end
    
    if (coverage_cfg.enable_state_coverage) begin
      total_coverage += get_state_machine_coverage();
      coverage_groups++;
    end
    
    if (coverage_cfg.enable_data_coverage) begin
      total_coverage += get_data_patterns_coverage();
      coverage_groups++;
    end
    
    if (coverage_cfg.enable_timing_coverage) begin
      total_coverage += get_timing_coverage();
      coverage_groups++;
    end
    
    if (coverage_cfg.enable_boundary_scan_coverage) begin
      total_coverage += get_boundary_scan_coverage();
      coverage_groups++;
    end
    
    if (coverage_cfg.enable_debug_coverage) begin
      total_coverage += get_debug_coverage();
      coverage_groups++;
    end
    
    if (coverage_cfg.enable_error_coverage) begin
      total_coverage += get_error_injection_coverage();
      coverage_groups++;
    end
    
    if (coverage_cfg.enable_compliance_coverage) begin
      total_coverage += get_compliance_coverage();
      coverage_groups++;
    end
    
    return (coverage_groups > 0) ? (total_coverage / coverage_groups) : 0.0;
  endfunction
  
  virtual function void report_coverage_statistics();
    `uvm_info("JTAG_COVERAGE_COLLECTOR", "=== Coverage Statistics ===", UVM_LOW)
    `uvm_info("JTAG_COVERAGE_COLLECTOR", $sformatf("Total transactions: %0d", total_transactions), UVM_LOW)
    `uvm_info("JTAG_COVERAGE_COLLECTOR", $sformatf("Instruction coverage: %0.2f%%", get_instruction_coverage()), UVM_LOW)
    `uvm_info("JTAG_COVERAGE_COLLECTOR", $sformatf("State machine coverage: %0.2f%%", get_state_machine_coverage()), UVM_LOW)
    `uvm_info("JTAG_COVERAGE_COLLECTOR", $sformatf("Data patterns coverage: %0.2f%%", get_data_patterns_coverage()), UVM_LOW)
    `uvm_info("JTAG_COVERAGE_COLLECTOR", $sformatf("Timing coverage: %0.2f%%", get_timing_coverage()), UVM_LOW)
    `uvm_info("JTAG_COVERAGE_COLLECTOR", $sformatf("Boundary scan coverage: %0.2f%%", get_boundary_scan_coverage()), UVM_LOW)
    `uvm_info("JTAG_COVERAGE_COLLECTOR", $sformatf("Debug coverage: %0.2f%%", get_debug_coverage()), UVM_LOW)
    `uvm_info("JTAG_COVERAGE_COLLECTOR", $sformatf("Error injection coverage: %0.2f%%", get_error_injection_coverage()), UVM_LOW)
    `uvm_info("JTAG_COVERAGE_COLLECTOR", $sformatf("Compliance coverage: %0.2f%%", get_compliance_coverage()), UVM_LOW)
    `uvm_info("JTAG_COVERAGE_COLLECTOR", $sformatf("Overall coverage: %0.2f%%", get_overall_coverage()), UVM_LOW)
    `uvm_info("JTAG_COVERAGE_COLLECTOR", "=========================", UVM_LOW)
  endfunction
  
  virtual function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    report_coverage_statistics();
  endfunction
  
endclass

`endif // JTAG_COVERAGE_COLLECTOR_SVH