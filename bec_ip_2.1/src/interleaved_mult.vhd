----------------------------------------------------------------------------
-- Interleaved Multiplier (interleaved_mult.vhd)
--
-- LSB first
-- 
-- Computes the polynomial multiplication mod f in GF(2**m)
-- Implements a sequential cincuit

-- Defines 2 entities (interleaved_data_path and interleaved_mult)
-- 
----------------------------------------------------------------------------

-----------------------------------
-- Interleaved MSB-first multipication data_path
-----------------------------------
library ieee; 
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.acb_package.all;

entity interleaved_data_path is
port (
  A: in std_logic_vector(M-1 downto 0);
  B: in std_logic_vector(M-1 downto 0);
  clk, inic, shift_r, reset, ce_c: in std_logic;
  Z: out std_logic_vector(M-1 downto 0)
);
end interleaved_data_path;

architecture rtl of interleaved_data_path is
  signal aa, bb, cc: std_logic_vector(M-1 downto 0);
  signal new_a, new_c: std_logic_vector(M-1 downto 0);
begin

  register_A: process(clk,reset, inic)
  --register and multiplexer
  begin
    if reset = '1' then aa <= (others => '0');
    elsif clk'event and clk = '1' then
      if inic = '1' then
         aa <= a;
      else
         aa <= new_a;
      end if;
    end if;
  end process;

  sh_register_B: process(reset, clk)
  begin
    if reset = '1' then bb <= (others => '0');
    elsif clk'event and clk = '1' then
      -- if (shift_r = '1') then
      --   bb <= '0' & bb(M-1 downto 1);
      -- elsif inic = '1' then
      --   bb <= b;
      -- end if;
      if inic = '1' then 
        bb <= b;
      -- elsif shift_r = '1' then 
      else
        bb <= '0' & bb(M-1 downto 1);
      end if;
    end if;
  end process;
  
  register_C: process(reset, clk, inic)
  begin
    if (reset = '1' ) then cc <= (others => '0');
    elsif clk'event and clk = '1' then
      if ( inic) = '1' then 
        cc <= (others => '0'); 
        -- z <= cc;
      elsif  shift_r ='1' then
        cc <= new_c;
        -- z <= cc;
      else
        cc <= cc;
      end if;
    end if;
  end process;

  z <= cc ;

  new_a(0) <= aa(m-1) and F(0);
  new_a_calc: for i in 1 to M-1 generate
    new_a(i) <= aa(i-1) xor (aa(m-1) and F(i));
  end generate;

  new_c_calc: for i in 0 to M-1 generate
    new_c(i) <= cc(i) xor (aa(i) and bb(0));
  end generate;

end rtl;

-----------------------------------
-- interleaved_mult
-----------------------------------
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
use work.acb_package.all;
entity interleaved_mult is
port (
  A, B: in std_logic_vector (M-1 downto 0);
  clk, reset, start: in std_logic; 
  Z: out std_logic_vector (M-1 downto 0);
  done: out std_logic
);
end interleaved_mult;

architecture rtl of interleaved_mult is

component interleaved_data_path is
port (
  A: in std_logic_vector(M-1 downto 0);
  B: in std_logic_vector(M-1 downto 0);
  clk, inic, shift_r, reset, ce_c: in std_logic;
  Z: out std_logic_vector(M-1 downto 0)
);
end component;

signal inic, shift_r, ce_c: std_logic;
signal count: std_logic_vector(7 downto 0);
type states is range 0 to 3;
signal current_state, next_state: states;
signal count_done: std_logic;
begin

data_path: interleaved_data_path port map 
  (A => A, B => B,
   clk => clk, inic => inic, shift_r => shift_r, reset => reset, ce_c => ce_c,
   Z => Z);
done <= count_done;
counter: process(reset, shift_r, clk)
begin
  if (reset ='1') then 
    count <= (others => '0');
    count_done <= '0';
  elsif clk' event and clk = '1' then
    if shift_r = '1' then
      if count = M then
        count <= (others => '0');
        count_done <= '1';
      else
        count <= count+1; 
        count_done <= '0';
      end if;
    end if;
  end if;
end process counter;

state_unit: process (current_state)
begin
  case current_state is
    when 0 =>
      inic <= '0';
      shift_r <= '0'; 
      -- done <= '1'; 
      ce_c <= '0';
    when 1 => 
      inic <= '0';
      shift_r <= '0'; 
      -- done <= '1'; 
      ce_c <= '0';
    when 2 => 
      inic <= '1'; 
      shift_r <= '0'; 
      -- done <= '0'; 
      ce_c <= '0';
    when 3 => 
      inic <= '0'; 
      shift_r <= '1'; 
      -- done <= '0'; 
      ce_c <= '1';
    when others =>
      inic <= '0';
      shift_r <= '0'; 
      -- done <= '1'; 
      ce_c <= '0';
  end case;
end process;

  fsm_proc : process (start, inic, count_done)
  begin
    case current_state is
      when 0 =>
        if start ='0' then
          next_state <= 1;
        else
          next_state <= 0;
        end if;
      when 1 =>
        if start ='1' then
          next_state <= 2;
        else
          next_state <= 1;
        end if;
      when 2 =>
        if inic ='1' then 
          next_state <= 3;
        else
          next_state <= 2;
        end if;
      when 3 =>
        if count_done = '1' then
          next_state <= 0;
        else
          next_state <= 3;
        end if;
      when others =>
        next_state <= 0;
    end case;
  end process;

  control_unit: process(clk, reset)
    begin
        if reset ='1' then 
          current_state <= 0;
        elsif rising_edge(clk) then
          current_state <= next_state;
        end if;
    end process control_unit;


end rtl;
