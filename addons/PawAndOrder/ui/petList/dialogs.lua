--[[
  ui/petList/dialogs.lua
  StaticPopupDialogs for Pet List Operations
  
  Extracted from petList.lua. Defines popup dialogs for rename, release, and cage
  operations. Each dialog calls back to petList for post-operation handling.
  Also provides Addon.dialogs:showUncageConfirm() for learning caged pets, which
  requires a custom frame (SecureActionButtonTemplate via actionButton) because
  C_Container.UseContainerItem is a protected function.
  
  Dependencies: popupFactory, actionButton (for showUncageConfirm)
  Used by: petList, contextMenu
]]

local ADDON_NAME, Addon = ...

--[[
  Rename dialog with restore default option
  Allows renaming a pet or restoring its default species name.
]]
StaticPopupDialogs["PAO_PET_RENAME"] = {
    text = "Rename %s\n\nEnter a new name or click Restore Default to use the original name.",
    button1 = ACCEPT,
    button2 = CANCEL,
    button3 = "Restore Default",
    hasEditBox = 1,
    maxLetters = 16,
    OnShow = function(dialog, data)
        local petData = data
        if petData then
            local editBox = dialog:GetEditBox()
            if petData.customName and petData.customName ~= "" then
                editBox:SetText(petData.customName)
            else
                editBox:SetText("")
            end
            editBox:SetFocus()
            editBox:HighlightText()
        end
    end,
    OnAccept = function(dialog, data)
        local petData = data
        if petData and petData.petID then
            local text = dialog:GetEditBox():GetText()
            C_PetJournal.SetCustomName(petData.petID, text)
            if Addon.events then
                Addon.events:emit("COLLECTION:PET_RENAMED", {petData = petData})
            end
        end
    end,
    OnAlt = function(dialog, data)
        local petData = data
        if petData and petData.petID then
            C_PetJournal.SetCustomName(petData.petID, "")
            if Addon.events then
                Addon.events:emit("COLLECTION:PET_RENAMED", {petData = petData})
            end
        end
    end,
    EditBoxOnEnterPressed = function(editBox, data)
        local petData = data
        if petData and petData.petID then
            local dialog = editBox:GetParent()
            local text = editBox:GetText()
            C_PetJournal.SetCustomName(petData.petID, text)
            if Addon.events then
                Addon.events:emit("COLLECTION:PET_RENAMED", {petData = petData})
            end
            dialog:Hide()
        end
    end,
    EditBoxOnEscapePressed = function(editBox)
        editBox:GetParent():Hide()
    end,
    OnHide = function(dialog)
        dialog:GetEditBox():SetText("")
    end,
    timeout = 0,
    exclusive = 1,
    hideOnEscape = 1
}

--[[
  Release confirmation dialog
  Confirms permanent release of a pet.
]]
StaticPopupDialogs["PAO_PET_RELEASE"] = {
    text = "Release %s?\n\nThis cannot be undone.",
    button1 = OKAY,
    button2 = CANCEL,
    OnAccept = function(dialog, data)
        local petData = data
        if petData and petData.petID then
            C_PetJournal.ReleasePetByID(petData.petID)
            if Addon.events then
                Addon.events:emit("COLLECTION:PET_RELEASED", {petData = petData})
            end
        end
    end,
    timeout = 0,
    exclusive = 1,
    hideOnEscape = 1,
    showAlert = 1
}

--[[
  Uncage confirmation frame (custom, not StaticPopup).

  C_Container.UseContainerItem is protected; it cannot be called from OnAccept.
  actionButton:create() with secureType="macro" produces a SecureActionButtonTemplate
  button styled to match PAO. setSecureAction() updates the macrotext fresh each
  show so the correct bag/slot is always used.
]]
local uncageConfirmFrame = nil

local function createUncageConfirmFrame()
    if uncageConfirmFrame then return uncageConfirmFrame end

    -- 300w × 226h: 72px popupFactory header + 16 gap + 76 message (4 lines) + 16 gap + 32 buttons + 14 bottom
    local frame = Addon.popupFactory:create({
        title  = "Learn Pet",
        icon   = 613074,  -- placeholder; overwritten per-pet in showUncageConfirm
        width  = 300,
        height = 226,
    })

    -- Body text anchored below the popupFactory content anchor
    frame.message = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.message:SetPoint("TOP", frame.contentAnchor, "TOP", 0, -16)
    frame.message:SetWidth(260)
    frame.message:SetJustifyH("CENTER")
    frame.message:SetText("This will teach you the pet and\nconsume the cage.\n\nThis will dismount you.")

    -- "Learn Pet" — SecureActionButtonTemplate via actionButton (secureType implies secure=true)
    -- macrotext is a placeholder; setSecureAction() overwrites it in showUncageConfirm
    frame.learnButton = Addon.actionButton:create(frame, {
        text       = "Learn Pet",
        size       = "medium",
        style      = 3,
        secureName = "PAOUncageLearnButton",
        secureType = "macro",
        secureId   = "/use 0 0",
    })
    frame.learnButton:SetPoint("BOTTOMRIGHT", frame, "BOTTOM", -4, 14)
    frame.learnButton:SetScript("PostClick", function()
        frame:Hide()
    end)

    -- Cancel
    frame.cancelButton = Addon.actionButton:create(frame, {
        text    = "Cancel",
        size    = "medium",
        style   = 3,
        onClick = function() frame:Hide() end,
    })
    frame.cancelButton:SetPoint("BOTTOMLEFT", frame, "BOTTOM", 4, 14)

    uncageConfirmFrame = frame
    return frame
end

if not Addon.dialogs then Addon.dialogs = {} end

--[[
  Show the uncage confirmation frame for a caged pet.
  Updates title, icon, and macrotext fresh on each call.

  @param petData table - Must contain .bag, .slot; optionally .speciesName, .icon
]]
function Addon.dialogs:showUncageConfirm(petData)
    if not petData or not petData.bag or not petData.slot then return end

    local frame = createUncageConfirmFrame()

    -- Title and icon reflect the specific pet being learned
    local name = petData.speciesName or "Pet"
    frame.titleText:SetText("Learn " .. name .. "?")
    if petData.icon and frame.iconTexture then
        frame.iconTexture:SetTexture(petData.icon)
    end

    -- macrotext set fresh each call so bag/slot is always current
    frame.learnButton:setSecureAction("macro",
        string.format("/use %d %d", petData.bag, petData.slot))

    frame:Show()
end

--[[
  Cage confirmation dialog
  Confirms caging a pet for trading.
]]
StaticPopupDialogs["PAO_PET_CAGE"] = {
    text = "Put %s in a cage?\n\nThis will make it tradable.",
    button1 = OKAY,
    button2 = CANCEL,
    OnAccept = function(dialog, data)
        local petData = data
        if petData and petData.petID then
            C_PetJournal.CagePetByID(petData.petID)
            if Addon.events then
                Addon.events:emit("COLLECTION:PET_CAGED", {petData = petData})
            end
        end
    end,
    timeout = 0,
    exclusive = 1,
    hideOnEscape = 1
}