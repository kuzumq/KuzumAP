-- start
local self
local _setdb
local _setdb_char
local _kuzumap = {}
local addonName = ...
local _is_ap_item = IsArtifactPowerItem
local UseContainerItem = UseContainerItem
local PutItemInBackpack = PutItemInBackpack
local _link, _itemicon, _bag, _slot, _count
local GetContainerItemID = GetContainerItemID
local PickupContainerItem = PickupContainerItem
local GetContainerNumSlots = GetContainerNumSlots
local BankButtonIDToInvSlotID = BankButtonIDToInvSlotID
local tipscan = CreateFrame("GameTooltip", "TooltipScanArt",nil,"GameTooltipTemplate")
local b_c = false
local b_c_2 = false
local elvui_changed = false
local have_elv = IsAddOnLoaded('ElvUI')
local disable_useap = false

function _kuzumap._ap_to_nlvl()

	local _, _, _, _, totalPower, traitsLearned = C_ArtifactUI.GetEquippedArtifactInfo()
	
	local _, power, powerForNextTrait = MainMenuBar_GetNumArtifactTraitsPurchasableFromXP(traitsLearned, totalPower)
	
	return powerForNextTrait-power, power
	
end

function _kuzumap._ap_lvl(lvl)

	local temp = {100,300,325,350,375,400,425,450,525,625,750,875,1000,
	6840,8830,11280,14400,18620,24000,30600,39520,50880,64800,82500,105280,138650,182780,240870,315520,
	417560,546000,718200,946660,1245840,1635200,1915000,2010000,2110000,2215000,2325000,2440000,2560000,
	2690000,2825000,2965000,3115000,3270000,3435000,3605000,3785000,3975000,4175000,4385000,4605000}
	
	return temp[lvl]

end

function _kuzumap._tolvl(learn,have_ap,lvl)

	local get_lvl = 0
	local nextlvl = lvl + 1
	local tolvl = _kuzumap._ap_lvl(nextlvl) - learn
	
	while have_ap > 0 do

	tolvl = _kuzumap._ap_lvl(nextlvl) - learn
    
		if (learn+have_ap) >= _kuzumap._ap_lvl(nextlvl) then
      
		get_lvl = get_lvl + 1 
		lvl = lvl + 1
		nextlvl = lvl+1
		have_ap = have_ap - tolvl
		learn = 0
      
		else
      
		learn = learn+have_ap
		tolvl = _kuzumap._ap_lvl(nextlvl) - learn
		have_ap = 0
      
		end
	
	end

	return get_lvl, tolvl, learn
	
end

function _kuzumap._getap_f_i(bag, slot)

	tipscan:SetOwner(UIParent, "ANCHOR_NONE")
	
	if bag == -1 then
	
		tipscan:SetInventoryItem("player", BankButtonIDToInvSlotID(slot, nil))
		
	else
	
		tipscan:SetBagItem(bag, slot)
		
	end
	
    tipscan:Show()
	
	local txt = _G['TooltipScanArtTextLeft4']:GetText()
	
	local x = tonumber(string.match(txt, '%d+'))
	
	tipscan:Hide()
	
	return x
	
end


function _kuzumap._grab_sa()

	local num = 0

	for _,i in pairs({-1,5,6,7,8,9,10,11}) do
	
		for j=1,GetContainerNumSlots(i) do 
		
			if _is_ap_item(GetContainerItemID(i,j)) then
			
				PickupContainerItem(i,j)
				PutItemInBackpack()
				num = num + 1
				
			end
			
		end
		
	end
	
	if num < 1 then
	
		print('|cffF29B38  СА Инфо:|r |cff38F2EC У вас нет СА в банке.|r')
	
	else
	
		print('|cffF29B38  СА Инфо:|r |cff38F2EC --> '..num..' СА перемещены в инвентарmь.|r')
		
	end
	
end

function _kuzumap._deposite_sa()

	local num = 0
	
	for _,i in pairs({0,1,2,3,4}) do
	
		for j=1,GetContainerNumSlots(i) do 
		
			if _is_ap_item(GetContainerItemID(i,j)) then
			
				UseContainerItem(i,j)
				num = num + 1
				
			end
			
		end
		
	end
	
	if num < 1 then
	
		print('|cffF29B38  СА Инфо:|r |cff38F2EC У вас нет СА в инвентаре.|r')
	
	else
	
		print('|cffF29B38  СА Инфо:|r |cff38F2EC <-- '..num..' СА перемещены в банк.|r')
		
	end
	
