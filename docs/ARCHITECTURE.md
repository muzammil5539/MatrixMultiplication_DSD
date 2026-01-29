# Architecture Overview

This document provides a detailed overview of the system architecture and design decisions for the Matrix Multiplication with UART Communication project.

## System Block Diagram

```
┌─────────────────────────────────────────────────────────┐
│                     Top Level System                     │
├─────────────────────────────────────────────────────────┤
│                                                           │
│  ┌───────────────────────────────────────────────────┐  │
│  │          UART Communication Interface             │  │
│  ├───────────────────────────────────────────────────┤  │
│  │                                                     │  │
│  │  ┌──────────────┐      ┌──────────────┐          │  │
│  │  │ Baud Rate    │      │ Baud Rate    │          │  │
│  │  │ Generator    │──────│ Generator    │          │  │
│  │  │ (RX/TX CLK)  │      │              │          │  │
│  │  └──────┬───────┘      └──────┬───────┘          │  │
│  │         │                     │                   │  │
│  │         ▼                     ▼                   │  │
│  │  ┌──────────────┐      ┌──────────────┐          │  │
│  │  │    UART      │      │    UART      │          │  │
│  │  │  Receiver    │      │ Transmitter  │          │  │
│  │  │   (8N1)      │      │   (8N1)      │          │  │
│  │  └──────┬───────┘      └──────┬───────┘          │  │
│  │         │                     │                   │  │
│  │         │    ┌──────────┐    │                   │  │
│  │         └────┤  Pulse   │────┘                   │  │
│  │              │ Generator│                         │  │
│  │              └──────────┘                         │  │
│  └─────────────────────────────────────────────────┘  │
│                          │                             │
│                          ▼                             │
│  ┌───────────────────────────────────────────────────┐│
│  │      Matrix Multiplication Processing Unit        ││
│  ├───────────────────────────────────────────────────┤│
│  │                                                     ││
│  │  Input: 2 × 3×3 Matrices (8-bit elements)         ││
│  │  Processing: Sequential FSM-based multiplication   ││
│  │  Output: 1 × 3×3 Result Matrix (8-bit elements)   ││
│  │                                                     ││
│  └───────────────────────────────────────────────────┘│
│                                                           │
└─────────────────────────────────────────────────────────┘
```

## Design Philosophy

### 1. Modularity

The design is highly modular with clear separation of concerns:

- **Communication Layer**: UART modules handle all serial I/O
- **Processing Layer**: Matrix multiplication operates independently
- **Common Utilities**: Shared components like pulse generators

This modularity allows:
- Easy testing of individual components
- Reusability in other projects
- Independent optimization of each module

### 2. Resource Efficiency

Design choices optimized for FPGA resources:

- **Sequential Processing**: Matrix multiplication uses iterative approach rather than parallel multipliers
- **Minimal Storage**: Only necessary registers for computation state
- **Clock Domain**: Single clock domain simplifies timing

### 3. Synchronous Design

All modules use synchronous design principles:
- All state changes occur on clock edges
- Asynchronous reset for reliable initialization
- No combinational loops or latches

## Module Details

### Matrix Multiplication Module

**File**: `src/matrix_multiplication/matrix_multiplication.v`

**Purpose**: Performs 3×3 matrix multiplication using a finite state machine approach.

**Key Features**:
- **Input Format**: Flattened 72-bit vectors (9 elements × 8 bits)
- **Output Format**: Flattened 72-bit result vector
- **Algorithm**: Triple nested loop (i, j, k) for C[i][j] = Σ(A[i][k] * B[k][j])

**State Machine**:
```
IDLE ──start──> MULT ──complete──> DONE ──> IDLE
      (wait)          (compute)        (signal)
```

**Computation Steps**:
1. IDLE: Wait for start signal
2. MULT: For each result element C[i][j]:
   - Initialize sum = 0
   - For k = 0 to 2: sum += A[i][k] * B[k][j]
   - Store sum[7:0] in C[i][j]
3. DONE: Assert done flag, return to IDLE

**Timing**: Approximately 27 clock cycles per multiplication (9 elements × 3 accumulations)

### UART Communication System

#### Baud Rate Generator

**File**: `src/uart/baud_rate_generator.v`

**Purpose**: Generates clock signals for UART TX and RX at specified baud rate.

