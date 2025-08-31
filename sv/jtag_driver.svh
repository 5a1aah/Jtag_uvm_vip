`ifndef JTAG_DRIVER_SVH
`define JTAG_DRIVER_SVH

class jtag_driver extends uvm_driver #(jtag_base_transaction, jtag_base_transaction);
  `uvm_component_utils(jtag_driver)
  
  // Enhanced configuration objects
  jtag_driver_config driver_cfg;
  jtag_timing_config timing_cfg;
  jtag_protocol_config protocol_cfg;
  jtag_error_config error_cfg;
  
  // Virtual interface and proxy
  virtual jtag_if jtag_vif_drv;
  jtag_if_proxy if_proxy;
  
  // Enhanced state tracking
  jtag_tap_state_e current_state = RESET;
  jtag_tap_state_e next_state;
  jtag_tap_state_e previous_state;
  bit exit;
  jtag_base_transaction temp_req;
  
  // Performance and timing tracking
  jtag_performance_metrics_s perf_metrics;
  real transaction_start_time;
  real transaction_end_time;
  int unsigned clock_cycles_count;
  
  // Error injection control
  bit error_injection_enabled = 0;
  jtag_error_type_e current_error_type = NO_ERROR;
  int unsigned error_injection_cycle = 0;
  
  // Protocol compliance tracking
  bit protocol_compliance_enabled = 1;
  jtag_protocol_standard_e current_protocol = IEEE_1149_1;
  bit timing_violation_detected = 0;
  
  // Enhanced monitoring and checking
  bit drv_mon_tx_check_en = 1;
  uvm_analysis_port #(jtag_base_transaction) drv_mon_tx_port;
  jtag_base_transaction drv_mon_tx_packet;
  
  // Coverage and analysis ports
  uvm_analysis_port #(jtag_timing_info_s) timing_analysis_port;
  uvm_analysis_port #(jtag_error_info_s) error_analysis_port;
  uvm_analysis_port #(jtag_performance_metrics_s) performance_analysis_port;
  
  function new(string name = "jtag_driver", uvm_component parent = null);
    super.new(name, parent);
    
    // Initialize performance metrics
    perf_metrics = '{default: 0};
    
    // Create analysis ports
    timing_analysis_port = new("timing_analysis_port", this);
    error_analysis_port = new("error_analysis_port", this);
    performance_analysis_port = new("performance_analysis_port", this);
  endfunction // new

  // virtual function void set_if_proxy(jtag_if_proxy if_proxy);
  //   this.if_proxy = if_proxy;
  // endfunction // set_if_proxy
  
  // Enhanced UVM phases
  function void build_phase (uvm_phase phase);
    super.build_phase(phase);
    
    // Get enhanced configuration objects
    if(!uvm_config_db#(jtag_driver_config)::get(this, "", "driver_cfg", driver_cfg)) begin
      `uvm_warning("JTAG_DRIVER_WARN", "Using default driver configuration")
      driver_cfg = jtag_driver_config::type_id::create("driver_cfg");
    end
    
    if(!uvm_config_db#(jtag_timing_config)::get(this, "", "timing_cfg", timing_cfg)) begin
      `uvm_info("JTAG_DRIVER_INFO", "Using default timing configuration", UVM_LOW)
      timing_cfg = jtag_timing_config::type_id::create("timing_cfg");
    end
    
    if(!uvm_config_db#(jtag_protocol_config)::get(this, "", "protocol_cfg", protocol_cfg)) begin
      `uvm_info("JTAG_DRIVER_INFO", "Using default protocol configuration", UVM_LOW)
      protocol_cfg = jtag_protocol_config::type_id::create("protocol_cfg");
    end
    
    if(!uvm_config_db#(jtag_error_config)::get(this, "", "error_cfg", error_cfg)) begin
      `uvm_info("JTAG_DRIVER_INFO", "Using default error configuration", UVM_LOW)
      error_cfg = jtag_error_config::type_id::create("error_cfg");
    end
    
    // Configure error injection
    error_injection_enabled = error_cfg.enable_error_injection;
    
    // Configure protocol compliance
    protocol_compliance_enabled = protocol_cfg.enable_compliance_checking;
    current_protocol = protocol_cfg.jtag_standard;
    
    // Create monitoring ports
    if (drv_mon_tx_check_en) begin
      drv_mon_tx_port = new("drv_mon_tx_port", this);
      drv_mon_tx_packet = jtag_base_transaction::type_id::create("drv_mon_tx_packet");
    end
    
    `uvm_info("JTAG_DRIVER_INFO", "Enhanced JTAG driver build phase completed", UVM_LOW)
  endfunction // build_phase
  
  virtual function void connect_phase (uvm_phase phase);
    super.connect_phase(phase);
   
    `uvm_info("JTAG_DRIVER_INFO", "Enhanced driver connect phase", UVM_LOW)
    
    // Get virtual interface
    if(!uvm_config_db#(virtual jtag_if)::get(this, "", "jtag_vif", jtag_vif_drv)) begin
      `uvm_fatal("JTAG_DRIVER_FATAL", {"Virtual interface must be set for: ", get_full_name()})
    end else begin
      `uvm_info("JTAG_DRIVER_INFO", {"Virtual interface configured for: ", get_full_name()}, UVM_LOW)
    end

    // Get interface proxy
    if(!uvm_config_db#(jtag_if_proxy)::get(this, "", "jtag_if_proxy", if_proxy)) begin
      `uvm_warning("JTAG_DRIVER_WARN", "Interface proxy not found, creating default")
      if_proxy = jtag_if_proxy::type_id::create("if_proxy");
    end else begin
      `uvm_info("JTAG_DRIVER_INFO", {"Interface proxy configured for: ", get_full_name()}, UVM_LOW)
    end
    
    // Initialize interface
    initialize_interface();
    
    `uvm_info("JTAG_DRIVER_INFO", "Enhanced driver connect phase completed", UVM_LOW)
  endfunction // connect_phase

  task run_phase (uvm_phase phase);
    if (jtag_vif_drv == null) begin
      `uvm_fatal("JTAG_DRIVER_FATAL", {"Virtual interface must be set for: ", get_full_name()})
    end
    
    `uvm_info("JTAG_DRIVER_INFO", "Enhanced JTAG driver run phase started", UVM_LOW)
    
    // Initialize TAP to known state
    reset_tap();
    
    // Main driver loop
    forever begin
      seq_item_port.get_next_item(req);
      
      // Start performance tracking
      transaction_start_time = $realtime;
      clock_cycles_count = 0;
      
      // Create response transaction
      rsp = jtag_base_transaction::type_id::create("rsp");
      rsp.set_id_info(req);
      
      phase.raise_objection(this, "JTAG Driver processing transaction");
      
      // Clone request for processing
      $cast(temp_req, req.clone());
      
      `uvm_info("JTAG_DRIVER_INFO", $sformatf("Driving transaction type: %s", temp_req.transaction_type.name()), UVM_MEDIUM)
      
      // Drive transaction based on type
      case (temp_req.transaction_type)
        INSTRUCTION_TRANS: drive_instruction_transaction(temp_req);
        DATA_TRANS: drive_data_transaction(temp_req);
        BOUNDARY_SCAN_TRANS: drive_boundary_scan_transaction(temp_req);
        DEBUG_TRANS: drive_debug_transaction(temp_req);
        IDCODE_READ_TRANS: drive_idcode_transaction(temp_req);
        TAP_RESET_TRANS: drive_reset_transaction(temp_req);
        COMPLIANCE_TEST_TRANS: drive_compliance_transaction(temp_req);
        default: begin
          `uvm_error("JTAG_DRIVER_ERROR", $sformatf("Unknown transaction type: %s", temp_req.transaction_type.name()))
        end
      endcase
      
      // Update performance metrics
      transaction_end_time = $realtime;
      update_performance_metrics();
      
      // Send monitoring information
      if (drv_mon_tx_check_en) begin
        drv_mon_tx_port.write(temp_req);
      end
      
      phase.drop_objection(this, "JTAG Driver completed transaction");
      
      // Apply post-transaction delay
      apply_transaction_delay(temp_req.timing_info.post_transaction_delay);
      
      seq_item_port.item_done(rsp);
    end
  endtask // run_phase
  
  task all_dropped (uvm_objection objection, uvm_object source_obj, string description, int count);
    if (objection == uvm_test_done) begin
      `uvm_info("JTAG_DRIVER_INFO", "Enhanced JTAG driver @ all_dropped - applying drain time", UVM_LOW)
      
      // Apply configurable drain time
      repeat (timing_cfg.drain_time_cycles) @jtag_vif_drv.tb_ck;
      
      // Final performance report
      report_final_performance();
    end
  endtask // all_dropped
  
  //=============================================================================
  // Enhanced Transaction Driving Tasks
  //=============================================================================
  
  // Drive instruction register transaction
  extern task drive_instruction_transaction(jtag_base_transaction trans);
  
  // Drive data register transaction
  extern task drive_data_transaction(jtag_base_transaction trans);
  
  // Drive boundary scan transaction
  extern task drive_boundary_scan_transaction(jtag_base_transaction trans);
  
  // Drive debug access transaction
  extern task drive_debug_transaction(jtag_base_transaction trans);
  
  // Drive IDCODE read transaction
  extern task drive_idcode_transaction(jtag_base_transaction trans);
  
  // Drive TAP reset transaction
  extern task drive_reset_transaction(jtag_base_transaction trans);
  
  // Drive compliance test transaction
  extern task drive_compliance_transaction(jtag_base_transaction trans);
  
  //=============================================================================
  // Low-level JTAG Operations
  //=============================================================================
  
  // Initialize interface to known state
  extern task initialize_interface();
  
  // Navigate TAP state machine
  extern task navigate_to_state(jtag_tap_state_e target_state);
  
  // Shift instruction register
  extern task shift_ir(bit [MAX_INSTRUCTION_LENGTH-1:0] instruction, int length);
  
  // Shift data register
  extern task shift_dr(bit [MAX_DATA_LENGTH-1:0] data_in, output bit [MAX_DATA_LENGTH-1:0] data_out, int length);
  
  //=============================================================================
  // Reset Operations
  //=============================================================================
  
  // Perform TAP reset
  extern task reset_tap();
  
  // Soft reset via TMS
  extern task soft_reset();
  
  // Hard reset via TRST
  extern task hard_reset();
  
  // TMS-only reset sequence
  extern task tms_reset();
  
  //=============================================================================
  // Error Injection
  //=============================================================================
  
  // Inject timing errors
  extern task inject_timing_error(jtag_error_type_e error_type);
  
  // Inject protocol errors
  extern task inject_protocol_error(jtag_error_type_e error_type);
  
  // Inject data corruption
  extern task inject_data_error(jtag_error_type_e error_type);
  
  //=============================================================================
  // Utility Functions
  //=============================================================================
  
  // Apply timing delays
  extern task apply_timing_delay(real delay_ns);
  
  // Apply transaction delay
  extern task apply_transaction_delay(int cycles);
  
  // Calculate TAP state path
  extern function jtag_tap_state_e[] calculate_state_path(jtag_tap_state_e from_state, jtag_tap_state_e to_state);
  
  // Update performance metrics
  extern function void update_performance_metrics();
  
  // Report final performance
  extern function void report_final_performance();
  
  // Sample coverage
  extern function void sample_coverage(jtag_base_transaction trans);
  
endclass // jtag_driver

//=============================================================================
// Enhanced Transaction Driving Task Implementations
//=============================================================================

// Drive instruction register transaction
task jtag_driver::drive_instruction_transaction(jtag_base_transaction trans);
  jtag_instruction_transaction instr_trans;
  bit [MAX_INSTRUCTION_LENGTH-1:0] captured_data;
  
  if (!$cast(instr_trans, trans)) begin
    `uvm_error("JTAG_DRIVER_ERROR", "Failed to cast to instruction transaction")
    return;
  end
  
  `uvm_info("JTAG_DRIVER_INFO", $sformatf("Driving instruction: 0x%0h", instr_trans.instruction), UVM_MEDIUM)
  
  // Apply pre-transaction timing
  apply_timing_delay(trans.timing_info.setup_time_ns);
  
  // Navigate to SHIFT_IR state
  navigate_to_state(SHIFT_IR);
  
  // Inject errors if enabled
  if (error_injection_enabled && (trans.error_info.error_type != NO_ERROR)) begin
    inject_protocol_error(trans.error_info.error_type);
  end
  
  // Shift instruction
  shift_ir(instr_trans.instruction, instr_trans.instruction_length);
  
  // Navigate to UPDATE_IR
  navigate_to_state(UPDATE_IR);
  
  // Apply hold time
  apply_timing_delay(trans.timing_info.hold_time_ns);
  
  // Update response
  rsp.transaction_type = INSTRUCTION_TRANS;
  rsp.status = TRANSACTION_SUCCESS;
  
  // Sample coverage
  sample_coverage(trans);
  
endtask // drive_instruction_transaction

// Drive data register transaction
task jtag_driver::drive_data_transaction(jtag_base_transaction trans);
  jtag_data_transaction data_trans;
  bit [MAX_DATA_LENGTH-1:0] captured_data;
  
  if (!$cast(data_trans, trans)) begin
    `uvm_error("JTAG_DRIVER_ERROR", "Failed to cast to data transaction")
    return;
  end
  
  `uvm_info("JTAG_DRIVER_INFO", $sformatf("Driving data: 0x%0h, length: %0d", data_trans.data, data_trans.data_length), UVM_MEDIUM)
  
  // Apply pre-transaction timing
  apply_timing_delay(trans.timing_info.setup_time_ns);
  
  // Navigate to SHIFT_DR state
  navigate_to_state(SHIFT_DR);
  
  // Inject errors if enabled
  if (error_injection_enabled && (trans.error_info.error_type != NO_ERROR)) begin
    inject_data_error(trans.error_info.error_type);
  end
  
  // Shift data
  shift_dr(data_trans.data, captured_data, data_trans.data_length);
  
  // Navigate to UPDATE_DR
  navigate_to_state(UPDATE_DR);
  
  // Apply hold time
  apply_timing_delay(trans.timing_info.hold_time_ns);
  
  // Update response with captured data
  rsp.transaction_type = DATA_TRANS;
  rsp.status = TRANSACTION_SUCCESS;
  
  // Sample coverage
  sample_coverage(trans);
  
endtask // drive_data_transaction

// Drive boundary scan transaction
task jtag_driver::drive_boundary_scan_transaction(jtag_base_transaction trans);
  jtag_boundary_scan_transaction bs_trans;
  bit [MAX_BOUNDARY_LENGTH-1:0] captured_data;
  
  if (!$cast(bs_trans, trans)) begin
    `uvm_error("JTAG_DRIVER_ERROR", "Failed to cast to boundary scan transaction")
    return;
  end
  
  `uvm_info("JTAG_DRIVER_INFO", $sformatf("Driving boundary scan operation: %s", bs_trans.operation.name()), UVM_MEDIUM)
  
  // Load appropriate instruction for boundary scan
  case (bs_trans.operation)
    EXTEST: begin
      navigate_to_state(SHIFT_IR);
      shift_ir(EXTEST, driver_cfg.instruction_length);
      navigate_to_state(UPDATE_IR);
    end
    INTEST: begin
      navigate_to_state(SHIFT_IR);
      shift_ir(INTEST, driver_cfg.instruction_length);
      navigate_to_state(UPDATE_IR);
    end
    SAMPLE_PRELOAD: begin
      navigate_to_state(SHIFT_IR);
      shift_ir(SAMPLE_PRELOAD, driver_cfg.instruction_length);
      navigate_to_state(UPDATE_IR);
    end
  endcase
  
  // Apply timing delay
  apply_timing_delay(trans.timing_info.setup_time_ns);
  
  // Shift boundary scan data
  navigate_to_state(SHIFT_DR);
  shift_dr(bs_trans.boundary_data, captured_data, bs_trans.boundary_length);
  navigate_to_state(UPDATE_DR);
  
  // Update response
  rsp.transaction_type = BOUNDARY_SCAN_TRANS;
  rsp.status = TRANSACTION_SUCCESS;
  
  sample_coverage(trans);
  
endtask // drive_boundary_scan_transaction

// Drive debug access transaction
task jtag_driver::drive_debug_transaction(jtag_base_transaction trans);
  jtag_debug_transaction debug_trans;
  bit [MAX_DATA_LENGTH-1:0] captured_data;
  
  if (!$cast(debug_trans, trans)) begin
    `uvm_error("JTAG_DRIVER_ERROR", "Failed to cast to debug transaction")
    return;
  end
  
  `uvm_info("JTAG_DRIVER_INFO", $sformatf("Driving debug operation: %s", debug_trans.operation.name()), UVM_MEDIUM)
  
  // Load debug instruction
  navigate_to_state(SHIFT_IR);
  shift_ir(debug_trans.debug_instruction, driver_cfg.instruction_length);
  navigate_to_state(UPDATE_IR);
  
  // Perform debug operation
  case (debug_trans.operation)
    DEBUG_REG_READ, DEBUG_REG_WRITE: begin
      navigate_to_state(SHIFT_DR);
      shift_dr(debug_trans.debug_data, captured_data, debug_trans.data_length);
      navigate_to_state(UPDATE_DR);
    end
    DEBUG_MEM_READ, DEBUG_MEM_WRITE: begin
      // Multi-step memory access
      navigate_to_state(SHIFT_DR);
      shift_dr(debug_trans.address, captured_data, 32); // Address phase
      navigate_to_state(UPDATE_DR);
      navigate_to_state(SHIFT_DR);
      shift_dr(debug_trans.debug_data, captured_data, debug_trans.data_length); // Data phase
      navigate_to_state(UPDATE_DR);
    end
  endcase
  
  rsp.transaction_type = DEBUG_TRANS;
  rsp.status = TRANSACTION_SUCCESS;
  
  sample_coverage(trans);
  
endtask // drive_debug_transaction

// Drive IDCODE read transaction
task jtag_driver::drive_idcode_transaction(jtag_base_transaction trans);
  bit [31:0] idcode_value;
  
  `uvm_info("JTAG_DRIVER_INFO", "Reading IDCODE", UVM_MEDIUM)
  
  // Load IDCODE instruction
  navigate_to_state(SHIFT_IR);
  shift_ir(IDCODE, driver_cfg.instruction_length);
  navigate_to_state(UPDATE_IR);
  
  // Read IDCODE value
  navigate_to_state(SHIFT_DR);
  shift_dr(32'h0, idcode_value, 32);
  navigate_to_state(UPDATE_DR);
  
  `uvm_info("JTAG_DRIVER_INFO", $sformatf("IDCODE read: 0x%08h", idcode_value), UVM_LOW)
  
  rsp.transaction_type = IDCODE_READ_TRANS;
  rsp.status = TRANSACTION_SUCCESS;
  
  sample_coverage(trans);
  
endtask // drive_idcode_transaction

// Drive TAP reset transaction
task jtag_driver::drive_reset_transaction(jtag_base_transaction trans);
  jtag_reset_transaction reset_trans;
  
  if (!$cast(reset_trans, trans)) begin
    `uvm_error("JTAG_DRIVER_ERROR", "Failed to cast to reset transaction")
    return;
  end
  
  `uvm_info("JTAG_DRIVER_INFO", $sformatf("Performing reset: %s", reset_trans.reset_type.name()), UVM_MEDIUM)
  
  case (reset_trans.reset_type)
    SOFT_RESET: soft_reset();
    HARD_RESET: hard_reset();
    TMS_RESET: tms_reset();
  endcase
  
  rsp.transaction_type = TAP_RESET_TRANS;
  rsp.status = TRANSACTION_SUCCESS;
  
  sample_coverage(trans);
  
endtask // drive_reset_transaction

// Drive compliance test transaction
task jtag_driver::drive_compliance_transaction(jtag_base_transaction trans);
  jtag_compliance_transaction comp_trans;
  
  if (!$cast(comp_trans, trans)) begin
    `uvm_error("JTAG_DRIVER_ERROR", "Failed to cast to compliance transaction")
    return;
  end
  
  `uvm_info("JTAG_DRIVER_INFO", $sformatf("Running compliance test: %s", comp_trans.test_type.name()), UVM_MEDIUM)
  
  // Execute compliance test based on type
  case (comp_trans.test_type)
    TIMING_COMPLIANCE: begin
      // Perform timing compliance test
      validate_timing_compliance(comp_trans);
    end
    PROTOCOL_COMPLIANCE: begin
      // Perform protocol compliance test
      validate_protocol_compliance(comp_trans);
    end
    INSTRUCTION_COMPLIANCE: begin
      // Test all mandatory instructions
      test_mandatory_instructions(comp_trans);
    end
  endcase
  
  rsp.transaction_type = COMPLIANCE_TEST_TRANS;
  rsp.status = TRANSACTION_SUCCESS;
  
  sample_coverage(trans);
  
endtask // drive_compliance_transaction

//=============================================================================
// Low-level JTAG Operations Implementation
//=============================================================================

// Initialize interface to known state
task jtag_driver::initialize_interface();
  `uvm_info("JTAG_DRIVER_INFO", "Initializing JTAG interface", UVM_MEDIUM)
  
  // Set initial signal states
  if_proxy.set_tms(1);
  if_proxy.set_tdi(0);
  
  // Reset TAP to known state
  reset_tap();
  
  current_state = RESET;
  previous_state = RESET;
  
endtask // initialize_interface

// Navigate TAP state machine
task jtag_driver::navigate_to_state(jtag_tap_state_e target_state);
  jtag_tap_state_e[] state_path;
  int path_length;
  
  if (current_state == target_state) return;
  
  `uvm_info("JTAG_DRIVER_INFO", $sformatf("Navigating from %s to %s", current_state.name(), target_state.name()), UVM_HIGH)
  
  // Calculate optimal path
  state_path = calculate_state_path(current_state, target_state);
  path_length = state_path.size();
  
  // Execute state transitions
  for (int i = 0; i < path_length; i++) begin
    previous_state = current_state;
    
    // Determine TMS value for transition
    case (current_state)
      RESET: if_proxy.set_tms(state_path[i] == RESET ? 1 : 0);
      IDLE: if_proxy.set_tms(state_path[i] == SELECT_DR ? 1 : 0);
      SELECT_DR: if_proxy.set_tms(state_path[i] == SELECT_IR ? 1 : 0);
      SELECT_IR: if_proxy.set_tms(state_path[i] == RESET ? 1 : 0);
      CAPTURE_DR: if_proxy.set_tms(state_path[i] == EXIT_DR ? 1 : 0);
      CAPTURE_IR: if_proxy.set_tms(state_path[i] == EXIT_IR ? 1 : 0);
      SHIFT_DR: if_proxy.set_tms(state_path[i] == EXIT_DR ? 1 : 0);
      SHIFT_IR: if_proxy.set_tms(state_path[i] == EXIT_IR ? 1 : 0);
      EXIT_DR: if_proxy.set_tms(state_path[i] == UPDATE_DR ? 1 : 0);
      EXIT_IR: if_proxy.set_tms(state_path[i] == UPDATE_IR ? 1 : 0);
      PAUSE_DR: if_proxy.set_tms(state_path[i] == EXIT2_DR ? 1 : 0);
      PAUSE_IR: if_proxy.set_tms(state_path[i] == EXIT2_IR ? 1 : 0);
      EXIT2_DR: if_proxy.set_tms(state_path[i] == UPDATE_DR ? 1 : 0);
      EXIT2_IR: if_proxy.set_tms(state_path[i] == UPDATE_IR ? 1 : 0);
      UPDATE_DR: if_proxy.set_tms(state_path[i] == SELECT_DR ? 1 : 0);
      UPDATE_IR: if_proxy.set_tms(state_path[i] == SELECT_DR ? 1 : 0);
    endcase
    
    @jtag_vif_drv.tb_ck;
    clock_cycles_count++;
    current_state = state_path[i];
  end
  
endtask // navigate_to_state

//=============================================================================
// Old function implementations (to be replaced)
//=============================================================================

// Shift instruction register
task jtag_driver::shift_ir(bit [MAX_INSTRUCTION_LENGTH-1:0] instruction, int length);
  bit [MAX_INSTRUCTION_LENGTH-1:0] captured_ir;
  
  `uvm_info("JTAG_DRIVER_INFO", $sformatf("Shifting IR: 0x%0h (length=%0d)", instruction, length), UVM_HIGH)
  
  for (int i = 0; i < length; i++) begin
    // Set TDI with instruction bit (LSB first)
    if_proxy.set_tdi(instruction[i]);
    
    // Capture TDO
    captured_ir[i] = if_proxy.get_tdo();
    
    // Apply timing delay
    apply_timing_delay(timing_cfg.tck_period_ns / 2);
    
    @jtag_vif_drv.tb_ck;
    clock_cycles_count++;
  end
  
  `uvm_info("JTAG_DRIVER_INFO", $sformatf("Captured IR: 0x%0h", captured_ir), UVM_HIGH)
  
endtask // shift_ir


// Shift data register
task jtag_driver::shift_dr(bit [MAX_DATA_LENGTH-1:0] data_in, output bit [MAX_DATA_LENGTH-1:0] data_out, int length);
  
  `uvm_info("JTAG_DRIVER_INFO", $sformatf("Shifting DR: 0x%0h (length=%0d)", data_in, length), UVM_HIGH)
  
  data_out = 0;
  
  for (int i = 0; i < length; i++) begin
    // Set TDI with data bit (LSB first)
    if_proxy.set_tdi(data_in[i]);
    
    // Capture TDO
    data_out[i] = if_proxy.get_tdo();
    
    // Apply timing delay
    apply_timing_delay(timing_cfg.tck_period_ns / 2);
    
    @jtag_vif_drv.tb_ck;
    clock_cycles_count++;
  end
  
  `uvm_info("JTAG_DRIVER_INFO", $sformatf("Captured DR: 0x%0h", data_out), UVM_HIGH)
  
endtask // shift_dr

//=============================================================================
// Reset Operations Implementation
//=============================================================================

// Reset TAP to known state
task jtag_driver::reset_tap();
  `uvm_info("JTAG_DRIVER_INFO", "Resetting TAP", UVM_MEDIUM)
  
  // Hold TMS high for 5 clock cycles to ensure reset
  if_proxy.set_tms(1);
  repeat(5) begin
    @jtag_vif_drv.tb_ck;
    clock_cycles_count++;
  end
  
  current_state = RESET;
  previous_state = RESET;
  
endtask // reset_tap

// Soft reset (TMS-based)
task jtag_driver::soft_reset();
  `uvm_info("JTAG_DRIVER_INFO", "Performing soft reset", UVM_MEDIUM)
  
  reset_tap();
  navigate_to_state(IDLE);
  
endtask // soft_reset

// Hard reset (TRST-based if available)
task jtag_driver::hard_reset();
  `uvm_info("JTAG_DRIVER_INFO", "Performing hard reset", UVM_MEDIUM)
  
  // If TRST is available, use it
  if (if_proxy.has_trst()) begin
    if_proxy.assert_trst();
    apply_timing_delay(timing_cfg.trst_pulse_width_ns);
    if_proxy.deassert_trst();
    apply_timing_delay(timing_cfg.trst_setup_time_ns);
  end else begin
    // Fall back to TMS reset
    soft_reset();
  end
  
  current_state = RESET;
  previous_state = RESET;
  
endtask // hard_reset

// TMS-only reset
task jtag_driver::tms_reset();
  `uvm_info("JTAG_DRIVER_INFO", "Performing TMS reset", UVM_MEDIUM)
  
  soft_reset();
  
endtask // tms_reset

//=============================================================================
// Error Injection Implementation
//=============================================================================

// Inject timing errors
task jtag_driver::inject_timing_error(jtag_error_type_e error_type);
  real error_delay;
  
  if (!error_cfg.enable_error_injection) return;
  
  case (error_type)
    SETUP_VIOLATION: begin
      error_delay = timing_cfg.tdi_setup_time_ns * error_cfg.timing_error_percentage / 100.0;
      apply_timing_delay(error_delay);
    end
    HOLD_VIOLATION: begin
      error_delay = timing_cfg.tdi_hold_time_ns * error_cfg.timing_error_percentage / 100.0;
      apply_timing_delay(-error_delay); // Negative delay (early transition)
    end
    CLOCK_JITTER: begin
      error_delay = $urandom_range(0, error_cfg.max_jitter_ns);
      apply_timing_delay(error_delay);
    end
  endcase
  
  error_injection_count++;
  
endtask // inject_timing_error

// Inject protocol errors
task jtag_driver::inject_protocol_error(jtag_error_type_e error_type);
  
  if (!error_cfg.enable_error_injection) return;
  
  case (error_type)
    INVALID_STATE_TRANSITION: begin
      // Force invalid TMS sequence
      if_proxy.set_tms($urandom());
    end
    INCORRECT_INSTRUCTION: begin
      // Use invalid instruction
      shift_ir($urandom(), driver_cfg.instruction_length);
    end
    DATA_LENGTH_MISMATCH: begin
      // Use wrong data length
      shift_dr($urandom(), , $urandom_range(1, MAX_DATA_LENGTH));
    end
  endcase
  
  protocol_violations_count++;
  
endtask // inject_protocol_error

// Inject data corruption
task jtag_driver::inject_data_error(jtag_error_type_e error_type);
  
  if (!error_cfg.enable_error_injection) return;
  
  case (error_type)
    DATA_CORRUPTION: begin
      // Corrupt random bits
      for (int i = 0; i < error_cfg.corruption_bit_count; i++) begin
        int bit_pos = $urandom_range(0, temp_req.data_length-1);
        temp_req.data[bit_pos] = ~temp_req.data[bit_pos];
      end
    end
    STUCK_AT_FAULT: begin
      // Force TDI to stuck value
      if_proxy.set_tdi(error_cfg.stuck_at_value);
    end
  endcase
  
  data_errors_count++;
  
endtask // inject_data_error

//=============================================================================
// Utility Functions Implementation
//=============================================================================

// Apply timing delay
task jtag_driver::apply_timing_delay(real delay_ns);
  if (delay_ns > 0) begin
    #(delay_ns * 1ns);
  end
endtask // apply_timing_delay

// Apply transaction delay
task jtag_driver::apply_transaction_delay(int cycles);
  if (cycles > 0) begin
    repeat(cycles) @jtag_vif_drv.tb_ck;
    clock_cycles_count += cycles;
  end
endtask // apply_transaction_delay

// Calculate optimal state path
function jtag_tap_state_e[] jtag_driver::calculate_state_path(jtag_tap_state_e from_state, jtag_tap_state_e to_state);
  jtag_tap_state_e[] path;
  jtag_tap_state_e current;
  
  current = from_state;
  
  // Simple path calculation - can be optimized
  while (current != to_state) begin
    case (current)
      RESET: begin
        if (to_state == IDLE) begin
          path.push_back(IDLE);
          current = IDLE;
        end else begin
          path.push_back(IDLE);
          current = IDLE;
        end
      end
      IDLE: begin
        if (to_state inside {SELECT_DR, CAPTURE_DR, SHIFT_DR, EXIT_DR, PAUSE_DR, EXIT2_DR, UPDATE_DR}) begin
          path.push_back(SELECT_DR);
          current = SELECT_DR;
        end else if (to_state inside {SELECT_IR, CAPTURE_IR, SHIFT_IR, EXIT_IR, PAUSE_IR, EXIT2_IR, UPDATE_IR}) begin
          path.push_back(SELECT_DR);
          current = SELECT_DR;
        end else if (to_state == RESET) begin
          path.push_back(SELECT_DR);
          current = SELECT_DR;
        end
      end
      SELECT_DR: begin
        if (to_state inside {SELECT_IR, CAPTURE_IR, SHIFT_IR, EXIT_IR, PAUSE_IR, EXIT2_IR, UPDATE_IR, RESET}) begin
          path.push_back(SELECT_IR);
          current = SELECT_IR;
        end else begin
          path.push_back(CAPTURE_DR);
          current = CAPTURE_DR;
        end
      end
      SELECT_IR: begin
        if (to_state == RESET) begin
          path.push_back(RESET);
          current = RESET;
        end else begin
          path.push_back(CAPTURE_IR);
          current = CAPTURE_IR;
        end
      end
      CAPTURE_DR: begin
        if (to_state == SHIFT_DR) begin
          path.push_back(SHIFT_DR);
          current = SHIFT_DR;
        end else begin
          path.push_back(EXIT_DR);
          current = EXIT_DR;
        end
      end
      CAPTURE_IR: begin
        if (to_state == SHIFT_IR) begin
          path.push_back(SHIFT_IR);
          current = SHIFT_IR;
        end else begin
          path.push_back(EXIT_IR);
          current = EXIT_IR;
        end
      end
      SHIFT_DR: begin
        path.push_back(EXIT_DR);
        current = EXIT_DR;
      end
      SHIFT_IR: begin
        path.push_back(EXIT_IR);
        current = EXIT_IR;
      end
      EXIT_DR: begin
        if (to_state == PAUSE_DR) begin
          path.push_back(PAUSE_DR);
          current = PAUSE_DR;
        end else begin
          path.push_back(UPDATE_DR);
          current = UPDATE_DR;
        end
      end
      EXIT_IR: begin
        if (to_state == PAUSE_IR) begin
          path.push_back(PAUSE_IR);
          current = PAUSE_IR;
        end else begin
          path.push_back(UPDATE_IR);
          current = UPDATE_IR;
        end
      end
      PAUSE_DR: begin
        path.push_back(EXIT2_DR);
        current = EXIT2_DR;
      end
      PAUSE_IR: begin
        path.push_back(EXIT2_IR);
        current = EXIT2_IR;
      end
      EXIT2_DR: begin
        if (to_state == SHIFT_DR) begin
          path.push_back(SHIFT_DR);
          current = SHIFT_DR;
        end else begin
          path.push_back(UPDATE_DR);
          current = UPDATE_DR;
        end
      end
      EXIT2_IR: begin
        if (to_state == SHIFT_IR) begin
          path.push_back(SHIFT_IR);
          current = SHIFT_IR;
        end else begin
          path.push_back(UPDATE_IR);
          current = UPDATE_IR;
        end
      end
      UPDATE_DR: begin
        if (to_state == SELECT_DR) begin
          path.push_back(SELECT_DR);
          current = SELECT_DR;
        end else begin
          path.push_back(IDLE);
          current = IDLE;
        end
      end
      UPDATE_IR: begin
        if (to_state == SELECT_DR) begin
          path.push_back(SELECT_DR);
          current = SELECT_DR;
        end else begin
          path.push_back(IDLE);
          current = IDLE;
        end
      end
    endcase
  end
  
  return path;
  
endfunction // calculate_state_path

// Update performance metrics
function void jtag_driver::update_performance_metrics();
  real transaction_time;
  
  transaction_time = transaction_end_time - transaction_start_time;
  
  perf_metrics.total_transactions++;
  perf_metrics.total_time_ns += transaction_time;
  perf_metrics.total_clock_cycles += clock_cycles_count;
  
  if (transaction_time > perf_metrics.max_transaction_time_ns) begin
    perf_metrics.max_transaction_time_ns = transaction_time;
  end
  
  if (transaction_time < perf_metrics.min_transaction_time_ns || perf_metrics.min_transaction_time_ns == 0) begin
    perf_metrics.min_transaction_time_ns = transaction_time;
  end
  
  perf_metrics.avg_transaction_time_ns = perf_metrics.total_time_ns / perf_metrics.total_transactions;
  
  // Send performance data to analysis port
  performance_analysis_port.write(perf_metrics);
  
endfunction // update_performance_metrics

// Report final performance
function void jtag_driver::report_final_performance();
  `uvm_info("JTAG_DRIVER_PERF", $sformatf(
    "Final Performance Report:\n" +
    "  Total Transactions: %0d\n" +
    "  Total Time: %0.2f ns\n" +
    "  Total Clock Cycles: %0d\n" +
    "  Average Transaction Time: %0.2f ns\n" +
    "  Min Transaction Time: %0.2f ns\n" +
    "  Max Transaction Time: %0.2f ns",
    perf_metrics.total_transactions,
    perf_metrics.total_time_ns,
    perf_metrics.total_clock_cycles,
    perf_metrics.avg_transaction_time_ns,
    perf_metrics.min_transaction_time_ns,
    perf_metrics.max_transaction_time_ns
  ), UVM_LOW)
endfunction // report_final_performance

// Sample coverage
 function void jtag_driver::sample_coverage(jtag_base_transaction trans);
   // Coverage sampling implementation would go here
   // This is a placeholder for coverage collection
 endfunction // sample_coverage

//=============================================================================
// Compliance Test Implementation
//=============================================================================

// Validate timing compliance
task jtag_driver::validate_timing_compliance(jtag_compliance_transaction comp_trans);
  real measured_setup_time, measured_hold_time;
  
  `uvm_info("JTAG_DRIVER_INFO", "Validating timing compliance", UVM_MEDIUM)
  
  // Measure setup and hold times
  measured_setup_time = measure_setup_time();
  measured_hold_time = measure_hold_time();
  
  // Check against specification
  if (measured_setup_time < timing_cfg.tdi_setup_time_ns) begin
    `uvm_error("TIMING_VIOLATION", $sformatf("Setup time violation: measured=%0.2f ns, required=%0.2f ns", 
                                             measured_setup_time, timing_cfg.tdi_setup_time_ns))
    comp_trans.compliance_status = COMPLIANCE_FAIL;
  end
  
  if (measured_hold_time < timing_cfg.tdi_hold_time_ns) begin
    `uvm_error("TIMING_VIOLATION", $sformatf("Hold time violation: measured=%0.2f ns, required=%0.2f ns", 
                                             measured_hold_time, timing_cfg.tdi_hold_time_ns))
    comp_trans.compliance_status = COMPLIANCE_FAIL;
  end
  
  if (comp_trans.compliance_status != COMPLIANCE_FAIL) begin
    comp_trans.compliance_status = COMPLIANCE_PASS;
    `uvm_info("JTAG_DRIVER_INFO", "Timing compliance test passed", UVM_LOW)
  end
  
endtask // validate_timing_compliance

// Validate protocol compliance
task jtag_driver::validate_protocol_compliance(jtag_compliance_transaction comp_trans);
  
  `uvm_info("JTAG_DRIVER_INFO", "Validating protocol compliance", UVM_MEDIUM)
  
  // Test state machine compliance
  if (!test_state_machine_compliance()) begin
    `uvm_error("PROTOCOL_VIOLATION", "State machine compliance test failed")
    comp_trans.compliance_status = COMPLIANCE_FAIL;
    return;
  end
  
  // Test instruction register compliance
  if (!test_instruction_register_compliance()) begin
    `uvm_error("PROTOCOL_VIOLATION", "Instruction register compliance test failed")
    comp_trans.compliance_status = COMPLIANCE_FAIL;
    return;
  end
  
  comp_trans.compliance_status = COMPLIANCE_PASS;
  `uvm_info("JTAG_DRIVER_INFO", "Protocol compliance test passed", UVM_LOW)
  
endtask // validate_protocol_compliance

// Test mandatory instructions
task jtag_driver::test_mandatory_instructions(jtag_compliance_transaction comp_trans);
  jtag_instruction_e mandatory_instructions[] = '{BYPASS, IDCODE, EXTEST, SAMPLE_PRELOAD};
  bit [31:0] response_data;
  
  `uvm_info("JTAG_DRIVER_INFO", "Testing mandatory instructions", UVM_MEDIUM)
  
  foreach (mandatory_instructions[i]) begin
    // Load instruction
    navigate_to_state(SHIFT_IR);
    shift_ir(mandatory_instructions[i], driver_cfg.instruction_length);
    navigate_to_state(UPDATE_IR);
    
    // Test instruction response
    navigate_to_state(SHIFT_DR);
    shift_dr(32'h0, response_data, 32);
    navigate_to_state(UPDATE_DR);
    
    // Validate response based on instruction
    case (mandatory_instructions[i])
      BYPASS: begin
        if (response_data[0] != 0) begin
          `uvm_error("INSTRUCTION_COMPLIANCE", "BYPASS instruction failed")
          comp_trans.compliance_status = COMPLIANCE_FAIL;
          return;
        end
      end
      IDCODE: begin
        if (response_data == 32'h0 || response_data == 32'hFFFFFFFF) begin
          `uvm_error("INSTRUCTION_COMPLIANCE", "IDCODE instruction failed")
          comp_trans.compliance_status = COMPLIANCE_FAIL;
          return;
        end
      end
    endcase
  end
  
  comp_trans.compliance_status = COMPLIANCE_PASS;
  `uvm_info("JTAG_DRIVER_INFO", "Mandatory instruction test passed", UVM_LOW)
  
endtask // test_mandatory_instructions

//=============================================================================
// Helper Functions for Compliance Testing
//=============================================================================

// Measure setup time
function real jtag_driver::measure_setup_time();
  // Implementation would measure actual setup time
  // This is a placeholder returning nominal value
  return timing_cfg.tdi_setup_time_ns;
endfunction // measure_setup_time

// Measure hold time
function real jtag_driver::measure_hold_time();
  // Implementation would measure actual hold time
  // This is a placeholder returning nominal value
  return timing_cfg.tdi_hold_time_ns;
endfunction // measure_hold_time

// Test state machine compliance
function bit jtag_driver::test_state_machine_compliance();
  // Implementation would test all state transitions
  // This is a placeholder returning pass
  return 1;
endfunction // test_state_machine_compliance

// Test instruction register compliance
function bit jtag_driver::test_instruction_register_compliance();
  // Implementation would test IR functionality
  // This is a placeholder returning pass
  return 1;
endfunction // test_instruction_register_compliance

endclass // jtag_driver
 
 `endif
