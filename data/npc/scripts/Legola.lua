local keywordHandler = KeywordHandler:new()
local npcHandler = NpcHandler:new(keywordHandler)
NpcSystem.parseParameters(npcHandler)

function onCreatureAppear(cid)			npcHandler:onCreatureAppear(cid)			end
function onCreatureDisappear(cid)		npcHandler:onCreatureDisappear(cid)			end
function onCreatureSay(cid, type, msg)		npcHandler:onCreatureSay(cid, type, msg)		end
function onThink()		npcHandler:onThink()		end

local voices = { {text = 'Teaching paladin spells! Just come to me!'} }
npcHandler:addModule(VoiceModule:new(voices))

-- Sniper Gloves
keywordHandler:addKeyword({'sniper gloves'}, StdModule.say, {npcHandler = npcHandler, text = 'We are always looking for sniper gloves. They are supposed to raise accuracy. If you find a pair, bring them here. Maybe I can offer you a nice trade.'}, function(player) return player:getItemCount(5875) == 0 end)

local function addGloveKeyword(text, condition, action)
	local gloveKeyword = keywordHandler:addKeyword({'sniper gloves'}, StdModule.say, {npcHandler = npcHandler, text = text[1]}, condition)
		gloveKeyword:addChildKeyword({'yes'}, StdModule.say, {npcHandler = npcHandler, text = text[2], reset = true}, function(player) return player:getItemCount(5875) == 0 end)
		gloveKeyword:addChildKeyword({'yes'}, StdModule.say, {npcHandler = npcHandler, text = text[3], reset = true}, nil, action)
		gloveKeyword:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, text = text[2], reset = true})
end

-- Free Account
addGloveKeyword({
		'You found sniper gloves?! Incredible! I would love to grant you the sniper gloves accessory, but I can only do that for premium warriors. However, I would pay you 2000 gold pieces for them. How about it?',
		'Maybe another time.',
		'Alright! Here is your money, thank you very much.'
	}, function(player) return not player:isPremium() end, function(player) player:removeItem(5875, 1) player:addMoney(2000) end
)

-- Premium account with addon
addGloveKeyword({
		'Did you find sniper gloves AGAIN?! Incredible! I cannot grant you other accessories, but would you like to sell them to me for 2000 gold pieces?',
		'Maybe another time.',
		'Alright! Here is your money, thank you very much.'
	}, function(player) return player:getStorageValue(Storage.OutfitQuest.Hunter.AddonGlove) == 1 end, function(player) player:removeItem(5875, 1) player:addMoney(2000) end
)

-- If you don't have the addon
addGloveKeyword({
		'You found sniper gloves?! Incredible! Listen, if you give them to me, I will grant you the right to wear the sniper gloves accessory. How about it?',
		'No problem, maybe another time.',
		'Great! I hereby grant you the right to wear the sniper gloves as an accessory. Congratulations!'
	}, function(player) return player:getStorageValue(Storage.OutfitQuest.Hunter.AddonGlove) == -1 end, function(player) player:removeItem(5875, 1) player:setStorageValue(Storage.OutfitQuest.Hunter.AddonGlove, 1) player:addOutfitAddon(129, 2) player:addOutfitAddon(137, 1) player:getPosition():sendMagicEffect(CONST_ME_MAGIC_BLUE) end
)

npcHandler:addModule(FocusModule:new())


