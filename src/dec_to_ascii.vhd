library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity dec_to_ascii is
    port (
        DEC : in std_logic_vector(3 downto 0);
        ASCII : out std_logic_vector(7 downto 0)
    );
end dec_to_ascii;

architecture Dataflow of dec_to_ascii is
begin
    process(DEC)
    begin
        case DEC is
            when "0000" => ASCII <= "00110000"; -- '0' (ASCII 48)
            when "0001" => ASCII <= "00110001"; -- '1' (ASCII 49)
            when "0010" => ASCII <= "00110010"; -- '2' (ASCII 50)
            when "0011" => ASCII <= "00110011"; -- '3' (ASCII 51)
            when "0100" => ASCII <= "00110100"; -- '4' (ASCII 52)
            when "0101" => ASCII <= "00110101"; -- '5' (ASCII 53)
            when "0110" => ASCII <= "00110110"; -- '6' (ASCII 54)
            when "0111" => ASCII <= "00110111"; -- '7' (ASCII 55)
            when "1000" => ASCII <= "00111000"; -- '8' (ASCII 56)
            when "1001" => ASCII <= "00111001"; -- '9' (ASCII 57)
            when "1100" => ASCII <= "00001010"; -- New Line
            when "1101" => ASCII <= "00101011"; -- '+'
            when "1110" => ASCII <= "00101101"; -- '-' 
            when others => ASCII <= "00111111"; -- '?' (ASCII 63) para entradas inválidas
        end case;
    end process;
end architecture;