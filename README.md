# Matrix Multiplication with UART Communication - Digital System Design

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![HDL: Verilog](https://img.shields.io/badge/HDL-Verilog-blue.svg)](https://en.wikipedia.org/wiki/Verilog)
[![FPGA: Xilinx](https://img.shields.io/badge/FPGA-Xilinx-red.svg)](https://www.xilinx.com/)

A hardware implementation of 3×3 matrix multiplication with UART communication interface, designed for FPGA deployment. This project demonstrates digital system design principles including finite state machines, serial communication protocols, and arithmetic operations in hardware.

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Architecture](#architecture)
- [Directory Structure](#directory-structure)
- [Prerequisites](#prerequisites)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Testing](#testing)
- [FPGA Implementation](#fpga-implementation)
- [Contributing](#contributing)
- [License](#license)

## 🔍 Overview

This project implements a hardware accelerator for 3×3 matrix multiplication using Verilog HDL. The design includes:

- **Matrix Multiplication Module**: Performs element-wise computation of two 3×3 matrices using a sequential state machine approach
- **UART Communication**: Full-duplex serial communication for data input/output at 9600 baud rate
- **Modular Design**: Separate, reusable modules for transmitter, receiver, and baud rate generation

The implementation is optimized for FPGA deployment with consideration for resource utilization and timing constraints.

## ✨ Features

- **3×3 Matrix Multiplication**: Hardware implementation supporting 8-bit matrix elements
- **UART Communication Interface**: 
  - Configurable baud rate (default: 9600 bps)
  - 8-bit data transfer
  - Start/stop bit protocol
  - Error detection and busy/done signaling
- **Synchronous Design**: All modules operate on clock edges for reliable timing
- **Parameterizable**: Clock rate and baud rate can be easily configured
- **Testbenches Included**: Comprehensive simulation files for verification

## 🏗️ Architecture

### Matrix Multiplication Module

The matrix multiplication module uses a sequential approach with three nested loops implemented as a finite state machine:

1. **IDLE State**: Waits for start signal
2. **MULT State**: Performs row-column multiplication and accumulation
3. **DONE State**: Signals completion and outputs result

**Input/Output:**
- Input: Two flattened 72-bit vectors (9 elements × 8 bits each)
- Output: One flattened 72-bit result vector
- Control: Start signal, reset, clock, and done flag

### UART Communication System

```
┌─────────────────┐
│  Baud Rate Gen  │
│  (Clock Div)    │
└────┬────────┬───┘
     │        │
     ▼        ▼
┌─────────┐ ┌──────────┐
│ TX Path │ │ RX Path  │
│ (8N1)   │ │ (8N1)    │
└─────────┘ └──────────┘
```

**Components:**
- **Baud Rate Generator**: Divides system clock to create TX and RX clock signals
- **UART Transmitter**: 8-bit serial transmitter with start/stop bits
- **UART Receiver**: 8-bit serial receiver with error detection
- **Pulse Generator**: Edge detection for control signals

## 📁 Directory Structure

```
MatrixMultiplication_DSD/
├── README.md                      # This file
├── CONTRIBUTING.md                # Contribution guidelines
├── LICENSE                        # Project license
├── .gitignore                     # Git ignore rules
│
├── src/                           # Source code directory
│   ├── matrix_multiplication/     # Matrix multiplication modules
│   │   └── matrix_multiplication.v
│   │
│   ├── uart/                      # UART communication modules
│   │   ├── uart_receiver.v
│   │   ├── uart_transmitter.v
│   │   ├── uart_top.v
│   │   └── baud_rate_generator.v
│   │
│   └── common/                    # Shared modules and headers
│       ├── pulse_generator.v
│       └── UartStates.vh
│
├── testbench/                     # Simulation testbenches
│   └── matrix_multiplication_tb.v
│
├── constraints/                   # FPGA constraint files
│   └── uart_constraints.ucf
│
└── docs/                          # Additional documentation
    └── (Future documentation files)
```

## 🔧 Prerequisites

### Software Requirements

- **FPGA Design Suite**: Xilinx ISE or Vivado Design Suite
- **Simulator**: ModelSim, Xilinx ISim, or Icarus Verilog for simulation
- **Optional**: GTKWave for waveform viewing

### Hardware Requirements (for FPGA deployment)

- Xilinx FPGA board (constraint file configured for specific board)
- UART interface (USB-to-Serial adapter or onboard UART)
- 100 MHz clock source (configurable in parameters)

## 🚀 Getting Started

### 1. Clone the Repository

```bash
git clone https://github.com/muzammil5539/MatrixMultiplication_DSD.git
cd MatrixMultiplication_DSD
```

### 2. Set Up Your Development Environment

**For Xilinx ISE:**
```bash
# Source ISE settings
source /opt/Xilinx/14.7/ISE_DS/settings64.sh
```

**For Vivado:**
```bash
# Source Vivado settings
source /opt/Xilinx/Vivado/2023.2/settings64.sh
```

### 3. Project Setup

**Option A: Command Line Simulation (Icarus Verilog)**

```bash
# Compile the design
iverilog -o matrix_sim \
  src/matrix_multiplication/matrix_multiplication.v \
  testbench/matrix_multiplication_tb.v

# Run simulation
vvp matrix_sim

# View waveform (if $dumpfile used in testbench)
gtkwave dump.vcd
```

**Option B: Xilinx ISE Project**

1. Create a new ISE project
2. Add all source files from `src/` directory
3. Add testbench files from `testbench/` directory
4. Add constraint file from `constraints/` directory
5. Set top module appropriately for synthesis or simulation

## 💻 Usage

### Matrix Multiplication Module

```verilog
// Instantiation example
MatrixMultiplication mult_inst (
    .clk(clk),              // System clock
    .reset(reset),          // Active high reset
    .start(start_sig),      // Start computation
    .A_flat(matrix_A),      // 72-bit flattened matrix A
    .B_flat(matrix_B),      // 72-bit flattened matrix B
    .C_flat(result),        // 72-bit flattened result matrix C
    .done(done_flag)        // Computation complete flag
);

// Matrix format: [A00, A01, A02, A10, A11, A12, A20, A21, A22]
// Each element is 8 bits
```

### UART Top Module

```verilog
// Instantiation example
UART_Top_Original uart_inst (
    .clk(clk_100MHz),       // 100 MHz clock
    .reset(reset),          // Active high reset
    .start_tx(tx_start),    // Start transmission
    .tx_data(data_to_send), // 8-bit data to transmit
    .rx_in(uart_rx_pin),    // Serial input
    .tx_out(uart_tx_pin),   // Serial output
    .rx_data(received_data),// 8-bit received data
    .rx_done(rx_complete),  // Reception complete
    .rx_busy(rx_in_prog),   // Reception in progress
    .rx_error(rx_err),      // Reception error
    .tx_done(tx_complete),  // Transmission complete
    .tx_busy(tx_in_prog)    // Transmission in progress
);
```

### Configuration Parameters

Modify these parameters in the UART modules as needed:

```verilog
parameter CLOCK_RATE = 100000000;  // 100 MHz system clock
parameter BAUD_RATE = 9600;         // UART baud rate
```

## 🧪 Testing

### Running Simulations

The project includes testbenches for verification:

**Matrix Multiplication Test:**
```bash
# Navigate to project directory
cd MatrixMultiplication_DSD

# Compile and simulate
iverilog -o test_matrix \
  src/matrix_multiplication/matrix_multiplication.v \
  testbench/matrix_multiplication_tb.v

vvp test_matrix
```

The testbench performs a sample 3×3 matrix multiplication and displays the results.

### Expected Test Output

```
Matrix C_flat:
  30  24  18
  84  69  54
 138 114  90
```

### Creating Custom Tests

1. Modify the testbench file in `testbench/` directory
2. Change input matrices `A_flat` and `B_flat`
3. Run simulation and verify output

## 🔌 FPGA Implementation

### Synthesis and Implementation Steps

1. **Open Your FPGA Tool**: Launch Xilinx ISE or Vivado

2. **Create/Open Project**: Set up project with correct FPGA part number

3. **Add Source Files**: 
   - Add all Verilog files from `src/` directory
   - Set the appropriate top module (e.g., `UART_Top_Original` or `MatrixMultiplication`)

4. **Add Constraints**: 
   - Add the UCF file from `constraints/` directory
   - Modify pin assignments to match your FPGA board

5. **Synthesize Design**:
   ```bash
   # Command line (ISE)
   xst -intstyle ise -ifn project.xst -ofn project.syr
   ```

6. **Implement Design**:
   - Run translate, map, and place & route
   
7. **Generate Bitstream**:
   - Create .bit file for programming

8. **Program FPGA**:
   - Use iMPACT (ISE) or Hardware Manager (Vivado)
   - Load bitstream to FPGA

### Pin Configuration

The constraint file (`constraints/uart_constraints.ucf`) contains pin mappings. Update these to match your specific FPGA board:

- Clock input (default: V10)
- Reset signal (default: B8)
- UART TX/RX pins (default: N18/N17)
- Data input/output pins
- Control signals

## 🤝 Contributing

We welcome contributions to improve this project! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for detailed guidelines.

### Quick Start for Contributors

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Make your changes
4. Test thoroughly
5. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
6. Push to the branch (`git push origin feature/AmazingFeature`)
7. Open a Pull Request

### Areas for Contribution

- Additional testbenches and verification
- Support for larger matrix sizes
- Different communication protocols (SPI, I2C)
- Optimization for resource utilization
- Documentation improvements
- Example applications

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📧 Contact

Project Maintainer: muzammil5539

Project Link: [https://github.com/muzammil5539/MatrixMultiplication_DSD](https://github.com/muzammil5539/MatrixMultiplication_DSD)

## 🙏 Acknowledgments

- Digital System Design course materials
- Verilog HDL community and resources
- Open-source FPGA development tools

---

**Note**: This is an educational project demonstrating hardware design concepts. For production use, additional verification, optimization, and error handling may be required.