
-- Unit Aura functions that return info about the first Aura matching the spellName or spellID given on the unit.
 WA_GetUnitAura = function(unit, spell, filter)
  if filter and not filter:upper():find("FUL") then
      filter = filter.."|HELPFUL"
  end
  for i = 1, 255 do
    local name, _, _, _, _, _, _, _, _, spellId = UnitAura(unit, i, filter)
    if not name then return end
    if spell == spellId or spell == name then
      return UnitAura(unit, i, filter)
    end
  end
end

if WeakAuras.IsClassicEra() then
  WA_GetUnitAuraBase = WA_GetUnitAura
  WA_GetUnitAura = function(unit, spell, filter)
    local name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId,
          canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod = WA_GetUnitAuraBase(unit, spell, filter)
    if spellId then
      local durationNew, expirationTimeNew = LCD:GetAuraDurationByUnit(unit, spellId, source, name)
      if duration == 0 and durationNew then
          duration = durationNew
          expirationTime = expirationTimeNew
      end
    end
    return name, icon, count, debuffType, duration, expirationTime, source, isStealable, nameplateShowPersonal, spellId,
           canApplyAura, isBossDebuff, castByPlayer, nameplateShowAll, timeMod
  end
end

 WA_GetUnitBuff = function(unit, spell, filter)
  filter = filter and filter.."|HELPFUL" or "HELPFUL"
  return WA_GetUnitAura(unit, spell, filter)
end

 WA_GetUnitDebuff = function(unit, spell, filter)
  filter = filter and filter.."|HARMFUL" or "HARMFUL"
  return WA_GetUnitAura(unit, spell, filter)
end

-- Function to assist iterating group members whether in a party or raid.
 WA_IterateGroupMembers = function(reversed, forceParty)
  local unit = (not forceParty and IsInRaid()) and 'raid' or 'party'
  local numGroupMembers = unit == 'party' and GetNumSubgroupMembers() or GetNumGroupMembers()
  local i = reversed and numGroupMembers or (unit == 'party' and 0 or 1)
  return function()
    local ret
    if i == 0 and unit == 'party' then
      ret = 'player'
    elseif i <= numGroupMembers and i > 0 then
      ret = unit .. i
    end
    i = i + (reversed and -1 or 1)
    return ret
  end
end

-- Wrapping a unit's name in its class colour is very common in custom Auras
 WA_ClassColorName = function(unit)
  if unit and UnitExists(unit) then
    local name = UnitName(unit)
    local _, class = UnitClass(unit)
    if not class then
      return name
    else
      local classData = (CUSTOM_CLASS_COLORS or RAID_CLASS_COLORS)[class]
      local coloredName = ("|c%s%s|r"):format(classData.colorStr, name)
      return coloredName
    end
  else
    return "" -- ¯\_(ツ)_/¯
  end
end

WeakAuras.WA_ClassColorName = WA_ClassColorName

-- UTF-8 Sub is pretty commonly needed
 WA_Utf8Sub = function(input, size)
  local output = ""
  if type(input) ~= "string" then
    return output
  end
  local i = 1
  while (size > 0) do
    local byte = input:byte(i)
    if not byte then
      return output
    end
    if byte < 128 then
      -- ASCII byte
      output = output .. input:sub(i, i)
      size = size - 1
    elseif byte < 192 then
      -- Continuation bytes
      output = output .. input:sub(i, i)
    elseif byte < 244 then
      -- Start bytes
      output = output .. input:sub(i, i)
      size = size - 1
    end
    i = i + 1
  end

  -- Add any bytes that are part of the sequence
  while (true) do
    local byte = input:byte(i)
    if byte and byte >= 128 and byte < 192 then
      output = output .. input:sub(i, i)
    else
      break
    end
    i = i + 1
  end

  return output
end

WeakAuras.WA_Utf8Sub = WA_Utf8Sub


local blockedFunctions = {
  -- Lua functions that may allow breaking out of the environment
  getfenv = true,
  setfenv = true,
  loadstring = true,
  pcall = true,
  xpcall = true,
  -- blocked WoW API
  SendMail = true,
  SetTradeMoney = true,
  AddTradeMoney = true,
  PickupTradeMoney = true,
  PickupPlayerMoney = true,
  TradeFrame = true,
  MailFrame = true,
  EnumerateFrames = true,
  RunScript = true,
  AcceptTrade = true,
  SetSendMailMoney = true,
  EditMacro = true,
  DevTools_DumpCommand = true,
  hash_SlashCmdList = true,
  RegisterNewSlashCommand = true,
  CreateMacro = true,
  SetBindingMacro = true,
  GuildDisband = true,
  GuildUninvite = true,
  securecall = true,
  DeleteCursorItem = true,
  ChatEdit_SendText = true,
  ChatEdit_ActivateChat = true,
  ChatEdit_ParseText = true,
  ChatEdit_OnEnterPressed = true,
  GetButtonMetatable = true,
  GetEditBoxMetatable = true,
  GetFontStringMetatable = true,
  GetFrameMetatable = true,
}

local blockedTables = {
  SlashCmdList = true,
  SendMailMailButton = true,
  SendMailMoneyGold = true,
  MailFrameTab2 = true,
  DEFAULT_CHAT_FRAME = true,
  ChatFrame1 = true,
  WeakAurasSaved = true,
  WeakAurasOptions = true,
  WeakAurasOptionsSaved = true
}


