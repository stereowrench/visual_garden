import random
from copy import deepcopy
import sys
import erlport.erlang
from erlport.erlterms import Atom
import json

elixir_pid = None
from_pid = None

weight_occupied_space = 0.4  # You can adjust these weights
weight_ratio = 0.5

def calculate_cost(solution, plants, num_rows, num_columns):
    """Calculates the cost of a solution by minimizing empty space and deviation from desired plant ratios."""

    # Part 1: Maximize occupied squares
    occupied_count = 0
    occupied_positions = set()
    for i in range(num_rows):
        for j in range(num_columns):
            plant_info = solution[i][j]
            if plant_info is not None and (i, j) not in occupied_positions:
                plant_name, orientation, _, _type = plant_info
                footprint_length, footprint_width = orientation

                # Mark all cells in the footprint as occupied
                for u in range(footprint_length):
                    for v in range(footprint_width):
                        occupied_positions.add((i + u, j + v))

                occupied_count += 1

    empty_space_cost = (num_rows * num_columns - occupied_count)

    # Part 2: Minimize deviation from desired plant ratios
    planted_quantities = get_planted_quantities(solution, plants)
    total_desired = sum(plants[p]['quantity'] for p in plants)
    ratio_cost = 0
    for p, data in plants.items():
        desired_proportion = data['quantity'] / total_desired
        actual_proportion = planted_quantities.get(p, 0) / occupied_count if occupied_count > 0 else 0
        ratio_cost += (desired_proportion - actual_proportion)**2  # Squared difference for larger penalty

    # Combine the costs with weights
    total_cost = weight_occupied_space * empty_space_cost + weight_ratio * ratio_cost
    return total_cost

import random
from copy import deepcopy


def delete_random_rectangle(solution):
    """Deletes a random rectangle from the solution, including overlapping footprints."""

    footprint_map = {} # Dict to map cell to footprint
    for i in range(len(solution)):
        for j in range(len(solution[0])):
            plant_info = solution[i][j]
            if plant_info:
                plant_name, orientation, _, _type = plant_info
                footprint_length, footprint_width = orientation
                for x in range(footprint_length):
                    for y in range(footprint_width):
                        if 0 <= i + x < len(solution) and 0 <= j + y < len(solution[0]):
                            footprint_map[(i + x, j + y)] = (i, j) # Map cell to top-left corner of footprint

    neighbor = deepcopy(solution)
    i1, j1 = random.randrange(len(neighbor)), random.randrange(len(neighbor[0]))
    length = random.randrange(1, min(len(neighbor) - i1 + 1, 4))
    width = random.randrange(1, min(len(neighbor[0]) - j1 + 1, 4))

    # Track which footprints to remove
    footprints_to_remove = set()

    for i in range(i1, i1 + length):
        for j in range(j1, j1 + width):
            if (i, j) in footprint_map:
                # If the cell is part of a footprint, mark the footprint for removal
                footprints_to_remove.add(footprint_map[(i, j)])

    # Remove plants and their entire footprint if they are in footprints_to_remove
    for i in range(len(neighbor)):
        for j in range(len(neighbor[0])):
            if neighbor[i][j] is not None and (i, j) in footprints_to_remove:
                neighbor[i][j] = None

    return neighbor



def unplaced_plants_fn(grid, plants):
    filled_grid = deepcopy(grid)
    unplaced_plants = [(p, data['quantity'] - get_planted_quantities(filled_grid, plants)[p])
                       for p, data in plants.items() if data['quantity'] - get_planted_quantities(filled_grid, plants)[p] > 0]
    unplaced_plants.sort(key=lambda item: item[1] / plants[item[0]]['quantity'], reverse=True)

    return filled_grid, unplaced_plants

