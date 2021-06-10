function EnvironmentFire:_do_damage()
	local pos = self._unit:position()
	local normal = math.UP
	local range = self._range
	local slot_mask = managers.slot:get_mask("explosion_targets")
	local player_in_range = false
	local player_in_range_count = 0

	if self._molotov_damage_effect_table then
		local collision_safety_distance = Vector3(0, 0, 5)
		local effect_position = nil
		local player_damage_range = range

		for _, damage_effect_entry in pairs(self._molotov_damage_effect_table) do
			if damage_effect_entry.body ~= nil then
				effect_position = damage_effect_entry.effect_current_position + collision_safety_distance
				local damage_range = range

				if _ == 1 then
					damage_range = range * 1.5
				end

				if managers.player:player_unit() then
					local player_distance = mvector3.distance(damage_effect_entry.effect_current_position, managers.player:player_unit():position())

					if player_distance <= damage_range and player_in_range == false then
						local raycast = World:raycast("ray", effect_position, managers.player:player_unit():position() + Vector3(0, 0, 30), "slot_mask", slot_mask)
						local raycast2 = World:raycast("ray", effect_position, managers.player:player_unit():position() + Vector3(0, 0, 0), "slot_mask", slot_mask)

						if raycast == nil or raycast2 == nil then
							player_in_range = true
							player_in_range_count = player_in_range_count + 1
							pos = damage_effect_entry.effect_current_position
							player_damage_range = damage_range
						end
					end
				end

				if Network:is_server() then
					local hit_units, splinters = managers.fire:detect_and_give_dmg({
						player_damage = 0,
						push_units = false,
						hit_pos = effect_position,
						range = damage_range,
						collision_slotmask = slot_mask,
						curve_pow = self._curve_pow,
						damage = self._damage,
						ignore_unit = self._unit,
						user = self._user_unit,
						owner = self._unit,
						alert_radius = self._fire_alert_radius,
						fire_dot_data = self._fire_dot_data,
						is_molotov = self._is_molotov
					})
				end
			end
		end

		if player_in_range == true then
			managers.fire:give_local_player_dmg(pos, player_damage_range, self._player_damage, self._user_unit) --Pass in the user.
		end
	end

	self._burn_tick_counter = 0
end