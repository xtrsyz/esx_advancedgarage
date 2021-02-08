local CurrentActionData, PlayerData, userProperties, this_Garage, vehInstance, BlipList, PrivateBlips, JobBlips = {}, {}, {}, {}, {}, {}, {}, {}
local HasAlreadyEnteredMarker = false
local LastZone, CurrentAction, CurrentActionMsg, garageName
ESX = nil

Citizen.CreateThread(function()
	while ESX == nil do
		TriggerEvent('esx:getSharedObject', function(obj) ESX = obj end)
		Citizen.Wait(0)
	end

	while ESX.GetPlayerData().job == nil do
		Citizen.Wait(10)
	end

	ESX.PlayerData = ESX.GetPlayerData()

	CreateBlips()
	RefreshJobBlips()
end)

RegisterNetEvent('esx:playerLoaded')
AddEventHandler('esx:playerLoaded', function(xPlayer)
	if Config.Pvt.Garages then
		ESX.TriggerServerCallback('esx_advancedgarage:getOwnedProperties', function(properties)
			userProperties = properties
			DeletePrivateBlips()
			RefreshPrivateBlips()
		end)
	end

	ESX.PlayerData = xPlayer

	RefreshJobBlips()
end)

RegisterNetEvent('esx:setJob')
AddEventHandler('esx:setJob', function(job)
    ESX.PlayerData.job = job

	DeleteJobBlips()
	RefreshJobBlips()
end)

RegisterNetEvent('esx_advancedgarage:getPropertiesC')
AddEventHandler('esx_advancedgarage:getPropertiesC', function(xPlayer)
	if Config.Pvt.Garages then
		ESX.TriggerServerCallback('esx_advancedgarage:getOwnedProperties', function(properties)
			userProperties = properties
			DeletePrivateBlips()
			RefreshPrivateBlips()
		end)

		ESX.ShowNotification(_U('get_properties'))
		TriggerServerEvent('esx_advancedgarage:printGetProperties')
	end
end)

local function has_value (tab, val)
	for index, value in ipairs(tab) do
		if value == val then
			return true
		end
	end
	return false
end

-- Start of Jobs Code
function OpenJobGarageMenu(job)
	local elements = {}
	local NoVeh = true

	ESX.TriggerServerCallback('esx_advancedgarage:getOwnedVehicles', function(ownedCars)
		if #ownedCars > 0 then
			table.insert(elements, {label = _U('cars'), value = 'cars'})
			NoVeh = false
		end
	end, job, 'cars', garageName)

	ESX.TriggerServerCallback('esx_advancedgarage:getOwnedVehicles', function(ownedHelis)
		if #ownedHelis > 0 then
			table.insert(elements, {label = _U('helis'), value = 'helis'})
			NoVeh = false
		end
	end, job, 'helis', garageName)
	Citizen.Wait(250)

	if NoVeh then
		ESX.UI.Menu.CloseAll()
		ESX.ShowNotification(_U('garage_no_veh'))
	else
		ESX.UI.Menu.CloseAll()
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'ambulancegaragemenu', {
			title = _U('garage_menu'),
			align = GetConvar('esx_MenuAlign', 'top-left'),
			elements = elements
		}, function(data, menu)
			local action = data.current.value

			if action == 'cars' then
				local elements = {head = {_U('veh_plate'), _U('veh_name'), _U('veh_loc'), _U('actions')}, rows = {}}
				ESX.TriggerServerCallback('esx_advancedgarage:getOwnedVehicles', function(ownedCars)
					for _,v in pairs(ownedCars) do
						local vehStored = _U('veh_loc_unknown')
						if v.stored then
							vehStored = _U('veh_loc_garage')
						else
							vehStored = _U('veh_loc_impound')
						end

						table.insert(elements.rows, {data = v, cols = {v.plate, v.vehName, vehStored, '{{' .. _U('spawn') .. '|spawn}} {{' .. _U('rename') .. '|rename}}'}})
					end

					ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'owned_vehicles_list', elements, function(data2, menu2)
						local vehVehicle, vehPlate, vehStored, vehFuel = data2.data.vehicle, data2.data.plate, data2.data.stored, data2.data.fuel
						if data2.value == 'spawn' then
							if vehStored then
								SpawnVehicle(vehVehicle, vehPlate, vehFuel)
								ESX.UI.Menu.CloseAll()
							else
								ESX.ShowNotification(_U('veh_not_here'))
							end
						elseif data2.value == 'rename' then
							if Config.Main.RenameVehs then
								ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'renamevehicle', {
									title = _U('veh_rename', Config.Main.RenameMin, Config.Main.RenameMax - 1)
								}, function(data3, menu3)
									if string.len(data3.value) >= Config.Main.RenameMin and string.len(data3.value) < Config.Main.RenameMax then
										TriggerServerEvent('esx_advancedgarage:renameVehicle', vehPlate, data3.value)
										ESX.UI.Menu.CloseAll()
									else
										ESX.ShowNotification(_U('veh_rename_empty', Config.Main.RenameMin, Config.Main.RenameMax - 1))
									end
								end, function(data3, menu3)
									menu3.close()
								end)
							else
								ESX.ShowNotification(_U('veh_rename_no'))
							end
						end
					end, function(data2, menu2)
						menu2.close()
					end)
				end, job, 'cars', garageName)
			elseif action == 'helis' then
				local elements = {head = {_U('veh_plate'), _U('veh_name'), _U('veh_loc'), _U('actions')}, rows = {}}
				ESX.TriggerServerCallback('esx_advancedgarage:getOwnedVehicles', function(ownedHelis)
					for _,v in pairs(ownedHelis) do
						local vehStored = _U('veh_loc_unknown')
						if v.stored then
							vehStored = _U('veh_loc_garage')
						else
							vehStored = _U('veh_loc_impound')
						end

						table.insert(elements.rows, {data = v, cols = {v.plate, v.vehName, vehStored, '{{' .. _U('spawn') .. '|spawn}} {{' .. _U('rename') .. '|rename}}'}})
					end

					ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'owned_vehicles_list', elements, function(data2, menu2)
						local vehVehicle, vehPlate, vehStored, vehFuel = data2.data.vehicle, data2.data.plate, data2.data.stored, data2.data.fuel
						if data2.value == 'spawn' then
							if vehStored then
								SpawnVehicle2(vehVehicle, vehPlate, vehFuel)
								ESX.UI.Menu.CloseAll()
							else
								ESX.ShowNotification(_U('veh_not_here'))
							end
						elseif data2.value == 'rename' then
							if Config.Main.RenameVehs then
								ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'renamevehicle', {
									title = _U('veh_rename', Config.Main.RenameMin, Config.Main.RenameMax - 1)
								}, function(data3, menu3)
									if string.len(data3.value) >= Config.Main.RenameMin and string.len(data3.value) < Config.Main.RenameMax then
										TriggerServerEvent('esx_advancedgarage:renameVehicle', vehPlate, data3.value)
										ESX.UI.Menu.CloseAll()
									else
										ESX.ShowNotification(_U('veh_rename_empty', Config.Main.RenameMin, Config.Main.RenameMax - 1))
									end
								end, function(data3, menu3)
									menu3.close()
								end)
							else
								ESX.ShowNotification(_U('veh_rename_no'))
							end
						end
					end, function(data2, menu2)
						menu2.close()
					end)
				end, job, 'helis', garageName)
			end
		end, function(data, menu)
			menu.close()
		end)
	end
end

function OpenJobImpoundMenu(job)
	ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'policeambulancemenu', {
		title = _U('garage_menu'),
		align = GetConvar('esx_MenuAlign', 'top-left'),
		elements = {
			{label = _U('cars'), value = 'cars'},
			{label = _U('helis'), value = 'helis'}
	}}, function(data, menu)
		local action = data.current.value

		if action == 'cars' then
			local elements = {head = {_U('veh_plate'), _U('veh_name'), _U('impound_fee'), _U('actions')}, rows = {}}
			ESX.TriggerServerCallback('esx_advancedgarage:getOutOwnedVehicles', function(outCars)
				if #outCars == 0 then
					ESX.ShowNotification(_U('impound_no'))
				else
					for _,v in pairs(outCars) do
						table.insert(elements.rows, {data = v, cols = {v.plate, v.vehName, _U('impound_fee_value', ESX.Math.GroupDigits(Config[job].PoundP)), '{{' .. _U('return') .. '|return}}'}})
					end

					ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'out_owned_vehicles_list', elements, function(data2, menu2)
						local vehVehicle, vehPlate, vehFuel = data2.data.vehicle, data2.data.plate, data2.data.fuel
						local doesVehicleExist = false

						if data2.value == 'return' then
							for k,v in pairs (vehInstance) do
								if ESX.Math.Trim(v.plate) == ESX.Math.Trim(vehPlate) then
									if DoesEntityExist(v.vehicleentity) then
										doesVehicleExist = true
									else
										table.remove(vehInstance, k)
										doesVehicleExist = false
									end
								end
							end

							if not doesVehicleExist and not DoesAPlayerDrivesVehicle(vehPlate) then
								ESX.TriggerServerCallback('esx_advancedgarage:payImpound', function(hasEnoughMoney)
									if hasEnoughMoney then
										ESX.TriggerServerCallback('esx_advancedgarage:payImpound', function()
											SpawnVehicle(vehVehicle, vehPlate, vehFuel)
											ESX.UI.Menu.CloseAll()
										end, job, 'both', 'pay')
									else
										ESX.ShowNotification(_U('not_enough_money'))
									end
								end, job, 'both', 'check')
							else
								ESX.ShowNotification(_U('veh_out_world'))
							end
						end
					end, function(data2, menu2)
						menu2.close()
					end)
				end
			end, job, 'cars')
		elseif action == 'helis' then
			local elements = {head = {_U('veh_plate'), _U('veh_name'), _U('impound_fee'), _U('actions')}, rows = {}}
			ESX.TriggerServerCallback('esx_advancedgarage:getOutOwnedVehicles', function(outHelis)
				if #outHelis == 0 then
					ESX.ShowNotification(_U('impound_no'))
				else
					for _,v in pairs(outHelis) do
						table.insert(elements.rows, {data = v, cols = {v.plate, v.vehName, _U('impound_fee_value', ESX.Math.GroupDigits(Config[job].PoundP)), '{{' .. _U('return') .. '|return}}'}})
					end

					ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'out_owned_vehicles_list', elements, function(data2, menu2)
						local vehVehicle, vehPlate, vehFuel = data2.data.vehicle, data2.data.plate, data2.data.fuel
						local doesVehicleExist = false

						if data2.value == 'return' then
							for k,v in pairs (vehInstance) do
								if ESX.Math.Trim(v.plate) == ESX.Math.Trim(vehPlate) then
									if DoesEntityExist(v.vehicleentity) then
										doesVehicleExist = true
									else
										table.remove(vehInstance, k)
										doesVehicleExist = false
									end
								end
							end

							if not doesVehicleExist and not DoesAPlayerDrivesVehicle(vehPlate) then
								ESX.TriggerServerCallback('esx_advancedgarage:payImpound', function(hasEnoughMoney)
									if hasEnoughMoney then
										ESX.TriggerServerCallback('esx_advancedgarage:payImpound', function()
											SpawnVehicle2(vehVehicle, vehPlate, vehFuel)
											ESX.UI.Menu.CloseAll()
										end, job, 'both', 'pay')
									else
										ESX.ShowNotification(_U('not_enough_money'))
									end
								end, job, 'both', 'check')
							else
								ESX.ShowNotification(_U('veh_out_world'))
							end
						end
					end, function(data2, menu2)
						menu2.close()
					end)
				end
			end, job, 'helis')
		end
	end, function(data, menu)
		menu.close()
	end)
