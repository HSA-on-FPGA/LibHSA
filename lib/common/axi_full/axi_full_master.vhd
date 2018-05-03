-- Copyright (C) 2017 Philipp Holzinger
-- Copyright (C) 2017 Martin Stumpf
-- 
-- This program is free software: you can redistribute it and/or modify
-- it under the terms of the GNU General Public License as published by
-- the Free Software Foundation, either version 3 of the License, or
-- (at your option) any later version.
-- 
-- This program is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU General Public License
-- along with this program.  If not, see <http://www.gnu.org/licenses/>.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity axi_full_master is
	generic (
		C_M_AXI_ADDR_WIDTH	: integer	:= 32;
		C_M_AXI_DATA_WIDTH	: integer	:= 32;
		C_M_AXI_CACHEABLE_TXN	: boolean	:= false
	);
	port (
		-- adress the CPU wants to access
		CPU_ADDR : in std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		-- data the CPU wants to write
		CPU_WDATA : in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		-- data the CPU wants to read
		CPU_RDATA : out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		-- signal to indicate if the CPU wants to read (0) or write (1)
		CPU_ACCESS_MODE : in std_logic;

		-- Initiate AXI transactions (must be asserted until TXN_DONE is high 
		-- and deasserted for at least one clock cycle between two transactions)
		INIT_AXI_TXN	: in std_logic;
		-- Asserts when ERROR is detected
		ERROR	: out std_logic;
		-- Asserts when AXI transactions is complete
		TXN_DONE	: out std_logic;

		-- AXI clock signal
		M_AXI_ACLK	: in std_logic;
		-- AXI active low reset signal
		M_AXI_ARESETN	: in std_logic;
		-- Master Interface Write Address ID
		M_AXI_AWID	: out std_logic_vector(0 downto 0);
		-- Master Interface Write Address
		M_AXI_AWADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		-- Burst length. The burst length gives the exact number of transfers in a burst
		M_AXI_AWLEN	: out std_logic_vector(7 downto 0);
		-- Burst size. This signal indicates the size of each transfer in the burst
		M_AXI_AWSIZE	: out std_logic_vector(2 downto 0);
		-- Burst type. The burst type and the size information, 
		-- determine how the address for each transfer within the burst is calculated.
		M_AXI_AWBURST	: out std_logic_vector(1 downto 0);
		-- Lock type. Provides additional information about the
		-- atomic characteristics of the transfer.
		M_AXI_AWLOCK	: out std_logic;
		-- Memory type. This signal indicates how transactions
		-- are required to progress through a system.
		M_AXI_AWCACHE	: out std_logic_vector(3 downto 0);
		-- Protection type. This signal indicates the privilege
		-- and security level of the transaction, and whether
		-- the transaction is a data access or an instruction access.
		M_AXI_AWPROT	: out std_logic_vector(2 downto 0);
		-- Quality of Service, QoS identifier sent for each write transaction.
		M_AXI_AWQOS	: out std_logic_vector(3 downto 0);
		-- Write address valid. This signal indicates that
		-- the channel is signaling valid write address and control information.
		M_AXI_AWVALID	: out std_logic;
		-- Write address ready. This signal indicates that
		-- the slave is ready to accept an address and associated control signals
		M_AXI_AWREADY	: in std_logic;
		-- Master Interface Write Data.
		M_AXI_WDATA	: out std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte
		-- lanes hold valid data. There is one write strobe
		-- bit for each eight bits of the write data bus.
		M_AXI_WSTRB	: out std_logic_vector(C_M_AXI_DATA_WIDTH/8-1 downto 0);
		-- Write last. This signal indicates the last transfer in a write burst.
		M_AXI_WLAST	: out std_logic;
		-- Write valid. This signal indicates that valid write
		-- data and strobes are available
		M_AXI_WVALID	: out std_logic;
		-- Write ready. This signal indicates that the slave
		-- can accept the write data.
		M_AXI_WREADY	: in std_logic;
		-- Master Interface Write Response.
		M_AXI_BID	: in std_logic_vector(0 downto 0);
		-- Write response. This signal indicates the status of the write transaction.
		M_AXI_BRESP	: in std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the
		-- channel is signaling a valid write response.
		M_AXI_BVALID	: in std_logic;
		-- Response ready. This signal indicates that the master
		-- can accept a write response.
		M_AXI_BREADY	: out std_logic;
		-- Master Interface Read Address.
		M_AXI_ARID	: out std_logic_vector(0 downto 0);
		-- Read address. This signal indicates the initial
		-- address of a read burst transaction.
		M_AXI_ARADDR	: out std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
		-- Burst length. The burst length gives the exact number of transfers in a burst
		M_AXI_ARLEN	: out std_logic_vector(7 downto 0);
		-- Burst size. This signal indicates the size of each transfer in the burst
		M_AXI_ARSIZE	: out std_logic_vector(2 downto 0);
		-- Burst type. The burst type and the size information, 
		-- determine how the address for each transfer within the burst is calculated.
		M_AXI_ARBURST	: out std_logic_vector(1 downto 0);
		-- Lock type. Provides additional information about the
		-- atomic characteristics of the transfer.
		M_AXI_ARLOCK	: out std_logic;
		-- Memory type. This signal indicates how transactions
		-- are required to progress through a system.
		M_AXI_ARCACHE	: out std_logic_vector(3 downto 0);
		-- Protection type. This signal indicates the privilege
		-- and security level of the transaction, and whether
		-- the transaction is a data access or an instruction access.
		M_AXI_ARPROT	: out std_logic_vector(2 downto 0);
		-- Quality of Service, QoS identifier sent for each read transaction
		M_AXI_ARQOS	: out std_logic_vector(3 downto 0);
		-- Write address valid. This signal indicates that
		-- the channel is signaling valid read address and control information
		M_AXI_ARVALID	: out std_logic;
		-- Read address ready. This signal indicates that
		-- the slave is ready to accept an address and associated control signals
		M_AXI_ARREADY	: in std_logic;
		-- Read ID tag. This signal is the identification tag
		-- for the read data group of signals generated by the slave.
		M_AXI_RID	: in std_logic_vector(0 downto 0);
		-- Master Read Data
		M_AXI_RDATA	: in std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the read transfer
		M_AXI_RRESP	: in std_logic_vector(1 downto 0);
		-- Read last. This signal indicates the last transfer in a read burst
		M_AXI_RLAST	: in std_logic;
		-- Read valid. This signal indicates that the channel
		-- is signaling the required read data.
		M_AXI_RVALID	: in std_logic;
		-- Read ready. This signal indicates that the master can
		-- accept the read data and response information.
		M_AXI_RREADY	: out std_logic
	);
