package main
import "base:runtime"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

clear :: proc() {
	fmt.print("\033[2J\033[H")
}

Task :: struct {
	name:        string,
	description: string,
	done:        bool,
}

input :: proc(prompt: string) -> string {
	fmt.println(prompt)
	buf: [256]byte
	bytes_read, _ := os.read(os.stdin, buf[:])
	output := string(buf[:bytes_read])
	output = strings.trim_space(output)
	return strings.clone(output)
}

main :: proc() {
	task: Task
	os.make_directory(".cache")
	tasks: [dynamic]Task
	defer (delete(tasks))
	fmt.println("Todo List App")
	for {
		for {
			// input for mode
			clear()
			mode := input(
				"(1, default)Add a task, (2)View all tasks, (3)Delete all cache and tasks",
			)
			if mode == "3" {
				clear()
				delete_cache := input("Type yes to delete all cache or press enter to cancel")
				if delete_cache == "yes" {
					clear()
					os.remove(".cache/tasks.json")
					for i := 0; i <= len(tasks); i += 1 {
						fmt.println("Removed Task", i + 1, ":", tasks[0].name)
						runtime.ordered_remove_dynamic_array(&tasks, 0)
					}
					input("\nCache successfully deleted. Press enter to continue...")
				} else {
					input("Cancelled. Press enter to continue...")
				}
				break
			}
			if mode == "2" {
				clear()
				// NOTE: Read this https://odin-lang.org/docs/overview/#range-based-for-loop
				data, reer := os.read_entire_file(".cache/tasks.json", context.allocator)

				defer (delete(data))
				_ = json.unmarshal(data, &tasks)
				if len(tasks) != 0 {
					for i := 0; i < len(tasks); i += 1 {
						fmt.println(
							"Task",
							i + 1,
							"Name:",
							tasks[i].name,
							"\nDescription:",
							tasks[i].description,
							"\n",
						)
					}
					choice: string
					hello: int
					fmt.println(
						"Select one of the tasks to mark as done or press enter to continue....",
					)
					for {
						choice = input("")
						if choice != "" {
							hello, ok := strconv.parse_int(choice)
							if !ok {
								fmt.println(
									"Please select a number from the list that is shown",
								)} else if hello > len(tasks) {
								clear()


								for i := 0; i < len(tasks); i += 1 {
									fmt.println(
										"Task",
										i + 1,
										"Name:",
										tasks[i].name,
										"\nDescription:",
										tasks[i].description,
										"\n",
									)
								}
								fmt.println("Please enter a number from the range available!")
							} else if hello <= len(tasks) { 	// add way to detect when index outf range
								runtime.ordered_remove_dynamic_array(&tasks, hello - 1)

								json_data, _ := json.marshal(
									tasks,
									{pretty = true, use_enum_names = true},
								)

								werr := os.write_entire_file(".cache/tasks.json", json_data)
								if werr != nil {fmt.println(werr)}

								break
							}
						} else {
							break
						}
					}
				} else {input("It seems like you have nothing to do! Press enter to continue...")}
				break
			}
			clear()
			// input func for name
			name := input("What is the name of your task?")
			task.name = name
			clear()
			// input func for desc
			desc := input("What is the description for your task?")
			task.description = desc
			// task is NOT done
			task.done = false
			append(&tasks, task)
			json_data, _ := json.marshal(tasks, {pretty = true, use_enum_names = true})

			werr := os.write_entire_file(".cache/tasks.json", json_data)
			if werr != nil {fmt.println(werr)}

		}
	}
}
