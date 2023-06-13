local dutyPlayers = {}
local trees = {}

ESX.RegisterServerCallback('map_lumberjack:duty', function(source, cb)
    local xPlayer = ESX.GetPlayerFromId(source)
    local job = xPlayer.getJob()
    if not Config.FreelanceJob and job.name ~= Config.JobName then
        return false
    end

    if dutyPlayers[source] then
        dutyPlayers[source] = nil
        cb(false)
    else
        dutyPlayers[source] = true
        cb(true)
    end
end)

Citizen.CreateThread(function()
    for k,v in pairs(Config.Trees) do
        table.insert(trees, { 
            coords = v, health = 100 
        })
    end
end)

ESX.RegisterServerCallback('map_lumberjack:getTreesWithData', function(_, cb)
   cb(trees)
end)

ESX.RegisterServerCallback('map_lumberjack:hasItem', function(src, cb)
    local xPlayer = ESX.GetPlayerFromId(src)
    cb(xPlayer.getInventoryItem(Config.RequireItem).count)
end)



ESX.RegisterServerCallback('map_lumberjack:makeDamage', function(source, cb, index)
    local data = trees[index]
    local xPlayer = ESX.GetPlayerFromId(source)

    if not data or not dutyPlayers[source] then
        cb(false)
    end

    trees[index].health -= 20
    syncTrees()
    cb(true)

    if data.health == 0 then
        xPlayer.addInventoryItem('wood', 1)
        Citizen.SetTimeout(Config.GrowingTime, function()
            trees[index].health = 100
            syncTrees()
        end)
    end

end)

function syncTrees()
    TriggerClientEvent('map_lumberjack:syncTrees', -1, trees)
end

RegisterNetEvent('map_lumberjack:sellAllWood', function()
    local xPlayer = ESX.GetPlayerFromId(source)
    local dist = #(xPlayer.getCoords(true) - Config.SellPoint)
    if (dist > 2) then
        return false
    end

    local inventory = xPlayer.getInventory(true)
    local total = 0

    for k,v in pairs(inventory) do
        if k == 'wood' then
            xPlayer.addAccountMoney('money', v * Config.WoodPrice)
            xPlayer.removeInventoryItem('wood', v)
            total = v
        end
    end

    if total > 0 then
        xPlayer.showNotification('You sold all the wood and got ' .. total * Config.WoodPrice .. '$')
    end
end)
