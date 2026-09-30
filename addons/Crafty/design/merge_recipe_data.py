#!/usr/bin/env python3
"""Recipe data build step: joins DB2 client data with Wowhead capture into the
shipped data files plus review artifacts.

Pipeline position (see design/patch-day.md):
    fetch-db2-closure.sh <build>   -> db2 CSVs        (capture, DB2 side)
    scrape (browser, capture-only) -> wh raw files    (capture, WH side)
    merge_recipe_data.py           -> data/*.lua + review/*.csv   (ALL rules)

All transformation rules live HERE, in one auditable place: per-tier sourcing,
acquisition classification, arbiters, the orange=1 rule, patch overlay
application. Capture tools carry no rules.

Per-tier sourcing (verified in design/db2-findings.md):
    yellow = DB2 TrivialSkillLineRankLow; WH for the perk recipes (both
             trivial fields placeholder)
    grey   = DB2 TrivialSkillLineRankHigh; WH for perk recipes; where both
             real and disagreeing, midpoint identity arbitrates
    green  = floor((yellow+grey)/2), never stored
    orange = by acquisition class:
             item-taught -> teaching item's RequiredSkillRank
             perk        -> MinSkillLineRank
             auto        -> MinSkillLineRank where real, else orange=1 rule
             trainer     -> WH learn value (cross-checked)
             residue     -> WH, flagged for review

Usage:
    merge_recipe_data.py --db2 <dir> [--wh <dir>] [--out <dir>]
Without --wh, runs the DB2 stage only and emits the DB2 fact set
(db2facts_<flavor>.csv + .json) - the DB2 half of the review artifact.
"""

import argparse, csv, json, os, sys
from collections import defaultdict, Counter

SKILL_LINES = {
    '164': 'Blacksmithing', '165': 'Leatherworking', '171': 'Alchemy',
    '185': 'Cooking', '186': 'Mining', '197': 'Tailoring',
    '202': 'Engineering', '333': 'Enchanting', '755': 'Jewelcrafting',
    '773': 'Inscription', '129': 'First Aid',

    # Cooking is the only profession DB2 splits into child skill lines, and it
    # puts the MoP specialisations there: 45 recipes across the six Ways and the
    # two starter cookbooks. Wowhead lists them all under 185, so the crawl
    # captured them - but keying the DB2 pass on the parent alone dropped every
    # one, and they reached the list from the live scan with no stored row to
    # colour them or fill the detail panel from.
    #
    # They map to Cooking rather than to themselves: the player has ONE Cooking
    # skill, and everything downstream - the panel, the ledger, the footer -
    # asks which profession a recipe belongs to. Reporting the child would
    # fragment all of it.
    '975': 'Cooking',   # Way of the Grill
    '976': 'Cooking',   # Way of the Wok
    '977': 'Cooking',   # Way of the Pot
    '978': 'Cooking',   # Way of the Steamer
    '979': 'Cooking',   # Way of the Oven
    '980': 'Cooking',   # Way of the Brew
    '981': 'Cooking',   # Apprentice Cookbook
    '982': 'Cooking',   # Journeyman Cookbook
}
# DB2 splits Cooking into child skill lines and puts the MoP specialisations
# there. Everything else in this file - and everything in the addon - works in
# parent skill lines, so a child is folded into its parent as the rows are read.
PARENT_LINE = {'975': '185', '976': '185', '977': '185', '978': '185',
               '979': '185', '980': '185', '981': '185', '982': '185'}

CRAFT_EFFECTS = {'24', '53', '54', '101', '156', '157'}   # create item / enchant / add socket / feed pet / create loot
RANK_WORDS = ('Apprentice', 'Journeyman', 'Expert', 'Artisan', 'Master',
              'Grand Master', 'Illustrious', 'Zen Master')
GENERIC_LEARN_SPELL = '483'


def read(db2dir, table, build):
    path = os.path.join(db2dir, f"{table}_{build.replace('.', '_')}.csv")
    with open(path, newline='', encoding='utf-8') as f:
        yield from csv.DictReader(f)


def build_db2_facts(db2dir, build):
    names = {r['ID']: r['Name_lang'] for r in read(db2dir, 'SpellName', build)}

    # --- SkillLineAbility: one fact row per recipe spell, all SLA rows folded.
    rows_by_spell = defaultdict(list)
    superceded = set()
    for r in read(db2dir, 'SkillLineAbility', build):
        if r['SkillLine'] in SKILL_LINES:
            # A child skill line becomes its parent HERE, once, so nothing
            # downstream has to know DB2 splits Cooking into six Ways. The
            # player has one Cooking skill; the split is a DB2 detail.
            if r['SkillLine'] in PARENT_LINE:
                r['_childLine'] = r['SkillLine']
                r['SkillLine'] = PARENT_LINE[r['SkillLine']]
            rows_by_spell[r['Spell']].append(r)
            if r.get('SupercedesSpell', '0') != '0':
                superceded.add(r['SupercedesSpell'])
                SUPERCEDES[r['Spell']] = r['SupercedesSpell']

    # --- SpellEffect: craft detection + teacher spells (Effect 36).
    craft, teachers = set(), defaultdict(set)   # taught spell -> teacher spells
    creates = {}                                # spell -> item it makes
    augments = {}                               # spell -> acts on an owned item
    for r in read(db2dir, 'SpellEffect', build):
        sid = r['SpellID']
        if sid in rows_by_spell and r['Effect'] in CRAFT_EFFECTS:
            craft.add(sid)
            # Effect 24 names the item created. Only needed where Wowhead has
            # no row to take it from, but it costs nothing to record here.
            if r['EffectIndex'] == '0' and r['Effect'] in ('53', '156'):
                augments[sid] = True
            if r['Effect'] == '24' and r.get('EffectItemType', '0') != '0':
                # EffectBasePoints is the quantity produced; EffectDieSides > 0
                # makes it a roll of base+1 .. base+sides. Validated against
                # every recipe Wowhead does carry: 4,684 agree, none disagree.
                bp = int(r.get('EffectBasePoints') or 0)
                ds = int(r.get('EffectDieSides') or 0)
                creates[sid] = (int(r['EffectItemType']),
                                bp + 1 if ds > 0 else bp,
                                bp + ds if ds > 0 else bp)
        if r['Effect'] == '36' and r['EffectTriggerSpell'] in rows_by_spell:
            teachers[r['EffectTriggerSpell']].add(sid)

    # --- ItemEffect TriggerType=6: teaching items; 483 is the generic Learn.
    teaching_item = {}
    for r in read(db2dir, 'ItemEffect', build):
        if r['TriggerType'] == '6' and r['SpellID'] in rows_by_spell:
            teaching_item.setdefault(r['SpellID'], r['ParentItemID'])

    item_req = {}
    wanted = set(teaching_item.values())
    for r in read(db2dir, 'ItemSparse', build):
        if r['ID'] in wanted:
            item_req[r['ID']] = (r['Display_lang'], r['RequiredSkill'],
                                 int(r['RequiredSkillRank'] or 0))

    # --- Script-taught recipe books: 'X and Its Uses' teaches recipe X via a
    # server script (Effect 77); the link is name-derived, req = book req.
    books_by_item = {}
    for r in read(db2dir, 'ItemSparse', build):
        if 'and Its Uses' in r['Display_lang']:
            nm = r['Display_lang'].split(': ', 1)[-1].replace(' and Its Uses', '')
            BOOKS[nm] = int(r['RequiredSkillRank'] or 0)
            BOOKS['Accelerated ' + nm] = int(r['RequiredSkillRank'] or 0)

    # --- Mechanic 28 = MECHANIC_DISCOVERY (discovery-capable casts).
    mech28 = {r['SpellID'] for r in read(db2dir, 'SpellCategories', build)
              if r['Mechanic'] == '28' and r['SpellID'] in rows_by_spell}

    facts, flags = {}, []
    for sp, rows in rows_by_spell.items():
        if sp in NONCRAFTS:
            continue
        methods = sorted({r['AcquireMethod'] for r in rows})
        ranked = (sp in superceded
                  or any(r.get('SupercedesSpell', '0') != '0' for r in rows))
        trivials = {(int(r['TrivialSkillLineRankLow']),
                     int(r['TrivialSkillLineRankHigh'])) for r in rows}
        if len(trivials) > 1:
            flags.append((sp, 'sla-rows-disagree-on-trivials', str(sorted(trivials))))
        lo, hi = max(trivials)               # placeholder rows sort below real ones
        minskill = max(int(r['MinSkillLineRank']) for r in rows)
        real_trivials = lo > 1 and hi > 1
        perk = not real_trivials and minskill > 1 and sp in craft

        # acquisition class, by source-evidence precedence
        teach = teachers.get(sp, set())
        rank_taught = any(any(w in names.get(t, '') for w in RANK_WORDS)
                          for t in teach)
        if sp in teaching_item:
            acq = 'item'
        elif rank_taught:
            acq = 'trainer-rank'
        elif teach:
            acq = 'special'
        elif '1' in methods:
            acq = 'auto'
        elif '2' in methods:
            acq = 'racial'
        elif sp in craft:
            acq = 'residue'                 # trainer UNION discovery; WH splits
        else:
            acq = 'non-craft'

        # DB2-sourced orange, where DB2 carries it
        orange, osrc = None, None
        if acq == 'item':
            item = teaching_item[sp]
            nm, skill, req = item_req.get(item, ('?', '0', 0))
            if skill != '0' and skill != rows[0]['SkillLine']:
                flags.append((sp, 'item-profession-mismatch', f'{nm} skill {skill}'))
            # The schematic's RequiredSkillRank is the skill to USE the book,
            # which is the acquisition skill only if the book is how you get the
            # recipe. DB2 keeps a teaching item forever - Schematic: Goblin
            # Rocket Boots is a TBC item still linked in MoP, where the recipe
            # is trainer-only - and carries no obtainability tell (PATTERNS.md,
            # worked negative). Wowhead absence is the signal the rest of the
            # pipeline uses, so require a captured taught-by-item path before
            # believing the item is the route.
            if not item_taught(sp):
                flags.append((sp, 'teaching-item-unobtainable',
                              f'{nm} req {req}; no taught-by-item path'))
            elif req > 0:
                orange, osrc = req, 'db2:item-req'
            else:
                flags.append((sp, 'item-req-zero', nm))
        elif perk:
            orange, osrc = minskill, 'db2:minskill'
        elif acq == 'auto' and minskill > 1:
            orange, osrc = minskill, 'db2:minskill'
        elif acq == 'auto':
            orange, osrc = None, 'rule:orange1-candidate'   # finalized vs WH zero

        facts[sp] = {
            'spell': sp, 'name': names.get(sp, '?'),
            'profession': SKILL_LINES[rows[0]['SkillLine']],
            'parent_line': rows[0]['SkillLine'],
            'creates_item': creates.get(sp),
            # AUGMENTS an item rather than creating one: ENCHANT_ITEM and
            # ADD_SOCKET both act on something already owned, and that is what
            # makes a profession's alternate verb the right word for its button.
            'augments': augments.get(sp) or None,
            'numskillups': int(rows[0].get('NumSkillUps') or 0) or None,
            'child_line': rows[0].get('_childLine'),
            'is_craft': sp in craft, 'acq': acq, 'methods': '+'.join(methods),
            'yellow_db2': lo if real_trivials else None,
            'grey_db2': hi if real_trivials else None,
            'minskill': minskill if minskill > 1 else None,
            'orange_db2': orange, 'orange_src': osrc,
            'teaching_item': teaching_item.get(sp),
            'mech28': sp in mech28, 'ranked': ranked,
        }
        if orange and real_trivials and orange > lo:
            facts[sp]['note'] = 'orange>yellow: orange tier empty (learned late)'

    # Tier ladders, from DB2 for every profession (crafting and gathering). The
    # full SkillLineAbility is re-read unfiltered because tiers live on skill
    # lines the recipe pass skips (the gatherers) and on the parent lines, not
    # the Cooking children. One authoritative source, replacing the old
    # crawl-name-matching that needed a hand exclusion list.
    all_sla = list(read(db2dir, 'SkillLineAbility', build))
    tiers = {sk: db2_tier_chain(sk, all_sla, names) for sk in DISPLAY}
    globals()['TIERS'] = tiers

    return facts, flags


