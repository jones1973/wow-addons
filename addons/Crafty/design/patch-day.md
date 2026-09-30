# Crafty Patch Day Runbook

Everything needed to regenerate Crafty's data files after a WoW patch. Two
sources feed the data, and this document covers both end to end:

- DB2 (wago.tools) -> recipe identity, output, reagents, and cooldowns.
- Wowhead scrape -> learn-rank, difficulty thresholds, source, gating, tiers.

Work through it top to bottom for each client build. The output is the per-build
Lua data files the addon ships. This is a working document, not shipped with the
addon.

---

## Clients

Crafty targets two builds. Each has its own database and its own output files.

| Client          | Database        | DB2 output files                                       |
|-----------------|-----------------|--------------------------------------------------------|
| MoP Classic     | wow_classic     | dbRecipeReagents_mop.lua, dbRecipeCooldown_mop.lua     |
| TBC Anniversary | wow_anniversary | dbRecipeReagents_tbc.lua, dbRecipeCooldown_tbc.lua     |

The fetch script resolves the latest build automatically, so build numbers are
not pinned here.

The Wowhead scrape produces its files (whRecipeProgression, whRecipeGate,
whProfessionTiers) per version too, suffixed `_mop`/`_tbc` - the professions,
yields, and tier counts differ between versions, so each is scraped separately.

Shipped data files are named by the pipeline that owns them: `wh` prefix =
Wowhead scrape output, `db` prefix = DB2 export output, `patch` prefix =
hand-curated corrections (data/patchRecipeProgression_mop.lua - obtainable
recipes Wowhead's curation wrongly excludes), unprefixed = primary hand-authored
static data. Era suffix appears in file names only; both era files assign the
same era-neutral Addon table, and the TOC loads exactly one. Consumers never
read these tables directly - logic/recipeCatalog is the single consumer-facing
object over all of them.

---

## At a glance

The whole patch-day sequence, in order. Each step is detailed below.

1. **Load DB2** (Step 1) - `fetch_db2.ps1 -Branch mop` and `-Branch tbc`.
2. **Confirm skill-line IDs** (Step 2) - stable, but verify after a patch.
3. **Export recipe data** (Step 3) - one combined query, run against each
   database -> dbRecipeReagents_mop.lua / dbRecipeReagents_tbc.lua.
4. **Wrap recipe data** (Step 4) - header/footer, verify it parses.
5. **Export cooldown data** (Step 4b) - separate query against each database
   -> dbRecipeCooldown_mop.lua / dbRecipeCooldown_tbc.lua. Still required: neither the
   live API nor the scrape carries static cooldown duration or the daily-reset flag.
6. **Scrape Wowhead** (Step 5) - paste the console scraper on each profession
   page; the page that completes the set auto-emits whRecipeProgression,
   whRecipeGate, whProfessionTiers (suffixed _mop/_tbc).
7. **Load** (Step 6) - already wired in the TOC; no per-patch work.

DB2 splits Cooking into child skill lines (975-982, the six Ways plus two
cookbooks) and puts 45 MoP recipes there. They must be in every skill-line list:
Wowhead has no category page for them, so the crawl never sees them, and without
a row here they reach the player's list from the live scan with nothing to colour
them or fill the detail panel from. They map to Cooking - the player has one
Cooking skill.

If a patch adds or removes a profession, update the profession list in two
places: the `IN (...)` skill-line list in the Step 3 and Step 4b queries, and the
`VERSIONS` map (plus `DISPLAY`) in the Step 5 console scraper. A new game version
is added to `VERSIONS` the same way.

What comes from where, so nothing is double-sourced:

- **DB2 owns**: recipe identity, created item + yield, reagents, cooldowns.
- **Wowhead owns**: learn-rank, difficulty thresholds (orange/yellow/green/grey),
  acquisition source, class/faction/spec gating, profession tier unlocks.
- **Live game API owns**: a learned recipe's current difficulty color and its
  current remaining cooldown (read at runtime, not exported).

---

## DB2 tables used

Which DB2 tables the queries below depend on, and why. This is reference - the
load script (Step 1) maintains its own list and pulls a superset, so you do not
feed this list anywhere. Use it to understand what a query needs, or to confirm a
table is present after loading.

| Table            | Used by              | Why                                                       |
|------------------|----------------------|----------------------------------------------------------|
| SkillLineAbility | dbRecipeReagents, dbRecipeCooldown | recipe -> skill line; the recipe set per profession      |
| SkillLine        | setup                | profession names -> SkillLine IDs, to set the filter     |
| SpellEffect      | dbRecipeReagents     | recipe identity (effect codes) and item output           |
| SpellReagents    | dbRecipeReagents     | reagent item IDs + counts (8 slots)                      |
| ItemSparse       | dbRecipeReagents     | reagent names for the `--` comment                       |
| SpellCooldowns   | dbRecipeCooldown     | rolling cooldown durations                               |
| SpellCategories  | dbRecipeCooldown     | spell -> cooldown category link (shared-timer key)       |
| SpellCategory    | dbRecipeCooldown     | category definition; Flags bit 8 = daily regional reset  |
| SpellName        | dbRecipeCooldown, dbRecipeReagents | recipe names (for the `--` comment in output)            |
| SpellMisc        | dbRecipeCooldown (MoP only) | join required by the MoP cooldown query                  |

Difficulty, learn-rank, gating, and tier data are NOT from DB2 - they come from
the Wowhead scrape (see Step 5). DB2 owns recipe identity,
output, and reagents only.

---

## Step 1 - Load the tables

`fetch_db2.ps1` (kept alongside this doc) pulls the current patch's DB2 tables
from wago.tools and loads them into the branch's MySQL database (wow_classic
for mop, wow_anniversary for tbc), typing each column from its WoWDBDefs
definition. One-time setup, prerequisites, build pinning, and schema behavior
are documented in the script's own header - that header is the single source
for how to run it. This step is only the patch-day orchestration:

