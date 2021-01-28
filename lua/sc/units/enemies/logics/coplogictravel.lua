local tmp_vec1 = Vector3()
local tmp_vec2 = Vector3()
local tmp_vec3 = Vector3()
local cone_top = Vector3()
local tmp_vec_cone_dir = Vector3()
local mvec3_set = mvector3.set
local mvec3_add = mvector3.add
local mvec3_mul = mvector3.multiply
local mvec3_set_l = mvector3.set_length
local mvec3_dir = mvector3.direction
local mvec3_copy = mvector3.copy
local mvec3_norm = mvector3.normalize
local mvec3_dis = mvector3.distance
local mvec3_dis_sq = mvector3.distance_sq
local mvec3_rot_with = mvector3.rotate_with
local math_lerp = math.lerp
local math_min = math.min
local math_max = math.max
local math_abs = math.abs
local math_random = math.random
local math_UP = math.UP
local math_sign = math.sign
local mrot_y = mrotation.y
local mrot_z = mrotation.z
local table_insert = table.insert

function CopLogicTravel.enter(data, new_logic_name, enter_params)
	CopLogicBase.enter(data, new_logic_name, enter_params)
	data.unit:brain():cancel_all_pathing_searches()

	local old_internal_data = data.internal_data
	local my_data = {
		unit = data.unit
	}
	local is_cool = data.unit:movement():cool()

	if is_cool then
		my_data.detection = data.char_tweak.detection.ntl
	else
		my_data.detection = data.char_tweak.detection.recon
	end

	if old_internal_data then
		my_data.turning = old_internal_data.turning
		my_data.firing = old_internal_data.firing
		my_data.shooting = old_internal_data.shooting
		my_data.attention_unit = old_internal_data.attention_unit

		if old_internal_data.nearest_cover then
			my_data.nearest_cover = old_internal_data.nearest_cover

			managers.navigation:reserve_cover(my_data.nearest_cover[1], data.pos_rsrv_id)
		end

		if old_internal_data.best_cover then
			my_data.best_cover = old_internal_data.best_cover

			managers.navigation:reserve_cover(my_data.best_cover[1], data.pos_rsrv_id)
		end
	end

	if data.char_tweak.announce_incomming then
		my_data.announce_t = data.t + 2
	end

	data.internal_data = my_data
	local key_str = tostring(data.key)
	my_data.upd_task_key = "CopLogicTravel.queued_update" .. key_str

	CopLogicTravel.queue_update(data, my_data)

	my_data.cover_update_task_key = "CopLogicTravel._update_cover" .. key_str

	if my_data.nearest_cover or my_data.best_cover then
		CopLogicBase.add_delayed_clbk(my_data, my_data.cover_update_task_key, callback(CopLogicTravel, CopLogicTravel, "_update_cover", data), data.t + 0.5)
	end

	my_data.advance_path_search_id = "CopLogicTravel_detailed" .. tostring(data.key)
	my_data.coarse_path_search_id = "CopLogicTravel_coarse" .. tostring(data.key)

	CopLogicIdle._chk_has_old_action(data, my_data)

	local objective = data.objective
	local path_data = objective.path_data

	if objective.path_style == "warp" then
		my_data.warp_pos = objective.pos
	elseif path_data then
		local path_style = objective.path_style

		if path_style == "precise" then
			local path = {
				mvec3_copy(data.m_pos)
			}

			for _, point in ipairs(path_data.points) do
				table.insert(path, mvec3_copy(point.position))
			end

			my_data.advance_path = path
			my_data.coarse_path_index = 1
			local start_seg = data.unit:movement():nav_tracker():nav_segment()
			local end_pos = mvec3_copy(path[#path])
			local end_seg = managers.navigation:get_nav_seg_from_pos(end_pos)
			my_data.coarse_path = {
				{
					start_seg
				},
				{
					end_seg,
					end_pos
				}
			}
			my_data.path_is_precise = true
		elseif path_style == "coarse" then
			local nav_manager = managers.navigation
			local f_get_nav_seg = nav_manager.get_nav_seg_from_pos
			local start_seg = data.unit:movement():nav_tracker():nav_segment()
			local path = {
				{
					start_seg
				}
			}

			for _, point in ipairs(path_data.points) do
				local pos = mvec3_copy(point.position)
				local nav_seg = f_get_nav_seg(nav_manager, pos)

				table.insert(path, {
					nav_seg,
					pos
				})
			end

			my_data.coarse_path = path
			my_data.coarse_path_index = CopLogicTravel.complete_coarse_path(data, my_data, path)
		elseif path_style == "coarse_complete" then
			if not data.is_converted then
				my_data.coarse_path_index = 1
				my_data.coarse_path = deep_clone(objective.path_data)
				my_data.coarse_path_index = CopLogicTravel.complete_coarse_path(data, my_data, my_data.coarse_path)
			else
				my_data.coarse_path = nil
				local nav_manager = managers.navigation
				local f_get_nav_seg = nav_manager.get_nav_seg_from_pos
				local start_seg = data.unit:movement():nav_tracker():nav_segment()
				local path = {
					{
						start_seg
					}
				}

				for _, point in ipairs(path_data.points) do
					local pos = mvec3_copy(point.position)
					local nav_seg = f_get_nav_seg(nav_manager, pos)

					table.insert(path, {
						nav_seg,
						pos
					})
				end

				my_data.coarse_path = path
				my_data.coarse_path_index = CopLogicTravel.complete_coarse_path(data, my_data, path)
			end			
		end
	end

	if objective.stance then
		local upper_body_action = data.unit:movement()._active_actions[3]

		if not upper_body_action or upper_body_action:type() ~= "shoot" then
			data.unit:movement():set_stance(objective.stance)
		end
	end

	if data.attention_obj and AIAttentionObject.REACT_AIM < data.attention_obj.reaction then
		data.unit:movement():set_cool(false, managers.groupai:state().analyse_giveaway(data.unit:base()._tweak_table, data.attention_obj.unit))
	end

	if is_cool then
		data.unit:brain():set_attention_settings({
			peaceful = true
		})
	else
		data.unit:brain():set_attention_settings({
			cbt = true
		})
	end

	my_data.attitude = data.objective.attitude or "avoid"
	my_data.weapon_range = data.char_tweak.weapon[data.unit:inventory():equipped_unit():base():weapon_tweak_data().usage].range
	my_data.path_safely = my_data.attitude == "avoid" or nil
	my_data.path_ahead = data.objective.path_ahead or data.team.id == tweak_data.levels:get_default_team_ID("player")

	data.unit:brain():set_update_enabled_state(false)
end

function CopLogicTravel.exit(data, new_logic_name, enter_params)
	CopLogicBase.exit(data, new_logic_name, enter_params)

	local my_data = data.internal_data

	data.unit:brain():cancel_all_pathing_searches()
	TaserLogicAttack._cancel_tase_attempt(data, my_data)
	SpoocLogicAttack._cancel_spooc_attempt(data, my_data)
	CopLogicBase.cancel_queued_tasks(my_data)
	CopLogicBase.cancel_delayed_clbks(my_data)

	if my_data.moving_to_cover then
		managers.navigation:release_cover(my_data.moving_to_cover[1])
	end

	if my_data.nearest_cover then
		managers.navigation:release_cover(my_data.nearest_cover[1])
	end

	if my_data.best_cover then
		managers.navigation:release_cover(my_data.best_cover[1])
	end

	data.brain:rem_pos_rsrv("path")
	data.unit:brain():set_update_enabled_state(true)
end

function CopLogicTravel._upd_enemy_detection(data)
	managers.groupai:state():on_unit_detection_updated(data.unit)

	local my_data = data.internal_data
	local min_reaction = nil
	if data.unit:base():has_tag("special") then
		min_reaction = AIAttentionObject.REACT_AIM
	end
	local delay = CopLogicBase._upd_attention_obj_detection(data, min_reaction, nil)
	local detected_enemies = data.detected_attention_objects
	local tasing = my_data.tasing
	local tased_u_key = tasing and tasing.target_u_key
	local tase_in_effect = nil
	local get_new_target = true

	if tasing then
		if data.unit:movement()._active_actions[3] and data.unit:movement()._active_actions[3]:type() == "tase" then
			local tase_action = data.unit:movement()._active_actions[3]

			if tase_action._discharging or tase_action._firing_at_husk or tase_action._discharging_on_husk then
				tase_in_effect = true
			end
		end
	end

	if tase_in_effect then
		return
	end
	
	local reaction_func = nil
	
	if data.unit:base():has_tag("taser") then
		reaction_func = TaserLogicAttack._chk_reaction_to_attention_object
	end
	
	if alive(data.unit:inventory() and data.unit:inventory()._shield_unit) then
		local focus_enemy, focus_enemy_angle, focus_enemy_reaction = nil
		local enemies = {}
		local enemies_cpy = {}
		local passive_enemies = {}
		local threat_epicenter, threats = nil
		local nr_threats = 0
		local verified_chk_t = data.t - 8
		for key, enemy_data in pairs(detected_enemies) do
			if AIAttentionObject.REACT_COMBAT <= enemy_data.reaction and enemy_data.identified and enemy_data.verified_t and verified_chk_t < enemy_data.verified_t then
				enemies[key] = enemy_data
				enemies_cpy[key] = enemy_data
			end
		end

		for key, enemy_data in pairs(enemies) do
			threat_epicenter = threat_epicenter or Vector3()

			mvector3.add(threat_epicenter, enemy_data.m_pos)

			nr_threats = nr_threats + 1
			enemy_data.aimed_at = CopLogicIdle.chk_am_i_aimed_at(data, enemy_data, enemy_data.aimed_at and 0.95 or 0.985)
		end

		if threat_epicenter then
			mvector3.divide(threat_epicenter, nr_threats)

			local from_threat = mvector3.copy(threat_epicenter)

			mvector3.subtract(from_threat, data.m_pos)
			mvector3.normalize(from_threat)

			local furthest_pt_dist = 0
			local furthest_line = nil

			if not my_data.threat_epicenter or mvector3.distance(threat_epicenter, my_data.threat_epicenter) > 100 then
				my_data.threat_epicenter = mvector3.copy(threat_epicenter)

				for key1, enemy_data1 in pairs(enemies) do
					enemies_cpy[key1] = nil

					for key2, enemy_data2 in pairs(enemies_cpy) do
						if nr_threats == 2 then
							local AB = mvector3.copy(enemy_data1.m_pos)

							mvector3.subtract(AB, enemy_data2.m_pos)
							mvector3.normalize(AB)

							local PA = mvector3.copy(data.m_pos)

							mvector3.subtract(PA, enemy_data1.m_pos)
							mvector3.normalize(PA)

							local PB = mvector3.copy(data.m_pos)

							mvector3.subtract(PB, enemy_data2.m_pos)
							mvector3.normalize(PB)

							local dot1 = mvector3.dot(AB, PA)
							local dot2 = mvector3.dot(AB, PB)

							if dot1 < 0 and dot2 < 0 or dot1 > 0 and dot2 > 0 then
								break
							else
								furthest_line = {
									enemy_data1.m_pos,
									enemy_data2.m_pos
								}

								break
							end
						end

						local pt = math.line_intersection(enemy_data1.m_pos, enemy_data2.m_pos, threat_epicenter, data.m_pos)
						local to_pt = mvector3.copy(threat_epicenter)

						mvector3.subtract(to_pt, pt)
						mvector3.normalize(to_pt)

						if mvector3.dot(from_threat, to_pt) > 0 then
							local line = mvector3.copy(enemy_data2.m_pos)

							mvector3.subtract(line, enemy_data1.m_pos)

							local line_len = mvector3.normalize(line)
							local pt_line = mvector3.copy(pt)

							mvector3.subtract(pt_line, enemy_data1.m_pos)

							local dot = mvector3.dot(line, pt_line)

							if dot < line_len and dot > 0 then
								local dist = mvector3.distance(pt, threat_epicenter)

								if furthest_pt_dist < dist then
									furthest_pt_dist = dist
									furthest_line = {
										enemy_data1.m_pos,
										enemy_data2.m_pos
									}
								end
							end
						end
					end
				end
			end

			local optimal_direction = nil

			if furthest_line then
				local BA = mvector3.copy(furthest_line[2])

				mvector3.subtract(BA, furthest_line[1])

				local PA = mvector3.copy(furthest_line[1])

				mvector3.subtract(PA, data.m_pos)

				local out = nil

				if nr_threats == 2 then
					mvector3.normalize(BA)

					local len = mvector3.dot(BA, PA)
					local x = mvector3.copy(furthest_line[1])

					mvector3.multiply(BA, len)
					mvector3.subtract(x, BA)

					out = mvector3.copy(data.m_pos)

					mvector3.subtract(out, x)
				else
					local EA = mvector3.copy(threat_epicenter)

					mvector3.subtract(EA, furthest_line[1])

					local rot_axis = Vector3()

					mvector3.cross(rot_axis, BA, EA)
					mvector3.set_static(rot_axis, 0, 0, rot_axis.z)

					out = Vector3()

					mvector3.cross(out, BA, rot_axis)
				end

				mvector3.normalize(out)

				optimal_direction = mvector3.copy(out)

				mvector3.multiply(optimal_direction, -1)
				mvector3.multiply(out, mvector3.dot(out, PA) + 600)

				my_data.optimal_pos = mvector3.copy(data.m_pos)

				mvector3.add(my_data.optimal_pos, out)
			else
				optimal_direction = mvector3.copy(threat_epicenter)

				mvector3.subtract(optimal_direction, data.m_pos)
				mvector3.normalize(optimal_direction)

				local optimal_length = 0

				for _, enemy in pairs(enemies) do
					local enemy_dir = mvector3.copy(threat_epicenter)

					mvector3.subtract(enemy_dir, enemy.m_pos)

					local len = mvector3.dot(enemy_dir, optimal_direction)
					optimal_length = math.max(len, optimal_length)
				end

				local optimal_pos = mvector3.copy(optimal_direction)

				mvector3.multiply(optimal_pos, -(optimal_length + 600))
				mvector3.add(optimal_pos, threat_epicenter)

				my_data.optimal_pos = optimal_pos
			end

			for key, enemy_data in pairs(enemies) do
				local reaction = CopLogicSniper._chk_reaction_to_attention_object(data, enemy_data, true)

				if not focus_enemy_reaction or focus_enemy_reaction <= reaction then
					local enemy_dir = tmp_vec1

					mvector3.direction(enemy_dir, data.m_pos, enemy_data.m_pos)

					local angle = mvector3.dot(optimal_direction, enemy_dir)

					if data.attention_obj and key == data.attention_obj.u_key then
						angle = angle + 0.15
					end

					if not focus_enemy or enemy_data.verified and not focus_enemy.verified or (enemy_data.verified or not focus_enemy.verified) and focus_enemy_angle < angle then
						focus_enemy = enemy_data
						focus_enemy_angle = angle
						focus_enemy_reaction = reaction
					end
				end
			end

			CopLogicBase._set_attention_obj(data, focus_enemy, focus_enemy_reaction)
			get_new_target = nil
		end
	end
		
	if get_new_target then
		local new_attention, new_prio_slot, new_reaction = CopLogicIdle._get_priority_attention(data, detected_enemies, reaction_func)
		local old_att_obj = data.attention_obj
		
		CopLogicBase._set_attention_obj(data, new_attention, new_reaction)
		
		if new_attention then
			if new_attention.nearly_visible or new_attention.verified then
				if old_att_obj and old_att_obj.u_key ~= new_attention.u_key then
					CopLogicAttack._cancel_charge(data, my_data)

					if not data.unit:movement():chk_action_forbidden("walk") then
						ShieldLogicAttack._cancel_optimal_attempt(data, my_data)
					end
				end
			end
		end
		
		if new_attention and new_reaction then 
			if data.important and AIAttentionObject.REACT_COMBAT <= new_reaction and new_attention.nav_tracker and not my_data.walking_to_optimal_pos then
				if alive(data.unit:inventory() and data.unit:inventory()._shield_unit) then
					my_data.optimal_pos = CopLogicAttack._find_flank_pos(data, my_data, new_attention.nav_tracker)
				elseif data.is_suppressed and new_attention.verified then
					local retreat_pos = CopLogicAttack._find_retreat_position(data.m_pos, new_attention.m_pos, new_attention.m_head_pos, new_attention.nav_tracker, 2000, nil)
					if retreat_pos then
						my_data.optimal_pos = retreat_pos
						--log("woo!")
					end
				elseif data.is_suppressed and not new_attention.verified then
					local threat_pos = nil
						
					if not my_data.cover_test_step then
						my_data.cover_test_step = 1
					end
						
					if new_attention.last_verified_pos then
						threat_pos = new_attention.last_verified_pos
					elseif new_attention.is_person then
						threat_pos = new_attention.m_head_pos
					else
						threat_pos = new_attention.m_pos
					end
						
					local my_tracker = data.unit:movement():nav_tracker()
					local shoot_from_pos = CopLogicTravel._peek_for_pos_sideways(data, my_data, my_tracker, threat_pos, nil)
						
					if shoot_from_pos then
						my_data.optimal_pos = shoot_from_pos
						--log("beeftime")
					elseif not data.unit:movement():chk_action_forbidden("walk") then
						ShieldLogicAttack._cancel_optimal_attempt(data, my_data)
						my_data.cover_test_step = my_data.cover_test_step + 1
					end
				elseif data.tactics and data.tactics.flank then
					my_data.optimal_pos = CopLogicAttack._find_flank_pos(data, my_data, new_attention.nav_tracker)
				elseif data.tactics and data.tactics.charge then
					my_data.optimal_pos = CopLogicTravel._get_pos_on_wall(new_attention.nav_tracker:field_position(), my_data.weapon_range.close, 45, nil)
				end
			end
		end
	end
	
	local objective = data.objective
	local allow_trans, obj_failed = CopLogicBase.is_obstructed(data, objective, nil, new_attention)

	if allow_trans and (obj_failed or not objective or objective.type ~= "follow") then
		local wanted_state = CopLogicBase._get_logic_state_from_reaction(data)

		if wanted_state and wanted_state ~= data.name then
			if obj_failed then
				data.objective_failed_clbk(data.unit, data.objective)
			end

			if my_data == data.internal_data and not objective.is_default then
				debug_pause_unit(data.unit, "[CopLogicTravel._upd_enemy_detection] exiting without discarding objective", data.unit, inspect(objective))
				
				CopLogicBase._exit(data.unit, wanted_state)
			end

			CopLogicBase._report_detections(detected_enemies)

			return delay
		end
	end

	if my_data == data.internal_data then
		if data.cool and new_reaction == AIAttentionObject.REACT_SUSPICIOUS and CopLogicBase._upd_suspicion(data, my_data, new_attention) then
			CopLogicBase._report_detections(detected_enemies)

			return delay
		elseif new_reaction and new_reaction <= AIAttentionObject.REACT_SCARED then
			local set_attention = data.unit:movement():attention()

			if not set_attention or set_attention.u_key ~= new_attention.u_key then
				CopLogicBase._set_attention(data, new_attention, nil)
			end
		end

		CopLogicAttack._upd_aim(data, my_data)
		if alive(data.unit:inventory() and data.unit:inventory()._shield_unit) and my_data.optimal_pos and focus_enemy then
			mvector3.set_z(my_data.optimal_pos, focus_enemy.m_pos.z)
		end
	end

	CopLogicBase._report_detections(detected_enemies)

	if new_attention and data.char_tweak.chatter.entrance and not data.entrance and new_attention.criminal_record and new_attention.verified and AIAttentionObject.REACT_SCARED <= new_reaction and math_abs(data.m_pos.z - new_attention.m_pos.z) < 4000 then
		data.unit:sound():say(data.brain.entrance_chatter_cue or "entrance", true, nil)

		data.entrance = true
	end

	if data.cool then
		CopLogicTravel.upd_suspicion_decay(data)
	end

	return delay
end

function CopLogicTravel._peek_for_pos_sideways(data, my_data, from_tracker, peek_to_pos, height)
	local unit = data.unit
	local my_tracker = from_tracker
	local enemy_pos = peek_to_pos
	local my_pos = unit:movement():m_pos()
	local back_vec = my_pos - enemy_pos
	local height = nil
	
	if not height then
		local low_ray, high_ray = CopLogicAttack._chk_covered(data, data.m_pos, enemy_pos, data.visibility_slotmask)
					
		if low_ray then
			height = 80
		else
			height = 150
		end
	end

	mvector3.set_z(back_vec, 0)
	mvector3.set_length(back_vec, 75)

	local back_pos = my_pos + back_vec
	local ray_params = {
		allow_entry = true,
		trace = true,
		tracker_from = my_tracker,
		pos_to = back_pos
	}
	local ray_res = managers.navigation:raycast(ray_params)
	back_pos = ray_params.trace[1]
	local back_polar = (back_pos - my_pos):to_polar()
	local right_polar = back_polar:with_spin(back_polar.spin + 90):with_r(100 + 80 * my_data.cover_test_step)
	local right_vec = right_polar:to_vector()
	local right_pos = back_pos + right_vec
	ray_params.pos_to = right_pos
	local ray_res = managers.navigation:raycast(ray_params)
	local shoot_from_pos, found_shoot_from_pos = nil
	local ray_softness = 150
	local stand_ray = World:raycast("ray", ray_params.trace[1] + math.UP * height, enemy_pos, "slot_mask", data.visibility_slotmask, "ray_type", "ai_vision")

	if not stand_ray or mvector3.distance(stand_ray.position, enemy_pos) < ray_softness then
		shoot_from_pos = ray_params.trace[1]
		found_shoot_from_pos = true
	end

	if not found_shoot_from_pos then
		local left_pos = back_pos - right_vec
		ray_params.pos_to = left_pos
		local ray_res = managers.navigation:raycast(ray_params)
		local stand_ray = World:raycast("ray", ray_params.trace[1] + math.UP * height, enemy_pos, "slot_mask", data.visibility_slotmask, "ray_type", "ai_vision")

		if not stand_ray or mvector3.distance(stand_ray.position, enemy_pos) < ray_softness then
			shoot_from_pos = ray_params.trace[1]
			found_shoot_from_pos = true
		end
	end

	return shoot_from_pos
end

function CopLogicTravel:_reserve_pos_step_clbk(data, test_pos)
	if not data.step_vector then
		data.step_vector = mvector3.copy(data.unit_pos)

		mvector3.subtract(data.step_vector, test_pos)

		data.distance = mvector3.normalize(data.step_vector)

		mvector3.set_length(data.step_vector, 25)

		data.num_steps = 0
	end

	local step_length = mvector3.length(data.step_vector)

	if data.distance < step_length or data.num_steps > 4 then
		return false
	end

	mvector3.add(test_pos, data.step_vector)

	data.distance = data.distance - step_length

	mvector3.set_length(data.step_vector, step_length * 2)

	data.num_steps = data.num_steps + 1

	return true
end

function CopLogicTravel._upd_combat_movement(data, ignore_walks)
	local my_data = data.internal_data
	local t = data.t
	local unit = data.unit
	local diff_index = tweak_data:difficulty_to_index(Global.game_settings.difficulty)
	
	if not data.unit:base():has_tag("law") then
		return
	end
	
	if not data.attention_obj or not data.important then
		--if not data.cool and not my_data.advancing then
		--	CopLogicTravel.upd_advance(data)
		--end
		
		return
	else
		local definitely_not_reactions_chk = AIAttentionObject.REACT_COMBAT > data.attention_obj.reaction

		if definitely_not_reactions_chk then
			--if not data.cool and not my_data.advancing then
			--	CopLogicTravel.upd_advance(data)
			--end
			
			return
		end
	end
	
	local engage_range = my_data.weapon_range.close or 1500

	local action_taken = data.logic.action_taken(data, my_data)
	local focus_enemy = data.attention_obj
	local in_cover = my_data.in_cover
	local best_cover = my_data.best_cover
	local nearest_cover = my_data.nearest_cover
	local enemy_visible = focus_enemy and focus_enemy.verified
	local enemy_visible_soft = nil
	
	if Global.game_settings.one_down then
		if data.tactics and data.tactics.ranged_fire or data.tactics and data.tactics.elite_ranged_fire then
			enemy_visible_soft = focus_enemy.verified_t and t - focus_enemy.verified_t < math_random(0.3, 1.05)
		else
			enemy_visible_soft = focus_enemy and focus_enemy.verified
		end
	else
		if diff_index <= 5 then
			if data.tactics and data.tactics.ranged_fire or data.tactics and data.tactics.elite_ranged_fire then
				enemy_visible_soft = focus_enemy.verified_t and t - focus_enemy.verified_t < math_random(3.1, 3.8)
			else
				enemy_visible_soft = focus_enemy.verified_t and t - focus_enemy.verified_t < math_random(1.05, 1.4)
			end
		else
			if data.tactics and data.tactics.ranged_fire or data.tactics and data.tactics.elite_ranged_fire then
				enemy_visible_soft = focus_enemy.verified_t and t - focus_enemy.verified_t < math_random(2, 3)
			else
				enemy_visible_soft = focus_enemy.verified_t and t - focus_enemy.verified_t < math_random(0.35, 1.05)
			end
		end
	end
	
	local enemy_visible_mild_soft = focus_enemy and focus_enemy.verified_t and t - focus_enemy.verified_t < 2
	local enemy_visible_softer = focus_enemy and focus_enemy.verified_t and t - focus_enemy.verified_t < 4
	local antipassivecheck = focus_enemy and focus_enemy.verified or my_data.shooting
	local flank_cover_charge_qualify = focus_enemy and focus_enemy.verified_t and t - focus_enemy.verified_t > 2 or focus_enemy and focus_enemy.verified
		
	local alert_soft = data.is_suppressed
	
	--hitnrun: approach enemies, back away once the enemy is visible, creating a variating degree of aggressiveness
	--eliterangedfire: open fire at enemies from longer distances, back away if the enemy gets too close for comfort
	--spoocavoidance: attempt to approach enemies, if aimed at/seen, retreat away into cover and disengage until ready to try again
	local hitnrunmovementqualify = data.tactics and data.tactics.hitnrun and focus_enemy and focus_enemy.verified and focus_enemy.verified_dis <= 1000 and math_abs(data.m_pos.z - data.attention_obj.m_pos.z) < 200
	local spoocavoidancemovementqualify = data.tactics and data.tactics.spoocavoidance and focus_enemy and focus_enemy.verified and focus_enemy.verified_dis <= 2000 and focus_enemy.aimed_at
	local eliterangedfiremovementqualify = data.tactics and data.tactics.elite_ranged_fire and focus_enemy and focus_enemy.verified and focus_enemy.verified_dis <= 1500
	
	local ammo_max, ammo = data.unit:inventory():equipped_unit():base():ammo_info()
	local reloadingretreatmovementqualify = ammo / ammo_max < 0.2 and data.tactics and data.tactics.reloadingretreat and focus_enemy and focus_enemy.verified
	
	
	local want_to_take_cover = my_data.want_to_take_cover
	local move_to_cover, want_flank_cover = nil
	local cover_test_step_chk = action_taken or want_to_take_cover or not in_cover --optimizations, yay
	
	if not my_data.cover_test_step then
		my_data.cover_test_step = 1
	elseif data.tactics and data.tactics.hitnrun or data.tactics and data.tactics.murder or data.unit:base():has_tag("takedown") or Global.game_settings.use_intense_AI then
		if my_data.cover_test_step ~= 1 and cover_test_step_chk then
			my_data.cover_test_step = 1
			--not many tactics need to be this aggressive, but hitnrun and murder are specifically for bulldozer and units which will want to get up to enemies' faces, and as such, require these.
		end
	else
		if my_data.cover_test_step ~= 1 and not enemy_visible_softer and cover_test_step_chk then
			my_data.cover_test_step = 1
		end
	end
	
	local ranged_fire_sot_bonus = 0.5
	
	if my_data.stay_out_time and not my_data.at_cover_shoot_pos or my_data.stay_out_time and action_taken then
		my_data.stay_out_time = nil
	elseif my_data.attitude == "engage" and not my_data.stay_out_time and my_data.at_cover_shoot_pos and not action_taken and not want_to_take_cover then
		if Global.game_settings.one_down or managers.skirmish.is_skirmish() or data.tactics and data.tactics.hitnrun or data.tactics and data.tactics.murder or data.unit:base():has_tag("takedown") or Global.game_settings.use_intense_AI then
			my_data.stay_out_time = t - 1
			--log("interesting")
		else
			if diff_index <= 5 then
				if data.tactics and data.tactics.ranged_fire or data.tactics and data.tactics.elite_ranged_fire then
					my_data.stay_out_time = t + 1 + ranged_fire_sot_bonus
				else
					my_data.stay_out_time = t + 1
				end
			elseif diff_index == 6 then
				if data.tactics and data.tactics.ranged_fire or data.tactics and data.tactics.elite_ranged_fire then
					my_data.stay_out_time = t + 0.5 + ranged_fire_sot_bonus
				else
					my_data.stay_out_time = t + 0.5
				end
			else
				if data.tactics and data.tactics.ranged_fire or data.tactics and data.tactics.elite_ranged_fire then
					my_data.stay_out_time = t + 0.5
				else
					my_data.stay_out_time = t - 1
				end
			end
		end
	end
	
	local do_something_else = true
	
	if not ignore_walks then
		if alive(data.unit:inventory() and data.unit:inventory()._shield_unit) then
			if not action_taken then
				if my_data.pathing_to_optimal_pos then
					-- Nothing
				elseif my_data.walking_to_optimal_pos then
					-- nothing
				elseif my_data.optimal_path then
					action_taken = CopLogicTravel._chk_request_action_walk_to_optimal_pos(data, my_data)
					do_something_else = nil
				elseif my_data.optimal_pos and focus_enemy.nav_tracker then
					local to_pos = my_data.optimal_pos
					my_data.optimal_pos = nil
					local ray_params = {
						trace = true,
						tracker_from = unit:movement():nav_tracker(),
						pos_to = to_pos
					}
					local ray_res = managers.navigation:raycast(ray_params)
					to_pos = ray_params.trace[1]

					if ray_res then
						local vec = data.m_pos - to_pos

						mvector3.normalize(vec)

						local fwd = unit:movement():m_fwd()
						local fwd_dot = fwd:dot(vec)

						if fwd_dot > 0 then
							local enemy_tracker = focus_enemy.nav_tracker

							if enemy_tracker:lost() then
								ray_params.tracker_from = nil
								ray_params.pos_from = enemy_tracker:field_position()
							else
								ray_params.tracker_from = enemy_tracker
							end

							ray_res = managers.navigation:raycast(ray_params)
							to_pos = ray_params.trace[1]
						end
					end

					local fwd_bump = nil
					to_pos, fwd_bump = ShieldLogicAttack.chk_wall_distance(data, my_data, to_pos)
					local do_move = mvector3.distance_sq(to_pos, data.m_pos) > 10000 

					if not do_move then
						local to_pos_current, fwd_bump_current = ShieldLogicAttack.chk_wall_distance(data, my_data, data.m_pos)

						if fwd_bump_current then
							do_move = true
						end
					end

					if do_move and not my_data.walking_to_optimal_pos then
						my_data.pathing_to_optimal_pos = true
						my_data.optimal_path_search_id = tostring(unit:key()) .. "optimal"
						local reservation = managers.navigation:reserve_pos(nil, nil, to_pos, callback(CopLogicTravel, CopLogicTravel, "_reserve_pos_step_clbk", {
							unit_pos = data.m_pos
						}), 70, data.pos_rsrv_id)

						if reservation then
							to_pos = reservation.position
						else
							reservation = {
								radius = 60,
								position = mvector3.copy(to_pos),
								filter = data.pos_rsrv_id
							}

							managers.navigation:add_pos_reservation(reservation)
						end

						data.brain:set_pos_rsrv("path", reservation)
						--log("shit")
						data.brain:search_for_path(my_data.optimal_path_search_id, to_pos)
					end
				end
			end
		else
			if data.unit:base():has_tag("takedown") or data.unit:base():has_tag("special") then
				if my_data.pathing_to_optimal_pos then
					-- Nothing
				elseif my_data.walking_to_optimal_pos then
					-- nothing
				elseif my_data.optimal_path then
					action_taken = CopLogicTravel._chk_request_action_walk_to_optimal_pos(data, my_data)
					do_something_else = nil
				elseif focus_enemy.unit then
					my_data.pathing_to_optimal_pos = true
					my_data.optimal_path_search_id = tostring(unit:key()) .. "optimal"
					data.brain:search_for_path_to_unit(my_data.optimal_path_search_id, focus_enemy.unit)
				end
			elseif data.tactics then
				if my_data.pathing_to_optimal_pos then
					-- Nothing
					--log("im fucking")
				elseif my_data.walking_to_optimal_pos then
					-- nothing
				elseif my_data.optimal_path then
					--my_data.aggro_move_t = t + math.random(0, 1.25)
					action_taken = CopLogicTravel._chk_request_action_walk_to_optimal_pos(data, my_data)
					do_something_else = nil
				elseif my_data.optimal_pos and focus_enemy.nav_tracker then
					local to_pos = my_data.optimal_pos
					my_data.pathing_to_optimal_pos = true
					my_data.optimal_path_search_id = tostring(unit:key()) .. "optimal"
					data.brain:search_for_path(my_data.optimal_path_search_id, to_pos)
				end
			end
		end
	end
	
	if not do_something_else then
		return true
	end
				
	if not ignore_walks then
		if not action_taken and hitnrunmovementqualify and not pantsdownchk or not action_taken and eliterangedfiremovementqualify and not pantsdownchk or not action_taken and spoocavoidancemovementqualify and not pantsdownchk or not action_taken and reloadingretreatmovementqualify then
			action_taken = CopLogicTravel._chk_start_action_move_back(data, my_data, focus_enemy, nil, nil)
			do_something_else = nil
			if data.char_tweak.chatter and data.char_tweak.chatter.cloakeravoidance then
				managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "cloakeravoidance")
			end
		end
	end
	
	if not do_something_else then
		return true
	end
	
	if not action_taken and not my_data.turning and not data.unit:movement():chk_action_forbidden("walk") and not my_data.has_old_action and CopLogicAttack._can_move(data) and data.attention_obj.verified and not spoocavoidancemovementqualify then
		if data.is_suppressed and data.t - data.unit:character_damage():last_suppression_t() < 0.7 then
			action_taken = CopLogicBase.chk_start_action_dodge(data, "scared")
			do_something_else = nil
			if data.char_tweak.chatter and data.char_tweak.chatter.dodge then
				managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "dodge")
			end
			
			if data.char_tweak.chatter and data.char_tweak.chatter.cloakeravoidance then
				managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "cloakeravoidance")
			end
		end

		if not action_taken and focus_enemy.is_person then
			local dodge = nil

			if focus_enemy.is_local_player then
				local e_movement_state = focus_enemy.unit:movement():current_state()

				if not e_movement_state:_is_reloading() and not e_movement_state:_interacting() and not e_movement_state:is_equipping() then
					dodge = true
				end
			else
				local e_anim_data = focus_enemy.unit:anim_data()
				local movingoridle = e_anim_data.move or e_anim_data.idle

				if movingoridle and not e_anim_data.reload then
					dodge = true
				end
			end

			if dodge and focus_enemy.aimed_at then
				action_taken = CopLogicBase.chk_start_action_dodge(data, "preemptive")
				do_something_else = nil
				if data.char_tweak.chatter and data.char_tweak.chatter.dodge then
					managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "dodge")
				end
				if data.char_tweak.chatter and data.char_tweak.chatter.cloakeravoidance then
					managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "cloakeravoidance")
				end
			end
		end
	end
