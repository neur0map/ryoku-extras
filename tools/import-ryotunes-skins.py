#!/usr/bin/env python3
"""Generate Ryotunes skin products from the Ryoku colour-scheme catalogue.

Usage:
    tools/import-ryotunes-skins.py <id> [<id>...]
    e.g. tools/import-ryotunes-skins.py nord-light catppuccin-frappe

Each ``<id>`` is a scheme id in ``colorschemes/registry.json`` (117 Noctalia
palettes, each with ``dark`` and/or ``light`` objects). For every id this tool
maps the Noctalia palette onto Ryotunes' eight skin roles and writes a complete
``ryotunes-skins/<id>/`` product:

- ``skin.json``       the Ryotunes manifest (format 1; see ryotunes/docs/SKINS.md)
- ``LICENSE``         the licence the skin ships under (CC0-1.0 by default)
- ``PROVENANCE.txt``  the scheme id, provider, source and the mapping used

and appends or refreshes the matching entry in ``ryotunes-skins/registry.json``.

It does **not** write ``manifest.json`` or ``manifestSha256`` -- run
``tools/pack-product.py ryotunes-skins/<id>`` afterwards for that, and
``scripts/dev/skin-preview.sh`` (in the Ryotunes checkout) for ``preview.png``.

The eight-role mapping (both modes, when the scheme carries both):

    paper     = mSurface
    paperLift = whichever of mSurfaceVariant / mHover is closest in luminance to
                mSurface without being identical to it
    ink       = mOnSurface
    inkDim    = mOnSurfaceVariant
    bone      = mOnSurface           (the inverse surface reuses the mode's ink)
    inkOnBone = mSurface             (text on bone is the mode's paper)
    sun       = mPrimary
    alert     = mError

Idempotent: re-running reproduces byte-identical skin.json / LICENSE /
PROVENANCE.txt, and preserves an existing entry's ``manifestSha256`` and
``lastUpdated`` (so it never undoes a later pack-product run).
"""
from __future__ import annotations

import argparse
import datetime
import json
from pathlib import Path
import sys


REPO_ROOT = Path(__file__).resolve().parent.parent
CATEGORY = "ryotunes-skins"
ROLES = ("paper", "paperLift", "ink", "inkDim", "bone", "inkOnBone", "sun", "alert")

# The palette itself (eight hex codes) is not a copyrightable work; a derived
# skin is dedicated to the public domain unless a source declares otherwise.
DEFAULT_LICENSE = "CC0-1.0"

# Well-known upstreams the catalogue palettes descend from, for PROVENANCE
# attribution. Matched by longest id prefix; the provider covers the rest.
UPSTREAMS = (
    ("catppuccin", "Catppuccin", "https://github.com/catppuccin/catppuccin"),
    ("gruvbox", "Gruvbox", "https://github.com/morhetz/gruvbox"),
    ("nord", "Nord", "https://www.nordtheme.com"),
    ("rose-pine", "Rosé Pine", "https://rosepinetheme.com"),
    ("tokyo-night", "Tokyo Night", "https://github.com/enkia/tokyo-night-vscode-theme"),
    ("kanagawa", "Kanagawa", "https://github.com/rebelot/kanagawa.nvim"),
    ("everforest", "Everforest", "https://github.com/sainnhe/everforest"),
    ("solarized", "Solarized", "https://ethanschoonover.com/solarized/"),
    ("one-dark", "One Dark", "https://github.com/atom/atom"),
    ("oceanic-next", "Oceanic Next", "https://github.com/voronianski/oceanic-next-color-scheme"),
    ("poimandres", "Poimandres", "https://github.com/drcmda/poimandres-theme"),
    ("github", "GitHub Primer", "https://github.com/primer/github-vscode-theme"),
    ("monokai", "Monokai", "https://monokai.pro"),
)

