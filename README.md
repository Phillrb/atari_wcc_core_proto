# Atari 'World Cup' (WCC/Goal IV) FPGA Recreation

This project is a VHDL recreation of the classic 1974 discrete logic arcade game known as 'World Cup', 'World Cup Football', 'Coupe du Monde' or 'Goal IV' by Atari. The original PCB is marked 'WCC' and was assigned the working ID 'TM-035'.

## Project Goals and Methodology
- The VHDL code is designed to closely resemble the original schematics for maximum traceability and historical accuracy.
- All standard TTL logic is implemented as 74 series ICs (e.g., LS02, LS04, etc.) and saved in the `74LS` directory.
- Each 74 series IC is defined as a VHDL component, with ports and instance names matching the real IC pinout and PCB location.
- Pin connections in port maps are labeled to reflect both the pin number and the signal it connects to, aiding cross-referencing with the schematic.
- Individual VHD files will be created to represent each circuit as descibed by the manual.
- The file [Goal_IV_TM-035.pdf](Goal_IV_TM-035.pdf) is the original manual and schematics.
- [Goal_IV_TM-035_ocr.pdf](Goal_IV_TM-035_ocr.pdf) was created with OCR and adds metadata to the original PDF to make it searchable.
- [Goal_IV_TM-035.md](Goal_IV_TM-035.md) is a markdown file generated from the OCR process and further adjusted.

## Tooling
- This project is designed to be opened and configured with Quartus II version 13.0.1 Service Pack 1.

## Project Status
- The 74LS library is well-structured and includes many standard TTL logic chips as VHDL modules.
- The top-level design currently instantiates the clock divider and composite sync generator; further game logic is to be implemented.
- Testbenches are provided for many of the 74LS components and flip-flop primitives.

## Atari WCC PCB

Pedominantly 74 series ICs

|       | A  | B  | C  | D  | E  | F  | H  | J  | K  | L  | M  | N  |
| -----:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| **1** | 04 | 20 | 93 | 93 | 93 | 93 | 107| 00 | 74 | 30 | 08 |  - |
| **2** | 10 | 107| 30 | 74 | 74 | 86 | 10 | 04 | 10 | 10 | 48 | 107|
| **3** | 20 | 107| 00 | 08 | 04 | 02 | 27 | 00 | 90 | 90 | 153| 153|
| **4** |9316|9316|9316|9316| 74 | 02 | 02 | 20 | 107|9316|9316| 27 |
| **5** | 86 | 83 | 08 | 74 |9602| 08 | 02 |9602|  - | 74 | 86 | 00 |
| **6** | 08 |9316| 04 | 74 | 86 | 00 | 10 | 27 | 08 | 86 | 92 |  - |
| **7** | 83 | 02 | 86 |9314| 20 | 107| 153|9316|9316| 153|9316|9316|
| **8** | 04 | 74 | 00 | 74 | 00 |  - | 107| 04 | 02 | 00 |  - | 555|
| **9** | 74 | 74 | 02 | 04 | 555| 747| 555|9602|  - |  - |9602| 747|

![Atari WCC PCB](diagrams/atari_wcc_pcb.jpg)
