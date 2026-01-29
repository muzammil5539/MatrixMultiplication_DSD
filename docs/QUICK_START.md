# Quick Start Guide

This guide provides quick instructions to get you up and running with the Matrix Multiplication with UART Communication project.

## ⚡ 5-Minute Quick Start

### Step 1: Clone and Explore
```bash
git clone https://github.com/muzammil5539/MatrixMultiplication_DSD.git
cd MatrixMultiplication_DSD
ls -la
```

### Step 2: Run Basic Simulation (Icarus Verilog)
```bash
# Compile matrix multiplication module and testbench
iverilog -o matrix_sim \
  src/matrix_multiplication/matrix_multiplication.v \
  testbench/matrix_multiplication_tb.v

# Run simulation
vvp matrix_sim

# You should see matrix multiplication results
```

### Step 3: View Results
The testbench will display the result matrix in the console output.

## 📝 Common Tasks

### Simulating Matrix Multiplication

**Using Icarus Verilog:**
```bash
iverilog -o sim src/matrix_multiplication/matrix_multiplication.v testbench/matrix_multiplication_tb.v
vvp sim
```

**Using ModelSim:**
```bash
vlib work
vlog src/matrix_multiplication/matrix_multiplication.v
vlog testbench/matrix_multiplication_tb.v
vsim -c tb_MatrixMultiplication -do "run -all; quit"
```

### Simulating UART Modules

**Compile all UART files:**
```bash
iverilog -o uart_sim \
  src/uart/baud_rate_generator.v \
  src/uart/uart_receiver.v \
  src/uart/uart_transmitter.v \
  src/uart/uart_top.v \
  src/common/pulse_generator.v
```

### Creating Custom Test

1. Copy the existing testbench:
```bash
cp testbench/matrix_multiplication_tb.v testbench/my_test_tb.v
```

2. Edit test matrices in the testbench:
```verilog
// Example: Test identity matrix
A_flat = {8'd1, 8'd0, 8'd0, 8'd0, 8'd1, 8'd0, 8'd0, 8'd0, 8'd1};
B_flat = {8'd5, 8'd6, 8'd7, 8'd8, 8'd9, 8'd10, 8'd11, 8'd12, 8'd13};
```

3. Run your custom test:
```bash
iverilog -o my_sim src/matrix_multiplication/matrix_multiplication.v testbench/my_test_tb.v
vvp my_sim
```

## 🔧 Xilinx ISE Workflow

### Creating a New Project

1. **Launch ISE Design Suite**
   ```bash
   ise
   ```

2. **Create New Project**
   - File → New Project
   - Name: `MatrixMultiplication_Project`
   - Location: Your preferred directory
   - Top-level source type: HDL

3. **Select Device**
   - Family: Spartan-6 (or your target)
   - Device: XC6SLX45
   - Package: CSG324
   - Speed: -3

4. **Add Source Files**
   - Project → Add Source
   - Navigate to `src/` directory
   - Select all `.v` files
   - Add constraint file from `constraints/`

5. **Set Top Module**
   - For simulation: `tb_MatrixMultiplication`
   - For synthesis: `MatrixMultiplication` or `UART_Top_Original`

6. **Run Simulation**
   - Double-click "Simulate Behavioral Model"
   - View waveforms in ISim

7. **Synthesize Design**
   - Double-click "Synthesize - XST"
   - Check for errors/warnings

8. **Implement Design**
   - Double-click "Implement Design"
   - Run Translate → Map → Place & Route

9. **Generate Bitstream**
   - Double-click "Generate Programming File"
   - Wait for `.bit` file creation

10. **Program FPGA**
    - Tools → iMPACT
    - Initialize chain
    - Assign configuration file
    - Program device

## 🎯 Vivado Workflow

### Quick TCL Script Method

Create a file `build.tcl`:
```tcl
# Create project
create_project matrix_mult_proj ./vivado_project -part xc7a35tcpg236-1

# Add source files
add_files [glob src/matrix_multiplication/*.v]
add_files [glob src/uart/*.v]
add_files [glob src/common/*.v]
add_files -fileset sim_1 [glob testbench/*.v]
add_files -fileset constrs_1 [glob constraints/*.ucf]

# Set top module
set_property top MatrixMultiplication [current_fileset]

# Run synthesis
launch_runs synth_1
wait_on_run synth_1

# Run implementation
launch_runs impl_1
wait_on_run impl_1

# Generate bitstream
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1
```

Run with:
```bash
vivado -mode batch -source build.tcl
```

### GUI Method

1. **Launch Vivado**
   ```bash
   vivado
   ```

2. **Create Project**
   - File → Project → New
   - Follow project wizard
   - Select FPGA part

3. **Add Sources**
   - Add files from `src/`, `testbench/`, `constraints/`

4. **Run Simulation**
   - Flow → Run Simulation → Run Behavioral Simulation

5. **Run Synthesis/Implementation**
   - Flow → Run Synthesis
   - Flow → Run Implementation
   - Flow → Generate Bitstream

6. **Program Device**
   - Flow → Open Hardware Manager
   - Open Target → Auto Connect
   - Program Device

## 🧪 Testing Examples