local PremiumSpells = false
local AllSpells = false
-- 1,5 Sorcerer
-- 2,6 Druid
-- 3,7 Paladin
-- 4,8 Knight
local spells = {
	[5706] = { buy = 80, spell = "Find Person", name = "Level 008: Find Person", vocations = {1,2,3,4,5,6,7,8}, level = 8, premium = 0},
	[8704] = { buy = 170, spell = "Light Healing", name = "Level 008: Light Healing", vocations = {1,2,3,5,6,7}, level = 8, premium = 0},
	[7618] = { buy = 300, spell = "Wound Cleansing", name = "Level 008: Wound Cleansing", vocations = {4,8}, level = 8, premium = 0},
	[2120] = { buy = 200, spell = "Magic Rope", name = "Level 009: Magic Rope", vocations = {1,2,3,4,5,6,7,8}, level = 9, premium = 1},
	[10092] = { buy = 150, spell = "Cure Poison", name = "Level 010: Cure Poison", vocations = {1,2,3,4,5,6,7,8}, level = 10, premium = 0},
	[2287] = { buy = 800, spell = "Energy Strike", name = "Level 012: Energy Strike", vocations = {1,2,5,6}, level = 12, premium = 1},
	[1386] = { buy = 500, spell = "Levitate", name = "Level 012: Levitate", vocations = {1,2,3,4,5,6,7,8}, level = 12, premium = 1},
	[2051] = { buy = 500, spell = "Great Light", name = "Level 013: Great Light", vocations = {1,2,3,4,5,6,7,8}, level = 13, premium = 0},
	[2544] = { buy = 450, spell = "Conjure Arrow", name = "Level 013: Conjure Arrow", vocations = {3,7}, level = 13, premium = 0},
	[1490] = { buy = 800, spell = "Terra Strike", name = "Level 013: Terra Strike", vocations = {1,2,5,6}, level = 13, premium = 1},
	[2169] = { buy = 600, spell = "Haste", name = "Level 014: Haste", vocations = {1,2,3,4,5,6,7,8}, level = 14, premium = 1},
	[1489] = { buy = 800, spell = "Flame Strike", name = "Level 014: Flame Strike", vocations = {1,2,5,6}, level = 14, premium = 1},
	[2671] = { buy = 300, spell = "Food", name = "Level 014: Food", vocations = {2,6}, level = 14, premium = 0},
	[2523] = { buy = 450, spell = "Magic Shield", name = "Level 014: Magic Shield", vocations = {1,2,5,6}, level = 14, premium = 0},
	[6683] = { buy = 800, spell = "Ice Strike", name = "Level 015: Ice Strike", vocations = {1,2,5,6}, level = 15, premium = 1},
	[2383] = { buy = 1000, spell = "Brutal Strike", name = "Level 016: Brutal Strike", vocations = {4,8}, level = 16, premium = 1},
	[2545] = { buy = 700, spell = "Conjure Poisoned Arrow", name = "Level 016: Conjure Poisoned Arrow", vocations = {3,7}, level = 16, premium = 0},
	[6300] = { buy = 800, spell = "Death Strike", name = "Level 016: Death Strike", vocations = {1,5}, level = 16, premium = 1},
	[2376] = { buy = 800, spell = "Physical Strike", name = "Level 016: Physical Strike", vocations = {2,6}, level = 16, premium = 1},
	[2543] = { buy = 750, spell = "Conjure Bolt", name = "Level 017: Conjure Bolt", vocations = {3,7}, level = 17, premium = 1},
	[7488] = { buy = 800, spell = "Heal Friend", name = "Level 018: Heal Friend", vocations = {2,6}, level = 18, premium = 1},
	[1487] = { buy = 850, spell = "Fire Wave", name = "Level 018: Fire Wave", vocations = {1,5}, level = 18, premium = 0},
	[6684] = { buy = 850, spell = "Ice Wave", name = "Level 018: Ice Wave", vocations = {2,6}, level = 18, premium = 0},
	[5787] = { buy = 2000, spell = "Challenge", name = "Level 020: Challenge", vocations = {8}, level = 20, premium = 1},
	[2265] = { buy = 350, spell = "Intense Healing", name = "Level 020: Intense Healing", vocations = {1,2,3,5,6,7}, level = 20, premium = 0},
	[2206] = { buy = 1300, spell = "Strong Haste", name = "Level 020: Strong Haste", vocations = {1,2,5,6}, level = 20, premium = 1},
	[1504] = { buy = 1000, spell = "Cure Electrification", name = "Level 022: Cure Electrification", vocations = {2,6}, level = 22, premium = 1},
	[2389] = { buy = 1100, spell = "Ethereal Spear", name = "Level 023: Ethereal Spear", vocations = {3,7}, level = 23, premium = 1},
	[5024] = { buy = 1000, spell = "Energy Beam", name = "Level 023: Energy Beam", vocations = {1,5}, level = 23, premium = 0},
	[13929] = { buy = 1000, spell = "Creature Illusion", name = "Level 023: Creature Illusion", vocations = {1,2,5,6}, level = 23, premium = 0},
	[7364] = { buy = 800, spell = "Conjure Sniper Arrow", name = "Level 024: Conjure Sniper Arrow", vocations = {3,7}, level = 24, premium = 1},
	[2546] = { buy = 1000, spell = "Conjure Explosive Arrow", name = "Level 025: Conjure Explosvie Arrow", vocations = {3,7}, level = 25, premium = 0},
	[2195] = { buy = 1300, spell = "Charge", name = "Level 025: Charge", vocations = {4,8}, level = 25, premium = 1},
	[9007] = { buy = 2000, spell = "Summon Creature", name = "Level 025: Summon Creature", vocations = {1,2,5,6}, level = 25, premium = 0},
	[2202] = { buy = 1600, spell = "Cancel Invisibility", name = "Level 026: Cancel Invvisibility", vocations = {3,7}, level = 26, premium = 1},
	[2308] = { buy = 1500, spell = "Ignite", name = "Level 026: Ignite", vocations = {1,5}, level = 26, premium = 0},
	[2163] = { buy = 1600, spell = "Ultimate Light", name = "Level 026: Ultimate Light", vocations = {1,2,5,6}, level = 26, premium = 1},
	[13883] = { buy = 1500, spell = "Whirlwind Throw", name = "Level 028: Whirlwind Throw", vocations = {4,8}, level = 28, premium = 1},
	[2315] = { buy = 1800, spell = "Great Energy Beam", name = "Level 029: Great Energy Beam", vocations = {1,5}, level = 29, premium = 0},
	[8474] = { buy = 2000, spell = "Cure Burning", name = "Level 030: Cure Burning", vocations = {2,6}, level = 30, premium = 1},
	[2273] = { buy = 1000, spell = "Ultimate Healing", name = "Level 030: Ultimate Healing", vocations = {1,2,5,6}, level = 30, premium = 0},
	[18492] = { buy = 4000, spell = "Enchant Party", name = "Level 032: Enchant Party", vocations = {1,5}, level = 32, premium = 1},
	[18491] = { buy = 4000, spell = "Protect Party", name = "Level 032: Protect Party", vocations = {3,7}, level = 32, premium = 1},
	[18489] = { buy = 4000, spell = "Heal Party", name = "Level 032: Heal Party", vocations = {2,6}, level = 32, premium = 1},
	[18490] = { buy = 4000, spell = "Train Party", name = "Level 032: Train Party", vocations = {4,8}, level = 32, premium = 1},
	[1505] = { buy = 1500, spell = "Groundshaker", name = "Level 033: Groundshaker", vocations = {4,8}, level = 33, premium = 1},
	[7363] = { buy = 850, spell = "Conjure Piercing Bolt", name = "Level 033: Conjure Piercing Bolt", vocations = {3,7}, level = 33, premium = 1},
	[1491] = { buy = 2500, spell = "Electrify", name = "Level 034: Electrify", vocations = {1,5}, level = 34, premium = 1},
	[7588] = { buy = 3000, spell = "Divine Healing", name = "Level 035: Divine Healing", vocations = {3,7}, level = 35, premium = 0},
	[2393] = { buy = 2500, spell = "Berserk", name = "Level 035: Berserk", vocations = {4,8}, level = 35, premium = 1},
	[2165] = { buy = 2000, spell = "Invisibility", name = "Level 035: Invisibility", vocations = {1,2,5,6}, level = 35, premium = 0},
	[8919] = { buy = 2200, spell = "Mass Healing", name = "Level 036: Mass Healing", vocations = {2,6}, level = 36, premium = 1},
	[2279] = { buy = 2500, spell = "Energy Wave", name = "Level 038: Energy Wave", vocations = {1,5}, level = 38, premium = 0},
	[2289] = { buy = 2500, spell = "Terra Wave", name = "Level 038: Terra Wave", vocations = {2,6}, level = 38, premium = 0},
	[2295] = { buy = 1800, spell = "Divine Missile", name = "Level 040: Divine Missile", vocations = {3,7}, level = 40, premium = 1},
	[1903] = { buy = 2500, spell = "Inflict Wound", name = "Level 040: Inflict Wound", vocations = {4,8}, level = 40, premium = 1},
	[671] = { buy = 7500, spell = "Strong Ice Wave", name = "Level 040: Strong Ice Wave", vocations = {2,6}, level = 40, premium = 1},
	[2433] = { buy = 2000, spell = "Enchant Staff", name = "Level 041: Enchant Staff", vocations = {5}, level = 41, premium = 1},
	[7367] = { buy = 2000, spell = "Enchant Spear", name = "Level 045: Enchant Spear", vocations = {3,7}, level = 45, premium = 1},
	[6558] = { buy = 2500, spell = "Cure Bleeding", name = "Level 045: Cure Bleeding", vocations = {2,4,6,8}, level = 45, premium = 1},
	[2298] = { buy = 3000, spell = "Divine Caldera", name = "Level 050: Divine Caldera", vocations = {3,7}, level = 50, premium = 1},
	[1496] = { buy = 6000, spell = "Envenom", name = "Level 050: Envenom", vocations = {2,6}, level = 50, premium = 1},
	[6132] = { buy = 4000, spell = "Recovery", name = "Level 050: Recovery", vocations = {3,4,7,8}, level = 50, premium = 1},
	[8920] = { buy = 6000, spell = "Rage of the Skies", name = "Level 055: Rage of the Skies", vocations = {1,5}, level = 55, premium = 1},
	[2522] = { buy = 6000, spell = "Protector", name = "Level 055: Protector", vocations = {4,8}, level = 55, premium = 1},
	[2309] = { buy = 5000, spell = "Lightning", name = "Level 055: Lightning", vocations = {1,5}, level = 55, premium = 1},
	[11303] = { buy = 6000, spell = "Swift Foot", name = "Level 055: Swift Foot", vocations = {3,7}, level = 55, premium = 1},
	[4208] = { buy = 6000, spell = "Wrath of Nature", name = "Level 055: Wrath of Nature", vocations = {2,6}, level = 55, premium = 1},
	[2547] = { buy = 2000, spell = "Conjure Power Bolt", name = "Level 059: Conjure Power Bolt", vocations = {7}, level = 59, premium = 1},
	[9110] = { buy = 8000, spell = "Eternal Winter", name = "Level 060: Eternal Winter", vocations = {2,6}, level = 60, premium = 1},
	[7416] = { buy = 8000, spell = "Blood Rage", name = "Level 060: Blood Rage", vocations = {4,8}, level = 60, premium = 1},
	[2187] = { buy = 8000, spell = "Hell's Core", name = "Level 060: Hell's Core", vocations = {1,5}, level = 60, premium = 1},
	[7591] = { buy = 8000, spell = "Salvation", name = "Level 060: Salvation", vocations = {3,7}, level = 60, premium = 1},
	[5777] = { buy = 8000, spell = "Sharpshooter", name = "Level 060: Sharpshooter", vocations = {3,7}, level = 60, premium = 1},
	[8930] = { buy = 4000, spell = "Front Sweep", name = "Level 070: Front Sweep", vocations = {4,8}, level = 70, premium = 1},
	[2300] = { buy = 7500, spell = "Holy Flash", name = "Level 070: Holy Flash", vocations = {3,7}, level = 70, premium = 1},
	[8062] = { buy = 6000, spell = "Strong Terra Strike", name = "Level 070: Strong Terra Strike", vocations = {2,6}, level = 70, premium = 1},
	[1492] = { buy = 6000, spell = "Strong Flame Strike", name = "Level 070: Strong Flame Strike", vocations = {1,2,5,6}, level = 70, premium = 1},
	[2268] = { buy = 6000, spell = "Curse", name = "Level 075: Curse", vocations = {1,5}, level = 75, premium = 1},
	[6301] = { buy = 6000, spell = "Cure Curse", name = "Level 080: Cure Curse", vocations = {3,7}, level = 80, premium = 1},
	[8473] = { buy = 6000, spell = "Intense Wound Cleansing", name = "Level 080: Intense Wound Cleansing", vocations = {4,8}, level = 80, premium = 1},
	[6686] = { buy = 6000, spell = "Strong Ice Strike", name = "Level 080: Strong Ice Strike", vocations = {2,6}, level = 80, premium = 1},
	[2311] = { buy = 7500, spell = "Strong Energy Strike", name = "Level 080: Strong Energy Strike", vocations = {1,5}, level = 80, premium = 1},
	[2421] = { buy = 7500, spell = "Fierce Berserk", name = "Level 090: Fierce Berserk", vocations = {4,8}, level = 90, premium = 1},
	[7378] = { buy = 10000, spell = "Strong Ethereal Spear", name = "Level 090: Strong Ethereal Spear", vocations = {3,7}, level = 90, premium = 1},
	[7465] = { buy = 15000, spell = "Ultimate Flame Strike", name = "Level 090: Ultimate Flame Strike", vocations = {1,5}, level = 90, premium = 1},
	[12334] = { buy = 15000, spell = "Ultimate Terra Strike", name = "Level 090: Ultimate Terra Strike", vocations = {2,6}, level = 90, premium = 1},
	[2640] = { buy = 10000, spell = "Intense Recovery", name = "Level 100: Intense Recovery", vocations = {3,4,7,8}, level = 100, premium = 1},
	[10547] = { buy = 15000, spell = "Ultimate Energy Strike", name = "Level 100: Ultimate Energy Strike", vocations = {1,5}, level = 100, premium = 1},
	[2271] = { buy = 15000, spell = "Ultimate Ice Strike", name = "Level 100: Ultimate Ice Strike", vocations = {2,6}, level = 100, premium = 1},
	[2390] = { buy = 20000, spell = "Annihilation", name = "Level 110: Annihilator", vocations = {4,8}, level = 110, premium = 1},
}

