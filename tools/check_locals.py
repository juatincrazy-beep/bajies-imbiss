"""Finds local variables in GDScript that are declared twice in the same function
(a parameter, `var x` or `for x in` that already exists in an enclosing block).
Godot refuses to load such a script ("Could not parse global class ..."), but gdparse
(syntax only) does not notice it. Also lists locals that hide a member variable of the same
script (Godot only warns about those).

Usage: python3 tools/check_locals.py [files or folders]   (default: the whole project)
Exit code 1 if an error was found."""
import os
import re
import sys

ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
SKIP_DIRS = {".git", ".godot", "addons", "tools", "build"}

FUNC_RE = re.compile(r"^(static\s+)?func\s+(\w+)\s*\((.*)")
VAR_RE = re.compile(r"^(?:var|const)\s+(\w+)")
FOR_RE = re.compile(r"^for\s+(\w+)\s*(?::\s*[\w.\[\], ]+?)?\s+in\s")
MEMBER_RE = re.compile(r"^(?:@\w+(?:\([^)]*\))?\s+)*(?:var|const)\s+(\w+)")


def indent_of(line):
    return len(line) - len(line.lstrip("\t"))


def param_names(text):
    # text = everything after "func name(" up to the closing ")" (may span lines; we join them)
    depth = 1
    out = ""
    for ch in text:
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
            if depth == 0:
                break
        out += ch
    names = []
    depth = 0
    part = ""
    for ch in out + ",":
        if ch in "([{":
            depth += 1
        elif ch in ")]}":
            depth -= 1
        if ch == "," and depth == 0:
            m = re.match(r"\s*(\w+)", part)
            if m:
                names.append(m.group(1))
            part = ""
        else:
            part += ch
    return names


def check_file(path):
    errors, warnings = [], []
    with open(path, encoding="utf-8") as f:
        lines = f.read().split("\n")
    members = set()
    for line in lines:
        if line and not line[0].isspace():
            m = MEMBER_RE.match(line)
            if m:
                members.add(m.group(1))
    in_func = False
    scopes = []  # list of (indent, set of names)
    i = 0
    while i < len(lines):
        raw = lines[i]
        stripped = raw.strip()
        if not stripped or stripped.startswith("#"):
            i += 1
            continue
        ind = indent_of(raw)
        m = FUNC_RE.match(stripped) if ind == 0 else None
        if m:
            sig = m.group(3)
            j = i
            while sig.count("(") + 1 > sig.count(")") and j + 1 < len(lines):
                j += 1
                sig += " " + lines[j].strip()
            in_func = True
            scopes = [(1, set(param_names(sig)))]
            for name in scopes[0][1]:
                if name in members:
                    warnings.append(f"{path}:{i + 1}: parameter '{name}' hides a member variable")
            i = j + 1
            continue
        if ind == 0:
            in_func = False
            i += 1
            continue
        if not in_func:
            i += 1
            continue
        while scopes and ind < scopes[-1][0]:
            scopes.pop()
        if not scopes or ind > scopes[-1][0]:
            scopes.append((ind, set()))
        declared = None
        for_var = None
        mv = VAR_RE.match(stripped)
        mf = FOR_RE.match(stripped)
        if mv:
            declared = mv.group(1)
        elif mf:
            for_var = mf.group(1)
        name = declared or for_var
        if name:
            if any(name in names for _ind, names in scopes):
                errors.append(f"{path}:{i + 1}: '{name}' is already declared in this function")
            elif name in members:
                warnings.append(f"{path}:{i + 1}: local '{name}' hides a member variable")
            if declared:
                scopes[-1][1].add(name)
            else:
                # The loop variable lives in the loop's own block (one level deeper).
                scopes.append((ind + 1, {name}))
        i += 1
    return errors, warnings


def check_members(path):
    """Two members (var / const / signal / func) with the same name in one script: Godot refuses it
    ("has the same name as a previously declared variable") but gdparse does not notice."""
    import collections
    seen = collections.Counter()
    for line in open(path, encoding="utf-8"):
        m = (re.match(r"^(?:@onready\s+|@export\S*\s+)*(?:var|const)\s+(\w+)", line)
             or re.match(r"^func\s+(\w+)", line) or re.match(r"^signal\s+(\w+)", line))
        if m:
            seen[m.group(1)] += 1
    return [f"{path}: member '{name}' is declared {count} times" for name, count in seen.items() if count > 1]


def main():
    targets = sys.argv[1:] or [ROOT]
    files = []
    for target in targets:
        if os.path.isfile(target):
            files.append(target)
            continue
        for folder, dirs, names in os.walk(target):
            dirs[:] = [d for d in dirs if d not in SKIP_DIRS]
            files += [os.path.join(folder, n) for n in names if n.endswith(".gd")]
    all_errors, all_warnings = [], []
    for path in sorted(files):
        e, w = check_file(path)
        all_errors += e
        all_warnings += w
        all_errors += check_members(path)
    for w in all_warnings:
        print("warning:", os.path.relpath(w, ROOT) if w.startswith(ROOT) else w)
    for e in all_errors:
        print("ERROR:", os.path.relpath(e, ROOT) if e.startswith(ROOT) else e)
    print(f"locals check: {len(all_errors)} error(s), {len(all_warnings)} warning(s) in {len(files)} scripts")
    sys.exit(1 if all_errors else 0)


main()
