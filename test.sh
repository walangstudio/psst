#!/usr/bin/env bash
# E2E matrix: session model x shortcut x scenario, run headless in parallel. Spends real tokens.
#   recall  answer from session context; next plain turn must run on the session model again
#   log     find 2 errors in a 20k-line log, write a context fact to a file
#   suite   run a noisy failing test suite (30k lines), report the 2 failures
#   edit    change a config value to the number agreed earlier in the session
#   remark  a plain comment, no question or task: short natural reply, no tool use in the main session
#   whoami  ask which model is answering; the reply must name the target
# Every cell also asserts: the raw bulk stayed out of the session, the reply is short,
# the expected model ran per the transcript (an untagged reply only warns) (inline, or in a subagent for /h from a bigger session).
# Fable needs usage credits on some accounts: drop it with SESSIONS="haiku sonnet opus" CMDS="s h o".
# Narrow with SESSIONS="opus" CMDS="h" SCENARIOS="suite" JOBS=4 MAX_WORDS=200 (default cap per scenario: recall 60, whoami 40, remark 120, edit/log 150, suite 250).
# ps ph po pf in CMDS run /psst <s|h|o|f> instead of the shortcut: CMDS="po ph".
set -uo pipefail
export MSYS_NO_PATHCONV=1  # Git Bash would rewrite "/s ..." into a Windows path
cmds=$(cd "$(dirname "$0")" && pwd)/commands; export cmds
for p in sonnet:s haiku:h opus:o fable:f; do
  cmp -s "$cmds/${p%%:*}.md" "$cmds/${p##*:}.md" || { echo "FAIL commands/${p##*:}.md drifted from ${p%%:*}.md"; exit 1; }
done
SESSIONS=${SESSIONS:-haiku sonnet opus fable}
CMDS=${CMDS:-s h o f}
SCENARIOS=${SCENARIOS:-recall log suite edit remark whoami}
export MAX_WORDS=${MAX_WORDS:-}
work=$(mktemp -d /tmp/ms-test.XXXXXX)
export work

