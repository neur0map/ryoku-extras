# Ryostore

The content catalogue for the [Ryoku](https://ryoku.dev) desktop. This is the
repository behind **Ryostore**, the in-desktop store: everything you browse and
install from Ryoku Settings and the Store lives here, and the shell fetches it
from this repo's `main` on demand.

Every top-level folder is one independent catalogue with its own `registry.json`
index. An item is invisible to the desktop until it is listed in that registry.

| Catalogue | What it holds | Where it shows up |
| --- | --- | --- |
| `rices/` | Whole-desktop looks: window style, shell skin, colour mode, wallpaper | Settings -> Appearance -> Rices |
| `plugins/` | Shell plugins: desktop widgets, frame popouts, and QS Bar widgets | Settings -> Add-ons -> Plugins |
| `colorschemes/` | Colour schemes | Settings -> Colour scheme -> Download |
| `lockscreens/` | Lockscreen looks | Settings -> Lockscreen |
| `decors/` | Poster / ornament art for the desktop | Settings -> Appearance |
| `barstyles/` | Bar skins | Settings -> Bar |
| `fastfetch/` | Fastfetch presets | Settings -> Fastfetch |
| `launcher-images/` | Launcher hero images | Settings -> Appearance |
| `livewalls/` | Live (video) wallpapers | ryowalls -> Ryoku source |
| `bundles/` | Curated sets of packages, scripts, and plugins installed together | Settings -> Extras |
| `nautilus/` | Right-click file-manager script packs (installed by a bundle) | Files right-click menu |
| `ryotunes-skins/` | Ryotunes skins: palette, type, radii and motion for the music player | Ryotunes -> Settings -> Appearance |

`installers/` holds small, auditable curl/script installers that a bundle item
can reference; it is not a browsable catalogue of its own.

## Want to add something?

Two guides, one job each:

- **[DEVELOP.md](DEVELOP.md)** build it and test it live in Ryoku before you
  submit. Point the running desktop at your local copy, watch it hot-reload, and
  validate the catalogue.
- **[CONTRIBUTING.md](CONTRIBUTING.md)** submit it: open a pull request, or fill
  in the [submission form](https://github.com/neur0map/ryostore/issues/new?template=submit-item.yml)
  and a maintainer helps land it.

Deep, per-catalogue authoring references live beside each catalogue
(`plugins/AUTHORING.md`, `rices/AUTHORING.md`, `colorschemes/AUTHORING.md`,
`fastfetch/AUTHORING.md`, `ryotunes-skins/AUTHORING.md`, `nautilus/AUTHORING.md`,
`bundles/README.md`, `installers/README.md`, `livewalls/README.md`).

## The rules, briefly

- **One folder per item, listed in its catalogue's `registry.json`.** Nothing
  ships until it is in the registry.
- **Ship only what you have the right to ship.** Your own work, CC0, or content
  under a licence that permits redistribution. Colour schemes, wallpapers, and
  art are the usual traps.
- **Run the check before you push:** `tests/validate-catalogue.sh`. CI runs it on
  every push and pull request, so a dangling reference never reaches a user as a
  failed install.
- **Plugins and Ryotunes skins carry a per-file manifest.** After any change to
  such a product's files, regenerate it and its registry hash with
  `tools/pack-product.py <category>/<id>` (e.g. `plugins/obsidian` or
  `ryotunes-skins/nord-light`).
