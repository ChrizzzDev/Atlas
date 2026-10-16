module main

#include <dirent.h>

fn C.readdir(voidptr) &C.dirent

fn list_scan_entries_linux(path string) ![]ScanEntry {
	dir := C.opendir(&char(path.str))
	if isnil(dir) {
		return error('cannot open directory: ${path}')
	}
	defer {
		C.closedir(dir)
	}

	mut entries := []ScanEntry{cap: 50}
	for {
		ent := C.readdir(dir)
		if isnil(ent) {
			break
		}
		unsafe {
			name := &u8(&ent.d_name[0])
			if name[0] == 0 || (name[0] == `.` && name[1] == 0)
				|| (name[0] == `.` && name[1] == `.` && name[2] == 0) {
				continue
			}
			kind := if ent.d_type == C.DT_DIR {
				ScanEntryKind.directory
			} else if ent.d_type == C.DT_LNK {
				ScanEntryKind.link
			} else if ent.d_type == C.DT_UNKNOWN {
				ScanEntryKind.unknown
			} else {
				ScanEntryKind.file
			}
			entries << ScanEntry{
				name: tos_clone(name)
				kind: kind
			}
		}
	}
	return entries
}