end axi_full_master;

architecture implementation of axi_full_master is
	type state is ( IDLE, 		-- This state initiates AXI4 transaction
	 	 			-- the state machine changes state to INIT_WRITE or INIT_READ
	 				-- when there is 0 to 1 transition on INIT_AXI_TXN
	 		INIT_WRITE,   	-- This state initializes write transaction
			INIT_READ,   	-- This state initializes read transaction
			SYNCHRONIZE);   -- This state manages the clock domain crossing of read data

	signal mst_exec_state	: state;
 
	constant BURST_LENGTH	: integer := C_M_AXI_DATA_WIDTH/C_M_AXI_DATA_WIDTH;
	constant INCR		: std_logic_vector(1 downto 0) := "01";

	-- AXI4 signals
	--write address valid
	signal axi_awvalid	: std_logic;
	--write data valid
	signal axi_wvalid	: std_logic;
	--read address valid
	signal axi_arvalid	: std_logic;
	--read data acceptance
	signal axi_rready	: std_logic;
	--write response acceptance
	signal axi_bready	: std_logic;
	--write address
	signal axi_awaddr	: std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
	--write data
	signal axi_wdata	: std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
	--read addresss
	signal axi_araddr	: std_logic_vector(C_M_AXI_ADDR_WIDTH-1 downto 0);
	--read data
	signal axi_rdata	: std_logic_vector(C_M_AXI_DATA_WIDTH-1 downto 0);
	--Asserts when there is a write response error
	signal write_resp_error	: std_logic;
	--Asserts when there is a read response error
	signal read_resp_error	: std_logic;
	--A pulse to initiate a write transaction
	signal start_single_write	: std_logic;
	--A pulse to initiate a read transaction
	signal start_single_read	: std_logic;
	--The error register is asserted when any of the write response error, read response error or the data mismatch flags are asserted.
	signal error_reg	: std_logic;
	-- additional signals
	signal init_txn_ff	: std_logic;
	signal init_txn_pulse	: std_logic;

