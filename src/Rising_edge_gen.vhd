library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity RisingEdge_gen is
    generic(
        num_dff : integer := 4
    );
    port (
        XIN : in std_logic;
        CLK : in std_logic;
        RST : in std_logic;
        XRE : out std_logic
    );
end RisingEdge_gen;

architecture Behavioral of RisingEdge_gen is
signal Qp : std_logic_vector(num_dff-1 downto 0):=(others => '0');
signal ones : std_logic_vector(num_dff-2 downto 0):=(others => '1');
signal Comp : std_logic_vector(num_dff-2 downto 0):=(others => '0');
begin

    --Combinational_PROC : process(Qp,CLK)
--    variable flag : std_logic:='0';
--    begin
--        for i in num_dff-2 downto 0 loop
--            if flag='0' and Qp(i)='1' then
--                flag:='0';
--            else
--                flag:='1';
--            end if;
--        end loop;
--        if flag='0' and Qp(Qp'left)='0' then
--            XRE <= not Qp(0) and XIN;
--        else
--            XRE <= '0';
--        end if;
--    end process;

    COMPARE_PROC : process(Qp,CLK)
    begin
        Comp <= Qp(num_dff-2 downto 0);
        if Comp = ones and Qp(num_dff-1)='0' and XIN = '1' then
            XRE <= '1';
        else
            XRE <= '0';
        end if;
    end process;

    DFF_PROC : process(CLK, RST)
    begin
        if RST = '0' then
            Qp <= (others => '0');
        elsif CLK'event and CLK='1' then
            for i in num_dff-1 downto 1 loop
                Qp(i) <= Qp(i-1);
            end loop;
            Qp(0) <= XIN;
        end if;
    end process;

end architecture;