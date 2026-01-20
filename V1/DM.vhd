library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DM is
    generic (
        ADDR_WIDTH : natural := 8;   -- 2^8 mots de 4 octets = 1024 octets
        MEM_DEPTH  : natural := 256  -- nombre de mots (4 octets)
    );
    port (
        addr   : in  std_logic_vector(31 downto 0);  -- adresse en octets
        data   : in  std_logic_vector(31 downto 0);  -- données à écrire (RS2)
        q      : out std_logic_vector(31 downto 0);  -- 4 octets lus
        wrMem  : in  std_logic_vector(3 downto 0);   -- bits d'écriture par octet
        clk    : in  std_logic
    );
end entity DM;

architecture Behavioral of DM is

    -- mémoire organisée en octets : 4 tableaux de 8 bits
    type byte_mem is array (0 to MEM_DEPTH-1) of std_logic_vector(7 downto 0);

    signal mem0 : byte_mem := (others => (others => '0')); -- addr+0
    signal mem1 : byte_mem := (others => (others => '0')); -- addr+1
    signal mem2 : byte_mem := (others => (others => '0')); -- addr+2
    signal mem3 : byte_mem := (others => (others => '0')); -- addr+3

begin

    -- écriture synchrone
    process(clk)
        variable index : integer;
    begin
        if rising_edge(clk) then
            -- on prend addr(ADDR_WIDTH+1 downto 2) -> index de mot (aligné)
            index := to_integer(unsigned(addr(ADDR_WIDTH+1 downto 2)));
            if index >= 0 and index < MEM_DEPTH then
                -- wrMem(0) : écrit octet à addr + 0
                if wrMem(0) = '1' then
                    mem0(index) <= data(7 downto 0);
                end if;
                -- wrMem(1) : écrit octet à addr + 1
                if wrMem(1) = '1' then
                    mem1(index) <= data(15 downto 8);
                end if;
                -- wrMem(2) : écrit octet à addr + 2
                if wrMem(2) = '1' then
                    mem2(index) <= data(23 downto 16);
                end if;
                -- wrMem(3) : écrit octet à addr + 3
                if wrMem(3) = '1' then
                    mem3(index) <= data(31 downto 24);
                end if;
            end if;
        end if;
    end process;

    -- lecture asynchrone : 4 octets consécutifs
    process(addr, mem0, mem1, mem2, mem3)
        variable index : integer;
        variable tmp   : std_logic_vector(31 downto 0);
    begin
        index := to_integer(unsigned(addr(ADDR_WIDTH+1 downto 2)));
        if index >= 0 and index < MEM_DEPTH then
            tmp(7 downto 0)   := mem0(index);
            tmp(15 downto 8)  := mem1(index);
            tmp(23 downto 16) := mem2(index);
            tmp(31 downto 24) := mem3(index);
        else
            tmp := (others => '0');
        end if;
        q <= tmp;
    end process;

end Behavioral;
