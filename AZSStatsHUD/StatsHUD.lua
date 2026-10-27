-- Standalone, read-only display of the game's AZS statistics.
-- Uses the old 1.12 event model and never depends on a global _G table.
AZSStatsHUD = { version = "0.3.0", rows = {}, lastStats = nil }
local HUD = AZSStatsHUD
local floor, max, min = math.floor, math.max, math.min
local width, rowHeight = 338, 19
local inset, gap = 9, 9
local columnWidth = (width - inset * 2 - gap) / 2
local backdrop = {
    bgFile = "Interface\\Tooltips\\UI-Tooltip-Background",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
}
local primary = {
    { "����ֵ", "hp", "number0" }, { "�˺�", "dmg", "delta" },
    { "����", "cd", "haste" }, { "����", "crit", "percent1" },
    { "�����˺�", "cm", "percent0" }, { "����", "arm", "percent0" },
    { "��Χ", "area", "delta" }, { "Ŀ����", "cnt", "signedNumber" },
    { "����", "echo", "percent0" }, { "�ٶ�", "spd", "delta" },
    { "�ظ�", "reg", "number1" }, { "ʰȡ", "pick", "yards" }
}
local adventure = {
    { "����͵ȡ", "lch", "percent1" }, { "��ɱ����", "heal", "number0" },
    { "����", "thn", "percent0" }, { "������", "liv", "number0" },
    { "����ֵ", "xp", "delta" }, { "���", "gold", "delta" },
    { "����", "luck", "signedPercent" }, { "����ǿ��", "bp", "signedPercent" },
    { "�����˺�����", "dots", "number0" }, { "�����˺�����", "doth", "signedPercent" },
    { "�Ծ�Ӣ�˺�", "big", "signedPercent", true }, { "նɱ�˺�", "exe", "signedPercent", true },
    { "���ܿ��˺�", "cc", "signedPercent", true }, { "�Գ����˺�Ŀ��", "dotd", "signedPercent", true },
    { "����ʱ�˺�", "shd", "signedPercent", true }, { "��ս�˺�", "auto", "signedPercent", true },
    { "�����˺�", "pet", "signedPercent", true }
}
HUD.primaryDefinitions, HUD.adventureDefinitions = primary, adventure
local function say(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff65c9ff������壺|r " .. tostring(message)) end
end
local function config()
    if type(AZSStatsHUDDB) ~= "table" then AZSStatsHUDDB = {} end
    local db = AZSStatsHUDDB
    if db.visible == nil then db.visible = true end
    if db.locked == nil then db.locked = false end
    if type(db.scale) ~= "number" or db.scale < 0.6 or db.scale > 1.6 then db.scale = 1 end
    if type(db.width) ~= "number" or db.width ~= db.width then db.width = 338 end
    db.width = max(280, min(700, db.width))
    if type(db.height) ~= "number" or db.height ~= db.height then db.height = nil
    elseif db.height < 68 then db.height = 68 elseif db.height > 900 then db.height = 900 end
    return db
end

function HUD:Format(value, formatType)
    local n = tonumber(value)
    if not n or n ~= n then return "--" end
    if formatType == "delta" then return string.format("%+.0f%%", (n - 1) * 100) end
    if formatType == "haste" then return string.format("%+.0f%%", (1 - n) * 100) end
    if formatType == "signedPercent" then return string.format("%+.0f%%", n * 100) end
    if formatType == "percent0" then return string.format("%.0f%%", n * 100) end
    if formatType == "percent1" then return string.format("%.1f%%", n * 100) end
    if formatType == "number1" then return string.format("%.1f", n) end
    if formatType == "signedNumber" then return string.format("%+.0f", n) end
    if formatType == "yards" then return string.format("%.0f��", n) end
    return string.format("%.0f", n)
end

function HUD:Parse(message)
    if type(message) ~= "string" then return nil end
    local stats, position, found = {}, 1, false
    while true do
        local first, last, key, value = string.find(message, "(%w+)=([^;]*)", position)
        if not first then break end
        local n = tonumber(value)
        if n then stats[key] = n; found = true end
        position = last + 1
    end
    if not found then return nil end
    return stats
end

local frame = CreateFrame("Frame", "AZSStatsHUDFrame", UIParent)
HUD.frame = frame
frame:SetWidth(width); frame:SetHeight(80)
frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 24, -155)
frame:SetBackdrop(backdrop); frame:SetBackdropColor(0.035, 0.045, 0.06, 0.88)
frame:SetBackdropBorderColor(0.35, 0.42, 0.48, 0.9)
frame:SetMovable(true); frame:SetClampedToScreen(true); frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", function() if not config().locked then this:StartMoving() end end)
frame:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local point, relative, relativePoint, x, y = this:GetPoint(1)
    if point and relativePoint then config().position = { point, relativePoint, x, y } end
