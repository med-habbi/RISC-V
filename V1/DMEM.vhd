library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity dmem is
    generic (
        DATA_WIDTH : natural := 32;
        ADDR_WIDTH : natural := 8;   -- 256 mots max
        MEM_DEPTH  : natural := 200;
        INIT_FILE  : string := ""    -- optionnel, non utilisé ici
    );
    port (
        addr    : in  std_logic_vector(31 downto 0);   -- adresse en octets
        din     : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        dout    : out std_logic_vector(DATA_WIDTH-1 downto 0);
        WE      : in  std_logic;                      -- 1 = write, 0 = read
        clk     : in  std_logic
    );
end entity dmem;

architecture Behavioral of dmem is

    type memType is array (0 to MEM_DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);
    signal mem : memType := (others => (others => '0'));

begin
    -- écriture synchrone
    process(clk)
        variable index : integer;
    begin
        if rising_edge(clk) then
            index := to_integer(unsigned(addr(9 downto 2)));  -- adresse mot (alignée)
            if WE = '1' and index >= 0 and index < MEM_DEPTH then
                mem(index) <= din;
            end if;
        end if;
    end process;

    -- lecture asynchrone
    process(addr, mem)
        variable index : integer;
    begin
        index := to_integer(unsigned(addr(9 downto 2)));
        if index >= 0 and index < MEM_DEPTH then
            dout <= mem(index);
        else
            dout <= (others => '0');
        end if;
    end process;

end Behavioral;
