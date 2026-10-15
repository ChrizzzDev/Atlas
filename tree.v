module main

import os

pub struct TreeNode {
pub:
	name   string
	is_dir bool
mut:
	children    []TreeNode
	child_index map[string]int
}

fn render_tree(tree TreeNode, max_depth int) {
	println('${tree.name}/')

	render_tree_node(&tree, '', 0, max_depth)
}

fn render_tree_node(node &TreeNode, prefix string, depth int, max_depth int) {
	if max_depth > 0 && depth >= max_depth {
		return
	}

	for i in 0 .. node.children.len {
		child := &node.children[i]
		is_last := i == node.children.len - 1

		connector := if is_last {
			'└── '
		} else {
			'├── '
		}

		suffix := if child.is_dir {
			'/'
		} else {
			''
		}

		println('${prefix}${connector}${child.name}${suffix}')

		if child.is_dir {
			next_prefix := if is_last {
				'${prefix}    '
			} else {
				'${prefix}│   '
			}

			render_tree_node(child, next_prefix, depth + 1, max_depth)
		}
	}
}

fn build_tree(project Project) TreeNode {
	mut root := TreeNode{
		name:   project.name
		is_dir: true
	}

	for directory in project.directories {
		add_tree_path(mut root, directory, true)
	}

	for file in project.files {
		add_tree_path(mut root, file.path, false)
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

fn add_tree_path(mut root TreeNode, path string, is_dir bool) {
	parts := path.split(os.path_separator)
	mut current := unsafe { &root }

	for i, name in parts {
		mut idx := -1
		if name in current.child_index {
			idx = current.child_index[name]
		}

		if idx == -1 {
			current.children << TreeNode{
				name:   name
				is_dir: i < parts.len - 1 || is_dir
			}
			idx = current.children.len - 1
			current.child_index[name] = idx
		}

		current = unsafe { &current.children[idx] }
	}
}
