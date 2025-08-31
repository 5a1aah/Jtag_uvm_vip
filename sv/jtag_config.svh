`ifndef JTAG_CONFIG__SVH
 `define JTAG_CONFIG__SVH

//=============================================================================
// Enhanced JTAG VIP Configuration Classes
// Comprehensive configuration support for advanced JTAG verification
//=============================================================================

//-----------------------------------------------------------------------------
// Enhanced Timing Configuration Class
// Provides comprehensive timing control for JTAG operations
//-----------------------------------------------------------------------------
class jtag_timing_config extends uvm_object;
  // Clock timing parameters
  rand real tck_period;           // TCK clock period (ns)
  rand real tck_duty_cycle;       // TCK duty cycle (0.0-1.0)
  rand real tck_jitter;           // Clock jitter percentage
  
  // Setup and hold times
  rand real tsu_tdi;              // TDI setup time (ns)
  rand real th_tdi;               // TDI hold time (ns)
  rand real tsu_tms;              // TMS setup time (ns)
  rand real th_tms;               // TMS hold time (ns)
  
  // Output timing
  rand real tco_tdo_min;          // TDO clock to output min (ns)
  rand real tco_tdo_max;          // TDO clock to output max (ns)
  rand real tdi_to_tdo_delay;     // TDI to TDO propagation (ns)
  
  // Reset timing
  rand real trst_pulse_width;     // TRST pulse width (ns)
  rand real trst_to_tck_delay;    // TRST to TCK delay (ns)
  
  // Edge timing
  rand real tck_rise_time;        // TCK rise time (ns)
  rand real tck_fall_time;        // TCK fall time (ns)
  
  // Timing constraints
  constraint tck_period_c {
    tck_period inside {[10.0:1000.0]}; // 1MHz to 100MHz
  }
  
  constraint duty_cycle_c {
    tck_duty_cycle inside {[0.3:0.7]}; // 30% to 70%
  }
  
  constraint jitter_c {
    tck_jitter inside {[0.0:5.0]}; // 0% to 5%
  }
  
  constraint setup_hold_c {
    tsu_tdi inside {[1.0:10.0]};
    th_tdi inside {[1.0:10.0]};
    tsu_tms inside {[1.0:10.0]};
    th_tms inside {[1.0:10.0]};
  }
  
  constraint output_timing_c {
    tco_tdo_min inside {[1.0:20.0]};
    tco_tdo_max inside {[5.0:50.0]};
    tco_tdo_max > tco_tdo_min;
    tdi_to_tdo_delay inside {[0.0:100.0]};
  }
  
  constraint reset_timing_c {
    trst_pulse_width inside {[100.0:1000.0]};
    trst_to_tck_delay inside {[10.0:100.0]};
  }
  
  constraint edge_timing_c {
    tck_rise_time inside {[0.1:5.0]};
    tck_fall_time inside {[0.1:5.0]};
  }
  
  `uvm_object_utils_begin(jtag_timing_config)
    `uvm_field_real(tck_period, UVM_ALL_ON)
    `uvm_field_real(tck_duty_cycle, UVM_ALL_ON)
    `uvm_field_real(tck_jitter, UVM_ALL_ON)
    `uvm_field_real(tsu_tdi, UVM_ALL_ON)
    `uvm_field_real(th_tdi, UVM_ALL_ON)
    `uvm_field_real(tsu_tms, UVM_ALL_ON)
    `uvm_field_real(th_tms, UVM_ALL_ON)
    `uvm_field_real(tco_tdo_min, UVM_ALL_ON)
    `uvm_field_real(tco_tdo_max, UVM_ALL_ON)
    `uvm_field_real(tdi_to_tdo_delay, UVM_ALL_ON)
    `uvm_field_real(trst_pulse_width, UVM_ALL_ON)
    `uvm_field_real(trst_to_tck_delay, UVM_ALL_ON)
    `uvm_field_real(tck_rise_time, UVM_ALL_ON)
    `uvm_field_real(tck_fall_time, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_timing_config");
    super.new(name);
    // Set default values
    tck_period = 100.0;        // 10MHz default
    tck_duty_cycle = 0.5;      // 50% duty cycle
    tck_jitter = 1.0;          // 1% jitter
    tsu_tdi = 5.0;
    th_tdi = 5.0;
    tsu_tms = 5.0;
    th_tms = 5.0;
    tco_tdo_min = 5.0;
    tco_tdo_max = 15.0;
    tdi_to_tdo_delay = 10.0;
    trst_pulse_width = 500.0;
    trst_to_tck_delay = 50.0;
    tck_rise_time = 1.0;
    tck_fall_time = 1.0;
  endfunction
  
  // Utility functions
  function real get_tck_frequency();
    return (1000.0 / tck_period); // MHz
  endfunction
  
  function void set_fast_timing();
    tck_period = 20.0;         // 50MHz
    tsu_tdi = 2.0;
    th_tdi = 2.0;
    tsu_tms = 2.0;
    th_tms = 2.0;
  endfunction
  
  function void set_slow_timing();
    tck_period = 1000.0;       // 1MHz
    tsu_tdi = 10.0;
    th_tdi = 10.0;
    tsu_tms = 10.0;
    th_tms = 10.0;
  endfunction
endclass

//-----------------------------------------------------------------------------
// Protocol Configuration Class
// Configures JTAG protocol variants and compliance settings
//-----------------------------------------------------------------------------
class jtag_protocol_config extends uvm_object;
  rand jtag_standard_e protocol_standard;  // IEEE standard to follow
  rand bit enable_compliance_checking;     // Enable protocol compliance
  rand bit enable_timing_checking;         // Enable timing validation
  rand bit enable_signal_integrity;        // Enable signal integrity checks
  
  // Protocol-specific settings
  rand bit ieee_1149_1_mode;              // Standard JTAG mode
  rand bit ieee_1149_4_mode;              // Mixed-signal mode
  rand bit ieee_1149_6_mode;              // AC-coupled mode
  rand bit ieee_1149_7_mode;              // Reduced pin count mode
  
  // Compliance tolerances
  rand real timing_tolerance;             // Timing tolerance percentage
  rand real voltage_tolerance;            // Voltage tolerance percentage
  
  constraint protocol_c {
    protocol_standard inside {IEEE_1149_1, IEEE_1149_4, IEEE_1149_6, CUSTOM_PROTOCOL};
  }
  
  constraint tolerance_c {
    timing_tolerance inside {[1.0:10.0]};
    voltage_tolerance inside {[1.0:5.0]};
  }
  
  `uvm_object_utils_begin(jtag_protocol_config)
    `uvm_field_enum(jtag_standard_e, protocol_standard, UVM_ALL_ON)
    `uvm_field_int(enable_compliance_checking, UVM_ALL_ON)
    `uvm_field_int(enable_timing_checking, UVM_ALL_ON)
    `uvm_field_int(enable_signal_integrity, UVM_ALL_ON)
    `uvm_field_int(ieee_1149_1_mode, UVM_ALL_ON)
    `uvm_field_int(ieee_1149_4_mode, UVM_ALL_ON)
    `uvm_field_int(ieee_1149_6_mode, UVM_ALL_ON)
    `uvm_field_int(ieee_1149_7_mode, UVM_ALL_ON)
    `uvm_field_real(timing_tolerance, UVM_ALL_ON)
    `uvm_field_real(voltage_tolerance, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_protocol_config");
    super.new(name);
    protocol_standard = IEEE_1149_1;
    enable_compliance_checking = 1;
    enable_timing_checking = 1;
    enable_signal_integrity = 1;
    ieee_1149_1_mode = 1;
    ieee_1149_4_mode = 0;
    ieee_1149_6_mode = 0;
    ieee_1149_7_mode = 0;
    timing_tolerance = 5.0;
    voltage_tolerance = 2.0;
  endfunction
endclass

//-----------------------------------------------------------------------------
// Error Injection Configuration Class
// Configures error injection capabilities for robustness testing
//-----------------------------------------------------------------------------
class jtag_error_config extends uvm_object;
  rand bit enable_error_injection;        // Enable error injection
  rand jtag_error_type_e error_type;      // Type of error to inject
  rand int error_rate;                    // Error injection rate (1 in N)
  rand int error_duration;                // Error duration in cycles
  rand bit enable_recovery_testing;       // Test error recovery
  
  // Error location control
  rand bit inject_in_instruction;         // Inject errors in IR
  rand bit inject_in_data;                // Inject errors in DR
  rand bit inject_in_control;             // Inject errors in control signals
  
  constraint error_rate_c {
    error_rate inside {[10:10000]}; // 1 in 10 to 1 in 10000
  }
  
  constraint error_duration_c {
    error_duration inside {[1:100]}; // 1 to 100 cycles
  }
  
  `uvm_object_utils_begin(jtag_error_config)
    `uvm_field_int(enable_error_injection, UVM_ALL_ON)
    `uvm_field_enum(jtag_error_type_e, error_type, UVM_ALL_ON)
    `uvm_field_int(error_rate, UVM_ALL_ON)
    `uvm_field_int(error_duration, UVM_ALL_ON)
    `uvm_field_int(enable_recovery_testing, UVM_ALL_ON)
    `uvm_field_int(inject_in_instruction, UVM_ALL_ON)
    `uvm_field_int(inject_in_data, UVM_ALL_ON)
    `uvm_field_int(inject_in_control, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_error_config");
    super.new(name);
    enable_error_injection = 0;
    error_type = NO_ERROR;
    error_rate = 1000;
    error_duration = 1;
    enable_recovery_testing = 0;
    inject_in_instruction = 1;
    inject_in_data = 1;
    inject_in_control = 0;
  endfunction
endclass

//-----------------------------------------------------------------------------
// Enhanced Driver Configuration Class
// Comprehensive driver configuration with advanced features
//-----------------------------------------------------------------------------
class jtag_driver_config extends uvm_object;
  // Basic configuration
  rand int instruction_size;
  rand int data_size;
  rand int boundary_length;
  
  // Advanced configuration objects
  jtag_timing_config timing_cfg;
  jtag_protocol_config protocol_cfg;
  jtag_error_config error_cfg;
  
  // Driver behavior control
  rand bit enable_debug_mode;             // Enable debug output
  rand bit enable_performance_monitoring; // Monitor performance
  rand bit enable_coverage_collection;    // Collect coverage
  rand bit randomize_delays;              // Add random delays
  
  // Transaction control
  rand int max_transaction_size;          // Maximum transaction size
  rand int min_transaction_size;          // Minimum transaction size
  rand real transaction_timeout;          // Transaction timeout (ns)
  
  constraint instruction_size_c {
    instruction_size inside {[4:32]};
  }
  
  constraint data_size_c {
    data_size inside {[1:MAX_DATA_WIDTH]};
  }
  
  constraint boundary_length_c {
    boundary_length inside {[1:MAX_BOUNDARY_LENGTH]};
  }
  
  constraint transaction_size_c {
    min_transaction_size inside {[1:1024]};
    max_transaction_size inside {[min_transaction_size:MAX_DATA_WIDTH]};
  }
  
  constraint timeout_c {
    transaction_timeout inside {[1000.0:1000000.0]}; // 1us to 1ms
  }
  
  `uvm_object_utils_begin(jtag_driver_config)
    `uvm_field_int(instruction_size, UVM_ALL_ON)
    `uvm_field_int(data_size, UVM_ALL_ON)
    `uvm_field_int(boundary_length, UVM_ALL_ON)
    `uvm_field_object(timing_cfg, UVM_ALL_ON)
    `uvm_field_object(protocol_cfg, UVM_ALL_ON)
    `uvm_field_object(error_cfg, UVM_ALL_ON)
    `uvm_field_int(enable_debug_mode, UVM_ALL_ON)
    `uvm_field_int(enable_performance_monitoring, UVM_ALL_ON)
    `uvm_field_int(enable_coverage_collection, UVM_ALL_ON)
    `uvm_field_int(randomize_delays, UVM_ALL_ON)
    `uvm_field_int(max_transaction_size, UVM_ALL_ON)
    `uvm_field_int(min_transaction_size, UVM_ALL_ON)
    `uvm_field_real(transaction_timeout, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_driver_config");
    super.new(name);
    // Create sub-configuration objects
    timing_cfg = jtag_timing_config::type_id::create("timing_cfg");
    protocol_cfg = jtag_protocol_config::type_id::create("protocol_cfg");
    error_cfg = jtag_error_config::type_id::create("error_cfg");
    
    // Set default values
    instruction_size = 8;
    data_size = 32;
    boundary_length = 256;
    enable_debug_mode = 0;
    enable_performance_monitoring = 1;
    enable_coverage_collection = 1;
    randomize_delays = 0;
    max_transaction_size = 1024;
    min_transaction_size = 1;
    transaction_timeout = 100000.0; // 100us
  endfunction
endclass

//-----------------------------------------------------------------------------
// Enhanced Monitor Configuration Class
// Configuration for comprehensive monitoring and checking
//-----------------------------------------------------------------------------
class jtag_monitor_config extends uvm_object;
  // Monitoring control
  rand bit enable_protocol_checking;      // Enable protocol compliance
  rand bit enable_timing_checking;        // Enable timing validation
  rand bit enable_coverage_collection;    // Enable coverage collection
  rand bit enable_performance_monitoring; // Enable performance monitoring
  
  // Checking levels
  rand int protocol_check_level;          // 0=basic, 1=standard, 2=strict
  rand int timing_check_level;            // 0=basic, 1=standard, 2=strict
  
  // Coverage configuration
  rand bit collect_instruction_coverage;  // Collect instruction coverage
  rand bit collect_state_coverage;        // Collect state coverage
  rand bit collect_transition_coverage;   // Collect transition coverage
  rand bit collect_timing_coverage;       // Collect timing coverage
  
  constraint check_level_c {
    protocol_check_level inside {[0:2]};
    timing_check_level inside {[0:2]};
  }
  
  `uvm_object_utils_begin(jtag_monitor_config)
    `uvm_field_int(enable_protocol_checking, UVM_ALL_ON)
    `uvm_field_int(enable_timing_checking, UVM_ALL_ON)
    `uvm_field_int(enable_coverage_collection, UVM_ALL_ON)
    `uvm_field_int(enable_performance_monitoring, UVM_ALL_ON)
    `uvm_field_int(protocol_check_level, UVM_ALL_ON)
    `uvm_field_int(timing_check_level, UVM_ALL_ON)
    `uvm_field_int(collect_instruction_coverage, UVM_ALL_ON)
    `uvm_field_int(collect_state_coverage, UVM_ALL_ON)
    `uvm_field_int(collect_transition_coverage, UVM_ALL_ON)
    `uvm_field_int(collect_timing_coverage, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_monitor_config");
    super.new(name);
    enable_protocol_checking = 1;
    enable_timing_checking = 1;
    enable_coverage_collection = 1;
    enable_performance_monitoring = 1;
    protocol_check_level = 1;
    timing_check_level = 1;
    collect_instruction_coverage = 1;
    collect_state_coverage = 1;
    collect_transition_coverage = 1;
    collect_timing_coverage = 1;
  endfunction
endclass

//-----------------------------------------------------------------------------
// Enhanced Agent Configuration Classes
// Comprehensive agent configuration with advanced features
//-----------------------------------------------------------------------------
class jtag_agent_config extends uvm_object;
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  jtag_monitor_config mon_cfg;
  
  `uvm_object_utils_begin(jtag_agent_config)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
    `uvm_field_object(mon_cfg, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_agent_config");
    super.new(name);
    mon_cfg = jtag_monitor_config::type_id::create("mon_cfg");
  endfunction
endclass

class jtag_agent_config_active extends jtag_agent_config;
  jtag_driver_config drv_cfg;
  
  `uvm_object_utils_begin(jtag_agent_config_active)
    `uvm_field_object(drv_cfg, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_agent_config_active");
    super.new(name);
    drv_cfg = jtag_driver_config::type_id::create("drv_cfg");
  endfunction
endclass

//-----------------------------------------------------------------------------
// Enhanced Environment Configuration Class
// Top-level environment configuration
//-----------------------------------------------------------------------------
class jtag_env_config extends uvm_object;
  jtag_agent_config agent_cfg;
  
  // Environment-level settings
  rand int num_agents;                    // Number of JTAG agents
  rand bit enable_scoreboard;             // Enable scoreboard
  rand bit enable_coverage_report;        // Generate coverage report
  rand bit enable_performance_report;     // Generate performance report
  
  constraint num_agents_c {
    num_agents inside {[1:MAX_CHAIN_LENGTH]};
  }
  
  `uvm_object_utils_begin(jtag_env_config)
    `uvm_field_object(agent_cfg, UVM_ALL_ON)
    `uvm_field_int(num_agents, UVM_ALL_ON)
    `uvm_field_int(enable_scoreboard, UVM_ALL_ON)
    `uvm_field_int(enable_coverage_report, UVM_ALL_ON)
    `uvm_field_int(enable_performance_report, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "jtag_env_config");
    super.new(name);
    agent_cfg = jtag_agent_config::type_id::create("agent_cfg");
    num_agents = 1;
    enable_scoreboard = 1;
    enable_coverage_report = 1;
    enable_performance_report = 1;
  endfunction
endclass

//-----------------------------------------------------------------------------
// Enhanced Test Configuration Class
// Comprehensive test configuration with advanced test scenarios
//-----------------------------------------------------------------------------
class test_configuration extends uvm_object;
  // Basic test parameters
  rand int num_of_sequences;
  rand int sequence_length;
  rand jtag_coverage_scenario_e test_scenario;
  
  // Test control
  rand bit enable_random_testing;         // Enable random test generation
  rand bit enable_directed_testing;       // Enable directed tests
  rand bit enable_stress_testing;         // Enable stress tests
  rand bit enable_corner_case_testing;    // Enable corner case tests
  
  // Test patterns
  rand jtag_test_pattern_e test_pattern;
  rand data_pattern_e data_pattern;
  
  // Test duration and limits
  rand int max_test_duration;             // Maximum test duration (cycles)
  rand int max_errors_allowed;            // Maximum errors before stopping
  
  constraint num_sequences_c {
    num_of_sequences inside {[1:1000]};
  }
  
  constraint sequence_length_c {
    sequence_length inside {[1:100]};
  }
  
  constraint test_duration_c {
    max_test_duration inside {[1000:1000000]};
  }
  
  constraint max_errors_c {
    max_errors_allowed inside {[0:100]};
  }
  
  `uvm_object_utils_begin(test_configuration)
    `uvm_field_int(num_of_sequences, UVM_ALL_ON)
    `uvm_field_int(sequence_length, UVM_ALL_ON)
    `uvm_field_enum(jtag_coverage_scenario_e, test_scenario, UVM_ALL_ON)
    `uvm_field_int(enable_random_testing, UVM_ALL_ON)
    `uvm_field_int(enable_directed_testing, UVM_ALL_ON)
    `uvm_field_int(enable_stress_testing, UVM_ALL_ON)
    `uvm_field_int(enable_corner_case_testing, UVM_ALL_ON)
    `uvm_field_enum(jtag_test_pattern_e, test_pattern, UVM_ALL_ON)
    `uvm_field_enum(data_pattern_e, data_pattern, UVM_ALL_ON)
    `uvm_field_int(max_test_duration, UVM_ALL_ON)
    `uvm_field_int(max_errors_allowed, UVM_ALL_ON)
  `uvm_object_utils_end
  
  function new(string name = "test_configuration");
    super.new(name);
    num_of_sequences = 10;
    sequence_length = 10;
    test_scenario = BASIC_INSTRUCTION_TEST;
    enable_random_testing = 1;
    enable_directed_testing = 1;
    enable_stress_testing = 0;
    enable_corner_case_testing = 0;
    test_pattern = RANDOM_PATTERN;
    data_pattern = PATTERN_RANDOM;
    max_test_duration = 100000;
    max_errors_allowed = 10;
  endfunction
endclass

`endif // JTAG_CONFIG__SVH
