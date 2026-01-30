library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RvDataRam is
  generic (
    gXlen      : natural := 32;
    gAddrWidth : natural := 32;
    gDepth     : natural := 100
  );
  port (
    iWordAddr : in  std_logic_vector(gAddrWidth-1 downto 0); -- word index
    iWriteData: in  std_logic_vector(gXlen-1 downto 0);
    iWe       : in  std_logic;
    iClk      : in  std_logic;
    oReadData : out std_logic_vector(gXlen-1 downto 0)
  );
end entity;

architecture rtl of RvDataRam is
  subtype word_t is std_logic_vector(gXlen-1 downto 0);
  type mem_t is array (0 to gDepth-1) of word_t;

  signal ram : mem_t := (others => (others => '0'));
  signal addrIdx : integer range 0 to gDepth-1;
begin
  addrIdx <= to_integer(unsigned(iWordAddr)) when to_integer(unsigned(iWordAddr)) < integer(gDepth) else 0;

  process(iClk)
  begin
    if rising_edge(iClk) then
      if iWe = '1' then
        ram(addrIdx) <= iWriteData;
      end if;
    end if;
  end process;

  oReadData <= ram(addrIdx);
end architecture;
