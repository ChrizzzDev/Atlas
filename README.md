# Atlas

**Atlas is a command-line tool for exploring and understanding software projects.**

Atlas analyzes a codebase and builds a map of its **structure, composition, and internal relationships**, giving developers a quick overview of what a project contains and how it is organized.

<p align="center">
  <img src="https://img.shields.io/badge/status-in_development-orange?style=for-the-badge" alt="Status">
  <img src="https://img.shields.io/badge/version-0.1.0-blue?style=for-the-badge" alt="Version">
  <img src="https://img.shields.io/badge/language-Vlang-5C6BC0?style=for-the-badge&logo=v&link=google.com" alt="V">
  <img src="https://img.shields.io/badge/license-MIT-green?style=for-the-badge" alt="License">
</p>

---

## What is Atlas?

Large codebases can become difficult to understand.

Before changing a project, developers often need to answer simple questions:

* How large is this project?
* What languages does it use?
* How many files does it contain?
* Where is the code located?
* What parts of the project are the largest?
* How are its components related?

Atlas is designed to answer these questions from the command line.

Give Atlas a project directory:

```bash
atlas .
```

And it builds a high-level map of the codebase.

### Example

```text
ATLAS 🗺️
────────────────────
Project      atlas
Root         /home/ttomer/projects/atlas
Files        8
Directories  0
Size         20.94 KB
Lines        1 068

Languages
  V      5 files (62.50%)
  Other  3 files (37.50%)
```

The goal is simple:

> **Understand the project before diving into the code.**

---

## Why Atlas?

Modern development environments provide powerful tools for working with individual files and symbols.

Atlas approaches the problem from a different direction.

Instead of asking:

> "What does this function do?"

Atlas starts with:

> **"What is this project made of, and how is it put together?"**

Atlas is not intended to replace:

* IDEs
* Linters
* Formatters
* Static analysis platforms
* Code review tools
* Version control systems

It is a lightweight **codebase exploration and intelligence tool**.

---

## Features

### Current

Atlas `v0.1` currently provides:

* Project discovery
* File scanning
* Directory scanning
* File count
* Directory count
* Project size
* Physical line count
* Programming language detection
* Language statistics
* Human-readable terminal output
* Basic JSON output infrastructure

### Coming later

Atlas will progressively understand more about the codebase:

* Project structure visualization
* Import and dependency analysis
* Symbol detection
* Functions and classes
* Internal relationships
* Dependency graphs
* Circular dependency detection
* Codebase hotspots
* Route detection
* Machine-readable project information
* File explanations

The long-term goal is to move from simply **scanning a project** to actually **mapping it**.

---

# Installation

Atlas is currently in early development.

## Requirements

You will need:

