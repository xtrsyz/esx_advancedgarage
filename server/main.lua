ESX = nil

TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)

-- Make sure all Vehicles are Stored on restart
MySQL.ready(function()
	if Config.Main.ParkVehicles then
		--ParkVehicles()
		MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = true WHERE `stored` = @stored', {
			['@stored'] = false
		}, function(rowsChanged)
			if rowsChanged > 0 then
				print(('esx_advancedgarage: %s vehicle(s) have been stored!'):format(rowsChanged))
			end
		end)
	else
		print('esx_advancedgarage: Parking Vehicles on restart is currently set to false.')
	end
end)

-- Add Command for Getting Properties
if Config.Main.Commands then
	ESX.RegisterCommand('getgarages', 'user', function(xPlayer, args, showError)
		xPlayer.triggerEvent('esx_advancedgarage:getPropertiesC')
	end, true, {help = 'Get Private Garages', validate = false})
end

-- Add Print Command for Getting Properties
RegisterServerEvent('esx_advancedgarage:printGetProperties')
AddEventHandler('esx_advancedgarage:printGetProperties', function()
	print('Getting Properties')
end)

-- Get Owned Properties
ESX.RegisterServerCallback('esx_advancedgarage:getOwnedProperties', function(source, cb)
	local xPlayer = ESX.GetPlayerFromId(source)
	local properties = {}

	MySQL.Async.fetchAll('SELECT * FROM owned_properties WHERE owner = @owner', {
		['@owner'] = xPlayer.identifier
	}, function(data)
		for _,v in pairs(data) do
			table.insert(properties, v.name)
		end
		cb(properties)
	end)
end)

-- Start of Garage Fetch Vehicles
ESX.RegisterServerCallback('esx_advancedgarage:getOwnedVehicles', function(source, cb, job, category, garage)
	local xPlayer = ESX.GetPlayerFromId(source)
	local type = 'car'
	if category == 'helis' or category == 'planes' then
		type = 'aircraft'
	elseif category == 'boats' or category == 'subs' then
		type = 'boat'
	end
	local ownedVehicles = {}

	if job == 'civ' then
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND garage = @garage AND Type = @Type AND job = @job AND category = @category', {
			['@owner'] = xPlayer.identifier,
			['@garage'] = garage,
			['@Type'] = type,
			['@job'] = job,
			['@category'] = category
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedVehicles, {vehicle = vehicle, plate = v.plate, vehName = v.name, fuel = v.fuel, stored = v.stored})
			end
			cb(ownedVehicles)
		end)
	else
		MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND category = @category', {
			['@owner'] = xPlayer.identifier,
			['@Type'] = type,
			['@job'] = job,
			['@category'] = category
		}, function(data)
			for _,v in pairs(data) do
				local vehicle = json.decode(v.vehicle)
				table.insert(ownedVehicles, {vehicle = vehicle, plate = v.plate, vehName = v.name, fuel = v.fuel, stored = v.stored})
			end
			cb(ownedVehicles)
		end)
	end	
end)
-- End of Garage Fetch Vehicles

-- Start of Impound Fetch Vehicles
ESX.RegisterServerCallback('esx_advancedgarage:getOutOwnedVehicles', function(source, cb, job, category)
	local xPlayer = ESX.GetPlayerFromId(source)
	local type = 'car'
	if category == 'helis' or category == 'planes' then
		type = 'aircraft'
	elseif category == 'boats' or category == 'subs' then
		type = 'boat'
	end
	local outVehicles = {}
	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND Type = @Type AND job = @job AND `stored` = @stored', {
		['@owner'] = xPlayer.identifier,
		['@Type'] = type,
		['@job'] = job,
		['@stored'] = false
	}, function(data) 
		for _,v in pairs(data) do
			local vehicle = json.decode(v.vehicle)
			table.insert(outVehicles, {vehicle = vehicle, plate = v.plate, vehName = v.name, fuel = v.fuel})
		end
		cb(outVehicles)
	end)
end)
-- End of Impound Fetch Vehicles

-- Start of Impound Pay
ESX.RegisterServerCallback('esx_advancedgarage:payImpound', function(source, cb, job, type, attempt)
	local xPlayer = ESX.GetPlayerFromId(source)

	if job == 'civ' then
		if type == 'aircrafts' then
			if attempt == 'check' then
				if xPlayer.getMoney() >= Config.Aircrafts.PoundP then
					cb(true)
				else
					cb(false)
				end
			else
				xPlayer.removeMoney(Config.Aircrafts.PoundP)
				TriggerClientEvent('esx:showNotification', source, _U('you_paid') .. Config.Aircrafts.PoundP)
				if Config.Main.GiveSocMoney then
					TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mechanic', function(account)
						account.addMoney(Config.Aircrafts.PoundP)
					end)
				end
				cb()
			end
		elseif type == 'boats' then
			if attempt == 'check' then
				if xPlayer.getMoney() >= Config.Boats.PoundP then
					cb(true)
				else
					cb(false)
				end
			else
				xPlayer.removeMoney(Config.Boats.PoundP)
				TriggerClientEvent('esx:showNotification', source, _U('you_paid') .. Config.Boats.PoundP)
				if Config.Main.GiveSocMoney then
					TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mechanic', function(account)
						account.addMoney(Config.Boats.PoundP)
					end)
				end
				cb()
			end
		elseif type == 'cars' then
			if attempt == 'check' then
				if xPlayer.getMoney() >= Config.Cars.PoundP then
					cb(true)
				else
					cb(false)
				end
			else
				xPlayer.removeMoney(Config.Cars.PoundP)
				TriggerClientEvent('esx:showNotification', source, _U('you_paid') .. Config.Cars.PoundP)
				if Config.Main.GiveSocMoney then
					TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mechanic', function(account)
						account.addMoney(Config.Cars.PoundP)
					end)
				end
				cb()
			end
		end
	else
		if type == 'both' then
			if attempt == 'check' then
				if xPlayer.getMoney() >= Config.Ambulance.PoundP then
					cb(true)
				else
					cb(false)
				end
			else
				xPlayer.removeMoney(Config[job].PoundP)
				TriggerClientEvent('esx:showNotification', source, _U('you_paid') .. Config[job].PoundP)
				if Config.Main.GiveSocMoney then
					TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mechanic', function(account)
						account.addMoney(Config[job].PoundP)
					end)
				end
				cb()
			end
		end
	end
