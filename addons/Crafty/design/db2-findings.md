# DB2 data-source findings (MoP Classic, build 5.5.4.68716)

Verified facts about what the client DB2 tables carry, established by querying the
actual CSVs (not from memory or comments). Recorded so they don't get lost. Spell
IDs are stable across expansions, so joins are by spell ID.

Tables referenced live on wago.tools; pull the CSV as `wago.tools/db2/<Table>/csv?build=<build>`.
Automated fetch works (plain curl, no auth) - no hand-download needed.
`design/fetch-db2-closure.sh <build>` pulls the full 32-table domain closure
in one command (works for any build incl. TBC Anniversary when that resumes).

---

## Tier thresholds (orange / yellow / green / grey)

Authoritative source PER TIER differs - neither Wowhead nor DB2 is uniformly right:

- **yellow** = DB2 `SkillLineAbility.TrivialSkillLineRankLow`. Authoritative
  where real (5,284 of 5,427 profession rows). Where WH and DB2 disagree on a
  real yellow, DB2 is right (WH is dropped-to-0 or stale). EXCEPTION: 30 perk
  recipes have BOTH trivial fields placeholder (see below) - yellow for those
  comes from WH.
- **grey** = DB2 `TrivialSkillLineRankHigh` where real (same 5,284 rows), WH
  for the 30 placeholder rows. The 30 both-fields-placeholder recipes:
  Toughness (all ranks), Fur Linings 500+, Socket Bracer/Gloves, the
  Embroideries, Leg Reinforcements, Master's/Sanctified Spellthread. The
  normal Spellthreads (Mystic..Cerulean) have REAL trivial values (345-600) -
  earlier "~45 incl. Spellthreads" was wrong; the count is 30 and only
  Master's/Sanctified are placeholder. Where WH and DB2 both have real grey
  and disagree, the arbiter is the midpoint identity: whichever grey satisfies
  `WHgreen == floor((DB2yellow + grey)/2)` is internally consistent (WH grey
  is observation-clamped for discovery recipes - clusters at observed-max).
- **green** = DERIVED, not stored anywhere: `green = (yellow + grey) / 2`
  (integer). Verified: holds for 4,669 of 4,670 recipes (one off-by-2:
  Goblin Jumper Cables). This is the game's own formula - green is never an
  independent fact. WH's scraped green matching this formula confirms it.
- **orange** = the recipe's first-craftable skill. Sourced per acquisition
  class (see "Orange sources by acquisition class" below). `MinSkillLineRank`
  is BIMODAL, not a pure placeholder: =1 for 5,340 profession rows, but the
  REAL learn level for 87 rows - including all 30 perk recipes (Toughness
  75..600, Fur Linings 500/575, Sockets 550, ...) and the method-1 bandage
  rows (40/80/115/150...). For the 30 perk recipes, MinSkillLineRank is the
  best available orange (better than WH observation). The two field groups are
  complementary registration styles: normal recipes declare progression in
  TrivialLow/High and leave MinSkill=1; perk recipes declare learn level in
  MinSkill and leave the trivial fields dark. For everything else, orange
  comes from WH `colors[0]`, EXCEPT:
  - WH orange is observation-biased HIGH (WH data is crowd-sourced from players
    via their uploader addon; players rarely craft a recipe the instant it's
    available, so the lowest-skill observations are missing). WH systematically
    over-reports orange / under-reports low thresholds.
  - Auto-learned apprentice recipes: WH drops orange to 0. See the orange=1 rule
    below.

### The orange=1 rule (auto-learned apprentice recipes)

15 recipes render wrong ("can't yet" when actually craftable) because WH lost
their orange. Rule, verified to fire on exactly the true apprentice starters and
nothing else:

    orange == 0 (WH dropped) AND
    SkillLineAbility.AcquireMethod == 1 AND
    yellow < grey (real progression arc)
    => orange = 1

Catches: Minor Health, Minor Dodge, Disenchant, Smelt Copper, Cooking Fire,
Delicate Copper Wire, Braided/Woven Copper Ring, Rough Stone Statue, the Scrolls
(Stamina/Intellect/Spirit), Ivory Ink, Charred Wolf Meat, Roasted Boar Meat.
Does NOT catch bandages (they have real oranges: 40/80/150, so orange!=0).

Needs DB2 AcquireMethod joined into the scraper/merge (scraper is WH-only today).
Only 15 recipes - small enough it could equally be a curated overlay entry.

### Orange sources by acquisition class