end

function CopLogicTravel.is_advancing(data)
	if data.internal_data.advancing and data.pos_rsrv.move_dest then
		return data.pos_rsrv.move_dest.position
	end
end

function CopLogicTravel._upd_pathing(data, my_data)
	if data.pathing_results then
		local pathing_results = data.pathing_results
		data.pathing_results = nil
		
		local path = pathing_results[my_data.optimal_path_search_id]
		
		if path then
			--log("ghsanh")
			if path ~= "failed" then
			--log("hgh")
				my_data.optimal_path = path
			else
				--log("aruugugh")
				print("[ShieldLogicAttack._process_pathing_results] optimal path failed")
			end

			my_data.pathing_to_optimal_pos = nil
			my_data.optimal_path_search_id = nil
		end
		
		local path = pathing_results[my_data.advance_path_search_id]

		if path and my_data.processing_advance_path then
			my_data.processing_advance_path = nil

			if path ~= "failed" then
				my_data.advance_path = path
			else
				data.path_fail_t = data.t

				data.objective_failed_clbk(data.unit, data.objective)

				return
			end
		end

		local path = pathing_results[my_data.coarse_path_search_id]

		if path and my_data.processing_coarse_path then
			my_data.processing_coarse_path = nil

			if path ~= "failed" then
				my_data.coarse_path = path
				my_data.coarse_path_index = 1
			elseif my_data.path_safely then
				my_data.path_safely = nil
			else
				print("[CopLogicTravel:_upd_pathing] coarse_path failed unsafe", data.unit, my_data.coarse_path_index)

				data.path_fail_t = data.t

				data.objective_failed_clbk(data.unit, data.objective)

				return
			end
		end
		
		local path = pathing_results[my_data.cover_path_search_id]

		if path then
			if path ~= "failed" then
				my_data.cover_path = path
			else
				print(data.unit, "[CopLogicAttack._process_pathing_results] cover path failed", data.unit)
				--CopLogicAttack._set_engage_cover(data, my_data, nil)
				--log("hmm")

				my_data.cover_path_failed_t = TimerManager:game():time()
			end

			my_data.processing_cover_path = nil
			my_data.cover_path_search_id = nil
		end

		path = pathing_results[my_data.charge_path_search_id]

		if path then
			if path ~= "failed" then
				my_data.charge_path = path
			else
				print("[CopLogicAttack._process_pathing_results] charge path failed", data.unit)
				--log("hmm")
			end

			my_data.charge_path_search_id = nil
			my_data.charge_path_failed_t = TimerManager:game():time()
		end
		
		path = pathing_results[my_data.expected_pos_path_search_id]

		if path then
			if path ~= "failed" then
				my_data.expected_pos_path = path
			end

			my_data.expected_pos_path_search_id = nil
		end
		
	end
