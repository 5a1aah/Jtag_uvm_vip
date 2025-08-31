`ifndef JTAG_ERROR_INJECTOR__SVH
 `define JTAG_ERROR_INJECTOR__SVH

//=============================================================================
// JTAG Error Injector
// Systematic error injection component for robustness testing
//=============================================================================

class jtag_error_injector extends uvm_component;
  
  // Analysis imports for receiving transactions
  uvm_analysis_imp_rx #(jtag_sequence_item, jtag_error_injector) rx_analysis_imp;
  uvm_analysis_imp_tx #(jtag_sequence_item, jtag_error_injector) tx_analysis_imp;
  
  // Analysis ports for sending modified transactions
  uvm_analysis_port #(jtag_sequence_item) error_injected_ap;
  uvm_analysis_port #(jtag_error_report) error_report_ap;
  
  // Configuration objects
  jtag_error_config error_cfg;
  jtag_protocol_config protocol_cfg;
  jtag_timing_config timing_cfg;
  
  // Error injection control
  bit error_injection_enabled;
  bit systematic_error_mode;
  bit random_error_mode;
  int unsigned error_injection_rate; // Percentage (0-100)
  int unsigned current_transaction_count;
  
  // Error types and patterns
  typedef enum {
    ERR_NONE,
    ERR_BIT_FLIP,
    ERR_STUCK_AT_0,
    ERR_STUCK_AT_1,
    ERR_TIMING_VIOLATION,
    ERR_PROTOCOL_VIOLATION,
    ERR_INSTRUCTION_CORRUPTION,
    ERR_DATA_CORRUPTION,
    ERR_STATE_MACHINE_ERROR,
    ERR_CLOCK_GLITCH,
    ERR_RESET_ANOMALY,
    ERR_BOUNDARY_SCAN_ERROR,
    ERR_DEBUG_ACCESS_ERROR,
    ERR_COMPLIANCE_VIOLATION
  } error_type_e;
  
  // Error injection statistics
  int unsigned total_transactions_processed;
  int unsigned total_errors_injected;
  int unsigned errors_by_type[error_type_e];
  int unsigned errors_by_phase[string];
  
  // Error patterns and sequences
  error_type_e error_sequence[$];
  int unsigned error_sequence_index;
  bit [31:0] error_pattern_mask;
  
  // Timing error parameters
  time setup_violation_delay;
  time hold_violation_delay;
  time clock_jitter_amount;
  
  // Random number generator
  int unsigned random_seed;
  
  `uvm_component_utils_begin(jtag_error_injector)
  `uvm_field_int(error_injection_enabled, UVM_DEFAULT)
  `uvm_field_int(error_injection_rate, UVM_DEFAULT)
  `uvm_field_int(total_errors_injected, UVM_DEFAULT)
  `uvm_component_utils_end
  
  //=============================================================================
  // Constructor and Build Phase
  //=============================================================================
  
  function new(string name = "jtag_error_injector", uvm_component parent = null);
    super.new(name, parent);
    
    // Initialize error injection parameters
    error_injection_enabled = 0;
    systematic_error_mode = 0;
    random_error_mode = 1;
    error_injection_rate = 5; // 5% default error rate
    current_transaction_count = 0;
    
    // Initialize statistics
    total_transactions_processed = 0;
    total_errors_injected = 0;
    error_sequence_index = 0;
    
    // Initialize timing parameters
    setup_violation_delay = 100ps;
    hold_violation_delay = 50ps;
    clock_jitter_amount = 200ps;
    
    // Initialize random seed
    random_seed = $urandom();
    
    // Initialize error pattern mask
    error_pattern_mask = 32'h00000000;
    
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis imports and ports
    rx_analysis_imp = new("rx_analysis_imp", this);
    tx_analysis_imp = new("tx_analysis_imp", this);
    error_injected_ap = new("error_injected_ap", this);
    error_report_ap = new("error_report_ap", this);
    
    // Get configuration objects
    if(!uvm_config_db#(jtag_error_config)::get(this, "", "error_cfg", error_cfg)) begin
      `uvm_info("JTAG_ERR_INJ_INFO", "Creating default error configuration", UVM_LOW)
      error_cfg = jtag_error_config::type_id::create("error_cfg");
    end
    
    if(!uvm_config_db#(jtag_protocol_config)::get(this, "", "protocol_cfg", protocol_cfg)) begin
      `uvm_info("JTAG_ERR_INJ_INFO", "Creating default protocol configuration", UVM_LOW)
      protocol_cfg = jtag_protocol_config::type_id::create("protocol_cfg");
    end
    
    if(!uvm_config_db#(jtag_timing_config)::get(this, "", "timing_cfg", timing_cfg)) begin
      `uvm_info("JTAG_ERR_INJ_INFO", "Creating default timing configuration", UVM_LOW)
      timing_cfg = jtag_timing_config::type_id::create("timing_cfg");
    end
    
    // Configure error injection based on configuration
    configure_error_injection();
    
  endfunction
  
  virtual function void configure_error_injection();
    
    // Set error injection parameters from configuration
    error_injection_enabled = error_cfg.enable_error_injection;
    error_injection_rate = error_cfg.error_injection_rate;
    systematic_error_mode = error_cfg.systematic_error_mode;
    random_error_mode = !systematic_error_mode;
    
    // Configure timing error parameters
    setup_violation_delay = timing_cfg.setup_time / 2; // Half of setup time for violation
    hold_violation_delay = timing_cfg.hold_time / 2;   // Half of hold time for violation
    clock_jitter_amount = timing_cfg.clock_period / 20; // 5% of clock period
    
    // Initialize error sequence for systematic mode
    if (systematic_error_mode) begin
      setup_systematic_error_sequence();
    end
    
    `uvm_info("JTAG_ERR_INJ_CONFIG", $sformatf("Error injection configured: enabled=%0b, rate=%0d%%, mode=%s", 
                                               error_injection_enabled, error_injection_rate,
                                               systematic_error_mode ? "systematic" : "random"), UVM_LOW)
    
  endfunction
  
  virtual function void setup_systematic_error_sequence();
    // Define a systematic sequence of errors to inject
    error_sequence.delete();
    
    // Add different error types in a systematic pattern
    error_sequence.push_back(ERR_BIT_FLIP);
    error_sequence.push_back(ERR_INSTRUCTION_CORRUPTION);
    error_sequence.push_back(ERR_DATA_CORRUPTION);
    error_sequence.push_back(ERR_TIMING_VIOLATION);
    error_sequence.push_back(ERR_PROTOCOL_VIOLATION);
    error_sequence.push_back(ERR_STATE_MACHINE_ERROR);
    error_sequence.push_back(ERR_CLOCK_GLITCH);
    error_sequence.push_back(ERR_BOUNDARY_SCAN_ERROR);
    error_sequence.push_back(ERR_DEBUG_ACCESS_ERROR);
    error_sequence.push_back(ERR_COMPLIANCE_VIOLATION);
    
    error_sequence_index = 0;
    
    `uvm_info("JTAG_ERR_INJ_SEQ", $sformatf("Systematic error sequence setup with %0d error types", 
                                           error_sequence.size()), UVM_LOW)
    
  endfunction
  
  //=============================================================================
  // Analysis Import Write Functions
  //=============================================================================
  
  virtual function void write_rx(jtag_sequence_item t);
    jtag_sequence_item modified_item;
    jtag_error_report error_report;
    
    total_transactions_processed++;
    current_transaction_count++;
    
    // Clone the transaction
    $cast(modified_item, t.clone());
    
    // Decide whether to inject an error
    if (should_inject_error()) begin
      error_type_e error_type = select_error_type();
      inject_error(modified_item, error_type, "RX");
      
      // Create error report
      error_report = create_error_report(modified_item, error_type, "RX");
      error_report_ap.write(error_report);
      
      total_errors_injected++;
      errors_by_type[error_type]++;
      errors_by_phase["RX"]++;
      
      `uvm_info("JTAG_ERR_INJ_RX", $sformatf("Injected %s error in RX transaction #%0d", 
                                             error_type.name(), total_transactions_processed), UVM_MEDIUM)
    end
    
    // Send the (possibly modified) transaction
    error_injected_ap.write(modified_item);
    
  endfunction
  
  virtual function void write_tx(jtag_sequence_item t);
    jtag_sequence_item modified_item;
    jtag_error_report error_report;
    
    total_transactions_processed++;
    current_transaction_count++;
    
    // Clone the transaction
    $cast(modified_item, t.clone());
    
    // Decide whether to inject an error
    if (should_inject_error()) begin
      error_type_e error_type = select_error_type();
      inject_error(modified_item, error_type, "TX");
      
      // Create error report
      error_report = create_error_report(modified_item, error_type, "TX");
      error_report_ap.write(error_report);
      
      total_errors_injected++;
      errors_by_type[error_type]++;
      errors_by_phase["TX"]++;
      
      `uvm_info("JTAG_ERR_INJ_TX", $sformatf("Injected %s error in TX transaction #%0d", 
                                             error_type.name(), total_transactions_processed), UVM_MEDIUM)
    end
    
    // Send the (possibly modified) transaction
    error_injected_ap.write(modified_item);
    
  endfunction
  
  //=============================================================================
  // Error Injection Logic
  //=============================================================================
  
  virtual function bit should_inject_error();
    bit inject = 0;
    
    if (!error_injection_enabled) return 0;
    
    if (random_error_mode) begin
      // Random error injection based on rate
      int random_val = $urandom_range(0, 99);
      inject = (random_val < error_injection_rate);
    end else if (systematic_error_mode) begin
      // Systematic error injection based on transaction count
      inject = (current_transaction_count % (100 / error_injection_rate) == 0);
    end
    
    return inject;
  endfunction
  
  virtual function error_type_e select_error_type();
    error_type_e selected_error;
    
    if (systematic_error_mode && error_sequence.size() > 0) begin
      // Select from systematic sequence
      selected_error = error_sequence[error_sequence_index];
      error_sequence_index = (error_sequence_index + 1) % error_sequence.size();
    end else begin
      // Random selection
      int error_index = $urandom_range(1, 13); // Skip ERR_NONE
      selected_error = error_type_e'(error_index);
    end
    
    return selected_error;
  endfunction
  
  virtual function void inject_error(jtag_sequence_item item, error_type_e error_type, string phase);
    
    case (error_type)
      ERR_BIT_FLIP: inject_bit_flip_error(item);
      ERR_STUCK_AT_0: inject_stuck_at_error(item, 0);
      ERR_STUCK_AT_1: inject_stuck_at_error(item, 1);
      ERR_TIMING_VIOLATION: inject_timing_violation(item);
      ERR_PROTOCOL_VIOLATION: inject_protocol_violation(item);
      ERR_INSTRUCTION_CORRUPTION: inject_instruction_corruption(item);
      ERR_DATA_CORRUPTION: inject_data_corruption(item);
      ERR_STATE_MACHINE_ERROR: inject_state_machine_error(item);
      ERR_CLOCK_GLITCH: inject_clock_glitch(item);
      ERR_RESET_ANOMALY: inject_reset_anomaly(item);
      ERR_BOUNDARY_SCAN_ERROR: inject_boundary_scan_error(item);
      ERR_DEBUG_ACCESS_ERROR: inject_debug_access_error(item);
      ERR_COMPLIANCE_VIOLATION: inject_compliance_violation(item);
      default: `uvm_warning("JTAG_ERR_INJ_WARN", $sformatf("Unknown error type: %s", error_type.name()))
    endcase
    
    // Mark the item as having an injected error
    item.has_error = 1;
    item.error_type = error_type.name();
    item.error_injection_time = $time;
    
  endfunction
  
  virtual function void inject_bit_flip_error(jtag_sequence_item item);
    int bit_position;
    
    // Randomly select a bit position to flip
    if (item.trans_kind == JTAG_INSTRUCTION_TRANS) begin
      bit_position = $urandom_range(0, 31);
      item.instruction[bit_position] = ~item.instruction[bit_position];
      `uvm_info("JTAG_ERR_INJ_BIT", $sformatf("Flipped bit %0d in instruction", bit_position), UVM_HIGH)
    end else if (item.trans_kind == JTAG_DATA_TRANS) begin
      bit_position = $urandom_range(0, 31);
      item.data[bit_position] = ~item.data[bit_position];
      `uvm_info("JTAG_ERR_INJ_BIT", $sformatf("Flipped bit %0d in data", bit_position), UVM_HIGH)
    end
    
  endfunction
  
  virtual function void inject_stuck_at_error(jtag_sequence_item item, bit stuck_value);
    int bit_position;
    
    // Randomly select a bit position to stick
    if (item.trans_kind == JTAG_INSTRUCTION_TRANS) begin
      bit_position = $urandom_range(0, 31);
      item.instruction[bit_position] = stuck_value;
      `uvm_info("JTAG_ERR_INJ_STUCK", $sformatf("Stuck bit %0d at %0d in instruction", bit_position, stuck_value), UVM_HIGH)
    end else if (item.trans_kind == JTAG_DATA_TRANS) begin
      bit_position = $urandom_range(0, 31);
      item.data[bit_position] = stuck_value;
      `uvm_info("JTAG_ERR_INJ_STUCK", $sformatf("Stuck bit %0d at %0d in data", bit_position, stuck_value), UVM_HIGH)
    end
    
  endfunction
  
  virtual function void inject_timing_violation(jtag_sequence_item item);
    // Inject timing violations by modifying timing parameters
    case ($urandom_range(0, 2))
      0: begin // Setup time violation
        item.setup_time = setup_violation_delay;
        `uvm_info("JTAG_ERR_INJ_TIMING", "Injected setup time violation", UVM_HIGH)
      end
      1: begin // Hold time violation
        item.hold_time = hold_violation_delay;
        `uvm_info("JTAG_ERR_INJ_TIMING", "Injected hold time violation", UVM_HIGH)
      end
      2: begin // Clock jitter
        item.clock_jitter = clock_jitter_amount;
        `uvm_info("JTAG_ERR_INJ_TIMING", "Injected clock jitter", UVM_HIGH)
      end
    endcase
    
  endfunction
  
  virtual function void inject_protocol_violation(jtag_sequence_item item);
    // Inject protocol violations
    case ($urandom_range(0, 2))
      0: begin // Invalid state transition
        item.tap_state = jtag_tap_state_e'($urandom_range(0, 15));
        `uvm_info("JTAG_ERR_INJ_PROTOCOL", "Injected invalid TAP state", UVM_HIGH)
      end
      1: begin // Invalid TMS sequence
        item.tms_sequence = $urandom();
        `uvm_info("JTAG_ERR_INJ_PROTOCOL", "Injected invalid TMS sequence", UVM_HIGH)
      end
      2: begin // Invalid transaction length
        item.length = $urandom_range(1, 128); // Random length
        `uvm_info("JTAG_ERR_INJ_PROTOCOL", "Injected invalid transaction length", UVM_HIGH)
      end
    endcase
    
  endfunction
  
  virtual function void inject_instruction_corruption(jtag_sequence_item item);
    // Corrupt instruction with invalid values
    case ($urandom_range(0, 2))
      0: item.instruction = 32'hDEADBEEF; // Invalid instruction
      1: item.instruction = 32'hFFFFFFFF; // All ones
      2: item.instruction = $urandom();    // Random value
    endcase
    
    `uvm_info("JTAG_ERR_INJ_INSTR", $sformatf("Corrupted instruction to %h", item.instruction), UVM_HIGH)
    
  endfunction
  
  virtual function void inject_data_corruption(jtag_sequence_item item);
    // Corrupt data with various patterns
    case ($urandom_range(0, 3))
      0: item.data = 32'h00000000;     // All zeros
      1: item.data = 32'hFFFFFFFF;     // All ones
      2: item.data = 32'hAAAAAAAA;     // Alternating pattern
      3: item.data = $urandom();       // Random value
    endcase
    
    `uvm_info("JTAG_ERR_INJ_DATA", $sformatf("Corrupted data to %h", item.data), UVM_HIGH)
    
  endfunction
  
  virtual function void inject_state_machine_error(jtag_sequence_item item);
    // Force invalid state machine transitions
    jtag_tap_state_e invalid_states[] = '{TAP_TEST_LOGIC_RESET, TAP_RUN_TEST_IDLE};
    
    item.tap_state = invalid_states[$urandom_range(0, invalid_states.size()-1)];
    item.next_tap_state = invalid_states[$urandom_range(0, invalid_states.size()-1)];
    
    `uvm_info("JTAG_ERR_INJ_STATE", $sformatf("Injected invalid state transition: %s -> %s", 
                                              item.tap_state.name(), item.next_tap_state.name()), UVM_HIGH)
    
  endfunction
  
  virtual function void inject_clock_glitch(jtag_sequence_item item);
    // Inject clock glitches by modifying clock parameters
    item.clock_glitch_count = $urandom_range(1, 5);
    item.clock_glitch_duration = $urandom_range(100ps, 1ns);
    
    `uvm_info("JTAG_ERR_INJ_CLOCK", $sformatf("Injected %0d clock glitches of %0t duration", 
                                              item.clock_glitch_count, item.clock_glitch_duration), UVM_HIGH)
    
  endfunction
  
  virtual function void inject_reset_anomaly(jtag_sequence_item item);
    // Inject reset-related errors
    case ($urandom_range(0, 1))
      0: begin // Premature reset release
        item.reset_duration = timing_cfg.reset_duration / 4;
        `uvm_info("JTAG_ERR_INJ_RESET", "Injected premature reset release", UVM_HIGH)
      end
      1: begin // Extended reset
        item.reset_duration = timing_cfg.reset_duration * 4;
        `uvm_info("JTAG_ERR_INJ_RESET", "Injected extended reset duration", UVM_HIGH)
      end
    endcase
    
  endfunction
  
  virtual function void inject_boundary_scan_error(jtag_sequence_item item);
    // Inject boundary scan specific errors
    if (item.trans_kind == JTAG_BOUNDARY_SCAN_TRANS) begin
      case ($urandom_range(0, 2))
        0: begin // Invalid boundary scan instruction
          item.boundary_scan_instruction = boundary_scan_instr_e'($urandom_range(0, 7));
          `uvm_info("JTAG_ERR_INJ_BS", "Injected invalid boundary scan instruction", UVM_HIGH)
        end
        1: begin // Corrupt boundary scan data
          item.boundary_scan_data = $urandom();
          `uvm_info("JTAG_ERR_INJ_BS", "Corrupted boundary scan data", UVM_HIGH)
        end
        2: begin // Invalid cell count
          item.boundary_scan_cell_count = $urandom_range(1, 1024);
          `uvm_info("JTAG_ERR_INJ_BS", "Injected invalid boundary scan cell count", UVM_HIGH)
        end
      endcase
    end
    
  endfunction
  
  virtual function void inject_debug_access_error(jtag_sequence_item item);
    // Inject debug access specific errors
    if (item.trans_kind == JTAG_DEBUG_TRANS) begin
      case ($urandom_range(0, 2))
        0: begin // Invalid debug register
          item.debug_register = debug_register_e'($urandom_range(0, 15));
          `uvm_info("JTAG_ERR_INJ_DEBUG", "Injected invalid debug register", UVM_HIGH)
        end
        1: begin // Corrupt debug data
          item.debug_data = $urandom();
          `uvm_info("JTAG_ERR_INJ_DEBUG", "Corrupted debug data", UVM_HIGH)
        end
        2: begin // Invalid debug operation
          item.debug_operation = debug_operation_e'($urandom_range(0, 7));
          `uvm_info("JTAG_ERR_INJ_DEBUG", "Injected invalid debug operation", UVM_HIGH)
        end
      endcase
    end
    
  endfunction
  
  virtual function void inject_compliance_violation(jtag_sequence_item item);
    // Inject IEEE compliance violations
    case ($urandom_range(0, 2))
      0: begin // Violate IEEE 1149.1 timing
        item.ieee_1149_1_compliant = 0;
        `uvm_info("JTAG_ERR_INJ_COMP", "Injected IEEE 1149.1 compliance violation", UVM_HIGH)
      end
      1: begin // Violate IEEE 1149.4 requirements
        item.ieee_1149_4_compliant = 0;
        `uvm_info("JTAG_ERR_INJ_COMP", "Injected IEEE 1149.4 compliance violation", UVM_HIGH)
      end
      2: begin // Violate IEEE 1149.6 requirements
        item.ieee_1149_6_compliant = 0;
        `uvm_info("JTAG_ERR_INJ_COMP", "Injected IEEE 1149.6 compliance violation", UVM_HIGH)
      end
    endcase
    
  endfunction
  
  //=============================================================================
  // Error Reporting
  //=============================================================================
  
  virtual function jtag_error_report create_error_report(jtag_sequence_item item, error_type_e error_type, string phase);
    jtag_error_report report;
    
    report = jtag_error_report::type_id::create("error_report");
    
    report.error_type = error_type.name();
    report.error_phase = phase;
    report.error_time = $time;
    report.transaction_id = item.get_inst_id();
    report.error_description = get_error_description(error_type);
    report.severity = get_error_severity(error_type);
    report.original_item = item;
    
    return report;
  endfunction
  
  virtual function string get_error_description(error_type_e error_type);
    case (error_type)
      ERR_BIT_FLIP: return "Single bit flip in data or instruction";
      ERR_STUCK_AT_0: return "Bit stuck at logic 0";
      ERR_STUCK_AT_1: return "Bit stuck at logic 1";
      ERR_TIMING_VIOLATION: return "Setup/hold time violation";
      ERR_PROTOCOL_VIOLATION: return "JTAG protocol violation";
      ERR_INSTRUCTION_CORRUPTION: return "Instruction corruption";
      ERR_DATA_CORRUPTION: return "Data corruption";
      ERR_STATE_MACHINE_ERROR: return "TAP state machine error";
      ERR_CLOCK_GLITCH: return "Clock signal glitch";
      ERR_RESET_ANOMALY: return "Reset signal anomaly";
      ERR_BOUNDARY_SCAN_ERROR: return "Boundary scan operation error";
      ERR_DEBUG_ACCESS_ERROR: return "Debug access error";
      ERR_COMPLIANCE_VIOLATION: return "IEEE standard compliance violation";
      default: return "Unknown error type";
    endcase
  endfunction
  
  virtual function uvm_severity get_error_severity(error_type_e error_type);
    case (error_type)
      ERR_BIT_FLIP, ERR_DATA_CORRUPTION: return UVM_LOW;
      ERR_STUCK_AT_0, ERR_STUCK_AT_1, ERR_INSTRUCTION_CORRUPTION: return UVM_MEDIUM;
      ERR_TIMING_VIOLATION, ERR_PROTOCOL_VIOLATION, ERR_STATE_MACHINE_ERROR: return UVM_HIGH;
      ERR_CLOCK_GLITCH, ERR_RESET_ANOMALY, ERR_COMPLIANCE_VIOLATION: return UVM_ERROR;
      default: return UVM_INFO;
    endcase
  endfunction
  
  //=============================================================================
  // Control and Configuration Functions
  //=============================================================================
  
  virtual function void enable_error_injection();
    error_injection_enabled = 1;
    `uvm_info("JTAG_ERR_INJ_CTRL", "Error injection enabled", UVM_LOW)
  endfunction
  
  virtual function void disable_error_injection();
    error_injection_enabled = 0;
    `uvm_info("JTAG_ERR_INJ_CTRL", "Error injection disabled", UVM_LOW)
  endfunction
  
  virtual function void set_error_rate(int unsigned rate);
    if (rate <= 100) begin
      error_injection_rate = rate;
      `uvm_info("JTAG_ERR_INJ_CTRL", $sformatf("Error injection rate set to %0d%%", rate), UVM_LOW)
    end else begin
      `uvm_warning("JTAG_ERR_INJ_WARN", $sformatf("Invalid error rate %0d%%, keeping current rate %0d%%", 
                                                  rate, error_injection_rate))
    end
  endfunction
  
  virtual function void set_systematic_mode(bit enable);
    systematic_error_mode = enable;
    random_error_mode = !enable;
    
    if (enable) begin
      setup_systematic_error_sequence();
      `uvm_info("JTAG_ERR_INJ_CTRL", "Switched to systematic error injection mode", UVM_LOW)
    end else begin
      `uvm_info("JTAG_ERR_INJ_CTRL", "Switched to random error injection mode", UVM_LOW)
    end
  endfunction
  
  virtual function void reset_statistics();
    total_transactions_processed = 0;
    total_errors_injected = 0;
    current_transaction_count = 0;
    
    // Clear error type counters
    foreach (errors_by_type[i]) errors_by_type[i] = 0;
    errors_by_phase.delete();
    
    `uvm_info("JTAG_ERR_INJ_CTRL", "Error injection statistics reset", UVM_LOW)
  endfunction
  
  //=============================================================================
  // Reporting and Analysis
  //=============================================================================
  
  virtual function void print_error_injection_report();
    real error_rate;
    
    `uvm_info("JTAG_ERR_INJ_REPORT", "=== Error Injection Report ===", UVM_LOW)
    `uvm_info("JTAG_ERR_INJ_REPORT", $sformatf("Total transactions processed: %0d", total_transactions_processed), UVM_LOW)
    `uvm_info("JTAG_ERR_INJ_REPORT", $sformatf("Total errors injected: %0d", total_errors_injected), UVM_LOW)
    
    if (total_transactions_processed > 0) begin
      error_rate = (real'(total_errors_injected) / real'(total_transactions_processed)) * 100.0;
      `uvm_info("JTAG_ERR_INJ_REPORT", $sformatf("Actual error injection rate: %0.2f%%", error_rate), UVM_LOW)
    end
    
    `uvm_info("JTAG_ERR_INJ_REPORT", "Error breakdown by type:", UVM_LOW)
    foreach (errors_by_type[error_type]) begin
      if (errors_by_type[error_type] > 0) begin
        `uvm_info("JTAG_ERR_INJ_REPORT", $sformatf("  %s: %0d", error_type.name(), errors_by_type[error_type]), UVM_LOW)
      end
    end
    
    `uvm_info("JTAG_ERR_INJ_REPORT", "Error breakdown by phase:", UVM_LOW)
    foreach (errors_by_phase[phase]) begin
      `uvm_info("JTAG_ERR_INJ_REPORT", $sformatf("  %s: %0d", phase, errors_by_phase[phase]), UVM_LOW)
    end
    
    `uvm_info("JTAG_ERR_INJ_REPORT", "=== End of Error Injection Report ===", UVM_LOW)
    
  endfunction
  
  virtual function int get_total_errors_injected();
    return total_errors_injected;
  endfunction
  
  virtual function real get_actual_error_rate();
    if (total_transactions_processed > 0) begin
      return (real'(total_errors_injected) / real'(total_transactions_processed)) * 100.0;
    end else begin
      return 0.0;
    end
  endfunction
  
  virtual function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    
    // Generate final error injection report
    print_error_injection_report();
    
  endfunction
  
endclass // jtag_error_injector

//=============================================================================
// JTAG Error Report Class
//=============================================================================

class jtag_error_report extends uvm_object;
  
  string error_type;
  string error_phase;
  time error_time;
  int unsigned transaction_id;
  string error_description;
  uvm_severity severity;
  jtag_sequence_item original_item;
  
  `uvm_object_utils_begin(jtag_error_report)
  `uvm_field_string(error_type, UVM_DEFAULT)
  `uvm_field_string(error_phase, UVM_DEFAULT)
  `uvm_field_int(error_time, UVM_DEFAULT)
  `uvm_field_int(transaction_id, UVM_DEFAULT)
  `uvm_field_string(error_description, UVM_DEFAULT)
  `uvm_field_enum(uvm_severity, severity, UVM_DEFAULT)
  `uvm_object_utils_end
  
  function new(string name = "jtag_error_report");
    super.new(name);
  endfunction
  
  virtual function string convert2string();
    return $sformatf("Error Report: Type=%s, Phase=%s, Time=%0t, TxnID=%0d, Severity=%s, Description=%s",
                    error_type, error_phase, error_time, transaction_id, severity.name(), error_description);
  endfunction
  
endclass // jtag_error_report

`endif