- **item-taught -> DB2, authoritative.** The teaching item's
  `ItemSparse.RequiredSkillRank` ("Requires <Profession> (N)") IS the orange.
  Link: `ItemEffect` rows with `TriggerType == 6` (the on-learn effect) where
  `SpellID` = the recipe spell and `ParentItemID` = the recipe item (the item's
  other ItemEffect row is generic Learn spell 483 - ignore). Verified across
  the full table: 2,890 of 2,891 TriggerType=6-linked recipes have a nonzero
  RequiredSkillRank; the one zero is a literal test item ("Recipe: Format
  Test"). Zero profession mismatches (`ItemSparse.RequiredSkill` == the
  recipe's skill line for all rows). NOTE: this join's item-taught count
  (2,891) differs from the classification section's 2,988 (different join
  basis) - reconcile when both run against the same catalog. 97 recipes have
  item-req > yellow (e.g. Large Prismatic Shard: learnable 335, yellow 5) -
  not errors: the orange tier is simply EMPTY for them (learned already
  yellow-or-worse). Display semantics, not a data conflict.
- **perk recipes (30) -> DB2** `MinSkillLineRank` (see above).
- **auto-learned (77) -> DB2** `MinSkillLineRank` where real, else the
  orange=1 rule.
- **trainer-taught -> WH** learn value (trainer lists are enumerated by
  uploaders, far more reliable than craft-observation) - cross-check against
  the orange==learn identity.
- **trainer-rank / special-taught -> manual list** (small).

WH orange remains observation-biased HIGH wherever it's the source; the classes
above where DB2 carries the value are exactly where WH is least trustworthy
(item-taught, discovery).

---

## AcquireMethod enum (SkillLineAbility.AcquireMethod)

From wowdev.wiki, verified against known recipes:
- 0 = learn by trainer (also the catch-all for discovery/quest/item recipes)
- 1 = learn when skill obtained (auto-learned; but NOT always orange=1 - bandages
  are method-1 with real high oranges)
- 2 = racial skill spells

MoP value distribution: 0=7288, 2=866, 1=124.