Run it once per branch (regenerating data needs both):

    .\fetch_db2.ps1 -Branch mop
    .\fetch_db2.ps1 -Branch tbc

The script loads in strict mode, so a value that does not fit its typed column
fails loudly rather than being silently truncated. When it finishes it prints a
PROBLEMS report (queued tables that did not load) and an ORPHANS report (tables in
the database that are not in its queue). Confirm PROBLEMS is empty before running
any query below.

---

## Step 2 - Find the crafting SkillLine IDs

The export filters to crafting professions by SkillLine ID. Confirm the IDs for
the build (they are stable, but verify after a patch):

    USE wow_classic;
    -- USE wow_anniversary;
    SELECT ID, DisplayName_lang FROM skillline
    WHERE DisplayName_lang IN
      ('Alchemy','Blacksmithing','Enchanting','Engineering','Inscription',
       'Jewelcrafting','Leatherworking','Tailoring','Cooking','First Aid');

Current IDs (both builds):

    129  First Aid       185  Cooking         333  Enchanting
    164  Blacksmithing   197  Tailoring       755  Jewelcrafting
    165  Leatherworking  202  Engineering     773  Inscription
    171  Alchemy

If any ID differs, update the IN (...) list in the export query below.

---

## Step 3 - Export the Lua lines

Run the recipe export against each database. It produces one Lua line per recipe:

    [recipeID] = { skill=skillLine, reagents={{reagentID,count},...} },  -- Recipe Name (5x ReagentName, ...)

One combined query covers what DB2 owns about a recipe: its skill line and its
reagents. (Yield comes from the scrape, not here - see Output yield below.) It runs
unchanged against both wow_classic and wow_anniversary - skill lines absent from a
build simply match nothing.

### Recipe identity (which spells are real recipes)

A profession skill line holds more than recipes: tier unlocks (Apprentice..Zen
Master), passives (Toughness, Find Minerals), skill-up actions (Open Box, Savage
Leather), gathering conversions (Prospecting, Milling), and cross-profession
utility (Release Spirit). These must be excluded. The clean discriminator is the
spell's SpellEffect codes, not its name or its reagents:

