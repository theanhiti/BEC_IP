----------------------------------------------------------------------------
-- Classic squarer (classic_squarer.vhd)
--
-- Computes the polynomial multiplication A.A mod f in GF(2**m)
-- The hardware is genenerate for a specific f.
--
-- Its is based on classic modular multiplier, but use the fact that
-- Squaring a polinomial is simplier than multiply.
--
-- Defines 2 entities:
-- poly_reducer: reduces a (2*m-1)- bit polynomial by f to an m-bit polinomial
-- classic_multiplication: instantiates the poly_reducer and squares the A polinomial
-- and a Package (classic_multiplier_parameterse)
-- 
----------------------------------------------------------------------------

------------------------------------------------------------
-- poly_reducer
------------------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.acb_package.all;

entity poly_reducer is
port (
  d: in std_logic_vector(2*M-2 downto 0);
  c: out std_logic_vector(M-1 downto 0)
);
end poly_reducer;

architecture simple of poly_reducer is
  constant R: matrix_reductionR := reduction_matrix_R;
begin

  gen_xors: for j in 0 to M-1 generate
    l1: process(d) 
        variable aux: std_logic;
        begin
          aux := d(j);
          for i in 0 to M-2 loop 
            aux := aux xor (d(M+i) and R(j)(i)); 
          end loop;
          c(j) <= aux;
    end process;
  end generate;

end simple;


------------------------------------------------------------
-- Classic Squaring
------------------------------------------------------------
library ieee; 
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
use work.acb_package.all;

entity classic_squarer is
port (
  a: in std_logic_vector(M-1 downto 0);
  c: out std_logic_vector(M-1 downto 0)
);
end classic_squarer;

architecture simple of classic_squarer is

  component poly_reducer port (
    d: in std_logic_vector(2*M-2 downto 0);
    c: out std_logic_vector(M-1 downto 0));
  end component;

  signal d: std_logic_vector(2*M-2 downto 0);

begin

  D(0) <= A(0);
  square: for i in 1 to M-1 generate
    D(2*i-1) <= '0';
    D(2*i) <= A(i);
  end generate;
  
  inst_reduc: poly_reducer port map(d => d, c => c);
  
end simple;