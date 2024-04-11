#!/bin/bash

# Define the column width

column_width=20

# Get the current terminal width

terminal_width=$(tput cols)

# Calculate the number of columns based on the terminal width

num_columns=$((terminal_width / column_width))


# Limit the number of columns to 3

if ((num_columns > 3)); then
  num_columns=3
fi

# Example data (replace with your own data)

data=(
  "Item 1" "Item 2" "Item 3" "Item 4" "Item 5"
  "Item 6" "Item 7" "Item 8" "Item 9" "Item 10"
)

# Loop through the data and format the output

for ((i = 0; i < ${#data[@]}; i++)); do
  item="${data[$i]}"
  printf "%-${column_width}s" "$item"
  # Add a newline if we've reached the end of a row
  if (( (i + 1) % num_columns == 0 )); then
    printf "\n"
  fi
done

# Add a newline if the last row is incomplete

if (( ${#data[@]} % num_columns != 0 )); then
  printf "\n"
fi


print_truncated_string() {
  local string="$1"
  local length="$2"
  local padding_length=$((length - ${#string}))
  printf "%s%${padding_length}s" "$string" ""
}