end

function _kuzumap._calculate_result()
	
	local have = 0

	for i=-1, 11 do 
	
		for j=1,GetContainerNumSlots(i) do 
		
			if _is_ap_item(GetContainerItemID(i,j)) then
			
				local count = _kuzumap._getap_f_i(i,j)
				
				have = have + count
				
			end
			
		end
		
	end

	local _, _, _, _, _, lvl = C_ArtifactUI.GetEquippedArtifactInfo()
	
	local tonextlvl,learning = _kuzumap._ap_to_nlvl()
	
	local totalpowerto_nextlvl = _kuzumap._ap_lvl(nextlvl)
	
	local novip_lvlups,novip_tonextneed,novip_learning = _kuzumap._tolvl(learning,have,lvl)
	
	local vip_lvlups,vip_tonextneed,vip_learning = _kuzumap._tolvl(learning,have*1.49,lvl)
	
	local novip_newlvl = lvl + novip_lvlups
	
	local vip_newlvl = lvl + vip_lvlups
	
	if have == 0 then
	
		print('|cffF29B38  СА Инфо:|r |cff38F2ECУ вас нет Силы Артефакта в инвенторе персонажа.|r')
		print('|cffF29B38  ---  |r |cff38F2ECБез|r |cffFD4C8DVIP|r |cff38F2ECдо|r '..(lvl+1)..'|cff38F2EC уровня нужно: |r'..novip_tonextneed)
		print('|cffF29B38  ---  |r |cff38F2ECС|r |cffFD4C8DVIP|r |cff38F2ECдо|r '..(lvl+1)..'|cff38F2EC уровня нужно: |r'..vip_tonextneed)
	
	else
	
		print('|cffF29B38  СА Инфо:|r |cff38F2ECИтого знаний артефакта:|r '..have..' |cff38F2ECС|r |cffFD4C8DVIP:|r '..have*1.49)
		print(' * * *')
		print('|cffF29B38- - - - - - -  |r |cff38F2ECNO|r |cffFD4C8DVIP|r |cffF29B38 - - - - - - -  |r')
		
		if novip_lvlups < 1 then
		
			print('|cffF29B38  ---  |r |cff38F2ECУровень НЕ повысится! До:|r '..(lvl+1)..' |cff38F2ECуровня нужно: |r'..novip_tonextneed)
			
		else
		
			print('|cffF29B38  ---  |r |cff38F2ECУровень повысится до |r'..novip_newlvl..'!')
			print('|cffF29B38  ---  |r |cff38F2ECДля |r'..(novip_newlvl+1)..' |cff38F2ECуровня необходимо еще|r '..novip_tonextneed)
		
		end
		
		print(' * * *')
		print('|cffF29B38- - - - - - -  |r |cffFD4C8DVIP|r |cffF29B38 - - - - - - -  |r')
		
		if vip_lvlups < 1 then 
			
			print('|cffF29B38  ---  |r |cff38F2ECУровень НЕ повысится! До:|r '..(lvl+1)..' |cff38F2ECуровня нужно: |r'..vip_tonextneed)
		
		else
		
			print('|cffF29B38  ---  |r |cff38F2ECУровень повысится до |r'..vip_newlvl..'!')
			print('|cffF29B38  ---  |r |cff38F2ECДля |r'..(vip_newlvl+1)..' |cff38F2ECуровня необходимо еще|r '..vip_tonextneed)
		
		end
		
	end
	
	print(' * * *')
	
end

function _kuzumap._ap_item_player_bag()
	
	local count = 0
	local ubag, uslot = 0, 0
	local itemicon = ''
	local itemlink
	for i=0, 4 do 
	
		for j=1,GetContainerNumSlots(i) do 
			
			local itemid = GetContainerItemID(i,j)
			local icon = GetItemIcon(itemid)
			local link = GetContainerItemLink(i,j)
			if _is_ap_item(itemid) then
				
				count = count + 1
				ubag, uslot = i, j
				itemicon = icon
				itemlink = link
			end
			
		end
		
	end

	return itemlink, itemicon, ubag, uslot, count
	
end

