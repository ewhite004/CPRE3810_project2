
library IEEE;
use IEEE.std_logic_1164.all;

entity add_sub_N is
  generic(N : integer := 16); -- Generic of type integer for input/output data width. Default value is 32.
  port(i_nAdd_Sub          : in std_logic;
       i_A         : in std_logic_vector(N-1 downto 0);
       i_B         : in std_logic_vector(N-1 downto 0);
       o_F          : out std_logic_vector(N-1 downto 0);
	o_C :out std_logic
);

end add_sub_N;

architecture structural of add_sub_N is

  component adder_N is
  generic(N : integer := 16); -- Generic of type integer for input/output data width. Default value is 32.
  port(i_C          : in std_logic;
       i_A         : in std_logic_vector(N-1 downto 0);
       i_B         : in std_logic_vector(N-1 downto 0);
       o_F          : out std_logic_vector(N-1 downto 0);
	o_C : out std_logic
);
end component;

component mux2t1_N is
  generic(N : integer := 16); -- Generic of type integer for input/output data width. Default value is 32.
  port(i_S          : in std_logic;
       i_D0         : in std_logic_vector(N-1 downto 0);
       i_D1         : in std_logic_vector(N-1 downto 0);
       o_O          : out std_logic_vector(N-1 downto 0));

end component;

component onesComp is
 generic(N : integer := 16);
port(
       i_A         : in std_logic_vector(N-1 downto 0);
       i_O         : out std_logic_vector(N-1 downto 0)
);
end component;




signal s_B_inv,s_mux_r :std_logic_vector(N-1 downto 0);
begin

inv0:onesComp
generic map(N =>N)
port map(
i_A => i_B,
i_O => s_B_inv
);

mux0:mux2t1_N
generic map(N =>N)
port map(
i_S => i_nAdd_Sub,
i_D0 => i_B,
i_D1 => s_B_inv,
o_O => s_mux_r
);
	
adder0:adder_N
generic map(N =>N)
port map(
i_C => i_nAdd_Sub,
i_A => i_A,
i_B => s_mux_r,
o_F => o_F,
o_C => o_C
);


	
  
end structural;