library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RvPcCounter is
  generic ( gAddrWidth : integer := 32 );
  port (
    iNextPc     : in  std_logic_vector(gAddrWidth-1 downto 0);
    iClk        : in  std_logic;
    iRst        : in  std_logic;
    iLoad       : in  std_logic;
    iPcEnable   : in  std_logic;
    oPc         : out std_logic_vector(gAddrWidth-1 downto 0);
    oPcPlus4    : out std_logic_vector(gAddrWidth-1 downto 0)
  );
end entity;

architecture rtl of RvPcCounter is
  signal pcQ : unsigned(gAddrWidth-1 downto 0);
begin
  process(iClk, iRst)
  begin
    if iRst = '1' then
      pcQ <= (others => '0');
    elsif rising_edge(iClk) then
      if iLoad = '1' then
        pcQ <= unsigned(iNextPc);
      elsif iPcEnable = '1' then
        pcQ <= pcQ + 4;
      end if;
    end if;
  end process;

  oPc      <= std_logic_vector(pcQ);
  oPcPlus4 <= std_logic_vector(pcQ + 4);
end architecture;