- KEEP a spell if it has effect 24, 157, or 53 (creates an item, or applies an
  enchant). Effect 53 is how enchanting recipes register - they produce an
  enchant, not an item, so they have zero item output but are real recipes.
- DISQUALIFY a spell if it has effect 118, 238, or 28, even when it also has a
  create effect. 118 = skill-line grant (tiers/specs). 238 = skill-up-by-
  disassembly (Open Box, Savage Leather - these carry a create effect too, which
  is why name/output alone cannot exclude them). 28 = the Release spells.

Prospecting (effect 127) and Milling (158) fall out naturally - they have no
keep-effect. This rule is derived from the full effect distribution across
profession spells, so it needs no hardcoded ID exclusion list and survives new
disassembly/release spells in future patches.

### Output yield

Output yield (item, min, max) is not in the DB2 export. It comes from the Wowhead
scrape's `creates` field and lives in whRecipeProgression_<ver>.lua (see Step 5). DB2's
create-item effect encodes yield as EffectBasePoints/EffectDieSides, but that
encoding is inconsistent: it misreads fixed yields (e.g. it gives 0 for a recipe
that makes 1) and does not cleanly express the genuine ranges that bombs and
dynamite have. The scrape's `creates` states yield directly. The recipe-identity
rule below still applies - it decides which spells are recipes at all.

### Reagents

SpellReagents holds 8 reagent slots (Reagent_0..7 / ReagentCount_0..7) on one row
per spell. Slots are NOT always filled from slot 0 - enchants commonly leave
slot 0 empty and populate 1..3 - so the "has reagents" test and the emit must
check all 8 slots, not just slot 0. Reagent names for the comment come from
ItemSparse.Display_lang (LEFT JOIN, so a missing item name never drops the row).

### The query

    USE wow_classic;
    -- USE wow_anniversary;
    SELECT
        CONCAT('  [', r.spell, '] = {skill=',
            r.sl, ', reagents={',
            COALESCE(CONCAT_WS(',',
                IF(sr.Reagent_0>0, CONCAT('{',sr.Reagent_0,',',sr.ReagentCount_0,'}'), NULL),
                IF(sr.Reagent_1>0, CONCAT('{',sr.Reagent_1,',',sr.ReagentCount_1,'}'), NULL),
                IF(sr.Reagent_2>0, CONCAT('{',sr.Reagent_2,',',sr.ReagentCount_2,'}'), NULL),
                IF(sr.Reagent_3>0, CONCAT('{',sr.Reagent_3,',',sr.ReagentCount_3,'}'), NULL),
                IF(sr.Reagent_4>0, CONCAT('{',sr.Reagent_4,',',sr.ReagentCount_4,'}'), NULL),
                IF(sr.Reagent_5>0, CONCAT('{',sr.Reagent_5,',',sr.ReagentCount_5,'}'), NULL),
                IF(sr.Reagent_6>0, CONCAT('{',sr.Reagent_6,',',sr.ReagentCount_6,'}'), NULL),
                IF(sr.Reagent_7>0, CONCAT('{',sr.Reagent_7,',',sr.ReagentCount_7,'}'), NULL)
            ), ''),
            '}},  -- ', r.name,
            COALESCE(CONCAT(' (', CONCAT_WS(', ',
                IF(sr.Reagent_0>0, CONCAT(sr.ReagentCount_0,'x ',i0.Display_lang), NULL),
                IF(sr.Reagent_1>0, CONCAT(sr.ReagentCount_1,'x ',i1.Display_lang), NULL),
                IF(sr.Reagent_2>0, CONCAT(sr.ReagentCount_2,'x ',i2.Display_lang), NULL),
                IF(sr.Reagent_3>0, CONCAT(sr.ReagentCount_3,'x ',i3.Display_lang), NULL),
                IF(sr.Reagent_4>0, CONCAT(sr.ReagentCount_4,'x ',i4.Display_lang), NULL),
                IF(sr.Reagent_5>0, CONCAT(sr.ReagentCount_5,'x ',i5.Display_lang), NULL),
                IF(sr.Reagent_6>0, CONCAT(sr.ReagentCount_6,'x ',i6.Display_lang), NULL),
                IF(sr.Reagent_7>0, CONCAT(sr.ReagentCount_7,'x ',i7.Display_lang), NULL)
            ), ')'), '')
        ) AS lua_line
    FROM (
        -- Inner: skilllineability spine, one row per recipe.
        SELECT
            sla.Spell AS spell,
            MIN(sla.SkillLine) AS sl,
            MIN(sn.Name_lang) AS name
        FROM skilllineability sla
        JOIN spellname sn ON sn.ID = sla.Spell
        WHERE sla.SkillLine IN (129,164,165,171,185,197,202,333,755,773,186,
                                     975,976,977,978,979,980,981,982)
          AND EXISTS (SELECT 1 FROM spelleffect k
                      WHERE k.SpellID = sla.Spell AND k.Effect IN (24,157,53))
          AND NOT EXISTS (SELECT 1 FROM spelleffect d
                      WHERE d.SpellID = sla.Spell AND d.Effect IN (118,238,28))
        GROUP BY sla.Spell
    ) r
    LEFT JOIN spellreagents sr ON sr.SpellID = r.spell
    LEFT JOIN itemsparse i0 ON i0.ID = sr.Reagent_0
    LEFT JOIN itemsparse i1 ON i1.ID = sr.Reagent_1
    LEFT JOIN itemsparse i2 ON i2.ID = sr.Reagent_2
    LEFT JOIN itemsparse i3 ON i3.ID = sr.Reagent_3
    LEFT JOIN itemsparse i4 ON i4.ID = sr.Reagent_4
    LEFT JOIN itemsparse i5 ON i5.ID = sr.Reagent_5
    LEFT JOIN itemsparse i6 ON i6.ID = sr.Reagent_6
    LEFT JOIN itemsparse i7 ON i7.ID = sr.Reagent_7
    ORDER BY r.sl, r.spell;

