module main

import os
import json
import cli

// One record per dependency occurrence; exports without a source are counted
// without collecting symbols. Paths are relative and use forward slashes.
struct Dependency {
mut:
	file      string
	line      int
	kind      string
	specifier string
	scope     string
	target    string
}

struct DependencyFile {
	path     string
	language string
	exports  int
}

struct DependencyReport {
	schema_version int = 1
	project        string
	root           string
	files          []DependencyFile
	dependencies   []Dependency
}

struct DependencyAnalyzer {
mut:
	path         string
	extension    string
	content      []u8
	files        []DependencyFile
	dependencies []Dependency
}

fn deps_supported(ext string) bool {
	return ext in ['.ts', '.tsx', '.mts', '.cts', '.js', '.jsx', '.mjs', '.cjs', '.v']
}

fn (mut a DependencyAnalyzer) start_file(path string, extension string) {
	a.path = path.replace('\\', '/')
	a.extension = extension
	a.content.clear()
}

fn (mut a DependencyAnalyzer) consume_chunk(chunk []u8) {
	if deps_supported(a.extension) { a.content << chunk }
}

fn (mut a DependencyAnalyzer) discard_file() {
	a.content.clear()
}

fn (mut a DependencyAnalyzer) finish_file(_ FileInfo) {
	if !deps_supported(a.extension) { return }
	tokens := dependency_tokens(a.content, a.extension == '.v')
	mut exports := 0
	if a.extension == '.v' {
		exports = a.parse_v(tokens)
	} else {
		exports = a.parse_js(tokens)
	}
	a.files << DependencyFile{
		path:     a.path
		language: if a.extension == '.v' {
			'V'
		} else if a.extension in ['.ts', '.tsx', '.mts', '.cts'] {
			'TypeScript'
		} else {
			'JavaScript'
		}
		exports:  exports
	}
	a.content.clear()
}

struct DependencyToken {
	text string
	kind string
	line int
}

fn dep_word(c u8) bool {
	return c.is_letter() || c.is_digit() || c in [`_`, `$`] || c >= 128
}

// Small lexer rather than regular expressions: comments and quoted text cannot
// introduce imports. Literal contents retain escapes; escaped module names are
// deliberately not resolved by this first version.
fn dependency_tokens(source []u8, is_v bool) []DependencyToken {
	mut out := []DependencyToken{}
	mut i := 0
	mut line := 1
	for i < source.len {
		c := source[i]
		if c == `\n` {
			line++
			i++
			continue
		}
		if c.is_space() {
			i++
			continue
		}
		if c == `/` && i + 1 < source.len && source[i + 1] == `/` {
			for i < source.len && source[i] != `\n` {
				i++
			}
			continue
		}
		if c == `/` && i + 1 < source.len && source[i + 1] == `*` {
			i += 2
			mut depth := 1
			for i < source.len && depth > 0 {
				if source[i] == `\n` { line++ }
				if is_v && i + 1 < source.len && source[i] == `/` && source[i + 1] == `*` {
					depth++
					i += 2
					continue
				}
				if i + 1 < source.len && source[i] == `*` && source[i + 1] == `/` {
					depth--
					i += 2
				} else {
					i++
				}
			}
			continue
		}
		// Slash after an expression introducer is a regex literal in JS.
		if !is_v && c == `/` && (out.len == 0
			|| out.last().text in ['=', '(', '[', '{', ',', ':', ';', '!', '?', 'return', '=>', '>']) {
			start_line := line
			i++
			mut in_class := false
			for i < source.len && source[i] != `\n` {
				if source[i] == `\\` {
					i += 2
					continue
				}
				if source[i] == `[` { in_class = true }
				if source[i] == `]` { in_class = false }
				if source[i] == `/` && !in_class {
					i++
					break
				}
				i++
			}
			for i < source.len && source[i].is_letter() {
				i++
			}
			out << DependencyToken{
				kind: 'opaque'
				line: start_line
			}
			continue
		}
		if c in [`'`, `"`, u8(96)] {
			start_line := line
			quote := c
			i++
			start := i
			mut escaped := false
			for i < source.len && source[i] != quote {
				if source[i] == `\n` { line++ }
				if source[i] == `\\` {
					escaped = true
					i += 2
				} else {
					i++
				}
			}
			end := if i > source.len { source.len } else { i }
			valid := i < source.len && quote != u8(96) && !escaped
			out << DependencyToken{
				text: source[start..end].bytestr()
				kind: if valid { 'string' } else { 'opaque' }
				line: start_line
			}
			if i < source.len { i++ }
			continue
		}
		start := i
		if dep_word(c) {
			for i < source.len && dep_word(source[i]) {
				i++
			}
		} else {
			i++
		}
		out << DependencyToken{
			text: source[start..i].bytestr()
			kind: if dep_word(c) { 'word' } else { 'punct' }
			line: line
		}
	}
	return out
}

