#!/usr/bin/env python3
"""Lightweight sanity checker for the BusSimulator Godot project.

It does NOT replace the Godot editor, but it catches the most common
hand-authored mistakes that would otherwise only surface at import time:
  * .tscn / .tres ext_resource paths that do not exist on disk
  * sub_resource / ext_resource ids referenced but never declared
  * node `parent=` targets that are not declared earlier
  * instance= ids that point at missing ext_resources
  * unbalanced (), [], {} in .gd scripts (after stripping strings/comments)
  * missing `extends` / `class_name` basics

Run:  python3 tools/validate.py
"""
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

problems = []
notices = []


def rel(p):
    return os.path.relpath(p, ROOT)


def check_scene(path):
    text = open(path, "r", encoding="utf-8").read()
    lines = text.splitlines()
    ext = {}        # id -> path
    sub = set()       # ids
    nodes = {}        # name -> parent
    used_sub = set()
    used_ext = set()
    seen_header = False
    load_steps = None

    for ln, line in enumerate(lines, 1):
        s = line.strip()
        if s.startswith("[gd_scene"):
            seen_header = True
            m = re.search(r"load_steps\s*=\s*(\d+)", s)
            if m:
                load_steps = int(m.group(1))
            continue
        m = re.search(r'\[ext_resource.*?path\s*=\s*"([^"]+)"', s)
        if m:
            rid = re.search(r'id\s*=\s*"([^"]+)"', s)
            if rid:
                ext[rid.group(1)] = m.group(1)
            continue
        m = re.search(r"\[sub_resource.*?id\s*=\s*\"([^\"]+)\"", s)
        if m:
            sub.add(m.group(1))
            continue
        m = re.search(r'\[node\s+name\s*=\s*"([^"]+)"', s)
        if m:
            name = m.group(1)
            pm = re.search(r'parent\s*=\s*"([^"]+)"', s)
            parent = pm.group(1) if pm else "."
            inst = re.search(r'instance\s*=\s*ExtResource\("([^"]+)"\)', s)
            if inst:
                used_ext.add(inst.group(1))
            nodes[name] = parent
            continue
        # SubResource(...) references inside property lines.
        for rid in re.findall(r'SubResource\("([^"]+)"\)', s):
            used_sub.add(rid)

    if not seen_header:
        problems.append(f"{rel(path)}: missing [gd_scene] header")

    # ext_resource path existence (strip the res:// virtual prefix)
    for rid, p in ext.items():
        if p.startswith("res://"):
            p = p[len("res://"):]
        fp = os.path.join(ROOT, p)
        if not os.path.exists(fp):
            problems.append(f"{rel(path)}: ext_resource '{rid}' -> missing file {p}")

    # sub_resource references resolve
    for rid in used_sub:
        if rid not in sub:
            problems.append(f"{rel(path)}: references SubResource('{rid}') never declared")

    # instance references resolve
    for rid in used_ext:
        if rid not in ext:
            problems.append(f"{rel(path)}: instance=ExtResource('{rid}') never declared")

    # parent targets exist (declared earlier or ".")
    order = [n for n in nodes]
    for name, parent in nodes.items():
        if parent != "." and parent not in nodes:
            problems.append(f"{rel(path)}: node '{name}' parent '{parent}' not declared")

    # load_steps sanity
    if load_steps is not None:
        need = len(ext) + len(sub) + 1
        if load_steps < need:
            notices.append(
                f"{rel(path)}: load_steps={load_steps} but ~{need} resources "
                f"declared (Godot may warn; harmless)"
            )

    return text


def strip_gd(text):
    out = []
    for line in text.splitlines():
        # drop full-line comments
        if line.strip().startswith("#"):
            continue
        # drop inline comments (rough: first # not in a string)
        res = []
        in_str = False
        i = 0
        while i < len(line):
            c = line[i]
            if c == '"':
                in_str = not in_str
                res.append(c)
                i += 1
                continue
            if c == "#" and not in_str:
                break
            res.append(c)
            i += 1
        out.append("".join(res))
    return "\n".join(out)


def check_gd(path):
    text = open(path, "r", encoding="utf-8").read()
    # remove string literals so brackets inside them are ignored
    no_str = re.sub(r'"(\\.|[^"\\])*"', '""', text)
    no_str = strip_gd(no_str)
    pairs = {")": "(", "]": "[", "}": "{"}
    stack = []
    for ch in no_str:
        if ch in "([{":
            stack.append(ch)
        elif ch in ")]}":
            if not stack or stack[-1] != pairs[ch]:
                problems.append(f"{rel(path)}: unbalanced bracket '{ch}'")
                break
            stack.pop()
    if stack:
        problems.append(f"{rel(path)}: unclosed brackets {stack}")
    if "extends" not in text:
        notices.append(f"{rel(path)}: no `extends` line (may be intentional)")


def main():
    for dp, _, files in os.walk(ROOT):
        if ".git" in dp or ".godot" in dp:
            continue
        for f in files:
            p = os.path.join(dp, f)
            if f.endswith((".tscn", ".tres")):
                check_scene(p)
            elif f.endswith(".gd"):
                check_gd(p)

    print("BusSimulator project validation")
    print("=" * 40)
    if notices:
        print("Notices:")
        for n in notices:
            print("  -", n)
    if problems:
        print("\nPROBLEMS FOUND:")
        for p in problems:
            print("  !", p)
        print(f"\n{len(problems)} problem(s).")
        sys.exit(1)
    else:
        print("\nNo structural problems detected. "
              "(Engine import still recommended before shipping.)")


if __name__ == "__main__":
    main()
