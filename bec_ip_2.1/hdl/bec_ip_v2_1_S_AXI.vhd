library ieee;
library xil_defaultlib;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_unsigned.all;
use xil_defaultlib.acb_package.all; 

entity bec_ip_v2_1_S_AXI is
	generic (
		-- Users to add parameters here
        BEC_DATA_BUS_WIDTH	: integer	:= 163; 
		-- User parameters ends
		-- Do not modify the parameters beyond this line

		-- Width of S_AXI data bus
		C_S_AXI_DATA_WIDTH	: integer	:= 32;
		-- Width of S_AXI address bus
		C_S_AXI_ADDR_WIDTH	: integer	:= 5
	);
	port (
		-- Users to add ports here

		-- User ports ends
		-- Do not modify the ports beyond this line

		-- Global Clock Signal
		S_AXI_ACLK	: in std_logic;
		-- Global Reset Signal. This Signal is Active LOW
		S_AXI_ARESETN	: in std_logic;
		-- Write address (issued by master, acceped by Slave)
		S_AXI_AWADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Write channel Protection type. This signal indicates the
    		-- privilege and security level of the transaction, and whether
    		-- the transaction is a data access or an instruction access.
		S_AXI_AWPROT	: in std_logic_vector(2 downto 0);
		-- Write address valid. This signal indicates that the master signaling
    		-- valid write address and control information.
		S_AXI_AWVALID	: in std_logic;
		-- Write address ready. This signal indicates that the slave is ready
    		-- to accept an address and associated control signals.
		S_AXI_AWREADY	: out std_logic;
		-- Write data (issued by master, acceped by Slave) 
		S_AXI_WDATA	: in std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Write strobes. This signal indicates which byte lanes hold
    		-- valid data. There is one write strobe bit for each eight
    		-- bits of the write data bus.    
		S_AXI_WSTRB	: in std_logic_vector((C_S_AXI_DATA_WIDTH/8)-1 downto 0);
		-- Write valid. This signal indicates that valid write
    		-- data and strobes are available.
		S_AXI_WVALID	: in std_logic;
		-- Write ready. This signal indicates that the slave
    		-- can accept the write data.
		S_AXI_WREADY	: out std_logic;
		-- Write response. This signal indicates the status
    		-- of the write transaction.
		S_AXI_BRESP	: out std_logic_vector(1 downto 0);
		-- Write response valid. This signal indicates that the channel
    		-- is signaling a valid write response.
		S_AXI_BVALID	: out std_logic;
		-- Response ready. This signal indicates that the master
    		-- can accept a write response.
		S_AXI_BREADY	: in std_logic;
		-- Read address (issued by master, acceped by Slave)
		S_AXI_ARADDR	: in std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
		-- Protection type. This signal indicates the privilege
    		-- and security level of the transaction, and whether the
    		-- transaction is a data access or an instruction access.
		S_AXI_ARPROT	: in std_logic_vector(2 downto 0);
		-- Read address valid. This signal indicates that the channel
    		-- is signaling valid read address and control information.
		S_AXI_ARVALID	: in std_logic;
		-- Read address ready. This signal indicates that the slave is
    		-- ready to accept an address and associated control signals.
		S_AXI_ARREADY	: out std_logic;
		-- Read data (issued by slave)
		S_AXI_RDATA	: out std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
		-- Read response. This signal indicates the status of the
    		-- read transfer.
		S_AXI_RRESP	: out std_logic_vector(1 downto 0);
		-- Read valid. This signal indicates that the channel is
    		-- signaling the required read data.
		S_AXI_RVALID	: out std_logic;
		-- Read ready. This signal indicates that the master can
    		-- accept the read data and response information.
		S_AXI_RREADY	: in std_logic
	);
end bec_ip_v2_1_S_AXI;

