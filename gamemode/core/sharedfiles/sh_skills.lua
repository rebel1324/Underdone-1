local Player = FindMetaTable("Player")
local intSkillPointsPerLevel = 1

function Player:SetSkill(strSkill, intAmount, load)
	local tblSkillTable = SkillTable(strSkill)
	if tblSkillTable then
		intAmount = intAmount or 0
		intAmount = math.Clamp(intAmount, 0, tblSkillTable.Levels)
		self.Data.Skills = self.Data.Skills or {}
		local intOldSkill = self.Data.Skills[strSkill] or 0
		self.Data.Skills[strSkill] = intAmount
		if SERVER then
			if tblSkillTable.OnSet then
				tblSkillTable:OnSet(self, intAmount, intOldSkill, load)
			end
			SendUsrMsg("UD_UpdateSkills", self, {strSkill, intAmount})
		end
		if CLIENT then
			if GAMEMODE.MainMenu then GAMEMODE.MainMenu.Character:LoadSkills() end
			if GAMEMODE.MainMenu then GAMEMODE.MainMenu.Inventory:LoadInventory() end
		end
	end
end

function Player:GetSkill(strSkill)
	self.Data.Skills = self.Data.Skills or {}
	return self.Data.Skills[strSkill] or 0
end

function Player:CanHaveSkill(strSkill)
	local tblSkillTable = SkillTable(strSkill)
	local SkillNeeded = tblSkillTable.Requirements
	if self:GetSkill( strSkill ) == tblSkillTable.Levels then return false end
	
	if SkillNeeded then
		local curneed = SkillNeeded[ self:GetSkill( strSkill ) ]
		--print( 'Need' )
		if curneed then
		--	print( 'Exist' )
			for k, v in pairs ( curneed.Skills ) do
			--	print( k .. ' ' .. v )
				if self:GetSkill( k ) < v then return false end
			end
			if curneed.Level then
				if curneed.Level > 0 then
					if self:GetLevel() < curneed.Level then
						return false
					end
				end
			end
		else
			--print( 'Not Exist' )
			return false
		end
	end
	
	if !tblSkillTable then return false end
	return true
end

function Player:HasSkill(strSkill)
	if !self.Data.Skills then return end
	for skill,skilllevel in pairs(self.Data.Skills) do
		if skilllevel > 0 then
			if SkillTable(skill).Name == strSkill then
				return true
			end
		end
	end
end

function Player:GetDeservedSkillPoints()
	local intSkillPoints = self:GetLevel() * intSkillPointsPerLevel
	for strSkill, intAmount in pairs(self.Data.Skills or {}) do
		intSkillPoints = math.Clamp(intSkillPoints - intAmount, 0, self:GetLevel())
	end
	return intSkillPoints
end

function Player:CallSkillHook(strHook, ...)
	local tblReturnTable = {...}
	for strSkill, intSkillLevel in pairs(self.Data.Skills or {}) do
		local tblSkillTable = SkillTable(strSkill)
		if self:GetSkill(strSkill) > 0 && tblSkillTable.Hooks && tblSkillTable.Hooks[strHook] then
			tblReturnTable = {tblSkillTable.Hooks[strHook](self, self:GetSkill(strSkill), table.Split(tblReturnTable))}
		end
	end
	return table.Split(tblReturnTable)
end

if SERVER then
	hook.Add("UD_Hook_PlayerLevelUp", "PlayerLevelUp_SkillPoints", function(plyPlayer, intLevels)
		plyPlayer:SetNWInt("SkillPoints", plyPlayer:GetNWInt("SkillPoints") + (intSkillPointsPerLevel * intLevels))
	end)
	
	function Player:BuySkill(strSkill, intAmount, load)
		local tblSkillTable = SkillTable(strSkill)
		if !tblSkillTable then return false end
		intAmount = math.Clamp(intAmount or 1, 0, tblSkillTable.Levels - self:GetSkill(strSkill))
		intAmount = math.Clamp(intAmount or 1, 0, self:GetNWInt("SkillPoints"))
		if intAmount <= 0 then return false end
		if self:CanHaveSkill(strSkill) then
			self:SetNWInt("SkillPoints", self:GetNWInt("SkillPoints") - intAmount)
			self:SetSkill(strSkill, self:GetSkill(strSkill) + intAmount, load)
			self:SaveGame()
			return true
		end
	end
	concommand.Add("UD_BuySkill", function(ply, command, args) ply:BuySkill(args[1]) end)
end
if CLIENT then
	usermessage.Hook("UD_UpdateSkills", function(usrMsg)
		LocalPlayer():SetSkill(usrMsg:ReadString(), usrMsg:ReadLong())
	end)
end