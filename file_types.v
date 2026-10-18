module main

import term

pub struct FileType {
pub:
	name       string
	extensions []string
	patterns   []string
	category   string
}

const file_type_categories = [
	FileType{
		name:       'Source Code'
		extensions: ['.v', '.ts', '.tsx', '.js', '.jsx', '.go', '.rs', '.java', '.cs', '.cpp',
			'.c', '.h', '.py', '.rb', '.php', '.kt', '.swift', '.zig', '.hs', '.ml', '.dart', '.lua']
		patterns:   []
		category:   'source'
	},
	FileType{
		name:       'Configuration'
		extensions: ['.json', '.yaml', '.yml', '.toml', '.ini', '.cfg', '.conf', '.config', '.env',
			'.properties']
		patterns:   ['dockerfile', 'docker-compose', 'makefile', 'cmakelists.txt', 'build.gradle',
			'pom.xml', 'package.json', 'tsconfig.json', 'vite.config', 'webpack.config',
			'rollup.config', '.eslintrc', '.prettierrc', '.gitignore', '.gitattributes',
			'.editorconfig']
		category:   'config'
	},
	FileType{
		name:       'Documentation'
		extensions: ['.md', '.rst', '.txt', '.adoc', '.asciidoc']
		patterns:   ['readme', 'changelog', 'contributing', 'license', 'code_of_conduct', 'security']
		category:   'docs'
	},
	FileType{
		name:       'Tests'
		extensions: ['.test.ts', '.test.js', '.test.tsx', '.test.jsx', '_test.go', '_test.rs',
			'Test.java', 'Test.cs', 'test.py', 'spec.ts', 'spec.js', 'spec.tsx', 'spec.jsx']
		patterns:   ['test_', '_test.', '.spec.', 'tests/', 'test/', '__tests__/', 'spec/']
		category:   'tests'
	},
	FileType{
		name:       'Build & CI'
		extensions: ['.gradle', '.maven', '.sbt', '.bazel', '.buck']
		patterns:   ['.github/workflows/', '.gitlab-ci.yml', '.travis.yml', 'azure-pipelines.yml',
			'jenkinsfile', '.circleci/', 'bitbucket-pipelines.yml', 'makefile', 'cmakelists.txt',
			'build.sh', 'build.bat']
		category:   'build'
	},
	FileType{
		name:       'Styles & Assets'
		extensions: ['.css', '.scss', '.sass', '.less', '.styl', '.html', '.htm', '.svg', '.png',
			'.jpg', '.jpeg', '.gif', '.webp', '.ico', '.woff', '.woff2', '.ttf', '.eot']
		patterns:   []
		category:   'assets'
	},
	FileType{
		name:       'Data & Serialization'
		extensions: ['.xml', '.csv', '.tsv', '.sql', '.proto', '.avsc', '.thrift', '.graphql',
			'.gql']
		patterns:   []
		category:   'data'
	},
	FileType{
		name:       'Scripts'
		extensions: ['.sh', '.bash', '.zsh', '.fish', '.ps1', '.bat', '.cmd', '.py', '.pl', '.rb']
		patterns:   ['scripts/', 'bin/']
		category:   'scripts'
	},
]

const file_type_extension_index = build_file_type_extension_index()

fn build_file_type_extension_index() map[string]int {
	mut index := map[string]int{}
	for i, file_type in file_type_categories {
		for extension in file_type.extensions {
			lower_extension := extension.to_lower()
			// Earlier categories keep their existing precedence.
			if lower_extension !in index {
				index[lower_extension] = i
			}
		}
	}
	return index
}

fn categorize_file(path string, extension string) string {
	lower_ext := extension.to_lower()
	extension_category := file_type_extension_index[lower_ext] or { file_type_categories.len }
	mut lower_path := ''
	mut path_ready := false

	for i, ft in file_type_categories {
		if i == extension_category {
			return ft.category
		}

		if ft.patterns.len == 0 {
			continue
		}

		if !path_ready {
			lower_path = path.to_lower()
			path_ready = true
		}

		for pattern in ft.patterns {
			if lower_path.contains(pattern) {
				return ft.category
			}
		}
	}

	return 'other'
}

fn get_file_type_distribution(project Project) map[string]int {
	mut distribution := map[string]int{}

	for file in project.files {
		category := categorize_file(file.path, file.extension)
		distribution[category] = distribution[category] + 1
	}

	return distribution
}

fn print_file_type_distribution(distribution map[string]int, total_files int) {
	category_order := ['source', 'config', 'docs', 'tests', 'build', 'assets', 'scripts', 'data',
		'other']
	category_labels := {
		'source':  'Source Code'
		'config':  'Configuration'
		'docs':    'Documentation'
		'tests':   'Tests'
		'build':   'Build & CI'
		'assets':  'Styles & Assets'
		'scripts': 'Scripts'
		'data':    'Data & Serialization'
		'other':   'Other'
	}

	mut width := 0
	for cat in category_order {
		if distribution[cat] > 0 {
			label := category_labels[cat]
			if label.len > width {
				width = label.len
			}
		}
	}

	println('')
	println(term.bold('File Types'))

	for cat in category_order {
		count := distribution[cat]
		if count == 0 {
			continue
		}
		label := category_labels[cat]
		padding := ' '.repeat(width - label.len + 2)
		percent := f64(count) / f64(total_files) * 100
		files := if count == 1 { 'file' } else { 'files' }
		println('  ${label}${padding}${format_count(count)} ${files} (${percent:.1f}%)')
	}
}
