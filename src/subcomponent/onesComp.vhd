library IEEE;
use IEEE.std_logic_1164.all;

entity onesComp is
 generic(N : integer := 16);
port(
       i_A         : in std_logic_vector(N-1 downto 0);
       i_O         : out std_logic_vector(N-1 downto 0)
);
end onesComp;

architecture structure of onesComp is

	component invg
	port(
		i_A:in std_logic;
		o_F:out std_logic
	);
	end component;

	begin
	 -- Instantiate N mux instances.
  G_NBit_INV: for i in 0 to N-1 generate
    INVI: invg port map(
              i_A     => i_A(i),  -- ith instance's data 1 input hooked up to ith data input.
              o_F      => i_O(i));  -- ith instance's data output hooked up to ith data output.
  end generate G_NBit_INV;
end structure;