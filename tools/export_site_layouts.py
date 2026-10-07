"""Write the built-in layouts from the iKeypadShared profile sources into docs/index.html.

Run from the repository root: ``python3 tools/export_site_layouts.py``. Each app panel in the page
holds a ``<!-- layout:<id> --> ... <!-- /layout -->`` block that this script replaces with that
app's real keys and shortcuts as static HTML, so the page works without JavaScript. Re-run it
whenever a layout changes.
"""
import html
import re
import sys

SOURCES = ["Packages/iKeypadShared/Sources/iKeypadShared/DefaultProfiles.swift",
           "Packages/iKeypadShared/Sources/iKeypadShared/PopularAppProfiles.swift"]
PAGE = "docs/index.html"
SLOTS = 15
# U+FE0E forces text presentation; without it browsers render ↩ as an emoji keycap.
GLYPHS = {"tab": "⇥\ufe0e", "return": "↩\ufe0e", "enter": "↩\ufe0e", "escape": "⎋\ufe0e", "esc": "⎋\ufe0e", "space": "Space",
          "up": "↑", "down": "↓", "left": "←", "right": "→"}
MODIFIER_ORDER = [(".control", "⌃"), (".option", "⌥"), (".shift", "⇧"), (".command", "⌘")]
# Site key id -> Swift factory, in the order the app keys appear on the page.
APPS = [("xcode", "makeXcodeProfile"), ("terminal", "makeTerminalProfile"), ("vscode", "makeVSCodeProfile"),
        ("safari", "makeSafariProfile"), ("zoom", "makeZoomProfile"), ("whatsapp", "makeWhatsAppProfile"),
        ("telegram", "makeTelegramProfile"), ("macdown", "makeMacDownProfile"), ("word", "makeWordProfile"), ("system", "makeDefaultFallbackProfile")]


def shortcut(action_kind, args):
    """Render a hotkey action the way the app does (⌃⌥⇧⌘ then the key); None for other actions."""
    if action_kind != ".hotkey":
        return None
    key = re.search(r'key: "((?:[^"\\]|\\.)*)"', args).group(1).replace("\\\\", "\\")
    mods = re.search(r"modifiers: \[(.*?)\]", args).group(1)
    return "".join(glyph for mod, glyph in MODIFIER_ORDER if mod in mods) + GLYPHS.get(key, key.upper())


def main():
    swift = "".join(open(path).read() for path in SOURCES)
    factories = {m.group(1): m.group(2) for m in re.finditer(
        r"func (make\w+)\(.*?\)\s*->\s*DeckProfile \{(.*?)\n    \}\n", swift, re.S)}
    out = {}
    for site_id, factory in APPS:
        body = factories[factory]
        name = re.search(r'appName: (?:"([^"]+)"|name)', body).group(1) or "Safari, Chrome, Arc"
        keys = [{"label": label, "shortcut": shortcut(kind, args), "role": role, "hold": bool(hold)}
                for label, kind, args, role, hold in re.findall(
                    r'label: "([^"]+)".*?action: (\.[a-zA-Z]+)\(?(.*?)\)?,?\n\s*role: \.(\w+)(,\s*requiresConfirm: true)?',
                    body, re.S)]
        if not keys:
            sys.exit(f"no keys parsed for {factory}")
        out[site_id] = {"app": name, "keys": keys}
    page = open(PAGE).read()
    for site_id, layout in out.items():
        block = re.compile(r"<!-- layout:%s -->.*?<!-- /layout -->" % site_id, re.S)
        if not block.search(page):
            sys.exit(f"{PAGE} has no layout block for {site_id}")
        page = block.sub(lambda _: render(site_id, layout), page)
    open(PAGE, "w").write(page)
    print(f"wrote {PAGE}: " + ", ".join(f"{v['app']} ({len(v['keys'])})" for v in out.values()))


def render(site_id, layout):
    """Static HTML for one app panel: an intro line and a 15-slot deck of that app's keys."""
    # The fallback layout is named "System" in code but applies to every app without its own.
    names = "any other app" if site_id == "system" else re.sub(r", ([^,]+)$", r" or \1", layout["app"])
    cells = []
    for i in range(SLOTS):
        if i >= len(layout["keys"]):
            cells.append('<div class="mini-key empty" aria-hidden="true"></div>')
            continue
        key = layout["keys"][i]
        hint = f"Hold · {key['shortcut'] or ''}" if key["hold"] else (key["shortcut"] or "Runs on Mac")
        cells.append(f'<div class="mini-key" role="listitem" data-role="{key["role"]}">'
                     f'<b>{html.escape(key["label"])}</b><span>{html.escape(hint)}</span></div>')
    return (f"<!-- layout:{site_id} -->\n          <p>When {html.escape(names)} is in front, the iPad shows these keys "
            f"and the shortcut each one sends.</p>\n          <div class=\"mini-deck\" role=\"list\">"
            + "".join(cells) + "</div>\n          <!-- /layout -->")

if __name__ == "__main__":
    main()
