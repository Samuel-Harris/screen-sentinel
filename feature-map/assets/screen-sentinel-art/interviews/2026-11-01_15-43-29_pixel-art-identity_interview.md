# Interview: Screen Sentinel pixel art identity

## Metadata

- Rounds: 6
- Final Ambiguity Score: 18%
- Type: brownfield
- Generated: 2026-11-01_15-43-29
- Threshold: 20%
- Status: PASSED

## Clarity Breakdown

| Dimension          | Score | Weight | Weighted |
| ------------------ | ----- | ------ | -------- |
| Goal Clarity       | 0.92  | 0.35   | 0.32     |
| Constraint Clarity | 0.80  | 0.25   | 0.20     |
| Success Criteria   | 0.70  | 0.25   | 0.18     |
| Context Clarity    | 0.85  | 0.15   | 0.13     |
| **Total Clarity**  |       |        | **0.82** |
| **Ambiguity**      |       |        | **0.18** |

## Goal

A static pixel art identity for Screen Sentinel built on one image: a monitor
whose screen holds a calm, heavy-lidded eye with a black pupil. It ships as a
macOS app icon, three menu bar status glyphs and a README/social-preview cover.

## Constraints

- Palette H, "night greyscale plus red": black, greys from #111111 to #d6d6d6,
  and one red (#ff3b30) used only for the recording light.
- Pupil is pure black. No red in the eye.
- Two masters: 16x16 for small sizes, a detailed 32x32 for 32px and up.
- Static. No animation in any shipped asset.
- Whole-number nearest-neighbour scaling only.
- Menu bar glyphs are macOS template images (black plus alpha) and differ by
  shape, not colour.
- Must not resemble the screenpipe name or logo (feature-map README, out of scope).

## Non-Goals

- Animated GIFs, including the scan and blink loops explored in round 4.
- Tauri desktop app icon set (the app is being removed per feature 01).
- Light-mode variant of the app icon.

## Acceptance Criteria

- [ ] At 32px in Finder the icon reads as "a screen that watches back" within half a second.
- [ ] Recording, frozen and stopped glyphs are distinguishable at 16px on light and dark menu bars.
- [ ] The only red pixels in the icon are the recording light.
- [ ] Every PNG is an integer nearest-neighbour upscale of a master (no blurred pixels).
- [ ] The cover is 1280x640 (GitHub social preview size) and works as the README banner.
- [ ] AppIcon.icns, icon.ico and a full AppIcon.iconset are produced.

## Assumptions Exposed & Resolved

| Assumption | Challenge | Resolution |
| --- | --- | --- |
| There is an app to put an icon on | Feature 01 removes the desktop app | Icon targets GitHub, the menu bar and a LaunchAgent wrapper .app |
| Inherit screenpipe's no-colour rule | That is screenpipe's identity, not yours | Greyscale plus one red |
| An eye on a screen reads as reassuring | It is the classic surveillance image | Protective: heavy lid, pupil low |
| Red belongs in the eye | Compared red pupil, red glint, black pupil | Black pupil; red only on the recording light |
| One sprite can serve every size | Simplifier mode | 16 master small, 32 master large plus a cover scene |
| Menu bar states (assumed) | Not asked | Pupil = recording, blank stare = frozen, closed lid = stopped |
| Cover composition (assumed) | Not asked | Monitor on a desk at night, title and tagline below |

## Technical Context

Repo is screenpipe CLI 0.4.15 being cut down to a single-Mac screen recorder
queried by agents. README.md and DESIGN.md are still upstream's. Upstream
icons live in apps/screenpipe-app-tauri/src-tauri/icons and assets/ (tray PNGs
in black/white variants), both slated for removal.

## Ontology (Key Entities)

| Entity | Fields | Relationships |
| --- | --- | --- |
| Master sprite | size (16, 32), palette | Source of every exported raster |
| App icon | iconset sizes, icns, ico | 16 master below 32px, 32 master from 32px |
| Tray glyph | state, 1x/2x | Recording / frozen / stopped; template images |
| Cover | 128x64 master, x10 export | Reuses the 32 monitor drawing |

## Interview Transcript

<details>
<summary>Full Q&A (6 rounds)</summary>

### Round 1
**Q:** Where will the icon and cover be seen?
**A:** GitHub README and social preview, macOS menu bar status icon, Finder/Dock .app icon.

### Round 2
**Q:** Which palette? (two rounds of visual options, A–K)
**A:** H, night greyscale plus red.

### Round 3
**Q:** What should a half-second glance communicate?
**A:** A screen that watches back.

### Round 4 (contrarian)
**Q:** How should the eye feel, given it can read as surveillance?
**A:** Compared protective, neutral and playful; then protective with scan and blink animations.

### Round 5
**Q:** Where should animation ship, and which pupil?
**A:** Static. Then a pure black pupil after comparing red and red-glint versions.

### Round 6 (simplifier)
**Q:** One 16x16 sprite everywhere, or a detailed 32x32 too?
**A:** 16x16 small, detailed 32x32 icon and a cover scene.

</details>
