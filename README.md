# psst

[![version](https://img.shields.io/badge/version-0.2.1-blue)](CHANGELOG.md)
[![license](https://img.shields.io/badge/license-MIT-green)](LICENSE)

**Please Send Smarter Thoughts.**

You're deep in a Claude Code session and want a second opinion. Maybe Opus on a tricky design call, or Haiku for a quick sanity check. Switching models mid-session is clumsy, and pasting context into a new chat is worse.

psst lets you lean over and whisper the question instead:

```
/o is this retry loop going to hammer the API under load?
/h what's the exit code convention we settled on?
```

The other model answers with your session's context. Your session model stays put. The reply comes back tagged `[Opus]`, `[Haiku]`, etc., so you always know who said what.

## Commands

| Short | Long | Asks |
|---|---|---|
| `/s` | `/sonnet` | Sonnet |
| `/h` | `/haiku` | Haiku |
| `/o` | `/opus` | Opus |
| `/f` | `/fable` | Fable |

Or name the model as you go:

```
/psst opus is this retry loop going to hammer the API under load?
/psst h what's the exit code convention we settled on?
```

`/psst` takes a short or long name as its first word. If it names your session model, that model just answers. Any other model gets a focused brief from your session model and answers in an isolated subagent. The shortcuts are the faster path for Sonnet, Opus, and Fable: they switch models for one turn and keep full context.

Questions get answered, tasks (edits, test runs, log digging) get done, and offhand remarks get a normal reply. Unlike `/btw`, these can use tools, and the exchange stays in your history.

## It won't blow up your context

Every reply lands in your session, so psst keeps it lean: just the answer, no recap, no file dumps. Noisy work like a 30k-line test run goes to a subagent, and only its conclusion comes back.

Haiku needs special handling. Its window is 200K, smaller than the 1M the others get, so handing it a big session directly would force a compaction. Instead:

| From -> to | What happens |
|---|---|
| any -> `/s` `/o` `/f` | one-turn model switch with full context and tools |
| Haiku -> `/h` | Haiku just answers |
| Sonnet/Opus/Fable -> `/h` | your session model writes Haiku a focused brief, an isolated Haiku subagent answers, the reply is relayed as-is |

If you run with `CLAUDE_CODE_DISABLE_1M_CONTEXT=1`, every model is 200K and this still holds.

## Install

From the [Walang Studio marketplace](https://github.com/walangstudio/marketplace):

```
/plugin marketplace add walangstudio/marketplace
/plugin install psst@walangstudio
```

Plugin commands are namespaced: `/psst:psst opus ...`, `/psst:o ...`, `/psst:h ...` and so on.

Or copy the commands into `~/.claude/commands` directly:

```
./install.sh      # Linux/macOS
./install.ps1     # Windows
```

That gives you the bare names: `/psst`, `/o`, `/h`. Set `CLAUDE_COMMANDS_DIR` to install somewhere else. These are copies, not symlinks, so re-run after pulling.

## Testing

`./test.sh` (Linux) runs the real thing: 4 session models x 4 commands x 6 scenarios, 8 at a time. It spends real tokens.

Scenarios: recall a fact from earlier, reply to a passing remark, scan a 20k-line log, run a noisy failing test suite, edit a config, ask which model is answering. Each cell checks the right model ran, the reply stayed short, and no bulk leaked into the session. Cells run in throwaway dirs, so your real projects and memory are untouched.

Narrow it down:

```
SESSIONS=opus CMDS=h SCENARIOS=suite JOBS=4 MAX_WORDS=150 ./test.sh
```

Add `ps ph po pf` to `CMDS` to run the same cells through `/psst s|h|o|f`.

Fable needs usage credits on some accounts. Skip it with `SESSIONS="haiku sonnet opus" CMDS="s h o"`.

## License

MIT, see [LICENSE](LICENSE).
