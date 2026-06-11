#!/usr/bin/env bash


read cursor_x cursor_y < <(hyprctl cursorpos -j | jq -r '"\(.x) \(.y)"')

monitor_id=$(hyprctl monitors -j | jq -r --arg x "$cursor_x" --arg y "$cursor_y" '
  map(select(
    (.x <= ($x | tonumber)) and
    (($x | tonumber) < (.x + .width)) and
    (.y <= ($y | tonumber)) and
    (($y | tonumber) < (.y + .height))
  ))[0].id // 0
')

#echo "$monitor_id"

eww open --toggle "topbar${monitor_id}"
