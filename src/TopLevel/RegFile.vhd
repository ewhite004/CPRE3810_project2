library IEEE;
use IEEE.std_logic_1164.all;
use work.RISCV_types.all;

entity RegFile is
  port(i_CLK, RST          : in std_logic;
	i_RegWr                 : in std_logic; -- added: FIXED: regfile had no write enable, so every instruction (even sw) wrote a register
	i_WrEN_sel,i_sel_rs1,i_sel_rs2: in std_logic_vector(5-1 downto 0);
	i_DATA: in std_logic_vector(32-1 downto 0);
	o_DATA1,o_DATA2: out std_logic_vector(32-1 downto 0)
);

end RegFile;

architecture structural of RegFile is

  component mux32_32t1 is
  port(
	i_W_VV : in vector_32x32;
	i_SEL        : in std_logic_vector(5-1 downto 0);     -- input
       o_OUT        : out std_logic_vector(32-1 downto 0)     -- output
	);
end component;

component decoder_5t32 is

  port(i_SEL        : in std_logic_vector(5-1 downto 0);     -- input
       o_HOT        : out std_logic_vector(32-1 downto 0)     -- output
	);

end component;

component dffg_N is
	generic(N : integer := 32);
	port(i_CLK        : in std_logic;     -- Clock input
       	i_RST        : in std_logic;     -- Reset input
       	i_WE         : in std_logic;     -- Write enable input
       	i_D          : in std_logic_vector(N-1 downto 0);     -- Data value input
       	o_Q          : out std_logic_vector(N-1 downto 0)   -- Data value output
	);
end component;

signal rd_wire:std_logic_vector(32-1 downto 0);
signal s_we   :std_logic_vector(32-1 downto 0); -- added: decoder output gated with i_RegWr
signal reg_rs: vector_32x32;
--signal s_B_inv,s_mux_r :std_logic_vector(N-1 downto 0);
begin

s_we <= rd_wire and (rd_wire'range => i_RegWr); -- added: only write when RegWrite is asserted

dffg_N0: dffg_N 
	generic map(N=>32)
	port map(
	i_CLK =>i_CLK,
       	i_RST => '1',
       	i_WE => rd_Wire(0),
       	i_D  => i_DATA,
       	o_Q  => reg_rs(0)	);
G_NBYTE_DFFG_N: for i in 1 to 32-1 generate
	dffg_N_I: dffg_N
	generic map(N=>32)
	port map(
	i_CLK =>i_CLK,
       	i_RST => RST,
       	i_WE => s_we(i), -- was: i_WE => rd_Wire(i), -- FIXED: gated with RegWrite (x0 above is held in reset so it is unchanged)
       	i_D  => i_DATA,
       	o_Q  => reg_rs(i)	);
end generate G_NBYTE_DFFG_N;



rs1:mux32_32t1
port map(
	i_W_VV =>reg_rs,
	i_SEL =>i_sel_rs1,
       o_OUT =>o_DATA1
	);

rs2:mux32_32t1
port map(
	i_W_VV =>reg_rs,
	i_SEL =>i_sel_rs2,
       o_OUT =>o_DATA2
	);

rd:decoder_5t32

  port map(i_SEL => i_WrEN_sel,    
       o_HOT => rd_wire  	
	);



	
  
end structural;