cell() {
  local sm=$1 c=$2 sc=$3
  local -A full=([s]=sonnet [h]=haiku [o]=opus [f]=fable)
  local key=${c#p} run="/$c"
  [[ $c == p? ]] && run="/psst $key"
  local target=${full[$key]} dir=$work/$sm-$c-$sc
  mkdir -p "$dir/.claude/commands"; cp "$cmds"/*.md "$dir/.claude/commands/"
  cd "$dir" || return
  local word="W$RANDOM$RANDOM" limit=$((RANDOM % 90 + 10)) why=() ask
  local sid
  sid=$(claude -p "Our project codename is $word. We agreed the retry limit is $limit. Reply OK." \
        --model "$sm" --output-format json 2>/dev/null | jq -r .session_id)
  [ -n "$sid" ] && [ "$sid" != null ] || { echo "FAIL $sm $run $sc: seed failed"; return; }

  case $sc in
    recall) ask="what is our project codename?" ;;
    whoami) ask="which Claude model are you? one word" ;;
    remark) ask="btw I think the codename sounds a bit robotic, honestly" ;;
    log)
      awk 'BEGIN{for(i=1;i<=20000;i++){if(i==4242)print "ERROR E4242X disk full";else if(i==17000)print "ERROR E17000Y timeout";else print "INFO filler line " i}}' > "$dir/app.log"
      ask="check $dir/app.log for ERROR lines and report each error code with its line number, then write our project codename into $dir/codename.txt" ;;
    suite)
      cat > "$dir/run_tests.sh" <<'EOS'
#!/usr/bin/env bash
for i in $(seq 1 30000); do
  case $i in
    11111) echo "FAIL test_checkout_total: expected 42.00 got 41.99" ;;
    22222) echo "FAIL test_login_lockout: account not locked after 5 attempts" ;;
    *) echo "PASS filler_test_$i ok" ;;
  esac
done
echo "29998 passed, 2 failed"; exit 1
EOS
      chmod +x "$dir/run_tests.sh"
      ask="run $dir/run_tests.sh and tell me which tests failed and why" ;;
    edit)
      printf 'HOST = "localhost"\nRETRIES = 1\nTIMEOUT = 30\n' > "$dir/config.py"
      ask="set the retry limit in $dir/config.py to the value we agreed" ;;
  esac

  local reply
  reply=$(claude -p "$run $ask" --resume "$sid" --model "$sm" --dangerously-skip-permissions 2>/dev/null)
  local file
  file=$(ls ~/.claude/projects/*/"$sid.jsonl" 2>/dev/null | head -1)
  local sdir=${file%.jsonl}

  case $sc in
    recall) [[ $reply == *"$word"* ]] || why+=("codename missing") ;;
    whoami)
      local body=${reply//"[${target^}]"/}; body=${body,,}
      [[ $body == *"$target"* ]] || why+=("did not say $target")
      for m in sonnet haiku opus fable; do [[ $m == "$target" || $body != *"$m"* ]] || why+=("said $m"); done ;;
    remark)
      [[ -n ${reply// /} ]] || why+=("empty reply")
      local tools
      local from
      from=$(grep -n 'sounds a bit robotic' "$file" | head -1 | cut -d: -f1)
      tools=$(tail -n +"${from:-1}" "$file" | jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' | grep -vxE 'Agent|Task' | sort -u | tr '\n' ' ')
      [[ -z $tools ]] || why+=("main session used tools: $tools") ;;
    log)
      grep -q "$word" "$dir/codename.txt" 2>/dev/null || why+=("codename file wrong")
      [[ $reply == *E4242X* && $reply == *E17000Y* && $reply == *4242* && $reply == *17000* ]] || why+=("errors missing") ;;
    suite)
      [[ $reply == *test_checkout_total* && $reply == *test_login_lockout* ]] || why+=("failures missing")
      [[ $reply == *41.99* || $reply == *"5 attempts"* ]] || why+=("failure reasons missing") ;;
    edit)
      grep -qE "^RETRIES *= *$limit\b" "$dir/config.py" || why+=("config not set to $limit")
      grep -q '^HOST = "localhost"' "$dir/config.py" && grep -q '^TIMEOUT = 30' "$dir/config.py" || why+=("collateral edit") ;;
  esac

  local tag="[${target^}" warn=""
  [[ $(sed -n '/[^[:space:]]/{p;q}' <<<"$reply") == "$tag"* ]] || warn="(warn: untagged)"
  local dumped words
  dumped=$(grep -oE "INFO filler line|PASS filler_test" "$file" 2>/dev/null | wc -l)
  (( dumped < 100 )) || why+=("bulk in session: $dumped lines")
  words=$(wc -w <<<"$reply")
  local -A cap=([recall]=60 [whoami]=40 [remark]=120 [edit]=150 [log]=150 [suite]=250)
  local max=${MAX_WORDS:-${cap[$sc]}}
  (( words <= max )) || why+=("reply $words > $max words")

  local cmdmodels sub
  cmdmodels=$(jq -r 'select(.type=="assistant") | .message.model' "$file" | sed 1d | sort -u | tr '\n' ' ')
  sub=$( [ -d "$sdir" ] && find "$sdir" -name '*.jsonl' -exec jq -r 'select(.type=="assistant") | .message.model' {} + | sort -u | tr '\n' ' ')
  if [[ $target != "$sm" && ( $target == haiku || $c == p? ) ]]; then
    [[ $sub == *$target* && $cmdmodels != *$target* ]] || why+=("$target not isolated")
  else
    [[ $cmdmodels == *$target* ]] || why+=("$target did not run")
  fi
  for m in $sub; do [[ $m == *$target* ]] || why+=("subagent ran $m"); done

  if [[ $sc == recall ]]; then
    claude -p "In one line: what did the previous reply say?" --resume "$sid" --model "$sm" >/dev/null 2>&1
    local last
    last=$(jq -r 'select(.type=="assistant") | .message.model' "$file" | tail -1)
    [[ $last == *$sm* ]] || why+=("follow-up ran $last, not $sm")
  fi

  local status=PASS; (( ${#why[@]} )) && status=FAIL
  printf '%s %-6s %-7s %-6s words=%-3s dumped=%-3s cmd=[%s] sub=[%s] %s\n' \
    "$status" "$sm" "$run" "$sc" "$words" "$dumped" "$cmdmodels" "$sub" "$warn${why[*]:+ -> ${why[*]}}"
  [[ $status == FAIL ]] && printf '  reply: %s\n' "$(tr '\n' ' ' <<<"${reply:0:300}")"
  local pdir; pdir=$(dirname "$file")
  [[ $pdir == */-tmp-* ]] && rm -rf "$pdir"
}
export -f cell

for sm in $SESSIONS; do for c in $CMDS; do for sc in $SCENARIOS; do echo "$sm $c $sc"; done; done; done |
  xargs -P "${JOBS:-8}" -L1 bash -c 'cell "$@"' _ | tee "$work/results.txt"

pass=$(grep -c '^PASS' "$work/results.txt"); total=$(grep -cE '^(PASS|FAIL)' "$work/results.txt")
echo "== $pass/$total passed"
rm -rf "$work"
(( pass == total ))
