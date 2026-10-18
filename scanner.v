module main

import os

const ignored_dirs = {
	'.git':          true
	'node_modules':  true
	'dist':          true
	'build':         true
	'target':        true
	'bin':           true
	'coverage':      true
	'.cache':        true
	'.tmp':          true
	'.next':         true
	'.nuxt':         true
	'.svelte-kit':   true
	'.turbo':        true
	'.parcel-cache': true
	'.pytest_cache': true
	'.mypy_cache':   true
	'.ruff_cache':   true
	'__pycache__':   true
	'.venv':         true
	'venv':          true
}

const ignored_file_names = {
	'.DS_Store': true
	'Thumbs.db': true
}

const ignored_file_extensions = {
	'.exe':         true
	'.dll':         true
	'.so':          true
	'.class':       true
	'.o':           true
	'.pyc':         true
	'.pyo':         true
	'.a':           true
	'.dylib':       true
	'.obj':         true
	'.lib':         true
	'.map':         true
	'.log':         true
	'.lockb':       true
	'.gitignore':   true
	'.atlasignore': true
}

struct FileScan {
	size      u64
	lines     int
	is_binary bool
}

// File analyzers receive borrowed chunks while Atlas counts lines and size.
// A chunk is only valid until the next read. Keep per-file results provisional
// until finish_file, because a later chunk can reveal a binary file or fail.
pub interface FileAnalyzer {
mut:
	start_file(path string, extension string)
	consume_chunk(chunk []u8)
	finish_file(file FileInfo)
	discard_file()
}

struct NoopFileAnalyzer {}

fn (mut _ NoopFileAnalyzer) start_file(_ string, _ string) {}

fn (mut _ NoopFileAnalyzer) consume_chunk(_ []u8) {}

fn (mut _ NoopFileAnalyzer) finish_file(_ FileInfo) {}

fn (mut _ NoopFileAnalyzer) discard_file() {}

struct ScanOptions {
pub mut:
	self_path    string
	max_depth    int // 0 = no limit
	read_content bool
}

enum ScanEntryKind {
	unknown
	file
	directory
	link
}

struct ScanEntry {
	name string
	kind ScanEntryKind
}

fn list_scan_entries(path string) ![]ScanEntry {
	$if linux {
		return list_scan_entries_linux(path)
	} $else {
		names := os.ls(path)!
		mut entries := []ScanEntry{cap: names.len}
		for name in names {
			entries << ScanEntry{ name: name }
		}
		return entries
	}
}

fn scan_file_contents[A](path string, relative_path string, extension string, mut buffer []u8, mut analyzer A) ?FileScan {
	mut file := os.open(path) or { return none }
	defer { file.close() }
	analyzer.start_file(relative_path, extension)

	mut total_size := u64(0)
	mut lines := 0
	mut last_byte := u8(0)

	for {
		m := file.read(mut buffer) or {
			if err is os.Eof {
				break
			}
			analyzer.discard_file()
			return none
		}
		if m == 0 {
			break
		}

		total_size += u64(m)
		for i in 0 .. m {
			bbyte := buffer[i]

			if bbyte == 0 {
				analyzer.discard_file()
				return FileScan{ is_binary: true }
			}

			if bbyte == `\n` {
				lines++
			}
		}
		last_byte = buffer[m - 1]
		analyzer.consume_chunk(buffer[..m])
	}

	if total_size > 0 && last_byte != `\n` {
		lines++
	}

	return FileScan{
		size:      total_size
		lines:     lines
		is_binary: false
	}
}

fn is_ignored_directory(name string) bool {
	return name in ignored_dirs
}

fn is_ignored_file(name string, ext string) bool {
	return name in ignored_file_names || ext in ignored_file_extensions
}

pub fn scan_project(root string) !Project {
	mut analyzer := NoopFileAnalyzer{}
	return scan_project_with_analyzer(root, mut analyzer)
}

pub fn scan_project_structure(root string, max_depth int) !Project {
	mut analyzer := NoopFileAnalyzer{}
	return scan_project_with_options(root, ScanOptions{ max_depth: max_depth, read_content: false }, mut analyzer)
}

// Consumers such as dependency analysis can inspect files during the scan
// without reopening them. Only finish_file confirms an accepted text file.
pub fn scan_project_with_analyzer[A](root string, mut analyzer A) !Project {
	return scan_project_with_options(root, ScanOptions{ read_content: true }, mut analyzer)
}

fn scan_project_with_options[A](root string, opts_in ScanOptions, mut analyzer A) !Project {
	if !os.exists(root) || !os.is_dir(root) {
		return error('invalid root')
	}

	abs_path := os.abs_path(root)
	mut opts := opts_in
	opts.self_path = os.abs_path(os.executable())

	mut project := Project{
		root: abs_path
		name: os.base(abs_path)
	}

	mut buffer := []u8{len: if opts.read_content { 65536 } else { 0 }}
	scan_directory(project.root, '', 0, opts, mut &project, mut buffer, mut analyzer)

	return project
}

fn scan_directory[A](path string, relative_path string, depth int, opts ScanOptions, mut ctx Project, mut buffer []u8, mut analyzer A) {
	entries := list_scan_entries(path) or { return }

	for entry in entries {
		full_path := os.join_path(path, entry.name)
		ext := os.file_ext(entry.name)
		if entry.kind == .link {
			continue
		}

		mut is_directory := entry.kind == .directory

		$if windows {
			if entry.kind == .unknown {
				if os.is_link(full_path) {
					continue
				}
				is_directory = os.is_dir(full_path)
			}
		} $else {
			if entry.kind == .unknown {
				metadata := os.lstat(full_path) or { continue }
				kind := metadata.get_filetype()
				if kind == .symbolic_link {
					continue
				}
				is_directory = kind == .directory
			}
		}

		if is_directory {
			if is_ignored_directory(entry.name) {
				continue
			}

			dir_path := os.join_path(relative_path, entry.name)
			ctx.directories << dir_path

			if opts.max_depth <= 0 || depth + 1 < opts.max_depth {
				scan_directory(full_path, dir_path, depth + 1, opts, mut ctx, mut buffer, mut analyzer)
			}

			continue
		}

		if full_path == opts.self_path {
			continue
		}

		if is_ignored_file(entry.name, ext) {
			continue
		}

		file_path := os.join_path(relative_path, entry.name)

		if !opts.read_content {
			ctx.files << FileInfo{
				path: file_path
			}
			continue
		}

		scan := scan_file_contents(full_path, file_path, ext, mut buffer, mut analyzer) or { continue }
		if scan.is_binary {
			continue
		}

		file_info := FileInfo{
			path:      file_path
			extension: ext
			size:      scan.size
			lines:     scan.lines
		}
		ctx.files << file_info
		analyzer.finish_file(file_info)
	}
}