end

function StoreOwnedJobMenu(job)
	local playerPed  = GetPlayerPed(-1)

	if IsPedInAnyVehicle(playerPed,  false) then
		local playerPed = GetPlayerPed(-1)
		local coords = GetEntityCoords(playerPed)
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
		local current = GetPlayersLastVehicle(GetPlayerPed(-1), true)
		local engineHealth = GetVehicleEngineHealth(current)
		local plate = vehicleProps.plate

		ESX.TriggerServerCallback('esx_advancedgarage:storeVehicle', function(valid)
			if valid then
				if engineHealth < 990 then
					if Config.Main.DamageMult then
						local apprasial = math.floor((1000 - engineHealth)/1000*Config[job].PoundP*Config.Main.MultAmount)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					else
						local apprasial = math.floor((1000 - engineHealth)/1000*Config[job].PoundP)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					end
				else
					StoreVehicle(vehicle, vehicleProps)
				end	
			else
				ESX.ShowNotification(_U('cannot_store_vehicle'))
			end
		end, vehicleProps, garageName)
	else
		ESX.ShowNotification(_U('no_vehicle_to_enter'))
	end
end
-- End of Jobs Code

-- Start of Aircraft Code
function OpenAircraftGarageMenu()
	local category = {'helis', 'planes' }
	local ownedVehicles = {}
	local elements = {}
	local NoVeh = true

	for _,v in pairs(category) do
		ESX.TriggerServerCallback('esx_advancedgarage:getOwnedVehicles', function(owned)
			if #owned > 0 then
				ownedVehicles[v] = owned
				table.insert(elements, {label = _U(v) .. ' #' .. #owned, value = v})
				NoVeh = false
			end
		end, 'civ', v, garageName)
	end
	Citizen.Wait(250)

	if NoVeh then
		ESX.UI.Menu.CloseAll()
		ESX.ShowNotification(_U('garage_no_veh'))
	else
		ESX.UI.Menu.CloseAll()
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'aircraftgaragemenu', {
			title = _U('garage_menu'),
			align = GetConvar('esx_MenuAlign', 'top-left'),
			elements = elements
		}, function(data, menu)
			local action = data.current.value
			local elements = {head = {_U('veh_plate'), _U('veh_name'), _U('veh_loc'), _U('actions')}, rows = {}}

			for _,v in pairs(ownedVehicles[action]) do
				local vehStored = _U('veh_loc_unknown')
				if v.stored then
					vehStored = _U('veh_loc_garage')
				else
					vehStored = _U('veh_loc_impound')
				end

				table.insert(elements.rows, {data = v, cols = {v.plate, v.vehName, vehStored, '{{' .. _U('spawn') .. '|spawn}} {{' .. _U('rename') .. '|rename}}'}})
			end

			ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'owned_vehicles_list', elements, function(data2, menu2)
				local vehVehicle, vehPlate, vehStored, vehFuel = data2.data.vehicle, data2.data.plate, data2.data.stored, data2.data.fuel
				if data2.value == 'spawn' then
					if vehStored then
						SpawnVehicle(vehVehicle, vehPlate, vehFuel)
						ESX.UI.Menu.CloseAll()
					else
						ESX.ShowNotification(_U('veh_not_here'))
					end
				elseif data2.value == 'rename' then
					if Config.Main.RenameVehs then
						ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'renamevehicle', {
							title = _U('veh_rename', Config.Main.RenameMin, Config.Main.RenameMax - 1)
						}, function(data3, menu3)
							if string.len(data3.value) >= Config.Main.RenameMin and string.len(data3.value) < Config.Main.RenameMax then
								TriggerServerEvent('esx_advancedgarage:renameVehicle', vehPlate, data3.value)
								ESX.UI.Menu.CloseAll()
							else
								ESX.ShowNotification(_U('veh_rename_empty', Config.Main.RenameMin, Config.Main.RenameMax - 1))
							end
						end, function(data3, menu3)
							menu3.close()
						end)
					else
						ESX.ShowNotification(_U('veh_rename_no'))
					end
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end
end

function OpenAircraftImpoundMenu()
	local elements = {head = {_U('veh_plate'), _U('veh_name'), _U('impound_fee'), _U('actions')}, rows = {}}
	ESX.TriggerServerCallback('esx_advancedgarage:getOutOwnedVehicles', function(outCivAircrafts)
		if #outCivAircrafts == 0 then
			ESX.ShowNotification(_U('impound_no'))
		else
			for _,v in pairs(outCivAircrafts) do
				table.insert(elements.rows, {data = v, cols = {v.plate, v.vehName, _U('impound_fee_value', ESX.Math.GroupDigits(Config.Aircrafts.PoundP)), '{{' .. _U('return') .. '|return}}'}})
			end

			ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'out_owned_vehicles_list', elements, function(data2, menu2)
				local vehVehicle, vehPlate, vehFuel = data2.data.vehicle, data2.data.plate, data2.data.fuel
				local doesVehicleExist = false

				if data2.value == 'return' then
					for k,v in pairs (vehInstance) do
						if ESX.Math.Trim(v.plate) == ESX.Math.Trim(vehPlate) then
							if DoesEntityExist(v.vehicleentity) then
								doesVehicleExist = true
							else
								table.remove(vehInstance, k)
								doesVehicleExist = false
							end
						end
					end

					if not doesVehicleExist and not DoesAPlayerDrivesVehicle(vehPlate) then
						ESX.TriggerServerCallback('esx_advancedgarage:payImpound', function(hasEnoughMoney)
							if hasEnoughMoney then
								ESX.TriggerServerCallback('esx_advancedgarage:payImpound', function()
									SpawnVehicle(vehVehicle, vehPlate, vehFuel)
									ESX.UI.Menu.CloseAll()
								end, 'civ', 'aircrafts', 'pay')
							else
								ESX.ShowNotification(_U('not_enough_money'))
							end
						end, 'civ', 'aircrafts', 'check')
					else
						ESX.ShowNotification(_U('veh_out_world'))
					end
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end
	end, 'civ', 'aircrafts')
end

function StoreOwnedAircraftMenu()
	local playerPed  = GetPlayerPed(-1)

	if IsPedInAnyVehicle(playerPed,  false) then
		local playerPed = GetPlayerPed(-1)
		local coords = GetEntityCoords(playerPed)
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
		local current = GetPlayersLastVehicle(GetPlayerPed(-1), true)
		local engineHealth = GetVehicleEngineHealth(current)
		local plate = vehicleProps.plate

		ESX.TriggerServerCallback('esx_advancedgarage:storeVehicle', function(valid)
			if valid then
				if engineHealth < 990 then
					if Config.Main.DamageMult then
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Aircrafts.PoundP*Config.Main.MultAmount)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					else
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Aircrafts.PoundP)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					end
				else
					StoreVehicle(vehicle, vehicleProps)
				end	
			else
				ESX.ShowNotification(_U('cannot_store_vehicle'))
			end
		end, vehicleProps, garageName)
	else
		ESX.ShowNotification(_U('no_vehicle_to_enter'))
	end
end
-- End of Aircraft Code

