# Changelog

## [0.2.0] - 2026-10-06

- `/psst <model> <message>`: name the model per call, short or long (`s`/`sonnet`, `h`/`haiku`, `o`/`opus`, `f`/`fable`). The session model answers when it is the target; any other model answers in an isolated subagent from a focused brief. A missing or unknown model prints usage.
- `test.sh`: `ps ph po pf` in `CMDS` run the matrix through `/psst`.
- README: plugin installs use namespaced names (`/psst:psst`, `/psst:o`); the install scripts give the bare ones.

## [0.1.0] - 2026-10-06

First release as psst (Please Send Smarter Thoughts), formerly model-shortcuts.

- Packaged as a Claude Code plugin for the walangstudio marketplace.
- Commands moved to `commands/`; install scripts copy from there.
- `test.sh` fails fast if a short alias drifts from its long command.
