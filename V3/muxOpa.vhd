library ieee;
use ieee.std_logic_1164.all;

entity muxOpa is
  generic ( gDataWidth : integer := 32 );
  port (
    iRs1   : in  std_logic_vector(gDataWidth-1 downto 0); -- 00
    iPc    : in  std_logic_vector(gDataWidth-1 downto 0); -- 01
    iZero  : in  std_logic_vector(gDataWidth-1 downto 0); -- 10
    iSel   : in  std_logic_vector(1 downto 0);
    oOut   : out std_logic_vector(gDataWidth-1 downto 0)
  );
end entity;

architecture rtl of muxOpa is
  constant cZeroVec : std_logic_vector(gDataWidth-1 downto 0) := (others => '0');
begin
  with iSel select oOut <=
    iRs1     when "00",
    iPc      when "01",
    cZeroVec when "10",
    cZeroVec when others;
end architecture;
