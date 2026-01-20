library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity SM is
    port(
        data   : in  std_logic_vector(31 downto 0);  -- rs2
        q      : in  std_logic_vector(31 downto 0);  -- mot actuel en mémoire
        funct3 : in  std_logic_vector(2 downto 0);   -- pour sb/sh/sw
        addrLSB: in  std_logic_vector(1 downto 0);   -- res(1 downto 0)
        dataOut: out std_logic_vector(31 downto 0)   -- nouveau mot à écrire
    );
end SM;

architecture Behavioral of SM is
begin
    process(data, q, funct3, addrLSB)
        variable tmp : std_logic_vector(31 downto 0);
    begin
        tmp := q;

        case funct3 is

            -- sb : store byte
            when "000" =>
                case addrLSB is
                    when "00" =>
                        tmp(7 downto 0)   := data(7 downto 0);
                    when "01" =>
                        tmp(15 downto 8)  := data(7 downto 0);
                    when "10" =>
                        tmp(23 downto 16) := data(7 downto 0);
                    when others => -- "11"
                        tmp(31 downto 24) := data(7 downto 0);
                end case;

            -- sh : store half-word (16 bits)
            when "001" =>
                if addrLSB(1) = '0' then
                    -- moitié basse du mot (bits 15..0)
                    tmp(15 downto 0)  := data(15 downto 0);
                else
                    -- moitié haute du mot (bits 31..16)
                    tmp(31 downto 16) := data(15 downto 0);
                end if;

            -- sw : store word (32 bits)
            when "010" =>
                tmp := data;

            when others =>
                tmp := q;
        end case;

        dataOut <= tmp;
    end process;
end Behavioral;
