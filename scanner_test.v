module main

import os

fn test_extensionless_files_are_not_ignored() {
	assert !is_ignored_file('README', '')
	assert !is_ignored_file('Dockerfile', '')
	assert !is_ignored_file('.env', '')
}

fn test_generated_files_are_ignored() {
	assert is_ignored_file('.DS_Store', '')
	assert is_ignored_file('npm-debug.log', '.log')
	assert is_ignored_file('bundle.js.map', '.map')
	assert is_ignored_file('debug.log', '.log')
	assert !is_ignored_file('package-lock.json', '.json')
}

fn test_generated_directories_are_ignored() {
	assert is_ignored_directory('node_modules')
	assert is_ignored_directory('.next')
	assert is_ignored_directory('__pycache__')
	assert !is_ignored_directory('src')
}

fn test_scan_keeps_extensionless_files_and_skips_generated_directories() {
	root := os.join_path(os.temp_dir(), 'atlas-scanner-${os.getpid()}')
	os.rmdir_all(root) or {}
	os.mkdir_all(root, os.MkdirParams{}) or { panic(err) }
	defer { os.rmdir_all(root) or {} }

	os.write_file(os.join_path(root, 'README'), 'project notes') or { panic(err) }
	os.write_file(os.join_path(root, 'Dockerfile'), 'FROM alpine') or { panic(err) }

	generated_dir := os.join_path(root, '.next')
	os.mkdir_all(generated_dir, os.MkdirParams{}) or { panic(err) }
	os.write_file(os.join_path(generated_dir, 'output.js'), 'generated') or {
		panic(err)
	}

	project := scan_project(root) or { panic(err) }
	paths := project.files.map(it.path)

	assert 'README' in paths
	assert 'Dockerfile' in paths
	assert '.next/output.js' !in paths
}
