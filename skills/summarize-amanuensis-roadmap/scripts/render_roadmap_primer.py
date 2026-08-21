#!/usr/bin/env python3
"""Render Amanuensis ROADMAP.md as a self-contained visual HTML primer."""

from __future__ import annotations

import argparse
import hashlib
import html
import re
from dataclasses import dataclass, field
from pathlib import Path


HEADING = re.compile(r"^##\s+(.+?)\s*$")
CHECKBOX = re.compile(r"^-\s+\[([ xX])\]\s+(.+?)\s*$")
BULLET = re.compile(r"^-\s+(.+?)\s*$")
CODE = re.compile(r"`([^`]+)`")


@dataclass
class Item:
    text: str
    complete: bool | None


@dataclass
class Section:
    title: str
    items: list[Item] = field(default_factory=list)
    notes: list[str] = field(default_factory=list)

    @property
    def completed(self) -> int:
        return sum(item.complete is True for item in self.items)

    @property
    def open(self) -> int:
        return sum(item.complete is False for item in self.items)


def inline_markdown(value: str) -> str:
    escaped = html.escape(value)
    return CODE.sub(r"<code>\1</code>", escaped)


def parse_roadmap(source: str) -> tuple[str, list[Section]]:
    title = "Roadmap"
    sections: list[Section] = []
    current: Section | None = None
    paragraph: list[str] = []
    pending_item: Item | None = None

    def flush_paragraph() -> None:
        nonlocal paragraph
        if current and paragraph:
            current.notes.append(" ".join(part.strip() for part in paragraph))
        paragraph = []

    for raw_line in source.splitlines():
        if raw_line.startswith("# "):
            title = raw_line[2:].strip()
            continue
        heading = HEADING.match(raw_line)
        if heading:
            flush_paragraph()
            current = Section(heading.group(1))
            sections.append(current)
            pending_item = None
            continue
        if current is None:
            continue

        checkbox = CHECKBOX.match(raw_line)
        if checkbox:
            flush_paragraph()
            pending_item = Item(checkbox.group(2), checkbox.group(1).lower() == "x")
            current.items.append(pending_item)
            continue
        bullet = BULLET.match(raw_line)
        if bullet:
            flush_paragraph()
            pending_item = Item(bullet.group(1), None)
            current.items.append(pending_item)
            continue
        if pending_item and raw_line.startswith("  ") and raw_line.strip():
            pending_item.text += f" {raw_line.strip()}"
            continue
        pending_item = None
        if raw_line.strip():
            paragraph.append(raw_line.strip())
        else:
            flush_paragraph()

    flush_paragraph()
    return title, sections


def item_html(item: Item) -> str:
    if item.complete is True:
        state, icon, label = "done", "✓", "Completado"
    elif item.complete is False:
        state, icon, label = "open", "○", "Por hacer"
    else:
        state, icon, label = "later", "→", "Después"
    return (
        f'<li class="item {state}"><span class="marker" aria-hidden="true">{icon}</span>'
        f'<span><span class="sr-only">{label}: </span>{inline_markdown(item.text)}</span></li>'
    )


def section_html(section: Section) -> str:
    explicit = section.completed + section.open
    percent = round(section.completed * 100 / explicit) if explicit else 0
    counts = ""
    if explicit:
        counts = (
            f'<div class="section-progress"><progress value="{section.completed}" max="{explicit}" '
            f'aria-label="{html.escape(section.title)}: {percent}% completado"></progress>'
            f'<span>{section.completed}/{explicit}</span></div>'
        )
    notes = "".join(f'<p class="note">{inline_markdown(note)}</p>' for note in section.notes)
    items = "".join(item_html(item) for item in section.items)
    return (
        '<article class="section">'
        f'<header><h2>{inline_markdown(section.title)}</h2>{counts}</header>'
        f'{notes}<ul class="items">{items}</ul></article>'
    )


