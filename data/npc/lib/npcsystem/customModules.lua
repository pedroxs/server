-- Custom Modules, created to help us in this datapack
local travelDiscounts = {
	['postman'] = {price = 10, storage = Storage.postman.Rank, value = 3},
	['new frontier'] = {price = 50, storage = Storage.TheNewFrontier.Mission03, value = 1}
}

function StdModule.travelDiscount(player, discounts)
	local discountPrice, discount = 0
	if type(discounts) == 'string' then
		discount = travelDiscounts[discounts]
		if discount and player:getStorageValue(discount.storage) >= discount.value then
			return discount.price
		end
	else
		for i = 1, #discounts do
			discount = travelDiscounts[discounts[i]]
			if discount and player:getStorageValue(discount.storage) >= discount.value then
				discountPrice = discountPrice + discount.price
			end
		end
	end

	return discountPrice
end

function StdModule.kick(cid, message, keywords, parameters, node)
	local npcHandler = parameters.npcHandler
	if npcHandler == nil then
		error("StdModule.travel called without any npcHandler instance.")
	end

	if not npcHandler:isFocused(cid) then
		return false
	end

	npcHandler:releaseFocus(cid)
	npcHandler:say(parameters.text or "Off with you!", cid)

	local destination = parameters.destination
	if type(destination) == 'table' then
		destination = destination[math.random(#destination)]
	end

	Player(cid):teleportTo(destination, true)

	npcHandler:resetNpc(cid)
	return true
end

local GreetModule = {}
function GreetModule.greet(cid, message, keywords, parameters)
	if not parameters.npcHandler:isInRange(cid) then
		return true
	end

	if parameters.npcHandler:isFocused(cid) then
		return true
	end

	local parseInfo = { [TAG_PLAYERNAME] = Player(cid):getName() }
	parameters.npcHandler:say(parameters.npcHandler:parseMessage(parameters.text, parseInfo), cid, true)
	parameters.npcHandler:addFocus(cid)
	return true
end

function GreetModule.farewell(cid, message, keywords, parameters)
	if not parameters.npcHandler:isFocused(cid) then
		return false
	end

	local parseInfo = { [TAG_PLAYERNAME] = Player(cid):getName() }
	parameters.npcHandler:say(parameters.npcHandler:parseMessage(parameters.text, parseInfo), cid, true)
	parameters.npcHandler:resetNpc(cid)
	parameters.npcHandler:releaseFocus(cid)
	return true
end

-- Adds a keyword which acts as a greeting word
function KeywordHandler:addGreetKeyword(keys, parameters, condition, action)
	local keys = keys
	keys.callback = FocusModule.messageMatcherDefault
	return self:addKeyword(keys, GreetModule.greet, parameters, condition, action)
end

-- Adds a keyword which acts as a farewell word
function KeywordHandler:addFarewellKeyword(keys, parameters, condition, action)
	local keys = keys
	keys.callback = FocusModule.messageMatcherDefault
	return self:addKeyword(keys, GreetModule.farewell, parameters, condition, action)
end

-- Adds a keyword which acts as a spell word
function KeywordHandler:addSpellKeyword(keys, parameters)
	local keys = keys
	keys.callback = FocusModule.messageMatcherDefault

	local npcHandler, spellName, price, vocationId = parameters.npcHandler, parameters.spellName, parameters.price, parameters.vocation
	local spellKeyword = self:addKeyword(keys, StdModule.say, {npcHandler = npcHandler, text = string.format("Do you want to learn the spell '%s' for %s?", spellName, price > 0 and price .. ' gold' or 'free')},
		function(player)
			local baseVocationId = player:getVocation():getBase():getId()
			if type(vocationId) == 'table' then
				return isInArray(vocationId, baseVocationId)
			else
				return vocationId == baseVocationId
			end
		end
	)

	spellKeyword:addChildKeyword({'yes'}, StdModule.learnSpell, {npcHandler = npcHandler, spellName = spellName, level = parameters.level, price = price})
	spellKeyword:addChildKeyword({'no'}, StdModule.say, {npcHandler = npcHandler, text = 'Maybe next time.', reset = true})
end

local hints = {
	[-1] = 'If you don\'t know the meaning of an icon on the right side, move the mouse cursor on it and wait a moment.',
	[0] = 'Send private messages to other players by right-clicking on the player or the player\'s name and select \'Message to ....\'. You can also open a \'private message channel\' and type in the name of the player.',
	[1] = 'Use the shortcuts \'SHIFT\' to look, \'CTRL\' for use and \'ALT\' for attack when clicking on an object or player.',
	[2] = 'If you already know where you want to go, click on the automap and your character will walk there automatically if the location is reachable and not too far away.',
	[3] = 'To open or close skills, battle or VIP list, click on the corresponding button to the right.',
	[4] = '\'Capacity\' restricts the amount of things you can carry with you. It raises with each level.',
	[5] = 'Always have a look on your health bar. If you see that you do not regenerate health points anymore, eat something.',
	[6] = 'Always eat as much food as possible. This way, you\'ll regenerate health points for a longer period of time.',
	[7] = 'After you have killed a monster, you have 10 seconds in which the corpse is not moveable and no one else but you can loot it.',
	[8] = 'Be careful when you approach three or more monsters because you only can block the attacks of two. In such a situation even a few rats can do severe damage or even kill you.',
	[9] = 'There are many ways to gather food. Many creatures drop food but you can also pick blueberries or bake your own bread. If you have a fishing rod and worms in your inventory, you can also try to catch a fish.',
	[10] = {'Baking bread is rather complex. First of all you need a scythe to harvest wheat. Then you use the wheat with a millstone to get flour. ...', 'This can be be used on water to get dough, which can be used on an oven to bake bread. Use milk instead of water to get cake dough.'},
	[11] = 'Dying hurts! Better run away than risk your life. You are going to lose experience and skill points when you die.',
	[12] = 'When you switch to \'Offensive Fighting\', you deal out more damage but you also get hurt more easily.',
	[13] = 'When you are on low health and need to run away from a monster, switch to \'Defensive Fighting\' and the monster will hit you less severely.',
	[14] = 'Many creatures try to run away from you. Select \'Chase Opponent\' to follow them.',
	[15] = 'The deeper you enter a dungeon, the more dangerous it will be. Approach every dungeon with utmost care or an unexpected creature might kill you. This will result in losing experience and skill points.',
	[16] = 'Due to the perspective, some objects in Tibia are not located at the spot they seem to appear (ladders, windows, lamps). Try clicking on the floor tile the object would lie on.',
	[17] = 'If you want to trade an item with another player, right-click on the item and select \'Trade with ...\', then click on the player with whom you want to trade.',
	[18] = 'Stairs, ladders and dungeon entrances are marked as yellow dots on the automap.',
	[19] = 'You can get food by killing animals or monsters. You can also pick blueberries or bake your own bread. If you are too lazy or own too much money, you can also buy food.',
	[20] = 'Quest containers can be recognised easily. They don\'t open up regularly but display a message \'You have found ....\'. They can only be opened once.',
	[21] = 'Better run away than risk to die. You\'ll lose experience and skill points each time you die.',
	[22] = 'You can form a party by right-clicking on a player and selecting \'Invite to Party\'. The party leader can also enable \'Shared Experience\' by right-clicking on him- or herself.',
	[23] = 'You can assign spells, the use of items, or random text to \'hotkeys\'. You find them under \'Options\'.',
	[24] = 'You can also follow other players. Just right-click on the player and select \'Follow\'.',
	[25] = 'You can found a party with your friends by right-clicking on a player and selecting \'Invite to Party\'. If you are invited to a party, right-click on yourself and select \'Join Party\'.',
	[26] = 'Only found parties with people you trust. You can attack people in your party without getting a skull. This is helpful for training your skills, but can be abused to kill people without having to fear negative consequences.',
	[27] = 'The leader of a party has the option to distribute gathered experience among all players in the party. If you are the leader, right-click on yourself and select \'Enable Shared Experience\'.',
	[28] = 'There is nothing more I can tell you. If you are still in need of some {hints}, I can repeat them for you.'
}

function StdModule.rookgaardHints(cid, message, keywords, parameters, node)
	local npcHandler = parameters.npcHandler
	if npcHandler == nil then
		error("StdModule.say called without any npcHandler instance.")
	end

	if not npcHandler:isFocused(cid) then
		return false
	end

	local player = Player(cid)
	local hintId = player:getStorageValue(Storage.RookgaardHints)
	npcHandler:say(hints[hintId], cid)
	if hintId >= #hints then
		player:setStorageValue(Storage.RookgaardHints, -1)
	else
		player:setStorageValue(Storage.RookgaardHints, hintId + 1)
	end
	return true
end

-- VoiceModule
VoiceModule = {
	voices = nil,
	voiceCount = 0,
	lastVoice = 0,
	timeout = nil,
	chance = nil,
	npcHandler = nil
}

-- Creates a new instance of VoiceModule
function VoiceModule:new(voices, timeout, chance)
	local obj = {}
	setmetatable(obj, self)
	self.__index = self

	obj.voices = voices
	for i = 1, #obj.voices do
		local voice = obj.voices[i]
		if voice.yell then
			voice.yell = nil
			voice.talktype = TALKTYPE_YELL
		else
			voice.talktype = TALKTYPE_SAY
		end
	end

	obj.voiceCount = #voices
	obj.timeout = timeout or 10
	obj.chance = chance or 25
	return obj
end

function VoiceModule:init(handler)
	return true
end

function VoiceModule:callbackOnThink()
	if self.lastVoice < os.time() then
		self.lastVoice = os.time() + self.timeout
		if math.random(100) < self.chance  then
			local voice = self.voices[math.random(self.voiceCount)]
			Npc():say(voice.text, voice.talktype)
		end
	end
	return true
end

-- TradeSpellModulo = {}

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

function StdModule.tradeSpellCallback(cid, type, msg)
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

