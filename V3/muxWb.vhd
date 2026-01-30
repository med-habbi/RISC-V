library ieee;
use ieee.std_logic_1164.all;

entity muxWb is
  generic ( gDataWidth : integer := 32 );
  port (
    iAlu   : in  std_logic_vector(gDataWidth-1 downto 0); -- 00
    iMem   : in  std_logic_vector(gDataWidth-1 downto 0); -- 01
    iPc4   : in  std_logic_vector(gDataWidth-1 downto 0); -- 10
    iSel   : in  std_logic_vector(1 downto 0);
    oOut   : out std_logic_vector(gDataWidth-1 downto 0)
  );
end entity;

architecture rtl of muxWb is
begin
  with iSel select oOut <=
    iAlu         when "00",
    iMem         when "01",
    iPc4         when "10",
    (others=>'0') when others;
end architecture;
 