end)
-- Resize in both directions without changing the font scale.
local grip = CreateFrame("Frame", "AZSStatsHUDScaleGrip", frame)
HUD.grip = grip
grip:SetWidth(18); grip:SetHeight(18)
grip:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -2, 2)
grip:EnableMouse(true)
local gripText = grip:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
gripText:SetPoint("BOTTOMRIGHT", grip, "BOTTOMRIGHT", -1, 1)
gripText:SetTextColor(0.65, 0.72, 0.78); gripText:SetText("/")
local dragX, dragY, dragWidth, dragHeight
grip:SetScript("OnMouseDown", function()
    if arg1 ~= "LeftButton" or config().locked or type(GetCursorPosition) ~= "function" then return end
    dragX, dragY = GetCursorPosition()
    if type(dragX) ~= "number" or type(dragY) ~= "number" then dragX = nil; return end
    dragWidth, dragHeight = frame:GetWidth(), frame:GetHeight()
end)
grip:SetScript("OnUpdate", function()
    if not dragX then return end
    local x, y = GetCursorPosition()
    local effectiveScale = frame:GetEffectiveScale()
    if type(x) ~= "number" or type(y) ~= "number" or not effectiveScale or effectiveScale <= 0 then return end
    local db = config()
    db.width = max(280, min(700, dragWidth + (x - dragX) / effectiveScale))
    db.height = max(68, min(900, dragHeight + (dragY - y) / effectiveScale))
    HUD:Render(HUD.lastStats)
end)
grip:SetScript("OnMouseUp", function() dragX = nil end)
grip:SetScript("OnHide", function() dragX = nil end)
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOPLEFT", frame, "TOPLEFT", 11, -9); title:SetText("��ɫ����")
local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hint:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -11, -10)
hint:SetTextColor(0.62, 0.68, 0.72); hint:SetText("/ast")
local waiting = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
waiting:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -35)
waiting:SetWidth(width - 24); waiting:SetJustifyH("LEFT")
waiting:SetText("�ȴ���Ϸ�������ݡ���")
waiting:SetTextColor(0.72, 0.74, 0.77)
local section = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
section:SetText("ð������")
local divider = frame:CreateTexture(nil, "ARTWORK")
divider:SetTexture("Interface\\Buttons\\WHITE8X8")
divider:SetVertexColor(0.35, 0.42, 0.48, 0.7)
divider:SetHeight(1)

local function newRow()
    local row = CreateFrame("Frame", nil, frame)
    row:SetWidth(columnWidth); row:SetHeight(rowHeight)
    local label = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    label:SetPoint("LEFT", row, "LEFT", 0, 0); label:SetWidth(columnWidth - 52); label:SetJustifyH("LEFT")
    label:SetTextColor(1, 0.82, 0)
    local value = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    value:SetPoint("RIGHT", row, "RIGHT", 0, 0); value:SetWidth(52); value:SetJustifyH("RIGHT")
    value:SetTextColor(1, 1, 1)
    row.label, row.value = label, value
    return row
end

local function placeRows(definitions, stats, y, offset)
    local visible, index = 0, 0
    for index = 1, table.getn(definitions) do
        local definition = definitions[index]
        local raw = stats[definition[2]]
        if not definition[4] or (tonumber(raw) and tonumber(raw) ~= 0) then
            visible = visible + 1
            local rowIndex = offset + visible
            local row = HUD.rows[rowIndex]
            if not row then row = newRow(); HUD.rows[rowIndex] = row end
            row:SetWidth(columnWidth); row.label:SetWidth(columnWidth - 52)
            local col = visible - 1 - floor((visible - 1) / 2) * 2
            local line = floor((visible - 1) / 2)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", frame, "TOPLEFT", inset + col * (columnWidth + gap), -y - line * rowHeight)
            row.label:SetText(definition[1] .. ":")
            row.value:SetText(HUD:Format(raw, definition[3]))
            row:Show()
        end
    end
    return y + floor((visible + 1) / 2) * rowHeight, offset + visible
end

