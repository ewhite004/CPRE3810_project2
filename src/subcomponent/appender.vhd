-- Quartus Prime VHDL Template
-- extends 20 input bits to 32-bit output, fills lower 12 bits with 0

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity appender is

    port 
    (
        i_data            : in std_logic_vector(20-1 downto 0);
        o_data            : out std_logic_vector(32-1 downto 0)
    );

end appender;

architecture dataflow of appender is
begin
    o_data(32-1 downto 32-20) <= i_data;
	o_data(32-20-1 downto 0) <= (others => '0');

end dataflow;