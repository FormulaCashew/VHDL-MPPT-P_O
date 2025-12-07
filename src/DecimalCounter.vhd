library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DecimalCounter is
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
end DecimalCounter;

architecture Structural of DecimalCounter is
    component CountUp_slv is
        generic(
            upto : integer:=9
        );
        port (
            CLK : in std_logic;
            RST : in std_logic;
            ENI : in std_logic;
            CNT : out std_logic_vector(3 downto 0);
            ENO : out std_logic
        );
    end component;

signal ENO_ONES, ENO_TENS, ENO_HUND, ENO_THOU, ENO_ToTHOU : std_logic;
begin
    UC1 : CountUp_slv
    generic map(upto => 9)
    port map(CLK, RST, ENI, ONES, ENO_ONES);

    UC2 : CountUp_slv
    generic map(upto => 9)
    port map(CLK, RST, ENO_ONES,TENS, ENO_TENS);

    UC3 : CountUp_slv
    generic map(upto => 9)
    port map(CLK, RST, ENO_TENS, HUND, ENO_HUND);

    UC4 : CountUp_slv
    generic map(upto => 9)
    port map(CLK, RST, ENO_HUND, THOU, ENO_THOU);

    UC5 : CountUp_slv
    generic map(upto => 9)
    port map(CLK, RST, ENO_THOU, ToTHO, ENO_ToTHOU);

    UC6 : CountUp_slv
    generic map(upto => 9)        
    port map(CLK, RST, ENO_ToTHOU, HoTHO, ENO);

end architecture;