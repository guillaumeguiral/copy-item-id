local addonName = ...

-- Binding descriptions (must be global for WoW keybinding UI)
BINDING_HEADER_COPY_ITEM_ID_HEADER = "Copy Item Id"
BINDING_NAME_COPY_ITEM_ID = "Copy Item ID"

-- StaticPopupDialog for copy
StaticPopupDialogs["CopyItemIdPopup"] = {
    text = "Item ID\nCTRL-C to copy",
    button1 = "Close",
    OnShow = function(self, data)
        local function HidePopup(self) self:GetParent():Hide() end

        local editBox = self.EditBox or self.editBox
        if not editBox then return end

        editBox:SetScript("OnEscapePressed", HidePopup)
        editBox:SetScript("OnEnterPressed", HidePopup)
        editBox:SetScript("OnKeyUp", function(self, key)
            if IsControlKeyDown() and key == "C" then HidePopup(self) end
        end)
        editBox:SetMaxLetters(0)
        editBox:SetText(data)
        editBox:HighlightText()
    end,
    hasEditBox = true,
    editBoxWidth = 240,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Extract Item ID from the currently displayed tooltip
local function GetItemIdFromTooltip()
    local name, link = GameTooltip:GetItem()
    if not link then
        name, link = ItemRefTooltip:GetItem()
    end
    if not link then return nil end

    local id = link:match("|Hitem:(%d+):")
    return id
end

-- Main function called by the keybinding
function CopyItemId_Run()
    local itemId = GetItemIdFromTooltip()
    if itemId then
        StaticPopup_Show("CopyItemIdPopup", nil, nil, itemId)
    end
end

local function EnsureDefaultBinding(bindingName, defaultKey)
    local bind1, bind2 = GetBindingKey(bindingName)
    local action = GetBindingAction(defaultKey)

    -- Only set the default when the addon action is unbound
    -- and the target key is currently unused.
    if bind1 == nil and bind2 == nil and action == "" then
        SetBinding(defaultKey, bindingName)
        return true
    end

    return false
end

-- Default binding setup
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        if CopyItemIdDB == nil then
            CopyItemIdDB = {}
        end
    elseif event == "PLAYER_LOGIN" then
        if CopyItemIdDB == nil then
            CopyItemIdDB = {}
        end

        local bind1, bind2 = GetBindingKey("COPY_ITEM_ID")
        local hasBinding = bind1 ~= nil or bind2 ~= nil

        if CopyItemIdDB.default_bindings_set == nil or not hasBinding then
            local didSet = EnsureDefaultBinding("COPY_ITEM_ID", "CTRL-C")
            if didSet then
                SaveBindings(GetCurrentBindingSet())
            end

            -- Mark setup as complete only once the action has a keybind.
            bind1, bind2 = GetBindingKey("COPY_ITEM_ID")
            if bind1 ~= nil or bind2 ~= nil then
                CopyItemIdDB.default_bindings_set = true
            end
        end

        self:UnregisterEvent("PLAYER_LOGIN")
    end
end)
