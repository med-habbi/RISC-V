library ieee;
use ieee.std_logic_1164.all;

entity controller_fsm_5 is
  port(
    clk       : in  std_logic;
    reset     : in  std_logic;
    pcenable  : out std_logic;
    rienable  : out std_logic;
    state_dbg : out std_logic_vector(2 downto 0)
  );
end entity;

architecture Behavioral of controller_fsm_5 is
  type state_t is (FETCH, DECODE, EXECUTE, MEMORY, WRITEBACK);
  signal st, st_n : state_t;
begin
  process(clk, reset)
  begin
    if reset = '1' then
      st <= FETCH;
    elsif rising_edge(clk) then
      st <= st_n;
    end if;
  end process;

  process(st)
  begin
    case st is
      when FETCH     => st_n <= DECODE;
      when DECODE    => st_n <= EXECUTE;
      when EXECUTE   => st_n <= MEMORY;
      when MEMORY    => st_n <= WRITEBACK;
      when WRITEBACK => st_n <= FETCH;
    end case;
  end process;

  process(st)
  begin
    pcenable <= '0';
    rienable <= '0';

    case st is
      when FETCH =>
        pcenable <= '1';
        rienable <= '1';
      when others =>
        pcenable <= '0';
        rienable <= '0';
    end case;

    case st is
      when FETCH     => state_dbg <= "000";
      when DECODE    => state_dbg <= "001";
      when EXECUTE   => state_dbg <= "010";
      when MEMORY    => state_dbg <= "011";
      when WRITEBACK => state_dbg <= "100";
    end case;
  end process;
end Behavioral;