end

function CopLogicTravel._chk_wants_to_take_cover(data, my_data)
	if not data.attention_obj or data.attention_obj.reaction < AIAttentionObject.REACT_COMBAT then
		return
	end
	
	if my_data.moving_to_cover or data.is_suppressed or my_data.attitude ~= "engage" or data.unit:anim_data().reload then
		--log("i want cover")
		return true
	end

	local ammo_max, ammo = data.unit:inventory():equipped_unit():base():ammo_info()

	if ammo / ammo_max < 0.2 then
		return true
	end
end

function CopLogicTravel.queued_update(data)
    local my_data = data.internal_data
	local objective = data.objective or nil
    data.t = TimerManager:game():time()
    my_data.close_to_criminal = nil
    local delay = CopLogicTravel._upd_enemy_detection(data)
	
	local focus_enemy = data.attention_obj
	
	if not data.is_converted and data.unit:base():has_tag("law") and data.tactics then
		if objective then --currently trying to get rawed by 9 lonewolves at the burger king drive-in in front of 81 other cops
			if data.tactics.lonewolf then
				if objective.follow_unit then
					if objective.follow_unit:brain() and objective.follow_unit:brain().objective and objective.follow_unit:brain():objective() ~= nil then
						local new_objective = objective.follow_unit:brain():objective() --ignore following the "follow_unit", copy their objective and become standalone instead in order to execute pinches and flanking manuevers freely
						--log("ay caramba!")
						if new_objective.type == "defend_area" and new_objective.grp_objective and new_objective.grp_objective.type ~= "retire" or new_objective.type == "hunt" then
							data.unit:brain():set_objective(new_objective, nil)
							
							return
						end
					end
				end
			end
		end
	end
	
	if my_data.tasing then
		action_taken = action_taken or CopLogicAttack._chk_request_action_turn_to_enemy(data, my_data, data.m_pos, focus_enemy.m_pos)
		
		if data.internal_data == my_data then
			CopLogicBase._report_detections(data.detected_attention_objects)
			CopLogicTravel.queue_update(data, my_data)
		end

		return
	end
	
	if my_data.spooc_attack then
		
		if data.internal_data == my_data then
			CopLogicBase._report_detections(data.detected_attention_objects)
			CopLogicTravel.queue_update(data, my_data)
		end

		return
	end
	
	if data.unit:base():has_tag("spooc") or data.unit:base()._tweak_table == "shadow_spooc" then
		SpoocLogicAttack._upd_spooc_attack(data, my_data)
	end

	if my_data.spooc_attack then
		if data.internal_data == my_data then
			CopLogicTravel.queue_update(data, data.internal_data, delay)
		end

		return
	end
	
	if data.unit:base():has_tag("law") and my_data.has_advanced_once then
		if data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction then
			if data.important or data.unit:base():has_tag("special") then
				--CopLogicTravel._chk_start_action_move_out_of_the_way(data, my_data)
				CopLogicTravel._upd_combat_movement(data)
				if managers.groupai:state():is_smoke_grenade_active() then
					CopLogicBase.do_smart_grenade(data, my_data, data.attention_obj)
				end
			end
		end
	end
	
    if data.internal_data ~= my_data then
    	return
    end
	
	--Snipers should stop if they have an aggressive reaction to a visible object or player
	if data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction then
		if not data.tactics or not data.tactics.sniper or data.tactics.sniper and not data.attention_obj.verified or data.tactics.sniper and data.attention_obj.dis > 4000 then
			CopLogicTravel.upd_advance(data)
		end
	else
		CopLogicTravel.upd_advance(data)
	end
	
	if data.internal_data ~= my_data then
		return
	end
	    
    if not delay then
    	debug_pause_unit(data.unit, "crap!!!", inspect(data))	
    
    	delay = 0.35
    end
	
	local hostage_count = managers.groupai:state():get_hostage_count_for_chatter() --check current hostage count
	local chosen_panic_chatter = "controlpanic" --set default generic assault break chatter
	
	if hostage_count > 0 then --make sure the hostage count is actually above zero before replacing any of the lines
		if hostage_count > 3 then  -- hostage count needs to be above 3
			if math_random() < 0.4 then --40% chance for regular panic if hostages are present
				chosen_panic_chatter = "controlpanic"
			else
				chosen_panic_chatter = "hostagepanic2" --more panicky "GET THOSE HOSTAGES OUT RIGHT NOW!!!" line for when theres too many hostages on the map
			end
		else
			if math_random() < 0.4 then
				chosen_panic_chatter = "controlpanic"
			else
				chosen_panic_chatter = "hostagepanic1" --less panicky "Delay the assault until those hostages are out." line
			end
		end
			
		if managers.groupai:state():chk_has_civilian_hostages() then
			--log("they got sausages!")
			if math_random() < 0.5 then
				chosen_panic_chatter = chosen_panic_chatter
			else
				chosen_panic_chatter = "civilianpanic"
			end
		end
			
	elseif managers.groupai:state():chk_had_hostages() then
		if math_random() < 0.4 then
			chosen_panic_chatter = "controlpanic"
		else
			chosen_panic_chatter = "hostagepanic3" -- no more hostages!!! full force!!!
		end
	end
	
	local chosen_sabotage_chatter = "sabotagegeneric" --set default sabotage chatter for variety's sake
	local skirmish_map = managers.skirmish:is_skirmish()--these shouldnt play on holdout
	local ignore_radio_rules = nil
	
	if objective and objective.bagjob then
		--log("oh, worm")
		chosen_sabotage_chatter = "sabotagebags"
		ignore_radio_rules = true
	elseif objective and objective.hostagejob then
		--log("sausage removal squadron")
		chosen_sabotage_chatter = "sabotagehostages"
		ignore_radio_rules = true 
	else
		chosen_sabotage_chatter = "sabotagegeneric" --if none of these levels are the current one, use a generic "Break their gear!" line
	end
		
	local clear_t_chk = not data.attention_obj or not data.attention_obj.verified_t or data.attention_obj.verified_t - data.t > math_random(2.5, 5)	
		
	local cant_say_clear = not data.attention_obj or AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and clear_t_chk
		
	if not data.unit:base():has_tag("special") and not cant_say_clear and not data.is_converted then
		if data.unit:movement():cool() and data.char_tweak.chatter and data.char_tweak.chatter.clear_whisper then            
			local roll = math.rand(1, 100)
			local whistle_chance = 50
			if roll <= whistle_chance then
				managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, "clear_whisper_2" )
				--log("whistle")
			else
				managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, "clear_whisper" )
				--log("reporting")
			end
		elseif not data.unit:movement():cool() then
			if not managers.groupai:state():chk_assault_active_atm() then
				if data.char_tweak.chatter and data.char_tweak.chatter.controlpanic then
					local clearchk = math_random(0, 90)
					local say_clear = 30
					if clearchk > 60 then
						managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, "clear" )
					elseif clearchk > 30 then
						if not skirmish_map and my_data.radio_voice or not skirmish_map and ignore_radio_rules then
							managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, chosen_sabotage_chatter )
						else
							managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, chosen_panic_chatter )
						end
					else
						managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, chosen_panic_chatter )
					end
				elseif data.char_tweak.chatter and data.char_tweak.chatter.clear then
					managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, "clear" )
				end
			end
		end
	end
	
	if data.unit:base():has_tag("special") and not cant_say_clear then
		if data.unit:base():has_tag("tank") or data.unit:base():has_tag("taser") then
			managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, "approachingspecial" )
		elseif data.unit:base()._tweak_table == "shield" then
			--fuck off
		elseif data.unit:base()._tweak_table == "akuma" then
			managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, "lotusapproach" )
		end
	end
		
	--mid-assault panic for cops based on alerts instead of opening fire, since its supposed to be generic action lines instead of for opening fire and such
	--I'm adding some randomness to these since the delays in groupaitweakdata went a bit overboard but also arent able to really discern things proper
				
	if data.char_tweak and data.char_tweak.chatter and data.char_tweak.chatter.enemyidlepanic and not data.is_converted then
		if not data.unit:base():has_tag("special") and data.unit:base():has_tag("law") then
			if managers.groupai:state():chk_assault_active_atm() then
				if managers.groupai:state():_check_assault_panic_chatter() then
					if data.attention_obj and data.attention_obj.verified and data.attention_obj.dis <= 500 or data.is_suppressed and data.attention_obj and data.attention_obj.verified then
						local roll = math_random(1, 100)
						local chance_suppanic = 50
						
						if roll <= chance_suppanic then
							local nroll = math_random(1, 100)
							local chance_help = 50
							if roll <= chance_suppanic then
								managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, "assaultpanicsuppressed1" )
							else
								managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, "assaultpanicsuppressed2" )
							end
						else
							managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, "assaultpanic" )
						end
					else
						if math_random() < 0.2 then
							managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, chosen_sabotage_chatter )
						else
							managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, "assaultpanic" )
						end
					end
				else
					local clearchk = math_random(0, 90)
						
					if clearchk > 60 then
						if not skirmish_map and my_data.radio_voice or not skirmish_map and ignore_radio_rules then
							managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, chosen_sabotage_chatter )
						end
					elseif chosen_panic_chatter == "civilianpanic" then
						managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, chosen_panic_chatter )
					end
				end
			end
		elseif not data.unit:base():has_tag("special") and data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and data.attention_obj.verified_t or not data.unit:base():has_tag("special") and data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and data.attention_obj.alert_t then
		
			if data.attention_obj.verified and data.attention_obj.dis <= 500 or data.is_suppressed and data.attention_obj.verified then
				local roll = math_random(1, 100)
				local chance_suppanic = 50
						
				if roll <= chance_suppanic then
					local nroll = math_random(1, 100)
					local chance_help = 50
					if roll <= chance_suppanic then
						managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, "assaultpanicsuppressed1" )
					else
						managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, "assaultpanicsuppressed2" )
					end
				else
					managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, "assaultpanic" )
				end
			else
				managers.groupai:state():chk_say_enemy_chatter( data.unit, data.m_pos, "assaultpanic" )
			end
			
		end	
	end
	
	data.logic._update_haste(data, data.internal_data)
	data.logic._upd_stance_and_pose(data, data.internal_data, objective)
      
    CopLogicTravel.queue_update(data, data.internal_data, delay)