def render(source: str, source_name: str) -> str:
    title, sections = parse_roadmap(source)
    review_match = re.search(
        r"^Revisión de vigencia:\s*(.+?)(?=\n\n|\Z)",
        source,
        flags=re.MULTILINE | re.DOTALL,
    )
    review_note = ""
    if review_match:
        review_text = " ".join(review_match.group(1).split())
        review_note = f'<p class="source-note">Revisión de vigencia: {inline_markdown(review_text)}</p>'
    completed = sum(section.completed for section in sections)
    open_count = sum(section.open for section in sections)
    backlog = sum(item.complete is None for section in sections for item in section.items)
    explicit = completed + open_count
    percent = round(completed * 100 / explicit) if explicit else 0
    fingerprint = hashlib.sha256(source.encode("utf-8")).hexdigest()[:12]
    missing = [item for section in sections for item in section.items if item.complete is False]
    later = [item for section in sections for item in section.items if item.complete is None]

    missing_html = "".join(item_html(item) for item in missing)
    later_html = "".join(item_html(item) for item in later)
    sections_html = "".join(section_html(section) for section in sections)

    return f'''<!doctype html>
<html lang="es">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <meta name="color-scheme" content="light dark">
  <title>{html.escape(title)} · Primer visual</title>
  <style>
    :root {{ color-scheme: light dark; --bg: #f5f3ee; --ink: #17201d; --muted: #5e6a65; --surface: #fffdf8; --line: #d8d6ce; --done: #197a5b; --open: #b75b2a; --later: #5e6fa8; --soft-done: #e1f3eb; --soft-open: #f8e8df; --soft-later: #e8ecf8; }}
    @media (prefers-color-scheme: dark) {{ :root {{ --bg: #111714; --ink: #edf3ef; --muted: #aab6b0; --surface: #19211d; --line: #35423c; --done: #71d5af; --open: #f1a678; --later: #aebced; --soft-done: #173a2d; --soft-open: #43291d; --soft-later: #283252; }} }}
    * {{ box-sizing: border-box; }}
    body {{ margin: 0; background: var(--bg); color: var(--ink); font: 16px/1.5 ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; }}
    main {{ width: min(1180px, calc(100% - 32px)); margin: 0 auto; padding: 44px 0 64px; }}
    h1, h2, p {{ margin-top: 0; }}
    h1 {{ max-width: 760px; font-size: clamp(2rem, 6vw, 4.4rem); line-height: .98; letter-spacing: -.045em; margin-bottom: 18px; }}
    h2 {{ font-size: 1.05rem; line-height: 1.25; margin: 0; }}
    .eyebrow {{ color: var(--muted); font-size: .78rem; font-weight: 700; letter-spacing: .12em; text-transform: uppercase; }}
    .lede {{ max-width: 720px; color: var(--muted); font-size: 1.08rem; }}
    .source-note {{ color: var(--muted); font-size: .9rem; }}
    .summary {{ display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 12px; margin: 30px 0; }}
    .stat, .section, .focus {{ background: var(--surface); border: 1px solid var(--line); border-radius: 16px; }}
    .stat {{ padding: 18px; }}
    .stat strong {{ display: block; font-size: 2rem; line-height: 1; margin-bottom: 8px; }}
    .stat span {{ color: var(--muted); }}
    .done-text {{ color: var(--done); }} .open-text {{ color: var(--open); }} .later-text {{ color: var(--later); }}
    .overall {{ margin: 0 0 34px; }}
    progress {{ width: 100%; height: 10px; accent-color: var(--done); }}
    .focus-grid {{ display: grid; grid-template-columns: 1.35fr 1fr; gap: 16px; margin-bottom: 38px; }}
    .focus {{ padding: 22px; }}
    .focus h2 {{ font-size: 1.35rem; margin-bottom: 14px; }}
    .sections {{ display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 16px; }}
    .section {{ padding: 20px; }}
    .section header {{ display: flex; align-items: start; justify-content: space-between; gap: 16px; margin-bottom: 14px; }}
    .section-progress {{ min-width: 90px; display: flex; align-items: center; gap: 8px; color: var(--muted); font-size: .78rem; }}
    .items {{ list-style: none; padding: 0; margin: 0; display: grid; gap: 8px; }}
    .item {{ display: grid; grid-template-columns: 1.5rem 1fr; gap: 8px; align-items: start; padding: 9px 10px; border-radius: 10px; }}
    .item.done {{ background: var(--soft-done); }} .item.open {{ background: var(--soft-open); }} .item.later {{ background: var(--soft-later); }}
    .marker {{ font-weight: 800; text-align: center; }}
    .done .marker {{ color: var(--done); }} .open .marker {{ color: var(--open); }} .later .marker {{ color: var(--later); }}
    .note {{ color: var(--muted); font-size: .92rem; border-left: 3px solid var(--line); padding-left: 12px; }}
    code {{ font: .88em ui-monospace, SFMono-Regular, Consolas, monospace; }}
    footer {{ color: var(--muted); font-size: .8rem; margin-top: 30px; }}
    .sr-only {{ position: absolute; width: 1px; height: 1px; padding: 0; margin: -1px; overflow: hidden; clip: rect(0,0,0,0); white-space: nowrap; border: 0; }}
    @media (max-width: 760px) {{ main {{ width: min(100% - 20px, 680px); padding-top: 28px; }} .summary {{ grid-template-columns: repeat(2, 1fr); }} .focus-grid, .sections {{ grid-template-columns: 1fr; }} }}
  </style>
</head>
<body>
  <main>
    <p class="eyebrow">Amanuensis · mapa de producto</p>
    <h1>Qué existe, qué falta y qué viene después.</h1>
    <p class="lede">Una lectura visual del roadmap. El avance mide solamente los elementos explícitos de la lista; no representa esfuerzo, fechas ni porcentaje de lanzamiento.</p>
    {review_note}
    <section class="summary" aria-label="Resumen del roadmap">
      <div class="stat"><strong>{percent}%</strong><span>avance explícito</span></div>
      <div class="stat"><strong class="done-text">{completed}</strong><span>completados</span></div>
      <div class="stat"><strong class="open-text">{open_count}</strong><span>por hacer</span></div>
      <div class="stat"><strong class="later-text">{backlog}</strong><span>para después</span></div>
    </section>
    <div class="overall"><progress value="{completed}" max="{explicit}" aria-label="Avance general: {percent}%"></progress></div>
    <section class="focus-grid" aria-label="Trabajo pendiente">
      <div class="focus"><h2>Qué falta</h2><ul class="items">{missing_html}</ul></div>
      <div class="focus"><h2>Después</h2><ul class="items">{later_html}</ul></div>
    </section>
    <section class="sections" aria-label="Detalle por etapa">{sections_html}</section>
    <footer>Generado desde {html.escape(source_name)} · huella {fingerprint}</footer>
  </main>
</body>
</html>
'''


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("roadmap", type=Path)
    parser.add_argument("output", type=Path)
    parser.add_argument("--check", action="store_true", help="fail if output is stale")
    args = parser.parse_args()

    source = args.roadmap.read_text(encoding="utf-8")
    rendered = render(source, args.roadmap.as_posix())
    if args.check:
        if not args.output.exists() or args.output.read_text(encoding="utf-8") != rendered:
            parser.error(f"{args.output} is missing or stale; regenerate it")
        print(f"{args.output} is current")
        return 0

    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(rendered, encoding="utf-8")
    print(f"wrote {args.output}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
