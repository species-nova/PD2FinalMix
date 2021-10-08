--Thanks Rocker
Hooks:PostHook(CivilianLogicSurrender,"_update_enemy_detection","stc_upd_sentry_aura",function(data,my_data) --self? what's a "self"

	local civ_pos = data.unit:movement():m_head_pos()	
	local all_deployables = World:find_units_quick("all",25)
	local dis_sentry = 1400 --max distance that sentries can intimidate at; would be a good name for a disease
	for k,unit in pairs(all_deployables) do 
		if not (unit and alive(unit)) then return end
		local this_dis = mvector3.direction(Vector3(),unit:position(),civ_pos)
--		local this_dis = mvector3.distance_sq(unit:position(),civ_pos)

		if this_dis < dis_sentry then 
			my_data.inside_intimidate_aura = true
			my_data.submission_meter = my_data.submission_max
			break
		end
	end
	
end)

function CivilianLogicSurrender.on_intimidated(data, amount, aggressor_unit, skip_delay)
	if data.is_tied then
		return
	end

	if not tweak_data.character[data.unit:base()._tweak_table].intimidateable or data.unit:base().unintimidateable or data.unit:anim_data().unintimidateable then
		return
	end

	skip_delay = true

	local my_data = data.internal_data

	CivilianLogicSurrender._delayed_intimidate_clbk(nil, {data, amount, aggressor_unit})
end

function CivilianLogicSurrender._delayed_intimidate_clbk(ignore_this, params)
	local data = params[1]
	local my_data = data.internal_data

	if my_data.delayed_intimidate_id then
		CopLogicBase.on_delayed_clbk(my_data, my_data.delayed_intimidate_id)

		my_data.delayed_intimidate_id = nil
	end

	if data.unit:movement():chk_action_forbidden("walk") then
		return
	end

	local amount = params[2]
	local anim_data = data.unit:anim_data()
	local adj_sumbission = amount * data.char_tweak.submission_intimidate
	my_data.submission_meter = math.min(my_data.submission_max, my_data.submission_meter + adj_sumbission)
	local adj_scare = amount * data.char_tweak.scare_intimidate
	my_data.scare_meter = math.max(0, my_data.scare_meter + adj_scare)

	if not anim_data.drop then
		if anim_data.react_enter and not anim_data.idle then

		elseif anim_data.react or anim_data.panic or anim_data.halt then
			local action_data = {
				clamp_to_graph = true,
				body_part = 1,
				type = "act",
				variant = anim_data.move and "halt" or "drop"
			}
			local action_res = data.unit:brain():action_request(action_data)

			if action_res and action_data.variant == "drop" then
				managers.groupai:state():unregister_fleeing_civilian(data.key)
				data.unit:interaction():set_tweak_data("intimidate")
				data.unit:interaction():set_active(true, true)

				my_data.interaction_active = true
			end
		else
			local action_data = {
				clamp_to_graph = true,
				variant = "panic",
				body_part = 1,
				type = "act"
			}

			data.unit:brain():action_request(action_data)
			data.unit:sound():say("a02x_any", true)

			if data.unit:unit_data().mission_element then
				data.unit:unit_data().mission_element:event("panic", data.unit)
			end

			if not managers.groupai:state():enemy_weapons_hot() then
				local alert = {
					"vo_distress",
					data.unit:movement():m_head_pos(),
					200,
					data.SO_access,
					data.unit
				}

				managers.groupai:state():propagate_alert(alert)
			end
		end
	end
end

function CivilianLogicSurrender.on_alert(data, alert_data)
	local alert_type = alert_data[1]

	if alert_type ~= "aggression" and alert_type ~= "bullet" and alert_type ~= "explosion" then
		return
	end

	local anim_data = data.unit:anim_data()

	if CopLogicBase.is_alert_aggressive(alert_data[1]) then
		local aggressor = alert_data[5]

		if aggressor and aggressor:base() then
			local is_intimidation = nil

			if aggressor:base().is_local_player then
				if managers.player:has_category_upgrade("player", "civ_calming_alerts") then
					is_intimidation = true
				end
			elseif aggressor:base().is_husk_player and aggressor:base():upgrade_value("player", "civ_calming_alerts") then
				is_intimidation = true
			end

			if is_intimidation and not data.is_tied then
				data.unit:brain():on_intimidated(1, aggressor)

				return
			end
		end
	end

	data.t = TimerManager:game():time()

	if not CopLogicBase.is_alert_dangerous(alert_data[1]) then
		return
	end

	local my_data = data.internal_data
	local scare_modifier = data.char_tweak.scare_shot

	if anim_data.halt or anim_data.react or anim_data.stand then
		scare_modifier = scare_modifier * 4
	end

	my_data.scare_meter = math.min(my_data.scare_max, my_data.scare_meter + scare_modifier)

	if my_data.scare_meter == my_data.scare_max then
		data.unit:sound():say("a01x_any", true)

		if not data.is_tied and not my_data.inside_intimidate_aura then
			data.unit:brain():set_objective({
				is_default = true,
				type = "free",
				alert_data = clone(alert_data)
			})
		end
	elseif not data.unit:sound():speaking(TimerManager:game():time()) then
		local rand = math.random()
		local alert_dis_sq = mvector3.distance_sq(data.m_pos, alert_data[2])
		local max_scare_dis_sq = 4000000

		if alert_dis_sq < max_scare_dis_sq then
			rand = math.lerp(rand, rand * 2, math.min(alert_dis_sq) / 4000000)
			local scare_mul = (max_scare_dis_sq - alert_dis_sq) / max_scare_dis_sq
			local max_nr_random_screams = 8
			scare_mul = scare_mul * math.lerp(1, 0.3, my_data.nr_random_screams / max_nr_random_screams)
			local chance_voice_1 = 0.3 * scare_mul
			local chance_voice_2 = 0.3 * scare_mul

			if data.char_tweak.female then
				chance_voice_1 = chance_voice_1 * 1.2
				chance_voice_2 = chance_voice_2 * 1.2
			end

			if rand < chance_voice_1 then
				data.unit:sound():say("a01x_any", true)

				my_data.nr_random_screams = math.min(my_data.nr_random_screams + 1, max_nr_random_screams)
			elseif rand < chance_voice_1 + chance_voice_2 then
				data.unit:sound():say("a02x_any", true)

				my_data.nr_random_screams = math.min(my_data.nr_random_screams + 1, max_nr_random_screams)
			end
		end
	end
end