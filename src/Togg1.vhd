library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity togg is
    port (
        TOG : in std_logic;
        CLK : in std_logic;
        RST : in std_logic;
        TGS : out std_logic
    );
end togg;

architecture Behavioral of togg is
signal Qp, Qn : std_logic;
begin
    COMB_PROC : process(Qp, TOG)
    begin
        Qn <= Qp xor TOG;
        TGS <=  Qp;
    end process;
    DFF_PROC : process(CLK, RST)
    begin
        if RST = '0' then
            Qp <= '0';
        elsif CLK'event and CLK = '1' then
            Qp <= Qn;
        end if;    
    end process;
end architecture;