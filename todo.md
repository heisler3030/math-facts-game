# Math Facts Game — TODO

## Factor Hunt Games (Games 2 & 3)

- [ ] **Restore Factor Hunt games to the home screen menu** (currently commented out in `index.html`)
  - Games 2 & 3 are fully implemented in the JS (search for `createFactorHuntGame`) but hidden from the menu
  - To re-enable: uncomment the two `game-card` blocks in the `#home-screen` div
  - **Issues to fix before restoring:**
    - Review and playtest the new Enter behavior (correct cells close, wrong cells stay red until deselected)
    - Verify the 7×7 grid (factors 2–8) fits well on iPhone 13 mini in portrait mode
    - Consider whether the "partial submit" UX (some correct cells close while wrong ones stay) is intuitive enough
    - Factor Hunt (Auto) — verify auto-factor selection flow works smoothly end-to-end
    - Consider adding a visual indicator showing which factors have been completed

## Equivalence Challenge (Game 6)

- [ ] **Restore Equivalence Challenge to the home screen menu** (currently commented out in `index.html`)
  - Game 6 is fully implemented in the JS (search for `Game6`) but hidden from the menu
  - To re-enable: uncomment the `game-card` block for Game 6 in the `#home-screen` div
  - **Issues to fix before restoring:**
    - Playtest the round generation — verify correct/wrong choices are well-balanced
    - Confirm all equivalence representations are accurate (fractions, decimals, percentages)
    - Review UX: the "Check Answer" button flow and feedback timing
    - Consider adding more target values or difficulty levels
    - Verify layout fits on iPhone 13 mini in both portrait and landscape

## Fullscreen / PWA

- [ ] **Create a proper app icon** for the PWA manifest (currently using an inline SVG placeholder)
  - Add a real PNG icon at 192×192 and 512×512 for best results on iOS/Android home screens
  - Update `manifest.json` to reference the PNG files
- [ ] **Add a service worker** for true offline support (currently the game works offline once loaded, but a SW would cache it properly)
