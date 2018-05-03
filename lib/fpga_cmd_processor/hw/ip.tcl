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

set script_dir "[file dirname "[file normalize "[info script]"]"]"

ipx::package_project -force -vendor {fau.de} -taxonomy {/HSA} -import_files -root_dir "[get_property DIRECTORY [current_project]]/ip"

set_property vendor              {fau.de}                 [ipx::current_core]
set_property library             {hsa}                    [ipx::current_core]
set_property taxonomy            {{/HSA}}                 [ipx::current_core]
set_property vendor_display_name {FAU Erlangen-Nuremberg} [ipx::current_core]
set_property company_url         {https://fau.de}         [ipx::current_core]
set_property version             2.0                      [ipx::current_core]
set_property description         {HSA Soft-Core Host}     [ipx::current_core]

# TODO add all supported families
set_property supported_families  { \
                     {virtex7}    {Production} \
                     {virtexu}    {Production} \
                     {zynq}    {Production} \
                     {zynquplus} {Beta} \
                     }   [ipx::current_core]

#####################################
# Actual IP Settings

set_property name {fpga_cmd_processor} [ipx::current_core]
set_property display_name {FPGA Command Processor} [ipx::current_core]

ipx::infer_bus_interface rcv_dma_irq_ack xilinx.com:signal:interrupt_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface rcv_cpl_irq_ack xilinx.com:signal:interrupt_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface rcv_add_irq_ack xilinx.com:signal:interrupt_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface rcv_rem_irq_ack xilinx.com:signal:interrupt_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface snd_aql_irq_ack xilinx.com:signal:interrupt_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface snd_dma_irq_ack xilinx.com:signal:interrupt_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface snd_cpl_irq_ack xilinx.com:signal:interrupt_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface snd_add_irq_ack xilinx.com:signal:interrupt_rtl:1.0 [ipx::current_core]
ipx::infer_bus_interface snd_rem_irq_ack xilinx.com:signal:interrupt_rtl:1.0 [ipx::current_core]

# End of Actual IP Settings
#####################################

ipx::create_xgui_files [ipx::current_core]
ipx::update_checksums  [ipx::current_core]
ipx::save_core         [ipx::current_core]
