-- Standalone, read-only display of the game's AZS statistics.
-- Uses the old 1.12 event model and never depends on a global _G table.
AZSStatsHUD = { version = "0.4.1", rows = {}, lastStats = nil, language = "zh" }
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
    { "生命值", "hp", "number0" }, { "伤害", "dmg", "delta" },
    { "急速", "cd", "haste" }, { "暴击", "crit", "percent1" },
    { "暴击伤害", "cm", "percent0" }, { "护甲", "arm", "percent0" },
    { "范围", "area", "delta" }, { "目标数", "cnt", "signedNumber" },
    { "回响", "echo", "percent0" }, { "速度", "spd", "delta" },
    { "回复", "reg", "number1" }, { "拾取", "pick", "yards" }
}
local adventure = {
    { "生命偷取", "lch", "percent1" }, { "击杀治疗", "heal", "number0" },
    { "荆棘", "thn", "percent0" }, { "生命数", "liv", "number0" },
    { "经验值", "xp", "delta" }, { "金币", "gold", "delta" },
    { "幸运", "luck", "signedPercent" }, { "增益强度", "bp", "signedPercent" },
    { "持续伤害层数", "dots", "number0" }, { "持续伤害急速", "doth", "signedPercent" },
    { "对精英伤害", "big", "signedPercent", true }, { "斩杀伤害", "exe", "signedPercent", true },
    { "对受控伤害", "cc", "signedPercent", true }, { "对持续伤害目标", "dotd", "signedPercent", true },
    { "护盾时伤害", "shd", "signedPercent", true }, { "近战伤害", "auto", "signedPercent", true },
    { "宠物伤害", "pet", "signedPercent", true }
}
HUD.primaryDefinitions, HUD.adventureDefinitions = primary, adventure
local english = {
    ["角色属性"] = "Character Stats", ["冒险属性"] = "Adventure Stats", ["属性面板："] = "Stats HUD: ",
    ["生命值"] = "Health", ["伤害"] = "Damage", ["急速"] = "Haste", ["暴击"] = "Critical", ["暴击伤害"] = "Crit Damage", ["护甲"] = "Armor",
    ["范围"] = "Area", ["目标数"] = "Targets", ["回响"] = "Echo", ["速度"] = "Speed", ["回复"] = "Regen", ["拾取"] = "Pickup",
    ["生命偷取"] = "Life Steal", ["击杀治疗"] = "Kill Healing", ["荆棘"] = "Thorns", ["生命数"] = "Lives", ["经验值"] = "Experience", ["金币"] = "Gold",
    ["幸运"] = "Luck", ["增益强度"] = "Buff Power", ["持续伤害层数"] = "DoT Stacks", ["持续伤害急速"] = "DoT Haste",
    ["对精英伤害"] = "Elite Damage", ["斩杀伤害"] = "Execute Damage", ["对受控伤害"] = "CC Damage", ["对持续伤害目标"] = "Damage vs DoT",
    ["护盾时伤害"] = "Shield Damage", ["近战伤害"] = "Melee Damage", ["宠物伤害"] = "Pet Damage",
    ["等待游戏属性数据……"] = "Waiting for stats...", ["码"] = " yd",
    ["已加载；拖动面板移动，输入 /ast 查看设置。"] = "Loaded. Drag to move; enter /ast help for options.",
    ["已锁定，鼠标可穿过；/ast unlock 解锁。"] = "Locked; mouse clicks pass through. Use /ast unlock to unlock.",
    ["已解锁，可拖动面板或右下角调整宽高。"] = "Unlocked. Drag the panel to move or the corner to resize.",
    ["用法：/ast scale 0.6 到 1.6，例如 /ast scale 0.8"] = "Usage: /ast scale 0.6 to 1.6, e.g. /ast scale 0.8",
    ["已恢复默认位置和大小。"] = "Default position and size restored.",
    ["/ast 显示或隐藏；/ast lock 锁定；/ast unlock 解锁；/ast scale 0.8 缩放；/ast reset 复位。"] = "/ast: show/hide; lock, unlock, scale 0.8, reset; lang auto/en/zh.",
    ["缩放已设为 "] = "Scale set to ", ["版本 "] = "Version ", ["；数据="] = "; data=", ["已收到"] = "received", ["尚未收到"] = "waiting", ["；可见="] = "; visible=",
    ["语言："] = "Language: ", ["用法：/ast lang auto、en 或 zh"] = "Usage: /ast lang auto, en or zh"
}
local function tr(s) if HUD.language == "en" then return english[s] or s end return s end
local function chooseLanguage(db)
    local mode = db.language or "zh"
    if mode == "zh" or mode == "en" then return mode end
    if type(GetLocale) == "function" then
        local ok, locale = pcall(GetLocale)
        if ok and (locale == "zhCN" or locale == "zhTW") then return "zh" end
    end
    return "en"
