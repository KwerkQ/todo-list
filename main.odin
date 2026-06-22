package main
import "base:runtime"
import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:strconv"
import "core:strings"

// function to clear the terminal
clear_screen :: proc() {
	fmt.print("\033[2J\033[H")
}

// structure to make saving data about tasks easier
Task :: struct {
	name:        string,
	description: string,
	done:        bool,
}

// function to take input like in python
input :: proc(prompt: string) -> string {
	fmt.println(prompt)
	buf: [256]byte
	bytes_read, _ := os.read(os.stdin, buf[:])
	output := string(buf[:bytes_read])
	output = strings.trim_space(output)
	return strings.clone(output)
}

// function to write a dynamic array of the type Task seen in the struct above to a file in the path
write_to_a_file :: proc(path: string, array: [dynamic]Task) {
	json_data, _ := json.marshal(array, {pretty = true, use_enum_names = true})
	werr := os.write_entire_file(path, json_data)
	if werr != nil {fmt.println(werr)}
}

// function to read a file at provided path and write it to an dynamic array with the type Task
read_a_file :: proc(path: string, tasks: ^[dynamic]Task) {
	data, reer := os.read_entire_file(path, context.allocator)

	defer (delete(data))
	_ = json.unmarshal(data, tasks)
}

// function to print the characteristics of a task
print_task :: proc(array: [dynamic]Task, index: int) {
	fmt.println("(", index + 1, ") Name:", array[index].name)
	fmt.println("Description:", array[index].description, "\n")
}

main :: proc() {
	// Variable and array work
	task: Task
	tasks: [dynamic]Task
	done_tasks: [dynamic]Task
	defer (delete(tasks))
	defer (delete(done_tasks))
	mode: string

	// Creating a cache directory to store the tasks information
	os.make_directory(".cache")

	for {
		// reading the tasks file to sync the array tasks with the file
		read_a_file(".cache/tasks.json", &tasks)
		clear_screen()

		// Mode switching
		mode = input(
			"(1, default)Add a new task, (2)View all tasks, (3)Delete all cache and tasks, (4)Quit",
		)
		clear_screen()

		if mode == "2" {
			// checks if there are tasks or not
			if len(tasks) != 0 {

				// repeats until satisfactory elements are met
				for {

					// print all tasks function
					for i := 0; i < len(tasks); i += 1 {
						print_task(tasks, i)
					}

					fmt.println(
						"Select a task that you wish to delete or press enter to continue...",
					)

					// input to check what task to delete
					task_to_delete_str := input("")

					if task_to_delete_str != "" {

						// converting the string to an integer
						task_to_delete_int, ok := strconv.parse_int(task_to_delete_str)

						if !ok {
							clear_screen()

							// triggers when not a number was entered
							fmt.println("Please choose a number:")

						} else if task_to_delete_int <= len(tasks) {
							runtime.ordered_remove_dynamic_array(&tasks, task_to_delete_int - 1)
							clear_screen()

							// triggers when the number was correct and allowed and breaks the loop
							input("Task was successfully removed. Press enter to continue...")

							// save the deletion of the task to the file
							write_to_a_file(".cache/tasks.json", tasks)

							// breaks because the requirements were met
							break
						} else {
							clear_screen()

							// triggers when a number out of the range was entered
							fmt.println("Please choose a number from the range that is available:")

						}
					} else {

						// breaks the loop if nothing was entered (enter was pressed)
						break

					}
				}
			} else {

				// triggers if there are no tasks in the array tasks
				input("Looks like you have nothing to do. Congrats!")

			}


		} else if mode == "3" {
			// asks if to delete cache
			delete_cache := input(
				"Type yes to delete all cache. Press enter to continue without deleting.",
			)
			if delete_cache == "yes" {
				clear_screen()
				// remove the directory .cache and all files in it
				os.remove_all(".cache")

				//clear the dynamic array tasks
				clear(&tasks)

				input("Cache successfully deleted. Press enter to continue...")
			} else // if anything but yes is entered, the deletion of cache is cancelled.
			{
				clear_screen()
				input("Cancelled. Press enter to continue...")
			}
		} else if mode == "4" {
			input("All data was saved. Press enter to quit.")
			clear_screen()

			// ends the forever loop
			break

		} else // triggers when anything but 2 or 3 was pressed.
		{

			// prompting for task info
			task.name = input("What is the name of your task?")
			clear_screen()
			task.description = input("What description would you want to add to this task?")
			clear_screen()

			// adding the task to the array tasks
			append(&tasks, task)

			// Writing the tasks to a file to persist on restarts
			write_to_a_file(".cache/tasks.json", tasks)

		}
	}
}
