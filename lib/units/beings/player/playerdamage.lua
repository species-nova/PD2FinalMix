function PlayerDamage:init(unit)
	self._lives_init = tweak_data.player.damage.LIVES_INIT

	if Global.game_settings.one_down then
		self._lives_init = 2
	end

	self._lives_init = managers.modifiers:modify_value("PlayerDamage:GetMaximumLives", self._lives_init)
	self._unit = unit
	self._max_health_reduction = managers.player:upgrade_value("player", "max_health_reduction", 1)
	self._healing_reduction = managers.player:upgrade_value("player", "healing_reduction", 1)
	self._revives = Application:digest_value(0, true)
	self._uppers_elapsed = 0

	self:replenish()

	local player_manager = managers.player
	self._bleed_out_health = Application:digest_value(tweak_data.player.damage.BLEED_OUT_HEALTH_INIT * player_manager:upgrade_value("player", "bleed_out_health_multiplier", 1), true)
	self._god_mode = Global.god_mode
	self._invulnerable = false
	self._mission_damage_blockers = {}
	self._gui = Overlay:newgui()
	self._ws = self._gui:create_screen_workspace()
	self._focus_delay_mul = 1
	self._dmg_interval = tweak_data.player.damage.MIN_DAMAGE_INTERVAL
	self._next_allowed_dmg_t = Application:digest_value(-100, true)
	self._last_received_dmg = 0
	self._next_allowed_sup_t = -100
	self._last_received_sup = 0
	self._supperssion_data = {}
	self._inflict_damage_body = self._unit:body("inflict_reciever")

	self._inflict_damage_body:set_extension(self._inflict_damage_body:extension() or {})

	local body_ext = PlayerBodyDamage:new(self._unit, self, self._inflict_damage_body)
	self._inflict_damage_body:extension().damage = body_ext

	managers.sequence:add_inflict_updator_body("fire", self._unit:key(), self._inflict_damage_body:key(), self._inflict_damage_body:extension().damage)

	self._doh_data = tweak_data.upgrades.damage_to_hot_data or {}
	self._damage_to_hot_stack = {}
	self._armor_stored_health = 0
	self._can_take_dmg_timer = 0
	self._dodge_meter = 0 --Amount of dodge built up as meter.
	self._regen_on_the_side_timer = 0
	self._regen_on_the_side = false
	self._interaction = managers.interaction
	self._armor_regen_mul = managers.player:upgrade_value("player", "armor_regen_time_mul", 1)
	self._dire_need = managers.player:has_category_upgrade("player", "armor_depleted_stagger_shot")
	self._has_damage_speed = managers.player:has_inactivate_temporary_upgrade("temporary", "damage_speed_multiplier")
	self._has_damage_speed_team = managers.player:upgrade_value("player", "team_damage_speed_multiplier_send", 0) ~= 0

	local function revive_player()
		self:revive(true)
	end

	managers.player:register_message(Message.RevivePlayer, self, revive_player)

	self._current_armor_fill = 0
	local has_swansong_skill = player_manager:has_category_upgrade("temporary", "berserker_damage_multiplier")
	self._current_state = nil
	self._listener_holder = unit:event_listener()

	if player_manager:has_category_upgrade("player", "damage_to_armor") then
		local damage_to_armor_data = player_manager:upgrade_value("player", "damage_to_armor", nil)
		local armor_data = tweak_data.blackmarket.armors[managers.blackmarket:equipped_armor(true, true)]

		if damage_to_armor_data and armor_data then
			local idx = armor_data.upgrade_level
			self._damage_to_armor = {
				armor_value = damage_to_armor_data[idx][1],
				target_tick = damage_to_armor_data[idx][2],
				elapsed = 0
			}

			local function on_damage(damage_info)
				local attacker_unit = damage_info and damage_info.attacker_unit

				if alive(attacker_unit) and attacker_unit:base() and attacker_unit:base().thrower_unit then
					attacker_unit = attacker_unit:base():thrower_unit()
				end

				if self._unit == attacker_unit then
					local time = Application:time()

					if self._damage_to_armor.target_tick < time - self._damage_to_armor.elapsed then
						self._damage_to_armor.elapsed = time

						self:restore_armor(self._damage_to_armor.armor_value, true)
					end
				end
			end

			CopDamage.register_listener("on_damage", {
				"on_damage"
			}, on_damage)
		end
	end

	self._listener_holder:add("on_use_armor_bag", {
		"on_use_armor_bag"
	}, callback(self, self, "_on_use_armor_bag_event"))

	if self:_init_armor_grinding_data() then
		function self._on_damage_callback_func()
			return callback(self, self, "_on_damage_armor_grinding")
		end

		self:_add_on_damage_event()
		self._listener_holder:add("on_enter_bleedout", {
			"on_enter_bleedout"
		}, callback(self, self, "_on_enter_bleedout_event"))

		if has_swansong_skill then
			self._listener_holder:add("on_enter_swansong", {
				"on_enter_swansong"
			}, callback(self, self, "_on_enter_swansong_event"))
			self._listener_holder:add("on_exit_swansong", {
				"on_enter_bleedout"
			}, callback(self, self, "_on_exit_swansong_event"))
		end

		self._listener_holder:add("on_revive", {
			"on_revive"
		}, callback(self, self, "_on_revive_event"))
	else
		self:_init_standard_listeners()
	end

	if player_manager:has_category_upgrade("temporary", "revive_damage_reduction") then
		self._listener_holder:add("combat_medic_damage_reduction", {
			"on_revive"
		}, callback(self, self, "_activate_combat_medic_damage_reduction"))
	end

	if player_manager:has_category_upgrade("player", "revive_damage_reduction") and player_manager:has_category_upgrade("player", "revive_damage_reduction") then
		local function on_revive_interaction_start()
			managers.player:set_property("revive_damage_reduction", player_manager:upgrade_value("player", "revive_damage_reduction"), 1)
		end

		local function on_exit_interaction()
			managers.player:remove_property("revive_damage_reduction")
		end

		local function on_revive_interaction_success()
			managers.player:activate_temporary_upgrade("temporary", "revive_damage_reduction")
		end

		self._listener_holder:add("on_revive_interaction_start", {
			"on_revive_interaction_start"
		}, on_revive_interaction_start)
		self._listener_holder:add("on_revive_interaction_interrupt", {
			"on_revive_interaction_interrupt"
		}, on_exit_interaction)
		self._listener_holder:add("on_revive_interaction_success", {
			"on_revive_interaction_success"
		}, on_revive_interaction_success)
	end

	managers.mission:add_global_event_listener("player_regenerate_armor", {
		"player_regenerate_armor"
	}, callback(self, self, "_regenerate_armor"))
	managers.mission:add_global_event_listener("player_force_bleedout", {
		"player_force_bleedout"
	}, callback(self, self, "force_into_bleedout", false))

	local level_tweak = tweak_data.levels[managers.job:current_level_id()]

	if level_tweak and level_tweak.is_safehouse and not level_tweak.is_safehouse_combat then
		self:set_mission_damage_blockers("damage_fall_disabled", true)
		self:set_mission_damage_blockers("invulnerable", true)
	end

	self._delayed_damage = {
		epsilon = 0.001,
		chunks = {}
	}

	self:clear_delayed_damage()
