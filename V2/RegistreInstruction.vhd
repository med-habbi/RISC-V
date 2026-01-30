library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RegistreInstruction is
  port (
    clk      : in  std_logic;
    reset    : in  std_logic;
    enable   : in  std_logic; -- rienable
    din      : in  std_logic_vector(31 downto 0);
    dout     : out std_logic_vector(31 downto 0)
  );
end entity;

architecture Behavioral of RegistreInstruction is
  signal r : std_logic_vector(31 downto 0) := x"00000013"; -- NOP
begin
  process(clk, reset)
  begin
    if reset = '1' then
      r <= x"00000013";
    elsif rising_edge(clk) then
      if enable = '1' then
        r <= din;
      end if;
    end if;
  end process;

  dout <= r;
end Behavioral;
