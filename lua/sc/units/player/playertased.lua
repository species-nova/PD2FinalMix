function PlayerTased:enter(state_data, enter_data)
	PlayerTased.super.enter(self, state_data, enter_data)
	self._ids_tased_boost = Idstring("tased_boost")
	self._ids_tased = Idstring("tased")
	self._ids_counter_tase = Idstring("tazer_counter")
	self:_start_action_tased(managers.player:player_timer():time(), state_data.non_lethal_electrocution)
	if state_data.non_lethal_electrocution then
		state_data.non_lethal_electrocution = nil
		local recover_time = Application:time() + tweak_data.player.damage.STUN_TIME * managers.player:upgrade_value("player", "electrocution_resistance_multiplier", 1)
		self._recover_delayed_clbk = "PlayerTased_recover_delayed_clbk"
		
		managers.enemy:add_delayed_clbk(self._recover_delayed_clbk, callback(self, self, "clbk_exit_to_std"), recover_time)
	else
		self._fatal_delayed_clbk = "PlayerTased_fatal_delayed_clbk"
		local tased_time = tweak_data.player.damage.TASED_TIME
		--Taser Overcharge changed to allow for taser aim delays to be changed.
		managers.enemy:add_delayed_clbk(self._fatal_delayed_clbk, callback(self, self, "clbk_exit_to_fatal"), TimerManager:game():time() + tased_time)
	end

	self._next_shock = 0.5
	self._taser_value = 1
	self._num_shocks = 0

	managers.groupai:state():on_criminal_disabled(self._unit, "electrified")

	if Network:is_server() then
		self:_register_revive_SO()
	end

	--Removed free reload from being tased.

	local projectile_entry = managers.blackmarket:equipped_projectile()

	if tweak_data.blackmarket.projectiles[projectile_entry].is_a_grenade then
		self:_interupt_action_throw_grenade()
	else
		self:_interupt_action_throw_projectile()
	end

	self:_interupt_action_reload()
	self:_interupt_action_steelsight()
	self:_interupt_action_melee(managers.player:player_timer():time())
	self:_interupt_action_ladder(managers.player:player_timer():time())
	self:_interupt_action_charging_weapon(managers.player:player_timer():time())

	self._rumble_electrified = managers.rumble:play("electrified")
	self.tased = true
	self._state_data = state_data

	if managers.player:has_category_upgrade("player", "taser_malfunction") then
		local data = managers.player:upgrade_value("player", "taser_malfunction")

		if data then
			managers.player:register_message(Message.SendTaserMalfunction, "taser_malfunction", function ()
				self:_on_malfunction_to_taser_event()
			end)
			managers.player:add_coroutine("taser_malfunction", PlayerAction.TaserMalfunction, managers.player, data.interval, data.chance_to_trigger)
		end
	end

	if managers.player:has_category_upgrade("player", "escape_taser") then
		local interact_string = managers.localization:text("hud_int_escape_taser", {
			BTN_INTERACT = managers.localization:btn_macro("interact", false)
		})

		managers.hud:show_interact({
			icon = "mugshot_electrified",
			text = interact_string
		})

		local target_time = managers.player:upgrade_value("player", "escape_taser", 2)
		managers.player:add_coroutine("escape_tase", PlayerAction.EscapeTase, managers.player, managers.hud, Application:time() + target_time)

		--Instead directly call give_shock_to_taser().

		managers.player:register_message(Message.EscapeTase, "escape_tase", self:give_shock_to_taser())
	end

	CopDamage.register_listener("on_criminal_tased", {	
		"on_criminal_tased"	
	}, callback(self, self, "_on_tased_event"))
end

--Prevent tasers from putting players at downed health, and instead deal flat health damage.
Hooks:PostHook(PlayerTased, "clbk_exit_to_fatal", "ResTaseNoHealthChange", function(self)
	self._unit:character_damage():cloak_or_shock_incap(tweak_data.character.taser.shock_damage)
end)

--Adds animation to shockproof ace.
function PlayerTased:call_teammate(line, t, no_gesture, skip_alert)
	local voice_type, plural, prime_target = self:_get_unit_intimidation_action(true, false, false, true, false)
	local interact_type, queue_name = nil
	if voice_type == "stop_cop" or voice_type == "mark_cop" then
		local prime_target_tweak = tweak_data.character[prime_target.unit:base()._tweak_table]
		local shout_sound = prime_target_tweak.priority_shout

		if managers.groupai:state():whisper_mode() then
			shout_sound = prime_target_tweak.silent_priority_shout or shout_sound
		end

		if shout_sound then
			interact_type = "cmd_point"
			queue_name = "s07x_sin"
			if managers.player:has_category_upgrade("player", "special_enemy_highlight") then
				prime_target.unit:contour():add(managers.player:get_contour_for_marked_enemy(), true, managers.player:upgrade_value("player", "mark_enemy_time_multiplier", 1))
			end
			
			--Play Shockproof Aced Animation
			if prime_target.unit:base()._tweak_table == "taser" then
				if not self._tase_ended and managers.player:has_category_upgrade("player", "escape_taser") and prime_target.unit:key() == self._unit:character_damage():tase_data().attacker_unit:key() then
					self:_start_action_counter_tase(t, prime_target)
				end
			end

		end
	end

	if interact_type then
		self:_do_action_intimidate(t, not no_gesture and interact_type or nil, queue_name, skip_alert)
	end
end	

function PlayerTased:give_shock_to_taser()
	if not alive(self._counter_taser_unit) then
		return
	end

	--Remove return, since we now damage Tasers with Shockproof Ace.
	self:_give_shock_to_taser(self._counter_taser_unit)
end
	
function PlayerTased:_give_shock_to_taser(taser_unit)
	--Remove return, since we now damage Tasers with Shockproof Ace.

	local action_data = {
		variant = "counter_tased",
		damage = taser_unit:character_damage()._HEALTH_INIT * (tweak_data.upgrades.counter_taser_damage or 0.2),
		damage_effect = taser_unit:character_damage()._HEALTH_INIT * 2,
		attacker_unit = self._unit,
		attack_dir = -taser_unit:movement()._action_common_data.fwd,
		col_ray = {
			position = mvector3.copy(taser_unit:movement():m_head_pos()),
			body = taser_unit:body("body")
		}
	}

	taser_unit:character_damage():damage_melee(action_data)
	self._unit:sound():play("tase_counter_attack") --Add sound
end	