def write_facts(facts, flags, outdir, flavor):
    os.makedirs(outdir, exist_ok=True)
    cols = ['spell', 'name', 'profession', 'is_craft', 'acq', 'methods',
            'orange_db2', 'orange_src', 'yellow_db2', 'grey_db2', 'minskill',
            'teaching_item', 'mech28', 'note']
    path = os.path.join(outdir, f'db2facts_{flavor}.csv')
    with open(path, 'w', newline='', encoding='utf-8') as f:
        w = csv.DictWriter(f, fieldnames=cols)
        w.writeheader()
        for sp in sorted(facts, key=lambda s: (facts[s]['profession'], int(s))):
            w.writerow({c: facts[sp].get(c, '') for c in cols})
    with open(os.path.join(outdir, f'db2facts_{flavor}.json'), 'w') as f:
        json.dump(facts, f)
    fpath = os.path.join(outdir, f'db2flags_{flavor}.csv')
    with open(fpath, 'w', newline='', encoding='utf-8') as f:
        w = csv.writer(f)
        w.writerow(['spell', 'flag', 'detail'])
        w.writerows(flags)
    return path


# --- WH capture: the crawler's recipes_raw_<ver>.json (one paste of
# design/scrape_crawl.js downloads it - {skillLine: [rows...]}), or any *.json
# of raw listviewspells arrays.
# Row schema (consumed fields, per the crawl verifier's contract):
#   id, name, learnedat (9999 = always-known -> 1), colors [o,y,g,grey],
#   source [codes], creates [item,min,max], reagents [[item,n]..],
#   nskillup, skill [profID], rank
WH_TRAINER = 6
# Crafty-assigned source code, outside Wowhead's numbering: granted with the
# profession itself (the starter set that arrives on learning it). Wowhead
# tags these with nothing, but the origin is certain.
SRC_PROFESSION_GRANT = 100
WH_SOURCE = {1: 'drop', 2: 'quest', 4: 'vendor', 5: 'world', 6: 'trainer',
             7: 'discovery', 12: 'achievement', 16: 'world', 21: 'questreward',
             22: 'instance', SRC_PROFESSION_GRANT: 'profession-grant'}


def load_sources(path):
    """The per-recipe source detail from the crawler's source pass.

    Which listviews a page carries IS the answer - a page with a trainer
    listview is trainer-taught, one with an item listview is taught by that
    item, and both means two acquisition paths.

    `path` may be a single capture file or a DIRECTORY of chunk files: the
    crawler writes sources_raw_<ver>_partN.json as it goes, because the whole
    capture cannot live in the browser's storage. Chunks are merged in order;
    each carries the NPC table as it stood, and later ones supersede.
    """
    if not path:
        return {}
    if os.path.isdir(path):
        import glob as _g
        parts = sorted(_g.glob(os.path.join(path, 'sources_raw_*part*.json')),
                       key=lambda p: int(''.join(c for c in os.path.basename(p)
                                                 .rsplit('part', 1)[-1]
                                                 if c.isdigit()) or 0))
        if not parts:
            parts = _g.glob(os.path.join(path, 'sources_raw_*.json'))
        out = {}
        for p in parts:
            out.update(load_sources(p))
        if parts:
            print(f'loaded {len(parts)} source chunk(s)')
        return out
    if not os.path.exists(path):
        return {}
    blob = json.load(open(path))
    # The capture normalizes trainers: an NPC is stored once in `npcs` and
    # recipes carry only ids under taught-by-npc. (Inlining them was 95% of
    # the capture's size and would not fit the browser's storage quota.)
    if 'recipes' in blob and 'npcs' in blob:
        for nid, n in blob['npcs'].items():
            NPCS[int(nid)] = {'name': n.get('name'), 'tag': n.get('tag'),
                              'zones': n.get('zones') or []}
        return blob['recipes']
    return blob


def item_taught(spellID):
    """Whether the capture shows a teaching ITEM for this recipe.

    DB2 links a teaching item whether or not it can still be obtained, and
    carries no column that tells the two apart. A captured taught-by-item
    listview does, and is the obtainability signal used elsewhere here.
    """
    return bool((SOURCES.get(str(spellID)) or {}).get('taught-by-item'))


def source_facts(sources, sp):
    """Acquisition paths for one recipe, from its captured page.

    Returns {paths: [...]} where each path is a dict carrying the kind and
    whatever detail that kind has: trainers name their NPCs and zones, items
    name the teaching item and its own skill requirement plus where THAT comes
    from, quests name the quest and its level.

    A quest's reqlevel is the level gate on TAKING THAT QUEST, and it stays on
    that path. It is not the recipe's own character-level gate: a recipe with
    both a quest and a trainer is learnable from the trainer with no such gate.
    Recipe-level levelReq comes from verdicts, which state it as a fact about
    the recipe rather than inferring it from one of its paths.
    """
    page = sources.get(str(sp))
    if not page:
        return None
    # The capture keeps every listview under its own Wowhead id; the merge
    # decides which ones carry acquisition facts. Anything else on the page
    # (achievement criteria, related recipes) stays in the capture for
    # whenever a question needs it.
    paths = []
    for t in page.get('taught-by-npc') or []:
        # Already normalized by the capture: an id, not a row. Older captures
        # inlined the whole NPC, so both shapes are accepted.
        if isinstance(t, dict):
            NPCS[t['id']] = {'name': t.get('name'), 'tag': t.get('tag'),
                             'zones': t.get('location') or []}
            paths.append({'kind': 'trainer', 'npc': t.get('id')})
        else:
            paths.append({'kind': 'trainer', 'npc': t})
    for it in page.get('taught-by-item') or []:
        p = {'kind': 'item', 'item': it.get('id'), 'name': it.get('name'),
             'req': it.get('skill')}
        if it.get('commondrop'):
            p['from'] = 'commondrop'
        for sm in it.get('sourcemore') or []:
            p['from'] = 'drop' if sm.get('dd') else 'vendor'
            if sm.get('ti'):
                NPCS[sm['ti']] = {'name': sm.get('n'),
                                  'zones': [sm['z']] if sm.get('z') else []}
                p['fromID'] = sm['ti']
        paths.append(p)
    for q in page.get('reward-from-q') or []:
        paths.append({'kind': 'quest', 'quest': q.get('id'),
                      'name': q.get('name'), 'reqlevel': q.get('reqlevel')})
    return {'paths': paths}


# Origin kinds carried ONLY by the recipe's raw source codes - they have no
# detailed listview (no NPC/item/quest to record) and no other authoritative
# store (unlike trainer=packed set, item/quest=path records, discovery=the
# discoverer-side M:M table). So they become bare path entries, kind alone.
# The detailed/otherwise-stored kinds are excluded here: trainer(6) is the
# packed trainer set, vendor(4) rides an item path, quest(2)/questreward(21)
# are quest paths, discovery(7) is the discovery table. What remains is the
# origin-only set.
_ORIGIN_ONLY = {1: 'drop', 5: 'world', 12: 'achievement', 16: 'world',
                22: 'instance', SRC_PROFESSION_GRANT: 'grant'}


def origin_paths(source_codes):
    """Bare path entries for the origin-only source codes of a recipe.

    De-duplicated by kind (5 and 16 both mean world). Empty when the recipe's
    origins are all covered by trainers / detailed paths / the discovery table.
    """
    kinds = []
    seen = set()
    for code in source_codes or []:
        kind = _ORIGIN_ONLY.get(code)
        if kind and kind not in seen:
            seen.add(kind)
            kinds.append({'kind': kind})
    return kinds


