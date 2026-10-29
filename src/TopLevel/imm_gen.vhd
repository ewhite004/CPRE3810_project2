
library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity imm_gen is
  port(inst_in: in std_logic_vector(32-1 downto 0);
	imm_out: out std_logic_vector(32-1 downto 0)
);

end imm_gen;

architecture mixed of imm_gen is

component extender is
    port 
    (
        i_sign_ex        : in std_logic;
        i_data            : in std_logic_vector(12-1 downto 0);
        o_data            : out std_logic_vector(32-1 downto 0)
    );
end component;

component appender is
    port 
    (
        i_data            : in std_logic_vector(20-1 downto 0);
        o_data            : out std_logic_vector(32-1 downto 0)
    );
end component;

component mux2t1_N is
  generic(N : integer := 16); -- Generic of type integer for input/output data width. Default value is 32.
  port(i_S          : in std_logic;
       i_D0         : in std_logic_vector(N-1 downto 0);
       i_D1         : in std_logic_vector(N-1 downto 0);
       o_O          : out std_logic_vector(N-1 downto 0));

end component;


signal opCode:std_logic_vector(7-1 downto 0);
signal funct3:std_logic_vector(3-1 downto 0);
signal s_imm12:std_logic_vector(12-1 downto 0);
signal s_imm20:std_logic_vector(20-1 downto 0);
signal sign_extend_en, ext_type_sel: std_logic;
signal s_opcode_funct3: std_logic_vector(10-1 downto 0); -- opcode & funct3 for the with/select below
signal extension, appendtion: std_logic_vector(32-1 downto 0);
signal s_imm_ea, s_imm_eab: std_logic_vector(32-1 downto 0); -- imm after the ext/app mux, and after the branch mux
signal s_branch_imm, s_jal_imm: std_logic_vector(32-1 downto 0); -- B-type and J-type immediates
signal sel_branch, sel_jal: std_logic; -- opcode is a branch / jal
--signal s_B_inv,s_mux_r :std_logic_vector(N-1 downto 0);
begin

opCode<=inst_in(7-1 downto 0);
funct3<=inst_in(14 downto 12);

s_opcode_funct3 <= opCode & funct3;

with s_opcode_funct3 select -- was: with opCode & funct3 select -- FIXED: GHDL rejects the concatenation as the selector (can't resolve overload for "&")
	sign_extend_en <= 
	'0' when "0110011"&"011",--sltu
	'0' when "0001111"&"011",--sltiu

	'1' when "0000011"&"100",--lbu -- was: '0' -- FIXED: RISC-V offsets are always sign-extended (only the loaded data is zero-extended)
	'1' when "0000011"&"101",--lhu -- was: '0' -- FIXED: same as lbu

	'1' when "1100011"&"110",--bltu -- was: '0' -- FIXED: branch offsets are always sign-extended (backward branches)
	'1' when "1100011"&"111",--bgeu -- was: '0' -- FIXED: same as bltu

	'1'  when others;

with opCode select
	ext_type_sel <= 
	'1' when "0110111",-- lui
	'1' when "0010111",-- auipc -- same U-type immediate as lui

	'0' when others;

-- B-type holds imm[12:1], so shift the sign-extended value left by 1 (branch offsets are multiples of 2)
s_branch_imm <= extension(30 downto 0) & '0';
-- J-type (jal) is imm[20|10:1|11|19:12] in inst[31:12]; rebuild imm[20:1] and append the 0 bit
s_jal_imm <= (11 downto 0 => inst_in(31)) & inst_in(19 downto 12) & inst_in(20) & inst_in(30 downto 21) & '0';

with opCode select
	sel_branch <=
	'1' when "1100011",-- branch
	'0' when others;

with opCode select
	sel_jal <=
	'1' when "1101111",-- jal
	'0' when others;

s_imm20<=inst_in(32-1 downto 12);
with opCode select
	s_imm12<=
	inst_in(32-1 downto 20) when "0000011"|"0001111"|"0010011"|"1100111",--I type, now also jalr (1100111) -- was: when "0000011"|"0001111"|"0010011",--I type
	inst_in(32-1 downto 25) & inst_in(12-1 downto 7) when "0100011",--S type
	inst_in(31) & inst_in(7) & inst_in(30 downto 25) & inst_in(11 downto 8) when "1100011",--SB type
	x"000" when others;

ext:extender
port  map
    (
        i_sign_ex => sign_extend_en,
        i_data => s_imm12,
        o_data =>extension
    );

app: appender 
    port map
    (
        i_data=>s_imm20,
        o_data=>appendtion
    );


mux_app_ext: mux2t1_N
  generic map(N => DATA_WIDTH) -- Generic of type integer for input/output data width. Default value is 32.
  port map(i_S  => ext_type_sel,
       i_D0 =>extension,
       i_D1 =>appendtion,
       o_O => s_imm_ea -- was: o_O => imm_out -- changed: branch and jal muxes follow
	);

mux_branch: mux2t1_N -- selects the shifted B-type immediate for branches
  generic map(N => DATA_WIDTH)
  port map(i_S  => sel_branch,
       i_D0 => s_imm_ea,
       i_D1 => s_branch_imm,
       o_O => s_imm_eab
	);

mux_jal: mux2t1_N -- selects the J-type immediate for jal
  generic map(N => DATA_WIDTH)
  port map(i_S  => sel_jal,
       i_D0 => s_imm_eab,
       i_D1 => s_jal_imm,
       o_O => imm_out
	);

end mixed;
