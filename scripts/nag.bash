export NAG_JAR="$HOME/.nag/nag.jar"
__nag_last=0

__nag_run() {
  history -a
  if [ -n "$TMUX" ]; then
    tmux split-window -h -l 45% "NAG_TARGET=$TMUX_PANE java -jar $NAG_JAR"
  else
    local out sel
    out=$(mktemp)
    java -jar "$NAG_JAR" --out "$out" </dev/tty >/dev/tty 2>/dev/tty
    if [ -s "$out" ]; then
      sel=$(<"$out")
      READLINE_LINE="${READLINE_LINE:0:READLINE_POINT}${sel}${READLINE_LINE:READLINE_POINT}"
      READLINE_POINT=$((READLINE_POINT + ${#sel}))
    fi
    rm -f "$out"
  fi
}

__nag_tab_check() {
  local now=${EPOCHREALTIME/./}
  local diff=$(( (now - __nag_last) / 1000 ))
  __nag_last=$now
  if [ "$diff" -lt 400 ]; then
    __nag_last=0
    bind '"\C-x\C-c": clear-screen'
    __nag_run
  else
    bind '"\C-x\C-c": complete'
  fi
}

bind -x '"\C-x\C-t": __nag_tab_check'
bind '"\C-x\C-c": complete'
bind '"\t": "\C-x\C-t\C-x\C-c"'
bind -x '"\C-g": __nag_run'
