if SC and SC._data.sc_ai_toggle or restoration and restoration.Options:GetValue("SC/SC") then

	local math = math
	local mvec3_set = mvector3.set
	local mvec3_set_z = mvector3.set_z
	local mvec3_sub = mvector3.subtract
	local mvec3_dir = mvector3.direction
	local mvec3_dot = mvector3.dot
	local mvec3_dis = mvector3.distance
	local mvec3_dis_sq = mvector3.distance_sq
	local tmp_vec1 = Vector3()
	local tmp_vec2 = Vector3()
	local mvec3_add = mvector3.add
	local mvec3_ang = mvector3.angle
	local mvec3_cpy = mvector3.copy
	local mvec3_crs = mvector3.cross
	local mvec3_mul = mvector3.multiply
	local mvec3_set_len = mvector3.set_length
	local REACT_SHOOT = AIAttentionObject.REACT_SHOOT
	local REACT_SUSPICIOUS = AIAttentionObject.REACT_SUSPICIOUS
	local REACT_COMBAT = AIAttentionObject.REACT_COMBAT
	local REACT_SCARED = AIAttentionObject.REACT_SCARED
	local REACT_ARREST = AIAttentionObject.REACT_ARREST

	function CopLogicBase.chk_start_action_dodge(data, reason)
		if not data.char_tweak.dodge or not data.char_tweak.dodge.occasions[reason] then
			return
		end
		if data.dodge_timeout_t and data.t < data.dodge_timeout_t or data.dodge_chk_timeout_t and data.t < data.dodge_chk_timeout_t or data.unit:movement():chk_action_forbidden("walk") then
			return
		end
		local dodge_tweak = data.char_tweak.dodge.occasions[reason]
		data.dodge_chk_timeout_t = TimerManager:game():time() + math.lerp(dodge_tweak.check_timeout[1], dodge_tweak.check_timeout[2], math.random())
		if dodge_tweak.chance == 0 or math.random() > dodge_tweak.chance then
			return
		end
		local rand_nr = math.random()
		local total_chance = 0
		local variation, variation_data
		for test_variation, test_variation_data in pairs(dodge_tweak.variations) do
			total_chance = total_chance + test_variation_data.chance
			if test_variation_data.chance > 0 and rand_nr <= total_chance then
				variation = test_variation
				variation_data = test_variation_data
			else
			end
		end
		local dodge_dir = Vector3()
		local face_attention
		if data.attention_obj and data.attention_obj.reaction >= AIAttentionObject.REACT_COMBAT then
			mvec3_set(dodge_dir, data.attention_obj.m_pos)
			mvec3_sub(dodge_dir, data.m_pos)
			mvector3.set_z(dodge_dir, 0)
			mvector3.normalize(dodge_dir)
			if 0 > mvector3.dot(data.unit:movement():m_fwd(), dodge_dir) then
				return
			end
			mvector3.cross(dodge_dir, dodge_dir, math.UP)
			face_attention = true
		else
			mvector3.random_orthogonal(dodge_dir, math.UP)
		end
		local dodge_dir_reversed = false
		if math.random() < 0.5 then
			mvector3.negate(dodge_dir)
			dodge_dir_reversed = not dodge_dir_reversed
		end
		local prefered_space = 130
		local min_space = 90
		local ray_to_pos = tmp_vec1
		mvec3_set(ray_to_pos, dodge_dir)
		mvector3.multiply(ray_to_pos, 130)
		mvector3.add(ray_to_pos, data.m_pos)
		local ray_params = {
			tracker_from = data.unit:movement():nav_tracker(),
			pos_to = ray_to_pos,
			trace = true
		}
		local ray_hit1 = managers.navigation:raycast(ray_params)
		local dis
		if ray_hit1 then
			local hit_vec = tmp_vec2
			mvec3_set(hit_vec, ray_params.trace[1])
			mvec3_sub(hit_vec, data.m_pos)
			mvec3_set_z(hit_vec, 0)
			dis = mvector3.length(hit_vec)
			mvec3_set(ray_to_pos, dodge_dir)
			mvector3.multiply(ray_to_pos, -130)
			mvector3.add(ray_to_pos, data.m_pos)
			ray_params.pos_to = ray_to_pos
			local ray_hit2 = managers.navigation:raycast(ray_params)
			if ray_hit2 then
				mvec3_set(hit_vec, ray_params.trace[1])
				mvec3_sub(hit_vec, data.m_pos)
				mvec3_set_z(hit_vec, 0)
				local prev_dis = dis
				dis = mvector3.length(hit_vec)
				if prev_dis < dis and min_space < dis then
					mvector3.negate(dodge_dir)
					dodge_dir_reversed = not dodge_dir_reversed
				end
			else
				mvector3.negate(dodge_dir)
				dis = nil
				dodge_dir_reversed = not dodge_dir_reversed
			end
		end
		if ray_hit1 and dis and min_space > dis then
			return
		end
		local dodge_side
		if face_attention then
			dodge_side = dodge_dir_reversed and "l" or "r"
		else
			local fwd_dot = mvec3_dot(dodge_dir, data.unit:movement():m_fwd())
			local my_right = tmp_vec1
			mrotation.x(data.unit:movement():m_rot(), my_right)
			local right_dot = mvec3_dot(dodge_dir, my_right)
			if math.abs(fwd_dot) > 0.70710677 then
				if fwd_dot > 0 then
					dodge_side = "fwd"
				else
					dodge_side = "bwd"
				end
			elseif right_dot > 0 then
				dodge_side = "r"
			else
				dodge_side = "l"
			end
		end
		local body_part = 1
		local shoot_chance = variation_data.shoot_chance
		if shoot_chance and shoot_chance > 0 and shoot_chance > math.random() then
			body_part = 2
		end
		local action_data = {
			type = "dodge",
			body_part = body_part,
			variation = variation,
			side = dodge_side,
			direction = dodge_dir,
			timeout = variation_data.timeout,
			speed = data.char_tweak.dodge.speed,
			shoot_accuracy = variation_data.shoot_accuracy,
			blocks = {
				walk = -1,
				action = body_part == 1 and -1 or nil,
				act = -1,
				aim = body_part == 1 and -1 or nil,
				tase = -1,
				bleedout = -1,
				dodge = -1
			}
		}
		if variation ~= "side_step" then
			action_data.blocks.hurt = -1
			action_data.blocks.heavy_hurt = -1
		end
		if data.unit:base()._tweak_table == "fbi_vet" then	
			action_data.body_part = 2
			action_data.blocks.action = nil
			action_data.blocks.aim = nil
		end
		local action = data.unit:movement():action_request(action_data)
		if action then
			local my_data = data.internal_data
			CopLogicAttack._cancel_cover_pathing(data, my_data)
			CopLogicAttack._cancel_charge(data, my_data)
			CopLogicAttack._cancel_expected_pos_path(data, my_data)
			CopLogicAttack._cancel_walking_to_cover(data, my_data, true)
		end
		return action
	end

	function CopLogicBase._set_attention_obj(data, new_att_obj, new_reaction)
		local old_att_obj = data.attention_obj
		data.attention_obj = new_att_obj

		if new_att_obj then
			new_reaction = new_reaction or new_att_obj.settings.reaction
			new_att_obj.reaction = new_reaction
			local new_crim_rec = new_att_obj.criminal_record
			local is_same_obj, contact_chatter_time_ok = nil

			if old_att_obj then
				if old_att_obj.u_key == new_att_obj.u_key then
					is_same_obj = true
					contact_chatter_time_ok = new_crim_rec and data.t - new_crim_rec.det_t > 2

					if new_att_obj.stare_expire_t and new_att_obj.stare_expire_t < data.t and (not new_att_obj.settings.pause or data.t + math.lerp(new_att_obj.settings.pause[1], new_att_obj.settings.pause[2], math.random())) or new_att_obj.pause_expire_t and new_att_obj.pause_expire_t < data.t then
						if not new_att_obj.settings.attract_chance or math.random() < new_att_obj.settings.attract_chance then
							new_att_obj.pause_expire_t = nil
							new_att_obj.stare_expire_t = data.t + math.lerp(new_att_obj.settings.duration[1], new_att_obj.settings.duration[2], math.random())
						else
							debug_pause_unit(data.unit, "skipping attraction")

							new_att_obj.pause_expire_t = data.t + math.lerp(new_att_obj.settings.pause[1], new_att_obj.settings.pause[2], math.random())
						end
					end
				else
					if old_att_obj.criminal_record then
						managers.groupai:state():on_enemy_disengaging(data.unit, old_att_obj.u_key)
					end

					if new_crim_rec then
						managers.groupai:state():on_enemy_engaging(data.unit, new_att_obj.u_key)
					end

					contact_chatter_time_ok = new_crim_rec and data.t - new_crim_rec.det_t > 15
				end
			else
				if new_crim_rec then
					managers.groupai:state():on_enemy_engaging(data.unit, new_att_obj.u_key)
				end

				contact_chatter_time_ok = new_crim_rec and data.t - new_crim_rec.det_t > 15
			end

			if not is_same_obj then
				if new_att_obj.settings.duration then
					new_att_obj.stare_expire_t = data.t + math.lerp(new_att_obj.settings.duration[1], new_att_obj.settings.duration[2], math.random())
					new_att_obj.pause_expire_t = nil
				end

				new_att_obj.acquire_t = data.t
			end

			if AIAttentionObject.REACT_SHOOT <= new_reaction and new_att_obj.verified and contact_chatter_time_ok and (data.unit:anim_data().idle or data.unit:anim_data().move) and new_att_obj.is_person and data.char_tweak.chatter.contact then
				if data.unit:base()._tweak_table == "phalanx_vip" then
					data.unit:sound():say("a01", true)
				elseif data.unit:base()._tweak_table == "spring" then
					data.unit:sound():say("a01", true)					
				elseif data.char_tweak.speech_prefix_p1 == "l5d" then
					data.unit:sound():say("i01", true)						
				elseif data.unit:base()._tweak_table == "gensec" then
					data.unit:sound():say("a01", true)			
				elseif data.unit:base()._tweak_table == "security" then
					data.unit:sound():say("a01", true)		
				elseif data.unit:base()._tweak_table == "spooc" then
					data.unit:sound():say("clk_c01x_plu", true, true)						
				else
					data.unit:sound():say("c01", true)
				end
			end
		elseif old_att_obj and old_att_obj.criminal_record then
			managers.groupai:state():on_enemy_disengaging(data.unit, old_att_obj.u_key)
		end
	end

