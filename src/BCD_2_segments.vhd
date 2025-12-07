library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BCD_2_segments is
    port (
        BCD : in std_logic_vector(3 downto 0);
        SEG : out std_logic_vector(6 downto 0)
    );
end BCD_2_segments;

architecture dataflow of BCD_2_segments is
begin
    process(BCD)
    begin
        case BCD is
            when "0000" => SEG <= "1000000"; -- 0
            when "0001" => SEG <= "1111001"; -- 1
            when "0010" => SEG <= "0100100"; -- 2
            when "0011" => SEG <= "0110000"; -- 3
            when "0100" => SEG <= "0011001"; -- 4
            when "0101" => SEG <= "0010010"; -- 5
            when "0110" => SEG <= "0000010"; -- 6
            when "0111" => SEG <= "1111000"; -- 7
            when "1000" => SEG <= "0000000"; -- 8
            when "1001" => SEG <= "0010000"; -- 9
            when others => SEG <= "1111111"; -- nada
        end case;
    end process;
end architecture;