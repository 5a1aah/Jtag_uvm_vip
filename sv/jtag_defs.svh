`ifndef JTAG_DEFS__SVH
 `define JTAG_DEFS__SVH

//=============================================================================
// Enhanced JTAG VIP Definitions
// Comprehensive definitions for advanced JTAG verification capabilities
//=============================================================================

// Maximum data width for enhanced VIP
parameter int MAX_DATA_WIDTH = 1024;
parameter int MAX_INSTRUCTION_WIDTH = 32;
parameter int MAX_BOUNDARY_LENGTH = 2048;
parameter int MAX_CHAIN_LENGTH = 16;

// Enhanced JTAG instruction registers with comprehensive instruction set
typedef enum bit [31:0] {
  // Standard IEEE 1149.1 instructions
  EXTEST      = 32'h00000000,  // External test
  SAMPLE_PREL = 32'h00000001,  // Sample/Preload
  IDCODE      = 32'h00000002,  // ID Code
  BYPASS      = 32'hFFFFFFFF,  // Bypass
  
  // Debug and test instructions
  DEBUG       = 32'h00000008,  // Debug access
  MBIST       = 32'h00000009,  // Memory BIST
  INTEST      = 32'h0000000A,  // Internal test
  RUNBIST     = 32'h0000000B,  // Run BIST
  
  // Advanced instructions for enhanced VIP
  HIGHZ       = 32'h0000000C,  // High impedance
  CLAMP       = 32'h0000000D,  // Clamp
  USERCODE    = 32'h0000000E,  // User code
  
  // Custom instructions for specific testing
  BOUNDARY_SCAN = 32'h00000010,  // Boundary scan test
  CHAIN_TEST    = 32'h00000011,  // Chain connectivity test
  TIMING_TEST   = 32'h00000012,  // Timing validation test
  ERROR_INJECT  = 32'h00000013,  // Error injection test
  
  // IEEE 1149.4 mixed-signal instructions
  ANALOG_TEST   = 32'h00000020,  // Analog test
  MIXED_SIGNAL  = 32'h00000021,  // Mixed signal test
  
  // IEEE 1149.6 AC-coupled instructions
  AC_COUPLED    = 32'h00000030,  // AC coupled test
  DIFFERENTIAL  = 32'h00000031   // Differential test
} jtag_instruction_e;

// Enhanced TAP state machine with additional states
typedef enum {
  // Standard TAP states
  TAP_UNKNOWN,
  TEST_LOGIC_RESET,
  RUN_TEST_IDLE,
  SELECT_DR_SCAN,
  SELECT_IR_SCAN,
  CAPTURE_DR,
  CAPTURE_IR,
  SHIFT_DR,
  SHIFT_IR,
  EXIT1_DR,
  EXIT1_IR,
  PAUSE_DR,
  PAUSE_IR,
  EXIT2_DR,
  EXIT2_IR,
  UPDATE_DR,
  UPDATE_IR,
  
  // Enhanced states for advanced features
  ERROR_STATE,
  RECOVERY_STATE
} jtag_tap_state_e;

// Legacy support for existing code
typedef jtag_tap_state_e tap_state;
parameter tap_state X = TAP_UNKNOWN;
parameter tap_state RESET = TEST_LOGIC_RESET;
parameter tap_state IDLE = RUN_TEST_IDLE;
parameter tap_state SELECT_DR = SELECT_DR_SCAN;
parameter tap_state SELECT_IR = SELECT_IR_SCAN;
parameter tap_state EXIT_DR = EXIT1_DR;
parameter tap_state EXIT_IR = EXIT1_IR;
parameter tap_state EXIT2_DR = EXIT2_DR;
parameter tap_state EXIT2_IR = EXIT2_IR;

// Legacy instruction support
typedef jtag_instruction_e jtag_instr_registers;
parameter jtag_instr_registers DEBIG = DEBUG;

// JTAG protocol standards
typedef enum {
  IEEE_1149_1,    // Standard JTAG
  IEEE_1149_4,    // Mixed-signal test
  IEEE_1149_6,    // AC-coupled test
  IEEE_1149_7,    // Reduced pin count
  CUSTOM_PROTOCOL // Custom implementation
} jtag_standard_e;

