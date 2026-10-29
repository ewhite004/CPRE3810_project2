-------------------------------------------------------------------------
-- Henry Duwe
-- Department of Electrical and Computer Engineering
-- Iowa State University
-------------------------------------------------------------------------


-- Reg.vhd
-------------------------------------------------------------------------
-- DESCRIPTION: This file contains an implementation of a behavioral 
-- register that delays the input by one clock cycle. 
--
--


-- 1/14/18 by H3::Design created.
-- 1/16/25 by CWS::Switched from integer to std_logic_vector.
-------------------------------------------------------------------------

library IEEE;
use IEEE.std_logic_1164.all;

entity Reg is

  generic(DATA_WIDTH : integer := 32);

  port(iCLK             : in std_logic;
       iD               : in std_logic_vector(DATA_WIDTH-1 downto 0);
       oQ               : out std_logic_vector(DATA_WIDTH-1 downto 0));

end Reg;

architecture behavior of Reg is
begin

  process(iCLK, iD)
  begin
    if rising_edge(iCLK) then
	   oQ <= iD;
    end if;
  end process;
  
end behavior;
