##################################################################################
## Constraints for Manual Reset
##################################################################################
set_property -dict {PACKAGE_PIN M11 IOSTANDARD LVCMOS33} [get_ports rst_0]

##################################################################################
## Constraints for Digilent Pmod SF3 on PMOD0 (J55)
##################################################################################
set_property -dict {PACKAGE_PIN G8 IOSTANDARD LVCMOS33} [get_ports spi_csn_0]
set_property -dict {PACKAGE_PIN H8 IOSTANDARD LVCMOS33} [get_ports spi_dq0_o_0]
set_property -dict {PACKAGE_PIN G7 IOSTANDARD LVCMOS33} [get_ports spi_dq1_i_0]
set_property -dict {PACKAGE_PIN H7 IOSTANDARD LVCMOS33} [get_ports spi_sclk_0]