architecture arch_imp of bec_ip_v2_1_S_AXI is
    
    -- SM_BEC_module 
	component sm_bec 
	port(
		clk, rst, enable 	: in std_logic; 
		w1, z1				: in std_logic_vector(BEC_DATA_BUS_WIDTH-1 downto 0);
		w2, z2				: in std_logic_vector(BEC_DATA_BUS_WIDTH-1 downto 0);
		ki					: in std_logic; 

		d,inv_w0 			: in std_logic_vector(BEC_DATA_BUS_WIDTH-1 downto 0);

		next_key 			: out std_logic; 
		done				: out std_logic;
		wout, zout			: out std_logic_vector(BEC_DATA_BUS_WIDTH-1 downto 0)
	); 
	end component;
	
	-- AXI4LITE signals
	signal axi_awaddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_awready	: std_logic;
	signal axi_wready	: std_logic;
	signal axi_bresp	: std_logic_vector(1 downto 0);
	signal axi_bvalid	: std_logic;
	signal axi_araddr	: std_logic_vector(C_S_AXI_ADDR_WIDTH-1 downto 0);
	signal axi_arready	: std_logic;
	signal axi_rdata	: std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal axi_rresp	: std_logic_vector(1 downto 0);
	signal axi_rvalid	: std_logic;

	-- Example-specific design signals
	-- local parameter for addressing 32 bit / 64 bit C_S_AXI_DATA_WIDTH
	-- ADDR_LSB is used for addressing 32/64 bit registers/memories
	-- ADDR_LSB = 2 for 32 bits (n downto 2)
	-- ADDR_LSB = 3 for 64 bits (n downto 3)
	constant ADDR_LSB  : integer := (C_S_AXI_DATA_WIDTH/32)+ 1;
	constant OPT_MEM_ADDR_BITS : integer := 2;
	------------------------------------------------
	---- Signals for user logic register space example
	--------------------------------------------------
	---- Number of Slave Registers 6
	signal rst_w           :std_logic; 
	signal enable_reg	   :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal key_reg	       :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal next_key_reg	   :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal wout_reg	       :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal zout_reg	       :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal done_reg	       :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	
	signal en_IP           :std_logic; 
	signal en_BEC          :std_logic; 
	
	signal key_w           :std_logic; 
	signal key_tmp         :std_logic_vector(BEC_DATA_BUS_WIDTH-1 downto 0); 
	signal count_key       :integer; 
	signal key_tmp_1       :std_logic_vector(BEC_DATA_BUS_WIDTH-1 downto 0);
	signal next_key_w      :std_logic; 
	signal wen_key         :std_logic;
	signal shift_k         :std_logic;
	signal wout_tmp        :std_logic_vector(BEC_DATA_BUS_WIDTH-1 downto 0);
	signal zout_tmp        :std_logic_vector(BEC_DATA_BUS_WIDTH-1 downto 0);
	signal wout_tmp1       :std_logic_vector(BEC_DATA_BUS_WIDTH-1 downto 0);
	signal zout_tmp1       :std_logic_vector(BEC_DATA_BUS_WIDTH-1 downto 0);
	signal done_w          :std_logic; 
	signal ren_res         :std_logic; 
	
	signal count_key_r     :std_logic_vector(2 downto 0); 
	signal count_result_1    :std_logic_vector(2 downto 0); 
	signal count_result_2    :std_logic_vector(2 downto 0); 
	
	signal slv_reg_rden	   :std_logic;
	signal slv_reg_wren	   :std_logic;
	signal reg_data_out	   :std_logic_vector(C_S_AXI_DATA_WIDTH-1 downto 0);
	signal byte_index	   :integer;
	signal aw_en	       :std_logic;
	
	type state is (IDLE, WRITE_KEY, SHIFT_KEY, COMPUTING, READ_RESULT);
	signal fsm_state : state;

