# claude-pet

A virtual pet that lives in your Claude Code status line. Your pet's mood reflects how often you use Claude Code — use it regularly and they're happy, stay away too long and they get sad.

```
~  Opus 4.6  ctx: 45k/1000k  $1.20  🐕 Buddy [happy]
```

## Moods

| Mood | When | Color |
|------|------|-------|
| sleepy | Late night (11pm–4am) | blue |
| ecstatic | 5+ day streak, used within the hour | magenta |
| happy | < 12h since last use | green |
| content | < 24h | cyan |
| bored | < 36h | yellow |
| sad | < 54h | red |
| desperate | 54h+ | bright red |

Your pet also tracks daily streaks and total sessions.

## Install

```bash
claude plugin marketplace add markwatson/claude-pet
claude plugin install claude-pet
```

Restart Claude Code or run `/reload-plugins` for the skill to become available.

Then run `/pet` to adopt your pet. You'll pick a name, choose an animal emoji, and the skill handles the rest.

## Usage

- `/pet` — check on your pet (stats, mood, streak)
- `/pet rename <name>` — rename your pet
- `/pet uninstall` — remove your pet

## How it works

The `/pet` skill copies a small bash script (`pet.sh`) to `~/.claude/` and wires it into your status line. The script has zero dependencies beyond `bash` and `date`. State is stored in `~/.claude/pet.state` as a plain key=value file.
