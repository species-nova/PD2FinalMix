local mvec3_set = mvector3.set
local mvec3_set_z = mvector3.set_z
local mvec3_lerp = mvector3.lerp
local mvec3_add = mvector3.add
local mvec3_sub = mvector3.subtract
local mvec3_mul = mvector3.multiply
local mvec3_norm = mvector3.normalize
local mvec3_len = mvector3.length
local mvec3_dir = mvector3.direction
local mvec3_cpy = mvector3.copy
local mvec3_dis = mvector3.distance
local mvec3_dot = mvector3.dot

local temp_vec1 = Vector3()
local temp_vec2 = Vector3()
local temp_vec3 = Vector3()

local mrot_set = mrotation.set_yaw_pitch_roll

local math_abs = math.abs
local math_min = math.min
local math_max = math.max
local math_clamp = math.clamp
local math_random = math.random
local math_ceil = math.ceil
local math_UP = math.UP
local math_lerp = math.lerp

local table_insert = table.insert
local table_remove = table.remove
local next_g = next

local alive_g = alive
local world_g = World

local ids_func = Idstring
local left_hand_str = ids_func("LeftHandMiddle2")
local ids_movement = ids_func("movement")

local old_init = CopMovement.init
local action_variants = {
	security = {
		idle = CopActionIdle,
		act = CopActionAct,
		walk = CopActionWalk,
		turn = CopActionTurn,
		hurt = CopActionHurt,
		stand = CopActionStand,
		crouch = CopActionCrouch,
		shoot = CopActionShoot,
		reload = CopActionReload,
		spooc = ActionSpooc,
		tase = CopActionTase,
		dodge = CopActionDodge,
		warp = CopActionWarp,
		healed = CopActionHealed
	}
}

local security_variant = action_variants.security
function CopMovement:init(unit)
	CopMovement._action_variants.dave = security_variant
	CopMovement._action_variants.cop_civ = security_variant
	CopMovement._action_variants.cop_forest = security_variant
	CopMovement._action_variants.gensec_guard = security_variant
	CopMovement._action_variants.fbi_female = security_variant
	CopMovement._action_variants.hrt = security_variant
	CopMovement._action_variants.fbi_swat_vet = security_variant
	CopMovement._action_variants.swat_titan = security_variant
	CopMovement._action_variants.city_swat_guard = security_variant
	CopMovement._action_variants.city_swat_titan = security_variant
	CopMovement._action_variants.city_swat_titan_assault = security_variant
	CopMovement._action_variants.skeleton_swat_titan = security_variant
	CopMovement._action_variants.weekend = security_variant
	CopMovement._action_variants.weekend_dmr = security_variant
	CopMovement._action_variants.weekend_lmg = security_variant
	CopMovement._action_variants.boom = security_variant
	CopMovement._action_variants.fbi_vet = security_variant
	CopMovement._action_variants.fbi_vet_boss = security_variant
	CopMovement._action_variants.vetlod = security_variant		
	CopMovement._action_variants.meme_man = security_variant		
	CopMovement._action_variants.meme_man_shield = clone(security_variant)
	CopMovement._action_variants.meme_man_shield.hurt = ShieldActionHurt
	CopMovement._action_variants.meme_man_shield.walk = ShieldCopActionWalk		
	CopMovement._action_variants.spring = clone(security_variant)
	CopMovement._action_variants.spring.walk = TankCopActionWalk
	CopMovement._action_variants.headless_hatman = clone(security_variant)
	CopMovement._action_variants.headless_hatman.walk = TankCopActionWalk
	CopMovement._action_variants.summers = clone(security_variant)
	CopMovement._action_variants.boom_summers = clone(security_variant)
	CopMovement._action_variants.boom_summers.heal = MedicActionHeal
	CopMovement._action_variants.taser_summers = clone(security_variant)
	CopMovement._action_variants.taser_summers.heal = MedicActionHeal
	CopMovement._action_variants.omnia_lpf = security_variant
	CopMovement._action_variants.medic_summers = clone(security_variant)
	CopMovement._action_variants.medic_summers.heal = MedicActionHeal
	CopMovement._action_variants.tank_titan = clone(security_variant)
	CopMovement._action_variants.tank_titan.walk = TankCopActionWalk
	CopMovement._action_variants.tank_titan_assault = clone(security_variant)
	CopMovement._action_variants.tank_titan_assault.walk = TankCopActionWalk
	CopMovement._action_variants.tank_biker = clone(security_variant)
	CopMovement._action_variants.tank_biker.walk = TankCopActionWalk
	CopMovement._action_variants.biker_guard = security_variant
	CopMovement._action_variants.phalanx_minion_assault = clone(security_variant)
	CopMovement._action_variants.phalanx_minion_assault.hurt = ShieldActionHurt
	CopMovement._action_variants.phalanx_minion_assault.walk = ShieldCopActionWalk
	CopMovement._action_variants.spooc_titan = security_variant
	CopMovement._action_variants.autumn = security_variant
	CopMovement._action_variants.taser_titan = clone(security_variant)

	old_init(self, unit)
end