function tradeSpellCallback(cid, type, msg)
	if not npcHandler:isFocused(cid) then
		return false
	end

	local shopWindow = {}
	local player = Player(cid)
	local talkUser = NPCHANDLER_CONVbehavior == CONVERSATION_DEFAULT and 0 or cid

	local function onBuy(cid, item, subType, amount, ignoreCap, inBackpacks)
		selfSay("You have choosen the spell: " .. spells[item].spell .. " which costs " .. spells[item].buy .. " gold.", cid)

		local player = Player(cid)
		if player:hasLearnedSpell(spells[item].spell) then
			return selfSay("You already know this spell.", cid)
		end

		if player:getLevel() < spells[item].level then
			return selfSay("You need to obtain a level of " .. spells[item].level .. " or higher to be able to learn this spell.", cid)
		end

		if not isInArray(spells[item].vocations, player:getVocation():getId()) then
			return selfSay("This spell is not for your vocation.", cid)
		end

		if PremiumSpells and (spells[item].premium == 1) and not player:isPremium() then
			return selfSay("You need to be premium in order to obtain this spell.", cid)
		end

		if player:getMoney() < spells[item].buy then
			return selfSay("You don't have enough money.", cid)
		end

		player:removeMoney(spells[item].buy)
		player:learnSpell(spells[item].spell)
		player:getPosition():sendMagicEffect(12)
		selfSay("You have learned " .. spells[item].spell, cid)
		return true
	end

	if msgcontains(msg, "spells") then
		selfSay("Here are the spells that you can learn from me.", cid)
		for var, item in pairs(spells) do
			if not AllSpells then
				if not player:hasLearnedSpell(item.spell) then
					if player:getLevel() >= item.level then
						if isInArray(item.vocations, player:getVocation():getId()) then
							if PremiumSpells then
								if (item.premium == 1) and player:isPremium() then
									table.insert(shopWindow, {id = var, subType = 0, buy = item.buy, sell = 0, name = item.name})
								end
							else
								table.insert(shopWindow, {id = var, subType = 0, buy = item.buy, sell = 0, name = item.name})
							end
						end
					end
				end
			else
				table.insert(shopWindow, {id = var, subType = 0, buy = item.buy, sell = 0, name = item.name})
			end
		end
		openShopWindow(cid, shopWindow, onBuy, onSell)
	end
	return true
end


npcHandler:setCallback(CALLBACK_MESSAGE_DEFAULT, tradeSpellCallback)