-- Start of Boat Code
function OpenBoatGarageMenu()
	local category = {'boats', 'subs' }
	local ownedVehicles = {}
	local elements = {}
	local NoVeh = true

	for _,v in pairs(category) do
		ESX.TriggerServerCallback('esx_advancedgarage:getOwnedVehicles', function(owned)
			if #owned > 0 then
				ownedVehicles[v] = owned
				table.insert(elements, {label = _U(v) .. ' #' .. #owned, value = v})
				NoVeh = false
			end
		end, 'civ', v, garageName)
	end
	Citizen.Wait(250)

	if NoVeh then
		ESX.UI.Menu.CloseAll()
		ESX.ShowNotification(_U('garage_no_veh'))
	else
		ESX.UI.Menu.CloseAll()
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'boatgaragemenu', {
			title = _U('garage_menu'),
			align = GetConvar('esx_MenuAlign', 'top-left'),
			elements = elements
		}, function(data, menu)
			local action = data.current.value
			local elements = {head = {_U('veh_plate'), _U('veh_name'), _U('veh_loc'), _U('actions')}, rows = {}}
			for _,v in pairs(ownedVehicles[action]) do
				local vehStored = _U('veh_loc_unknown')
				if v.stored then
					vehStored = _U('veh_loc_garage')
				else
					vehStored = _U('veh_loc_impound')
				end

				table.insert(elements.rows, {data = v, cols = {v.plate, v.vehName, vehStored, '{{' .. _U('spawn') .. '|spawn}} {{' .. _U('rename') .. '|rename}}'}})
			end

			ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'owned_vehicles_list', elements, function(data2, menu2)
				local vehVehicle, vehPlate, vehStored, vehFuel = data2.data.vehicle, data2.data.plate, data2.data.stored, data2.data.fuel
				if data2.value == 'spawn' then
					if vehStored then
						SpawnVehicle(vehVehicle, vehPlate, vehFuel)
						ESX.UI.Menu.CloseAll()
					else
						ESX.ShowNotification(_U('veh_not_here'))
					end
				elseif data2.value == 'rename' then
					if Config.Main.RenameVehs then
						ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'renamevehicle', {
							title = _U('veh_rename', Config.Main.RenameMin, Config.Main.RenameMax - 1)
						}, function(data3, menu3)
							if string.len(data3.value) >= Config.Main.RenameMin and string.len(data3.value) < Config.Main.RenameMax then
								TriggerServerEvent('esx_advancedgarage:renameVehicle', vehPlate, data3.value)
								ESX.UI.Menu.CloseAll()
							else
								ESX.ShowNotification(_U('veh_rename_empty', Config.Main.RenameMin, Config.Main.RenameMax - 1))
							end
						end, function(data3, menu3)
							menu3.close()
						end)
					else
						ESX.ShowNotification(_U('veh_rename_no'))
					end
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end
end

function OpenBoatImpoundMenu()
	local elements = {head = {_U('veh_plate'), _U('veh_name'), _U('impound_fee'), _U('actions')}, rows = {}}
	ESX.TriggerServerCallback('esx_advancedgarage:getOutOwnedVehicles', function(outCivBoats)
		if #outCivBoats == 0 then
			ESX.ShowNotification(_U('impound_no'))
		else
			for _,v in pairs(outCivBoats) do
				table.insert(elements.rows, {data = v, cols = {v.plate, v.vehName, _U('impound_fee_value', ESX.Math.GroupDigits(Config.Boats.PoundP)), '{{' .. _U('return') .. '|return}}'}})
			end

			ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'out_owned_vehicles_list', elements, function(data2, menu2)
				local vehVehicle, vehPlate, vehFuel = data2.data.vehicle, data2.data.plate, data2.data.fuel
				local doesVehicleExist = false

				if data2.value == 'return' then
					for k,v in pairs (vehInstance) do
						if ESX.Math.Trim(v.plate) == ESX.Math.Trim(vehPlate) then
							if DoesEntityExist(v.vehicleentity) then
								doesVehicleExist = true
							else
								table.remove(vehInstance, k)
								doesVehicleExist = false
							end
						end
					end

					if not doesVehicleExist and not DoesAPlayerDrivesVehicle(vehPlate) then
						ESX.TriggerServerCallback('esx_advancedgarage:payImpound', function(hasEnoughMoney)
							if hasEnoughMoney then
								ESX.TriggerServerCallback('esx_advancedgarage:payImpound', function()
									SpawnVehicle(vehVehicle, vehPlate, vehFuel)
									ESX.UI.Menu.CloseAll()
								end, 'civ', 'boats', 'pay')
							else
								ESX.ShowNotification(_U('not_enough_money'))
							end
						end, 'civ', 'boats', 'check')
					else
						ESX.ShowNotification(_U('veh_out_world'))
					end
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end
	end, 'civ', 'boats')
end

function StoreOwnedBoatMenu()
	local playerPed  = GetPlayerPed(-1)

	if IsPedInAnyVehicle(playerPed,  false) then
		local playerPed = GetPlayerPed(-1)
		local coords = GetEntityCoords(playerPed)
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
		local current = GetPlayersLastVehicle(GetPlayerPed(-1), true)
		local engineHealth = GetVehicleEngineHealth(current)
		local plate = vehicleProps.plate

		ESX.TriggerServerCallback('esx_advancedgarage:storeVehicle', function(valid)
			if valid then
				if engineHealth < 990 then
					if Config.Main.DamageMult then
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Boats.PoundP*Config.Main.MultAmount)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					else
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Boats.PoundP)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					end
				else
					StoreVehicle(vehicle, vehicleProps)
				end	
			else
				ESX.ShowNotification(_U('cannot_store_vehicle'))
			end
		end, vehicleProps, garageName)
	else
		ESX.ShowNotification(_U('no_vehicle_to_enter'))
	end
end
-- End of Boat Code

-- Start of Car Code
function OpenCarGarageMenu()
	local category = {'cycles', 'compacts', 'coupes', 'motorcycles', 'muscles', 'offroads', 'sedans', 'sports', 'sportsclassics', 'supers', 'suvs', 'vans' }
	local elements = {}
	local NoVeh = true
	local ownedVehicles = {}

	-- Start of esx_advancedvehicleshop Truck Shop
	if Config.Main.TruckShop then
		table.insert(elements, {label = _U('large_trucks'), value = 'large_trucks'})
	end
	-- End of esx_advancedvehicleshop Truck Shop

	for _,v in pairs(category) do
		ESX.TriggerServerCallback('esx_advancedgarage:getOwnedVehicles', function(owned)
			if #owned > 0 then
				ownedVehicles[v] = owned
				table.insert(elements, {label = _U(v) .. ' #' .. #owned, value = v})
				NoVeh = false
			end
		end, 'civ', v, garageName)
	end

	Citizen.Wait(250)

	if NoVeh and not Config.Main.TruckShop then
		ESX.UI.Menu.CloseAll()
		ESX.ShowNotification(_U('garage_no_veh'))
	else
		ESX.UI.Menu.CloseAll()
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'cargaragemenu', {
			title = _U('garage_menu'),
			align = GetConvar('esx_MenuAlign', 'top-left'),
			elements = elements
		}, function(data, menu)
			local action = data.current.value

			if action == 'large_trucks' then
				if Config.Main.TruckShop then
					OpenTruckGarageMenu()
				else
					ESX.ShowNotification(_U('large_trucks_no'))
				end
			else
				local elements = {head = {_U('veh_plate'), _U('veh_name'), _U('veh_loc'), _U('actions')}, rows = {}}
				for _,v in pairs(ownedVehicles[action]) do
					local vehStored = _U('veh_loc_unknown')
					if v.stored then
						vehStored = _U('veh_loc_garage')
					else
						vehStored = _U('veh_loc_impound')
					end

					table.insert(elements.rows, {data = v, cols = {v.plate, v.vehName, vehStored, '{{' .. _U('spawn') .. '|spawn}} {{' .. _U('rename') .. '|rename}}'}})
				end

				ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'owned_vehicles_list', elements, function(data2, menu2)
					local vehVehicle, vehPlate, vehStored, vehFuel = data2.data.vehicle, data2.data.plate, data2.data.stored, data2.data.fuel
					if data2.value == 'spawn' then
						if vehStored then
							SpawnVehicle(vehVehicle, vehPlate, vehFuel)
							ESX.UI.Menu.CloseAll()
						else
							ESX.ShowNotification(_U('veh_not_here'))
						end
					elseif data2.value == 'rename' then
						if Config.Main.RenameVehs then
							ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'renamevehicle', {
								title = _U('veh_rename', Config.Main.RenameMin, Config.Main.RenameMax - 1)
							}, function(data3, menu3)
								if string.len(data3.value) >= Config.Main.RenameMin and string.len(data3.value) < Config.Main.RenameMax then
									TriggerServerEvent('esx_advancedgarage:renameVehicle', vehPlate, data3.value)
									ESX.UI.Menu.CloseAll()
								else
									ESX.ShowNotification(_U('veh_rename_empty', Config.Main.RenameMin, Config.Main.RenameMax - 1))
								end
							end, function(data3, menu3)
								menu3.close()
							end)
						else
							ESX.ShowNotification(_U('veh_rename_no'))
						end
					end
				end, function(data2, menu2)
					menu2.close()
				end)
			end
		end, function(data, menu)
			menu.close()
		end)
	end
end

