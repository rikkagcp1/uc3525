#!/bin/bash

# Function to perform variable substitution.
# E.g.: #VARIABLE_NAME# will be replaced with the value of
#       environmental variable $VARIABLE_NAME. # pairs will be
#       removed after the substitution.
# The arguments are the variable names.
# The input and output are pipes
perform_variable_substitution() {
    local var_names=("$@")  # Array of variable names

    # Read the input text from stdin
    local text
    read -r -d '' text

    # Iterate over each variable name in the array
    for var_name in "${var_names[@]}"; do
        # Get the value of the variable
        local var_value="${!var_name}"
        local escaped_value="${var_value//\//\\/}"  # Escape forward slashes
        escaped_value="${escaped_value//&/\\&}"  # Escape &

        # Replace the placeholder with the variable value in the text file
        text=$(echo "$text" | sed "s/#${var_name}#/${escaped_value}/g")
    done

    # Output the processed text
    echo "$text"
}
