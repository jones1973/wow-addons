#!/usr/bin/env bash
# Fetch the Crafty DB2 table closure from wago.tools as CSVs.
# Usage: ./fetch-db2-closure.sh <build> [outdir]
#   e.g. ./fetch-db2-closure.sh 5.5.4.68716 /home/claude/db2
# Tables: the profession-data domain plus every FK-adjacent table, so
# cross-domain pattern hunts (PATTERNS.md) have the neighborhood in hand.

set -euo pipefail
BUILD="${1:?build required, e.g. 5.5.4.68716}"
OUT="${2:-./db2-$BUILD}"
mkdir -p "$OUT"

TABLES=(
  # recipe core
  SkillLine SkillLineCategory SkillLineAbility SkillRaceClassInfo
  TradeSkillCategory TradeSkillItem
  # spell side
  Spell SpellName SpellMisc SpellLevels SpellEffect SpellLearnSpell
  SpellCategories SpellCategory SpellLabel
  # requirements: tools, stations, areas, factions
  SpellTotems TotemCategory
  SpellCastingRequirements SpellFocusObject
  AreaGroupMember AreaTable Faction
  # reagents
  SpellReagents SpellReagentsCurrency CurrencyTypes
  # item side: teaching items, sources, conversions
  Item ItemSparse ItemEffect ItemNameDescription ItemLimitCategory
  ItemExtendedCost ItemCurrencyCost ItemDisenchantLoot
)

for t in "${TABLES[@]}"; do
  f="$OUT/${t}_${BUILD//./_}.csv"
  if [ -s "$f" ]; then echo "have  $t"; continue; fi
  curl -sfL -o "$f" "https://wago.tools/db2/${t}/csv?build=${BUILD}" \
    && echo "fetch $t ($(wc -l < "$f") lines)" \
    || { echo "MISS  $t (not in this build?)"; rm -f "$f"; }
done