The inner query reduces each recipe's possibly-multiple SkillLineAbility rows (a
recipe can appear more than once - same recipe, different acquisition paths - which
would otherwise collide on the Lua key) to one row per spell via GROUP BY. The
outer query joins reagents (one row per spell, no aggregation) and item names.
Keeping the GROUP BY in the inner query only is what avoids an only_full_group_by
conflict with the un-aggregated reagent columns.

Save each result to a plain .txt (one column of Lua lines).

### Expected count

MoP: 5284 recipes. The recipe-identity rule excludes 6 non-recipes that carry
reagents or item output but are not crafts: Open Box, Savage Leather (skill-ups),
Release Spirit, Release Fire Spirit (utility), Prospecting, Milling (gathering
conversions). Confirm the count after export; a large deviation means a new effect
code has appeared - re-run the effect distribution (below) and classify it before
trusting the export.

### Effect distribution (re-run if the count looks wrong, or after a major patch)

This is how the keep/disqualify effect sets were derived. It lists every effect
code present on profession spells, so a new code can be classified rather than
silently mishandled:

    USE wow_classic;
    -- USE wow_anniversary;
    SELECT se.Effect, COUNT(DISTINCT se.SpellID) AS spells,
           MIN(sn.Name_lang) AS sample
    FROM spelleffect se
    JOIN spellname sn ON sn.ID = se.SpellID
    WHERE se.SpellID IN (
        SELECT sla.Spell FROM skilllineability sla
        WHERE sla.SkillLine IN (129,164,165,171,185,197,202,333,755,773,186,
                                     975,976,977,978,979,980,981,982)
    )
    GROUP BY se.Effect ORDER BY spells DESC;

Known effects: 24/157 create item, 53 enchant (all KEEP); 118 skill grant, 238
skill-up disassembly, 28 release (all DISQUALIFY); 47 generic/tier machinery and
127/158 prospect/mill and 6/33 gathering passives (none are keep-effects, so they
are excluded by absence). Other effect codes seen on profession spells (3, 77, 90,
64, 156, ...) are secondary effects riding on real crafts - they appear alongside
24/157 and are harmless.

