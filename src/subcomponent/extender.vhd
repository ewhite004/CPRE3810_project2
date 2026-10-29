-- Quartus Prime VHDL Template
-- Single-port RAM with single read/write address

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity extender is

    port 
    (
        i_sign_ex        : in std_logic;
        i_data            : in std_logic_vector(12-1 downto 0);
        o_data            : out std_logic_vector(32-1 downto 0)
    );

end extender;

architecture dataflow of extender is
begin
    o_data(32-1 downto 12)<= (others=> i_data(12-1)) when (i_sign_ex='1') else (others=> '0');
	o_data(12-1 downto 0) <= i_data;

end dataflow;
