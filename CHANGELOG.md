# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Comprehensive README.md with project overview, setup instructions, and usage guidelines
- CONTRIBUTING.md with detailed contribution guidelines and coding standards
- LICENSE file (MIT License)
- .gitignore for common FPGA/Verilog build artifacts
- docs/ARCHITECTURE.md with detailed system architecture documentation
- docs/QUICK_START.md with quick start guide and common workflows
- docs/CHANGELOG.md (this file)
- src/common/UartStates.vh header file for UART state definitions
- Professional badges and formatting in documentation
- Complete directory structure following best practices

### Changed
- Reorganized entire repository structure for better organization
- Moved matrix multiplication module to `src/matrix_multiplication/`
- Moved UART modules to `src/uart/`
- Moved common modules to `src/common/`
- Moved testbench files to `testbench/`
- Moved constraint files to `constraints/`
- Renamed files to follow consistent naming convention (lowercase with underscores):
  - `flattend_matrix_3.v` → `matrix_multiplication.v`
  - `UART_Receiver.v` → `uart_receiver.v`
  - `transmitter.v` → `uart_transmitter.v`
  - `baud.v` → `baud_rate_generator.v`
  - `UART_TOP_Original.v` → `uart_top.v`
  - `ucfuart1.ucf` → `uart_constraints.ucf`
  - `flattened_serial_mul_tb.v` → `matrix_multiplication_tb.v`
- Updated include paths in UART modules to reference common directory

### Removed
- Empty `UART_Matrix_Try_Folder` file

### Fixed
- Missing UartStates.vh header file (was referenced but not present)
- Inconsistent file naming conventions

## [Initial] - Pre-reorganization

### Initial Repository State
- Basic matrix multiplication implementation in Verilog
- UART communication modules (transmitter, receiver, baud rate generator)
- Test bench for matrix multiplication
- UCF constraint file for FPGA implementation
- Minimal README with just project title

---

**Note**: This is the first comprehensive documentation update. Previous development history focused on functionality implementation.
