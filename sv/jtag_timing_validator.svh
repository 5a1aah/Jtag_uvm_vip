`ifndef JTAG_TIMING_VALIDATOR_SVH
`define JTAG_TIMING_VALIDATOR_SVH

//=============================================================================
// Enhanced JTAG Timing Validator
// Comprehensive timing validation and constraint checking
//=============================================================================

class jtag_timing_validator extends uvm_component;
  `uvm_component_utils(jtag_timing_validator)
  
  // Configuration objects
  jtag_timing_config timing_cfg;
  jtag_protocol_config protocol_cfg;
  jtag_error_config error_cfg;
  
  // Analysis ports for receiving transactions
  uvm_analysis_imp_rx #(jtag_base_transaction, jtag_timing_validator) rx_analysis_imp;
  uvm_analysis_imp_tx #(jtag_base_transaction, jtag_timing_validator) tx_analysis_imp;
  
  // Output ports for timing violations
  uvm_analysis_port #(jtag_timing_info_s) timing_ap;
  uvm_analysis_port #(jtag_error_info_s) error_ap;
  uvm_analysis_port #(jtag_performance_metrics_s) performance_ap;
  
  // Timing measurement variables
  real last_tck_edge_time;
  real last_tdi_change_time;
  real last_tms_change_time;
  real last_trst_edge_time;
  
  // Timing constraint tracking
  real measured_tck_period;
  real measured_tck_duty_cycle;
  real measured_setup_time;
  real measured_hold_time;
  real measured_tco_delay;
  real measured_tdi_to_tdo_delay;
  
  // Violation counters
  int setup_violations;
  int hold_violations;
  int period_violations;
  int duty_cycle_violations;
  int jitter_violations;
  int delay_violations;
  
  // Performance metrics
  real min_period_measured;
  real max_period_measured;
  real total_jitter_measured;
  int total_measurements;
  real total_validation_time;
  
  // Timing history for jitter analysis
  real tck_period_history[$];
  real setup_time_history[$];
  real hold_time_history[$];
  
  // Clock edge detection
  bit last_tck_value;
  bit tck_rising_edge;
  bit tck_falling_edge;
  
  function new(string name = "jtag_timing_validator", uvm_component parent = null);
    super.new(name, parent);
    
    // Initialize timing measurements
    last_tck_edge_time = 0.0;
    last_tdi_change_time = 0.0;
    last_tms_change_time = 0.0;
    last_trst_edge_time = 0.0;
    
    measured_tck_period = 0.0;
    measured_tck_duty_cycle = 0.0;
    measured_setup_time = 0.0;
    measured_hold_time = 0.0;
    measured_tco_delay = 0.0;
    measured_tdi_to_tdo_delay = 0.0;
    
    // Initialize violation counters
    setup_violations = 0;
    hold_violations = 0;
    period_violations = 0;
    duty_cycle_violations = 0;
    jitter_violations = 0;
    delay_violations = 0;
    
    // Initialize performance metrics
    min_period_measured = 1e9; // Large initial value
    max_period_measured = 0.0;
    total_jitter_measured = 0.0;
    total_measurements = 0;
    total_validation_time = 0.0;
    
    // Initialize clock edge detection
    last_tck_value = 0;
    tck_rising_edge = 0;
    tck_falling_edge = 0;
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis ports
    rx_analysis_imp = new("rx_analysis_imp", this);
    tx_analysis_imp = new("tx_analysis_imp", this);
    timing_ap = new("timing_ap", this);
    error_ap = new("error_ap", this);
    performance_ap = new("performance_ap", this);
    
    // Get configuration objects
    if(!uvm_config_db#(jtag_timing_config)::get(this, "", "timing_cfg", timing_cfg)) begin
      `uvm_info("JTAG_TIMING_VALIDATOR", "Using default timing configuration", UVM_LOW)
      timing_cfg = jtag_timing_config::type_id::create("timing_cfg");
    end
    
    if(!uvm_config_db#(jtag_protocol_config)::get(this, "", "protocol_cfg", protocol_cfg)) begin
      `uvm_info("JTAG_TIMING_VALIDATOR", "Using default protocol configuration", UVM_LOW)
      protocol_cfg = jtag_protocol_config::type_id::create("protocol_cfg");
    end
    
    if(!uvm_config_db#(jtag_error_config)::get(this, "", "error_cfg", error_cfg)) begin
      `uvm_info("JTAG_TIMING_VALIDATOR", "Using default error configuration", UVM_LOW)
      error_cfg = jtag_error_config::type_id::create("error_cfg");
    end
  endfunction
  
  // Write function for RX transactions
  virtual function void write_rx(jtag_base_transaction trans);
    if (protocol_cfg.enable_timing_checking) begin
      validate_transaction_timing(trans, "RX");
    end
  endfunction
  
  // Write function for TX transactions
  virtual function void write_tx(jtag_base_transaction trans);
    if (protocol_cfg.enable_timing_checking) begin
      validate_transaction_timing(trans, "TX");
    end
  endfunction
  
  //=============================================================================
  // Timing Validation Functions
  //=============================================================================
  
  virtual function void validate_transaction_timing(jtag_base_transaction trans, string direction);
    real start_time, end_time;
    jtag_timing_info_s timing_info;
    jtag_error_info_s error_info;
    jtag_performance_metrics_s perf_metrics;
    
    start_time = $realtime;
    
    // Initialize timing info
    timing_info.transaction_id = trans.transaction_id;
    timing_info.timestamp = $realtime;
    timing_info.direction = direction;
    timing_info.is_timing_valid = 1;
    timing_info.violation_count = 0;
    
    // Validate different timing aspects
    validate_clock_timing(trans, timing_info, error_info);
    validate_setup_hold_timing(trans, timing_info, error_info);
    validate_propagation_delays(trans, timing_info, error_info);
    validate_reset_timing(trans, timing_info, error_info);
    
    // Calculate jitter and stability
    calculate_jitter_metrics(trans, timing_info);
    
    // Update performance metrics
    update_performance_metrics(trans, perf_metrics);
    
    // Update statistics
    total_measurements++;
    end_time = $realtime;
    total_validation_time += (end_time - start_time);
    
    // Send timing information
    timing_ap.write(timing_info);
    performance_ap.write(perf_metrics);
    
    // Send error information if violations found
    if (!timing_info.is_timing_valid) begin
      error_ap.write(error_info);
    end
    
    // Log timing status
    if (timing_info.is_timing_valid) begin
      `uvm_info("JTAG_TIMING_VALIDATOR", 
        $sformatf("%s transaction %0d: TIMING VALID", direction, trans.transaction_id), UVM_HIGH)
    end else begin
      `uvm_warning("JTAG_TIMING_VALIDATOR", 
        $sformatf("%s transaction %0d: TIMING VIOLATION - %s", direction, trans.transaction_id, error_info.error_message))
    end
  endfunction
  
  virtual function void validate_clock_timing(jtag_base_transaction trans,
                                             ref jtag_timing_info_s timing_info,
                                             ref jtag_error_info_s error_info);
    real transaction_duration, calculated_period, calculated_duty_cycle;
    
    transaction_duration = trans.end_time - trans.start_time;
    
    // Calculate TCK period from transaction
    if (trans.tck_cycles > 0) begin
      calculated_period = transaction_duration / trans.tck_cycles;
      measured_tck_period = calculated_period;
      
      // Check period constraints
      if (calculated_period < timing_cfg.tck_period * (1.0 - timing_cfg.tck_jitter/100.0)) begin
        timing_info.is_timing_valid = 0;
        timing_info.violation_count++;
        period_violations++;
        error_info.error_type = TIMING_ERROR;
        error_info.error_message = $sformatf("TCK period %0.2f ns < minimum %0.2f ns", 
                                            calculated_period, timing_cfg.tck_period * (1.0 - timing_cfg.tck_jitter/100.0));
      end
      
      if (calculated_period > timing_cfg.tck_period * (1.0 + timing_cfg.tck_jitter/100.0)) begin
        timing_info.is_timing_valid = 0;
        timing_info.violation_count++;
        period_violations++;
        error_info.error_type = TIMING_ERROR;
        error_info.error_message = $sformatf("TCK period %0.2f ns > maximum %0.2f ns", 
                                            calculated_period, timing_cfg.tck_period * (1.0 + timing_cfg.tck_jitter/100.0));
      end
      
      // Update period history for jitter analysis
      tck_period_history.push_back(calculated_period);
      if (tck_period_history.size() > 100) begin
        tck_period_history.pop_front();
      end
      
      // Update min/max measurements
      if (calculated_period < min_period_measured) min_period_measured = calculated_period;
      if (calculated_period > max_period_measured) max_period_measured = calculated_period;
    end
    
    // Calculate duty cycle
    if (trans.tck_high_time > 0.0 && calculated_period > 0.0) begin
      calculated_duty_cycle = trans.tck_high_time / calculated_period;
      measured_tck_duty_cycle = calculated_duty_cycle;
      
      // Check duty cycle constraints
      real duty_cycle_tolerance = 0.05; // 5% tolerance
      if (calculated_duty_cycle < (timing_cfg.tck_duty_cycle - duty_cycle_tolerance)) begin
        timing_info.is_timing_valid = 0;
        timing_info.violation_count++;
        duty_cycle_violations++;
        error_info.error_type = TIMING_ERROR;
        error_info.error_message = $sformatf("TCK duty cycle %0.2f < minimum %0.2f", 
                                            calculated_duty_cycle, timing_cfg.tck_duty_cycle - duty_cycle_tolerance);
      end
      
      if (calculated_duty_cycle > (timing_cfg.tck_duty_cycle + duty_cycle_tolerance)) begin
        timing_info.is_timing_valid = 0;
        timing_info.violation_count++;
        duty_cycle_violations++;
        error_info.error_type = TIMING_ERROR;
        error_info.error_message = $sformatf("TCK duty cycle %0.2f > maximum %0.2f", 
                                            calculated_duty_cycle, timing_cfg.tck_duty_cycle + duty_cycle_tolerance);
      end
    end
    
    // Store timing measurements in timing_info
    timing_info.measured_period = calculated_period;
    timing_info.measured_duty_cycle = calculated_duty_cycle;
  endfunction
  
  virtual function void validate_setup_hold_timing(jtag_base_transaction trans,
                                                  ref jtag_timing_info_s timing_info,
                                                  ref jtag_error_info_s error_info);
    // Validate TDI setup time
    if (trans.setup_time < timing_cfg.tsu_tdi) begin
      timing_info.is_timing_valid = 0;
      timing_info.violation_count++;
      setup_violations++;
      error_info.error_type = TIMING_ERROR;
      error_info.error_message = $sformatf("TDI setup time %0.2f ns < minimum %0.2f ns", 
                                          trans.setup_time, timing_cfg.tsu_tdi);
    end
    
    // Validate TDI hold time
    if (trans.hold_time < timing_cfg.th_tdi) begin
      timing_info.is_timing_valid = 0;
      timing_info.violation_count++;
      hold_violations++;
      error_info.error_type = TIMING_ERROR;
      error_info.error_message = $sformatf("TDI hold time %0.2f ns < minimum %0.2f ns", 
                                          trans.hold_time, timing_cfg.th_tdi);
    end
    
    // Validate TMS setup time
    if (trans.tms_setup_time < timing_cfg.tsu_tms) begin
      timing_info.is_timing_valid = 0;
      timing_info.violation_count++;
      setup_violations++;
      error_info.error_type = TIMING_ERROR;
      error_info.error_message = $sformatf("TMS setup time %0.2f ns < minimum %0.2f ns", 
                                          trans.tms_setup_time, timing_cfg.tsu_tms);
    end
    
    // Validate TMS hold time
    if (trans.tms_hold_time < timing_cfg.th_tms) begin
      timing_info.is_timing_valid = 0;
      timing_info.violation_count++;
      hold_violations++;
      error_info.error_type = TIMING_ERROR;
      error_info.error_message = $sformatf("TMS hold time %0.2f ns < minimum %0.2f ns", 
                                          trans.tms_hold_time, timing_cfg.th_tms);
    end
    
    // Store measurements
    measured_setup_time = trans.setup_time;
    measured_hold_time = trans.hold_time;
    timing_info.measured_setup_time = trans.setup_time;
    timing_info.measured_hold_time = trans.hold_time;
    
    // Update setup/hold history
    setup_time_history.push_back(trans.setup_time);
    hold_time_history.push_back(trans.hold_time);
    if (setup_time_history.size() > 100) setup_time_history.pop_front();
    if (hold_time_history.size() > 100) hold_time_history.pop_front();
  endfunction
  
  virtual function void validate_propagation_delays(jtag_base_transaction trans,
                                                   ref jtag_timing_info_s timing_info,
                                                   ref jtag_error_info_s error_info);
    // Validate TCO delay (TCK to TDO)
    if (trans.tco_delay > timing_cfg.tco_max) begin
      timing_info.is_timing_valid = 0;
      timing_info.violation_count++;
      delay_violations++;
      error_info.error_type = TIMING_ERROR;
      error_info.error_message = $sformatf("TCO delay %0.2f ns > maximum %0.2f ns", 
                                          trans.tco_delay, timing_cfg.tco_max);
    end
    
    // Validate TDI to TDO delay
    if (trans.tdi_to_tdo_delay > timing_cfg.tdi_to_tdo_delay) begin
      timing_info.is_timing_valid = 0;
      timing_info.violation_count++;
      delay_violations++;
      error_info.error_type = TIMING_ERROR;
      error_info.error_message = $sformatf("TDI to TDO delay %0.2f ns > maximum %0.2f ns", 
                                          trans.tdi_to_tdo_delay, timing_cfg.tdi_to_tdo_delay);
    end
    
    // Store measurements
    measured_tco_delay = trans.tco_delay;
    measured_tdi_to_tdo_delay = trans.tdi_to_tdo_delay;
    timing_info.measured_tco_delay = trans.tco_delay;
    timing_info.measured_propagation_delay = trans.tdi_to_tdo_delay;
  endfunction
  
  virtual function void validate_reset_timing(jtag_base_transaction trans,
                                             ref jtag_timing_info_s timing_info,
                                             ref jtag_error_info_s error_info);
    // Validate TRST timing if reset transaction
    if (trans.trans_type == JTAG_RESET && trans.reset_type == TRST_RESET) begin
      // Check TRST pulse width
      if (trans.reset_duration < timing_cfg.trst_pulse_width) begin
        timing_info.is_timing_valid = 0;
        timing_info.violation_count++;
        error_info.error_type = TIMING_ERROR;
        error_info.error_message = $sformatf("TRST pulse width %0.2f ns < minimum %0.2f ns", 
                                            trans.reset_duration, timing_cfg.trst_pulse_width);
      end
      
      // Check TRST to TCK delay
      if (trans.trst_to_tck_delay < timing_cfg.trst_to_tck_delay) begin
        timing_info.is_timing_valid = 0;
        timing_info.violation_count++;
        error_info.error_type = TIMING_ERROR;
        error_info.error_message = $sformatf("TRST to TCK delay %0.2f ns < minimum %0.2f ns", 
                                            trans.trst_to_tck_delay, timing_cfg.trst_to_tck_delay);
      end
    end
  endfunction
  
  virtual function void calculate_jitter_metrics(jtag_base_transaction trans,
                                                ref jtag_timing_info_s timing_info);
    real period_jitter, cumulative_jitter;
    real period_mean, period_variance, period_std_dev;
    int i;
    
    // Calculate period jitter if we have enough history
    if (tck_period_history.size() >= 2) begin
      // Calculate mean period
      period_mean = 0.0;
      for (i = 0; i < tck_period_history.size(); i++) begin
        period_mean += tck_period_history[i];
      end
      period_mean = period_mean / tck_period_history.size();
      
      // Calculate variance
      period_variance = 0.0;
      for (i = 0; i < tck_period_history.size(); i++) begin
        period_variance += (tck_period_history[i] - period_mean) * (tck_period_history[i] - period_mean);
      end
      period_variance = period_variance / tck_period_history.size();
      
      // Calculate standard deviation (jitter)
      period_std_dev = $sqrt(period_variance);
      period_jitter = (period_std_dev / period_mean) * 100.0; // Convert to percentage
      
      // Check jitter limits
      if (period_jitter > timing_cfg.tck_jitter) begin
        timing_info.is_timing_valid = 0;
        timing_info.violation_count++;
        jitter_violations++;
      end
      
      timing_info.measured_jitter = period_jitter;
      total_jitter_measured += period_jitter;
    end
  endfunction
  
  virtual function void update_performance_metrics(jtag_base_transaction trans,
                                                  ref jtag_performance_metrics_s perf_metrics);
    real current_time = $realtime;
    
    // Initialize performance metrics
    perf_metrics.transaction_id = trans.transaction_id;
    perf_metrics.timestamp = current_time;
    perf_metrics.transaction_type = trans.trans_type;
    
    // Calculate throughput metrics
    if (total_measurements > 0) begin
      perf_metrics.average_transaction_time = total_validation_time / total_measurements;
      perf_metrics.transactions_per_second = 1e9 / (total_validation_time / total_measurements); // Convert ns to seconds
    end
    
    // Clock performance metrics
    perf_metrics.min_clock_period = min_period_measured;
    perf_metrics.max_clock_period = max_period_measured;
    perf_metrics.average_clock_period = (total_measurements > 0) ? 
      (min_period_measured + max_period_measured) / 2.0 : 0.0;
    
    // Jitter metrics
    perf_metrics.average_jitter = (total_measurements > 0) ? 
      total_jitter_measured / total_measurements : 0.0;
    perf_metrics.peak_jitter = timing_info.measured_jitter;
    
    // Violation statistics
    perf_metrics.setup_violation_rate = (total_measurements > 0) ? 
      (real'(setup_violations) / real'(total_measurements)) * 100.0 : 0.0;
    perf_metrics.hold_violation_rate = (total_measurements > 0) ? 
      (real'(hold_violations) / real'(total_measurements)) * 100.0 : 0.0;
    perf_metrics.timing_violation_rate = (total_measurements > 0) ? 
      (real'(setup_violations + hold_violations + period_violations + duty_cycle_violations + jitter_violations + delay_violations) / real'(total_measurements)) * 100.0 : 0.0;
    
    // Data integrity metrics
    perf_metrics.data_integrity_score = 100.0 - perf_metrics.timing_violation_rate;
    
    // Performance score (0-100)
    perf_metrics.overall_performance_score = calculate_performance_score(perf_metrics);
  endfunction
  
  virtual function real calculate_performance_score(jtag_performance_metrics_s perf_metrics);
    real score = 100.0;
    
    // Deduct points for violations
    score -= perf_metrics.timing_violation_rate * 2.0; // 2 points per percent violation rate
    
    // Deduct points for excessive jitter
    if (perf_metrics.average_jitter > timing_cfg.tck_jitter) begin
      score -= (perf_metrics.average_jitter - timing_cfg.tck_jitter) * 5.0;
    end
    
    // Deduct points for poor throughput
    if (perf_metrics.average_transaction_time > timing_cfg.tck_period * 10.0) begin
      score -= 10.0;
    end
    
    // Ensure score doesn't go below 0
    if (score < 0.0) score = 0.0;
    
    return score;
  endfunction
  
  //=============================================================================
  // Reporting Functions
  //=============================================================================
  
  virtual function void report_timing_statistics();
    real average_validation_time, average_jitter;
    
    if (total_measurements > 0) begin
      average_validation_time = total_validation_time / total_measurements;
      average_jitter = total_jitter_measured / total_measurements;
    end else begin
      average_validation_time = 0.0;
      average_jitter = 0.0;
    end
    
    `uvm_info("JTAG_TIMING_VALIDATOR", "=== Timing Validation Statistics ===", UVM_LOW)
    `uvm_info("JTAG_TIMING_VALIDATOR", $sformatf("Total measurements: %0d", total_measurements), UVM_LOW)
    `uvm_info("JTAG_TIMING_VALIDATOR", $sformatf("Setup violations: %0d", setup_violations), UVM_LOW)
    `uvm_info("JTAG_TIMING_VALIDATOR", $sformatf("Hold violations: %0d", hold_violations), UVM_LOW)
    `uvm_info("JTAG_TIMING_VALIDATOR", $sformatf("Period violations: %0d", period_violations), UVM_LOW)
    `uvm_info("JTAG_TIMING_VALIDATOR", $sformatf("Duty cycle violations: %0d", duty_cycle_violations), UVM_LOW)
    `uvm_info("JTAG_TIMING_VALIDATOR", $sformatf("Jitter violations: %0d", jitter_violations), UVM_LOW)
    `uvm_info("JTAG_TIMING_VALIDATOR", $sformatf("Delay violations: %0d", delay_violations), UVM_LOW)
    `uvm_info("JTAG_TIMING_VALIDATOR", $sformatf("Min period measured: %0.2f ns", min_period_measured), UVM_LOW)
    `uvm_info("JTAG_TIMING_VALIDATOR", $sformatf("Max period measured: %0.2f ns", max_period_measured), UVM_LOW)
    `uvm_info("JTAG_TIMING_VALIDATOR", $sformatf("Average jitter: %0.2f%%", average_jitter), UVM_LOW)
    `uvm_info("JTAG_TIMING_VALIDATOR", $sformatf("Average validation time: %0.2f ns", average_validation_time), UVM_LOW)
    `uvm_info("JTAG_TIMING_VALIDATOR", "====================================", UVM_LOW)
  endfunction
  
  virtual function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    report_timing_statistics();
  endfunction
  
endclass

`endif // JTAG_TIMING_VALIDATOR_SVH