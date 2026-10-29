-------------------------------------------------------------------------
-- tb_alu.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: Self-checking testbench for the 32-bit ALU (ALU.vhd).
--   Every case is held for 10 ns, s_Case shows the case number on the waveform,
--   and each case checks BOTH o_Result and o_Zero against hand-written expected
--   values (the expected Zero is 1 exactly when the expected result is 0).
--
-- TEST PLAN (why this is comprehensive):
--   * Every ALU operation is tested: add, sub, and, or, xor, nor, slt, sltu,
--     sll, srl, sra. (addi, slti, slli and so on use the same ALU operations
--     with an immediate as operand B, so they are covered by the same cases.)
--   * Each operation gets a normal case plus the edge cases that could break it:
--       add / sub : zero operands, results of exactly 0 (Zero = 1), wrap around
--                   at 0xFFFFFFFF -> 0 and 0x7FFFFFFF -> 0x80000000, negative results
--       and/or/xor/nor : all zeros, all ones, alternating bit patterns (0xAAAAAAAA
--                   and 0x55555555 are complements, so they exercise every bit
--                   position with both values), results of 0
--       slt / sltu: equal operands, A < B, A > B, negative vs positive (where signed
--                   and unsigned compares DISAGREE), and 0x80000000 vs 0x7FFFFFFF
--                   (where A - B overflows, so the sign of the subtraction is wrong
--                   and only the carry / sign-bit logic gives the right answer)
--       shifts    : shift by 0, 1 stage, 31 (the largest), a value shifted all the way
--                   out (result 0), sra of negative and positive numbers, and a shift
--                   amount larger than 31 (only B[4:0] is used)
--   * Zero is checked on every case, including results that are 0 for different
--     reasons (equal subtraction, and of complements, slt = 0, shifted out).
--
--   ALUControl: AND 0000, OR 0001, XOR 0010, NOR 0011, SLL 0100, SRL 0101,
--               ADD 0110, SRA 0111, SLTU 1011, SUB 1110, SLT 1111
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity tb_alu is
end tb_alu;

architecture behavior of tb_alu is

  constant N     : integer := 32;
  constant cHOLD : time := 10 ns;

  -- ALUControl codes
  constant cAND  : std_logic_vector(3 downto 0) := "0000";
  constant cOR   : std_logic_vector(3 downto 0) := "0001";
  constant cXOR  : std_logic_vector(3 downto 0) := "0010";
  constant cNOR  : std_logic_vector(3 downto 0) := "0011";
  constant cSLL  : std_logic_vector(3 downto 0) := "0100";
  constant cSRL  : std_logic_vector(3 downto 0) := "0101";
  constant cADD  : std_logic_vector(3 downto 0) := "0110";
  constant cSRA  : std_logic_vector(3 downto 0) := "0111";
  constant cSLTU : std_logic_vector(3 downto 0) := "1011";
  constant cSUB  : std_logic_vector(3 downto 0) := "1110";
  constant cSLT  : std_logic_vector(3 downto 0) := "1111";

  signal s_A       : std_logic_vector(N-1 downto 0) := (others => '0');
  signal s_B       : std_logic_vector(N-1 downto 0) := (others => '0');
  signal s_Control : std_logic_vector(3 downto 0) := (others => '0');
  signal s_Result  : std_logic_vector(N-1 downto 0);
  signal s_Zero    : std_logic;

  signal s_Case   : integer := 0; -- case number, shown on the waveform
  signal s_Errors : integer := 0; -- number of failed cases