CC0_TEXT = """Creative Commons Legal Code

CC0 1.0 Universal

    CREATIVE COMMONS CORPORATION IS NOT A LAW FIRM AND DOES NOT PROVIDE
    LEGAL SERVICES. DISTRIBUTION OF THIS DOCUMENT DOES NOT CREATE AN
    ATTORNEY-CLIENT RELATIONSHIP. CREATIVE COMMONS PROVIDES THIS
    INFORMATION ON AN "AS-IS" BASIS. CREATIVE COMMONS MAKES NO WARRANTIES
    REGARDING THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS
    PROVIDED HEREUNDER, AND DISCLAIMS LIABILITY FOR DAMAGES RESULTING FROM
    THE USE OF THIS DOCUMENT OR THE INFORMATION OR WORKS PROVIDED
    HEREUNDER.

Statement of Purpose

The laws of most jurisdictions throughout the world automatically confer
exclusive Copyright and Related Rights (defined below) upon the creator
and subsequent owner(s) (each and all, an "owner") of an original work of
authorship and/or a database (each, a "Work").

Certain owners wish to permanently relinquish those rights to a Work for
the purpose of contributing to a commons of creative, cultural and
scientific works ("Commons") that the public can reliably and without fear
of later claims of infringement build upon, modify, incorporate in other
works, reuse and redistribute as freely as possible in any form whatsoever
and for any purposes, including without limitation commercial purposes.
These owners may contribute to the Commons to promote the ideal of a free
culture and the further production of creative, cultural and scientific
works, or to gain reputation or greater distribution for their Work in
part through the use and efforts of others.

For these and/or other purposes and motivations, and without any
expectation of additional consideration or compensation, the person
associating CC0 with a Work (the "Affirmer"), to the extent that he or she
is an owner of Copyright and Related Rights in the Work, voluntarily
elects to apply CC0 to the Work and publicly distribute the Work under its
terms, with knowledge of his or her Copyright and Related Rights in the
Work and the meaning and intended legal effect of CC0 on those rights.

1. Copyright and Related Rights. A Work made available under CC0 may be
protected by copyright and related or neighboring rights ("Copyright and
Related Rights"). Copyright and Related Rights include, but are not
limited to, the following:

  i. the right to reproduce, adapt, distribute, perform, display,
     communicate, and translate a Work;
 ii. moral rights retained by the original author(s) and/or performer(s);
iii. publicity and privacy rights pertaining to a person's image or
     likeness depicted in a Work;
 iv. rights protecting against unfair competition in regards to a Work,
     subject to the limitations in paragraph 4(a), below;
  v. rights protecting the extraction, dissemination, use and reuse of data
     in a Work;
 vi. database rights (such as those arising under Directive 96/9/EC of the
     European Parliament and of the Council of 11 March 1996 on the legal
     protection of databases, and under any national implementation
     thereof, including any amended or successor version of such
     directive); and
vii. other similar, equivalent or corresponding rights throughout the
     world based on applicable law or treaty, and any national
     implementations thereof.

2. Waiver. To the greatest extent permitted by, but not in contravention
of, applicable law, Affirmer hereby overtly, fully, permanently,
irrevocably and unconditionally waives, abandons, and surrenders all of
Affirmer's Copyright and Related Rights and associated claims and causes
of action, whether now known or unknown (including existing as well as
future claims and causes of action), in the Work (i) in all territories
worldwide, (ii) for the maximum duration provided by applicable law or
treaty (including future time extensions), (iii) in any current or future
medium and for any number of copies, and (iv) for any purpose whatsoever,
including without limitation commercial, advertising or promotional
purposes (the "Waiver"). Affirmer makes the Waiver for the benefit of each
member of the public at large and to the detriment of Affirmer's heirs and
successors, fully intending that such Waiver shall not be subject to
revocation, rescission, cancellation, termination, or any other legal or
equitable action to disrupt the quiet enjoyment of the Work by the public
as contemplated by Affirmer's express Statement of Purpose.

3. Public License Fallback. Should any part of the Waiver for any reason
be judged legally invalid or ineffective under applicable law, then the
Waiver shall be preserved to the maximum extent permitted taking into
account Affirmer's express Statement of Purpose. In addition, to the
extent the Waiver is so judged Affirmer hereby grants to each affected
person a royalty-free, non transferable, non sublicensable, non exclusive,
irrevocable and unconditional license to exercise Affirmer's Copyright and
Related Rights in the Work (i) in all territories worldwide, (ii) for the
maximum duration provided by applicable law or treaty (including future
time extensions), (iii) in any current or future medium and for any number
of copies, and (iv) for any purpose whatsoever, including without
limitation commercial, advertising or promotional purposes (the
"License"). The License shall be deemed effective as of the date CC0 was
applied by Affirmer to the Work. Should any part of the License for any
reason be judged legally invalid or ineffective under applicable law, such
partial invalidity or ineffectiveness shall not invalidate the remainder
of the License, and in such case Affirmer hereby affirms that he or she
will not (i) exercise any of his or her remaining Copyright and Related
Rights in the Work or (ii) assert any associated claims and causes of
action with respect to the Work, in either case contrary to Affirmer's
express Statement of Purpose.

4. Limitations and Disclaimers.

 a. No trademark or patent rights held by Affirmer are waived, abandoned,
    surrendered, licensed or otherwise affected by this document.
 b. Affirmer offers the Work as-is and makes no representations or
    warranties of any kind concerning the Work, express, implied,
    statutory or otherwise, including without limitation warranties of
    title, merchantability, fitness for a particular purpose, non
    infringement, or the absence of latent or other defects, accuracy, or
    the present or absence of errors, whether or not discoverable, all to
    the greatest extent permissible under applicable law.
 c. Affirmer disclaims responsibility for clearing rights of other persons
    that may apply to the Work or any use thereof, including without
    limitation any person's Copyright and Related Rights in the Work.
    Further, Affirmer disclaims responsibility for obtaining any necessary
    consents, permissions or other rights required for any use of the
    Work.
 d. Affirmer understands and acknowledges that Creative Commons is not a
    party to this document and has no duty or obligation with respect to
    this CC0 or use of the Work.
"""

