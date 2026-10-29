-------------------------------------------------------------------------
-- tb_barrel_shifter.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: Simple self-checking testbench for barrel_shifter (32 bit).
--   10 cases, each held for 10 ns, so every case is easy to see and annotate on
--   the waveform. s_Case shows the case number (1 to 10). Each case is checked
--   against a hand-written expected value and reports an error if it differs.
--   Mode: sll = (i_Left=1, i_Arith=0), srl = (i_Left=0, i_Arith=0),
--         sra = (i_Left=0, i_Arith=1).
--
--   Case  Operation  Input        Shift  Expected      What it shows
--    1    sll        0x00000001     4     0x00000010    left shift
--    2    sll        0x00000001    31     0x80000000    largest left shift
--    3    srl        0x0000FF00     8     0x000000FF    logical right shift
--    4    srl        0x80000000    31     0x00000001    srl fills with 0
--    5    sra        0x80000000    31     0xFFFFFFFF    sra fills with the sign bit (1)
--    6    sra        0xF0000000     4     0xFF000000    sra of a negative number
--    7    srl        0xF0000000     4     0x0F000000    same input as 6, srl fills with 0
--    8    sra        0x7FFFFFFF     4     0x07FFFFFF    sra of a positive number fills 0
--    9    srl        0x12345678     0     0x12345678    shift by 0 changes nothing
--   10    sll        0x0000000F    16     0x000F0000    shift by 16 (last stage)
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity tb_barrel_shifter is
end tb_barrel_shifter;

architecture behavior of tb_barrel_shifter is

  constant N     : integer := 32;
  constant cHOLD : time := 10 ns; -- how long each case is applied

  signal s_D     : std_logic_vector(N-1 downto 0) := (others => '0');
  signal s_Shamt : std_logic_vector(4 downto 0) := (others => '0');
  signal s_Left  : std_logic := '0';
  signal s_Arith : std_logic := '0';
  signal s_Q     : std_logic_vector(N-1 downto 0);

  signal s_Case   : integer := 0; -- case number, shown on the waveform
  signal s_Errors : integer := 0; -- number of failed cases

begin

  DUT : entity work.barrel_shifter
    generic map(N => N)
    port map(i_D     => s_D,
             i_Shamt => s_Shamt,
             i_Left  => s_Left,
             i_Arith => s_Arith,
             o_Q     => s_Q);

  TEST : process
    -- apply one case, wait, then compare o_Q with the expected value
    procedure check(num      : in integer;
                    d        : in std_logic_vector(N-1 downto 0);
                    shamt    : in std_logic_vector(4 downto 0);
                    left     : in std_logic;
                    arith    : in std_logic;
                    expected : in std_logic_vector(N-1 downto 0)) is
    begin
      s_Case  <= num;
      s_D     <= d;
      s_Shamt <= shamt;
      s_Left  <= left;
      s_Arith <= arith;
      wait for cHOLD;
      if s_Q /= expected then
        s_Errors <= s_Errors + 1;
        report "case " & integer'image(num) & " FAILED: got " & to_hstring(s_Q) & ", expected " & to_hstring(expected) severity error;
      end if;
    end procedure;
  begin
    wait for cHOLD;

    --    case  input         shamt    left  arith  expected
    check( 1,  x"00000001",  "00100", '1',  '0',   x"00000010"); -- sll by 4
    check( 2,  x"00000001",  "11111", '1',  '0',   x"80000000"); -- sll by 31
    check( 3,  x"0000FF00",  "01000", '0',  '0',   x"000000FF"); -- srl by 8
    check( 4,  x"80000000",  "11111", '0',  '0',   x"00000001"); -- srl by 31
    check( 5,  x"80000000",  "11111", '0',  '1',   x"FFFFFFFF"); -- sra by 31
    check( 6,  x"F0000000",  "00100", '0',  '1',   x"FF000000"); -- sra by 4 (negative)
    check( 7,  x"F0000000",  "00100", '0',  '0',   x"0F000000"); -- srl by 4 (same input as 6)
    check( 8,  x"7FFFFFFF",  "00100", '0',  '1',   x"07FFFFFF"); -- sra by 4 (positive)
    check( 9,  x"12345678",  "00000", '0',  '0',   x"12345678"); -- shift by 0
    check(10,  x"0000000F",  "10000", '1',  '0',   x"000F0000"); -- sll by 16

    if s_Errors = 0 then
      report "ALL 10 CASES PASSED" severity note;
    else
      report integer'image(s_Errors) & " CASE(S) FAILED" severity failure;
    end if;
    wait;
  end process;

end behavior;