end)
-- End of Impound Pay

-- Store Vehicles
ESX.RegisterServerCallback('esx_advancedgarage:storeVehicle', function (source, cb, vehicleProps, garage)
	local ownedCars = {}
	local vehplate = vehicleProps.plate:match("^%s*(.-)%s*$")
	local vehiclemodel = vehicleProps.model
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.fetchAll('SELECT * FROM owned_vehicles WHERE owner = @owner AND plate = @plate', {
		['@owner'] = xPlayer.identifier,
		['@plate'] = vehicleProps.plate
	}, function (result)
		if result[1] ~= nil then
			local originalvehprops = json.decode(result[1].vehicle)
			if originalvehprops.model == vehiclemodel then
				if result[1].job == 'civ' then
					MySQL.Async.execute('UPDATE owned_vehicles SET vehicle = @vehicle, garage = @garage WHERE owner = @owner AND plate = @plate', {
						['@owner'] = xPlayer.identifier,
						['@garage'] = garage,
						['@vehicle'] = json.encode(vehicleProps),
						['@plate'] = vehicleProps.plate
					}, function (rowsChanged)
						if rowsChanged == 0 then
							print(('esx_advancedgarage: %s attempted to store an vehicle they don\'t own!'):format(xPlayer.identifier))
						end
						cb(true)
					end)
				else
					MySQL.Async.execute('UPDATE owned_vehicles SET vehicle = @vehicle WHERE owner = @owner AND plate = @plate', {
						['@owner'] = xPlayer.identifier,
						['@vehicle'] = json.encode(vehicleProps),
						['@plate'] = vehicleProps.plate
					}, function (rowsChanged)
						if rowsChanged == 0 then
							print(('esx_advancedgarage: %s attempted to store an vehicle they don\'t own!'):format(xPlayer.identifier))
						end
						cb(true)
					end)
				end
				
			else
				if Config.Main.KickCheaters then
					if Config.Main.CustomKickMsg then
						print(('esx_advancedgarage: %s attempted to Cheat! Tried Storing: %s | Original Vehicle: %s '):format(xPlayer.identifier, vehiclemodel, originalvehprops.model))

						DropPlayer(source, _U('custom_kick'))
						cb(false)
					else
						print(('esx_advancedgarage: %s attempted to Cheat! Tried Storing: %s | Original Vehicle: %s '):format(xPlayer.identifier, vehiclemodel, originalvehprops.model))

						DropPlayer(source, 'You have been Kicked from the Server for Possible Garage Cheating!!!')
						cb(false)
					end
				else
					print(('esx_advancedgarage: %s attempted to Cheat! Tried Storing: %s | Original Vehicle: %s '):format(xPlayer.identifier, vehiclemodel, originalvehprops.model))
					cb(false)
				end
			end
		else
			print(('esx_advancedgarage: %s attempted to store an vehicle they don\'t own!'):format(xPlayer.identifier))
			cb(false)
		end
	end)
end)

-- Pay to Return Broken Vehicles
RegisterServerEvent('esx_advancedgarage:payhealth')
AddEventHandler('esx_advancedgarage:payhealth', function(price)
	local xPlayer = ESX.GetPlayerFromId(source)
	xPlayer.removeMoney(price)
	TriggerClientEvent('esx:showNotification', source, _U('you_paid') .. price)

	if Config.Main.GiveSocMoney then
		TriggerEvent('esx_addonaccount:getSharedAccount', 'society_mechanic', function(account)
			account.addMoney(price)
		end)
	end
end)

-- Rename Vehicle
RegisterServerEvent('esx_advancedgarage:renameVehicle')
AddEventHandler('esx_advancedgarage:renameVehicle', function(plate, name)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE owned_vehicles SET name = @name WHERE plate = @plate', {
		['@name'] = name,
		['@plate'] = plate
	}, function(rowsChanged)
		if rowsChanged == 0 then
			print(('esx_advancedgarage: %s exploited the garage!'):format(xPlayer.identifier))
		end
	end)
end)

-- Modify State of Vehicles
RegisterServerEvent('esx_advancedgarage:setVehicleState')
AddEventHandler('esx_advancedgarage:setVehicleState', function(plate, state)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE owned_vehicles SET `stored` = @stored WHERE plate = @plate', {
		['@stored'] = state,
		['@plate'] = plate
	}, function(rowsChanged)
		if rowsChanged == 0 then
			print(('esx_advancedgarage: %s exploited the garage!'):format(xPlayer.identifier))
		end
	end)
end)

-- Set Fuel Level
RegisterServerEvent('esx_advancedgarage:setVehicleFuel')
AddEventHandler('esx_advancedgarage:setVehicleFuel', function(plate, fuel)
	local xPlayer = ESX.GetPlayerFromId(source)

	MySQL.Async.execute('UPDATE owned_vehicles SET fuel = @fuel WHERE plate = @plate', {
		['@fuel'] = fuel,
		['@plate'] = plate
	}, function(rowsChanged)
		if rowsChanged == 0 then
			print(('esx_advancedgarage: %s exploited the garage!'):format(xPlayer.identifier))
		end
	end)
end)
