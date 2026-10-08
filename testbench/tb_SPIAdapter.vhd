library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
entity tb_SPIAdapter is end;
architecture test of tb_SPIAdapter is
    signal clk : std_logic := '0';
    signal rst, frame : std_logic := '0';
    signal sck, cs, mosi, miso, valid, error : std_logic;
    signal sd,sf,cd,cf,r0,r1,r2,r3 : std_logic_vector(9 downto 0);
    signal packet : std_logic_vector(63 downto 0) := x"02BC03FF029E0320";
begin
    clk<=not clk after 70 ns;
    dut: entity work.SPIAdapter
        generic map(STARTUP_CLOCKS=>10000, CF_REVERSE=>true)
        port map(clk,rst,frame,miso,sck,cs,mosi,sd,sf,cd,cf,r0,r1,r2,r3,valid,error);
    tiny: entity work.ATtinySPITestModel port map(cs,sck,mosi,packet,miso);
    process
        procedure publish is
        begin frame<='1';wait for 1 us;frame<='0';wait for 1 us;end;
    begin
        wait for 1 us;rst<='1';
        wait until valid='1';wait for 1 us;
        assert unsigned(r0)=700 and unsigned(r1)=1023 and unsigned(r2)=670 and unsigned(r3)=800
            report "channel mapping / byte order failed" severity failure;
        assert unsigned(sd)=46 and unsigned(sf)=118 report "changed before VSYNC" severity failure;
        publish;
        assert unsigned(sd)=10 and unsigned(sf)=154 and unsigned(cd)=10 and unsigned(cf)=132
            report "clamping / reverse mapping failed" severity failure;
        packet<=x"03FF02BC03FF03FF";
        wait until valid='1';wait for 1 us;
        assert unsigned(sd)=10 and unsigned(sf)=154 report "partial packet published" severity failure;
        publish;
        assert unsigned(sd)=82 and unsigned(sf)=82 and unsigned(cd)=82 and unsigned(cf)=82
            report "endpoints failed" severity failure;
        packet<=x"FFFFFFFFFFFFFFFF"; -- disconnected MISO with pull-up
        wait until error='1';wait for 1 us;publish;
        assert unsigned(sd)=82 and unsigned(sf)=82 and unsigned(r0)=1023
            report "invalid packet did not preserve last good values" severity failure;
        packet<=x"02BC040002BC02BC"; -- reject all four if even one channel is >1023
        wait until error='1';wait for 1 us;publish;
        assert unsigned(sd)=82 and unsigned(sf)=82 report "partially invalid packet accepted" severity failure;
        -- Full 670..1023 range, monotonically increasing mapped motion.
        for value in 670 to 1023 loop
            packet<=std_logic_vector(to_unsigned(value,16)) & std_logic_vector(to_unsigned(value,16)) &
                    std_logic_vector(to_unsigned(value,16)) & std_logic_vector(to_unsigned(value,16));
            wait until valid='1';wait for 1 us;publish;
            if value<=700 then
                assert unsigned(sd)=10 and unsigned(sf)=82 severity failure;
            else
                assert to_integer(unsigned(sf))=82+((value-700)*72+161)/323
                    report "ADC sweep mapping failed" severity failure;
                assert unsigned(sd)=unsigned(sf)-72 and unsigned(cd)=unsigned(sd)
                    report "defense scaling failed" severity failure;
            end if;
            assert unsigned(sf)+unsigned(cf)=236 report "reverse mapping asymmetry" severity failure;
        end loop;
        -- Reset during an incomplete packet must release CS and recenter.
        wait until falling_edge(cs);wait for 150 us;rst<='0';wait for 1 us;
        assert cs='1' and sck='0' and unsigned(sd)=46 and unsigned(sf)=118
            report "reset during packet failed" severity failure;
        rst<='1';wait until valid='1';wait for 1 us;publish;
        assert unsigned(sd)=82 and unsigned(sf)=154 report "reset recovery failed" severity failure;
        report "SPI timing, full ADC sweep, channels, clamps, reversal, atomic frames, rejection and reset passed";
        wait;
    end process;
end;
