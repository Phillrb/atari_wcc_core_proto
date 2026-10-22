-- Approved 6/8 moving-hole wiring with actual Figures 5/9 feedback.
-- Compare raw ripple decode with the explicit FPGA LS74 sampling adapter.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;
entity tb_MovingHoleRaster is end;
architecture test of tb_MovingHoleRaster is
    signal hr,hs : std_logic := '0';
    signal sn : std_logic := '0';
    signal v : std_logic_vector(8 downto 0);
    signal vn,vrn,cd,hole : std_logic;
    signal sample_clk : std_logic := '0';
    signal sampled_cd : std_logic_vector(1 downto 0);
    signal sample_d : std_logic_vector(1 downto 0);
    signal filtered_hole : std_logic;
begin
    raster: entity work.VerticalSync port map(HRESET=>hr,VSYNC=>open,VSYNCn=>open,
        V1=>v(0),V2=>v(1),V4=>v(2),V8=>v(3),V16=>v(4),V32=>v(5),
        V64=>v(6),V64n=>open,V128=>v(7),V128n=>vn,V256=>v(8),V256n=>open,
        VRESET=>open,VRESETn=>vrn);
    field: entity work.PlayfieldCircuit port map(H1=>'0',H2=>'0',H4=>'0',H8=>'0',
        H16=>'0',H32=>'0',H64=>'0',H128=>'0',H256=>'0',H256n=>'1',HRESETn=>'1',
        V1=>v(0),V2=>v(1),V4=>v(2),V8=>v(3),V16=>v(4),V32=>v(5),
        V64=>v(6),V128=>v(7),V128n=>vn,V256=>v(8),VRESETn=>vrn,
        WINDOWS=>'0',CLOCK_7=>'0',PLAYFIELDn=>open,H_ENABLE=>open,V_ENABLE=>open,
        A_PLUS_Bn=>open,C_PLUS_Dn=>cd,H1n=>open);
    moving: entity work.MovingHoleCircuit port map(C_PLUS_Dn=>cd,HSYNCn=>hs,
        STARTn=>sn,V128=>v(7),HOLE=>hole);
    sample_d <= '0' & cd;
    sample_boundary: entity work.CollisionSampleBank
        generic map(WIDTH=>2)
        port map(SAMPLE_CLK=>sample_clk,D=>sample_d,Q=>sampled_cd);
    filtered: entity work.MovingHoleCircuit port map(C_PLUS_Dn=>sampled_cd(0),
        HSYNCn=>hs,STARTn=>sn,V128=>v(7),HOLE=>filtered_hole);
    stimulus: process
        file trace : text open write_mode is "moving_hole_raster.csv";
        variable row : line;
        variable frame, previous_v, line_v : integer := 0;
    begin
        write(row,string'("frame,line,raw,sampled"));writeline(trace,row);
        wait for 100 ns;sn<='1';
        for i in 1 to 313000 loop
            hr<='1';wait for 10 ns;
            hr<='0';wait for 10 ns;
            -- Sample after ripple settles and before HSYNCn, as the FPGA
            -- collision clock does after CLOCK_7 changes.
            sample_clk<='1';wait for 20 ns;
            hs<='1';wait for 10 ns;
            line_v:=to_integer(unsigned(v));
            if line_v<previous_v then frame:=frame+1; end if;
            previous_v:=line_v;
            write(row,frame);write(row,string'(","));
            write(row,line_v);write(row,string'(","));
            if hole='1' then write(row,1);else write(row,0);end if;
            write(row,string'(","));
            if filtered_hole='1' then write(row,1);else write(row,0);end if;
            writeline(trace,row);
            hs<='0';sample_clk<='0';wait for 50 ns;
        end loop;
        report "Actual vertical raster / boundary capture complete";
        wait;
    end process;
    observe: process
        variable was_hole : boolean;
        variable before_v,after_v : integer;
        variable glitches : natural := 0;
    begin
        wait until falling_edge(cd);
        was_hole:=hole='1';before_v:=to_integer(unsigned(v));
        wait for 1 ns;after_v:=to_integer(unsigned(v));
        if was_hole and cd='1' then
            report "False boundary during HOLE: transient V=" & integer'image(before_v) &
                " settled V=" & integer'image(after_v);
            glitches:=glitches+1;
        end if;
    end process;
end;
