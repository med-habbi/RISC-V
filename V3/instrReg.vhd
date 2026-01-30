library ieee;
use ieee.std_logic_1164.all;

entity instrReg is
  generic ( gDataWidth : integer := 32 );
  port (
    iClk      : in  std_logic;
    iRst      : in  std_logic;
    iEnable   : in  std_logic;
    iData     : in  std_logic_vector(gDataWidth-1 downto 0);
    oData     : out std_logic_vector(gDataWidth-1 downto 0)
  );
end entity;

architecture rtl of instrReg is
begin
  process(iClk, iRst)
  begin
    if iRst = '1' then
      oData <= (others => '0');
    elsif rising_edge(iClk) then
      if iEnable = '1' then
        oData <= iData;
      end if;
    end if;
  end process;
end architecture;
