library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Serializer is
    generic(
        buswidth : integer := 8
    );
    port (
        CLK : in std_logic;
        RST : in std_logic;
        DIN : in std_logic_vector(buswidth-1 downto 0);
        LDR : in std_logic;
        SHF : in std_logic;
        BOUT : out std_logic
    );
end Serializer;

architecture Behavioral of Serializer is
signal Qp, Qn : std_logic_vector(buswidth-1 downto 0):=(others => '1');	
begin

    MUX_PROC : process(LDR,SHF)						   
    begin
        if LDR='1' and SHF='0' then
            Qn <= DIN; 
        elsif LDR = '0' and SHF = '1' then
            Qn <= '1' & Qp(buswidth-1 downto 1); -- Shift left, inserting '1' at the LSB
        else
            Qn <= Qp;
        end if;
    end process;

    DFF_PROC : process(CLK, RST)
    begin
        if RST='0' then
            Qp <= (others => '1');
			BOUT <= '1';
        elsif CLK'event and CLK='1' then
            Qp <= Qn;
            BOUT <= Qn(0);
        end if;
    end process;

end architecture;