def load_wh(whpath):
    import glob
    files = ([whpath] if os.path.isfile(whpath)
             else glob.glob(os.path.join(whpath, '*.json')))
    rows = {}
    for fn in files:
        data = json.load(open(fn))
        pages = data.values() if isinstance(data, dict) else [data]
        for page in pages:
            for r in page:
                rows[str(r['id'])] = r
    if not rows:
        sys.exit(f'WH stage: no capture rows found at {whpath}')
    by_skill = {}
    for r in rows.values():
        sk = r.get('skill') or [0]
        by_skill.setdefault(str(sk[0]), []).append(r)
    return rows, by_skill


def midpoint_ok(y, g, green):
    return y is not None and g is not None and green == (y + g) // 2


DISPLAY = {'129': 'First Aid', '164': 'Blacksmithing', '165': 'Leatherworking',
           '171': 'Alchemy', '185': 'Cooking', '186': 'Mining',
           '197': 'Tailoring', '202': 'Engineering', '333': 'Enchanting',
           '755': 'Jewelcrafting', '773': 'Inscription',
           '182': 'Herbalism', '393': 'Skinning', '356': 'Fishing'}
EMIT_ORDER = ['129', '164', '165', '171', '185', '186', '197', '202', '333',
              '755', '773', '182', '356', '393']
# The eight-tier ladder, unchanged from vanilla through Mists (it only breaks in
# Battle for Azeroth). Skill requirement, then the CHARACTER LEVEL gate, which no
# reachable data source carries: SkillLineAbility.MinSkillLineRank is 1 for every
# tier spell, SpellLevels has no row for any of them, SkillRaceClassInfo.MinLevel
# is 0 for all fourteen professions, and Wowhead's spell rows report level 0.
# The trainer states it - "Requires: Level 35, First Aid (200)" - and so do the
# wikis, consistently.
TIER_RANKS = [1, 50, 125, 200, 275, 350, 425, 500]

# Two places the level gate is not flat:
#   Apprentice is level 5 for a PRIMARY profession and unrestricted for a
#   secondary one. Only Apprentice - First Aid is secondary and still gates
#   Artisan at 35.
#   Grand Master is 65 for crafting and 55 for GATHERING.
TIER_LEVELS          = [5, 10, 20, 35, 50, 65, 75, 80]
TIER_LEVELS_GATHER   = [5, 10, 20, 35, 50, 55, 75, 80]
GATHERING_SKILLS     = {'182', '186', '393'}   # Herbalism, Mining, Skinning
SECONDARY_SKILLS     = {'129', '185', '356'}   # First Aid, Cooking, Fishing


def tier_level(skill_line, index):
    """Character level to train tier `index` (0-based) of this skill line."""
    ladder = TIER_LEVELS_GATHER if skill_line in GATHERING_SKILLS else TIER_LEVELS
    if index >= len(ladder):
        return 0
    if index == 0 and skill_line in SECONDARY_SKILLS:
        return 0        # a secondary profession may be started at any level
    return ladder[index]
# The tier ability whose SupercedesSpell chain IS the profession's tier ladder.
# Almost always the profession's own name, but a gathering profession's ladder
# is its gathering ABILITY, which differs for Herbalism ("Herb Gathering").
TIER_ABILITY = {'182': 'Herb Gathering', '393': 'Skinning', '356': 'Fishing'}


def db2_tier_chain(sk, sla, names):
    """The profession's tier ladder as an ordered list of spell ids, from DB2.

    A profession's eight ranks (Apprentice up) are a SupercedesSpell chain of
    the tier ability - each rank superceding the one below. This is the
    authoritative tier ladder for EVERY profession, crafting and gathering
    alike: verified to reproduce all eleven crafting professions' tiers exactly,
    and to exclude non-tier abilities the name alone would catch (the
    Engineering passive 49383 is named "Engineering" but is not in the chain).

    The chain gives tiers in rank order intrinsically - no sort by spell id,
    which was only ever a proxy for rank order and is not guaranteed monotonic.

    @param sk skill-line id (string)
    @param sla the SkillLineAbility rows (list of dicts)
    @param names spell id -> name
    @return [spellID, ...] in ascending tier order, or [] if none
    """
    ability = TIER_ABILITY.get(sk, DISPLAY.get(sk))
    rows = [r for r in sla if r['SkillLine'] == sk
            and names.get(r['Spell']) == ability]
    by_super = {r.get('SupercedesSpell'): r for r in rows}
    root = next((r for r in rows if r.get('SupercedesSpell', '0') == '0'), None)
    chain, cur = [], root
    while cur:
        chain.append(int(cur['Spell']))
        cur = by_super.get(cur['Spell'])
    return chain
GENERAL_MAX = {'mop': 600, 'tbc': 375}
NONCRAFTS = {'110955', '105518'}   # Release Spirit, Open Box: skill-up actions,
                                   # not recipes (named exclusions, est. Jul 1)
FACTION_MASK = {18875469: 1, 33555378: 2}   # Alliance, Horde


TRAINER_VERDICTS = {}


SKILL_OF = {}

# Gathering / non-craft trainers have no craft recipes of their own, so every
# recipe attributed to them is foreign and is stripped. Recognised by the
# profession word (or role) in the tag or name.
_GATHERING_TAGS = ('Skinning', 'Herbalism', 'Fishing', 'Flying Trainer')
_GATHERING = object()   # sentinel: strip every recipe

# Generic multi-profession trainers legitimately teach every profession.
_GENERIC_TAGS = ('Profession Trainer', 'Professions Trainer & Vendor')

# Titles that name a profession without containing the profession word. A closed
# set, verified against the full tag universe of the capture.
_TITLE_PROFESSION = {
    'Head Chef': 'Cooking',
    'Barmaid': 'Cooking',
    'Superior Butcher': 'Cooking',
    'Guide to the Ways': 'Cooking',
    "Explorers' League": 'Mining',
}

# Profession words as they appear in tags/names, including agent-noun stems
# ("Blacksmith Trainer", "The Tailor of Pandaria", "Apprentice Jewelcrafter").
# Each stem maps to its DB2 profession string. Longest stems first so
# "Blacksmithing" is not also matched as the shorter "Blacksmith" twice - the
# match is by set membership, so duplicates collapse, but ordering keeps intent
# clear.
_PROFESSION_STEMS = {
    'Alchemy': 'Alchemy',
    'Blacksmith': 'Blacksmithing',      # covers Blacksmith and Blacksmithing
    'Enchant': 'Enchanting',
    'Engineer': 'Engineering',          # covers Gnomish/Goblin Engineering
    'Inscription': 'Inscription',
    'Jewelcraft': 'Jewelcrafting',      # covers Jewelcrafter and Jewelcrafting
    'Leatherwork': 'Leatherworking',
    'Tailor': 'Tailoring',              # covers Tailor and Tailoring
    'Cooking': 'Cooking',
    'First Aid': 'First Aid',
    'Mining': 'Mining',
}


def _professions_in(text):
    """The set of DB2 professions a tag or name names, by stem match."""
    return {prof for stem, prof in _PROFESSION_STEMS.items() if stem in text}


def _resolve_npc_professions():
    """The one profession each trainer NPC teaches, or a keep-signal.

    A trainer teaches exactly one profession, and that is a fact about the
    trainer's IDENTITY - its tag or its name - never about how many recipes
    Wowhead happened to attribute to it. Recipe counts are the corruption
    itself: Wowhead dumps whole catalogues onto the wrong NPC, and the dumped
    catalogue is often larger than the real one (Apothecary Cheng's corrupt
    Tailoring 255 dwarfs his real First Aid 20; Head Chef carries only a dumped
    First Aid set and no Cooking at all). So counts point AT the corruption in
    exactly the cases that matter, and are not consulted here.

    Identity resolves it, in order:

    - TAG names a profession word (incl. agent-noun stems: "Blacksmith" ->
      Blacksmithing, "Tailor" -> Tailoring, "Jewelcraft" -> Jewelcrafting).
      "Gnomish Engineering Trainer" and the "& Supplies" variants match the same
      way. Exactly one profession word -> that profession.
    - TAG is a known TITLE that names a profession without the word:
      Head Chef / Barmaid / Superior Butcher / Guide to the Ways -> Cooking;
      Explorers' League -> Mining. A closed set, verified against the full tag
      universe of the capture.
    - TAG is GENERIC ("Profession Trainer", "Professions Trainer & Vendor"):
      teaches every profession; never strip (None).
    - TAG or NAME is a GATHERING profession (Skinning/Herbalism/Fishing) or a
      non-craft trainer (Flying Trainer): no craft recipes are its own, so every
      recipe attributed is foreign -> _GATHERING (strip all).
    - NAME is a bare profession (the Shattrath trainers are literally named
      "Alchemy", "Blacksmithing", ...) -> that profession.
    - Nothing identifies it -> None (left for a hand verdict, not guessed).

    @return { npcID: profession | None | _GATHERING }
    """
    resolved = {}
    for nid, n in NPCS.items():
        tag = n.get('tag') or ''
        name = n.get('name') or ''

        # Gathering / non-craft trainer: strip all attributed craft recipes.
        if any(g in tag or g in name for g in _GATHERING_TAGS):
            resolved[nid] = _GATHERING
            continue
        # Generic multi-profession trainer: teaches everything, strip nothing.
        if any(g in tag for g in _GENERIC_TAGS):
            resolved[nid] = None
            continue
        # A known title that names a profession without the profession word.
        if tag in _TITLE_PROFESSION:
            resolved[nid] = _TITLE_PROFESSION[tag]
            continue
        # A profession word (or agent-noun stem) in the tag. Exactly one wins;
        # zero or an ambiguous several -> fall through.
        named = _professions_in(tag)
        if len(named) == 1:
            resolved[nid] = next(iter(named))
            continue
        # The NPC's own name IS a profession (the Shattrath trainers).
        named = _professions_in(name)
        if len(named) == 1:
            resolved[nid] = next(iter(named))
            continue
        # Unidentifiable from identity - a hand verdict decides, never a guess.
        resolved[nid] = None
    return resolved