def is_valid_placement(plants, solution, plant_name, i, j, time_slot, slot_duration, planting_windows, placed_time_slots, planting_type):
    """
    Checks if a plant can be placed at the given coordinates, respecting footprints and planting windows.
    Returns the valid orientation if one exists, or None otherwise.
    """
    footprint_length, footprint_width = plants[plant_name]['footprint']
    staggered = plants[plant_name].get('staggered', False)

    plant_type_index = plants[plant_name]["planting_types"].index(planting_type)

    # Check both orientations
    for orientation in [(footprint_length, footprint_width), (footprint_width, footprint_length)]:
        # Check if footprint is within grid bounds
        if not (0 <= i < len(solution) - orientation[0] + 1 and 0 <= j < len(solution[0]) - orientation[1] + 1):
            continue  # Try the other orientation

        # Check if all cells in the footprint are empty
        if any(solution[i + x][j + y] is not None for x in range(orientation[0]) for y in range(orientation[1])):
            continue  # Try the other orientation

        # Check if all cells in the footprint have a valid planting window in the given time slot
        all_cells_valid = True
        for x in range(orientation[0]):
            for y in range(orientation[1]):
                has_valid_window = False
                for window_start, window_end in planting_windows[plant_name][plant_type_index][i + x][j + y]:
                    if window_start <= time_slot * slot_duration < window_end:
                        has_valid_window = True
                        break  # No need to check other windows in this cell if one is valid
                if not has_valid_window:
                    all_cells_valid = False
                    break  # No need to check other cells if one is invalid
            if not all_cells_valid:
                break  # Try the other orientation

        # Check if staggered planting is violated
        if staggered and all_cells_valid:
            for x in range(orientation[0]):
                for y in range(orientation[1]):
                    if time_slot in placed_time_slots:
                        continue  # Try the other orientation

        # If all checks pass for this orientation, return it
        if all_cells_valid:
            return orientation

    # If no valid orientation is found, return None
    return None


