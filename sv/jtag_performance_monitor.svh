`ifndef JTAG_PERFORMANCE_MONITOR_SVH
`define JTAG_PERFORMANCE_MONITOR_SVH

//=============================================================================
// Enhanced JTAG Performance Monitor
// Comprehensive performance monitoring and analysis
//=============================================================================

class jtag_performance_monitor extends uvm_component;
  `uvm_component_utils(jtag_performance_monitor)
  
  // Configuration objects
  jtag_timing_config timing_cfg;
  jtag_protocol_config protocol_cfg;
  jtag_performance_config performance_cfg;
  
  // Analysis ports for receiving performance data
  uvm_analysis_imp_perf #(jtag_performance_metrics_s, jtag_performance_monitor) perf_analysis_imp;
  uvm_analysis_imp_timing #(jtag_timing_info_s, jtag_performance_monitor) timing_analysis_imp;
  uvm_analysis_imp_trans #(jtag_base_transaction, jtag_performance_monitor) trans_analysis_imp;
  
  // Output ports for performance reports
  uvm_analysis_port #(jtag_performance_report_s) report_ap;
  uvm_analysis_port #(jtag_performance_alert_s) alert_ap;
  
  // Performance tracking variables
  real simulation_start_time;
  real last_transaction_time;
  real total_simulation_time;
  
  // Transaction statistics
  int total_transactions;
  int successful_transactions;
  int failed_transactions;
  int timeout_transactions;
  
  // Throughput metrics
  real instantaneous_throughput;
  real average_throughput;
  real peak_throughput;
  real minimum_throughput;
  
  // Latency metrics
  real total_latency;
  real average_latency;
  real min_latency;
  real max_latency;
  real latency_variance;
  
  // Timing performance
  real total_timing_violations;
  real timing_violation_rate;
  real average_setup_time;
  real average_hold_time;
  real average_clock_period;
  
  // Bandwidth utilization
  real data_bits_transferred;
  real effective_bandwidth;
  real theoretical_bandwidth;
  real bandwidth_utilization;
  
  // Error and quality metrics
  real error_rate;
  real data_integrity_score;
  real protocol_compliance_score;
  real overall_quality_score;
  
  // Performance history for trend analysis
  real throughput_history[$];
  real latency_history[$];
  real error_rate_history[$];
  real bandwidth_history[$];
  
  // Performance thresholds
  real throughput_threshold;
  real latency_threshold;
  real error_rate_threshold;
  real bandwidth_threshold;
  
  // Alert counters
  int throughput_alerts;
  int latency_alerts;
  int error_rate_alerts;
  int bandwidth_alerts;
  
  // Performance windows for moving averages
  parameter int PERFORMANCE_WINDOW_SIZE = 100;
  
  function new(string name = "jtag_performance_monitor", uvm_component parent = null);
    super.new(name, parent);
    
    // Initialize timing
    simulation_start_time = 0.0;
    last_transaction_time = 0.0;
    total_simulation_time = 0.0;
    
    // Initialize transaction statistics
    total_transactions = 0;
    successful_transactions = 0;
    failed_transactions = 0;
    timeout_transactions = 0;
    
    // Initialize throughput metrics
    instantaneous_throughput = 0.0;
    average_throughput = 0.0;
    peak_throughput = 0.0;
    minimum_throughput = 1e9; // Large initial value
    
    // Initialize latency metrics
    total_latency = 0.0;
    average_latency = 0.0;
    min_latency = 1e9; // Large initial value
    max_latency = 0.0;
    latency_variance = 0.0;
    
    // Initialize timing performance
    total_timing_violations = 0.0;
    timing_violation_rate = 0.0;
    average_setup_time = 0.0;
    average_hold_time = 0.0;
    average_clock_period = 0.0;
    
    // Initialize bandwidth metrics
    data_bits_transferred = 0.0;
    effective_bandwidth = 0.0;
    theoretical_bandwidth = 0.0;
    bandwidth_utilization = 0.0;
    
    // Initialize quality metrics
    error_rate = 0.0;
    data_integrity_score = 100.0;
    protocol_compliance_score = 100.0;
    overall_quality_score = 100.0;
    
    // Initialize thresholds (will be updated from config)
    throughput_threshold = 1000000.0; // 1 Mbps
    latency_threshold = 100.0; // 100 ns
    error_rate_threshold = 1.0; // 1%
    bandwidth_threshold = 80.0; // 80% utilization
    
    // Initialize alert counters
    throughput_alerts = 0;
    latency_alerts = 0;
    error_rate_alerts = 0;
    bandwidth_alerts = 0;
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis ports
    perf_analysis_imp = new("perf_analysis_imp", this);
    timing_analysis_imp = new("timing_analysis_imp", this);
    trans_analysis_imp = new("trans_analysis_imp", this);
    report_ap = new("report_ap", this);
    alert_ap = new("alert_ap", this);
    
    // Get configuration objects
    if(!uvm_config_db#(jtag_timing_config)::get(this, "", "timing_cfg", timing_cfg)) begin
      `uvm_info("JTAG_PERFORMANCE_MONITOR", "Using default timing configuration", UVM_LOW)
      timing_cfg = jtag_timing_config::type_id::create("timing_cfg");
    end
    
    if(!uvm_config_db#(jtag_protocol_config)::get(this, "", "protocol_cfg", protocol_cfg)) begin
      `uvm_info("JTAG_PERFORMANCE_MONITOR", "Using default protocol configuration", UVM_LOW)
      protocol_cfg = jtag_protocol_config::type_id::create("protocol_cfg");
    end
    
    if(!uvm_config_db#(jtag_performance_config)::get(this, "", "performance_cfg", performance_cfg)) begin
      `uvm_info("JTAG_PERFORMANCE_MONITOR", "Using default performance configuration", UVM_LOW)
      performance_cfg = jtag_performance_config::type_id::create("performance_cfg");
    end
    
    // Update thresholds from configuration
    if (performance_cfg != null) begin
      throughput_threshold = performance_cfg.min_throughput;
      latency_threshold = performance_cfg.max_latency;
      error_rate_threshold = performance_cfg.max_error_rate;
      bandwidth_threshold = performance_cfg.min_bandwidth_utilization;
    end
  endfunction
  
  virtual function void start_of_simulation_phase(uvm_phase phase);
    super.start_of_simulation_phase(phase);
    simulation_start_time = $realtime;
    `uvm_info("JTAG_PERFORMANCE_MONITOR", "Performance monitoring started", UVM_LOW)
  endfunction
  
  // Write function for performance metrics
  virtual function void write_perf(jtag_performance_metrics_s perf_metrics);
    update_performance_metrics(perf_metrics);
    check_performance_thresholds(perf_metrics);
  endfunction
  
  // Write function for timing information
  virtual function void write_timing(jtag_timing_info_s timing_info);
    update_timing_metrics(timing_info);
  endfunction
  
  // Write function for transactions
  virtual function void write_trans(jtag_base_transaction trans);
    update_transaction_metrics(trans);
  endfunction
  
  //=============================================================================
  // Performance Metrics Update Functions
  //=============================================================================
  
  virtual function void update_performance_metrics(jtag_performance_metrics_s perf_metrics);
    real current_time = $realtime;
    real time_delta;
    
    // Update transaction counts
    total_transactions++;
    
    // Update timing
    if (last_transaction_time > 0.0) begin
      time_delta = current_time - last_transaction_time;
    end else begin
      time_delta = current_time - simulation_start_time;
    end
    last_transaction_time = current_time;
    total_simulation_time = current_time - simulation_start_time;
    
    // Update throughput metrics
    if (time_delta > 0.0) begin
      instantaneous_throughput = 1e9 / time_delta; // Convert ns to Hz
      
      // Update peak and minimum throughput
      if (instantaneous_throughput > peak_throughput) begin
        peak_throughput = instantaneous_throughput;
      end
      if (instantaneous_throughput < minimum_throughput) begin
        minimum_throughput = instantaneous_throughput;
      end
      
      // Calculate average throughput
      if (total_simulation_time > 0.0) begin
        average_throughput = (real'(total_transactions) * 1e9) / total_simulation_time;
      end
    end
    
    // Update latency metrics
    real transaction_latency = perf_metrics.average_transaction_time;
    total_latency += transaction_latency;
    average_latency = total_latency / real'(total_transactions);
    
    if (transaction_latency < min_latency) min_latency = transaction_latency;
    if (transaction_latency > max_latency) max_latency = transaction_latency;
    
    // Update bandwidth metrics
    data_bits_transferred += perf_metrics.data_bits_processed;
    if (total_simulation_time > 0.0) begin
      effective_bandwidth = (data_bits_transferred * 1e9) / total_simulation_time; // bits per second
      theoretical_bandwidth = average_throughput * 64.0; // Assuming 64-bit max data width
      if (theoretical_bandwidth > 0.0) begin
        bandwidth_utilization = (effective_bandwidth / theoretical_bandwidth) * 100.0;
      end
    end
    
    // Update quality metrics
    data_integrity_score = perf_metrics.data_integrity_score;
    overall_quality_score = perf_metrics.overall_performance_score;
    
    // Update history for trend analysis
    throughput_history.push_back(instantaneous_throughput);
    latency_history.push_back(transaction_latency);
    bandwidth_history.push_back(bandwidth_utilization);
    
    // Maintain window size
    if (throughput_history.size() > PERFORMANCE_WINDOW_SIZE) throughput_history.pop_front();
    if (latency_history.size() > PERFORMANCE_WINDOW_SIZE) latency_history.pop_front();
    if (bandwidth_history.size() > PERFORMANCE_WINDOW_SIZE) bandwidth_history.pop_front();
    
    // Calculate latency variance
    calculate_latency_variance();
  endfunction
  
  virtual function void update_timing_metrics(jtag_timing_info_s timing_info);
    // Update timing violation tracking
    if (!timing_info.is_timing_valid) begin
      total_timing_violations += timing_info.violation_count;
    end
    
    // Calculate timing violation rate
    if (total_transactions > 0) begin
      timing_violation_rate = (total_timing_violations / real'(total_transactions)) * 100.0;
    end
    
    // Update average timing measurements
    average_setup_time = ((average_setup_time * real'(total_transactions - 1)) + timing_info.measured_setup_time) / real'(total_transactions);
    average_hold_time = ((average_hold_time * real'(total_transactions - 1)) + timing_info.measured_hold_time) / real'(total_transactions);
    average_clock_period = ((average_clock_period * real'(total_transactions - 1)) + timing_info.measured_period) / real'(total_transactions);
  endfunction
  
  virtual function void update_transaction_metrics(jtag_base_transaction trans);
    // Update transaction status counts
    case (trans.status)
      TRANS_SUCCESS: successful_transactions++;
      TRANS_ERROR: failed_transactions++;
      TRANS_TIMEOUT: timeout_transactions++;
      default: ; // Unknown status
    endcase
    
    // Calculate error rate
    if (total_transactions > 0) begin
      error_rate = (real'(failed_transactions + timeout_transactions) / real'(total_transactions)) * 100.0;
    end
    
    // Update error rate history
    error_rate_history.push_back(error_rate);
    if (error_rate_history.size() > PERFORMANCE_WINDOW_SIZE) begin
      error_rate_history.pop_front();
    end
    
    // Update protocol compliance score based on transaction compliance
    if (trans.is_compliant) begin
      protocol_compliance_score = ((protocol_compliance_score * real'(total_transactions - 1)) + 100.0) / real'(total_transactions);
    end else begin
      protocol_compliance_score = ((protocol_compliance_score * real'(total_transactions - 1)) + 0.0) / real'(total_transactions);
    end
  endfunction
  
  virtual function void calculate_latency_variance();
    real sum_squared_diff = 0.0;
    int i;
    
    if (latency_history.size() > 1) begin
      for (i = 0; i < latency_history.size(); i++) begin
        sum_squared_diff += (latency_history[i] - average_latency) * (latency_history[i] - average_latency);
      end
      latency_variance = sum_squared_diff / real'(latency_history.size());
    end
  endfunction
  
  //=============================================================================
  // Performance Threshold Checking
  //=============================================================================
  
  virtual function void check_performance_thresholds(jtag_performance_metrics_s perf_metrics);
    jtag_performance_alert_s alert;
    
    // Check throughput threshold
    if (instantaneous_throughput < throughput_threshold) begin
      alert.alert_type = PERF_ALERT_THROUGHPUT;
      alert.severity = ALERT_WARNING;
      alert.timestamp = $realtime;
      alert.message = $sformatf("Throughput %0.2f Hz below threshold %0.2f Hz", 
                               instantaneous_throughput, throughput_threshold);
      alert.current_value = instantaneous_throughput;
      alert.threshold_value = throughput_threshold;
      alert_ap.write(alert);
      throughput_alerts++;
    end
    
    // Check latency threshold
    if (perf_metrics.average_transaction_time > latency_threshold) begin
      alert.alert_type = PERF_ALERT_LATENCY;
      alert.severity = ALERT_WARNING;
      alert.timestamp = $realtime;
      alert.message = $sformatf("Latency %0.2f ns above threshold %0.2f ns", 
                               perf_metrics.average_transaction_time, latency_threshold);
      alert.current_value = perf_metrics.average_transaction_time;
      alert.threshold_value = latency_threshold;
      alert_ap.write(alert);
      latency_alerts++;
    end
    
    // Check error rate threshold
    if (error_rate > error_rate_threshold) begin
      alert.alert_type = PERF_ALERT_ERROR_RATE;
      alert.severity = ALERT_ERROR;
      alert.timestamp = $realtime;
      alert.message = $sformatf("Error rate %0.2f%% above threshold %0.2f%%", 
                               error_rate, error_rate_threshold);
      alert.current_value = error_rate;
      alert.threshold_value = error_rate_threshold;
      alert_ap.write(alert);
      error_rate_alerts++;
    end
    
    // Check bandwidth utilization threshold
    if (bandwidth_utilization < bandwidth_threshold) begin
      alert.alert_type = PERF_ALERT_BANDWIDTH;
      alert.severity = ALERT_INFO;
      alert.timestamp = $realtime;
      alert.message = $sformatf("Bandwidth utilization %0.2f%% below threshold %0.2f%%", 
                               bandwidth_utilization, bandwidth_threshold);
      alert.current_value = bandwidth_utilization;
      alert.threshold_value = bandwidth_threshold;
      alert_ap.write(alert);
      bandwidth_alerts++;
    end
  endfunction
  
  //=============================================================================
  // Performance Reporting Functions
  //=============================================================================
  
  virtual function void generate_performance_report();
    jtag_performance_report_s report;
    
    // Initialize report
    report.timestamp = $realtime;
    report.simulation_time = total_simulation_time;
    report.total_transactions = total_transactions;
    
    // Throughput metrics
    report.instantaneous_throughput = instantaneous_throughput;
    report.average_throughput = average_throughput;
    report.peak_throughput = peak_throughput;
    report.minimum_throughput = minimum_throughput;
    
    // Latency metrics
    report.average_latency = average_latency;
    report.min_latency = min_latency;
    report.max_latency = max_latency;
    report.latency_variance = latency_variance;
    
    // Timing metrics
    report.timing_violation_rate = timing_violation_rate;
    report.average_setup_time = average_setup_time;
    report.average_hold_time = average_hold_time;
    report.average_clock_period = average_clock_period;
    
    // Bandwidth metrics
    report.effective_bandwidth = effective_bandwidth;
    report.theoretical_bandwidth = theoretical_bandwidth;
    report.bandwidth_utilization = bandwidth_utilization;
    
    // Quality metrics
    report.error_rate = error_rate;
    report.data_integrity_score = data_integrity_score;
    report.protocol_compliance_score = protocol_compliance_score;
    report.overall_quality_score = overall_quality_score;
    
    // Transaction statistics
    report.successful_transactions = successful_transactions;
    report.failed_transactions = failed_transactions;
    report.timeout_transactions = timeout_transactions;
    
    // Alert statistics
    report.throughput_alerts = throughput_alerts;
    report.latency_alerts = latency_alerts;
    report.error_rate_alerts = error_rate_alerts;
    report.bandwidth_alerts = bandwidth_alerts;
    
    // Send report
    report_ap.write(report);
  endfunction
  
  virtual function void print_performance_summary();
    `uvm_info("JTAG_PERFORMANCE_MONITOR", "=== Performance Summary ===", UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Simulation time: %0.2f ns", total_simulation_time), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Total transactions: %0d", total_transactions), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Successful: %0d, Failed: %0d, Timeout: %0d", 
                                                    successful_transactions, failed_transactions, timeout_transactions), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", "--- Throughput Metrics ---", UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Average throughput: %0.2f Hz", average_throughput), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Peak throughput: %0.2f Hz", peak_throughput), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Minimum throughput: %0.2f Hz", minimum_throughput), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", "--- Latency Metrics ---", UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Average latency: %0.2f ns", average_latency), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Min latency: %0.2f ns", min_latency), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Max latency: %0.2f ns", max_latency), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Latency variance: %0.2f", latency_variance), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", "--- Quality Metrics ---", UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Error rate: %0.2f%%", error_rate), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Data integrity score: %0.2f%%", data_integrity_score), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Protocol compliance score: %0.2f%%", protocol_compliance_score), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Overall quality score: %0.2f%%", overall_quality_score), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", "--- Bandwidth Metrics ---", UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Effective bandwidth: %0.2f bps", effective_bandwidth), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Bandwidth utilization: %0.2f%%", bandwidth_utilization), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", "--- Alert Statistics ---", UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Throughput alerts: %0d", throughput_alerts), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Latency alerts: %0d", latency_alerts), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Error rate alerts: %0d", error_rate_alerts), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", $sformatf("Bandwidth alerts: %0d", bandwidth_alerts), UVM_LOW)
    `uvm_info("JTAG_PERFORMANCE_MONITOR", "=========================", UVM_LOW)
  endfunction
  
  virtual function void final_phase(uvm_phase phase);
    super.final_phase(phase);
    generate_performance_report();
    print_performance_summary();
  endfunction
  
  //=============================================================================
  // Trend Analysis Functions
  //=============================================================================
  
  virtual function real get_throughput_trend();
    real trend = 0.0;
    int i;
    
    if (throughput_history.size() > 10) begin
      // Simple linear trend calculation
      real first_half_avg = 0.0;
      real second_half_avg = 0.0;
      int half_size = throughput_history.size() / 2;
      
      for (i = 0; i < half_size; i++) begin
        first_half_avg += throughput_history[i];
      end
      first_half_avg = first_half_avg / real'(half_size);
      
      for (i = half_size; i < throughput_history.size(); i++) begin
        second_half_avg += throughput_history[i];
      end
      second_half_avg = second_half_avg / real'(throughput_history.size() - half_size);
      
      trend = ((second_half_avg - first_half_avg) / first_half_avg) * 100.0;
    end
    
    return trend;
  endfunction
  
  virtual function real get_latency_trend();
    real trend = 0.0;
    int i;
    
    if (latency_history.size() > 10) begin
      real first_half_avg = 0.0;
      real second_half_avg = 0.0;
      int half_size = latency_history.size() / 2;
      
      for (i = 0; i < half_size; i++) begin
        first_half_avg += latency_history[i];
      end
      first_half_avg = first_half_avg / real'(half_size);
      
      for (i = half_size; i < latency_history.size(); i++) begin
        second_half_avg += latency_history[i];
      end
      second_half_avg = second_half_avg / real'(latency_history.size() - half_size);
      
      trend = ((second_half_avg - first_half_avg) / first_half_avg) * 100.0;
    end
    
    return trend;
  endfunction
  
endclass

`endif // JTAG_PERFORMANCE_MONITOR_SVH