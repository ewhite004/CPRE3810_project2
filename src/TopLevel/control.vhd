library IEEE;
use IEEE.std_logic_1164.all;

entity control is
  port(Opcode   : in std_logic_vector(7-1 downto 0);
       auipc, jal, jalr : out std_logic; -- auipc writes PC+imm to rd; jal/jalr are jumps (next PC and rd = PC+4 handled in the processor)
       ALU_Op   : out std_logic_vector(2-1 downto 0); -- ALUControl takes a 2-bit ALUOp
       dMem_be : out std_logic_vector(4-1 downto 0);
       branch, MemRead, memToReg, memWrite, ALU_Src, regWrite, useImm : out std_logic
  );

end control;

architecture dataflow of control is

signal s_out_vector : std_logic_vector(7-1 downto 0);

begin

with Opcode select
    s_out_vector <= 
    "0110110" when "0000011", -- l*, lb, lh, lw -- was: "000000" -- FIXED: regWrite, ALU_Src, memToReg, MemRead
    "0000000" when "0001111", -- fence

    "0110000" when "0010011", -- ALUi -- was: "000011" -- FIXED: regWrite, ALU_Src (was setting branch and MemRead)

    "0100000" when "0010111", -- auipc -- was: "0000000" -- changed: regWrite (rd = PC + imm, taken from the PC branch adder)
    "0011000" when "0100011", -- s* -- was: "000000" -- FIXED: ALU_Src, memWrite

    "0100000" when "0110011", -- ALU -- was: "000001" -- FIXED: regWrite (was setting branch)

    "1100000" when "0110111", -- lui
    "0000001" when "1100011", -- b**, beq, bne -- was: "0000000" -- changed: branch (ALU compares rs1 and rs2, ALU_Src stays 0)
    "0100000" when "1101111", -- jal -- was: "0000000" -- changed: regWrite (rd = PC+4, target comes from the PC branch adder)
    "0110000" when "1100111", -- jalr -- added: regWrite, ALU_Src (ALU adds rs1 + imm for the target, rd = PC+4)
    "0000000" when "1110011", -- syscalls
    "0000000" when others;


branch   <= s_out_vector(0);
MemRead  <= s_out_vector(1);
memToReg <= s_out_vector(2);
memWrite <= s_out_vector(3);
ALU_Src  <= s_out_vector(4);
regWrite <= s_out_vector(5);
useImm <= s_out_vector(6);

-- auipc / jal / jalr flags, used by the processor to pick the write back data and the next PC
with Opcode select
    auipc <=
    '1' when "0010111", -- auipc
    '0' when others;

with Opcode select
    jal <=
    '1' when "1101111", -- jal
    '0' when others;

with Opcode select
    jalr <=
    '1' when "1100111", -- jalr
    '0' when others;


-- ALU op
-- addi, lw, sw and R-type instructions enter ALUControl.
with Opcode select
    ALU_Op <=
    "00" when "0000011", -- lw: address ADD: 2-bit ALUOp
    "00" when "0100011", -- sw: address ADD: 2-bit ALUOp
    "11" when "0010011", -- addi: ALUControl decodes funct3: 2-bit ALUOp
    "10" when "0110011", -- R-type: ALUControl determines add/sub: 2-bit ALUOp
    "01" when "1100011", -- branch: ALUControl picks sub/slt/sltu from funct3 -- added
    "00" when others;    -- 2-bit ALUOp


end dataflow;
