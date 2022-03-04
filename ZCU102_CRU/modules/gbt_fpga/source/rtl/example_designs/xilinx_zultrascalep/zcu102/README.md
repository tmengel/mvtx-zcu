## ZCU102 GBT-FPGA example project

This example is based on the Kintex Ultrascale (KC105) example design.
Due to the newer chip on the ZCU102 board this project is opened with Vivado 2020.2, compared to 2016.3 which was the latest GBT-FPGA release v6.1.0.

Clocks:
- SFP_SI5328_OUT_C: 120 MHz - MGT reference clock
- CLK_125: 125 MHz - clock used to generate 120 MHz free running clock

Connections:
- SFP0 (top right looking into the 2x2 SFP cage) is used
