library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PC is
  port (
    clk    : in  std_logic;
    reset  : in  std_logic;
    enable : in  std_logic; -- pcenable
    load   : in  std_logic;
    din    : in  std_logic_vector(31 downto 0);
    dout   : out std_logic_vector(31 downto 0)
  );
end PC;

architecture Behavioral of PC is
  signal pcreg : unsigned(31 downto 0) := (others => '0');
begin
  process(clk, reset)
  begin
    if reset = '1' then
      pcreg <= (others => '0');
    elsif rising_edge(clk) then
      if enable = '1' then
        if load = '1' then
          pcreg <= unsigned(din);
        else
          pcreg <= pcreg + 4;
        end if;
      end if;
    end if;
  end process;

  dout <= std_logic_vector(pcreg);
end Behavioral;
