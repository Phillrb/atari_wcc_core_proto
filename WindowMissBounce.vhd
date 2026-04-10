-- Window/Miss/Bounce Circuit - Goal IV (WCC) TM-035 Figure 19
-- ICs: F5(LS08), F4(LS02), H5(LS02), E3(LS04)
-- Window: F5 gates 1,2 + F4 gate 4 + H5 gates 1-4 + E3 gate 1 -> WINDOWS
-- Bounce: F4 gates 1,2,3 -> V_BOUNCE, H_BOUNCE, BOUNCEn
-- Miss: F5 gate 3 -> MISS (ball through goal)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity WindowMissBounce is
    Port (
        -- Window circuit inputs
        V64        : in  STD_LOGIC;   -- 64V from vertical counter
        H256n      : in  STD_LOGIC;   -- 256Hn from horizontal counter
        ONE_PLAYER : in  STD_LOGIC;   -- 1-player mode
        ATRC       : in  STD_LOGIC;   -- Attract mode (high=attract, low=play)
        HOLE       : in  STD_LOGIC;   -- Moving hole signal (active low = hole present)
        -- Bounce/miss circuit inputs
        BALLn      : in  STD_LOGIC;   -- Inverted ball signal (low = ball present)
        A_PLUS_Bn  : in  STD_LOGIC;   -- (A+B)n from playfield (low at L/R wall positions)
        C_PLUS_Dn  : in  STD_LOGIC;   -- (C+D)n from playfield (low at T/B wall positions)
        -- Outputs
        WINDOWS    : out STD_LOGIC;   -- Goal window (high = opening)
        WINDOWSn   : out STD_LOGIC;   -- Inverted WINDOWS (for external use)
        V_BOUNCE   : out STD_LOGIC;   -- Ball hit top/bottom wall
        H_BOUNCE   : out STD_LOGIC;   -- Ball hit left/right wall
        BOUNCEn    : out STD_LOGIC;   -- Active low: any bounce occurred
        MISS       : out STD_LOGIC    -- Ball went through goal
    );
end WindowMissBounce;

architecture Schematic of WindowMissBounce is
    -- Window circuit internals
    signal F5_Y1     : STD_LOGIC;   -- F5 gate 1: AND(H256n, V64) = left half window
    signal F4_Y4     : STD_LOGIC;   -- F4 gate 4: NOR(H256n, HOLE) = right half hole (1P only)
    signal H5_Y3     : STD_LOGIC;   -- H5 gate 3: NOR(F5_Y1, F4_Y4)
    signal H5_Y1     : STD_LOGIC;   -- H5 gate 1: NOR(V64, ONE_PLAYER) = 2P V64 inverter
    signal F5_Y2     : STD_LOGIC;   -- F5 gate 2: AND(ONE_PLAYER, H5_Y3) = 1P path
    signal H5_Y2     : STD_LOGIC;   -- H5 gate 2: NOR(F5_Y2, H5_Y1)
    signal windows_i : STD_LOGIC;   -- H5 gate 4 output = WINDOWS
    -- Bounce circuit internals
    signal v_bounce_i : STD_LOGIC;  -- F4 gate 1: NOR(C_PLUS_Dn, BALLn) = V BOUNCE
    signal h_bounce_i : STD_LOGIC;  -- F4 gate 3: NOR(A_PLUS_Bn, BALLn) = H BOUNCE