LICENSE_TEXT = {"CC0-1.0": CC0_TEXT}


def _read_json(path: Path) -> object:
    return json.loads(path.read_text(encoding="utf-8"))


def _write_json(path: Path, value: object) -> None:
    path.write_text(json.dumps(value, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")


def _write_text(path: Path, text: str) -> None:
    if not text.endswith("\n"):
        text += "\n"
    path.write_text(text, encoding="utf-8")


def provider_slug(provider: str) -> str:
    slug = "".join(ch.lower() if ch.isalnum() else "-" for ch in provider)
    return "-".join(part for part in slug.split("-") if part)


def upstream_for(scheme_id: str, provider: str) -> tuple[str, str | None]:
    """(label, url) naming where the palette comes from, for PROVENANCE."""
    best = None
    for prefix, label, url in UPSTREAMS:
        if scheme_id == prefix or scheme_id.startswith(prefix + "-"):
            if best is None or len(prefix) > len(best[0]):
                best = (prefix, label, url)
    if best is not None:
        return best[1], best[2]
    return provider, None


def relative_luminance(hex_colour: str) -> float:
    value = hex_colour.lstrip("#")
    channels = (int(value[i:i + 2], 16) for i in (0, 2, 4))
    linear = []
    for channel in channels:
        c = channel / 255.0
        linear.append(c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4)
    r, g, b = linear
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def norm(hex_colour: str) -> str:
    return "#" + hex_colour.lstrip("#").lower()


def pick_paper_lift(mode: dict) -> str | None:
    surface = norm(mode["mSurface"])
    surface_lum = relative_luminance(surface)
    candidates = []
    for key in ("mSurfaceVariant", "mHover"):
        value = mode.get(key)
        if isinstance(value, str) and value and norm(value) != surface:
            candidates.append(norm(value))
    if not candidates:
        variant = mode.get("mSurfaceVariant")
        return norm(variant) if isinstance(variant, str) and variant else None
    return min(candidates, key=lambda c: abs(relative_luminance(c) - surface_lum))


def map_mode(mode: dict) -> dict:
    palette = {
        "paper": norm(mode["mSurface"]),
        "paperLift": pick_paper_lift(mode),
        "ink": norm(mode["mOnSurface"]),
        "inkDim": norm(mode["mOnSurfaceVariant"]),
        "bone": norm(mode["mOnSurface"]),
        "inkOnBone": norm(mode["mSurface"]),
        "sun": norm(mode["mPrimary"]),
        "alert": norm(mode["mError"]),
    }
    return {role: palette[role] for role in ROLES if palette[role] is not None}


def build_skin(scheme: dict) -> dict:
    scheme_id = scheme["id"]
    modes = {name: map_mode(scheme[name]) for name in ("dark", "light") if name in scheme}
    if not modes:
        raise ValueError(f"{scheme_id}: scheme has neither a dark nor a light palette")
    default = "dark" if "dark" in modes else "light"
    name = scheme.get("name", scheme_id)
    return {
        "format": 1,
        "id": scheme_id,
        "name": name,
        "author": scheme.get("provider", ""),
        "version": "1.0.0",
        "license": DEFAULT_LICENSE,
        "description": f"{name} for Ryotunes, from the Ryoku colour-scheme catalogue.",
        "default": default,
        "modes": modes,
        "accent": "artwork",
        "wash": 1.0,
    }


def build_provenance(scheme: dict, skin: dict) -> str:
    scheme_id = scheme["id"]
    provider = scheme.get("provider", "")
    label, url = upstream_for(scheme_id, provider)
    catalogue = scheme.get("preview", "")
    lines = [
        f"Skin: {skin['name']} ({scheme_id})",
        f"Provider: {provider}",
        f"Upstream palette: {label}" + (f" <{url}>" if url else ""),
        f"Source: Ryoku colour-scheme catalogue (colorschemes/{scheme_id})",
    ]
    if catalogue:
        lines.append(f"        {catalogue}")
    lines += [
        f"License: {skin['license']}",
        "",
        "Derived by tools/import-ryotunes-skins.py, mapping the Noctalia palette",
        "onto Ryotunes' eight skin roles, per mode:",
        "  paper     = mSurface",
        "  paperLift = mSurfaceVariant or mHover, whichever is closest in",
        "              luminance to mSurface without equalling it",
        "  ink       = mOnSurface",
        "  inkDim    = mOnSurfaceVariant",
        "  bone      = mOnSurface",
        "  inkOnBone = mSurface",
        "  sun       = mPrimary",
        "  alert     = mError",
        "",
        "Only the eight colour roles are set; type, shape, motion and decor are",
        "left to Ryotunes' Paper defaults.",
    ]
    return "\n".join(lines)


def registry_entry(scheme: dict, skin: dict, previous: dict | None) -> dict:
    scheme_id = scheme["id"]
    default_mode = skin["modes"][skin["default"]]
    mode_tag = skin["default"]
    entry = {
        "id": scheme_id,
        "name": skin["name"],
        "version": skin["version"],
        "path": f"{CATEGORY}/{scheme_id}",
        "author": skin["author"],
        "summary": f"{skin['name']} colour scheme as a Ryotunes skin",
        "description": skin["description"],
        "tags": [mode_tag, provider_slug(skin["author"]), "colorscheme"],
        "accent": default_mode["sun"],
        "surface": default_mode["paper"],
        "preview": "preview.png",
        "screenshots": [],
        "manifest": "manifest.json",
        "manifestSha256": (previous or {}).get("manifestSha256", "0" * 64),
        "lastUpdated": (previous or {}).get(
            "lastUpdated", datetime.date.today().isoformat()
        ),
    }
    return entry


def load_registry(path: Path) -> dict:
    if path.exists():
        registry = _read_json(path)
        if not isinstance(registry, dict) or CATEGORY not in registry:
            raise ValueError(f"{path}: not a {CATEGORY} registry")
        registry.setdefault("schema", 1)
        if not isinstance(registry.get(CATEGORY), list):
            registry[CATEGORY] = []
        return registry
    return {"schema": 1, CATEGORY: []}


def import_scheme(root: Path, schemes: dict[str, dict], scheme_id: str, registry: dict) -> None:
    scheme = schemes.get(scheme_id)
    if scheme is None:
        raise ValueError(f"{scheme_id}: not found in colorschemes/registry.json")

    skin = build_skin(scheme)
    product = root / CATEGORY / scheme_id
    product.mkdir(parents=True, exist_ok=True)
    _write_json(product / "skin.json", skin)
    _write_text(product / "LICENSE", LICENSE_TEXT[skin["license"]])
    _write_text(product / "PROVENANCE.txt", build_provenance(scheme, skin))

    entries = registry[CATEGORY]
    previous = next((e for e in entries if isinstance(e, dict) and e.get("id") == scheme_id), None)
    entry = registry_entry(scheme, skin, previous)
    if previous is None:
        entries.append(entry)
    else:
        entries[entries.index(previous)] = entry
    entries.sort(key=lambda e: e.get("id", ""))


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("ids", nargs="+", help="scheme ids from colorschemes/registry.json")
    parser.add_argument("--root", type=Path, default=REPO_ROOT, help="catalogue root")
    args = parser.parse_args(argv)

    root = args.root.resolve()
    schemes_registry = _read_json(root / "colorschemes" / "registry.json")
    schemes = {t["id"]: t for t in schemes_registry.get("themes", []) if isinstance(t, dict)}

    registry_path = root / CATEGORY / "registry.json"
    registry = load_registry(registry_path)
    try:
        for scheme_id in args.ids:
            import_scheme(root, schemes, scheme_id, registry)
    except (ValueError, OSError) as error:
        print(f"import-ryotunes-skins: {error}", file=sys.stderr)
        return 1
    _write_json(registry_path, registry)

    print(f"imported {len(args.ids)} skin(s): {', '.join(args.ids)}")
    print(f"next: tools/pack-product.py {CATEGORY}/<id> and scripts/dev/skin-preview.sh")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
