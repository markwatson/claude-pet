---
name: pet
description: "Adopt a virtual pet for your status line, or manage your existing pet"
---

# Pet — Virtual Status Line Pet

A virtual pet that lives in the Claude Code status line. Its mood reflects how often you use Claude Code.

## Step 1: Check if a pet exists

Check if `~/.claude/pet.sh` exists.

- If it does NOT exist → go to **Adopt** below
- If it does exist → go to **Manage** below

## Adopt

This is the first-time setup. Walk the user through adopting their pet:

1. **Ask the user to name their pet.** Suggest a fun default but let them pick anything.

2. **Ask what kind of animal.** Offer a few emoji options and let them pick, or type their own:
   - 🐕 Dog
   - 🐈 Cat
   - 🐹 Hamster
   - 🐸 Frog
   - 🐧 Penguin
   - Or any emoji they want

3. **Ask about decay_hours** (optional). This controls how quickly the pet gets sad without use. Default is 72 hours. Most users should keep the default — only mention this if they seem interested in customizing.

4. **Create the pet script.** Read the template at `pet.sh` in the same repo as this SKILL.md file (two directories up from this file). Copy it to `~/.claude/pet.sh`. Then edit the copy at `~/.claude/pet.sh` to set:
   - The emoji on the `printf` line at the bottom (replace 🐕 with their choice)
   - The default `name=` value to their chosen name
   - The default `decay_hours=` value if they changed it

5. **Make it executable:** `chmod +x ~/.claude/pet.sh`

6. **Wire into statusline.** Read `~/.claude/statusline-command.sh`.
   - If it doesn't exist, create it with `#!/usr/bin/env bash` and `input=$(cat)` on the first two lines
   - Append this block to the end:
   ```bash

   # Pet
   pet=$("$HOME/.claude/pet.sh" 2>/dev/null)
   if [ -n "$pet" ]; then
       printf "  %s" "$pet"
   fi
   ```

7. **Run the pet script** once so the user can see their new pet's first appearance. Show them the output.

8. Tell the user their pet is adopted and will appear in their status line!

## Manage

The pet already exists. Read `~/.claude/pet.state` for current stats.

If the user provided arguments, handle them:

- **No arguments / "stats"**: Show a summary — name, age (from `born`), total sessions, current streak, current mood. Run `~/.claude/pet.sh` to show current output.
- **"rename <new_name>"**: Update `name=` in `~/.claude/pet.state` AND update the default `name=` in `~/.claude/pet.sh`.
- **"uninstall"**: Confirm first, then remove the `# Pet` block from `~/.claude/statusline-command.sh`, delete `~/.claude/pet.sh` and `~/.claude/pet.state`.
