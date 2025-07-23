# Atari 'World Cup' (WCC/Goal IV) FPGA Recreation

This project is a VHDL recreation of the classic 1974 discrete logic arcade game known as 'World Cup', 'World Cup Football', 'Coupe du Monde' or 'Goal IV' by Atari. The original PCB is marked 'WCC' and was assigned the working ID 'TM-035'.

## Project Goals and Methodology
- The VHDL code is designed to closely resemble the original schematics for maximum traceability and historical accuracy.
- All standard TTL logic is implemented as 74 series ICs (e.g., LS02, LS04, etc.) and saved in the `74LS` directory.
- Other ICs are saved in the `IC` directory.
- Each IC is defined as a VHDL component, with ports and instance names matching the real IC pinout and PCB location.
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

### IC Layout

Pedominantly 74 series ICs.
The UA747 at F9 and N9 are opamps so are not implemented.

|       | A  | B  | C  | D  | E  | F  | H  | J  | K  | L  | M  | N  |
| -----:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|:--:|
| **1** | [04](74LS/LS04.vhd) | [20](74LS/LS20.vhd) | [93](74LS/LS93.vhd) | [93](74LS/LS93.vhd) | [93](74LS/LS93.vhd) | [93](74LS/LS93.vhd) | [107](74LS/LS107.vhd) | [00](74LS/LS00.vhd) | [74](74LS/LS74.vhd) | [30](74LS/LS30.vhd) | [08](74LS/LS08.vhd) |  - |
| **2** | [10](74LS/LS10.vhd) | [107](74LS/LS107.vhd) | [30](74LS/LS30.vhd) | [74](74LS/LS74.vhd) | [74](74LS/LS74.vhd) | [86](74LS/LS86.vhd) | [10](74LS/LS10.vhd) | [04](74LS/LS04.vhd) | [10](74LS/LS10.vhd) | [10](74LS/LS10.vhd) | [08](74LS/LS08.vhd) | [107](74LS/LS107.vhd) |
| **3** | [20](74LS/LS20.vhd) | [107](74LS/LS107.vhd) | [00](74LS/LS00.vhd) | [08](74LS/LS08.vhd) | [04](74LS/LS04.vhd) | [02](74LS/LS02.vhd) | [27](74LS/LS27.vhd) | [00](74LS/LS00.vhd) | [90](74LS/LS90.vhd) | [90](74LS/LS90.vhd) | [153](74LS/LS153.vhd) | [153](74LS/LS153.vhd) |
| **4** |[9316](IC/IC9316.vhd)|[9316](IC/IC9316.vhd)|[9316](IC/IC9316.vhd)|[9316](IC/IC9316.vhd)| [74](74LS/LS74.vhd) | [02](74LS/LS02.vhd) | [02](74LS/LS02.vhd) | [20](74LS/LS20.vhd) | [107](74LS/LS107.vhd) |[9316](IC/IC9316.vhd)|[9316](IC/IC9316.vhd)| [27](74LS/LS27.vhd) |
| **5** | [86](74LS/LS86.vhd) | [83](74LS/LS83.vhd) | [08](74LS/LS08.vhd) | [74](74LS/LS74.vhd) |[9602](IC/IC9602.vhd)| [08](74LS/LS08.vhd) | [02](74LS/LS02.vhd) |[9602](IC/IC9602.vhd)|  - | [74](74LS/LS74.vhd) | [86](74LS/LS86.vhd) | [00](74LS/LS00.vhd) |
| **6** | [08](74LS/LS08.vhd) |[9316](IC/IC9316.vhd)| [04](74LS/LS04.vhd) | [74](74LS/LS74.vhd) | [86](74LS/LS86.vhd) | [00](74LS/LS00.vhd) | [10](74LS/LS10.vhd) | [27](74LS/LS27.vhd) | [08](74LS/LS08.vhd) | [86](74LS/LS86.vhd) | [92](74LS/LS92.vhd) |  - |
| **7** | [83](74LS/LS83.vhd) | [02](74LS/LS02.vhd) | [86](74LS/LS86.vhd) |[9314](IC/IC9314.vhd)| [20](74LS/LS20.vhd) | [107](74LS/LS107.vhd) | [153](74LS/LS153.vhd) |[9316](IC/IC9316.vhd)|[9316](IC/IC9316.vhd)| [153](74LS/LS153.vhd) |[9316](IC/IC9316.vhd)|[9316](IC/IC9316.vhd)|
| **8** | [04](74LS/LS04.vhd) | [74](74LS/LS74.vhd) | [00](74LS/LS00.vhd) | [74](74LS/LS74.vhd) | [00](74LS/LS00.vhd) |  - | [107](74LS/LS107.vhd) | [04](74LS/LS04.vhd) | [02](74LS/LS02.vhd) | [00](74LS/LS00.vhd) |  - | [555](IC/IC555.vhd)|
| **9** | [74](74LS/LS74.vhd) | [74](74LS/LS74.vhd) | [02](74LS/LS02.vhd) | [04](74LS/LS04.vhd) | [555](IC/IC555.vhd)| 747| [555](IC/IC555.vhd)|[9602](IC/IC9602.vhd)|  - |  - |[9602](IC/IC9602.vhd)| 747|

### PCB Image

![Atari WCC PCB](diagrams/atari_wcc_pcb.jpg)
