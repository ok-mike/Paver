# Paver
Verilog description for 16-bit microcontroller in FPGA

These files are for an original 16-bit microcontroller developed from scratch. The system works fine on a Terasic DE1-SOC board at around 80MHz clock. It implements a native assembler and rudimentary OS based on a Forth interpreter, VGA output, PS/2 keyboard interface and media card storage.

In the subfolders, there are native implementions of Paver emulators with graphics consoles for iOS, Android, macOS, and Windows.

Weirdly joyous, when the character generator in your VGA driver is still off, but you know you'll get there soon:

![CPU board](https://github.com/Dosflange/Paver/blob/main/vga_driver_fail.jpg)