---

## Step 4 - Wrap into the Lua data file

Each build's exported lines get wrapped in the data-file header and footer and
saved to its output path (data/dbRecipeReagents_mop.lua, data/dbRecipeReagents_tbc.lua).

The file shape:

    --[[ header documenting field order ]]
    local ADDON_NAME, Addon = ...
    Addon.dbRecipeReagents = {
      [recipeID] = { skill=skillLine, reagents={{reagentID,count},...} },
      ...
    }

Both files assign to the same Addon.dbRecipeReagents. Only one is ever loaded (see
loading, below), so there is no clash.

Validate each finished file parses:

    luac5.1 -p data/dbRecipeReagents_mop.lua
    luac5.1 -p data/dbRecipeReagents_tbc.lua

---

## Step 4b - Cooldown data (the category-join mechanism)

Produces dbRecipeCooldown_mop.lua / dbRecipeCooldown_tbc.lua. Still required: neither
the Wowhead scrape nor the live API can replace this. The scrape has no cooldown
field at all; the live `GetTradeSkillCooldown` returns only the current remaining
time on a known recipe, not the recipe's intrinsic duration or whether it is a
daily reset. The static duration and the daily-reset flag only exist in DB2.

More involved than the recipe data because profession cooldowns are stored two
different ways, and the daily ones are NOT a millisecond duration anywhere.

Two kinds of cooldown:
- "Rolling" - a literal duration in SpellCooldowns (RecoveryTime or
  CategoryRecoveryTime), e.g. Prismatic Sphere 48h, Primal Mooncloth 92h. Counts
  down from the moment of crafting.
- "Daily Regional Reset" - has NO stored duration. It is a category flag:
  SpellCategory.Flags bit 8 (& 8 != 0), meaning a 24h reset at the regional
  daily boundary. This is how MoP transmutes, Imperial Silk, Living Steel, the
  JC daily cuts, etc. work. Looking for a stored 86400000 finds nothing - the
  daily-ness lives in the category flag, reached by joining SkillLineAbility ->
  SpellCategories (link table) -> SpellCategory (the flag).

Tables needed beyond the difficulty set: SpellCategories (spell->category link),
SpellCategory (carries Flags), SpellName (recipe names), SpellMisc (MoP join).

There are two variants below - MoP and TBC - which differ because TBC has no
daily-reset cooldowns (all rolling) and does not need the SpellMisc join. Both
were verified to reproduce the shipped data exactly (74 MoP, 29 TBC).

MoP (handles daily reset + rolling; note the SpellMisc join):

    USE wow_classic;
    SELECT lua_line FROM (
        SELECT DISTINCT
            sla.Spell AS spell_id,
            CONCAT(
                '  [', sla.Spell, '] = {',
                IF((scat.Flags & 8) != 0, 0,
                   ROUND(GREATEST(sc.CategoryRecoveryTime, sc.RecoveryTime) / 1000 / 60 / 60, 1)), ',',
                ( IF((scat.Flags & 8) != 0, 1, 0)
                  + IF(COALESCE(scats.Category,0) > 0, 2, 0) ), ',',
                COALESCE(scats.Category, 0),
                '},  -- ', sn.Name_lang
            ) AS lua_line
        FROM SkillLineAbility sla
        JOIN SpellMisc sm       ON sla.Spell = sm.SpellID
        JOIN SpellCooldowns sc  ON sla.Spell = sc.SpellID
        JOIN SpellName sn       ON sla.Spell = sn.ID
        LEFT JOIN SpellCategories scats ON sla.Spell = scats.SpellID
        LEFT JOIN SpellCategory scat    ON (scats.Category = scat.ID OR scats.ChargeCategory = scat.ID)
        WHERE sla.SkillLine IN (129,164,165,171,185,197,202,333,755,773,
                                     975,976,977,978,979,980,981,982)
          AND ( (scat.Flags & 8) != 0
                OR sc.CategoryRecoveryTime > (12*60*60*1000)
                OR sc.RecoveryTime        > (12*60*60*1000) )
    ) t
    ORDER BY spell_id;

