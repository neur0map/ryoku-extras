# Ryoku plugins

Shell plugins for Ryoku. Each plugin is a self-contained folder the shell installs as a
receipt-owned product (its files are fetched and SHA-verified per `product-manifest.json`)
and loads from Settings → Plugins.

## Folder layout

```
plugins/
  registry.json        # the installable list (see below)
  AUTHORING.md         # how to build a plugin (desktop tile, popout, or bar mark)
  template/            # minimal example - copy it to start
  photo-frame/         # the worked example
    manifest.json      # id, version, entry points, host placement
    product-manifest.json # per-file sha256/size/mode; run tools/pack-product.py
    README.md          # required; embeds assets/preview-widget.png
    assets/preview-widget.png
    service/Main.qml   # main entry point: persistent logic
    content/Widget.qml # content entry point: the adaptive view
    content/PhotoFrame.qml
```

## How registry.json works

`registry.json` is the catalogue the shell reads. It has two arrays: `plugins`, the
installable list, and `archived`, retired plugins kept for reference. Entries share one
shape:

```json
{
  "id": "my-plugin",
  "name": "My Plugin",
  "path": "plugins/my-plugin",
  "version": "1.0.0",
  "author": "Ryoku Team",
  "description": "One sentence shown in the catalogue.",
  "tags": ["desktop-widget"],
  "hosts": ["desktopWidget"],
  "official": true,
  "lastUpdated": "2026-06-06"
}
```

A plugin folder is offered in Settings only while its entry is in `plugins`. Moving an entry
to `archived` retires it: the folder stays in the repo but the shell stops listing it.

Tag a bar widget `bar-widget` and a desktop plugin `desktop-widget` / `frame-popout`,
keep `hosts` in sync with the manifest, and leave `official` off for community work.
After any file change, regenerate the product manifest and its hash with
`tools/pack-product.py plugins/<id>`. [`AUTHORING.md`](AUTHORING.md) has the rest.

## Contributing

Copy `template/` and read [`AUTHORING.md`](AUTHORING.md) for the full guide.
