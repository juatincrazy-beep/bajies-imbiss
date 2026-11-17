"""Sanity check for .tscn files: every parent exists before its child, node names are unique per
parent, and every ExtResource/SubResource id that is used is defined. Usage: python3 tools/check_scene_files.py files..."""
import re
import sys

problems = 0
for path in sys.argv[1:]:
    text = open(path, encoding="utf-8").read()
    ext_ids = set(re.findall(r'^\[ext_resource [^\]]*id="([^"]+)"', text, re.M))
    sub_ids = set(re.findall(r'^\[sub_resource [^\]]*id="([^"]+)"', text, re.M))
    for used in set(re.findall(r'ExtResource\("([^"]+)"\)', text)) - ext_ids:
        print(f"{path}: ExtResource {used} not defined"); problems += 1
    for used in set(re.findall(r'SubResource\("([^"]+)"\)', text)) - sub_ids:
        print(f"{path}: SubResource {used} not defined"); problems += 1
    # Godot needs this order: all ext_resource, then all sub_resource, then nodes.
    order = {"ext_resource": 0, "sub_resource": 1, "node": 2, "connection": 3}
    last = 0
    for kind in re.findall(r'^\[(ext_resource|sub_resource|node|connection)\b', text, re.M):
        if order[kind] < last:
            print(f"{path}: [{kind}] comes after a later section type (wrong order)"); problems += 1
            break
        last = order[kind]
    known = {"."}
    for match in re.finditer(r'^\[node name="([^"]+)"([^\]]*)\]', text, re.M):
        name, rest = match.group(1), match.group(2)
        parent = re.search(r'parent="([^"]*)"', rest)
        if parent is None:
            continue  # root node
        parent = parent.group(1)
        if parent not in known:
            print(f"{path}: node {name} has unknown parent {parent}"); problems += 1
        full = name if parent == "." else f"{parent}/{name}"
        if full in known:
            print(f"{path}: duplicate node {full}"); problems += 1
        known.add(full)
print("scene check:", "OK" if problems == 0 else f"{problems} problem(s)")
sys.exit(1 if problems else 0)