### Example 1: Identity Matrix Test
```verilog
// Matrix A (Identity)
// [1 0 0]
// [0 1 0]
// [0 0 1]
A_flat = {8'd1, 8'd0, 8'd0, 8'd0, 8'd1, 8'd0, 8'd0, 8'd0, 8'd1};

// Matrix B (Any matrix)
// [1 2 3]
// [4 5 6]
// [7 8 9]
B_flat = {8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8, 8'd9};

// Expected Result: B (since A * B = B when A is identity)
// [1 2 3]
// [4 5 6]
// [7 8 9]
```

### Example 2: Zero Matrix Test
```verilog
// Matrix A (Zeros)
A_flat = 72'h0;

// Matrix B (Any matrix)
B_flat = {8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8, 8'd9};

// Expected Result: Zero matrix
// [0 0 0]
// [0 0 0]
// [0 0 0]
```

### Example 3: Known Result Test
```verilog
// Matrix A
// [1 2 3]
// [4 5 6]
// [7 8 9]
A_flat = {8'd1, 8'd2, 8'd3, 8'd4, 8'd5, 8'd6, 8'd7, 8'd8, 8'd9};

// Matrix B
// [9 8 7]
// [6 5 4]
// [3 2 1]
B_flat = {8'd9, 8'd8, 8'd7, 8'd6, 8'd5, 8'd4, 8'd3, 8'd2, 8'd1};

// Expected Result (calculated manually or with Python):
// [30  24  18]
// [84  69  54]
// [138 114 90]
```

## 📊 Verification with Python

You can verify results using Python:

```python
import numpy as np

# Define matrices
A = np.array([[1, 2, 3],
              [4, 5, 6],
              [7, 8, 9]], dtype=np.uint8)

B = np.array([[9, 8, 7],
              [6, 5, 4],
              [3, 2, 1]], dtype=np.uint8)

# Multiply
C = np.matmul(A, B).astype(np.uint8)

# Display result
print("Result Matrix C:")
print(C)

# Flatten to check against Verilog output
C_flat = C.flatten()
print("\nFlattened (MSB to LSB):")
print(' '.join([f"{x:3d}" for x in C_flat]))
```

## 🔍 Debugging Tips

### Viewing Waveforms

**With Icarus + GTKWave:**
```verilog
// Add to testbench
initial begin
    $dumpfile("simulation.vcd");
    $dumpvars(0, tb_MatrixMultiplication);
end
```

Then view:
```bash
gtkwave simulation.vcd
```

### Common Issues

**Issue 1: "Include file not found"**
```bash
# Solution: Use -I flag to specify include path
iverilog -I./src/common -o sim src/uart/uart_receiver.v
```

**Issue 2: Simulation doesn't finish**
```verilog
// Add timeout in testbench
initial begin
    #100000 $display("Timeout!");
    $finish;
end
```

**Issue 3: Wrong results**
- Check input matrix format (MSB to LSB order)
- Verify bit widths match (8 bits per element)
- Check for overflow in multiplication

## 📈 Performance Testing

### Measure Computation Time
```verilog
initial begin
    integer start_time, end_time;
    
    start_time = $time;
    start = 1;
    #10 start = 0;
    
    wait (done);
    end_time = $time;
    
    $display("Computation took %0d ns", end_time - start_time);
end
```

### Measure Max Frequency

1. Synthesize design in ISE/Vivado
2. Check timing report
3. Look for maximum frequency

**Example**:
```
Minimum period: 8.523ns (Maximum Frequency: 117.323MHz)
```

## 🚀 Next Steps

After getting started:

1. **Read Full Documentation**:
   - [README.md](../README.md) - Complete project overview
   - [ARCHITECTURE.md](ARCHITECTURE.md) - Detailed architecture
   - [CONTRIBUTING.md](../CONTRIBUTING.md) - Contribution guidelines

2. **Experiment**:
   - Modify matrix sizes
   - Change element bit widths
   - Add new features

3. **Deploy to Hardware**:
   - Update constraint file for your board
   - Program FPGA
   - Test with UART terminal

4. **Contribute**:
   - Report bugs
   - Suggest improvements
   - Submit pull requests

## 📚 Additional Resources

### Verilog Learning
- [Verilog Tutorial](http://www.asic-world.com/verilog/veritut.html)
- [HDL Bits](https://hdlbits.01xz.net/wiki/Main_Page) - Practice exercises

### FPGA Tools
- [Xilinx ISE WebPACK](https://www.xilinx.com/products/design-tools/ise-design-suite.html)
- [Vivado Design Suite](https://www.xilinx.com/products/design-tools/vivado.html)
- [Icarus Verilog](http://iverilog.icarus.com/)

### Simulation
- [GTKWave](http://gtkwave.sourceforge.net/) - Waveform viewer
- [Verilator](https://www.veripool.org/verilator/) - Fast simulator

## ❓ Getting Help

- **Issues**: Open an issue on GitHub
- **Questions**: Check existing issues or create new one
- **Discussions**: Use GitHub Discussions for general topics

---

**Happy coding!** 🎉 If you have questions, don't hesitate to ask in the Issues section.
