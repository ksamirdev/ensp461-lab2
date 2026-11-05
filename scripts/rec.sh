# usage: source rec.sh <logfile>; rec <command>
# Echoes a command, runs it, and appends its real output to the log.
LOG="$1"; mkdir -p "$(dirname "$LOG")"; : > "$LOG"
rec() { echo "\$ $*" | tee -a "$LOG"; bash -c "$*" 2>&1 | tee -a "$LOG"; local rc=${PIPESTATUS[0]}; echo | tee -a "$LOG"; return $rc; }
