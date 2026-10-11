# microASM

A lightweight assembly language compiler designed for educational purposes.

## Architecture Overview

The `microASM` repository is structured to provide a simple yet effective environment for learning and understanding the basics of assembly language compilation. The core component of this project is the `compiler.asm` file, which contains the assembly code responsible for compiling source programs into machine code.

## Tech Stack

- **Programming Language**: Assembly
- **Tools**: Assembler (specific toolchain may vary based on target architecture)

## Getting Started / Setup Guide

1. **Install an Assembler**:
   - Ensure you have an assembler installed that supports the assembly language used in `compiler.asm`. For example, if targeting x86 architecture, tools like NASM or YASM can be used.

2. **Clone the Repository**:
   ```bash
   git clone https://github.com/yourusername/microASM.git
   cd microASM
   ```

3. **Compile the Compiler**:
   - Use your chosen assembler to compile `compiler.asm`. For example, with NASM:
     ```bash
     nasm -f elf64 compiler.asm -o compiler.o
     ```
   - Link the object file into an executable (if necessary):
     ```bash
     ld -o microASM compiler.o
     ```

4. **Run the Compiler**:
   - Execute the compiled `microASM` binary to start using it for compiling your assembly programs.

5. **Developing with microASM**:
   - Modify `compiler.asm` as needed to extend or customize the functionality of the compiler.
   - Write new assembly source files and use `microASM` to compile them into machine code.

This setup provides a foundational environment for exploring and experimenting with assembly language compilation, suitable for educational purposes and small-scale projects.