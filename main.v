module main

import os

fn main() {
	root := os.args.last() // Provisionally
	project := scan_project(root) or {
		panic(err)
	}
	
	output(project, '')
}
