# Enhanced JTAG VIP User Guide

## Table of Contents

1. [Introduction](#introduction)
2. [Getting Started](#getting-started)
3. [Configuration Guide](#configuration-guide)
4. [Sequence Library](#sequence-library)
5. [Advanced Features](#advanced-features)
6. [Performance Monitoring](#performance-monitoring)
7. [Error Injection](#error-injection)
8. [Debugging and Troubleshooting](#debugging-and-troubleshooting)
9. [Best Practices](#best-practices)
10. [API Reference](#api-reference)

## Introduction

The Enhanced JTAG VIP (Verification IP) is a comprehensive SystemVerilog UVM-based verification environment for JTAG protocol testing. This user guide provides detailed instructions for effectively using all features of the VIP.

### Key Benefits

- **Comprehensive Protocol Support**: IEEE 1149.1/1149.4/1149.6/1149.7 compliance
- **Advanced Verification**: Protocol checking, timing validation, coverage collection
- **Performance Monitoring**: Real-time metrics and analysis
- **Error Injection**: Systematic fault injection and testing
- **Professional Reporting**: Detailed analysis and visualization

## Getting Started

### Prerequisites

- SystemVerilog simulator (VCS, Questa, Xcelium)
- UVM 1.2 or later
- Basic understanding of JTAG protocol
- Familiarity with UVM methodology

### Installation

1. **Clone or download the JTAG VIP**
   ```bash
   git clone <repository_url>
   cd jtag_vip_uvm
   ```

2. **Set up include paths**
   ```bash
   export JTAG_VIP_HOME=$PWD
   export UVM_HOME=<path_to_uvm>
   ```

3. **Compile the VIP**
   ```bash
   # Using VCS
   vcs -sverilog +incdir+$JTAG_VIP_HOME/src \
       +incdir+$JTAG_VIP_HOME/src/config \
       +incdir+$JTAG_VIP_HOME/src/sequences \
       +incdir+$JTAG_VIP_HOME/src/components \
       +incdir+$JTAG_VIP_HOME/src/analysis \
       +incdir+$JTAG_VIP_HOME/src/advanced \
       -ntb_opts uvm-1.2 \
       $JTAG_VIP_HOME/src/jtag_vip_pkg.sv
   ```

### First Test

```systemverilog
// my_first_jtag_test.sv
class my_first_jtag_test extends uvm_test;
  `uvm_component_utils(my_first_jtag_test)
  
  jtag_env env;
  jtag_env_config env_cfg;
  
  function new(string name = "my_first_jtag_test", uvm_component parent = null);
    super.new(name, parent);
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Initialize JTAG VIP
    jtag_vip_init();
    jtag_vip_info();
    
    // Create and configure environment
    env_cfg = jtag_env_config::type_id::create("env_cfg");
    env_cfg.agent_cfg.is_active = UVM_ACTIVE;
    env_cfg.agent_cfg.protocol_cfg.ieee_standard = IEEE_1149_1_2013;
    env_cfg.agent_cfg.protocol_cfg.ir_width = 8;
    
    uvm_config_db#(jtag_env_config)::set(this, "env", "config", env_cfg);
    env = jtag_env::type_id::create("env", this);
  endfunction
  
  virtual task run_phase(uvm_phase phase);
    jtag_reset_sequence reset_seq;
    jtag_ir_scan_sequence ir_seq;
    
    phase.raise_objection(this);
    
    `uvm_info("TEST", "Starting first JTAG test", UVM_LOW)
    
    // Reset the JTAG TAP
    reset_seq = jtag_reset_sequence::type_id::create("reset_seq");
    reset_seq.start(env.agent.sequencer);
    
    // Scan IDCODE instruction
    ir_seq = jtag_ir_scan_sequence::type_id::create("ir_seq");
    ir_seq.instruction = IDCODE;
    ir_seq.start(env.agent.sequencer);
    
    `uvm_info("TEST", "First JTAG test completed", UVM_LOW)
    
    phase.drop_objection(this);
  endtask
endclass
```

## Configuration Guide

### Environment Configuration

The JTAG VIP uses a hierarchical configuration system:

```systemverilog
// Complete environment configuration
jtag_env_config env_cfg = jtag_env_config::type_id::create("env_cfg");

// Agent configuration
env_cfg.agent_cfg.is_active = UVM_ACTIVE;
env_cfg.agent_cfg.has_driver = 1;
env_cfg.agent_cfg.has_monitor = 1;
env_cfg.agent_cfg.has_collector = 1;

// Enable advanced components
env_cfg.enable_scoreboard = 1;
env_cfg.enable_error_injector = 1;
env_cfg.enable_debug_dashboard = 1;
env_cfg.enable_virtual_sequencer = 1;
```

### Protocol Configuration

```systemverilog
// Protocol-specific settings
jtag_protocol_config protocol_cfg = jtag_protocol_config::type_id::create("protocol_cfg");

// IEEE standard selection
protocol_cfg.ieee_standard = IEEE_1149_1_2013;

// Register widths
protocol_cfg.ir_width = 8;           // Instruction register width
protocol_cfg.max_ir_length = 32;     // Maximum IR length
protocol_cfg.max_dr_length = 1024;   // Maximum DR length

// Compliance checking
protocol_cfg.enable_compliance_checking = 1;
protocol_cfg.enable_state_checking = 1;
protocol_cfg.enable_instruction_checking = 1;
protocol_cfg.enable_data_integrity_checking = 1;

// Device chain configuration
protocol_cfg.num_devices = 1;
protocol_cfg.device_ir_lengths = '{8}; // IR length for each device
```

### Timing Configuration

```systemverilog
// Timing parameters
jtag_timing_config timing_cfg = jtag_timing_config::type_id::create("timing_cfg");

// Clock timing
timing_cfg.tck_period = 100.0;       // 10MHz clock
timing_cfg.tck_duty_cycle = 50.0;    // 50% duty cycle
timing_cfg.tck_jitter = 1.0;         // 1ns jitter

// Setup and hold times
timing_cfg.tsu_time = 5.0;           // Setup time
timing_cfg.th_time = 5.0;            // Hold time
timing_cfg.tco_time = 10.0;          // Clock to output time
timing_cfg.tpd_time = 15.0;          // Propagation delay

// Reset timing
timing_cfg.trst_pulse_width = 100.0; // Reset pulse width
timing_cfg.trst_setup_time = 10.0;   // Reset setup time

// Validation enables
timing_cfg.enable_timing_checks = 1;
timing_cfg.enable_setup_hold_checks = 1;
timing_cfg.enable_jitter_analysis = 1;
timing_cfg.enable_performance_analysis = 1;
```

### Coverage Configuration

```systemverilog
// Coverage settings
jtag_coverage_config coverage_cfg = jtag_coverage_config::type_id::create("coverage_cfg");

// Enable coverage groups
coverage_cfg.enable_instruction_coverage = 1;
coverage_cfg.enable_state_coverage = 1;
coverage_cfg.enable_data_coverage = 1;
coverage_cfg.enable_timing_coverage = 1;
coverage_cfg.enable_boundary_scan_coverage = 1;
coverage_cfg.enable_debug_coverage = 1;
coverage_cfg.enable_error_coverage = 1;
coverage_cfg.enable_compliance_coverage = 1;

// Coverage goals
coverage_cfg.instruction_coverage_goal = 100;
coverage_cfg.state_coverage_goal = 100;
coverage_cfg.data_coverage_goal = 95;
coverage_cfg.overall_coverage_goal = 98;
```

## Sequence Library

### Basic Sequences

#### Reset Sequence

```systemverilog
// Reset the JTAG TAP
jtag_reset_sequence reset_seq = jtag_reset_sequence::type_id::create("reset_seq");
reset_seq.reset_type = HARD_RESET;  // or SOFT_RESET
reset_seq.reset_cycles = 5;
reset_seq.start(sequencer);
```

#### IR Scan Sequence

```systemverilog
// Scan instruction register
jtag_ir_scan_sequence ir_seq = jtag_ir_scan_sequence::type_id::create("ir_seq");
ir_seq.instruction = EXTEST;
ir_seq.ir_width = 8;
ir_seq.start(sequencer);
```

#### DR Scan Sequence

```systemverilog
// Scan data register
jtag_dr_scan_sequence dr_seq = jtag_dr_scan_sequence::type_id::create("dr_seq");
dr_seq.data_in = 32'hA5A5A5A5;
dr_seq.data_length = 32;
dr_seq.capture_data = 1;
dr_seq.start(sequencer);
```

### Advanced Sequences

#### Boundary Scan Sequence

```systemverilog
// Comprehensive boundary scan test
jtag_boundary_scan_sequence bs_seq = jtag_boundary_scan_sequence::type_id::create("bs_seq");

// Configure scan type
bs_seq.scan_type = EXTEST;           // External test
bs_seq.pattern_type = WALKING_ONES;  // Test pattern
bs_seq.num_patterns = 10;            // Number of patterns
bs_seq.boundary_length = 256;        // Boundary scan length
bs_seq.enable_capture = 1;           // Capture responses
bs_seq.enable_comparison = 1;        // Compare expected vs actual

// Custom test patterns
bs_seq.custom_patterns = new[3];
bs_seq.custom_patterns[0] = 256'h0;
bs_seq.custom_patterns[1] = 256'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF;
bs_seq.custom_patterns[2] = 256'hA5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5A5;

bs_seq.start(sequencer);
```

#### Debug Access Sequence

```systemverilog
// Debug register access
jtag_debug_sequence debug_seq = jtag_debug_sequence::type_id::create("debug_seq");

// Configure debug operation
debug_seq.debug_op = DEBUG_REG_READ;  // or DEBUG_REG_WRITE, DEBUG_MEM_READ, etc.
debug_seq.debug_addr = 32'h1000;     // Debug register address
debug_seq.debug_data = 32'h12345678; // Data for write operations
debug_seq.data_width = 32;           // Data width

// Advanced debug features
debug_seq.enable_authentication = 1;  // Enable debug authentication
debug_seq.auth_key = 64'hDEADBEEFCAFEBABE; // Authentication key
debug_seq.enable_encryption = 1;      // Enable data encryption

debug_seq.start(sequencer);
```

### Error Injection Sequence

```systemverilog
// Systematic error injection
jtag_error_injection_sequence err_seq = jtag_error_injection_sequence::type_id::create("err_seq");

// Configure error types
err_seq.error_types = '{ERR_BIT_FLIP, ERR_TIMING_VIOLATION, ERR_PROTOCOL_VIOLATION};
err_seq.injection_mode = SYSTEMATIC;  // or RANDOM
err_seq.error_rate = 0.1;            // 10% error rate
err_seq.num_transactions = 100;       // Number of transactions to test

// Error injection phases
err_seq.inject_in_ir_scan = 1;
err_seq.inject_in_dr_scan = 1;
err_seq.inject_in_state_transitions = 1;

err_seq.start(sequencer);
```

## Advanced Features

### Protocol Compliance Checking

The VIP automatically validates JTAG protocol compliance:

```systemverilog
// Access compliance results
jtag_protocol_checker checker = env.agent.protocol_checker;

// Get compliance statistics
int total_violations = checker.get_total_violations();
int state_violations = checker.get_state_violations();
int instruction_violations = checker.get_instruction_violations();
int timing_violations = checker.get_timing_violations();

`uvm_info("COMPLIANCE", $sformatf("Total violations: %0d", total_violations), UVM_LOW);

// Get detailed violation report
string violation_report = checker.get_violation_report();
`uvm_info("COMPLIANCE", violation_report, UVM_LOW);
```

### Timing Validation

```systemverilog
// Access timing validation results
jtag_timing_validator validator = env.agent.timing_validator;

// Get timing statistics
real avg_setup_time = validator.get_average_setup_time();
real avg_hold_time = validator.get_average_hold_time();
real max_jitter = validator.get_maximum_jitter();

`uvm_info("TIMING", $sformatf("Avg setup: %0.2f ns", avg_setup_time), UVM_LOW);
`uvm_info("TIMING", $sformatf("Max jitter: %0.2f ns", max_jitter), UVM_LOW);
```

### Functional Coverage

```systemverilog
// Access coverage results
jtag_coverage_collector coverage = env.agent.coverage_collector;

// Get coverage percentages
real instruction_cov = coverage.get_instruction_coverage();
real state_cov = coverage.get_state_coverage();
real overall_cov = coverage.get_overall_coverage();

`uvm_info("COVERAGE", $sformatf("Instruction coverage: %0.1f%%", instruction_cov), UVM_LOW);
`uvm_info("COVERAGE", $sformatf("Overall coverage: %0.1f%%", overall_cov), UVM_LOW);

// Generate coverage report
string cov_report = coverage.get_coverage_report();
`uvm_info("COVERAGE", cov_report, UVM_LOW);
```

## Performance Monitoring

### Real-time Metrics

```systemverilog
// Access performance monitor
jtag_performance_monitor perf_mon = env.performance_monitor;

// Get current metrics
jtag_performance_metrics_s metrics = perf_mon.get_current_metrics();

`uvm_info("PERF", $sformatf("Throughput: %0.2f Mbps", metrics.throughput_mbps), UVM_LOW);
`uvm_info("PERF", $sformatf("Latency: %0.2f ns", metrics.latency_ns), UVM_LOW);
`uvm_info("PERF", $sformatf("Bandwidth utilization: %0.1f%%", metrics.bandwidth_utilization), UVM_LOW);
`uvm_info("PERF", $sformatf("Error rate: %0.3f%%", metrics.error_rate), UVM_LOW);
```

### Performance Thresholds

```systemverilog
// Set performance thresholds
perf_mon.set_throughput_threshold(50.0);      // Minimum 50 Mbps
perf_mon.set_latency_threshold(1000.0);       // Maximum 1000 ns
perf_mon.set_error_rate_threshold(1.0);       // Maximum 1% error rate

// Enable automatic alerts
perf_mon.enable_threshold_alerts = 1;
perf_mon.alert_interval = 1000; // Check every 1000 transactions
```

### Trend Analysis

```systemverilog
// Enable trend analysis
perf_mon.enable_trend_analysis = 1;
perf_mon.trend_window_size = 1000; // Analyze last 1000 transactions

// Get trend data
real throughput_trend = perf_mon.get_throughput_trend();
real latency_trend = perf_mon.get_latency_trend();

`uvm_info("TREND", $sformatf("Throughput trend: %0.2f%%", throughput_trend), UVM_LOW);
`uvm_info("TREND", $sformatf("Latency trend: %0.2f%%", latency_trend), UVM_LOW);
```

## Error Injection

### Systematic Error Testing

```systemverilog
// Configure error injector
jtag_error_injector err_inj = env.error_injector;

// Enable systematic error injection
err_inj.enable_error_injection = 1;
err_inj.error_injection_mode = SYSTEMATIC;

// Configure error types
err_inj.enable_bit_flip = 1;
err_inj.enable_stuck_at_0 = 1;
err_inj.enable_stuck_at_1 = 1;
err_inj.enable_timing_errors = 1;
err_inj.enable_protocol_errors = 1;

// Set injection parameters
err_inj.bit_flip_probability = 0.01;    // 1% bit flip rate
err_inj.timing_error_magnitude = 5.0;   // 5ns timing error
err_inj.protocol_error_rate = 0.005;    // 0.5% protocol error rate
```

### Random Error Testing

```systemverilog
// Random error injection
err_inj.error_injection_mode = RANDOM;
err_inj.random_seed = 12345;
err_inj.error_injection_rate = 0.1; // 10% overall error rate

// Weight different error types
err_inj.bit_flip_weight = 40;      // 40% of errors are bit flips
err_inj.timing_error_weight = 30;  // 30% are timing errors
err_inj.protocol_error_weight = 20; // 20% are protocol errors
err_inj.other_error_weight = 10;   // 10% are other errors
```

### Error Recovery Testing

```systemverilog
// Test error recovery mechanisms
err_inj.enable_error_recovery_testing = 1;
err_inj.recovery_timeout = 1000; // 1000 clock cycles
err_inj.max_recovery_attempts = 3;

// Monitor recovery success rate
real recovery_rate = err_inj.get_recovery_success_rate();
`uvm_info("RECOVERY", $sformatf("Recovery success rate: %0.1f%%", recovery_rate), UVM_LOW);
```

## Debugging and Troubleshooting

### Debug Dashboard

```systemverilog
// Access debug dashboard
jtag_debug_dashboard dashboard = env.debug_dashboard;

// Enable real-time monitoring
dashboard.enable_real_time_monitoring = 1;
dashboard.update_interval = 100; // Update every 100 transactions

// Get dashboard report
jtag_dashboard_report dash_report = dashboard.get_dashboard_report();
`uvm_info("DASHBOARD", dash_report.to_string(), UVM_LOW);

// Check for alerts
if (dashboard.has_active_alerts()) begin
  jtag_alert_report alert = dashboard.get_latest_alert();
  `uvm_warning("ALERT", alert.to_string());
end
```

### Verbose Logging

```systemverilog
// Enable detailed logging
uvm_top.set_report_verbosity_level_hier(UVM_HIGH);

// Enable specific debug categories
uvm_top.set_report_id_action_hier("JTAG_VIP_DEBUG", UVM_DISPLAY);
uvm_top.set_report_id_action_hier("JTAG_PROTOCOL", UVM_DISPLAY);
uvm_top.set_report_id_action_hier("JTAG_TIMING", UVM_DISPLAY);
uvm_top.set_report_id_action_hier("JTAG_PERFORMANCE", UVM_DISPLAY);

// Log to file
uvm_top.set_report_default_file_hier("jtag_debug.log");
```

### Common Issues and Solutions

#### Issue: Timing Violations

```systemverilog
// Solution: Adjust timing parameters
timing_cfg.tck_period = 200.0;  // Slower clock
timing_cfg.tsu_time = 10.0;     // Longer setup time
timing_cfg.th_time = 10.0;      // Longer hold time
```

#### Issue: Protocol Compliance Failures

```systemverilog
// Solution: Check protocol configuration
protocol_cfg.ieee_standard = IEEE_1149_1_2013; // Correct standard
protocol_cfg.ir_width = 8;                     // Correct IR width
protocol_cfg.enable_compliance_checking = 1;   // Enable checking
```

#### Issue: Low Coverage

```systemverilog
// Solution: Add more test scenarios
// Use coverage-driven test generation
jtag_coverage_driven_sequence cov_seq = jtag_coverage_driven_sequence::type_id::create("cov_seq");
cov_seq.target_coverage = 95.0;
cov_seq.max_iterations = 10000;
cov_seq.start(sequencer);
```

## Best Practices

### 1. Configuration Management

```systemverilog
// Use configuration objects consistently
class my_test_config extends jtag_env_config;
  function new(string name = "my_test_config");
    super.new(name);
    
    // Set common configuration
    this.agent_cfg.is_active = UVM_ACTIVE;
    this.agent_cfg.protocol_cfg.ieee_standard = IEEE_1149_1_2013;
    this.enable_scoreboard = 1;
    this.enable_debug_dashboard = 1;
  endfunction
endclass
```

### 2. Sequence Organization

```systemverilog
// Create base test class
class jtag_base_test extends uvm_test;
  jtag_env env;
  jtag_env_config env_cfg;
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Common setup
    jtag_vip_init();
    create_environment();
    configure_environment();
  endfunction
  
  virtual function void create_environment();
    env = jtag_env::type_id::create("env", this);
  endfunction
  
  virtual function void configure_environment();
    env_cfg = my_test_config::type_id::create("env_cfg");
    uvm_config_db#(jtag_env_config)::set(this, "env", "config", env_cfg);
  endfunction
endclass
```

### 3. Error Handling

```systemverilog
// Implement robust error handling
virtual task run_phase(uvm_phase phase);
  phase.raise_objection(this);
  
  fork
    begin
      // Main test sequence
      run_main_sequence();
    end
    begin
      // Timeout watchdog
      #1ms;
      `uvm_fatal("TIMEOUT", "Test timed out")
    end
  join_any
  disable fork;
  
  phase.drop_objection(this);
endtask
```

### 4. Performance Optimization

```systemverilog
// Optimize for performance
// Disable unnecessary features for performance tests
if (test_type == PERFORMANCE_TEST) begin
  env_cfg.agent_cfg.coverage_cfg.enable_instruction_coverage = 0;
  env_cfg.agent_cfg.coverage_cfg.enable_state_coverage = 0;
  env_cfg.enable_debug_dashboard = 0;
end
```

## API Reference

### Core Classes

#### jtag_env
- `build_phase()` - Build environment components
- `connect_phase()` - Connect components
- `run_phase()` - Monitor environment health
- `report_phase()` - Generate final reports

#### jtag_agent
- `build_phase()` - Build agent components
- `connect_phase()` - Connect analysis ports

#### jtag_driver
- `run_phase()` - Drive JTAG transactions
- `drive_transaction()` - Drive single transaction
- `reset_interface()` - Reset JTAG interface

#### jtag_monitor
- `run_phase()` - Monitor JTAG interface
- `collect_transaction()` - Collect transaction
- `check_protocol()` - Check protocol compliance

### Configuration Classes

#### jtag_protocol_config
- `ieee_standard` - IEEE standard selection
- `ir_width` - Instruction register width
- `enable_compliance_checking` - Enable protocol checking

#### jtag_timing_config
- `tck_period` - Clock period
- `tsu_time` - Setup time
- `th_time` - Hold time
- `enable_timing_checks` - Enable timing validation

### Sequence Classes

#### jtag_base_sequence
- `pre_body()` - Pre-sequence setup
- `body()` - Main sequence body
- `post_body()` - Post-sequence cleanup

#### jtag_boundary_scan_sequence
- `scan_type` - Boundary scan type
- `pattern_type` - Test pattern type
- `num_patterns` - Number of patterns

### Analysis Classes

#### jtag_protocol_checker
- `check_compliance()` - Check protocol compliance
- `get_violation_report()` - Get violation report
- `get_total_violations()` - Get violation count

#### jtag_performance_monitor
- `get_current_metrics()` - Get performance metrics
- `set_throughput_threshold()` - Set throughput threshold
- `enable_trend_analysis` - Enable trend analysis

---

**Enhanced JTAG VIP User Guide v2.0** - Complete reference for professional JTAG verification.