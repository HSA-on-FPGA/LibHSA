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


set script_directory "[file dirname "[file normalize "[info script]"]"]"

set bd_file [create_bd_design xilinx_datamover]
puts $bd_file
current_bd_design xilinx_datamover

########################################
# Ports
#

# Create interface ports
  create_bd_intf_port -mode Master \
                      -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_MM2S
  
  create_bd_intf_port -mode Master \
                      -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_MM2S_STS
  
  create_bd_intf_port -mode Master \
                      -vlnv xilinx.com:interface:axis_rtl:1.0 M_AXIS_S2MM_STS

  create_bd_intf_port -mode Master \
                      -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_MM2S
  set_property -dict [ list \
    CONFIG.ADDR_WIDTH {64} \
    CONFIG.DATA_WIDTH {512} \
    CONFIG.HAS_BRESP {0} \
    CONFIG.HAS_BURST {1} \
    CONFIG.HAS_CACHE {1} \
    CONFIG.HAS_LOCK {0} \
    CONFIG.HAS_PROT {0} \
    CONFIG.HAS_QOS {0} \
    CONFIG.HAS_REGION {0} \
    CONFIG.HAS_WSTRB {0} \
    CONFIG.NUM_READ_OUTSTANDING {2} \
    CONFIG.NUM_WRITE_OUTSTANDING {2} \
    CONFIG.PROTOCOL {AXI4} \
    CONFIG.READ_WRITE_MODE {READ_ONLY} \
  ] [get_bd_intf_ports M_AXI_MM2S]

  create_bd_intf_port -mode Master \
                      -vlnv xilinx.com:interface:aximm_rtl:1.0 M_AXI_S2MM
  set_property -dict [ list \
    CONFIG.ADDR_WIDTH {64} \
    CONFIG.DATA_WIDTH {512} \
    CONFIG.HAS_BURST {1} \
    CONFIG.HAS_CACHE {1} \
    CONFIG.HAS_LOCK {0} \
    CONFIG.HAS_PROT {0} \
    CONFIG.HAS_QOS {0} \
    CONFIG.HAS_REGION {0} \
    CONFIG.HAS_RRESP {0} \
    CONFIG.NUM_READ_OUTSTANDING {2} \
    CONFIG.NUM_WRITE_OUTSTANDING {2} \
    CONFIG.PROTOCOL {AXI4} \
    CONFIG.READ_WRITE_MODE {WRITE_ONLY} \
  ] [get_bd_intf_ports M_AXI_S2MM]

  create_bd_intf_port -mode Slave \
                      -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_MM2S_CMD
  set_property -dict [ list \
    CONFIG.HAS_TKEEP {0} \
    CONFIG.HAS_TLAST {0} \
    CONFIG.HAS_TREADY {1} \
    CONFIG.HAS_TSTRB {0} \
    CONFIG.LAYERED_METADATA {undef} \
    CONFIG.PHASE {0.000} \
    CONFIG.TDATA_NUM_BYTES {13} \
    CONFIG.TDEST_WIDTH {0} \
    CONFIG.TID_WIDTH {0} \
    CONFIG.TUSER_WIDTH {0} \
  ] [get_bd_intf_ports S_AXIS_MM2S_CMD]

  create_bd_intf_port -mode Slave \
                      -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_S2MM
  set_property -dict [ list \
    CONFIG.HAS_TKEEP {1} \
    CONFIG.HAS_TLAST {1} \
    CONFIG.HAS_TREADY {1} \
    CONFIG.HAS_TSTRB {0} \
    CONFIG.LAYERED_METADATA {undef} \
    CONFIG.PHASE {0.000} \
    CONFIG.TDATA_NUM_BYTES {4} \
    CONFIG.TDEST_WIDTH {0} \
    CONFIG.TID_WIDTH {0} \
    CONFIG.TUSER_WIDTH {0} \
 ] [get_bd_intf_ports S_AXIS_S2MM]

 create_bd_intf_port -mode Slave \
                     -vlnv xilinx.com:interface:axis_rtl:1.0 S_AXIS_S2MM_CMD
  set_property -dict [ list \
    CONFIG.HAS_TKEEP {0} \
    CONFIG.HAS_TLAST {0} \
    CONFIG.HAS_TREADY {1} \
    CONFIG.HAS_TSTRB {0} \
    CONFIG.LAYERED_METADATA {undef} \
    CONFIG.PHASE {0.000} \
    CONFIG.TDATA_NUM_BYTES {13} \
    CONFIG.TDEST_WIDTH {0} \
    CONFIG.TID_WIDTH {0} \
    CONFIG.TUSER_WIDTH {0} \
 ] [get_bd_intf_ports S_AXIS_S2MM_CMD]




