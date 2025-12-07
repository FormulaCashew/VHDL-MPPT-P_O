library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity FreeRunCounter is
    generic(
        buswidth : integer:= 3
    );
    port (
        inc : in std_logic;
        clk : in std_logic;
        rst : in std_logic;
        cnt : out std_logic_vector(buswidth-1 downto 0)
    );
end FreeRunCounter;

architecture Behavioral of FreeRunCounter is
signal Cn : integer:=0;
signal Cp : integer:=0;
begin

    COMBINATIONAL_PROC : process(inc, clk)
    begin
        if inc = '1' then
            Cn <= Cp+1;
        else
            Cn <= Cn;
        end if;
        cnt <= std_logic_vector(to_unsigned(Cn,buswidth));
    end process;

    Sequential_PROC : process(CLK,RST)
    begin
        if rst='0' then
            Cp <= 0;
        elsif clk'event and clk='1' then
            Cp <= Cn;
        end if;
    end process;
end architecture;