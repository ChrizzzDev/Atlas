# Changelog

All notable changes to Atlas will be documented here.
## [0.2.1] - 2026-10-16

### Added
- File analyzer interface for processing file contents during the project scan, preparing Atlas for dependency analysis without requiring a second file read.

### Changed
- Use directory entry types on Linux to avoid unnecessary file metadata calls during scans.
- Introduce buffered tree output to significantly reduce individual write system calls.
- Stop directory traversal once the requested tree depth is reached.
- Index file extensions for faster classification while preserving category precedence.
- Optimize tree construction by reducing redundant path processing and child lookups.
- Reduce unnecessary filesystem metadata queries, improving scanning efficiency.

### Performance
- **Reduced total system calls by 74.51%** during full tree generation on the Flutter SDK (77,502 → 19,756).
- **Reduced `write()` calls by 99.95%** through buffered tree output (38,796 → 19).
- **Reduced `newfstatat()` calls by 99.96%** by avoiding redundant metadata queries (19,443 → 7).
- Reduced execution time for tree generation by approximately **7%** in earlier benchmarks.
- Reduced CPU instructions and cycles during depth-limited tree generation.
- Preserved identical tree output while improving execution efficiency.

### Fixed
- Discard files when a read fails instead of reporting partial size and line counts.

> **Benchmark notes:** System call measurements were collected using `strace -c` on Linux while generating the complete Flutter SDK project tree (`atlas tree -d 0`). Execution-time improvements refer to earlier Hyperfine measurements and may differ under the latest implementation. System call reductions do not directly represent equivalent reductions in execution time.

## [0.2.0] - 2026-10-15

### Added

- Project tree command with configurable depth
- File type distribution and top-level directory summaries
- JSON output and optional extension statistics
- Improved filtering for generated files and directories

## [0.1.1] - 2026-09-18
- Add formatting for LOC (according to ISO 80000-1:2022)
- Add some config files to ignored files (.editorconfig, .gitattributes, .gitignore)

## [0.1.0] - 2026-09-18

### Added

- Recursive project scanning
- Project name and root detection
- File and directory statistics
- Project size calculation
- Physical line counting
- Programming language detection
- Language statistics
- Human-readable terminal output
- Ignored directories for generated/dependency files
- Filtering of common binary artifacts
- Handling of empty projects and filesystem errors
