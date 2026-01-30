library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RvRegFile is
  generic ( gXlen : integer := 32 );
  port (
    iRa    : in  std_logic_vector(4 downto 0);
    iRb    : in  std_logic_vector(4 downto 0);
    iRw    : in  std_logic_vector(4 downto 0);
    iWd    : in  std_logic_vector(gXlen-1 downto 0);
    oA     : out std_logic_vector(gXlen-1 downto 0);
    oB     : out std_logic_vector(gXlen-1 downto 0);
    iWe    : in  std_logic;
    iClk   : in  std_logic;
    iRst   : in  std_logic
  );
end entity;

architecture rtl of RvRegFile is
  type regArray_t is array (0 to 31) of std_logic_vector(gXlen-1 downto 0);
  signal rf : regArray_t;
  constant cX0 : std_logic_vector(4 downto 0) := (others => '0');
begin
  process(iClk, iRst)
  begin
    if iRst = '1' then
      for i in 0 to 31 loop
        rf(i) <= std_logic_vector(to_unsigned(i, gXlen));
      end loop;
    elsif rising_edge(iClk) then
      if iWe = '1' and iRw /= cX0 then
        rf(to_integer(unsigned(iRw))) <= iWd;
      end if;
    end if;
  end process;

  oA <= rf(to_integer(unsigned(iRa)));
  oB <= rf(to_integer(unsigned(iRb)));
end architecture;