begin
	-- I/O Connections assignments

	S_AXI_AWREADY	<= axi_awready;
	S_AXI_WREADY	<= axi_wready;
	S_AXI_BRESP	<= axi_bresp;
	S_AXI_BVALID	<= axi_bvalid;
	S_AXI_ARREADY	<= axi_arready;
	S_AXI_RDATA	<= axi_rdata;
	S_AXI_RRESP	<= axi_rresp;
	S_AXI_RVALID	<= axi_rvalid;
	-- Implement axi_awready generation
	-- axi_awready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_awready is
	-- de-asserted when reset is low.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awready <= '0';
	      aw_en <= '1';
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- slave is ready to accept write address when
	        -- there is a valid write address and write data
	        -- on the write address and data bus. This design 
	        -- expects no outstanding transactions. 
	           axi_awready <= '1';
	           aw_en <= '0';
	        elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then
	           aw_en <= '1';
	           axi_awready <= '0';
	      else
	        axi_awready <= '0';
	      end if;
	    end if;
	  end if;
	end process;

	-- Implement axi_awaddr latching
	-- This process is used to latch the address when both 
	-- S_AXI_AWVALID and S_AXI_WVALID are valid. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_awaddr <= (others => '0');
	    else
	      if (axi_awready = '0' and S_AXI_AWVALID = '1' and S_AXI_WVALID = '1' and aw_en = '1') then
	        -- Write Address latching
	        axi_awaddr <= S_AXI_AWADDR;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_wready generation
	-- axi_wready is asserted for one S_AXI_ACLK clock cycle when both
	-- S_AXI_AWVALID and S_AXI_WVALID are asserted. axi_wready is 
	-- de-asserted when reset is low. 

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_wready <= '0';
	    else
	      if (axi_wready = '0' and S_AXI_WVALID = '1' and S_AXI_AWVALID = '1' and aw_en = '1') then
	          -- slave is ready to accept write data when 
	          -- there is a valid write address and write data
	          -- on the write address and data bus. This design 
	          -- expects no outstanding transactions.           
	          axi_wready <= '1';
	      else
	        axi_wready <= '0';
	      end if;
	    end if;
	  end if;
	end process; 

	-- Implement memory mapped register select and write logic generation
	-- The write data is accepted and written to memory mapped registers when
	-- axi_awready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted. Write strobes are used to
	-- select byte enables of slave registers while writing.
	-- These registers are cleared when reset (active low) is applied.
	-- Slave register write enable is asserted when valid address and data are available
	-- and the slave is ready to accept the write address and write data.
	slv_reg_wren <= axi_wready and S_AXI_WVALID and axi_awready and S_AXI_AWVALID ;

	process (S_AXI_ACLK)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0); 
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      enable_reg       <= (others => '0');
	      key_reg          <= (others => '0');
	    
	    else
	      loc_addr := axi_awaddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	      if (slv_reg_wren = '1') then
	        case loc_addr is
	          when b"000" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 0
	                enable_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
	          when b"001" =>
	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
	                -- Respective byte enables are asserted as per write strobes                   
	                -- slave registor 1
	                key_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
	              end if;
	            end loop;