end

function CopLogicTravel.chk_group_ready_to_move(data, my_data)
	local my_objective = data.objective

	if not my_objective.grp_objective then
		return true
	end

	local my_dis = mvector3.distance_sq(my_objective.area.pos, data.m_pos)

	if my_dis > 4000000 then
		return true
	end

	my_dis = my_dis * 1.15 * 1.15

	for u_key, u_data in pairs(data.group.units) do
		if u_key ~= data.key then
			local his_objective = u_data.unit:brain():objective()

			if his_objective and his_objective.grp_objective == my_objective.grp_objective and not his_objective.in_place then
				local his_dis = mvector3.distance_sq(his_objective.area.pos, u_data.m_pos)

				if my_dis < his_dis then
					return false
				end
			end
		end
	end

	return true
end

function CopLogicTravel._chk_request_action_walk_to_cover(data, my_data)
	CopLogicAttack._correct_path_start_pos(data, my_data.cover_path)
	
	local haste = nil
	
	local can_perform_walking_action = not data.unit:movement():chk_action_forbidden("walk") and not my_data.turning or data.unit:anim_data().act_idle
	local pose = nil
	
	local mook_units = {
		"security",
		"security_undominatable",
		"mute_security_undominatable",
		"security_mex",
		"security_mex_no_pager",
		"cop",
		"cop_scared",
		"cop_female",
		"dave",
		"gensec",
		"fbi",
		"fbi_vet",
		"fbi_vet_boss",
		"meme_man",
		"meme_man_shield",
		"vetlod",
		"swat",
		"swat_titan",
		"heavy_swat",
		"heavy_swat_sniper",
		"weekend_dmr",
		"fbi_swat",
		"fbi_heavy_swat",
		"city_swat",
		"city_swat_guard",
		"weekend",
		"city_swat_titan",
		"city_swat_titan_assault",
		"skeleton_swat_titan",
		"weekend_lmg",
		"gangster",
		"biker",
		"biker_guard",
		"mobster",
		"bolivian",
		"bolivian_indoors",
		"medic",
		"taser",
		"taser_titan",
		"boom",
		"spooc",
		"spooc_titan",
		"shadow_spooc",
		"tank_mini",
		"tank",
		"tank_medic"
	}
	local is_mook = nil
	for _, name in ipairs(mook_units) do
		if data.unit:base()._tweak_table == name then
			is_mook = true
		end
	end
	
	if can_perform_walking_action then 
		
		--enemies at long distances makes cops run, enemies at shorter distances makes cops walk, keeps pacing in small maps consistent and manageable, while making the cops seem cooler
		local pose_chk = not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.crouch
		local enemyseeninlast4secs = data.attention_obj and data.attention_obj.verified_t and data.t - data.attention_obj.verified_t < 4
		local enemy_seen_range_bonus = enemyseeninlast4secs and 500 or 0
		local enemy_has_height_difference = data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and data.attention_obj.dis >= 1200 and data.attention_obj.verified_t and data.t - data.attention_obj.verified_t < 4 and math.abs(data.m_pos.z - data.attention_obj.m_pos.z) > 250
		local height_difference_penalty = math.abs(data.m_pos.z - data.attention_obj.m_pos.z) < 250 and 400 or 0
		--local testing = true
		
		if data.unit:movement():cool() then
			haste = "walk"
		elseif data.tactics and data.tactics.legday then
			haste = "run"
		elseif data.attention_obj and data.attention_obj.dis > 10000 or data.team and data.team.id == tweak_data.levels:get_default_team_ID("player") or data.is_converted or data.unit:in_slot(16) or data.unit:in_slot(managers.slot:get_mask("criminals")) then
			haste = "run"
		elseif data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and data.attention_obj.dis > 800 + enemy_seen_range_bonus and not data.unit:movement():cool() and not managers.groupai:state():whisper_mode() then
			haste = "run"
		elseif data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and data.attention_obj.dis <= 800 + enemy_seen_range_bonus - height_difference_penalty and is_mook and data.tactics and not data.tactics.hitnrun then
			haste = "walk"
		else
			haste = "run"
		end
		
		local crouch_roll = math.random(0.01, 1)
		local stand_chance = nil
		local end_pose = nil
		local enemy_visible15m_or_10m_chk = data.attention_obj.verified and data.attention_obj.dis <= 1500 or data.attention_obj.dis <= 1000
	
		if data.attention_obj and data.attention_obj.dis > 10000 or data.team and data.team.id == tweak_data.levels:get_default_team_ID("player") or data.is_converted or data.unit:in_slot(16) or data.unit:in_slot(managers.slot:get_mask("criminals")) then
			stand_chance = 1
			pose = "stand"
			end_pose = "stand"
		elseif data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and data.attention_obj.dis > 2000 then
			stand_chance = 0.75
		elseif enemy_has_height_difference and pose_chk and is_mook then
			stand_chance = 0.25
		elseif data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and enemy_visible15m_or_10m_chk and CopLogicTravel._chk_close_to_criminal(data, my_data) and data.tactics and data.tactics.flank and haste == "walk" and is_mook then
			stand_chance = 0.25
		elseif my_data.moving_to_cover and pose_chk then
			stand_chance = 0.5
		else
			stand_chance = 1
			pose = "stand"
			end_pose = "stand"
		end
	
		--randomize enemy crouching to make enemies feel less easy to aim at, the fact they're always crouching all over the place always bugged me, plus, they shouldn't need to crouch so often when you're at long distances from them
		
		if not data.unit:movement():cool() and not managers.groupai:state():whisper_mode() then
			if stand_chance ~= 1 and crouch_roll > stand_chance and pose_chk or data.char_tweak.allowed_poses and data.char_tweak.allowed_poses.crouch then
				end_pose = "crouch"
				pose = "crouch"
			else
				end_pose = "stand"
				pose = "stand"
			end
		end
				
		if not pose then
			pose = not data.char_tweak.crouch_move and "stand" or data.char_tweak.allowed_poses and not data.char_tweak.allowed_poses.stand and "crouch" or "stand"
			end_pose = pose
		end
		
		if not data.unit:anim_data()[pose] then
			CopLogicAttack["_chk_request_action_" .. pose](data)
		end
		
		local new_action_data = {
			type = "walk",
			body_part = 2,
			pose = pose,
			nav_path = my_data.cover_path,
			variant = haste,
			end_pose = end_pose
		}
		my_data.cover_path = nil
		my_data.combat_cover_movement = data.unit:brain():action_request(new_action_data)

		if my_data.combat_cover_movement then
			my_data.at_cover_shoot_pos = nil
			my_data.in_cover = nil

			data.brain:rem_pos_rsrv("path")
		end
	end
