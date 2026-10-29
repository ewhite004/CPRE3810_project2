library IEEE;
use IEEE.std_logic_1164.all;

entity ALUControl is
  port(
    i_ALUOp       : in std_logic_vector(1 downto 0); -- 2 bit input from the main control unit that chooses the instruction type 
    i_Funct3      : in std_logic_vector(2 downto 0);
    i_Funct7Bit   : in std_logic;
    o_ALUControl  : out std_logic_vector(3 downto 0) -- 4 bit output that tells the ALU what operation to select
  );
end ALUControl;


architecture dataflow of ALUControl is

  signal s_RTypeControl : std_logic_vector(3 downto 0);
  signal s_ITypeControl : std_logic_vector(3 downto 0);
  signal s_BranchControl : std_logic_vector(3 downto 0); -- ALU operation for the branch compare, chosen by funct3
  signal s_ShiftRControl : std_logic_vector(3 downto 0); -- srli (funct7 bit 0) or srai (funct7 bit 1)

begin

  -- R-type instruction decoding
  with (i_Funct7Bit & i_Funct3) select
    s_RTypeControl <=
      "0110" when "0000",  -- ADD
      "1110" when "1000",  -- SUB
      "0100" when "0001",  -- SLL
      "1111" when "0010",  -- SLT
      "1011" when "0011",  -- SLTU
      "0010" when "0100",  -- XOR
      "0101" when "0101",  -- SRL
      "0111" when "1101",  -- SRA
      "0001" when "0110",  -- OR
      "0000" when "0111",  -- AND
      "0110" when others;

  -- Immediate arithmetic
  with i_Funct3 select
    s_ITypeControl <=
      "0110" when "000",   -- ADDI
      "0100" when "001",   -- SLLI
      "1111" when "010",   -- SLTI
      "1011" when "011",   -- SLTIU
      "0010" when "100",   -- XORI
      s_ShiftRControl when "101",   -- SRLI / SRAI
      "0001" when "110",   -- ORI
      "0000" when "111",   -- ANDI
      "0110" when others;

  -- SRLI/SRAI share funct3 = 101 and differ in instruction bit 30 (funct7 bit)
  s_ShiftRControl <= "0111" when i_Funct7Bit = '1' else "0101";

  -- branch compare, chosen by funct3
  -- beq/bne subtract (Zero says equal), blt/bge use slt, bltu/bgeu use sltu
  with i_Funct3 select
    s_BranchControl <=
      "1110" when "000",   -- BEQ  (sub)
      "1110" when "001",   -- BNE  (sub)
      "1111" when "100",   -- BLT  (slt)
      "1111" when "101",   -- BGE  (slt)
      "1011" when "110",   -- BLTU (sltu)
      "1011" when "111",   -- BGEU (sltu)
      "1110" when others;

  -- Main ALUOp selection
  with i_ALUOp select
    o_ALUControl <=
      "0110"         when "00",  -- lw/sw/address calculations
      s_BranchControl when "01",  -- branch comparison -- was: "1110" when "01" -- changed: pick sub/slt/sltu by funct3
      s_RTypeControl when "10",  -- R-type
      s_ITypeControl when "11",  -- I-type ALU
      "0110"         when others;

end dataflow;