Discovery has NO positive per-recipe marker in SkillLineAbility (Flags all-zero,
confirmed in both MoP 5.5.4 and Retail 12.1.0) - but the class IS recoverable by
subtraction. Residue = AcquireMethod=0 AND no teaching item AND no teacher spell
AND is-a-craft (has a create/enchant effect) = 2,289 recipes = trainer UNION
discovery. DB2 has no trainer table (server-side), so the final split is
`residue - WH trainer enumeration = discovery` (WH trainer lists are uploaded
as complete enumerations - WH's reliable kind). Pre-filter for the proc-based
subset: residue INTERSECT Mechanic=28 = 141 candidates. Research-pool
discoveries land in plain residue: the Research spells use Effect 157 with pool
references (26700/26746/26754) that resolve to no client table - pool
membership is server-side.

---

## Recipe acquisition source (the "missing recipes and sources" foundation)

The discovery/source distinction lives in ONE place: the `Effect=36` (learn spell)
relationship in `SpellEffect`, plus `ItemEffect` for item-taught recipes.

Full classification of all 5,356 MoP recipes:
- **item-taught: 2,988** - taught by a recipe ITEM (drop/vendor). The recipe spell
  is the item's use-effect: `ItemEffect.SpellID == recipeSpell`,
  `ItemEffect.ParentItemID == the recipe item`. In MoP the link is direct
  (ParentItemID on the row); retail uses a separate ItemXItemEffect bridge.
- **trainer: 2,148** - AcquireMethod=0, no teacher spell, no item.
- **trainer-rank: 90** - granted in bulk by profession-rank spells
  ("Apprentice/Journeyman/.../Grand Master <Prof>"), found via SpellEffect Effect=36
  where the teacher's SpellName contains a rank word.
- **auto-learned: 77** - AcquireMethod=1 apprentice grants (superset of the 15
  orange=1 recipes).
- **special-taught: 53** - taught by a NON-rank, NON-item teacher spell
  (quest/discovery-direct, no lootable recipe item). Includes Riddle of Steel,
  the Cauldrons, Dimensional Rippers, Glacial/Icebane/Icy Scale sets, Flasks.

This maps directly to the parked "Missing recipes and sources" roadmap item.
The 2,988 item-taught recipes -> their source item is known; the item's own
source (drops from where / sold by whom / quest reward) is the next FK hop from
the Item table's source relationships (loot/vendor tables), not yet pulled.

Acquisition class also predicts WH orange reliability: item-taught and
special-taught are exactly where WH's crowd-sourced orange is least trustworthy
(observed late), so trust DB2 tiers hardest for those.

---

## Multi-rank and duplicate recipes

- **Rank chains** (177 recipes): `SkillLineAbility.SupercedesSpell` /
  `SupercededBySpell` link rank N to N+1. These are the upgradeable perks:
  bandages, Fur Linings, Leg Reinforcements, Embroideries, Spellthreads,
  Toughness, Socket Bracer/Gloves, Synapse Springs. Each rank is a distinct
  spell ID with its own thresholds.
- **Faction variants** (6): same recipe name, two spell IDs, distinguished by
  `RaceMask_0/1` (Alliance mask 18875469 vs Horde mask 33555378). The Pilgrim's
  Bounty cooking recipes (Pumpkin Pie, Slow-Roasted Turkey, Cranberry Chutney,
  Spice Bread Stuffing, Candied Sweet Potato) and Forged Documents. Thresholds
  identical between the pair.
- **True duplicates** (29): same name, two spell IDs, identical thresholds and
  masks - registered twice (dual skill-line or source). Safe to collapse by
  created item.

If the recipe catalog keys on spell ID, faction variants and rank chains show as
separate rows; keying on created item collapses them (fine for dupes/faction,
NOT for rank chains which are genuinely different thresholds).

---

## Fields worth surfacing in Crafty (tangential finds)

Captured while chasing the above - potentially useful, not yet used:

- **`SkillLineAbility.NumSkillUps`** - how many skill points a craft grants
  (most = 1; Riddle of Steel = 5). Directly relevant to "what should I craft to
  level" - could show/sort by skill-up value.
- **`SkillLineAbility.SupercedesSpell` / `SupercededBySpell`** - authoritative
  rank chains (177 recipes). Crafty has no notion of "this upgrades that" yet;
  could dedupe rank-perks or show only current rank.
- **`SpellReagents`** - authoritative item-reagent lists. Covers 5,244 of 5,356
  recipes (near-total). Reagent_0..7 + ReagentCount_0..7. Cross-check against the
  Wowhead-scraped reagents to catch scrape errors. `SpellReagentsCurrency` is
  EMPTY for all crafting recipes - no MoP recipe takes a currency reagent, so
  Spirits of Harmony is consumed as a normal ITEM reagent, not a currency.
- **Tool requirements (`SpellTotems` + `TotemCategory`)** - DONE, complete asset.
  `SpellTotems.RequiredTotemCategoryID_0/1` -> `TotemCategory.Name_lang` gives the
  required TOOL for 2,972 recipes: Blacksmith Hammer (978), Jeweler's Kit (863),
  Virtuoso Inking Set (591), Runed Copper Rod (360), Arclight Spanner (223),
  Gyromatic Micro-Adjustor (92), Philosopher's Stone (66), High-Powered Bolt Gun (5).
  The "Requires: <tool>" data for the profession-tool census - authoritative, total.
- **Station requirements (`SpellCastingRequirements` + `SpellFocusObject`)** -
  DONE, complete asset. `SpellCastingRequirements.RequiresSpellFocus` (NOT
  "SpellFocusID" as previously recorded) -> `SpellFocusObject.Name_lang` gives
  the required STATION for 1,298 profession recipes (8,807 rows total, 2,051
  nonzero-focus spells, zero duplicate spell IDs). Per profession:
  Blacksmithing 817/850 (Anvil 776, Black Anvil 20, Anvil of the Thunder
  Forges 18, Icebellow Anvil 3), Cooking 232/249 (Cooking Fire 231, Ghostly
  Cooking Fire 1), Engineering 203/390, Mining 32/53 (all smelts -> Forge),
  Alchemy 6 (the Alchemist Stones -> Alchemy Lab), Tailoring 3 (Mooncloth x2
  -> Moonwell, Shadowcloth -> Altar of Shadows), Jewelcrafting 3, Enchanting 1
  (Smoking Heart of the Mountain -> Black Forge), Inscription 1 (Portrait of
  Madam Goya -> Madam Goya), Leatherworking/First Aid 0. No-station remainders
  are coherent (BS sharpening/weight/grinding stones + wards/runes; Cooking
  drinks/specials; Mining gather/rank spells).
  ALSO in this table: `RequiredAreasID` - 3 Tailoring recipes carry AREA
  requirements (Imperial Silk + Song of Harmony -> Silken Fields, AreaGroup
  3461; Spellcloth -> Netherstorm, 7276; resolved via AreaGroupMember ->
  AreaTable). No profession spell uses the faction/reputation, aura-vision, or
  facing columns. Full requirement model: tool (SpellTotems, 2,972) + station
  (1,298) + area (3).
- **`TradeSkillCategory`** - the real in-game category tree (Bracers, Chest,
  Transmutation...) with OrderIndex, per skill line. Authoritative grouping vs
  scraped guesses. NOTE: category is item-TYPE, not acquisition type.
- **`SpellCategories.Mechanic == 28`** = MECHANIC_DISCOVERY (canonical mechanic
  enum), NOT transmute as previously recorded. Marks discovery-CAPABLE casts -
  spells whose crafting can trigger a discovery proc. Full membership: 263
  profession recipes, Alchemy 191 + Engineering 72, nothing else, TBC->MoP
  skill bands only (vanilla transmutes NOT covered - the old "marks transmutes"
  reading fails both directions). The set mixes trainer-taught triggers and
  discovered recipes (discovered TBC recipes are themselves further triggers).
  The Engineering membership implies Cata/MoP engineering discovery - confirm
  against WH "Discovered" tags. Research-spell discoveries (Northrend pools,
  glyph techniques) do NOT carry it - the Research spell is the trigger, not
  the taught recipe.

## Item source (drop / vendor / quest) - the next hop, partially server-side

The `Item` table is item STATS only (class, damage, resistances) - it carries no
source data. An item does not know its own sources; the loot/vendor/quest tables
point AT item IDs (inverse FK).

What exists in the DB2 index for sources:
- **No general mob-loot table** (no CreatureLoot / ItemLootTemplate). World-drop
  loot is SERVER-SIDE, not in client DB2 - same pattern as the (absent) trainer
  table. So "this recipe drops from mob X" is likely NOT recoverable from DB2.
- **`CollectableSourceVendor` / `CollectableSourceQuest` / `CollectableSourceEncounter`
  / `CollectableSourceInfo`** - a "collectable source" system. UNVERIFIED whether
  it covers recipe items (in modern WoW "collectable" often means transmog/mount/
  pet/toy, not recipes). Pull these to check if recipe items appear.
- **`ItemDisenchantLoot`** - DIRECT HIT for the conversions roadmap: what an item
  disenchants INTO (the disenchant yield table). This is the disenchanting half of
  the conversions engine, from DB2.
- **`ItemSalvageLoot`** - salvage yields (similar shape, for salvageable items).

So: recipe item SOURCES may be only partially in DB2 (vendor/quest via Collectable*,
maybe; mob-drops no). Confirm by pulling CollectableSource* and checking for recipe
item IDs.

## Disenchant yields (ItemDisenchantLoot) - conversions engine, disenchant side

`ItemDisenchantLoot` (117 rows) is a BRACKET-rule table, not a per-item list -
which is exactly how DE works. Columns: ID (loot-group id), Class, Subclass,
Quality, MinLevel/MaxLevel (item-level range), SkillRequired, ExpansionID.

Maps an item's properties -> a disenchant loot group:
- Class 2 = Weapons, Class 4 = Armor (the only disenchantable classes).
- Quality 2/3/4 = green/blue/epic (white/grey can't be DE'd - correctly absent).
- Bracketed by item-level range, each with a required Enchanting skill.
- So: (item class, quality, ilvl) -> group + skill needed to DE it.

Remaining hop for the actual mats + odds: **NOT in MoP DB2.** `ItemDisenchantLoot`
is the ONLY disenchant table in the index - there is no companion group->mats
loot-template table. So which shards/essences/dust a group yields, and at what
odds, is SERVER-SIDE (like mob-drops and trainers). The disenchant YIELD data must
come from Wowhead (crowd-sourced observed DE results) - same source as the existing
milling/prospecting yield files. DB2 gives only the bracket rules (what skill is
needed, which quality/ilvl are DE-able), not the output mats.

NOTE - salvage is different: the index has BOTH `ItemSalvage` (input mapping) AND
`ItemSalvageLoot` (yields), so salvage yields MAY be fully in DB2. Disenchant has
only the one table. If salvage matters, pull both ItemSalvage tables.

To compute an item's DE yield in-game: read its class/quality/ilvl (live item
API), find the matching bracket here, resolve the group to mats via the companion
table. This is the disenchant third of the conversions engine (milling/prospecting
need their own yield tables - those come from Wowhead, not DB2, per the milling/
prospecting data files already in the project).

## Dead ends (checked, not assumed)
- `SpellLearnSpell` - NOT a recipe teach path. 47 rows total, all class-ability
  /glyph plumbing (Grimoire of Service, cosmetic glyphs, test spells). Zero
  overlap with profession recipes.
- **No Collectable* tables in MoP DB2** - the CollectableSource{Vendor,Quest,
  Encounter,Info} system is retail-only. Recipe-item vendor/quest sources are NOT
  recoverable via that path in MoP. (Recipe->item link IS known via ItemEffect;
  it's the item's own source that's the gap, and it appears largely server-side.)

- `SkillLineAbility.Flags` - all zero in MoP. No signal.
- `SpellLabel` - empty for all our recipes.
- `SpellMisc.Attributes_*` - discovery and normal transmutes byte-identical.
- `RecipeProgressionGroupEntry` - retail-only (12.1.0), Dragonflight recipe-
  EXPERIENCE/knowledge system, not linked to any MoP recipe. Not a MoP table.
- Retail (12.1.0) tier values - rescaled by skill squishes, useless for MoP.
- `MinSkillLineRank` - placeholder (=1) for nearly all recipes; not orange.