function _kuzumap._help_msg()

	print('* * *')
	print('|cffF29B38  СА Инфо:|r |cff38F2ECДоступные команды:|r')
	print('|cffF29B38  ---  |r |cffFD4C8D/kap total |r|cff38F2EC - подсчет всего СА. |r')
	print('|cffF29B38  ---  |r |cffFD4C8D/kap grab |r|cff38F2EC - забрать СА из банка. |r')
	print('|cffF29B38  ---  |r |cffFD4C8D/kap deposite |r|cff38F2EC - положить СА в банк. |r')
	print('* * *')

end

SLASH_KUZUMAP1 = "/kap"
SlashCmdList["KUZUMAP"] = function(msg, editBox)
	
	if msg == 'help' then
		
		_kuzumap._help_msg()
		return false
		
	end

    if BankFrame:IsShown() then 
	
		if msg == 'deposite' then
		
			_kuzumap._deposite_sa()
			
		elseif msg == 'grab' then
		
			_kuzumap._grab_sa()
			
		elseif msg == 'total' or msg == 'result' then
		
			_kuzumap._calculate_result()
		
		else
			
			print('|cffF29B38  СА Инфо:|r |cff38F2ECТакой команды не существует.|r')
			_kuzumap._help_msg()
			
		end
		
	else
	
		print('|cffF29B38  СА Инфо:|r |cff38F2ECОкно банка персонажа закрыто, работать не буду.|r')
		
	end
	
end

function _kuzumap._bank_buttons_create()
	
	local b_size_x = 112
	local b_size_y = 30
	
	local _b_1 = CreateFrame('Button', 'kuzumap_getAP', BankFrame, 'UIPanelButtonTemplate')
	_b_1:SetSize(b_size_x,b_size_y)
	_b_1:SetPoint('BOTTOMLEFT',20,30)
	_b_1:SetText('Подсчет СА')
	_b_1:SetScript('OnClick', function()

		_kuzumap._calculate_result()
	
	end)
	
	local _b_2 = CreateFrame('Button', 'kuzumap_dropAP', _b_1, 'UIPanelButtonTemplate')
	_b_2:SetSize(b_size_x,b_size_y)
	_b_2:SetPoint('RIGHT',b_size_x+5,0)
	_b_2:SetText('Положить СА')
	_b_2:SetScript('OnClick', function()

		_kuzumap._deposite_sa()
	
	end)
	
	local _b_3 = CreateFrame('Button', 'kuzumap_backAP', _b_2, 'UIPanelButtonTemplate')
	_b_3:SetSize(b_size_x,b_size_y)
	_b_3:SetPoint('RIGHT',b_size_x+5,0)
	_b_3:SetText('Забрать СА') 
	_b_3:SetScript('OnClick', function()

		_kuzumap._grab_sa()
	
	end)
	
	b_c = true 

end

function _kuzumap.ElvUI_bank_buttons_create()
	
	local b_size_x = 50
	local b_size_y = 30
	local x_off = 13
	
	if elvui_changed then return end 
	
	local _b_1 = CreateFrame('Button', 'elvui_kuzumap_getAP', _G.ElvUI_BankContainerFrame)
	_b_1:SetSize(b_size_x,b_size_y)
	_b_1:SetPoint('TOPLEFT',5,0)
	_b_1:SetNormalFontObject("GameFontNormalSmall")
	_b_1:SetText('[Подсчет СА]')
	_b_1:Show()
	_b_1:SetScript('OnClick', function()

		_kuzumap._calculate_result()
	
	end)
	
	local _b_2 = CreateFrame('Button', 'elvui_kuzumap_dropAP', _b_1)
	_b_2:SetSize(b_size_x,b_size_y)
	_b_2:SetPoint('RIGHT',b_size_x+x_off,0)
	_b_2:SetNormalFontObject("GameFontNormalSmall")
	_b_2:SetText('[Положить СА]')
	_b_2:SetScript('OnClick', function()

		_kuzumap._deposite_sa()
	
	end)
	
	local _b_3 = CreateFrame('Button', 'elvui_kuzumap_backAP', _b_2)
	_b_3:SetSize(b_size_x,b_size_y)
	_b_3:SetPoint('RIGHT',b_size_x+x_off,0)
	_b_3:SetNormalFontObject("GameFontNormalSmall")
	_b_3:SetText('[Забрать СА]') 
	_b_3:SetScript('OnClick', function()

		_kuzumap._grab_sa()
	
	end)
	
	elvui_changed = true
	
end