**Parameters**:
- `CLOCK_RATE`: System clock frequency (default: 100 MHz)
- `BAUD_RATE`: Target baud rate (default: 9600)

**Functionality**:
- RX Clock: Oversampled at 16× baud rate for better timing margin
- TX Clock: Exactly at baud rate for transmission
- Independent counters for RX and TX

**Calculation**:
```
TX_CLK_DIV = CLOCK_RATE / (2 × BAUD_RATE)
RX_CLK_DIV = CLOCK_RATE / (2 × BAUD_RATE × 16)
```

#### UART Receiver

**File**: `src/uart/uart_receiver.v`

**Purpose**: Receives serial data and converts to parallel format.

**Protocol**: 8N1 (8 data bits, no parity, 1 stop bit)

**Features**:
- Majority voting for noise immunity
- Start bit detection
- Error detection (framing errors)
- Busy/done signaling

**State Machine**:
```
RESET ──> IDLE ──detect start──> DATA_BITS ──8 bits──> STOP_BIT ──> IDLE
                    (sample)         (shift in)        (validate)
```

**Sampling Strategy**:
- 3-sample majority vote on input
- Samples at 16× baud rate
- Middle-of-bit sampling for best reliability

#### UART Transmitter

**File**: `src/uart/uart_transmitter.v`

**Purpose**: Converts parallel data to serial format for transmission.

**Protocol**: 8N1 (8 data bits, no parity, 1 stop bit)

**Features**:
- Start signal edge detection (pulse generator)
- Automatic framing (start/stop bits)
- Busy/done signaling

**State Machine**:
```
IDLE ──start──> START_BIT ──> DATA_BITS ──8 bits──> STOP_BIT ──> IDLE
     (latch)      (send 0)     (shift out)        (send 1)
```

**Transmission Sequence**:
1. Idle: Line held high
2. Start bit: Transmit '0'
3. Data bits: Transmit LSB first, 8 bits
4. Stop bit: Transmit '1'
5. Return to idle

#### Pulse Generator

**File**: `src/common/pulse_generator.v`

**Purpose**: Edge detection for control signals.

**Functionality**:
- Detects rising edge on input signal
- Generates single-cycle pulse on output
- Used for start signal detection in UART TX

### Common Header

**File**: `src/common/UartStates.vh`

**Purpose**: Defines common state constants for UART modules.

**Constants**:
```verilog
`define RESET      3'b000
`define IDLE       3'b001
`define START_BIT  3'b010
`define DATA_BITS  3'b011
`define STOP_BIT   3'b100
```

## Data Flow

### Matrix Multiplication Data Flow

```
Input A (72 bits) ──┐
                     ├──> Unpacking ──> 2D Array ──> FSM Processing ──> Result Array ──> Packing ──> Output C (72 bits)
Input B (72 bits) ──┘                    (9 × 8-bit)                      (9 × 8-bit)
```

**Flattening Convention**:
```
Matrix: [A00 A01 A02]     Flattened: [A00, A01, A02, A10, A11, A12, A20, A21, A22]
        [A10 A11 A12]              MSB ←────────────────────────────────→ LSB
        [A20 A21 A22]              [71:64][63:56][55:48][47:40][39:32][31:24][23:16][15:8][7:0]
```

### UART Data Flow

**Receive Path**:
```
RX Pin ──> Synchronizer ──> Start Detect ──> Bit Sampling ──> Shift Register ──> Output Register
           (3 samples)      (majority vote)   (16× sampling)    (8 bits)          (parallel out)
