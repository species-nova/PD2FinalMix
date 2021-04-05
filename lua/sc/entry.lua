local Net = _G.LuaNetworking

--Place grenade case
Hooks:Add("NetworkReceivedData", "PlaceGrenadeCrate", function(sender, id, data)	
	if id == "PlaceGrenadeCrate" then

		--Put the data into an array
		local DataArray = {}
		for i in string.gmatch(data, "[^|]+") do
			table.insert(DataArray, i)
		end

		if Network:is_server() then
			if BaseNetworkHandler._verify_gamestate(BaseNetworkHandler._gamestate_filter.any_ingame) then
				if #DataArray == 3 then
					--Retrieve the values from string
					--Pos
					local TempDataArray = {}
					for i in string.gmatch(DataArray[1], "[^(,)]+") do
						table.insert(TempDataArray, tonumber(i))
					end
					local pos = Vector3(TempDataArray[1],TempDataArray[2],TempDataArray[3])
					
					--Rot
					local TempDataArray = {}
					for i in string.gmatch(DataArray[2], "[^(,)]+") do
						table.insert(TempDataArray, tonumber(i))
					end
					local rot = Rotation(TempDataArray[1],TempDataArray[2],TempDataArray[3])
					--Lvl
					local amount_upgrade_lvl = tonumber(DataArray[3])
					--Spawn Grenade Crate
					local unit = GrenadeCrateBase.spawn(pos, rot, amount_upgrade_lvl, managers.network:session():local_peer():id())

				end
			end
		end

	end
end)