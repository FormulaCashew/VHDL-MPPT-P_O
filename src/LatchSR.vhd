Library IEEE;
Use IEEE.Std_logic_1164.all;
Use IEEE.Numeric_Std.all;

Entity LatchSR is
	PORT(
	RST : in Std_Logic;
	CLK	: in Std_Logic;
	SET : in Std_Logic;
	CLR : in Std_Logic;
	SOUT : out Std_Logic
	);
End LatchSR;

Architecture Behavioral of LatchSR is
Signal Qp, Qn : Std_Logic := '0'; 
begin
	Combinational : Process(SET,CLR,Qp)
	begin							
		if(SET = '1')then
			Qn <= '1';
		elsif(CLR = '1') then
			Qn <= '0';
		else
			Qn <= Qp;
		end if;
		  	SOUT <= Qp;
	End Process Combinational;
	
	Sequential : Process(CLK,RST)
	begin						
		if RST = '0' then  
			Qp <= '0';
		elsif CLK'event and CLK = '1' then
			Qp <= Qn;
		end if;
	End Process Sequential;
	
End Behavioral;