# Copyright (C) 2017 Philipp Holzinger
# Copyright (C) 2017 Martin Stumpf
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

ipx::package_project -force -vendor {fau.de} -taxonomy {/HSA} -import_files -root_dir "[get_property DIRECTORY [current_project]]/ip"

set_property vendor              {fau.de}                 [ipx::current_core]
set_property library             {hsa}                    [ipx::current_core]
set_property taxonomy            {{/HSA}}                 [ipx::current_core]
set_property vendor_display_name {FAU Erlangen-Nuremberg} [ipx::current_core]
set_property company_url         {https://fau.de}         [ipx::current_core]
set_property version             1.0                      [ipx::current_core]
set_property description         {generic bram block}     [ipx::current_core]

# TODO add all supported families
set_property supported_families  { \
                     {virtex7}    {Production} \
                     {virtexu}    {Production} \
                     {zynq}       {Production} \
                     {zynquplus}  {Beta} \
                     }   [ipx::current_core]

#####################################
# Actual IP Settings

set_property name {dualclock_bram} [ipx::current_core]
set_property display_name {Dualclock Bram} [ipx::current_core]

ipx::add_bus_interface BRAM_PORTA [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:bram_rtl:1.0 [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:bram:1.0 [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]
set_property interface_mode master [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]
set_property display_name BRAM_PORTA [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]
set_property interface_mode slave [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]
ipx::add_port_map DIN [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]
set_property physical_name a_din [ipx::get_port_maps DIN -of_objects [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]]
ipx::add_port_map EN [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]
set_property physical_name a_en [ipx::get_port_maps EN -of_objects [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]]
ipx::add_port_map DOUT [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]
set_property physical_name a_dout [ipx::get_port_maps DOUT -of_objects [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]]
ipx::add_port_map CLK [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]
set_property physical_name a_clk [ipx::get_port_maps CLK -of_objects [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]]
ipx::add_port_map WE [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]
set_property physical_name a_wr [ipx::get_port_maps WE -of_objects [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]]
ipx::add_port_map ADDR [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]
set_property physical_name a_addr [ipx::get_port_maps ADDR -of_objects [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces a_clk -of_objects [ipx::current_core]]
set_property value BRAM_PORTA [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces a_clk -of_objects [ipx::current_core]]]
ipx::add_bus_parameter MASTER_TYPE [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]
set_property value BRAM_CTRL [ipx::get_bus_parameters MASTER_TYPE -of_objects [ipx::get_bus_interfaces BRAM_PORTA -of_objects [ipx::current_core]]]

ipx::add_bus_interface BRAM_PORTB [ipx::current_core]
set_property abstraction_type_vlnv xilinx.com:interface:bram_rtl:1.0 [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]
set_property bus_type_vlnv xilinx.com:interface:bram:1.0 [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]
set_property display_name BRAM_PORTB [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]
ipx::add_port_map DIN [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]
set_property physical_name b_din [ipx::get_port_maps DIN -of_objects [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]]
ipx::add_port_map EN [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]
set_property physical_name b_en [ipx::get_port_maps EN -of_objects [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]]
ipx::add_port_map DOUT [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]
set_property physical_name b_dout [ipx::get_port_maps DOUT -of_objects [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]]
ipx::add_port_map CLK [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]
set_property physical_name b_clk [ipx::get_port_maps CLK -of_objects [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]]
ipx::add_port_map WE [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]
set_property physical_name b_wr [ipx::get_port_maps WE -of_objects [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]]
ipx::add_port_map ADDR [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]
set_property physical_name b_addr [ipx::get_port_maps ADDR -of_objects [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]]
ipx::add_bus_parameter ASSOCIATED_BUSIF [ipx::get_bus_interfaces b_clk -of_objects [ipx::current_core]]
set_property value BRAM_PORTB [ipx::get_bus_parameters ASSOCIATED_BUSIF -of_objects [ipx::get_bus_interfaces b_clk -of_objects [ipx::current_core]]]
ipx::add_bus_parameter MASTER_TYPE [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]
set_property value BRAM_CTRL [ipx::get_bus_parameters MASTER_TYPE -of_objects [ipx::get_bus_interfaces BRAM_PORTB -of_objects [ipx::current_core]]]

# End of Actual IP Settings
#####################################

ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums  [ipx::current_core]
ipx::save_core         [ipx::current_core]
