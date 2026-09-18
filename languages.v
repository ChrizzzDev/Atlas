module main

pub struct Language {
  name      string
  extension string
}

const language_extensions = {
  '.v': 'V'
  '.ts': 'TypeScript'
  '.tsx': 'TypeScript'
  '.js': 'JavaScript'
  '.jsx': 'JavaScript'
  '.html': 'HTML'
  '.svelte': 'Svelte'
  '.css': 'CSS'
  '.dart': 'Dart'
  '.lua': 'Lua'
  '.ps1': 'PowerShell'
  '.zig': 'Zig'
  '.hs': 'Haskell'
  '.ml': 'OCaml',
  '.txt': 'Plain Text'
  '.go': 'Go'
  '.rs': 'Rust'
  '.java': 'Java'
  '.cs': 'C#'
  '.cpp': 'C++'
  '.c': 'C'
  '.h': 'C/C++'
  '.py': 'Python'
  '.rb': 'Ruby'
  '.php': 'PHP'
  '.kt': 'Kotlin'
  '.swift': 'Swift'
  '.sql': 'SQL'
  '.asm': 'Assembly'
  '.wasm': 'WebAssembly'
  '.f90': 'Fortran'
  '.f95': 'Fortran'
  '.f03': 'Fortran'
  '.f': 'Fortran'
  '.for': 'Fortran'
}

fn language_from_extension(ext string) Language {
  return Language{
    name: language_extensions[ext] or {'Other'}
    extension: ext
  }
}