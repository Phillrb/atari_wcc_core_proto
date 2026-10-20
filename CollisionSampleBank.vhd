-- FPGA timing adapter (owner approved 18 October 2026), not a PCB circuit.
-- Explicit LS74 pairs capture settled, already-qualified collision signals.
-- WIDTH must be even; tie any unused channel low.
library ieee;
use ieee.std_logic_1164.all;
entity CollisionSampleBank is
    generic (WIDTH : positive := 8);
    port (SAMPLE_CLK : in std_logic;
          D : in std_logic_vector(WIDTH-1 downto 0);
          Q : out std_logic_vector(WIDTH-1 downto 0));
end;
architecture Structural of CollisionSampleBank is
begin
    assert WIDTH mod 2 = 0 report "Collision bank requires LS74 pairs" severity failure;
    pairs: for i in 0 to WIDTH/2-1 generate
        U_SAMPLE: entity work.LS74
            port map(P1_CLR1n=>'1', P2_D1=>D(2*i), P3_CLK1=>SAMPLE_CLK,
                P4_SET1n=>'1', P5_Q1=>Q(2*i), P6_Q1n=>open,
                P8_Q2n=>open, P9_Q2=>Q(2*i+1), P10_SET2n=>'1',
                P11_CLK2=>SAMPLE_CLK, P12_D2=>D(2*i+1), P13_CLR2n=>'1');
    end generate;
end;
