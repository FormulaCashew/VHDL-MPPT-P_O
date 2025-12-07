library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PWM_Comp_deadtime is
    generic(
        bits : integer:=10;
        deadtime : integer:=100;  --in ns
        freq : integer:= 50000 --in hz
    );
    port (
        CLK : in std_logic;
        RST : in std_logic;
        DUT : in std_logic_vector(bits-1 downto 0);
        PWM : out std_logic;
        PWM_comp : out std_logic;
		DEB : out std_logic -- not used
    );
end PWM_Comp_deadtime;

architecture Structural of PWM_Comp_deadtime is
    component Dead_time_gen is
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
    end component;

    component PWM_ent is
        generic(
            CLK_FREQ : integer := 50_000_000;
            --TIMER_TICKS : integer := 39;
            COUNTER_BITS : integer := 10;
            FREQ : integer := 50
        );
        port (
            CLK : in std_logic;
            RST : in std_logic;
            DUT : in std_logic_vector(COUNTER_BITS-1 downto 0);
            PWM : out std_logic;
            DEB : out std_logic_vector(1 downto 0)
        );
    end component;

constant deadtime_2_dff : integer := (deadtime/20);
signal N_PWM : std_logic:='0';
signal PWM_S : std_logic:='0';	
signal PWM_Norm : std_logic := '0';
begin
    U01 : PWM_ent
    generic map(
        CLK_FREQ => 50e6,
        COUNTER_BITS => bits,
        FREQ => FREQ
    )
    port map(
        CLK => CLK,
        RST => RST,
        DUT => DUT,
        PWM => PWM_Norm,
        DEB => OPEN
    );

    PWM <= PWM_S;
    N_PWM <= not PWM_Norm;

    U02 : Dead_time_gen
    generic map(
        num_dff => deadtime_2_dff
    )
    port map(
        XIN => N_PWM,
        CLK => CLK,
        RST => RST,
        Qp_deb => open,
        XOUT => PWM_Comp
    );	 
	
	U03 : Dead_time_gen
    generic map(
        num_dff => deadtime_2_dff
    )
    port map(
        XIN => PWM_Norm,
        CLK => CLK,
        RST => RST,
        Qp_deb => open,
        XOUT => PWM_S
    );

end architecture;