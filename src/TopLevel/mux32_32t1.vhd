library IEEE;
use IEEE.std_logic_1164.all;
use ieee.numeric_std.all;
use work.RISCV_types.all;

entity mux32_32t1 is

  port(
	i_W_VV : in vector_32x32;
	i_SEL        : in std_logic_vector(5-1 downto 0);     -- input
       o_OUT        : out std_logic_vector(32-1 downto 0)     -- output
	);

end mux32_32t1;

architecture dataflow of mux32_32t1 is
	
begin

	o_OUT <= i_W_VV(to_integer(unsigned(i_SEL))); 
end dataflow;
