module main

import os
import io

pub struct TreeNode {
pub:
	name   string
	is_dir bool
mut:
	children    []TreeNode
	child_index map[string]int
}

fn render_tree(tree TreeNode, max_depth int) ! {
	mut stdout := os.stdout()
	mut writer := io.new_buffered_writer(writer: stdout, cap: 64 * 1024)!
	write_tree_line(mut writer, '${tree.name}/')!
	render_tree_node(&tree, '', 0, max_depth, mut writer)!
	writer.flush()!
}

fn write_tree_line(mut writer io.BufferedWriter, line string) ! {
	writer.write('${line}\n'.bytes())!
}

fn render_tree_node(node &TreeNode, prefix string, depth int, max_depth int, mut writer io.BufferedWriter) ! {
	if max_depth > 0 && depth >= max_depth {
		return
	}

	for i in 0 .. node.children.len {
		child := &node.children[i]
		is_last := i == node.children.len - 1
		connector := if is_last { '└── ' } else { '├── ' }
		suffix := if child.is_dir { '/' } else { '' }

		write_tree_line(mut writer, '${prefix}${connector}${child.name}${suffix}')!

		// Do not allocate a new prefix when recursion cannot produce output.
		if child.is_dir && child.children.len > 0
			&& (max_depth <= 0 || depth + 1 < max_depth) {
			next_prefix := if is_last { '${prefix}    ' } else { '${prefix}│   ' }
			render_tree_node(child, next_prefix, depth + 1, max_depth, mut writer)!
		}
	}
}

// When only a limited view is needed, avoid allocating hidden descendants.
// A non-positive max_depth preserves the original unlimited behavior.
fn build_tree_with_depth(project Project, max_depth int) TreeNode {
	mut root := TreeNode{
		name:   project.name
		is_dir: true
	}

	for directory in project.directories {
		add_tree_path_limited(mut root, directory, true, max_depth)
	}

	for file in project.files {
		add_tree_path_limited(mut root, file.path, false, max_depth)
	}

	sort_tree_children_recursive(mut root)
	return root
}

fn sort_tree_children_recursive(mut node TreeNode) {
	sort_tree_children(mut node.children)

	for i in 0 .. node.children.len {
		sort_tree_children_recursive(mut node.children[i])
	}
}

fn sort_tree_children(mut children []TreeNode) {
	children.sort_with_compare(fn (a &TreeNode, b &TreeNode) int {
		if a.is_dir != b.is_dir {
			return if a.is_dir { -1 } else { 1 }
		}

		return if a.name < b.name {
			-1
		} else if a.name > b.name {
			1
		} else {
			0
		}
	})
}

// Walk path components directly, without allocating an array via split().
// The index is retrieved in a single map lookup, including when it is zero.
fn add_tree_path_limited(mut root TreeNode, path string, is_dir bool, max_depth int) {
	mut current := unsafe { &root }
	mut start := 0
	mut depth := 0
	separator := os.path_separator[0]

	for pos in 0 .. path.len + 1 {
		if pos < path.len && path[pos] != separator {
			continue
		}

		// A limited tree only needs the first max_depth path components.
		if max_depth > 0 && depth >= max_depth {
			break
		}

		name := path[start..pos]
		has_more := pos < path.len
		mut idx := 0

		if existing_idx := current.child_index[name] {
			idx = existing_idx
		} else {
			idx = current.children.len
			current.children << TreeNode{
				name:   name
				is_dir: has_more || is_dir
			}
			current.child_index[name] = idx
		}

		current = unsafe { &current.children[idx] }
		depth++
		start = pos + 1
	}
}