```

**Transmit Path**:
```
Input Register ──> Edge Detect ──> Shift Register ──> Bit Serialization ──> TX Pin
(parallel in)      (pulse gen)     (8 bits)           (with start/stop)     (serial out)
```

## Timing Analysis

### Matrix Multiplication

**Clock Cycles per Operation**:
- Reset: 1 cycle
- Start: 1 cycle  
- Per element computation:
  - k=0: 1 cycle (initialize)
  - k=1,2: 2 cycles (accumulate)
  - Store: 1 cycle
  - Total per element: 4 cycles
- 9 elements: 9 × 4 = 36 cycles
- Done: 1 cycle
- **Total: ~38 clock cycles**

### UART Communication

**Transmission Timing** (9600 baud):
- Bit period: 1/9600 ≈ 104 μs
- Frame: 1 start + 8 data + 1 stop = 10 bits
- Frame time: 10 × 104 μs ≈ 1.04 ms
- Throughput: ~960 bytes/second

**Reception Timing**:
- Oversampling at 16× = 153.6 kHz
- Sample period: ~6.5 μs
- 16 samples per bit for robust detection

## Resource Utilization (Typical)

Estimated for Xilinx Spartan-6 or similar:

### Matrix Multiplication Module
- Flip-Flops: ~150
- LUTs: ~200
- DSP Blocks: 0 (uses fabric multipliers)
- Block RAM: 0

### UART System
- Flip-Flops: ~80
- LUTs: ~100
- DSP Blocks: 0
- Block RAM: 0

**Total System**:
- Flip-Flops: ~230
- LUTs: ~300
- Max Frequency: >100 MHz (typical)

## Design Considerations

### Clock Domain

**Single Clock Domain Design**:
- Simplifies timing analysis
- Eliminates CDC (Clock Domain Crossing) issues
- Baud rate generator produces divided clocks

**Alternative**: Could use separate clock domains for UART with CDC FIFOs for higher performance.

### Reset Strategy

**Asynchronous Reset, Synchronous Release**:
```verilog
always @(posedge clk or posedge reset) begin
    if (reset) begin
        // Reset logic
    end else begin
        // Normal operation
    end
end
```

Benefits:
- Reliable initialization
- Doesn't require clock during reset
- Industry standard practice

### Error Handling

**UART Receiver**:
- Framing error detection (invalid stop bit)
- Error flag output for monitoring
- Continues operation after error

**Matrix Multiplication**:
- Overflow handling: Results truncated to 8 bits
- No explicit overflow flag (design choice)

### Scalability

**Current Limitations**:
- Fixed 3×3 matrix size
- Fixed 8-bit element size
- No pipelining

**Potential Improvements**:
- Parameterize matrix size
- Configurable element bit width
- Pipeline for higher throughput
- Parallel multipliers for speed

## Testing Strategy

### Simulation Testing

**Unit Tests**:
- Individual module testbenches
- Verify state machines
- Check boundary conditions

**Integration Tests**:
- Top-level system verification
- Multi-transaction sequences
- Error condition testing

### Hardware Testing

**FPGA Verification**:
1. Load bitstream
2. Connect UART terminal
3. Send test patterns
4. Verify results
5. Measure timing with oscilloscope

**Test Cases**:
- Identity matrix multiplication
- Zero matrix handling
- Maximum value elements
- Random matrices

## Performance Metrics

### Throughput

**Matrix Multiplication**:
- ~38 clock cycles per multiplication
- At 100 MHz: ~2.6 million multiplications/second
- Limited by sequential processing

**UART Communication**:
- 960 bytes/second at 9600 baud
- ~7.68 kbps data rate
- Can be increased by changing baud rate

### Latency

**Matrix Multiplication**:
- ~380 ns per multiplication at 100 MHz

**UART Round Trip**:
- Send 18 bytes (2 matrices): ~18.75 ms
- Process: ~380 ns
- Receive 9 bytes (result): ~9.38 ms
- **Total: ~28.13 ms per transaction**

## Future Enhancements

### Planned Improvements

1. **Larger Matrices**: Support 4×4, 8×8, or configurable sizes
2. **Higher Precision**: 16-bit or 32-bit elements
3. **Pipeline**: Increase throughput with pipelined design
4. **AXI Interface**: Add AXI-Stream or AXI-Lite interface
5. **DMA Support**: Direct memory access for large transfers
6. **Multiple Formats**: Support different number formats (fixed-point, floating-point)

### Advanced Features

1. **Matrix Operations**:
   - Addition/subtraction
   - Transpose
   - Determinant
   - Inversion

2. **Communication Protocols**:
   - SPI interface
   - I2C interface
   - PCIe (for high-speed applications)

3. **Optimization**:
   - Use DSP blocks for multiplication
   - Systolic array implementation
   - Block RAM for large matrices

## References

### Verilog HDL
- IEEE Standard 1364-2005
- Xilinx Synthesis Guide

### UART Protocol
- "Serial Port Complete" by Jan Axelson
- RS-232 Standard

### Matrix Multiplication
- "Computer Arithmetic: Algorithms and Hardware Designs" by Behrooz Parhami
- FPGA acceleration literature

---

**Document Version**: 1.0  
**Last Updated**: 2026-01-29  
**Maintained By**: Project Team