--	          when b"010" =>
--	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
--	                -- Respective byte enables are asserted as per write strobes                   
--	                -- slave registor 2
--	                next_key_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--	              end if;
--	            end loop;
--	          when b"011" =>
--	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
--	                -- Respective byte enables are asserted as per write strobes                   
--	                -- slave registor 3
--	                wout_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--	              end if;
--	            end loop;
--	          when b"100" =>
--	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
--	                -- Respective byte enables are asserted as per write strobes                   
--	                -- slave registor 4
--	                zout_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--	              end if;
--	            end loop;
--	          when b"101" =>
--	            for byte_index in 0 to (C_S_AXI_DATA_WIDTH/8-1) loop
--	              if ( S_AXI_WSTRB(byte_index) = '1' ) then
--	                -- Respective byte enables are asserted as per write strobes                   
--	                -- slave registor 5
--	                done_reg(byte_index*8+7 downto byte_index*8) <= S_AXI_WDATA(byte_index*8+7 downto byte_index*8);
--	              end if;
--	            end loop;
	          when others =>
	            enable_reg <= enable_reg;
	            key_reg <= key_reg;
	  
	        end case;
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement write response logic generation
	-- The write response and response valid signals are asserted by the slave 
	-- when axi_wready, S_AXI_WVALID, axi_wready and S_AXI_WVALID are asserted.  
	-- This marks the acceptance of address and indicates the status of 
	-- write transaction.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_bvalid  <= '0';
	      axi_bresp   <= "00"; --need to work more on the responses
	    else
	      if (axi_awready = '1' and S_AXI_AWVALID = '1' and axi_wready = '1' and S_AXI_WVALID = '1' and axi_bvalid = '0'  ) then
	        axi_bvalid <= '1';
	        axi_bresp  <= "00"; 
	      elsif (S_AXI_BREADY = '1' and axi_bvalid = '1') then   --check if bready is asserted while bvalid is high)
	        axi_bvalid <= '0';                                 -- (there is a possibility that bready is always asserted high)
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arready generation
	-- axi_arready is asserted for one S_AXI_ACLK clock cycle when
	-- S_AXI_ARVALID is asserted. axi_awready is 
	-- de-asserted when reset (active low) is asserted. 
	-- The read address is also latched when S_AXI_ARVALID is 
	-- asserted. axi_araddr is reset to zero on reset assertion.

	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then 
	    if S_AXI_ARESETN = '0' then
	      axi_arready <= '0';
	      axi_araddr  <= (others => '1');
	    else
	      if (axi_arready = '0' and S_AXI_ARVALID = '1') then
	        -- indicates that the slave has acceped the valid read address
	        axi_arready <= '1';
	        -- Read Address latching 
	        axi_araddr  <= S_AXI_ARADDR;           
	      else
	        axi_arready <= '0';
	      end if;
	    end if;
	  end if;                   
	end process; 

	-- Implement axi_arvalid generation
	-- axi_rvalid is asserted for one S_AXI_ACLK clock cycle when both 
	-- S_AXI_ARVALID and axi_arready are asserted. The slave registers 
	-- data are available on the axi_rdata bus at this instance. The 
	-- assertion of axi_rvalid marks the validity of read data on the 
	-- bus and axi_rresp indicates the status of read transaction.axi_rvalid 
	-- is deasserted on reset (active low). axi_rresp and axi_rdata are 
	-- cleared to zero on reset (active low).  
	process (S_AXI_ACLK)
	begin
	  if rising_edge(S_AXI_ACLK) then
	    if S_AXI_ARESETN = '0' then
	      axi_rvalid <= '0';
	      axi_rresp  <= "00";
	    else
	      if (axi_arready = '1' and S_AXI_ARVALID = '1' and axi_rvalid = '0') then
	        -- Valid read data is available at the read data bus
	        axi_rvalid <= '1';
	        axi_rresp  <= "00"; -- 'OKAY' response
	      elsif (axi_rvalid = '1' and S_AXI_RREADY = '1') then
	        -- Read data is accepted by the master
	        axi_rvalid <= '0';
	      end if;            
	    end if;
	  end if;
	end process;

	-- Implement memory mapped register select and read logic generation
	-- Slave register read enable is asserted when valid address is available
	-- and the slave is ready to accept the read address.
	slv_reg_rden <= axi_arready and S_AXI_ARVALID and (not axi_rvalid) ;

	process (next_key_reg, wout_reg, zout_reg, done_reg, axi_araddr, S_AXI_ARESETN, slv_reg_rden)
	variable loc_addr :std_logic_vector(OPT_MEM_ADDR_BITS downto 0);
	begin
	    -- Address decoding for reading registers
	    loc_addr := axi_araddr(ADDR_LSB + OPT_MEM_ADDR_BITS downto ADDR_LSB);
	    case loc_addr is
