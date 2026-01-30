library ieee;
use ieee.std_logic_1164.all;

entity mux2to1 is
  generic ( gDataWidth : integer := 32 );
  port (
    iIn0  : in  std_logic_vector(gDataWidth-1 downto 0);
    iIn1  : in  std_logic_vector(gDataWidth-1 downto 0);
    iSel  : in  std_logic;
    oOut  : out std_logic_vector(gDataWidth-1 downto 0)
  );
end entity;

architecture rtl of mux2to1 is
begin
  oOut <= iIn0 when iSel = '0' else iIn1;
end architecture;
