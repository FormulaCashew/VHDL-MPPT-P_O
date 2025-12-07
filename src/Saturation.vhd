library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Saturation is
    port (
        DIN : in std_logic_vector(47 downto 0);
        DOUT : out std_logic_vector(10 downto 0)
    );
end Saturation;

architecture Behavioral of Saturation is
constant DMAX : std_logic_vector(47 downto 0) := X"00000FFF0000";--F32.16
constant DMIN : std_logic_vector(47 downto 0) := X"FFFFF0010000";   --prevent an overflow for the pwm
begin
    COMB_PROC : process(DIN)
    begin
        if signed(DIN) > signed(DMAX) then
            DOUT <= DMAX(26 downto 16);
        elsif signed(DIN) < signed(DMIN) then
            DOUT <= DMIN(26 downto 16); 
        else
            DOUT <= DIN(26 downto 16);
        end if;
    end process;
end architecture;