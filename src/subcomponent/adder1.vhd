library IEEE;
use IEEE.std_logic_1164.all;

entity adder1 is
port(
	i_A,i_B,i_C: in std_logic;
	o_F, o_C: out std_logic
);
end adder1;

architecture structure of adder1 is

	component andg2
	port(
		i_A,i_B:in std_logic;
		o_F:out std_logic
	);
	end component;
	component org2
	port(
		i_A,i_B:in std_logic;
		o_F:out std_logic
	);
	end component;
	component xorg2
	port(
		i_A,i_B:in std_logic;
		o_F:out std_logic
	);
	end component;
	signal s_one1, s_and1, s_and2:std_logic;

	begin
	xor0: xorg2
	port map(
		i_A => i_A,
		i_B => i_B,
		o_F => s_one1
	);
	xor1: xorg2
	port map(
		i_A => s_one1,
		i_B => i_C,
		o_F => o_F
	);
	and0: andg2
	port map(
		i_A => s_one1,
		i_B => i_C,
		o_F => s_and1
	);
	and1: andg2
	port map(
		i_A => i_A,
		i_B => i_B,
		o_F => s_and2
	);
	or0: org2
	port map(
		i_A => s_and1,
		i_B => s_and2,
		o_F => o_C
	);
	
	
end structure;