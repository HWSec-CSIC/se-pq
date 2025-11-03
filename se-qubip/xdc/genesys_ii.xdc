# Clock Signal 100 MHz
set_property -dict {PACKAGE_PIN AD11 IOSTANDARD LVDS} [get_ports clk_in1_n_0]
set_property -dict {PACKAGE_PIN AD12 IOSTANDARD LVDS} [get_ports clk_in1_p_0]

#create_clock -period 10.000 -name clk -waveform {0.000 5.000} -add [get_ports s00_axi_aclk_0]
# I2C
set_property -dict {PACKAGE_PIN AC26 IOSTANDARD LVCMOS33} [get_ports SDA_0]
set_property -dict {PACKAGE_PIN AJ27 IOSTANDARD LVCMOS33} [get_ports SCL_0]

# PULL-UP Resistor for SDA
set_property PULLTYPE PULLUP [get_ports SDA_0]

# Reset Button
set_property -dict {PACKAGE_PIN E18 IOSTANDARD LVCMOS12} [get_ports rst_0]

##################################################################################
## Constraints for Digilent Pmod SF3 on PMOD_B
##################################################################################
set_property -dict {PACKAGE_PIN V29 IOSTANDARD LVCMOS33} [get_ports spi_csn_0]
set_property -dict {PACKAGE_PIN V30 IOSTANDARD LVCMOS33} [get_ports spi_dq0_o_0]
set_property -dict {PACKAGE_PIN V25 IOSTANDARD LVCMOS33} [get_ports spi_dq1_i_0]
set_property -dict {PACKAGE_PIN W26 IOSTANDARD LVCMOS33} [get_ports spi_sclk_0]