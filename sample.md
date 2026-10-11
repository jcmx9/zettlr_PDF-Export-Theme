---
title: Source — sample document
tags: [typora, theme]
---

# Heading level 1

Body text is set in **Source Sans 3**, headings in *Source Serif 4* and code in `Source Code Pro`. This paragraph contains a [link](https://typora.io), ==highlighted text==, ~~strikethrough~~, a keyboard shortcut <kbd>⌘</kbd> + <kbd>⇧</kbd> + <kbd>P</kbd> and a footnote[^1].

## Heading level 2

A paragraph directly below a second-level heading. Umlauts and special characters: äöü ÄÖÜ ß — „Anführungszeichen“ … € 1.234,56.

### Heading level 3

Headings from level 4 onward use the body size and differ only in weight and style.

#### Heading level 4

Bold serif at body size.

##### Heading level 5

Semibold italic serif at body size.

###### Heading level 6

Muted italic serif at body size.

## Stacked headings
### Directly followed by a subheading

The gap between stacked headings is reduced.

## Lists

- Unordered item
- Second item with a longer text that wraps onto the next line to show the line height inside list items.
  - Nested item
  - Another nested item

1. First step
2. Second step
3. Third step

- [x] Completed task
- [ ] Open task

## Quote

> Typography is what language looks like.
>
> > A nested quote inside the first one.

## Alerts

> [!NOTE]
> Useful information the reader should notice.

> [!TIP]
> A helpful suggestion.

> [!IMPORTANT]
> Key information needed to succeed.

> [!WARNING]
> Urgent information that needs attention.

> [!CAUTION]
> Possible negative consequences of an action.

## Code

Inline code like `font-family: var(--font-mono);` sits within the text.

```python
from pathlib import Path


def count_words(path: Path) -> int:
    """Count the words in a text file."""
    # Read the whole file at once
    text = path.read_text(encoding="utf-8")
    return len(text.split())


print(count_words(Path("sample.md")), 42, True)
```

```css
:root {
    --accent: #b5452b; /* rust */
}
```

## Table

| Font            | Role     | Weights  |
| :-------------- | :------- | -------: |
| Source Serif 4  | Headings | 200–900  |
| Source Sans 3   | Body     | 200–900  |
| Source Code Pro | Code     | 200–900  |

## Math

Inline math $e^{i\pi} + 1 = 0$ and a block:

$$
\int_0^\infty e^{-x^2}\,dx = \frac{\sqrt{\pi}}{2}
$$

---

## Table of contents

[TOC]

[^1]: Footnotes are set smaller and muted.
