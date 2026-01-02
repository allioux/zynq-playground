# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "lsb" -parent ${Page_0}
  ipgui::add_param $IPINST -name "msb" -parent ${Page_0}
  ipgui::add_param $IPINST -name "width" -parent ${Page_0}


}

proc update_PARAM_VALUE.lsb { PARAM_VALUE.lsb } {
	# Procedure called to update lsb when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.lsb { PARAM_VALUE.lsb } {
	# Procedure called to validate lsb
	return true
}

proc update_PARAM_VALUE.msb { PARAM_VALUE.msb } {
	# Procedure called to update msb when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.msb { PARAM_VALUE.msb } {
	# Procedure called to validate msb
	return true
}

proc update_PARAM_VALUE.width { PARAM_VALUE.width } {
	# Procedure called to update width when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.width { PARAM_VALUE.width } {
	# Procedure called to validate width
	return true
}


proc update_MODELPARAM_VALUE.width { MODELPARAM_VALUE.width PARAM_VALUE.width } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.width}] ${MODELPARAM_VALUE.width}
}

proc update_MODELPARAM_VALUE.msb { MODELPARAM_VALUE.msb PARAM_VALUE.msb } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.msb}] ${MODELPARAM_VALUE.msb}
}

proc update_MODELPARAM_VALUE.lsb { MODELPARAM_VALUE.lsb PARAM_VALUE.lsb } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.lsb}] ${MODELPARAM_VALUE.lsb}
}

