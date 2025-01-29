#!/bin/sh

# nuclear() {
#     # Save cursor position
#     printf '\033[s'
#     # Move the cursor up 1 line
#     printf '\033[1A'
#     # Clear the screen
#     printf '\033[1J'
#     # Restore cursor position
#     printf '\033[u'
# }
#

gum_border_msg() {
    gum style --foreground 212 --border-foreground 212 --border double --width 50 --margin "1 2" --padding "2 4" "$1"
}

show_header() {
    gum_border_msg "Welcome to the tmuxinator session creator"
}

show_header

# Get the current working directory
cwd=$(pwd)

# Check if the user is in the right directory
gum confirm --prompt.foreground "#04B575" "Do you want this directory to be your root directory? $(gum style --foreground "#909090" '('$cwd')')" || confirm=false

if [ "$confirm" = false ]; then
    echo "Please navigate to the right directory and run the command again"
    exit 1
fi



clear
show_header

# Get the name of the session
gum style --foreground "#04B575" "Enter the name of the tmux session"
filename=$(gum input --cursor.foreground "#F4AC45" --prompt.foreground "#04B575" --placeholder "$(basename $cwd)")

# Check if the user entered a name
if [ -z "$filename" ]; then
    clear;
    show_header
    gum style --foreground "#F4AC45" "Please enter a name for the session"
    filename=$(gum input --cursor.foreground "#F4AC45" --prompt.foreground "#04B575" --placeholder "$(basename $cwd)")
    if [ -z "$filename" ]; then
        clear;
        show_header
        gum style --foreground "#F4AC45" "Come back when you have a name for the session..."
        exit 1
    fi
fi

MUX_DIR=~/dotfiles/.config/tmuxinator
cd $MUX_DIR

# Check if the session already exists
if [ -f "$filename.yml" ]; then
    clear;
    show_header
    gum confirm --prompt.foreground "#04B575" "The session file already exists. Do you want to overwrite it?" || exit 0
    rm "$filename.yml"
fi


#list of all the hooks available

hooks=( "on_project_start" "on_project_first_start" "on_project_restart" "on_project_exit" "on_project_stop" "pre_window" "startup_window" "startup_pane" )

# Select the hooks you want to use
selected_hooks=$(gum choose --no-limit --cursor.foreground "#F4AC45" --header.foreground "#04B575" --output-delimiter " "  --header "Select the hooks you want to use" ${hooks[@]})

gum spin --title "Creating file $(gum style --foreground "#04B575" "$MUX_DIR/$filename.yml")..." -- sleep 2.5

clear
show_header



# Create the session file
touch "$filename.yml"

# Add the details to the session file
echo "name: $filename" >> "$filename.yml"
echo "root: $cwd" >> "$filename.yml"


# DONE: The hooks below are not being looped through one by one. Need to fix this
# The code works for single hooks but not for multiple hooks

# esc() {
#     # space char after //
#     v=${1// /\\s}   
#     # tab character after //
#     v=${v// /\\t}
#     # newline character after //
#     v=${v// /\\n}
#     echo $v
# }
#
# esc $selected_hooks

# If selected_hooks, then split the string into an array
if [ -n "$selected_hooks" ]; then
    IFS=" " read -ra selected_hooks <<< "$selected_hooks"
    for hook in "${selected_hooks[@]}"; do
        # if hook is on_project_exit, add the command to kill the session as value
        if [ "$hook" = "on_project_exit" ]; then
            exit_hook_command="tmux kill-session -t $filename"
        else
            unset exit_hook_command
        fi

        gum style --foreground "#04B575" "Enter the command for the $hook hook"
        if [ -z "$exit_hook_command" ]; then
            hook_command=$(gum input --cursor.foreground "#F4AC45" --prompt.foreground "#04B575" --placeholder "$hook")
        else
            hook_command=$(gum input --cursor.foreground "#F4AC45" --prompt.foreground "#04B575" --placeholder "$hook" --value "$exit_hook_command")
        fi
        echo "$hook: $hook_command" >> "$filename.yml"
    done

fi


# for hook in "${selected_hooks[@]}"; do
#     echo "hook: $hook"
# done
#
# exit 0


# Add the hooks to the session file
clear;
show_header

# Add the windows to the session file
gum style --foreground "#04B575" "Enter the number of windows you want to create"
windows=$(gum choose {1..9})

echo "windows:" >> "$filename.yml"
for ((i = 1; i <= $windows; i++)); do
    gum style --foreground "#04B575" "Enter the name for window $i"
    window_name=$(gum input --cursor.foreground "#F4AC45" --prompt.foreground "#04B575" --placeholder "editor, server, etc.")
    clear;
    show_header
    gum style --foreground "#04B575" "Enter the layout for window $i"
    window_layout=$(gum input --cursor.foreground "#F4AC45" --prompt.foreground "#04B575" --placeholder "main-horizontal" --value "main-horizontal")
    clear;
    show_header
    gum style --foreground "#04B575" "Enter the number of panes in window $i"
    window_panes=$(gum choose {1..4})
    clear;
    show_header

    echo "  - $window_name:" >> "$filename.yml"
    echo "      layout: $window_layout" >> "$filename.yml"
    echo "      panes:" >> "$filename.yml"

    for ((j = 1; j <= $window_panes; j++)); do
        gum style --foreground "#04B575" "Enter the command for pane $j in window $i"
        pane_command=$(gum input --cursor.foreground "#F4AC45" --prompt.foreground "#04B575" --placeholder "nvim, clear, etc.")
        clear;
        show_header
        echo "        - $pane_command" >> "$filename.yml"
    done
done

# Add all the hooks to the session file as comments that are not used
echo "# Hooks" >> "$filename.yml"
for hook in "${hooks[@]}"; do
    if [[ ! " ${selected_hooks[@]} " =~ " ${hook} " ]]; then
        echo "# $hook:" >> "$filename.yml"
    fi
done

clear;
show_header

# Open the session file for further edits
gum confirm --prompt.foreground "#04B575" "Do you want to open the file for further edits?" || exit 0

gum spin --title "Opening file $(gum style --foreground "#04B575" "$MUX_DIR/$filename.yml") for further edits..." -- sleep 1.5
clear

# Open the session file
nvim "$MUX_DIR/$filename.yml" && exit 0

