Domination = RegisterMod("Domination", 1)
local mod = Domination
local IsaacD = Isaac.GetPlayerTypeByName("IsaacD", false)
local rng = RNG()
local game = Game()

function mod:GetAllPlayers()
	local players = {}
	for i = 1, game:GetNumPlayers() do
		local player = Isaac.GetPlayer(i)
		if player:Exists() then
			table.insert(players, player)
		end
	end
	return players
end

function mod:GetPlayersOfType(type)
	local players = {}
	for _, player in pairs(mod:GetAllPlayers()) do
		if player:GetPlayerType() == type then
			table.insert(players, player)
		end
	end
	if players[1] then
		return players
	else
		return nil
	end
end

function mod:RandomInt(min, max, customRNG) --This and GetRandomElem were written by Guwahavel (hi)
    local rand = customRNG or rng
    if not max then
        max = min
        min = 0
    end  
    if min > max then 
        local temp = min
        min = max
        max = temp
    end
    return min + (rand:RandomInt(max - min + 1))
end

function mod:GetRandomElem(table, customRNG)
    if table and #table > 0 then
		local index = mod:RandomInt(1, #table, customRNG)
        return table[index], index
    end
end

local diceitems = {
	CollectibleType.COLLECTIBLE_D1,
	CollectibleType.COLLECTIBLE_D4,
	CollectibleType.COLLECTIBLE_D6,
	CollectibleType.COLLECTIBLE_D7,
	CollectibleType.COLLECTIBLE_D8,
	CollectibleType.COLLECTIBLE_D10,
	CollectibleType.COLLECTIBLE_D12,
	CollectibleType.COLLECTIBLE_D20,
	CollectibleType.COLLECTIBLE_D100,
	CollectibleType.COLLECTIBLE_ETERNAL_D6,
	CollectibleType.COLLECTIBLE_SPINDOWN_DICE,
}

mod:AddCallback(ModCallbacks.MC_POST_NPC_DEATH, function(_, npc)
	local players = mod:GetPlayersOfType(IsaacD)
	for i, player in pairs(players or {}) do
		player:UseActiveItem(mod:GetRandomElem(diceitems), false)
	end
end)

mod:AddCallback(ModCallbacks.MC_USE_ITEM, function(_, type, rng, player)
	if player:GetPlayerType() == IsaacD then
		for i, entity in pairs(Isaac.FindByType(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE)) do
			if not player:HasCollectible(CollectibleType.COLLECTIBLE_BIRTHRIGHT) then
				entity:GetData().Rerolls = 2
			else
				entity:GetData().Rerolls = -1
			end
		end
	end
end, CollectibleType.COLLECTIBLE_D6)

mod:AddCallback(ModCallbacks.MC_POST_PICKUP_UPDATE, function(_, pickup)
	if pickup:GetData().Rerolls and pickup:GetData().Rerolls ~= 0 and pickup.FrameCount % 25 == 0 and pickup.SubType ~= 0 then
		local itempool = game:GetItemPool()
		local rerolls = pickup:GetData().Rerolls
		pickup:Morph(EntityType.ENTITY_PICKUP, PickupVariant.PICKUP_COLLECTIBLE, itempool:GetCollectible(itempool:GetPoolForRoom(game:GetLevel():GetCurrentRoomDesc().Data.Type, rng:GetSeed()), true))
		pickup:GetData().Rerolls = rerolls - 1
		Isaac.Spawn(EntityType.ENTITY_EFFECT, EffectVariant.POOF01, 0, pickup.Position, Vector.Zero, nil)
		rng:Next()
	end
end, PickupVariant.PICKUP_COLLECTIBLE)