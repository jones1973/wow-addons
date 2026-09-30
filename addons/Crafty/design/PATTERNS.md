# Pattern-finding methodology

Working rules for any "how do I distinguish class X in this data" question -
DB2 archaeology, scrape reconciliation, log analysis, anything. The failure
this doc exists to prevent: concluding "indistinguishable" after running only
ONE of the methods below (it happened - see the worked example).

The core discipline: a search that can only confirm is not evidence. Every
hypothesis about the data gets tested in a way that could fail, and every
"can't find it" gets attacked from at least one more angle before it is
recorded as a finding.

---

## The checklist

Run these in order until the question yields. Do not stop after #1.

1. **Positive marker search.** Look for a field/flag/value that marks class X
   directly. Cheapest when it works. Failure mode: "no marker found" says
   nothing by itself - it is the START of the investigation, not a finding.

2. **Complement subtraction (method of residues).** Partition the corpus by
   every class you CAN positively source; interrogate what remains. If the
   residue equals X (or X union one other class), the problem is solved or
   reduced. Ask: what would be left if I removed everything I understand?

3. **Invariant exploitation.** Find identities that MUST hold (a formula the
   game itself computes, a field that must equal another, a total that must
   sum) and read violations as signal. Invariants also arbitrate between
   conflicting sources: the one satisfying the identity is the consistent one.

4. **Full-membership enumeration.** Before believing any candidate marker,
   pull its ENTIRE membership and test both directions: does X imply the
   marker, AND does the marker imply X? Verifying against known positives
   only is the classic trap - counterexamples live in the part you didn't
   enumerate, and enumeration is usually one query.

5. **Mechanistic necessity.** Reason from what the system MUST do: if the
   server has to decide something at runtime, data enabling that decision
   must exist somewhere. Work forward from the mechanism to predict where
   the signal lives, then check the prediction.

6. **Cross-source triangulation.** Independent sources (DB2 vs WH vs in-game
   observation) fail in DIFFERENT ways. Agreement across failure modes is
   strong evidence; disagreement localizes exactly which source is broken
   and how (pipeline artifact vs observation bias vs placeholder).
   INDEPENDENCE IS THE WHOLE VALUE: derivative sources (leveling guides,
   wikis, aggregators) trace back to the same upstream and to each other -
   one witness counted twice. Their agreement adds ~nothing; treat it as
   consistency, never confirmation. Private-server databases are genuinely
   independent (reverse-engineered server data) but exist only for old
   content - usable to VALIDATE an algorithm once, never as a pipeline
   dependency, since new expansions arrive with no such mirror.

7. **Combination search.** A tell is often conditional: no single field
   separates the classes, but a conjunction does. Marginals cannot see this -
   test PAIRS exhaustively across and within tables, then let a decision tree
   or forest search deeper conjunctions than anyone would write by hand. Read
   the result honestly: high recall bought with heavy false positives means
   the model found a correlate of the set's COMPOSITION (age, item class),
   not the property being hunted. Diffuse feature importances mean no signal.

---

## Standing rules

- Never record "indistinguishable" / "not present" / "not recoverable" unless
  at least the subtraction (#2) and enumeration (#4) passes have run. "No
  positive marker" and "not recoverable" are different claims - say which.
- A fact "verified against known recipes" is verified in one direction only.
  Record the verification basis with the fact so the gap is visible.
- Treat the residue as the most informative data available, not leftovers.
  If the residue is messy, the model of the known classes is wrong or
  incomplete - refine and re-subtract.
- When two sources disagree, do not vote - find an invariant to arbitrate.

---

## Worked example: a properly closed NEGATIVE

Question: is a recipe still obtainable this expansion? 43 known-unobtainable
recipes (user-verified in game), 5,242 obtainable controls. Every move in the
checklist, in order, before answering:

- #1 positive markers: acquisition class, AcquireMethod, orange source, rank
  chain, trivial placeholders, SpellLabel, SpellMisc attributes,
  TradeSkillItem membership. Nothing.
- #4 full membership, BOTH directions, every column of Item, ItemSparse,
  SkillLineAbility, SpellMisc, SpellReagents, SpellCategories - on the
  CREATED item and the TEACHING item - including the unnamed/opaque fields
  (Field_5_5_4_*). ~250 columns. Nothing above noise.
- #7 combinations: ~99,000 pairwise conjunctions over 426 features - zero.
  Decision trees to depth 8 (deeper conjunctions than anyone would write by
  hand): depth 3 recalls 36/43 but drags 1,240 false positives; a random
  forest tuned for precision collapses to 4/43. Diffuse feature importances
  (top feature 4%, and it is an identity-ish column) - the signature of no
  signal.
- The four weak single-column hits (RequiredSkillRank=355, ItemLevel=71,
  two ReagentCount values) are all the same TBC-era gear cohort seen from
  different angles - composition of the set, not a marker of availability.
- #5 mechanistic explanation for the absence: obtainability is decided by
  VENDOR INVENTORIES, LOOT TABLES, and QUEST REWARDS - all server-side. The
  client ships the spell and the item regardless, because it must render
  them for anyone who already owns one. The tell cannot be in client data by
  construction.

Conclusion: no client-side obtainability marker exists. Wowhead's ABSENCE is
the signal (43/46 precision), because WH's curation encodes exactly the
server-side world knowledge the client omits - and the 3 exceptions are
covered by user verdicts. Recorded as "no marker exists, here is why" rather
than "could not find one".

## Worked example (why this doc exists)

Question: which recipes are discovery-taught? Pass #1 found no flag and the
finding was recorded as "discovery is NOT distinguishable." Wrong method,
wrong conclusion:

- #2: residue after removing item-taught, teacher-spell-taught, and
  auto-learned = trainer union discovery (2,289). One outside enumeration
  (WH trainer lists) finishes the split.
- #4: the recorded "Mechanic=28 = transmute" fact collapsed the moment full
  membership was pulled (263 rows: potions, elixirs, flasks, gadgets - and
  no vanilla transmutes). It is MECHANIC_DISCOVERY, marking discovery-capable
  casts - a pre-filter #1 had been looking for all along.
- #5 would have found it from the front: the server must know which casts
  roll a discovery proc, so a per-spell mechanic marker had to exist.

## Canon (optional reading)

Mill, *A System of Logic* (the five methods; #2 is his method of residues).
Klayman & Ha 1987 (why positive-only testing fails, and when it's fine).
Popper, *Conjectures and Refutations* (tests must be able to fail).
Polya, *How to Solve It* (invert the problem, solve the complement).
Tukey, *Exploratory Data Analysis* (the residual-examination loop).
