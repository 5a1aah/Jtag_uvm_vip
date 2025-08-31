`ifndef JTAG_VIRTUAL_SEQUENCER__SVH
 `define JTAG_VIRTUAL_SEQUENCER__SVH

//=============================================================================
// JTAG Virtual Sequencer
// Coordinates multiple sequences and provides high-level test orchestration
//=============================================================================

class jtag_virtual_sequencer extends uvm_sequencer;
  
  // Reference to the main JTAG sequencer
  jtag_sequencer jtag_seqr;
  
  // Configuration objects
  jtag_protocol_config protocol_cfg;
  jtag_timing_config timing_cfg;
  jtag_error_config error_cfg;
  jtag_coverage_config coverage_cfg;
  jtag_performance_config performance_cfg;
  
  // Virtual sequencer configuration
  typedef struct {
    bit enable_parallel_sequences;
    bit enable_sequence_coordination;
    bit enable_error_injection_control;
    bit enable_coverage_driven_testing;
    bit enable_performance_monitoring;
    int unsigned max_parallel_sequences;
    time sequence_timeout;
    time coordination_delay;
  } virtual_sequencer_config_t;
  
  virtual_sequencer_config_t vseq_cfg;
  
  // Sequence coordination and control
  typedef struct {
    string sequence_name;
    uvm_sequence_base sequence_handle;
    bit is_running;
    bit is_completed;
    bit has_error;
    time start_time;
    time end_time;
    int unsigned priority;
  } sequence_info_t;
  
  sequence_info_t active_sequences[$];
  sequence_info_t completed_sequences[$];
  
  // Synchronization events
  event sequence_started;
  event sequence_completed;
  event all_sequences_done;
  event error_detected;
  event coordination_point;
  
  // Statistics and monitoring
  int unsigned total_sequences_started;
  int unsigned total_sequences_completed;
  int unsigned total_sequences_failed;
  int unsigned max_concurrent_sequences;
  time total_execution_time;
  
  // Error injection control
  typedef struct {
    bit enable_injection;
    string target_sequence;
    string error_type;
    int unsigned injection_count;
    time injection_interval;
  } error_injection_control_t;
  
  error_injection_control_t error_injection_ctrl;
  
  // Coverage-driven testing control
  typedef struct {
    bit enable_coverage_feedback;
    real target_coverage;
    real current_coverage;
    string focus_areas[$];
    int unsigned max_iterations;
  } coverage_control_t;
  
  coverage_control_t coverage_ctrl;
  
  `uvm_component_utils_begin(jtag_virtual_sequencer)
  `uvm_field_int(total_sequences_started, UVM_DEFAULT)
  `uvm_field_int(total_sequences_completed, UVM_DEFAULT)
  `uvm_field_int(total_sequences_failed, UVM_DEFAULT)
  `uvm_component_utils_end
  
  //=============================================================================
  // Constructor and Build Phase
  //=============================================================================
  
  function new(string name = "jtag_virtual_sequencer", uvm_component parent = null);
    super.new(name, parent);
    
    // Initialize virtual sequencer configuration
    initialize_vseq_config();
    
    // Initialize error injection control
    initialize_error_injection_control();
    
    // Initialize coverage control
    initialize_coverage_control();
    
    // Initialize statistics
    total_sequences_started = 0;
    total_sequences_completed = 0;
    total_sequences_failed = 0;
    max_concurrent_sequences = 0;
    total_execution_time = 0;
    
  endfunction
  
  virtual function void build_phase(uvm_phase phase);
    super.build_phase(phase);
    
    // Get configuration objects
    if(!uvm_config_db#(jtag_protocol_config)::get(this, "", "protocol_cfg", protocol_cfg)) begin
      `uvm_info("JTAG_VSEQ_INFO", "Creating default protocol configuration", UVM_LOW)
      protocol_cfg = jtag_protocol_config::type_id::create("protocol_cfg");
    end
    
    if(!uvm_config_db#(jtag_timing_config)::get(this, "", "timing_cfg", timing_cfg)) begin
      `uvm_info("JTAG_VSEQ_INFO", "Creating default timing configuration", UVM_LOW)
      timing_cfg = jtag_timing_config::type_id::create("timing_cfg");
    end
    
    if(!uvm_config_db#(jtag_error_config)::get(this, "", "error_cfg", error_cfg)) begin
      `uvm_info("JTAG_VSEQ_INFO", "Creating default error configuration", UVM_LOW)
      error_cfg = jtag_error_config::type_id::create("error_cfg");
    end
    
    if(!uvm_config_db#(jtag_coverage_config)::get(this, "", "coverage_cfg", coverage_cfg)) begin
      `uvm_info("JTAG_VSEQ_INFO", "Creating default coverage configuration", UVM_LOW)
      coverage_cfg = jtag_coverage_config::type_id::create("coverage_cfg");
    end
    
    if(!uvm_config_db#(jtag_performance_config)::get(this, "", "performance_cfg", performance_cfg)) begin
      `uvm_info("JTAG_VSEQ_INFO", "Creating default performance configuration", UVM_LOW)
      performance_cfg = jtag_performance_config::type_id::create("performance_cfg");
    end
    
  endfunction
  
  virtual function void initialize_vseq_config();
    vseq_cfg.enable_parallel_sequences = 1;
    vseq_cfg.enable_sequence_coordination = 1;
    vseq_cfg.enable_error_injection_control = 1;
    vseq_cfg.enable_coverage_driven_testing = 1;
    vseq_cfg.enable_performance_monitoring = 1;
    vseq_cfg.max_parallel_sequences = 4;
    vseq_cfg.sequence_timeout = 10ms;
    vseq_cfg.coordination_delay = 100ns;
  endfunction
  
  virtual function void initialize_error_injection_control();
    error_injection_ctrl.enable_injection = 0;
    error_injection_ctrl.target_sequence = "";
    error_injection_ctrl.error_type = "random";
    error_injection_ctrl.injection_count = 0;
    error_injection_ctrl.injection_interval = 1us;
  endfunction
  
  virtual function void initialize_coverage_control();
    coverage_ctrl.enable_coverage_feedback = 1;
    coverage_ctrl.target_coverage = 95.0;
    coverage_ctrl.current_coverage = 0.0;
    coverage_ctrl.focus_areas.delete();
    coverage_ctrl.max_iterations = 1000;
  endfunction
  
  //=============================================================================
  // Sequence Management and Coordination
  //=============================================================================
  
  virtual task start_sequence(uvm_sequence_base seq, string seq_name = "", int unsigned priority = 100);
    sequence_info_t seq_info;
    
    // Check if we can start another sequence
    if (vseq_cfg.enable_parallel_sequences && active_sequences.size() >= vseq_cfg.max_parallel_sequences) begin
      `uvm_warning("JTAG_VSEQ_WARN", $sformatf("Maximum parallel sequences (%0d) reached. Waiting for completion.", 
                                               vseq_cfg.max_parallel_sequences))
      wait_for_sequence_completion();
    end
    
    // Create sequence info
    seq_info.sequence_name = (seq_name != "") ? seq_name : seq.get_type_name();
    seq_info.sequence_handle = seq;
    seq_info.is_running = 1;
    seq_info.is_completed = 0;
    seq_info.has_error = 0;
    seq_info.start_time = $time;
    seq_info.priority = priority;
    
    // Add to active sequences
    active_sequences.push_back(seq_info);
    
    // Update statistics
    total_sequences_started++;
    if (active_sequences.size() > max_concurrent_sequences) begin
      max_concurrent_sequences = active_sequences.size();
    end
    
    `uvm_info("JTAG_VSEQ_START", $sformatf("Starting sequence '%s' (Priority: %0d, Active: %0d)", 
                                          seq_info.sequence_name, priority, active_sequences.size()), UVM_MEDIUM)
    
    // Start the sequence
    fork
      begin
        fork
          begin
            // Start sequence with timeout
            fork
              seq.start(jtag_seqr);
              begin
                #(vseq_cfg.sequence_timeout);
                `uvm_error("JTAG_VSEQ_TIMEOUT", $sformatf("Sequence '%s' timed out after %0t", 
                                                          seq_info.sequence_name, vseq_cfg.sequence_timeout))
                seq_info.has_error = 1;
              end
            join_any
            disable fork;
            
            // Mark sequence as completed
            mark_sequence_completed(seq_info.sequence_name, !seq_info.has_error);
          end
        join
      end
    join_none
    
    // Trigger sequence started event
    -> sequence_started;
    
  endtask
  
  virtual function void mark_sequence_completed(string seq_name, bit success);
    sequence_info_t seq_info;
    int seq_index = -1;
    
    // Find the sequence in active list
    for (int i = 0; i < active_sequences.size(); i++) begin
      if (active_sequences[i].sequence_name == seq_name) begin
        seq_info = active_sequences[i];
        seq_index = i;
        break;
      end
    end
    
    if (seq_index >= 0) begin
      // Update sequence info
      seq_info.is_running = 0;
      seq_info.is_completed = 1;
      seq_info.has_error = !success;
      seq_info.end_time = $time;
      
      // Move to completed list
      completed_sequences.push_back(seq_info);
      active_sequences.delete(seq_index);
      
      // Update statistics
      if (success) begin
        total_sequences_completed++;
      end else begin
        total_sequences_failed++;
      end
      
      total_execution_time += (seq_info.end_time - seq_info.start_time);
      
      `uvm_info("JTAG_VSEQ_COMPLETE", $sformatf("Sequence '%s' completed %s (Duration: %0t, Active: %0d)", 
                                                seq_name, success ? "successfully" : "with errors", 
                                                (seq_info.end_time - seq_info.start_time), active_sequences.size()), UVM_MEDIUM)
      
      // Trigger events
      -> sequence_completed;
      if (active_sequences.size() == 0) begin
        -> all_sequences_done;
      end
      
      if (!success) begin
        -> error_detected;
      end
    end else begin
      `uvm_warning("JTAG_VSEQ_WARN", $sformatf("Sequence '%s' not found in active list", seq_name))
    end
    
  endfunction
  
  virtual task wait_for_sequence_completion(string seq_name = "");
    if (seq_name == "") begin
      // Wait for any sequence to complete
      if (active_sequences.size() > 0) begin
        @(sequence_completed);
      end
    end else begin
      // Wait for specific sequence to complete
      while (is_sequence_active(seq_name)) begin
        @(sequence_completed);
      end
    end
  endtask
  
  virtual task wait_for_all_sequences();
    if (active_sequences.size() > 0) begin
      @(all_sequences_done);
    end
  endtask
  
  virtual function bit is_sequence_active(string seq_name);
    foreach (active_sequences[i]) begin
      if (active_sequences[i].sequence_name == seq_name) begin
        return 1;
      end
    end
    return 0;
  endfunction
  
  //=============================================================================
  // Parallel Sequence Execution
  //=============================================================================
  
  virtual task run_parallel_sequences(uvm_sequence_base sequences[], string seq_names[] = {}, int unsigned priorities[] = {});
    int num_sequences = sequences.size();
    
    `uvm_info("JTAG_VSEQ_PARALLEL", $sformatf("Starting %0d parallel sequences", num_sequences), UVM_LOW)
    
    // Start all sequences
    for (int i = 0; i < num_sequences; i++) begin
      string name = (seq_names.size() > i) ? seq_names[i] : $sformatf("parallel_seq_%0d", i);
      int unsigned priority = (priorities.size() > i) ? priorities[i] : 100;
      
      start_sequence(sequences[i], name, priority);
      
      // Add coordination delay if enabled
      if (vseq_cfg.enable_sequence_coordination) begin
        #(vseq_cfg.coordination_delay);
      end
    end
    
    // Wait for all sequences to complete
    wait_for_all_sequences();
    
    `uvm_info("JTAG_VSEQ_PARALLEL", "All parallel sequences completed", UVM_LOW)
    
  endtask
  
  virtual task run_sequential_sequences(uvm_sequence_base sequences[], string seq_names[] = {}, int unsigned priorities[] = {});
    int num_sequences = sequences.size();
    
    `uvm_info("JTAG_VSEQ_SEQUENTIAL", $sformatf("Starting %0d sequential sequences", num_sequences), UVM_LOW)
    
    // Start sequences one by one
    for (int i = 0; i < num_sequences; i++) begin
      string name = (seq_names.size() > i) ? seq_names[i] : $sformatf("sequential_seq_%0d", i);
      int unsigned priority = (priorities.size() > i) ? priorities[i] : 100;
      
      start_sequence(sequences[i], name, priority);
      wait_for_sequence_completion(name);
      
      // Add coordination delay if enabled
      if (vseq_cfg.enable_sequence_coordination) begin
        #(vseq_cfg.coordination_delay);
      end
    end
    
    `uvm_info("JTAG_VSEQ_SEQUENTIAL", "All sequential sequences completed", UVM_LOW)
    
  endtask
  
  //=============================================================================
  // Error Injection Control
  //=============================================================================
  
  virtual function void configure_error_injection(string target_seq, string error_type, int unsigned count, time interval);
    error_injection_ctrl.enable_injection = 1;
    error_injection_ctrl.target_sequence = target_seq;
    error_injection_ctrl.error_type = error_type;
    error_injection_ctrl.injection_count = count;
    error_injection_ctrl.injection_interval = interval;
    
    `uvm_info("JTAG_VSEQ_ERROR_INJ", $sformatf("Error injection configured: Target='%s', Type='%s', Count=%0d, Interval=%0t", 
                                              target_seq, error_type, count, interval), UVM_LOW)
  endfunction
  
  virtual function void enable_error_injection(bit enable);
    error_injection_ctrl.enable_injection = enable;
    `uvm_info("JTAG_VSEQ_ERROR_INJ", $sformatf("Error injection %s", enable ? "enabled" : "disabled"), UVM_LOW)
  endfunction
  
  virtual task inject_errors_during_sequence(string seq_name);
    if (!error_injection_ctrl.enable_injection) return;
    
    if (error_injection_ctrl.target_sequence == "" || error_injection_ctrl.target_sequence == seq_name) begin
      fork
        begin
          for (int i = 0; i < error_injection_ctrl.injection_count && is_sequence_active(seq_name); i++) begin
            #(error_injection_ctrl.injection_interval);
            
            // Trigger error injection (this would interface with error injector component)
            `uvm_info("JTAG_VSEQ_ERROR_INJ", $sformatf("Injecting error %0d/%0d during sequence '%s'", 
                                                        i+1, error_injection_ctrl.injection_count, seq_name), UVM_MEDIUM)
            
            // Here you would interface with the error injector component
            // For example: error_injector.inject_error(error_injection_ctrl.error_type);
          end
        end
      join_none
    end
  endtask
  
  //=============================================================================
  // Coverage-Driven Testing
  //=============================================================================
  
  virtual function void configure_coverage_driven_testing(real target_coverage, string focus_areas[], int unsigned max_iterations);
    coverage_ctrl.enable_coverage_feedback = 1;
    coverage_ctrl.target_coverage = target_coverage;
    coverage_ctrl.focus_areas = focus_areas;
    coverage_ctrl.max_iterations = max_iterations;
    
    `uvm_info("JTAG_VSEQ_COV_DRIVEN", $sformatf("Coverage-driven testing configured: Target=%0.2f%%, Max Iterations=%0d", 
                                                target_coverage, max_iterations), UVM_LOW)
  endfunction
  
  virtual function void update_coverage_feedback(real current_coverage);
    coverage_ctrl.current_coverage = current_coverage;
    
    `uvm_info("JTAG_VSEQ_COV_UPDATE", $sformatf("Coverage updated: %0.2f%% (Target: %0.2f%%)", 
                                                current_coverage, coverage_ctrl.target_coverage), UVM_HIGH)
  endfunction
  
  virtual function bit is_coverage_target_met();
    return (coverage_ctrl.current_coverage >= coverage_ctrl.target_coverage);
  endfunction
  
  virtual task run_coverage_driven_test(uvm_sequence_base base_sequences[]);
    int iteration = 0;
    
    `uvm_info("JTAG_VSEQ_COV_DRIVEN", "Starting coverage-driven test", UVM_LOW)
    
    while (!is_coverage_target_met() && iteration < coverage_ctrl.max_iterations) begin
      iteration++;
      
      `uvm_info("JTAG_VSEQ_COV_DRIVEN", $sformatf("Coverage iteration %0d/%0d (Current: %0.2f%%, Target: %0.2f%%)", 
                                                  iteration, coverage_ctrl.max_iterations, 
                                                  coverage_ctrl.current_coverage, coverage_ctrl.target_coverage), UVM_MEDIUM)
      
      // Select and run sequences based on coverage feedback
      select_and_run_coverage_sequences(base_sequences);
      
      // Wait for sequences to complete
      wait_for_all_sequences();
      
      // Small delay to allow coverage update
      #1us;
    end
    
    if (is_coverage_target_met()) begin
      `uvm_info("JTAG_VSEQ_COV_DRIVEN", $sformatf("Coverage target achieved in %0d iterations: %0.2f%%", 
                                                  iteration, coverage_ctrl.current_coverage), UVM_LOW)
    end else begin
      `uvm_warning("JTAG_VSEQ_COV_DRIVEN", $sformatf("Coverage target not met after %0d iterations: %0.2f%% (Target: %0.2f%%)", 
                                                     iteration, coverage_ctrl.current_coverage, coverage_ctrl.target_coverage))
    end
    
  endtask
  
  virtual task select_and_run_coverage_sequences(uvm_sequence_base base_sequences[]);
    // This is a simplified implementation
    // In a real implementation, you would analyze coverage holes and select appropriate sequences
    
    int selected_index = $urandom_range(0, base_sequences.size()-1);
    string seq_name = $sformatf("coverage_driven_seq_%0d", selected_index);
    
    start_sequence(base_sequences[selected_index], seq_name);
    
  endtask
  
  //=============================================================================
  // Coordination and Synchronization
  //=============================================================================
  
  virtual task coordinate_sequences(string coordination_point_name);
    if (!vseq_cfg.enable_sequence_coordination) return;
    
    `uvm_info("JTAG_VSEQ_COORD", $sformatf("Coordination point '%s' reached", coordination_point_name), UVM_MEDIUM)
    
    // Wait for coordination delay
    #(vseq_cfg.coordination_delay);
    
    // Trigger coordination event
    -> coordination_point;
    
  endtask
  
  virtual task wait_for_coordination_point();
    @(coordination_point);
  endtask
  
  virtual task synchronize_sequences(string sync_point_name, int expected_sequences);
    int synchronized_count = 0;
    
    `uvm_info("JTAG_VSEQ_SYNC", $sformatf("Synchronization point '%s' - waiting for %0d sequences", 
                                         sync_point_name, expected_sequences), UVM_MEDIUM)
    
    // This is a simplified synchronization mechanism
    // In a real implementation, you would have more sophisticated synchronization
    
    while (synchronized_count < expected_sequences) begin
      @(coordination_point);
      synchronized_count++;
    end
    
    `uvm_info("JTAG_VSEQ_SYNC", $sformatf("Synchronization point '%s' completed", sync_point_name), UVM_MEDIUM)
    
  endtask
  
  //=============================================================================
  // Configuration and Control
  //=============================================================================
  
  virtual function void set_max_parallel_sequences(int unsigned max_sequences);
    vseq_cfg.max_parallel_sequences = max_sequences;
    `uvm_info("JTAG_VSEQ_CONFIG", $sformatf("Maximum parallel sequences set to %0d", max_sequences), UVM_LOW)
  endfunction
  
  virtual function void set_sequence_timeout(time timeout);
    vseq_cfg.sequence_timeout = timeout;
    `uvm_info("JTAG_VSEQ_CONFIG", $sformatf("Sequence timeout set to %0t", timeout), UVM_LOW)
  endfunction
  
  virtual function void enable_parallel_execution(bit enable);
    vseq_cfg.enable_parallel_sequences = enable;
    `uvm_info("JTAG_VSEQ_CONFIG", $sformatf("Parallel sequence execution %s", enable ? "enabled" : "disabled"), UVM_LOW)
  endfunction
  
  virtual function void enable_coordination(bit enable);
    vseq_cfg.enable_sequence_coordination = enable;
    `uvm_info("JTAG_VSEQ_CONFIG", $sformatf("Sequence coordination %s", enable ? "enabled" : "disabled"), UVM_LOW)
  endfunction
  
  //=============================================================================
  // Information and Statistics
  //=============================================================================
  
  virtual function int unsigned get_active_sequence_count();
    return active_sequences.size();
  endfunction
  
  virtual function int unsigned get_completed_sequence_count();
    return completed_sequences.size();
  endfunction
  
  virtual function real get_success_rate();
    int total = total_sequences_completed + total_sequences_failed;
    if (total > 0) begin
      return (real'(total_sequences_completed) / real'(total)) * 100.0;
    end else begin
      return 100.0;
    end
  endfunction
  
  virtual function time get_average_execution_time();
    if (total_sequences_completed > 0) begin
      return total_execution_time / total_sequences_completed;
    end else begin
      return 0;
    end
  endfunction
  
  virtual function void print_statistics();
    `uvm_info("JTAG_VSEQ_STATS", "=== Virtual Sequencer Statistics ===", UVM_LOW)
    `uvm_info("JTAG_VSEQ_STATS", $sformatf("Total Sequences Started: %0d", total_sequences_started), UVM_LOW)
    `uvm_info("JTAG_VSEQ_STATS", $sformatf("Total Sequences Completed: %0d", total_sequences_completed), UVM_LOW)
    `uvm_info("JTAG_VSEQ_STATS", $sformatf("Total Sequences Failed: %0d", total_sequences_failed), UVM_LOW)
    `uvm_info("JTAG_VSEQ_STATS", $sformatf("Success Rate: %0.2f%%", get_success_rate()), UVM_LOW)
    `uvm_info("JTAG_VSEQ_STATS", $sformatf("Active Sequences: %0d", active_sequences.size()), UVM_LOW)
    `uvm_info("JTAG_VSEQ_STATS", $sformatf("Max Concurrent Sequences: %0d", max_concurrent_sequences), UVM_LOW)
    `uvm_info("JTAG_VSEQ_STATS", $sformatf("Average Execution Time: %0t", get_average_execution_time()), UVM_LOW)
    `uvm_info("JTAG_VSEQ_STATS", $sformatf("Total Execution Time: %0t", total_execution_time), UVM_LOW)
    `uvm_info("JTAG_VSEQ_STATS", "=== End of Statistics ===", UVM_LOW)
  endfunction
  
  virtual function void print_active_sequences();
    `uvm_info("JTAG_VSEQ_ACTIVE", $sformatf("=== Active Sequences (%0d) ===", active_sequences.size()), UVM_LOW)
    foreach (active_sequences[i]) begin
      time elapsed = $time - active_sequences[i].start_time;
      `uvm_info("JTAG_VSEQ_ACTIVE", $sformatf("[%0d] %s (Priority: %0d, Elapsed: %0t)", 
                                              i, active_sequences[i].sequence_name, 
                                              active_sequences[i].priority, elapsed), UVM_LOW)
    end
    `uvm_info("JTAG_VSEQ_ACTIVE", "=== End of Active Sequences ===", UVM_LOW)
  endfunction
  
  //=============================================================================
  // Phase Management
  //=============================================================================
  
  virtual function void extract_phase(uvm_phase phase);
    super.extract_phase(phase);
    
    // Print final statistics
    print_statistics();
    
    // Print any remaining active sequences
    if (active_sequences.size() > 0) begin
      `uvm_warning("JTAG_VSEQ_EXTRACT", $sformatf("%0d sequences still active at end of test", active_sequences.size()))
      print_active_sequences();
    end
    
  endfunction
  
endclass // jtag_virtual_sequencer

`