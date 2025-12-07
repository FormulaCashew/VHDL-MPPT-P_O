library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CountUp_slv is
    generic(
        upto : integer:=9
    );
    port (
        CLK : in std_logic;
        RST : in std_logic;
        ENI : in std_logic;
        CNT : out std_logic_vector(3 downto 0);
        ENO : out std_logic
    );
end CountUp_slv;

architecture Behavioral of CountUp_slv is
signal Cp : integer:=0;
signal Cn : integer:=0;
begin

    Sequential_PROC : process(CLK,RST)
    begin
        if RST = '0' then
            Cp <= 0;
        elsif CLK'event and CLK='1' then
            Cp <= Cn;
        end if;
    end process;

    Combinational_PROC : process(CP,ENI)
    begin
        if ENI='1' then
            if Cp=9 then
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
        CNT <= std_logic_vector(to_unsigned(Cp,4));
    end process;
end architecture;