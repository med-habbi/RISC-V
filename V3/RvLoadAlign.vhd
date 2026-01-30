library ieee;
use ieee.std_logic_1164.all;

entity RvLoadAlign is
  generic ( gXlen : integer := 32 );
  port (
    iWord      : in  std_logic_vector(gXlen-1 downto 0);
    iAddrLo    : in  std_logic_vector(1 downto 0);
    iFunct3    : in  std_logic_vector(2 downto 0);
    oLoadData  : out std_logic_vector(gXlen-1 downto 0)
  );
end entity;

architecture rtl of RvLoadAlign is
  alias b0 : std_logic_vector(7 downto 0) is iWord(7 downto 0);
  alias b1 : std_logic_vector(7 downto 0) is iWord(15 downto 8);
  alias b2 : std_logic_vector(7 downto 0) is iWord(23 downto 16);
  alias b3 : std_logic_vector(7 downto 0) is iWord(31 downto 24);

  alias h0 : std_logic_vector(15 downto 0) is iWord(15 downto 0);
  alias h1 : std_logic_vector(15 downto 0) is iWord(31 downto 16);

  signal selByte : std_logic_vector(7 downto 0);
  signal selHalf : std_logic_vector(15 downto 0);
  signal signB   : std_logic;
  signal signH   : std_logic;

  alias isUnsigned : std_logic is iFunct3(2);
  alias sizeSel    : std_logic_vector(1 downto 0) is iFunct3(1 downto 0);
begin
  with iAddrLo select selByte <=
    b0 when "00",
    b1 when "01",
    b2 when "10",
    b3 when others;

  selHalf <= h0 when iAddrLo(1) = '0' else h1;

  signB <= '0' when isUnsigned = '1' else selByte(7);
  signH <= '0' when isUnsigned = '1' else selHalf(15);

  process(sizeSel, selByte, selHalf, iWord, signB, signH)
  begin
    case sizeSel is
      when "00" => oLoadData <= (31 downto 8  => signB) & selByte; -- LB/LBU
      when "01" => oLoadData <= (31 downto 16 => signH) & selHalf; -- LH/LHU
      when "10" => oLoadData <= iWord;                              -- LW
      when others => oLoadData <= iWord;
    end case;
  end process;
end architecture;