// Error types for error injection framework
typedef enum {
  NO_ERROR,
  SINGLE_BIT_ERROR,
  MULTI_BIT_ERROR,
  PROTOCOL_VIOLATION,
  TIMING_ERROR,
  SIGNAL_CORRUPTION,
  STATE_MACHINE_ERROR,
  INSTRUCTION_ERROR,
  DATA_CORRUPTION,
  CLOCK_ERROR
} jtag_error_type_e;

// Protocol violation types
typedef enum {
  NO_VIOLATION,
  SETUP_TIME_VIOLATION,
  HOLD_TIME_VIOLATION,
  CLOCK_FREQUENCY_VIOLATION,
  SIGNAL_INTEGRITY_VIOLATION,
  STATE_TRANSITION_VIOLATION,
  INSTRUCTION_DECODE_VIOLATION,
  DATA_LENGTH_VIOLATION
} jtag_violation_type_e;

// Coverage scenarios for comprehensive testing
typedef enum {
  BASIC_INSTRUCTION_TEST,
  BOUNDARY_SCAN_TEST,
  DEBUG_ACCESS_TEST,
  ERROR_INJECTION_TEST,
  TIMING_VALIDATION_TEST,
  PROTOCOL_COMPLIANCE_TEST,
  PERFORMANCE_TEST,
  STRESS_TEST,
  CORNER_CASE_TEST
} jtag_coverage_scenario_e;

// Test patterns for boundary scan
typedef enum {
  ALL_ZEROS,
  ALL_ONES,
  ALTERNATING_01,
  ALTERNATING_10,
  WALKING_ONES,
  WALKING_ZEROS,
  RANDOM_PATTERN,
  CUSTOM_PATTERN
} jtag_test_pattern_e;

// Data patterns for enhanced testing
typedef enum {
  PATTERN_ZEROS,
  PATTERN_ONES,
  PATTERN_ALTERNATING,
  PATTERN_WALKING,
  PATTERN_RANDOM,
  PATTERN_CUSTOM
} data_pattern_e;

// Timing configuration structure
typedef struct {
  real tck_period;        // TCK clock period
  real tsu_tdi;          // TDI setup time
  real th_tdi;           // TDI hold time
  real tsu_tms;          // TMS setup time
  real th_tms;           // TMS hold time
  real tco_tdo;          // TDO clock to output
  real tdi_to_tdo_delay; // TDI to TDO propagation
  real trst_pulse_width; // TRST pulse width
  real tck_rise_time;    // TCK rise time
  real tck_fall_time;    // TCK fall time
} timing_info_t;

// Error information structure
typedef struct {
  jtag_error_type_e error_type;
  int error_location;
  int error_severity;
  string error_description;
  time error_time;
} error_info_t;

// Performance metrics structure
typedef struct {
  time transaction_start_time;
  time transaction_end_time;
  real transaction_latency;
  real throughput;
  int instruction_count;
  int data_bits_transferred;
} performance_info_t;

// Protocol compliance information
typedef struct {
  bit ieee_1149_1_compliant;
  bit ieee_1149_4_compliant;
  bit ieee_1149_6_compliant;
  jtag_violation_type_e violation_type;
  string compliance_notes;
} compliance_info_t;

// Enhanced transaction information
typedef struct {
  jtag_instruction_e instruction;
  bit [MAX_DATA_WIDTH-1:0] data;
  int instruction_length;
  int data_length;
  timing_info_t timing;
  error_info_t error_info;
  performance_info_t performance;
  compliance_info_t compliance;
  jtag_tap_state_e start_state;
  jtag_tap_state_e end_state;
} jtag_transaction_info_t;

// Utility macros for enhanced VIP
`define JTAG_INFO(msg) `uvm_info("JTAG_VIP", msg, UVM_LOW)
`define JTAG_WARNING(msg) `uvm_warning("JTAG_VIP", msg)
`define JTAG_ERROR(msg) `uvm_error("JTAG_VIP", msg)
`define JTAG_FATAL(msg) `uvm_fatal("JTAG_VIP", msg)

// Debug macros
`define JTAG_DEBUG(msg) `uvm_info("JTAG_DEBUG", msg, UVM_DEBUG)
`define JTAG_TRACE(msg) `uvm_info("JTAG_TRACE", msg, UVM_FULL)

`endif // JTAG_DEFS__SVH
