# Packet Decoder - SystemVerilog Testbench

Class-based SystemVerilog testbench for `pkt_decoder` (header with destination address and length, payload, XOR CRC, output on ports AA/BB/CC/DD). Includes transaction, generator, driver, receiver (one per port), scoreboard with functional coverage, environment, test and top.

## Layout
- `rtl/` - `pkt_decoder.sv` (DUT)
- `tb/` - `infc.sv`, `transaction.sv`, `packet_test.h`, `generator.sv`, `driverbase.sv`, `driver.sv`, `receiverbase.sv`, `receiver.sv`, `scoreboard.sv`, `environment.sv`, `packet_test_pkg.sv`, `test.sv`, `test_top.sv`
- `eda_playground/` - `design.sv` (DUT) and `testbench.sv` (whole testbench merged, with waveform dump) ready to paste

## Run on EDA Playground
Link: https://edaplayground.com/x/NiqH

Simulator: Synopsys VCS (any SV-class capable simulator). Top module: `test_top`.

## Results
<img width="1661" height="846" alt="image" src="https://github.com/user-attachments/assets/3b7f270f-bcae-42d6-9e41-622566ceca5b" />
<img width="1848" height="663" alt="image" src="https://github.com/user-attachments/assets/9070bc09-9a6a-4846-bc04-22c04349d153" />
