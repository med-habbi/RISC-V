library ieee;
use ieee.std_logic_1164.all;

entity RvCpuTopTb is
end entity;

architecture tb of RvCpuTopTb is
  component RvCpuTop
    generic (
      gXlen      : integer := 32;
      gAddrWidth : integer := 32;
      gDepth     : integer := 100;
      gProgFile  : string  := "add_r.hex"
    );
    port (
      iClk : in std_logic;
      iRst : in std_logic
    );
  end component;

  constant cXlen      : integer := 32;
  constant cAddrWidth : integer := 32;
  constant cDepth     : integer := 100;
  constant cProgFile  : string  := "C:/Users/mhabb/Downloads/RISC-V/V3/add_r.hex";


  signal clk : std_logic := '0';
  signal rst : std_logic := '1';
begin
  dut: RvCpuTop
    generic map (
      gXlen      => cXlen,
      gAddrWidth => cAddrWidth,
      gDepth     => cDepth,
      gProgFile  => cProgFile
    )
    port map (
      iClk => clk,
      iRst => rst
    );

  clk <= not clk after 5 ns;  -- 100 MHz

  process
  begin
    rst <= '1';
    wait for 50 ns;
    rst <= '0';

    -- Let it run for a while (adjust to your program length)
    wait for 5 us;

    -- Stop simulation (portable)
    assert false report "TB finished (timeout reached)" severity failure; -- [web:39]
    wait;
  end process;
end architecture;
