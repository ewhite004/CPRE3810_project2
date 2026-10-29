-- load_ext.vhd
-- the load data unit
-- The data memory returns a whole 32-bit word, so for lb, lh, lbu and lhu this unit picks
-- the addressed byte/halfword out of the word (using the low address bits)
-- and sign-extends (lb, lh) or zero-extends (lbu, lhu) it to 32 bits.
-- lw passes the whole word through.

library IEEE;
use IEEE.std_logic_1164.all;

entity load_ext is
  port(
    i_Data   : in std_logic_vector(32-1 downto 0);  -- word read from the data memory
    i_Addr   : in std_logic_vector(2-1 downto 0);   -- low 2 bits of the byte address
    i_Funct3 : in std_logic_vector(3-1 downto 0);   -- load type (instruction bits 14:12)
    o_Data   : out std_logic_vector(32-1 downto 0)  -- value written to the register file
  );
end load_ext;


architecture dataflow of load_ext is

  signal s_Byte     : std_logic_vector(8-1 downto 0);
  signal s_Half     : std_logic_vector(16-1 downto 0);
  signal s_ByteSign : std_logic_vector(24-1 downto 0);  -- sign bits for lb
  signal s_HalfSign : std_logic_vector(16-1 downto 0);  -- sign bits for lh

begin

  -- addressed byte of the word (little endian)
  with i_Addr select
    s_Byte <=
      i_Data(7 downto 0)   when "00",
      i_Data(15 downto 8)  when "01",
      i_Data(23 downto 16) when "10",
      i_Data(31 downto 24) when others;

  -- addressed halfword of the word
  with i_Addr(1) select
    s_Half <=
      i_Data(15 downto 0)  when '0',
      i_Data(31 downto 16) when others;

  s_ByteSign <= (others => s_Byte(7));
  s_HalfSign <= (others => s_Half(15));

  with i_Funct3 select
    o_Data <=
      s_ByteSign & s_Byte  when "000",  -- lb, sb
      s_HalfSign & s_Half  when "001",  -- lh, sh
      i_Data               when "010",  -- lw, sw
      x"000000" & s_Byte   when "100",  -- lbu
      x"0000" & s_Half     when "101",  -- lhu
      i_Data               when others;

end dataflow;
