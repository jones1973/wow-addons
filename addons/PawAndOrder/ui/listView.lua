-- UI/ListView.lua
local ADDON_NAME, Addon = ...

Addon.ListView = Addon.ListView or {}
local ListView = Addon.ListView

-- ListView object-oriented widget factory
function ListView:New(parent, width, height, rowHeight, maxRows)
    local self = setmetatable({}, {__index = ListView})
    
    self.frame = CreateFrame("Frame", nil, parent)
    self.frame:SetSize(width, height)
    
    -- ScrollFrame - Use ScrollFrameTemplate for MoP compatibility
    self.scrollFrame = CreateFrame("ScrollFrame", nil, self.frame, "ScrollFrameTemplate")
    self.scrollFrame:SetPoint("TOPLEFT", self.frame, "TOPLEFT", 0, 0)
    self.scrollFrame:SetPoint("BOTTOMRIGHT", self.frame, "BOTTOMRIGHT", -25, 0)
    
    -- Content Frame for scrollable rows
    self.content = CreateFrame("Frame", nil, self.scrollFrame)
    self.scrollFrame:SetScrollChild(self.content)
    self.content:SetSize(width-25, height) -- Scrollbar is 25px wide
    
    self.rowHeight = rowHeight or 28
    self.maxRows = maxRows or math.floor(height / self.rowHeight)
    self.rows = {}
    
    -- Mousewheel support with fallback for MoP
    self.scrollFrame:EnableMouseWheel(true)
    self.scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        -- Try modern scrollbar first, fallback to manual scrolling
        local scrollBar = self.scrollFrame.ScrollBar or self.scrollFrame.scrollBar
        if scrollBar then
            scrollBar:SetValue(scrollBar:GetValue() - delta * 24)
        else
            -- Manual scrolling fallback
            local current = self.scrollFrame:GetVerticalScroll()
            local max = self.scrollFrame:GetVerticalScrollRange()
            local new = math.max(0, math.min(max, current - delta * 40))
            self.scrollFrame:SetVerticalScroll(new)
        end
    end)
    
    -- data
    self.data = {}
    self.OnRowClick = nil
    
    self:CreateRows()
    return self
end

function ListView:CreateRows()
    for i = 1, self.maxRows do
        local row = CreateFrame("Button", nil, self.content)
        row:SetSize(self.content:GetWidth(), self.rowHeight)
        
        if i == 1 then
            row:SetPoint("TOPLEFT", self.content, "TOPLEFT", 0, 0)
        else
            row:SetPoint("TOPLEFT", self.rows[i-1], "BOTTOMLEFT", 0, 0)
        end
        
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetTexture(0.13, 0.13, 0.13)
        row.bg:SetAlpha(0.7)
        
        row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
        
        -- Main text field
        row.text = row:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        row.text:SetPoint("LEFT", 8, 0)
        row.text:SetWidth(self.content:GetWidth() - 40)
        row.text:SetJustifyH("LEFT")
        
        -- For icon support add row.icon extending as needed
        row.icon = row:CreateTexture(nil, "ARTWORK")
        row.icon:SetSize(22, 22)
        row.icon:SetPoint("LEFT", 2, 0)
        row.icon:Hide()
        
        -- Row click event
        row:SetScript("OnClick", function(btn)
            if self.OnRowClick then
                self.OnRowClick(self, btn, row.idx, row.data)
            end
        end)
        row:RegisterForClicks("AnyDown")
        
        -- Tooltip support
        row:SetScript("OnEnter", function()
            if self.OnRowEnter then
                self.OnRowEnter(self, row.idx, row.data, row)
            end
        end)
        
        row:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        
        row:Hide()
        self.rows[i] = row
    end
end

-- Public: Set list data (array of tables, or text)
function ListView:SetData(data)
    self.data = data or {}
    self:Refresh()
end

function ListView:Refresh()
    local offset = self.scrollFrame.offset or 0
    local shownRows = 0
    
    -- ScrollFrame Elements for classic - Use FauxScrollFrame for MoP
    if FauxScrollFrame_Update then
        FauxScrollFrame_Update(self.scrollFrame, #self.data, self.maxRows, self.rowHeight)
    end
    
    for i = 1, self.maxRows do
        local row = self.rows[i]
        local idx = i + offset
        
        if self.data[idx] then
            local entry = self.data[idx]
            row.idx = idx
            row.data = entry
            
            -- Display icon if .icon or .texture present
            if entry.icon then
                row.icon:SetTexture(entry.icon)
                row.icon:Show()
                row.text:SetPoint("LEFT", row.icon, "RIGHT", 4, 0)
            else
                row.icon:Hide()
                row.text:SetPoint("LEFT", 8, 0)
            end
            
            -- Show main label
            row.text:SetText(entry.text or entry.name or tostring(entry))
            row:Show()
            shownRows = shownRows + 1
        else
            row:Hide()
        end
    end
    
    -- Resize to fit
    self.content:SetHeight(math.max(1, shownRows * self.rowHeight))
end

-- Optional: allows callback for row clicks
function ListView:SetOnRowClick(func)
    self.OnRowClick = func
end

function ListView:SetOnRowEnter(func)
    self.OnRowEnter = func
end

-- Self-register with dependency system
if Addon.registerModule then
    Addon.registerModule("listView", {}, function()
        return true
    end)
end

return ListView
