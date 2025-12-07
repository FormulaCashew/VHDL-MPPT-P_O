library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CountUp is
    generic(
        upto : integer:=9
    );
    port (
        CLK : in std_logic;
        RST : in std_logic;
        ENI : in std_logic;
        CNT : out integer range 0 to upto;
        ENO : out std_logic
    );
end CountUp;

architecture Behavioral of CountUp is
signal Cp : integer range 0 to upto:=0;
signal Cn : integer range 0 to upto:=0;
begin

    Sequential_PROC : process(CLK,RST)
    begin
        if RST = '0' then
            Cp <= 0;
            CNT <= 0;
        elsif CLK'event and CLK='1' then
            Cp <= Cn; 
			CNT <= Cn;
        end if;
    end process;

    Combinational_PROC : process(CP,ENI)
    begin
        if ENI='1' then
            if Cp = upto then
                Cn <= 0;
                ENO <= '1';
            else
                Cn <= Cp + 1;
                ENO <= '0';
            end if;
        else
            Cn <= Cp;
            ENO <= '0';
        end if;
    end process;
end architecture;