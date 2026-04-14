local addonName, ns = ...

--- Rep-gated vendor items. Keyed by faction ID.
--- Each entry: itemID, nameDisplay, standingRequired, professionRequired (nil if none),
--- category (gear/recipe/inscription/flask/mount/tabard/key), slot or nil, notes or nil.

ns.dataVendors = {
    [ns.FACTION_SCRYERS] = {
        -- Inscriptions (shoulder enchants)
        { itemID = 29674, nameDisplay = "Greater Inscription of the Blade",  standingRequired = ns.STANDING_EXALTED,  category = "inscription", notes = "+15 Spell Crit, +20 Spell Dmg" },
        { itemID = 29673, nameDisplay = "Greater Inscription of the Oracle", standingRequired = ns.STANDING_EXALTED,  category = "inscription", notes = "+22 Healing, +6 mp5" },
        { itemID = 28886, nameDisplay = "Inscription of the Blade",          standingRequired = ns.STANDING_HONORED,  category = "inscription", notes = "+13 Spell Crit" },
        { itemID = 28885, nameDisplay = "Inscription of the Oracle",         standingRequired = ns.STANDING_HONORED,  category = "inscription", notes = "+13 Healing" },

        -- Gear
        { itemID = 29132, nameDisplay = "Retainer's Blade",          standingRequired = ns.STANDING_HONORED,  category = "gear", notes = "Dagger, +23 Spell Dmg" },
        { itemID = 29126, nameDisplay = "Seer's Cane",               standingRequired = ns.STANDING_HONORED,  category = "gear", notes = "Staff, +49 Healing" },
        { itemID = 31779, nameDisplay = "Socrethar's Girdle",        standingRequired = ns.STANDING_REVERED,  category = "gear", notes = "Cloth waist" },
        { itemID = 29133, nameDisplay = "Bloodgem Infused Bandage",  standingRequired = ns.STANDING_HONORED,  category = "gear", notes = "Consumable, heals 3400" },

        -- Recipes
        { itemID = 22908, nameDisplay = "Recipe: Elixir of Major Firepower",    standingRequired = ns.STANDING_REVERED, category = "recipe", professionRequired = ns.PROFESSION_ALCHEMY },
        { itemID = 24001, nameDisplay = "Pattern: Magister's Armor Kit",         standingRequired = ns.STANDING_REVERED, category = "recipe", professionRequired = ns.PROFESSION_LEATHERWORKING },

        -- Enchanting
        { itemID = 28272, nameDisplay = "Formula: Enchant Weapon - Major Intellect", standingRequired = ns.STANDING_REVERED, category = "recipe", professionRequired = ns.PROFESSION_ENCHANTING, notes = "+30 Intellect" },
    },

    [ns.FACTION_CENARION_EXPEDITION] = {
        -- Gear
        { itemID = 25838, nameDisplay = "Watcher's Cowl",            standingRequired = ns.STANDING_REVERED,  category = "gear", notes = "Cloth helm, +42 Healing" },
        { itemID = 29170, nameDisplay = "Windcaller's Orb",          standingRequired = ns.STANDING_EXALTED,  category = "gear", notes = "Offhand, +23 Spell Dmg" },
        { itemID = 29172, nameDisplay = "Ashyen's Gift",             standingRequired = ns.STANDING_EXALTED,  category = "gear", notes = "Ring, +23 Spell Dmg, +21 Sta, +24 Spell Hit" },
        { itemID = 25836, nameDisplay = "Strength of the Untamed",   standingRequired = ns.STANDING_REVERED,  category = "gear", notes = "Necklace, tank" },

        -- Head enchant
        { itemID = 29192, nameDisplay = "Glyph of Ferocity",         standingRequired = ns.STANDING_REVERED,  category = "inscription", notes = "+34 AP, +16 Hit Rating" },

        -- Key
        { itemID = 30623, nameDisplay = "Reservoir Key",             standingRequired = ns.STANDING_REVERED,  category = "key", notes = "Heroic Coilfang access" },

        -- Mount
        { itemID = 33999, nameDisplay = "Cenarion War Hippogryph",   standingRequired = ns.STANDING_EXALTED,  category = "mount", notes = "Flying mount, 2000g" },

        -- Recipes
        { itemID = 30623, nameDisplay = "Plans: Adamantite Sharpening Stone",  standingRequired = ns.STANDING_HONORED,  category = "recipe", professionRequired = ns.PROFESSION_BLACKSMITHING },

        -- Enchanting
        { itemID = 28271, nameDisplay = "Formula: Enchant Gloves - Spell Strike", standingRequired = ns.STANDING_REVERED, category = "recipe", professionRequired = ns.PROFESSION_ENCHANTING, notes = "+15 Spell Hit Rating" },
    },

    [ns.FACTION_SHATAR] = {
        -- Gear
        { itemID = 29175, nameDisplay = "Sha'tar Vindicator's Waistguard", standingRequired = ns.STANDING_REVERED,  category = "gear" },

        -- Head enchant
        { itemID = 30109, nameDisplay = "Glyph of Power",             standingRequired = ns.STANDING_REVERED,  category = "inscription", notes = "+22 Spell Dmg, +14 Spell Hit Rating" },

        -- Key
        { itemID = 30634, nameDisplay = "Warpforged Key",             standingRequired = ns.STANDING_REVERED,  category = "key", notes = "Heroic Tempest Keep access" },

        -- Enchanting
        { itemID = 22535, nameDisplay = "Formula: Enchant Ring - Healing Power", standingRequired = ns.STANDING_REVERED, category = "recipe", professionRequired = ns.PROFESSION_ENCHANTING, notes = "+20 Healing, +7 Spell Dmg" },
        { itemID = 28270, nameDisplay = "Formula: Enchant Weapon - Major Healing",  standingRequired = ns.STANDING_HONORED, category = "recipe", professionRequired = ns.PROFESSION_ENCHANTING, notes = "+81 Healing, +27 Spell Dmg" },
        { itemID = 33153, nameDisplay = "Formula: Void Shatter",     standingRequired = ns.STANDING_HONORED,  category = "recipe", professionRequired = ns.PROFESSION_ENCHANTING, notes = "Void Crystal -> 2x Large Prismatic Shard" },

        -- Alchemy
        { itemID = 22910, nameDisplay = "Recipe: Elixir of Major Shadow Power", standingRequired = ns.STANDING_REVERED, category = "recipe", professionRequired = ns.PROFESSION_ALCHEMY },
    },

    [ns.FACTION_CONSORTIUM] = {
        -- Gear
        { itemID = 29115, nameDisplay = "Consortium Blaster",         standingRequired = ns.STANDING_REVERED,  category = "gear", notes = "Gun" },
        { itemID = 29116, nameDisplay = "Smuggler's Ammo Pouch",     standingRequired = ns.STANDING_HONORED,  category = "gear", notes = "Ammo pouch" },
        { itemID = 29121, nameDisplay = "Haramad's Bargain",         standingRequired = ns.STANDING_EXALTED,  category = "gear", notes = "Necklace, +15 Sta, +24 AP, +16 Crit" },

        -- Enchanting
        { itemID = 28274, nameDisplay = "Formula: Enchant Cloak - Spell Penetration", standingRequired = ns.STANDING_FRIENDLY, category = "recipe", professionRequired = ns.PROFESSION_ENCHANTING, notes = "+20 Spell Pen" },
        { itemID = 28273, nameDisplay = "Formula: Enchant Weapon - Major Striking",   standingRequired = ns.STANDING_HONORED,  category = "recipe", professionRequired = ns.PROFESSION_ENCHANTING, notes = "+7 Weapon Dmg" },

        -- Jewelcrafting
        { itemID = 25902, nameDisplay = "Design: Shifting Shadow Draenite",    standingRequired = ns.STANDING_FRIENDLY, category = "recipe", professionRequired = ns.PROFESSION_JEWELCRAFTING },
        { itemID = 25903, nameDisplay = "Design: Luminous Flame Spessarite",   standingRequired = ns.STANDING_FRIENDLY, category = "recipe", professionRequired = ns.PROFESSION_JEWELCRAFTING },
        { itemID = 33305, nameDisplay = "Design: Don Julio's Heart",           standingRequired = ns.STANDING_REVERED,  category = "recipe", professionRequired = ns.PROFESSION_JEWELCRAFTING },

        -- Engineering
        { itemID = 23799, nameDisplay = "Schematic: Elemental Seaforium Charge", standingRequired = ns.STANDING_REVERED, category = "recipe", professionRequired = ns.PROFESSION_ENGINEERING },
    },
}

