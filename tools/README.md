# tools/

Python helper scripts; Godot ignores this folder (`.gdignore`).

| Script | What it does |
|---|---|
| `gen_diner_data.py` | Writes `scenes/diner/data/*/*.tres` (ingredients, dishes, guests, trips, upgrades) and appends missing translation keys to `localization/translations.csv`. Edit the tables at the top, then run it. |
| `check_locals.py` | Finds duplicate local variables / class members in GDScript (Godot refuses such scripts, gdparse does not notice). |
| `check_scene_files.py` | Sanity check for hand-written `.tscn` files. |
| `import_ki_models.py` | Shrinks AI-made 3D models (needs the originals, which live in the old repo `cake-carriers`, `tools/ki_originals`). |

Before every push: `gdparse` on all scripts (pip install gdtoolkit), `check_locals.py`, `check_scene_files.py`.