TBC (all rolling; no SpellMisc join, no daily flag, no SpellCategory):

    USE wow_anniversary;
    SELECT lua_line FROM (
        SELECT DISTINCT
            sla.Spell AS spell_id,
            CONCAT(
                '  [', sla.Spell, '] = {',
                ROUND(GREATEST(sc.CategoryRecoveryTime, sc.RecoveryTime) / 1000 / 60 / 60, 1), ',',
                IF(COALESCE(scats.Category,0) > 0, 2, 0), ',',
                COALESCE(scats.Category, 0),
                '},  -- ', sn.Name_lang
            ) AS lua_line
        FROM SkillLineAbility sla
        JOIN SpellCooldowns sc ON sla.Spell = sc.SpellID
        JOIN SpellName sn      ON sc.SpellID = sn.ID
        LEFT JOIN SpellCategories scats ON sla.Spell = scats.SpellID
        WHERE sla.SkillLine IN (129,164,165,171,185,197,202,333,755,773,
                                     975,976,977,978,979,980,981,982)
          AND (sc.CategoryRecoveryTime > (12*60*60*1000) OR sc.RecoveryTime > (12*60*60*1000))
    ) t
    ORDER BY spell_id;

The DISTINCT + outer-query ORDER BY exists because DISTINCT (which dedups the
emitted Lua lines) conflicts with ordering on a non-selected column; the wrapper
resolves it.

The >12h floor on rolling cooldowns drops short category-housekeeping timers
(1s/etc.) without touching real cooldowns - the genuine rolling ones are >=20h.

### Wrapping into Lua

The cooldown queries emit paste-ready Lua directly (the flag normalization is
done in SQL), so the wrap step is just header + footer. Each line:

    [recipeID] = { hours=, flags=, sharedCat= },  -- RecipeName  -- Meow

  hours     - rolling cooldown length in hours; 0 for a daily regional reset
              (a daily reset is a wall-clock boundary, not an N-hour countdown -
              the flag carries it; the client computes time to next reset)
  flags     - bitmask: 0x1 = daily regional reset, 0x2 = shares a category timer
  sharedCat - shared cooldown-category id; 0 when not shared. Recipes with the
              same non-zero sharedCat share ONE timer (e.g. the 42 MoP transmutes
              all share 310 - crafting one locks the rest).

Both build files assign to Addon.dbRecipeCooldown (only one loads). Consumed by
logic/cooldownData.lua. Absence from the file = no cooldown by nature.

Result sizes: 74 MoP, 29 TBC.

## Other available-but-unextracted columns

These tables/columns are already loaded in MySQL (the full tables are pulled at
load time) but not currently exported. Captured here so picking them up later is
a checklist, not a re-derivation:

- SkillLineAbility.SupercedesSpell - the recipe this one replaces (rank upgrade
  chains). Investigated and dropped: across all professions it yields exactly one
  real recipe-level row (Heavy Windwool Bandage Rank 1 -> Rank 2); every other
  non-zero SupercedesSpell is a tier-spell chain, not a recipe. The single real
  case is also expressible via the Wowhead scrape's `rank` field, so no dedicated
  extraction is warranted.
- SkillLineAbility.NumSkillUps - static source for skill-up count (currently
  derived live from the trade-skill API at harvest; also in the Wowhead scrape as
  `nskillup`).
- Spell.Description_lang / SkillLine.AlternateVerb_lang - static text sources
  (currently harvested live).

Note: recipe list grouping ("Bags", "Epic Gems", etc.) does NOT need DB2. The
live legacy trade-skill list interleaves header/subheader rows with recipes
(GetTradeSkillInfo skillType "header"/"subheader" + indentLevel), so the display
category comes from the harvest by recording the current header per recipe rather
than skipping it. Distinct from the cooldown SHARED category (SpellCategories),
which is not in the live API and must come from DB2.