--	      when b"000" =>
--	        reg_data_out <= enable_reg;
--	      when b"001" =>
--	        reg_data_out <= key_reg;
	      when b"010" =>
	        reg_data_out <= next_key_reg;
	      when b"011" =>
	        reg_data_out <= wout_reg;
	      when b"100" =>
	        reg_data_out <= zout_reg;
	      when b"101" =>
	        reg_data_out <= done_reg;
	      when others =>
	        reg_data_out  <= (others => '0');
	    end case;
	end process; 

	-- Output register or memory read data
	process( S_AXI_ACLK ) is
	begin
	  if (rising_edge (S_AXI_ACLK)) then
	    if ( S_AXI_ARESETN = '0' ) then
	      axi_rdata  <= (others => '0');
	    else
	      if (slv_reg_rden = '1') then
	        -- When there is a valid read address (S_AXI_ARVALID) with 
	        -- acceptance of read address by the slave (axi_arready), 
	        -- output the read dada 
	        -- Read address mux
	          axi_rdata <= reg_data_out;     -- register read data
	      end if;   
	    end if;
	  end if;
	end process;


	-- Add user logic here
    SM_BEC_module: sm_bec
	port map(
			clk 		=> S_AXI_ACLK, 
			rst 		=> rst_w,
			enable 		=> en_BEC,
			w1 			=> w1, 
			z1 			=> z1,
			w2 			=> w2,
			z2 			=> z2,
			ki          => key_w,  
			d			=> d,
			inv_w0		=> inv_w0,
			next_key	=> next_key_w, 
			done 		=> done_w, 
			wout 		=> wout_tmp, 
			zout 		=> zout_tmp
	);
    
    rst_w           <= not S_AXI_ARESETN; 
	en_IP 		    <= enable_reg(0);
    done_reg   	    <= "000000000000000000000000000000" & done_w & ren_res; 
    next_key_reg   	<= "0000000000000000000000000000000" & next_key_w;
    
    
    --input key 
	counter_key: process(S_AXI_ACLK, S_AXI_ARESETN, en_IP)
	begin
	if rising_edge (S_AXI_ACLK) then 
	   if (S_AXI_ARESETN = '0') then 
	       count_key_r <= (others => '0');
	   elsif wen_key = '1' then
	       if count_key_r = "111" then 
	           count_key_r <= count_key_r; 
	       elsif done_w = '1' then 
	           count_key_r <= (others => '0');
            elsif axi_awaddr = "00100" then 
	           if (axi_wready and axi_awready) = '1' then
	               count_key_r <= count_key_r + 1; 
	           end if; 
	       end if;   
	   end if; 
	end if; 
	end process; 
	
	
	load_key_tmp: process(S_AXI_ACLK, S_AXI_ARESETN, wen_key) 
	begin 
	if rising_edge (S_AXI_ACLK) then 
	   if (S_AXI_ARESETN = '0') then 
	       key_tmp <= (others => '0'); 
	   elsif wen_key = '1' then 
	       case count_key_r is 
	           when "001" => 
	               key_tmp(31 downto 0) <= key_reg;
	           when "010" =>
	               key_tmp(63 downto 32) <= key_reg;
	           when "011" =>
	               key_tmp(95 downto 64) <= key_reg;
	           when "100" =>
	               key_tmp(127 downto 96) <= key_reg;    
	           when "101" =>
	               key_tmp(159 downto 128) <= key_reg;
	           when "110" =>
	               key_tmp(162 downto 160) <= key_reg(2 downto 0);
	           when others =>
	               key_tmp <= key_tmp; 
	       end case;       
	   end if;
	end if;
	end process;
	
	shift_key_tmp: process(S_AXI_ACLK, S_AXI_ARESETN, next_key_w)
	begin 
	   if rising_edge(S_AXI_ACLK) then 
	       if S_AXI_ARESETN = '0' then 
	           key_tmp_1 <= (others => '0');
	       elsif next_key_w = '0' and wen_key = '1' then 
	           key_tmp_1 <= key_tmp; 
	       elsif next_key_w = '1' then 
	           key_tmp_1<= '0' & key_tmp_1(BEC_DATA_BUS_WIDTH-1 downto 1); 
	       end if;
	   end if; 
	end process; 
	key_w       <= key_tmp_1(0);
	
	count_shift_key: process(S_AXI_ACLK, S_AXI_ARESETN, next_key_w) 
	begin 
	   if rising_edge(S_AXI_ACLK) then 
	       if S_AXI_ARESETN = '0' then 
	           count_key <= 0;
	       elsif next_key_w = '1' then 
	           count_key <= count_key + 1; 
	       end if; 
	   end if; 
	end process;
	
	--output	
	store_result_tmp: process (S_AXI_ACLK, S_AXI_ARESETN, done_w) 
	begin 
	if rising_edge(S_AXI_ACLK) then 
        if (S_AXI_ARESETN = '0') then 
            zout_tmp1 <= (others => '0');
            wout_tmp1 <= (others => '0'); 
        elsif (done_w = '1') then 
            zout_tmp1 <= zout_tmp; 
            wout_tmp1 <= wout_tmp; 
        else 
            zout_tmp1 <= zout_tmp1; 
            wout_tmp1 <= wout_tmp1; 
        end if; 
    end if;
	end process;
	
	count_read_result1: process(S_AXI_ACLK, S_AXI_ARESETN, done_w) 
	begin 
	   if rising_edge(S_AXI_ACLK) then 
	       if S_AXI_ARESETN = '0' then 
	           count_result_1 <= (others => '0');
	       elsif ren_res = '1' then 
	           if count_result_1 = "111" then 
	               count_result_1 <= (others => '0'); 
	           elsif (axi_araddr = "01100") then 
	               if (slv_reg_rden = '1') then
	                   count_result_1 <= count_result_1 + 1; 
	               end if; 
	           end if;
	       end if; 
	   end if; 
	end process;
	
    count_read_result2: process(S_AXI_ACLK, S_AXI_ARESETN, done_w) 
	begin 
	   if rising_edge(S_AXI_ACLK) then 
	       if S_AXI_ARESETN = '0' then 
	           count_result_2 <= (others => '0');
	       elsif ren_res = '1' then 
	           if count_result_2 = "111" then 
	               count_result_2 <= (others => '0'); 
	           elsif (axi_araddr = "10000") then 
	               if (slv_reg_rden = '1') then
	                   count_result_2 <= count_result_2 + 1; 
	               end if; 
	           end if;
	       end if; 
	   end if; 
	end process;
	
    read_result_tmp1: process(S_AXI_ACLK, S_AXI_ARESETN, ren_res) 
	begin 
	if rising_edge (S_AXI_ACLK) then 
	   if (S_AXI_ARESETN = '0') then 
	       wout_reg <= (others => '0');

	   elsif axi_rvalid = '1'  then 
	       case count_result_1 is 
	           when "000" => 
	               wout_reg <= wout_tmp1(31 downto 0); 

	           when "001" =>
	               wout_reg <= wout_tmp1(63 downto 32);
	       
	           when "010" =>
	               wout_reg <= wout_tmp1(95 downto 64);
	             
	           when "011" =>
	               wout_reg <= wout_tmp1(127 downto 96);
	          
	           when "100" =>
	               wout_reg <= wout_tmp1(159 downto 128);
	              
	           when "101" =>
	               wout_reg(2 downto 0) <= wout_tmp1(162 downto 160);
	           
	           when others =>
	               wout_reg <= wout_reg; 
	             
	       end case;       
	   end if;
	end if;
	end process;
	
	read_result_tmp2: process(S_AXI_ACLK, S_AXI_ARESETN, ren_res) 
	begin 
	if rising_edge (S_AXI_ACLK) then 
	   if (S_AXI_ARESETN = '0') then 
	       zout_reg <= (others => '0'); 
	       
	   elsif axi_rvalid = '1' then 
	       case count_result_2 is 
	           when "000" => 
	   
	               zout_reg <= zout_tmp1(31 downto 0); 
	           when "001" =>
	         
	               zout_reg <= zout_tmp1(63 downto 32);
	           when "010" =>
	             
	               zout_reg <= zout_tmp1(95 downto 64);
	           when "011" =>
	            
	               zout_reg <= zout_tmp1(127 downto 96);    
	           when "100" =>
	              
	               zout_reg <= zout_tmp1(159 downto 128);
	           when "101" =>
	          
	               zout_reg(2 downto 0) <= zout_tmp1(162 downto 160);
	           when others =>
	         
	               zout_reg <= zout_reg; 
	       end case;       
	   end if;
	end if;
	end process;
	
	
	--controller
	Finite_state_machine: process(S_AXI_ACLK, S_AXI_ARESETN)
	begin  
			if (S_AXI_ARESETN = '0') then 
				fsm_state <= IDLE; 
			elsif rising_edge (S_AXI_ACLK) then 
				case fsm_state is 
					when IDLE => 
						if en_IP = '1' then 
							fsm_state <= WRITE_KEY; 
						else 
							fsm_state <= IDLE; 
						end if;
                
					when WRITE_KEY => 
						if next_key_w = '1' then 
							fsm_state <= SHIFT_KEY; 
						else 
							fsm_state <= WRITE_KEY;
						end if; 
                
					when SHIFT_KEY => 
						if next_key_w = '0' then 
							fsm_state <= COMPUTING;
						else 
							fsm_state <= SHIFT_KEY; 
						end if; 
               
					when COMPUTING =>  
						if done_w = '1'then 
							fsm_state <= READ_RESULT; 
						elsif next_key_w = '1' then 
							fsm_state <= SHIFT_KEY; 
						else 
							fsm_state <= COMPUTING; 
						end if; 
						
                    when READ_RESULT =>  
						if en_IP = '0' then 
							fsm_state <= IDLE;
					    else 
					        fsm_state <= READ_RESULT;  
						end if; 
               
				end case; 
			end if;
	end process;

	wen_key 	<= '1' when fsm_state = WRITE_KEY else '0'; 
	ren_res 	<= '1' when fsm_state = READ_RESULT else '0'; 
	shift_k     <= '1' when fsm_state = SHIFT_KEY else '0'; 
	en_BEC 		<= '0' when fsm_state = IDLE or fsm_state = READ_RESULT else '1';
	
	-- User logic ends

end arch_imp;