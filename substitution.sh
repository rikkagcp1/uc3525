#!/bin/bash

# Function to perform variable substitution in a text file.
# E.g.: #VARIABLE_NAME# will be replaced with the value of
#       environmental variable $VARIABLE_NAME. # pairs will be
#       removed after the substitution.
# The first argument is the path to the file.
# The rest arguments are the variable names.
perform_variable_substitution() {
    local text_file="$1"  # Text file to be processed
    shift  # Shift the arguments to remove the text_file argument
    local var_names=("$@")  # Array of variable names

    # Iterate over each variable name in the array
    for var_name in "${var_names[@]}"; do
        # Get the value of the variable
        local var_value="${!var_name}"
        local escaped_value="${var_value//\//\\/}"  # Escape forward slashes

        # Replace the placeholder with the variable value in the text file
        sed -i "s/#${var_name}#/${escaped_value}/g" "$text_file"
    done
}