## Step 5 - Scrape Wowhead (learn-rank, difficulty, gating, tiers)

This produces the build-independent files the DB2 export cannot: per-recipe
learn-rank, the full orange/yellow/green/grey difficulty thresholds, acquisition
source, class/faction/spec gating, and the profession tier unlocks.

### Why Wowhead, and why it must run in a browser

DB2 cannot supply this. `MinSkillLineRank` is a placeholder (1 for ~98% of
recipes), and the trivial fields give only yellow-start and grey-start, never the
orange-start (the learn/first-craftable rank). Trainer-taught recipes have no
teaching item, so their learn-rank is server-side, absent from client DB2.
CraftLib (the comparable retail DB2 library) resolves this the same way - it
pulls difficulty and source from Wowhead.

Wowhead sits behind CloudFront with TLS-fingerprint bot detection, so automated
fetching does not work:

- PowerShell `Invoke-WebRequest` -> 403 (blocked at the TLS handshake; browser
  headers do not help, the .NET TLS fingerprint is the tell).
- Datacenter `curl` -> a 919-byte challenge page (IP blocked).
- The recipe data is not in the raw HTML regardless - it arrives by XHR and is
  assembled into JS variables at runtime.

So the scrape runs as a console snippet in a real browser on a residential
connection: one profession spell-list page per profession the version has, plus
the prospecting and milling spell pages. One-time per patch.

### Step 5a - capture Wowhead (one paste)

`scrape_crawl.js` is capture-only: paste it into the browser console on ANY
page of the target version's Wowhead subsite (e.g. any /mop-classic/ page).
It builds the URL manifest itself - every profession page plus Milling and
Prospecting, including the per-item quantity pass - loads each one, and
downloads exactly two files:

    recipes_raw_<ver>.json    { skillLine: [raw listview rows...] }
    converts_raw_<ver>.json   { Milling|Prospecting: { rows, qty } }

No transforms happen in the browser. A page it cannot load is named in the
run report; re-run, or check whether Wowhead moved the URL.

### Step 5b - the emitted files

The scraper emits three files directly, each suffixed by version (the MoP run
produces whRecipeProgression_mop.lua etc.; TBC produces ..._tbc.lua). All
entries use keyed fields (read as `entry.field`, not `entry[n]`):

- `whRecipeProgression_<ver>.lua` - `[recipeID] = {learn, item, min, max, skillupCnt, source={...}, colors={o,y,g,grey}}`.
  The full per-recipe scrape record: learn-rank, the crafted item and its yield
  (min..max; equal for fixed-yield, a range for bombs/dynamite/some cooking),
  skill-ups per craft, acquisition source, and the four difficulty band starts.
  Yield comes from the `creates` field, not DB2: DB2's EffectBasePoints/
  EffectDieSides encoding is inconsistent across versions and misreads fixed yields
  (it can give 0 for a recipe that makes 1), so the scrape is the yield source.
- `whRecipeGate_<ver>.lua` - `[recipeID] = {class=classMask, faction=0/1/2, spec=specSpellID}`
  (faction enum: 0 both, 1 Alliance, 2 Horde; only gated recipes appear)
- `whProfessionTiers_<ver>.lua` - `[skillLine] = { {rank=learnRank, spell=spellID}, ... }`, the
  profession tier unlocks (outer is an ordered list, inner pairs are keyed). MoP
  has 8 (Apprentice..Zen Master); TBC has 5 (Apprentice..Master, capping at the
  375 skill ceiling).

It handles the non-recipe rows: a `creates`-less row named after the profession is
a tier unlock; its IDs ascend with tier, so the thresholds 1/50/125/200/275/350/
425/500 map positionally (TBC simply uses the first 5). A tier row may carry a
`rank` field naming the tier ("Apprentice", "Master", ...) - this is NOT a
disqualifier, because multi-rank *recipes* have `creates` and never reach the tier
branch. Passives (Toughness, Find Minerals, base Smelting) carry `scaling` and are
dropped. Engineering carries one extra profession-named non-tier (49383) excluded
by ID. Release Spirit (110955) is excluded as a cross-profession non-recipe. The
scraper warns at the console if any profession yields 0 tiers (the tier test
matched nothing - a sign the naming differs) or more tiers than there are
thresholds.

