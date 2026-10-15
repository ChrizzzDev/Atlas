module main

fn format_size(bytes i64) string {
	if bytes < 1000 {
		return '${bytes} B'
	} else if bytes < 1000 ** 2 {
		return '${f64(bytes) / 1000:.2f} KB'
	} else if bytes < 1000 ** 3 {
		return '${f64(bytes) / 1000 ** 2:.2f} MB'
	} else {
		return '${f64(bytes) / 1000 ** 3:.2f} GB'
	}
}
