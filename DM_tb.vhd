library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DM_tb is
end DM_tb;

architecture Behavioral of DM_tb is

    component DM is
        generic (
            ADDR_WIDTH : natural := 8;
            MEM_DEPTH  : natural := 256
        );
        port (
            addr   : in  std_logic_vector(31 downto 0);
            data   : in  std_logic_vector(31 downto 0);
            q      : out std_logic_vector(31 downto 0);
            wrMem  : in  std_logic_vector(3 downto 0);
            clk    : in  std_logic
        );
    end component;

    signal clk   : std_logic := '0';
    signal addr  : std_logic_vector(31 downto 0) := (others => '0');
    signal data  : std_logic_vector(31 downto 0) := (others => '0');
    signal q     : std_logic_vector(31 downto 0);
    signal wrMem : std_logic_vector(3 downto 0) := "0000";

    constant clk_period : time := 10 ns;

begin

    UUT : DM
        port map(
            addr  => addr,
            data  => data,
            q     => q,
            wrMem => wrMem,
            clk   => clk
        );

    -- Horloge
    clk_process : process
    begin
        clk <= '0';
        wait for clk_period/2;
        clk <= '1';
        wait for clk_period/2;
    end process;

    -- Stimuli
    stim_proc : process
    begin
        ----------------------------------------------------------------
        -- 1) Ecrire un mot complet à l'adresse 0 : 0x11223344
        ----------------------------------------------------------------
        addr  <= x"00000000";
        data  <= x"11223344";
        wrMem <= "1111";        -- sw
        wait for clk_period;
        wrMem <= "0000";
        wait for 20 ns;

        ----------------------------------------------------------------
        -- 2) Ecrire un demi-mot bas (bytes 0 et 1) : 0xAABB
        --    Résultat attendu : 0x1122AABB
        ----------------------------------------------------------------
        addr  <= x"00000000";
        data  <= x"0000AABB";
        wrMem <= "0011";        -- sh bas
        wait for clk_period;
        wrMem <= "0000";
        wait for 20 ns;

        ----------------------------------------------------------------
        -- 3) Ecrire un octet de poids fort (byte 3) : 0xCC
        --    Résultat attendu : 0xCC22AABB
        ----------------------------------------------------------------
        addr  <= x"00000000";
        data  <= x"CC000000";
        wrMem <= "1000";        -- sb sur byte 3
        wait for clk_period;
        wrMem <= "0000";
        wait for 20 ns;

        ----------------------------------------------------------------
        -- 4) Lire à nouveau à 0 : vérifier q = 0xCC22AABB
        ----------------------------------------------------------------
        addr  <= x"00000000";
        wait for 40 ns;

        ----------------------------------------------------------------
        -- 5) Ecrire un mot complet à l'adresse 16 (index 4) : 0xDEADBEEF
        ----------------------------------------------------------------
        addr  <= x"00000010";   -- 16 décimal
        data  <= x"DEADBEEF";
        wrMem <= "1111";
        wait for clk_period;
        wrMem <= "0000";
        wait for 20 ns;

        ----------------------------------------------------------------
        -- 6) Lire à cette adresse : q doit valoir 0xDEADBEEF
        ----------------------------------------------------------------
        addr  <= x"00000010";
        wait for 40 ns;

        wait;
    end process;

end Behavioral;
