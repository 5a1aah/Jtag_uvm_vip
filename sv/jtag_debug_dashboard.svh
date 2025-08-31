`ifndef JTAG_DEBUG_DASHBOARD__SVH
 `define JTAG_DEBUG_DASHBOARD__SVH

//=============================================================================
// JTAG Debug Dashboard
// Comprehensive monitoring and visualization component
//=============================================================================

class jtag_debug_dashboard extends uvm_component;
  
  // Analysis imports for receiving data from various components
  uvm_analysis_imp_compliance #(jtag_compliance_report, jtag_debug_dashboard) compliance_analysis_imp;
  uvm_analysis_imp_timing #(jtag_timing_report, jtag_debug_dashboard) timing_analysis_imp;
  uvm_analysis_imp_performance #(jtag_performance_report, jtag_debug_dashboard) performance_analysis_imp;
  uvm_analysis_imp_coverage #(jtag_coverage_report, jtag_debug_dashboard) coverage_analysis_imp;
  uvm_analysis_imp_error #(jtag_error_report, jtag_debug_dashboard) error_analysis_imp;
  
  // Analysis ports for dashboard outputs
  uvm_analysis_port #(jtag_dashboard_report) dashboard_report_ap;
  uvm_analysis_port #(jtag_alert_report) alert_report_ap;
  
  // Configuration objects
  jtag_protocol_config protocol_cfg;
  jtag_timing_config timing_cfg;
  jtag_coverage_config coverage_cfg;
  jtag_performance_config performance_cfg;
  
  // Dashboard configuration
  bit enable_real_time_monitoring;
  bit enable_alert_system;
  bit enable_trend_analysis;
  bit enable_auto_reporting;
  time reporting_interval;
  time alert_check_interval;
  
  // Data storage and tracking
  jtag_compliance_report compliance_reports[$];
  jtag_timing_report timing_reports[$];
  jtag_performance_report performance_reports[$];
  jtag_coverage_report coverage_reports[$];
  jtag_error_report error_reports[$];
  
  // Dashboard metrics and statistics
  typedef struct {
    real compliance_score;
    real timing_score;
    real performance_score;
    real coverage_score;
    real overall_health_score;
    int unsigned total_violations;
    int unsigned critical_alerts;
    int unsigned warnings;
    time last_update_time;
  } dashboard_metrics_t;
  
  dashboard_metrics_t current_metrics;
  dashboard_metrics_t historical_metrics[$];
  
  // Alert thresholds and configuration
  typedef struct {
    real min_compliance_score;
    real min_timing_score;
    real min_performance_score;
    real min_coverage_score;
    real min_overall_score;
    int unsigned max_violations_per_interval;
    int unsigned max_errors_per_interval;
  } alert_thresholds_t;
  
  alert_thresholds_t alert_thresholds;
  
  // Trend analysis data
  typedef struct {
    real values[$];
    real trend_slope;
    real trend_correlation;
    bit is_improving;
    bit is_degrading;
  } trend_data_t;
  
  trend_data_t compliance_trend;
  trend_data_t timing_trend;
  trend_data_t performance_trend;
  trend_data_t coverage_trend;
  
  // Events for synchronization
  event dashboard_updated;
  event alert_triggered;
  event report_generated;
  
  // Statistics and counters
  int unsigned total_reports_processed;
  int unsigned total_alerts_generated;
  int unsigned total_dashboard_updates;
  
  `uvm_component_utils_begin(jtag_debug_dashboard)
  `uvm_field_int(enable_real_time_monitoring, UVM_DEFAULT)
  `uvm_field_int(enable_alert_system, UVM_DEFAULT)
  `uvm_field_int(total_reports_processed, UVM_DEFAULT)
  `uvm_field_int(total_alerts_generated, UVM_DEFAULT)
  `uvm_component_utils_end
  
  //=============================================================================
  // Constructor and Build Phase
  //=============================================================================
  
  function new(string name = "jtag_debug_dashboard", uvm_component parent = null);
    super.new(name, parent);
    
    // Initialize dashboard configuration
    enable_real_time_monitoring = 1;
    enable_alert_system = 1;
    enable_trend_analysis = 1;
    enable_auto_reporting = 1;
    reporting_interval = 1ms;
    alert_check_interval = 100us;
    
    // Initialize statistics
    total_reports_processed = 0;
    total_alerts_generated = 0;
    total_dashboard_updates = 0;
    
    // Initialize metrics
    initialize_metrics();
    
    // Initialize alert thresholds
    initialize_alert_thresholds();
    
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Create analysis imports and ports
    compliance_analysis_imp = new("compliance_analysis_imp", this);
    timing_analysis_imp = new("timing_analysis_imp", this);
    performance_analysis_imp = new("performance_analysis_imp", this);
    coverage_analysis_imp = new("coverage_analysis_imp", this);
    error_analysis_imp = new("error_analysis_imp", this);
    
    dashboard_report_ap = new("dashboard_report_ap", this);
    alert_report_ap = new("alert_report_ap", this);
    
    // Get configuration objects
    if(!uvm_config_db#(jtag_protocol_config)::get(this, "", "protocol_cfg", protocol_cfg)) begin
      `uvm_info("JTAG_DASH_INFO", "Creating default protocol configuration", UVM_LOW)
      protocol_cfg = jtag_protocol_config::type_id::create("protocol_cfg");
    end
    
    if(!uvm_config_db#(jtag_timing_config)::get(this, "", "timing_cfg", timing_cfg)) begin
      `uvm_info("JTAG_DASH_INFO", "Creating default timing configuration", UVM_LOW)
      timing_cfg = jtag_timing_config::type_id::create("timing_cfg");
    end
    
    if(!uvm_config_db#(jtag_coverage_config)::get(this, "", "coverage_cfg", coverage_cfg)) begin
      `uvm_info("JTAG_DASH_INFO", "Creating default coverage configuration", UVM_LOW)
      coverage_cfg = jtag_coverage_config::type_id::create("coverage_cfg");
    end
    
    if(!uvm_config_db#(jtag_performance_config)::get(this, "", "performance_cfg", performance_cfg)) begin
      `uvm_info("JTAG_DASH_INFO", "Creating default performance configuration", UVM_LOW)
      performance_cfg = jtag_performance_config::type_id::create("performance_cfg");
    end
    
  endfunction
  
  virtual function void initialize_metrics();
    current_metrics.compliance_score = 100.0;
    current_metrics.timing_score = 100.0;
    current_metrics.performance_score = 100.0;
    current_metrics.coverage_score = 0.0;
    current_metrics.overall_health_score = 100.0;
    current_metrics.total_violations = 0;
    current_metrics.critical_alerts = 0;
    current_metrics.warnings = 0;
    current_metrics.last_update_time = $time;
  endfunction
  
  virtual function void initialize_alert_thresholds();
    alert_thresholds.min_compliance_score = 90.0;
    alert_thresholds.min_timing_score = 85.0;
    alert_thresholds.min_performance_score = 80.0;
    alert_thresholds.min_coverage_score = 70.0;
    alert_thresholds.min_overall_score = 85.0;
    alert_thresholds.max_violations_per_interval = 10;
    alert_thresholds.max_errors_per_interval = 5;
  endfunction
  
  //=============================================================================
  // Analysis Import Write Functions
  //=============================================================================
  
  virtual function void write_compliance(jtag_compliance_report report);
    // Store the compliance report
    compliance_reports.push_back(report);
    total_reports_processed++;
    
    // Update compliance metrics
    update_compliance_metrics(report);
    
    // Update dashboard
    update_dashboard();
    
    `uvm_info("JTAG_DASH_COMPLIANCE", $sformatf("Received compliance report: %s", 
                                                report.convert2string()), UVM_HIGH)
    
  endfunction
  
  virtual function void write_timing(jtag_timing_report report);
    // Store the timing report
    timing_reports.push_back(report);
    total_reports_processed++;
    
    // Update timing metrics
    update_timing_metrics(report);
    
    // Update dashboard
    update_dashboard();
    
    `uvm_info("JTAG_DASH_TIMING", $sformatf("Received timing report: %s", 
                                            report.convert2string()), UVM_HIGH)
    
  endfunction
  
  virtual function void write_performance(jtag_performance_report report);
    // Store the performance report
    performance_reports.push_back(report);
    total_reports_processed++;
    
    // Update performance metrics
    update_performance_metrics(report);
    
    // Update dashboard
    update_dashboard();
    
    `uvm_info("JTAG_DASH_PERFORMANCE", $sformatf("Received performance report: %s", 
                                                  report.convert2string()), UVM_HIGH)
    
  endfunction
  
  virtual function void write_coverage(jtag_coverage_report report);
    // Store the coverage report
    coverage_reports.push_back(report);
    total_reports_processed++;
    
    // Update coverage metrics
    update_coverage_metrics(report);
    
    // Update dashboard
    update_dashboard();
    
    `uvm_info("JTAG_DASH_COVERAGE", $sformatf("Received coverage report: %s", 
                                              report.convert2string()), UVM_HIGH)
    
  endfunction
  
  virtual function void write_error(jtag_error_report report);
    // Store the error report
    error_reports.push_back(report);
    total_reports_processed++;
    
    // Update error metrics
    update_error_metrics(report);
    
    // Update dashboard
    update_dashboard();
    
    // Check for immediate alerts
    if (enable_alert_system) begin
      check_error_alerts(report);
    end
    
    `uvm_info("JTAG_DASH_ERROR", $sformatf("Received error report: %s", 
                                           report.convert2string()), UVM_HIGH)
    
  endfunction
  
  //=============================================================================
  // Metrics Update Functions
  //=============================================================================
  
  virtual function void update_compliance_metrics(jtag_compliance_report report);
    real new_score;
    
    // Calculate compliance score based on violations
    if (report.total_checks > 0) begin
      new_score = ((real'(report.total_checks - report.total_violations) / real'(report.total_checks)) * 100.0);
    end else begin
      new_score = 100.0;
    end
    
    // Update current metrics with weighted average
    current_metrics.compliance_score = (current_metrics.compliance_score * 0.8) + (new_score * 0.2);
    current_metrics.total_violations += report.total_violations;
    
    // Update trend data
    if (enable_trend_analysis) begin
      update_trend_data(compliance_trend, new_score);
    end
    
  endfunction
  
  virtual function void update_timing_metrics(jtag_timing_report report);
    real new_score;
    
    // Calculate timing score based on violations
    if (report.total_measurements > 0) begin
      new_score = ((real'(report.total_measurements - report.timing_violations) / real'(report.total_measurements)) * 100.0);
    end else begin
      new_score = 100.0;
    end
    
    // Update current metrics with weighted average
    current_metrics.timing_score = (current_metrics.timing_score * 0.8) + (new_score * 0.2);
    
    // Update trend data
    if (enable_trend_analysis) begin
      update_trend_data(timing_trend, new_score);
    end
    
  endfunction
  
  virtual function void update_performance_metrics(jtag_performance_report report);
    real new_score;
    
    // Calculate performance score based on throughput and latency
    new_score = calculate_performance_score(report);
    
    // Update current metrics with weighted average
    current_metrics.performance_score = (current_metrics.performance_score * 0.8) + (new_score * 0.2);
    
    // Update trend data
    if (enable_trend_analysis) begin
      update_trend_data(performance_trend, new_score);
    end
    
  endfunction
  
  virtual function void update_coverage_metrics(jtag_coverage_report report);
    // Update coverage score directly from report
    current_metrics.coverage_score = report.overall_coverage;
    
    // Update trend data
    if (enable_trend_analysis) begin
      update_trend_data(coverage_trend, report.overall_coverage);
    end
    
  endfunction
  
  virtual function void update_error_metrics(jtag_error_report report);
    // Increment error counters based on severity
    case (report.severity)
      UVM_ERROR, UVM_FATAL: current_metrics.critical_alerts++;
      UVM_WARNING: current_metrics.warnings++;
      default: ; // Info messages don't affect metrics
    endcase
    
  endfunction
  
  virtual function real calculate_performance_score(jtag_performance_report report);
    real throughput_score, latency_score, bandwidth_score;
    real combined_score;
    
    // Calculate throughput score (higher is better)
    if (performance_cfg.target_throughput > 0) begin
      throughput_score = (report.current_throughput / performance_cfg.target_throughput) * 100.0;
      if (throughput_score > 100.0) throughput_score = 100.0;
    end else begin
      throughput_score = 100.0;
    end
    
    // Calculate latency score (lower is better)
    if (performance_cfg.max_latency > 0) begin
      latency_score = ((performance_cfg.max_latency - report.average_latency) / performance_cfg.max_latency) * 100.0;
      if (latency_score < 0.0) latency_score = 0.0;
    end else begin
      latency_score = 100.0;
    end
    
    // Calculate bandwidth score
    if (performance_cfg.target_bandwidth > 0) begin
      bandwidth_score = (report.bandwidth_utilization / performance_cfg.target_bandwidth) * 100.0;
      if (bandwidth_score > 100.0) bandwidth_score = 100.0;
    end else begin
      bandwidth_score = 100.0;
    end
    
    // Combine scores with weights
    combined_score = (throughput_score * 0.4) + (latency_score * 0.4) + (bandwidth_score * 0.2);
    
    return combined_score;
  endfunction
  
  //=============================================================================
  // Dashboard Update and Management
  //=============================================================================
  
  virtual function void update_dashboard();
    // Calculate overall health score
    calculate_overall_health_score();
    
    // Update timestamp
    current_metrics.last_update_time = $time;
    
    // Store historical data
    store_historical_metrics();
    
    // Increment update counter
    total_dashboard_updates++;
    
    // Check for alerts
    if (enable_alert_system) begin
      check_dashboard_alerts();
    end
    
    // Generate dashboard report if auto-reporting is enabled
    if (enable_auto_reporting) begin
      generate_dashboard_report();
    end
    
    // Trigger dashboard updated event
    -> dashboard_updated;
    
    `uvm_info("JTAG_DASH_UPDATE", $sformatf("Dashboard updated #%0d - Overall Health: %0.2f%%", 
                                           total_dashboard_updates, current_metrics.overall_health_score), UVM_MEDIUM)
    
  endfunction
  
  virtual function void calculate_overall_health_score();
    real weighted_score;
    
    // Calculate weighted average of all scores
    weighted_score = (current_metrics.compliance_score * 0.3) +
                    (current_metrics.timing_score * 0.25) +
                    (current_metrics.performance_score * 0.25) +
                    (current_metrics.coverage_score * 0.2);
    
    // Apply penalties for violations and alerts
    if (current_metrics.critical_alerts > 0) begin
      weighted_score -= (current_metrics.critical_alerts * 5.0); // 5% penalty per critical alert
    end
    
    if (current_metrics.warnings > 5) begin
      weighted_score -= ((current_metrics.warnings - 5) * 1.0); // 1% penalty per warning above 5
    end
    
    // Ensure score is within bounds
    if (weighted_score < 0.0) weighted_score = 0.0;
    if (weighted_score > 100.0) weighted_score = 100.0;
    
    current_metrics.overall_health_score = weighted_score;
    
  endfunction
  
  virtual function void store_historical_metrics();
    dashboard_metrics_t historical_snapshot;
    
    // Create a snapshot of current metrics
    historical_snapshot = current_metrics;
    
    // Add to historical data
    historical_metrics.push_back(historical_snapshot);
    
    // Limit historical data size to prevent memory issues
    if (historical_metrics.size() > 1000) begin
      historical_metrics.pop_front();
    end
    
  endfunction
  
  //=============================================================================
  // Trend Analysis
  //=============================================================================
  
  virtual function void update_trend_data(ref trend_data_t trend, real new_value);
    // Add new value to trend data
    trend.values.push_back(new_value);
    
    // Limit trend data size
    if (trend.values.size() > 50) begin
      trend.values.pop_front();
    end
    
    // Calculate trend if we have enough data points
    if (trend.values.size() >= 5) begin
      calculate_trend_statistics(trend);
    end
    
  endfunction
  
  virtual function void calculate_trend_statistics(ref trend_data_t trend);
    real sum_x, sum_y, sum_xy, sum_x2;
    real n, slope, correlation;
    int i;
    
    n = real'(trend.values.size());
    sum_x = 0.0; sum_y = 0.0; sum_xy = 0.0; sum_x2 = 0.0;
    
    // Calculate sums for linear regression
    for (i = 0; i < trend.values.size(); i++) begin
      real x = real'(i);
      real y = trend.values[i];
      
      sum_x += x;
      sum_y += y;
      sum_xy += (x * y);
      sum_x2 += (x * x);
    end
    
    // Calculate slope (trend)
    if ((n * sum_x2 - sum_x * sum_x) != 0.0) begin
      slope = (n * sum_xy - sum_x * sum_y) / (n * sum_x2 - sum_x * sum_x);
    end else begin
      slope = 0.0;
    end
    
    // Store trend information
    trend.trend_slope = slope;
    trend.is_improving = (slope > 0.1); // Improving if slope > 0.1
    trend.is_degrading = (slope < -0.1); // Degrading if slope < -0.1
    
  endfunction
  
  //=============================================================================
  // Alert System
  //=============================================================================
  
  virtual function void check_dashboard_alerts();
    jtag_alert_report alert;
    
    // Check compliance score
    if (current_metrics.compliance_score < alert_thresholds.min_compliance_score) begin
      alert = create_alert("COMPLIANCE_LOW", UVM_WARNING, 
                          $sformatf("Compliance score (%0.2f%%) below threshold (%0.2f%%)", 
                                   current_metrics.compliance_score, alert_thresholds.min_compliance_score));
      send_alert(alert);
    end
    
    // Check timing score
    if (current_metrics.timing_score < alert_thresholds.min_timing_score) begin
      alert = create_alert("TIMING_LOW", UVM_WARNING, 
                          $sformatf("Timing score (%0.2f%%) below threshold (%0.2f%%)", 
                                   current_metrics.timing_score, alert_thresholds.min_timing_score));
      send_alert(alert);
    end
    
    // Check performance score
    if (current_metrics.performance_score < alert_thresholds.min_performance_score) begin
      alert = create_alert("PERFORMANCE_LOW", UVM_WARNING, 
                          $sformatf("Performance score (%0.2f%%) below threshold (%0.2f%%)", 
                                   current_metrics.performance_score, alert_thresholds.min_performance_score));
      send_alert(alert);
    end
    
    // Check coverage score
    if (current_metrics.coverage_score < alert_thresholds.min_coverage_score) begin
      alert = create_alert("COVERAGE_LOW", UVM_INFO, 
                          $sformatf("Coverage score (%0.2f%%) below threshold (%0.2f%%)", 
                                   current_metrics.coverage_score, alert_thresholds.min_coverage_score));
      send_alert(alert);
    end
    
    // Check overall health score
    if (current_metrics.overall_health_score < alert_thresholds.min_overall_score) begin
      alert = create_alert("HEALTH_LOW", UVM_ERROR, 
                          $sformatf("Overall health score (%0.2f%%) below threshold (%0.2f%%)", 
                                   current_metrics.overall_health_score, alert_thresholds.min_overall_score));
      send_alert(alert);
    end
    
    // Check for trend degradation
    if (enable_trend_analysis) begin
      check_trend_alerts();
    end
    
  endfunction
  
  virtual function void check_error_alerts(jtag_error_report error_report);
    jtag_alert_report alert;
    
    // Generate immediate alert for critical errors
    if (error_report.severity == UVM_ERROR || error_report.severity == UVM_FATAL) begin
      alert = create_alert("CRITICAL_ERROR", UVM_ERROR, 
                          $sformatf("Critical error detected: %s", error_report.error_description));
      send_alert(alert);
    end
    
  endfunction
  
  virtual function void check_trend_alerts();
    jtag_alert_report alert;
    
    // Check for degrading trends
    if (compliance_trend.is_degrading) begin
      alert = create_alert("COMPLIANCE_DEGRADING", UVM_WARNING, 
                          "Compliance score showing degrading trend");
      send_alert(alert);
    end
    
    if (timing_trend.is_degrading) begin
      alert = create_alert("TIMING_DEGRADING", UVM_WARNING, 
                          "Timing score showing degrading trend");
      send_alert(alert);
    end
    
    if (performance_trend.is_degrading) begin
      alert = create_alert("PERFORMANCE_DEGRADING", UVM_WARNING, 
                          "Performance score showing degrading trend");
      send_alert(alert);
    end
    
  endfunction
  
  virtual function jtag_alert_report create_alert(string alert_type, uvm_severity severity, string description);
    jtag_alert_report alert;
    
    alert = jtag_alert_report::type_id::create("alert_report");
    alert.alert_type = alert_type;
    alert.severity = severity;
    alert.description = description;
    alert.timestamp = $time;
    alert.dashboard_metrics = current_metrics;
    
    return alert;
  endfunction
  
  virtual function void send_alert(jtag_alert_report alert);
    // Send alert through analysis port
    alert_report_ap.write(alert);
    
    // Increment alert counter
    total_alerts_generated++;
    
    // Log the alert
    `uvm_info("JTAG_DASH_ALERT", $sformatf("Alert #%0d: %s", total_alerts_generated, alert.convert2string()), UVM_LOW)
    
    // Trigger alert event
    -> alert_triggered;
    
  endfunction
  
  //=============================================================================
  // Reporting
  //=============================================================================
  
  virtual function void generate_dashboard_report();
    jtag_dashboard_report report;
    
    report = jtag_dashboard_report::type_id::create("dashboard_report");
    
    // Fill report with current metrics and data
    report.timestamp = $time;
    report.metrics = current_metrics;
    report.compliance_trend = compliance_trend;
    report.timing_trend = timing_trend;
    report.performance_trend = performance_trend;
    report.coverage_trend = coverage_trend;
    report.total_reports_processed = total_reports_processed;
    report.total_alerts_generated = total_alerts_generated;
    
    // Send report through analysis port
    dashboard_report_ap.write(report);
    
    // Trigger report event
    -> report_generated;
    
  endfunction
  
  //=============================================================================
  // Run Phase
  //=============================================================================
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    fork
      if (enable_real_time_monitoring) periodic_monitoring();
      if (enable_auto_reporting) periodic_reporting();
      if (enable_alert_system) periodic_alert_checking();
    join_none
    
  endtask
  
  virtual task periodic_monitoring();
    forever begin
      #(alert_check_interval);
      
      // Perform periodic health checks
      if (enable_alert_system) begin
        check_dashboard_alerts();
      end
    end
  endtask
  
  virtual task periodic_reporting();
    forever begin
      #(reporting_interval);
      
      // Generate periodic dashboard report
      generate_dashboard_report();
    end
  endtask
  
  virtual task periodic_alert_checking();
    forever begin
      #(alert_check_interval / 2);
      
      // Check for any pending alerts or threshold violations
      check_dashboard_alerts();
    end
  endtask
  
  //=============================================================================
  // Control and Configuration Functions
  //=============================================================================
  
  virtual function void set_alert_thresholds(alert_thresholds_t new_thresholds);
    alert_thresholds = new_thresholds;
    `uvm_info("JTAG_DASH_CONFIG", "Alert thresholds updated", UVM_LOW)
  endfunction
  
  virtual function void enable_monitoring(bit enable);
    enable_real_time_monitoring = enable;
    `uvm_info("JTAG_DASH_CONFIG", $sformatf("Real-time monitoring %s", enable ? "enabled" : "disabled"), UVM_LOW)
  endfunction
  
  virtual function void enable_alerts(bit enable);
    enable_alert_system = enable;
    `uvm_info("JTAG_DASH_CONFIG", $sformatf("Alert system %s", enable ? "enabled" : "disabled"), UVM_LOW)
  endfunction
  
  virtual function void set_reporting_interval(time interval);
    reporting_interval = interval;
    `uvm_info("JTAG_DASH_CONFIG", $sformatf("Reporting interval set to %0t", interval), UVM_LOW)
  endfunction
  
  //=============================================================================
  // Information and Status Functions
  //=============================================================================
  
  virtual function dashboard_metrics_t get_current_metrics();
    return current_metrics;
  endfunction
  
  virtual function real get_overall_health_score();
    return current_metrics.overall_health_score;
  endfunction
  
  virtual function void print_dashboard_status();
    `uvm_info("JTAG_DASH_STATUS", "=== JTAG Debug Dashboard Status ===", UVM_LOW)
    `uvm_info("JTAG_DASH_STATUS", $sformatf("Overall Health Score: %0.2f%%", current_metrics.overall_health_score), UVM_LOW)
    `uvm_info("JTAG_DASH_STATUS", $sformatf("Compliance Score: %0.2f%%", current_metrics.compliance_score), UVM_LOW)
    `uvm_info("JTAG_DASH_STATUS", $sformatf("Timing Score: %0.2f%%", current_metrics.timing_score), UVM_LOW)
    `uvm_info("JTAG_DASH_STATUS", $sformatf("Performance Score: %0.2f%%", current_metrics.performance_score), UVM_LOW)
    `uvm_info("JTAG_DASH_STATUS", $sformatf("Coverage Score: %0.2f%%", current_metrics.coverage_score), UVM_LOW)
    `uvm_info("JTAG_DASH_STATUS", $sformatf("Total Violations: %0d", current_metrics.total_violations), UVM_LOW)
    `uvm_info("JTAG_DASH_STATUS", $sformatf("Critical Alerts: %0d", current_metrics.critical_alerts), UVM_LOW)
    `uvm_info("JTAG_DASH_STATUS", $sformatf("Warnings: %0d", current_metrics.warnings), UVM_LOW)
    `uvm_info("JTAG_DASH_STATUS", $sformatf("Reports Processed: %0d", total_reports_processed), UVM_LOW)
    `uvm_info("JTAG_DASH_STATUS", $sformatf("Alerts Generated: %0d", total_alerts_generated), UVM_LOW)
    `uvm_info("JTAG_DASH_STATUS", "=== End of Dashboard Status ===", UVM_LOW)
  endfunction
  
  virtual function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    
    // Generate final dashboard report
    generate_dashboard_report();
    
    // Print final status
    print_dashboard_status();
    
  endfunction
  
endclass // jtag_debug_dashboard

//=============================================================================
// JTAG Dashboard Report Class
//=============================================================================

class jtag_dashboard_report extends uvm_object;
  
  time timestamp;
  jtag_debug_dashboard::dashboard_metrics_t metrics;
  jtag_debug_dashboard::trend_data_t compliance_trend;
  jtag_debug_dashboard::trend_data_t timing_trend;
  jtag_debug_dashboard::trend_data_t performance_trend;
  jtag_debug_dashboard::trend_data_t coverage_trend;
  int unsigned total_reports_processed;
  int unsigned total_alerts_generated;
  
  `uvm_object_utils_begin(jtag_dashboard_report)
  `uvm_field_int(timestamp, UVM_DEFAULT)
  `uvm_field_int(total_reports_processed, UVM_DEFAULT)
  `uvm_field_int(total_alerts_generated, UVM_DEFAULT)
  `uvm_object_utils_end
  
  function new(string name = "jtag_dashboard_report");
    super.new(name);
  endfunction
  
  virtual function string convert2string();
    return $sformatf("Dashboard Report @ %0t: Health=%0.2f%%, Compliance=%0.2f%%, Timing=%0.2f%%, Performance=%0.2f%%, Coverage=%0.2f%%",
                    timestamp, metrics.overall_health_score, metrics.compliance_score, 
                    metrics.timing_score, metrics.performance_score, metrics.coverage_score);
  endfunction
  
endclass // jtag_dashboard_report

//=============================================================================
// JTAG Alert Report Class
//=============================================================================

class jtag_alert_report extends uvm_object;
  
  string alert_type;
  uvm_severity severity;
  string description;
  time timestamp;
  jtag_debug_dashboard::dashboard_metrics_t dashboard_metrics;
  
  `uvm_object_utils_begin(jtag_alert_report)
  `uvm_field_string(alert_type, UVM_DEFAULT)
  `uvm_field_enum(uvm_severity, severity, UVM_DEFAULT)
  `uvm_field_string(description, UVM_DEFAULT)
  `uvm_field_int(timestamp, UVM_DEFAULT)
  `uvm_object_utils_end
  
  function new(string name = "jtag_alert_report");
    super.new(name);
  endfunction
  
  virtual function string convert2string();
    return $sformatf("Alert @ %0t [%s]: %s - %s", timestamp, severity.name(), alert_type, description);
  endfunction
  
endclass // jtag_alert_report

`endif