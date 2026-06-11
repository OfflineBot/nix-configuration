#!/usr/bin/env bash

update_wk_with_hyprctl() {
    local tmpfile=$(mktemp)
    local ws_json
    local focused_id
    ws_json=$(hyprctl workspaces -j)
    focused_id=$(hyprctl activeworkspace -j | jq '.id')

    local filtered_ws
    filtered_ws=$(echo "$ws_json" | jq --arg focused_id "$focused_id" '
        [.[] | {id: (.id|tostring), name: .name, focused: (.id|tostring == $focused_id)}] | sort_by(.id | tonumber)
    ')

    jq --argjson new_ws "$filtered_ws" '.workspaces = $new_ws' "$workspaces_file" > "$tmpfile" && mv "$tmpfile" "$workspaces_file"
}

workspaces_file="/tmp/workspaces.json"
tmpfile=$(mktemp)

# Initialize empty data
echo '{"workspaces":[], "active_window":""}' > "$workspaces_file"
update_wk_with_hyprctl

socat -U - UNIX-CONNECT:/run/user/1000/hypr/$HYPRLAND_INSTANCE_SIGNATURE/.socket2.sock | while IFS= read -r line; do

    if [[ "$line" =~ ^activewindow\>\>(.+) ]]; then
        active="${BASH_REMATCH[1]}"

        # Split by comma into an array
        IFS=',' read -r -a parts <<< "$active"
        # Remove first item and join the rest back with commas
        if [ "${#parts[@]}" -gt 1 ]; then
            active="${parts[@]:1}"
            # Join array elements with commas
            active=$(IFS=','; echo "${parts[*]:1}")
        else
            # If only one item, set to empty or keep as is
            active=""
        fi

        if [[ -z "$(echo "$active" | xargs)" ]]; then
            active="-"
        elif [ ${#active} -gt 60 ]; then
            active="${active:0:60}..."
        fi

        jq --arg active "$active" '.active_window = $active' "$workspaces_file" > "$tmpfile" && mv "$tmpfile" "$workspaces_file"

    elif [[ "$line" =~ ^focusedmon\>\>(.+) ]]; then
            update_wk_with_hyprctl
    elif [[ "$line" =~ ^workspace\>\>(.+) ]]; then
            # Workspace switch detected; update
            update_wk_with_hyprctl
    elif [[ "$line" =~ ^destroyworkspace\>\>(.+) ]]; then
            update_wk_with_hyprctl

    elif [[ "$line" =~ ^destroyworkspacev2\>\>(.+) ]]; then
            update_wk_with_hyprctl
    fi

    "$HOME/.config/eww/scripts/workspace_listener/upload_eww.sh"
done