function OpenTruckGarageMenu()
	local category = {'box', 'haul', 'other', 'trans'}
	local elements = {}
	local NoVeh = true
	local ownedVehicles = {}

	for _,v in pairs(category) do
		ESX.TriggerServerCallback('esx_advancedgarage:getOwnedVehicles', function(owned)
			if #owned > 0 then
				ownedVehicles[v] = owned
				table.insert(elements, {label = _U(v) .. ' #' .. #owned, value = v})
				NoVeh = false
			end
		end, 'civ', v, garageName)
	end
	Citizen.Wait(250)

	if NoVeh then
		ESX.ShowNotification(_U('garage_no', _U('large_trucks')))
	else
		ESX.UI.Menu.CloseAll()
		ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'truckgaragemenu', {
			title = _U('garage_menu'),
			align = GetConvar('esx_MenuAlign', 'top-left'),
			elements = elements
		}, function(data, menu)
			local action = data.current.value
			local elements = {head = {_U('veh_plate'), _U('veh_name'), _U('veh_loc'), _U('actions')}, rows = {}}

			for _,v in pairs(ownedVehicles[action]) do
				local vehStored = _U('veh_loc_unknown')
				if v.stored then
					vehStored = _U('veh_loc_garage')
				else
					vehStored = _U('veh_loc_impound')
				end

				table.insert(elements.rows, {data = v, cols = {v.plate, v.vehName, vehStored, '{{' .. _U('spawn') .. '|spawn}} {{' .. _U('rename') .. '|rename}}'}})
			end

			ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'owned_vehicles_list', elements, function(data2, menu2)
				local vehVehicle, vehPlate, vehStored, vehFuel = data2.data.vehicle, data2.data.plate, data2.data.stored, data2.data.fuel
				if data2.value == 'spawn' then
					if vehStored then
						SpawnVehicle(vehVehicle, vehPlate, vehFuel)
						ESX.UI.Menu.CloseAll()
					else
						ESX.ShowNotification(_U('veh_not_here'))
					end
				elseif data2.value == 'rename' then
					if Config.Main.RenameVehs then
						ESX.UI.Menu.Open('dialog', GetCurrentResourceName(), 'renamevehicle', {
							title = _U('veh_rename', Config.Main.RenameMin, Config.Main.RenameMax - 1)
						}, function(data3, menu3)
							if string.len(data3.value) >= Config.Main.RenameMin and string.len(data3.value) < Config.Main.RenameMax then
								TriggerServerEvent('esx_advancedgarage:renameVehicle', vehPlate, data3.value)
								ESX.UI.Menu.CloseAll()
							else
								ESX.ShowNotification(_U('veh_rename_empty', Config.Main.RenameMin, Config.Main.RenameMax - 1))
							end
						end, function(data3, menu3)
							menu3.close()
						end)
					else
						ESX.ShowNotification(_U('veh_rename_no'))
					end
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end, function(data, menu)
			menu.close()
		end)
	end
end

function OpenCarImpoundMenu()
	local elements = {head = {_U('veh_plate'), _U('veh_name'), _U('impound_fee'), _U('actions')}, rows = {}}
	ESX.TriggerServerCallback('esx_advancedgarage:getOutOwnedVehicles', function(outCivCars)
		if #outCivCars == 0 then
			ESX.ShowNotification(_U('impound_no'))
		else
			for _,v in pairs(outCivCars) do
				table.insert(elements.rows, {data = v, cols = {v.plate, v.vehName, _U('impound_fee_value', ESX.Math.GroupDigits(Config.Cars.PoundP)), '{{' .. _U('return') .. '|return}}'}})
			end

			ESX.UI.Menu.Open('list', GetCurrentResourceName(), 'out_owned_vehicles_list', elements, function(data2, menu2)
				local vehVehicle, vehPlate, vehFuel = data2.data.vehicle, data2.data.plate, data2.data.fuel
				local doesVehicleExist = false

				if data2.value == 'return' then
					for k,v in pairs (vehInstance) do
						if ESX.Math.Trim(v.plate) == ESX.Math.Trim(vehPlate) then
							if DoesEntityExist(v.vehicleentity) then
								doesVehicleExist = true
							else
								table.remove(vehInstance, k)
								doesVehicleExist = false
							end
						end
					end

					if not doesVehicleExist and not DoesAPlayerDrivesVehicle(vehPlate) then
						ESX.TriggerServerCallback('esx_advancedgarage:payImpound', function(hasEnoughMoney)
							if hasEnoughMoney then
								ESX.TriggerServerCallback('esx_advancedgarage:payImpound', function()
									SpawnVehicle(vehVehicle, vehPlate, vehFuel)
									ESX.UI.Menu.CloseAll()
								end, 'civ', 'cars', 'pay')
							else
								ESX.ShowNotification(_U('not_enough_money'))
							end
						end, 'civ', 'cars', 'check')
					else
						ESX.ShowNotification(_U('veh_out_world'))
					end
				end
			end, function(data2, menu2)
				menu2.close()
			end)
		end
	end, 'civ', 'cars')
end

function StoreOwnedCarMenu()
	local playerPed  = GetPlayerPed(-1)

	if IsPedInAnyVehicle(playerPed,  false) then
		local playerPed = GetPlayerPed(-1)
		local coords = GetEntityCoords(playerPed)
		local vehicle = GetVehiclePedIsIn(playerPed, false)
		local vehicleProps = ESX.Game.GetVehicleProperties(vehicle)
		local current = GetPlayersLastVehicle(GetPlayerPed(-1), true)
		local engineHealth = GetVehicleEngineHealth(current)
		local plate = vehicleProps.plate

		ESX.TriggerServerCallback('esx_advancedgarage:storeVehicle', function(valid)
			if valid then
				if engineHealth < 990 then
					if Config.Main.DamageMult then
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Cars.PoundP*Config.Main.MultAmount)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					else
						local apprasial = math.floor((1000 - engineHealth)/1000*Config.Cars.PoundP)
						RepairVehicle(apprasial, vehicle, vehicleProps)
					end
				else
					StoreVehicle(vehicle, vehicleProps)
				end	
			else
				ESX.ShowNotification(_U('cannot_store_vehicle'))
			end
		end, vehicleProps, garageName)
	else
		ESX.ShowNotification(_U('no_vehicle_to_enter'))
	end
end
-- End of Car Code

-- Repair Vehicles
function RepairVehicle(apprasial, vehicle, vehicleProps)
	ESX.UI.Menu.CloseAll()
	ESX.UI.Menu.Open('default', GetCurrentResourceName(), 'delete_menu', {
		title = _U('damaged_vehicle'),
		align = GetConvar('esx_MenuAlign', 'top-left'),
		elements = {
			{label = _U('return_vehicle', apprasial), value = 'yes'},
			{label = _U('see_mechanic'), value = 'no'}
	}}, function(data, menu)
		menu.close()

		if data.current.value == 'yes' then
			TriggerServerEvent('esx_advancedgarage:payhealth', apprasial)
			vehicleProps.bodyHealth = 1000.0 -- must be a decimal value!!!
			vehicleProps.engineHealth = 1000
			StoreVehicle(vehicle, vehicleProps)
		elseif data.current.value == 'no' then
			ESX.ShowNotification(_U('visit_mechanic'))
		end
	end, function(data, menu)
		menu.close()
	end)
end

-- Store Vehicles
function StoreVehicle(vehicle, vehicleProps)
	for k,v in pairs (vehInstance) do
		if ESX.Math.Trim(v.plate) == ESX.Math.Trim(vehicleProps.plate) then
			table.remove(vehInstance, k)
		end
	end

	if Config.Main.LegacyFuel then
		currentFuel = exports['LegacyFuel']:GetFuel(vehicle)
	else
		currentFuel = GetVehicleFuelLevel(vehicle)
	end
	TriggerServerEvent('esx_advancedgarage:setVehicleFuel', vehicleProps.plate, currentFuel)

	DeleteEntity(vehicle)
	TriggerServerEvent('esx_advancedgarage:setVehicleState', vehicleProps.plate, true)
	ESX.ShowNotification(_U('vehicle_in_garage'))
end

-- Spawn Vehicles
function SpawnVehicle(vehicle, plate, fuel)
	ESX.Game.SpawnVehicle(vehicle.model, this_Garage.Spawner, this_Garage.Heading, function(callback_vehicle)
		ESX.Game.SetVehicleProperties(callback_vehicle, vehicle)
		SetVehRadioStation(callback_vehicle, "OFF")
		SetVehicleFixed(callback_vehicle)
		SetVehicleDeformationFixed(callback_vehicle)
		SetVehicleUndriveable(callback_vehicle, false)
		SetVehicleEngineOn(callback_vehicle, true, true)
		--SetVehicleEngineHealth(callback_vehicle, 1000) -- Might not be needed
		--SetVehicleBodyHealth(callback_vehicle, 1000) -- Might not be needed
		local carplate = GetVehicleNumberPlateText(callback_vehicle)
		table.insert(vehInstance, {vehicleentity = callback_vehicle, plate = carplate})
		if Config.Main.LegacyFuel then
			exports['LegacyFuel']:SetFuel(callback_vehicle, fuel)
		else
			SetVehicleFuelLevel(callback_vehicle, fuel + 0.0)
		end
		TaskWarpPedIntoVehicle(GetPlayerPed(-1), callback_vehicle, -1)
	end)

	TriggerServerEvent('esx_advancedgarage:setVehicleState', plate, false)
end

function SpawnVehicle2(vehicle, plate, fuel)
	ESX.Game.SpawnVehicle(vehicle.model, this_Garage.Spawner2, this_Garage.Heading2, function(callback_vehicle)
		ESX.Game.SetVehicleProperties(callback_vehicle, vehicle)
		SetVehRadioStation(callback_vehicle, "OFF")
		SetVehicleFixed(callback_vehicle)
		SetVehicleDeformationFixed(callback_vehicle)
		SetVehicleUndriveable(callback_vehicle, false)
		SetVehicleEngineOn(callback_vehicle, true, true)
		--SetVehicleEngineHealth(callback_vehicle, 1000) -- Might not be needed
		--SetVehicleBodyHealth(callback_vehicle, 1000) -- Might not be needed
		local carplate = GetVehicleNumberPlateText(callback_vehicle)
		table.insert(vehInstance, {vehicleentity = callback_vehicle, plate = carplate})
		if Config.Main.LegacyFuel then
			exports['LegacyFuel']:SetFuel(callback_vehicle, fuel)
		else
			SetVehicleFuelLevel(callback_vehicle, fuel + 0.0)
		end
		TaskWarpPedIntoVehicle(GetPlayerPed(-1), callback_vehicle, -1)
	end)

	TriggerServerEvent('esx_advancedgarage:setVehicleState', plate, false)
