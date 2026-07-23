set_property PACKAGE_PIN A17 [get_ports {result[0]}]
set_property IOSTANDARD LVCMOS18 [get_ports {result[0]}]
set_property PACKAGE_PIN W21 [get_ports {result[1]}]
set_property IOSTANDARD LVCMOS25 [get_ports {result[1]}]
set_property PACKAGE_PIN G2 [get_ports {result[2]}]
set_property IOSTANDARD LVCMOS18 [get_ports {result[2]}]
set_property PACKAGE_PIN Y21 [get_ports {result[3]}]
set_property IOSTANDARD LVCMOS25 [get_ports {result[3]}]

set_property PACKAGE_PIN AJ21 [get_ports rx]
set_property IOSTANDARD LVCMOS25 [get_ports rx]
set_false_path -from [get_ports rx]

set_property PACKAGE_PIN Y20 [get_ports tx]
set_property IOSTANDARD LVCMOS25 [get_ports tx]

set_property PACKAGE_PIN H9 [get_ports clk_p]
set_property PACKAGE_PIN G9 [get_ports clk_n]
set_property IOSTANDARD LVDS [get_ports clk_p]

set_property PACKAGE_PIN AK25 [get_ports reset_raw]
set_property IOSTANDARD LVCMOS25 [get_ports reset_raw]
set_false_path -from [get_ports reset_raw]