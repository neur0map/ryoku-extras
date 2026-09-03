# Authoring a colour scheme for the Ryoku store

A colour scheme is a fixed palette: a `dark` block, a `light` block, or both.
Users download schemes from **Settings -> Colour scheme -> Download**, and once
installed a scheme behaves exactly like a built-in one: it appears in the
`Super+W` colour-scheme belt and the Hub picker, applies through
`ryoku-shell theme <id>`, and matugen fans it into every app.

Copy [`template/template.json`](template/template.json) to start; it is a
complete, legible dark+light scheme you can recolour role by role.

## Layout

```
colorschemes/
  registry.json        the catalogue (envelope: {"version": 1, "themes": [...]})
  <Name>/
    <Name>.json         the scheme: { "dark": {...}, "light": {...} }
    preview.png         optional art shown instead of the generated pills
```

One folder per scheme; the file is named after the folder. Nothing ships until
it is listed in `registry.json`.

## How a scheme looks in `Super+W` (design first)

The switcher and Hub draw each scheme as a tall card filled with your `mSurface`,
the name on top in your `mOnSurface`, and a row of five tall rounded pills -- the
colour-combo preview:

```
pills:  mOnSurface  mPrimary  mSecondary  mTertiary  mError
```

`mSurface` is the card, `mOutline` is its border, and dark vs light is decided
from `mSurface`'s luma (< 0.5 = dark). To read well in the belt:

- **Legible name.** Keep `mOnSurface` well clear of `mSurface` (aim for a WCAG
  contrast of 4.5 or more). The template's dark block is 16:1.
- **Distinct, saturated accents.** `mPrimary`/`mSecondary`/`mTertiary`/`mError`
  are the four colour pills, so make them read as four different hues that pop
  against `mSurface`. The template borrows a five-colour combo (lavender, mint,
  pale yellow, red) so the row stays lively.
- **A visible but quiet `mOutline`.** It is the card's border, so keep it a muted
  mid-tone, not a fifth accent.
- **Legible ink on accents.** `mOnPrimary`/`mOnSecondary`/`mOnTertiary`/`mOnError`
  paint text and icons on those accents; keep each at 4.5+ against its accent.

## Preview art (optional)

Most schemes are best shown as the generated pills, which cost nothing and always
match the palette. When a scheme's own art sells the look better, ship a
`preview.png` (or `.jpg`/`.jpeg`) beside the scheme file: when the installed
scheme folder carries one, the picker shows that image cropped to the card
instead of the pills.

## The scheme file

Each block carries the sixteen Material roles plus a `terminal` sub-object. Only
`mSurface`, `mOnSurface`, and `mPrimary` are strictly required; the daemon
derives any role you omit, but a complete block gives you full control.

| role | what it paints |
| --- | --- |
| `mSurface` / `mOnSurface` | window and widget backgrounds / the ink on them |
| `mPrimary` / `mOnPrimary` | the accent (buttons, active state) / ink on it |
| `mSecondary` / `mOnSecondary` | second accent / ink on it |
| `mTertiary` / `mOnTertiary` | third accent / ink on it |
| `mError` / `mOnError` | error / ink on it |
| `mSurfaceVariant` / `mOnSurfaceVariant` | raised surfaces / their ink |
| `mHover` / `mOnHover` | hover fill / ink on it (usually mirrors primary) |
| `mOutline` | borders and dividers |
| `mShadow` | drop shadows (`#000000` for most schemes) |

`terminal` sets the emulator palette: `background`, `foreground`, `cursor`,
`cursorText`, `selectionBg`, `selectionFg`, and the `normal` and `bright`
sixteen ANSI colours (`black red green yellow blue magenta cyan white`). Match
these to your roles so the terminal agrees with the shell.

Ship at least one of `dark`/`light`; ship both to cover either mode.

## registry.json entry

Add a row to the `themes` array. Keep this key order:

| field | meaning |
| --- | --- |
| `id` | kebab-case slug, unique across the catalogue |
| `name` | display name shown in the picker |
| `provider` | where the scheme comes from (e.g. `Ryoku`, `Noctalia`) |
| `path` | `colorschemes/<Name>` (the folder) |
| `accent` | `#rrggbb`, normally your `mPrimary` (tile accent) |
| `surface` | `#rrggbb`, your `mSurface` (tile background) |
| `source` | upstream URL (optional, for imported schemes) |
| `preview` | raw URL to a preview image (optional) |
| `wallpapers` | list of raw URLs to the scheme's own wallpapers (optional); the store lands them in the user's wallpaper library on install, so pin them to a commit, not a branch |
| `dark` / `light` | the same block(s) as the scheme file, inline |

The row embeds `dark`/`light` so the desktop installs from the registry alone;
keep the row's blocks identical to `<Name>/<Name>.json`.

## Test and submit

Point the running desktop at your checkout and open the picker, exactly as
[`DEVELOP.md`](../DEVELOP.md) describes, then validate from the repo root:

```sh
tests/validate-catalogue.sh
```

It should print `catalogue OK`. Then follow
[`CONTRIBUTING.md`](../CONTRIBUTING.md) to submit.