function CopMovement:post_init()
	local unit = self._unit
	self._ext_brain = unit:brain()
	self._ext_network = unit:network()
	self._ext_anim = unit:anim_data()
	self._ext_base = unit:base()
	self._ext_damage = unit:character_damage()
	self._ext_inventory = unit:inventory()
	self._tweak_data = tweak_data.character[self._ext_base._tweak_table]

	tweak_data:add_reload_callback(self, self.tweak_data_clbk_reload)
	self._machine:set_callback_object(self)

	self._stance = {
		name = "ntl",
		code = 1,
		values = {
			1,
			0,
			0,
			0
		}
	}

	if managers.navigation:is_data_ready() then
		self._nav_tracker = managers.navigation:create_nav_tracker(self._m_pos)
		self._pos_rsrv_id = managers.navigation:get_pos_reservation_id()
	else
		--Application:error("[CopMovement:post_init] Spawned AI unit with incomplete navigation data.")
		self._unit:set_extension_update(ids_movement, false)
	end

	self._unit:kill_mover()
	self._unit:set_driving("script")

	self._unit:unit_data().has_alarm_pager = self._tweak_data.has_alarm_pager
	local event_list = {
		"bleedout",
		"light_hurt",
		"heavy_hurt",
		"expl_hurt",
		"hurt",
		"hurt_sick",
		"shield_knock",
		"knock_down",
		"stagger",
		"counter_tased",
		"taser_tased",
		"death",
		"fatal",
		"fire_hurt",
		"poison_hurt",
		"concussion",
		"healed"
	}

	self._unit:character_damage():add_listener("movement", event_list, callback(self, self, "damage_clbk"))
	self._unit:inventory():add_listener("movement", {
		"equip",
		"unequip"
	}, callback(self, self, "clbk_inventory"))
	self:add_weapons()

	if self._unit:inventory():is_selection_available(2) then
		if managers.groupai:state():whisper_mode() or not self._unit:inventory():is_selection_available(1) then
			self._unit:inventory():equip_selection(2, true)
		else
			self._unit:inventory():equip_selection(1, true)
		end
	elseif self._unit:inventory():is_selection_available(1) then
		self._unit:inventory():equip_selection(1, true)
	end

	if self._ext_inventory:equipped_selection() == 2 and managers.groupai:state():whisper_mode() then
		self._ext_inventory:set_weapon_enabled(false)
	end

	local weap_name = self._ext_base:default_weapon_name(managers.groupai:state():enemy_weapons_hot() and "primary" or "secondary")
	local fwd = self._m_rot:y()
	self._action_common_data = {
		stance = self._stance,
		pos = self._m_pos,
		rot = self._m_rot,
		fwd = fwd,
		right = self._m_rot:x(),
		unit = unit,
		machine = self._machine,
		ext_movement = self,
		ext_brain = self._ext_brain,
		ext_anim = self._ext_anim,
		ext_inventory = self._ext_inventory,
		ext_base = self._ext_base,
		ext_network = self._ext_network,
		ext_damage = self._ext_damage,
		char_tweak = self._tweak_data,
		nav_tracker = self._nav_tracker,
		active_actions = self._active_actions,
		queued_actions = self._queued_actions,
		look_vec = mvector3.copy(fwd)
	}

	self:upd_ground_ray()

	if self._gnd_ray then
		self:set_position(self._gnd_ray.position)
	end

	self:_post_init()
	self._aoe_blackout_cooldown = 0		

	local char_tweak = self._tweak_data

	if char_tweak.do_autumn_blackout then 
		managers.groupai:state():register_blackout_source(self._unit)
	end

	local tweak_name = self._unit:base()._tweak_table

	self._can_cloak = char_tweak.can_cloak
	self._cloaked = self._can_cloak

	local omnia_tweak = char_tweak.do_omnia
	if char_tweak.do_omnia and Network:is_server() then
		self._can_do_omnia = true
		self._omnia_cooldown = omnia_tweak.cooldown or 8
		self._next_omnia_t = 0
		self._omnia_radius = omnia_tweak.radius or 600
		self._omnia_slotmask = managers.slot:get_mask("enemies")
		self._overheal_specials = omnia_tweak.overheal_specials
	end

	if char_tweak.do_summers_heal and tweak_name == "medic_summers" then
		self._can_do_summers_heal = true
		self._summers_heal_cooldown = 0
		self._summers_heal_radius = tweak_data.medic.doc_radius
		self._summers_heal_slotmask = managers.slot:get_mask("enemies")
	end
end	

function CopMovement:_upd_actions(t)
	local a_actions = self._active_actions
	local has_no_action = true

	for i = 1, #a_actions do
		local action = a_actions[i]

		if action then
			if action.update then
				action:update(t)
			end

			if not self._need_upd and action.need_upd then
				self._need_upd = action:need_upd()
			end

			if action.expired and action:expired() then
				a_actions[i] = false

				if action.on_exit then
					action:on_exit()
				end

				self._ext_brain:action_complete_clbk(action)
				self._ext_base:chk_freeze_anims()
			else
				has_no_action = nil
			end
		end
	end

	if has_no_action then
		for i = 1, #a_actions do
			local action = a_actions[i]

			if action then
				has_no_action = nil

				break
			end
		end
	end

	if has_no_action then
		if not self._queued_actions or not next_g(self._queued_actions) then
			self:action_request({
				body_part = 1,
				type = "idle"
			})
		end
	end

	if not a_actions[1] then
		if not self._queued_actions or not next_g(self._queued_actions) then
			if not a_actions[2] then
				if not a_actions[3] or a_actions[3]:type() == "idle" then
					if not self:chk_action_forbidden("action") then
						self:action_request({
							body_part = 1,
							type = "idle"
						})
					end
				elseif not self:chk_action_forbidden("action") then
					self:action_request({
						body_part = 2,
						type = "idle"
					})
				end
			elseif a_actions[2]:type() == "idle" then
				if not a_actions[3] or a_actions[3]:type() == "idle" then
					if not self:chk_action_forbidden("action") then
						self:action_request({
							body_part = 1,
							type = "idle"
						})
					end
				end
			elseif not a_actions[3] and not self:chk_action_forbidden("action") then
				self:action_request({
					body_part = 3,
					type = "idle"
				})
			end
		end
	end

	self:_upd_stance(t)

	if not self._need_upd then
		if self._ext_anim.base_need_upd or self._ext_anim.upper_need_upd or self._ext_anim.fumble or self._stance.transition or self._suppression.transition then
			self._need_upd = true
		end
	end
end

function CopMovement:do_omnia(t)
	if not Network:is_server() or self._next_omnia_t > t then
		return
	end

	local enemies = world_g:find_units_quick(self._unit, "sphere", self._unit:position(), self._omnia_radius, self._omnia_slotmask)
	local healed_someone = nil
	for i = 1, #enemies do
		local enemy = enemies[i]
		if (self._overheal_specials or not enemy:base():char_tweak().is_special) and not enemy:character_damage():is_overhealed() then
			healed_someone = true
			managers.groupai:state():chk_say_enemy_chatter(self._unit, self._m_pos, "heal_chatter")
			self._next_omnia_t = t + self._omnia_cooldown
			enemy:character_damage():apply_overheal()
			
			local contour_ext = self._unit:contour()
			if contour_ext then
				contour_ext:add("medic_show", false)
				contour_ext:flash("medic_show", 0.2)
			end

			managers.network:session():send_to_peers_synched("sync_omnia_heal", self._unit, enemy)

			break
		end
	end

	if not healed_someone then
		self._next_omnia_t = t + 0.5
	end