end

function CopLogicBase.should_duck_on_alert(data, alert_data)
	--this fucking sucks.
	
	--if data.char_tweak.allowed_poses and not data.char_tweak.allowed_poses.crouch or alert_data[1] == "voice" or data.unit:anim_data().crouch or data.unit:movement():chk_action_forbidden("walk") then
		--return
	--end

	--local lower_body_action = data.unit:movement()._active_actions[2]

	--if lower_body_action and lower_body_action:type() == "walk" and not data.char_tweak.crouch_move then
		--return
	--end
	
	return
end

function CopLogicBase._chk_nearly_visible_chk_needed(data, attention_info, u_key)
	return not attention_info.criminal_record or attention_info.is_human_player
end

function CopLogicBase._upd_attention_obj_detection(data, min_reaction, max_reaction)
	local t = data.t
	local detected_obj = data.detected_attention_objects
	local my_data = data.internal_data
	local my_key = data.key
	local my_pos = data.unit:movement():m_head_pos()
	local my_access = data.SO_access
	local all_attention_objects = managers.groupai:state():get_AI_attention_objects_by_filter(data.SO_access_str, data.team)
	local my_head_fwd = nil
	local my_tracker = data.unit:movement():nav_tracker()
	local chk_vis_func = my_tracker.check_visibility
	local is_detection_persistent = managers.groupai:state():is_detection_persistent()
	local delay = nil
	local diff_index = tweak_data:difficulty_to_index(Global.game_settings.difficulty)
	
	if diff_index == 8 or managers.skirmish:is_skirmish() or data.unit:base():has_tag("special") then
		delay = 0.35
	else
		delay = 0.7
	end
	
	if data.unit:base()._tweak_table == "spooc" then
		
	end
	
	--if CopLogicTravel.chk_slide_conditions(data) then 
		--data.unit:movement():play_redirect("e_nl_button_slide_under")
	--end
	
	local player_importance_wgt = data.unit:in_slot(managers.slot:get_mask("enemies")) and {}

	local function _angle_chk(attention_pos, dis, strictness)
		mvector3.direction(tmp_vec1, my_pos, attention_pos)

		my_head_fwd = my_head_fwd or data.unit:movement():m_head_rot():z()
		local angle = mvector3.angle(my_head_fwd, tmp_vec1)
		local angle_max = math.lerp(180, my_data.detection.angle_max, math.clamp((dis - 150) / 700, 0, 1))

		if angle_max > angle * strictness then
			return true
		end
	end

	local function _angle_and_dis_chk(handler, settings, attention_pos)
		attention_pos = attention_pos or handler:get_detection_m_pos()
		local dis = mvector3.direction(tmp_vec1, my_pos, attention_pos)
		local dis_multiplier, angle_multiplier = nil
		local max_dis = math.min(my_data.detection.dis_max, settings.max_range or my_data.detection.dis_max)

		if settings.detection and settings.detection.range_mul then
			max_dis = max_dis * settings.detection.range_mul
		end

		dis_multiplier = dis / max_dis

		if settings.uncover_range and my_data.detection.use_uncover_range and dis < settings.uncover_range then
			return -1, 0
		end

		if dis_multiplier < 1 then
			if settings.notice_requires_FOV then
				my_head_fwd = my_head_fwd or data.unit:movement():m_head_rot():z()
				local angle = mvector3.angle(my_head_fwd, tmp_vec1)

				if angle < 55 and not my_data.detection.use_uncover_range and settings.uncover_range and dis < settings.uncover_range then
					return -1, 0
				end

				local angle_max = math.lerp(180, my_data.detection.angle_max, math.clamp((dis - 150) / 700, 0, 1))
				angle_multiplier = angle / angle_max

				if angle_multiplier < 1 then
					return angle, dis_multiplier
				end
			else
				return 0, dis_multiplier
			end
		end
	end

	local function _nearly_visible_chk(attention_info, detect_pos)
		local near_pos = tmp_vec1

		if attention_info.verified_dis < 2000 and math.abs(detect_pos.z - my_pos.z) < 300 then
			mvec3_set(near_pos, detect_pos)
			mvec3_set_z(near_pos, near_pos.z + 100)

			local near_vis_ray = World:raycast("ray", my_pos, near_pos, "slot_mask", data.visibility_slotmask, "ray_type", "ai_vision", "report")

			if near_vis_ray then
				local side_vec = tmp_vec1

				mvec3_set(side_vec, detect_pos)
				mvec3_sub(side_vec, my_pos)
				mvector3.cross(side_vec, side_vec, math.UP)
				mvector3.set_length(side_vec, 150)
				mvector3.set(near_pos, detect_pos)
				mvector3.add(near_pos, side_vec)

				local near_vis_ray = World:raycast("ray", my_pos, near_pos, "slot_mask", data.visibility_slotmask, "ray_type", "ai_vision", "report")

				if near_vis_ray then
					mvector3.multiply(side_vec, -2)
					mvector3.add(near_pos, side_vec)

					near_vis_ray = World:raycast("ray", my_pos, near_pos, "slot_mask", data.visibility_slotmask, "ray_type", "ai_vision", "report")
				end
			end

			if not near_vis_ray then
				attention_info.nearly_visible = true
				attention_info.last_verified_pos = mvector3.copy(near_pos)
			end
		end
	end

	local function _chk_record_acquired_attention_importance_wgt(attention_info)
		if not player_importance_wgt or not attention_info.is_human_player then
			return
		end

		local weight = mvector3.direction(tmp_vec1, attention_info.m_head_pos, my_pos)
		local e_fwd = nil

		if attention_info.is_husk_player then
			e_fwd = attention_info.unit:movement():detect_look_dir()
		else
			e_fwd = attention_info.unit:movement():m_head_rot():y()
		end

		local dot = mvector3.dot(e_fwd, tmp_vec1)
		weight = weight * weight * (1 - dot)

		table.insert(player_importance_wgt, attention_info.u_key)
		table.insert(player_importance_wgt, weight)
	end

	local function _chk_record_attention_obj_importance_wgt(u_key, attention_info)
		if not player_importance_wgt then
			return
		end

		local is_human_player, is_local_player, is_husk_player = nil

		if attention_info.unit:base() then
			is_local_player = attention_info.unit:base().is_local_player
			is_husk_player = not is_local_player and attention_info.unit:base().is_husk_player
			is_human_player = is_local_player or is_husk_player
		end

		if not is_human_player then
			return
		end

		local weight = mvector3.direction(tmp_vec1, attention_info.handler:get_detection_m_pos(), my_pos)
		local e_fwd = nil

		if is_husk_player then
			e_fwd = attention_info.unit:movement():detect_look_dir()
		else
			e_fwd = attention_info.unit:movement():m_head_rot():y()
		end

		local dot = mvector3.dot(e_fwd, tmp_vec1)
		weight = weight * weight * (1 - dot)

		table.insert(player_importance_wgt, u_key)
		table.insert(player_importance_wgt, weight)
	end

	for u_key, attention_info in pairs(all_attention_objects) do
		if u_key ~= my_key and not detected_obj[u_key] and (not attention_info.nav_tracker or chk_vis_func(my_tracker, attention_info.nav_tracker)) then
			local settings = attention_info.handler:get_attention(my_access, min_reaction, max_reaction, data.team)

			if settings then
				local acquired = nil
				local attention_pos = attention_info.handler:get_detection_m_pos()

				if _angle_and_dis_chk(attention_info.handler, settings, attention_pos) then
					local vis_ray = World:raycast("ray", my_pos, attention_pos, "slot_mask", data.visibility_slotmask, "ray_type", "ai_vision")

					if not vis_ray or vis_ray.unit:key() == u_key then
						acquired = true
						detected_obj[u_key] = CopLogicBase._create_detected_attention_object_data(data.t, data.unit, u_key, attention_info, settings)
					end
				end

				if not acquired then
					_chk_record_attention_obj_importance_wgt(u_key, attention_info)
				end
			end
		end
	end

	for u_key, attention_info in pairs(detected_obj) do
		if t < attention_info.next_verify_t then
			if AIAttentionObject.REACT_SUSPICIOUS <= attention_info.reaction then
				delay = math.min(attention_info.next_verify_t - t, delay)
			end
		else
			attention_info.next_verify_t = t + (attention_info.identified and attention_info.verified and attention_info.settings.verification_interval or attention_info.settings.notice_interval or attention_info.settings.verification_interval)

			if not attention_info.identified then
				local noticable = nil
				local angle, dis_multiplier = _angle_and_dis_chk(attention_info.handler, attention_info.settings)

				if angle then
					local attention_pos = attention_info.handler:get_detection_m_pos()
					local vis_ray = World:raycast("ray", my_pos, attention_pos, "slot_mask", data.visibility_slotmask, "ray_type", "ai_vision")

					if not vis_ray or vis_ray.unit:key() == u_key then
						noticable = true
					end
				end

				local delta_prog = nil
				local dt = t - attention_info.prev_notice_chk_t

				if noticable then
					if angle == -1 then
						delta_prog = 1
					else
						local min_delay = my_data.detection.delay[1]
						local max_delay = my_data.detection.delay[2]
						local angle_mul_mod = 0.25 * math.min(angle / my_data.detection.angle_max, 1)
						local dis_mul_mod = 0.75 * dis_multiplier
						local notice_delay_mul = attention_info.settings.notice_delay_mul or 1

						if attention_info.settings.detection and attention_info.settings.detection.delay_mul then
							notice_delay_mul = notice_delay_mul * attention_info.settings.detection.delay_mul
						end

						local notice_delay_modified = math.lerp(min_delay * notice_delay_mul, max_delay, dis_mul_mod + angle_mul_mod)
						delta_prog = notice_delay_modified > 0 and dt / notice_delay_modified or 1
					end
				else
					delta_prog = dt * -0.125
				end

				attention_info.notice_progress = attention_info.notice_progress + delta_prog

				if attention_info.notice_progress > 1 then
					attention_info.notice_progress = nil
					attention_info.prev_notice_chk_t = nil
					attention_info.identified = true
					attention_info.release_t = t + attention_info.settings.release_delay
					attention_info.identified_t = t
					noticable = true

					data.logic.on_attention_obj_identified(data, u_key, attention_info)
				elseif attention_info.notice_progress < 0 then
					CopLogicBase._destroy_detected_attention_object_data(data, attention_info)

					noticable = false
				else
					noticable = attention_info.notice_progress
					attention_info.prev_notice_chk_t = t

					if data.cool and AIAttentionObject.REACT_SCARED <= attention_info.settings.reaction then
						managers.groupai:state():on_criminal_suspicion_progress(attention_info.unit, data.unit, noticable)
					end
				end

				if noticable ~= false and attention_info.settings.notice_clbk then
					attention_info.settings.notice_clbk(data.unit, noticable)
				end
			end

			if attention_info.identified then
				attention_info.nearly_visible = nil
				local verified, vis_ray = nil
				local attention_pos = attention_info.handler:get_detection_m_pos()
				local dis = mvector3.distance(data.m_pos, attention_info.m_pos)

				if dis < my_data.detection.dis_max * 1.2 and (not attention_info.settings.max_range or dis < attention_info.settings.max_range * (attention_info.settings.detection and attention_info.settings.detection.range_mul or 1) * 1.2) then
					local detect_pos = nil

					if attention_info.is_husk_player and attention_info.unit:anim_data().crouch then
						detect_pos = tmp_vec1

						mvector3.set(detect_pos, attention_info.m_pos)
						mvector3.add(detect_pos, tweak_data.player.stances.default.crouched.head.translation)
					else
						detect_pos = attention_pos
					end

					local in_FOV = not attention_info.settings.notice_requires_FOV or data.enemy_slotmask and attention_info.unit:in_slot(data.enemy_slotmask) or _angle_chk(attention_pos, dis, 0.8)

					if in_FOV then
						vis_ray = World:raycast("ray", my_pos, detect_pos, "slot_mask", data.visibility_slotmask, "ray_type", "ai_vision")

						if not vis_ray or vis_ray.unit:key() == u_key then
							verified = true
						end
					end

					attention_info.verified = verified
				end

				attention_info.dis = dis
				attention_info.vis_ray = vis_ray and vis_ray.dis or nil
				local is_ignored = false

				if attention_info.unit:movement() and attention_info.unit:movement().is_cuffed then
					is_ignored = attention_info.unit:movement():is_cuffed()
				end

				if is_ignored then
					CopLogicBase._destroy_detected_attention_object_data(data, attention_info)
				elseif verified then
					attention_info.release_t = nil
					attention_info.verified_t = t

					mvector3.set(attention_info.verified_pos, attention_pos)

					attention_info.last_verified_pos = mvector3.copy(attention_pos)
					attention_info.verified_dis = dis
				elseif data.enemy_slotmask and attention_info.unit:in_slot(data.enemy_slotmask) then
					if attention_info.criminal_record and AIAttentionObject.REACT_COMBAT <= attention_info.settings.reaction then
						if not is_detection_persistent and mvector3.distance(attention_pos, attention_info.criminal_record.pos) > 700 then
							CopLogicBase._destroy_detected_attention_object_data(data, attention_info)
						else
							--this lets cops use their buddies' vision to identify targets, maybe we should limit this to higher difficulties only?
							attention_info.verified_pos = mvector3.copy( attention_info.criminal_record.pos )
							attention_info.verified_dis = dis
							
							if vis_ray and data.logic._chk_nearly_visible_chk_needed(data, attention_info, u_key) then
								_nearly_visible_chk(attention_info, attention_pos)
							end
						end
					elseif attention_info.release_t and attention_info.release_t < t then
						CopLogicBase._destroy_detected_attention_object_data(data, attention_info)
					else
						attention_info.release_t = attention_info.release_t or t + attention_info.settings.release_delay
					end
				elseif attention_info.release_t and attention_info.release_t < t then
					CopLogicBase._destroy_detected_attention_object_data(data, attention_info)
				else
					attention_info.release_t = attention_info.release_t or t + attention_info.settings.release_delay
				end
			end
		end

		_chk_record_acquired_attention_importance_wgt(attention_info)
	end

	if player_importance_wgt then
		managers.groupai:state():set_importance_weight(data.key, player_importance_wgt)
	end

	return delay
end
