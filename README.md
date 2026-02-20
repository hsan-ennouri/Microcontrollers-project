# Morse Code Translator
## Overview
Developed a low-level embedded system capable of translating keypad input into audible Morse code and visual text in real-time. Executed entirely in AVR Assembly for an ATmega microcontroller as part of the Microcontrollers and Digital Systems course (EE208) at EPFL. Engineered custom peripheral drivers and managed strict timing constraints without relying on any external C/C++ libraries.

## Key Features
Pure Assembly Implementation: Co-wrote the entire codebase in AVR Assembly to manage precise hardware-level execution and standard Morse dot/dash timing requirements.

Custom Peripheral Drivers: Coded bare-metal drivers from scratch to interface with a 4x4 matrix keypad and an LCD display.

Non-Blocking Architecture: Configured hardware timers and external interrupts (INTx) to handle user inputs and motor actuation simultaneously without blocking the main CPU execution cycle.

Electromechanical Integration: Integrated a stepper motor driver to actuate a stepper motor, providing physical rotational feedback during the message input phase.

## Hardware Components
ATmega Microcontroller (STK300 AVR Kit)

4x4 Matrix Keypad

16x2 LCD Display

Stepper Motor and Driver Module

Piezo Buzzer / Speaker for audio output

## Software Architecture
Architected the system around Interrupt Service Routines (ISRs) and Hardware Timers. The main execution loop remains lightweight, while time-critical tasks such as debouncing the keypad, toggling the buzzer at specific frequencies, and stepping the motor are handled via precise timer overflows and external interrupt triggers.
