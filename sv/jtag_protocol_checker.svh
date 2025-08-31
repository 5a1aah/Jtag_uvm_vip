`ifndef JTAG_PROTOCOL_CHECKER_SVH
`define JTAG_PROTOCOL_CHECKER_SVH

//=============================================================================
// Enhanced JTAG Protocol Compliance Checker
// Comprehensive protocol validation for IEEE 1149.x standards
//=============================================================================

class jtag_protocol_checker extends uvm_component;
  `uvm_component_utils(jtag_protocol_checker)
  
  // Configuration objects
  jtag_protocol_config protocol_cfg;
  jtag_timing_config timing_cfg;
  jtag_error_config error_cfg;
  
  // Analysis ports for receiving transactions
  uvm_analysis_imp_rx #(jtag_base_transaction, jtag_protocol_checker) rx_analysis_imp;
  uvm_analysis_imp_tx #(jtag_base_transaction, jtag_protocol_checker) tx_analysis_imp;
  
  // Output ports for compliance violations
  uvm_analysis_port #(jtag_compliance_info_s) compliance_ap;
  uvm_analysis_port #(jtag_error_info_s) error_ap;
  
  // Protocol state tracking
  jtag_tap_state_e current_tap_state;
  jtag_tap_state_e previous_tap_state;
  jtag_instruction_e current_instruction;
  bit [31:0] instruction_register;
  bit [31:0] data_register;
  
  // Compliance tracking variables
  int ieee_1149_1_violations;
  int ieee_1149_4_violations;
  int ieee_1149_6_violations;
  int ieee_1149_7_violations;
  int timing_violations;
  int protocol_violations;
  
  // State machine validation
  bit [15:0] valid_state_transitions[jtag_tap_state_e];
  
  // Performance metrics
  real last_transaction_time;
  real total_check_time;
  int total_transactions_checked;
  
  function new(string name = "jtag_protocol_checker", uvm_component parent = null);
    super.new(name, parent);
    
    // Initialize state tracking
    current_tap_state = TEST_LOGIC_RESET;
    previous_tap_state = TEST_LOGIC_RESET;
    current_instruction = IDCODE;
    
    // Initialize violation counters
    ieee_1149_1_violations = 0;
    ieee_1149_4_violations = 0;
    ieee_1149_6_violations = 0;
    ieee_1149_7_violations = 0;
    timing_violations = 0;
    protocol_violations = 0;
    
    // Initialize performance metrics
    last_transaction_time = 0.0;
    total_check_time = 0.0;
    total_transactions_checked = 0;
    
    // Initialize valid state transitions
    initialize_state_machine();
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis ports
    rx_analysis_imp = new("rx_analysis_imp", this);
    tx_analysis_imp = new("tx_analysis_imp", this);
    compliance_ap = new("compliance_ap", this);
    error_ap = new("error_ap", this);
    
    // Get configuration objects
    if(!uvm_config_db#(jtag_protocol_config)::get(this, "", "protocol_cfg", protocol_cfg)) begin
      `uvm_info("JTAG_PROTOCOL_CHECKER", "Using default protocol configuration", UVM_LOW)
      protocol_cfg = jtag_protocol_config::type_id::create("protocol_cfg");
    end
    
    if(!uvm_config_db#(jtag_timing_config)::get(this, "", "timing_cfg", timing_cfg)) begin
      `uvm_info("JTAG_PROTOCOL_CHECKER", "Using default timing configuration", UVM_LOW)
      timing_cfg = jtag_timing_config::type_id::create("timing_cfg");
    end
    
    if(!uvm_config_db#(jtag_error_config)::get(this, "", "error_cfg", error_cfg)) begin
      `uvm_info("JTAG_PROTOCOL_CHECKER", "Using default error configuration", UVM_LOW)
      error_cfg = jtag_error_config::type_id::create("error_cfg");
    end
  endfunction
  
  // Write function for RX transactions
  virtual function void write_rx(jtag_base_transaction trans);
    if (protocol_cfg.enable_compliance_checking) begin
      check_protocol_compliance(trans, "RX");
    end
  endfunction
  
  // Write function for TX transactions
  virtual function void write_tx(jtag_base_transaction trans);
    if (protocol_cfg.enable_compliance_checking) begin
      check_protocol_compliance(trans, "TX");
    end
  endfunction
  
  //=============================================================================
  // Protocol Compliance Checking Functions
  //=============================================================================
  
  virtual function void check_protocol_compliance(jtag_base_transaction trans, string direction);
    real start_time, end_time;
    jtag_compliance_info_s compliance_info;
    jtag_error_info_s error_info;
    
    start_time = $realtime;
    
    // Initialize compliance info
    compliance_info.transaction_id = trans.transaction_id;
    compliance_info.timestamp = $realtime;
    compliance_info.compliance_level = protocol_cfg.compliance_level;
    compliance_info.standard_version = protocol_cfg.protocol_standard;
    compliance_info.is_compliant = 1;
    compliance_info.violation_count = 0;
    
    // Check based on transaction type
    case (trans.trans_type)
      JTAG_INSTRUCTION: check_instruction_compliance(trans, compliance_info, error_info);
      JTAG_DATA: check_data_compliance(trans, compliance_info, error_info);
      JTAG_RESET: check_reset_compliance(trans, compliance_info, error_info);
      JTAG_IDLE: check_idle_compliance(trans, compliance_info, error_info);
      JTAG_BOUNDARY_SCAN: check_boundary_scan_compliance(trans, compliance_info, error_info);
      JTAG_DEBUG: check_debug_compliance(trans, compliance_info, error_info);
      default: begin
        compliance_info.is_compliant = 0;
        compliance_info.violation_count++;
        error_info.error_type = PROTOCOL_ERROR;
        error_info.error_message = $sformatf("Unknown transaction type: %s", trans.trans_type.name());
      end
    endcase
    
    // Check state machine compliance
    check_state_machine_compliance(trans, compliance_info, error_info);
    
    // Check timing compliance if enabled
    if (protocol_cfg.enable_timing_checking) begin
      check_timing_compliance(trans, compliance_info, error_info);
    end
    
    // Check IEEE standard specific requirements
    check_ieee_standard_compliance(trans, compliance_info, error_info);
    
    // Update statistics
    total_transactions_checked++;
    end_time = $realtime;
    total_check_time += (end_time - start_time);
    
    // Send compliance information
    compliance_ap.write(compliance_info);
    
    // Send error information if violations found
    if (!compliance_info.is_compliant) begin
      error_ap.write(error_info);
      protocol_violations++;
    end
    
    // Log compliance status
    if (compliance_info.is_compliant) begin
      `uvm_info("JTAG_PROTOCOL_CHECKER", 
        $sformatf("%s transaction %0d: COMPLIANT", direction, trans.transaction_id), UVM_HIGH)
    end else begin
      `uvm_warning("JTAG_PROTOCOL_CHECKER", 
        $sformatf("%s transaction %0d: VIOLATION - %s", direction, trans.transaction_id, error_info.error_message))
    end
  endfunction
  
  virtual function void check_instruction_compliance(jtag_base_transaction trans, 
                                                    ref jtag_compliance_info_s compliance_info,
                                                    ref jtag_error_info_s error_info);
    // Check instruction register width
    if (trans.instruction_data.size() > MAX_INSTRUCTION_WIDTH) begin
      compliance_info.is_compliant = 0;
      compliance_info.violation_count++;
      error_info.error_type = PROTOCOL_ERROR;
      error_info.error_message = $sformatf("Instruction width %0d exceeds maximum %0d", 
                                          trans.instruction_data.size(), MAX_INSTRUCTION_WIDTH);
    end
    
    // Check for mandatory instructions (IEEE 1149.1)
    if (protocol_cfg.ieee_1149_1_mode) begin
      case (trans.instruction)
        BYPASS, IDCODE, SAMPLE_PRELOAD, EXTEST: begin
          // These are mandatory - always compliant
        end
        default: begin
          // Check if it's a valid optional instruction
          if (!is_valid_optional_instruction(trans.instruction)) begin
            compliance_info.is_compliant = 0;
            compliance_info.violation_count++;
            ieee_1149_1_violations++;
            error_info.error_type = PROTOCOL_ERROR;
            error_info.error_message = $sformatf("Invalid instruction: %s", trans.instruction.name());
          end
        end
      endcase
    end
    
    // Update current instruction
    current_instruction = trans.instruction;
  endfunction
  
  virtual function void check_data_compliance(jtag_base_transaction trans,
                                            ref jtag_compliance_info_s compliance_info,
                                            ref jtag_error_info_s error_info);
    // Check data register width
    if (trans.data_out.size() > MAX_DATA_WIDTH) begin
      compliance_info.is_compliant = 0;
      compliance_info.violation_count++;
      error_info.error_type = PROTOCOL_ERROR;
      error_info.error_message = $sformatf("Data width %0d exceeds maximum %0d", 
                                          trans.data_out.size(), MAX_DATA_WIDTH);
    end
    
    // Check data consistency with current instruction
    if (!is_data_consistent_with_instruction(trans)) begin
      compliance_info.is_compliant = 0;
      compliance_info.violation_count++;
      error_info.error_type = PROTOCOL_ERROR;
      error_info.error_message = "Data inconsistent with current instruction";
    end
  endfunction
  
  virtual function void check_reset_compliance(jtag_base_transaction trans,
                                             ref jtag_compliance_info_s compliance_info,
                                             ref jtag_error_info_s error_info);
    // Check reset timing requirements
    if (trans.reset_type == TRST_RESET) begin
      if (trans.reset_duration < timing_cfg.trst_pulse_width) begin
        compliance_info.is_compliant = 0;
        compliance_info.violation_count++;
        timing_violations++;
        error_info.error_type = TIMING_ERROR;
        error_info.error_message = $sformatf("TRST pulse width %0.2f ns < minimum %0.2f ns", 
                                            trans.reset_duration, timing_cfg.trst_pulse_width);
      end
    end
  endfunction
  
  virtual function void check_idle_compliance(jtag_base_transaction trans,
                                            ref jtag_compliance_info_s compliance_info,
                                            ref jtag_error_info_s error_info);
    // Check idle state requirements
    if (current_tap_state != RUN_TEST_IDLE) begin
      compliance_info.is_compliant = 0;
      compliance_info.violation_count++;
      error_info.error_type = PROTOCOL_ERROR;
      error_info.error_message = $sformatf("IDLE transaction in wrong TAP state: %s", current_tap_state.name());
    end
  endfunction
  
  virtual function void check_boundary_scan_compliance(jtag_base_transaction trans,
                                                     ref jtag_compliance_info_s compliance_info,
                                                     ref jtag_error_info_s error_info);
    // Check boundary scan chain length
    if (trans.boundary_data.size() > MAX_BOUNDARY_LENGTH) begin
      compliance_info.is_compliant = 0;
      compliance_info.violation_count++;
      error_info.error_type = PROTOCOL_ERROR;
      error_info.error_message = $sformatf("Boundary scan length %0d exceeds maximum %0d", 
                                          trans.boundary_data.size(), MAX_BOUNDARY_LENGTH);
    end
    
    // Check boundary scan instruction compatibility
    case (current_instruction)
      EXTEST, INTEST, SAMPLE_PRELOAD: begin
        // Valid boundary scan instructions
      end
      default: begin
        compliance_info.is_compliant = 0;
        compliance_info.violation_count++;
        error_info.error_type = PROTOCOL_ERROR;
        error_info.error_message = $sformatf("Boundary scan with invalid instruction: %s", current_instruction.name());
      end
    endcase
  endfunction
  
  virtual function void check_debug_compliance(jtag_base_transaction trans,
                                             ref jtag_compliance_info_s compliance_info,
                                             ref jtag_error_info_s error_info);
    // Check debug access permissions
    if (!protocol_cfg.enable_debug_access) begin
      compliance_info.is_compliant = 0;
      compliance_info.violation_count++;
      error_info.error_type = PROTOCOL_ERROR;
      error_info.error_message = "Debug access not enabled in protocol configuration";
    end
    
    // Check debug instruction validity
    case (trans.instruction)
      DEBUG_REQUEST, DEBUG_REGISTER_ACCESS, DEBUG_MEMORY_ACCESS: begin
        // Valid debug instructions
      end
      default: begin
        compliance_info.is_compliant = 0;
        compliance_info.violation_count++;
        error_info.error_type = PROTOCOL_ERROR;
        error_info.error_message = $sformatf("Invalid debug instruction: %s", trans.instruction.name());
      end
    endcase
  endfunction
  
  virtual function void check_state_machine_compliance(jtag_base_transaction trans,
                                                      ref jtag_compliance_info_s compliance_info,
                                                      ref jtag_error_info_s error_info);
    // Check if state transition is valid
    if (!is_valid_state_transition(previous_tap_state, trans.start_state)) begin
      compliance_info.is_compliant = 0;
      compliance_info.violation_count++;
      error_info.error_type = PROTOCOL_ERROR;
      error_info.error_message = $sformatf("Invalid state transition: %s -> %s", 
                                          previous_tap_state.name(), trans.start_state.name());
    end
    
    // Update state tracking
    previous_tap_state = current_tap_state;
    current_tap_state = trans.end_state;
  endfunction
  
  virtual function void check_timing_compliance(jtag_base_transaction trans,
                                              ref jtag_compliance_info_s compliance_info,
                                              ref jtag_error_info_s error_info);
    real transaction_duration;
    
    transaction_duration = trans.end_time - trans.start_time;
    
    // Check minimum transaction duration
    if (transaction_duration < timing_cfg.tck_period) begin
      compliance_info.is_compliant = 0;
      compliance_info.violation_count++;
      timing_violations++;
      error_info.error_type = TIMING_ERROR;
      error_info.error_message = $sformatf("Transaction duration %0.2f ns < TCK period %0.2f ns", 
                                          transaction_duration, timing_cfg.tck_period);
    end
    
    // Check setup and hold times
    if (trans.setup_time < timing_cfg.tsu_tdi) begin
      compliance_info.is_compliant = 0;
      compliance_info.violation_count++;
      timing_violations++;
      error_info.error_type = TIMING_ERROR;
      error_info.error_message = $sformatf("Setup time %0.2f ns < minimum %0.2f ns", 
                                          trans.setup_time, timing_cfg.tsu_tdi);
    end
    
    if (trans.hold_time < timing_cfg.th_tdi) begin
      compliance_info.is_compliant = 0;
      compliance_info.violation_count++;
      timing_violations++;
      error_info.error_type = TIMING_ERROR;
      error_info.error_message = $sformatf("Hold time %0.2f ns < minimum %0.2f ns", 
                                          trans.hold_time, timing_cfg.th_tdi);
    end
  endfunction
  
  virtual function void check_ieee_standard_compliance(jtag_base_transaction trans,
                                                      ref jtag_compliance_info_s compliance_info,
                                                      ref jtag_error_info_s error_info);
    // Check IEEE 1149.1 compliance
    if (protocol_cfg.ieee_1149_1_mode) begin
      check_ieee_1149_1_compliance(trans, compliance_info, error_info);
    end
    
    // Check IEEE 1149.4 compliance (mixed-signal)
    if (protocol_cfg.ieee_1149_4_mode) begin
      check_ieee_1149_4_compliance(trans, compliance_info, error_info);
    end
    
    // Check IEEE 1149.6 compliance (AC-coupled)
    if (protocol_cfg.ieee_1149_6_mode) begin
      check_ieee_1149_6_compliance(trans, compliance_info, error_info);
    end
    
    // Check IEEE 1149.7 compliance (reduced pin count)
    if (protocol_cfg.ieee_1149_7_mode) begin
      check_ieee_1149_7_compliance(trans, compliance_info, error_info);
    end
  endfunction
  
  //=============================================================================
  // IEEE Standard Specific Compliance Functions
  //=============================================================================
  
  virtual function void check_ieee_1149_1_compliance(jtag_base_transaction trans,
                                                    ref jtag_compliance_info_s compliance_info,
                                                    ref jtag_error_info_s error_info);
    // Check mandatory instruction support
    case (trans.instruction)
      BYPASS: begin
        if (trans.data_out.size() != 1) begin
          compliance_info.is_compliant = 0;
          compliance_info.violation_count++;
          ieee_1149_1_violations++;
          error_info.error_type = PROTOCOL_ERROR;
          error_info.error_message = "BYPASS instruction must have 1-bit data register";
        end
      end
      IDCODE: begin
        if (trans.data_out.size() != 32) begin
          compliance_info.is_compliant = 0;
          compliance_info.violation_count++;
          ieee_1149_1_violations++;
          error_info.error_type = PROTOCOL_ERROR;
          error_info.error_message = "IDCODE instruction must have 32-bit data register";
        end
      end
    endcase
  endfunction
  
  virtual function void check_ieee_1149_4_compliance(jtag_base_transaction trans,
                                                    ref jtag_compliance_info_s compliance_info,
                                                    ref jtag_error_info_s error_info);
    // Check mixed-signal specific requirements
    if (trans.trans_type == JTAG_ANALOG_TEST) begin
      // Verify analog test capabilities
      if (!protocol_cfg.enable_analog_test) begin
        compliance_info.is_compliant = 0;
        compliance_info.violation_count++;
        ieee_1149_4_violations++;
        error_info.error_type = PROTOCOL_ERROR;
        error_info.error_message = "Analog test not supported in current configuration";
      end
    end
  endfunction
  
  virtual function void check_ieee_1149_6_compliance(jtag_base_transaction trans,
                                                    ref jtag_compliance_info_s compliance_info,
                                                    ref jtag_error_info_s error_info);
    // Check AC-coupled specific requirements
    if (protocol_cfg.ac_coupling_mode) begin
      // Verify AC-coupled signal integrity
      if (trans.signal_integrity_check && !trans.ac_coupling_valid) begin
        compliance_info.is_compliant = 0;
        compliance_info.violation_count++;
        ieee_1149_6_violations++;
        error_info.error_type = SIGNAL_INTEGRITY_ERROR;
        error_info.error_message = "AC-coupled signal integrity violation";
      end
    end
  endfunction
  
  virtual function void check_ieee_1149_7_compliance(jtag_base_transaction trans,
                                                    ref jtag_compliance_info_s compliance_info,
                                                    ref jtag_error_info_s error_info);
    // Check reduced pin count specific requirements
    if (protocol_cfg.reduced_pin_mode) begin
      // Verify 2-pin operation
      if (trans.pin_count > 2) begin
        compliance_info.is_compliant = 0;
        compliance_info.violation_count++;
        ieee_1149_7_violations++;
        error_info.error_type = PROTOCOL_ERROR;
        error_info.error_message = $sformatf("Pin count %0d exceeds 2-pin limit for IEEE 1149.7", trans.pin_count);
      end
    end
  endfunction
  
  //=============================================================================
  // Utility Functions
  //=============================================================================
  
  virtual function void initialize_state_machine();
    // Initialize valid state transitions for TAP state machine
    valid_state_transitions[TEST_LOGIC_RESET] = 16'b0000_0000_0000_0011; // Can go to RUN_TEST_IDLE
    valid_state_transitions[RUN_TEST_IDLE] = 16'b0000_0000_0000_1101; // Can go to SELECT_DR_SCAN or stay
    valid_state_transitions[SELECT_DR_SCAN] = 16'b0000_0000_0011_0001; // Can go to CAPTURE_DR or SELECT_IR_SCAN
    valid_state_transitions[CAPTURE_DR] = 16'b0000_0000_0110_0000; // Can go to SHIFT_DR or EXIT1_DR
    valid_state_transitions[SHIFT_DR] = 16'b0000_0000_1100_0000; // Can go to EXIT1_DR or stay
    valid_state_transitions[EXIT1_DR] = 16'b0000_0011_1000_0000; // Can go to PAUSE_DR or UPDATE_DR
    valid_state_transitions[PAUSE_DR] = 16'b0000_0110_0000_0000; // Can go to EXIT2_DR or stay
    valid_state_transitions[EXIT2_DR] = 16'b0000_1100_0000_0000; // Can go to SHIFT_DR or UPDATE_DR
    valid_state_transitions[UPDATE_DR] = 16'b0000_0000_0000_1101; // Can go to SELECT_DR_SCAN or RUN_TEST_IDLE
    valid_state_transitions[SELECT_IR_SCAN] = 16'b0011_0000_0000_0001; // Can go to CAPTURE_IR or TEST_LOGIC_RESET
    valid_state_transitions[CAPTURE_IR] = 16'b0110_0000_0000_0000; // Can go to SHIFT_IR or EXIT1_IR
    valid_state_transitions[SHIFT_IR] = 16'b1100_0000_0000_0000; // Can go to EXIT1_IR or stay
    valid_state_transitions[EXIT1_IR] = 16'b0011_0000_0000_0000; // Can go to PAUSE_IR or UPDATE_IR
    valid_state_transitions[PAUSE_IR] = 16'b0110_0000_0000_0000; // Can go to EXIT2_IR or stay
    valid_state_transitions[EXIT2_IR] = 16'b1100_0000_0000_0000; // Can go to SHIFT_IR or UPDATE_IR
    valid_state_transitions[UPDATE_IR] = 16'b0000_0000_0000_1101; // Can go to SELECT_DR_SCAN or RUN_TEST_IDLE
  endfunction
  
  virtual function bit is_valid_state_transition(jtag_tap_state_e from_state, jtag_tap_state_e to_state);
    return valid_state_transitions[from_state][to_state];
  endfunction
  
  virtual function bit is_valid_optional_instruction(jtag_instruction_e instruction);
    case (instruction)
      INTEST, RUNBIST, CLAMP, HIGHZ, USERCODE: return 1;
      DEBUG_REQUEST, DEBUG_REGISTER_ACCESS, DEBUG_MEMORY_ACCESS: return protocol_cfg.enable_debug_access;
      ANALOG_TEST: return protocol_cfg.enable_analog_test;
      default: return 0;
    endcase
  endfunction
  
  virtual function bit is_data_consistent_with_instruction(jtag_base_transaction trans);
    case (current_instruction)
      BYPASS: return (trans.data_out.size() == 1);
      IDCODE: return (trans.data_out.size() == 32);
      SAMPLE_PRELOAD, EXTEST, INTEST: return (trans.data_out.size() == trans.boundary_data.size());
      default: return 1; // Assume consistent for unknown instructions
    endcase
  endfunction
  
  //=============================================================================
  // Reporting Functions
  //=============================================================================
  
  virtual function void report_compliance_statistics();
    real average_check_time;
    
    if (total_transactions_checked > 0) begin
      average_check_time = total_check_time / total_transactions_checked;
    end else begin
      average_check_time = 0.0;
    end
    
    `uvm_info("JTAG_PROTOCOL_CHECKER", "=== Compliance Statistics ===", UVM_LOW)
    `uvm_info("JTAG_PROTOCOL_CHECKER", $sformatf("Total transactions checked: %0d", total_transactions_checked), UVM_LOW)
    `uvm_info("JTAG_PROTOCOL_CHECKER", $sformatf("Total protocol violations: %0d", protocol_violations), UVM_LOW)
    `uvm_info("JTAG_PROTOCOL_CHECKER", $sformatf("IEEE 1149.1 violations: %0d", ieee_1149_1_violations), UVM_LOW)
    `uvm_info("JTAG_PROTOCOL_CHECKER", $sformatf("IEEE 1149.4 violations: %0d", ieee_1149_4_violations), UVM_LOW)
    `uvm_info("JTAG_PROTOCOL_CHECKER", $sformatf("IEEE 1149.6 violations: %0d", ieee_1149_6_violations), UVM_LOW)
    `uvm_info("JTAG_PROTOCOL_CHECKER", $sformatf("IEEE 1149.7 violations: %0d", ieee_1149_7_violations), UVM_LOW)
    `uvm_info("JTAG_PROTOCOL_CHECKER", $sformatf("Timing violations: %0d", timing_violations), UVM_LOW)
    `uvm_info("JTAG_PROTOCOL_CHECKER", $sformatf("Average check time: %0.2f ns", average_check_time), UVM_LOW)
    `uvm_info("JTAG_PROTOCOL_CHECKER", "==============================", UVM_LOW)
  endfunction
  
  virtual function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    report_compliance_statistics();
  endfunction
  
endclass

`endif // JTAG_PROTOCOL_CHECKER_SVH