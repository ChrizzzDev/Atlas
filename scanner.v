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

struct ScanOptions {
pub mut:
	self_path    string
	max_depth    int // 0 = no limit
	read_content bool
}

fn scan_file_contents(path string, mut buffer []u8) ?FileScan {
	mut file := os.open(path) or { return none }
	defer { file.close() }

	mut total_size := u64(0)
	mut lines := 0
	mut last_byte := u8(0)

	for {
		m := file.read(mut buffer) or { break }
		if m == 0 {
			break
		}

		total_size += u64(m)
		for i in 0 .. m {
			bbyte := buffer[i]

			if bbyte == 0 {
				return FileScan{ is_binary: true }
			}

			if bbyte == `\n` {
				lines++
			}

			last_byte = buffer[m - 1]
		}
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
	return scan_project_with_options(root, ScanOptions{ read_content: true })
}

pub fn scan_project_structure(root string, max_depth int) !Project {
	return scan_project_with_options(root, ScanOptions{ max_depth: max_depth, read_content: false })
}

fn scan_structure_directory(path string, relative_path string, depth int, opts ScanOptions, mut ctx Project, mut buffer []u8) {
	entries := os.ls(path) or { return }

	for entry in entries {
		full_path := os.join_path(path, entry)
		ext := os.file_ext(entry)

		if os.is_link(full_path) {
			continue
		}

		if os.is_dir(full_path) {
			if is_ignored_directory(entry) {
				continue
			}

			dir_path := os.join_path(relative_path, entry)
			ctx.directories << dir_path

			if opts.max_depth <= 0 || depth + 1 < opts.max_depth {
				scan_structure_directory(full_path, dir_path, depth + 1, opts, mut ctx, mut buffer)
			}
			continue
		}

		if full_path == opts.self_path {
			continue
		}

		if is_ignored_file(entry, ext) {
			continue
		}

		file_path := os.join_path(relative_path, entry)

		if !opts.read_content {
			ctx.files << FileInfo{
				path: file_path
			}
			continue
		}

		scan := scan_file_contents(full_path, mut buffer) or { continue }
		if scan.is_binary {
			continue
		}

		ctx.files << FileInfo{
			path:      file_path
			extension: ext
			size:      scan.size
			lines:     scan.lines
		}
	}
}

fn scan_project_with_options(root string, opts_in ScanOptions) !Project {
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
	scan_directory(project.root, '', 0, opts, mut &project, mut buffer)

	return project
}

fn scan_directory(path string, relative_path string, depth int, opts ScanOptions, mut ctx Project, mut buffer []u8) {
	entries := os.ls(path) or { return }

	for entry in entries {
		full_path := os.join_path(path, entry)
		ext := os.file_ext(entry)

		mut is_directory := false

		$if windows {
			if os.is_link(full_path) {
				continue
			}
			is_directory = os.is_dir(full_path)
		} $else {
			metadata := os.lstat(full_path) or { continue }
			kind := metadata.get_filetype()
			if kind == .symbolic_link {
				continue
			}
			is_directory = kind == .directory
		}

		if is_directory {
			if is_ignored_directory(entry) {
				continue
			}

			dir_path := os.join_path(relative_path, entry)
			ctx.directories << dir_path

			if opts.max_depth <= 0 || depth < opts.max_depth {
				scan_directory(full_path, dir_path, depth + 1, opts, mut ctx, mut buffer)
			}

			continue
		}

		if full_path == opts.self_path {
			continue
		}

		if is_ignored_file(entry, ext) {
			continue
		}

		file_path := os.join_path(relative_path, entry)

		if !opts.read_content {
			ctx.files << FileInfo{
				path: file_path
			}
			continue
		}

		scan := scan_file_contents(full_path, mut buffer) or { continue } // couldn't read
		if scan.is_binary {
			continue
		}

		ctx.files << FileInfo{
			path:      file_path
			extension: ext
			size:      scan.size
			lines:     scan.lines
		}
	}
}
