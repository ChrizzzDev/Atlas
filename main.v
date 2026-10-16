module main

import os
import cli
import term

fn main() {
	mut app := cli.Command{
		name:        'atlas'
		description: 'A lightweight CLI tool for exploring software projects.'
		usage:       '[path]'
		execute:     execute_stats
		posix_mode:  true
		flags:       [
			cli.Flag{
				name:          'extensions'
				abbrev:        'xs'
				description:   'Show extensions statistics.'
				flag:          .bool
				default_value: ['false']
			}
			cli.Flag{
				name:          'format'
				abbrev:        'f'
				description:   'Output format.'
				flag:          .string
				default_value: ['human']
			},
		]
		commands:    [
			cli.Command{
				name:        'tree'
				description: 'Display the project structure.'
				usage:       '[path]'
				execute:     execute_tree
				flags:       [
					cli.Flag{
						name:          'depth'
						abbrev:        'd'
						description:   'Maximum tree depth.'
						flag:          .int
						default_value: ['0']
					},
				]
			},
		]
	}

	app.setup()
	app.parse(os.args)
}

fn execute_stats(cmd cli.Command) ! {
	root := if cmd.args.len > 0 {
		cmd.args[0]
	} else {
		'.'
	}

	format := cmd.flags.get_string('format') or {
		'human'
	}

	if format !in output_formats {
		println(term.fail_message('! Unknown flag value: ${format}'))
		return
	}

	project := scan_project(root)!
	show_extensions := cmd.flags.get_bool('extensions')! && format != 'json'
	mut stats := []ExtensionStat{}

	if show_extensions {
		stats = get_extension_stats(project)
		sort_extension_stats(mut stats)
	}

	output(project, format, stats, show_extensions)
}

fn execute_tree(cmd cli.Command) ! {
	root := if cmd.args.len > 0 {
		cmd.args[0]
	} else {
		'.'
	}

	depth := cmd.flags.get_int('depth') or {
		0
	}

	project := scan_project_structure(root, depth)!
	tree := build_tree_with_depth(project, depth)

	render_tree(tree, depth)!
}
