export NAG_JAR="${NAG_JAR:-$HOME/.nag/nag.jar}"
__nag_last=0
__nag_line_buf=""

__nag_now_ms() {
  if [ -n "${EPOCHREALTIME:-}" ]; then
    local v="${EPOCHREALTIME/[.,]/}"
    echo $(( v / 1000 ))
  else
    date +%s%3N
  fi
}

__nag_open_side_window() {
  local out="$1"
  local done_flag="$2"
  local line_file="$3"
  local java_cmd="NAG_LINE_FILE=\"$line_file\" java -jar \"$NAG_JAR\" --out \"$out\"; touch \"$done_flag\""

  if command -v gnome-terminal >/dev/null 2>&1; then
    gnome-terminal --geometry=68x26+960+0 -- bash -c "$java_cmd" >/dev/null 2>&1 &
    return 0
  elif command -v xfce4-terminal >/dev/null 2>&1; then
    xfce4-terminal --geometry=68x26+960+0 -e "bash -c '$java_cmd'" >/dev/null 2>&1 &
    return 0
  elif command -v mate-terminal >/dev/null 2>&1; then
    mate-terminal --geometry=68x26+960+0 -e "bash -c '$java_cmd'" >/dev/null 2>&1 &
    return 0
  elif command -v konsole >/dev/null 2>&1; then
    konsole -e bash -c "$java_cmd" >/dev/null 2>&1 &
    return 0
  elif command -v alacritty >/dev/null 2>&1; then
    alacritty -e bash -c "$java_cmd" >/dev/null 2>&1 &
    return 0
  fi
  return 1
}

__nag_run() {
  history -a
  if [ ! -f "$NAG_JAR" ]; then
    printf "\nnag: JAR introuvable (%s)\n" "$NAG_JAR" >/dev/tty
    return 1
  fi

  local current_line="${READLINE_LINE:-$__nag_line_buf}"
  __nag_line_buf=""

  local line_file
  line_file=$(mktemp)
  printf '%s' "${current_line:-}" > "$line_file"

  if [ -n "${TMUX:-}" ]; then
    local origin_pane
    origin_pane=$(tmux display-message -p '#{pane_id}')
    tmux split-window -h -l 42% -t "$origin_pane" \
      -e "NAG_TARGET=$origin_pane" \
      -e "NAG_LINE=${current_line:-}" \
      -e "NAG_LINE_FILE=$line_file" \
      "java -jar \"$NAG_JAR\""
    rm -f "$line_file"
    return 0
  fi

  local out sel
  out=$(mktemp)

  if { [ -n "${DISPLAY:-}" ] || [ -n "${WAYLAND_DISPLAY:-}" ]; }; then
    local done_flag
    done_flag=$(mktemp -u)
    if __nag_open_side_window "$out" "$done_flag" "$line_file"; then
      while [ ! -f "$done_flag" ]; do
        sleep 0.05
      done
      rm -f "$done_flag"
    else
      local saved
      saved=$(stty -g </dev/tty 2>/dev/null || true)
      stty sane </dev/tty 2>/dev/null || true
      NAG_LINE="${current_line:-}" NAG_LINE_FILE="$line_file" java -jar "$NAG_JAR" --out "$out" </dev/tty >/dev/tty
      [ -n "$saved" ] && stty "$saved" </dev/tty 2>/dev/null || true
    fi
  else
    local saved
    saved=$(stty -g </dev/tty 2>/dev/null || true)
    stty sane </dev/tty 2>/dev/null || true
    NAG_LINE="${current_line:-}" NAG_LINE_FILE="$line_file" java -jar "$NAG_JAR" --out "$out" </dev/tty >/dev/tty
    [ -n "$saved" ] && stty "$saved" </dev/tty 2>/dev/null || true
  fi

  rm -f "$line_file"

  if [ -s "$out" ]; then
    sel=$(<"$out")
    READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}${sel}${READLINE_LINE:READLINE_POINT}"
    READLINE_POINT=$((READLINE_POINT + ${#sel}))
  fi
  rm -f "$out"
}

__nag_tab_check() {
  local now diff
  now=$(__nag_now_ms)
  diff=$(( now - __nag_last ))
  __nag_last=$now

  if [ -n "${READLINE_LINE:-}" ]; then
    __nag_line_buf="$READLINE_LINE"
  fi

  if [ "$diff" -lt 650 ]; then
    __nag_last=0
    __nag_run
  fi
}

bind -x '"\C-x\C-t": __nag_tab_check'
bind '"\t": "\C-x\C-t"'
bind -x '"\C-g": __nag_run'
