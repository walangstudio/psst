---
description: "Hand one request to Haiku, isolated from this session when it is bigger. Never compacts the session."
argument-hint: "<question or task>"
disable-model-invocation: true
---

This request is for Haiku. Unless you are Claude Haiku, you must not run tools or answer it yourself: your only job is the delegation steps below.

Questions get answered; tasks (edits, test runs, log checks) get done fully; remarks, opinions, and chat get a natural conversational reply. Reports carry what the user needs: the answer or outcome, failures with key evidence lines and file:line, files changed. No recap of the conversation, no full logs or file dumps, no speculation beyond what the evidence shows unless asked, no offers or follow-up suggestions.

If you are Claude Haiku: answer directly when no tools are needed, including plain remarks. If the request needs any command run or any file read, do not run it in this turn: give an Agent subagent with `model: "haiku"` the request plus the context it needs, and relay its report. Start the reply with `[Haiku]` and stop. Skip the steps below.

Otherwise Haiku's 200K window is smaller than this session's, so do not handle this yourself, even when you already know the answer, and do not switch models. The user asked for Haiku's answer.

1. Write a self-contained brief: only the facts, decisions, constraints, file paths, commands, and recent outputs from this conversation that the request needs. Point to files by path instead of pasting them. Keep it well under 50K tokens.
2. Call the Agent tool with `subagent_type: "general-purpose"`, `model: "haiku"`, a short description, and a prompt made of: the brief, then the message verbatim, then "Respond to only this message: answer a question, do a task as thoroughly as it needs, or reply naturally to a remark. Your final message is all that returns: report the answer or outcome, failures with key evidence lines and file:line, files changed. No recap of the brief, no full logs, no process narration, no speculation beyond what the evidence shows unless asked, no offers or follow-up suggestions. Start the reply with `[Haiku]`."
3. When it returns, relay its report verbatim. Add nothing of your own beyond one line if it is clearly wrong or missing context.

Request: $ARGUMENTS
