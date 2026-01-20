library ieee;
use ieee.std_logic_1164.all;

entity Mux2to1 is
    generic(
        DATA_WIDTH : natural := 32
    );
    port(
        in0    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        in1    : in  std_logic_vector(DATA_WIDTH-1 downto 0);
        sel    : in  std_logic;
        output : out std_logic_vector(DATA_WIDTH-1 downto 0)
    );
end Mux2to1;

architecture Behavioral of Mux2to1 is
begin
    output <= in0 when sel = '0' else in1;
end Behavioral;
