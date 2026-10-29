-- sote_ext.vhd
-- the store data unit

library IEEE;
use IEEE.std_logic_1164.all;

entity store_ext is
  port(
    i_Addr   : in std_logic_vector(2-1 downto 0);   -- low 2 bits of the byte address
    i_Funct3 : in std_logic_vector(3-1 downto 0);   -- store type (instruction bits 14:12)
    o_BE   : out std_logic_vector(4-1 downto 0)  -- be of DMEM
  );
end store_ext;


architecture dataflow of store_ext is
begin

with (i_Funct3 & i_Addr) select
o_BE <=
        --SB
        "0001" when ("000"&"00"),
        "0010" when ("000"&"01"),
        "0100" when ("000"&"10"),
        "1000" when ("000"&"11"),
        --SH
        "0011" when ("001"&"00"),
        "1100" when ("001"&"10"),
        --SW
        "1111" when ("010"&"00"),

        "1111" when others;--this should probalby be 0000 but whatever

end dataflow;
