library IEEE;
use IEEE.std_logic_1164.all;

entity ALU is
  generic(
    N : integer := 32
  );
  port(
    i_A          : in std_logic_vector(N-1 downto 0);
    i_B          : in std_logic_vector(N-1 downto 0);
    i_ALUControl : in std_logic_vector(3 downto 0);
    o_Result     : out std_logic_vector(N-1 downto 0);
    o_Zero       : out std_logic
  );
end ALU;


architecture structural of ALU is
  component add_sub_N is
    generic(
      N : integer := 32
    );
    port(
      i_nAdd_Sub : in std_logic;
      i_A        : in std_logic_vector(N-1 downto 0);
      i_B        : in std_logic_vector(N-1 downto 0);
      o_F        : out std_logic_vector(N-1 downto 0);
      o_C        : out std_logic
    );
  end component;

  -- added components
  component mux2t1_N is
    generic(
      N : integer := 16
    );
    port(
      i_S  : in std_logic;
      i_D0 : in std_logic_vector(N-1 downto 0);
      i_D1 : in std_logic_vector(N-1 downto 0);
      o_O  : out std_logic_vector(N-1 downto 0)
    );
  end component;

  component barrel_shifter is
    generic(
      N : integer := 32
    );
    port(
      i_D     : in std_logic_vector(N-1 downto 0);
      i_Shamt : in std_logic_vector(4 downto 0);
      i_Left  : in std_logic;
      i_Arith : in std_logic;
      o_Q     : out std_logic_vector(N-1 downto 0)
    );
  end component;

  component andg2 is
    port(
      i_A : in std_logic;
      i_B : in std_logic;
      o_F : out std_logic
    );
  end component;

  component org2 is
    port(
      i_A : in std_logic;
      i_B : in std_logic;
      o_F : out std_logic
    );
  end component;

  component xorg2 is
    port(
      i_A : in std_logic;
      i_B : in std_logic;
      o_F : out std_logic
    );
  end component;

  component invg is
    port(
      i_A : in std_logic;
      o_F : out std_logic
    );
  end component;

  signal s_AddSubSelect : std_logic;
  signal s_Carry        : std_logic;
  signal s_Result       : std_logic_vector(N-1 downto 0); -- internal copy of the result so Zero can be computed

  -- results of each operation
  signal s_AddSub : std_logic_vector(N-1 downto 0); 
  signal s_And    : std_logic_vector(N-1 downto 0);
  signal s_Or     : std_logic_vector(N-1 downto 0);
  signal s_Xor    : std_logic_vector(N-1 downto 0);
  signal s_Nor    : std_logic_vector(N-1 downto 0);
  signal s_Shift  : std_logic_vector(N-1 downto 0); -- sll / srl / sra from the barrel shifter
  signal s_Slt    : std_logic_vector(N-1 downto 0); -- 0 or 1
  signal s_Sltu   : std_logic_vector(N-1 downto 0); -- 0 or 1

  -- slt / sltu
  signal s_LtU      : std_logic; -- A < B unsigned
  signal s_SignDiff : std_logic; -- A and B have different sign bits
  signal s_Lt       : std_logic; -- A < B signed

  -- shifter controls
  signal s_ShLeft : std_logic;

  -- result mux tree
  signal s_MuxA0, s_MuxA1, s_MuxA : std_logic_vector(N-1 downto 0); -- codes 00xx
  signal s_MuxB1, s_MuxB          : std_logic_vector(N-1 downto 0); -- codes 01xx
  signal s_MuxD, s_MuxE, s_MuxF   : std_logic_vector(N-1 downto 0); -- codes 1xxx and the combined groups

  -- zero detection (OR tree over the 32 result bits, then inverted)
  signal s_Z1 : std_logic_vector(15 downto 0);
  signal s_Z2 : std_logic_vector(7 downto 0);
  signal s_Z3 : std_logic_vector(3 downto 0);
  signal s_Z4 : std_logic_vector(1 downto 0);
  signal s_AnyOne : std_logic;

