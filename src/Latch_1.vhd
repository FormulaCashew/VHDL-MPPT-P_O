library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Latch_1 is
    port (
        RST : in std_logic;
        CLK : in std_logic;
        SET : in std_logic;
        CLR : in std_logic;
        SOUT : out std_logic
    );
end Latch_1;

architecture Behavioral of Latch_1 is
signal Qp, Qn : std_logic:='0';
begin

    COMBINATIONAL_PROC : process(SET, CLR, Qp)
    begin
        if SET = '1' then
            Qn <= '1';
        elsif CLR = '1' then
            Qn <= '0';
        else
            Qn <= Qp;
        end if;		   
        SOUT <= Qn;
    end process;

    SEQUENTIAL_PROC : process(RST, CLK)
    begin
        if RST = '0' then
            Qp <= '0';
        elsif CLK'event and CLK = '1' then
            Qp <= Qn; 
        end if;
    end process;

end architecture;