end

function CopMovement:do_autumn_blackout()	--no longer used
	local test_kicker = false 
	
	--every [cooldown] seconds:
	-- check all equipment units with equipment tweakdata tag "blackout_vulnerable"
	-- for each of these units:
		-- if (in surrounding [radius] area): set var "blackout_active" to "true
		-- else: set var "blackout_active" 

	local t = TimerManager:main():time()

	if self._aoe_blackout_cooldown > t then
		return
	else
		self._aoe_blackout_cooldown = t + 1
	end
	
	if self._unit then
		if self._unit:character_damage():dead() then return end --autumn's corpse will still disable equipment otherwise
		
		local all_eq = world_g:find_units_quick("all",14,25,26)
		local closest = { --not currently used
			--unit = false, 
			--distance = math.huge()
		}
		for k,unit in pairs(all_eq) do 
			if unit and alive_g(unit) and unit:base() then
				
				local dis = mvector3.distance_sq(self._unit:position(),unit:position())
				if unit:interaction() and unit:interaction()._tweak_data and unit:interaction()._tweak_data.blackout_vulnerable then 
					if not test_kicker then 
						if dis < blackout_radius and not unit:base().blackout_active then --within blackout aoe
							if unit:base().get_name_id then 
								local eq_id = unit:base():get_name_id() or "ERROR"
								if eq_id == "sentry_gun" then --perish
									unit:character_damage():die()
								elseif eq_id == "ecm_jammer" then 
									unit:base():set_battery_empty()
									unit:base():_set_feedback_active(false)
								end
							end
							
							unit:base().blackout_active = true
							
							if unit.contour and unit:contour() then 
								unit:contour():add("deployable_blackout")
							end
						elseif dis >= blackout_radius and unit:base().blackout_active then
						
							unit:base().blackout_active = false
							
							if unit.contour and unit:contour() then 
								unit:contour():remove("deployable_blackout")
							end
						end
					elseif (dis < (closest.distance or blackout_radius)) then --do dick kickem
						closest = {
							distance = distance,
							unit = unit
						}
					end 
				end
			end
		end
		if test_kicker then  --unused

			if closest.unit then 
				local followup_objective = {
					type = "act",
					scan = true,
					action = {type = "act", body_part = 1, variant = "crouch", 
								blocks = {action = -1, walk = -1, hurt = -1, heavy_hurt = -1, aim = -1}
							}
					}
				local act = "e_so_container_kick"
				local override_objective = {
					type = act,
					follow_unit = self._unit,
					called = true,
					destroy_clbk_key = false,
					nav_seg = self._nav_tracker:nav_segment(),
					pos = closest.unit:position(),
					scan = true,
					action = {
						type = "act", 
						variant = act,
						body_part = 1,
						blocks = {action = -1, walk = -1, hurt = -1, light_hurt = -1, heavy_hurt = -1 ,aim = -1},
						align_sync = true,
						},
					action_duration = 3,
					followup_objective = followup_objective,
					complete_clbk = callback(self,self,"clbk_autumn_blackout_complete"),
					fail_clbk = callback(self,self,"clbk_autumn_blackout_cancel")
					
				}
				self._ext_brain:set_objective(override_objective)
			end
		end
	end
end

function CopMovement:do_summers_heal(t)
	local enemies = managers.enemy._registered_summers_crew
	local summers = managers.enemy._summers
	
	if not next(summers) and not next(enemies) then
		return
	end
	
	if self._summers_heal_cooldown > t then
		return
	else
		local cooldown = 0.4
		
		for i = 1, #enemies do
			local enemy = enemies[i]
			
			if enemy:key() ~= self._unit:key() then
				cooldown = cooldown - 0.15
			end
		end
		
		math_clamp(cooldown, 0.01, 0.4) --in case, either due to mutators or whatever, theres multiple summer teams
			
		self._summers_heal_cooldown = t + cooldown
	end
	
	local healed_someone = nil
	
	for i = 1, #enemies do
		local enemy = enemies[i]
		
		if enemy:key() ~= self._unit:key() then
			local dmg_ext = enemy:character_damage()
			local health_left = dmg_ext._health
			local max_health = dmg_ext._HEALTH_INIT

			if health_left < max_health then
				healed_someone = true

				local amount_to_heal = math_ceil(((max_health - health_left) / 20))
				
				local contour_ext = enemy:contour()

				if contour_ext and not contour_ext:is_flashing() then
					contour_ext:remove("medic_heal", false)
					contour_ext:add("medic_heal", false)
					contour_ext:flash("medic_heal", 0.2)
				end
					
				dmg_ext:_apply_damage_to_health((amount_to_heal * -1))	
			end
		end
	end
	
	for i = 1, #summers do
		local summer = summers[i]
		
		local dmg_ext = summer:character_damage()
		local health_left = dmg_ext._health
		local max_health = dmg_ext._HEALTH_INIT

		if health_left < max_health then
			healed_someone = true

			local amount_to_heal = math_ceil(((max_health - health_left) / 20))
			local contour_ext = summer:contour()

			if contour_ext and not contour_ext:is_flashing() then
				contour_ext:remove("medic_heal", false)
				contour_ext:add("medic_heal", false)
				contour_ext:flash("medic_heal", 0.2)
			end

			dmg_ext:_apply_damage_to_health((amount_to_heal * -1))							
		end
	end

	if healed_someone then
		local contour_ext = self._unit:contour()

		if contour_ext and not contour_ext:is_flashing() then
			contour_ext:remove("medic_show", false)
			contour_ext:add("medic_show", false)
			contour_ext:flash("medic_show", 0.2)
		end

		if Network:is_server() then
			managers.groupai:state():chk_say_enemy_chatter(self._unit, self._m_pos, "heal_chatter")
		end
	end
end

