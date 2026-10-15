module main

struct LanguageStats {
	name    string
	files   int
	percent f64
}

fn get_language_stats(used_languages map[string]int, total_files int) []LanguageStats {
	mut languages := []LanguageStats{}

	for name, files in used_languages {
		languages << LanguageStats{
			name:    name
			files:   files
			percent: f64(files) / total_files * 100
		}
	}

	languages.sort_with_compare(fn (a &LanguageStats, b &LanguageStats) int {
		if a.files != b.files {
			return b.files - a.files
		}

		return if a.name < b.name { -1 } else { 1 }
	})

	return languages
}