def audit_trainer_professions(sources, facts):
    """Strip cross-profession trainer attributions Wowhead got wrong, using DB2.

    Wowhead's taught-by-npc copies whole catalogues onto the wrong NPC - an
    Engineering trainer carrying Alchemy's full list, a Skinning trainer
    carrying Blacksmithing's. Each trainer teaches one profession; a recipe
    whose DB2 profession is a DIFFERENT profession than the trainer teaches is a
    corrupt attribution, and is removed.

    Two independent sources decide it. DB2's SkillLineAbility names each recipe's
    real profession (not Wowhead's own skill field, which is the same source as
    the corruption). And the trainer's own profession is read from its tag via
    DB2 consensus among same-tagged peers - so titles resolve ("Head Chef" ->
    Cooking) and a trainer whose own catalogue is mostly corrupt is still pinned
    to its real profession by its peers.

    A gathering-tagged trainer (Skinning, Herbalism) resolves to no profession -
    its skill has no recipes - so every recipe on it is foreign and stripped,
    correctly leaving it with none.

    Mutates taught-by-npc in place, like apply_trainer_verdicts, so paths and
    the trainer sets downstream see the corrected relation.
    """
    npc_prof = _resolve_npc_professions()

    changed = Counter()
    for spellID, page in sources.items():
        listed = page.get('taught-by-npc')
        if not listed:
            continue
        fact = facts.get(str(spellID))
        recipe_prof = fact and fact.get('profession')
        if not recipe_prof:
            # No DB2 profession for this recipe - no independent authority to
            # check the attribution against, so it is left as captured.
            continue
        kept = []
        for npc in listed:
            nid = int(npc) if str(npc).isdigit() else None
            # An NPC with a hand verdict is left entirely to it. Verdicts exist
            # for exactly the cases the audit cannot resolve: a unique tag with
            # no peers to vote and a mostly-corrupt own catalogue (Sungshin,
            # Skydancer), or a set the corruption REPLACED so it must be granted
            # back, not stripped (Ala'thinel). Running both would have the audit
            # strip on wrong-but-coincidental reasoning and the verdict clean up
            # after - two owners for one fact.
            if nid is not None and str(nid) in TRAINER_VERDICTS:
                kept.append(npc)
                continue
            want = npc_prof.get(nid) if nid is not None else None
            # _GATHERING keeps nothing (its skill has no craft recipes); a named
            # profession keeps only its own; None (unknown or generic
            # multi-trainer) keeps everything - no basis or no reason to strip.
            if want is _GATHERING or (want is not None and want != recipe_prof):
                changed[f'{npc} ({NPCS[nid]["name"]} '
                        f'<{NPCS[nid].get("tag") or ""}>) '
                        f'removed {recipe_prof}'] += 1
            else:
                kept.append(npc)
        if len(kept) != len(listed):
            page['taught-by-npc'] = kept
    for k, n in sorted(changed.items()):
        print('  trainer audit: %s x%d' % (k, n))


def apply_trainer_verdicts(sources):
    """Hand corrections for trainer attributions the DB2 audit cannot reach.

    audit_trainer_professions already strips cross-profession corruption from
    every trainer whose tag names one profession. What remains for a hand
    verdict is the residue that has no single-profession tag to key on: a title
    tag ('Head Chef'), a non-profession trainer that should teach nothing
    ('Flying Trainer'), or a corruption that replaced the real set so nothing
    correct is left to keep - the DB2 audit only removes, so it cannot grant the
    real set back. 'sameAs' does that from an exemplar; 'exceptProfession' keeps
    all but one profession; 'teaches: none' clears a non-profession trainer.

    Mutates the captured taught-by-npc lists in place, so everything downstream
    - paths, the trainer sets, recipesTaughtBy - sees the corrected relation
    without knowing this happened.
    """
    if not TRAINER_VERDICTS:
        return

    # Which skill line each recipe belongs to - needed to drop one profession's
    # worth from an NPC that legitimately teaches another.
    for spellID, page in sources.items():
        for row in (page.get('recipes') or []):
            if str(row.get('id')) == str(spellID) and row.get('skill'):
                SKILL_OF[str(spellID)] = row['skill'][0]

    # What each exemplar teaches, read from the capture before anything moves.
    exemplar = defaultdict(set)
    for spellID, page in sources.items():
        for npc in (page.get('taught-by-npc') or []):
            exemplar[str(npc)].add(str(spellID))

    changed = Counter()
    for npcID, v in TRAINER_VERDICTS.items():
        if npcID.startswith('_'):
            continue
        # 'exceptProfession' keeps everything the NPC legitimately teaches and
        # drops one profession's worth. The others replace outright.
        drop_prof = v.get('exceptProfession') if v.get('teaches') == 'exceptProfession' else None
        keep = (exemplar.get(str(v['sameAs'])) or set()
                if v.get('teaches') == 'sameAs' else set())
        if drop_prof is not None:
            keep = {sp for sp in (exemplar.get(npcID) or set())
                    if SKILL_OF.get(sp) != drop_prof}
        for spellID, page in sources.items():
            listed = page.get('taught-by-npc')
            if not listed:
                continue
            has = any(str(n) == npcID for n in listed)
            want = str(spellID) in keep
            if has and not want:
                page['taught-by-npc'] = [n for n in listed if str(n) != npcID]
                changed[npcID + ' removed'] += 1
            elif want and not has:
                listed.append(int(npcID))
                changed[npcID + ' added'] += 1
    for k, n in sorted(changed.items()):
        print('  trainer verdict: %s %d' % (k, n))


def lua_trainers(paths):
    """Serialize the trainer NPCs as a packed id list.

    A trainer "path" carries exactly one variable field - which NPC - and a
    kind that is constant across every one of them. That is a SET of ids, not a
    record, and writing it as one table per element cost 111x the memory of the
    string and 57,543 copies of a word that never varies.
    """
    npcs = [str(p['npc']) for p in paths if p['kind'] == 'trainer' and p.get('npc')]
    return '"' + ','.join(npcs) + '"' if npcs else None


def lua_paths(paths):
    """Serialize non-trainer acquisition paths as a Lua array of tables.

    These ARE records: an item path names the item, its own skill requirement,
    and where the item itself comes from; a quest path names the quest and its
    level. Fields vary per path, so each needs its own table. Only fields that
    are present are written - absent means unknown, never zero.
    """
    out = []
    for p in (q for q in paths if q['kind'] != 'trainer'):
        bits = [f'kind="{p["kind"]}"']
        for k in ('npc', 'item', 'quest', 'req', 'reqlevel', 'fromID', 'zone'):
            if p.get(k) is not None:
                bits.append(f'{k}={p[k]}')
        for k in ('name', 'from', 'fromName', 'tag'):
            if p.get(k):
                bits.append(f'{k}="{str(p[k]).replace(chr(34), "")}"')
        if p.get('zones'):
            bits.append('zones={' + ','.join(str(z) for z in p['zones']) + '}')
        out.append('{' + ', '.join(bits) + '}')
    return ('{' + ', '.join(out) + '}') if out else None


def emit_discovery(discovery_json, outdir, flavor, is_discoverer):
    """Which spell discovers which recipe, at what skill and what odds.

    From skill_discovery_template - Blizzard's own SERVER data, extracted by the
    emulators. Not a reconstruction: the shape (spellId, reqSpell, reqSkillValue,
    chance) and values like 0.1%, 20%, 30% are the server's constants, and
    nobody derives a 0.1% chance by playing. The union of a MoP-era core and a
    WotLK one, the latter carrying 23 rows the former dropped.

    NO CLIENT-SIDE EQUIVALENT EXISTS. Every SkillLineAbility field is identical
    between discovery recipes and the rest; a discovered recipe is defined by
    having no acquisition at all, and that is indistinguishable from Wowhead
    simply not recording one. Elimination was measured as a classifier and
    scores 0% precision in four professions.

    Stored DISCOVERER-side and grouped by (skill, chance): 61 discoverers
    against 812 recipes, and 236 recipes have more than one discoverer, so the
    recipe-side shape repeats the relation on both ends of a many-to-many.
    11 KB against 28. Recipe ids pack as a string for the same reason trainer
    sets do - it is a set of ids, and Lua interns one string per group.

    reqSpell 0 is the SKILL case: any discovery-capable craft of that
    profession, gated by Mechanic == MECHANIC_DISCOVERY on the spell being cast.
    Not any craft - a bandage rolls nothing.

    VERIFIED, and a failure is DROPPED rather than shipped. Every named
    discoverer must look like one in DB2 - either Mechanic 28, or the
    explicit-discovery shape the server tests for: effect 0 creates an item,
    effect 1 is SCRIPT_EFFECT. Both halves matter; Mechanic alone leaves the
    research recipes unverified.
    """
    if not discovery_json or not os.path.exists(discovery_json):
        return None
    os.makedirs(outdir, exist_ok=True)
    with open(discovery_json, encoding='utf-8') as fh:
        data = json.load(fh)

    # A discoverer the player can never cast is not shipped. The dumps carry
    # rows Blizzard never exposes - a QA variant of Northrend Inscription
    # Research, and the Tillers farm harvests - and REACHABILITY is what
    # separates them: a real discoverer is either a profession recipe
    # (SkillLineAbility) or a spell an item triggers (ItemEffect). The QA
    # variant and the harvests are neither.
    #
    # Shape is the wrong test. An item-use discoverer - Tome of Discovery, Book
    # of Glyph Mastery - carries only SCRIPT_EFFECT and looks nothing like a
    # profession recipe, so a shape test excludes real discoverers along with
    # everything they teach.
    dropped = [d for d in data if d != '0' and not is_discoverer(d)]
    for d in dropped:
        data.pop(d)
    if dropped:
        print('  discovery: dropped %d unreachable discoverers: %s'
              % (len(dropped), ','.join(sorted(dropped, key=int))))

    L = ['-- Crafty discovery relation (%s (design/merge_recipe_data.py))' % flavor,
         '--',
         '-- [discovererSpellID] = { {skill, chance, recipes="id,id,..."}, ... }',
         '-- [0] is the SKILL case: any discovery-capable craft of the profession.',
         '--',
         '-- See emit_discovery() for the source and why no client-side',
         '-- equivalent exists.',
         'local _, Addon = ...',
         'Addon.data = Addon.data or {}',
         'Addon.data.discovery = {']
    pairs = 0
    for disc in sorted(data, key=int):
        L.append('  [%s] = {' % disc)
        for terms, ids in sorted(data[disc].items(),
                                 key=lambda kv: int(kv[0].split('|')[0])):
            skill, chance = terms.split('|')
            L.append('    {skill=%s, chance=%s, recipes="%s"},'
                     % (int(skill), float(chance),
                        ','.join(str(i) for i in sorted(ids))))
            pairs += len(ids)
        L.append('  },')
    L.append('}')
    path = os.path.join(outdir, 'discovery_%s.lua' % flavor)
    with open(path, 'w', encoding='utf-8') as fh:
        fh.write('\n'.join(L) + '\n')
    print('emitted discovery_%s.lua (%d discoverers, %d relations)'
          % (flavor, len(data), pairs))
    return path