begin
	-- I/O Connections assignments

	M_AXI_AWID	<= (others => '0');
	M_AXI_AWADDR	<= axi_awaddr;
	--Burst length is number of transaction beats, minus 1
	M_AXI_AWLEN	<= std_logic_vector(to_unsigned(BURST_LENGTH-1,M_AXI_AWLEN'length));
	--Size should be C_M_AXI_DATA_WIDTH, in 2^n bytes
	M_AXI_AWSIZE	<= std_logic_vector(to_unsigned(integer(ceil(log2(real((C_M_AXI_DATA_WIDTH/8)-1)))),M_AXI_AWSIZE'length));
	--INCR burst type is usually used
	M_AXI_AWBURST	<= INCR;
	M_AXI_AWLOCK	<= '0';
	M_AXI_AWPROT	<= "000";
	M_AXI_AWQOS	<= x"0";
	M_AXI_AWVALID	<= axi_awvalid;
	--Write Data(W)
	M_AXI_WDATA	<= axi_wdata;
	M_AXI_WSTRB	<= (others => '1');
	M_AXI_WLAST	<= '1';
	M_AXI_WVALID	<= axi_wvalid;
	--Write Response (B)
	M_AXI_BREADY	<= axi_bready;
	--Read Address (AR)
	M_AXI_ARID	<= (others => '0');
	M_AXI_ARADDR	<= axi_araddr;
	--Burst length is number of transaction beats, minus 1
	M_AXI_ARLEN	<= std_logic_vector(to_unsigned(BURST_LENGTH-1,M_AXI_ARLEN'length));
	--Size should be C_M_AXI_DATA_WIDTH, in 2^n bytes
	M_AXI_ARSIZE	<= std_logic_vector(to_unsigned(integer(ceil(log2(real((C_M_AXI_DATA_WIDTH/8)-1)))),M_AXI_ARSIZE'length));
	--INCR burst type is usually used, except for keyhole bursts
	M_AXI_ARBURST	<= INCR;
	M_AXI_ARLOCK	<= '0';
	M_AXI_ARPROT	<= "000";
	M_AXI_ARQOS	<= x"0";
	M_AXI_ARVALID	<= axi_arvalid;
	--Read and Read Response (R)
	M_AXI_RREADY	<= axi_rready;
	
	gen_cacheable_signals: if C_M_AXI_CACHEABLE_TXN = true generate
		M_AXI_AWCACHE	<= "1100";
		M_AXI_ARCACHE	<= "1100";
	end generate gen_cacheable_signals;
	gen_not_cacheable_signals: if C_M_AXI_CACHEABLE_TXN = false generate
		M_AXI_AWCACHE	<= "0010";
		M_AXI_ARCACHE	<= "0010";
	end generate gen_not_cacheable_signals;

	ERROR 		<= error_reg;                                                               
	init_txn_pulse	<= ( not init_txn_ff)  and  INIT_AXI_TXN;


	--Generate a pulse to initiate AXI transaction.
	process(M_AXI_ACLK)                                                          
	begin                                                                             
	  if (rising_edge (M_AXI_ACLK)) then                                              
	      -- Initiates AXI transaction delay        
	    if (M_AXI_ARESETN = '0' ) then                                                
	      init_txn_ff <= '0';                                                   
	    else                                                                                       
	      init_txn_ff <= INIT_AXI_TXN;
	    end if;                                                                       
	  end if;                                                                         
	end process; 

	  process(M_AXI_ACLK)                                                          
	  begin                                                                             
	    if (rising_edge (M_AXI_ACLK)) then                                              
	      --Only VALID signals must be deasserted during reset per AXI spec             
	      --Consider inverting then registering active-low reset for higher fmax        
	      if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                                
	        axi_awvalid <= '0';                                                         
	      else                                                                          
	        --Signal a new address/data command is available by user logic              
	        if (start_single_write = '1') then                                          
	          axi_awvalid <= '1';                                                       
	        elsif (M_AXI_AWREADY = '1' and axi_awvalid = '1') then                      
	          --Address accepted by interconnect/slave (issue of M_AXI_AWREADY by slave)
	          axi_awvalid <= '0';                                                       
	        end if;                                                                     
	      end if;                                                                       
	    end if;                                                                         
	  end process;                                                                      

	   process(M_AXI_ACLK)                                                 
	   begin                                                                         
	     if (rising_edge (M_AXI_ACLK)) then                                          
	       if (M_AXI_ARESETN = '0' or init_txn_pulse = '1' ) then                                            
	         axi_wvalid <= '0';                                                      
	       else                                                                      
	         if (start_single_write = '1') then                                      
	           --Signal a new address/data command is available by user logic        
	           axi_wvalid <= '1';                                                    
	         elsif (M_AXI_WREADY = '1' and axi_wvalid = '1') then                    
	           --Data accepted by interconnect/slave (issue of M_AXI_WREADY by slave)
	           axi_wvalid <= '0';                                                    
	         end if;                                                                 
	       end if;                                                                   
	     end if;                                                                     
	   end process;                                                                  

	  process(M_AXI_ACLK)                                            
	  begin                                                                
	    if (rising_edge (M_AXI_ACLK)) then                                 
	      if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                   
	        axi_bready <= '0';                                             
	      else                                                             
	        if (axi_awvalid = '1' and axi_wvalid = '1' and axi_bready = '0') then              
	          -- accept/acknowledge bresp with axi_bready by the master                    
	           axi_bready <= '1';                                          
	        elsif (M_AXI_BVALID = '1' and axi_bready = '1') then                                  
	          -- deassert after handshake                            
	          axi_bready <= '0';
		else
		  axi_bready <= axi_bready;                                           
	        end if;                                                        
	      end if;                                                          
	    end if;                                                            
	  end process;                                                         
	--Flag write errors                                                    
	  write_resp_error <= (axi_bready and M_AXI_BVALID and M_AXI_BRESP(1));

	  process(M_AXI_ACLK)                                                              
	  begin                                                                            
	    if (rising_edge (M_AXI_ACLK)) then                                             
	      if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                               
	        axi_arvalid <= '0';                                                        
	      else                                                                         
	        if (start_single_read = '1') then                                          
	          --Signal a new read address command is available by user logic           
	          axi_arvalid <= '1';                                                      
	        elsif (M_AXI_ARREADY = '1' and axi_arvalid = '1') then                     
	        --RAddress accepted by interconnect/slave (issue of M_AXI_ARREADY by slave)
	          axi_arvalid <= '0';                                                      
	        end if;                                                                    
	      end if;                                                                      
	    end if;                                                                        
	  end process;                                                                     

	  process(M_AXI_ACLK)                                             
	  begin                                                                 
	    if (rising_edge (M_AXI_ACLK)) then                                  
	      if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                    
	        axi_rready <= '0';                                              
	      else                                                              
	        if (axi_arvalid = '1' and axi_rready = '0') then               
	         -- accept/acknowledge rdata/rresp with axi_rready by the master
	          axi_rready <= '1';                                            
	        elsif (M_AXI_RVALID = '1' and axi_rready = '1') then                                   
	          -- deassert                             
	          axi_rready <= '0';
		else
		  axi_rready <= axi_rready;                                            
	        end if;                                                         
	      end if;                                                           
	    end if;                                                             
	  end process;                                                          
	                                                                        
	--Flag write errors                                                     
	  read_resp_error <= (axi_rready and M_AXI_RVALID and M_AXI_RRESP(1));  

	--  Write Addresses                                                               
	    process(M_AXI_ACLK)                                                                 
	      begin                                                                            
	    	if (rising_edge (M_AXI_ACLK)) then                                              
	    	  if (M_AXI_ARESETN = '0') then
	    	    axi_awaddr <= (others => '0');                                              
	    	  else                        
	    	    -- Signals a new write address/ write data is                               
	    	    -- available by user logic                                                  
	    	    axi_awaddr <= CPU_ADDR; 
	    	  end if;                                                                       
	    	end if;                                                                         
	      end process;                                                                     
	                                                                                       
	-- Read Addresses                                                                      
	    process(M_AXI_ACLK)                                                                
	   	  begin                                                                         
	   	    if (rising_edge (M_AXI_ACLK)) then                                          
	   	      if (M_AXI_ARESETN = '0') then
	   	        axi_araddr <= (others => '0');                                          
	   	      else                    
	   	        -- Signals a new read address/ read data is                           
	   	        -- available by user logic                                              
	   	        axi_araddr <= CPU_ADDR; 
	   	      end if;                                                                   
	   	    end if;                                                                     
	   	  end process;                                                                  
		                                                                                    
	-- Write data                                                                          
	    process(M_AXI_ACLK)                                                                
		  begin                                                                             
		    if (rising_edge (M_AXI_ACLK)) then                                              
		      if (M_AXI_ARESETN = '0') then                                                
		        axi_wdata <= (others => '0');                             
		      else                          
		        -- Signals a new write address/ write data is                               
		        -- available by user logic                                                  
		        axi_wdata <= CPU_WDATA; 
		      end if;                                                                       
		    end if;                                                                         
		  end process;                                                                      
		                                                                                    
		                                                                                    
	-- Read data                                                                  
	    process(M_AXI_ACLK)                                                                
	    begin                                                                              
	      if (rising_edge (M_AXI_ACLK)) then                                               
	        if (M_AXI_ARESETN = '0' or init_txn_pulse = '1' ) then                                                 
	          axi_rdata <= (others => '0');
	        elsif(M_AXI_RVALID = '1') then                          
	          -- Signals a new read address/read data is                                
	          -- available by user logic                                                   
	          axi_rdata <= M_AXI_RDATA;
	        else
	          -- hold the value until synchronizing handshake is complete
	          axi_rdata <= axi_rdata;
	        end if;                                                                        
	      end if;                                                                          
	    end process;                    
	
	    CPU_RDATA <= axi_rdata;

	 
	  --implement master command interface state machine                                           
	  MASTER_EXECUTION_PROC:process(M_AXI_ACLK)                                                         
	  begin                                                                                             
	    if (rising_edge (M_AXI_ACLK)) then                                                              
	      if (M_AXI_ARESETN = '0' ) then                                                                
	        -- reset condition                                                                          
	        -- All the signals are ed default values under reset condition                              
	        mst_exec_state     <= IDLE;                                                            
		TXN_DONE           <= '0';
	        start_single_write <= '0';                                                                  
	        start_single_read  <= '0';                                                                  
	      else                                                                                          
	        -- prevent latches
		TXN_DONE           <= '0';
		start_single_write <= '0';                                                                  
	        start_single_read  <= '0';                                                                  
	        -- state transition                                                                         
	        case (mst_exec_state) is                                                                                          
	          when IDLE =>                                                                      
	            -- This state is responsible to initiate
	            -- AXI transaction when init_txn_pulse is asserted 
	            if ( init_txn_pulse = '1') then    
		      if(CPU_ACCESS_MODE = '0') then
	                if (axi_arvalid = '0' and M_AXI_RVALID = '0' and start_single_read = '0') then                                 
	              	  mst_exec_state  <= INIT_READ;                                                        
	                  start_single_read <= '1';                                                           
			end if;                                    
		      else
	              	if (axi_awvalid = '0' and axi_wvalid = '0' and M_AXI_BVALID = '0' and start_single_write = '0') then          
	              	  mst_exec_state  <= INIT_WRITE;
	                  start_single_write <= '1';                                                          
			end if;                                                               
		      end if;
	            else                                                                                    
	              mst_exec_state  <= IDLE;                                                      
	            end if;                                                                                 
	                                                                                                    
	          when INIT_WRITE =>                                                                        
	            -- write controller                                                                     
	              if (M_AXI_BVALID = '1') then                                                         
	                mst_exec_state  <= SYNCHRONIZE;                                         
	              else                                                                                  
	                mst_exec_state  <= INIT_WRITE;                                                        
	                start_single_write <= '0'; --Negate to generate a pulse                             
	              end if;                                                                               
	                                                                                                    
	          when INIT_READ =>                                                                         
	            -- read controller                                                                      
	              if (M_AXI_RVALID = '1') then                                                         
	                mst_exec_state  <= SYNCHRONIZE;
	              else                                                                                  
	                mst_exec_state  <= INIT_READ;                                                         
	                start_single_read <= '0'; --Negate to generate a pulse                              
	              end if;                                                                               
	          
		   when SYNCHRONIZE =>
		     -- synchronization with clock of requesting unit
		     TXN_DONE <= '1';
		     if(INIT_AXI_TXN = '0') then
		       mst_exec_state <= IDLE;
		     else
		       mst_exec_state <= SYNCHRONIZE;
		     end if;

		   when others  =>                                                                           
	              mst_exec_state  <= IDLE;                                                      
	        end case  ;                                                                                 
	      end if;                                                                                       
	    end if;                                                                                         
	  end process;                                                                                      
	                                                                                                    
	-- Register and hold any read/write interface errors                            
	  process(M_AXI_ACLK)                                                                               
	  begin                                                                                             
	    if (rising_edge (M_AXI_ACLK)) then                                                              
	      if (M_AXI_ARESETN = '0' or init_txn_pulse = '1') then                                                                
	        error_reg <= '0';                                                                           
	      else                                                                                          
	        if (write_resp_error = '1' or read_resp_error = '1') then            
	          --Capture any error types                                                                 
	          error_reg <= '1';                                                                         
	        end if;                                                                                     
	      end if;                                                                                       
	    end if;                                                                                         
	  end process;                                                                                      

end implementation;