fn (mut a DependencyAnalyzer) add_dep(t DependencyToken, kind string) {
	if t.text.len == 0 { return }
	a.dependencies << Dependency{
		file:      a.path
		line:      t.line
		kind:      kind
		specifier: t.text.clone()
	}
}

fn (mut a DependencyAnalyzer) parse_js(t []DependencyToken) int {
	mut exports := 0
	for i, token in t {
		if token.kind != 'word' {
			continue
		}
		if i > 0 && t[i - 1].text in ['.', '?.'] {
			continue
		}
		if token.text == 'require' || token.text == 'import' {
			if i + 3 < t.len && t[i + 1].text == '(' && t[i + 2].kind == 'string'
				&& t[i + 3].text == ')' {
				a.add_dep(t[i + 2], if token.text == 'require' {
					'require'
				} else {
					'dynamic_import'
				})
				continue
			}
		}
		if token.text !in ['import', 'export'] {
			continue
		}
		if i + 1 >= t.len || t[i + 1].text in ['(', '.', ':'] {
			continue
		}
		if token.text == 'export' { exports++ }
		if token.text == 'import' && t[i + 1].kind == 'string' {
			a.add_dep(t[i + 1], 'import')
			continue
		}
		// Only import/export clauses can contain a source, not exported bodies.
		mut braces := 0
		for j := i + 1; j < t.len; j++ {
			if braces == 0 && t[j].kind == 'word' && t[j].text == 'from' && j + 1 < t.len
				&& t[j + 1].kind == 'string' {
				a.add_dep(t[j + 1], if token.text == 'export' { 'reexport' } else { 'import' })
				break
			}
			if t[j].text == '{' { braces++ }
			if t[j].text == '}' { braces-- }
			if t[j].text in [';', '=', '('] || (braces == 0 && t[j].kind == 'word' && t[j].text in ['const', 'let', 'var', 'function', 'class', 'interface', 'default', 'import', 'export']) {
				break
			}
			if braces < 0 {
				break
			}
		}
	}
	return exports
}

fn (mut a DependencyAnalyzer) parse_v(t []DependencyToken) int {
	mut exports := 0
	for j, token in t {
		if token.kind == 'word' && token.text == 'pub' && j + 1 < t.len
			&& t[j + 1].text in ['fn', 'struct', 'enum', 'type', 'interface', 'const'] {
			exports++
		}
	}
	mut i := 0
	for i < t.len {
		if t[i].kind != 'word' || t[i].text != 'import' {
			i++
			continue
		}
		i++
		grouped := i < t.len && t[i].text == '('
		if grouped { i++ }
		for i < t.len {
			if t[i].kind != 'word' {
				break
			}
			start := t[i]
			mut name := start.text
			i++
			for i + 1 < t.len && t[i].text == '.' && t[i + 1].kind == 'word' {
				name += '.' + t[i + 1].text
				i += 2
			}
			a.add_dep(DependencyToken{ text: name, line: start.line }, 'import')
			if i < t.len && t[i].text == 'as' { i += 2 }
			if !grouped {
				break
			}
		}
	}
	return exports
}

