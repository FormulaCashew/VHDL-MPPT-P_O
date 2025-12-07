# FPGA-based MPPT System

## Project Overview

This project implements a Maximum Power Point Tracking (MPPT) system for solar panels using a Field Programmable Gate Array (FPGA). The system utilizes a Perturb and Observe (P&O) algorithm to optimize the power output from the solar panel. It features a digital filter for noise reduction, UART communication for data monitoring, and a 7-segment display interface for real-time power visualization.

## Hardware Components

The system is built using the following key hardware components:

- **FPGA**: The core controller implementing the MPPT logic and system management.
- **H-Bridge Circuit**: Used for power conversion and control.
- **INA219**: A high-side current and power monitor used to measure the solar panel's voltage and current.
- **Solar Panel**: The power source.
- **4x 7-Segment Displays**: Visual output for displaying the current power extraction.
- **Switch**: A physical switch to enable or disable the MPPT system.

## Key Features

### MPPT Algorithm

The core of the system is the **Maximum Power Point Tracking** algorithm, implemented in `MPPT.vhd`. It uses the **Perturb and Observe (P&O)** method. The algorithm continuously measures the power from the solar panel and adjusts the PWM duty cycle of the H-bridge to find the operating point that yields the maximum power.

- **Logic**: It compares the current power with the previous power measurement. If the power increases, it continues adjusting the duty cycle in the same direction. If the power decreases, it reverses the direction.

### Digital Filter

To ensure stable and accurate readings from the INA219 sensor, a digital filter is implemented in `LPF.vhd`.

- **Efficiency**: The filter is designed for hardware efficiency, utilizing a **serialized architecture** that requires **few multipliers**.
- **Fixed-Point Arithmetic**: It employs **fixed-point operations** to maintain precision while minimizing resource usage on the FPGA.

### UART Communication

The system includes a UART interface, handled by `DataSender.vhd`, to transmit real-time system data to an external device (e.g., a PC).

- **Transmitted Data**:
  - **Power**: The current power output.
  - **Duty Cycle**: The current PWM duty cycle being applied.
  - **Error**: Error signals or status codes.
- **Format**: Data is sent in a structured format (e.g., "P: <Power>, W: <Watts>, ...") for easy parsing and monitoring.

### User Interface

- **7-Segment Display**: Shows the real-time power value, allowing for immediate visual feedback of the system's performance.
- **Control Switch**: A digital input allows the user to turn the MPPT tracking on or off, providing manual control over the system operation.

## File Structure

- **`TopLevel.vhd`**: The top-level entity that integrates all components (MPPT, INA219 driver, UART, Display, Filter).
- **`MPPT.vhd`**: Implements the P&O MPPT algorithm and PWM generation.
- **`LPF.vhd`**: The efficient digital low-pass filter for sensor data.
- **`DataSender.vhd`**: Manages data formatting and transmission over UART.
- **`Get_INA219.vhd`**: I2C driver for communicating with the INA219 sensor.
- **`UART_TX.vhd`**: Basic UART transmitter module.
