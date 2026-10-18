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

// Counts use a fixed space separator on supported stable V releases.
fn format_count(count int) string {
	text := count.str()
	mut result := []u8{cap: text.len + text.len / 3}
	for i, c in text.bytes() {
		if i > 0 && (text.len - i) % 3 == 0 && text[i - 1] != `-` {
			result << ` `
		}
		result << c
	}
	return result.bytestr()
}
