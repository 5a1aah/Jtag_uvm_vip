`ifndef JTAG_AGENT__SVH
 `define JTAG_AGENT__SVH

class jtag_agent extends uvm_agent;
  
  // Core components
  jtag_driver driver;
  jtag_sequencer sequencer;
  jtag_collector collector;
  jtag_monitor monitor;
  
  // Enhanced verification components
  jtag_protocol_checker protocol_checker;
  jtag_timing_validator timing_validator;
  jtag_coverage_collector coverage_collector;
  jtag_performance_monitor performance_monitor;
  
  // Configuration objects
  jtag_agent_config jtag_agent_cfg;
  jtag_protocol_config protocol_cfg;
  jtag_timing_config timing_cfg;
  jtag_coverage_config coverage_cfg;
  jtag_performance_config performance_cfg;

  `uvm_component_utils_begin(jtag_agent)
  `uvm_field_object(jtag_agent_cfg, UVM_DEFAULT)
  `uvm_component_utils_end
    
    function new (string name, uvm_component parent);
      super.new(name,parent);
    endfunction // new

  extern function void build_phase (uvm_phase phase);
  extern function void connect_phase (uvm_phase phase);
  
  // function void end_of_elaboration_phase (uvm_phase phase);
  //   print();
  // endfunction // end_of_elaboration_phase  
endclass // jtag_agent

function void jtag_agent::build_phase (uvm_phase phase);
  super.build_phase(phase);
  
  // Get or create main agent configuration
  if (jtag_agent_cfg == null)
    begin
      `uvm_info("JTAG_AGENT_INFO", " Creating configuration", UVM_LOW)
      jtag_agent_cfg = jtag_agent_config::type_id::create("jtag_agent_cfg");
      if (!jtag_agent_cfg.randomize())
        `uvm_fatal("JTAG_AGENT_FATAL", "Randomization of jtag_agent_cfg failed")
    end
  else
    `uvm_info("JTAG_AGENT_INFO", " Agent used auto config", UVM_LOW)
  
  // Get or create enhanced configuration objects
  if(!uvm_config_db#(jtag_protocol_config)::get(this, "", "protocol_cfg", protocol_cfg)) begin
    `uvm_info("JTAG_AGENT_INFO", "Creating default protocol configuration", UVM_LOW)
    protocol_cfg = jtag_protocol_config::type_id::create("protocol_cfg");
    if (!protocol_cfg.randomize())
      `uvm_warning("JTAG_AGENT_WARN", "Randomization of protocol_cfg failed")
  end
  
  if(!uvm_config_db#(jtag_timing_config)::get(this, "", "timing_cfg", timing_cfg)) begin
    `uvm_info("JTAG_AGENT_INFO", "Creating default timing configuration", UVM_LOW)
    timing_cfg = jtag_timing_config::type_id::create("timing_cfg");
    if (!timing_cfg.randomize())
      `uvm_warning("JTAG_AGENT_WARN", "Randomization of timing_cfg failed")
  end
  
  if(!uvm_config_db#(jtag_coverage_config)::get(this, "", "coverage_cfg", coverage_cfg)) begin
    `uvm_info("JTAG_AGENT_INFO", "Creating default coverage configuration", UVM_LOW)
    coverage_cfg = jtag_coverage_config::type_id::create("coverage_cfg");
    if (!coverage_cfg.randomize())
      `uvm_warning("JTAG_AGENT_WARN", "Randomization of coverage_cfg failed")
  end
  
  if(!uvm_config_db#(jtag_performance_config)::get(this, "", "performance_cfg", performance_cfg)) begin
    `uvm_info("JTAG_AGENT_INFO", "Creating default performance configuration", UVM_LOW)
    performance_cfg = jtag_performance_config::type_id::create("performance_cfg");
    if (!performance_cfg.randomize())
      `uvm_warning("JTAG_AGENT_WARN", "Randomization of performance_cfg failed")
  end
  
  // Set configurations in config_db for sub-components
  uvm_config_db#(jtag_protocol_config)::set(this, "*", "protocol_cfg", protocol_cfg);
  uvm_config_db#(jtag_timing_config)::set(this, "*", "timing_cfg", timing_cfg);
  uvm_config_db#(jtag_coverage_config)::set(this, "*", "coverage_cfg", coverage_cfg);
  uvm_config_db#(jtag_performance_config)::set(this, "*", "performance_cfg", performance_cfg);
  
  if (jtag_agent_cfg.is_active == UVM_ACTIVE)
    begin
      `uvm_info("JTAG_AGENT_INFO", "Agent is active... building drv and seq", UVM_LOW)
      
      uvm_config_db#(uvm_object)::set(this,"driver","driver_cfg", jtag_agent_cfg.driver_cfg);

      // the existance of vif can be checked in build phase since it is top down.
      // That way we avoid driver errors in connect phase that is bottom up
      if(uvm_config_db#(jtag_vif)::exists(this, get_full_name(), "jtag_virtual_if"))
        begin
          `uvm_info("JTAG_AGENT_INFO","VIF EXISTS IN CONFIG DB",UVM_LOW)
        end
      else
        `uvm_fatal("JTAG_AGENT_FATAL", {"VIF must exist for: ", get_full_name()})
      
      // the existance of proxy can be checked in build phase since it is top down.
      // That way we avoid driver errors in connect phase that is bottom up
      if(uvm_config_db#(jtag_if_proxy)::exists(this, get_full_name(), "jtag_if_proxy"))
        begin
          `uvm_info("JTAG_AGENT_INFO","IF_PROXY EXISTS IN CONFIG DB",UVM_LOW)
        end
      else
        `uvm_fatal("JTAG_AGENT_FATAL", {"IF_PROXY must exist for: ", get_full_name()})
      
      driver = jtag_driver::type_id::create("driver",this);
      sequencer = jtag_sequencer::type_id::create("sequencer",this);
    end 
  
  // Create core monitoring components
  collector = jtag_collector::type_id::create("collector",this);
  monitor = jtag_monitor::type_id::create("monitor",this);
  
  // Create enhanced verification components
  if (protocol_cfg.enable_compliance_checking) begin
    `uvm_info("JTAG_AGENT_INFO", "Creating protocol checker", UVM_LOW)
    protocol_checker = jtag_protocol_checker::type_id::create("protocol_checker", this);
  end
  
  if (timing_cfg.enable_timing_checking) begin
    `uvm_info("JTAG_AGENT_INFO", "Creating timing validator", UVM_LOW)
    timing_validator = jtag_timing_validator::type_id::create("timing_validator", this);
  end
  
  if (coverage_cfg.enable_functional_coverage) begin
    `uvm_info("JTAG_AGENT_INFO", "Creating coverage collector", UVM_LOW)
    coverage_collector = jtag_coverage_collector::type_id::create("coverage_collector", this);
  end
  
  if (performance_cfg.enable_performance_monitoring) begin
    `uvm_info("JTAG_AGENT_INFO", "Creating performance monitor", UVM_LOW)
    performance_monitor = jtag_performance_monitor::type_id::create("performance_monitor", this);
  end
  
endfunction // build_phase

function void jtag_agent::connect_phase (uvm_phase phase);
  super.connect_phase(phase);
  
  `uvm_info("JTAG_AGENT_INFO", "Agent connect phase", UVM_LOW)

  // Connect core components
  collector.item_collected_rx_port.connect(monitor.col_mon_rx_import);
  collector.item_collected_tx_port.connect(monitor.col_mon_tx_import);
  
  // requires automatic configuration from test
  if (monitor.drv_mon_tx_check_en)
    driver.drv_mon_tx_port.connect(monitor.drv_mon_tx_import);
    
  if (jtag_agent_cfg.is_active == UVM_ACTIVE)
    begin
      `uvm_info("JTAG_AGENT_INFO", "Agent is active... connecting drv and seq", UVM_LOW)
      driver.seq_item_port.connect(sequencer.seq_item_export);
    end
  
  // Connect enhanced verification components
  if (protocol_checker != null) begin
    `uvm_info("JTAG_AGENT_INFO", "Connecting protocol checker", UVM_LOW)
    collector.item_collected_rx_port.connect(protocol_checker.rx_analysis_imp);
    collector.item_collected_tx_port.connect(protocol_checker.tx_analysis_imp);
    if (jtag_agent_cfg.is_active == UVM_ACTIVE)
      driver.drv_mon_tx_port.connect(protocol_checker.tx_analysis_imp);
  end
  
  if (timing_validator != null) begin
    `uvm_info("JTAG_AGENT_INFO", "Connecting timing validator", UVM_LOW)
    collector.item_collected_rx_port.connect(timing_validator.rx_analysis_imp);
    collector.item_collected_tx_port.connect(timing_validator.tx_analysis_imp);
    if (jtag_agent_cfg.is_active == UVM_ACTIVE)
      driver.drv_mon_tx_port.connect(timing_validator.tx_analysis_imp);
  end
  
  if (coverage_collector != null) begin
    `uvm_info("JTAG_AGENT_INFO", "Connecting coverage collector", UVM_LOW)
    collector.item_collected_rx_port.connect(coverage_collector.analysis_export);
    collector.item_collected_tx_port.connect(coverage_collector.analysis_export);
    if (jtag_agent_cfg.is_active == UVM_ACTIVE)
      driver.drv_mon_tx_port.connect(coverage_collector.analysis_export);
  end
  
  if (performance_monitor != null) begin
    `uvm_info("JTAG_AGENT_INFO", "Connecting performance monitor", UVM_LOW)
    collector.item_collected_rx_port.connect(performance_monitor.trans_analysis_imp);
    collector.item_collected_tx_port.connect(performance_monitor.trans_analysis_imp);
    if (jtag_agent_cfg.is_active == UVM_ACTIVE)
      driver.drv_mon_tx_port.connect(performance_monitor.trans_analysis_imp);
    
    // Connect cross-component analysis ports for comprehensive monitoring
    if (protocol_checker != null)
      protocol_checker.compliance_ap.connect(performance_monitor.trans_analysis_imp);
    if (timing_validator != null)
      timing_validator.timing_ap.connect(performance_monitor.timing_analysis_imp);
  end
  
endfunction // connect_phase

`endif
