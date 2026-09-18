module main

pub struct Project {
pub mut:
  root        string
  name        string
  files       []FileInfo
  directories []string
}

pub struct FileInfo {
pub:
  path      string
  extension string
  size      i64
  lines     int
}