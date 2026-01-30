library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity imem is
  generic (
    DATA_WIDTH : natural := 32;
    ADDR_WIDTH : natural := 8;
    MEM_DEPTH  : natural := 200;
    INIT_FILE  : string  := "C:/Users/mhabb/Desktop/S9/dscp/Habbi/add02.hex"
  );
  port (
    clk  : in  std_logic;
    addr : in  std_logic_vector(31 downto 0);
    inst : out std_logic_vector(31 downto 0)
  );
end entity imem;

architecture Behavioral of imem is
  type memType is array (0 to MEM_DEPTH-1) of std_logic_vector(DATA_WIDTH-1 downto 0);

  function strtoslv(str : string) return std_logic_vector is
    alias strnorm : string(1 to str'length) is str;
    variable resv : std_logic_vector(4*str'length-1 downto 0);
    variable charv : character;
    variable valofchar : natural := 0;
  begin
    for i in strnorm'range loop
      charv := strnorm(i);
      case charv is
        when '0' to '9' => valofchar := character'pos(charv) - character'pos('0');
        when 'A' to 'F' => valofchar := character'pos(charv) - character'pos('A') + 10;
        when 'a' to 'f' => valofchar := character'pos(charv) - character'pos('a') + 10;
        when others =>
          report "strtoslv: invalid hex character" severity ERROR;
          valofchar := 0;
      end case;
      resv(resv'left - 4*i + 4 downto resv'left - 4*i + 1) :=
        std_logic_vector(to_unsigned(valofchar, 4));
    end loop;
    return resv;
  end function;

  impure function memInit(fileName : string) return memType is
    variable memtmp   : memType := (others => (others => '0'));
    file f            : text;
    variable L         : line;
    variable instrstr  : string(1 to 8);
    variable instnum   : integer := 0;
    variable instrinit : std_logic_vector(31 downto 0);
  begin
    file_open(f, fileName, READ_MODE);
    while (instnum < MEM_DEPTH and not endfile(f)) loop
      readline(f, L);
      read(L, instrstr);
      instrinit := strtoslv(instrstr);
      memtmp(instnum) := instrinit;
      instnum := instnum + 1;
    end loop;
    file_close(f);
    return memtmp;
  end function;

  signal mem      : memType := memInit(INIT_FILE);
  signal inst_reg : std_logic_vector(31 downto 0) := (others => '0');

begin
  process(clk)
    variable index : integer;
  begin
    if rising_edge(clk) then
      index := to_integer(unsigned(addr(9 downto 2)));
      if (index >= 0) and (index < MEM_DEPTH) then
        inst_reg <= mem(index);
      else
        inst_reg <= (others => '0');
      end if;
    end if;
  end process;

  inst <= inst_reg;
end Behavioral;