begin
    -- Output assignments (internal signals needed for readback)
    WINDOWS  <= windows_i;
    V_BOUNCE <= v_bounce_i;
    H_BOUNCE <= h_bounce_i;

    -- ========== F5 (LS08) - AND gates for window and miss ==========
    -- Gate 1: AND(H256n, V64) -> left half window (active when 256H=0 and 64V=1)
    -- Gate 2: AND(ONE_PLAYER, H5_Y3) -> 1-player path
    -- Gate 3: AND(H_BOUNCE, WINDOWS) -> MISS (ball through goal)
    IC_F5: entity work.LS08
        port map(
            P1_A1   => H256n,        -- pin 1 = 256Hn
            P2_B1   => V64,           -- pin 2 = 64V
            P3_Y1   => F5_Y1,        -- pin 3 = left half window
            P4_A2   => ONE_PLAYER,    -- pin 4 = 1 PLAYER
            P5_B2   => H5_Y3,        -- pin 5 = H5 gate 3 output
            P6_Y2   => F5_Y2,        -- pin 6 -> H5 gate 2 pin 5
            P9_A3   => h_bounce_i,   -- pin 9 = H BOUNCE (F4-10)
            P10_B3  => windows_i,    -- pin 10 = WINDOWS (H5-13)
            P8_Y3   => MISS,         -- pin 8 = MISS
            P12_A4  => '0', P13_B4 => '0', P11_Y4 => open  -- gate 4 unused
        );

    -- ========== F4 (LS02) - NOR gates for window and bounce ==========
    -- Gate 1: NOR(C_PLUS_Dn, BALLn) -> V BOUNCE (ball at top/bottom wall)
    -- Gate 2: NOR(V_BOUNCE, H_BOUNCE) -> BOUNCEn (any bounce)
    -- Gate 3: NOR(A_PLUS_Bn, BALLn) -> H BOUNCE (ball at left/right wall)
    -- Gate 4: NOR(H256n, HOLE) -> right half hole (1-player moving hole)
    IC_F4: entity work.LS02
        port map(
            P2_A1   => C_PLUS_Dn,    -- pin 2 = (C+D)n
            P3_B1   => BALLn,         -- pin 3 = BALLn
            P1_Y1   => v_bounce_i,    -- pin 1 = V BOUNCE
            P5_A2   => h_bounce_i,    -- pin 5 = H BOUNCE (F4-10)
            P6_B2   => v_bounce_i,    -- pin 6 = V BOUNCE (F4-1)
            P4_Y2   => BOUNCEn,       -- pin 4 = BOUNCEn
            P8_A3   => A_PLUS_Bn,     -- pin 8 = (A+B)n
            P9_B3   => BALLn,         -- pin 9 = BALLn
            P10_Y3  => h_bounce_i,    -- pin 10 = H BOUNCE
            P11_A4  => H256n,         -- pin 11 = 256Hn
            P12_B4  => HOLE,          -- pin 12 = HOLE
            P13_Y4  => F4_Y4          -- pin 13 = right half hole
        );

    -- ========== H5 (LS02) - NOR gates for window processing ==========
    -- Gate 1: NOR(V64, ONE_PLAYER) -> 2P: NOT(V64); 1P: disabled (0)
    -- Gate 2: NOR(F5_Y2, H5_Y1) -> combine 1P/2P paths
    -- Gate 3: NOR(F5_Y1, F4_Y4) -> combine left window and right hole
    -- Gate 4: NOR(H5_Y2, ATRC) -> WINDOWS (gated by attract mode)
    IC_H5: entity work.LS02
        port map(
            P2_A1   => V64,           -- pin 2 = 64V
            P3_B1   => ONE_PLAYER,    -- pin 3 = 1 PLAYER
            P1_Y1   => H5_Y1,         -- pin 1 = 2P path
            P5_A2   => F5_Y2,         -- pin 5 = 1P path (F5-6)
            P6_B2   => H5_Y1,         -- pin 6 = 2P path (H5-1)
            P4_Y2   => H5_Y2,         -- pin 4 -> H5 gate 4 pin 11
            P8_A3   => F5_Y1,         -- pin 8 = left half window (F5-3)
            P9_B3   => F4_Y4,         -- pin 9 = right half hole (F4-13)
            P10_Y3  => H5_Y3,         -- pin 10 -> F5 gate 2 pin 5
            P11_A4  => H5_Y2,         -- pin 11 = H5 gate 2 output
            P12_B4  => ATRC,          -- pin 12 = ATRC
            P13_Y4  => windows_i      -- pin 13 = WINDOWS
        );

    -- ========== E3 (LS04) - Inverter for WINDOWSn ==========
    -- Gate 1: NOT(WINDOWS) -> WINDOWSn
    IC_E3: entity work.LS04
        port map(
            P1_A1   => windows_i,
            P2_Y1   => WINDOWSn,
            P3_A2   => '0', P4_Y2 => open, P5_A3 => '0', P6_Y3 => open,
            P9_A4   => '0', P8_Y4 => open, P11_A5 => '0', P10_Y5 => open,
            P13_A6  => '0', P12_Y6 => open
        );
end Schematic;