* [V](https://vlang.io/)
* Git

Check your V installation:

```bash
v version
```

## Clone the repository

```bash
git clone https://github.com/ChrizzzDev/atlas.git
cd atlas
```

## Build Atlas

```bash
v .
```

This produces the Atlas executable in the project directory.

You can then run:

```bash
./atlas .
```

### Development mode

Alternatively, run Atlas directly through V:

```bash
v run .
```

---

# Usage

Atlas works directly from the command line.

## Analyze the current directory

```bash
atlas .
```

## Analyze another project

```bash
atlas /path/to/project
```

For example:

```bash
atlas ~/projects/seyfert
```

Atlas will scan the target project and display a summary of its composition.

---

## Output

Atlas separates its analysis into several pieces of information.

### Project information

```
Project      seyfert
Root         /home/ttomer/projects/seyfert
Files        416
Directories  49
Size         2.59 MB
Lines        74 144
```

### Languages

```
Languages
  TypeScript  311 files (74.76%)
  Other       103 files (24.76%)
  JavaScript  2 files (0.48%)
```

As Atlas evolves, these sections will become increasingly detailed.

---

# Supported languages

Atlas currently recognizes the following extensions:

<center>
  <table>
    <thead>
      <tr>
        <th>Language</th>
        <th>Extensions</th>
      </tr>
    </thead>
    <tbody>
      <tr>
        <td>V</td>
        <td><code>.v</code></td>
      </tr>
      <tr>
        <td>TypeScript</td>
        <td><code>.ts</code>, <code>.tsx</code></td>
      </tr>
      <tr>
        <td>JavaScript</td>
        <td><code>.js</code>, <code>.jsx</code></td>
      </tr>
      <tr>
        <td>Go</td>
        <td><code>.go</code></td>
      </tr>
      <tr>
        <td>Rust</td>
        <td><code>.rs</code></td>
      </tr>
      <tr>
        <td>Java</td>
        <td><code>.java</code></td>
      </tr>
      <tr>
        <td>C#</td>
        <td><code>.cs</code></td>
      </tr>
      <tr>
        <td>C++</td>
        <td><code>.cpp</code></td>
      </tr>
      <tr>
        <td>C</td>
        <td><code>.c</code></td>
      </tr>
      <tr>
        <td>Python</td>
        <td><code>.py</code></td>
      </tr>
      <tr>
        <td>PHP</td>
        <td><code>.php</code></td>
      </tr>
      <tr>
        <td>Kotlin</td>
        <td><code>.kt</code></td>
      </tr>
      <tr>
        <td>Swift</td>
        <td><code>.swift</code></td>
      </tr>
    </tbody>
  </table>
</center>

You can check out all the supported languages in by clicking [here](languages.v)

---

# Roadmap

Atlas is being developed incrementally.

The project intentionally starts with simple and deterministic analysis before introducing deeper code intelligence.

```
      ATLAS
        │
        ▼
┌───────────────┐
│     v0.1      │
│    Explorer   │ 
└───────┬───────┘
        │
        ▼
┌───────────────┐
│     v0.2      │
│   Structure   │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│     v0.3      │
│  Dependencies │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│     v0.4      │
│    Symbols    │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│     v0.5+     │
│ Relationships │
└───────┬───────┘
        │
        ▼
┌───────────────┐
│     v1.0      │
│     Atlas     │
└───────────────┘
```

### v0.1 • Explorer

- [x] Scan project
- [x] Detect files
- [x] Detect directories
- [x] Detect programming languages
- [x] Calculate project size
- [x] Count physical lines
- [x] Display language statistics
- [ ] Improve generated-file detection
- [ ] Improve edge-case handling

### v0.2 • Structure

- [ ] Project tree
- [ ] Directory hierarchy
- [ ] `atlas tree`
- [ ] File type distribution
- [ ] Better project structure summaries

### v0.3 • Dependencies

- [ ] Import detection
- [ ] Export detection
- [ ] Internal dependencies
- [ ] External dependencies
- [ ] `atlas deps`

### v0.4 • Symbols

- [ ] Function detection
- [ ] Class detection
- [ ] Struct detection
- [ ] Constants
- [ ] Methods
- [ ] Symbol relationships
- [ ] `atlas symbols`

### v0.5+ • Relationships

- [ ] Dependency graphs
- [ ] Circular dependency detection
- [ ] Codebase hotspots
- [ ] Relationship analysis
- [ ] Route detection
- [ ] `atlas graph`
- [ ] `atlas cycles`
- [ ] `atlas hotspots`

### v1.0 • Codebase Intelligence

The first stable release aims to provide a complete high-level representation of a software project.

Potential commands:

```md
atlas .
atlas tree
atlas stats
atlas deps
atlas symbols
atlas graph
atlas hotspots
atlas cycles
atlas routes
atlas explain
```

---

# Architecture

Atlas is designed around a pipeline where each stage adds another layer of understanding.

```
┌──────────────┐
│  Filesystem  │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│   Scanner    │
└──────┬───────┘
       │
       ▼
┌───────────────┐
│ Project Model │
└──────┬────────┘
       │
       ▼
┌──────────────┐
│   Analyzers  │
├──────────────┤
│ Files        │
│ Dependencies │
│ Symbols      │
│ Graph        │
└──────┬───────┘
       │
       ▼
┌──────────────┐
│    Output    │
└──────────────┘
```

This architecture allows Atlas to become more sophisticated without turning the core scanner into a large monolithic system.

---

# Project Structure

The current project is intentionally small:

```text
atlas/
├── main.v
├── output.v
├── project.v
├── scanner.v
├── languages.v
├── v.mod
├── README.md
└── ...
```

Each component has a focused responsibility.

<table>
  <thead>
    <tr>
      <th>File</th>
      <th>Responsibility</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td><code>main.v</code></td>
      <td>CLI entry point</td>
    </tr>
    <tr>
      <td><code>scanner.v</code></td>
      <td>Filesystem scanning</td>
    </tr>
    <tr>
      <td><code>project.v</code></td>
      <td>Project data structures</td>
    </tr>
    <tr>
      <td><code>languages.v</code></td>
      <td>Language detection</td>
    </tr>
    <tr>
      <td><code>output.v</code></td>
      <td>Terminal output and formatting</td>
    </tr>
    <tr>
      <td><code>v.mod</code></td>
      <td>V module definition</td>
    </tr>
  </tbody>
</table>

As Atlas grows, the internal architecture will evolve with it.

---

# Design Philosophy

Atlas follows a few principles.

### Useful before intelligent

Atlas should provide useful information without requiring AI, remote services, or external infrastructure.

The first layer of Atlas is therefore: **deterministic, local, and explainable.**

### Progressive understanding

Atlas does not need to understand everything about a codebase immediately.

It starts with:

```text
Files
  ↓
Structure
  ↓
Dependencies
  ↓
Symbols
  ↓
Relationships
  ↓
Understanding
```

Each layer builds on the previous one.

### CLI first

Atlas is designed to work naturally from a terminal.
* No dashboard.
* No web server.
* No database.
* No account.
* No unnecessary infrastructure.

Just point it at a project and inspect the result.

### Small core

The project should remain lightweight enough to run comfortably on a developer's machine.

Complexity should be introduced because it provides meaningful information, not simply because it is technically possible.

---

# Future: `atlas explain`

One of Atlas's long-term goals is to provide structural explanations of files and components.

For example:

```text
scanner.v
────────────────────────────────

Purpose
  Project filesystem scanner

Language
  V

Size
  184 lines
  4.82 KB

Imports
  os
  io

Symbols
  scan_project()
  scan_directory()
  count_lines()

Dependencies
  project.v
  languages.v

Used by
  main.v

Structure
  3 functions
  0 structs
  0 constants

Behavior
  • Traverses directories recursively
  • Identifies files and directories
  • Collects file size and line count
  • Builds the Project representation
```

This does not necessarily require an AI model.

Atlas can derive a surprising amount of information from the structure of a program itself.

If local AI capabilities are introduced in the future, they can remain an optional layer rather than becoming a requirement for the core tool.

---

# Development

Run Atlas directly from the repository:

```bash
v run .
```

Build it:

```bash
v .
```

The project is written in **V** and currently keeps its source files in the module root.

---

# Contributing

Atlas is currently a personal project in active development.

Contributions, ideas, bug reports, and discussions are welcome as the project matures.

Before submitting a larger change, consider opening an issue to discuss the approach first.

When contributing, try to keep changes:

* Focused
* Small
* Deterministic
* Easy to understand
* Consistent with Atlas's CLI-first philosophy

---

# License

Atlas is released under the **MIT License**.

See [`LICENSE`](LICENSE) for the complete license text.

---

<p align="center">
  <strong>Atlas 🗺️</strong>
  <br>
  <sub>Map your codebase. Understand your project.</sub>
</p>
