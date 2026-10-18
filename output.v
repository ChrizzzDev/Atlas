module main

import term
import json
import strconv

struct Info {
	label string
	value string
}

struct JsonOutput {
	project     string
	root        string
	files       int
	directories int
	size        i64
	lines       int
	languages   []LanguageStats
	file_types  map[string]int
}

pub fn output(project Project, format string, stats []ExtensionStat, show_extensions bool) {
	match format {
		'', 'human' {
			print_header()
			human_readable_output(project, stats, show_extensions)
		}
		'json' {
			json_output(project)
		}
		else {
			println("Unknown output format: '${format}'")
		}
	}
}

fn print_header() {
	println(term.bold(term.bright_blue('ATLAS 🗺️')))
	println(term.gray('${'─':20r}'))
}

fn human_readable_output(project Project, stats []ExtensionStat, show_extensions bool) {
	mut project_size := i64(0)
	mut loc := 0
	mut used_languages := map[string]int{}

	for file in project.files {
		project_size += file.size
		loc += file.lines

		language := language_from_extension(file.extension)
		used_languages[language.name]++
	}

	print_info([
		Info{ label: 'Project', value: project.name }
		Info{ label: 'Root', value: project.root }
		Info{ label: 'Files', value: strconv.format_thousands(project.files.len, ' ') }
		Info{ label: 'Directories', value: strconv.format_thousands(project.directories.len, ' ') }
		Info{ label: 'Size', value: format_size(project_size) }
		Info{ label: 'Lines', value: strconv.format_thousands(loc, ' ') },
	])

	// Languages
	println('')
	println(term.bold('Languages'))

	if project.files.len <= 0 {
		println(term.warn_message('    ! No recognized files'))
	} else {
		langs := get_language_stats(used_languages, project.files.len)
		print_languages(langs)
	}

	// File Types
	file_type_dist := get_file_type_distribution(project)
	print_file_type_distribution(file_type_dist, project.files.len)

	// Directory Structure
	print_directory_summary(project)

	// Extensions
	if show_extensions {
		println('')
		println(term.bold('Extensions'))

		if stats.len > 0 {
			print_extensions(stats)
		}
	}
}

fn json_output(project Project) {
	mut project_size := i64(0)
	mut loc := 0
	mut used_languages := map[string]int{}

	for file in project.files {
		project_size += file.size
		loc += file.lines

		language := language_from_extension(file.extension)
		used_languages[language.name]++
	}

	file_type_dist := get_file_type_distribution(project)

	println(json.encode(&JsonOutput{
		project:     project.name
		root:        project.root
		files:       project.files.len
		directories: project.directories.len
		size:        project_size
		lines:       loc
		languages:   get_language_stats(used_languages, project.files.len)
		file_types:  file_type_dist
	}))
}

fn print_info(items []Info) {
	mut width := 0

	for item in items {
		if item.label.len > width {
			width = item.label.len
		}
	}

	for item in items {
		padding := ' '.repeat(width - item.label.len + 2)
		println('${term.bold(item.label)}${padding}${item.value}')
	}
}

fn print_languages(stats []LanguageStats) {
	mut width := 0

	for lang in stats {
		if lang.name.len > width {
			width = lang.name.len
		}
	}

	for lang in stats {
		padding := ' '.repeat(width - lang.name.len + 2)
		files := if lang.files == 1 { 'file' } else { 'files' }

		println('  ${lang.name}${padding}${strconv.format_thousands(lang.files, ' ')} ${files} (${lang.percent:.2f}%)')
	}
}

fn print_extensions(stats []ExtensionStat) {
	mut width := 0

	for stat in stats {
		extension := if stat.extension == '' { '[no extension]' } else { stat.extension }
		if extension.len > width {
			width = extension.len
		}
	}

	for stat in stats {
		extension := if stat.extension == '' { '[no extension]' } else { stat.extension }
		padding := ' '.repeat(width - extension.len + 2)
		files := if stat.files == 1 { 'file' } else { 'files' }

		println('  ${extension}${padding}${strconv.format_thousands(stat.files, ' ')} ${files}')
	}
}

fn print_directory_summary(project Project) {
	if project.directories.len == 0 {
		return
	}

	mut dir_stats := map[string]DirStat{}

	for file in project.files {
		top_dir := top_level_directory(file.path)
		if top_dir == '' {
			continue
		}
		mut stat := dir_stats[top_dir] or { DirStat{ name: top_dir } }
		stat.files++
		stat.size += file.size
		stat.lines += file.lines
		dir_stats[top_dir] = stat
	}

	for dir in project.directories {
		top_dir := top_level_directory(dir)
		if top_dir == '' {
			continue
		}
		mut stat := dir_stats[top_dir] or { DirStat{ name: top_dir } }
		dir_stats[top_dir] = stat
	}

	mut sorted_dirs := []DirStat{}
	for _, stat in dir_stats {
		sorted_dirs << stat
	}

	sorted_dirs.sort_with_compare(fn (a &DirStat, b &DirStat) int {
		if a.files != b.files {
			return b.files - a.files
		}
		return if a.name < b.name { -1 } else { 1 }
	})

	println('')
	println(term.bold('Directories'))

	mut width := 0
	for d in sorted_dirs {
		if d.name.len > width {
			width = d.name.len
		}
	}

	for d in sorted_dirs {
		if d.files == 0 && d.name != '.' {
			continue
		}
		padding := ' '.repeat(width - d.name.len + 2)
		size_str := format_size(d.size)
		println('  ${d.name}${padding}${strconv.format_thousands(d.files, ' ')} files  ${size_str}  ${d.lines} lines')
	}
}

fn top_level_directory(path string) string {
	separator := path.index_u8(47)
	if separator == -1 {
		return ''
	}
	return path[..separator]
}

struct DirStat {
	name string
mut:
	files int
	size  i64
	lines int
}

