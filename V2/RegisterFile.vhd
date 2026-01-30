library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RegisterFile is
    port(
        clk : in  std_logic;
        reset : in std_logic;
        WE  : in  std_logic;  -- Write Enable
        RA  : in  std_logic_vector(4 downto 0);  -- Read Address A (rs1)
        RB  : in  std_logic_vector(4 downto 0);  -- Read Address B (rs2)
        RW  : in  std_logic_vector(4 downto 0);  -- Write Address (rd)
        BusW : in  std_logic_vector(31 downto 0);  -- Write Data
        BusA : out std_logic_vector(31 downto 0);  -- Read Data A
        BusB : out std_logic_vector(31 downto 0)   -- Read Data B
    );
end RegisterFile;

architecture Behavioral of RegisterFile is
    type reg_array is array (0 to 31) of std_logic_vector(31 downto 0);
    signal registers : reg_array := (others => (others => '0'));
begin
    -- Lecture asynchrone
    process(RA, RB, registers)
    begin
        BusA <= registers(to_integer(unsigned(RA)));
        BusB <= registers(to_integer(unsigned(RB)));
    end process;
    
    -- Écriture synchrone
    process(clk, reset)
    begin
        if reset = '1' then
            -- Initialisation: REG[i] = i
            for i in 0 to 31 loop
                registers(i) <= std_logic_vector(to_unsigned(i, 32));
            end loop;
        elsif rising_edge(clk) then
            if WE = '1' and to_integer(unsigned(RW)) /= 0 then
                -- x0 est toujours 0, on ne peut pas écrire dedans
                registers(to_integer(unsigned(RW))) <= BusW;
            end if;
        end if;
    end process;
end Behavioral;
