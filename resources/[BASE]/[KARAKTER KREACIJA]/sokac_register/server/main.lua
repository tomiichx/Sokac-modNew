ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

function getIdentity(source, callback)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT identifier, firstname, lastname, dateofbirth, sex, height FROM `users` WHERE `identifier` = @identifier', {
		['@identifier'] = xPlayer.identifier
	}, function(result)
		if result[1].firstname ~= nil then
			local data = {
				identifier	= result[1].identifier,
				firstname	= result[1].firstname,
				lastname	= result[1].lastname,
				dateofbirth	= result[1].dateofbirth,
				sex			= result[1].sex,
				height		= result[1].height
			}

			callback(data)
		else
			local data = {
				identifier	= '',
				firstname	= '',
				lastname	= '',
				dateofbirth	= '',
				sex			= '',
				height		= ''
			}

			callback(data)
		end
	end)
end

function setIdentity(identifier, data, callback)
	MySQL.Async.execute('UPDATE `users` SET `firstname` = @firstname, `lastname` = @lastname, `dateofbirth` = @dateofbirth, `sex` = @sex, `height` = @height WHERE identifier = @identifier', {
		['@identifier']		= identifier,
		['@firstname']		= data.firstname,
		['@lastname']		= data.lastname,
		['@dateofbirth']	= data.dateofbirth,
		['@sex']			= data.sex,
		['@height']			= data.height
	}, function(rowsChanged)
		if callback then
			callback(true)
		end
	end)
end

function updateIdentity(playerId, data, callback)
	local xPlayer = ESX.GetPlayerFromId(playerId)

	MySQL.Async.execute('UPDATE `users` SET `firstname` = @firstname, `lastname` = @lastname, `dateofbirth` = @dateofbirth, `sex` = @sex, `height` = @height WHERE identifier = @identifier', {
		['@identifier']		= xPlayer.identifier,
		['@firstname']		= data.firstname,
		['@lastname']		= data.lastname,
		['@dateofbirth']	= data.dateofbirth,
		['@sex']			= data.sex,
		['@height']			= data.height
	}, function(rowsChanged)
		if callback then
			xPlayer.set('firstName', data.firstname)
			xPlayer.set('lastName', data.lastname)
			xPlayer.setName(('%s %s'):format(data.firstname, data.lastname))
			callback(true)
		end
	end)
end

function deleteIdentity(identifier, data, callback)
	MySQL.Async.execute('UPDATE `users` SET `firstname` = @firstname, `lastname` = @lastname, `dateofbirth` = @dateofbirth, `sex` = @sex, `height` = @height WHERE identifier = @identifier', {
		['@identifier']		= identifier,
		['@firstname']		= '',
		['@lastname']		= '',
		['@dateofbirth']	= '',
		['@sex']			= '',
		['@height']			= ''
	}, function(rowsChanged)
		if callback then
			callback(true)
		end
	end)
end

RegisterServerEvent('esx_identity:setIdentity')
AddEventHandler('esx_identity:setIdentity', function(data, myIdentifiers)
	local xPlayer = ESX.GetPlayerFromId(source)
	setIdentity(myIdentifiers.steamid, data, function(callback)
		if callback then
			TriggerClientEvent('esx_identity:identityCheck', myIdentifiers.playerid, true)
			TriggerEvent('esx_identity:characterUpdated', myIdentifiers.playerid, data)
		else
			TriggerClientEvent('chat:addMessage', myIdentifiers.playerid, { args = { 'Sokac ^3» ', 'Greška prilikom učitavanja karaktera, kontaktirajte admina.' } })
		end
	end)
end)

AddEventHandler('esx:playerLoaded', function(playerId, xPlayer)
	local myID = {
		steamid = xPlayer.identifier,
		playerid = playerId
	}

	TriggerClientEvent('esx_identity:saveID', playerId, myID)

	getIdentity(playerId, function(data)
		if data.firstname == '' then
			TriggerClientEvent('esx_identity:identityCheck', playerId, false)
			TriggerClientEvent('esx_identity:showRegisterIdentity', xPlayer.source)
		else
			TriggerClientEvent('esx_identity:identityCheck', playerId, true)
			TriggerEvent('esx_identity:characterUpdated', playerId, data)
		end
	end)
end)

AddEventHandler('esx_identity:characterUpdated', function(playerId, data)
	local xPlayer = ESX.GetPlayerFromId(playerId)

	if xPlayer then
		xPlayer.setName(('%s %s'):format(data.firstname, data.lastname))
		xPlayer.set('firstName', data.firstname)
		xPlayer.set('lastName', data.lastname)
		xPlayer.set('dateofbirth', data.dateofbirth)
		xPlayer.set('sex', data.sex)
		xPlayer.set('height', data.height)
	end
end)

AddEventHandler('onResourceStart', function(resource)
	if resource == GetCurrentResourceName() then
		Citizen.Wait(3000)
		local xPlayers = ESX.GetPlayers()

		for i=1, #xPlayers, 1 do
			local xPlayer = ESX.GetPlayerFromId(xPlayers[i])

			if xPlayer then
				local myID = {
					steamid  = xPlayer.identifier,
					playerid = xPlayer.source
				}
	
				TriggerClientEvent('esx_identity:saveID', xPlayer.source, myID)
	
				getIdentity(xPlayer.source, function(data)
					if data.firstname == '' then
						TriggerClientEvent('esx_identity:identityCheck', xPlayer.source, false)
						TriggerClientEvent('esx_identity:showRegisterIdentity', playerid)
					else
						TriggerClientEvent('esx_identity:identityCheck', xPlayer.source, true)
						TriggerEvent('esx_identity:characterUpdated', xPlayer.source, data)
					end
				end)
			end
		end
	end
end)

ESX.RegisterCommand('register', 'user', function(xPlayer, args, showError)
	getIdentity(xPlayer.source, function(data)
		if data.firstname ~= '' then
			TriggerClientEvent('chat:addMessage', xPlayer.source, { args = { 'Sokac ^3» ', '^0Možete imati samo jedan karakter, u butik se presvucite' } })
		else
			TriggerClientEvent('esx_identity:showRegisterIdentity', xPlayer.source)
		end
	end)
end, false, {help = "Napravite novi karakter"})

ESX.RegisterCommand('الْعَرَبِيَّة', 'user', function(xPlayer, args, showError)
	getIdentity(xPlayer.source, function(data)
		if data.firstname ~= '' then
			deleteIdentity(xPlayer.identifier, data, function(callback)
				if callback then
					TriggerClientEvent('chat:addMessage', xPlayer.source, { args = { 'Sokac ^3» ', 'Obrisali ste ^1' .. data.firstname .. ' ' .. data.lastname } })
				else
					TriggerClientEvent('chat:addMessage', xPlayer.source, { args = { 'Sokac ^3» ', 'Greška u bazi kontaktirajte vlasnika!' } })
				end
			end)
		else
			TriggerClientEvent('chat:addMessage', xPlayer.source, { args = { 'Sokac ^3» ', 'Već ste obrisali karakter!' } })
		end
	end)
end, false, {help = ''})
