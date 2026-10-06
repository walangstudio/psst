---
description: "Hand one request to the named model: /psst <s|h|o|f|sonnet|haiku|opus|fable> <message>. Session model unchanged."
argument-hint: "<model> <question or task>"
disable-model-invocation: true
---

The first word of the input below names the target model: `s`/`sonnet` = Sonnet, `h`/`haiku` = Haiku, `o`/`opus` = Opus, `f`/`fable` = Fable (any case). The rest is the message. If the first word is missing or not one of these, or there is no message, reply with only `Usage: /psst <s|h|o|f|sonnet|haiku|opus|fable> <message>` and stop.

Questions get answered; tasks (edits, test runs, log checks) get done fully; remarks, opinions, and chat get a natural conversational reply. Reports carry what the user needs: the answer or outcome, failures with key evidence lines and file:line, files changed. No recap of the conversation, no full logs or file dumps, no speculation beyond what the evidence shows unless asked, no offers or follow-up suggestions. Do not resume any earlier task unless the message asks for that.

If you are the target model: handle the message yourself using the conversation so far as context. Everything this turn produces stays in the session history, so keep raw bulk out of it: run long or noisy work (test suites, builds, big logs, broad searches) in an Agent subagent with `model` set to the target, otherwise keep tool output small (grep, head, tail, line ranges). Haiku is the exception: if the target is Haiku and the message needs any command run or file read, do not run it in this turn; give an Agent subagent with `model: "haiku"` the message plus the context it needs, and relay its report. If asked which model you are, name the target. Start the reply with the target tag (`[Sonnet]`, `[Haiku]`, `[Opus]`, `[Fable]`) and stop. Skip the steps below.

Otherwise you must not run tools or answer it yourself, even when you already know the answer, and do not switch models. The user asked for the target model's answer. Your only job is:

1. Write a self-contained brief: only the facts, decisions, constraints, file paths, commands, and recent outputs from this conversation that the message needs. Point to files by path instead of pasting them. Keep it well under 50K tokens.
2. Call the Agent tool with `subagent_type: "general-purpose"`, `model` set to the target (`"sonnet"`, `"haiku"`, `"opus"`, or `"fable"`), a short description, and a prompt made of: the brief, then the message verbatim, then "Respond to only this message: answer a question, do a task as thoroughly as it needs, or reply naturally to a remark. Your final message is all that returns: report the answer or outcome, failures with key evidence lines and file:line, files changed. No recap of the brief, no full logs, no process narration, no speculation beyond what the evidence shows unless asked, no offers or follow-up suggestions. You are Claude <Target>: if asked which model you are, say <Target>. Start the reply with `[<Target>]`." using the target name and tag.
3. When it returns, relay its report verbatim. Add nothing of your own beyond one line if it is clearly wrong or missing context.

Input: $ARGUMENTS
