`ifndef JTAG_ENV__SVH
 `define JTAG_ENV__SVH

//=============================================================================
// Enhanced JTAG Environment
// Comprehensive verification environment with advanced features
//=============================================================================

class jtag_env extends uvm_env;
  
  // Core agent
  jtag_agent jtag_agnt;
  
  // Enhanced verification components
  jtag_scoreboard scoreboard;
  jtag_error_injector error_injector;
  jtag_debug_dashboard debug_dashboard;
  jtag_virtual_sequencer virtual_sequencer;
  
  // Configuration objects
  jtag_env_config jtag_env_cfg;
  jtag_protocol_config protocol_cfg;
  jtag_timing_config timing_cfg;
  jtag_coverage_config coverage_cfg;
  jtag_performance_config performance_cfg;
  jtag_error_config error_cfg;
  jtag_debug_config debug_cfg;
  
  // Analysis ports for environment-level monitoring
  uvm_analysis_port #(jtag_performance_report_s) env_performance_ap;
  uvm_analysis_port #(jtag_compliance_report_s) env_compliance_ap;
  uvm_analysis_port #(jtag_coverage_report_s) env_coverage_ap;
  uvm_analysis_port #(jtag_debug_report_s) env_debug_ap;
  
  `uvm_component_utils_begin(jtag_env)
  `uvm_field_object(jtag_env_cfg,UVM_DEFAULT)
  `uvm_component_utils_end
    
  function new (string name, uvm_component parent);
    super.new(name, parent);
  endfunction // new

  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    
    // Get or create main environment configuration
    if (jtag_env_cfg == null)
      begin
        `uvm_info("JTAG_ENV_INFO","Creating default env configuration",UVM_LOW)
        jtag_env_cfg = jtag_env_config::type_id::create("jtag_env_cfg");
        
        if(!jtag_env_cfg.randomize())
          `uvm_fatal("JTAG_ENV_FATAL","Randomization env configuration failed")
      end
    
    // Get or create enhanced configuration objects
    get_enhanced_configurations();
    
    // Set configurations for sub-components
    set_sub_component_configurations();
    
    // Create core agent
    jtag_agnt = jtag_agent::type_id::create("jtag_agnt", this);
    
    // Create enhanced verification components based on configuration
    create_enhanced_components();
    
    // Create analysis ports
    create_analysis_ports();
    
  endfunction // build_phase
  
  //=============================================================================
  // Configuration Management Functions
  //=============================================================================
  
  virtual function void get_enhanced_configurations();
    // Get protocol configuration
    if(!uvm_config_db#(jtag_protocol_config)::get(this, "", "protocol_cfg", protocol_cfg)) begin
      `uvm_info("JTAG_ENV_INFO", "Creating default protocol configuration", UVM_LOW)
      protocol_cfg = jtag_protocol_config::type_id::create("protocol_cfg");
      if (!protocol_cfg.randomize())
        `uvm_warning("JTAG_ENV_WARN", "Randomization of protocol_cfg failed")
    end
    
    // Get timing configuration
    if(!uvm_config_db#(jtag_timing_config)::get(this, "", "timing_cfg", timing_cfg)) begin
      `uvm_info("JTAG_ENV_INFO", "Creating default timing configuration", UVM_LOW)
      timing_cfg = jtag_timing_config::type_id::create("timing_cfg");
      if (!timing_cfg.randomize())
        `uvm_warning("JTAG_ENV_WARN", "Randomization of timing_cfg failed")
    end
    
    // Get coverage configuration
    if(!uvm_config_db#(jtag_coverage_config)::get(this, "", "coverage_cfg", coverage_cfg)) begin
      `uvm_info("JTAG_ENV_INFO", "Creating default coverage configuration", UVM_LOW)
      coverage_cfg = jtag_coverage_config::type_id::create("coverage_cfg");
      if (!coverage_cfg.randomize())
        `uvm_warning("JTAG_ENV_WARN", "Randomization of coverage_cfg failed")
    end
    
    // Get performance configuration
    if(!uvm_config_db#(jtag_performance_config)::get(this, "", "performance_cfg", performance_cfg)) begin
      `uvm_info("JTAG_ENV_INFO", "Creating default performance configuration", UVM_LOW)
      performance_cfg = jtag_performance_config::type_id::create("performance_cfg");
      if (!performance_cfg.randomize())
        `uvm_warning("JTAG_ENV_WARN", "Randomization of performance_cfg failed")
    end
    
    // Get error configuration
    if(!uvm_config_db#(jtag_error_config)::get(this, "", "error_cfg", error_cfg)) begin
      `uvm_info("JTAG_ENV_INFO", "Creating default error configuration", UVM_LOW)
      error_cfg = jtag_error_config::type_id::create("error_cfg");
      if (!error_cfg.randomize())
        `uvm_warning("JTAG_ENV_WARN", "Randomization of error_cfg failed")
    end
    
    // Get debug configuration
    if(!uvm_config_db#(jtag_debug_config)::get(this, "", "debug_cfg", debug_cfg)) begin
      `uvm_info("JTAG_ENV_INFO", "Creating default debug configuration", UVM_LOW)
      debug_cfg = jtag_debug_config::type_id::create("debug_cfg");
      if (!debug_cfg.randomize())
        `uvm_warning("JTAG_ENV_WARN", "Randomization of debug_cfg failed")
    end
  endfunction
  
  virtual function void set_sub_component_configurations();
    // Set agent configuration
    uvm_config_db#(uvm_object)::set(this,"jtag_agnt","jtag_agent_cfg",jtag_env_cfg.jtag_agent_cfg);
    
    // Set enhanced configurations for all sub-components
    uvm_config_db#(jtag_protocol_config)::set(this, "*", "protocol_cfg", protocol_cfg);
    uvm_config_db#(jtag_timing_config)::set(this, "*", "timing_cfg", timing_cfg);
    uvm_config_db#(jtag_coverage_config)::set(this, "*", "coverage_cfg", coverage_cfg);
    uvm_config_db#(jtag_performance_config)::set(this, "*", "performance_cfg", performance_cfg);
    uvm_config_db#(jtag_error_config)::set(this, "*", "error_cfg", error_cfg);
    uvm_config_db#(jtag_debug_config)::set(this, "*", "debug_cfg", debug_cfg);
  endfunction
  
  virtual function void create_enhanced_components();
    // Create scoreboard for transaction checking
    if (jtag_env_cfg.enable_scoreboard) begin
      `uvm_info("JTAG_ENV_INFO", "Creating scoreboard", UVM_LOW)
      scoreboard = jtag_scoreboard::type_id::create("scoreboard", this);
    end
    
    // Create error injector for systematic error testing
    if (error_cfg.enable_error_injection) begin
      `uvm_info("JTAG_ENV_INFO", "Creating error injector", UVM_LOW)
      error_injector = jtag_error_injector::type_id::create("error_injector", this);
    end
    
    // Create debug dashboard for real-time monitoring
    if (debug_cfg.enable_debug_dashboard) begin
      `uvm_info("JTAG_ENV_INFO", "Creating debug dashboard", UVM_LOW)
      debug_dashboard = jtag_debug_dashboard::type_id::create("debug_dashboard", this);
    end
    
    // Create virtual sequencer for coordinated test execution
    if (jtag_env_cfg.enable_virtual_sequencer) begin
      `uvm_info("JTAG_ENV_INFO", "Creating virtual sequencer", UVM_LOW)
      virtual_sequencer = jtag_virtual_sequencer::type_id::create("virtual_sequencer", this);
    end
  endfunction
  
  virtual function void create_analysis_ports();
    env_performance_ap = new("env_performance_ap", this);
    env_compliance_ap = new("env_compliance_ap", this);
    env_coverage_ap = new("env_coverage_ap", this);
    env_debug_ap = new("env_debug_ap", this);
  endfunction
  
  //=============================================================================
  // Connection Phase
  //=============================================================================
  
  virtual function void connect_phase(uvm_phase phase);
    super.connect_phase(phase);
    
    `uvm_info("JTAG_ENV_INFO", "Environment connect phase", UVM_LOW)
    
    // Connect scoreboard if enabled
    if (scoreboard != null) begin
      `uvm_info("JTAG_ENV_INFO", "Connecting scoreboard", UVM_LOW)
      jtag_agnt.collector.item_collected_rx_port.connect(scoreboard.rx_analysis_imp);
      jtag_agnt.collector.item_collected_tx_port.connect(scoreboard.tx_analysis_imp);
      if (jtag_agnt.driver != null)
        jtag_agnt.driver.drv_mon_tx_port.connect(scoreboard.expected_analysis_imp);
    end
    
    // Connect error injector if enabled
    if (error_injector != null) begin
      `uvm_info("JTAG_ENV_INFO", "Connecting error injector", UVM_LOW)
      jtag_agnt.collector.item_collected_rx_port.connect(error_injector.monitor_analysis_imp);
      jtag_agnt.collector.item_collected_tx_port.connect(error_injector.monitor_analysis_imp);
    end
    
    // Connect debug dashboard if enabled
    if (debug_dashboard != null) begin
      `uvm_info("JTAG_ENV_INFO", "Connecting debug dashboard", UVM_LOW)
      jtag_agnt.collector.item_collected_rx_port.connect(debug_dashboard.transaction_analysis_imp);
      jtag_agnt.collector.item_collected_tx_port.connect(debug_dashboard.transaction_analysis_imp);
      
      // Connect enhanced component outputs to dashboard
      if (jtag_agnt.protocol_checker != null)
        jtag_agnt.protocol_checker.compliance_ap.connect(debug_dashboard.compliance_analysis_imp);
      if (jtag_agnt.timing_validator != null)
        jtag_agnt.timing_validator.timing_ap.connect(debug_dashboard.timing_analysis_imp);
      if (jtag_agnt.performance_monitor != null)
        jtag_agnt.performance_monitor.report_ap.connect(debug_dashboard.performance_analysis_imp);
      if (jtag_agnt.coverage_collector != null)
        jtag_agnt.coverage_collector.coverage_ap.connect(debug_dashboard.coverage_analysis_imp);
    end
    
    // Connect virtual sequencer if enabled
    if (virtual_sequencer != null && jtag_agnt.sequencer != null) begin
      `uvm_info("JTAG_ENV_INFO", "Connecting virtual sequencer", UVM_LOW)
      virtual_sequencer.jtag_sequencer = jtag_agnt.sequencer;
    end
    
    // Connect environment-level analysis ports
    connect_environment_analysis_ports();
    
  endfunction
  
  virtual function void connect_environment_analysis_ports();
    // Connect performance monitoring at environment level
    if (jtag_agnt.performance_monitor != null) begin
      jtag_agnt.performance_monitor.report_ap.connect(env_performance_ap);
    end
    
    // Connect compliance monitoring at environment level
    if (jtag_agnt.protocol_checker != null) begin
      jtag_agnt.protocol_checker.compliance_ap.connect(env_compliance_ap);
    end
    
    // Connect coverage monitoring at environment level
    if (jtag_agnt.coverage_collector != null) begin
      jtag_agnt.coverage_collector.coverage_ap.connect(env_coverage_ap);
    end
    
    // Connect debug monitoring at environment level
    if (debug_dashboard != null) begin
      debug_dashboard.debug_report_ap.connect(env_debug_ap);
    end
  endfunction
  
  //=============================================================================
  // Runtime Phases
  //=============================================================================
  
  virtual task run_phase(uvm_phase phase);
    super.run_phase(phase);
    
    // Start environment-level monitoring and reporting
    fork
      monitor_environment_health();
      generate_periodic_reports();
    join_none
    
  endtask
  
  virtual task monitor_environment_health();
    forever begin
      #1000ns; // Check every 1us
      
      // Check for critical errors or performance issues
      if (jtag_agnt.performance_monitor != null) begin
        if (jtag_agnt.performance_monitor.error_rate > error_cfg.critical_error_threshold) begin
          `uvm_error("JTAG_ENV_ERROR", $sformatf("Critical error rate detected: %0.2f%%", 
                                                  jtag_agnt.performance_monitor.error_rate))
        end
      end
      
      // Check for timing violations
      if (jtag_agnt.timing_validator != null) begin
        if (jtag_agnt.timing_validator.timing_violation_rate > timing_cfg.max_violation_rate) begin
          `uvm_warning("JTAG_ENV_WARN", $sformatf("High timing violation rate: %0.2f%%", 
                                                   jtag_agnt.timing_validator.timing_violation_rate))
        end
      end
    end
  endtask
  
  virtual task generate_periodic_reports();
    forever begin
      #10000ns; // Generate reports every 10us
      
      if (debug_dashboard != null) begin
        debug_dashboard.generate_status_report();
      end
      
      if (jtag_agnt.performance_monitor != null) begin
        jtag_agnt.performance_monitor.generate_performance_report();
      end
    end
  endtask
  
  //=============================================================================
  // End of Test Phases
  //=============================================================================
  
  virtual function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    
    `uvm_info("JTAG_ENV_INFO", "Extracting final results", UVM_LOW)
    
    // Extract final coverage results
    if (jtag_agnt.coverage_collector != null) begin
      jtag_agnt.coverage_collector.report_coverage_summary();
    end
    
    // Extract final performance results
    if (jtag_agnt.performance_monitor != null) begin
      jtag_agnt.performance_monitor.print_performance_summary();
    end
    
    // Extract final compliance results
    if (jtag_agnt.protocol_checker != null) begin
      jtag_agnt.protocol_checker.print_compliance_summary();
    end
    
    // Extract scoreboard results
    if (scoreboard != null) begin
      scoreboard.print_final_report();
    end
    
  endfunction
  
  virtual function void check_phase(uvm_phase phase);
    super.check_phase(phase);
    
    `uvm_info("JTAG_ENV_INFO", "Checking test results", UVM_LOW)
    
    // Check scoreboard for mismatches
    if (scoreboard != null) begin
      if (scoreboard.get_mismatch_count() > 0) begin
        `uvm_error("JTAG_ENV_ERROR", $sformatf("Scoreboard detected %0d mismatches", 
                                               scoreboard.get_mismatch_count()))
      end
    end
    
    // Check coverage goals
    if (jtag_agnt.coverage_collector != null) begin
      real coverage_percentage = jtag_agnt.coverage_collector.get_overall_coverage();
      if (coverage_percentage < coverage_cfg.coverage_goal) begin
        `uvm_warning("JTAG_ENV_WARN", $sformatf("Coverage goal not met: %0.2f%% < %0.2f%%", 
                                                 coverage_percentage, coverage_cfg.coverage_goal))
      end
    end
    
    // Check performance goals
    if (jtag_agnt.performance_monitor != null) begin
      if (jtag_agnt.performance_monitor.overall_quality_score < performance_cfg.min_quality_score) begin
        `uvm_warning("JTAG_ENV_WARN", $sformatf("Quality score below target: %0.2f%% < %0.2f%%", 
                                                 jtag_agnt.performance_monitor.overall_quality_score, 
                                                 performance_cfg.min_quality_score))
      end
    end
    
  endfunction
  
  virtual function void report_phase(uvm_phase phase);
    super.report_phase(phase);
    
    `uvm_info("JTAG_ENV_INFO", "=== JTAG VIP Final Report ===", UVM_LOW)
    
    // Print environment configuration summary
    print_configuration_summary();
    
    // Print component status
    print_component_status();
    
    // Print final statistics
    print_final_statistics();
    
    `uvm_info("JTAG_ENV_INFO", "=== End of JTAG VIP Report ===", UVM_LOW)
    
  endfunction
  
  virtual function void print_configuration_summary();
    `uvm_info("JTAG_ENV_INFO", "--- Configuration Summary ---", UVM_LOW)
    `uvm_info("JTAG_ENV_INFO", $sformatf("Protocol compliance checking: %s", 
                                         protocol_cfg.enable_compliance_checking ? "ENABLED" : "DISABLED"), UVM_LOW)
    `uvm_info("JTAG_ENV_INFO", $sformatf("Timing validation: %s", 
                                         timing_cfg.enable_timing_checking ? "ENABLED" : "DISABLED"), UVM_LOW)
    `uvm_info("JTAG_ENV_INFO", $sformatf("Functional coverage: %s", 
                                         coverage_cfg.enable_functional_coverage ? "ENABLED" : "DISABLED"), UVM_LOW)
    `uvm_info("JTAG_ENV_INFO", $sformatf("Performance monitoring: %s", 
                                         performance_cfg.enable_performance_monitoring ? "ENABLED" : "DISABLED"), UVM_LOW)
    `uvm_info("JTAG_ENV_INFO", $sformatf("Error injection: %s", 
                                         error_cfg.enable_error_injection ? "ENABLED" : "DISABLED"), UVM_LOW)
    `uvm_info("JTAG_ENV_INFO", $sformatf("Debug dashboard: %s", 
                                         debug_cfg.enable_debug_dashboard ? "ENABLED" : "DISABLED"), UVM_LOW)
  endfunction
  
  virtual function void print_component_status();
    `uvm_info("JTAG_ENV_INFO", "--- Component Status ---", UVM_LOW)
    `uvm_info("JTAG_ENV_INFO", $sformatf("Agent: %s", jtag_agnt != null ? "ACTIVE" : "INACTIVE"), UVM_LOW)
    `uvm_info("JTAG_ENV_INFO", $sformatf("Protocol Checker: %s", jtag_agnt.protocol_checker != null ? "ACTIVE" : "INACTIVE"), UVM_LOW)
    `uvm_info("JTAG_ENV_INFO", $sformatf("Timing Validator: %s", jtag_agnt.timing_validator != null ? "ACTIVE" : "INACTIVE"), UVM_LOW)
    `uvm_info("JTAG_ENV_INFO", $sformatf("Coverage Collector: %s", jtag_agnt.coverage_collector != null ? "ACTIVE" : "INACTIVE"), UVM_LOW)
    `uvm_info("JTAG_ENV_INFO", $sformatf("Performance Monitor: %s", jtag_agnt.performance_monitor != null ? "ACTIVE" : "INACTIVE"), UVM_LOW)
    `uvm_info("JTAG_ENV_INFO", $sformatf("Scoreboard: %s", scoreboard != null ? "ACTIVE" : "INACTIVE"), UVM_LOW)
    `uvm_info("JTAG_ENV_INFO", $sformatf("Error Injector: %s", error_injector != null ? "ACTIVE" : "INACTIVE"), UVM_LOW)
    `uvm_info("JTAG_ENV_INFO", $sformatf("Debug Dashboard: %s", debug_dashboard != null ? "ACTIVE" : "INACTIVE"), UVM_LOW)
    `uvm_info("JTAG_ENV_INFO", $sformatf("Virtual Sequencer: %s", virtual_sequencer != null ? "ACTIVE" : "INACTIVE"), UVM_LOW)
  endfunction
  
  virtual function void print_final_statistics();
    `uvm_info("JTAG_ENV_INFO", "--- Final Statistics ---", UVM_LOW)
    
    if (jtag_agnt.performance_monitor != null) begin
      `uvm_info("JTAG_ENV_INFO", $sformatf("Total transactions: %0d", 
                                           jtag_agnt.performance_monitor.total_transactions), UVM_LOW)
      `uvm_info("JTAG_ENV_INFO", $sformatf("Success rate: %0.2f%%", 
                                           (real'(jtag_agnt.performance_monitor.successful_transactions) / 
                                            real'(jtag_agnt.performance_monitor.total_transactions)) * 100.0), UVM_LOW)
      `uvm_info("JTAG_ENV_INFO", $sformatf("Average throughput: %0.2f Hz", 
                                           jtag_agnt.performance_monitor.average_throughput), UVM_LOW)
      `uvm_info("JTAG_ENV_INFO", $sformatf("Overall quality score: %0.2f%%", 
                                           jtag_agnt.performance_monitor.overall_quality_score), UVM_LOW)
    end
    
    if (jtag_agnt.coverage_collector != null) begin
      `uvm_info("JTAG_ENV_INFO", $sformatf("Overall coverage: %0.2f%%", 
                                           jtag_agnt.coverage_collector.get_overall_coverage()), UVM_LOW)
    end
    
    if (scoreboard != null) begin
      `uvm_info("JTAG_ENV_INFO", $sformatf("Scoreboard matches: %0d", 
                                           scoreboard.get_match_count()), UVM_LOW)
      `uvm_info("JTAG_ENV_INFO", $sformatf("Scoreboard mismatches: %0d", 
                                           scoreboard.get_mismatch_count()), UVM_LOW)
    end
  endfunction
  
  function void end_of_elaboration_phase (uvm_phase phase);
    print();
  endfunction // end_of_elaboration_phase

endclass // jtag_env

`endif
