# Enhanced JTAG VIP (Verification IP)

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)
[![SystemVerilog](https://img.shields.io/badge/SystemVerilog-IEEE1800-orange.svg)]
[![UVM](https://img.shields.io/badge/UVM-1.2-red.svg)]

A comprehensive, production-ready JTAG (IEEE 1149.1/1149.4/1149.6) Verification IP built with SystemVerilog and UVM. This enhanced VIP provides advanced verification capabilities including protocol compliance checking, comprehensive coverage collection, performance monitoring, error injection, and debug access features.

## 🚀 Key Features

### Core JTAG Functionality
- **IEEE Standards Compliance**: Full support for IEEE 1149.1, 1149.4, and 1149.6 standards
- **Complete TAP Controller**: All 16 TAP states with proper state machine implementation
- **Instruction Support**: IDCODE, BYPASS, SAMPLE/PRELOAD, EXTEST, INTEST, and custom instructions
- **Boundary Scan**: Comprehensive boundary scan test capabilities
- **Debug Access**: Advanced debug register and memory access features

### Advanced Verification Features
- **Protocol Compliance Checker**: Real-time protocol violation detection and reporting
- **Timing Validation**: Setup/hold time checking and clock domain validation
- **Comprehensive Coverage**: Functional, instruction, state, and protocol coverage
- **Performance Monitoring**: Throughput, latency, and bandwidth analysis
- **Error Injection Framework**: Systematic error testing with configurable error types
- **Debug Dashboard**: Real-time monitoring and analysis capabilities

### Enhanced Components
- **Configurable Agent**: Multiple operating modes and protocol variants
- **Advanced Sequences**: Pre-built test sequences for common scenarios
- **Smart Monitor**: Protocol-aware monitoring with intelligent checking
- **Flexible Driver**: Support for various timing configurations and error injection
- **Rich Scoreboard**: Transaction-level checking with detailed mismatch analysis

## 📁 Project Structure

```
jtag_vip_uvm/
├── docs/                          # Documentation
│   ├── user_guide.md             # User guide and tutorials
│   ├── api_reference.md          # API documentation
│   └── examples.md               # Usage examples
├── examples/                      # Example tests and testbenches
│   ├── basic_test.sv             # Basic functionality test
│   ├── boundary_scan_test.sv     # Boundary scan test
│   ├── compliance_test.sv        # IEEE compliance test
│   └── integration_test.sv       # Comprehensive integration test
├── src/                          # Source package
│   └── jtag_vip_pkg.sv          # Main package file
├── sv/                           # SystemVerilog components
│   ├── jtag_if.sv               # JTAG interface
│   ├── jtag_defs.svh            # Type definitions and constants
│   ├── jtag_agent.svh           # JTAG agent
│   ├── jtag_driver.svh          # JTAG driver
│   ├── jtag_monitor.svh         # JTAG monitor
│   ├── jtag_sequencer.svh       # JTAG sequencer
│   ├── jtag_env.svh             # JTAG environment
│   ├── jtag_test_lib.svh        # Test library
│   └── sequences/               # Sequence library
│       ├── jtag_base_sequence.svh
│       ├── jtag_reset_sequence.svh
│       ├── jtag_boundary_scan_sequence.svh
│       ├── jtag_debug_sequence.svh
│       ├── jtag_error_injection_sequence.svh
│       └── jtag_compliance_sequence.svh
├── Makefile                      # Build and simulation scripts
├── README.md                     # This file
├── CHANGELOG.md                  # Version history
└── LICENSE                       # License information
```

## 🛠️ Installation and Setup

### Prerequisites

- **SystemVerilog Simulator**: Questa/ModelSim, VCS, or Xcelium
- **UVM Library**: UVM 1.2 or later
- **Make**: For build automation (optional)

### Quick Start

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd jtag_vip_uvm
   ```

2. **Compile the VIP**:
   ```bash
   # Using Questa/ModelSim
   make compile SIM=questa
   
   # Using VCS
   make compile SIM=vcs
   
   # Using Xcelium
   make compile SIM=xcelium
   ```

3. **Run basic test**:
   ```bash
   make run TEST=basic_test SIM=questa
   ```

## 📖 Usage Examples

### Basic Test Setup

```systemverilog
// Include the JTAG VIP package
import jtag_vip_pkg::*;

// Create and configure the environment
jtag_env_config env_cfg = jtag_env_config::type_id::create("env_cfg");
jtag_agent_config agent_cfg = jtag_agent_config::type_id::create("agent_cfg");

// Configure basic settings
agent_cfg.is_active = UVM_ACTIVE;
agent_cfg.enable_protocol_checking = 1;
agent_cfg.enable_coverage_collection = 1;

// Set timing parameters
agent_cfg.tck_period = 100.0; // 10MHz
agent_cfg.setup_time = 10.0;
agent_cfg.hold_time = 10.0;
```

### Running a Boundary Scan Test

```systemverilog
// Create boundary scan sequence
jtag_boundary_scan_sequence boundary_seq = 
    jtag_boundary_scan_sequence::type_id::create("boundary_seq");

// Configure the test
boundary_seq.instruction = EXTEST;
boundary_seq.test_pattern = WALKING_ONES;
boundary_seq.boundary_length = 256;

// Execute the sequence
boundary_seq.start(env.agent.sequencer);
```

### Error Injection Testing

```systemverilog
// Enable error injection
agent_cfg.enable_error_injection = 1;
agent_cfg.error_injection_mode = SYSTEMATIC;
agent_cfg.error_injection_rate = 5; // 5% error rate

// Create error injection sequence
jtag_error_injection_sequence error_seq = 
    jtag_error_injection_sequence::type_id::create("error_seq");

// Configure error type
error_seq.error_type = SINGLE_BIT_ERROR;
error_seq.error_location = 10;

// Execute the sequence
error_seq.start(env.agent.sequencer);
```

## 🧪 Available Tests

### Basic Tests
- **basic_test**: Fundamental JTAG operations (IDCODE, BYPASS)
- **reset_test**: TAP controller reset functionality
- **instruction_test**: Instruction register operations

### Advanced Tests
- **boundary_scan_test**: EXTEST, INTEST, SAMPLE/PRELOAD operations
- **debug_test**: Debug register and memory access
- **error_injection_test**: Systematic error testing
- **compliance_test**: IEEE standard compliance verification
- **performance_test**: Throughput and timing analysis
- **stress_test**: High-frequency and long-duration testing

### Running Tests

```bash
# Run specific test
make run TEST=boundary_scan_test SIM=questa

# Run with specific IEEE standard
make run TEST=compliance_test SIM=questa STANDARD=IEEE_1149_4

# Run with coverage collection
make run TEST=basic_test SIM=questa COVERAGE=1

# Run all tests (regression)
make regression SIM=questa
```

## ⚙️ Configuration Options

### Agent Configuration

```systemverilog
class jtag_agent_config extends uvm_object;
  // Basic configuration
  uvm_active_passive_enum is_active = UVM_ACTIVE;
  
  // Protocol settings
  jtag_ieee_standard_e protocol_standard = IEEE_1149_1;
  jtag_compliance_level_e compliance_level = STANDARD_COMPLIANCE;
  
  // Timing configuration
  real tck_period = 100.0;  // TCK period in ns
  real setup_time = 10.0;   // Setup time in ns
  real hold_time = 10.0;    // Hold time in ns
  
  // Feature enables
  bit enable_protocol_checking = 1;
  bit enable_timing_validation = 1;
  bit enable_coverage_collection = 1;
  bit enable_performance_monitoring = 0;
  bit enable_error_injection = 0;
  bit enable_debug_features = 0;
  
  // Coverage configuration
  bit coverage_enable_instruction = 1;
  bit coverage_enable_state = 1;
  bit coverage_enable_boundary_scan = 0;
  bit coverage_enable_debug = 0;
  bit coverage_enable_error = 0;
  
  // Error injection configuration
  jtag_error_injection_mode_e error_injection_mode = RANDOM;
  int error_injection_rate = 1; // Percentage
endclass
```

### Environment Configuration

```systemverilog
class jtag_env_config extends uvm_object;
  jtag_agent_config agent_cfg;
  virtual jtag_if vif;
  
  // Environment settings
  bit enable_scoreboard = 1;
  bit enable_coverage = 1;
  bit enable_protocol_checker = 1;
  bit enable_timing_validator = 1;
  bit enable_performance_monitor = 0;
endclass
```

## 📊 Coverage and Analysis

### Functional Coverage

The VIP provides comprehensive functional coverage including:

- **Instruction Coverage**: All supported JTAG instructions
- **State Coverage**: TAP controller state transitions
- **Protocol Coverage**: IEEE standard compliance points
- **Boundary Scan Coverage**: Test patterns and operations
- **Debug Coverage**: Register and memory access patterns
- **Error Coverage**: Error injection and recovery scenarios

### Performance Monitoring

```systemverilog
// Enable performance monitoring
agent_cfg.enable_performance_monitoring = 1;

// Access performance metrics
jtag_performance_metrics_s metrics = env.performance_monitor.get_metrics();

$display("Throughput: %0.2f Mbps", metrics.throughput_mbps);
$display("Average Latency: %0.2f ns", metrics.avg_latency_ns);
$display("Total Transactions: %0d", metrics.total_transactions);
```

## 🔧 Advanced Features

### Protocol Compliance Checking

The VIP includes a comprehensive protocol checker that validates:
- TAP state machine transitions
- Instruction register operations
- Data register operations
- Timing requirements
- IEEE standard compliance

### Error Injection Framework

Supported error types:
- Single bit errors
- Burst errors
- Timing violations
- Protocol violations
- State machine errors

### Debug Access Features

- Register read/write operations
- Memory access capabilities
- Breakpoint management
- Real-time debugging support

## 🐛 Debugging and Troubleshooting

### Common Issues

1. **Compilation Errors**:
   - Ensure UVM library is properly included
   - Check SystemVerilog simulator compatibility
   - Verify file paths in package includes

2. **Simulation Issues**:
   - Check virtual interface connections
   - Verify clock and reset signal generation
   - Ensure proper test configuration

3. **Coverage Issues**:
   - Enable coverage collection in agent configuration
   - Check coverage database generation
   - Verify coverage model compilation

### Debug Features

```systemverilog
// Enable debug logging
agent_cfg.verbosity = UVM_HIGH;

// Enable waveform dumping
make run TEST=basic_test SIM=questa WAVES=1

// Enable protocol checking debug
agent_cfg.protocol_checker_debug = 1;
```

## 🤝 Contributing

We welcome contributions! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Setup

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new features
5. Run the regression suite
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For questions, issues, or feature requests:

- **Issues**: [GitHub Issues](https://github.com/your-repo/jtag_vip_uvm/issues)
- **Discussions**: [GitHub Discussions](https://github.com/your-repo/jtag_vip_uvm/discussions)
- **Email**: support@your-domain.com

## 🙏 Acknowledgments

- IEEE Standards Association for JTAG specifications
- Accellera Systems Initiative for UVM methodology
- SystemVerilog community for best practices
- Contributors and users of this VIP

## 📈 Roadmap

### Version 2.1 (Planned)
- Enhanced IEEE 1149.7 support
- Advanced power management features
- Improved performance optimization
- Additional debug capabilities

### Version 3.0 (Future)
- SystemC/TLM integration
- Python API bindings
- Cloud-based verification support
- AI-powered test generation

---

**Enhanced JTAG VIP v2.0.0** - Production-ready verification IP for comprehensive JTAG testing and validation.