def emit_vendor_reagents(reagents_json, outdir, flavor):
    """Reagents a vendor sells at UNLIMITED stock for plain gold.

    Buying these is an errand, not a constraint, so they do not gate whether a
    recipe can be made. Unlimited stock is the test rather than "a vendor sells
    it": Linen Cloth has a vendor, at stock 5, and a shelf that empties is
    nothing like buying thread. GnomeWorks, Skillet and TSM all reached the same
    test independently - numAvailable == -1 at a live merchant window - which is
    the same fact read here from Wowhead's sold-by rows.

    Plain gold only. Of the 180 reagents with an unlimited vendor, 93 are sold
    for tokens or currency alone, which a fresh character cannot buy. The
    capture keeps their cost data for a later opt-in.

    No client-side source exists: DB2 ships no vendor table, ItemSparse has no
    flag separating vendor reagents from farmed ones (BuyPrice is set on Linen
    Cloth too), and GetItemInfo returns 18 fields, none of them this.
    """
    if not reagents_json or not os.path.exists(reagents_json):
        return None
    os.makedirs(outdir, exist_ok=True)
    with open(reagents_json, encoding='utf-8') as fh:
        data = json.load(fh)

    ids = []
    for itemID, rec in data.items():
        for row in (rec.get('listviews') or {}).get('sold-by') or []:
            if not isinstance(row, dict) or row.get('stock') != -1:
                continue
            cost = row.get('cost')
            if isinstance(cost, list) and cost and isinstance(cost[0], list) \
                    and len(cost[0]) > 1:
                continue        # token or currency, not plain gold
            ids.append(int(itemID))
            break

    ids.sort()
    L = ['-- Crafty vendor reagents (%s (design/merge_recipe_data.py))' % flavor,
         '--',
         '-- Reagents a vendor sells at UNLIMITED stock for plain gold. Buying these',
         '-- is an errand, not a constraint, so they do not gate craftability.',
         '-- See emit_vendor_reagents() for why no client-side source exists.',
         'local _, Addon = ...',
         'Addon.data = Addon.data or {}',
         'Addon.data.vendorReagents = {']
    L += ['  [%d] = true,' % i for i in ids]
    L.append('}')
    path = os.path.join(outdir, 'vendorReagents_%s.lua' % flavor)
    with open(path, 'w', encoding='utf-8') as fh:
        fh.write('\n'.join(L) + '\n')
    print('emitted vendorReagents_%s.lua (%d reagents)' % (flavor, len(ids)))
    return path


def emit_craft_verbs(db2dir, build, outdir, flavor):
    """The word a profession uses for AUGMENTING an item, per profession.

    SkillLine.AlternateVerb_lang carries it, localized, for the nine skill lines
    that have one: Enchanting "Enchant", Inscription "Inscribe", Leatherworking
    "Emboss", Tailoring "Embroider", Engineering "Tinker", Blacksmithing and
    Jewelcrafting "Modify". A profession without one - Alchemy makes potions,
    Cooking makes food - contributes nothing and keeps the create verb.

    NOT a per-profession override. A Blacksmithing sword is created and a
    Blacksmithing socket is a modification, so the verb belongs to the RECIPE:
    SpellEffect 53 (ENCHANT_ITEM) and 156 (ADD_SOCKET) are the augmenting ones,
    399 recipes across six professions. Everything else creates.
    """
    verbs = {}
    for r in read(db2dir, 'SkillLine', build):
        v = (r.get('AlternateVerb_lang') or '').strip()
        if v and r['ID'] in SKILL_LINES:
            verbs[r['ID']] = v
    if not verbs:
        return None

    os.makedirs(outdir, exist_ok=True)
    L = ['-- Crafty augment verbs (%s (design/merge_recipe_data.py))' % flavor,
         '--',
         '-- [skillLine] = "verb" - what this profession calls modifying an item,',
         '-- from SkillLine.AlternateVerb_lang, so it arrives in the player\'s',
         '-- language. Used for recipes whose effect augments rather than creates;',
         '-- see emit_craft_verbs.',
         'local _, Addon = ...',
         'Addon.data = Addon.data or {}',
         'Addon.data.augmentVerbs = {']
    for sk in sorted(verbs, key=int):
        L.append('  [%s] = "%s",   -- %s' % (sk, verbs[sk], SKILL_LINES[sk]))
    L.append('}')
    path = os.path.join(outdir, 'augmentVerbs_%s.lua' % flavor)
    with open(path, 'w', encoding='utf-8') as fh:
        fh.write('\n'.join(L) + '\n')
    print('emitted augmentVerbs_%s.lua (%d professions)' % (flavor, len(verbs)))
    return path