end
local function say(message)
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("|cff65c9ff" .. tr("属性面板：") .. "|r " .. tostring(message)) end
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
    if formatType == "yards" then return string.format("%.0f", n) .. tr("码") end
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
title:SetPoint("TOPLEFT", frame, "TOPLEFT", 11, -9); title:SetText("角色属性")
local hint = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
hint:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -11, -10)
hint:SetTextColor(0.62, 0.68, 0.72); hint:SetText("/ast")
local waiting = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
waiting:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -35)
waiting:SetWidth(width - 24); waiting:SetJustifyH("LEFT")
waiting:SetText("等待游戏属性数据……")
waiting:SetTextColor(0.72, 0.74, 0.77)
local section = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
section:SetText("冒险属性")
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
            row.label:SetText(tr(definition[1]) .. ":")
            row.value:SetText(HUD:Format(raw, definition[3]))
            row:Show()
        end
    end
    return y + floor((visible + 1) / 2) * rowHeight, offset + visible
end

function HUD:Render(stats)
    local db = config()
    title:SetText(tr("角色属性")); section:SetText(tr("冒险属性")); waiting:SetText(tr("等待游戏属性数据……"))
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
    HUD.language = chooseLanguage(db)
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
    say(tr("已加载；拖动面板移动，输入 /ast 查看设置。"))
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
    elseif cmd == "lock" then db.locked = true; frame:EnableMouse(false); grip:Hide(); say(tr("已锁定，鼠标可穿过；/ast unlock 解锁。"))
    elseif cmd == "unlock" then db.locked = false; frame:EnableMouse(true); grip:Show(); say(tr("已解锁，可拖动面板或右下角调整宽高。"))
    elseif cmd == "lang" then
        if value == "auto" or value == "en" or value == "zh" then
            db.language = value; HUD.language = chooseLanguage(db); HUD:Render(HUD.lastStats); say(tr("语言：") .. value)
        else say(tr("用法：/ast lang auto、en 或 zh")) end
    elseif cmd == "scale" then
        local n = tonumber(value)
        if n and n >= 0.6 and n <= 1.6 then db.scale = n; frame:SetScale(n); say(tr("缩放已设为 ") .. n)
        else say(tr("用法：/ast scale 0.6 到 1.6，例如 /ast scale 0.8")) end
    elseif cmd == "reset" then
        db.position = nil; db.scale = 1; db.width = 338; db.height = nil; db.locked = false; db.visible = true
        frame:ClearAllPoints(); frame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 24, -155)
        frame:SetScale(1); frame:EnableMouse(true); grip:Show(); frame:Show(); HUD:Render(HUD.lastStats); say(tr("已恢复默认位置和大小。"))
    elseif cmd == "debug" then
        say(tr("版本 ") .. HUD.version .. tr("；数据=") .. tr(HUD.lastStats and "已收到" or "尚未收到") .. tr("；可见=") .. tostring(db.visible))
    else
        say(tr("/ast 显示或隐藏；/ast lock 锁定；/ast unlock 解锁；/ast scale 0.8 缩放；/ast reset 复位。"))
    end
end
