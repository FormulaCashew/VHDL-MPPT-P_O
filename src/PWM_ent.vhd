library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity PWM_ent is
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
end PWM_ent;

architecture Structural of PWM_ent is
    component FreeRunCounter is
        generic(
            buswidth : integer:= 3
        );
        port (
            inc : in std_logic;
            clk : in std_logic;
            rst : in std_logic;
            cnt : out std_logic_vector(buswidth-1 downto 0)
        );
    end component;

    component TimCirc is
        GENERIC (
            ticks : INTEGER:=24
        );
        PORT (
            clk : IN STD_LOGIC;
            rst : IN STD_LOGIC;
            eot : OUT STD_LOGIC
        );
    end component;

constant TIMER_TICKS : integer := (CLK_FREQ)/(FREQ * (2**COUNTER_BITS));
signal SYN : std_logic:= '0';
signal CNT_S : std_logic_vector(COUNTER_BITS-1 downto 0):=(others => '0');
begin
    U01 : TimCirc
    generic map (
        ticks => TIMER_TICKS
    )
    port map (
        clk => CLK,
        rst => RST,
        eot => SYN
    );

    U02 : FreeRunCounter
    generic map (
        buswidth => COUNTER_BITS
    )
    port map (
        inc => SYN,
        clk => CLK,
        rst => RST,
        cnt => CNT_S
    );

    --CNT_S <= (others => '0');
    DEB(1) <= '0';
    DEB(0) <= SYN;

    COMB_PROC : process(DUT, CNT_S)
    begin
        if DUT > CNT_S then
            PWM <= '1';
        else
            PWM <= '0';
        end if;
    end process;
end architecture;