function _kuzumap.useap_button_upd()
	
	_link, _itemicon, _bag, _slot, _count = _kuzumap._ap_item_player_bag()
	
	if InCombatLockdown() or UnitHasVehicleUI("player") then
	
		return
		
	end
	
	if not kuzumap_useAP then return false end
	
	if not disable_useap and _link then
	
		kuzumap_useAP:Show()
		kuzumap_useAP.text_center:SetText(_count)
		kuzumap_useAP.icon:SetTexture(_itemicon)
		kuzumap_useAP:SetAttribute("type", "item")
		kuzumap_useAP:SetAttribute("item", _bag.." ".._slot)
	
		if kuzumap_useAP:IsMouseOver() then
			GameTooltip:SetHyperlink(_link)
		end
	
		local start, duration, enable = GetContainerItemCooldown(_bag, _slot)
		if duration > 0 then
			kuzumap_useAP.cooldown:SetCooldown(start, duration)
		end
	else

		kuzumap_useAP:Hide()	
			
	end
	
end

function _kuzumap._useap_button_create()

	local _ub = CreateFrame('Button', 'kuzumap_useAP', UIParent, "ActionButtonTemplate, SecureActionButtonTemplate")
	
	_ub:SetSize(45,45)
	_ub:SetPoint(_setdb.position.point, UIParent, _setdb.position.relativePoint, _setdb.position.x, _setdb.position.y)
	_ub:RegisterEvent("BAG_UPDATE_DELAYED")
	_ub:RegisterEvent("PLAYER_REGEN_DISABLED")
	_ub:RegisterEvent("PLAYER_REGEN_ENABLED")
	_ub:RegisterEvent("PET_BATTLE_OPENING_START")
	_ub:RegisterEvent("PET_BATTLE_CLOSE")
	_ub:RegisterEvent("UNIT_ENTERED_VEHICLE")
	_ub:RegisterEvent("UNIT_EXITED_VEHICLE")
	_ub:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
	_ub:RegisterEvent("BANKFRAME_OPENED")
	_ub:RegisterEvent("BANKFRAME_CLOSED")
	
	_ub.text_top = _ub:CreateFontString()
	_ub.text_top:SetPoint("CENTER",0,27)
	_ub.text_top:SetSize(200, 50)
	_ub.text_top:SetFont("Fonts\\MORPHEUS.ttf", 13, "OUTLINE")
	
	_ub.text_center = _ub:CreateFontString()
	_ub.text_center:SetPoint("CENTER",0,-1)
	_ub.text_center:SetSize(200, 50)
	_ub.text_center:SetTextColor(0.1, 1, 0.1)
	_ub.text_center:SetFont("Fonts\\MORPHEUS.ttf", 26, "OUTLINE")
	
	_ub.NormalTexture:SetTexture(nil)
	_ub:EnableMouse(true)
	_ub:RegisterForDrag("LeftButton")
	_ub:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	_ub:SetMovable(true)

	_ub:SetScript("OnHide", function(self)
		self:SetAttribute("type", nil)
		self:SetAttribute("item", nil)
	end)
	
	_ub:SetScript("OnEnter", function(self)
		if _link then
			GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
			GameTooltip:SetHyperlink(_link)
		end
	end)
	
	_ub:SetScript("OnLeave", function(self)
		GameTooltip_Hide()
	end)
	
	_ub:SetScript("OnDragStart", function(self)
		if self:IsMovable() then
			self:StartMoving()
		end
	end)
	_ub:SetScript("OnDragStop", function(self)
		print(self:GetPoint())
		self:StopMovingOrSizing()
		_setdb.position.point, _, _setdb.position.relativePoint, _setdb.position.x, _setdb.position.y = self:GetPoint()
	end)
	
	_kuzumap.useap_button_upd()
	
	b_c_2 = true 
	
end

-- chat filter
	-- Идея взаимствована у Авгена

function _kuzumap._mythKeyChat_Info(link)

	tipscan:SetOwner(UIParent, "ANCHOR_NONE")
	
	tipscan:SetHyperlink(link)
	
    tipscan:Show()
	
	local name = _G['TooltipScanArtTextLeft1']:GetText()
	
	if name == 'Получение сведений о предмете' then return false end
	
	local txtlvl = _G['TooltipScanArtTextLeft2']:GetText()
	local lvl = txtlvl:match('(%d+)')
	
	tipscan:Hide()
	
	return name, lvl
	
end