end

function CopLogicTravel._chk_request_action_walk_to_cover_shoot_pos(data, my_data, path, speed)
	local can_perform_walking_action = not data.unit:movement():chk_action_forbidden("walk") and not my_data.turning or data.unit:anim_data().act_idle
	
	local pose = nil
	
	local mook_units = {
		"security",
		"security_undominatable",
		"mute_security_undominatable",
		"security_mex",
		"security_mex_no_pager",
		"cop",
		"cop_scared",
		"cop_female",
		"dave",
		"gensec",
		"fbi",
		"fbi_vet",
		"fbi_vet_boss",
		"meme_man",
		"meme_man_shield",
		"vetlod",
		"swat",
		"swat_titan",
		"heavy_swat",
		"heavy_swat_sniper",
		"weekend_dmr",
		"fbi_swat",
		"fbi_heavy_swat",
		"city_swat",
		"city_swat_guard",
		"weekend",
		"city_swat_titan",
		"city_swat_titan_assault",
		"skeleton_swat_titan",
		"weekend_lmg",
		"gangster",
		"biker",
		"biker_guard",
		"mobster",
		"bolivian",
		"bolivian_indoors",
		"medic",
		"taser",
		"taser_titan",
		"boom",
		"spooc",
		"spooc_titan",
		"shadow_spooc",
		"tank_mini",
		"tank",
		"tank_medic"
	}
	local is_mook = nil
	for _, name in ipairs(mook_units) do
		if data.unit:base()._tweak_table == name then
			is_mook = true
		end
	end
	
	local haste = nil
	
	if can_perform_walking_action then
		CopLogicAttack._cancel_cover_pathing(data, my_data)
		CopLogicAttack._cancel_charge(data, my_data)
		CopLogicAttack._correct_path_start_pos(data, path)
		
		--enemies at long distances makes cops run, enemies at shorter distances makes cops walk, keeps pacing in small maps consistent and manageable, while making the cops seem cooler
		local pose_chk = not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.crouch
		local enemyseeninlast4secs = data.attention_obj and data.attention_obj.verified_t and data.t - data.attention_obj.verified_t < 4
		local enemy_seen_range_bonus = enemyseeninlast4secs and 500 or 0
		local enemy_has_height_difference = data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and data.attention_obj.dis >= 1200 and data.attention_obj.verified_t and data.t - data.attention_obj.verified_t < 4 and math.abs(data.m_pos.z - data.attention_obj.m_pos.z) > 250
		local height_difference_penalty = math.abs(data.m_pos.z - data.attention_obj.m_pos.z) < 250 and 400 or 0
		--local testing = true
		
		if data.unit:movement():cool() then
			haste = "walk"
		elseif data.tactics and data.tactics.legday then
			haste = "run"
		elseif data.team and data.team.id == tweak_data.levels:get_default_team_ID("player") or data.is_converted or data.unit:in_slot(16) or data.unit:in_slot(managers.slot:get_mask("criminals")) or data.attention_obj and data.attention_obj.dis > 10000 then 
			haste = "run"
		elseif data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and data.attention_obj.dis > 800 + enemy_seen_range_bonus and not data.unit:movement():cool() and not managers.groupai:state():whisper_mode() then
			haste = "run"
		elseif data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and data.attention_obj.dis <= 800 + enemy_seen_range_bonus - height_difference_penalty and is_mook and data.tactics and not data.tactics.hitnrun then
			haste = "walk"
		else
			haste = "run"
		end
		
		local crouch_roll = math.random(0.01, 1)
		local stand_chance = nil
		local end_pose = nil
		
		local enemy_visible15m_or_10m_chk = data.attention_obj.verified and data.attention_obj.dis <= 1500 or data.attention_obj.dis <= 1000
		
		if data.attention_obj and data.attention_obj.dis > 10000 or data.team and data.team.id == tweak_data.levels:get_default_team_ID("player") or data.is_converted or data.unit:in_slot(16) or data.unit:in_slot(managers.slot:get_mask("criminals")) then
			stand_chance = 1
			pose = "stand"
			end_pose = "stand"
		elseif data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and data.attention_obj.dis > 2000 and is_mook then
			stand_chance = 0.75
		elseif enemy_has_height_difference and pose_chk and is_mook then
			stand_chance = 0.25
		elseif data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and enemy_visible15m_or_10m_chk and CopLogicTravel._chk_close_to_criminal(data, my_data) and data.tactics and data.tactics.flank and haste == "walk" and is_mook then
			stand_chance = 0.25
		elseif my_data.moving_to_cover and pose_chk then
			stand_chance = 0.5
		else
			stand_chance = 1
			pose = "stand"
			end_pose = "stand"
		end
	
		--randomize enemy crouching to make enemies feel less easy to aim at, the fact they're always crouching all over the place always bugged me, plus, they shouldn't need to crouch so often when you're at long distances from them
		
		if not data.unit:movement():cool() and not managers.groupai:state():whisper_mode() then
			if stand_chance ~= 1 and crouch_roll > stand_chance and pose_chk or data.char_tweak.allowed_poses and data.char_tweak.allowed_poses.crouch then
				end_pose = "crouch"
				pose = "crouch"
			else
				end_pose = "stand"
				pose = "stand"
			end
		end
				
		if not pose then
			pose = not data.char_tweak.crouch_move and "stand" or data.char_tweak.allowed_poses and not data.char_tweak.allowed_poses.stand and "crouch" or "stand"
			end_pose = pose
		end
		
		if not data.unit:anim_data()[pose] then
			CopLogicAttack["_chk_request_action_" .. pose](data)
		end
		
		local new_action_data = {
			body_part = 2,
			type = "walk",
			nav_path = path,
			pose = pose,
			end_pose = end_pose,
			variant = haste or "walk"
		}
		my_data.cover_path = nil
		my_data.walking_to_cover_shoot_pos = data.unit:brain():action_request(new_action_data)

		if my_data.walking_to_cover_shoot_pos then
			--my_data.walking_to_cover_shoot_pos = my_data.advancing
			my_data.at_cover_shoot_pos = nil
			my_data.in_cover = nil

			data.brain:rem_pos_rsrv("path")
		end
	end
end

