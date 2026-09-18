module main

import os
import io
import term

const ignored_dirs = [
  '.git',
  'node_modules',
  'dist',
  'build',
  'target',
  'bin',
  'coverage',
  '.cache',
  '.tmp'
]

const ignored_files = [
  '.exe',
  '.dll',
  '.so',
  '.class',
  '.o',
  '.pyc'
]

fn is_ignored_directory(name string) bool {
  return os.base(name) in ignored_dirs
}

fn is_ignored_file(name string) bool {
  return os.file_ext(os.base(name)).len == 0 || os.file_ext(os.base(name)) in ignored_files
}

fn is_itself_executable(path string) bool {
  self := os.executable()
  return os.abs_path(path) == os.abs_path(self)
}

fn is_binary(path string) bool {
  mut file := os.open(path) or { return false }
  defer { file.close() }

  mut buf := []u8{len: 8000}
  n := file.read(mut buf) or { return false }

  for i in 0..n {
    if buf[i] == 0 { return true }
  }

  return false
}

pub fn scan_project(root string) !Project {
  if !os.exists(root) || !os.is_dir(root) {
    return error("invalid root")
  }

  abs_path := os.abs_path(root)
  name := os.base(abs_path)

  mut project := Project{
    root: abs_path,
    name: name
  }

  scan_directory(project.root, '', mut &project)

  return project
}

fn scan_directory(path string, relative_path string, mut ctx Project) {
  entries := os.ls(path) or { return }

  for entry in entries {
    full_path := os.join_path(path, entry)

    if os.is_dir(full_path) {
      if is_ignored_directory(full_path) { continue }

      dir_path := os.join_path(relative_path, entry)
      ctx.directories << dir_path

      scan_directory(full_path, dir_path, mut ctx)
    } else {
      if is_ignored_file(full_path) { continue }
      if is_itself_executable(full_path) { continue }
      if is_binary(full_path) { continue }

      file_path := os.join_path(relative_path, entry)

      add_file(os.join_path(path, entry), file_path, mut ctx)
    }
  }
}

fn add_file(full_path string, relative_path string, mut ctx Project) {
  fi := FileInfo{
    path: relative_path,
    extension: os.file_ext(full_path),
    size: os.file_size(full_path)
    lines: count_lines(full_path)
  }

  ctx.files << fi
}

fn count_lines(path string) int {
  mut file := os.open(path) or { return 0 }
  defer { file.close() }

  mut reader := io.new_buffered_reader(reader: file)

  mut count  := 0
  for {
    _ := reader.read_line() or { break }
    count++
  }

  return count
}