begin

  DUT : entity work.ALU
    generic map(N => N)
    port map(i_A          => s_A,
             i_B          => s_B,
             i_ALUControl => s_Control,
             o_Result     => s_Result,
             o_Zero       => s_Zero);

  TEST : process
    -- apply one case, wait, then check o_Result and o_Zero
    procedure check(num      : in integer;
                    name     : in string;
                    ctrl     : in std_logic_vector(3 downto 0);
                    a        : in std_logic_vector(N-1 downto 0);
                    b        : in std_logic_vector(N-1 downto 0);
                    expected : in std_logic_vector(N-1 downto 0)) is
      variable v_ExpZero : std_logic;
    begin
      if expected = x"00000000" then v_ExpZero := '1'; else v_ExpZero := '0'; end if;
      s_Case    <= num;
      s_Control <= ctrl;
      s_A       <= a;
      s_B       <= b;
      wait for cHOLD;
      if s_Result /= expected then
        s_Errors <= s_Errors + 1;
        report "case " & integer'image(num) & " (" & name & ") FAILED: result " & to_hstring(s_Result) & ", expected " & to_hstring(expected) severity error;
      end if;
      if s_Zero /= v_ExpZero then
        s_Errors <= s_Errors + 1;
        report "case " & integer'image(num) & " (" & name & ") FAILED: Zero is " & std_logic'image(s_Zero) & ", expected " & std_logic'image(v_ExpZero) severity error;
      end if;
    end procedure;
  begin
    wait for cHOLD;

    --     case  name                          ctrl   A             B             expected
    -- ---- add ----
    check( 1, "add 5 + 3",                     cADD,  x"00000005",  x"00000003",  x"00000008");
    check( 2, "add 0 + 0 (Zero)",              cADD,  x"00000000",  x"00000000",  x"00000000");
    check( 3, "add -1 + 1 wraps to 0 (Zero)",  cADD,  x"FFFFFFFF",  x"00000001",  x"00000000");
    check( 4, "add INT_MAX + 1 overflows",     cADD,  x"7FFFFFFF",  x"00000001",  x"80000000");
    check( 5, "add -1 + -1",                   cADD,  x"FFFFFFFF",  x"FFFFFFFF",  x"FFFFFFFE");
    check( 6, "add large values",              cADD,  x"12345678",  x"11111111",  x"23456789");
    -- ---- sub ----
    check( 7, "sub 5 - 3",                     cSUB,  x"00000005",  x"00000003",  x"00000002");
    check( 8, "sub 3 - 5 is negative",         cSUB,  x"00000003",  x"00000005",  x"FFFFFFFE");
    check( 9, "sub 5 - 5 (Zero)",              cSUB,  x"00000005",  x"00000005",  x"00000000");
    check(10, "sub 0 - 1",                     cSUB,  x"00000000",  x"00000001",  x"FFFFFFFF");
    check(11, "sub INT_MIN - 1 overflows",     cSUB,  x"80000000",  x"00000001",  x"7FFFFFFF");
    check(12, "sub 0 - INT_MIN",               cSUB,  x"00000000",  x"80000000",  x"80000000");
    -- ---- and ----
    check(13, "and mask",                      cAND,  x"FFFF0000",  x"0F0F0F0F",  x"0F0F0000");
    check(14, "and complements (Zero)",        cAND,  x"AAAAAAAA",  x"55555555",  x"00000000");
    check(15, "and all ones",                  cAND,  x"FFFFFFFF",  x"12345678",  x"12345678");
    -- ---- or ----
    check(16, "or complements",                cOR,   x"AAAAAAAA",  x"55555555",  x"FFFFFFFF");
    check(17, "or 0 | 0 (Zero)",               cOR,   x"00000000",  x"00000000",  x"00000000");
    check(18, "or mixed",                      cOR,   x"F0F0F0F0",  x"0000FFFF",  x"F0F0FFFF");
    -- ---- xor ----
    check(19, "xor same value (Zero)",         cXOR,  x"FFFFFFFF",  x"FFFFFFFF",  x"00000000");
    check(20, "xor with all ones is not",      cXOR,  x"AAAAAAAA",  x"FFFFFFFF",  x"55555555");
    check(21, "xor with 0 is unchanged",       cXOR,  x"12345678",  x"00000000",  x"12345678");
    -- ---- nor ----
    check(22, "nor 0 0 is all ones",           cNOR,  x"00000000",  x"00000000",  x"FFFFFFFF");
    check(23, "nor complements (Zero)",        cNOR,  x"AAAAAAAA",  x"55555555",  x"00000000");
    check(24, "nor mixed",                     cNOR,  x"F0F0F0F0",  x"0F0F0000",  x"00000F0F");
    -- ---- slt (signed) ----
    check(25, "slt 5 < 7",                     cSLT,  x"00000005",  x"00000007",  x"00000001");
    check(26, "slt 7 < 5 (Zero)",              cSLT,  x"00000007",  x"00000005",  x"00000000");
    check(27, "slt 5 < 5 equal (Zero)",        cSLT,  x"00000005",  x"00000005",  x"00000000");
    check(28, "slt -1 < 1",                    cSLT,  x"FFFFFFFF",  x"00000001",  x"00000001");
    check(29, "slt 1 < -1 (Zero)",             cSLT,  x"00000001",  x"FFFFFFFF",  x"00000000");
    check(30, "slt INT_MIN < INT_MAX",         cSLT,  x"80000000",  x"7FFFFFFF",  x"00000001");
    check(31, "slt INT_MAX < INT_MIN (Zero)",  cSLT,  x"7FFFFFFF",  x"80000000",  x"00000000");
    check(32, "slt -5 < -3",                   cSLT,  x"FFFFFFFB",  x"FFFFFFFD",  x"00000001");
    -- ---- sltu (unsigned) ----
    check(33, "sltu 5 < 7",                    cSLTU, x"00000005",  x"00000007",  x"00000001");
    check(34, "sltu 0xFFFFFFFF < 1 (Zero)",    cSLTU, x"FFFFFFFF",  x"00000001",  x"00000000");
    check(35, "sltu 1 < 0xFFFFFFFF",           cSLTU, x"00000001",  x"FFFFFFFF",  x"00000001");
    check(36, "sltu 0x80000000 < 0x7FFFFFFF (Zero)", cSLTU, x"80000000", x"7FFFFFFF", x"00000000");
    check(37, "sltu 0x7FFFFFFF < 0x80000000",  cSLTU, x"7FFFFFFF",  x"80000000",  x"00000001");
    check(38, "sltu 5 < 5 equal (Zero)",       cSLTU, x"00000005",  x"00000005",  x"00000000");
    -- ---- sll ----
    check(39, "sll 1 << 4",                    cSLL,  x"00000001",  x"00000004",  x"00000010");
    check(40, "sll 1 << 31",                   cSLL,  x"00000001",  x"0000001F",  x"80000000");
    check(41, "sll by 0",                      cSLL,  x"12345678",  x"00000000",  x"12345678");
    check(42, "sll all ones << 16",            cSLL,  x"FFFFFFFF",  x"00000010",  x"FFFF0000");
    check(43, "sll uses only B[4:0] (36 -> 4)", cSLL, x"00000001",  x"00000024",  x"00000010");
    check(44, "sll shifts everything out (Zero)", cSLL, x"00010000", x"00000010", x"00000000");
    -- ---- srl ----
    check(45, "srl 0x80000000 >> 31",          cSRL,  x"80000000",  x"0000001F",  x"00000001");
    check(46, "srl all ones >> 16",            cSRL,  x"FFFFFFFF",  x"00000010",  x"0000FFFF");
    check(47, "srl 0xF0000000 >> 4",           cSRL,  x"F0000000",  x"00000004",  x"0F000000");
    check(48, "srl by 0",                      cSRL,  x"12345678",  x"00000000",  x"12345678");
    check(49, "srl 1 >> 1 (Zero)",             cSRL,  x"00000001",  x"00000001",  x"00000000");
    -- ---- sra ----
    check(50, "sra 0x80000000 >>> 31",         cSRA,  x"80000000",  x"0000001F",  x"FFFFFFFF");
    check(51, "sra 0xF0000000 >>> 4",          cSRA,  x"F0000000",  x"00000004",  x"FF000000");
    check(52, "sra 0x7FFFFFFF >>> 4",          cSRA,  x"7FFFFFFF",  x"00000004",  x"07FFFFFF");
    check(53, "sra all ones >>> 31",           cSRA,  x"FFFFFFFF",  x"0000001F",  x"FFFFFFFF");
    check(54, "sra 0x12345678 >>> 8",          cSRA,  x"12345678",  x"00000008",  x"00123456");

    if s_Errors = 0 then
      report "ALL 54 ALU CASES PASSED" severity note;
    else
      report integer'image(s_Errors) & " ALU CHECK(S) FAILED" severity failure;
    end if;
    wait;
  end process;

end behavior;
