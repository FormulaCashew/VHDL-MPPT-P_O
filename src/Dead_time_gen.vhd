library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Dead_time_gen is
    generic(
        num_dff : integer := 4  --each delay is num*clk_period, 4=80ns delay
    );
    port (
        XIN : in std_logic;
        CLK : in std_logic;
        RST : in std_logic;
        Qp_deb : out std_logic_vector(num_dff-1 downto 0);
        XOUT : out std_logic
    );
end Dead_time_gen;

architecture Behavioral of Dead_time_gen is
signal Qp : std_logic_vector(num_dff-1 downto 0):=(others => '0');
signal ones : std_logic_vector(num_dff-1 downto 0):=(others => '1');
signal Comp : std_logic_vector(num_dff-1 downto 0):=(others => '0');
begin

    COMPARE_PROC : process(Qp,CLK)
    begin
        Comp <= Qp(num_dff-1 downto 0);
        if (Comp = ones and XIN = '1') then
            XOUT <= '1';
        else
            XOUT <= '0';
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
	
	Qp_deb <= Qp;

end architecture;