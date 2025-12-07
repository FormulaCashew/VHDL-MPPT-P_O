library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CountDown is
    generic(
        Ticks : integer:= 10
    );
    port (
        clk : in std_logic;
        rst : in std_logic;
        dec : in std_logic;
        rdy : out std_logic
    );
end CountDown;

architecture Behavioral of CountDown is
signal Cp : integer:=Ticks;
signal Cn :integer:=0;
signal rdy_s : std_logic:='0';

begin
    Combinational_PROC : process(Cp,CLK)
    begin
        if dec='1' and Cp /= 0 then
            Cn <= Cp - 1;
            rdy <= '0';
        elsif dec = '1' and Cp = 0 then
            rdy <= '1';
            --Cn <= Ticks;
			Cn <= 0;
        else
            rdy <= '0';
            Cn <= Cp;
        end if;
        --if Cp = 0 then
--            rdy <= '0';
--        elsif dec='1' then
--            Cn <= Cp-1;
--        else
--            Cn <= Cp;
--        end if;
    end process;

    SEQUENTIAL_PROC : process(CLK, RST)
    begin
        if rst = '0' then
            Cp <= Ticks;
        elsif clk'event and clk='1' then
            Cp <= Cn; 
        end if;
    end process;
end architecture;