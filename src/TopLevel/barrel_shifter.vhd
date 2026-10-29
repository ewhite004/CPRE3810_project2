-- barrel_shifter.vhd

library IEEE;
use IEEE.std_logic_1164.all;

entity barrel_shifter is
  generic(
    N : integer := 32
  );
  port(
    i_D     : in std_logic_vector(N-1 downto 0);  -- value to shift
    i_Shamt : in std_logic_vector(4 downto 0);    -- shift amount (0-31)
    i_Left  : in std_logic;                       -- 1: shift left, 0: shift right
    i_Arith : in std_logic;                       -- 1: arithmetic (sign fill), 0: logical (zero fill)
    o_Q     : out std_logic_vector(N-1 downto 0)  -- shifted value
  );
end barrel_shifter;


architecture structural of barrel_shifter is
  component mux2t1_N is
    generic(N : integer := 16);
    port(
      i_S  : in std_logic;
      i_D0 : in std_logic_vector(N-1 downto 0);
      i_D1 : in std_logic_vector(N-1 downto 0);
      o_O  : out std_logic_vector(N-1 downto 0)
    );
  end component;

  component andg2 is
    port(
      i_A : in std_logic;
      i_B : in std_logic;
      o_F : out std_logic
    );
  end component;

  type t_stages is array (0 to 5) of std_logic_vector(N-1 downto 0);
  type t_shifts is array (0 to 4) of std_logic_vector(N-1 downto 0);

  signal s_Stage   : t_stages;  -- s_Stage(0) = input (reversed for left shifts), s_Stage(5) = fully shifted result
  signal s_Shifted : t_shifts;  -- s_Shifted(k) = s_Stage(k) shifted right by 2^k with the fill bit on top
  signal s_Rev     : std_logic_vector(N-1 downto 0);  -- i_D with the bit order reversed
  signal s_RevOut  : std_logic_vector(N-1 downto 0);  -- shifted result with the bit order reversed
  signal s_Fill    : std_logic;                       -- bit shifted in at the top

begin

  -- bit reversal is only wiring: bit i <-> bit N-1-i
  G_REVERSE : for i in 0 to N-1 generate
    s_Rev(i)    <= i_D(N-1-i);
    s_RevOut(i) <= s_Stage(5)(N-1-i);
  end generate;

  -- left shift: feed the reversed input to the right shifter
  INPUT_MUX : mux2t1_N
    generic map(N => N)
    port map(
      i_S  => i_Left,
      i_D0 => i_D,
      i_D1 => s_Rev,
      o_O  => s_Stage(0)
    );

  -- fill bit: the sign bit for an arithmetic shift, '0' for a logical shift
  FILL_AND : andg2
    port map(
      i_A => i_Arith,
      i_B => i_D(N-1),
      o_F => s_Fill
    );

  -- 5 cascaded stages (shift by 1, 2, 4, 8, 16)
  G_STAGE : for k in 0 to 4 generate
    s_Shifted(k)(N-1 downto N-2**k)   <= (others => s_Fill);
    s_Shifted(k)(N-2**k-1 downto 0)   <= s_Stage(k)(N-1 downto 2**k);

    STAGE_MUX : mux2t1_N
      generic map(N => N)
      port map(
        i_S  => i_Shamt(k),
        i_D0 => s_Stage(k),
        i_D1 => s_Shifted(k),
        o_O  => s_Stage(k+1)
      );
  end generate;

  -- left shift: reverse the result back
  OUTPUT_MUX : mux2t1_N
    generic map(N => N)
    port map(
      i_S  => i_Left,
      i_D0 => s_Stage(5),
      i_D1 => s_RevOut,
      o_O  => o_Q
    );

end structural;