end

-- Check Vehicles
function DoesAPlayerDrivesVehicle(plate)
	local isVehicleTaken = false
	local players = ESX.Game.GetPlayers()
	for i=1, #players, 1 do
		local target = GetPlayerPed(players[i])
		if target ~= PlayerPedId() then
			local plate1 = GetVehicleNumberPlateText(GetVehiclePedIsIn(target, true))
			local plate2 = GetVehicleNumberPlateText(GetVehiclePedIsIn(target, false))
			if plate == plate1 or plate == plate2 then
				isVehicleTaken = true
				break
			end
		end
	end
	return isVehicleTaken
end

-- Entered Marker
AddEventHandler('esx_advancedgarage:hasEnteredMarker', function(zone)
	if zone == 'ambulance_garage_point' then
		CurrentAction = 'ambulance_garage_point'
		CurrentActionMsg = _U('press_to_enter')
		CurrentActionData = {}
	elseif zone == 'ambulance_store_point' then
		CurrentAction = 'ambulance_store_point'
		CurrentActionMsg = _U('press_to_delete')
		CurrentActionData = {}
	elseif zone == 'ambulance_pound_point' then
		CurrentAction = 'ambulance_pound_point'
		CurrentActionMsg = _U('press_to_impound')
		CurrentActionData = {}
	elseif zone == 'police_garage_point' then
		CurrentAction = 'police_garage_point'
		CurrentActionMsg = _U('press_to_enter')
		CurrentActionData = {}
	elseif zone == 'police_store_point' then
		CurrentAction = 'police_store_point'
		CurrentActionMsg = _U('press_to_delete')
		CurrentActionData = {}
	elseif zone == 'police_pound_point' then
		CurrentAction = 'police_pound_point'
		CurrentActionMsg = _U('press_to_impound')
		CurrentActionData = {}
	elseif zone == 'mechanic_garage_point' then
		CurrentAction = 'mechanic_garage_point'
		CurrentActionMsg = _U('press_to_enter')
		CurrentActionData = {}
	elseif zone == 'mechanic_store_point' then
		CurrentAction = 'mechanic_store_point'
		CurrentActionMsg = _U('press_to_delete')
		CurrentActionData = {}
	elseif zone == 'mechanic_pound_point' then
		CurrentAction = 'mechanic_pound_point'
		CurrentActionMsg = _U('press_to_impound')
		CurrentActionData = {}
	elseif zone == 'aircraft_garage_point' then
		CurrentAction = 'aircraft_garage_point'
		CurrentActionMsg = _U('press_to_enter')
		CurrentActionData = {}
	elseif zone == 'aircraft_store_point' then
		CurrentAction = 'aircraft_store_point'
		CurrentActionMsg = _U('press_to_delete')
		CurrentActionData = {}
	elseif zone == 'aircraft_pound_point' then
		CurrentAction = 'aircraft_pound_point'
		CurrentActionMsg = _U('press_to_impound')
		CurrentActionData = {}
	elseif zone == 'boat_garage_point' then
		CurrentAction = 'boat_garage_point'
		CurrentActionMsg = _U('press_to_enter')
		CurrentActionData = {}
	elseif zone == 'boat_store_point' then
		CurrentAction = 'boat_store_point'
		CurrentActionMsg = _U('press_to_delete')
		CurrentActionData = {}
	elseif zone == 'boat_pound_point' then
		CurrentAction = 'boat_pound_point'
		CurrentActionMsg = _U('press_to_impound')
		CurrentActionData = {}
	elseif zone == 'car_garage_point' then
		CurrentAction = 'car_garage_point'
		CurrentActionMsg = _U('press_to_enter')
		CurrentActionData = {}
	elseif zone == 'car_store_point' then
		CurrentAction = 'car_store_point'
		CurrentActionMsg = _U('press_to_delete')
		CurrentActionData = {}
	elseif zone == 'car_pound_point' then
		CurrentAction = 'car_pound_point'
		CurrentActionMsg = _U('press_to_impound')
		CurrentActionData = {}
	end
end)

-- Exited Marker
AddEventHandler('esx_advancedgarage:hasExitedMarker', function()
	ESX.UI.Menu.CloseAll()
	CurrentAction = nil
end)

-- Resource Stop
AddEventHandler('onResourceStop', function(resource)
	if resource == GetCurrentResourceName() then
		ESX.UI.Menu.CloseAll()
	end
end)