def fill_empty_spaces(grid, plants, planting_windows, slot_duration, max_attempts=10):
    """Fills empty spaces prioritizing plants based on deviation from the desired quantity."""
    filled_grid, unplaced_plants = unplaced_plants_fn(grid, plants)

    for plant_name, remaining_quantity in unplaced_plants:
        plant_data = plants[plant_name]
        staggered = plant_data.get('staggered', False)
        placed_time_slots = set()

        # get all matching plants and add time slots to placed_time_slots
        for i in range(len(filled_grid)):
            for j in range(len(filled_grid[0])):
                if filled_grid[i][j] is not None and filled_grid[i][j][0] == plant_name:
                    placed_time_slots.add((filled_grid[i][j][2], filled_grid[i][j][3]))

        # Fill empty spaces
        while remaining_quantity > 0:
            placed = False
            attempts = 0

            while not placed and attempts < max_attempts:
                attempts += 1
                i, j = random.randrange(len(grid)), random.randrange(len(grid[0]))
                planting_type = random.choice(plant_data['planting_types'])

                # Find the earliest valid time slot for this position
                for t in range(0, 365 // slot_duration):
                    if staggered and (t, planting_type) in placed_time_slots:
                        continue  # Skip if the time slot and planting type are already used
                    # Directly get the orientation from the result of is_valid_placement
                    orientation = is_valid_placement(plants, filled_grid, plant_name, i, j, t, slot_duration, planting_windows, placed_time_slots, planting_type)

                    if orientation is not None and (not staggered or t not in placed_time_slots):
                        # Place the plant
                        for x in range(orientation[0]):
                            for y in range(orientation[1]):
                                filled_grid[i + x][j + y] = (plant_name, orientation, t, planting_type)

                        if staggered:
                            placed_time_slots.add((t, planting_type))
                        placed = True
                        break  # Exit the inner loop since plant is placed
                if not placed:
                    # If no initial valid time slot is found, try a random available slot
                    available_time_slots = set(range(0, 365 // slot_duration))
                    while available_time_slots and not placed:
                        t = random.choice(list(available_time_slots))
                        available_time_slots.remove(t)

                        orientation = is_valid_placement(plants, filled_grid, plant_name, i, j, t, slot_duration, planting_windows, placed_time_slots, planting_type)
                        if orientation is not None:
                            # Place the plant
                            for x in range(orientation[0]):
                                for y in range(orientation[1]):
                                    filled_grid[i + x][j + y] = (plant_name, orientation, t, planting_type)

                            if staggered:
                                placed_time_slots.add((t, planting_type))
                            placed = True
            if placed:
                remaining_quantity -= 1
            else:
                # If max attempts are reached, move on to the next plant
                break

    return filled_grid


def iterated_local_search(plants, planting_windows, num_rows, num_columns, slot_duration, max_iterations=100):
    """Performs iterated local search to find a good plant arrangement."""
    current_solution = fill_empty_spaces(
        [[None for _ in range(num_columns)] for _ in range(num_rows)],
        plants,
        planting_windows,
        slot_duration,
    )
    current_score = calculate_cost(current_solution, plants, num_rows, num_columns)
    best_solution = current_solution
    best_score = current_score

    for iter in range(max_iterations):
        if elixir_pid and from_pid:
            erlport.erlang.cast(elixir_pid, (Atom(b'python'), from_pid, (Atom(b'status'), iter+1, max_iterations)))
        sys.stdout.flush()
        neighbors = []
        for i in range(10):
            neighbor = delete_random_rectangle(current_solution)
            neighbor = fill_empty_spaces(neighbor, plants, planting_windows, slot_duration)
            neighbors.append(neighbor)

        for neighbor in neighbors:
            neighbor_score = calculate_cost(current_solution, plants, num_rows, num_columns)
            if neighbor_score < current_score:
                current_solution = neighbor
                current_score = neighbor_score
                if neighbor_score < best_score:
                    best_solution = neighbor
                    best_score = neighbor_score
                    break  # Move to the next iteration with the improved solution

    return best_solution


def get_planted_quantities(solution, plants):
    """Calculates the number of each plant type placed in the grid, respecting footprints."""
    planted_quantities = {p: 0 for p in plants}
    occupied_positions = set()

    for i in range(len(solution)):
        for j in range(len(solution[0])):
            plant_info = solution[i][j]
            if plant_info is not None and (i, j) not in occupied_positions:
                plant_name, orientation, _, _type = plant_info
                footprint_length, footprint_width = plants[plant_name]['footprint']

                # Mark all cells in the footprint as occupied
                for u in range(footprint_length):
                    for v in range(footprint_width):
                        occupied_positions.add((i + u, j + v))

                planted_quantities[plant_name] += 1
    return planted_quantities


def create_plant_list(grid):
    print("\nPlant Placement with Footprints and Time Slots:")
    printed_plants = set()  # Keep track of printed plants

    plant_list = []
    for i in range(len(grid)):
        for j in range(len(grid[0])):
            cell = grid[i][j]
            if cell is not None and (i, j) not in printed_plants:
                name, (dx, dy), t, type = cell
                print(f"{name} - ({dx}x{dy}), in ({i}, {j}) @ w{t} - {type}")
                plant_list.append({"name": name, "rows": dx, "cols": dy, "x": i, "y": j, "weeks": t, "type": type})
                for h in range(dx):
                    for k in range(dy):
                        printed_plants.add((i + h, j + k))
    return json.dumps(plant_list)

def print_to_elixir(msg):
    global elixir_pid
    global from_pid
    if elixir_pid:
        erlport.erlang.cast(elixir_pid, (Atom(b'python'), from_pid, (Atom(b'stdout'), msg)))
    else:
        print("Elixir pid is None")


def register_handler(elixir_pid2, from_pid2):
    global elixir_pid
    elixir_pid = elixir_pid2
    global from_pid
    from_pid = from_pid2
    def handle_message(message):
        print(message)
        if isinstance(message, tuple) and len(message) > 0:
            if message[0] == b'run_optimization':
                plants = json.loads(message[1][0].decode("utf-8"))
                planting_windows = json.loads(message[1][1].decode("utf-8"))
                num_rows = message[1][2]
                num_columns = message[1][3]
                slot_duration = message[1][4]
                max_iterations = message[1][5]

                result = iterated_local_search(plants, planting_windows, num_rows, num_columns, slot_duration, max_iterations)
                plant_list = create_plant_list(result)
                erlport.erlang.cast(elixir_pid, (Atom(b'python'), from_pid, (Atom(b'result'), plant_list)))
            else:
                print("invalid message type")

    erlport.erlang.set_message_handler(handle_message)


# # --- Example Data ---

# plants = {
#     'tomato': {'footprint': (2, 2), 'quantity': 0, 'staggered': False, "planting_types": ["seed", "transplant"]},
#     'pepper': {'footprint': (2, 1), 'quantity': 2, 'staggered': False, "planting_types": ["seed", "transplant"]},
#     'basil': {'footprint': (1, 1), 'quantity': 8, 'staggered': True, "planting_types": ["seed", "transplant"]}
# }

# num_rows = 2
# num_columns = 4
# slot_duration = 7  # Days per time slot

# # Example planting windows (Delray Beach, Florida, USA)
# planting_windows = {
#     'tomato': [
#         [  # Seed planting windows
#             [[(1, 30)], [(1, 30)], [(1, 30)], [(1, 30)]],
#             [[(1, 30)], [(1, 30)], [(1, 30)], [(1, 30)]]
#         ],
#         [  # Transplant planting windows
#             [[(31, 90), (244, 334)], [(31, 90), (244, 334)], [(31, 90), (244, 334)], [(31, 90), (244, 334)]],
#             [[(31, 90), (244, 334)], [(31, 90), (244, 334)], [(31, 90), (244, 334)], [(31, 90), (244, 334)]]
#         ],
#     ],

#     'pepper': [
#         [  # Seed planting windows
#             [[(1, 60)], [(1, 60)], [(1, 60)], [(1, 60)]],
#             [[(1, 60)], [(1, 60)], [(1, 60)], [(1, 60)]],
#         ],
#         [  # Transplant planting windows
#             [[(91, 213), (244, 334)], [(91, 213)], [(91, 213), (244, 334)], [(91, 213)]],
#             [[(91, 213), (244, 334)], [(91, 213)], [(91, 213), (244, 334)], [(91, 213)]]
#         ],
#     ],

#     'basil': [
#         [  # Seed planting windows
#             [[(91, 273)], [(91, 273)], [(91, 273)], [(91, 273)]],
#             [[(91, 273)], [(91, 273)], [(91, 273)], [(91, 273)]],
#         ],
#         [  # Transplant planting windows (typically not done for basil)
#             [[(0, 0)], [(0, 0)], [(0, 0)], [(0, 0)]],
#             [[(0, 0)], [(0, 0)], [(0, 0)], [(0, 0)]]
#         ],
#     ]
#     # ... (Other plants with their seed and transplant windows)
# }



# # --- Running the Algorithm ---

# plant_to_index = {p: i for i, p in enumerate(plants)}  # Map plant names to indices

# def print_planting_layout(grid):
    # # print grid 2d
    # for row in grid:
    #     for cell in row:
    #         if cell is None:
    #             print("".ljust(5), end=" ")
    #         else:
    #             name, _, _, _ = cell
    #             # print all cells on line line
    #             print(name.ljust(5), end=" ")
    #     print()

    # print("\nPlant Placement with Footprints and Time Slots:")
    # printed_plants = set()  # Keep track of printed plants

    # for i in range(len(grid)):
    #     for j in range(len(grid[0])):
    #         cell = grid[i][j]
    #         if cell is not None and (i, j) not in printed_plants:
    #             name, (dx, dy), t, type = cell
    #             print(f"{name} - ({dx}x{dy}), in ({i}, {j}) @ w{t} - {type}")
    #             for h in range(dx):
    #                 for k in range(dy):
    #                     printed_plants.add((i + h, j + k))


# --- Running the Algorithm and Printing ---

# ... (Your other variables, constraints, solver setup, greedy_plant_arrangement)
# best_solution = iterated_local_search(plants, planting_windows, num_rows, num_columns, slot_duration)  # ... (your algorithm call)

# Print the best solution (grid layout)
# print_planting_layout(best_solution)