### Step 5b.1 - re-check the hand-curated patch file

data/patchRecipeProgression_mop.lua overlays recipes the Wowhead scrape wrongly
excludes (its header documents each entry's evidence). After a re-scrape, check
whether any patched recipeID now appears in the fresh whRecipeProgression file -
if Wowhead fixed its classification, the patch entry is redundant and gets
removed. Any entry still absent from the scrape stays.

### Step 5c - Prospecting & Milling conversion tables (graduated from "bonus")

Both scrapers now emit these as FINAL-FORM data files - milling_mop.lua /
prospecting_mop.lua under `Addon.data.*`, chances as 0-1 fractions with
"primary"/"proc" tiers assigned and results sorted best-first. Conversion
happens at emit; the addon only reads (logic/recipeCatalog.lua, the conversion section).

These tables carry no provenance prefix: milling/prospecting have exactly
one source (no DB2 counterpart exists - conversion results are server-side
loot tables), so there is nothing to disambiguate.

The crawler covers these pages in its manifest automatically, and runs a
QUANTITY PASS afterward: per-proc stack ranges (the "2-3" on Wowhead's row
icons) live on each SOURCE ITEM's page, not the spell page, so the crawler
fetches every source item once and merges qty = {min,max} into the results.
Pages without stack data are reported; their results ship without qty and
consumers treat that as 1 per proc (conservative). Running
re-running the crawl for the Milling (spell=51005) or Prospecting
(spell=31252) page emits the same file, plus the raw listview JSON for
design-side provenance/diffing (never shipped).

Data semantics: chances are independent per-cast presence probabilities
(not a distribution), sourced from Wowhead's sample counts (count/outof -
the page-displayed `percent` is runtime-derived and is NOT consumed).
Per-proc quantity is absent from this source; consumers treat it as 1
(conservative) until a quantity source is added.

## Step 6 - Loading (already wired; no per-patch work)

The TOC loads only the matching build's files via per-file conditions:

    data\dbRecipeReagents_mop.lua [AllowLoadGameType mists]
    data\dbRecipeReagents_tbc.lua [AllowLoadGameType tbc]
    data\whRecipeProgression_mop.lua [AllowLoadGameType mists]
    data\whRecipeProgression_tbc.lua [AllowLoadGameType tbc]
    data\patchRecipeProgression_mop.lua [AllowLoadGameType mists]
    ... (whRecipeGate, whProfessionTiers, dbRecipeCooldown follow the same pattern)

The client loads only its own datasets, and logic/recipeCatalog consolidates
them (applying the patch overlay) for every consumer. This needs no change at
patch time unless a new client flavor is added - drop the regenerated files in
place under the same names and everything downstream is untouched.

---

## Field reference (dbRecipeReagents)

Each entry: `[recipeID] = { skill=skillLine, reagents={{reagentID,count},...} }`

- recipeID  - the Spell ID (matches what Crafty parses from a recipe link)
- skill     - profession SkillLine ID
- reagents  - list of {reagentItemID, count}; empty {} when the recipe consumes
              no items

Output (item/yield/skill-ups) is not in this file - it is in the scrape's
whRecipeProgression_<ver>.lua, from the `creates` field (see Step 5). Difficulty
is not here either: for a learned recipe the game's live trade-skill API gives
the color directly (logic/difficulty.lua reads the GetTradeSkillInfo skillType
string); for unlearned recipes the learn-rank, difficulty thresholds, output,
gating, and tier unlocks all come from the scrape (whRecipeProgression /
whRecipeGate / whProfessionTiers). See Step 5.

Re-export is only needed when a patch changes recipes or reagents.
