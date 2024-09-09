# Paver-CLI

This is a cleaned-up WIP including the native Paver assembler source I was using for the various implementations of that CPU, notably the [FPGA version](https://github.com/Dosflange/Paver).

Hen.c does not directly implement an assembler. It instead loads the native binary version (!) of the assembler and runs it by emulating a Paver core in order to assemble a new version of itself (the egg). The source code of the native assembler is in Colonel/src/CYF.asm.

The native binary was produced by an early cross-assembler version of Cyf, written in C. Once the assembler code was self-hosting, the C version was put aside. 
