`ifndef JTAG_SEQUENCE_ITEM__SVH
 `define JTAG_SEQUENCE_ITEM__SVH

//=============================================================================
// Enhanced JTAG VIP Sequence Items
// Comprehensive transaction items for advanced JTAG verification
//=============================================================================

//-----------------------------------------------------------------------------
// Base Enhanced JTAG Transaction Class
// Foundation class for all JTAG transactions with advanced features
//-----------------------------------------------------------------------------
class jtag_base_transaction extends uvm_sequence_item;
  // Transaction identification
  rand int transaction_id;
  rand jtag_transaction_type_e transaction_type;
  
  // Timing information
  jtag_timing_info_t timing_info;
  
  // Error injection
  rand bit inject_error;
  rand jtag_error_type_e error_type;
  
  // Performance tracking
  time start_time;
  time end_time;
  
  // Protocol compliance
  rand jtag_standard_e protocol_standard;
  
  constraint transaction_id_c {
    transaction_id inside {[1:1000000]};
  }
  
  constraint error_injection_c {
    inject_error dist {0 := 95, 1 := 5}; // 5% error injection probability
  }
  
  `uvm_object_utils_begin(jtag_base_transaction)
    `uvm_field_int(transaction_id, UVM_ALL_ON)
    `uvm_field_enum(jtag_transaction_type_e, transaction_type, UVM_ALL_ON)
    `uvm_field_int(inject_error, UVM_ALL_ON)
    `uvm_field_enum(jtag_error_type_e, error_type, UVM_ALL_ON)
    `uvm_field_enum(jtag_standard_e, protocol_standard, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_base_transaction");
    super.new(name);
    transaction_type = INSTRUCTION_SCAN;
    protocol_standard = IEEE_1149_1;
    inject_error = 0;
    error_type = NO_ERROR;
  endfunction
  
  // Utility functions
  function time get_duration();
    return (end_time - start_time);
  endfunction
  
  function void start_transaction();
    start_time = $time;
  endfunction
  
  function void end_transaction();
    end_time = $time;
  endfunction
endclass

//-----------------------------------------------------------------------------
// Enhanced JTAG Instruction Transaction
// Advanced instruction register operations with comprehensive features
//-----------------------------------------------------------------------------
class jtag_instruction_transaction extends jtag_base_transaction;
  // Instruction data
  rand jtag_instruction_e instruction;
  rand logic [MAX_INSTRUCTION_WIDTH-1:0] instruction_data;
  rand int instruction_length;
  
  // Advanced instruction features
  rand bit bypass_instruction;           // Use BYPASS instruction
  rand bit custom_instruction;           // Custom instruction mode
  rand logic [MAX_INSTRUCTION_WIDTH-1:0] custom_opcode;
  
  // Instruction validation
  rand bit validate_instruction;         // Validate instruction execution
  rand int expected_ir_length;
  
  constraint instruction_length_c {
    instruction_length inside {[4:MAX_INSTRUCTION_WIDTH]};
  }
  
  constraint instruction_data_c {
    instruction_data < (1 << instruction_length);
  }
  
  constraint custom_instruction_c {
    if (custom_instruction) {
      instruction == CUSTOM_INSTRUCTION;
      custom_opcode < (1 << instruction_length);
    }
  }
  
  `uvm_object_utils_begin(jtag_instruction_transaction)
    `uvm_field_enum(jtag_instruction_e, instruction, UVM_ALL_ON)
    `uvm_field_int(instruction_data, UVM_ALL_ON)
    `uvm_field_int(instruction_length, UVM_ALL_ON)
    `uvm_field_int(bypass_instruction, UVM_ALL_ON)
    `uvm_field_int(custom_instruction, UVM_ALL_ON)
    `uvm_field_int(custom_opcode, UVM_ALL_ON)
    `uvm_field_int(validate_instruction, UVM_ALL_ON)
    `uvm_field_int(expected_ir_length, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_instruction_transaction");
    super.new(name);
    transaction_type = INSTRUCTION_SCAN;
    instruction = IDCODE;
    instruction_length = 8;
    bypass_instruction = 0;
    custom_instruction = 0;
    validate_instruction = 1;
    expected_ir_length = 8;
  endfunction
  
  // Get instruction opcode
  function logic [MAX_INSTRUCTION_WIDTH-1:0] get_opcode();
    if (custom_instruction)
      return custom_opcode;
    else
      return instruction_data;
  endfunction
endclass

//-----------------------------------------------------------------------------
// Enhanced JTAG Data Transaction
// Advanced data register operations with comprehensive features
//-----------------------------------------------------------------------------
class jtag_data_transaction extends jtag_base_transaction;
  // Data payload
  rand logic [MAX_DATA_WIDTH-1:0] data_in;
  logic [MAX_DATA_WIDTH-1:0] data_out;
  rand int data_length;
  
  // Data patterns
  rand data_pattern_e data_pattern;
  rand bit use_custom_pattern;
  rand logic [MAX_DATA_WIDTH-1:0] custom_pattern;
  
  // Data validation
  rand bit validate_data;
  rand logic [MAX_DATA_WIDTH-1:0] expected_data;
  rand bit compare_data;
  
  // Advanced data features
  rand bit shift_only;                   // Shift without capture
  rand bit capture_only;                 // Capture without shift
  rand int shift_count;                  // Number of shifts
  
  constraint data_length_c {
    data_length inside {[1:MAX_DATA_WIDTH]};
  }
  
  constraint data_pattern_c {
    if (use_custom_pattern) {
      data_pattern == PATTERN_CUSTOM;
      data_in == custom_pattern;
    }
  }
  
  constraint shift_count_c {
    shift_count inside {[1:data_length]};
  }
  
  `uvm_object_utils_begin(jtag_data_transaction)
    `uvm_field_int(data_in, UVM_ALL_ON)
    `uvm_field_int(data_out, UVM_ALL_ON)
    `uvm_field_int(data_length, UVM_ALL_ON)
    `uvm_field_enum(data_pattern_e, data_pattern, UVM_ALL_ON)
    `uvm_field_int(use_custom_pattern, UVM_ALL_ON)
    `uvm_field_int(custom_pattern, UVM_ALL_ON)
    `uvm_field_int(validate_data, UVM_ALL_ON)
    `uvm_field_int(expected_data, UVM_ALL_ON)
    `uvm_field_int(compare_data, UVM_ALL_ON)
    `uvm_field_int(shift_only, UVM_ALL_ON)
    `uvm_field_int(capture_only, UVM_ALL_ON)
    `uvm_field_int(shift_count, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_data_transaction");
    super.new(name);
    transaction_type = DATA_SCAN;
    data_length = 32;
    data_pattern = PATTERN_RANDOM;
    use_custom_pattern = 0;
    validate_data = 1;
    compare_data = 1;
    shift_only = 0;
    capture_only = 0;
    shift_count = 1;
  endfunction
  
  // Generate data based on pattern
  function void generate_data_pattern();
    case (data_pattern)
      PATTERN_ALL_ZEROS: data_in = '0;
      PATTERN_ALL_ONES:  data_in = '1;
      PATTERN_WALKING_ONES: data_in = 1 << ($urandom % data_length);
      PATTERN_WALKING_ZEROS: data_in = ~(1 << ($urandom % data_length));
      PATTERN_CHECKERBOARD: data_in = {data_length{2'b10}};
      PATTERN_INVERSE_CHECKERBOARD: data_in = {data_length{2'b01}};
      PATTERN_CUSTOM: data_in = custom_pattern;
      default: data_in = $urandom;
    endcase
  endfunction
endclass

//-----------------------------------------------------------------------------
// Boundary Scan Transaction
// Specialized transaction for boundary scan operations
//-----------------------------------------------------------------------------
class jtag_boundary_scan_transaction extends jtag_base_transaction;
  // Boundary scan data
  rand logic [MAX_BOUNDARY_LENGTH-1:0] boundary_data_in;
  logic [MAX_BOUNDARY_LENGTH-1:0] boundary_data_out;
  rand int boundary_length;
  
  // Boundary scan operations
  rand jtag_boundary_scan_op_e boundary_operation;
  rand bit enable_boundary_scan;
  
  // Pin control
  rand logic [MAX_BOUNDARY_LENGTH-1:0] pin_control;
  rand logic [MAX_BOUNDARY_LENGTH-1:0] pin_direction;
  
  constraint boundary_length_c {
    boundary_length inside {[1:MAX_BOUNDARY_LENGTH]};
  }
  
  `uvm_object_utils_begin(jtag_boundary_scan_transaction)
    `uvm_field_int(boundary_data_in, UVM_ALL_ON)
    `uvm_field_int(boundary_data_out, UVM_ALL_ON)
    `uvm_field_int(boundary_length, UVM_ALL_ON)
    `uvm_field_enum(jtag_boundary_scan_op_e, boundary_operation, UVM_ALL_ON)
    `uvm_field_int(enable_boundary_scan, UVM_ALL_ON)
    `uvm_field_int(pin_control, UVM_ALL_ON)
    `uvm_field_int(pin_direction, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_boundary_scan_transaction");
    super.new(name);
    transaction_type = BOUNDARY_SCAN;
    boundary_length = 256;
    boundary_operation = SAMPLE_PRELOAD;
    enable_boundary_scan = 1;
  endfunction
endclass

//-----------------------------------------------------------------------------
// Debug Access Transaction
// Specialized transaction for debug access operations
//-----------------------------------------------------------------------------
class jtag_debug_transaction extends jtag_base_transaction;
  // Debug operation
  rand jtag_debug_op_e debug_operation;
  rand logic [31:0] debug_address;
  rand logic [31:0] debug_data_in;
  logic [31:0] debug_data_out;
  
  // Debug control
  rand bit enable_debug_mode;
  rand int debug_chain_select;
  rand bit halt_processor;
  
  constraint debug_address_c {
    debug_address inside {[0:32'hFFFFFFFF]};
  }
  
  constraint debug_chain_c {
    debug_chain_select inside {[0:15]};
  }
  
  `uvm_object_utils_begin(jtag_debug_transaction)
    `uvm_field_enum(jtag_debug_op_e, debug_operation, UVM_ALL_ON)
    `uvm_field_int(debug_address, UVM_ALL_ON)
    `uvm_field_int(debug_data_in, UVM_ALL_ON)
    `uvm_field_int(debug_data_out, UVM_ALL_ON)
    `uvm_field_int(enable_debug_mode, UVM_ALL_ON)
    `uvm_field_int(debug_chain_select, UVM_ALL_ON)
    `uvm_field_int(halt_processor, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_debug_transaction");
    super.new(name);
    transaction_type = DEBUG_ACCESS;
    debug_operation = DEBUG_READ_REG;
    enable_debug_mode = 1;
    debug_chain_select = 0;
    halt_processor = 0;
  endfunction
endclass

//-----------------------------------------------------------------------------
// Enhanced JTAG Packet (Backward Compatibility)
// Enhanced version of the original packet with advanced features
//-----------------------------------------------------------------------------
class jtag_send_packet extends jtag_base_transaction;
  rand logic [31:0] instruction;
  rand logic [31:0] data;
  rand int delay;
  
  // Enhanced features
  rand bit enable_timing_control;
  rand real custom_delay_ns;
  rand jtag_delay_type_e delay_type;
  
  constraint instruction_c {
    instruction inside {[0:255]}; // Extended range
  }
  
  constraint data_c {
    data inside {[0:32'hFFFFFFFF]}; // Full 32-bit range
  }
  
  constraint delay_c {
    delay inside {[1:100]}; // Extended delay range
  }
  
  constraint custom_delay_c {
    if (enable_timing_control) {
      custom_delay_ns inside {[1.0:1000.0]};
    }
  }
  
  `uvm_object_utils_begin(jtag_send_packet)
    `uvm_field_int(instruction, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(delay, UVM_ALL_ON)
    `uvm_field_int(enable_timing_control, UVM_ALL_ON)
    `uvm_field_real(custom_delay_ns, UVM_ALL_ON)
    `uvm_field_enum(jtag_delay_type_e, delay_type, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_send_packet");
    super.new(name);
    transaction_type = INSTRUCTION_DATA_SCAN;
    enable_timing_control = 0;
    delay_type = DELAY_FIXED;
  endfunction
endclass

//-----------------------------------------------------------------------------
// Enhanced JTAG Packet (Simple Version)
// Enhanced version with basic advanced features
//-----------------------------------------------------------------------------
class jtag_packet extends jtag_base_transaction;
  rand logic [31:0] instruction;
  rand logic [31:0] data;
  
  // Response data
  logic [31:0] response_data;
  
  // Enhanced validation
  rand bit validate_response;
  rand logic [31:0] expected_response;
  
  constraint instruction_c {
    instruction inside {[0:255]}; // Extended range
  }
  
  constraint data_c {
    data inside {[0:32'hFFFFFFFF]}; // Full 32-bit range
  }
  
  `uvm_object_utils_begin(jtag_packet)
    `uvm_field_int(instruction, UVM_ALL_ON)
    `uvm_field_int(data, UVM_ALL_ON)
    `uvm_field_int(response_data, UVM_ALL_ON)
    `uvm_field_int(validate_response, UVM_ALL_ON)
    `uvm_field_int(expected_response, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_packet");
    super.new(name);
    transaction_type = INSTRUCTION_DATA_SCAN;
    validate_response = 1;
  endfunction
endclass

//-----------------------------------------------------------------------------
// Enhanced IDCODE Transaction
// Advanced IDCODE operations with comprehensive validation
//-----------------------------------------------------------------------------
class jtag_idcode extends jtag_base_transaction;
  rand logic [31:0] idcode;
  
  // IDCODE fields (IEEE 1149.1 standard)
  rand logic [11:0] manufacturer_id;     // Bits [11:1]
  rand logic [15:0] part_number;         // Bits [27:12]
  rand logic [3:0]  version;             // Bits [31:28]
  
  // Validation features
  rand bit validate_idcode_format;
  rand bit check_manufacturer_id;
  rand logic [11:0] expected_manufacturer;
  
  constraint idcode_format_c {
    idcode[0] == 1'b1; // LSB must be 1 for valid IDCODE
    idcode[11:1] == manufacturer_id;
    idcode[27:12] == part_number;
    idcode[31:28] == version;
  }
  
  constraint manufacturer_c {
    manufacturer_id != 12'h000; // Reserved value
    manufacturer_id != 12'h7FF; // Reserved value
  }
  
  `uvm_object_utils_begin(jtag_idcode)
    `uvm_field_int(idcode, UVM_ALL_ON)
    `uvm_field_int(manufacturer_id, UVM_ALL_ON)
    `uvm_field_int(part_number, UVM_ALL_ON)
    `uvm_field_int(version, UVM_ALL_ON)
    `uvm_field_int(validate_idcode_format, UVM_ALL_ON)
    `uvm_field_int(check_manufacturer_id, UVM_ALL_ON)
    `uvm_field_int(expected_manufacturer, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_idcode");
    super.new(name);
    transaction_type = IDCODE_READ;
    validate_idcode_format = 1;
    check_manufacturer_id = 1;
  endfunction
  
  // Utility functions
  function void set_idcode_fields();
    idcode = {version, part_number, manufacturer_id, 1'b1};
  endfunction
  
  function bit is_valid_idcode();
    return (idcode[0] == 1'b1 && 
            idcode[11:1] != 11'h000 && 
            idcode[11:1] != 11'h7FF);
  endfunction
  
  function string get_manufacturer_name();
    // Common manufacturer IDs (partial list)
    case (manufacturer_id)
      11'h049: return "Intel";
      11'h13D: return "Realtek";
      11'h17F: return "National Semiconductor";
      11'h1CF: return "Lattice";
      11'h093: return "Xilinx";
      11'h0E5: return "Altera";
      default: return "Unknown";
    endcase
  endfunction
endclass

//-----------------------------------------------------------------------------
// Reset Transaction
// Specialized transaction for JTAG reset operations
//-----------------------------------------------------------------------------
class jtag_reset_transaction extends jtag_base_transaction;
  rand jtag_reset_type_e reset_type;
  rand int reset_duration_cycles;
  rand bit use_trst;                     // Use TRST pin
  rand bit use_tms_reset;                // Use TMS reset sequence
  
  constraint reset_duration_c {
    reset_duration_cycles inside {[5:1000]};
  }
  
  `uvm_object_utils_begin(jtag_reset_transaction)
    `uvm_field_enum(jtag_reset_type_e, reset_type, UVM_ALL_ON)
    `uvm_field_int(reset_duration_cycles, UVM_ALL_ON)
    `uvm_field_int(use_trst, UVM_ALL_ON)
    `uvm_field_int(use_tms_reset, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_reset_transaction");
    super.new(name);
    transaction_type = TAP_RESET;
    reset_type = SOFT_RESET;
    reset_duration_cycles = 10;
    use_trst = 0;
    use_tms_reset = 1;
  endfunction
endclass

//-----------------------------------------------------------------------------
// Compliance Test Transaction
// Specialized transaction for protocol compliance testing
//-----------------------------------------------------------------------------
class jtag_compliance_transaction extends jtag_base_transaction;
  rand jtag_compliance_test_e compliance_test;
  rand jtag_standard_e target_standard;
  
  // Test parameters
  rand int test_iterations;
  rand bit enable_timing_validation;
  rand bit enable_signal_integrity;
  
  constraint test_iterations_c {
    test_iterations inside {[1:1000]};
  }
  
  `uvm_object_utils_begin(jtag_compliance_transaction)
    `uvm_field_enum(jtag_compliance_test_e, compliance_test, UVM_ALL_ON)
    `uvm_field_enum(jtag_standard_e, target_standard, UVM_ALL_ON)
    `uvm_field_int(test_iterations, UVM_ALL_ON)
    `uvm_field_int(enable_timing_validation, UVM_ALL_ON)
    `uvm_field_int(enable_signal_integrity, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_compliance_transaction");
    super.new(name);
    transaction_type = COMPLIANCE_TEST;
    compliance_test = IEEE_1149_1_BASIC;
    target_standard = IEEE_1149_1;
    test_iterations = 100;
    enable_timing_validation = 1;
    enable_signal_integrity = 1;
  endfunction
endclass

`endif // JTAG_SEQUENCE_ITEM__SVH
