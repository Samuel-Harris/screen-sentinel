# 12. A skill for reviewing recorded data

## Why

The recorder exists so agents can use what was on the owner's screen. An
agent with only the raw API has to work out the endpoints, the time ranges and
what is worth reading every time it starts. A skill that reviews the recorded
data gives every agent one entry point for that work.

The skill must outlive this repo's working tree and reach every project and
machine where the owner runs agents. Package it with
[Microsoft APM](https://github.com/microsoft/apm), the way the repo already
gets pstack and the default stack through `apm.yml`, instead of copying a
`SKILL.md` by hand.

## State in 0.4.15

- `.claude/skills/screenpipe-api/` teaches an agent the REST API at
  `localhost:3030`. It is committed by hand, uses the old names and port, and
  no other project can install it.
- `apm.yml` depends only on `Samuel-Harris/foundry/packages/default-stack`
  and `Samuel-Harris/foundry/packages/pstack`, both on `#main`. It deploys to
  `cursor` only. The repo ships no APM package of its own.
- No skill reviews recorded data. The existing skills query a running
  recorder on request.

## Behaviour wanted

1. A skill that reviews the data Screen Sentinel has recorded.
2. The skill lives in an APM package with its own `apm.yml`, committed to git.
   That package is the only source of the skill.
3. This repo installs the skill through its own `apm.yml`, and
   `apm.lock.yaml` pins it, as it pins the foundry packages.
4. Another project, or another machine, gets the skill with `apm install`
   and nothing else.
5. The skill uses the names, data directory and port from 02.

What the skill reviews, how it reads the data, when it runs and what it
produces are left open. Decide them when the work starts and record them
here.

## Done when

- `apm install` in a fresh clone of this repo deploys the skill, and
  `apm.lock.yaml` records the commit it came from.
- `apm install` in an unrelated project deploys the same skill.
- No copy of the skill is committed outside its APM package.
- `apm audit --ci` passes on the package.
- The checks for the skill's behaviour, once decided, are added here and pass.