-- Enter / Exit marker events & Draw Markers
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerCoords = GetEntityCoords(PlayerPedId())
		local isInMarker, letSleep, currentZone = false, true

		if Config.Ambulance.Garages then
			if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
				for k,v in pairs(Config.AmbulanceGarages) do
					local distance = #(playerCoords - v.Marker)
					local distance2 = #(playerCoords - v.Deleter)
					local distance3 = #(playerCoords - v.Deleter2)

					if distance < Config.Main.DrawDistance then
						letSleep = false

						if Config.Ambulance.Markers.Points.Type ~= -1 then
							DrawMarker(Config.Ambulance.Markers.Points.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Ambulance.Markers.Points.x, Config.Ambulance.Markers.Points.y, Config.Ambulance.Markers.Points.z, Config.Ambulance.Markers.Points.r, Config.Ambulance.Markers.Points.g, Config.Ambulance.Markers.Points.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance < Config.Ambulance.Markers.Points.x then
							garageName, isInMarker, this_Garage, currentZone = k, true, v, 'ambulance_garage_point'
						end
					end

					if distance2 < Config.Main.DrawDistance then
						letSleep = false

						if Config.Ambulance.Markers.Delete.Type ~= -1 then
							DrawMarker(Config.Ambulance.Markers.Delete.Type, v.Deleter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Ambulance.Markers.Delete.x, Config.Ambulance.Markers.Delete.y, Config.Ambulance.Markers.Delete.z, Config.Ambulance.Markers.Delete.r, Config.Ambulance.Markers.Delete.g, Config.Ambulance.Markers.Delete.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance2 < Config.Ambulance.Markers.Delete.x then
							garageName, isInMarker, this_Garage, currentZone = k, true, v, 'ambulance_store_point'
						end
					end

					if distance3 < Config.Main.DrawDistance then
						letSleep = false

						if Config.Ambulance.Markers.Delete.Type ~= -1 then
							DrawMarker(Config.Ambulance.Markers.Delete.Type, v.Deleter2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Ambulance.Markers.Delete.x, Config.Ambulance.Markers.Delete.y, Config.Ambulance.Markers.Delete.z, Config.Ambulance.Markers.Delete.r, Config.Ambulance.Markers.Delete.g, Config.Ambulance.Markers.Delete.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance3 < Config.Ambulance.Markers.Delete.x then
							garageName, isInMarker, this_Garage, currentZone = k, true, v, 'ambulance_store_point'
						end
					end
				end
			end
		end

		if Config.Ambulance.Pounds then
			if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
				for k,v in pairs(Config.AmbulancePounds) do
					local distance = #(playerCoords - v.Marker)

					if distance < Config.Main.DrawDistance then
						letSleep = false

						if Config.Ambulance.Markers.Pounds.Type ~= -1 then
							DrawMarker(Config.Ambulance.Markers.Pounds.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Ambulance.Markers.Pounds.x, Config.Ambulance.Markers.Pounds.y, Config.Ambulance.Markers.Pounds.z, Config.Ambulance.Markers.Pounds.r, Config.Ambulance.Markers.Pounds.g, Config.Ambulance.Markers.Pounds.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance < Config.Ambulance.Markers.Pounds.x then
							garageName, isInMarker, this_Garage, currentZone = k, true, v, 'ambulance_pound_point'
						end
					end
				end
			end
		end

		if Config.Police.Garages then
			if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
				for k,v in pairs(Config.PoliceGarages) do
					local distance = #(playerCoords - v.Marker)
					local distance2 = #(playerCoords - v.Deleter)
					local distance3 = #(playerCoords - v.Deleter2)

					if distance < Config.Main.DrawDistance then
						letSleep = false

						if Config.Police.Markers.Points.Type ~= -1 then
							DrawMarker(Config.Police.Markers.Points.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Police.Markers.Points.x, Config.Police.Markers.Points.y, Config.Police.Markers.Points.z, Config.Police.Markers.Points.r, Config.Police.Markers.Points.g, Config.Police.Markers.Points.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance < Config.Police.Markers.Points.x then
							garageName, isInMarker, this_Garage, currentZone = k, true, v, 'police_garage_point'
						end
					end

					if distance2 < Config.Main.DrawDistance then
						letSleep = false

						if Config.Police.Markers.Delete.Type ~= -1 then
							DrawMarker(Config.Police.Markers.Delete.Type, v.Deleter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Police.Markers.Delete.x, Config.Police.Markers.Delete.y, Config.Police.Markers.Delete.z, Config.Police.Markers.Delete.r, Config.Police.Markers.Delete.g, Config.Police.Markers.Delete.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance2 < Config.Police.Markers.Delete.x then
							garageName, isInMarker, this_Garage, currentZone = k, true, v, 'police_store_point'
						end
					end

					if distance3 < Config.Main.DrawDistance then
						letSleep = false

						if Config.Police.Markers.Delete.Type ~= -1 then
							DrawMarker(Config.Police.Markers.Delete.Type, v.Deleter2, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Police.Markers.Delete.x, Config.Police.Markers.Delete.y, Config.Police.Markers.Delete.z, Config.Police.Markers.Delete.r, Config.Police.Markers.Delete.g, Config.Police.Markers.Delete.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance3 < Config.Police.Markers.Delete.x then
							garageName, isInMarker, this_Garage, currentZone = k, true, v, 'police_store_point'
						end
					end
				end
			end
		end

		if Config.Police.Pounds then
			if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
				for k,v in pairs(Config.PolicePounds) do
					local distance = #(playerCoords - v.Marker)

					if distance < Config.Main.DrawDistance then
						letSleep = false

						if Config.Police.Markers.Pounds.Type ~= -1 then
							DrawMarker(Config.Police.Markers.Pounds.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Police.Markers.Pounds.x, Config.Police.Markers.Pounds.y, Config.Police.Markers.Pounds.z, Config.Police.Markers.Pounds.r, Config.Police.Markers.Pounds.g, Config.Police.Markers.Pounds.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance < Config.Police.Markers.Pounds.x then
							garageName, isInMarker, this_Garage, currentZone = k, true, v, 'police_pound_point'
						end
					end
				end
			end
		end

		if Config.Mechanic.Garages then
			if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
				for k,v in pairs(Config.MechanicGarages) do
					local distance = #(playerCoords - v.Marker)
					local distance2 = #(playerCoords - v.Deleter)

					if distance < Config.Main.DrawDistance then
						letSleep = false

						if Config.Mechanic.Markers.Points.Type ~= -1 then
							DrawMarker(Config.Mechanic.Markers.Points.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Mechanic.Markers.Points.x, Config.Mechanic.Markers.Points.y, Config.Mechanic.Markers.Points.z, Config.Mechanic.Markers.Points.r, Config.Mechanic.Markers.Points.g, Config.Mechanic.Markers.Points.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance < Config.Mechanic.Markers.Points.x then
							garageName, isInMarker, this_Garage, currentZone = k, true, v, 'mechanic_garage_point'
						end
					end

					if distance2 < Config.Main.DrawDistance then
						letSleep = false

						if Config.Mechanic.Markers.Delete.Type ~= -1 then
							DrawMarker(Config.Mechanic.Markers.Delete.Type, v.Deleter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Mechanic.Markers.Delete.x, Config.Mechanic.Markers.Delete.y, Config.Mechanic.Markers.Delete.z, Config.Mechanic.Markers.Delete.r, Config.Mechanic.Markers.Delete.g, Config.Mechanic.Markers.Delete.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance2 < Config.Mechanic.Markers.Delete.x then
							garageName, isInMarker, this_Garage, currentZone = k, true, v, 'mechanic_store_point'
						end
					end
				end
			end
		end

		if Config.Mechanic.Pounds then
			if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
				for k,v in pairs(Config.MechanicPounds) do
					local distance = #(playerCoords - v.Marker)

					if distance < Config.Main.DrawDistance then
						letSleep = false

						if Config.Mechanic.Markers.Pounds.Type ~= -1 then
							DrawMarker(Config.Mechanic.Markers.Pounds.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Mechanic.Markers.Pounds.x, Config.Mechanic.Markers.Pounds.y, Config.Mechanic.Markers.Pounds.z, Config.Mechanic.Markers.Pounds.r, Config.Mechanic.Markers.Pounds.g, Config.Mechanic.Markers.Pounds.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance < Config.Mechanic.Markers.Pounds.x then
							garageName, isInMarker, this_Garage, currentZone = k, true, v, 'mechanic_pound_point'
						end
					end
				end
			end
		end

		if Config.Aircrafts.Garages then
			for k,v in pairs(Config.AircraftGarages) do
				local distance = #(playerCoords - v.Marker)
				local distance2 = #(playerCoords - v.Deleter)

				if distance < Config.Main.DrawDistance then
					letSleep = false

					if Config.Aircrafts.Markers.Points.Type ~= -1 then
						DrawMarker(Config.Aircrafts.Markers.Points.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Aircrafts.Markers.Points.x, Config.Aircrafts.Markers.Points.y, Config.Aircrafts.Markers.Points.z, Config.Aircrafts.Markers.Points.r, Config.Aircrafts.Markers.Points.g, Config.Aircrafts.Markers.Points.b, 100, false, true, 2, false, nil, nil, false)
					end

					if distance < Config.Aircrafts.Markers.Points.x then
						garageName, isInMarker, this_Garage, currentZone = k, true, v, 'aircraft_garage_point'
					end
				end

				if distance2 < Config.Main.DrawDistance then
					letSleep = false

					if Config.Aircrafts.Markers.Delete.Type ~= -1 then
						DrawMarker(Config.Aircrafts.Markers.Delete.Type, v.Deleter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Aircrafts.Markers.Delete.x, Config.Aircrafts.Markers.Delete.y, Config.Aircrafts.Markers.Delete.z, Config.Aircrafts.Markers.Delete.r, Config.Aircrafts.Markers.Delete.g, Config.Aircrafts.Markers.Delete.b, 100, false, true, 2, false, nil, nil, false)
					end

					if distance2 < Config.Aircrafts.Markers.Delete.x then
						garageName, isInMarker, this_Garage, currentZone = k, true, v, 'aircraft_store_point'
					end
				end
			end

			for k,v in pairs(Config.AircraftPounds) do
				local distance = #(playerCoords - v.Marker)

				if distance < Config.Main.DrawDistance then
					letSleep = false

					if Config.Aircrafts.Markers.Pounds.Type ~= -1 then
						DrawMarker(Config.Aircrafts.Markers.Pounds.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Aircrafts.Markers.Pounds.x, Config.Aircrafts.Markers.Pounds.y, Config.Aircrafts.Markers.Pounds.z, Config.Aircrafts.Markers.Pounds.r, Config.Aircrafts.Markers.Pounds.g, Config.Aircrafts.Markers.Pounds.b, 100, false, true, 2, false, nil, nil, false)
					end

					if distance < Config.Aircrafts.Markers.Pounds.x then
						garageName, isInMarker, this_Garage, currentZone = k, true, v, 'aircraft_pound_point'
					end
				end
			end
		end

		if Config.Boats.Garages then
			for k,v in pairs(Config.BoatGarages) do
				local distance = #(playerCoords - v.Marker)
				local distance2 = #(playerCoords - v.Deleter)

				if distance < Config.Main.DrawDistance then
					letSleep = false

					if Config.Boats.Markers.Points.Type ~= -1 then
						DrawMarker(Config.Boats.Markers.Points.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Boats.Markers.Points.x, Config.Boats.Markers.Points.y, Config.Boats.Markers.Points.z, Config.Boats.Markers.Points.r, Config.Boats.Markers.Points.g, Config.Boats.Markers.Points.b, 100, false, true, 2, false, nil, nil, false)
					end

					if distance < Config.Boats.Markers.Points.x then
						garageName, isInMarker, this_Garage, currentZone = k, true, v, 'boat_garage_point'
					end
				end

				if distance2 < Config.Main.DrawDistance then
					letSleep = false

					if Config.Boats.Markers.Delete.Type ~= -1 then
						DrawMarker(Config.Boats.Markers.Delete.Type, v.Deleter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Boats.Markers.Delete.x, Config.Boats.Markers.Delete.y, Config.Boats.Markers.Delete.z, Config.Boats.Markers.Delete.r, Config.Boats.Markers.Delete.g, Config.Boats.Markers.Delete.b, 100, false, true, 2, false, nil, nil, false)
					end

					if distance2 < Config.Boats.Markers.Delete.x then
						garageName, isInMarker, this_Garage, currentZone = k, true, v, 'boat_store_point'
					end
				end
			end

			for k,v in pairs(Config.BoatPounds) do
				local distance = #(playerCoords - v.Marker)

				if distance < Config.Main.DrawDistance then
					letSleep = false

					if Config.Boats.Markers.Pounds.Type ~= -1 then
						DrawMarker(Config.Boats.Markers.Pounds.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Boats.Markers.Pounds.x, Config.Boats.Markers.Pounds.y, Config.Boats.Markers.Pounds.z, Config.Boats.Markers.Pounds.r, Config.Boats.Markers.Pounds.g, Config.Boats.Markers.Pounds.b, 100, false, true, 2, false, nil, nil, false)
					end

					if distance < Config.Boats.Markers.Pounds.x then
						garageName, isInMarker, this_Garage, currentZone = k, true, v, 'boat_pound_point'
					end
				end
			end
		end

		if Config.Cars.Garages then
			for k,v in pairs(Config.CarGarages) do
				local distance = #(playerCoords - v.Marker)
				local distance2 = #(playerCoords - v.Deleter)

				if distance < Config.Main.DrawDistance then
					letSleep = false

					if Config.Cars.Markers.Points.Type ~= -1 then
						DrawMarker(Config.Cars.Markers.Points.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Cars.Markers.Points.x, Config.Cars.Markers.Points.y, Config.Cars.Markers.Points.z, Config.Cars.Markers.Points.r, Config.Cars.Markers.Points.g, Config.Cars.Markers.Points.b, 100, false, true, 2, false, nil, nil, false)
					end

					if distance < Config.Cars.Markers.Points.x then
						garageName, isInMarker, this_Garage, currentZone = k, true, v, 'car_garage_point'
					end
				end

				if distance2 < Config.Main.DrawDistance then
					letSleep = false

					if Config.Cars.Markers.Delete.Type ~= -1 then
						DrawMarker(Config.Cars.Markers.Delete.Type, v.Deleter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Cars.Markers.Delete.x, Config.Cars.Markers.Delete.y, Config.Cars.Markers.Delete.z, Config.Cars.Markers.Delete.r, Config.Cars.Markers.Delete.g, Config.Cars.Markers.Delete.b, 100, false, true, 2, false, nil, nil, false)
					end

					if distance2 < Config.Cars.Markers.Delete.x then
						garageName, isInMarker, this_Garage, currentZone = k, true, v, 'car_store_point'
					end
				end
			end

			for k,v in pairs(Config.CarPounds) do
				local distance = #(playerCoords - v.Marker)

				if distance < Config.Main.DrawDistance then
					letSleep = false

					if Config.Cars.Markers.Pounds.Type ~= -1 then
						DrawMarker(Config.Cars.Markers.Pounds.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Cars.Markers.Pounds.x, Config.Cars.Markers.Pounds.y, Config.Cars.Markers.Pounds.z, Config.Cars.Markers.Pounds.r, Config.Cars.Markers.Pounds.g, Config.Cars.Markers.Pounds.b, 100, false, true, 2, false, nil, nil, false)
					end

					if distance < Config.Cars.Markers.Pounds.x then
						garageName, isInMarker, this_Garage, currentZone = k, true, v, 'car_pound_point'
					end
				end
			end
		end

		if Config.Pvt.Garages then
			for k,v in pairs(Config.PrivateCarGarages) do
				if not v.Private or has_value(userProperties, v.Private) then
					local distance = #(playerCoords - v.Marker)
					local distance2 = #(playerCoords - v.Deleter)

					if distance < Config.Main.DrawDistance then
						letSleep = false

						if Config.Pvt.Markers.Points.Type ~= -1 then
							DrawMarker(Config.Pvt.Markers.Points.Type, v.Marker, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Pvt.Markers.Points.x, Config.Pvt.Markers.Points.y, Config.Pvt.Markers.Points.z, Config.Pvt.Markers.Points.r, Config.Pvt.Markers.Points.g, Config.Pvt.Markers.Points.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance < Config.Pvt.Markers.Points.x then
							garageName, isInMarker, this_Garage, currentZone = k, true, v, 'car_garage_point'
						end
					end

					if distance2 < Config.Main.DrawDistance then
						letSleep = false

						if Config.Pvt.Markers.Delete.Type ~= -1 then
							DrawMarker(Config.Pvt.Markers.Delete.Type, v.Deleter, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, Config.Pvt.Markers.Delete.x, Config.Pvt.Markers.Delete.y, Config.Pvt.Markers.Delete.z, Config.Pvt.Markers.Delete.r, Config.Pvt.Markers.Delete.g, Config.Pvt.Markers.Delete.b, 100, false, true, 2, false, nil, nil, false)
						end

						if distance2 < Config.Pvt.Markers.Delete.x then
							garageName, isInMarker, this_Garage, currentZone = k, true, v, 'car_store_point'
						end
					end
				end
			end
		end

		if (isInMarker and not HasAlreadyEnteredMarker) or (isInMarker and LastZone ~= currentZone) then
			HasAlreadyEnteredMarker, LastZone = true, currentZone
			LastZone = currentZone
			TriggerEvent('esx_advancedgarage:hasEnteredMarker', currentZone)
		end

		if not isInMarker and HasAlreadyEnteredMarker then
			HasAlreadyEnteredMarker = false
			TriggerEvent('esx_advancedgarage:hasExitedMarker', LastZone)
		end

		if letSleep then
			Citizen.Wait(500)
		end
	end
end)

-- Key Controls
Citizen.CreateThread(function()
	while true do
		Citizen.Wait(0)
		local playerPed = GetPlayerPed(-1)
		local playerVeh = GetVehiclePedIsIn(playerPed, false)
		local model = GetEntityModel(playerVeh)

		if CurrentAction then
			ESX.ShowHelpNotification(CurrentActionMsg)

			if IsControlJustReleased(0, 38) then
				if CurrentAction == 'ambulance_garage_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
						if not IsPedSittingInAnyVehicle(PlayerPedId()) then
							OpenJobGarageMenu(ESX.PlayerData.job.name)
						else
							ESX.ShowNotification(_U('cant_in_veh'))
						end
					else
						ESX.ShowNotification(_U('must_ambulance'))
					end
				elseif CurrentAction == 'ambulance_store_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
						if IsThisModelACar(model) or IsThisModelABicycle(model) or IsThisModelABike(model) or IsThisModelAHeli(model) then
							if (GetPedInVehicleSeat(playerVeh, -1) == playerPed) then
								StoreOwnedJobMenu(ESX.PlayerData.job.name)
							else
								ESX.ShowNotification(_U('driver_seat'))
							end
						else
							ESX.ShowNotification(_U('not_correct_veh'))
						end
					else
						ESX.ShowNotification(_U('must_ambulance'))
					end
				elseif CurrentAction == 'ambulance_pound_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
						if not IsPedSittingInAnyVehicle(PlayerPedId()) then
							OpenJobImpoundMenu(ESX.PlayerData.job.name)
						else
							ESX.ShowNotification(_U('cant_in_veh'))
						end
					else
						ESX.ShowNotification(_U('must_ambulance'))
					end
				elseif CurrentAction == 'police_garage_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
						if not IsPedSittingInAnyVehicle(PlayerPedId()) then
							OpenJobGarageMenu(ESX.PlayerData.job.name)
						else
							ESX.ShowNotification(_U('cant_in_veh'))
						end
					else
						ESX.ShowNotification(_U('must_police'))
					end
				elseif CurrentAction == 'police_store_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
						if IsThisModelACar(model) or IsThisModelABicycle(model) or IsThisModelABike(model) or IsThisModelAHeli(model) then
							if (GetPedInVehicleSeat(playerVeh, -1) == playerPed) then
								StoreOwnedJobMenu(ESX.PlayerData.job.name)
							else
								ESX.ShowNotification(_U('driver_seat'))
							end
						else
							ESX.ShowNotification(_U('not_correct_veh'))
						end
					else
						ESX.ShowNotification(_U('must_police'))
					end
				elseif CurrentAction == 'police_pound_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
						if not IsPedSittingInAnyVehicle(PlayerPedId()) then
							OpenJobImpoundMenu(ESX.PlayerData.job.name)
						else
							ESX.ShowNotification(_U('cant_in_veh'))
						end
					else
						ESX.ShowNotification(_U('must_police'))
					end
				elseif CurrentAction == 'mechanic_garage_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
						if not IsPedSittingInAnyVehicle(PlayerPedId()) then
							OpenJobGarageMenu(ESX.PlayerData.job.name)
						else
							ESX.ShowNotification(_U('cant_in_veh'))
						end
					else
						ESX.ShowNotification(_U('must_mechanic'))
					end
				elseif CurrentAction == 'mechanic_store_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
						if IsThisModelACar(model) or IsThisModelABicycle(model) or IsThisModelABike(model) or IsThisModelAHeli(model) then
							if (GetPedInVehicleSeat(playerVeh, -1) == playerPed) then
								StoreOwnedJobMenu(ESX.PlayerData.job.name)
							else
								ESX.ShowNotification(_U('driver_seat'))
							end
						else
							ESX.ShowNotification(_U('not_correct_veh'))
						end
					else
						ESX.ShowNotification(_U('must_mechanic'))
					end
				elseif CurrentAction == 'mechanic_pound_point' then
					if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
						if not IsPedSittingInAnyVehicle(PlayerPedId()) then
							OpenJobImpoundMenu(ESX.PlayerData.job.name)
						else
							ESX.ShowNotification(_U('cant_in_veh'))
						end
					else
						ESX.ShowNotification(_U('must_mechanic'))
					end
				elseif CurrentAction == 'aircraft_garage_point' then
					if not IsPedSittingInAnyVehicle(PlayerPedId()) then
						OpenAircraftGarageMenu()
					else
						ESX.ShowNotification(_U('cant_in_veh'))
					end
				elseif CurrentAction == 'aircraft_store_point' then
					if IsThisModelAHeli(model) or IsThisModelAPlane(model) then
						if (GetPedInVehicleSeat(playerVeh, -1) == playerPed) then
							StoreOwnedAircraftMenu()
						else
							ESX.ShowNotification(_U('driver_seat'))
						end
					else
						ESX.ShowNotification(_U('not_correct_veh'))
					end
				elseif CurrentAction == 'aircraft_pound_point' then
					if not IsPedSittingInAnyVehicle(PlayerPedId()) then
						OpenAircraftImpoundMenu()
					else
						ESX.ShowNotification(_U('cant_in_veh'))
					end
				elseif CurrentAction == 'boat_garage_point' then
					if not IsPedSittingInAnyVehicle(PlayerPedId()) then
						OpenBoatGarageMenu()
					else
						ESX.ShowNotification(_U('cant_in_veh'))
					end
				elseif CurrentAction == 'boat_store_point' then
					if (GetPedInVehicleSeat(playerVeh, -1) == playerPed) then
						StoreOwnedBoatMenu()
					else
						ESX.ShowNotification(_U('driver_seat'))
					end
				elseif CurrentAction == 'boat_pound_point' then
					if not IsPedSittingInAnyVehicle(PlayerPedId()) then
						OpenBoatImpoundMenu()
					else
						ESX.ShowNotification(_U('cant_in_veh'))
					end
				elseif CurrentAction == 'car_garage_point' then
					if not IsPedSittingInAnyVehicle(PlayerPedId()) then
						OpenCarGarageMenu()
					else
						ESX.ShowNotification(_U('cant_in_veh'))
					end
				elseif CurrentAction == 'car_store_point' then
					if IsThisModelACar(model) or IsThisModelABicycle(model) or IsThisModelABike(model) or IsThisModelAQuadbike(model) then
						if (GetPedInVehicleSeat(playerVeh, -1) == playerPed) then
							StoreOwnedCarMenu()
						else
							ESX.ShowNotification(_U('driver_seat'))
						end
					else
						ESX.ShowNotification(_U('not_correct_veh'))
					end
				elseif CurrentAction == 'car_pound_point' then
					if not IsPedSittingInAnyVehicle(PlayerPedId()) then
						OpenCarImpoundMenu()
					else
						ESX.ShowNotification(_U('cant_in_veh'))
					end
				end

				CurrentAction = nil
			end
		else
			Citizen.Wait(500)
		end
	end
end)

-- Create Blips
function CreateBlips()
	if Config.Aircrafts.Garages and Config.Aircrafts.Blips then
		for k,v in pairs(Config.AircraftGarages) do
			local blip = AddBlipForCoord(v.Marker)

			SetBlipSprite (blip, Config.Blips.Garages.Sprite)
			SetBlipColour (blip, Config.Blips.Garages.Color)
			SetBlipDisplay(blip, Config.Blips.Garages.Display)
			SetBlipScale  (blip, Config.Blips.Garages.Scale)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('blip_garage'))
			EndTextCommandSetBlipName(blip)
			table.insert(BlipList, blip)
		end

		for k,v in pairs(Config.AircraftPounds) do
			local blip = AddBlipForCoord(v.Marker)

			SetBlipSprite (blip, Config.Blips.Pounds.Sprite)
			SetBlipColour (blip, Config.Blips.Pounds.Color)
			SetBlipDisplay(blip, Config.Blips.Pounds.Display)
			SetBlipScale  (blip, Config.Blips.Pounds.Scale)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('blip_pound'))
			EndTextCommandSetBlipName(blip)
			table.insert(BlipList, blip)
		end
	end

	if Config.Boats.Garages and Config.Boats.Blips then
		for k,v in pairs(Config.BoatGarages) do
			local blip = AddBlipForCoord(v.Marker)

			SetBlipSprite (blip, Config.Blips.Garages.Sprite)
			SetBlipColour (blip, Config.Blips.Garages.Color)
			SetBlipDisplay(blip, Config.Blips.Garages.Display)
			SetBlipScale  (blip, Config.Blips.Garages.Scale)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('blip_garage'))
			EndTextCommandSetBlipName(blip)
			table.insert(BlipList, blip)
		end

		for k,v in pairs(Config.BoatPounds) do
			local blip = AddBlipForCoord(v.Marker)

			SetBlipSprite (blip, Config.Blips.Pounds.Sprite)
			SetBlipColour (blip, Config.Blips.Pounds.Color)
			SetBlipDisplay(blip, Config.Blips.Pounds.Display)
			SetBlipScale  (blip, Config.Blips.Pounds.Scale)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('blip_pound'))
			EndTextCommandSetBlipName(blip)
			table.insert(BlipList, blip)
		end
	end

	if Config.Cars.Garages and Config.Cars.Blips then
		for k,v in pairs(Config.CarGarages) do
			local blip = AddBlipForCoord(v.Marker)

			SetBlipSprite (blip, Config.Blips.Garages.Sprite)
			SetBlipColour (blip, Config.Blips.Garages.Color)
			SetBlipDisplay(blip, Config.Blips.Garages.Display)
			SetBlipScale  (blip, Config.Blips.Garages.Scale)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('blip_garage'))
			EndTextCommandSetBlipName(blip)
			table.insert(BlipList, blip)
		end

		for k,v in pairs(Config.CarPounds) do
			local blip = AddBlipForCoord(v.Marker)

			SetBlipSprite (blip, Config.Blips.Pounds.Sprite)
			SetBlipColour (blip, Config.Blips.Pounds.Color)
			SetBlipDisplay(blip, Config.Blips.Pounds.Display)
			SetBlipScale  (blip, Config.Blips.Pounds.Scale)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('blip_pound'))
			EndTextCommandSetBlipName(blip)
			table.insert(BlipList, blip)
		end
	end
end

-- Handles Private Blips
function DeletePrivateBlips()
	if PrivateBlips[1] ~= nil then
		for i=1, #PrivateBlips, 1 do
			RemoveBlip(PrivateBlips[i])
			PrivateBlips[i] = nil
		end
	end
end

function RefreshPrivateBlips()
	for zoneKey,zoneValues in pairs(Config.PrivateCarGarages) do
		if zoneValues.Private and has_value(userProperties, zoneValues.Private) then
			local blip = AddBlipForCoord(zoneValues.Marker)

			SetBlipSprite (blip, Config.Blips.PGarages.Sprite)
			SetBlipColour (blip, Config.Blips.PGarages.Color)
			SetBlipDisplay(blip, Config.Blips.PGarages.Display)
			SetBlipScale  (blip, Config.Blips.PGarages.Scale)
			SetBlipAsShortRange(blip, true)

			BeginTextCommandSetBlipName("STRING")
			AddTextComponentString(_U('blip_garage_private'))
			EndTextCommandSetBlipName(blip)
			table.insert(PrivateBlips, blip)
		end
	end
end

-- Handles Job Blips
function DeleteJobBlips()
	if JobBlips[1] ~= nil then
		for i=1, #JobBlips, 1 do
			RemoveBlip(JobBlips[i])
			JobBlips[i] = nil
		end
	end
end

function RefreshJobBlips()
	if Config.Ambulance.Garages and Config.Ambulance.Blips then
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
			for k,v in pairs(Config.AmbulanceGarages) do
				local blip = AddBlipForCoord(v.Marker)

				SetBlipSprite (blip, Config.Blips.JGarages.Sprite)
				SetBlipColour (blip, Config.Blips.JGarages.Color)
				SetBlipDisplay(blip, Config.Blips.JGarages.Display)
				SetBlipScale  (blip, Config.Blips.JGarages.Scale)
				SetBlipAsShortRange(blip, true)

				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(_U('blip_ambulance_garage'))
				EndTextCommandSetBlipName(blip)
				table.insert(JobBlips, blip)
			end
		end
	end

	if Config.Ambulance.Pounds and Config.Ambulance.Blips then
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'ambulance' then
			for k,v in pairs(Config.AmbulancePounds) do
				local blip = AddBlipForCoord(v.Marker)

				SetBlipSprite (blip, Config.Blips.JPounds.Sprite)
				SetBlipColour (blip, Config.Blips.JPounds.Color)
				SetBlipDisplay(blip, Config.Blips.JPounds.Display)
				SetBlipScale  (blip, Config.Blips.JPounds.Scale)
				SetBlipAsShortRange(blip, true)

				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(_U('blip_ambulance_impound'))
				EndTextCommandSetBlipName(blip)
				table.insert(JobBlips, blip)
			end
		end
	end

	if Config.Police.Garages and Config.Police.Blips then
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
			for k,v in pairs(Config.PoliceGarages) do
				local blip = AddBlipForCoord(v.Marker)

				SetBlipSprite (blip, Config.Blips.JGarages.Sprite)
				SetBlipColour (blip, Config.Blips.JGarages.Color)
				SetBlipDisplay(blip, Config.Blips.JGarages.Display)
				SetBlipScale  (blip, Config.Blips.JGarages.Scale)
				SetBlipAsShortRange(blip, true)

				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(_U('blip_police_garage'))
				EndTextCommandSetBlipName(blip)
				table.insert(JobBlips, blip)
			end
		end
	end

	if Config.Police.Pounds and Config.Police.Blips then
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'police' then
			for k,v in pairs(Config.PolicePounds) do
				local blip = AddBlipForCoord(v.Marker)

				SetBlipSprite (blip, Config.Blips.JPounds.Sprite)
				SetBlipColour (blip, Config.Blips.JPounds.Color)
				SetBlipDisplay(blip, Config.Blips.JPounds.Display)
				SetBlipScale  (blip, Config.Blips.JPounds.Scale)
				SetBlipAsShortRange(blip, true)

				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(_U('blip_police_impound'))
				EndTextCommandSetBlipName(blip)
				table.insert(JobBlips, blip)
			end
		end
	end

	if Config.Mechanic.Garages and Config.Mechanic.Blips then
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
			for k,v in pairs(Config.MechanicGarages) do
				local blip = AddBlipForCoord(v.Marker)

				SetBlipSprite (blip, Config.Blips.JGarages.Sprite)
				SetBlipColour (blip, Config.Blips.JGarages.Color)
				SetBlipDisplay(blip, Config.Blips.JGarages.Display)
				SetBlipScale  (blip, Config.Blips.JGarages.Scale)
				SetBlipAsShortRange(blip, true)

				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(_U('blip_mechanic_garage'))
				EndTextCommandSetBlipName(blip)
				table.insert(JobBlips, blip)
			end
		end
	end

	if Config.Mechanic.Pounds and Config.Mechanic.Blips then
		if ESX.PlayerData.job and ESX.PlayerData.job.name == 'mechanic' then
			for k,v in pairs(Config.MechanicPounds) do
				local blip = AddBlipForCoord(v.Marker)

				SetBlipSprite (blip, Config.Blips.JPounds.Sprite)
				SetBlipColour (blip, Config.Blips.JPounds.Color)
				SetBlipDisplay(blip, Config.Blips.JPounds.Display)
				SetBlipScale  (blip, Config.Blips.JPounds.Scale)
				SetBlipAsShortRange(blip, true)

				BeginTextCommandSetBlipName("STRING")
				AddTextComponentString(_U('blip_mechanic_impound'))
				EndTextCommandSetBlipName(blip)
				table.insert(JobBlips, blip)
			end
		end
	end
end
