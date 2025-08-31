`ifndef JTAG_MONITOR__SVH
 `define JTAG_MONITOR__SVH

`uvm_analysis_imp_decl(_tx)
`uvm_analysis_imp_decl(_drv_tx)
`uvm_analysis_imp_decl(_rx)
`uvm_analysis_imp_decl(_error)
`uvm_analysis_imp_decl(_timing)
`uvm_analysis_imp_decl(_compliance)

//=============================================================================
// Enhanced JTAG Monitor Class
// Provides comprehensive transaction monitoring, coverage collection,
// protocol compliance checking, and performance analysis
//=============================================================================
class jtag_monitor extends uvm_monitor;

  //===========================================================================
  // Transaction Objects
  //===========================================================================
  jtag_base_transaction collected_rx;
  jtag_base_transaction collected_tx;
  jtag_base_transaction driver_tx;
  
  // Enhanced transaction queues for analysis
  jtag_base_transaction transaction_queue[$];
  jtag_base_transaction error_queue[$];
  
  //===========================================================================
  // Configuration Objects
  //===========================================================================
  jtag_monitor_config monitor_cfg;
  jtag_timing_config timing_cfg;
  jtag_protocol_config protocol_cfg;
  jtag_error_config error_cfg;
  
  //===========================================================================
  // Control Flags
  //===========================================================================
  bit coverage_enable = 1;
  bit protocol_checking_enable = 1;
  bit timing_checking_enable = 1;
  bit performance_monitoring_enable = 1;
  bit error_injection_monitoring = 1;
  bit drv_mon_tx_check_en = 1;
  
  //===========================================================================
  // State Tracking
  //===========================================================================
  jtag_tap_state_e current_state = TEST_LOGIC_RESET;
  jtag_tap_state_e previous_state = TEST_LOGIC_RESET;
  jtag_instruction_e current_instruction = BYPASS;
  
  //===========================================================================
  // Performance and Timing Tracking
  //===========================================================================
  jtag_performance_metrics_s performance_metrics;
  real transaction_start_time;
  real transaction_end_time;
  int unsigned transaction_count = 0;
  int unsigned error_count = 0;
  int unsigned protocol_violation_count = 0;
  
  //===========================================================================
  // Protocol Compliance Tracking
  //===========================================================================
  jtag_compliance_info_s compliance_info;
  bit [31:0] timing_violations = 0;
  bit [31:0] protocol_violations = 0;

  `uvm_component_utils_begin(jtag_monitor)
  `uvm_field_object(collected_rx, UVM_DEFAULT)
  `uvm_field_object(collected_tx, UVM_DEFAULT)
  `uvm_field_object(driver_tx, UVM_DEFAULT)
  `uvm_field_object(monitor_cfg, UVM_DEFAULT)
  `uvm_field_int(coverage_enable, UVM_DEFAULT)
  `uvm_field_int(protocol_checking_enable, UVM_DEFAULT)
  `uvm_field_int(timing_checking_enable, UVM_DEFAULT)
  `uvm_field_int(performance_monitoring_enable, UVM_DEFAULT)
  `uvm_field_int(drv_mon_tx_check_en, UVM_DEFAULT)
  `uvm_component_utils_end
  
  //===========================================================================
  // Analysis Ports
  //===========================================================================
  uvm_analysis_imp_tx #(jtag_base_transaction, jtag_monitor) col_mon_tx_import;
  uvm_analysis_imp_drv_tx #(jtag_base_transaction, jtag_monitor) drv_mon_tx_import;
  uvm_analysis_imp_rx #(jtag_base_transaction, jtag_monitor) col_mon_rx_import;
  uvm_analysis_imp_error #(jtag_error_info_s, jtag_monitor) error_import;
  uvm_analysis_imp_timing #(jtag_timing_info_s, jtag_monitor) timing_import;
  uvm_analysis_imp_compliance #(jtag_compliance_info_s, jtag_monitor) compliance_import;
  
  // Output analysis ports
  uvm_analysis_port #(jtag_base_transaction) transaction_ap;
  uvm_analysis_port #(jtag_error_info_s) error_ap;
  uvm_analysis_port #(jtag_performance_metrics_s) performance_ap;
  uvm_analysis_port #(jtag_compliance_info_s) compliance_ap;

  //===========================================================================
  // Enhanced Coverage Groups
  //===========================================================================
  
  // Transaction type coverage
  covergroup jtag_transaction_cg;
    option.per_instance = 1;
    
    TRANS_TYPE: coverpoint collected_tx.transaction_type {
      bins instruction_trans = {INSTRUCTION_TRANSACTION};
      bins data_trans = {DATA_TRANSACTION};
      bins boundary_scan_trans = {BOUNDARY_SCAN_TRANSACTION};
      bins debug_trans = {DEBUG_TRANSACTION};
      bins reset_trans = {RESET_TRANSACTION};
      bins compliance_trans = {COMPLIANCE_TRANSACTION};
      bins idcode_trans = {IDCODE_TRANSACTION};
    }
    
    TRANS_SIZE: coverpoint collected_tx.data_length {
      bins small = {[1:8]};
      bins medium = {[9:32]};
      bins large = {[33:64]};
      bins extra_large = {[65:128]};
    }
    
    TRANS_PATTERN: coverpoint collected_tx.data_pattern {
      bins all_zeros = {PATTERN_ALL_ZEROS};
      bins all_ones = {PATTERN_ALL_ONES};
      bins alternating = {PATTERN_ALTERNATING};
      bins walking_ones = {PATTERN_WALKING_ONES};
      bins walking_zeros = {PATTERN_WALKING_ZEROS};
      bins random_pattern = {PATTERN_RANDOM};
      bins custom_pattern = {PATTERN_CUSTOM};
    }
    
    // Cross coverage
    TRANS_TYPE_X_SIZE: cross TRANS_TYPE, TRANS_SIZE;
    TRANS_TYPE_X_PATTERN: cross TRANS_TYPE, TRANS_PATTERN;
    
  endgroup // jtag_transaction_cg
  
  // Instruction coverage
  covergroup jtag_instruction_cg;
    option.per_instance = 1;
    
    INSTRUCTION: coverpoint current_instruction {
      // Standard instructions
      bins bypass = {BYPASS};
      bins idcode = {IDCODE};
      bins sample_preload = {SAMPLE_PRELOAD};
      bins extest = {EXTEST};
      bins intest = {INTEST};
      bins runbist = {RUNBIST};
      bins clamp = {CLAMP};
      bins highz = {HIGHZ};
      
      // Debug instructions
      bins debug_request = {DEBUG_REQUEST};
      bins debug_select = {DEBUG_SELECT};
      bins debug_capture = {DEBUG_CAPTURE};
      bins debug_shift = {DEBUG_SHIFT};
      bins debug_update = {DEBUG_UPDATE};
      
      // Advanced instructions
      bins boundary_scan_chain = {BOUNDARY_SCAN_CHAIN};
      bins device_id_chain = {DEVICE_ID_CHAIN};
      bins user_code = {USER_CODE};
      bins private_1 = {PRIVATE_1};
      bins private_2 = {PRIVATE_2};
      
      // Custom instructions
      bins custom_inst[] = {[CUSTOM_INST_BASE:CUSTOM_INST_MAX]};
    }
    
  endgroup // jtag_instruction_cg
  
  // TAP state coverage
  covergroup jtag_state_cg;
    option.per_instance = 1;
    
    CURRENT_STATE: coverpoint current_state {
      bins test_logic_reset = {TEST_LOGIC_RESET};
      bins run_test_idle = {RUN_TEST_IDLE};
      bins select_dr_scan = {SELECT_DR_SCAN};
      bins capture_dr = {CAPTURE_DR};
      bins shift_dr = {SHIFT_DR};
      bins exit1_dr = {EXIT1_DR};
      bins pause_dr = {PAUSE_DR};
      bins exit2_dr = {EXIT2_DR};
      bins update_dr = {UPDATE_DR};
      bins select_ir_scan = {SELECT_IR_SCAN};
      bins capture_ir = {CAPTURE_IR};
      bins shift_ir = {SHIFT_IR};
      bins exit1_ir = {EXIT1_IR};
      bins pause_ir = {PAUSE_IR};
      bins exit2_ir = {EXIT2_IR};
      bins update_ir = {UPDATE_IR};
    }
    
    STATE_TRANSITIONS: coverpoint {previous_state, current_state} {
      // Valid state transitions
      bins reset_to_idle = {[TEST_LOGIC_RESET:TEST_LOGIC_RESET], [RUN_TEST_IDLE:RUN_TEST_IDLE]};
      bins idle_to_select_dr = {[RUN_TEST_IDLE:RUN_TEST_IDLE], [SELECT_DR_SCAN:SELECT_DR_SCAN]};
      bins idle_to_select_ir = {[RUN_TEST_IDLE:RUN_TEST_IDLE], [SELECT_IR_SCAN:SELECT_IR_SCAN]};
      // Add more transition bins as needed
    }
    
  endgroup // jtag_state_cg
  
  // Error and compliance coverage
  covergroup jtag_error_cg;
    option.per_instance = 1;
    
    ERROR_TYPE: coverpoint collected_tx.error_info.error_type {
      bins no_error = {NO_ERROR};
      bins timing_error = {TIMING_ERROR};
      bins protocol_error = {PROTOCOL_ERROR};
      bins data_error = {DATA_ERROR};
      bins state_error = {STATE_ERROR};
      bins instruction_error = {INSTRUCTION_ERROR};
    }
    
    PROTOCOL_VIOLATION: coverpoint collected_tx.error_info.protocol_violation {
      bins no_violation = {NO_VIOLATION};
      bins invalid_state_transition = {INVALID_STATE_TRANSITION};
      bins invalid_instruction = {INVALID_INSTRUCTION};
      bins timing_violation = {TIMING_VIOLATION};
      bins data_corruption = {DATA_CORRUPTION};
    }
    
  endgroup // jtag_error_cg
  
  // Performance coverage
  covergroup jtag_performance_cg;
    option.per_instance = 1;
    
    TRANSACTION_LATENCY: coverpoint collected_tx.performance_metrics.transaction_latency_ns {
      bins fast = {[0:100]};
      bins normal = {[101:1000]};
      bins slow = {[1001:10000]};
      bins very_slow = {[10001:$]};
    }
    
    THROUGHPUT: coverpoint collected_tx.performance_metrics.throughput_mbps {
      bins low = {[0:10]};
      bins medium = {[11:50]};
      bins high = {[51:100]};
      bins very_high = {[101:$]};
    }
    
  endgroup // jtag_performance_cg
  
  function new (string name, uvm_component parent);
    super.new(name,parent);
    
    // Initialize enhanced covergroups
    jtag_transaction_cg = new();
    jtag_instruction_cg = new();
    jtag_state_cg = new();
    jtag_error_cg = new();
    jtag_performance_cg = new();
    
    // Initialize performance metrics
    performance_metrics = '{default:0};
    compliance_info = '{default:0};
    
  endfunction // new
  
  virtual function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration objects
    if (!uvm_config_db#(jtag_monitor_config)::get(this, "", "monitor_cfg", monitor_cfg)) begin
      `uvm_info("JTAG_MONITOR", "Using default monitor configuration", UVM_LOW)
      monitor_cfg = jtag_monitor_config::type_id::create("monitor_cfg");
    end
    
    if (!uvm_config_db#(jtag_timing_config)::get(this, "", "timing_cfg", timing_cfg)) begin
      `uvm_info("JTAG_MONITOR", "Using default timing configuration", UVM_LOW)
      timing_cfg = jtag_timing_config::type_id::create("timing_cfg");
    end
    
    if (!uvm_config_db#(jtag_protocol_config)::get(this, "", "protocol_cfg", protocol_cfg)) begin
      `uvm_info("JTAG_MONITOR", "Using default protocol configuration", UVM_LOW)
      protocol_cfg = jtag_protocol_config::type_id::create("protocol_cfg");
    end
    
    if (!uvm_config_db#(jtag_error_config)::get(this, "", "error_cfg", error_cfg)) begin
      `uvm_info("JTAG_MONITOR", "Using default error configuration", UVM_LOW)
      error_cfg = jtag_error_config::type_id::create("error_cfg");
    end
    
    // Apply configuration settings
    coverage_enable = monitor_cfg.coverage_enable;
    protocol_checking_enable = monitor_cfg.protocol_checking_enable;
    timing_checking_enable = monitor_cfg.timing_checking_enable;
    performance_monitoring_enable = monitor_cfg.performance_monitoring_enable;
    error_injection_monitoring = monitor_cfg.error_injection_monitoring;
    drv_mon_tx_check_en = monitor_cfg.driver_monitor_check_enable;
    
    // Create transaction objects
    collected_rx = jtag_base_transaction::type_id::create("collected_rx");
    collected_tx = jtag_base_transaction::type_id::create("collected_tx");
    driver_tx = jtag_base_transaction::type_id::create("driver_tx");
    
    // Create analysis import ports
    col_mon_rx_import = new("col_mon_rx_import", this);
    col_mon_tx_import = new("col_mon_tx_import", this);
    
    if (drv_mon_tx_check_en)
      drv_mon_tx_import = new("drv_mon_tx_import", this);
    
    if (error_injection_monitoring)
      error_import = new("error_import", this);
    
    if (timing_checking_enable)
      timing_import = new("timing_import", this);
    
    if (protocol_checking_enable)
      compliance_import = new("compliance_import", this);
    
    // Create analysis output ports
    transaction_ap = new("transaction_ap", this);
    error_ap = new("error_ap", this);
    performance_ap = new("performance_ap", this);
    compliance_ap = new("compliance_ap", this);
    
    if (coverage_enable)
      `uvm_info("JTAG_MONITOR", "Enhanced coverage collection enabled", UVM_LOW)
    
    if (protocol_checking_enable)
      `uvm_info("JTAG_MONITOR", "Protocol compliance checking enabled", UVM_LOW)
    
    if (timing_checking_enable)
      `uvm_info("JTAG_MONITOR", "Timing validation enabled", UVM_LOW)
    
    if (performance_monitoring_enable)
      `uvm_info("JTAG_MONITOR", "Performance monitoring enabled", UVM_LOW)
    
  endfunction // build_phase

  //===========================================================================
  // External Function Declarations
  //===========================================================================
  extern virtual function void write_rx (jtag_base_transaction rsp);
  extern virtual function void write_tx (jtag_base_transaction trans);
  extern virtual function void write_drv_tx (jtag_base_transaction trans);
  extern virtual function void write_error (jtag_error_info_s error_info);
  extern virtual function void write_timing (jtag_timing_info_s timing_info);
  extern virtual function void write_compliance (jtag_compliance_info_s compliance_info);
  
  // Enhanced monitoring functions
  extern virtual function void perform_transaction_analysis(jtag_base_transaction trans);
  extern virtual function void perform_protocol_checking(jtag_base_transaction trans);
  extern virtual function void perform_timing_validation(jtag_base_transaction trans);
  extern virtual function void perform_performance_monitoring(jtag_base_transaction trans);
  extern virtual function void perform_comprehensive_coverage(jtag_base_transaction trans);
  extern virtual function void update_state_tracking(jtag_base_transaction trans);
  extern virtual function void check_transaction_consistency();
  extern virtual function void generate_performance_report();
  extern virtual function void validate_instruction_compliance(jtag_instruction_e instruction);
  extern virtual function void check_timing_constraints(jtag_base_transaction trans);
  extern virtual function void analyze_error_patterns();
  
endclass // jtag_monitor

//=============================================================================
// Enhanced Write Functions Implementation
//=============================================================================

// RX transaction processing with comprehensive analysis
function void jtag_monitor::write_rx (jtag_base_transaction rsp);
  `uvm_info("JTAG_MONITOR", "Processing RX transaction from collector", UVM_MEDIUM)
  
  // Copy transaction
  collected_rx.copy(rsp);
  transaction_count++;
  
  // Add to transaction queue for analysis
  transaction_queue.push_back(collected_rx);
  
  // Perform comprehensive analysis
  perform_transaction_analysis(collected_rx);
  
  // Update state tracking
  update_state_tracking(collected_rx);
  
  // Protocol compliance checking
  if (protocol_checking_enable)
    perform_protocol_checking(collected_rx);
  
  // Timing validation
  if (timing_checking_enable)
    perform_timing_validation(collected_rx);
  
  // Performance monitoring
  if (performance_monitoring_enable)
    perform_performance_monitoring(collected_rx);
  
  // Coverage collection
  if (coverage_enable)
    perform_comprehensive_coverage(collected_rx);
  
  // Send to analysis port
  transaction_ap.write(collected_rx);
  
  `uvm_info("JTAG_MONITOR", $sformatf("RX transaction processed: ID=%0d, Type=%s", 
                                      collected_rx.transaction_id, 
                                      collected_rx.transaction_type.name()), UVM_HIGH)

endfunction // write_rx

// TX transaction processing with enhanced checking
function void jtag_monitor::write_tx (jtag_base_transaction trans);
  `uvm_info("JTAG_MONITOR", "Processing TX transaction from collector", UVM_MEDIUM)
  
  // Copy transaction
  collected_tx.copy(trans);
  transaction_count++;
  
  // Record transaction end time for performance metrics
  transaction_end_time = $realtime;
  
  // Add to transaction queue
  transaction_queue.push_back(collected_tx);
  
  // Perform comprehensive analysis
  perform_transaction_analysis(collected_tx);
  
  // Update state tracking
  update_state_tracking(collected_tx);
  
  // Protocol compliance checking
  if (protocol_checking_enable)
    perform_protocol_checking(collected_tx);
  
  // Timing validation
  if (timing_checking_enable)
    perform_timing_validation(collected_tx);
  
  // Performance monitoring
  if (performance_monitoring_enable)
    perform_performance_monitoring(collected_tx);
  
  // Coverage collection
  if (coverage_enable)
    perform_comprehensive_coverage(collected_tx);
  
  // Driver-monitor consistency checking
  if (drv_mon_tx_check_en)
    check_transaction_consistency();
  
  // Send to analysis port
  transaction_ap.write(collected_tx);
  
  `uvm_info("JTAG_MONITOR", $sformatf("TX transaction processed: ID=%0d, Type=%s", 
                                      collected_tx.transaction_id, 
                                      collected_tx.transaction_type.name()), UVM_HIGH)

endfunction // write_tx

// Driver transaction processing
function void jtag_monitor::write_drv_tx (jtag_base_transaction trans);
  `uvm_info("JTAG_MONITOR", "Processing TX transaction from driver", UVM_MEDIUM)
  
  // Copy transaction
  driver_tx.copy(trans);
  
  // Record transaction start time
  transaction_start_time = $realtime;
  
  `uvm_info("JTAG_MONITOR", $sformatf("Driver TX transaction received: ID=%0d, Type=%s", 
                                      driver_tx.transaction_id, 
                                      driver_tx.transaction_type.name()), UVM_HIGH)

endfunction // write_drv_tx

// Error information processing
function void jtag_monitor::write_error (jtag_error_info_s error_info);
  `uvm_info("JTAG_MONITOR", "Processing error information", UVM_MEDIUM)
  
  error_count++;
  
  // Log error details
  `uvm_warning("JTAG_ERROR", $sformatf("Error detected: Type=%s, Violation=%s, Description=%s",
                                       error_info.error_type.name(),
                                       error_info.protocol_violation.name(),
                                       error_info.error_description))
  
  // Add to error queue for analysis
  // error_queue.push_back(error_info); // Would need error transaction type
  
  // Send to analysis port
  error_ap.write(error_info);
  
endfunction // write_error

// Timing information processing
function void jtag_monitor::write_timing (jtag_timing_info_s timing_info);
  `uvm_info("JTAG_MONITOR", "Processing timing information", UVM_HIGH)
  
  // Validate timing against constraints
  if (timing_info.setup_time_ns < timing_cfg.tdi_setup_time_ns) begin
    timing_violations[0] = 1;
    `uvm_error("TIMING_VIOLATION", $sformatf("Setup time violation: %0.2f ns < %0.2f ns",
                                             timing_info.setup_time_ns, timing_cfg.tdi_setup_time_ns))
  end
  
  if (timing_info.hold_time_ns < timing_cfg.tdi_hold_time_ns) begin
    timing_violations[1] = 1;
    `uvm_error("TIMING_VIOLATION", $sformatf("Hold time violation: %0.2f ns < %0.2f ns",
                                             timing_info.hold_time_ns, timing_cfg.tdi_hold_time_ns))
  end
  
endfunction // write_timing

// Compliance information processing
function void jtag_monitor::write_compliance (jtag_compliance_info_s compliance_info);
  `uvm_info("JTAG_MONITOR", "Processing compliance information", UVM_MEDIUM)
  
  // Update compliance tracking
  this.compliance_info = compliance_info;
  
  // Check compliance status
  if (compliance_info.ieee_1149_1_compliant == 0) begin
    protocol_violations[0] = 1;
    `uvm_warning("COMPLIANCE_VIOLATION", "IEEE 1149.1 compliance violation detected")
  end
  
  // Send to analysis port
  compliance_ap.write(compliance_info);
  
endfunction // write_compliance

//=============================================================================
// Enhanced Monitoring Functions Implementation
//=============================================================================

// Comprehensive transaction analysis
function void jtag_monitor::perform_transaction_analysis(jtag_base_transaction trans);
  `uvm_info("JTAG_MONITOR", "Performing transaction analysis", UVM_HIGH)
  
  // Analyze transaction patterns
  case (trans.transaction_type)
    JTAG_INSTRUCTION: begin
      instruction_count++;
      last_instruction = trans.instruction;
    end
    JTAG_DATA: begin
      data_count++;
      if (trans.data_length > max_data_length)
        max_data_length = trans.data_length;
    end
    JTAG_BOUNDARY_SCAN: boundary_scan_count++;
    JTAG_DEBUG: debug_count++;
    JTAG_IDCODE: idcode_count++;
    JTAG_RESET: reset_count++;
    default: unknown_count++;
  endcase
  
  // Update transaction statistics
  total_transactions++;
  
endfunction // perform_transaction_analysis

// Protocol compliance checking
function void jtag_monitor::perform_protocol_checking(jtag_base_transaction trans);
  `uvm_info("JTAG_MONITOR", "Performing protocol compliance checking", UVM_HIGH)
  
  // Check instruction compliance
  if (trans.transaction_type == JTAG_INSTRUCTION) begin
    validate_instruction_compliance(trans);
  end
  
  // Check state transitions
  if (current_tap_state != trans.start_state) begin
    protocol_violations[1] = 1;
    `uvm_warning("PROTOCOL_VIOLATION", 
                 $sformatf("State mismatch: Expected %s, Got %s",
                          current_tap_state.name(), trans.start_state.name()))
  end
  
  // Update current state
  current_tap_state = trans.end_state;
  
endfunction // perform_protocol_checking

// Timing validation
function void jtag_monitor::perform_timing_validation(jtag_base_transaction trans);
  `uvm_info("JTAG_MONITOR", "Performing timing validation", UVM_HIGH)
  
  real transaction_duration;
  
  // Calculate transaction duration
  transaction_duration = transaction_end_time - transaction_start_time;
  
  // Check minimum transaction time
  if (transaction_duration < timing_cfg.min_transaction_time_ns) begin
    timing_violations[2] = 1;
    `uvm_error("TIMING_VIOLATION", 
               $sformatf("Transaction too fast: %0.2f ns < %0.2f ns",
                        transaction_duration, timing_cfg.min_transaction_time_ns))
  end
  
  // Check maximum transaction time
  if (transaction_duration > timing_cfg.max_transaction_time_ns) begin
    timing_violations[3] = 1;
    `uvm_warning("TIMING_WARNING", 
                 $sformatf("Transaction slow: %0.2f ns > %0.2f ns",
                          transaction_duration, timing_cfg.max_transaction_time_ns))
  end
  
endfunction // perform_timing_validation

// Performance monitoring
function void jtag_monitor::perform_performance_monitoring(jtag_base_transaction trans);
  `uvm_info("JTAG_MONITOR", "Performing performance monitoring", UVM_HIGH)
  
  real current_time = $realtime;
  real transaction_latency;
  
  // Calculate transaction latency
  transaction_latency = transaction_end_time - transaction_start_time;
  
  // Update performance metrics
  performance_metrics.total_transactions++;
  performance_metrics.total_latency_ns += transaction_latency;
  performance_metrics.average_latency_ns = performance_metrics.total_latency_ns / performance_metrics.total_transactions;
  
  // Track min/max latency
  if (transaction_latency < performance_metrics.min_latency_ns || performance_metrics.min_latency_ns == 0)
    performance_metrics.min_latency_ns = transaction_latency;
  if (transaction_latency > performance_metrics.max_latency_ns)
    performance_metrics.max_latency_ns = transaction_latency;
  
  // Calculate throughput (transactions per second)
  if (current_time > 0)
    performance_metrics.throughput_tps = (performance_metrics.total_transactions * 1e9) / current_time;
  
  // Send performance data to analysis port
  performance_ap.write(performance_metrics);
  
endfunction // perform_performance_monitoring

// Comprehensive coverage collection
function void jtag_monitor::perform_comprehensive_coverage(jtag_base_transaction trans);
  `uvm_info("JTAG_MONITOR", "Performing comprehensive coverage collection", UVM_HIGH)
  
  // Sample all covergroups
  jtag_transaction_cg.sample();
  jtag_instruction_cg.sample();
  jtag_state_cg.sample();
  
  // Sample error coverage if errors present
  if (error_count > 0)
    jtag_error_cg.sample();
  
  // Sample performance coverage
  jtag_performance_cg.sample();
  
endfunction // perform_comprehensive_coverage

// State tracking update
function void jtag_monitor::update_state_tracking(jtag_base_transaction trans);
  `uvm_info("JTAG_MONITOR", "Updating state tracking", UVM_HIGH)
  
  // Update previous and current states
  previous_tap_state = current_tap_state;
  current_tap_state = trans.end_state;
  
  // Track state transition
  state_transition_count++;
  
  // Log significant state changes
  if (previous_tap_state != current_tap_state) begin
    `uvm_info("STATE_TRANSITION", 
              $sformatf("TAP state transition: %s -> %s",
                       previous_tap_state.name(), current_tap_state.name()), UVM_MEDIUM)
  end
  
endfunction // update_state_tracking

// Transaction consistency checking
function void jtag_monitor::check_transaction_consistency();
  `uvm_info("JTAG_MONITOR", "Checking transaction consistency", UVM_HIGH)
  
  // Compare collected TX with driver TX
  if (!collected_tx.compare(driver_tx)) begin
    consistency_errors++;
    `uvm_error("CONSISTENCY_ERROR", 
               "TX transaction mismatch between collector and driver")
    
    // Detailed comparison logging
    `uvm_info("CONSISTENCY_DEBUG", "Driver transaction:", UVM_MEDIUM)
    driver_tx.print();
    `uvm_info("CONSISTENCY_DEBUG", "Collected transaction:", UVM_MEDIUM)
    collected_tx.print();
  end else begin
    `uvm_info("CONSISTENCY_CHECK", 
              "TX transaction consistency verified", UVM_HIGH)
  end
  
endfunction // check_transaction_consistency

// Performance report generation
function void jtag_monitor::generate_performance_report();
  `uvm_info("JTAG_MONITOR", "=== JTAG Monitor Performance Report ===", UVM_LOW)
  `uvm_info("PERFORMANCE", $sformatf("Total Transactions: %0d", performance_metrics.total_transactions), UVM_LOW)
  `uvm_info("PERFORMANCE", $sformatf("Average Latency: %0.2f ns", performance_metrics.average_latency_ns), UVM_LOW)
  `uvm_info("PERFORMANCE", $sformatf("Min Latency: %0.2f ns", performance_metrics.min_latency_ns), UVM_LOW)
  `uvm_info("PERFORMANCE", $sformatf("Max Latency: %0.2f ns", performance_metrics.max_latency_ns), UVM_LOW)
  `uvm_info("PERFORMANCE", $sformatf("Throughput: %0.2f TPS", performance_metrics.throughput_tps), UVM_LOW)
  `uvm_info("PERFORMANCE", $sformatf("Error Count: %0d", error_count), UVM_LOW)
  `uvm_info("PERFORMANCE", $sformatf("Consistency Errors: %0d", consistency_errors), UVM_LOW)
endfunction // generate_performance_report

// Instruction compliance validation
function void jtag_monitor::validate_instruction_compliance(jtag_base_transaction trans);
  `uvm_info("JTAG_MONITOR", "Validating instruction compliance", UVM_HIGH)
  
  // Check mandatory instructions
  case (trans.instruction)
    BYPASS, IDCODE, SAMPLE_PRELOAD, EXTEST: begin
      // These are mandatory - always compliant
      compliance_info.ieee_1149_1_compliant = 1;
    end
    default: begin
      // Check if custom instruction follows naming conventions
      if (trans.instruction[31:28] == 4'hF) begin
        // Private instruction space - compliant
        compliance_info.ieee_1149_1_compliant = 1;
      end else begin
        // May need additional validation
        `uvm_info("COMPLIANCE_CHECK", 
                  $sformatf("Custom instruction detected: 0x%08x", trans.instruction), UVM_MEDIUM)
      end
    end
  endcase
  
endfunction // validate_instruction_compliance

// Timing constraint checking
function void jtag_monitor::check_timing_constraints(jtag_base_transaction trans);
  `uvm_info("JTAG_MONITOR", "Checking timing constraints", UVM_HIGH)
  
  // This would typically be called from timing validation
  // Implementation depends on specific timing requirements
  
endfunction // check_timing_constraints

// Error pattern analysis
function void jtag_monitor::analyze_error_patterns();
  `uvm_info("JTAG_MONITOR", "Analyzing error patterns", UVM_MEDIUM)
  
  // Analyze error frequency and patterns
  if (error_count > 0) begin
    real error_rate = real'(error_count) / real'(total_transactions);
    `uvm_info("ERROR_ANALYSIS", 
              $sformatf("Error rate: %0.2f%% (%0d/%0d)", 
                       error_rate * 100, error_count, total_transactions), UVM_LOW)
  end
  
endfunction // analyze_error_patterns

`endif
