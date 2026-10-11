-- N8 digital analogue boundary: a settling ramp must not create an E1 pulse.
-- RTL normally changes all ramp bits together; exercise a brief intermediate
-- value explicitly to cover a behaviour omitted by ideal functional tests.
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_SolidDefensePulse is end;
architecture test of tb_SolidDefensePulse is
    signal h : std_logic := '0';
    signal vn : std_logic := '0';
    signal ramp : std_logic_vector(9 downto 0) := (others=>'0');
    signal symbol : std_logic;
begin
    dut: entity work.PlayersSolidDefenseGoalie
        generic map(PLAY_INITIAL_GAP=>57)
        port map(HSYNC=>h, VSYNCn=>vn, RAMP_VALUE=>ramp,
                 POSITION=>std_logic_vector(to_unsigned(10,10)),
                 ATRCn=>'1', GOALIE=>'0', E1=>symbol,
                 B1=>open, C1=>open, D1=>open);
    process
    begin
        -- Reach the initial N8 high interval with H8 reset and M7 loaded.
        for row in 0 to 20 loop
            if row=8 then vn<='1'; end if;
            ramp<=std_logic_vector(to_unsigned(row,10));
            h<='0'; wait for 1 us;
            h<='1'; wait for 1 us;
        end loop;
        assert symbol='0' report "unexpected symbol during initial delay" severity failure;
        -- Emulate a transient low comparator input while ramp bits settle.
        ramp<=(others=>'0'); wait for 10 ns;
        assert symbol='0'
            report "ramp settling transient leaked through N8 into E1" severity failure;
        ramp<=std_logic_vector(to_unsigned(20,10)); wait for 10 ns;
        assert symbol='0' report "symbol changed without HSYNC" severity failure;
        report "Solid defence N8 rejects between-edge ramp transients";
        wait;
    end process;
end;
