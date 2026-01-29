// UART State Machine Definitions
// Common header file for UART transmitter and receiver modules

`ifndef UART_STATES_VH
`define UART_STATES_VH

// UART State Definitions
`define RESET      3'b000
`define IDLE       3'b001
`define START_BIT  3'b010
`define DATA_BITS  3'b011
`define STOP_BIT   3'b100

`endif // UART_STATES_VH
