# Playfield: Manual-Faithful Implementation and Correct Look

## How the manual defines a line: the "window" concept

From Goal_IV_TM-035 § **Windows** (and Figure 7):

> The term **window** is one that has been coined to explain the process of **gating the TV lines** so that they can only appear within certain limits. The most confusing thing about the window concept is that **it takes information from the vertical sync circuit to produce a horizontal window and vice versa**.

- **Horizontal window** (on the TV) = a **horizontal band** (a line or strip that runs left–right across the screen). It is produced by **gating with V (vertical) signals**. Example: if **64V and 128V** (128V active low) from the vertical sync circuit are ANDed, a signal develops that can be used to blank the beam for all TV lines *except* those between vertical positions 64V and 128V → a **bright band between 64V and 128V** appears on the screen.
- **Vertical window** (on the TV) = a **vertical band** (a line or strip that runs top–bottom). It is produced by **gating with H (horizontal) signals**.

So: **V signals** define where a **horizontal** (left–right) band appears vertically; **H signals** define where a **vertical** (up–down) band appears horizontally. For the playfield:

- **Top/bottom horizontal lines**: use a **horizontal window** = V gating (e.g. only between certain V positions for the top band and the bottom band). The C+D pattern gives the “4V width” of the line; the **V ENABLE** (from the manual) is the window that limits those lines to the correct V range (top and bottom bands).
- **Left/right vertical lines**: use a **vertical window** = H gating (only between certain H positions for the left and right edges). The A+B pattern gives the “4H width”; **H ENABLE** is the window that limits those lines to the correct H range (left and right edges).

When implementing, lines should be formed by: **(pattern) AND (window)** — pattern from the sync counter combos (A+B, C+D), window from the appropriate V or H gating so the line only appears within the desired limits.

## Manual notation: active-low signals

In Goal_IV_TM-035.md, **`<span class="over">Signal</span>`** means the signal is **inverted / active low** (equivalent to a bar over the name). When interpreting the Playfield section with that in mind:
