// FILE: ~/.emacs.d/templates/default.typ

// TEMPLATE
// To switch to light mode, comment out the dark mode colors below

// Document setup
#set document(
  title: "<<TITLE>>",
  author: "Erico Silva"
)

// DARK MODE COLORS
#let page-bg = rgb("#1e1e1e")
#let text-color = rgb("#e0e0e0")
#let heading-color = rgb("#ffffff")
#let link-color = rgb("#6db3f2")
#let code-bg = rgb("#2d2d2d")
#let border-color = rgb("#404040")

// LIGHT MODE COLORS (uncomment to use)
// #let page-bg = white
// #let text-color = black
// #let heading-color = black
// #let link-color = rgb("#0066cc")
// #let code-bg = rgb("#f5f5f5")
// #let border-color = rgb("#d0d0d0")

#set page(
  paper: "a4",
  margin: (x: 2.5cm, y: 3cm),
  numbering: "1",
  number-align: center,
  fill: page-bg,
)

#set text(
  font: "Concrete Math",
  size: 11pt,
  lang: "en",
  fill: text-color,
)

// Math font (if different from main font)
#show math.equation: set text(font: "Concrete Math", fill: text-color)

#set par(
  justify: true,
  leading: 0.65em,
)

#set heading(
  numbering: "1.",
)

#show heading: set text(fill: heading-color)

#set math.equation(numbering: "(1)")

#show link: set text(fill: link-color)

#show raw.where(block: true): block.with(
  fill: code-bg,
  inset: 10pt,
  radius: 4pt,
  stroke: border-color,
)

#show raw.where(block: false): box.with(
  fill: code-bg,
  inset: (x: 3pt, y: 0pt),
  outset: (y: 3pt),
  radius: 2pt,
)

// Theorem environment
#let theorem(title, content) = {
  block(
    fill: code-bg,
    inset: 10pt,
    radius: 2pt,
    stroke: (left: 3pt + link-color),
    [
      #text(weight: "medium", fill: heading-color)[Theorem #title.] #content
    ]
  )
}

// Title and author information
#align(left)[
  #text(size: 15pt, weight: "bold", fill: heading-color)[
    <<TITLE>>
  ]
  
  #v(1em)
  
  #text(size: 12pt)[
    Erico Silva#footnote[DeCODE Genetics. Email: #link("mailto:erics@decode.is")[#text(font: "Courier New", fill: link-color)[erics\@decode.is]]]
  ]
]

#v(2em)

// Main content starts here
= Introduction

Introduction here. For manual references, cite them like [1] or [2]. Can reference equations like @eq:example below.

// Note: The @ syntax only works for equations, figures, tables, and .bib file entries

= Mathematical Content

Here's an example of inline math: $alpha + beta = gamma$. And here's a display equation:

$
  nabla dot bold(E) = rho / epsilon_0
$ <eq:example>

== Subsection Example

You can create subsections as needed. Here's another equation:

$
  integral_0^infinity e^(-x^2) dif x = sqrt(pi) / 2
$

== Theorems

#theorem[
  (Pythagorean)
][
  For a right triangle with legs $a$ and $b$ and hypotenuse $c$:
  $ a^2 + b^2 = c^2 $
]

= Tables and Figures

#figure(
  table(
    columns: (1fr, 1fr, 1fr),
    inset: 10pt,
    align: horizon,
    fill: (x, y) => if y == 0 { code-bg } else { none },
    stroke: border-color,
    [*Column 1*], [*Column 2*], [*Column 3*],
    [Data 1], [Data 2], [Data 3],
    [Data 4], [Data 5], [Data 6],
  ),
  caption: [Example table],
) <tab:example>

Refer to tables like this: See @tab:example for details.

= Code Examples

```python
def example_function(x):
    """Example code block"""
    return x**2 + 2*x + 1
```
