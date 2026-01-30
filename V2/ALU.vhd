library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ALU is
	port
   (	opA : in std_logic_vector(31 downto 0);
	opB : in std_logic_vector(31 downto 0);
	aluOp : in std_logic_vector(3 downto 0);
	res : out std_logic_vector(31 downto 0)
		
	);

end entity;

architecture Behavioral of ALU is
    constant ALU_ADD  : std_logic_vector(3 downto 0) := "0000";
    constant ALU_SUB  : std_logic_vector(3 downto 0) := "0001";
    constant ALU_SLL  : std_logic_vector(3 downto 0) := "0010";
    constant ALU_SLT  : std_logic_vector(3 downto 0) := "0011";
    constant ALU_SLTU : std_logic_vector(3 downto 0) := "0100";
    constant ALU_XOR  : std_logic_vector(3 downto 0) := "0101";
    constant ALU_SRL  : std_logic_vector(3 downto 0) := "0110";
    constant ALU_SRA  : std_logic_vector(3 downto 0) := "0111";
    constant ALU_OR   : std_logic_vector(3 downto 0) := "1000";
    constant ALU_AND  : std_logic_vector(3 downto 0) := "1001";
    
    signal shift_amount : integer range 0 to 31;
begin
    shift_amount <= to_integer(unsigned(opB(4 downto 0)));
    
    process(opA, opB, aluOp, shift_amount)
    begin
        case aluOp is
            when ALU_ADD =>  -- Addition
                res <= std_logic_vector(signed(opA) + signed(opB));
                
            when ALU_SUB =>  -- Soustraction
                res <= std_logic_vector(signed(opA) - signed(opB));
                
            when ALU_SLL =>  -- Shift Left Logical
                res <= std_logic_vector(shift_left(unsigned(opA), shift_amount));
                
            when ALU_SLT =>  -- Set Less Than (signé)
                if signed(opA) < signed(opB) then
                    res <= x"00000001";
                else
                    res <= x"00000000";
                end if;
                
            when ALU_SLTU =>  -- Set Less Than Unsigned
                if unsigned(opA) < unsigned(opB) then
                    res <= x"00000001";
                else
                    res <= x"00000000";
                end if;
                
            when ALU_XOR =>  -- XOR
                res <= opA xor opB;
                
            when ALU_SRL =>  -- Shift Right Logical
                res <= std_logic_vector(shift_right(unsigned(opA), shift_amount));
                
            when ALU_SRA =>  -- Shift Right Arithmetic
                res <= std_logic_vector(shift_right(signed(opA), shift_amount));
                
            when ALU_OR =>  -- OR
                res <= opA or opB;
                
            when ALU_AND =>  -- AND
                res <= opA and opB;
                
            when others =>
                res <= (others => '0');
        end case;
    end process;
end Behavioral;