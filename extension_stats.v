module main

pub struct ExtensionStat {
pub:
	extension string
mut:
	files int
	lines int
	size  i64
}

fn get_extension_stats(project Project) []ExtensionStat {
	mut by_extension := map[string]ExtensionStat{}

	for file in project.files {
		mut stat := by_extension[file.extension] or {
			ExtensionStat{ extension: file.extension }
		}
		stat.files++
		stat.lines += file.lines
		stat.size += file.size
		by_extension[file.extension] = stat
	}

	mut stats := []ExtensionStat{cap: by_extension.len}
	for _, stat in by_extension {
		stats << stat
	}

	return stats
}

fn sort_extension_stats(mut stats []ExtensionStat) {
	stats.sort_with_compare(fn (a &ExtensionStat, b &ExtensionStat) int {
		if a.files != b.files {
			return if a.files > b.files { -1 } else { 1 }
		}

		return if a.extension < b.extension {
			-1
		} else if a.extension > b.extension {
			1
		} else {
			0
		}
	})
}
