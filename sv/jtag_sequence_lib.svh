`ifndef JTAG_SEQUENCE_LIB__SVH
 `define JTAG_SEQUENCE_LIB__SVH

//=============================================================================
// Enhanced JTAG VIP Sequence Library
// Comprehensive sequence library for advanced JTAG verification
//=============================================================================

//-----------------------------------------------------------------------------
// Base Enhanced JTAG Sequence
// Foundation class for all enhanced JTAG sequences
//-----------------------------------------------------------------------------
class jtag_base_sequence extends uvm_sequence #(jtag_base_transaction, jtag_base_transaction);
  
  // Configuration objects
  jtag_driver_config driver_cfg;
  jtag_timing_config timing_cfg;
  jtag_protocol_config protocol_cfg;
  jtag_error_config error_cfg;
  
  // Sequence control
  rand int num_transactions;
  rand bit enable_error_injection;
  rand bit enable_timing_variation;
  
  // Constraints
  constraint reasonable_transactions {
    num_transactions inside {[1:50]};
  }
  
  `uvm_object_utils_begin(jtag_base_sequence)
    `uvm_field_object(driver_cfg, UVM_ALL_ON)
    `uvm_field_object(timing_cfg, UVM_ALL_ON)
    `uvm_field_object(protocol_cfg, UVM_ALL_ON)
    `uvm_field_object(error_cfg, UVM_ALL_ON)
    `uvm_field_int(num_transactions, UVM_ALL_ON)
    `uvm_field_int(enable_error_injection, UVM_ALL_ON)
    `uvm_field_int(enable_timing_variation, UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "jtag_base_sequence");
    super.new(name);
    num_transactions = 10;
    enable_error_injection = 0;
    enable_timing_variation = 0;
  endfunction // new
  
  // Pre-body configuration retrieval
  virtual task pre_body();
    super.pre_body();
    
    // Get configuration objects
    if(!uvm_config_db#(jtag_driver_config)::get(null, "", "driver_cfg", driver_cfg)) begin
      `uvm_info("JTAG_SEQ", "Using default driver configuration", UVM_LOW)
      driver_cfg = jtag_driver_config::type_id::create("driver_cfg");
    end
    
    if(!uvm_config_db#(jtag_timing_config)::get(null, "", "timing_cfg", timing_cfg)) begin
      `uvm_info("JTAG_SEQ", "Using default timing configuration", UVM_LOW)
      timing_cfg = jtag_timing_config::type_id::create("timing_cfg");
    end
    
    if(!uvm_config_db#(jtag_protocol_config)::get(null, "", "protocol_cfg", protocol_cfg)) begin
      `uvm_info("JTAG_SEQ", "Using default protocol configuration", UVM_LOW)
      protocol_cfg = jtag_protocol_config::type_id::create("protocol_cfg");
    end
    
    if(!uvm_config_db#(jtag_error_config)::get(null, "", "error_cfg", error_cfg)) begin
      `uvm_info("JTAG_SEQ", "Using default error configuration", UVM_LOW)
      error_cfg = jtag_error_config::type_id::create("error_cfg");
    end
    
  endtask // pre_body
  
  // Utility function to create and configure transaction
  virtual function jtag_base_transaction create_transaction(jtag_transaction_type_e trans_type);
    jtag_base_transaction trans;
    trans = jtag_base_transaction::type_id::create("trans");
    trans.transaction_type = trans_type;
    trans.transaction_id = $urandom();
    trans.timestamp = $realtime();
    return trans;
  endfunction // create_transaction
  
endclass // jtag_base_sequence

//-----------------------------------------------------------------------------
// Simple JTAG Sequence
// Basic sequence for simple JTAG operations
//-----------------------------------------------------------------------------
class jtag_simple_sequence extends jtag_base_sequence;
  
  `uvm_object_utils(jtag_simple_sequence)

  function new (string name = "jtag_simple_sequence");
    super.new(name);
  endfunction // new
  
  virtual task body();
    jtag_base_transaction trans;
    
    `uvm_info("JTAG_SIMPLE_SEQ", $sformatf("Starting simple sequence with %0d transactions", num_transactions), UVM_LOW)
    
    repeat(num_transactions) begin
      // Create instruction transaction
      trans = create_transaction(JTAG_INSTRUCTION);
      trans.instruction = IDCODE;
      trans.data_length = 32;
      
      start_item(trans);
      if (!trans.randomize() with {
        trans.instruction == IDCODE;
        trans.data_length == 32;
      }) begin
        `uvm_fatal("JTAG_SIMPLE_SEQ", "Failed to randomize transaction")
      end
      finish_item(trans);
      get_response(rsp);
      
      `uvm_info("JTAG_SIMPLE_SEQ", $sformatf("Transaction completed: ID=0x%0h", trans.transaction_id), UVM_MEDIUM)
    end
    
  endtask // body
  
endclass // jtag_simple_sequence

//-----------------------------------------------------------------------------
// Boundary Scan Test Sequences
// Comprehensive boundary scan testing capabilities
//-----------------------------------------------------------------------------

// EXTEST Sequence - External test of board-level interconnects
class jtag_boundary_scan_extest_sequence extends jtag_base_sequence;
  
  rand bit [31:0] test_pattern [];
  rand int pattern_count;
  
  constraint reasonable_patterns {
    pattern_count inside {[1:10]};
    test_pattern.size() == pattern_count;
  }
  
  `uvm_object_utils_begin(jtag_boundary_scan_extest_sequence)
    `uvm_field_array_int(test_pattern, UVM_ALL_ON)
    `uvm_field_int(pattern_count, UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "jtag_boundary_scan_extest_sequence");
    super.new(name);
    pattern_count = 4;
  endfunction // new
  
  virtual task body();
    jtag_base_transaction trans;
    
    `uvm_info("JTAG_EXTEST_SEQ", "Starting EXTEST boundary scan sequence", UVM_LOW)
    
    // Step 1: Load EXTEST instruction
    trans = create_transaction(JTAG_BOUNDARY_SCAN);
    trans.boundary_scan_type = EXTEST;
    trans.instruction = EXTEST;
    
    start_item(trans);
    if (!trans.randomize() with {
      trans.boundary_scan_type == EXTEST;
      trans.instruction == EXTEST;
    }) begin
      `uvm_fatal("JTAG_EXTEST_SEQ", "Failed to randomize EXTEST instruction")
    end
    finish_item(trans);
    get_response(rsp);
    
    // Step 2: Apply test patterns
    foreach(test_pattern[i]) begin
      trans = create_transaction(JTAG_BOUNDARY_SCAN);
      trans.boundary_scan_type = EXTEST;
      trans.data_out = test_pattern[i];
      trans.data_length = 32;
      
      start_item(trans);
      if (!trans.randomize() with {
        trans.boundary_scan_type == EXTEST;
        trans.data_out == test_pattern[i];
        trans.data_length == 32;
      }) begin
        `uvm_fatal("JTAG_EXTEST_SEQ", "Failed to randomize EXTEST data")
      end
      finish_item(trans);
      get_response(rsp);
      
      `uvm_info("JTAG_EXTEST_SEQ", $sformatf("Applied pattern[%0d]: 0x%0h, captured: 0x%0h", 
                i, test_pattern[i], rsp.data_in), UVM_MEDIUM)
    end
    
    `uvm_info("JTAG_EXTEST_SEQ", "EXTEST sequence completed", UVM_LOW)
    
  endtask // body
  
endclass // jtag_boundary_scan_extest_sequence

// INTEST Sequence - Internal test of device logic
class jtag_boundary_scan_intest_sequence extends jtag_base_sequence;
  
  rand bit [31:0] stimulus_data [];
  rand bit [31:0] expected_data [];
  rand int test_cycles;
  
  constraint reasonable_test_cycles {
    test_cycles inside {[1:20]};
    stimulus_data.size() == test_cycles;
    expected_data.size() == test_cycles;
  }
  
  `uvm_object_utils_begin(jtag_boundary_scan_intest_sequence)
    `uvm_field_array_int(stimulus_data, UVM_ALL_ON)
    `uvm_field_array_int(expected_data, UVM_ALL_ON)
    `uvm_field_int(test_cycles, UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "jtag_boundary_scan_intest_sequence");
    super.new(name);
    test_cycles = 5;
  endfunction // new
  
  virtual task body();
    jtag_base_transaction trans;
    
    `uvm_info("JTAG_INTEST_SEQ", "Starting INTEST boundary scan sequence", UVM_LOW)
    
    // Step 1: Load INTEST instruction
    trans = create_transaction(JTAG_BOUNDARY_SCAN);
    trans.boundary_scan_type = INTEST;
    trans.instruction = INTEST;
    
    start_item(trans);
    if (!trans.randomize() with {
      trans.boundary_scan_type == INTEST;
      trans.instruction == INTEST;
    }) begin
      `uvm_fatal("JTAG_INTEST_SEQ", "Failed to randomize INTEST instruction")
    end
    finish_item(trans);
    get_response(rsp);
    
    // Step 2: Apply stimulus and check response
    foreach(stimulus_data[i]) begin
      trans = create_transaction(JTAG_BOUNDARY_SCAN);
      trans.boundary_scan_type = INTEST;
      trans.data_out = stimulus_data[i];
      trans.data_length = 32;
      
      start_item(trans);
      if (!trans.randomize() with {
        trans.boundary_scan_type == INTEST;
        trans.data_out == stimulus_data[i];
        trans.data_length == 32;
      }) begin
        `uvm_fatal("JTAG_INTEST_SEQ", "Failed to randomize INTEST data")
      end
      finish_item(trans);
      get_response(rsp);
      
      // Check response against expected data
      if (rsp.data_in !== expected_data[i]) begin
        `uvm_error("JTAG_INTEST_SEQ", $sformatf("Data mismatch at cycle %0d: expected=0x%0h, actual=0x%0h", 
                   i, expected_data[i], rsp.data_in))
      end else begin
        `uvm_info("JTAG_INTEST_SEQ", $sformatf("Cycle[%0d] passed: stimulus=0x%0h, response=0x%0h", 
                  i, stimulus_data[i], rsp.data_in), UVM_MEDIUM)
      end
    end
    
    `uvm_info("JTAG_INTEST_SEQ", "INTEST sequence completed", UVM_LOW)
    
  endtask // body
  
endclass // jtag_boundary_scan_intest_sequence

// SAMPLE/PRELOAD Sequence - Sample inputs and preload outputs
class jtag_boundary_scan_sample_preload_sequence extends jtag_base_sequence;
  
  rand bit [31:0] preload_data [];
  rand int sample_cycles;
  
  constraint reasonable_sample_cycles {
    sample_cycles inside {[1:15]};
    preload_data.size() == sample_cycles;
  }
  
  `uvm_object_utils_begin(jtag_boundary_scan_sample_preload_sequence)
    `uvm_field_array_int(preload_data, UVM_ALL_ON)
    `uvm_field_int(sample_cycles, UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "jtag_boundary_scan_sample_preload_sequence");
    super.new(name);
    sample_cycles = 3;
  endfunction // new
  
  virtual task body();
    jtag_base_transaction trans;
    
    `uvm_info("JTAG_SAMPLE_PRELOAD_SEQ", "Starting SAMPLE/PRELOAD boundary scan sequence", UVM_LOW)
    
    // Step 1: Load SAMPLE/PRELOAD instruction
    trans = create_transaction(JTAG_BOUNDARY_SCAN);
    trans.boundary_scan_type = SAMPLE_PRELOAD;
    trans.instruction = SAMPLE_PRELOAD;
    
    start_item(trans);
    if (!trans.randomize() with {
      trans.boundary_scan_type == SAMPLE_PRELOAD;
      trans.instruction == SAMPLE_PRELOAD;
    }) begin
      `uvm_fatal("JTAG_SAMPLE_PRELOAD_SEQ", "Failed to randomize SAMPLE/PRELOAD instruction")
    end
    finish_item(trans);
    get_response(rsp);
    
    // Step 2: Perform sample and preload operations
    foreach(preload_data[i]) begin
      trans = create_transaction(JTAG_BOUNDARY_SCAN);
      trans.boundary_scan_type = SAMPLE_PRELOAD;
      trans.data_out = preload_data[i];
      trans.data_length = 32;
      
      start_item(trans);
      if (!trans.randomize() with {
        trans.boundary_scan_type == SAMPLE_PRELOAD;
        trans.data_out == preload_data[i];
        trans.data_length == 32;
      }) begin
        `uvm_fatal("JTAG_SAMPLE_PRELOAD_SEQ", "Failed to randomize SAMPLE/PRELOAD data")
      end
      finish_item(trans);
      get_response(rsp);
      
      `uvm_info("JTAG_SAMPLE_PRELOAD_SEQ", $sformatf("Cycle[%0d] preload=0x%0h, sampled=0x%0h", 
                i, preload_data[i], rsp.data_in), UVM_MEDIUM)
    end
    
    `uvm_info("JTAG_SAMPLE_PRELOAD_SEQ", "SAMPLE/PRELOAD sequence completed", UVM_LOW)
    
  endtask // body
  
endclass // jtag_boundary_scan_sample_preload_sequence

//-----------------------------------------------------------------------------
// Debug Access Sequences
// Advanced debug and test access capabilities
//-----------------------------------------------------------------------------

// Debug Register Access Sequence
class jtag_debug_register_access_sequence extends jtag_base_sequence;
  
  rand bit [31:0] register_addresses [];
  rand bit [31:0] write_data [];
  rand bit [31:0] expected_data [];
  rand bit read_write_mode [];  // 0=read, 1=write
  rand int access_count;
  
  constraint reasonable_accesses {
    access_count inside {[1:20]};
    register_addresses.size() == access_count;
    write_data.size() == access_count;
    expected_data.size() == access_count;
    read_write_mode.size() == access_count;
  }
  
  `uvm_object_utils_begin(jtag_debug_register_access_sequence)
    `uvm_field_array_int(register_addresses, UVM_ALL_ON)
    `uvm_field_array_int(write_data, UVM_ALL_ON)
    `uvm_field_array_int(expected_data, UVM_ALL_ON)
    `uvm_field_array_int(read_write_mode, UVM_ALL_ON)
    `uvm_field_int(access_count, UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "jtag_debug_register_access_sequence");
    super.new(name);
    access_count = 5;
  endfunction // new
  
  virtual task body();
    jtag_base_transaction trans;
    
    `uvm_info("JTAG_DEBUG_REG_SEQ", "Starting debug register access sequence", UVM_LOW)
    
    // Step 1: Enter debug mode
    trans = create_transaction(JTAG_DEBUG);
    trans.debug_operation = DEBUG_ENTER;
    
    start_item(trans);
    if (!trans.randomize() with {
      trans.debug_operation == DEBUG_ENTER;
    }) begin
      `uvm_fatal("JTAG_DEBUG_REG_SEQ", "Failed to randomize debug enter")
    end
    finish_item(trans);
    get_response(rsp);
    
    // Step 2: Perform register accesses
    foreach(register_addresses[i]) begin
      trans = create_transaction(JTAG_DEBUG);
      trans.debug_operation = read_write_mode[i] ? DEBUG_WRITE_REG : DEBUG_READ_REG;
      trans.address = register_addresses[i];
      if (read_write_mode[i]) trans.data_out = write_data[i];
      trans.data_length = 32;
      
      start_item(trans);
      if (!trans.randomize() with {
        trans.debug_operation == (read_write_mode[i] ? DEBUG_WRITE_REG : DEBUG_READ_REG);
        trans.address == register_addresses[i];
        if (read_write_mode[i]) trans.data_out == write_data[i];
        trans.data_length == 32;
      }) begin
        `uvm_fatal("JTAG_DEBUG_REG_SEQ", "Failed to randomize debug register access")
      end
      finish_item(trans);
      get_response(rsp);
      
      if (read_write_mode[i]) begin
        `uvm_info("JTAG_DEBUG_REG_SEQ", $sformatf("Write reg[0x%0h] = 0x%0h", 
                  register_addresses[i], write_data[i]), UVM_MEDIUM)
      end else begin
        `uvm_info("JTAG_DEBUG_REG_SEQ", $sformatf("Read reg[0x%0h] = 0x%0h", 
                  register_addresses[i], rsp.data_in), UVM_MEDIUM)
        if (rsp.data_in !== expected_data[i]) begin
          `uvm_error("JTAG_DEBUG_REG_SEQ", $sformatf("Register read mismatch at 0x%0h: expected=0x%0h, actual=0x%0h", 
                     register_addresses[i], expected_data[i], rsp.data_in))
        end
      end
    end
    
    // Step 3: Exit debug mode
    trans = create_transaction(JTAG_DEBUG);
    trans.debug_operation = DEBUG_EXIT;
    
    start_item(trans);
    if (!trans.randomize() with {
      trans.debug_operation == DEBUG_EXIT;
    }) begin
      `uvm_fatal("JTAG_DEBUG_REG_SEQ", "Failed to randomize debug exit")
    end
    finish_item(trans);
    get_response(rsp);
    
    `uvm_info("JTAG_DEBUG_REG_SEQ", "Debug register access sequence completed", UVM_LOW)
    
  endtask // body
  
endclass // jtag_debug_register_access_sequence

// Debug Memory Access Sequence
class jtag_debug_memory_access_sequence extends jtag_base_sequence;
  
  rand bit [31:0] memory_addresses [];
  rand bit [31:0] write_data [];
  rand bit [31:0] expected_data [];
  rand bit read_write_mode [];  // 0=read, 1=write
  rand int burst_length [];
  rand int access_count;
  
  constraint reasonable_memory_accesses {
    access_count inside {[1:10]};
    memory_addresses.size() == access_count;
    write_data.size() == access_count;
    expected_data.size() == access_count;
    read_write_mode.size() == access_count;
    burst_length.size() == access_count;
    foreach(burst_length[i]) burst_length[i] inside {[1:8]};
  }
  
  `uvm_object_utils_begin(jtag_debug_memory_access_sequence)
    `uvm_field_array_int(memory_addresses, UVM_ALL_ON)
    `uvm_field_array_int(write_data, UVM_ALL_ON)
    `uvm_field_array_int(expected_data, UVM_ALL_ON)
    `uvm_field_array_int(read_write_mode, UVM_ALL_ON)
    `uvm_field_array_int(burst_length, UVM_ALL_ON)
    `uvm_field_int(access_count, UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "jtag_debug_memory_access_sequence");
    super.new(name);
    access_count = 3;
  endfunction // new
  
  virtual task body();
    jtag_base_transaction trans;
    
    `uvm_info("JTAG_DEBUG_MEM_SEQ", "Starting debug memory access sequence", UVM_LOW)
    
    // Step 1: Enter debug mode
    trans = create_transaction(JTAG_DEBUG);
    trans.debug_operation = DEBUG_ENTER;
    
    start_item(trans);
    if (!trans.randomize() with {
      trans.debug_operation == DEBUG_ENTER;
    }) begin
      `uvm_fatal("JTAG_DEBUG_MEM_SEQ", "Failed to randomize debug enter")
    end
    finish_item(trans);
    get_response(rsp);
    
    // Step 2: Perform memory accesses
    foreach(memory_addresses[i]) begin
      trans = create_transaction(JTAG_DEBUG);
      trans.debug_operation = read_write_mode[i] ? DEBUG_WRITE_MEM : DEBUG_READ_MEM;
      trans.address = memory_addresses[i];
      if (read_write_mode[i]) trans.data_out = write_data[i];
      trans.data_length = burst_length[i] * 32;
      trans.burst_length = burst_length[i];
      
      start_item(trans);
      if (!trans.randomize() with {
        trans.debug_operation == (read_write_mode[i] ? DEBUG_WRITE_MEM : DEBUG_READ_MEM);
        trans.address == memory_addresses[i];
        if (read_write_mode[i]) trans.data_out == write_data[i];
        trans.data_length == burst_length[i] * 32;
        trans.burst_length == burst_length[i];
      }) begin
        `uvm_fatal("JTAG_DEBUG_MEM_SEQ", "Failed to randomize debug memory access")
      end
      finish_item(trans);
      get_response(rsp);
      
      if (read_write_mode[i]) begin
        `uvm_info("JTAG_DEBUG_MEM_SEQ", $sformatf("Write mem[0x%0h] = 0x%0h (burst=%0d)", 
                  memory_addresses[i], write_data[i], burst_length[i]), UVM_MEDIUM)
      end else begin
        `uvm_info("JTAG_DEBUG_MEM_SEQ", $sformatf("Read mem[0x%0h] = 0x%0h (burst=%0d)", 
                  memory_addresses[i], rsp.data_in, burst_length[i]), UVM_MEDIUM)
        if (rsp.data_in !== expected_data[i]) begin
          `uvm_error("JTAG_DEBUG_MEM_SEQ", $sformatf("Memory read mismatch at 0x%0h: expected=0x%0h, actual=0x%0h", 
                     memory_addresses[i], expected_data[i], rsp.data_in))
        end
      end
    end
    
    // Step 3: Exit debug mode
    trans = create_transaction(JTAG_DEBUG);
    trans.debug_operation = DEBUG_EXIT;
    
    start_item(trans);
    if (!trans.randomize() with {
      trans.debug_operation == DEBUG_EXIT;
    }) begin
      `uvm_fatal("JTAG_DEBUG_MEM_SEQ", "Failed to randomize debug exit")
    end
    finish_item(trans);
    get_response(rsp);
    
    `uvm_info("JTAG_DEBUG_MEM_SEQ", "Debug memory access sequence completed", UVM_LOW)
    
  endtask // body
  
endclass // jtag_debug_memory_access_sequence

//-----------------------------------------------------------------------------
// Error Injection Sequences
// Systematic error testing and fault injection
//-----------------------------------------------------------------------------

// Timing Error Injection Sequence
class jtag_error_injection_timing_sequence extends jtag_base_sequence;
  
  rand jtag_error_type_e error_types [];
  rand real timing_violations [];
  rand int error_count;
  
  constraint reasonable_errors {
    error_count inside {[1:10]};
    error_types.size() == error_count;
    timing_violations.size() == error_count;
    foreach(timing_violations[i]) timing_violations[i] inside {[0.1:5.0]};
  }
  
  `uvm_object_utils_begin(jtag_error_injection_timing_sequence)
    `uvm_field_array_enum(jtag_error_type_e, error_types, UVM_ALL_ON)
    `uvm_field_array_real(timing_violations, UVM_ALL_ON)
    `uvm_field_int(error_count, UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "jtag_error_injection_timing_sequence");
    super.new(name);
    error_count = 3;
    enable_error_injection = 1;
  endfunction // new
  
  virtual task body();
    jtag_base_transaction trans;
    
    `uvm_info("JTAG_ERROR_TIMING_SEQ", "Starting timing error injection sequence", UVM_LOW)
    
    foreach(error_types[i]) begin
      trans = create_transaction(JTAG_INSTRUCTION);
      trans.instruction = IDCODE;
      trans.data_length = 32;
      trans.enable_error_injection = 1;
      trans.error_type = error_types[i];
      trans.timing_violation_amount = timing_violations[i];
      
      start_item(trans);
      if (!trans.randomize() with {
        trans.instruction == IDCODE;
        trans.data_length == 32;
        trans.enable_error_injection == 1;
        trans.error_type == error_types[i];
        trans.timing_violation_amount == timing_violations[i];
      }) begin
        `uvm_fatal("JTAG_ERROR_TIMING_SEQ", "Failed to randomize error injection transaction")
      end
      finish_item(trans);
      get_response(rsp);
      
      `uvm_info("JTAG_ERROR_TIMING_SEQ", $sformatf("Injected %s error with %0.2f violation", 
                error_types[i].name(), timing_violations[i]), UVM_MEDIUM)
    end
    
    `uvm_info("JTAG_ERROR_TIMING_SEQ", "Timing error injection sequence completed", UVM_LOW)
    
  endtask // body
  
endclass // jtag_error_injection_timing_sequence

// Protocol Error Injection Sequence
class jtag_error_injection_protocol_sequence extends jtag_base_sequence;
  
  rand jtag_error_type_e protocol_errors [];
  rand int error_positions [];
  rand int error_count;
  
  constraint reasonable_protocol_errors {
    error_count inside {[1:8]};
    protocol_errors.size() == error_count;
    error_positions.size() == error_count;
    foreach(error_positions[i]) error_positions[i] inside {[0:31]};
  }
  
  `uvm_object_utils_begin(jtag_error_injection_protocol_sequence)
    `uvm_field_array_enum(jtag_error_type_e, protocol_errors, UVM_ALL_ON)
    `uvm_field_array_int(error_positions, UVM_ALL_ON)
    `uvm_field_int(error_count, UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "jtag_error_injection_protocol_sequence");
    super.new(name);
    error_count = 4;
    enable_error_injection = 1;
  endfunction // new
  
  virtual task body();
    jtag_base_transaction trans;
    
    `uvm_info("JTAG_ERROR_PROTOCOL_SEQ", "Starting protocol error injection sequence", UVM_LOW)
    
    foreach(protocol_errors[i]) begin
      trans = create_transaction(JTAG_DATA);
      trans.data_out = $urandom();
      trans.data_length = 32;
      trans.enable_error_injection = 1;
      trans.error_type = protocol_errors[i];
      trans.error_position = error_positions[i];
      
      start_item(trans);
      if (!trans.randomize() with {
        trans.data_length == 32;
        trans.enable_error_injection == 1;
        trans.error_type == protocol_errors[i];
        trans.error_position == error_positions[i];
      }) begin
        `uvm_fatal("JTAG_ERROR_PROTOCOL_SEQ", "Failed to randomize protocol error transaction")
      end
      finish_item(trans);
      get_response(rsp);
      
      `uvm_info("JTAG_ERROR_PROTOCOL_SEQ", $sformatf("Injected %s error at position %0d", 
                protocol_errors[i].name(), error_positions[i]), UVM_MEDIUM)
    end
    
    `uvm_info("JTAG_ERROR_PROTOCOL_SEQ", "Protocol error injection sequence completed", UVM_LOW)
    
  endtask // body
  
endclass // jtag_error_injection_protocol_sequence

//-----------------------------------------------------------------------------
// Compliance Test Sequences
// IEEE 1149.1/1149.4/1149.6 standard compliance testing
//-----------------------------------------------------------------------------

// IEEE 1149.1 Compliance Test Sequence
class jtag_compliance_ieee1149_1_sequence extends jtag_base_sequence;
  
  rand bit test_mandatory_instructions;
  rand bit test_state_machine;
  rand bit test_timing_requirements;
  rand bit test_instruction_register;
  
  `uvm_object_utils_begin(jtag_compliance_ieee1149_1_sequence)
    `uvm_field_int(test_mandatory_instructions, UVM_ALL_ON)
    `uvm_field_int(test_state_machine, UVM_ALL_ON)
    `uvm_field_int(test_timing_requirements, UVM_ALL_ON)
    `uvm_field_int(test_instruction_register, UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "jtag_compliance_ieee1149_1_sequence");
    super.new(name);
    test_mandatory_instructions = 1;
    test_state_machine = 1;
    test_timing_requirements = 1;
    test_instruction_register = 1;
  endfunction // new
  
  virtual task body();
    jtag_base_transaction trans;
    
    `uvm_info("JTAG_IEEE1149_1_SEQ", "Starting IEEE 1149.1 compliance test sequence", UVM_LOW)
    
    // Test 1: Mandatory Instructions
    if (test_mandatory_instructions) begin
      test_mandatory_instruction_compliance();
    end
    
    // Test 2: TAP State Machine
    if (test_state_machine) begin
      test_tap_state_machine_compliance();
    end
    
    // Test 3: Timing Requirements
    if (test_timing_requirements) begin
      test_timing_compliance();
    end
    
    // Test 4: Instruction Register
    if (test_instruction_register) begin
      test_instruction_register_compliance();
    end
    
    `uvm_info("JTAG_IEEE1149_1_SEQ", "IEEE 1149.1 compliance test sequence completed", UVM_LOW)
    
  endtask // body
  
  // Test mandatory instructions (BYPASS, EXTEST, SAMPLE/PRELOAD)
  virtual task test_mandatory_instruction_compliance();
    jtag_base_transaction trans;
    jtag_instruction_e mandatory_instructions[] = '{BYPASS, EXTEST, SAMPLE_PRELOAD};
    
    `uvm_info("JTAG_IEEE1149_1_SEQ", "Testing mandatory instruction compliance", UVM_MEDIUM)
    
    foreach(mandatory_instructions[i]) begin
      trans = create_transaction(JTAG_COMPLIANCE);
      trans.compliance_test_type = COMPLIANCE_MANDATORY_INSTRUCTIONS;
      trans.instruction = mandatory_instructions[i];
      
      start_item(trans);
      if (!trans.randomize() with {
        trans.compliance_test_type == COMPLIANCE_MANDATORY_INSTRUCTIONS;
        trans.instruction == mandatory_instructions[i];
      }) begin
        `uvm_fatal("JTAG_IEEE1149_1_SEQ", "Failed to randomize mandatory instruction test")
      end
      finish_item(trans);
      get_response(rsp);
      
      `uvm_info("JTAG_IEEE1149_1_SEQ", $sformatf("Tested mandatory instruction: %s", 
                mandatory_instructions[i].name()), UVM_MEDIUM)
    end
  endtask // test_mandatory_instruction_compliance
  
  // Test TAP state machine transitions
  virtual task test_tap_state_machine_compliance();
    jtag_base_transaction trans;
    
    `uvm_info("JTAG_IEEE1149_1_SEQ", "Testing TAP state machine compliance", UVM_MEDIUM)
    
    trans = create_transaction(JTAG_COMPLIANCE);
    trans.compliance_test_type = COMPLIANCE_STATE_MACHINE;
    
    start_item(trans);
    if (!trans.randomize() with {
      trans.compliance_test_type == COMPLIANCE_STATE_MACHINE;
    }) begin
      `uvm_fatal("JTAG_IEEE1149_1_SEQ", "Failed to randomize state machine test")
    end
    finish_item(trans);
    get_response(rsp);
    
    `uvm_info("JTAG_IEEE1149_1_SEQ", "TAP state machine compliance test completed", UVM_MEDIUM)
  endtask // test_tap_state_machine_compliance
  
  // Test timing requirements
  virtual task test_timing_compliance();
    jtag_base_transaction trans;
    
    `uvm_info("JTAG_IEEE1149_1_SEQ", "Testing timing compliance", UVM_MEDIUM)
    
    trans = create_transaction(JTAG_COMPLIANCE);
    trans.compliance_test_type = COMPLIANCE_TIMING;
    
    start_item(trans);
    if (!trans.randomize() with {
      trans.compliance_test_type == COMPLIANCE_TIMING;
    }) begin
      `uvm_fatal("JTAG_IEEE1149_1_SEQ", "Failed to randomize timing test")
    end
    finish_item(trans);
    get_response(rsp);
    
    `uvm_info("JTAG_IEEE1149_1_SEQ", "Timing compliance test completed", UVM_MEDIUM)
  endtask // test_timing_compliance
  
  // Test instruction register
  virtual task test_instruction_register_compliance();
    jtag_base_transaction trans;
    
    `uvm_info("JTAG_IEEE1149_1_SEQ", "Testing instruction register compliance", UVM_MEDIUM)
    
    trans = create_transaction(JTAG_COMPLIANCE);
    trans.compliance_test_type = COMPLIANCE_INSTRUCTION_REGISTER;
    
    start_item(trans);
    if (!trans.randomize() with {
      trans.compliance_test_type == COMPLIANCE_INSTRUCTION_REGISTER;
    }) begin
      `uvm_fatal("JTAG_IEEE1149_1_SEQ", "Failed to randomize instruction register test")
    end
    finish_item(trans);
    get_response(rsp);
    
    `uvm_info("JTAG_IEEE1149_1_SEQ", "Instruction register compliance test completed", UVM_MEDIUM)
  endtask // test_instruction_register_compliance
  
endclass // jtag_compliance_ieee1149_1_sequence

// IDCODE Test Sequence
class jtag_idcode_test_sequence extends jtag_base_sequence;
  
  rand bit [31:0] expected_idcode;
  rand int read_cycles;
  
  constraint reasonable_reads {
    read_cycles inside {[1:5]};
  }
  
  `uvm_object_utils_begin(jtag_idcode_test_sequence)
    `uvm_field_int(expected_idcode, UVM_ALL_ON)
    `uvm_field_int(read_cycles, UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "jtag_idcode_test_sequence");
    super.new(name);
    read_cycles = 3;
    expected_idcode = 32'h12345678;  // Default expected IDCODE
  endfunction // new
  
  virtual task body();
    jtag_base_transaction trans;
    
    `uvm_info("JTAG_IDCODE_SEQ", "Starting IDCODE test sequence", UVM_LOW)
    
    repeat(read_cycles) begin
      trans = create_transaction(JTAG_IDCODE);
      trans.instruction = IDCODE;
      trans.data_length = 32;
      
      start_item(trans);
      if (!trans.randomize() with {
        trans.instruction == IDCODE;
        trans.data_length == 32;
      }) begin
        `uvm_fatal("JTAG_IDCODE_SEQ", "Failed to randomize IDCODE transaction")
      end
      finish_item(trans);
      get_response(rsp);
      
      // Verify IDCODE
      if (rsp.data_in !== expected_idcode) begin
        `uvm_error("JTAG_IDCODE_SEQ", $sformatf("IDCODE mismatch: expected=0x%0h, actual=0x%0h", 
                   expected_idcode, rsp.data_in))
      end else begin
        `uvm_info("JTAG_IDCODE_SEQ", $sformatf("IDCODE verified: 0x%0h", rsp.data_in), UVM_MEDIUM)
      end
    end
    
    `uvm_info("JTAG_IDCODE_SEQ", "IDCODE test sequence completed", UVM_LOW)
    
  endtask // body
  
endclass // jtag_idcode_test_sequence

// Reset Test Sequence
class jtag_reset_test_sequence extends jtag_base_sequence;
  
  rand jtag_reset_type_e reset_types [];
  rand int reset_count;
  
  constraint reasonable_resets {
    reset_count inside {[1:5]};
    reset_types.size() == reset_count;
  }
  
  `uvm_object_utils_begin(jtag_reset_test_sequence)
    `uvm_field_array_enum(jtag_reset_type_e, reset_types, UVM_ALL_ON)
    `uvm_field_int(reset_count, UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "jtag_reset_test_sequence");
    super.new(name);
    reset_count = 2;
  endfunction // new
  
  virtual task body();
    jtag_base_transaction trans;
    
    `uvm_info("JTAG_RESET_SEQ", "Starting reset test sequence", UVM_LOW)
    
    foreach(reset_types[i]) begin
      trans = create_transaction(JTAG_RESET);
      trans.reset_type = reset_types[i];
      
      start_item(trans);
      if (!trans.randomize() with {
        trans.reset_type == reset_types[i];
      }) begin
        `uvm_fatal("JTAG_RESET_SEQ", "Failed to randomize reset transaction")
      end
      finish_item(trans);
      get_response(rsp);
      
      `uvm_info("JTAG_RESET_SEQ", $sformatf("Applied %s reset", reset_types[i].name()), UVM_MEDIUM)
    end
    
    `uvm_info("JTAG_RESET_SEQ", "Reset test sequence completed", UVM_LOW)
    
  endtask // body
  
endclass // jtag_reset_test_sequence

//-----------------------------------------------------------------------------
// Stress Test Sequences
// High-volume and stress testing scenarios
//-----------------------------------------------------------------------------

// High-Volume Transaction Sequence
class jtag_stress_high_volume_sequence extends jtag_base_sequence;
  
  rand int transaction_count;
  rand jtag_transaction_type_e transaction_types [];
  rand bit enable_random_delays;
  rand int max_delay_cycles;
  
  constraint stress_constraints {
    transaction_count inside {[100:1000]};
    transaction_types.size() inside {[5:10]};
    max_delay_cycles inside {[0:50]};
  }
  
  `uvm_object_utils_begin(jtag_stress_high_volume_sequence)
    `uvm_field_int(transaction_count, UVM_ALL_ON)
    `uvm_field_array_enum(jtag_transaction_type_e, transaction_types, UVM_ALL_ON)
    `uvm_field_int(enable_random_delays, UVM_ALL_ON)
    `uvm_field_int(max_delay_cycles, UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "jtag_stress_high_volume_sequence");
    super.new(name);
    transaction_count = 500;
    enable_random_delays = 1;
    max_delay_cycles = 10;
  endfunction // new
  
  virtual task body();
    jtag_base_transaction trans;
    int delay_cycles;
    
    `uvm_info("JTAG_STRESS_VOLUME_SEQ", $sformatf("Starting high-volume stress test with %0d transactions", transaction_count), UVM_LOW)
    
    repeat(transaction_count) begin
      // Randomly select transaction type
      jtag_transaction_type_e selected_type = transaction_types[$urandom_range(transaction_types.size()-1)];
      
      trans = create_transaction(selected_type);
      
      start_item(trans);
      if (!trans.randomize()) begin
        `uvm_fatal("JTAG_STRESS_VOLUME_SEQ", "Failed to randomize stress transaction")
      end
      finish_item(trans);
      get_response(rsp);
      
      // Add random delays if enabled
      if (enable_random_delays) begin
        delay_cycles = $urandom_range(max_delay_cycles);
        repeat(delay_cycles) @(posedge jtag_vif.tck);
      end
    end
    
    `uvm_info("JTAG_STRESS_VOLUME_SEQ", "High-volume stress test completed", UVM_LOW)
    
  endtask // body
  
endclass // jtag_stress_high_volume_sequence

// Back-to-Back Transaction Sequence
class jtag_stress_back_to_back_sequence extends jtag_base_sequence;
  
  rand int burst_count;
  rand int burst_size;
  rand jtag_instruction_e instructions [];
  
  constraint burst_constraints {
    burst_count inside {[5:20]};
    burst_size inside {[10:50]};
    instructions.size() inside {[3:8]};
  }
  
  `uvm_object_utils_begin(jtag_stress_back_to_back_sequence)
    `uvm_field_int(burst_count, UVM_ALL_ON)
    `uvm_field_int(burst_size, UVM_ALL_ON)
    `uvm_field_array_enum(jtag_instruction_e, instructions, UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "jtag_stress_back_to_back_sequence");
    super.new(name);
    burst_count = 10;
    burst_size = 25;
  endfunction // new
  
  virtual task body();
    jtag_base_transaction trans;
    
    `uvm_info("JTAG_STRESS_B2B_SEQ", $sformatf("Starting back-to-back stress test: %0d bursts of %0d transactions", burst_count, burst_size), UVM_LOW)
    
    repeat(burst_count) begin
      `uvm_info("JTAG_STRESS_B2B_SEQ", $sformatf("Starting burst %0d", burst_count), UVM_MEDIUM)
      
      repeat(burst_size) begin
        // Randomly select instruction
        jtag_instruction_e selected_instr = instructions[$urandom_range(instructions.size()-1)];
        
        trans = create_transaction(JTAG_INSTRUCTION);
        trans.instruction = selected_instr;
        
        start_item(trans);
        if (!trans.randomize() with {
          trans.instruction == selected_instr;
        }) begin
          `uvm_fatal("JTAG_STRESS_B2B_SEQ", "Failed to randomize back-to-back transaction")
        end
        finish_item(trans);
        get_response(rsp);
        
        // No delays between transactions in burst
      end
      
      // Small delay between bursts
      repeat(5) @(posedge jtag_vif.tck);
    end
    
    `uvm_info("JTAG_STRESS_B2B_SEQ", "Back-to-back stress test completed", UVM_LOW)
    
  endtask // body
  
endclass // jtag_stress_back_to_back_sequence

// Random Mixed Operation Sequence
class jtag_stress_random_mixed_sequence extends jtag_base_sequence;
  
  rand int operation_count;
  rand bit enable_error_injection;
  rand bit enable_timing_variations;
  rand bit enable_state_transitions;
  
  constraint mixed_constraints {
    operation_count inside {[50:200]};
  }
  
  `uvm_object_utils_begin(jtag_stress_random_mixed_sequence)
    `uvm_field_int(operation_count, UVM_ALL_ON)
    `uvm_field_int(enable_error_injection, UVM_ALL_ON)
    `uvm_field_int(enable_timing_variations, UVM_ALL_ON)
    `uvm_field_int(enable_state_transitions, UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "jtag_stress_random_mixed_sequence");
    super.new(name);
    operation_count = 100;
    enable_error_injection = 1;
    enable_timing_variations = 1;
    enable_state_transitions = 1;
  endfunction // new
  
  virtual task body();
    jtag_base_transaction trans;
    jtag_transaction_type_e all_types[] = '{JTAG_INSTRUCTION, JTAG_DATA, JTAG_IDCODE, JTAG_BYPASS, JTAG_BOUNDARY_SCAN, JTAG_DEBUG, JTAG_RESET, JTAG_COMPLIANCE};
    
    `uvm_info("JTAG_STRESS_MIXED_SEQ", $sformatf("Starting random mixed stress test with %0d operations", operation_count), UVM_LOW)
    
    repeat(operation_count) begin
      // Randomly select operation type
      jtag_transaction_type_e selected_type = all_types[$urandom_range(all_types.size()-1)];
      
      trans = create_transaction(selected_type);
      
      // Enable random features
      if (enable_error_injection && ($urandom_range(100) < 10)) begin // 10% chance
        trans.enable_error_injection = 1;
        trans.error_type = jtag_error_type_e'($urandom_range(JTAG_ERROR_PROTOCOL_VIOLATION));
      end
      
      if (enable_timing_variations && ($urandom_range(100) < 20)) begin // 20% chance
        trans.enable_timing_variation = 1;
        trans.timing_variation_amount = $urandom_range(1, 5) * 0.1;
      end
      
      start_item(trans);
      if (!trans.randomize()) begin
        `uvm_fatal("JTAG_STRESS_MIXED_SEQ", "Failed to randomize mixed operation transaction")
      end
      finish_item(trans);
      get_response(rsp);
      
      // Random delays
      if ($urandom_range(100) < 30) begin // 30% chance of delay
        repeat($urandom_range(1, 10)) @(posedge jtag_vif.tck);
      end
    end
    
    `uvm_info("JTAG_STRESS_MIXED_SEQ", "Random mixed stress test completed", UVM_LOW)
    
  endtask // body
  
endclass // jtag_stress_random_mixed_sequence

//-----------------------------------------------------------------------------
// Comprehensive Test Sequence
// Master sequence that runs multiple test scenarios
//-----------------------------------------------------------------------------

class jtag_comprehensive_test_sequence extends jtag_base_sequence;
  
  rand bit run_boundary_scan_tests;
  rand bit run_debug_tests;
  rand bit run_error_injection_tests;
  rand bit run_compliance_tests;
  rand bit run_stress_tests;
  rand bit run_idcode_tests;
  rand bit run_reset_tests;
  
  `uvm_object_utils_begin(jtag_comprehensive_test_sequence)
    `uvm_field_int(run_boundary_scan_tests, UVM_ALL_ON)
    `uvm_field_int(run_debug_tests, UVM_ALL_ON)
    `uvm_field_int(run_error_injection_tests, UVM_ALL_ON)
    `uvm_field_int(run_compliance_tests, UVM_ALL_ON)
    `uvm_field_int(run_stress_tests, UVM_ALL_ON)
    `uvm_field_int(run_idcode_tests, UVM_ALL_ON)
    `uvm_field_int(run_reset_tests, UVM_ALL_ON)
  `uvm_object_utils_end

  function new (string name = "jtag_comprehensive_test_sequence");
    super.new(name);
    run_boundary_scan_tests = 1;
    run_debug_tests = 1;
    run_error_injection_tests = 1;
    run_compliance_tests = 1;
    run_stress_tests = 1;
    run_idcode_tests = 1;
    run_reset_tests = 1;
  endfunction // new
  
  virtual task body();
    
    `uvm_info("JTAG_COMPREHENSIVE_SEQ", "Starting comprehensive JTAG test sequence", UVM_LOW)
    
    // Phase 1: Basic functionality tests
    if (run_idcode_tests) begin
      `uvm_info("JTAG_COMPREHENSIVE_SEQ", "Running IDCODE tests", UVM_MEDIUM)
      `uvm_do(jtag_idcode_test_sequence)
    end
    
    if (run_reset_tests) begin
      `uvm_info("JTAG_COMPREHENSIVE_SEQ", "Running reset tests", UVM_MEDIUM)
      `uvm_do(jtag_reset_test_sequence)
    end
    
    // Phase 2: Boundary scan tests
    if (run_boundary_scan_tests) begin
      `uvm_info("JTAG_COMPREHENSIVE_SEQ", "Running boundary scan tests", UVM_MEDIUM)
      `uvm_do(jtag_boundary_scan_extest_sequence)
      `uvm_do(jtag_boundary_scan_intest_sequence)
      `uvm_do(jtag_boundary_scan_sample_preload_sequence)
    end
    
    // Phase 3: Debug tests
    if (run_debug_tests) begin
      `uvm_info("JTAG_COMPREHENSIVE_SEQ", "Running debug tests", UVM_MEDIUM)
      `uvm_do(jtag_debug_register_access_sequence)
      `uvm_do(jtag_debug_memory_access_sequence)
    end
    
    // Phase 4: Error injection tests
    if (run_error_injection_tests) begin
      `uvm_info("JTAG_COMPREHENSIVE_SEQ", "Running error injection tests", UVM_MEDIUM)
      `uvm_do(jtag_error_injection_timing_sequence)
      `uvm_do(jtag_error_injection_protocol_sequence)
    end
    
    // Phase 5: Compliance tests
    if (run_compliance_tests) begin
      `uvm_info("JTAG_COMPREHENSIVE_SEQ", "Running compliance tests", UVM_MEDIUM)
      `uvm_do(jtag_compliance_ieee1149_1_sequence)
    end
    
    // Phase 6: Stress tests
    if (run_stress_tests) begin
      `uvm_info("JTAG_COMPREHENSIVE_SEQ", "Running stress tests", UVM_MEDIUM)
      `uvm_do(jtag_stress_high_volume_sequence)
      `uvm_do(jtag_stress_back_to_back_sequence)
      `uvm_do(jtag_stress_random_mixed_sequence)
    end
    
    `uvm_info("JTAG_COMPREHENSIVE_SEQ", "Comprehensive JTAG test sequence completed", UVM_LOW)
    
  endtask // body
  
endclass // jtag_comprehensive_test_sequence
  
  `endif
