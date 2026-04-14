[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/d5nOy1eX)


*Author: Laksh Mittal*


*Roll Number: 2024113003*

*Strategy for Q3:*

**Part A: Password Extraction**
I used the `strings` command on the executable to dump all the readable text. Scrolling through the output, I located the program's success and failure messages. The actual password was stored directly next to these strings in the binary's read-only memory. I extracted that string and fed it into the program to pass the check.

**Part B: Buffer Overflow**
The second binary had a buffer overflow vulnerability rather than a hardcoded password. I took control of the program's execution flow and forced it to run a specific hidden function. I ran `objdump -d` on the binary to disassemble it and locate the exact hex memory address of the target success function. Then, I crafted a binary payload. I overflowed the input buffer with enough garbage characters to intentionally overflow it and reach the instruction pointer on the stack. I overwrote the return address with the memory address of the success function, mapped out in little-endian format. When the vulnerable function finished executing, it popped my injected address off the stack and jumped straight to the success function.