function _kuzumap._chatFilter(frame, event, message, ...)

	
    if message:match("Hitem:138019") then
		
		local link = message:match("|cffa335ee|Hitem:138019.*|h|r")
		
		local name, lvl = _kuzumap._mythKeyChat_Info(link)
			
		if name and lvl then
			
			local newmessage = message:gsub("Mythic Keystone", name..' +'..lvl)
			return false, newmessage, ...
			
		end
		
    end
	
	-- Who say ME?:
	
	if message:match(UnitName('player')) then

		FlashClientIcon()
		
	end
	
	return false
	
end

local chatEvents = {
	"CHAT_MSG_SAY",
	"CHAT_MSG_YELL",
	"CHAT_MSG_CHANNEL",
	"CHAT_MSG_TEXT_EMOTE",
	"CHAT_MSG_WHISPER",
	"CHAT_MSG_WHISPER_INFORM",
	"CHAT_MSG_BN_WHISPER",
	"CHAT_MSG_BN_WHISPER_INFORM",
	"CHAT_MSG_BN_CONVERSATION",
	"CHAT_MSG_GUILD",
	"CHAT_MSG_OFFICER",
	"CHAT_MSG_PARTY",
	"CHAT_MSG_PARTY_LEADER",
	"CHAT_MSG_RAID",
	"CHAT_MSG_RAID_LEADER",
	"CHAT_MSG_INSTANCE_CHAT",
	"CHAT_MSG_INSTANCE_CHAT_LEADER",
}

-- chat Filter
for _, v in pairs(chatEvents) do

	ChatFrame_AddMessageEventFilter(v, _kuzumap._chatFilter)
	
end

-- Merchant mod
function _kuzumap._merchant_buy(name, num, itemcount)
	
	local itemcount = tonumber(itemcount)
	local num = tonumber(num)-1
	local total = 0
	
	while total < num do
	
		for i=1,100 do 
	
			if name==GetMerchantItemInfo(i) then 
		
				BuyMerchantItem(i, itemcount)
				total = total + 1
				break
				
			end
		
		end 
		
	end
	
end

function _kuzumap._merchantmod_ed()

	local itemcount

	local _e_b = CreateFrame('EditBox', 'kuzumap_Popup', StaticPopup1, "InputBoxTemplate")
	_e_b:SetWidth(20)
	_e_b:SetHeight(20)
	_e_b:SetPoint('CENTER',30,20)
	_e_b:SetMaxLetters(2)
	_e_b:SetNumeric(true)
	_e_b:SetAutoFocus(false)
	_e_b:SetCursorPosition(0)
	_e_b:SetText("1")
	_e_b:SetScript("OnShow",function(self)

		self:SetText("1")
		itemcount = tonumber(StaticPopup1ItemFrameCount:GetText()) or 1
	
	end)
	
	_e_b:SetScript("OnChar",function(self,userInput,...)
		
		--if userInput == '0' then self:SetText('1') end
		
		local Text = self:GetText() or userInput
		
		self:SetText(Text)
		
		if tonumber(self:GetText()) < 1 then
		
			self.text_right:SetText(' * 1 = 1')
		
		else
		
			self.text_right:SetText(' * '..itemcount..' = '..(itemcount*self:GetText()))
		
		end
		
	end)
	
	_e_b:SetScript("OnHide",function(self)

		-- clean
	
	end)
	
	_e_b:SetScript("OnKeyDown",function(self, key)
		
		if key == 'BACKSPACE' then
			
			if self:GetText() == '0' then self:SetText('1') end
			self.text_right:SetText(' * '..itemcount..' = '..itemcount)
			
		end
		
	end)
	
	_e_b.text_left = _e_b:CreateFontString()
	_e_b.text_left:SetPoint("CENTER", _e_b, -65, 0)
	_e_b.text_left:SetSize(150, 20)
	_e_b.text_left:SetFont("Fonts\\ARIALN.TTF", 13)
	_e_b.text_left:SetText('Сколько обменять: ')
	
	_e_b.text_right = _e_b:CreateFontString()
	_e_b.text_right:SetPoint("CENTER", _e_b, 40, 0)
	_e_b.text_right:SetSize(100, 20)
	_e_b.text_right:SetFont("Fonts\\ARIALN.TTF", 13)
	
	_e_b:Hide()
	
end

--hooks

StaticPopup1:HookScript("OnShow", function(self)

	local sttext = StaticPopup1Text:GetText()
	
	if sttext:match("Hitem:124124") then
	
		local itemcount = tonumber(StaticPopup1ItemFrameCount:GetText()) or 1
	
		kuzumap_Popup:Show()
		kuzumap_Popup.text_right:SetText(' * '..itemcount..' = '..itemcount)
		
	end

end)

