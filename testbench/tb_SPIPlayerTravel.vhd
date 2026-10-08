-- Figure 11 circuits driven by the SPI adapter's calibrated threshold range.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tb_SPIPlayerTravel is end;
architecture test of tb_SPIPlayerTravel is
    signal h,vn,play : std_logic := '0';
    signal ramp,pdef,pfwd : std_logic_vector(9 downto 0) := (others=>'0');
    signal e : std_logic_vector(5 downto 0);
    signal original_sd,original_cd : std_logic;
begin
    sf: entity work.PlayersSolidForwards port map(h,ramp,pfwd,play,e(0),open,open,open);
    cf: entity work.PlayersStripedForwards port map(h,ramp,pfwd,play,e(1),open,open,open);
    sd: entity work.PlayersSolidDefenseGoalie generic map(PLAY_INITIAL_GAP=>57)
        port map(h,vn,ramp,pdef,play,'0',e(2),open,open,open);
    sg: entity work.PlayersSolidDefenseGoalie generic map(PLAY_INITIAL_GAP=>57)
        port map(h,vn,ramp,pdef,play,'1',e(3),open,open,open);
    cd: entity work.PlayersStripedDefenseGoalie generic map(PLAY_INITIAL_GAP=>55)
        port map(h,vn,ramp,pdef,play,'0','0',e(4),open,open,open);
    cg: entity work.PlayersStripedDefenseGoalie generic map(PLAY_INITIAL_GAP=>55)
        port map(h,vn,ramp,pdef,play,'1','0',e(5),open,open,open);
    old_sd: entity work.PlayersSolidDefenseGoalie
        port map(h,vn,ramp,pdef,play,'0',original_sd,open,open,open);
    old_cd: entity work.PlayersStripedDefenseGoalie
        port map(h,vn,ramp,pdef,play,'0','0',original_cd,open,open,open);
    process
        type counts is array(0 to 5) of natural;
        variable lit : counts;
        variable expected : std_logic_vector(5 downto 0);
        variable row : integer;
    begin
        for mode in 0 to 1 loop
            if mode=0 then play<='0';else play<='1';end if;
            for offset in 0 to 72 loop
                pdef<=std_logic_vector(to_unsigned(10+offset,10));
                pfwd<=std_logic_vector(to_unsigned(82+offset,10));
                for frame in 0 to 2 loop
                    lit:=(others=>0);
                    for v in 0 to 312 loop
                        if v<8 then vn<='0';else vn<='1';end if;
                        if v<256 then ramp<=std_logic_vector(to_unsigned(v,10));
                        else ramp<=(others=>'0');end if;
                        h<='0';wait for 1 us;h<='1';wait for 1 us;
                        if frame=2 then
                            if mode=0 then
                                assert e(2)=original_sd and e(4)=original_cd
                                    report "attract layout changed" severity failure;
                            elsif v>=84 and v<=239 then
                                expected:=(others=>'0');row:=v-offset;
                                if (row>=84 and row<=98) or (row>=151 and row<=165) then
                                    expected(0):='1';expected(1):='1';end if;
                                if (row>=84 and row<=98) or (row>=152 and row<=166) then
                                    expected(2):='1';expected(4):='1';end if;
                                if row>=118 and row<=132 then expected(3):='1';expected(5):='1';end if;
                                assert e=expected report "player travel geometry mismatch at offset " & integer'image(offset) &
                                    " line " & integer'image(v) severity failure;
                                for i in 0 to 5 loop if e(i)='1' then lit(i):=lit(i)+1;end if;end loop;
                            end if;
                        end if;
                    end loop;
                end loop;
                if mode=1 then
                    assert lit=(30,30,30,15,30,15) report "player clipped or extra symbol" severity failure;
                end if;
            end loop;
        end loop;
        report "All 73 travel positions preserve forward/defense/goalie sizes and attract layout";
        wait;
    end process;
end;