--- Returns all vendor items for a faction that the character can use or learn.
--- Filters by profession if item has professionRequired.
--- @param factionID number
--- @param professionFilter boolean|nil -- if true, only show items matching character's professions
--- @return table itemsRelevant
function ns.vendorItemsGet(factionID, professionFilter)
    local itemsFaction = ns.dataVendors[factionID]
    if not itemsFaction then return {} end

    local itemsRelevant = {}
    for _, item in ipairs(itemsFaction) do
        local isRelevant = true

        if professionFilter and item.professionRequired then
            isRelevant = ns.professionHas(item.professionRequired)
        end

        if isRelevant then
            table.insert(itemsRelevant, item)
        end
    end

    return itemsRelevant
end

--- Returns the highest standing required across all selected/relevant items for a faction.
--- @param factionID number
--- @param itemsSelected table|nil -- { [itemID] = true } if nil, considers all items
--- @return number standingHighest
function ns.standingRequiredHighest(factionID, itemsSelected)
    local itemsFaction = ns.dataVendors[factionID]
    if not itemsFaction then return 0 end

    local standingHighest = 0
    for _, item in ipairs(itemsFaction) do
        if not itemsSelected or itemsSelected[item.itemID] then
            if item.standingRequired > standingHighest then
                standingHighest = item.standingRequired
            end
        end
    end

    return standingHighest
end