def emit_lua(merged, by_skill, outdir, flavor):
    suf, cap = '_' + flavor, GENERAL_MAX.get(flavor, 9999)
    import datetime
    prov = [
        '--[[', f'  data/recipeProgression_{flavor}.lua',
        '  Recipe progression - the finished product. Emitted, never hand-edited.',
        '',
        '  HOW TO REGENERATE (design/patch-day.md has the full runbook):',
        '    1. design/scrape_crawl.js  (paste on Wowhead) -> recipes_raw + converts_raw',
        '    2. design/fetch-db2-closure.sh <build>         -> the DB2 CSV closure',
        '    3. design/merge_recipe_data.py --db2 <dir> --build <b> --wh <raw> --out <o>',
        '',
        '  PROVENANCE per field (all reconciliation happens in the merge, not here):',
        '    ACQUISITION is per-path, not one flattened value:',
        '      trainers  = packed id set of trainer NPCs (a set, one string).',
        '      trainerReq= skill the trainer requires (one value across trainers).',
        '      paths     = detailed acquisition records (item/quest) plus bare',
        '                  origin kinds (drop/world/grant); an item path carries',
        '                  its own req. Discovery is NOT here: it is the',
        '                  discoverer-side discovery table (a M:M, stored once).',
        '      itemReq   = the teaching item DB2 skill req (independent check).',
        '    colors  = {orange, yellow, green, grey} - INTRINSIC craft difficulty,',
        '              distinct from acquisition skill. yellow/grey from DB2',
        '              trivials (WH fills placeholders); green = floor((y+grey)/2).',
        '    min/max = yield range from the WH capture.',
        f'    built {datetime.date.today().isoformat()}.',
        ']]',
        'local _, Addon = ...', 'Addon.data = Addon.data or {}',
        'Addon.data.recipeProgression = {']
    L = list(prov)
    tag = f'{flavor} (design/merge_recipe_data.py)'
    G = [f'-- Crafty recipe gating ({tag})',
         '-- [recipeID] = {class=classMask, faction=0/1/2, spec=specSpellID}  (faction 0=both 1=Alliance 2=Horde)',
         '-- Absent recipeID = no restriction.',
         'local _, Addon = ...', 'Addon.data = Addon.data or {}',
         'Addon.data.recipeGate = {']
    T = [f'-- Crafty profession tier unlocks ({tag})',
         '-- [skillLine] = { {rank=learnRank, level=charLevel, spell=spellID}, ... }',
         '-- ascending. level=0 means no character-level gate.',
         'local _, Addon = ...', 'Addon.data = Addon.data or {}',
         'Addon.data.professionTiers = {']

    for s in EMIT_ORDER:
        rows = by_skill.get(s) or []
        # A gathering profession has no crawl rows (no recipe pages) but does
        # have a DB2 tier ladder; it must still reach tier emission below. Only
        # skip a profession that has neither.
        if not rows and not TIERS.get(s):
            continue
        recips, gates = [], []
        # WH-absent, verdict-carried: DB2 knows the recipe, Wowhead's curation
        # dropped it, and a user verdict says it IS obtainable (WH absence is
        # the obtainability signal - see design/PATTERNS.md; verdicts are the
        # exceptions). Synthesized into a capture-shaped row so one emit path
        # serves both origins.
        seen_ids = {r['id'] for r in rows}

        # WH-absent for a STRUCTURAL reason, not a curation one. Wowhead has no
        # category page for Cooking's child skill lines - the Ways - so their 45
        # recipes appear in no manifest at all, and WH absence cannot mean
        # "unobtainable" for them. They reach the player's list from the live
        # scan; without a row here there is nothing to colour them or fill the
        # detail panel from.
        #
        # Synthesized from DB2 alone. Thresholds come from the same
        # TrivialSkillLineRank fields every other recipe uses, so they are as
        # good as any - what is missing is only Wowhead's observation layer.
        for sp, f in FACTS.items():
            if int(sp) in seen_ids or not f.get('is_craft'):
                continue
            # CHILD SKILL LINES ONLY. Wowhead absence is the obtainability
            # signal everywhere else - it is what the 0.7.37 Engineering fix
            # rests on, and PATTERNS.md records it as a worked negative. Without
            # this condition the synthesis emitted 43 recipes across every
            # profession that WH absence says are NOT obtainable in MoP.
            #
            # A child line is the one place absence means nothing: Wowhead has
            # no category page for the Ways at all, so their recipes could never
            # have appeared in any manifest.
            if not f.get('child_line') or f.get('parent_line') != s:
                continue
            lo, hi = f.get('yellow_db2'), f.get('grey_db2')
            # learn comes from MinSkillLineRank ONLY. Taking it from trivLow -
            # the YELLOW - invented a requirement DB2 does not state, and made a
            # recipe the player already owns render as unavailable below its own
            # yellow. All 45 of these read MinSkillLineRank = 1, so DB2's answer
            # is that there is no minimum, and the recipe shows orange below the
            # yellow the way any other pre-yellow recipe does.
            rows = rows + [{
                'id': int(sp), 'name': f['name'],
                'learnedat': f.get('minskill'),
                'colors': [0, lo, (lo + hi) // 2 if lo and hi else None, hi],
                # Quantity from DB2, not a hardcoded 1: 18 of these make 10.
                'creates': list(f.get('creates_item') or (0, 1, 1)),
                # NumSkillUps, not a default of 1: these have no Wowhead row to
                # take nskillup from, and DB2 records 2, 5 and 8 among them.
                'nskillup': f.get('numskillups') or 1,
                'source': [],
                'reagents': [[0, 0]],
                'skill': [int(s)],
            }]
            seen_ids.add(int(sp))

        for sp, v in VERDICTS.items():
            if 'item' not in v or int(sp) in seen_ids:
                continue
            f = FACTS.get(sp)
            if not f or f['profession'] != DISPLAY[s]:
                continue
            rows = rows + [{
                'id': int(sp), 'name': f['name'],
                'learnedat': v.get('orange'),
                'colors': [v.get('orange'), v.get('yellow'),
                           v.get('green'), v.get('grey')],
                'creates': [v['item'], 1, 1],
                'nskillup': v.get('nskillup', 1),
                'source': v.get('source', []),
                'reagents': [[0, 0]],   # presence marks it a recipe; the
                                        # addon reads reagents from
                                        # dbRecipeReagents, not from here
                'skill': [int(s)],
            }]
        for r in rows:
            if r.get('reagents'):
                recips.append(r)
                cm = r.get('reqclass') or 0
                fac = FACTION_MASK.get(r.get('reqrace'), 0)
                spec = r.get('specialization') or 0
                if cm or fac or spec:
                    gates.append((r['id'], cm, fac, spec))

        if recips:
            L.append('  -- skillLine ' + s)
        def orange_of(r):
            # The merge's chosen orange is the recipe's first-craftable skill
            # (auto/item/perk/dual-source resolved).
            v = VERDICTS.get(str(r['id']))
            if v and v.get('orange'):
                return int(v['orange'])
            m = merged.get(str(r['id']))
            if m and m.get('orange') not in (None, ''):
                return int(m['orange'])
            if m:
                # The merge SAW this recipe and found no orange source. Do not
                # substitute learnedat - that is the yellow, and the whole
                # reason the orange is absent (see the orange block above).
                # 0 means "unknown", and the emitter leaves it as such.
                return 0
            # Never reached the merge (no craft row): learnedat is all there is.
            la = r.get('learnedat')
            return 1 if la == 9999 else (la or 0)
        for r in sorted(recips, key=lambda r: (orange_of(r), r['id'])):
            m = merged.get(str(r['id']))
            # learn is the skill at which the recipe can be ACQUIRED, which is
            # the orange wherever one is known - the two coincide for a recipe
            # that is orange the moment you get it. Where no source names an
            # orange, they do not coincide and learn is still knowable: WH's
            # learnedat states it, trainer-confirmed across every relation it
            # can have to the yellow (above, equal and below all verified).
            # That is NOT an orange and colors[0] stays unknown - a recipe
            # acquired past its orange range has no orange tier at all.
            o = orange_of(r)
            if o:
                learn = min(o, cap)
                if learn < 1:
                    learn = 1
            else:
                la = r.get('learnedat')
                learn = min(la, cap) if la and la != 9999 else 0
            v = VERDICTS.get(str(r['id']))
            if v and 'item' in v:
                # Verdict-carried: the user's measured tiers are the record.
                colors = [v.get('orange') or 0, v.get('yellow') or 0,
                          v.get('green') or 0, v.get('grey') or 0]
            elif v and v.get('orange') and m and m.get('yellow') is not None:
                # A field-observed orange (a trainer stating its requirement)
                # over the merged ramp: the observation outranks every source.
                colors = [v['orange'], m['yellow'] or 0,
                          m['green'] or 0, m['grey'] or 0]
            elif m and m.get('yellow') is not None:
                colors = [m['orange'] or 0, m['yellow'] or 0,
                          m['green'] or 0, m['grey'] or 0]
                if m.get('acq') == 'trainer-quest' and colors[1] == colors[3]:
                    colors[3] = colors[1] + 1   # single-craft window (user-directed)
                    colors[2] = colors[1]
            else:
                colors = list(r.get('colors') or [0, 0, 0, 0])
            # Zero-fill the RAMP only: a zero yellow/green/grey means the
            # ramp is degenerate and collapses to the learn point. colors[0]
            # is left alone - a zero orange means UNKNOWN, and painting the
            # learn over it is the exact error field-testing exposed.
            colors = [colors[0]] + [learn if v == 0 else v for v in colors[1:]]
            if colors[0]:
                colors[0] = min(colors[0], cap)
            # Orange cannot exceed yellow: the recipe is craftable before it is
            # trivial. Two different causes, two different answers.
            #
            # A WH-OBSERVED learn later than the DB2 yellow is the known
            # observation bias - nobody was seen crafting it earlier - so the
            # yellow wins and the learn comes back to meet it.
            if (m and m.get('orange_src') == 'wh:learn'
                    and colors[1] and colors[0] > colors[1]):
                colors[0] = colors[1]
                learn = min(learn, colors[1])

            # Anything else above the yellow means the recipe is ACQUIRED past
            # its orange range, so the orange tier is genuinely empty - the
            # Smelt Tin shape, learned at 50 with bands at 40/57/75, arriving
            # yellow. An empty tier is written as 0, which is how the catalog
            # already states it 421 times. Writing the acquisition point there
            # instead recorded the same fact a second, contradictory way, in a
            # field that means "where orange begins" - and left 92 recipes
            # claiming a band that runs backwards. Wowhead reports 0 for every
            # one of the 88 it covers.
            #
            # learn is NOT touched here: it is the acquisition point and it is
            # correct. Only the claim that an orange band exists is wrong.
            if colors[1] and colors[0] > colors[1]:
                colors[0] = 0
            # Acquisition is represented ONE way: the detailed paths (item /
            # quest records) plus the packed trainer set plus, for origins that
            # carry no detail and live in no other store, bare origin paths
            # (drop / world / grant). The flat source-code array is gone - it
            # duplicated these and drifted from them (it omitted discovery,
            # which is authoritative in the discovery table). Discovery is NOT
            # repeated recipe-side: it is the discoverer-side M:M table, and a
            # consumer answers "is X discovery-learnable" from there.
            sf = source_facts(SOURCES, r['id'])
            detailed = list(sf['paths']) if sf else []
            src_codes = list(r.get('source') or [])
            vrd = VERDICTS.get(str(r['id'])) or {}
            if vrd.get('source'):
                # A user verdict names the origin outright.
                src_codes = list(vrd['source'])
            # AcquireMethod=1 covers TWO origins: the starter set handed over
            # with the profession, and rank upgrades that arrive as skill
            # climbs (Heavy Linen Bandage after Linen Bandage). Only the former
            # is a grant. A rank upgrade gets no origin rather than a wrong one.
            elif (not src_codes and m
                    and '1' in (FACTS.get(str(r['id'])) or {}).get('methods', '').split('+')
                    and not SUPERCEDES.get(str(r['id']))
                    and (m.get('orange') in (None, '') or int(m['orange']) <= 1)):
                src_codes = [SRC_PROFESSION_GRANT]
            paths = detailed + origin_paths(src_codes)
            # 1b: the acquisition skill is per-path, not one flattened recipe
            # value. An item path already carries its own `req`; a discovery
            # path's skill lives in the discovery table (discoverer-side). The
            # trainer requirement is one value across a recipe's trainers, so it
            # rides the packed trainer set as trainerReq - emitted only when the
            # recipe HAS trainers. `learn` (the old flattened first-craft skill)
            # is gone: a consumer derives "min skill to acquire" from the paths.
            has_trainer = bool(lua_trainers(paths))
            trainer_req = learn if (has_trainer and learn) else None
            c = r.get('creates') or [0, 0, 0]
            name = r.get('name') or ''
            rng = f' ({c[1]}-{c[2]})' if c[1] != c[2] else ''
            sup = SUPERCEDES.get(str(r['id']))
            # Character-level gate, where one is known. Only trainers state
            # it, so this comes from field observation (the Training Projects
            # are level 85). Absent = no level gate known.
            lvlreq = (VERDICTS.get(str(r['id'])) or {}).get('levelReq')
            # The teaching item's own skill requirement, when a live item
            # teaches this recipe: a second, independently checkable fact
            # about the same recipe (see design/db2-findings.md).
            fr = FACTS.get(str(r['id'])) or {}
            itemreq = fr.get('orange_db2') if fr.get('orange_src') == 'db2:item-req' else None
            trainers_str = lua_trainers(paths)
            paths_str = lua_paths(paths)
            L.append(f"  [{r['id']}] = {{item={c[0]}, min={c[1]}, max={c[2]}"
                     f", skillupCnt={r.get('nskillup') or 1}"
                     f", colors={{{','.join(map(str, colors))}}}"
                     + (f", supercedes={sup}" if sup else "")
                     + (f", levelReq={lvlreq}" if lvlreq else "")
                     + (f", trainers={trainers_str}" if trainers_str else "")
                     + (f", trainerReq={trainer_req}" if trainer_req else "")
                     + (f", paths={paths_str}" if paths_str else "")
                     + (f", itemReq={itemreq}" if itemreq else "")
                     + (", augments=true" if fr.get('augments') else "") + "},"
                     f"  -- {name}{rng}")
        if gates:
            G.append('  -- skillLine ' + s)
            for gid, cm, fac, spec in sorted(gates):
                G.append(f'  [{gid}] = {{class={cm}, faction={fac}, spec={spec}}},')
        chain = TIERS.get(s) or []
        if chain:
            if len(chain) > len(TIER_RANKS):
                T.append(f'  -- WARNING: {len(chain)} tiers exceed the '
                         f'{len(TIER_RANKS)} known thresholds')
            T.append(f"  [{s}] = {{  -- {DISPLAY[s]}")
            for i, spell in enumerate(chain):
                T.append(f"    {{rank={TIER_RANKS[i] if i < len(TIER_RANKS) else 0}"
                         f", level={tier_level(s, i)}"
                         f", spell={spell}}},")
            T.append('  },')
    for buf, fn in ((L, 'recipeProgression'), (G, 'recipeGate'),
                    (T, 'professionTiers')):
        buf.append('}')
        with open(os.path.join(outdir, fn + suf + '.lua'), 'w') as fh:
            fh.write('\n'.join(buf) + '\n')
    print(f'emitted recipeProgression{suf}.lua, recipeGate{suf}.lua, '
          f'professionTiers{suf}.lua')


def emit_npcs(outdir, flavor):
    """The NPCs referenced by acquisition paths, once each.

    A trainer teaches dozens of recipes and a vendor sells many formulas;
    inlining them per recipe would repeat the same name and zones hundreds of
    times. Recipes reference these by id.
    """
    if not NPCS:
        return
    suf = '_' + flavor
    L = ['--[[', f'  data/sourceNPCs{suf}.lua',
         '  NPCs named by recipe acquisition paths - trainers, vendors, and',
         '  the creatures that drop recipe items. Emitted, never hand-edited;',
         '  see the regeneration steps in data/recipeProgression' + suf + '.lua.',
         '',
         '  [npcID] = { name, tag (their title, where they have one),',
         '              zones = {zoneID, ...} }',
         ']]', 'local _, Addon = ...', 'Addon.data = Addon.data or {}',
         'Addon.data.sourceNPCs = {']
    for nid in sorted(NPCS, key=int):
        n = NPCS[nid]
        bits = [f'name="{(n["name"] or "").replace(chr(34), "")}"']
        if n.get('tag'):
            bits.append(f'tag="{n["tag"].replace(chr(34), "")}"')
        if n.get('zones'):
            bits.append('zones={' + ','.join(str(z) for z in n['zones']) + '}')
        L.append(f'  [{nid}] = {{' + ', '.join(bits) + '},')
    L.append('}')
    with open(os.path.join(outdir, f'sourceNPCs{suf}.lua'), 'w') as fh:
        fh.write('\n'.join(L) + '\n')
    print(f'emitted sourceNPCs{suf}.lua ({len(NPCS)} NPCs)')


def emit_converts(convpath, outdir, flavor):
    import datetime
    suf = '_' + flavor
    today = datetime.date.today().isoformat()
    data = json.load(open(convpath))
    for verb, blob in data.items():
        rows, qty = blob['rows'], blob.get('qty') or {}
        src = {}
        for r in rows:
            h = src.setdefault(r['id'], {'name': r.get('name'), 'results': []})
            chance = round((r['count'] / r['outof'] if r.get('outof')
                            else (r.get('percent') or 0) / 100), 4)
            q = (qty.get(str(r['id'])) or {}).get(str(r['yield']))
            h['results'].append({'id': r['yield'], 'chance': chance,
                                 'tier': 'primary' if chance >= 0.75 else 'proc',
                                 'qty': q})
        L = ['--[[', f'  data/{verb.lower()}{suf}.lua',
             f'  {verb} conversion table (design/merge_recipe_data.py, {today})',
             '',
             '  What only sampling knows: which results a source can yield, and how',
             '  often. Eligibility and required skill are NOT here - the client',
             '  declares both at runtime.', '',
             '  [sourceItemID] = { { id, chance (0-1, INDEPENDENT per-cast presence -',
             '  not a distribution), tier = "primary"|"proc", qty = {min,max} per proc',
             '  when known }, ... } sorted best-first',
             ']]', '', 'local ADDON_NAME, Addon = ...', '',
             'Addon.data = Addon.data or {}',
             f'Addon.data.{verb.lower()} = {{']
        for sid in sorted(src):
            h = src[sid]
            h['results'].sort(key=lambda r: (-r['chance'], r['id']))
            res = ', '.join(
                f"{{ id = {r['id']}, chance = {r['chance']}, tier = \"{r['tier']}\""
                + (f", qty = {{ {r['qty'][0]}, {r['qty'][1]} }}" if r['qty'] else '')
                + ' }' for r in h['results'])
            L.append(f"    [{sid}] = {{ {res} }}, -- {h['name']}")
        L += ['}', '', f"return Addon.data.{verb.lower()}", '']
        with open(os.path.join(outdir, verb.lower() + suf + '.lua'), 'w') as fh:
            fh.write('\n'.join(L))
        print(f'emitted {verb.lower()}{suf}.lua ({len(src)} sources)')


VERDICTS = {}
SOURCES = {}      # recipeID -> captured page detail (crawler source pass)
NPCS = {}         # npcID -> {name, tag, zones} - entities, emitted once
SUPERCEDES = {}   # spell -> the spell it replaces (rank chain edge)
FACTS = {}      # db2 facts, for verdict-carried emission
TIERS = {}      # skillLine -> [tier spell ids] in rank order, from DB2
BOOKS = {}   # recipe name -> book RequiredSkillRank ('...and Its Uses' script-taught)


def wh_stage(facts, whrows, by_skill, outdir, flavor):
    # One-time server-validated classifications (design/validation_verdicts_*.json,
    # generated from a 3.3.5 world DB - algorithm validation on old content,
    # never a live pipeline dependency).
    global VERDICTS
    for vp in (f'validation_verdicts_{flavor}.json', f'user_verdicts_{flavor}.json'):
        if os.path.exists(vp):
            VERDICTS.update(json.load(open(vp)))
    if VERDICTS:
        print(f'loaded {len(VERDICTS)} verdicts (server-validated + user)')
    merged, review = {}, []

    def flag(sp, kind, detail=''):
        review.append((sp, kind, detail, 'review'))

    resolved = {}

    def note(sp, kind, detail=''):
        resolved[kind] = resolved.get(kind, 0) + 1

    for sp, f in facts.items():
        if not f['is_craft']:
            continue
        w = whrows.get(sp)
        if w is None and (f['acq'] in ('residue', 'special')
                          or f['orange_src'] == 'rule:orange1-candidate'
                          or f['yellow_db2'] is None):
            uv = VERDICTS.get(sp)
            if uv:
                merged[sp] = dict(f, acq=uv.get('acq', f['acq']),
                                  orange=uv.get('orange', f['orange_db2']),
                                  yellow=uv.get('yellow', f['yellow_db2']),
                                  grey=uv.get('grey', f['grey_db2']),
                                  green=None, wh_sources='',
                                  orange_src='user' if 'orange' in uv else f['orange_src'])
            else:
                flag(sp, 'not-in-wh-capture', f"acq={f['acq']}")
                merged[sp] = dict(f, orange=f['orange_db2'], yellow=f['yellow_db2'],
                                  grey=f['grey_db2'], green=None, wh_sources='')
            continue
        c = (w or {}).get('colors') or [None] * 4
        wo, wy, wgreen, wgrey = (c + [None] * 4)[:4]
        learn = (w or {}).get('learnedat')
        if learn == 9999:
            learn = 1
        srcs = [WH_SOURCE.get(s, str(s)) for s in (w or {}).get('source') or []]

        # yellow / grey: DB2 primary, WH fills placeholders, identity arbitrates
        yellow, ysrc = f['yellow_db2'], 'db2'
        grey, gsrc = f['grey_db2'], 'db2'
        if wy and yellow is not None and wy != yellow:
            # WH display-clamp: WH raises displayed yellow to learn when the
            # true yellow sits below it; WH's own green is computed from the
            # RAW yellow. Both identities holding = proof, not theory.
            if wy == learn and grey is not None and wgreen == (yellow + grey) // 2:
                note(sp, 'yellow-wh-display-clamp', f'db2={yellow} wh={wy}')
            else:
                flag(sp, 'yellow-conflict-theory-picked', f'db2={yellow} wh={wy}')
        if yellow is None:
            yellow, ysrc = (wy or None), 'wh'
            if yellow is None:
                (note if f['orange_src'] == 'db2:minskill' or f.get('ranked')
                 or (not wo and not wy and not wgreen)
                 else flag)(sp, 'no-yellow', '')
        if grey is None:
            grey, gsrc = (wgrey or None), 'wh'
            if grey is None:
                flag(sp, 'no-grey')
        elif wgrey and wgrey != grey:
            if not wo and not wy and not wgreen and wgrey == learn:
                # WH shows only learn in the last slot: the recipe is learned
                # already at/past grey - a learn-display, not a measured grey.
                # WH offers no grey testimony; DB2 stands unopposed.
                note(sp, 'wh-learn-display-only', f'learn={learn}')
            else:
                db2_ok = midpoint_ok(yellow, grey, wgreen)
                wh_ok = midpoint_ok(yellow, wgrey, wgreen)
                if wh_ok and not db2_ok:
                    grey, gsrc = wgrey, 'wh:arbiter'
                elif db2_ok:
                    note(sp, 'grey-crosscheck-db2-wins', f'db2={grey} wh={wgrey}')
                else:
                    flag(sp, 'grey-conflict-unarbitrated',
                         f'db2={grey} wh={wgrey} whgreen={wgreen}')
        green = (yellow + grey) // 2 if yellow is not None and grey is not None else None
        if wgreen and green is not None and wgreen != green:
            note(sp, 'wh-green-off-formula', f'derived={green} wh={wgreen}')

        # orange per acquisition class
        orange, osrc, acq = f['orange_db2'], f['orange_src'], f['acq']
        if osrc == 'rule:orange1-candidate':
            if not wo:
                orange, osrc = 1, 'rule:orange1'
            else:
                # Auto-learn at a threshold: WH learnedat is the grant level
                # (enumerated metadata, same witness class as trainer-learn,
                # server-validated at 97.6%; grant-at-1 subset user-verified).
                orange, osrc = (learn or wo), 'wh:grant'
                note(sp, 'auto-grant-wh-learn', f'grant={orange}')
        elif orange is not None:
            # Dual-source recipes: the item teaches at item-req, a trainer may
            # teach at WH learn. First-craftable = the EARLIER path.
            if acq == 'item' and learn and learn < orange:
                note(sp, 'orange-min-dual-source', f'item={orange} learn={learn}')
                orange, osrc = learn, 'wh:learn<item'
            elif wo and wo != orange:
                note(sp, 'orange-crosscheck', f'db2={orange} wh={wo} learn={learn}')
        else:
            # DB2 carries no orange for this recipe - either its class never
            # had one, or its teaching item was rejected as unobtainable.
            # WH's colors[0] is the orange when Wowhead has one. When it is 0
            # Wowhead simply does not know the orange, and `learnedat` is NOT
            # a substitute: field-verified against trainers across eight
            # professions, learnedat in that case reproduces the YELLOW (or
            # the grey, for single-craft recipes) and the true orange sits
            # 5-25 points below it. Publishing it manufactures a recipe with
            # no orange tier at all. With no orange source, we carry none.
            if wo:
                orange, osrc = wo, 'wh:orange'
            else:
                orange, osrc = None, None
                flag(sp, 'no-orange-source', f'wh learnedat={learn} is the yellow/grey, not the orange')

        v = VERDICTS.get(sp)
        if v:
            acq = v.get('acq', acq)
            if 'orange' in v: orange, osrc = v['orange'], 'user'
            if 'yellow' in v: yellow, ysrc = v['yellow'], 'user'
            if 'grey' in v: grey, gsrc = v['grey'], 'user'

        # residue split: WH trainer enumeration finishes the classification
        if v and v.get('acq') == 'unobtainable':
            merged[sp] = dict(f, acq=acq, orange=orange, yellow=yellow,
                              grey=grey, green=None, wh_sources='')
            continue
        if acq == 'residue' and not v:
            if 'trainer' in srcs:
                acq = 'trainer'
            elif srcs:
                acq = srcs[0]              # quest/drop/vendor/... per WH
            elif w and w.get('specialization'):
                acq = 'spec'               # specialization-taught (Truesilver etc.)
            elif f.get('ranked'):
                acq = 'ranked'             # SupercedesSpell chain: rank upgrade
            elif f['name'].startswith('Training Project:'):
                acq = 'trainer-quest'      # user-verified: Vale trainers, quest-gated at 85
            elif f['name'] in BOOKS:
                acq = 'item'
                orange, osrc = BOOKS[f['name']], 'db2:book-req'
            elif (f['profession'] == 'Inscription'
                  and (f['name'] or '').startswith('Glyph of')):
                # Sourceless glyphs are the Scribe's-research pool: research-
                # spell discoveries carry no WH source and no discovery
                # mechanic (the Research spell is the trigger).
                acq = 'discovery:research'
                note(sp, 'research-discovery', '')
            else:
                acq = 'discovery' if f['mech28'] else 'discovery?'
                if not f['mech28']:
                    flag(sp, 'sourceless-unmarked-discovery')
        if f['acq'] == 'item' and w and srcs == ['trainer']:
            note(sp, 'item-taught-but-wh-trainer-only')

        merged[sp] = dict(f, acq=acq, orange=orange, orange_src=osrc,
                          yellow=yellow, yellow_src=ysrc, grey=grey,
                          grey_src=gsrc, green=green, wh_sources='+'.join(srcs),
                          wh_orange=wo, wh_yellow=wy, wh_green=wgreen,
                          wh_grey=wgrey, wh_learn=learn)

    def pattern_of(sp, kind, detail):
        # cluster label so one in-game check clears a whole pattern
        if kind in ('yellow-conflict-theory-picked', 'orange-crosscheck', 'orange-min-dual-source'):
            try:
                a, b = (int(x.split('=')[1]) for x in detail.split()[:2])
                return f'{kind}:offset{b - a:+d}'
            except Exception:
                return kind
        return kind

    revcols = ['profession', 'spell', 'name', 'acq', 'flag',
               'pattern', 'wh_orange', 'wh_yellow', 'wh_green', 'wh_grey',
               'wh_learn', 'wh_sources', 'db2_orange', 'db2_orange_src',
               'db2_yellow', 'db2_grey', 'chosen_orange', 'chosen_orange_src',
               'chosen_yellow', 'chosen_yellow_src', 'chosen_grey',
               'chosen_grey_src', 'chosen_green', 'detail']
    with open(os.path.join(outdir, f'review_{flavor}.csv'), 'w', newline='',
              encoding='utf-8') as fh:
        wtr = csv.DictWriter(fh, fieldnames=revcols)
        wtr.writeheader()
        for sp, kind, detail, sev in sorted(
                review, key=lambda x: (facts[x[0]]['profession'],
                                       pattern_of(*x[:3]), int(x[0]))):
            f, m, w = facts[sp], merged.get(sp, {}), whrows.get(sp) or {}
            c = (w.get('colors') or [None] * 4) + [None] * 4
            learn = w.get('learnedat')
            wtr.writerow({
                'profession': f['profession'], 'spell': sp, 'name': f['name'],
                'acq': m.get('acq', f['acq']), 'flag': kind,
                'pattern': pattern_of(sp, kind, detail),
                'wh_orange': c[0], 'wh_yellow': c[1], 'wh_green': c[2],
                'wh_grey': c[3], 'wh_learn': 1 if learn == 9999 else learn,
                'wh_sources': m.get('wh_sources', ''),
                'db2_orange': f['orange_db2'], 'db2_orange_src': f['orange_src'],
                'db2_yellow': f['yellow_db2'], 'db2_grey': f['grey_db2'],
                'chosen_orange': m.get('orange'),
                'chosen_orange_src': m.get('orange_src'),
                'chosen_yellow': m.get('yellow'),
                'chosen_yellow_src': m.get('yellow_src'),
                'chosen_grey': m.get('grey'),
                'chosen_grey_src': m.get('grey_src'),
                'chosen_green': m.get('green'), 'detail': detail})

    cols = ['spell', 'name', 'profession', 'acq', 'orange', 'orange_src',
            'yellow', 'yellow_src', 'grey', 'grey_src', 'green',
            'wh_orange', 'wh_yellow', 'wh_green', 'wh_grey', 'wh_learn',
            'wh_sources', 'mech28']
    with open(os.path.join(outdir, f'merged_{flavor}.csv'), 'w', newline='',
              encoding='utf-8') as fh:
        wtr = csv.DictWriter(fh, fieldnames=cols)
        wtr.writeheader()
        for sp in sorted(merged, key=lambda s: (merged[s]['profession'], int(s))):
            wtr.writerow({c: merged[sp].get(c, '') for c in cols})
    print(f'merged {len(merged)} crafts; review rows: {len(review)}; '
          f'rule-resolved (audited in merged csv): {resolved}')
    emit_lua(merged, by_skill, outdir, flavor)
    return merged, review


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--db2', required=True)
    ap.add_argument('--build', required=True)
    ap.add_argument('--wh')
    ap.add_argument('--sources', help='sources_raw_<ver>.json from the crawler')
    ap.add_argument('--reagents', help='reagents_raw_<ver>.json from the reagent capture')
    ap.add_argument('--discovery', default='discovery_union.json',
                    help='skill_discovery_template union, discoverer-keyed')
    ap.add_argument('--trainer-verdicts', dest='trainer_verdicts',
                    default='trainer_verdicts_mop.json',
                    help='per-NPC corrections to what a trainer teaches')
    ap.add_argument('--out', default='./merge-out')
    ap.add_argument('--flavor', default='mop')
    a = ap.parse_args()

    # Sources first: the DB2 pass consults the capture to tell an obtainable
    # teaching item from a legacy one DB2 still links.
    emit_vendor_reagents(a.reagents, a.out, a.flavor)
    emit_craft_verbs(a.db2, a.build, a.out, a.flavor)
    # Reachable by the player: a profession recipe, or a spell an item casts.
    reachable = set()
    for r in read(a.db2, 'SkillLineAbility', a.build):
        reachable.add(r['Spell'])
    for r in read(a.db2, 'ItemEffect', a.build):
        if r.get('SpellID'):
            reachable.add(r['SpellID'])

    def is_discoverer(spellID):
        return spellID in reachable

    emit_discovery(a.discovery, a.out, a.flavor, is_discoverer)
    if a.trainer_verdicts and os.path.exists(a.trainer_verdicts):
        with open(a.trainer_verdicts, encoding='utf-8') as fh:
            globals()['TRAINER_VERDICTS'] = json.load(fh)
    globals()['SOURCES'] = load_sources(a.sources)
    # DB2 facts first: the trainer audit reconciles Wowhead's NPC tag against
    # DB2's authoritative recipe->profession, so DB2 must be built before it.
    facts, flags = build_db2_facts(a.db2, a.build)
    globals()['FACTS'] = facts
    audit_trainer_professions(SOURCES, facts)
    apply_trainer_verdicts(SOURCES)
    if SOURCES:
        print(f'loaded source detail for {len(SOURCES)} recipes')
    path = write_facts(facts, flags, a.out, a.flavor)
    crafts = [f for f in facts.values() if f['is_craft']]
    by_acq = defaultdict(int)
    for f in crafts:
        by_acq[f['acq']] += 1
    print(f'{len(facts)} recipe spells ({len(crafts)} crafts) -> {path}')
    print('acquisition:', dict(sorted(by_acq.items(), key=lambda x: -x[1])))
    print(f'flags: {len(flags)}')
    if a.wh:
        whrows, by_skill = load_wh(a.wh)
        wh_stage(facts, whrows, by_skill, a.out, a.flavor)
        convdir = os.path.dirname(a.wh) if os.path.isfile(a.wh) else a.wh
        import glob as _g
        for cp in _g.glob(os.path.join(convdir, 'converts_raw_*.json')):
            emit_converts(cp, a.out, a.flavor)
        emit_npcs(a.out, a.flavor)


if __name__ == '__main__':
    main()
