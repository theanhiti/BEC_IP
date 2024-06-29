library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;
-- use ieee.std_logic_textio.all;
-- library std_developerskit;
-- use std_developerskit.std_iopak.all;
-- library std;
-- use std.textio.all;
-- use std.env.all;
package acb_package is
  constant M: integer := 163;
  --constant F: std_logic_vector(M-1 downto 0):= "00011011";
  --constant F: std_logic_vector(M-1 downto 0):= x"001B"; --for M=16 bits
  --constant F: std_logic_vector(M-1 downto 0):= x"0101001B"; --for M=32 bits
  --constant F: std_logic_vector(M-1 downto 0):= x"010100000101001B"; --for M=64 bits
  --constant F: std_logic_vector(M-1 downto 0):= x"0000000000000000010100000101001B"; --for M=128 bits
	constant F: std_logic_vector(M-1 downto 0):= "000"&x"00000000000000000000000000000000000000C9"; --for M=163
  --constant F: std_logic_vector(M-1 downto 0):= (0=> '1', 74 => '1', others => '0'); --for M=233
  type matrix_reductionR is array (0 to M-1) of STD_LOGIC_VECTOR(M-2 downto 0);
  function reduction_matrix_R return matrix_reductionR;

  constant w1: std_logic_vector(M-1 downto 0):= "010" & x"DBF4C5B57791F6C43C6373AAE46D5179FD1CCCB5";
  constant z1: std_logic_vector(M-1 downto 0):= (0 => '1', others => '0');
  constant w2: std_logic_vector(M-1 downto 0):= "001" & x"0F274FEAECFD6FC4A1AD4298F745B7150BB9C6AA";
  constant z2: std_logic_vector(M-1 downto 0):= "000" & x"B1BE81525E388A655E0448F1196D63B6746E0C69";

  constant d: std_logic_vector(M-1 downto 0):= "001" & x"be99ceb8b2c5e5a1ffa90a69ee28d4a37fd7cac3";
  constant inv_w0: std_logic_vector(M-1 downto 0):= "010" & x"56652A45448C7C0FA3DEE973B9D4823D01D9947C";
end acb_package;

package body acb_package is
  function reduction_matrix_R return matrix_reductionR is
  variable R: matrix_reductionR;
  begin
  for j in 0 to M-1 loop
     for i in 0 to M-2 loop
        R(j)(i) := '0'; 
     end loop;
  end loop;
  for j in 0 to M-1 loop
     R(j)(0) := f(j);
  end loop;
  for i in 1 to M-2 loop
     for j in 0 to M-1 loop
        if j = 0 then 
           R(j)(i) := R(M-1)(i-1) and R(j)(0);
        else
           R(j)(i) := R(j-1)(i-1) xor (R(M-1)(i-1) and R(j)(0)); 
        end if;
     end loop;
  end loop;
  return R;
end reduction_matrix_R;

end acb_package;
