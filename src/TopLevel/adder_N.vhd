
library IEEE;
use IEEE.std_logic_1164.all;

entity adder_N is
  generic(N : integer := 16); -- Generic of type integer for input/output data width. Default value is 32.
  port(i_C          : in std_logic;
       i_A         : in std_logic_vector(N-1 downto 0);
       i_B         : in std_logic_vector(N-1 downto 0);
       o_F          : out std_logic_vector(N-1 downto 0);
	o_C : out std_logic
);

end adder_N;

architecture structural of adder_N is

  component adder1 is
port(
	i_A,i_B,i_C: in std_logic;
	o_F, o_C: out std_logic
);
  end component;
signal C :std_logic_vector(N downto 0);
begin

  -- Instantiate N mux instances.
	adderfirst:adder1 port map(
	i_A =>i_A(0),
	i_B =>i_B(0),
	o_F =>o_F(0),
	i_C =>i_C,
	o_C => C(1)
);
  G_NBit_ADDER: for i in 1 to N-2 generate -- was: for i in 1 to N-1 generate -- FIXED: bit N-1 is built by adderlast below, it was being driven twice
    ADDERI: adder1 port map(
              i_A      => i_A(i),      -- All instances share the same select input.
              i_B     => i_B(i),  -- ith instance's data 0 input hooked up to ith data 0 input.
              i_C     => C(i),  -- ith instance's data 1 input hooked up to ith data 1 input.
              o_F      => o_F(i),  -- ith instance's data output hooked up to ith data output.
	o_C => C(i+1)
);
  end generate G_NBit_ADDER;
	adderlast:adder1 port map(
	i_A =>i_A(N-1),
	i_B =>i_B(N-1),
	o_F =>o_F(N-1),
	i_C =>C(N-1),
	o_C => o_C
);
	
  
end structural;
