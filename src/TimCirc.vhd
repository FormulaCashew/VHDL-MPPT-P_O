LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY TimCirc IS
    GENERIC (
        ticks : INTEGER := 1529
    );
    PORT (
        clk : IN STD_LOGIC;
        rst : IN STD_LOGIC;
        eot : OUT STD_LOGIC
    );
END TimCirc;

ARCHITECTURE Behavioral OF TimCirc IS
    SIGNAL Cn, Cp : INTEGER := 0;
BEGIN

    COMBINATIONAL_PROC : PROCESS (Cp)
    BEGIN
        IF (ticks-1) /= Cp THEN
            Cn <= Cp + 1;
            eot <= '0';
        ELSE
            Cn <= 0;
            eot <= '1';
        END IF;
    END PROCESS;

    Sequential_PROC : PROCESS (CLK, RST)
    BEGIN
        IF rst = '0' THEN
            Cp <= 0;
        ELSIF clk'event AND clk = '1' THEN
            Cp <= Cn;
        END IF;
    END PROCESS;
END ARCHITECTURE;