end

function PlayerDamage:damage_bullet(attack_data)
	if not self:_chk_can_take_dmg() then
		return
	end

	local damage_info = {
		result = {
			variant = "bullet",
			type = "hurt"
		},
		attacker_unit = attack_data.attacker_unit
	}
	local pm = managers.player
	local dmg_mul = pm:damage_reduction_skill_multiplier("bullet")
	attack_data.damage = attack_data.damage * dmg_mul
	attack_data.damage = managers.mutators:modify_value("PlayerDamage:TakeDamageBullet", attack_data.damage)
	attack_data.damage = managers.modifiers:modify_value("PlayerDamage:TakeDamageBullet", attack_data.damage)

	if _G.IS_VR then
		local distance = mvector3.distance(self._unit:position(), attack_data.attacker_unit:position())

		if tweak_data.vr.long_range_damage_reduction_distance[1] < distance then
			local step = math.clamp(distance / tweak_data.vr.long_range_damage_reduction_distance[2], 0, 1)
			local mul = 1 - math.step(tweak_data.vr.long_range_damage_reduction[1], tweak_data.vr.long_range_damage_reduction[2], step)
			attack_data.damage = attack_data.damage * mul
		end
	end

	local damage_absorption = pm:damage_absorption()

	if damage_absorption > 0 then
		attack_data.damage = math.max(0, attack_data.damage - damage_absorption)
	end

	if self._god_mode then
		if attack_data.damage > 0 then
			self:_send_damage_drama(attack_data, attack_data.damage)
		end

		self:_call_listeners(damage_info)

		return
	elseif self._invulnerable or self._mission_damage_blockers.invulnerable then
		self:_call_listeners(damage_info)

		return
	elseif self:incapacitated() then
		return
	elseif self:is_friendly_fire(attack_data.attacker_unit) then
		return
	elseif self:_chk_dmg_too_soon(attack_data.damage) then
		return
	elseif self._unit:movement():current_state().immortal then
		return
	elseif self._revive_miss and math.random() < self._revive_miss then
		self:play_whizby(attack_data.col_ray.position)

		return
	end

	self._last_received_dmg = attack_data.damage
	self._next_allowed_dmg_t = Application:digest_value(pm:player_timer():time() + self._dmg_interval, true)
	local dodge_value = tweak_data.player.damage.DODGE_INIT or 0
	local armor_dodge_chance = pm:body_armor_value("dodge")
	local skill_dodge_chance = pm:skill_dodge_chance(self._unit:movement():running(), self._unit:movement():crouching(), self._unit:movement():zipline_unit())
	dodge_value = dodge_value + armor_dodge_chance + skill_dodge_chance

	if self._temporary_dodge_t and TimerManager:game():time() < self._temporary_dodge_t then
		dodge_value = dodge_value + self._temporary_dodge
	end

	local smoke_dodge = 0

	for _, smoke_screen in ipairs(managers.player._smoke_screen_effects or {}) do
		if smoke_screen:is_in_smoke(self._unit) then
			smoke_dodge = tweak_data.projectiles.smoke_screen_grenade.dodge_chance

			break
		end
	end

	dodge_value = 1 - (1 - dodge_value) * (1 - smoke_dodge)

	self._dodge_meter = self._dodge_meter + (dodge_value / 2) --Getting attacked gives half your dodge in meter.
		if self._dodge_meter >= 1.0 then --Dodge attacks if your meter is at '100'.
			self._unit:sound():play("pickup_fak_skill") --Auditory feedback, feel free to replace. It looks like play_whizby() is broken.
			if attack_data.damage > 0 then
				self._dodge_meter = self._dodge_meter - 1.0 --Dodging an attack lets excess dodge above '100' to roll over, so that dodge above 67 is still relevant.
			self:_send_damage_drama(attack_data, 0) --Resetting the meter feels bad to play with anyway.
		end
		self:_call_listeners(damage_info)
		self:play_whizby(attack_data.col_ray.position)
		self:_hit_direction(attack_data.attacker_unit:position())

		self._next_allowed_dmg_t = Application:digest_value(pm:player_timer():time() + self._dmg_interval, true)
		self._last_received_dmg = attack_data.damage

		managers.player:send_message(Message.OnPlayerDodge)
		managers.hud:set_dodge_value(self._dodge_meter, dodge_value) --Update dodge meter hud element, goes through Hudmanager.lua then HUDtemp.lua.
		return
		else
			self._dodge_meter = self._dodge_meter + (dodge_value / 2) --Taking damage gives the other half.
			if dodge_value > 0 then
				managers.hud:set_dodge_value(self._dodge_meter, dodge_value)
			end
	end

	if attack_data.attacker_unit:base()._tweak_table == "tank" then
		managers.achievment:set_script_data("dodge_this_fail", true)
	end

	if self:get_real_armor() > 0 then
		self._unit:sound():play("player_hit")
	else
		self._unit:sound():play("player_hit_permadamage")
	end

	local shake_armor_multiplier = pm:body_armor_value("damage_shake") * pm:upgrade_value("player", "damage_shake_multiplier", 1)
	local gui_shake_number = tweak_data.gui.armor_damage_shake_base / shake_armor_multiplier
	gui_shake_number = gui_shake_number + pm:upgrade_value("player", "damage_shake_addend", 0)
	shake_armor_multiplier = tweak_data.gui.armor_damage_shake_base / gui_shake_number
	local shake_multiplier = math.clamp(attack_data.damage, 0.2, 2) * shake_armor_multiplier

	self._unit:camera():play_shaker("player_bullet_damage", 1 * shake_multiplier)

	if not _G.IS_VR then
		managers.rumble:play("damage_bullet")
	end

	self:_hit_direction(attack_data.attacker_unit:position())
	pm:check_damage_carry(attack_data)

	attack_data.damage = managers.player:modify_value("damage_taken", attack_data.damage, attack_data)

	if self._bleed_out then
		self:_bleed_out_damage(attack_data)

		return
	end

	if not attack_data.ignore_suppression and not self:is_suppressed() then
		return
	end

	self:_check_chico_heal(attack_data)

	local armor_reduction_multiplier = 0

	if self:get_real_armor() <= 0 then
		armor_reduction_multiplier = 1
	end

	local health_subtracted = self:_calc_armor_damage(attack_data)

	if attack_data.armor_piercing then
		attack_data.damage = attack_data.damage - health_subtracted
	else
		attack_data.damage = attack_data.damage * armor_reduction_multiplier
	end

	health_subtracted = health_subtracted + self:_calc_health_damage(attack_data)

	if not self._bleed_out and health_subtracted > 0 then
		self:_send_damage_drama(attack_data, health_subtracted)
	elseif self._bleed_out and attack_data.attacker_unit and attack_data.attacker_unit:alive() and attack_data.attacker_unit:base()._tweak_table == "tank" then
		self._kill_taunt_clbk_id = "kill_taunt" .. tostring(self._unit:key())

		managers.enemy:add_delayed_clbk(self._kill_taunt_clbk_id, callback(self, self, "clbk_kill_taunt", attack_data), TimerManager:game():time() + tweak_data.timespeed.downed.fade_in + tweak_data.timespeed.downed.sustain + tweak_data.timespeed.downed.fade_out)
	end

	pm:send_message(Message.OnPlayerDamage, nil, attack_data)
	self:_call_listeners(damage_info)
end
