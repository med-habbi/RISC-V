library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use std.textio.all;

entity imem is
    generic (
        DATA_WIDTH : natural := 32;
        ADDR_WIDTH : natural := 8;
        MEM_DEPTH  : natural := 200;
        INIT_FILE  : string := "C:/Users/mhabb/Desktop/S9/dscp/Habbi/add_02.hex"
    );
    port (
        addr : in  std_logic_vector(31 downto 0);   -- adresse PC (octets)
        inst : out std_logic_vector(31 downto 0)    -- instruction
    );
end entity imem;

architecture Behavioral of imem is

    type memType is array (0 to MEM_DEPTH - 1) of std_logic_vector(DATA_WIDTH - 1 downto 0);

    -- conversion chaine hexa (8 caractères) -> std_logic_vector(31 downto 0)
    function str_to_slv(str : string) return std_logic_vector is
        alias str_norm : string(1 to str'length) is str;
        variable char_v       : character;
        variable val_of_char  : natural;
        variable res_v        : std_logic_vector(4 * str'length - 1 downto 0);
    begin
        for i in str_norm'range loop
            char_v := str_norm(i);
            case char_v is
                when '0' to '9' =>
                    val_of_char := character'pos(char_v) - character'pos('0');
                when 'A' to 'F' =>
                    val_of_char := character'pos(char_v) - character'pos('A') + 10;
                when 'a' to 'f' =>
                    val_of_char := character'pos(char_v) - character'pos('a') + 10;
                when others =>
                    report "str_to_slv: invalid hex character" severity ERROR;
            end case;
            res_v(res_v'left - 4 * i + 4 downto res_v'left - 4 * i + 1) :=
                std_logic_vector(to_unsigned(val_of_char, 4));
        end loop;
        return res_v;
    end function;

    -- lecture du fichier texte hexa
    function memInit(fileName : string) return memType is
        variable mem_tmp    : memType := (others => (others => '0'));
        file     f          : text;
        variable L          : line;
        variable instr_str  : string(1 to 8);
        variable inst_num   : integer := 0;
        variable instr_init : std_logic_vector(31 downto 0);
    begin
        file_open(f, fileName, READ_MODE);
        while (inst_num < MEM_DEPTH and not endfile(f)) loop
            readline(f, L);
            read(L, instr_str);
            instr_init := str_to_slv(instr_str);
            mem_tmp(inst_num) := instr_init;
            inst_num := inst_num + 1;
        end loop;
        file_close(f);
        return mem_tmp;
    end function;

    signal mem : memType := memInit(INIT_FILE);

begin
    -- Lecture asynchrone, adressage par mots
    process(addr)
        variable index : integer;
    begin
        -- PC en octets → division par 4 : bits (9 downto 2)
        index := to_integer(unsigned(addr(9 downto 2)));
        if index >= 0 and index < MEM_DEPTH then
            inst <= mem(index);
        else
            inst <= (others => '0');
        end if;
    end process;

end Behavioral;