function CopLogicTravel._chk_request_action_walk_to_advance_pos(data, my_data, speed, end_rot, no_strafe, pose, end_pose)
	if not data.unit:movement():chk_action_forbidden("walk") and not my_data.turning or data.unit:anim_data().act_idle then
		CopLogicAttack._correct_path_start_pos(data, my_data.advance_path)

		local path = my_data.advance_path
		local new_action_data = {
			type = "walk",
			body_part = 2,
			nav_path = path,
			variant = speed or "run",
			end_rot = end_rot,
			path_simplified = my_data.path_is_precise,
			no_strafe = no_strafe,
			pose = pose,
			end_pose = end_pose
		}
		my_data.advance_path = nil
		my_data.starting_advance_action = true
		my_data.advancing = data.unit:brain():action_request(new_action_data)
		my_data.starting_advance_action = false

		if my_data.advancing then
			data.brain:rem_pos_rsrv("path")
			
			if data.tactics then
				if data.objective.pos and my_data.coarse_path and my_data.coarse_path_index then
					local cur_index = my_data.coarse_path_index
					local total_nav_points = #my_data.coarse_path
					
					if cur_index == total_nav_points - 1 then
						local flash = nil
						if data.tactics.smoke_grenade or data.tactics.flash_grenade then
							if data.tactics.smoke_grenade and data.tactics.flash_grenade then
								local flashchance = math.random()
								
								if flashchance < 0.5 then
									flash = true
								end
							else
								if data.tactics.flash_grenade then
									flash = true
								end
							end
							
							CopLogicBase.do_grenade(data, data.objective.pos + math.UP * 5, flash)
						end
					end
				end
			end
			
			
			local notdelayclbksornotdlclbks_chk = not my_data.delayed_clbks or not my_data.delayed_clbks[my_data.cover_update_task_key]
			my_data.has_advanced_once = true
			if my_data.nearest_cover and notdelayclbksornotdlclbks_chk then
				CopLogicBase.add_delayed_clbk(my_data, my_data.cover_update_task_key, callback(CopLogicTravel, CopLogicTravel, "_update_cover", data), data.t + 0.066)
			end
			
			return true
		end
	end
end

function CopLogicTravel._chk_request_action_walk_to_optimal_pos(data, my_data, end_rot)
	if not data.unit:movement():chk_action_forbidden("walk") and not my_data.turning or data.unit:anim_data().act_idle then
		CopLogicAttack._correct_path_start_pos(data, my_data.optimal_path)
		--log("piss")
		local new_action_data = {
			type = "walk",
			body_part = 2,
			variant = "run",
			nav_path = my_data.optimal_path,
			end_rot = end_rot
		}
		my_data.optimal_path = nil
		my_data.walking_to_optimal_pos = data.unit:brain():action_request(new_action_data)

		if my_data.walking_to_optimal_pos then
			data.brain:rem_pos_rsrv("path")

			return true
		end
	end
end

function CopLogicTravel._chk_begin_advance(data, my_data)
	if my_data.turning or data.unit:movement():chk_action_forbidden("walk") then
		return
	end

	local objective = data.objective
	local haste = nil
	local pose = nil
	local can_perform_walking_action = true
	
	local mook_units = {
		"security",
		"security_undominatable",
		"mute_security_undominatable",
		"security_mex",
		"security_mex_no_pager",
		"cop",
		"cop_scared",
		"cop_female",
		"dave",
		"gensec",
		"fbi",
		"fbi_vet",
		"fbi_vet_boss",
		"meme_man",
		"meme_man_shield",
		"vetlod",
		"swat",
		"swat_titan",
		"heavy_swat",
		"heavy_swat_sniper",
		"weekend_dmr",
		"fbi_swat",
		"fbi_heavy_swat",
		"city_swat",
		"city_swat_guard",
		"weekend",
		"city_swat_titan",
		"city_swat_titan_assault",
		"skeleton_swat_titan",
		"weekend_lmg",
		"gangster",
		"biker",
		"biker_guard",
		"mobster",
		"bolivian",
		"bolivian_indoors",
		"medic",
		"taser",
		"taser_titan",
		"boom",
		"spooc",
		"spooc_titan",
		"shadow_spooc",
		"tank_mini",
		"tank",
		"tank_medic"
	}
	local is_mook = nil
	for _, name in ipairs(mook_units) do
		if data.unit:base()._tweak_table == name then
			is_mook = true
		end
	end
	
	--this is a mess, but it should keep enemy movement tacticool overall, by having them prefer slower apporoaches at close ranges
	if can_perform_walking_action then
		local pose_chk = not data.char_tweak.allowed_poses or data.char_tweak.allowed_poses.crouch
		local enemyseeninlast4secs = data.attention_obj and data.attention_obj.verified_t and data.t - data.attention_obj.verified_t < 4
		local enemy_seen_range_bonus = enemyseeninlast4secs and 500 or 0
		local enemy_has_height_difference = data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and data.attention_obj.dis >= 1200 and data.attention_obj.verified_t and data.t - data.attention_obj.verified_t < 4 and math_abs(data.m_pos.z - data.attention_obj.m_pos.z) > 250
		local height_difference_penalty = data.attention_obj and math_abs(data.m_pos.z - data.attention_obj.m_pos.z) < 250 and 400 or 0
		--local testing = true
		
		if data.unit:movement():cool() then
			haste = "walk"
		elseif data.tactics and data.tactics.legday then
			haste = "run"
		elseif data.team and data.team.id == tweak_data.levels:get_default_team_ID("player") or data.is_converted or data.unit:in_slot(16) or data.unit:in_slot(managers.slot:get_mask("criminals")) or data.attention_obj and data.attention_obj.dis > 10000 then
			haste = "run"
		elseif data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and data.attention_obj.dis > 800 + enemy_seen_range_bonus and not data.unit:movement():cool() and not managers.groupai:state():whisper_mode() then
			haste = "run"
		elseif data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and data.attention_obj.dis <= 800 + enemy_seen_range_bonus - height_difference_penalty and is_mook and data.tactics and not data.tactics.hitnrun then
			haste = "walk"
		else
			haste = "run"
		end

		local should_crouch = nil

		local end_rot = nil

		if my_data.coarse_path and my_data.coarse_path_index >= #my_data.coarse_path - 1 then
			end_rot = objective and objective.rot
		end

		local no_strafe, end_pose = nil
		
		local crouch_roll = math_random(0.01, 1)
		local stand_chance = nil
		local enemy_visible15m_or_10m_chk = data.attention_obj and data.attention_obj.verified and data.attention_obj.dis <= 1500 or data.attention_obj and data.attention_obj.dis <= 1000
		
		if data.attention_obj and data.attention_obj.dis > 10000 or data.unit:in_slot(16) or data.is_converted then
			stand_chance = 1
		elseif data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and data.attention_obj.dis > 2000 and is_mook then
			stand_chance = 0.75
		elseif enemy_has_height_difference and enemy_visible15m_or_10m_chk and is_mook then
			stand_chance = 0.25
		elseif data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and enemy_visible15m_or_10m_chk and CopLogicTravel._chk_close_to_criminal(data, my_data) and data.tactics and data.tactics.flank and haste == "walk" and is_mook then
			stand_chance = 0.25
		elseif my_data.moving_to_cover and pose_chk then
			stand_chance = 0.5
		else
			stand_chance = 0.5
		end
		
		--randomize enemy crouching to make enemies feel less easy to aim at, the fact they're always crouching all over the place always bugged me, plus, they shouldn't need to crouch so often when you're at long distances from them
		
		if not data.unit:movement():cool() and not managers.groupai:state():whisper_mode() then
			if data.char_tweak.allowed_poses and data.char_tweak.allowed_poses.crouch then
				end_pose = "crouch"
				pose = "crouch"
			elseif data.char_tweak.allowed_poses and data.char_tweak.allowed_poses.stand then
				end_pose = "stand"
				pose = "stand"
			elseif stand_chance ~= 1 and crouch_roll > stand_chance then
				end_pose = "crouch"
				pose = "crouch"
			else
				end_pose = "stand"
				pose = "stand"
			end
		end
		
		if not pose then
			pose = not data.char_tweak.crouch_move and "stand" or data.char_tweak.allowed_poses and not data.char_tweak.allowed_poses.stand and "crouch" or "stand"
		end
		
		if not data.unit:anim_data()[pose] then
			CopLogicAttack["_chk_request_action_" .. pose](data)
		end
		
		CopLogicTravel._chk_request_action_walk_to_advance_pos(data, my_data, haste, end_rot, no_strafe, pose, end_pose)
	end
end

function CopLogicTravel._chk_start_action_move_out_of_the_way(data, my_data)
	local my_tracker = data.unit:movement():nav_tracker()
	local reservation = {
		radius = 30,
		position = data.m_pos,
		filter = data.pos_rsrv_id
	}

	if not managers.navigation:is_pos_free(reservation) then
		local to_pos = CopLogicTravel._get_pos_on_wall(data.m_pos, 500)

		if to_pos then
			local path = {
				my_tracker:position(),
				to_pos
			}

			CopLogicTravel._chk_request_action_walk_to_cover_shoot_pos(data, my_data, path, "run")
		end
	end
end

function CopLogicTravel._chk_start_action_move_back(data, my_data, focus_enemy, engage, assault_break)

	local pantsdownchk = nil
	
	if focus_enemy.is_person and focus_enemy.is_husk_player or focus_enemy.is_person and focus_enemy.is_local_player then
		if focus_enemy.is_local_player then
			local e_movement_state = focus_enemy.unit:movement():current_state()
			if e_movement_state:_is_reloading() or e_movement_state:_interacting() or e_movement_state:is_equipping() then
				pantsdownchk = true
			end
		else
			local e_anim_data = focus_enemy.unit:anim_data()
			local movingoridle = e_anim_data.move or e_anim_data.idle
			if not movingoridle or e_anim_data.reload then
				pantsdownchk = true
			end
		end
	end
	
	local can_perform_walking_action = not my_data.turning and not data.unit:movement():chk_action_forbidden("walk") and not my_data.has_old_action
	
	if can_perform_walking_action then
	--what the fuck is my code rn tbh
		if focus_enemy and focus_enemy.nav_tracker and focus_enemy.verified and focus_enemy.dis < 250 and CopLogicAttack._can_move(data) or data.tactics and data.tactics.elite_ranged_fire and focus_enemy and focus_enemy.nav_tracker and focus_enemy.verified and focus_enemy.verified_dis <= 1500 and CopLogicAttack._can_move(data) or data.tactics and data.tactics.hitnrun and focus_enemy and focus_enemy.verified and focus_enemy.verified_dis <= 1000 and CopLogicAttack._can_move(data) or data.tactics and data.tactics.spoocavoidance and focus_enemy.verified and focus_enemy.aimed_at or data.tactics and data.tactics.reloadingretreat and focus_enemy and focus_enemy.verified then
			
			local from_pos = mvector3.copy(data.m_pos)
			local threat_tracker = focus_enemy.nav_tracker
			local threat_head_pos = focus_enemy.m_head_pos
			local max_walk_dis = nil
			local vis_required = nil
			
			if assault_break then 	
				max_walk_dis = 5000
				vis_required = nil
			elseif data.tactics and data.tactics.hitnrun then
				max_walk_dis = 800
			elseif data.tactics and data.tactics.elite_ranged_fire then
				max_walk_dis = 2000
				vis_required = true
			elseif data.tactics and data.tactics.spoocavoidance then
				max_walk_dis = 1500
			elseif data.tactics and data.tactics.reloadingretreat then
				max_walk_dis = 1500
			else
				max_walk_dis = 400
			end
				
			local retreat_to = CopLogicAttack._find_retreat_position(from_pos, focus_enemy.m_pos, threat_head_pos, threat_tracker, max_walk_dis, vis_required)

			if retreat_to then
				CopLogicAttack._cancel_cover_pathing(data, my_data)
				
				if data.unit:anim_data().move or data.unit:anim_data().run then
					local new_action = {
						body_part = 2,
						type = "idle"
					}
					data.unit:brain():action_request(new_action)
				end
					
				--if data.tactics and data.tactics.hitnrun or data.tactics and data.tactics.elite_ranged_fire then
					--log("hitnrun or eliteranged just backed up properly")
				--end
					
				if data.tactics and data.tactics.elite_ranged_fire then
					if not data.unit:in_slot(16) and data.char_tweak.chatter.dodge then
						managers.groupai:state():chk_say_enemy_chatter(data.unit, data.m_pos, "dodge")
					end
				end

				local new_action_data = {
					variant = "run",
					body_part = 2,
					type = "walk",
					nav_path = {
						from_pos,
						retreat_to
					}
				}
				my_data.retreating = data.unit:brain():action_request(new_action_data)
					
				if my_data.retreating then
					my_data.surprised = true
					
					local flash = nil
					
					if data.tactics.smoke_grenade or data.tactics.flash_grenade then
						if data.tactics.smoke_grenade and data.tactics.flash_grenade then
							local flashchance = math.random()
								
							if flashchance < 0.5 then
								flash = true
							end
						else
							if data.tactics.flash_grenade then
								flash = true
							end
						end
							
						CopLogicBase.do_grenade(data, data.m_pos + math.UP * 5, flash, true)
					end

					return true
				end
			end
		end
	end
