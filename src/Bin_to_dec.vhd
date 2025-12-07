library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- This entity separates a binary value into its digits, adapted to get a pulse and latch conversion until done
-- Data is stored and unchanged until new start

entity Bin_to_dec is
    generic(
        bus_width : integer:= 16
    );
    port (
        CLK : in std_logic;
        RST : in std_logic;
        STR : in std_logic;
        DIN : in std_logic_vector(bus_width-1 downto 0);
        ONE : out std_logic_vector(3 downto 0);
        TEN : out std_logic_vector(3 downto 0);
        HUN : out std_logic_vector(3 downto 0);
        THO : out std_logic_vector(3 downto 0);
        ToTHO : out std_logic_vector(3 downto 0);
        HoTHO : out std_logic_vector(3 downto 0);
        BUSY : out std_logic;
        EOC : out std_logic
    );
end Bin_to_dec;

architecture Structural of Bin_to_dec is

------------------------------------------------------------------------
    component LatchSR is
        port (
            RST : in std_logic;
            CLK : in std_logic;
            SET : in std_logic;
            CLR : in std_logic;
            SOUT : out std_logic
        );
    end component;

    component FreeRunCounter is
        generic(
            buswidth : integer
        );
        port (
            INC : in std_logic;
            CLK : in std_logic;
            RST : in std_logic;
            CNT : out std_logic_vector(buswidth-1 downto 0)
        );
    end component;

    component DecimalCounter is
        port (
            CLK : in std_logic;
            RST : in std_logic;
            ENO : out std_logic;
            ENI : in std_logic;
            ONES : out std_logic_vector(3 downto 0);
            TENS : out std_logic_vector(3 downto 0);
            HUND : out std_logic_vector(3 downto 0);
            THOU : out std_logic_vector(3 downto 0);
            ToTHO : out std_logic_vector(3 downto 0);
            HoTHO : out std_logic_vector(3 downto 0)
        );
    end component;

    component RisingEdge_gen
	generic(
		num_dff : INTEGER := 4
	);
	port(
		XIN : in STD_LOGIC;
		CLK : in STD_LOGIC;
		RST : in STD_LOGIC;
		XRE : out STD_LOGIC
	);
	end component;
-------------------------------------------------------------------------
signal GTE : std_logic:='0';
signal N_GTE : std_logic:='1';
signal N_STR : std_logic := '1';
signal INC : std_logic:='0';
signal RSS : std_logic:='1';
signal ENA : std_logic:='0';
signal COUNT_COMP : std_logic_vector(bus_width-1 downto 0):=(others => '0'); -- for free run counter to comp
signal XRE, N_XRE : std_logic:='0';
signal STR_1 : std_logic:='0';
---------------------------------------------------------------------------------
begin
    N_GTE <= not GTE;
    N_STR <= not STR;
    N_XRE <= not XRE;

    RED_PROC : process(clk)
    begin
        if RST='0' then
            XRE <= '0';
            ENA <= '0';
        elsif CLK'event and CLK='1' then
            STR_1 <= STR;
            if STR='1' and STR_1='0' and ENA='0' then -- Detect Rising edge and prevent interrupt
                XRE <= '1';
                ENA <= '1';
            else
                XRE <= '0';
            end if;
            if N_GTE='1' then 
                ENA <= '0';
            end if;
        end if;
    end process;

    BUSY <= ENA;
    EOC <= N_GTE;

    U02 : FreeRunCounter
    generic map(
        buswidth => bus_width
    )
    Port map(
        INC => '1',
        CLK => CLK,
        RST => ENA,
        CNT => COUNT_COMP
    );

    COMP_PROC : process(GTE, COUNT_COMP,DIN,ENA)
    begin
        if DIN >= COUNT_COMP then
            GTE <= '1';
        else
            GTE <= '0';
        end if;

        if ENA='1' and GTE = '1' then
            INC <= '1';
        else
			INC <= '0';
        end if;
    end process;

    U03 : DecimalCounter
    port map(
        CLK => CLK,
        RST => N_XRE,
        ENO => open,
        ENI => INC,
        ONES => ONE,
        TENS => TEN,
        HUND => HUN,
        THOU => THO,
        ToTHO => ToTHO,
        HoTHO => HoTHO
    );

    RST_PROC : process(RST,STR,CLK)
    begin
        if STR='1' and RST='1' then
            RSS <= '1';
        else
            RSS <= '0';
        end if;
    end process;

end architecture;