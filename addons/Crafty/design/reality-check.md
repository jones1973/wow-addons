# Reality check, profession lifecycle - build spec

Three features from the 2026-07-21 data session. Build order per Brad. All
event/API names below are candidates requiring a 50504 probe before use -
verify, don't assume.

## 1. Unlearn profession

UX: context menu on the profession card -> "Unlearn profession..." ->
confirmation window -> unlearn.

- Unlearn call: AbandonSkill lineage - PROBE whether callable from addon code
  on this client and whether it takes skill index or line ID. If protected,
  the menu item degrades to opening the Blizzard unlearn flow, and Crafty
  handles DETECTION only.
- Detection (works regardless of who unlearned): SKILL_LINES_CHANGED ->
  re-enumerate GetProfessions() and diff against the ledger. PROBE: does
  GetProfessions() reflect the removal at event time or one frame late?
  Re-query on event either way; never cache across the fire.
- On removal: purge the ledger SV entry; profession band retires the chip
  with a departure choreography (inverse of the newly-learned arrival -
  cartoon principles apply); if the removed profession was viewed, composer
  selects a neighbor or the empty state.

## 2. Learn-while-open switches immediately

Arrival already works. After the add, the composer runs its own selection
orchestration on the new profession ID via the existing pending-selection
handoff (the crafting-journey cross-profession path), so the switch animates
through the standard choreography instead of a cold jump.

## 3. Reality-check harness (factCheck)

Passive module, always on. The game is the third witness: compare what the
client shows against what the static data claims, in BOTH directions -
observed-but-unexpected AND expected-but-missing. Inconsistencies go to chat
once (throttled, utils:chat) and accumulate in SV. The SV export is a merge
input alongside the verdict files: in-game observation feeds back as ground
truth, so the static data self-corrects through play.

### Observation points
- Trainer window (TRAINER_SHOW / TRAINER_UPDATE): enumerate services.
  * listed recipe: compare req skill (and req LEVEL - trainer rows carry one;
    the Training Projects are level-85-gated) against our orange + class.
  * expected-but-missing: a recipe we class trainer, orange <= current skill,
    level req met, not known, not listed -> observation. (Trainer must teach
    the profession being checked.)
- Craft difficulty (trade skill open): live difficulty category vs predicted
  tier at current skill. Tests yellow/green/grey boundaries continuously.
- Recipe learned (system message / spellbook delta): record HOW -
  * trainer: learned while a trainer window is open -> trainer + npc id
  * item: correlate with the last successful item-use teach cast -> item id
  * discovery: learned during/immediately after a craft cast -> discovery,
    plus WHICH craft triggered it
  * quest: learned on quest turn-in (quest id if capturable)
  * none of the above -> auto/unknown, flagged
  Compare how + at-what-skill/level against predicted class + orange.
- Trainer quests: when the open trainer offers a quest (gossip/quest events
  while the trainer NPC is engaged), record it - the Training Project gate
  is exactly this shape. General quest tracking is out of scope.
- New-recipes-appeared: if a trainer list shows recipes it didn't show at a
  lower level/skill for this character, the stored level+skill context on
  every observation explains why. Level is stored on EVERY row for this
  reason.

### SV schema (normalized)
CraftyFactCheck = {
  schema = 1,
  observations = {          -- append-only; de-duped
    [key] = {               -- key = kind..":"..spell..":"..hash(expected)
      kind,                 -- enum: trainer-listed | trainer-missing |
                            --   tier-mismatch | learned | quest-offered
      spell, prof,          -- ids
      expected, observed,   -- same-keyed small tables (skill/level/class/tier)
      source,               -- { how, item?, npc?, quest?, craft? }
      char, level, skill,   -- context at first observation
      count, firstSeen, lastSeen,
    },
  },
}
Rules: enumerated kinds only; expected/observed share field names; context
(char/level/skill) flat, never nested; repeats bump count+lastSeen, never
append. Export format = this table verbatim; the merge ingests it directly.

### Probe list (one session, comprehensive per DEBUGGING.md)
- SKILL_LINES_CHANGED timing vs GetProfessions()
- AbandonSkill callability + signature
- Trainer API surface: service enumeration fields incl. req level; open
  trainer -> profession identification
- Difficulty category source for the live tier comparison
- Learn signal (message vs event) + reliable correlation windows for
  trainer/item/discovery/quest attribution
