library ieee;
use ieee.std_logic_1164.all;

entity tb_RISCV_Top_DM1 is
end tb_RISCV_Top_DM1;

architecture Behavioral of tb_RISCV_Top_DM1 is

    component RISCV_Top_DM1 is
        port(
            clk   : in std_logic;
            reset : in std_logic
        );
    end component;

    signal clk   : std_logic := '0';
    signal reset : std_logic := '0';

    constant clk_period : time := 10 ns;

begin

    uut : RISCV_Top_DM1
        port map(
            clk   => clk,
            reset => reset
        );

    -- Horloge
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Reset + run
    stim_proc : process
    begin
        reset <= '1';
        wait for 20 ns;
        reset <= '0';

        wait for 800 ns;
        wait;
    end process;

end Behavioral;