fn dependency_report(project Project, a DependencyAnalyzer) DependencyReport {
	mut paths := map[string]bool{}
	mut v_dirs := map[string]bool{}
	for f in project.files {
		path := f.path.replace('\\', '/')
		paths[path] = true
		if f.extension == '.v' { v_dirs[os.dir(path).replace('\\', '/')] = true }
	}
	mut deps := a.dependencies.clone()
	for mut dep in deps {
		if dep.file.ends_with('.v') {
			module_path := dep.specifier.replace('.', '/')
			for candidate in [module_path, 'src/' + module_path, 'modules/' + module_path] {
				if candidate in v_dirs {
					dep.scope = 'internal'
					dep.target = candidate
					break
				}
			}
		} else if dep.specifier.starts_with('./') || dep.specifier.starts_with('../') {
			dep.scope = 'internal'
			base := os.norm_path(os.join_path(os.dir(dep.file), dep.specifier)).replace('\\', '/')
			mut candidates := [base]
			for ext in ['.ts', '.tsx', '.mts', '.cts', '.js', '.jsx', '.mjs', '.cjs', '.json'] {
				candidates << base + ext
			}
			for ext in ['.ts', '.tsx', '.mts', '.cts', '.js', '.jsx', '.mjs', '.cjs', '.json'] {
				candidates << base + '/index' + ext
			}
			// Node-style .js specifiers commonly refer to TypeScript source.
			if base.ends_with('.js') {
				candidates << base[..base.len - 3] + '.ts'
				candidates << base[..base.len - 3] + '.tsx'
			}
			for candidate in candidates {
				if candidate in paths {
					dep.target = candidate
					break
				}
			}
		}
		if dep.scope == '' { dep.scope = 'external' }
	}
	deps.sort_with_compare(fn (a &Dependency, b &Dependency) int {
		if a.file != b.file {
			return if a.file < b.file { -1 } else { 1 }
		}
		if a.line != b.line { return a.line - b.line }
		if a.specifier != b.specifier {
			return if a.specifier < b.specifier { -1 } else { 1 }
		}
		return if a.kind == b.kind {
			0
		} else if a.kind < b.kind {
			-1
		} else {
			1
		}
	})
	mut files := a.files.clone()
	files.sort(a.path < b.path)
	return DependencyReport{
		project:      project.name
		root:         project.root
		files:        files
		dependencies: deps
	}
}

fn scan_dependencies(root string) !DependencyReport {
	mut analyzer := DependencyAnalyzer{}
	project := scan_project_with_analyzer(root, mut analyzer)!
	return dependency_report(project, analyzer)
}

fn render_dependencies(report DependencyReport, format string) string {
	if format == 'json' { return json.encode(report) }
	mut lines := ['ATLAS dependencies — ${report.project}',
		'${report.files.len} source files, ${report.dependencies.len} references']
	for scope in ['internal', 'external'] {
		lines << '\n${scope}:'
		mut count := 0
		for d in report.dependencies {
			if d.scope != scope {
				continue
			}
			count++
			target := if d.target != '' {
				' -> ${d.target}'
			} else if scope == 'internal' {
				' (unresolved)'
			} else {
				''
			}
			lines << '  ${d.file}:${d.line}  ${d.kind} ${d.specifier}${target}'
		}
		if count == 0 { lines << '  (none)' }
	}
	lines << '\nExports (declarations per file):'
	mut exported_files := 0
	for file in report.files {
		if file.exports > 0 {
			exported_files++
			lines << '  ${file.path}: ${file.exports}'
		}
	}
	if exported_files == 0 { lines << '  (none)' }
	return lines.join('\n')
}

fn execute_deps(cmd cli.Command) ! {
	if cmd.args.len > 1 { return error('usage: atlas deps [path] [--format human|json]') }
	format := cmd.flags.get_string('format')!
	if format !in ['human', 'json'] { return error('unknown dependency output format: ${format}') }
	root := if cmd.args.len == 1 { cmd.args[0] } else { '.' }
	report := scan_dependencies(root)!
	println(render_dependencies(report, format))
}
