library IEEE;
use IEEE.std_logic_1164.all;

entity mux2t1 is
port(
	i_D0,i_D1,i_S: in std_logic;
	o_O: out std_logic
);
end mux2t1;

architecture dataflow of mux2t1 is
begin
	o_O <= i_D0 when i_S = '0' else i_D1;
end dataflow;