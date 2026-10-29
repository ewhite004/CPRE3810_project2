library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_tb is
end control_tb;

architecture mixed of control_tb is

	component control is
	port(Opcode   : in std_logic_vector(7-1 downto 0);
       auipc, jal, jalr : out std_logic; -- auipc writes PC+imm to rd; jal/jalr are jumps (next PC and rd = PC+4 handled in the processor)
       ALU_Op   : out std_logic_vector(2-1 downto 0); -- ALUControl takes a 2-bit ALUOp
       branch, MemRead, memToReg, memWrite, ALU_Src, regWrite, useImm : out std_logic
 	 );	
	end component;

signal s_opCode: std_logic_vector(7-1 downto 0);
signal s_auipc,s_jal,s_jalr,s_branch,s_MemRead,s_memToReg,s_memWrite,s_ALU_Src,s_regWrite,s_useImm :std_logic;
signal s_ALU_Op : std_logic_vector(2-1 downto 0);

begin
myC: control
port map(Opcode =>s_opCode,
       auipc=>s_auipc, jal=>s_jal, jalr=>s_jalr,
       ALU_Op=>s_alu_op,
       branch=>s_branch, MemRead=>s_MemRead, memToReg=>s_memToReg, memWrite=>s_memWrite, ALU_Src=>s_ALU_src, regWrite=>s_regWrite, useImm=>s_useImm
 	);	


tb:process
begin
	s_opCode<="0000011";
	wait for 10 ns;

	s_opCode<="0001111";
	wait for 10 ns;

	s_opCode<="0010011";
	wait for 10 ns;

	s_opCode<="0010111";
	wait for 10 ns;

	s_opCode<="0100011";
	wait for 10 ns;

	s_opCode<="0110011";
	wait for 10 ns;

	s_opCode<="0110111";
	wait for 10 ns;

	s_opCode<="1100011";
	wait for 10 ns;

	s_opCode<="1101111";
	wait for 10 ns;

	s_opCode<="1100111";
	wait for 10 ns;

	s_opCode<="1110011";
	wait for 10 ns;

	s_opCode<="0010111";
	wait for 10 ns;

	s_opCode<="1101111";
	wait for 10 ns;

	s_opCode<="1100111";
	wait for 10 ns;

end process;

end mixed;

