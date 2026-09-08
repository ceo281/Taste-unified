# taste-unified

One anti-slop design skill, consolidated from 13 Taste Skill modules into a
single 7,356-line `SKILL.md`. It routes by deliverable (code, images, design
spec, audit) and aesthetic profile, enforces the invariants every source module
agrees on, and scopes the rules they disagree on.

Covers landing pages, portfolios, redesigns, dashboards, image reference
boards, mobile app comps, and brand kits.

This repo is the canonical copy. Install *from* here into projects and tools
rather than keeping a fork in each one — the file is fragile in a specific way
(see below), and forks drift silently.

```
skills/taste-unified/SKILL.md      the skill
skills/taste-unified/line-map.lock anchors for its internal line-number map
scripts/install.sh                 copy it into a project or your user scope
scripts/verify-line-map.sh         check the map still points where it claims
.claude-plugin/                    plugin + marketplace manifests
```

## Install

**Claude Code, as a plugin (recommended — updates with `/plugin update`):**

```
/plugin marketplace add ceo281/taste-unified
/plugin install taste-unified@taste-unified
```

**Claude Code, as a plain skill in every project:**

```sh
git clone https://github.com/ceo281/taste-unified
taste-unified/scripts/install.sh                    # -> ~/.claude/skills/taste-unified
taste-unified/scripts/install.sh ../other-project   # -> that project's .claude/skills
```

**Without cloning:**

```sh
mkdir -p ~/.claude/skills/taste-unified && curl -fsSL \
  https://raw.githubusercontent.com/ceo281/taste-unified/main/skills/taste-unified/SKILL.md \
  -o ~/.claude/skills/taste-unified/SKILL.md
```

**Claude apps that accept uploaded skills.** Upload `SKILL.md` as-is. The YAML
frontmatter carries the `name` and `description` those surfaces use to decide
when to trigger it.

**Claude Agent SDK / API.** Point the agent's skill directory at
`skills/taste-unified/`, or read `SKILL.md` into the system prompt. If you
inline it, inline the *whole* file — GATE 0 assumes the line numbers it cites
are reachable, and a truncated paste breaks routing.

**Any other assistant.** Paste GATE 0 (lines 1–60) first and let it declare its
route, then paste the profile line range it names. That two-step is the file's
own intended reading order, not a workaround.

## Do not casually edit SKILL.md

The skill navigates itself by **absolute line number**. Its GATE 0 map says
things like "Part 2, universal invariants: line 136" and "A1
design-taste-frontend, THE DEFAULT: line 382", and instructs the reader to jump
straight to those coordinates instead of reading top to bottom (the file is long
enough to truncate).

So a single added or deleted line above a target re-points that coordinate at
the wrong section. Nothing errors. The skill just quietly reads the wrong
profile and produces confident output from it.

If you edit the file, update the GATE 0 map to match, then:

```sh
scripts/verify-line-map.sh            # fails if any of the 18 entries drifted
scripts/verify-line-map.sh --update   # re-record anchors after a fixed edit
```

`line-map.lock` stores a hash of the *content* each map entry points at, keyed
by label — so renumbering the whole file is fine, as long as the map is
renumbered with it. CI runs the check on every push.

## Using it

The skill is deliberately gated. It expects to:

1. Read GATE 0, pick a mode, and read the routed profile in full.
2. Emit a 5-point declaration — deliverable, canvas type, mode/profile with the
   line range it read, brand, and a verbatim quote from the profile as proof of
   read — then **stop and wait** for you before building.
3. Run the Part 9 pre-flight visibly in the output before shipping.

Design output with no declaration block and no visible pre-flight means the
skill was not actually read. That is the failure mode it is built to expose, so
treat a missing declaration as a reason to re-prompt rather than a style
choice.

## Source

Consolidation of 13 skills / 6,670 source lines, merged without deletion.
