----------------------------------------------------------------------------
-- Arithmetic Computation Block (acb.vhd)
--
-- Computes the polynomial multiplication (A.B)^2 mod f in GF(2**m)
-- The hardware is genenerate for a specific f.
--
-- Its is based on classic interleaved multiplier and classical square
--
-- Defines 2 entities:
-- poly_reducer: reduces a (2*m-1)- bit polynomial by f to an m-bit polinomial
-- classic_multiplication: instantiates the poly_reducer and squares the A polinomial
-- and a Package (classic_multiplier_parameterse)
-- 
----------------------------------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.acb_package.all;

entity acb is
    port (
        clk, rst, enable, config: in std_logic;
        A, B: in std_logic_vector(M-1 downto 0);
        C: out std_logic_vector(M-1 downto 0);
        done: out std_logic
    );
end entity acb;

architecture rtl of acb is
    component classic_squarer is
        port (
          a: in std_logic_vector(M-1 downto 0);
          c: out std_logic_vector(M-1 downto 0)
        );
    end component; 

    component interleaved_mult is
        port (
          A, B: in std_logic_vector (M-1 downto 0);
          clk, reset, start: in std_logic; 
          Z: out std_logic_vector (M-1 downto 0);
          done: out std_logic
        );
    end component;

    signal z_tmp: std_logic_vector(M-1 downto 0);
    signal c_tmp: std_logic_vector(M-1 downto 0);
begin
    c <= c_tmp when config = '0' else z_tmp;
    
    U1: classic_squarer 
    port map(
        a => z_tmp,
        c => c_tmp
        );

    U2: interleaved_mult
    port map(
        A   => A,
        B   => B,
        clk => clk,
        reset => rst,
        start => enable,
        Z   => z_tmp,
        done => done);

end rtl;