end

function CopLogicTravel.action_complete_clbk(data, action)
	local my_data = data.internal_data
	local action_type = action:type()
	
	local engage_range = nil
	
	if my_data.weapon_range and my_data.weapon_range.close then
		engage_range = my_data.weapon_range.close
	else
		engage_range = 1500
	end
	
	if action_type == "act" then
		if not data.unit:in_slot(managers.slot:get_mask("criminals")) then
			if not data.unit:character_damage():dead() and action:expired() then
				if data.unit:base():has_tag("spooc") or data.unit:base()._tweak_table == "shadow_spooc" then
					SpoocLogicAttack._upd_spooc_attack(data, my_data)
				end
				CopLogicAttack._upd_aim(data, my_data)
				data.logic._upd_stance_and_pose(data, data.internal_data)
				CopLogicTravel._upd_combat_movement(data)
			end
		end
	elseif action_type == "healed" then
		CopLogicAttack._cancel_cover_pathing(data, my_data)
		CopLogicAttack._cancel_charge(data, my_data)
	
		if not data.unit:character_damage():dead() and action:expired() then
			if data.unit:base():has_tag("spooc") or data.unit:base()._tweak_table == "shadow_spooc" then
				SpoocLogicAttack._upd_spooc_attack(data, my_data)
			end
			CopLogicAttack._upd_aim(data, my_data)
			data.logic._upd_stance_and_pose(data, data.internal_data)
			CopLogicTravel._upd_combat_movement(data)
		end
	elseif action_type == "heal" then
		CopLogicAttack._cancel_cover_pathing(data, my_data)
		CopLogicAttack._cancel_charge(data, my_data)
	
		if not data.unit:character_damage():dead() and action:expired() then
			if data.unit:base():has_tag("spooc") or data.unit:base()._tweak_table == "shadow_spooc" then
				SpoocLogicAttack._upd_spooc_attack(data, my_data)
			end
			CopLogicAttack._upd_aim(data, my_data)
			data.logic._upd_stance_and_pose(data, data.internal_data)
			CopLogicTravel._upd_combat_movement(data)
		end
	elseif action_type == "walk" then
		if action:expired() and my_data.coarse_path and not my_data.starting_advance_action and my_data.coarse_path_index and not my_data.has_old_action and my_data.advancing then
			my_data.coarse_path_index = my_data.coarse_path_index + 1

			if my_data.coarse_path_index > #my_data.coarse_path then
				debug_pause_unit(data.unit, "[CopLogicTravel.action_complete_clbk] invalid coarse path index increment", data.unit, inspect(my_data.coarse_path), my_data.coarse_path_index)

				my_data.coarse_path_index = my_data.coarse_path_index - 1
			end
		end

		my_data.advancing = nil
		
		if my_data.retreating then
			if action:expired() then
				my_data.retreating = nil
				my_data.surprised = nil
				
				if data.unit:base():has_tag("spooc") or data.unit:base()._tweak_table == "shadow_spooc" then
					SpoocLogicAttack._upd_spooc_attack(data, my_data)
				end
				
				CopLogicAttack._upd_aim(data, my_data)
				data.logic._upd_stance_and_pose(data, data.internal_data)
				CopLogicTravel._upd_combat_movement(data, true)
			end
		elseif my_data.combat_cover_movement then
			if action:expired() then
				my_data.combat_cover_movement = nil
				
				if data.unit:base():has_tag("spooc") or data.unit:base()._tweak_table == "shadow_spooc" then
					SpoocLogicAttack._upd_spooc_attack(data, my_data)
				end
				
				CopLogicAttack._upd_aim(data, my_data)
				data.logic._upd_stance_and_pose(data, data.internal_data)
				CopLogicTravel._upd_combat_movement(data, true)
			end
		elseif my_data.walking_to_optimal_pos then
			if action:expired() then
				my_data.walking_to_optimal_pos = nil
				
				if data.unit:base():has_tag("spooc") or data.unit:base()._tweak_table == "shadow_spooc" then
					SpoocLogicAttack._upd_spooc_attack(data, my_data)
				end
				
				CopLogicAttack._upd_aim(data, my_data)
				data.logic._upd_stance_and_pose(data, data.internal_data)
				CopLogicTravel._upd_combat_movement(data, true)
			end
		elseif my_data.walking_to_cover_shoot_pos then
			if action:expired() then
				my_data.walking_to_cover_shoot_pos = nil
				my_data.at_cover_shoot_pos = true
				
				if data.unit:base():has_tag("spooc") or data.unit:base()._tweak_table == "shadow_spooc" then
					SpoocLogicAttack._upd_spooc_attack(data, my_data)
				end
				
				CopLogicAttack._upd_aim(data, my_data)
				data.logic._upd_stance_and_pose(data, data.internal_data)
				CopLogicTravel._upd_combat_movement(data, true)
			end
		elseif my_data.moving_to_cover then
			if action:expired() then
				if my_data.best_cover then
					managers.navigation:release_cover(my_data.best_cover[1])
				end

				my_data.best_cover = my_data.moving_to_cover

				CopLogicBase.chk_cancel_delayed_clbk(my_data, my_data.cover_update_task_key)

				local high_ray = CopLogicTravel._chk_cover_height(data, my_data.best_cover[1], data.visibility_slotmask)
				my_data.best_cover[4] = high_ray
				my_data.in_cover = true
				local cover_wait_time = 0
				
				if my_data.coarse_path then
				    cover_wait_time = my_data.coarse_path_index == #my_data.coarse_path - 1 and 0.3 or 0.6 + 0.4 * math.random()
				else
					cover_wait_time = 0.6 + 0.4 * math.random()
  			    end
				
				if not CopLogicTravel._chk_close_to_criminal(data, my_data) then
					cover_wait_time = 0
				end
				
				if data.tactics and data.tactics.haste then
					cover_wait_time = 0
				end

				my_data.cover_leave_t = data.t
				
				if data.unit:base():has_tag("spooc") or data.unit:base()._tweak_table == "shadow_spooc" then
					SpoocLogicAttack._upd_spooc_attack(data, my_data)
				end
				
				CopLogicAttack._upd_aim(data, my_data)
				data.logic._upd_stance_and_pose(data, data.internal_data)
				CopLogicTravel._upd_combat_movement(data, true)
			else
				managers.navigation:release_cover(my_data.moving_to_cover[1])

				if my_data.best_cover then
					local dis = mvector3.distance(my_data.best_cover[1][1], data.unit:movement():m_pos())

					if dis > 100 then
						managers.navigation:release_cover(my_data.best_cover[1])

						my_data.best_cover = nil
					end
				end
			end

			my_data.moving_to_cover = nil
		elseif my_data.best_cover then
			local dis = mvector3.distance(my_data.best_cover[1][1], data.unit:movement():m_pos())

			if dis > 100 then
				managers.navigation:release_cover(my_data.best_cover[1])

				my_data.best_cover = nil
			end
		end

		if not action:expired() then
			if my_data.processing_advance_path then
				local pathing_results = data.pathing_results

				if pathing_results and pathing_results[my_data.advance_path_search_id] then
					data.pathing_results[my_data.advance_path_search_id] = nil
					my_data.processing_advance_path = nil
				end
			elseif my_data.advance_path then
				my_data.advance_path = nil
			end

			data.unit:brain():abort_detailed_pathing(my_data.advance_path_search_id)
		end
	elseif action_type == "shoot" then		
		my_data.shooting = nil
	elseif action_type == "tase" then
		if not data.unit:character_damage():dead() and action:expired() and my_data.tasing then
			local record = managers.groupai:state():criminal_record(my_data.tasing.target_u_key)

			if record and record.status then
				data.tase_delay_t = TimerManager:game():time() + 45
			end
			CopLogicAttack._upd_aim(data, my_data)
			data.logic._upd_stance_and_pose(data, data.internal_data)
			CopLogicTravel._upd_combat_movement(data)
		end
		
		if my_data.tasing then
			managers.groupai:state():on_tase_end(my_data.tasing.target_u_key)
		end

		my_data.tasing = nil
	elseif action_type == "spooc" then
		data.spooc_attack_timeout_t = TimerManager:game():time() + math_lerp(data.char_tweak.spooc_attack_timeout[1], data.char_tweak.spooc_attack_timeout[2], math_random())

		if action:complete() and data.char_tweak.spooc_attack_use_smoke_chance > 0 and math_random() <= data.char_tweak.spooc_attack_use_smoke_chance and managers.groupai:state():is_smoke_grenade_active() then
			managers.groupai:state():detonate_smoke_grenade(data.m_pos + math_UP * 10, data.unit:movement():m_head_pos(), math_lerp(15, 30, math_random()), false)
		end
		
		if not data.unit:character_damage():dead() and action:expired() then
			CopLogicAttack._upd_aim(data, my_data)
			data.logic._upd_stance_and_pose(data, data.internal_data)
			CopLogicTravel._upd_combat_movement(data)
		end

		my_data.spooc_attack = nil
	elseif action_type == "reload" then
		--Removed the requirement for being important here.
		if not data.unit:character_damage():dead() and action:expired() then
			if data.unit:base():has_tag("spooc") or data.unit:base()._tweak_table == "shadow_spooc" then
				SpoocLogicAttack._upd_spooc_attack(data, my_data)
			end
			CopLogicAttack._upd_aim(data, my_data)
			data.logic._upd_stance_and_pose(data, data.internal_data)
			CopLogicTravel._upd_combat_movement(data)
		end
	elseif action_type == "turn" then
		if not data.unit:character_damage():dead() and action:expired() then
			if data.unit:base():has_tag("spooc") or data.unit:base()._tweak_table == "shadow_spooc" then
				SpoocLogicAttack._upd_spooc_attack(data, my_data)
			end
			CopLogicAttack._upd_aim(data, my_data)
			data.logic._upd_stance_and_pose(data, data.internal_data)
			CopLogicTravel._upd_combat_movement(data)
		end
		
		my_data.turning = nil
		
		local objective = data.objective
		local allow_trans, obj_failed = CopLogicBase.is_obstructed(data, objective, nil, nil)

		if allow_trans then
			local wanted_state = data.logic._get_logic_state_from_reaction(data)

			if wanted_state and wanted_state ~= data.name and obj_failed then
				if data.unit:in_slot(managers.slot:get_mask("enemies")) or data.unit:in_slot(17) then
					data.objective_failed_clbk(data.unit, data.objective)
				elseif data.unit:in_slot(managers.slot:get_mask("criminals")) then
					managers.groupai:state():on_criminal_objective_failed(data.unit, data.objective, false)
				end

				if my_data == data.internal_data then
					debug_pause_unit(data.unit, "[CopLogicTravel.action_complete_clbk] exiting without discarding objective", data.unit, inspect(data.objective))
					CopLogicBase._exit(data.unit, wanted_state)
				end
			end
		end
	elseif action_type == "hurt" then
		CopLogicAttack._cancel_cover_pathing(data, my_data)
		CopLogicAttack._cancel_charge(data, my_data)
		
		--Removed the requirement for being important here.
		if not data.unit:character_damage():dead() and action:expired() and not CopLogicBase.chk_start_action_dodge(data, "hit") then
			if data.unit:base():has_tag("spooc") or data.unit:base()._tweak_table == "shadow_spooc" then
				SpoocLogicAttack._upd_spooc_attack(data, my_data)
			end
			CopLogicAttack._upd_aim(data, my_data)
			data.logic._upd_stance_and_pose(data, data.internal_data)
			CopLogicTravel._upd_combat_movement(data)
		end
		
		local objective = data.objective
		local allow_trans, obj_failed = CopLogicBase.is_obstructed(data, objective, nil, nil)

		if allow_trans then
			local wanted_state = data.logic._get_logic_state_from_reaction(data)

			if wanted_state and wanted_state ~= data.name and obj_failed then
				if data.unit:in_slot(managers.slot:get_mask("enemies")) or data.unit:in_slot(17) then
					data.objective_failed_clbk(data.unit, data.objective)
				elseif data.unit:in_slot(managers.slot:get_mask("criminals")) then
					managers.groupai:state():on_criminal_objective_failed(data.unit, data.objective, false)
				end

				if my_data == data.internal_data then
					debug_pause_unit(data.unit, "[CopLogicTravel.action_complete_clbk] exiting without discarding objective", data.unit, inspect(data.objective))
					CopLogicBase._exit(data.unit, wanted_state)
				end
			end
		end
		
	elseif action_type == "dodge" then
		local timeout = action:timeout()

		if timeout then
			data.dodge_timeout_t = TimerManager:game():time() + math_lerp(timeout[1], timeout[2], math_random())
		end

		CopLogicAttack._cancel_cover_pathing(data, my_data)
		CopLogicAttack._cancel_charge(data, my_data)
		
		if not data.unit:character_damage():dead() and action:expired() then
			if data.unit:base():has_tag("spooc") or data.unit:base()._tweak_table == "shadow_spooc" then
				SpoocLogicAttack._upd_spooc_attack(data, my_data)
			end
			CopLogicAttack._upd_aim(data, my_data)
			data.logic._upd_stance_and_pose(data, data.internal_data)
			CopLogicTravel._upd_combat_movement(data)
		end
		
		local objective = data.objective
		local allow_trans, obj_failed = CopLogicBase.is_obstructed(data, objective, nil, nil)

		if allow_trans then
			local wanted_state = data.logic._get_logic_state_from_reaction(data)

			if wanted_state and wanted_state ~= data.name and obj_failed then
				if data.unit:in_slot(managers.slot:get_mask("enemies")) or data.unit:in_slot(17) then
					data.objective_failed_clbk(data.unit, data.objective)
				elseif data.unit:in_slot(managers.slot:get_mask("criminals")) then
					managers.groupai:state():on_criminal_objective_failed(data.unit, data.objective, false)
				end

				if my_data == data.internal_data then
					debug_pause_unit(data.unit, "[CopLogicTravel.action_complete_clbk] exiting without discarding objective", data.unit, inspect(data.objective))
					CopLogicBase._exit(data.unit, wanted_state)
				end
			end
		end
	end
