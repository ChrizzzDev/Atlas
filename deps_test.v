module main

import os
import json

fn analyze_dependency_source(source string, extension string, chunk_size int) DependencyAnalyzer {
	mut a := DependencyAnalyzer{}
	a.start_file('src/main' + extension, extension)
	bytes := source.bytes()
	for start := 0; start < bytes.len; start += chunk_size {
		end := if start + chunk_size < bytes.len { start + chunk_size } else { bytes.len }
		a.consume_chunk(bytes[start..end])
	}
	a.finish_file(FileInfo{})
	return a
}

fn test_js_dependency_forms_and_chunk_boundaries() {
	source := "import './setup';\nimport type {\n Foo,\n from as other\n} from './types';\nexport { Foo } from '@scope/pkg/sub';\nexport * from 'other';\nconst p = import('lazy');\nconst r = require('node:fs');\nimport x = require('legacy');\nexport const answer = 42;\nimport(variable); require(prefix + '/path');\n"
	for chunk_size in [1, 2, 7, 65536] {
		a := analyze_dependency_source(source, '.ts', chunk_size)
		assert a.dependencies.map(it.specifier) == ['./setup', './types', '@scope/pkg/sub', 'other', 'lazy', 'node:fs', 'legacy']
		assert a.dependencies.map(it.kind) == ['import', 'import', 'reexport', 'reexport', 'dynamic_import', 'require', 'require']
		assert a.dependencies[1].line == 6
		assert a.files[0].exports == 3
	}
}

fn test_lexical_noise_is_not_a_dependency() {
	source := "// import 'comment';\n/* export * from 'block'; */\nconst text = \"require('string')\";\nconst template = `import('template')`;\nconst re = /require('regex')/;\nobject.require('method'); object.import('method');\nimport.meta.resolve('meta');\nimport 'real';"
	a := analyze_dependency_source(source, '.js', 1)
	assert a.dependencies.map(it.specifier) == ['real']
}

fn test_v_grouped_aliased_imports_public_declarations_and_comments() {
	source := "module main\n/* outer /* nested */ import fake */\nimport os\nimport (\n net.http as client\n local.tools\n)\npub fn hello() {}\npub struct Thing {}\n"
	a := analyze_dependency_source(source, '.v', 1)
	assert a.dependencies.map(it.specifier) == ['os', 'net.http', 'local.tools']
	assert a.files[0].exports == 2
}

fn test_dependencies_resolve_without_reopening_source_files() {
	mut a := analyze_dependency_source("import './utils.js'; import './missing'; import '@scope/pkg/sub'; export * from './dir';", '.ts', 3)
	project := Project{
		name: 'fixture'
		root: '/does-not-exist'
		files: [FileInfo{path: 'src/main.ts', extension: '.ts'}, FileInfo{path: 'src/utils.ts', extension: '.ts'}, FileInfo{path: 'src/dir/index.js', extension: '.js'}]
	}
	r := dependency_report(project, a)
	assert r.dependencies.filter(it.specifier == './utils.js')[0].target == 'src/utils.ts'
	assert r.dependencies.filter(it.specifier == './missing')[0].scope == 'internal'
	assert r.dependencies.filter(it.specifier == './missing')[0].target == ''
	assert r.dependencies.filter(it.specifier == '@scope/pkg/sub')[0].scope == 'external'
	assert r.dependencies.filter(it.specifier == './dir')[0].target == 'src/dir/index.js'
	decoded := json.decode(DependencyReport, render_dependencies(r, 'json')) or { panic(err) }
	assert decoded.schema_version == 1
	assert decoded.dependencies.len == 4
	assert render_dependencies(r, 'human').contains('(unresolved)')
}

fn test_v_internal_and_external_modules() {
	a := analyze_dependency_source('import local.tools\nimport os\nimport vendor.pkg', '.v', 2)
	r := dependency_report(Project{files: [FileInfo{path: 'modules/local/tools/tool.v', extension: '.v'}]}, a)
	assert r.dependencies.filter(it.specifier == 'local.tools')[0].scope == 'internal'
	assert r.dependencies.filter(it.specifier == 'local.tools')[0].target == 'modules/local/tools'
	assert r.dependencies.filter(it.specifier == 'os')[0].scope == 'external'
	assert r.dependencies.filter(it.specifier == 'vendor.pkg')[0].scope == 'external'
}

fn test_scanner_discards_late_binary_results_and_ignores_generated_files() {
	root := os.join_path(os.temp_dir(), 'atlas-deps-${os.getpid()}')
	os.mkdir_all(os.join_path(root, 'node_modules')) or { panic(err) }
	defer { os.rmdir_all(root) or {} }
	os.write_file(os.join_path(root, 'main.ts'), "import './local'; export const n = 1;") or { panic(err) }
	os.write_file(os.join_path(root, 'local.ts'), 'export const local = 2;') or { panic(err) }
	os.write_file(os.join_path(root, 'notes.txt'), "import 'text';") or { panic(err) }
	os.write_file(os.join_path(root, 'node_modules', 'ignored.js'), "import 'ignored';") or { panic(err) }
	mut bytes := "import 'binary';".bytes()
	bytes << []u8{len: 65536, init: ` `}
	bytes << u8(0)
	os.write_file_array(os.join_path(root, 'binary.js'), bytes) or { panic(err) }
	r := scan_dependencies(root) or { panic(err) }
	assert r.files.len == 2
	assert r.dependencies.len == 1
	assert r.dependencies[0].target == 'local.ts'
	assert r.files.map(it.path) == ['local.ts', 'main.ts']
}