function HUD:Render(stats)
    local db = config()
    width = db.width
    columnWidth = (width - inset * 2 - gap) / 2
    frame:SetWidth(width)
    waiting:SetWidth(width - 24)
    if type(stats) ~= "table" then
        waiting:Show(); section:Hide(); divider:Hide()
        local index
        for index = 1, table.getn(self.rows) do self.rows[index]:Hide() end
        frame:SetHeight(max(68, db.height or 0))
        return
    end
    waiting:Hide()
    local y, used = placeRows(primary, stats, 31, 0)
    y = y + 8
    divider:ClearAllPoints()
    divider:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -y)
    divider:SetWidth(width - inset * 2); divider:Show()
    y = y + 10
    section:ClearAllPoints()
    section:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -y); section:Show()
    y = y + 22
    y, used = placeRows(adventure, stats, y, used)
    local index
    for index = used + 1, table.getn(self.rows) do self.rows[index]:Hide() end
    frame:SetHeight(max(y + 10, db.height or 0))
end

local initialized, pending, elapsed = false, nil, 0
local function initialize()
    if initialized then return end
    initialized = true
    local db = config()
    frame:SetScale(db.scale)
    if type(db.position) == "table" and type(db.position[1]) == "string" and type(db.position[2]) == "string" then
        frame:ClearAllPoints()
        frame:SetPoint(db.position[1], UIParent, db.position[2], tonumber(db.position[3]) or 0, tonumber(db.position[4]) or 0)
    end
    frame:EnableMouse(not db.locked)
    if db.locked then grip:Hide() else grip:Show() end
    if db.visible then frame:Show() else frame:Hide() end
    if type(AZS_STATS) == "table" then HUD.lastStats = AZS_STATS end
    HUD:Render(HUD.lastStats)
    say("�Ѽ��أ��϶�����ƶ������� /ast �鿴���á�")
end

local driver = CreateFrame("Frame", "AZSStatsHUDDriver", UIParent)
driver:RegisterEvent("ADDON_LOADED"); driver:RegisterEvent("PLAYER_ENTERING_WORLD"); driver:RegisterEvent("CHAT_MSG_ADDON")
driver:SetScript("OnEvent", function()
    if event == "ADDON_LOADED" then
        if arg1 == "AZSStatsHUD" then initialize() end
    elseif event == "PLAYER_ENTERING_WORLD" then
        initialize()
        if type(AZS_STATS) == "table" then HUD.lastStats = AZS_STATS; pending = AZS_STATS end
    elseif event == "CHAT_MSG_ADDON" and arg1 == "AZS" then
        local stats = HUD:Parse(arg2)
        if stats then HUD.lastStats = stats; pending = stats end
    end
end)
driver:SetScript("OnUpdate", function()
    if not initialized or not pending then return end
    elapsed = elapsed + (tonumber(arg1) or 0)
    if elapsed < 0.25 then return end
    elapsed = 0
    local nextStats = pending
    pending = nil
    HUD:Render(nextStats)
end)

SLASH_AZSSTATSHUD1 = "/ast"
SLASH_AZSSTATSHUD2 = "/azstats"
SlashCmdList["AZSSTATSHUD"] = function(message)
    initialize()
    local _, _, cmd, value = string.find(string.lower(message or ""), "^%s*(%S*)%s*(.-)%s*$")
    local db = config()
    if cmd == "" then
        db.visible = not db.visible
        if db.visible then frame:Show() else frame:Hide() end
    elseif cmd == "show" then db.visible = true; frame:Show()
    elseif cmd == "hide" then db.visible = false; frame:Hide()
    elseif cmd == "lock" then db.locked = true; frame:EnableMouse(false); grip:Hide(); say("�����������ɴ�����/ast unlock ������")
    elseif cmd == "unlock" then db.locked = false; frame:EnableMouse(true); grip:Show(); say("�ѽ��������϶��������½ǵ������ߡ�")
    elseif cmd == "scale" then
        local n = tonumber(value)
        if n and n >= 0.6 and n <= 1.6 then db.scale = n; frame:SetScale(n); say("��������Ϊ " .. n)
        else say("�÷���/ast scale 0.6 �� 1.6������ /ast scale 0.8") end
    elseif cmd == "reset" then
        db.position = nil; db.scale = 1; db.width = 338; db.height = nil; db.locked = false; db.visible = true
        frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 24, -155)
        frame:SetScale(1); frame:EnableMouse(true); grip:Show(); frame:Show(); HUD:Render(HUD.lastStats); say("�ѻָ�Ĭ��λ�úʹ�С��")
    elseif cmd == "debug" then
        say("�汾 " .. HUD.version .. "������=" .. (HUD.lastStats and "���յ�" or "��δ�յ�") .. "���ɼ�=" .. tostring(db.visible))
    else
        say("/ast ��ʾ�����أ�/ast lock ������/ast unlock ������/ast scale 0.8 ���ţ�/ast reset ��λ��")
    end
end