end

function CopLogicTravel._find_cover(data, search_nav_seg, near_pos)
	local cover = nil
	local search_area = managers.groupai:state():get_area_from_nav_seg_id(search_nav_seg)
	local diff_index = tweak_data:difficulty_to_index(Global.game_settings.difficulty)
	local threat_tracker = nil
	local threat_area = nil
	local allow_fwd = nil
	local my_data = data.internal_data
	local my_pos = data.m_pos
	
	if data.objective and data.objective.type == "follow" and not data.tactics.lonewolf then
		if data.tactics and data.tactics.shield_cover and data.attention_obj and data.attention_obj.nav_tracker and data.attention_obj.reaction and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and not alive(data.unit:inventory() and data.unit:inventory()._shield_unit) then
			local threat_nav_pos = data.attention_obj.nav_tracker:field_position()

			local threat_pos = data.attention_obj.m_pos --the threat
			local shield_pos = mvec3_copy(data.objective.follow_unit:movement():m_pos()) --the pillar
			mvec3_dir(tmp_vec1, threat_pos, shield_pos)
			mvec3_norm(tmp_vec1)

			local near_pos = shield_pos + tmp_vec1 * 120
			local follow_unit_area = managers.groupai:state():get_area_from_nav_seg_id(data.objective.follow_unit:movement():nav_tracker():nav_segment())
			local objective_dis = data.objective.distance and data.objective.distance * 0.9 or nil
			local cover = managers.navigation:find_cover_in_nav_seg_3(follow_unit_area.nav_segs, objective_dis, near_pos, threat_nav_pos)

			if cover then
				return cover
			end
		elseif data.objective.follow_unit:movement():nav_tracker() then
			search_area = managers.groupai:state():get_area_from_nav_seg_id(data.objective.follow_unit:movement():nav_tracker():nav_segment())
		else
			search_area = managers.groupai:state():get_area_from_nav_seg_id(search_nav_seg)
		end
	else
		search_area = managers.groupai:state():get_area_from_nav_seg_id(search_nav_seg)
	end
	
	local want_to_take_cover = my_data.want_to_take_cover
	local flank_cover = my_data.flank_cover
	local min_dis, max_dis = nil
	
	if data.unit:movement():cool() then
		cover = managers.navigation:find_cover_in_nav_seg_1(search_area.nav_segs)
	else
		local optimal_threat_dis, threat_pos = nil
		
		optimal_threat_dis = 100
		allow_fwd = true
		
		if my_data.optimal_pos then
			near_pos = my_data.optimal_pos
		end
		
		near_pos = near_pos or search_area.pos
		
		if data.attention_obj and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and data.attention_obj.is_person and data.attention_obj.verified then
			threat_pos = data.attention_obj.m_pos
			threat_tracker = data.attention_obj.nav_tracker
			threat_area = managers.groupai:state():get_area_from_nav_seg_id(threat_tracker:nav_segment())
			--log("got an area!")
		elseif my_data.expected_pos then
			threat_pos = my_data.expected_pos
		else
			local all_criminals = managers.groupai:state():all_char_criminals()
			local closest_crim_u_data, closest_crim_dis = nil

			for u_key, u_data in pairs(all_criminals) do
				local crim_area = managers.groupai:state():get_area_from_nav_seg_id(u_data.tracker:nav_segment()) --this checks for the area any criminal units are standing in, this includes players and bots, keep in mind, this is nav-segment to nav-segment, so its map-dependant

				if crim_area == search_area then
					threat_pos = u_data.m_pos
					--near_pos = threat_pos
					threat_tracker = u_data.tracker
					threat_area = managers.groupai:state():get_area_from_nav_seg_id(threat_tracker:nav_segment())
					--log("got an area!")
					break
				else
					local crim_dis = mvec3_dis_sq(near_pos, u_data.m_pos)

					if not closest_crim_dis or crim_dis < closest_crim_dis then
						threat_pos = u_data.m_pos
						threat_tracker = u_data.tracker
						threat_area = managers.groupai:state():get_area_from_nav_seg_id(threat_tracker:nav_segment())
						closest_crim_dis = crim_dis
					end
				end
			end
		end
	end	
		
	if not cover then
		if my_data.optimal_pos then
			near_pos = my_data.optimal_pos
		end		
			
		cover = managers.navigation:find_cover_from_threat(search_area.nav_segs, optimal_threat_dis, near_pos, threat_pos)
			
		if cover then
			return cover
		end
	end

	return cover
end

function CopLogicTravel.get_pathing_prio(data)
	local prio = nil
	local objective = data.objective
	local focus_enemy = data.attention_obj
	
	if objective then
		prio = 4
		
		if (objective.follow_unit or objective.type == "phalanx") then
			prio = prio + 1
			
			if focus_enemy and AIAttentionObject.REACT_COMBAT <= data.attention_obj.reaction and focus_enemy.dis < 4000 then
				prio = prio + 2
			end
		end
		
		if data.team and data.team.id == tweak_data.levels:get_default_team_ID("player") or data.is_converted or data.unit:in_slot(16) or data.unit:in_slot(managers.slot:get_mask("criminals")) then
			prio = prio + 2
		end	
	end

	return prio
end

function CopLogicTravel._get_all_paths(data)
	return {
		optimal_path = data.internal_data.optimal_path,
		advance_path = data.internal_data.advance_path,
		cover_path = data.internal_data.cover_path,
		coarse_path = data.internal_data.coarse_path,
		flank_path = data.internal_data.flank_path,
		expected_pos_path = data.internal_data.expected_pos_path,
		charge_path = data.internal_data.charge_path
	}
end

function CopLogicTravel._set_verified_paths(data, verified_paths)
	data.internal_data.optimal_path = verified_paths.optimal_path
	data.internal_data.advance_path = verified_paths.advance_path
	data.internal_data.cover_path = verified_paths.cover_path
	data.internal_data.coarse_path = verified_paths.coarse_path
	data.internal_data.flank_path = verified_paths.flank_path
	data.internal_data.expected_pos_path = verified_paths.expected_pos_path
	data.internal_data.charge_path = verified_paths.charge_path
end

function CopLogicTravel._chk_start_pathing_to_next_nav_point(data, my_data)
	if not CopLogicTravel.chk_group_ready_to_move(data, my_data) then
		return
	end

	local to_pos = nil
	
	if data.objective.pos and my_data.coarse_path and my_data.coarse_path_index then
		local cur_index = my_data.coarse_path_index
		local total_nav_points = #my_data.coarse_path
		
		if cur_index == total_nav_points - 1 then
			to_pos = data.objective.pos
		end
	end
	
	if not to_pos and my_data.coarse_path_index then
		to_pos = CopLogicTravel._get_exact_move_pos(data, my_data.coarse_path_index + 1)
	end
	
	my_data.advance_pos = to_pos
	
	my_data.processing_advance_path = true
	local prio = CopLogicTravel.get_pathing_prio(data)
	local nav_segs = CopLogicTravel._get_allowed_travel_nav_segs(data, my_data, to_pos)

	data.unit:brain():search_for_path(my_data.advance_path_search_id, to_pos, prio, nil, nav_segs)
end

function CopLogicTravel.upd_advance(data)
	local unit = data.unit
	local my_data = data.internal_data
	local objective = data.objective
	local t = TimerManager:game():time()
	data.t = t

	if my_data.has_old_action then
		CopLogicAttack._upd_stop_old_action(data, my_data)
	elseif my_data.warp_pos then
		local action_desc = {
			body_part = 1,
			type = "warp",
			position = mvec3_copy(objective.pos),
			rotation = objective.rot
		}

		if unit:movement():action_request(action_desc) then
			CopLogicTravel._on_destination_reached(data)
			my_data.has_advanced_once = true
		end
	elseif my_data.advancing then
		if my_data.coarse_path then
			if my_data.announce_t and my_data.announce_t < t then
				CopLogicTravel._try_anounce(data, my_data)
			end
            
			--if data.is_converted then
			--    my_data.coarse_path = nil
			--end
			
			if not data.is_converted then
				CopLogicTravel._chk_stop_for_follow_unit(data, my_data)
			end

			if my_data ~= data.internal_data then
				return
			end
		end
	elseif my_data.advance_path then
		
		
		CopLogicTravel._chk_begin_advance(data, my_data)

		if my_data.advancing and my_data.path_ahead then
			CopLogicTravel._check_start_path_ahead(data)
		end
	elseif my_data.processing_advance_path or my_data.processing_coarse_path then
		CopLogicTravel._upd_pathing(data, my_data)

		if my_data ~= data.internal_data then
			return
		end
	elseif objective and (objective.nav_seg or objective.type == "follow") then
		if my_data.coarse_path then
			if my_data.coarse_path_index == #my_data.coarse_path then
				CopLogicTravel._on_destination_reached(data)
				
				return
			else
				CopLogicTravel._chk_start_pathing_to_next_nav_point(data, my_data)
			end
		else
			CopLogicTravel._begin_coarse_pathing(data, my_data)
		end
	else
		CopLogicBase._exit(data.unit, "idle")

		return
	end
end

function CopLogicTravel._chk_stop_for_follow_unit(data, my_data)
	local objective = data.objective

	if objective.type ~= "follow" or data.unit:movement():chk_action_forbidden("walk") or data.unit:anim_data().act_idle then
		return
	end

	if not my_data.coarse_path_index then
		debug_pause_unit(data.unit, "[CopLogicTravel._chk_stop_for_follow_unit]", data.unit, inspect(data), inspect(my_data))

		return
	end

	local follow_unit_nav_seg = data.objective.follow_unit:movement():nav_tracker():nav_segment()
	
	if not follow_unit_nav_seg or not my_data.coarse_path or not my_data.coarse_path_index or not my_data.coarse_path[my_data.coarse_path_index + 1] or not my_data.coarse_path[my_data.coarse_path_index + 1][1] then 
		--log("FUCKINGAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA")
		return
	end

	if my_data.coarse_path[my_data.coarse_path_index + 1] and follow_unit_nav_seg ~= my_data.coarse_path[my_data.coarse_path_index + 1][1] or my_data.coarse_path_index ~= #my_data.coarse_path - 1 then
		local my_nav_seg = data.unit:movement():nav_tracker():nav_segment()

		if follow_unit_nav_seg == my_nav_seg then
			objective.in_place = true

			data.logic.on_new_objective(data)
		end
	end
end