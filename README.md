Digital System: ALU and PWM Unit with Timing Analysis
-----------------------------------------------------

Overview
--------
This project implements a digital system in VHDL featuring a parameterized Arithmetic Logic Unit (ALU) and a Pulse Width Modulation (PWM) generator. The system is designed for FPGA deployment and includes comprehensive testbenches and timing analysis support.

System Components
-----------------
1. **ALU (Arithmetic Logic Unit)**
   - Supports arithmetic (add, subtract, increment, decrement, negate), logic (and, or, xor, etc.), and shift operations.
   - Operation is selected via a 5-bit function code (`ALUFN`).
   - Inputs and outputs are registered to enable accurate timing analysis and improve performance.
   - Outputs standard flags: Zero (Z), Carry (C), Negative (N), and Overflow (V).

2. **PWM Unit**
   - Generates a PWM signal with configurable period and duty cycle.
   - Parameters are set via input vectors `X` (duty cycle) and `Y` (period).
   - Supports multiple PWM modes, selectable via `ALUFN`.
   - Includes a counter implemented as a register vector (`Timer_vec`), which is incremented each clock cycle and reset when reaching the period value.

3. **Top-Level Wrapper**
   - Integrates the ALU and PWM unit.
   - Provides input/output registers for timing closure and system integration.
   - Connects to external switches, keys, LEDs, and 7-segment displays for user interaction and debugging.
   - Includes a PLL for clock management (if required).




File List
---------
- `ALU.vhd`           : Main ALU implementation
- `AdderSub.vhd`      : Adder/Subtractor module
- `Logic.vhd`         : Logic operations module
- `Shifter.vhd`       : Shift operations module
- `PWMunit.vhd`       : PWM generator module
- `topPureLogicWithoutPLL.vhd` : Top-level ALU wrapper for timing analysis
- `TopIO_Interface.vhd`: Full system integration with I/O
- `aux_package.vhd`   : Component/package definitions