StaticPopup1:HookScript("OnHide", function(self)

	kuzumap_Popup:Hide()

end)

StaticPopup1Button1:HookScript("OnClick", function(self)

	local sttext = StaticPopup1Text:GetText()
	
	
	if sttext:match("Hitem:124124") then
	
		local itemcount = tonumber(StaticPopup1ItemFrameCount:GetText()) or 1
		local setitemcount = kuzumap_Popup:GetNumber()
		local itemname = StaticPopup1ItemFrameText:GetText()

		if setitemcount > 1 then
	
			_kuzumap._merchant_buy(itemname, setitemcount, itemcount)
		
		end
	
	end
	
end)

ReagentBankFrame:HookScript("OnShow", function(self)

    kuzumap_getAP:Hide()
	
end)

ReagentBankFrame:HookScript("OnHide", function(self)

    kuzumap_getAP:Show()
	
end)

function _kuzumap._load()
	
	if KuzumAP_UserDB == nil then KuzumAP_UserDB = {} end
	_setdb = KuzumAP_UserDB

	if KuzumAP_UserCharacterDB == nil then KuzumAP_UserCharacterDB = {} end
	_setdb_char = KuzumAP_UserCharacterDB

	if _setdb.position == nil then _setdb.position = {} end
	if _setdb.position.point == nil then _setdb.position.point = "CENTER" end
	if _setdb.position.relativePoint == nil then _setdb.position.relativePoint = _setdb.position.point or "CENTER" end
	if _setdb.position.x == nil then 
		_setdb.position.x, _setdb.position.y = 0, -150 
	end
	
end

-- load
local _load = CreateFrame("Frame")
_load:Hide()
_load:RegisterEvent("ADDON_LOADED")
_load:RegisterEvent("PLAYER_ENTERING_WORLD")
_load:RegisterEvent("BAG_UPDATE_DELAYED")
_load:RegisterEvent("PLAYER_REGEN_DISABLED")
_load:RegisterEvent("PLAYER_REGEN_ENABLED")
_load:RegisterEvent("PET_BATTLE_OPENING_START")
_load:RegisterEvent("PET_BATTLE_CLOSE")
_load:RegisterEvent("UNIT_ENTERED_VEHICLE")
_load:RegisterEvent("UNIT_EXITED_VEHICLE")
_load:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
_load:RegisterEvent("BANKFRAME_OPENED")
_load:RegisterEvent("BANKFRAME_CLOSED")
_load:SetScript("OnEvent", function(self, event, ...)

	if event == "ADDON_LOADED" and (...) == addonName then
		
		_kuzumap._load()
		
	elseif event == "PLAYER_ENTERING_WORLD" and (not b_c_2) and (not b_c) then
	
		_kuzumap._bank_buttons_create()
		_kuzumap._useap_button_create()
		_kuzumap._merchantmod_ed()
		
	end
	
	-- recount mod
	if event == "ADDON_LOADED" and (...) == 'Recount' then
		
		_G.Recount.ResetData = _G.Recount.ResetDataUnsafe
		
	end
	
	if event == "BAG_UPDATE_DELAYED" or event == "PLAYER_SPECIALIZATION_CHANGED" then
	
			_kuzumap.useap_button_upd()
			
		elseif event == "PLAYER_REGEN_DISABLED" or event == "PET_BATTLE_OPENING_START" or (event == "UNIT_ENTERED_VEHICLE" and ... == "player" and not InCombatLockdown()) then
		
			_kuzumap.useap_button_upd()
			_load:UnregisterEvent("BAG_UPDATE_DELAYED")
			
		elseif event == "PLAYER_REGEN_ENABLED" or event == "PET_BATTLE_CLOSE" or (event == "UNIT_EXITED_VEHICLE" and ... == "player") then
		
			_kuzumap.useap_button_upd()
			_load:RegisterEvent("BAG_UPDATE_DELAYED")
			
		elseif event == "BANKFRAME_OPENED" then
			
			disable_useap = true
			
			-- ElvUI

			if have_elv then
				
				C_Timer.After(0.1, function() _kuzumap.ElvUI_bank_buttons_create() end)
					
			end
			
			_kuzumap.useap_button_upd()
			
		elseif event == "BANKFRAME_CLOSED" then
			
			disable_useap = false
			_kuzumap.useap_button_upd()
			
	end
	
end)
