-- Playfield Circuit for Goal IV (WCC) - TM-035 Figure 9
-- Connections per schematic (user-described).
-- ICs: M5(LS86), N5(LS00), N4(LS27), H4(LS02), H6(LS10), J4(LS20), K4(LS107), C6(LS04)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity PlayfieldCircuit is
    Port (
        H1       : in  STD_LOGIC;
        H2       : in  STD_LOGIC;
        H4       : in  STD_LOGIC;
        H8       : in  STD_LOGIC;
        H16      : in  STD_LOGIC;
        H32      : in  STD_LOGIC;
        H64      : in  STD_LOGIC;
        H128     : in  STD_LOGIC;
        H256     : in  STD_LOGIC;
        H256n    : in  STD_LOGIC;
        HRESETn  : in  STD_LOGIC;
        V1       : in  STD_LOGIC;
        V2       : in  STD_LOGIC;
        V4       : in  STD_LOGIC;
        V8       : in  STD_LOGIC;
        V16      : in  STD_LOGIC;
        V32      : in  STD_LOGIC;
        V64      : in  STD_LOGIC;
        V128     : in  STD_LOGIC;
        V128n    : in  STD_LOGIC;
        V256     : in  STD_LOGIC;
        VRESETn  : in  STD_LOGIC;
        WINDOWS  : in  STD_LOGIC := '1';
        CLOCK_7  : in  STD_LOGIC;
        PLAYFIELDn : out STD_LOGIC;
        H_ENABLE : out STD_LOGIC;
        V_ENABLE : out STD_LOGIC;
        A_PLUS_Bn : out STD_LOGIC;   -- (A+B)n: active low at left/right wall positions
        C_PLUS_Dn : out STD_LOGIC;    -- (C+D)n: active low at top/bottom wall positions
        H1n       : out STD_LOGIC
    );
end PlayfieldCircuit;

architecture Schematic of PlayfieldCircuit is
    -- M5 outputs
    signal M5_Y1, M5_Y3, M5_Y4 : STD_LOGIC;
    -- (A+B)n = H6 pin 8 (gate 3 output). M5 pin 3 is just connection to H6 pin 10.
    signal A_plus_B_n : STD_LOGIC;
    -- A+B = not (A+B)n for final combine
    signal A_plus_B : STD_LOGIC;
    -- N5 gate 1 output -> N4 pin 1
    signal n5_y1 : STD_LOGIC;
    -- N4 gate 1 output -> H6 pin 9
    signal n4_y1 : STD_LOGIC;
    -- H6 gate 3: pin 9=N4_Y1, pin 10=M5 pin 3 (M5_Y1), pin 11=M5_Y4; pin 8 (Y3) = (A+B)n
    signal H6_Y3 : STD_LOGIC;
    -- H4 (LS02) gate 3: V4 pin 8, V8 pin 9, pin 10 (Y3) -> J4 pin 10
    signal H4_Y3 : STD_LOGIC;
    -- (C+D)n = J4 gate 2 output
    signal C_plus_D_n : STD_LOGIC;
    -- C+D = not (C+D)n for final combine
    signal C_plus_D : STD_LOGIC;
    -- V128n from C6 (V128 -> C6 pin 9, pin 10 = V128n)
    signal V128n_int : STD_LOGIC;
    -- K4 (LS107) FF1: V = pin 3 (Q1), Vn = pin 2 (Q1n). FF2: Hn = pin 6 (Q2n)
    signal K4_H_Qn : STD_LOGIC;
    signal K4_V_Q, K4_V_Qn : STD_LOGIC;
    -- N5 pin 8 = H_ENABLE, N5 pin 11 = V_ENABLE, N5 pin 6 (Y2) -> J4 pin 2
    signal H_ENABLE_i, V_ENABLE_i : STD_LOGIC;
    signal n5_y2 : STD_LOGIC;
    -- WINDOWSn = not WINDOWS (for J4 pin 5)
    signal WINDOWSn : STD_LOGIC;
    -- J4 pin 6 = PLAYFIELDn (direct from J4 gate 1)
    signal playfield_n_i : STD_LOGIC;
