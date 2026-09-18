module main

import term
import strings

struct Info {
  label string
  value string
}

struct LanguageStats {
  name    string
  files   int
  percent f64
}

pub fn output(project Project, format string) {
  println(term.bold(term.bright_blue('ATLAS 🗺️')))
  println(term.gray('${'─':20r}'))

  match format {
    '' {
      human_readable_output(&project)
    }

    'json' {
      json_output(&project)
    }

    else {
      human_readable_output(&project)
    }
  }
}

fn human_readable_output(project Project) {
  mut project_size := 0
  mut loc := 0
  mut used_languages := map[string]int{}

  for file in project.files {
    project_size += file.size
    loc += file.lines

    language := language_from_extension(file.extension)
    used_languages[language.name]++
  }

  print_info([
    Info{label: 'Project', value: project.name}
    Info{label: 'Root', value: project.root}
    Info{label: 'Files', value: '${project.files.len}'}
    Info{label: 'Directories', value: '${project.directories.len}'}
    Info{label: 'Size', value: format_size(project_size)}
    Info{label: 'Lines', value: format_loc(loc) }
  ])

  println('')
  println(term.bold('Languages'))

  // This shouln't be less than 0, but just in case 
  if project.files.len <= 0 {
    println(term.warn_message('    ! No recognized files'))
  } else {
    print_languages(get_language_stats(used_languages, project.files.len))
  }
}

fn json_output(_ Project) {
  println('soon')
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

    println('  ${lang.name}${padding}${lang.files} ${files} (${lang.percent:.2f}%)')
  }
}

fn get_language_stats(used_languages map[string]int, total_files int) []LanguageStats {
  mut languages := []LanguageStats{}

  for name, files in used_languages {
    languages << LanguageStats{
      name: name
      files: files
      percent: f64(files) / total_files * 100
    }
  }

  languages.sort_with_compare(fn (a &LanguageStats, b &LanguageStats) int {
    if a.files != b.files {
      return b.files - a.files
    }

    return if a.name < b.name {-1} else {1}
  })

  return languages
}

fn format_loc(lines int) string {
  str := lines.str()
  if str.len < 3 {
    return str
  }

  mut sb := strings.new_builder(str.len + (str.len / 3))
  mut count := 0

  for i := str.len - 1; i >= 0; i-- {
    ch := str[i]

    if ch == `-` {
      sb.write_byte(ch)
      continue
    }

    if count > 0 && count % 3 == 0 {
      sb.write_byte(` `)
    }

    sb.write_byte(ch)
    count++
  }

  return sb.str().reverse()
}

fn format_size(bytes i64) string {
  if bytes < 1000 {
    return '${bytes} B'
  } else if bytes < 1000**2 {
    return '${f64(bytes) / 1000:.2f} KB'
  } else if bytes < 1000**3 {
    return '${f64(bytes) / 1000**2:.2f} MB'
  } else {
    return '${f64(bytes) / 1000**3:.2f} GB'
  }
}