# Create ports
    create_bd_port -dir I -type rst aresetn
    set_property -dict [ list \
        CONFIG.POLARITY {ACTIVE_LOW} \
    ] [get_bd_ports aresetn]

    create_bd_port -dir I -type clk aclk
    set_property -dict [ list \
        CONFIG.ASSOCIATED_RESET {aresetn} \
    ] [get_bd_ports aclk]
    
    create_bd_port -dir O mm2s_err
    create_bd_port -dir O s2mm_err




########################################
# IP Instances
#
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_datamover:5.1 axi_datamover_0
  set_property -dict [ list \
    CONFIG.c_addr_width {64} \
    CONFIG.c_include_mm2s_dre {false} \
    CONFIG.c_include_s2mm_dre {false} \
    CONFIG.c_m_axi_mm2s_data_width {512} \
    CONFIG.c_m_axi_s2mm_data_width {512} \
    CONFIG.c_mm2s_burst_size {16} \
    CONFIG.c_s2mm_burst_size {16} \
    CONFIG.c_mm2s_btt_used {23} \
    CONFIG.c_s2mm_btt_used {23} \
 ] [get_bd_cells axi_datamover_0]


########################################
# Connections
#

# Not beautified, just copy-paste
# TODO beautify

  # Create interface connections
  connect_bd_intf_net -intf_net S_AXIS_MM2S_CMD_1 [get_bd_intf_ports S_AXIS_MM2S_CMD] [get_bd_intf_pins axi_datamover_0/S_AXIS_MM2S_CMD]
  connect_bd_intf_net -intf_net S_AXIS_S2MM_1 [get_bd_intf_ports S_AXIS_S2MM] [get_bd_intf_pins axi_datamover_0/S_AXIS_S2MM]
  connect_bd_intf_net -intf_net S_AXIS_S2MM_CMD_1 [get_bd_intf_ports S_AXIS_S2MM_CMD] [get_bd_intf_pins axi_datamover_0/S_AXIS_S2MM_CMD]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXIS_MM2S [get_bd_intf_ports M_AXIS_MM2S] [get_bd_intf_pins axi_datamover_0/M_AXIS_MM2S]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXIS_MM2S_STS [get_bd_intf_ports M_AXIS_MM2S_STS] [get_bd_intf_pins axi_datamover_0/M_AXIS_MM2S_STS]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXIS_S2MM_STS [get_bd_intf_ports M_AXIS_S2MM_STS] [get_bd_intf_pins axi_datamover_0/M_AXIS_S2MM_STS]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXI_MM2S [get_bd_intf_ports M_AXI_MM2S] [get_bd_intf_pins axi_datamover_0/M_AXI_MM2S]
  connect_bd_intf_net -intf_net axi_datamover_0_M_AXI_S2MM [get_bd_intf_ports M_AXI_S2MM] [get_bd_intf_pins axi_datamover_0/M_AXI_S2MM]

  # Create port connections
  connect_bd_net -net axi_datamover_0_mm2s_err [get_bd_ports mm2s_err] [get_bd_pins axi_datamover_0/mm2s_err]
  connect_bd_net -net axi_datamover_0_s2mm_err [get_bd_ports s2mm_err] [get_bd_pins axi_datamover_0/s2mm_err]
  connect_bd_net -net clk_1 [get_bd_ports aclk] [get_bd_pins axi_datamover_0/m_axi_mm2s_aclk] [get_bd_pins axi_datamover_0/m_axi_s2mm_aclk] [get_bd_pins axi_datamover_0/m_axis_mm2s_cmdsts_aclk] [get_bd_pins axi_datamover_0/m_axis_s2mm_cmdsts_awclk]
  connect_bd_net -net rst_1 [get_bd_ports aresetn] [get_bd_pins axi_datamover_0/m_axi_mm2s_aresetn] [get_bd_pins axi_datamover_0/m_axi_s2mm_aresetn] [get_bd_pins axi_datamover_0/m_axis_mm2s_cmdsts_aresetn] [get_bd_pins axi_datamover_0/m_axis_s2mm_cmdsts_aresetn]

########################################
# Addresses Space Config
#


  # Create address segments
  create_bd_addr_seg -range 0x00010000000000000000 -offset 0x00000000 \
    [get_bd_addr_spaces axi_datamover_0/Data_MM2S] \
    [get_bd_addr_segs M_AXI_MM2S/Reg] SEG_M_AXI_MM2S_Reg
  
  create_bd_addr_seg -range 0x00010000000000000000 -offset 0x00000000 \
    [get_bd_addr_spaces axi_datamover_0/Data_S2MM] \
    [get_bd_addr_segs M_AXI_S2MM/Reg] SEG_M_AXI_S2MM_Reg



########################################
# Final touches
#

# Beautify
regenerate_bd_layout
regenerate_bd_layout -routing

# Save
save_bd_design

# Generate Files
generate_target all [get_files [get_property FILE_NAME $bd_file]]

# Generate Wrapper
add_files [make_wrapper -top [get_files [get_property FILE_NAME $bd_file]]]