begin
  -- ALUControl encoding:
  -- ADD = 0110
  -- SUB = 1110
  -- Bit 3 distinguishes these:
  -- ADD: 0 110
  -- SUB: 1 110
  --
  -- full ALUControl encoding (bit 3 = 1 makes the adder subtract, which sub, slt and sltu need)
  -- AND  = 0000    OR   = 0001    XOR  = 0010    NOR  = 0011
  -- SLL  = 0100    SRL  = 0101    ADD  = 0110    SRA  = 0111
  -- SLTU = 1011    SUB  = 1110    SLT  = 1111


  s_AddSubSelect <= i_ALUControl(3);

  ADD_SUB_UNIT : add_sub_N
    generic map(
      N => N
    )
    port map(
      i_nAdd_Sub => s_AddSubSelect,
      i_A        => i_A,
      i_B        => i_B,
      o_F        => s_AddSub,
      o_C        => s_Carry
    );

  -- and / or / xor / nor, one gate per bit
  G_LOGIC : for i in 0 to N-1 generate
    AND_I : andg2 port map(i_A => i_A(i), i_B => i_B(i), o_F => s_And(i));
    OR_I  : org2  port map(i_A => i_A(i), i_B => i_B(i), o_F => s_Or(i));
    XOR_I : xorg2 port map(i_A => i_A(i), i_B => i_B(i), o_F => s_Xor(i));
    NOR_I : invg  port map(i_A => s_Or(i), o_F => s_Nor(i));
  end generate;

  -- sltu / slt. The adder runs A + ~B + 1 for these (bit 3 of the control is 1).
  -- A + ~B + 1 has a carry out exactly when A >= B (unsigned), so sltu = NOT carry out.
  -- If the sign bits differ the signed order is the opposite of the unsigned order, so slt = sltu XOR (signs differ).
  LTU_INV  : invg  port map(i_A => s_Carry, o_F => s_LtU);
  SIGN_XOR : xorg2 port map(i_A => i_A(N-1), i_B => i_B(N-1), o_F => s_SignDiff);
  LT_XOR   : xorg2 port map(i_A => s_LtU, i_B => s_SignDiff, o_F => s_Lt);
  s_Sltu(0) <= s_LtU;
  s_Slt(0)  <= s_Lt;
  s_Sltu(N-1 downto 1) <= (others => '0');
  s_Slt(N-1 downto 1)  <= (others => '0');

  -- shifts, the shift amount is B(4 downto 0). For the shift codes (SLL 0100, SRL 0101, SRA 0111):
  -- bit 0 = 0 means shift left, and bit 1 = 1 means arithmetic (sign fill).
  SHL_INV : invg port map(i_A => i_ALUControl(0), o_F => s_ShLeft);

  SHIFTER : barrel_shifter
    generic map(
      N => N
    )
    port map(
      i_D     => i_A,
      i_Shamt => i_B(4 downto 0),
      i_Left  => s_ShLeft,
      i_Arith => i_ALUControl(1),
      o_Q     => s_Shift
    );

  -- result mux tree, selected by the ALUControl bits
  --   c3 c2 c1 c0
  --   0  0  0  x  : AND (c0=0)  OR  (c0=1)
  --   0  0  1  x  : XOR (c0=0)  NOR (c0=1)
  --   0  1  0  x  : SLL (c0=0)  SRL (c0=1)
  --   0  1  1  x  : ADD (c0=0)  SRA (c0=1)
  --   1  0  x  x  : SLTU
  --   1  1  1  x  : SUB (c0=0)  SLT (c0=1)
  MUX_A0 : mux2t1_N generic map(N => N) port map(i_S => i_ALUControl(0), i_D0 => s_And,    i_D1 => s_Or,    o_O => s_MuxA0);
  MUX_A1 : mux2t1_N generic map(N => N) port map(i_S => i_ALUControl(0), i_D0 => s_Xor,    i_D1 => s_Nor,   o_O => s_MuxA1);
  MUX_A  : mux2t1_N generic map(N => N) port map(i_S => i_ALUControl(1), i_D0 => s_MuxA0,  i_D1 => s_MuxA1, o_O => s_MuxA);
  MUX_B1 : mux2t1_N generic map(N => N) port map(i_S => i_ALUControl(0), i_D0 => s_AddSub, i_D1 => s_Shift, o_O => s_MuxB1);
  MUX_B  : mux2t1_N generic map(N => N) port map(i_S => i_ALUControl(1), i_D0 => s_Shift,  i_D1 => s_MuxB1, o_O => s_MuxB);
  MUX_D  : mux2t1_N generic map(N => N) port map(i_S => i_ALUControl(0), i_D0 => s_AddSub, i_D1 => s_Slt,   o_O => s_MuxD);
  MUX_E  : mux2t1_N generic map(N => N) port map(i_S => i_ALUControl(2), i_D0 => s_Sltu,   i_D1 => s_MuxD,  o_O => s_MuxE);
  MUX_F  : mux2t1_N generic map(N => N) port map(i_S => i_ALUControl(2), i_D0 => s_MuxA,   i_D1 => s_MuxB,  o_O => s_MuxF);
  MUX_R  : mux2t1_N generic map(N => N) port map(i_S => i_ALUControl(3), i_D0 => s_MuxF,   i_D1 => s_MuxE,  o_O => s_Result);

  o_Result <= s_Result;

  -- Zero = NOR of all 32 result bits, built as a balanced OR tree followed by an inverter
  G_Z1 : for i in 0 to 15 generate
    Z1_I : org2 port map(i_A => s_Result(2*i), i_B => s_Result(2*i+1), o_F => s_Z1(i));
  end generate;
  G_Z2 : for i in 0 to 7 generate
    Z2_I : org2 port map(i_A => s_Z1(2*i), i_B => s_Z1(2*i+1), o_F => s_Z2(i));
  end generate;
  G_Z3 : for i in 0 to 3 generate
    Z3_I : org2 port map(i_A => s_Z2(2*i), i_B => s_Z2(2*i+1), o_F => s_Z3(i));
  end generate;
  G_Z4 : for i in 0 to 1 generate
    Z4_I : org2 port map(i_A => s_Z3(2*i), i_B => s_Z3(2*i+1), o_F => s_Z4(i));
  end generate;
  Z5 : org2 port map(i_A => s_Z4(0), i_B => s_Z4(1), o_F => s_AnyOne);
  ZERO_INV : invg port map(i_A => s_AnyOne, o_F => o_Zero);

end structural;
