`ifndef JTAG_SCOREBOARD__SVH
 `define JTAG_SCOREBOARD__SVH

//=============================================================================
// JTAG Scoreboard
// Advanced transaction checking and verification component
//=============================================================================

class jtag_scoreboard extends uvm_scoreboard;
  
  // Analysis imports for receiving transactions
  uvm_analysis_imp_rx #(jtag_sequence_item, jtag_scoreboard) rx_analysis_imp;
  uvm_analysis_imp_tx #(jtag_sequence_item, jtag_scoreboard) tx_analysis_imp;
  uvm_analysis_imp_expected #(jtag_sequence_item, jtag_scoreboard) expected_analysis_imp;
  
  // Configuration objects
  jtag_protocol_config protocol_cfg;
  jtag_timing_config timing_cfg;
  jtag_error_config error_cfg;
  
  // Transaction queues and storage
  jtag_sequence_item rx_queue[$];
  jtag_sequence_item tx_queue[$];
  jtag_sequence_item expected_queue[$];
  jtag_sequence_item matched_transactions[$];
  jtag_sequence_item unmatched_rx_transactions[$];
  jtag_sequence_item unmatched_tx_transactions[$];
  
  // Statistics and counters
  int unsigned total_rx_transactions;
  int unsigned total_tx_transactions;
  int unsigned total_expected_transactions;
  int unsigned matched_transactions_count;
  int unsigned mismatched_transactions_count;
  int unsigned timeout_transactions_count;
  int unsigned protocol_violations_count;
  int unsigned data_integrity_errors_count;
  
  // Timing and performance tracking
  time first_transaction_time;
  time last_transaction_time;
  real average_transaction_latency;
  real peak_transaction_rate;
  
  // Error tracking
  string error_log[$];
  jtag_sequence_item error_transactions[$];
  
  // Events for synchronization
  event transaction_matched;
  event transaction_mismatched;
  event scoreboard_full;
  
  `uvm_component_utils_begin(jtag_scoreboard)
  `uvm_field_int(total_rx_transactions, UVM_DEFAULT)
  `uvm_field_int(total_tx_transactions, UVM_DEFAULT)
  `uvm_field_int(matched_transactions_count, UVM_DEFAULT)
  `uvm_field_int(mismatched_transactions_count, UVM_DEFAULT)
  `uvm_component_utils_end
  
  //=============================================================================
  // Constructor and Build Phase
  //=============================================================================
  
  function new(string name = "jtag_scoreboard", uvm_component parent = null);
    super.new(name, parent);
    
    // Initialize statistics
    total_rx_transactions = 0;
    total_tx_transactions = 0;
    total_expected_transactions = 0;
    matched_transactions_count = 0;
    mismatched_transactions_count = 0;
    timeout_transactions_count = 0;
    protocol_violations_count = 0;
    data_integrity_errors_count = 0;
    
    average_transaction_latency = 0.0;
    peak_transaction_rate = 0.0;
    first_transaction_time = 0;
    last_transaction_time = 0;
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis imports
    rx_analysis_imp = new("rx_analysis_imp", this);
    tx_analysis_imp = new("tx_analysis_imp", this);
    expected_analysis_imp = new("expected_analysis_imp", this);
    
    // Get configuration objects
    if(!uvm_config_db#(jtag_protocol_config)::get(this, "", "protocol_cfg", protocol_cfg)) begin
      `uvm_info("JTAG_SB_INFO", "Creating default protocol configuration", UVM_LOW)
      protocol_cfg = jtag_protocol_config::type_id::create("protocol_cfg");
    end
    
    if(!uvm_config_db#(jtag_timing_config)::get(this, "", "timing_cfg", timing_cfg)) begin
      `uvm_info("JTAG_SB_INFO", "Creating default timing configuration", UVM_LOW)
      timing_cfg = jtag_timing_config::type_id::create("timing_cfg");
    end
    
    if(!uvm_config_db#(jtag_error_config)::get(this, "", "error_cfg", error_cfg)) begin
      `uvm_info("JTAG_SB_INFO", "Creating default error configuration", UVM_LOW)
      error_cfg = jtag_error_config::type_id::create("error_cfg");
    end
    
  endfunction
  
  //=============================================================================
  // Analysis Import Write Functions
  //=============================================================================
  
  virtual function void write_rx(jtag_sequence_item t);
    jtag_sequence_item cloned_item;
    
    // Clone the transaction for storage
    $cast(cloned_item, t.clone());
    cloned_item.set_name($sformatf("rx_item_%0d", total_rx_transactions));
    
    // Add to RX queue
    rx_queue.push_back(cloned_item);
    total_rx_transactions++;
    
    // Update timing statistics
    if (first_transaction_time == 0)
      first_transaction_time = $time;
    last_transaction_time = $time;
    
    `uvm_info("JTAG_SB_RX", $sformatf("Received RX transaction #%0d: %s", 
                                      total_rx_transactions, t.convert2string()), UVM_HIGH)
    
    // Perform immediate checks
    check_protocol_compliance(cloned_item, "RX");
    
    // Try to match with expected transactions
    try_match_transactions();
    
  endfunction
  
  virtual function void write_tx(jtag_sequence_item t);
    jtag_sequence_item cloned_item;
    
    // Clone the transaction for storage
    $cast(cloned_item, t.clone());
    cloned_item.set_name($sformatf("tx_item_%0d", total_tx_transactions));
    
    // Add to TX queue
    tx_queue.push_back(cloned_item);
    total_tx_transactions++;
    
    // Update timing statistics
    if (first_transaction_time == 0)
      first_transaction_time = $time;
    last_transaction_time = $time;
    
    `uvm_info("JTAG_SB_TX", $sformatf("Received TX transaction #%0d: %s", 
                                      total_tx_transactions, t.convert2string()), UVM_HIGH)
    
    // Perform immediate checks
    check_protocol_compliance(cloned_item, "TX");
    
    // Try to match with expected transactions
    try_match_transactions();
    
  endfunction
  
  virtual function void write_expected(jtag_sequence_item t);
    jtag_sequence_item cloned_item;
    
    // Clone the transaction for storage
    $cast(cloned_item, t.clone());
    cloned_item.set_name($sformatf("expected_item_%0d", total_expected_transactions));
    
    // Add to expected queue
    expected_queue.push_back(cloned_item);
    total_expected_transactions++;
    
    `uvm_info("JTAG_SB_EXP", $sformatf("Received expected transaction #%0d: %s", 
                                       total_expected_transactions, t.convert2string()), UVM_HIGH)
    
    // Try to match with received transactions
    try_match_transactions();
    
  endfunction
  
  //=============================================================================
  // Transaction Matching and Checking
  //=============================================================================
  
  virtual function void try_match_transactions();
    int rx_idx, tx_idx, exp_idx;
    bit found_match;
    
    // Try to match RX transactions with expected
    for (rx_idx = 0; rx_idx < rx_queue.size(); rx_idx++) begin
      found_match = 0;
      for (exp_idx = 0; exp_idx < expected_queue.size(); exp_idx++) begin
        if (compare_transactions(rx_queue[rx_idx], expected_queue[exp_idx])) begin
          // Found a match
          record_match(rx_queue[rx_idx], expected_queue[exp_idx], "RX_EXPECTED");
          rx_queue.delete(rx_idx);
          expected_queue.delete(exp_idx);
          found_match = 1;
          break;
        end
      end
      if (found_match) break;
    end
    
    // Try to match TX transactions with expected
    for (tx_idx = 0; tx_idx < tx_queue.size(); tx_idx++) begin
      found_match = 0;
      for (exp_idx = 0; exp_idx < expected_queue.size(); exp_idx++) begin
        if (compare_transactions(tx_queue[tx_idx], expected_queue[exp_idx])) begin
          // Found a match
          record_match(tx_queue[tx_idx], expected_queue[exp_idx], "TX_EXPECTED");
          tx_queue.delete(tx_idx);
          expected_queue.delete(exp_idx);
          found_match = 1;
          break;
        end
      end
      if (found_match) break;
    end
    
    // Check for queue overflow
    if (rx_queue.size() > protocol_cfg.max_queue_size || 
        tx_queue.size() > protocol_cfg.max_queue_size ||
        expected_queue.size() > protocol_cfg.max_queue_size) begin
      `uvm_warning("JTAG_SB_WARN", "Scoreboard queue overflow detected")
      -> scoreboard_full;
    end
    
  endfunction
  
  virtual function bit compare_transactions(jtag_sequence_item actual, jtag_sequence_item expected);
    bit match = 1;
    
    // Compare instruction
    if (actual.instruction != expected.instruction) begin
      `uvm_info("JTAG_SB_MISMATCH", $sformatf("Instruction mismatch: actual=%h, expected=%h", 
                                              actual.instruction, expected.instruction), UVM_HIGH)
      match = 0;
    end
    
    // Compare data (if applicable)
    if (actual.trans_kind == JTAG_DATA_TRANS && expected.trans_kind == JTAG_DATA_TRANS) begin
      if (actual.data != expected.data) begin
        `uvm_info("JTAG_SB_MISMATCH", $sformatf("Data mismatch: actual=%h, expected=%h", 
                                                actual.data, expected.data), UVM_HIGH)
        match = 0;
      end
    end
    
    // Compare transaction type
    if (actual.trans_kind != expected.trans_kind) begin
      `uvm_info("JTAG_SB_MISMATCH", $sformatf("Transaction type mismatch: actual=%s, expected=%s", 
                                              actual.trans_kind.name(), expected.trans_kind.name()), UVM_HIGH)
      match = 0;
    end
    
    // Compare timing (if enabled)
    if (timing_cfg.enable_timing_checking) begin
      time time_diff = (actual.end_time > expected.end_time) ? 
                       (actual.end_time - expected.end_time) : 
                       (expected.end_time - actual.end_time);
      if (time_diff > timing_cfg.max_timing_tolerance) begin
        `uvm_info("JTAG_SB_MISMATCH", $sformatf("Timing mismatch: difference=%0t, tolerance=%0t", 
                                                time_diff, timing_cfg.max_timing_tolerance), UVM_HIGH)
        match = 0;
      end
    end
    
    return match;
  endfunction
  
  virtual function void record_match(jtag_sequence_item actual, jtag_sequence_item expected, string match_type);
    jtag_sequence_item matched_item;
    
    // Clone the actual transaction for the matched list
    $cast(matched_item, actual.clone());
    matched_item.set_name($sformatf("matched_%s_%0d", match_type, matched_transactions_count));
    matched_transactions.push_back(matched_item);
    
    matched_transactions_count++;
    
    `uvm_info("JTAG_SB_MATCH", $sformatf("Transaction match #%0d (%s): %s", 
                                         matched_transactions_count, match_type, 
                                         actual.convert2string()), UVM_MEDIUM)
    
    // Update performance statistics
    update_performance_statistics(actual, expected);
    
    // Trigger match event
    -> transaction_matched;
    
  endfunction
  
  virtual function void record_mismatch(jtag_sequence_item actual, jtag_sequence_item expected, string reason);
    string error_msg;
    
    mismatched_transactions_count++;
    
    error_msg = $sformatf("Transaction mismatch #%0d: %s\nActual: %s\nExpected: %s", 
                         mismatched_transactions_count, reason, 
                         actual.convert2string(), expected.convert2string());
    
    error_log.push_back(error_msg);
    error_transactions.push_back(actual);
    
    `uvm_error("JTAG_SB_MISMATCH", error_msg)
    
    // Trigger mismatch event
    -> transaction_mismatched;
    
  endfunction
  
  //=============================================================================
  // Protocol Compliance Checking
  //=============================================================================
  
  virtual function void check_protocol_compliance(jtag_sequence_item item, string direction);
    
    // Check instruction validity
    if (!is_valid_instruction(item.instruction)) begin
      protocol_violations_count++;
      `uvm_error("JTAG_SB_PROTOCOL", $sformatf("Invalid instruction detected (%s): %h", 
                                               direction, item.instruction))
    end
    
    // Check data integrity
    if (item.trans_kind == JTAG_DATA_TRANS) begin
      if (!check_data_integrity(item)) begin
        data_integrity_errors_count++;
        `uvm_error("JTAG_SB_DATA", $sformatf("Data integrity error detected (%s): %s", 
                                             direction, item.convert2string()))
      end
    end
    
    // Check state machine compliance
    if (!check_state_machine_compliance(item)) begin
      protocol_violations_count++;
      `uvm_error("JTAG_SB_STATE", $sformatf("State machine violation detected (%s): %s", 
                                            direction, item.convert2string()))
    end
    
  endfunction
  
  virtual function bit is_valid_instruction(bit [31:0] instruction);
    // Check against known valid instructions
    case (instruction)
      32'h00000000, // EXTEST
      32'h00000001, // SAMPLE/PRELOAD
      32'h00000002, // IDCODE
      32'h00000003, // INTEST
      32'h0000000F, // BYPASS
      32'h00000008, // DEBUG_REQUEST
      32'h00000009, // DEBUG_ACCESS
      32'h0000000A: // DEBUG_MEMORY
        return 1;
      default:
        return protocol_cfg.allow_custom_instructions;
    endcase
  endfunction
  
  virtual function bit check_data_integrity(jtag_sequence_item item);
    bit [31:0] calculated_checksum;
    
    // Simple checksum calculation for data integrity
    calculated_checksum = 0;
    for (int i = 0; i < 32; i++) begin
      calculated_checksum ^= item.data[i];
    end
    
    // For now, assume data is valid if it's not all zeros or all ones
    return (item.data != 32'h00000000 && item.data != 32'hFFFFFFFF);
  endfunction
  
  virtual function bit check_state_machine_compliance(jtag_sequence_item item);
    // Basic state machine compliance check
    // This would be enhanced based on specific JTAG state machine requirements
    return 1; // Placeholder implementation
  endfunction
  
  //=============================================================================
  // Performance and Statistics
  //=============================================================================
  
  virtual function void update_performance_statistics(jtag_sequence_item actual, jtag_sequence_item expected);
    time latency;
    real current_rate;
    
    // Calculate transaction latency
    if (actual.end_time > actual.start_time) begin
      latency = actual.end_time - actual.start_time;
      
      // Update average latency
      if (matched_transactions_count == 1) begin
        average_transaction_latency = real'(latency);
      end else begin
        average_transaction_latency = (average_transaction_latency * real'(matched_transactions_count - 1) + 
                                     real'(latency)) / real'(matched_transactions_count);
      end
    end
    
    // Calculate current transaction rate
    if (last_transaction_time > first_transaction_time) begin
      current_rate = real'(matched_transactions_count) / 
                    (real'(last_transaction_time - first_transaction_time) / 1ns);
      
      if (current_rate > peak_transaction_rate) begin
        peak_transaction_rate = current_rate;
      end
    end
    
  endfunction
  
  //=============================================================================
  // Run Phase and Cleanup
  //=============================================================================
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    fork
      monitor_timeout_transactions();
      periodic_queue_cleanup();
    join_none
    
  endtask
  
  virtual task monitor_timeout_transactions();
    forever begin
      #(timing_cfg.transaction_timeout);
      
      // Check for timed-out transactions
      check_transaction_timeouts();
    end
  endtask
  
  virtual task periodic_queue_cleanup();
    forever begin
      #(timing_cfg.cleanup_interval);
      
      // Clean up old unmatched transactions
      cleanup_old_transactions();
    end
  endtask
  
  virtual function void check_transaction_timeouts();
    time current_time = $time;
    int timeout_count = 0;
    
    // Check RX queue for timeouts
    for (int i = rx_queue.size() - 1; i >= 0; i--) begin
      if ((current_time - rx_queue[i].start_time) > timing_cfg.transaction_timeout) begin
        unmatched_rx_transactions.push_back(rx_queue[i]);
        rx_queue.delete(i);
        timeout_count++;
      end
    end
    
    // Check TX queue for timeouts
    for (int i = tx_queue.size() - 1; i >= 0; i--) begin
      if ((current_time - tx_queue[i].start_time) > timing_cfg.transaction_timeout) begin
        unmatched_tx_transactions.push_back(tx_queue[i]);
        tx_queue.delete(i);
        timeout_count++;
      end
    end
    
    if (timeout_count > 0) begin
      timeout_transactions_count += timeout_count;
      `uvm_warning("JTAG_SB_TIMEOUT", $sformatf("Detected %0d timed-out transactions", timeout_count))
    end
    
  endfunction
  
  virtual function void cleanup_old_transactions();
    // Remove very old unmatched transactions to prevent memory leaks
    time cleanup_threshold = $time - (timing_cfg.transaction_timeout * 10);
    
    // Clean unmatched RX transactions
    for (int i = unmatched_rx_transactions.size() - 1; i >= 0; i--) begin
      if (unmatched_rx_transactions[i].start_time < cleanup_threshold) begin
        unmatched_rx_transactions.delete(i);
      end
    end
    
    // Clean unmatched TX transactions
    for (int i = unmatched_tx_transactions.size() - 1; i >= 0; i--) begin
      if (unmatched_tx_transactions[i].start_time < cleanup_threshold) begin
        unmatched_tx_transactions.delete(i);
      end
    end
    
  endfunction
  
  //=============================================================================
  // Reporting and Analysis
  //=============================================================================
  
  virtual function void print_final_report();
    `uvm_info("JTAG_SB_REPORT", "=== JTAG Scoreboard Final Report ===", UVM_LOW)
    `uvm_info("JTAG_SB_REPORT", $sformatf("Total RX transactions: %0d", total_rx_transactions), UVM_LOW)
    `uvm_info("JTAG_SB_REPORT", $sformatf("Total TX transactions: %0d", total_tx_transactions), UVM_LOW)
    `uvm_info("JTAG_SB_REPORT", $sformatf("Total expected transactions: %0d", total_expected_transactions), UVM_LOW)
    `uvm_info("JTAG_SB_REPORT", $sformatf("Matched transactions: %0d", matched_transactions_count), UVM_LOW)
    `uvm_info("JTAG_SB_REPORT", $sformatf("Mismatched transactions: %0d", mismatched_transactions_count), UVM_LOW)
    `uvm_info("JTAG_SB_REPORT", $sformatf("Timeout transactions: %0d", timeout_transactions_count), UVM_LOW)
    `uvm_info("JTAG_SB_REPORT", $sformatf("Protocol violations: %0d", protocol_violations_count), UVM_LOW)
    `uvm_info("JTAG_SB_REPORT", $sformatf("Data integrity errors: %0d", data_integrity_errors_count), UVM_LOW)
    
    if (matched_transactions_count > 0) begin
      real success_rate = (real'(matched_transactions_count) / 
                          real'(total_rx_transactions + total_tx_transactions)) * 100.0;
      `uvm_info("JTAG_SB_REPORT", $sformatf("Success rate: %0.2f%%", success_rate), UVM_LOW)
      `uvm_info("JTAG_SB_REPORT", $sformatf("Average latency: %0.2f ns", average_transaction_latency), UVM_LOW)
      `uvm_info("JTAG_SB_REPORT", $sformatf("Peak transaction rate: %0.2f Hz", peak_transaction_rate), UVM_LOW)
    end
    
    `uvm_info("JTAG_SB_REPORT", "=== End of Scoreboard Report ===", UVM_LOW)
    
    // Print error summary if there were errors
    if (error_log.size() > 0) begin
      `uvm_info("JTAG_SB_ERRORS", "=== Error Summary ===", UVM_LOW)
      foreach (error_log[i]) begin
        `uvm_info("JTAG_SB_ERRORS", error_log[i], UVM_LOW)
      end
      `uvm_info("JTAG_SB_ERRORS", "=== End of Error Summary ===", UVM_LOW)
    end
    
  endfunction
  
  virtual function int get_match_count();
    return matched_transactions_count;
  endfunction
  
  virtual function int get_mismatch_count();
    return mismatched_transactions_count;
  endfunction
  
  virtual function real get_success_rate();
    int total_transactions = total_rx_transactions + total_tx_transactions;
    if (total_transactions > 0) begin
      return (real'(matched_transactions_count) / real'(total_transactions)) * 100.0;
    end else begin
      return 0.0;
    end
  endfunction
  
  virtual function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    
    // Final cleanup and statistics calculation
    check_transaction_timeouts();
    
    // Move any remaining transactions to unmatched lists
    while (rx_queue.size() > 0) begin
      unmatched_rx_transactions.push_back(rx_queue.pop_front());
    end
    
    while (tx_queue.size() > 0) begin
      unmatched_tx_transactions.push_back(tx_queue.pop_front());
    end
    
  endfunction
  
endclass // jtag_scoreboard

`endif