begin
    -- ========== M5 (LS86) per schematic
    -- H8 -> M5 pin 13 (B4), H256 -> M5 pin 12 (A4), M5 pin 11 (Y4) -> H6 pin 11
    -- H16 -> M5 pin 2 (B1), H256n -> M5 pin 1 (A1), M5 pin 3 (Y1) = (A+B)n -> H6 pin 10
    -- V32 -> M5 pin 9 (A3), V128n -> M5 pin 10 (B3), M5 pin 8 (Y3) -> J4 pin 9
    IC_M5: entity work.LS86
        port map(
            P1_A1   => H256n,     -- 256n to M5 pin 1
            P2_B1   => H16,       -- H16 to M5 pin 2
            P3_Y1   => M5_Y1,     -- M5 pin 3 -> H6 pin 10 only
            P4_A2   => '0', P5_B2 => '0', P6_Y2 => open,
            P9_A3   => V32,       -- V32 to M5 pin 9
            P10_B3  => V128n_int, -- V128n to M5 pin 10 (from C6)
            P8_Y3   => M5_Y3,     -- M5 pin 8 -> J4 pin 9
            P12_A4  => H256,      -- H256 to M5 pin 12
            P13_B4  => H8,        -- H8 to M5 pin 13
            P11_Y4  => M5_Y4      -- M5 pin 11 -> H6 pin 11
        );

    -- ========== C6: V128 -> pin 9, pin 10 = V128n
    IC_C6_V128: entity work.LS04
        port map(
            P9_A4   => V128,
            P8_Y4   => V128n_int,
            P1_A1   => '0', P2_Y1 => open,
            P3_A2   => '0', P4_Y2 => open,
            P5_A3   => '0', P6_Y3 => open,
            P11_A5  => '0', P10_Y5 => open,
            P13_A6  => '0', P12_Y6 => open
        );

    -- ========== N5 (LS00) per schematic
    -- H4 -> N5 pin 1, H128 -> N5 pin 2, N5 pin 3 -> N4 pin 1
    -- (A+B)n -> N5 pin 10 and N5 pin 5; Hn -> N5 pin 9; N5 pin 8 = H_ENABLE
    -- (C+D)n -> N5 pin 13 and N5 pin 4; K4 pin 2 (Vn) -> N5 pin 12; N5 pin 11 = V_ENABLE; N5 pin 6 -> J4 pin 2
    IC_N5: entity work.LS00
        port map(
            P1_A1   => H4,        -- H4 to N5 pin 1
            P2_B1   => H128,      -- H128 to N5 pin 2
            P3_Y1   => n5_y1,     -- N5 pin 3 -> N4 pin 1
            P4_A2   => C_plus_D_n,-- (C+D)n to N5 pin 4
            P5_B2   => A_plus_B_n,-- (A+B)n to N5 pin 5
            P6_Y2   => n5_y2,     -- N5 pin 6 -> J4 pin 2
            P9_A3   => K4_H_Qn,   -- Hn to N5 pin 9
            P10_B3  => A_plus_B_n,-- (A+B)n to N5 pin 10
            P8_Y3   => H_ENABLE_i,  -- N5 pin 8 = H_ENABLE
            P12_A4  => K4_V_Qn,   -- K4 pin 2 to N5 pin 12
            P13_B4  => C_plus_D_n,-- (C+D)n to N5 pin 13
            P11_Y4  => V_ENABLE_i   -- N5 pin 11 = V_ENABLE
        );

    -- ========== N4 (LS27) per schematic
    -- N5 pin 3 -> N4 pin 1, H32 -> N4 pin 2, H64 -> N4 pin 13, N4 pin 12 -> H6 pin 9
    IC_N4: entity work.LS27
        port map(
            P1_A1   => n5_y1,
            P2_B1   => H32,
            P13_C1  => H64,
            P12_Y1  => n4_y1,     -- N4 pin 12 -> H6 pin 9
            P3_A2   => '0', P4_B2 => '0', P5_C2 => '0', P6_Y2 => open,
            P9_A3   => '0', P10_B3 => '0', P11_C3 => '0', P8_Y3 => open
        );

    -- ========== H6 (LS10) per schematic
    -- N4 pin 12 -> H6 pin 9, M5 pin 3 -> H6 pin 10, M5 pin 11 -> H6 pin 11; H6 pin 8 = (A+B)n
    IC_H6: entity work.LS10
        port map(
            P9_A3   => n4_y1,
            P10_B3  => M5_Y1,     -- M5 pin 3 to H6 pin 10 (not (A+B)n)
            P11_C3  => M5_Y4,
            P8_Y3   => H6_Y3,     -- H6 pin 8 = (A+B)n
            P1_A1   => '1', P2_B1 => '1', P13_C1 => '1', P12_Y1 => open,
            P3_A2   => '1', P4_B2 => '1', P5_C2 => '1', P6_Y2 => open
        );

    -- (A+B)n is H6 pin 8 output, not M5 pin 3
    A_plus_B_n <= H6_Y3;

    -- ========== H4 (LS02) per schematic: V4 -> H4 pin 8 (A3), V8 -> H4 pin 9 (B3), H4 pin 10 (Y3) -> J4 pin 10
    IC_H4: entity work.LS02
        port map(
            P8_A3   => V4,        -- V4 to H4 pin 8
            P9_B3   => V8,        -- V8 to H4 pin 9
            P10_Y3  => H4_Y3,     -- H4 pin 10 to J4 pin 10
            P1_Y1   => open, P2_A1 => '0', P3_B1 => '0',
            P4_Y2   => open, P5_A2 => '0', P6_B2 => '0',
            P11_A4  => '0', P12_B4 => '0', P13_Y4 => open
        );

    -- ========== J4 (LS20) gate 2: (C+D)n path. H4 pin 10 -> J4 pin 10, V16->pin12, V64->pin13, M5 pin 8->pin9, J4 pin 8=(C+D)n
    IC_J4_C_D: entity work.LS20
        port map(
            P13_A2  => V64,       -- V64 to J4 pin 13
            P12_B2  => V16,       -- V16 to J4 pin 12
            P10_C2  => H4_Y3,     -- H4 pin 10 to J4 pin 10
            P9_D2   => M5_Y3,     -- M5 pin 8 to J4 pin 9
            P8_Y2   => C_plus_D_n,-- J4 pin 8 = (C+D)n
            P1_A1   => '1', P2_B1 => '1', P4_C1 => '1', P5_D1 => '1', P6_Y1 => open
        );

    -- ========== K4 (LS107) single IC: FF1 = V, FF2 = H
    -- FF1 (V): V128n->pin1(J1), (C+D)n->pin12(CLK1), V128->pin4(K1), VRESETn->pin13(CLR1n); pin3=V, pin2->N5 pin12
    -- FF2 (H): H256n->pin8(J2), (A+B)n->pin9(CLK2), H256->pin11(K2), HRESETn->pin10(CLR2n); pin6=Hn
    IC_K4: entity work.LS107
        port map(
            P1_J1     => V128n,     -- V128n to K4 pin 1
            P2_Q1n    => K4_V_Qn,   -- K4 pin 2 to N5 pin 12
            P3_Q1     => K4_V_Q,    -- K4 pin 3 is V
            P4_K1     => V128,      -- V128 to K4 pin 4
            P5_Q2     => open,
            P6_Q2n    => K4_H_Qn,   -- K4 pin 6 is Hn
            P8_J2     => H256n,     -- H256n to K4 pin 8
            P9_CLK2   => A_plus_B_n,-- (A+B)n to K4 pin 9
            P10_CLR2n => HRESETn,   -- HRESETn to K4 pin 10
            P11_K2    => H256,      -- H256 to K4 pin 11
            P12_CLK1  => C_plus_D_n,-- (C+D)n to K4 pin 12
            P13_CLR1n => VRESETn    -- VRESETn to K4 pin 13
        );

    -- A+B and C+D for final combine (invert (A+B)n and (C+D)n)
    IC_C6_AB: entity work.LS04
        port map(
            P1_A1   => A_plus_B_n,
            P2_Y1   => A_plus_B,
            P3_A2   => '0', P4_Y2 => open, P5_A3 => '0', P6_Y3 => open,
            P9_A4   => '0', P8_Y4 => open, P11_A5  => '0', P10_Y5 => open,
            P13_A6  => '0', P12_Y6 => open
        );
    IC_C6_CD: entity work.LS04
        port map(
            P1_A1   => C_plus_D_n,
            P2_Y1   => C_plus_D,
            P3_A2   => '0', P4_Y2 => open, P5_A3 => '0', P6_Y3 => open,
            P9_A4   => '0', P8_Y4 => open, P11_A5  => '0', P10_Y5 => open,
            P13_A6  => '0', P12_Y6 => open
        );

    -- WINDOWSn for J4 pin 5
    IC_C6_WINDOWS: entity work.LS04
        port map(
            P1_A1   => WINDOWS,
            P2_Y1   => WINDOWSn,
            P3_A2   => '0', P4_Y2 => open, P5_A3 => '0', P6_Y3 => open,
            P9_A4   => '0', P8_Y4 => open, P11_A5  => '0', P10_Y5 => open,
            P13_A6  => '0', P12_Y6 => open
        );

    -- ========== J4 gate 1: H_ENABLE pin 1, N5 pin 6 pin 2, V_ENABLE pin 4, WINDOWSn pin 5, pin 6 = PLAYFIELDn
    IC_J4_6: entity work.LS20
        port map(
            P1_A1   => H_ENABLE_i,   -- HENABLE to J4 pin 1
            P2_B1   => n5_y2,      -- N5 pin 6 to J4 pin 2
            P4_C1   => V_ENABLE_i,   -- VENABLE to J4 pin 4
            P5_D1   => WINDOWSn,   -- WINDOWSn to J4 pin 5
            P6_Y1   => playfield_n_i,  -- J4 pin 6 = PLAYFIELDn
            P13_A2  => '1', P12_B2 => '1', P10_C2 => '1', P9_D2 => '1', P8_Y2 => open
        );

    PLAYFIELDn <= playfield_n_i;
    H_ENABLE   <= H_ENABLE_i;
    V_ENABLE   <= V_ENABLE_i;
    A_PLUS_Bn  <= A_plus_B_n;
    C_PLUS_Dn  <= C_plus_D_n;
    H1n        <= K4_H_Qn;
end Schematic;