function CopMovement:play_redirect(redirect_name, at_time)
	if redirect_name == "throw_grenade" then
		if self._unit:in_slot(16) or self._unit:in_slot(22) or self._unit:base()._tweak_table == "boom" or self._unit:base()._tweak_table == "shield" or self._unit:base()._tweak_table == "phalanx_minion" or self._unit:base()._tweak_table == "phalanx_minion_assault" or self._unit:base()._tweak_table == "phalanx_vip" then
			return
		end
	end

	local result = self._unit:play_redirect(ids_func(redirect_name), at_time)

	return result ~= ids_func("") and result
end

function CopMovement:on_suppressed(state)
	local suppression = self._suppression
	local end_value = state and 1 or 0
	local vis_state = self._ext_base:lod_stage() 

	--vis_state is used to do a smooth transition instead of snapping into the suppressed stance
	--as long as the enemy is visible
	if vis_state and end_value ~= suppression.value then
		local t = TimerManager:game():time()
		local duration = 0.5 * math.abs(end_value - suppression.value)
		suppression.transition = {
			end_val = end_value,
			start_val = suppression.value,
			duration = duration,
			start_t = t,
			next_upd_t = t + 0.07
		}
	else
		suppression.transition = nil
		suppression.value = end_value

		self._machine:set_global("sup", end_value)
	end

	self._action_common_data.is_suppressed = state and true or nil

	if Network:is_server() then
		if state then
			if not self._tweak_data.allowed_poses or self._tweak_data.allowed_poses.crouch then
				if not self._tweak_data.allowed_poses or self._tweak_data.allowed_poses.stand then
					if not self:chk_action_forbidden("walk") then
						local try_something_else = true

						if state == "panic" and not self:chk_action_forbidden("act") then
							if self._ext_anim.run and self._ext_anim.move_fwd then
								local action_desc = {
									clamp_to_graph = true,
									type = "act",
									body_part = 1,
									variant = "e_so_sup_fumble_run_fwd",
									blocks = {
										action = -1,
										walk = -1
									}
								}

								if self:action_request(action_desc) then
									try_something_else = false
								end
							else
								local allow = nil
								local vec_from = temp_vec1
								local vec_to = temp_vec2
								local ray_params = {
									allow_entry = false,
									trace = true,
									tracker_from = self:nav_tracker(),
									pos_from = vec_from,
									pos_to = vec_to
								}
								local allowed_fumbles = {
									"e_so_sup_fumble_inplace_3"
								}

								mvec3_set(ray_params.pos_from, self:m_pos())
								mvec3_set(ray_params.pos_to, self:m_rot():y())
								mvec3_mul(ray_params.pos_to, -100)
								mvec3_add(ray_params.pos_to, self:m_pos())

								allow = not managers.navigation:raycast(ray_params)

								if allow then
									table.insert(allowed_fumbles, "e_so_sup_fumble_inplace_1")
								end

								mvec3_set(ray_params.pos_from, self:m_pos())
								mvec3_set(ray_params.pos_to, self:m_rot():x())
								mvec3_mul(ray_params.pos_to, 200)
								mvec3_add(ray_params.pos_to, self:m_pos())

								allow = not managers.navigation:raycast(ray_params)

								if allow then
									table.insert(allowed_fumbles, "e_so_sup_fumble_inplace_2")
								end

								mvec3_set(ray_params.pos_from, self:m_pos())
								mvec3_set(ray_params.pos_to, self:m_rot():x())
								mvec3_mul(ray_params.pos_to, -200)
								mvec3_add(ray_params.pos_to, self:m_pos())

								allow = not managers.navigation:raycast(ray_params)

								if allow then
									table.insert(allowed_fumbles, "e_so_sup_fumble_inplace_4")
								end

								if #allowed_fumbles > 0 then
									local action_desc = {
										body_part = 1,
										type = "act",
										variant = allowed_fumbles[math.random(#allowed_fumbles)],
										blocks = {
											action = -1,
											walk = -1
										}
									}

									if self:action_request(action_desc) then
										try_something_else = false
									end
								end
							end
						end

						if try_something_else and not self._ext_anim.crouch then
							if self._tweak_data.can_slide_on_suppress and not self._ext_anim.run and self._ext_anim.move_fwd and not self:chk_action_forbidden("act") then
								local allow = nil
								local vec_from = temp_vec1
								local vec_to = temp_vec2
								local ray_params = {
									allow_entry = false,
									trace = true,
									tracker_from = self:nav_tracker(),
									pos_from = vec_from,
									pos_to = vec_to
								}

								mvec3_set(ray_params.pos_from, self:m_pos())
								mvec3_set(ray_params.pos_to, self:m_rot():y())
								mvec3_mul(ray_params.pos_to, 380)
								mvec3_add(ray_params.pos_to, self:m_pos())

								--verify there's the way is clear to execute the slide
								if not managers.navigation:raycast(ray_params) then
									local action_desc = {
										clamp_to_graph = true,
										type = "act",
										body_part = 1,
										variant = "e_nl_slide_fwd_4m",
										blocks = {
											action = -1,
											walk = -1
										}
									}

									if self:action_request(action_desc) then
										try_something_else = false
									end
								end
							end

							if try_something_else and self._tweak_data.crouch_move then
								if self._ext_anim.idle then
									if not self._active_actions[2] or self._active_actions[2]:type() == "idle" then
										if not self:chk_action_forbidden("act") then
											--using body part 2 means shooting won't be interrupted, which in turn fixes the issue
											--where sometimes suppressing an enemy causes them to instantly fire their weapon again
											--this happens because using 1 causes the shoot action to expire and exit
											local action_desc = {
												clamp_to_graph = true,
												type = "act",
												body_part = 2,
												variant = "suppressed_reaction",
												blocks = {
													walk = -1
												}
											}

											if self:action_request(action_desc) then
												try_something_else = false
											end
										end
									end
								end

								if try_something_else and not self:chk_action_forbidden("crouch") then
									local action_desc = {
										body_part = 4,
										type = "crouch"
									}

									self:action_request(action_desc)
								end
							end
						end
					end
				end
			end
		end

		managers.network:session():send_to_peers_synched("suppressed_state", self._unit, state and true or false)
	end

	self:enable_update()
end

function CopMovement:synch_attention(attention)
	self:_remove_attention_destroy_listener(self._attention)
	self:_add_attention_destroy_listener(attention)

	if attention and attention.unit and not attention.destroy_listener_key then
		self:synch_attention(nil)

		return
	end

	local old_attention = self._attention --of course vanilla lacks this for no real reason
	self._attention = attention
	self._action_common_data.attention = attention

	for _, action in ipairs(self._active_actions) do
		if action and action.on_attention then
			action:on_attention(attention, old_attention)
		end
	end
end

function CopMovement:clbk_sync_attention(attention)
	if not alive_g(self._unit) then
		return
	end

	if self._attention ~= attention then
		return
	end

	attention = self._attention

	if attention.handler then
		if attention.handler:unit():id() ~= -1 then
			self._ext_network:send("set_attention", attention.handler:unit(), attention.reaction)
		else
			self._ext_network:send("cop_set_attention_pos", mvec3_cpy(attention.handler:get_attention_m_pos()))
		end
	elseif attention.unit then
		if attention.unit:id() ~= -1 then
			self._ext_network:send("set_attention", attention.unit, AIAttentionObject.REACT_IDLE)
		else
			self._ext_network:send("cop_set_attention_pos", mvec3_cpy(attention.handler:get_attention_m_pos()))
		end
	end
end

--crash prevention
function CopMovement:anim_clbk_enemy_spawn_melee_item()
	local unit_name = self._melee_item_unit_name

	if unit_name == false or unit_name and alive_g(self._melee_item_unit) then
		return
	end

	if unit_name == nil then
		local base_ext = self._ext_base
		local melee_weapon = base_ext.melee_weapon and base_ext:melee_weapon()

		if melee_weapon and melee_weapon ~= "weapon" then
			local npc_melee_tweak_data = tweak_data.weapon.npc_melee[melee_weapon]

			if npc_melee_tweak_data then
				unit_name = npc_melee_tweak_data.unit_name
				self._melee_item_unit_name = unit_name
			else
				local ms = managers
				local melee_weapon_data = ms.blackmarket:get_melee_weapon_data(melee_weapon)

				if melee_weapon_data then
					local third_unit = melee_weapon_data.third_unit

					if third_unit then
						unit_name = ids_func(third_unit)
						self._melee_item_unit_name = unit_name
					end
				end
			end
		end

		if not unit_name then
			self._melee_item_unit_name = false

			return
		end
	end

	local my_unit = self._unit
	local align_obj_l_name = CopMovement._gadgets.aligns.hand_l
	local align_obj_l = my_unit:get_object(align_obj_l_name)
	local melee_unit = world_g:spawn_unit(unit_name, align_obj_l:position(), align_obj_l:rotation())

	my_unit:link(align_obj_l:name(), melee_unit, melee_unit:orientation_object():name())

	self._melee_item_unit = melee_unit
end

function CopMovement:update(unit, t, dt)
	local old_need_upd = self._need_upd
	self._need_upd = false

	self:_upd_actions(t)
	
	if not self._unit:character_damage():dead() then
		if self._can_do_omnia then
			self:do_omnia(t)
		end

		if self._can_do_summers_heal then
			self:do_summers_heal(t)
		end
	end

	if self._need_upd ~= old_need_upd then
		unit:set_extension_update_enabled(ids_movement, self._need_upd)
	end

	if self._force_head_upd then
		self._force_head_upd = nil

		self:upd_m_head_pos()
	end
end

local pre_destroy_original = CopMovement.pre_destroy
function CopMovement:pre_destroy()
	pre_destroy_original(self)

	managers.groupai:state():unregister_blackout_source(self._unit)

	local melee_unit = self._melee_item_unit

	if alive_g(melee_unit) then
		melee_unit:unlink()
		world_g:delete_unit(melee_unit)

		self._melee_item_unit = nil
	end

	self.update = self._upd_empty
end

function CopMovement:_upd_empty()
	self._gnd_ray = nil

	unit:set_extension_update_enabled(ids_movement, false)
end

local _equip_item_original = CopMovement._equip_item
function CopMovement:_equip_item(item_type, align_place, droppable)
	if item_type == "needle" then
		align_place = "hand_l"
	end

	_equip_item_original(self, item_type, align_place, droppable)
end

function CopMovement:sync_action_act_start(index, blocks_hurt, clamp_to_graph, needs_full_blend, start_rot, start_pos)
	if self._ext_damage:dead() then
		return
	end

	local redir_name = self._actions.act:_get_act_name_from_index(index)
	local body_part = 1
	local blocks = nil

	if redir_name == "suppressed_reaction" then
		body_part = 2
		blocks = {
			walk = -1,
			act = -1,
			idle = -1
		}
	elseif redir_name == "gesture_stop" or redir_name == "arrest" or redir_name == "cmd_get_up" or redir_name == "cmd_down" or redir_name == "cmd_stop" or redir_name == "cmd_gogo" or redir_name == "cmd_point" then
		body_part = 3
		blocks = {
			action = -1,
			act = -1,
			idle = -1
		}
	else
		blocks = {
			act = -1,
			idle = -1,
			action = -1,
			walk = -1
		}
	end

	local action_data = {
		type = "act",
		body_part = body_part,
		variant = redir_name,
		blocks = blocks,
		start_rot = start_rot,
		start_pos = start_pos,
		clamp_to_graph = clamp_to_graph,
		needs_full_blend = needs_full_blend
	}

	if blocks_hurt then
		action_data.blocks.light_hurt = -1
		action_data.blocks.hurt = -1
		action_data.blocks.heavy_hurt = -1
		action_data.blocks.expl_hurt = -1
		action_data.blocks.fire_hurt = -1
	end

	self:action_request(action_data)
end

function CopMovement:sync_action_dodge_start(body_part, var, side, rot, speed, shoot_acc)
	if self._ext_damage:dead() then
		return
	end

	local action_data = {
		type = "dodge",
		body_part = body_part,
		variation = CopActionDodge.get_variation_name(var),
		direction = Rotation(rot):y(),
		side = CopActionDodge.get_side_name(side),
		speed = speed,
		shoot_accuracy = shoot_acc / 10,
		blocks = {
			act = -1,
			tase = -1,
			bleedout = -1,
			dodge = -1,
			walk = -1,
			action = body_part == 1 and -1 or nil,
			aim = body_part == 1 and -1 or nil
		}
	}

	if action_data.variation ~= "side_step" then
		action_data.blocks.hurt = -1
		action_data.blocks.heavy_hurt = -1
	end

	self:action_request(action_data)
end

function CopMovement:sync_action_spooc_nav_point(pos, action_id)
	local spooc_action, is_queued = self:_get_latest_spooc_action(action_id)

	if is_queued then
		if spooc_action.stop_pos and not spooc_action.nr_expected_nav_points then
			return
		end

		table.insert(spooc_action.nav_path, pos)

		if spooc_action.nr_expected_nav_points then
			if spooc_action.nr_expected_nav_points == 1 then
				spooc_action.nr_expected_nav_points = nil

				table.insert(spooc_action.nav_path, spooc_action.stop_pos)
			else
				spooc_action.nr_expected_nav_points = spooc_action.nr_expected_nav_points - 1
			end
		end
	elseif spooc_action then
		spooc_action:sync_append_nav_point(pos)
	end
end

function CopMovement:sync_action_spooc_stop(pos, nav_index, action_id)
	local spooc_action, is_queued = self:_get_latest_spooc_action(action_id)

	if is_queued then
		spooc_action.host_expired = true

		if spooc_action.host_stop_pos_inserted then
			nav_index = nav_index + spooc_action.host_stop_pos_inserted
		end

		local nav_path = spooc_action.nav_path

		while nav_index < #nav_path do
			table.remove(nav_path)
		end

		spooc_action.stop_pos = pos

		if #nav_path < nav_index - 1 then
			spooc_action.nr_expected_nav_points = nav_index - #nav_path + 1
		else
			table.insert(nav_path, pos)

			spooc_action.path_index = math.max(1, math.min(spooc_action.path_index, #nav_path - 1))
		end
	elseif spooc_action then
		spooc_action:sync_stop(pos, nav_index)
	end
end

function CopMovement:sync_action_spooc_strike(pos, action_id)
	local spooc_action, is_queued = self:_get_latest_spooc_action(action_id)

	if is_queued then
		if spooc_action.stop_pos and not spooc_action.nr_expected_nav_points then
			return
		end

		table.insert(spooc_action.nav_path, pos)

		spooc_action.strike_nav_index = #spooc_action.nav_path
		spooc_action.strike = true
	elseif spooc_action then
		spooc_action:sync_strike(pos)
	end
end

function CopMovement:_get_latest_act_action()
	if self._queued_actions then
		for i = #self._queued_actions, 1, -1 do
			if self._queued_actions[i].type == "act" and not self._queued_actions[i].host_expired then
				return i, self._queued_actions[i], true
			end
		end
	end

	for body_part, action in ipairs(self._active_actions) do
		if action and action:type() == "act" then
			return body_part, self._active_actions[body_part]
		end
	end
end

function CopMovement:sync_action_act_end()
	local body_part, act_action, queued = self:_get_latest_act_action()

	if queued then
		act_action.host_expired = true
	elseif act_action then
		self._active_actions[body_part] = false

		if act_action.on_exit then
			act_action:on_exit()
		end

		self:_chk_start_queued_action()
		self._ext_brain:action_complete_clbk(act_action)
	end
end

function CopMovement:_get_latest_tase_action()
	if self._queued_actions then
		for i = #self._queued_actions, 1, -1 do
			local action = self._queued_actions[i]

			if action.type == "tase" then
				return self._queued_actions[i], true
			end
		end
	end

	if self._active_actions[3] and self._active_actions[3]:type() == "tase" and not self._active_actions[3]:expired() then
		return self._active_actions[3]
	end
end

function CopMovement:sync_taser_fire()
	local tase_action, is_queued = self:_get_latest_tase_action()

	if is_queued then
		tase_action.firing_at_husk = true
	elseif tase_action then
		tase_action:fire_taser()
	end
end

function CopMovement:anim_clbk_reload_exit()
	if self._ext_inventory:equipped_unit() then
		self._ext_inventory:equipped_unit():base():on_reload()
	end

	self:anim_clbk_hide_magazine_in_hand()
end

--Function that sets the cloaked ("invisibility") state of units. Only runs on the server, but syncs to clients to ensure the cloaked flag and visuals are correct.
function CopMovement:set_cloaked(state)
	local damage_ext = self._unit:damage()
	if not self._can_cloak or not Network:is_server() then
		return
	end

	if self._can_cloak and not (damage_ext:has_sequence("cloak_engaged") and damage_ext:has_sequence("decloak")) then
		log("WARNING: Unit " .. tweak_name .. "is marked as being able to cloak, but lacks the sequences to be able to do so")
		self._can_cloak = nil
		return
	end

	if state and not self._cloaked then
		managers.network:session():send_to_peers_synched("sync_unit_event_id_16", self._unit, "brain", HuskCopBrain._NET_EVENTS.cloak)
		self:sync_set_cloaked(state)
		
		if alive(self._unit:brain()) then
			self._unit:brain()._logic_data.coward_t = TimerManager:main():time()
		end
	elseif not state and self._cloaked then
		local is_autumn = self._ext_base._tweak_table == "autumn"
		if is_autumn then
			if not self._ext_brain._set_endless_assault then
				local ai_task_data = managers.groupai:state()._task_data

				if ai_task_data and ai_task_data.assault.active then
					if ai_task_data.assault.phase == "build" or ai_task_data.assault.phase == "sustain" then
						managers.groupai:state():set_assault_endless(true)
						managers.hud:set_buff_enabled("vip", true)
						self._ext_brain._set_endless_assault = true
					end
				end
			end
		end
		
		managers.network:session():send_to_peers_synched("sync_unit_event_id_16", self._unit, "brain", HuskCopBrain._NET_EVENTS.uncloak)
		self:sync_set_cloaked(state)
	end
end

--Handles visuals behind cloaking, along with the flag to indicate if a unit is or isn't cloaked.
--Run on both clients and server.
function CopMovement:sync_set_cloaked(state)
	local damage_ext = self._unit:damage()
	if not damage_ext then
		return
	end

	if state then
		damage_ext:run_sequence_simple("cloak_engaged")

		local weapon_unit = self._ext_inventory:equipped_unit()
		local weapon_damage_ext = weapon_unit and weapon_unit:damage()
		if weapon_unit and weapon_damage_ext and weapon_damage_ext:has_sequence("cloak_engaged") then
			weapon_damage_ext:run_sequence_simple("cloak_engaged")
		end
	else
		damage_ext:run_sequence_simple("decloak")

		local weapon_unit = self._ext_inventory:equipped_unit()
		local weapon_damage_ext = weapon_unit and weapon_unit:damage()
		if weapon_damage_ext and weapon_damage_ext:has_sequence("decloak") then
			weapon_damage_ext:run_sequence_simple("decloak")
		end
	end

	self._cloaked = state
end

--Returns whether or not a unit is currently "invisible". Relevant on Titan Cloakers and Capt. Autumn
function CopMovement:is_cloaked()
	return self._cloaked
end

--syncing stuff
function CopMovement:sync_reload_weapon(empty_reload, reload_speed_multiplier)
	local reload_action = {
		body_part = 3,
		type = "reload",
		idle_reload = empty_reload ~= 0 and empty_reload or nil
	}

	self:action_request(reload_action)
end

--syncing stuff
function CopMovement:sync_fall_position(pos, rot)
	self:set_position(pos)
	self:set_rotation(rot)
end

function CopMovement:damage_clbk(my_unit, damage_info)
	local hurt_type = damage_info.result.type

	if not hurt_type then
		return
	end

	if hurt_type == "healed" then
		self._ext_damage._health = self._ext_damage._HEALTH_INIT
		self._ext_damage._health_ratio = 1

		if self._unit:contour() then
			self._unit:contour():add("medic_heal")
			self._unit:contour():flash("medic_heal", 0.2)
		end

		--temporarily disabling buff due to other conflicts
		--[[if Network:is_server() then
			managers.modifiers:run_func("OnEnemyHealed", nil, self._unit)
		end]]

		if damage_info.is_synced then
			local healed_cooldown = self._tweak_data.heal_cooldown or 90
			self._ext_damage._healed_cooldown_t = TimerManager:main():time() + healed_cooldown

			return
		elseif self._tweak_data.ignore_medic_revive_animation then
			return
		end
		
		if self._ext_base._tweak_table == "summers" then
			local action_data = {
				body_part = 1,
				type = "healed",
				client_interrupt = Network:is_client(),
				allow_network = true
			}

			self:action_request(action_data)
		end

		return
	elseif hurt_type == "death" and damage_info.is_synced then
		if self._queued_actions then
			self._queued_actions = {}
		end

		if self._rope then
			self._rope:base():retract()

			self._rope = nil
			self._rope_death = true

			if self._unit:sound().anim_clbk_play_sound then
				self._unit:sound():anim_clbk_play_sound(self._unit, "repel_end")
			end
		end

		if Network:is_server() then
			self:set_attention()
		else
			self:synch_attention()
		end

		local attack_dir = damage_info.col_ray and damage_info.col_ray.ray or damage_info.attack_dir
		local hit_pos = damage_info.col_ray and damage_info.col_ray.position or damage_info.pos
		local body_part = 1
		local blocks = {
			act = -1,
			aim = -1,
			action = -1,
			tase = -1,
			walk = -1,
			light_hurt = -1
		}

		local tweak = self._tweak_data
		local death_type = "normal"

		if tweak.damage.death_severity then
			if tweak.damage.death_severity < damage_info.damage / self._ext_damage._HEALTH_INIT then
				death_type = "heavy"
			end
		end

		local action_data = {
			type = "hurt",
			block_type = hurt_type,
			hurt_type = hurt_type,
			variant = damage_info.variant,
			direction_vec = attack_dir,
			hit_pos = hit_pos,
			body_part = body_part,
			blocks = blocks,
			client_interrupt = Network:is_client(),
			attacker_unit = damage_info.attacker_unit,
			death_type = death_type,
			ignite_character = damage_info.ignite_character,
			start_dot_damage_roll = damage_info.start_dot_damage_roll,
			is_fire_dot_damage = damage_info.is_fire_dot_damage,
			fire_dot_data = damage_info.fire_dot_data,
			allow_network = false
		}

		self:action_request(action_data)

		return
	elseif damage_info.is_synced or damage_info.variant == "bleeding" and not Network:is_server() then
		return
	end

	if hurt_type ~= "death" then
		if damage_info.variant == "bullet" or damage_info.variant == "explosion" or damage_info.variant == "fire" or damage_info.variant == "poison" or damage_info.variant == "bleed" or damage_info.variant == "dot" or damage_info.variant == "graze" then
			hurt_type = managers.modifiers:modify_value("CopMovement:HurtType", hurt_type)

			if not hurt_type then
				return
			end
		end
	end

	if self._anim_global == "shield" and damage_info.variant == "stun" and hurt_type ~= "death" then
		hurt_type = "expl_hurt"
		damage_info.result = {
			variant = damage_info.variant,
			type = "expl_hurt"
		}
	elseif hurt_type == "stagger" or hurt_type == "knock_down" then
		if self._anim_global == "shield" then
			hurt_type = "expl_hurt"
		else
			hurt_type = "hurt"
		end
	elseif hurt_type == "hurt" or hurt_type == "heavy_hurt" then
		if self._anim_global == "shield" then
			hurt_type = "expl_hurt"
		end
	end

	local block_type = hurt_type

	if hurt_type == "expl_hurt" or hurt_type == "fire_hurt" or hurt_type == "poison_hurt" or hurt_type == "taser_tased" then
		block_type = "heavy_hurt"
	end

	if hurt_type == "death" and self._queued_actions then
		self._queued_actions = {}
	end

	if Network:is_server() and self:chk_action_forbidden(block_type) then
		return
	end

	if hurt_type == "death" then
		if self._rope then
			self._rope:base():retract()

			self._rope = nil
			self._rope_death = true

			if self._unit:sound().anim_clbk_play_sound then
				self._unit:sound():anim_clbk_play_sound(self._unit, "repel_end")
			end
		end

		if Network:is_server() then
			self:set_attention()
		else
			self:synch_attention()
		end
	end

	local attack_dir = damage_info.col_ray and damage_info.col_ray.ray or damage_info.attack_dir
	local hit_pos = damage_info.col_ray and damage_info.col_ray.position or damage_info.pos
	local lgt_hurt = hurt_type == "light_hurt"
	local body_part = lgt_hurt and 4 or 1
	local blocks = nil

	if not lgt_hurt then
		blocks = {
			act = -1,
			aim = -1,
			action = -1,
			tase = -1,
			walk = -1,
			light_hurt = -1
		}

		if hurt_type == "bleedout" then
			blocks.bleedout = -1
			blocks.hurt = -1
			blocks.heavy_hurt = -1
			blocks.hurt_sick = -1
			blocks.concussion = -1
		end
	end

	local client_interrupt = nil

	if damage_info.variant == "tase" and hurt_type ~= "death" then
		block_type = "bleedout"
	elseif hurt_type == "expl_hurt" or hurt_type == "fire_hurt" or hurt_type == "poison_hurt" or hurt_type == "taser_tased" then
		block_type = "heavy_hurt"

		if Network:is_client() then
			client_interrupt = true
		end
	else
		if hurt_type ~= "bleedout" and hurt_type ~= "fatal" and Network:is_client() then
			client_interrupt = true
		end

		block_type = hurt_type
	end

	local tweak = self._tweak_data
	local death_type = "normal"

	if tweak.damage.death_severity then
		if tweak.damage.death_severity < damage_info.damage / self._ext_damage._HEALTH_INIT then
			death_type = "heavy"
		end
	end

	local action_data = {
		type = "hurt",
		block_type = block_type,
		hurt_type = hurt_type,
		variant = damage_info.variant,
		direction_vec = attack_dir,
		hit_pos = hit_pos,
		body_part = body_part,
		blocks = blocks,
		client_interrupt = client_interrupt,
		attacker_unit = damage_info.attacker_unit,
		death_type = death_type,
		ignite_character = damage_info.ignite_character,
		start_dot_damage_roll = damage_info.start_dot_damage_roll,
		is_fire_dot_damage = damage_info.is_fire_dot_damage,
		fire_dot_data = damage_info.fire_dot_data,
		allow_network = true
	}

	if Network:is_server() or not self:chk_action_forbidden(action_data) then
		self:action_request(action_data)
	end
end

function CopMovement:anim_clbk_spawn_dropped_magazine()
	if not self:allow_dropped_magazines() then
		return
	end

	local equipped_weapon = self._unit:inventory():equipped_unit()

	if alive_g(equipped_weapon) and not equipped_weapon:base()._assembly_complete then
		return
	end

	local ref_unit = nil
	local allow_throw = true

	if not self._magazine_data then
		local w_td_crew = self:_equipped_weapon_crew_tweak_data()

		if not w_td_crew or not w_td_crew.pull_magazine_during_reload then
			return
		end

		self:anim_clbk_show_magazine_in_hand()

		if not self._magazine_data then
			return
		elseif not alive_g(self._magazine_data.unit) then
			self._magazine_data = nil

			return
		end

		local attach_bone = left_hand_str
		local bone_hand = self._unit:get_object(attach_bone)

		if bone_hand then
			mvec3_set(temp_vec1, self._magazine_data.unit:position())
			mvec3_sub(temp_vec1, self._magazine_data.unit:oobb():center())
			mvec3_add(temp_vec1, bone_hand:position())
			self._magazine_data.unit:set_position(temp_vec1)
		end

		ref_unit = self._magazine_data.part_unit
		allow_throw = false
	end

	if self._magazine_data and alive_g(self._magazine_data.unit) then
		ref_unit = ref_unit or self._magazine_data.unit

		self._magazine_data.unit:set_visible(false)

		local pos = ref_unit:position()
		local rot = ref_unit:rotation()
		local dropped_mag = self:_spawn_magazine_unit(self._magazine_data.id, self._magazine_data.name, pos, rot)

		self:_set_unit_bullet_objects_visible(dropped_mag, self._magazine_data.bullets, false)

		local mag_size = self._magazine_data.weapon_data.pull_magazine_during_reload

		if type(mag_size) ~= "string" then
			mag_size = "medium"
		end

		mvec3_set(temp_vec1, ref_unit:oobb():center())
		mvec3_sub(temp_vec1, pos)
		mvec3_set(temp_vec2, pos)
		mvec3_add(temp_vec2, temp_vec1)

		local dropped_col = world_g:spawn_unit(CopMovement.magazine_collisions[mag_size][1], temp_vec2, rot)

		dropped_col:link(CopMovement.magazine_collisions[mag_size][2], dropped_mag)

		if allow_throw then
			if self._left_hand_direction then
				local throw_force = 10

				mvec3_set(temp_vec1, self._left_hand_direction)
				mvec3_mul(temp_vec1, self._left_hand_velocity or 3)
				mvec3_mul(temp_vec1, math_random(25, 45))
				mvec3_mul(temp_vec1, -1)
				dropped_col:push(throw_force, temp_vec1)
			end
		else
			local throw_force = 10
			local reload_speed_multiplier = 1
			local w_td_crew = self:_equipped_weapon_crew_tweak_data()

			if w_td_crew then
				local weapon_usage_tweak = self._tweak_data.weapon[w_td_crew.usage]
				reload_speed_multiplier = weapon_usage_tweak.RELOAD_SPEED or 1

				if weapon_usage_tweak.crew then
					reload_speed_multiplier = reload_speed_multiplier * (w_td_crew.crew_reload_speed_mul or 1)
				end
			end

			local _t = reload_speed_multiplier - 1

			mvec3_set(temp_vec1, equipped_weapon:rotation():z())
			mvec3_mul(temp_vec1, math_lerp(math_random(65, 80), math_random(140, 160), _t))
			mvec3_mul(temp_vec1, math_random() < 0.0005 and 10 or -1)
			dropped_col:push(throw_force, temp_vec1)
		end

		managers.enemy:add_magazine(dropped_mag, dropped_col)
	end
end