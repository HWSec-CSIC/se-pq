# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  ipgui::add_param $IPINST -name "IMP_SHA2"
  ipgui::add_param $IPINST -name "IMP_SHA3"
  ipgui::add_param $IPINST -name "IMP_EDDSA"
  ipgui::add_param $IPINST -name "IMP_X25519"
  ipgui::add_param $IPINST -name "IMP_TRNG"
  ipgui::add_param $IPINST -name "IMP_AES"

}

proc update_PARAM_VALUE.IMP_AES { PARAM_VALUE.IMP_AES } {
	# Procedure called to update IMP_AES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IMP_AES { PARAM_VALUE.IMP_AES } {
	# Procedure called to validate IMP_AES
	return true
}

proc update_PARAM_VALUE.IMP_EDDSA { PARAM_VALUE.IMP_EDDSA } {
	# Procedure called to update IMP_EDDSA when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IMP_EDDSA { PARAM_VALUE.IMP_EDDSA } {
	# Procedure called to validate IMP_EDDSA
	return true
}

proc update_PARAM_VALUE.IMP_SHA2 { PARAM_VALUE.IMP_SHA2 } {
	# Procedure called to update IMP_SHA2 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IMP_SHA2 { PARAM_VALUE.IMP_SHA2 } {
	# Procedure called to validate IMP_SHA2
	return true
}

proc update_PARAM_VALUE.IMP_SHA3 { PARAM_VALUE.IMP_SHA3 } {
	# Procedure called to update IMP_SHA3 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IMP_SHA3 { PARAM_VALUE.IMP_SHA3 } {
	# Procedure called to validate IMP_SHA3
	return true
}

proc update_PARAM_VALUE.IMP_TRNG { PARAM_VALUE.IMP_TRNG } {
	# Procedure called to update IMP_TRNG when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IMP_TRNG { PARAM_VALUE.IMP_TRNG } {
	# Procedure called to validate IMP_TRNG
	return true
}

proc update_PARAM_VALUE.IMP_X25519 { PARAM_VALUE.IMP_X25519 } {
	# Procedure called to update IMP_X25519 when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.IMP_X25519 { PARAM_VALUE.IMP_X25519 } {
	# Procedure called to validate IMP_X25519
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to update C_S00_AXI_DATA_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_DATA_WIDTH { PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to validate C_S00_AXI_DATA_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to update C_S00_AXI_ADDR_WIDTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_ADDR_WIDTH { PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to validate C_S00_AXI_ADDR_WIDTH
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to update C_S00_AXI_BASEADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_BASEADDR { PARAM_VALUE.C_S00_AXI_BASEADDR } {
	# Procedure called to validate C_S00_AXI_BASEADDR
	return true
}

proc update_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to update C_S00_AXI_HIGHADDR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.C_S00_AXI_HIGHADDR { PARAM_VALUE.C_S00_AXI_HIGHADDR } {
	# Procedure called to validate C_S00_AXI_HIGHADDR
	return true
}


proc update_MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH { MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH PARAM_VALUE.C_S00_AXI_DATA_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_DATA_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_DATA_WIDTH}
}

proc update_MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH { MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH PARAM_VALUE.C_S00_AXI_ADDR_WIDTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.C_S00_AXI_ADDR_WIDTH}] ${MODELPARAM_VALUE.C_S00_AXI_ADDR_WIDTH}
}

proc update_MODELPARAM_VALUE.IMP_SHA2 { MODELPARAM_VALUE.IMP_SHA2 PARAM_VALUE.IMP_SHA2 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IMP_SHA2}] ${MODELPARAM_VALUE.IMP_SHA2}
}

proc update_MODELPARAM_VALUE.IMP_SHA3 { MODELPARAM_VALUE.IMP_SHA3 PARAM_VALUE.IMP_SHA3 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IMP_SHA3}] ${MODELPARAM_VALUE.IMP_SHA3}
}

proc update_MODELPARAM_VALUE.IMP_EDDSA { MODELPARAM_VALUE.IMP_EDDSA PARAM_VALUE.IMP_EDDSA } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IMP_EDDSA}] ${MODELPARAM_VALUE.IMP_EDDSA}
}

proc update_MODELPARAM_VALUE.IMP_X25519 { MODELPARAM_VALUE.IMP_X25519 PARAM_VALUE.IMP_X25519 } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IMP_X25519}] ${MODELPARAM_VALUE.IMP_X25519}
}

proc update_MODELPARAM_VALUE.IMP_TRNG { MODELPARAM_VALUE.IMP_TRNG PARAM_VALUE.IMP_TRNG } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IMP_TRNG}] ${MODELPARAM_VALUE.IMP_TRNG}
}

proc update_MODELPARAM_VALUE.IMP_AES { MODELPARAM_VALUE.IMP_AES PARAM_VALUE.IMP_AES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.IMP_AES}] ${MODELPARAM_VALUE.IMP_AES}
}

