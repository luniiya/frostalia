"""Built-in settings defaults, read from the JsonAdapter in Commons/Settings.qml.

Settings.qml is the only place defaults are written down: at runtime the settings
store snapshots it before loading the host's TOML, and Settings.getDefaultValue()
reads that snapshot. Tests use this parser to see the same tree.
"""

import functools
import json
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parents[2]
SETTINGS_QML = ROOT / "Commons" / "Settings.qml"

OPEN_OBJECT = re.compile(r"^\s*(?:property JsonObject )?(\w+): JsonObject \{")
PROPERTY = re.compile(r"^\s*property (bool|int|real|double|string|var|list<var>|list<string>) (\w+): (.*)$")
SCALAR = re.compile(r'^(true|false|-?\d+(?:\.\d+)?|"(?:[^"\\]|\\.)*")\s*(?://.*)?$')


def adapter_lines(text):
    start = text.index("JsonAdapter {")
    depth = 0
    for index, char in enumerate(text[start:]):
        depth += {"{": 1, "}": -1}.get(char, 0)
        if char == "}" and depth == 0:
            return text[start:start + index + 1].splitlines()
    raise ValueError("unterminated JsonAdapter")


def strip_comment(line):
    # Drops a // comment that is not inside a string
    in_string = False
    for index, char in enumerate(line):
        if char == '"' and (index == 0 or line[index - 1] != "\\"):
            in_string = not in_string
        elif not in_string and line.startswith("//", index):
            return line[:index]
    return line


def enum_value(match):
    # Component.Enum.Member, e.g. OSD.Type.Volume from Modules/OSD/OSD.qml
    component, enum, member = match.groups()
    for path in ROOT.glob(f"Modules/**/{component}.qml"):
        block = re.search(r"enum " + enum + r" \{([^}]*)\}", path.read_text(encoding="utf-8"))
        if block:
            members = [name.split("=")[0].strip() for name in block.group(1).split(",") if name.strip()]
            return str(members.index(member))
    raise KeyError(match.group(0))


def literal(source):
    text = source.strip()
    if text.startswith("(") and text.endswith(")"):
        text = text[1:-1]
    text = re.sub(r"\b([A-Z]\w*)\.([A-Z]\w*)\.([A-Z]\w*)\b", enum_value, text)
    # qmlformat allows trailing commas, JSON does not
    text = re.sub(r",(\s*[\]}])", r"\1", text)
    return json.loads(text)


def scalar(kind, raw):
    if raw in ("true", "false"):
        return raw == "true"
    if raw.startswith('"'):
        return json.loads(raw)  # QML string escapes match JSON's
    number = float(raw)
    return int(number) if kind == "int" else number


@functools.lru_cache(maxsize=None)
def defaults():
    """The default settings tree, as the shell's store snapshots it."""
    tree = {}
    stack = [tree]
    depth_stack = []
    depth = 0
    lines = iter(adapter_lines(SETTINGS_QML.read_text(encoding="utf-8")))
    for line in lines:
        match = OPEN_OBJECT.match(line)
        if match and depth >= 1:
            child = {}
            stack[-1][match.group(1)] = child
            stack.append(child)
            depth_stack.append(depth)
        prop = PROPERTY.match(line)
        if prop and depth >= 1:
            kind, name, raw = prop.groups()
            raw = strip_comment(raw).strip()
            if SCALAR.match(raw):
                stack[-1][name] = scalar(kind, SCALAR.match(raw).group(1))
            elif raw.startswith(("[", "({")):
                # Multi-line list or object literal: collect until brackets balance
                source = raw
                while source.count("[") + source.count("{") > source.count("]") + source.count("}"):
                    source += "\n" + strip_comment(next(lines))
                stack[-1][name] = literal(source)
                continue
        depth += line.count("{") - line.count("}")
        while depth_stack and depth <= depth_stack[-1]:
            depth_stack.pop()
            stack.pop()
    return tree


def lookup(path, tree=None):
    node = defaults() if tree is None else tree
    for part in path.split("."):
        if not isinstance(node, dict) or part not in node:
            raise KeyError(path)
        node = node[part]
    return node
