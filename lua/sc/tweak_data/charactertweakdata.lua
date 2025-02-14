local job = Global.level_data and Global.level_data.level_id

--Headshot damage tiers.
	local headshot_difficulty_array = {2, 2.5, 3}
	local normal_headshot = 1 --2 below Overkill, 2.5 on Mayhem-Deathwish, 3 on DS
	local bravo_headshot = 1.5 --3 below Overkill, 3.75 on Mayhem-Deathwish, 4.5 on DS
	local strong_headshot = 2 --4 below Overkill, 5 on Mayhem-Deathwish, 6 on DS
	local projectile_throw_pos_offset = Vector3(50, 50, 0)

--Grenades
	local frag = {
		type = "bravo_frag",
		cooldown = 3, --Cooldown between grenade throw attempts.
		use_cooldown = 12, --Cooldown between throwing a grenade and starting attempts again.
		chance = 0.15, --Chance to throw grenade for each attempt.
		min_range = 500, --Minimum range grenade can be thrown to.
		max_range = 2000, --Maximum range grenade can be thrown to.
		throw_force = 1 / 1300, --Force multiplier applied to throw.
		offset = projectile_throw_pos_offset, --Offset applied to grenade spawn position, usually used to sync it to hand position.
		voiceline = "use_gas" --Voiceline unit plays when throwing grenade.
		--no_anim = true --Add this field to grenades launched by grenade launchers to skip throwing animation.
	}

	local cluster_frag = {
		type = "cluster_fuck",
		cooldown = 12,
		chance = 1,
		min_range = 500,
		max_range = 2000,
		throw_force = 1 / 1300,
		offset = projectile_throw_pos_offset,
		voiceline = "use_gas"
	}

	local tear_gas = {
		type = "gas_grenade",
		cooldown = 2,
		use_cooldown = 7.5,
		chance = 0.75,
		min_range = 500,
		max_range = 2400,
		throw_force = 1 / 1150,
		no_anim = true,
		voiceline = "use_gas"
	}

	local autumn_gas = {
		type = "gas_grenade",
		cooldown = 2,
		use_cooldown = 15,
		chance = 0.6,
		min_range = 500,
		max_range = 2400,
		throw_force = 1 / 1150,
		offset = projectile_throw_pos_offset,
		voiceline = "i03"
	}

	local molotov = {
		type = "molotov",
		cooldown = 2,
		use_cooldown = 6,
		chance = 0.5,
		min_range = 500,
		max_range = 2000,
		throw_force = 1 / 1300,
		offset = projectile_throw_pos_offset,
		voiceline = "use_gas"
	}

	local hatman_molotov = {
		type = "hatman_molotov",
		cooldown = 10,
		chance = 1,
		min_range = 500,
		max_range = 2000,
		throw_force = 1 / 1300,
		offset = projectile_throw_pos_offset,
		voiceline = "use_gas"
	}

	local gang_member_launcher_frag = {
		type="launcher_frag",
		chance = 0.9,
		cooldown = 5,
		use_cooldown = 50,
		min_range = 500,
		max_range = 2400,
		throw_force = 1 / 650,
		voiceline = "g43",
		strict_throw = 3,
		no_anim = true
	}

local old_init = CharacterTweakData.init
function CharacterTweakData:init(tweak_data, presets)
	old_init(self, tweak_data, presets)
	local presets = self:_presets(tweak_data)
	local func = "_init_region_" .. tostring(tweak_data.levels:get_ai_group_type())

	self[func](self)

	self._prefix_data_p1 = {
		cop = function ()
			return self._unit_prefixes.cop
		end,
		swat = function ()
			return self._unit_prefixes.swat
		end,
		heavy_swat = function ()
			return self._unit_prefixes.heavy_swat
		end,
		taser = function ()
			return self._unit_prefixes.taser
		end,
		cloaker = function ()
			return self._unit_prefixes.cloaker
		end,
		bulldozer = function ()
			return self._unit_prefixes.bulldozer
		end,
		medic = function ()
			return self._unit_prefixes.medic
		end
	}

	self.heavy_swat_sniper = deep_clone(self.marshal_marksman)
	self:_init_fbi_vet(presets)
	self:_init_medic_summers(presets)
	self:_init_weekend_dmr(presets)
	self:_init_weekend_lmg(presets)
	self:_init_weekend(presets)
	self:_init_boom(presets)
	self:_init_spring(presets)
	self:_init_summers(presets)
	self:_init_autumn(presets)
	self:_init_omnia_lpf(presets)
	self:_init_tank_titan(presets)
	self:_init_tank_biker(presets)
	self:_init_spooc_titan(presets)

	--Blanket mechanics changes.
	self:_set_characters_ecm_hurts()
end

function CharacterTweakData:_init_region_america()
	self._default_chatter = "dispatch_generic_message"
	self._unit_prefixes = {
		cop = "l",
		swat = "l",
		heavy_swat = "l",
		taser = "tsr",
		cloaker = "clk",
		bulldozer = "bdz",
		medic = "mdc"
	}
	self._speech_prefix_p2 = "d"
end

function CharacterTweakData:_init_region_russia()
	self._default_chatter = "dsp_radio_russian"
	self._unit_prefixes = {
		cop = "r",
		swat = "r",
		heavy_swat = "r",
		taser = "rtsr",
		cloaker = "rclk",
		bulldozer = "rbdz",
		medic = "rmdc"
	}
	self._speech_prefix_p2 = "n"
end

function CharacterTweakData:_init_region_zombie()
	self._default_chatter = "dsp_radio_zombie"
	self._unit_prefixes = {
		cop = "z",
		swat = "z",
		heavy_swat = "z",
		taser = "tsr",
		cloaker = "clk",
		bulldozer = "bdz",
		medic = "mdc"
	}
	self._speech_prefix_p2 = "n"
end

function CharacterTweakData:_init_region_murkywater()
	self._default_chatter = "dispatch_generic_message"
	self._unit_prefixes = {
		cop = "l",
		swat = "l",
		heavy_swat = "l5d",
		taser = "tsr",
		cloaker = "clk",
		bulldozer = "bdz",
		medic = "nothing"
	}
	self._speech_prefix_p2 = "n"
end

function CharacterTweakData:_init_region_federales()
	self._default_chatter = "mex_dispatch_generic_message"
	self._unit_prefixes = {
		cop = "m",
		swat = "m",
		heavy_swat = "m",
		taser = "mtsr",
		cloaker = "mclk",
		bulldozer = "mbdz",
		medic = "mmdc"
	}
	self._speech_prefix_p2 = "n"
end

function CharacterTweakData:_init_region_nypd()
	self._default_chatter = "dispatch_generic_message"
	self._unit_prefixes = {
		cop = "l",
		swat = "l",
		heavy_swat = "l",
		taser = "tsr",
		cloaker = "clk",
		bulldozer = "bdz",
		medic = "mdc"
	}
	self._speech_prefix_p2 = "d"
end

function CharacterTweakData:_init_region_lapd()
	self._default_chatter = "dispatch_generic_message"
	self._unit_prefixes = {
		cop = "l",
		swat = "l",
		heavy_swat = "l",
		taser = "tsr",
		cloaker = "clk",
		bulldozer = "bdz",
		medic = "mdc"
	}
	self._speech_prefix_p2 = "d"
end

function CharacterTweakData:get_ai_group_type()
	return self.tweak_data.levels:get_ai_group_type()
end

local function override_enemies(enemy_tweak_tables, changes)
	for i = 1, #enemy_tweak_tables do
		enemy = enemy_tweak_tables[i]
		for field, value in pairs(changes) do
			enemy[field] = value
		end
	end
end

local orig_init_security = CharacterTweakData._init_security
function CharacterTweakData:_init_security(presets)
	orig_init_security(self, presets)

	--Security Guard, Tutorial Guard, Mute Tutorial Guard, Pagerless Mex Guard
	local enemies = {self.security, self.security_undominatable, self.mute_security_undominatable, self.security_mex, self.security_mex_no_pager}
	override_enemies(enemies, {
		HEALTH_INIT = 7.2,
		headshot_dmg_mul = normal_headshot,
		chatter = presets.enemy_chatter.guard,
		shooting_death = false
	})

	if job == "fex" then
		override_enemies(enemies, {melee_weapon = "fists"})
	end
end

local orig_init_gensec = CharacterTweakData._init_gensec
function CharacterTweakData:_init_gensec(presets)
	orig_init_gensec(self, presets)

	--Gensec Guards, used on armored transport
	override_enemies({self.gensec}, {
		HEALTH_INIT = 7.2,
		headshot_dmg_mul = normal_headshot,
		hurt_severity = presets.hurt_severities.bravo,
		move_speed = presets.move_speed.very_fast,
		hurt_severity = presets.suppression.hard_def,
		chatter = presets.enemy_chatter.guard,
		shooting_death = false
	})
end

local orig_init_cop = CharacterTweakData._init_cop
function CharacterTweakData:_init_cop(presets)
	orig_init_cop(self, presets)

	--Beat Cops
	local enemies = {self.cop, self.cop_female, self.cop_scared}
	override_enemies(enemies, {
		HEALTH_INIT = 7.2,
		headshot_dmg_mul = normal_headshot,
		weapon = presets.weapon.good,
		speech_prefix_p1 = self._prefix_data_p1.cop(),
		shooting_death = false
	})

	if job == "wwh" then
		override_enemies(enemies, {access = "fbi"})
	end

	self.cop_forest = deep_clone(self.cop) --bomb forest cop
	self.cop_forest.speech_prefix_p1 = "l"
	self.cop_forest.speech_prefix_p2 = "n"
	self.cop_forest.speech_prefix_count = 4		
	self.cop_forest.access = "gangster"
	table.insert(self._enemy_list, "cop_forest")
end

local orig_init_fbi = CharacterTweakData._init_fbi
function CharacterTweakData:_init_fbi(presets)
	orig_init_fbi(self, presets)

	--FBI and HRTs.
	override_enemies({self.fbi}, {
		HEALTH_INIT = 12,
		headshot_dmg_mul =  normal_headshot,
		weapon = presets.weapon.expert,
		speech_prefix_p1 = self._prefix_data_p1.cop(),
		rescue_hostages = true,
		no_arrest = true
	})

	self.fbi_female = deep_clone(self.fbi) --fbi office female
	self.fbi_female.speech_prefix_p1 = "fl"
	self.fbi_female.speech_prefix_p2 = "n"
	self.fbi_female.speech_prefix_count = 1
	table.insert(self._enemy_list, "fbi_female")

	self.hrt = deep_clone(self.fbi)
end

function CharacterTweakData:_init_fbi_vet(presets)
	--Bravo HRTs ("Vet Cops")
	self.fbi_vet = deep_clone(self.fbi)
	self.fbi_vet.weapon = presets.weapon.expert
	table.insert(self.fbi_vet.tags, "fbi_vet")
	self.fbi_vet.can_shoot_while_dodging = true
	self.fbi_vet.can_slide_on_suppress = true
	self.fbi_vet.HEALTH_INIT = 18
	self.fbi_vet.headshot_dmg_mul = bravo_headshot
	self.fbi_vet.dodge = presets.dodge.ninja_complex
	self.fbi_vet.access = "spooc"
	self.fbi_vet.damage.hurt_severity = presets.hurt_severities.bravo
	self.fbi_vet.move_speed = presets.move_speed.lightning
	if self:get_ai_group_type() == "russia" then
		self.fbi_vet.custom_voicework = nil
		self.fbi_vet.speech_prefix_p1 = self._prefix_data_p1.swat()
		self.fbi_vet.speech_prefix_p2 = self._speech_prefix_p2
		self.fbi_vet.speech_prefix_count = 4
	else
		self.fbi_vet.custom_voicework = "pdth"
		self.fbi_vet.speech_prefix_p1 = "CVOV"
		self.fbi_vet.speech_prefix_count = nil
	end
	self.fbi_vet.dodge_with_grenade = {
		flash = {duration = {
			1,
			1
		}},
		check = function (t, nr_grenades_used)
			local delay_till_next_use = 8
			local chance = 0.25

			if math.random() < chance then
				return true, t + delay_till_next_use
			end

			return false, t + delay_till_next_use
		end
	}
	table.insert(self._enemy_list, "fbi_vet")

	self.fbi_vet_boss = deep_clone(self.fbi_vet) --hoxout fbi boss
	self.fbi_vet_boss.HEALTH_INIT = 56
	self.fbi_vet_boss.weapon = presets.weapon.expert
	self.fbi_vet_boss.headshot_dmg_mul = normal_headshot
	self.fbi_vet_boss.melee_weapon = "buzzer_summer"
	self.fbi_vet_boss.tase_on_melee = true
	table.insert(self._enemy_list, "fbi_vet_boss")
end

local orig_init_medic = CharacterTweakData._init_medic
function CharacterTweakData:_init_medic(presets)
	orig_init_medic(self, presets)

	--Medic
	override_enemies({self.medic}, {
		HEALTH_INIT = 36,
		headshot_dmg_mul = normal_headshot,
		chatter = {
			aggressive = true,
			retreat = true,
			go_go = true,
			contact = true,
			entrance = true
		},
		is_special = true,
		priority_shout_max_dis = 3000,
		bot_priority_shout = "f47x_any"
	})
end

function CharacterTweakData:_init_medic_summers(presets)
	self.medic_summers = deep_clone(self.medic) --Doc
	self.medic_summers.HEALTH_INIT = 100.8
	self.medic_summers.headshot_dmg_mul = normal_headshot
	self.medic_summers.weapon = presets.weapon.good
	self.medic_summers.tags = {"medic_summers_special", "medic_summers", "special"}
	self.medic_summers.ignore_medic_revive_animation = false
	self.medic_summers.surrender = nil
	self.medic_summers.flammable = false
	self.medic_summers.use_animation_on_fire_damage = false
	self.medic_summers.damage.hurt_severity = presets.hurt_severities.medic_summers
	self.medic_summers.ecm_vulnerability = 0
	self.medic_summers.immune_to_concussion = true
	self.medic_summers.no_damage_mission = true
	self.medic_summers.no_limping = true
	self.medic_summers.no_retreat = true
	self.medic_summers.no_arrest = true
	self.medic_summers.immune_to_knock_down = true
	self.medic_summers.priority_shout = "f45"
	self.medic_summers.bot_priority_shout = "f45x_any"
	self.medic_summers.custom_voicework = "olpf"
	self.medic_summers.speech_prefix_p1 = nil
	self.medic_summers.speech_prefix_p2 = nil
	self.medic_summers.chatter = presets.enemy_chatter.omnia_lpf
	self.medic_summers.is_special = true
	self.medic_summers.do_summers_heal = true
	self.medic_summers.follower = true
	table.insert(self._enemy_list, "medic_summers")
end

function CharacterTweakData:_init_omnia_lpf(presets) --lpf
	self.omnia_lpf = deep_clone(presets.base)
	self.omnia_lpf.experience = {}
	self.omnia_lpf.tags = {"law", "lpf", "special"}
	self.omnia_lpf.weapon = presets.weapon.normal
	self.omnia_lpf.detection = presets.detection.normal
	self.omnia_lpf.HEALTH_INIT = 67.2
	self.omnia_lpf.headshot_dmg_mul = normal_headshot
	self.omnia_lpf.damage.hurt_severity = presets.hurt_severities.strong
	self.omnia_lpf.damage.melee_damage_mul = 2
	self.omnia_lpf.move_speed = presets.move_speed.fast
	self.omnia_lpf.surrender_break_time = {7, 12}
	self.omnia_lpf.suppression = presets.suppression.no_supress
	self.omnia_lpf.surrender = nil
	self.omnia_lpf.ecm_vulnerability = 1
	self.omnia_lpf.weapon_voice = "2"
	self.omnia_lpf.experience.cable_tie = "tie_swat"
	if self:get_ai_group_type() == "russia" then
		self.omnia_lpf.speech_prefix_p1 = self._prefix_data_p1.medic()
		self.omnia_lpf.speech_prefix_count = nil
		self.omnia_lpf.spawn_sound_event = "rmdc_entrance"
	else
		self.omnia_lpf.speech_prefix_p1 = "CVOLPF"
		self.omnia_lpf.speech_prefix_p2 = nil
		self.omnia_lpf.speech_prefix_count = nil
		self.omnia_lpf.spawn_sound_event = nil
	end
	self.omnia_lpf.access = "swat"
	self.omnia_lpf.dodge = presets.dodge.elite
	self.omnia_lpf.no_arrest = true
	self.omnia_lpf.chatter = presets.enemy_chatter.omnia_lpf
	self.omnia_lpf.melee_weapon = "baton"
	self.omnia_lpf.rescue_hostages = false
	self.omnia_lpf.steal_loot = nil
	if self:get_ai_group_type() == "russia" then
		self.omnia_lpf.custom_voicework = nil
	elseif self:get_ai_group_type() == "zombie" then
		self.omnia_lpf.custom_voicework = "awoolpf"
	else
		self.omnia_lpf.custom_voicework = "olpf"
	end
	self.omnia_lpf.priority_shout = "f47"
	self.omnia_lpf.bot_priority_shout = "f47x_any"
	self.omnia_lpf.do_omnia = {
		cooldown = 8,
		radius = 600
	}
	self.omnia_lpf.overheal_specials = true
	self.omnia_lpf.is_special = true
	table.insert(self._enemy_list, "omnia_lpf")
end

local orig_init_swat = CharacterTweakData._init_swat
function CharacterTweakData:_init_swat(presets)
	orig_init_swat(self, presets)

	--Light Swat
	override_enemies({self.swat}, {
		HEALTH_INIT = 16.8,
		headshot_dmg_mul = normal_headshot,
		weapon = presets.weapon.expert,
		move_speed = presets.move_speed.very_fast,
		surrender = presets.surrender.hard,
		no_arrest = false,
		silent_priority_shout = "f37"
	})

	if self:get_ai_group_type() == "murkywater" then
		self.swat.has_alarm_pager = true
	end

	if job == "kosugi" or job == "dark" then
		self.swat.shooting_death = false
	end

	--Just in case, makes them be able to go for the hostage
	if managers.skirmish and managers.skirmish:is_skirmish() then
		self.swat.access = "fbi"
	else
		self.swat.access = "swat"
	end
end

local orig_init_heavy_swat = CharacterTweakData._init_heavy_swat
function CharacterTweakData:_init_heavy_swat(presets) --heavy swat
	orig_init_heavy_swat(self, presets)

	--Heavy Swat
	override_enemies({self.heavy_swat}, {
		HEALTH_INIT = 25.2,
		headshot_dmg_mul = normal_headshot,
		weapon = presets.weapon.expert,
		surrender = presets.surrender.hard,
		no_arrest = false,
		silent_priority_shout = "f37"
	})

	if self:get_ai_group_type() == "murkywater" then
		self.heavy_swat.has_alarm_pager = true
	end

	if job == "kosugi" or job == "dark" then
		self.heavy_swat.shooting_death = false
	end
end

local orig_init_marshall_marksman = CharacterTweakData._init_marshal_marksman
function CharacterTweakData:_init_marshal_marksman(presets)
	orig_init_marshall_marksman(self, presets)

	--Marshall Marksmen ("Titan Snipers")
	override_enemies({self.marshal_marksman}, {
		tags = {"law", "marksman", "special"},
		weapon = presets.weapon.expert,
		dodge = presets.dodge.elite,
		HEALTH_INIT = 14.4,
		headshot_dmg_mul = normal_headshot,
		move_speed = presets.move_speed.normal,
		dodge = presets.dodge.heavy,
		ecm_vulnerability = 1,
		bot_priority_shout = "f34x_any",
		melee_weapon = "fists",
		no_retreat = nil,
		is_special = true
	})
end

function CharacterTweakData:_init_weekend_dmr(presets)
	--Bravo Marksmen
	self.weekend_dmr = deep_clone(self.marshal_marksman)
	self.weekend_dmr.speech_prefix_p1 = "CVOB"
	self.weekend_dmr.speech_prefix_p2 = nil
	self.weekend_dmr.speech_prefix_count = nil
	if self:get_ai_group_type() == "russia" then
		self.weekend_dmr.custom_voicework = "bravo_elite"
	elseif self:get_ai_group_type() == "murkywater" then
		self.weekend_dmr.custom_voicework = "bravo_murky"
	elseif self:get_ai_group_type() == "federales" then
		self.weekend_dmr.custom_voicework = "bravo_mex"
	else
		self.weekend_dmr.custom_voicework = "bravo_elite"
	end
	self.weekend_dmr.HEALTH_INIT = 21.6
	self.weekend_dmr.headshot_dmg_mul = bravo_headshot
	self.weekend_dmr.damage.hurt_severity = presets.hurt_severities.bravo
	self.weekend_dmr.damage.explosion_damage_mul = 1.5
	self.weekend_dmr.damage.fire_pool_damage_mul = 1.5
	self.weekend_dmr.grenade = frag
	table.insert(self._enemy_list, "weekend_dmr")
end

local orig_init_fbi_swat = CharacterTweakData._init_fbi_swat
function CharacterTweakData:_init_fbi_swat(presets)
	orig_init_fbi_swat(self, presets)

	--Green Light Swat
	override_enemies({self.fbi_swat}, {
		HEALTH_INIT = 16.8,
		headshot_dmg_mul = normal_headshot,
		surrender = presets.surrender.hard,
		speech_prefix_p1 = self._prefix_data_p1.swat(),
		dodge = presets.dodge.athletic_very_hard,
		no_arrest = false
	})
end

local orig_init_fbi_heavy_swat = CharacterTweakData._init_fbi_heavy_swat
function CharacterTweakData:_init_fbi_heavy_swat(presets)
	orig_init_fbi_heavy_swat(self, presets)

	--Tan FBI/Gensec Heavy Swat
	override_enemies({self.fbi_heavy_swat}, {
		HEALTH_INIT = 25.2,
		headshot_dmg_mul = normal_headshot,
		damage = {
			hurt_severity = presets.hurt_severities.boom,
			explosion_damage_mul = 0.5,
			death_severity = 0.5,
			tased_response = {
				light = {tased_time = 5, down_time = 5},
				heavy = {tased_time = 5, down_time = 10}
			}
		},
		surrender = presets.surrender.hard,
		dodge = presets.dodge.heavy_very_hard,
		weapon = presets.weapon.normal,
		no_arrest = false,
		melee_weapon = "knife_1"
	})
end

function CharacterTweakData:_init_weekend_lmg(presets)
	--Bravo LMG
	self.weekend_lmg = deep_clone(self.heavy_swat)
	if self:get_ai_group_type() == "russia" then
		self.weekend_lmg.custom_voicework = "bravo_elite"
	elseif self:get_ai_group_type() == "murkywater" then
		self.weekend_lmg.custom_voicework = "bravo_murky"
	elseif self:get_ai_group_type() == "federales" then
		self.weekend_lmg.custom_voicework = "bravo_mex"
	else
		self.weekend_lmg.custom_voicework = "bravo_elite"
	end
	self.weekend_lmg.speech_prefix_p1 = "CVOB"
	self.weekend_lmg.speech_prefix_p2 = nil
	self.weekend_lmg.speech_prefix_count = nil
	self.weekend_lmg.can_slide_on_suppress = true
	self.weekend_lmg.HEALTH_INIT = 37.8
	self.weekend_lmg.weapon = presets.weapon.expert
	self.weekend_lmg.headshot_dmg_mul = bravo_headshot
	self.weekend_lmg.damage.explosion_damage_mul = 0.75
	self.weekend_lmg.damage.fire_pool_damage_mul = 0.75
	self.weekend_lmg.grenade = frag
	table.insert(self._enemy_list, "weekend_lmg")
end

local orig_init_city_swat = CharacterTweakData._init_city_swat
function CharacterTweakData:_init_city_swat(presets) --light zeal gensec swat
	orig_init_city_swat(self, presets)

	--Light Zeal Gensec Swat
	override_enemies({self.city_swat}, {
		HEALTH_INIT = 16.8,
		headshot_dmg_mul = normal_headshot,
		weapon = presets.weapon.expert,
		surrender = presets.surrender.hard,
		no_arrest = false,
		speech_prefix_p1 = self._prefix_data_p1.swat(),
		dodge = presets.dodge.athletic_overkill,
		has_alarm_pager = true
	})

	if job == "kosugi" or job == "dark" then
		self.city_swat.shooting_death = false
		self.city_swat.radio_prefix = "fri_"
		self.city_swat.use_radio = "dsp_radio_russian"
	end

	self.skeleton_swat_titan = deep_clone(self.city_swat) --zombie riot titan swat
	table.insert(self._enemy_list, "skeleton_swat_titan")
end

function CharacterTweakData:_init_weekend(presets)
	--Bravo Shotgunner Rifle
	self.weekend = deep_clone(self.swat)
	if self:get_ai_group_type() == "russia" then
		self.weekend.custom_voicework = "bravo"
	elseif self:get_ai_group_type() == "murkywater" then
		self.weekend.custom_voicework = "bravo_murky"
	elseif self:get_ai_group_type() == "federales" then
		self.weekend.custom_voicework = "bravo_mex"
	else
		self.weekend.custom_voicework = "bravo"
	end
	self.weekend.HEALTH_INIT = 29.7
	self.weekend.dodge = self.presets.dodge.athletic_very_hard
	self.weekend.damage.explosion_damage_mul = 1.5
	self.weekend.damage.fire_pool_damage_mul = 1.5
	self.weekend.headshot_dmg_mul = bravo_headshot
	self.weekend.damage.hurt_severity = presets.hurt_severities.bravo
	self.weekend.speech_prefix_p1 = "CVOB"
	self.weekend.speech_prefix_p2 = nil
	self.weekend.speech_prefix_count = nil
	self.weekend.grenade = frag
	self.weekend.surrender = presets.surrender.bravo
	table.insert(self._enemy_list, "weekend")
end

local orig_init_sniper = CharacterTweakData._init_sniper
function CharacterTweakData:_init_sniper(presets) --sniper
	orig_init_sniper(self, presets)
	override_enemies({self.sniper}, {
		HEALTH_INIT = 9.6,
		big_head_mode = true, --TODO: Replace with the ability to explicitly set the radius.
		headshot_dmg_mul = normal_headshot,
		allowed_poses = {stand = true},
		move_speed = presets.move_speed.normal,
		suppression = presets.suppression.no_supress,
		damage = {
			hurt_severity = presets.hurt_severities.no_hurts,
			explosion_damage_mul = 1,
			death_severity = 0,
			tased_response = {
				light = {tased_time = 5, down_time = 5},
				heavy = {tased_time = 5, down_time = 10}
			}
		},
		bot_priority_shout = "f34x_any",
		priority_shout_max_dis = 5000,
		no_limping = true,
		crouch_move = false,
		is_special = true,
		die_sound_event = "mga_death_scream",
		do_not_drop_ammo = true
	})
end

local orig_init_gangster = CharacterTweakData._init_gangster
function CharacterTweakData:_init_gangster(presets) --gangster
	orig_init_gangster(self, presets)
	override_enemies({self.gangster}, {
		HEALTH_INIT = 6,
		damage = {
			hurt_severity = presets.hurt_severities.no_hurts,
			explosion_damage_mul = 1,
			death_severity = 0.5,
			tased_response = {
				light = {tased_time = 5, down_time = 5},
				heavy = {tased_time = 5, down_time = 10}
			}
		},
		headshot_dmg_mul = normal_headshot,
		move_speed = presets.move_speed.normal,
		weapon = presets.weapon.gangster,
		unintimidateable = true,
		silent_priority_shout = "f37",
		chatter = {
			aggressive = true,
			retreat = true,
			contact = true,
			go_go = true,
			suppress = true
		}
	})

	if job == "nightclub" or job == "short2_stage1" or job == "jolly" or job == "spa" then
		self.gangster.speech_prefix_p1 = "rt"
		self.gangster.speech_prefix_p2 = nil
		self.gangster.speech_prefix_count = 2
	elseif job == "alex_2" or job == "alex_2_res" or job == "welcome_to_the_jungle_1" then
		self.gangster.speech_prefix_p1 = "ict"
		self.gangster.speech_prefix_p2 = nil
		self.gangster.speech_prefix_count = 2
	elseif job == "man" then
		self.gangster.speech_prefix_p1 = self._prefix_data_p1.cop()
		self.gangster.speech_prefix_p2 = "n"
		self.gangster.speech_prefix_count = 4
		self.gangster.no_arrest = false
		self.gangster.rescue_hostages = true
		self.gangster.use_radio = self._default_chatter
	else
		self.gangster.speech_prefix_p1 = "lt"
		self.gangster.speech_prefix_p2 = nil
		self.gangster.speech_prefix_count = 2
	end

	if job == "alex_3" or job == "alex_3_res" or job == "mex" then
		self.gangster.access = "security"
	else
		self.gangster.access = "gangster"
	end
end

local orig_init_biker = CharacterTweakData._init_biker
function CharacterTweakData:_init_biker(presets) --biker
	orig_init_biker(self, presets)
	override_enemies({self.biker}, {
		speech_prefix_p1 = "bik",
		speech_prefix_p2 = false,
		speech_prefix_count = 2,
		melee_weapon = "knife_1"
	})
end

function CharacterTweakData:_init_triad(presets) --triad gangster
	self.triad = deep_clone(self.gangster)
	self.triad.detection = presets.detection.guard
	self.triad.radio_prefix = "fri_"
	self.triad.calls_in = true
	self.triad.suspicious = true
	self.triad.die_sound_event = "l2n_x01a_any_3p"
	table.insert(self._enemy_list, "triad")
end

local orig_init_captain = CharacterTweakData._init_captain
function CharacterTweakData:_init_captain(presets) --alaskan deal friendly captain
	orig_init_captain(self, presets)
	override_enemies({self.captain}, {
		no_limping = true,
		--unintimidateable = true
	})
end

function CharacterTweakData:_init_biker_escape(presets) --unused, prolly for old firestarter day 1
	self.biker_escape = deep_clone(self.gangster)
	self.biker_escape.melee_weapon = "knife_1"
	self.biker_escape.move_speed = presets.move_speed.very_fast
	self.biker_escape.suppression = nil
	table.insert(self._enemy_list, "biker_escape")
end

function CharacterTweakData:_init_mobster(presets) --hotline miami mobster gangster
	self.mobster = deep_clone(self.gangster)
	self.mobster.speech_prefix_p1 = "rt"
	self.mobster.speech_prefix_p2 = nil
	self.mobster.speech_prefix_count = 2
	self.mobster.chatter = {
		aggressive = true,
		retreat = true,
		contact = true,
		go_go = true,
		suppress = true
	}
	table.insert(self._enemy_list, "mobster")
end

local orig_init_mobster_boss = CharacterTweakData._init_mobster_boss
function CharacterTweakData:_init_mobster_boss(presets) --the commissar
	orig_init_mobster_boss(self, presets)
	override_enemies({self.mobster_boss}, {
		die_sound_event = "l1n_burndeath",
		custom_shout = true,
		priority_shout = "g29",
		bot_priority_shout = "g29",
		silent_priority_shout = false
	})

	override_enemies({self.mobster_boss}, presets.generic_boss_stats)
end

local orig_init_biker_boss = CharacterTweakData._init_biker_boss
function CharacterTweakData:_init_biker_boss(presets) --biker heist day 2 Female boss
	orig_init_biker_boss(self, presets)
	override_enemies({self.biker_boss}, {
		speech_prefix_p1 = "bb"	,
		speech_prefix_p2 = "n",
		speech_prefix_count = 1,
		custom_shout = true,
		die_sound_event = "f1n_x01a_any_3p"
	})

	override_enemies({self.biker_boss}, presets.generic_boss_stats)
end

local orig_init_hector_boss_no_armor = CharacterTweakData._init_hector_boss_no_armor
function CharacterTweakData:_init_hector_boss_no_armor(presets) --stealth hoxvenge hector boss
	orig_init_hector_boss_no_armor(self, presets)
	override_enemies({self.hector_boss_no_armor}, {
		unintimidateable = true,
		no_limping = true,
		can_be_tased = true
	})
end

local orig_init_chavez_boss = CharacterTweakData._init_chavez_boss
function CharacterTweakData:_init_chavez_boss(presets) --chavez
	orig_init_chavez_boss(self, presets)
	override_enemies({self.chavez_boss}, {
		priority_shout = "g29",
		bot_priority_shout = "g29",
		custom_shout = true,
		silent_priority_shout = false,
		die_sound_event = "l1n_burndeath"
	})

	override_enemies({self.chavez_boss}, presets.generic_boss_stats)
end

local orig_init_triad_boss = CharacterTweakData._init_triad_boss
function CharacterTweakData:_init_triad_boss(presets) -- Yufu wang
	orig_init_triad_boss(self, presets)
	override_enemies({self.triad_boss}, {
		weapon = presets.weapon.expert,
		priority_shout = "g29",
		bot_priority_shout = "g29",
		silent_priority_shout = false,
		custom_shout = true,
		priority_shout_max_dis = 3000,
		HEALTH_INIT = 480,
		headshot_dmg_mul = normal_headshot,
		big_head_mode = true,
		damage = {
			hurt_severity = presets.hurt_severities.spring,
			explosion_damage_mul = 2
		},
		move_speed = presets.move_speed.very_slow,
		no_arrest = true,
		melee_weapon = "fists_dozer",
		ecm_vulnerability = 0,
		ecm_hurts = {},
		flammable = true,
		must_headshot = false,
		bullet_damage_only_from_front = false,
		player_health_scaling_mul = false,
		grenade = molotov
	})

	self.triad_boss.aoe_damage_data.activation_range = 500
	self.triad_boss.aoe_damage_data.activation_delay = 3
end

local orig_init_bolivians = CharacterTweakData._init_bolivians
function CharacterTweakData:_init_bolivians(presets) --Scarface guards
	orig_init_bolivians(self, presets)
	override_enemies({self.bolivian, self.bolivian_indoors}, {
		detection = presets.detection.normal,
		suspicious = true,
		no_arrest = true
	})
end

local orig_init_bolivian_indoors_mex = CharacterTweakData._init_bolivian_indoors_mex
function CharacterTweakData:_init_bolivian_indoors_mex(presets)
	orig_init_bolivian_indoors_mex(self, presets)
	override_enemies({self.bolivian_indoors_mex}, {
		weapon = presets.weapon.gangster
	})

	if job == "mex" then
		self.bolivian_indoors_mex.access = "security"
	else
		self.bolivian_indoors_mex.access = "gangster"
	end
end

local orig_init_drug_lord_boss = CharacterTweakData._init_drug_lord_boss
function CharacterTweakData:_init_drug_lord_boss(presets) --sosa
	orig_init_drug_lord_boss(self, presets)
	override_enemies({self.drug_lord_boss}, {
		grenade = frag,
		die_sound_event = "l1n_burndeath"
	})
	override_enemies({self.drug_lord_boss}, presets.generic_boss_stats)
end

local orig_init_drug_lord_boss_stealth = CharacterTweakData._init_drug_lord_boss_stealth
function CharacterTweakData:_init_drug_lord_boss_stealth(presets) --sosa stealth
	orig_init_drug_lord_boss_stealth(self, presets)
	override_enemies({self.drug_lord_boss_stealth}, {
		weapon = presets.weapon.gangster,
		die_sound_event = "l2n_x01a_any_3p",
		HEALTH_INIT = 12,
		headshot_dmg_mul = strong_headshot,
		move_speed = presets.move_speed.very_fast,
		no_limping = true,
		melee_weapon = "fists_dozer",
		unintimidateable = true,
		ecm_hurts = {
			ears = {min_duration = 0, max_duration = 0}
		},
		ecm_vulnerability = 0
	})
end

local orig_init_tank = CharacterTweakData._init_tank
function CharacterTweakData:_init_tank(presets) --motherfucking bulldozer
	orig_init_tank(self, presets)
	override_enemies({self.tank, self.tank_medic, self.tank_mini}, {
		weapon = presets.weapon.dozer,
		HEALTH_INIT = 294,
		headshot_dmg_mul = strong_headshot,
		damage = {
			explosion_damage_mul = 2,
			tased_response = {
				light = {down_time = 0, tased_time = 1},
				heavy = {down_time = 0, tased_time = 2}
			},
			hurt_severity = presets.hurt_severities.tank,
			death_severity = 0.5
		},
		ecm_vulnerability = 0,
		ecm_hurts = {ears = {min_duration = 0, max_duration = 0}},
		spawn_sound_event = self._prefix_data_p1.bulldozer() .. "_entrance",
		bot_priority_shout = "f30x_any",
		priority_shout_max_dis = 3000,
		melee_weapon = "fists_dozer",
		chatter = {
			reload = true, --this is just here for tdozers
			aggressive = true,
			retreat = true,
			go_go = true,
			contact = true,
			entrance = true
		},
		is_special = true,
		immune_to_concussion = false,
		tank_concussion = true,
		no_recoil = true
	})

	override_enemies({self.tank_mini}, {
		move_speed = presets.move_speed.slow,
		shooting_death = false
	})

	override_enemies({self.tank_hw}, {
		weapon = presets.weapon.sniper,
		tags = {"law", "tank", "special", "tank_titan", "customvo", "no_run", "backliner"},
		move_speed = presets.move_speed.very_slow,
		headshot_dmg_mul = strong_headshot,
		immune_to_knock_down = true,
		priority_shout_max_dis = 3000,
		spawn_sound_event = "bdz_entrance_elite",
	}) --Headless dozer
end

function CharacterTweakData:_init_tank_titan(presets)
	self.tank_titan = deep_clone(self.tank) --titan dozer
	self.tank_titan.weapon = presets.weapon.sniper
	self.tank_titan.tags = {"law", "tank", "special", "tank_titan", "customvo", "no_run", "backliner"}
	self.tank_titan.move_speed = presets.move_speed.very_slow
	self.tank_titan.damage.hurt_severity = presets.hurt_severities.tank_titan
	self.tank_titan.HEALTH_INIT = 480
	self.tank_titan.spawn_sound_event = "bdz_entrance_elite"
	if self:get_ai_group_type() == "russia" then
		self.tank.speech_prefix_p1 = self._prefix_data_p1.bulldozer()
		self.tank.speech_prefix_p2 = nil
		self.tank.speech_prefix_count = nil
		self.tank_titan.custom_voicework = "tdozer_ru"
		self.tank_titan.spawn_sound_event = "bdz_entrance_elite"
	else
		self.tank_titan.custom_voicework = "tdozer"
		self.tank_titan.speech_prefix_p1 = "CVOD"
		self.tank_titan.speech_prefix_count = nil
	end
	table.insert(self._enemy_list, "tank_titan")
end

function CharacterTweakData:_init_tank_biker(presets) --biker dozer
	self.tank_biker = deep_clone(self.tank)
	self.tank_biker.spawn_sound_event = nil
	self.tank_biker.spawn_sound_event_2 = nil
	self.tank_biker.use_radio = nil
	self.tank_biker.speech_prefix_p1 = "bik"
	self.tank_biker.speech_prefix_p2 = nil
	self.tank_biker.speech_prefix_count = 2
	self.tank_biker.die_sound_event = "x02_any_3p"
	self.tank_biker.die_sound_event_2 = "l1n_burndeath"
	self.tank_biker.chatter = presets.enemy_chatter.swat
end

local orig_init_spooc = CharacterTweakData._init_spooc
function CharacterTweakData:_init_spooc(presets) --cloaker
	orig_init_spooc(self, presets)
	override_enemies({self.spooc}, {
		HEALTH_INIT = 72,
		headshot_dmg_mul = strong_headshot,
		melee_damage_mul = 0.5,
		priority_shout_max_dis = 3000,
		is_special = true,
		spooc_attack_timeout = {4, 4},
		spooc_attack_beating_time = {3, 3},
		spooc_attack_use_smoke_chance = 0,
		use_animation_on_fire_damage = true,
		dodge_with_grenade = false,
		chatter = presets.enemy_chatter.cloaker,
		melee_weapon = "fists",
		kick_damage = 6.0, --Amount of damage dealt when cloakers kick players.
		jump_kick_damage = 12.0, --Amount of damage dealt when cloakers jump kick players.
		spawn_sound_event_2 = "clk_c01x_plu",
		special_deaths = {
			melee = {
				[("head"):id():key()] = {
					sequence = "dismember_head",
					melee_weapon_id = "sandsteel",
					character_name = "dragon",
					sound_effect = "split_gen_head"
				},
				[("body"):id():key()] = {
					sequence = "dismember_body_top",
					melee_weapon_id = "sandsteel",
					character_name = "dragon",
					sound_effect = "split_gen_body"
				}
			}
		}
	})
	self.spooc.damage.explosion_damage_mul = 2
	self.spooc.damage.hurt_severity = presets.hurt_severities.spooc
end

function CharacterTweakData:_init_spooc_titan(presets)
	self.spooc_titan = deep_clone(self.spooc) --titan cloaker
	self.spooc_titan.weapon = presets.weapon.normal
	self.spooc_titan.tags = {"law", "custom", "special", "spooc"}
	self.spooc_titan.special_deaths = nil
	if self:get_ai_group_type() == "russia" then
		self.spooc_titan.speech_prefix_p1 = self._prefix_data_p1.cloaker()
		self.spooc_titan.speech_prefix_count = nil
		self.spooc_titan.custom_voicework = nil
	else
		self.spooc_titan.speech_prefix_p1 = "CVOC"
		self.spooc_titan.speech_prefix_count = nil
		self.spooc_titan.custom_voicework = "tspook"
	end
	self.spooc_titan.can_cloak = true
	self.spooc_titan.recloak_damage_threshold = 0.5
	self.spooc_titan.can_be_tased = false
	self.spooc_titan.priority_shout_max_dis = 0
	table.insert(self._enemy_list, "spooc_titan")
end

local orig_init_shadow_spooc = CharacterTweakData._init_shadow_spooc
function CharacterTweakData:_init_shadow_spooc(presets) --white house shadow cloaker
	orig_init_shadow_spooc(self, presets)
	override_enemies({self.shadow_spooc}, {
		HEALTH_INIT = 72,
		headshot_dmg_mul = strong_headshot,
		melee_damage_mul = 0.5,
		priority_shout_max_dis = 3000,
		is_special = true,
		spooc_attack_timeout = {4, 4},
		spooc_attack_beating_time = {3, 3},
		use_animation_on_fire_damage = true,
		chatter = presets.enemy_chatter.cloaker,
		melee_weapon = "fists",
		kick_damage = 6.0, --Amount of damage dealt when cloakers kick players.
		jump_kick_damage = 12.0, --Amount of damage dealt when cloakers jump kick players.
		spawn_sound_event_2 = "clk_c01x_plu"
	})
end

function CharacterTweakData:_init_shield(presets) --shielddddd
	self.shield = deep_clone(presets.base)
	self.shield.tags = {"law", "shield", "special"}
	self.shield.damage.shield_explosion_ally_damage_mul = 1
	self.shield.damage.shield_explosion_damage_mul = 1
	self.shield.damage.explosion_damage_mul = 0.75
	self.shield.damage.fire_pool_damage_mul = 0.75
	self.shield.headshot_dmg_mul = normal_headshot
	self.shield.experience = {}
	self.shield.weapon = presets.weapon.shield
	self.shield.detection = presets.detection.normal
	self.shield.HEALTH_INIT = 19.8
	self.shield.damage.melee_damage_mul = 2
	self.shield.allowed_stances = {cbt = true}
	self.shield.allowed_poses = {crouch = true}
	self.shield.always_face_enemy = true
	self.shield.move_speed = presets.move_speed.fast
	self.shield.no_run_start = true
	self.shield.no_run_stop = true
	self.shield.no_retreat = true
	self.shield.no_limping = true
	self.shield.no_arrest = true
	self.shield.surrender = nil
	self.shield.ecm_vulnerability = 1
	self.shield.suppression = nil
	self.shield.ecm_hurts = {
		ears = {min_duration = 3, max_duration = 3}
	}
	self.shield.priority_shout = "f31"
	self.shield.bot_priority_shout = "f31x_any"
	self.shield.priority_shout_max_dis = 3000
	self.shield.rescue_hostages = false
	self.shield.deathguard = false
	self.shield.no_equip_anim = true
	self.shield.wall_fwd_offset = 100
	self.shield.calls_in = nil
	self.shield.ignore_medic_revive_animation = true
	self.shield.damage.hurt_severity = presets.hurt_severities.shield
	self.shield.damage.shield_knock_breakpoint = 11.4
	self.shield.use_animation_on_fire_damage = false
	self.shield.flammable = true
	self.shield.weapon_voice = "3"
	self.shield.experience.cable_tie = "tie_swat"
	self.shield.speech_prefix_p1 = self._prefix_data_p1.swat()
	self.shield.speech_prefix_p2 = self._speech_prefix_p2
	self.shield.speech_prefix_count = 4
	self.shield.access = "shield"
	self.shield.chatter = presets.enemy_chatter.shield
	self.shield.announce_incomming = "incomming_shield"
	self.shield.spawn_sound_event = "shield_identification"
	self.shield.steal_loot = nil
	self.shield.use_animation_on_fire_damage = false
	self.shield.immune_to_knock_down = true
	self.shield.is_special = true
	table.insert(self._enemy_list, "shield")
end

function CharacterTweakData:_init_phalanx_minion(presets) --titan shield
	self.phalanx_minion = deep_clone(self.shield)
	self.phalanx_minion.tags = {"law", "shield", "special", "shield_titan"}
	self.phalanx_minion.experience = {}
	self.phalanx_minion.damage.shield_explosion_damage_mul = 0
	self.phalanx_minion.damage.shield_explosion_ally_damage_mul = 0
	self.phalanx_minion.weapon = presets.weapon.normal
	self.phalanx_minion.detection = presets.detection.normal
	self.phalanx_minion.headshot_dmg_mul = normal_headshot
	self.phalanx_minion.HEALTH_INIT = 25.2
	self.phalanx_minion.damage.explosion_damage_mul = 0.5
	self.phalanx_minion.damage.fire_pool_damage_mul = 0.5
	self.phalanx_minion.damage.melee_damage_mul = 2
	self.phalanx_minion.damage.hurt_severity = presets.hurt_severities.no_hurts
	self.phalanx_minion.damage.shield_knock_breakpoint = 22.4
	self.phalanx_minion.damage.shield_knock_resistance_stacking = 0.9
	self.phalanx_minion.flammable = false
	self.phalanx_minion.priority_shout = "f31"
	self.phalanx_minion.bot_priority_shout = "f31x_any"
	self.phalanx_minion.move_speed = presets.move_speed.slow
	self.phalanx_minion.priority_shout_max_dis = 3000
	self.phalanx_minion.weapon_voice = "3"
	self.phalanx_minion.experience.cable_tie = "tie_swat"
	self.phalanx_minion.access = "shield"
	self.phalanx_minion.chatter = presets.enemy_chatter.shield
	self.phalanx_minion.announce_incomming = "incomming_shield"
	self.phalanx_minion.steal_loot = nil
	self.phalanx_minion.ignore_medic_revive_animation = true
	self.phalanx_minion.ecm_vulnerability = 1
	self.phalanx_minion.ecm_hurts = {
		ears = {min_duration = 3, max_duration = 3}
	}
	self.phalanx_minion.use_animation_on_fire_damage = false
	self.phalanx_minion.can_be_tased = false
	self.phalanx_minion.immune_to_knock_down = true
	self.phalanx_minion.immune_to_concussion = true
	self.phalanx_minion.damage.immune_to_knockback = false
	self.phalanx_minion.spawn_sound_event = "shield_identification"
	self.phalanx_minion.suppression = nil
	self.phalanx_minion.is_special = true
	self.phalanx_minion.speech_prefix_p1 = "CVOSH"
	self.phalanx_minion.speech_prefix_p2 = nil
	self.phalanx_minion.speech_prefix_count = 1
	self.phalanx_minion.custom_voicework = "pdth"
	table.insert(self._enemy_list, "phalanx_minion")
	self.phalanx_minion_assault = deep_clone(self.phalanx_minion)
	table.insert(self._enemy_list, "phalanx_minion_assault")
end

function CharacterTweakData:_init_phalanx_vip(presets) --captain winters
	self.phalanx_vip = deep_clone(self.phalanx_minion)
	self.phalanx_vip.tags = {"law", "shield", "special", "shield_titan", "captain"}
	self.phalanx_vip.damage.immune_to_knockback = true
	self.phalanx_vip.immune_to_knock_down = true
	self.phalanx_vip.damage.shield_explosion_damage_mul = 0
	self.phalanx_vip.damage.shield_explosion_ally_damage_mul = 0
	self.phalanx_vip.HEALTH_INIT = 360
	self.phalanx_vip.damage.shield_knock_breakpoint = 40
	self.phalanx_vip.damage.shield_knock_resistance_stacking = 0.75
	self.phalanx_vip.headshot_dmg_mul = normal_headshot
	self.phalanx_vip.damage.melee_damage_mul = 2
	self.phalanx_vip.spawn_sound_event = "cpa_a02_01"
	self.phalanx_vip.priority_shout = "f45"
	self.phalanx_vip.bot_priority_shout = "f45x_any"
	self.phalanx_vip.priority_shout_max_dis = 3000
	self.phalanx_vip.flammable = false
	self.phalanx_vip.can_be_tased = false
	self.phalanx_vip.ecm_vulnerability = nil
	self.phalanx_vip.die_sound_event_2 = "l2n_x01a_any_3p"
	self.phalanx_vip.must_headshot = true
	self.phalanx_vip.ends_assault_on_death = true
	self.phalanx_vip.suppression = nil
	self.phalanx_vip.ecm_hurts = {}
	self.phalanx_vip.is_special = true
	self.phalanx_vip.custom_voicework = nil
	self.phalanx_vip.speech_prefix_p1 = "cpw"
	self.phalanx_vip.speech_prefix_p2 = nil
	self.phalanx_vip.speech_prefix_count = nil
	self.phalanx_vip.no_damage_mission = true
	self.phalanx_vip.weapon = presets.weapon.expert
	--self.phalanx_vip.death_animation = "death_run"
	--self.phalanx_vip.death_animation_vars = {"var3", "heavy", "fwd", "high"}
	self.phalanx_vip.chatter = {
		aggressive = true,
		retreat = true,
		go_go = true,
		contact = true,
		heal_chatter_winters = true,
		entrance = true
	}
	self.phalanx_vip.slowing_bullets = {
		duration = 1.5,
		power = 0.75
	}
	self.phalanx_vip.do_omnia = {
		cooldown = 8,
		radius = 1200
	}
	self.phalanx_vip.captain_type = heat.captain_types.winter
	table.insert(self._enemy_list, "phalanx_vip")
end

function CharacterTweakData:_init_spring(presets) --captain spring
	self.spring = deep_clone(self.tank)
	self.spring.weapon = presets.weapon.dozer
	self.spring.tags = {"law", "custom", "special", "captain", "no_run"}
	self.spring.move_speed = presets.move_speed.very_slow
	self.spring.rage_move_speed = presets.move_speed.fast
	self.spring.grenade = cluster_frag
	self.spring.no_run_start = true
	self.spring.no_run_stop = true
	self.spring.no_retreat = true
	self.spring.no_limping = true
	self.spring.no_arrest = true
	self.spring.ends_assault_on_death = true
	self.spring.no_damage_mission = true
	self.spring.immune_to_knock_down = true
	self.spring.HEALTH_INIT = 480
	self.spring.headshot_dmg_mul = normal_headshot
	self.spring.damage.explosion_damage_mul = 2
	self.spring.priority_shout = "f45"
	self.spring.bot_priority_shout = "f45x_any"
	self.spring.priority_shout_max_dis = 3000
	self.spring.flammable = true
	self.spring.rescue_hostages = false
	self.spring.can_be_tased = false
	self.spring.ecm_vulnerability = nil
	self.spring.immune_to_concussion = true
	self.spring.ecm_hurts = {}
	self.spring.damage.hurt_severity = presets.hurt_severities.spring
	self.spring.melee_weapon = "fists_dozer"
	self.spring.speech_prefix_p1 = "cpw"
	self.spring.speech_prefix_p2 = nil
	self.spring.speech_prefix_count = nil
	self.spring.chatter = {
		aggressive = true,
		retreat = true,
		go_go = true,
		contact = true,
		entrance = true
	}
	self.spring.announce_incomming = "incomming_captain"
	self.spring.spawn_sound_event = "cpa_a02_01"
	self.spring.die_sound_event_2 = "bdz_x02a_any_3p"
	self.spring.is_special = true
	self.spring.captain_type = heat.captain_types.spring
	table.insert(self._enemy_list, "spring")

	--Headless Titandozer Boss
	self.headless_hatman = deep_clone(self.spring)
	self.headless_hatman.custom_voicework = "hatman"
	self.headless_hatman.slowing_bullets = {
		duration = 1,
		power = 0.5
	}
	self.headless_hatman.grenade = hatman_molotov
	self.headless_hatman.captain_type = heat.captain_types.hvh
	table.insert(self._enemy_list, "headless_hatman")
end

function CharacterTweakData:_init_summers(presets) --captain summers
	self.summers = deep_clone(presets.base)
	self.summers.tags = {"law", "custom", "special", "summers"}
	self.summers.experience = {}
	self.summers.weapon = presets.weapon.expert
	self.summers.melee_weapon = "buzzer_summer"
	self.summers.weapon_safety_range = 1
	self.summers.detection = presets.detection.normal
	self.summers.HEALTH_INIT = 117
	self.summers.headshot_dmg_mul = normal_headshot
	self.summers.flammable = false
	self.summers.use_animation_on_fire_damage = false
	self.summers.damage.hurt_severity = presets.hurt_severities.summers
	self.summers.damage.explosion_damage_mul = 0.5
	self.summers.bag_dmg_mul = 6
	self.summers.move_speed = presets.move_speed.fast
	self.summers.crouch_move = false
	self.summers.no_retreat = true
	self.summers.no_limping = true
	self.summers.no_arrest = true
	self.summers.ends_assault_on_death = true
	self.summers.no_damage_mission = true
	self.summers.immune_to_knock_down = true
	self.summers.priority_shout = "f45"
	self.summers.bot_priority_shout = "f45x_any"
	self.summers.priority_shout_max_dis = 3000
	self.summers.surrender = nil
	self.summers.ecm_vulnerability = 0
	self.summers.ecm_hurts = {}
	self.summers.surrender_break_time = {4, 6}
	self.summers.suppression = nil
	self.summers.weapon_voice = "3"
	self.summers.experience.cable_tie = "tie_swat"
	self.summers.custom_voicework = "tdozer"
	self.summers.speech_prefix_p1 = nil
	self.summers.speech_prefix_p2 = nil
	self.summers.speech_prefix_count = nil
	self.summers.access = "taser"
	self.summers.dodge = presets.dodge.elite
	self.summers.use_gas = true
	self.summers.rescue_hostages = false
	self.summers.can_be_tased = false
	self.summers.immune_to_concussion = true
	self.summers.deathguard = true
	self.summers.tase_on_melee = true
	self.summers.chatter = presets.enemy_chatter.summers
	self.summers.announce_incomming = "incomming_captain"
	if self:get_ai_group_type() == "russia" then
		self.summers.spawn_sound_event = "cloaker_spawn"
	else
		self.summers.spawn_sound_event = "cpa_a02_01"
	end
	self.summers.steal_loot = nil
	self.summers.is_special = true
	self.summers.captain_type = heat.captain_types.summer
	self.summers.leader = {max_nr_followers = 3}
	table.insert(self._enemy_list, "summers")
end

function CharacterTweakData:_init_autumn(presets) --captain autumn
	self.autumn = deep_clone(presets.base)
	self.autumn.tags = {"law", "custom", "special", "customvo"}
	self.autumn.experience = {}
	self.autumn.damage.hurt_severity = presets.hurt_severities.autumn
	self.autumn.weapon = presets.weapon.expert
	self.autumn.detection = presets.detection.normal
	self.autumn.damage.immune_to_knockback = true
	self.autumn.immune_to_knock_down = true
	self.autumn.immune_to_concussion = true
	self.autumn.HEALTH_INIT = 192
	self.autumn.headshot_dmg_mul = normal_headshot
	self.autumn.flammable = false
	self.autumn.damage.explosion_damage_mul = 2
	self.autumn.move_speed = presets.move_speed.lightning
	self.autumn.can_cloak = true
	self.autumn.recloak_damage_threshold = 0.2
	self.autumn.no_retreat = true
	self.autumn.no_limping = true
	self.autumn.no_arrest = true
	self.autumn.surrender_break_time = {4, 6}
	self.autumn.suppression = nil
	self.autumn.surrender = nil
	self.autumn.can_be_tased = false
	self.autumn.priority_shout_max_dis = 0
	self.autumn.unintimidateable = true
	self.autumn.must_headshot = true
	self.autumn.priority_shout_max_dis = 3000
	self.autumn.rescue_hostages = true
	self.autumn.spooc_attack_timeout = {4, 4}
	self.autumn.spooc_attack_beating_time = {0, 0}
	self.autumn.no_damage_mission = true
	self.autumn.spawn_sound_event_2 = "cloaker_spawn"
	self.autumn.grenade = autumn_gas
	self.autumn.cuff_on_melee = true
	--self.autumn.spawn_sound_event_2 = "cpa_a02_01"--uncomment for testing purposes
	self.autumn.weapon_voice = "3"
	self.autumn.experience.cable_tie = "tie_swat"
	self.autumn.speech_prefix_p1 = "cpa"
	self.autumn.speech_prefix_count = nil
	self.autumn.custom_voicework = "autumn"
	self.autumn.ends_assault_on_death = true
	self.autumn.access = "spooc"
	self.autumn.dodge = presets.dodge.autumn
	self.autumn.chatter = {
		aggressive = true,
		retreat = true,
		go_go = true,
		contact = true,
		entrance = true
	}
	self.autumn.steal_loot = nil
	self.autumn.melee_weapon = nil
	self.autumn.use_radio = nil
	self.autumn.is_special = true
	self.autumn.dodge_with_grenade = {
		flash = {duration = {
			1,
			1
		}},
		check = function (t, nr_grenades_used)
			local delay_till_next_use = 4
			local chance = 1

			if math.random() < chance then
				return true, t + delay_till_next_use
			end

			return false, t + delay_till_next_use
		end
	}
	self.autumn.do_autumn_blackout = true --if true, deployables in a radius around this cop will be disabled
	self.autumn.captain_type = heat.captain_types.autumn
	table.insert(self._enemy_list, "autumn")
end

function CharacterTweakData:_init_taser(presets) --taser
	self.taser = deep_clone(presets.base)
	self.taser.tags = {"law", "taser", "special"}
	self.taser.experience = {}
	self.taser.weapon = presets.weapon.taser
	self.taser.detection = presets.detection.normal
	self.taser.damage.hurt_severity = presets.hurt_severities.taser
	self.taser.HEALTH_INIT = 48
	self.taser.headshot_dmg_mul = normal_headshot
	self.taser.move_speed = presets.move_speed.fast
	self.taser.no_retreat = true
	self.taser.no_arrest = true
	self.taser.surrender = presets.surrender.special
	self.taser.ecm_vulnerability = 1
	self.taser.ecm_hurts = {
		ears = {min_duration = 3, max_duration = 3}
	}
	self.taser.surrender_break_time = {4, 6}
	self.taser.suppression = nil
	self.taser.weapon_voice = "3"
	self.taser.experience.cable_tie = "tie_swat"
	self.taser.speech_prefix_p1 = self._prefix_data_p1.taser()
	self.taser.speech_prefix_p2 = nil
	self.taser.speech_prefix_count = nil
	self.taser.spawn_sound_event = self._prefix_data_p1.taser() .. "_entrance"
	self.taser.access = "taser"
	self.taser.dodge = presets.dodge.athletic
	self.taser.priority_shout = "f32"
	self.taser.bot_priority_shout = "f32x_any"
	self.taser.priority_shout_max_dis = 3000
	self.taser.rescue_hostages = false
	self.taser.deathguard = true
	self.taser.shock_damage = 8.0 --Amount of damage dealt when taser shocks down.
	self.taser.chatter = {
		aggressive = true,
		retreat = true,
		go_go = true,
		contact = true,
		entrance = true
	}
	self.taser.announce_incomming = "incomming_taser"
	self.taser.steal_loot = nil
	self.taser.special_deaths = {}
	self.taser.special_deaths.bullet = {
		[("head"):id():key()] = {
			character_name = "bodhi",
			weapon_id = "model70",
			sequence = "kill_tazer_headshot",
			special_comment = "x01"
		}
	}
	self.taser.is_special = true
	table.insert(self._enemy_list, "taser")

	self.taser_summers = deep_clone(self.taser) --elytra
	self.taser_summers.weapon = presets.weapon.taser_summers
	self.taser_summers.HEALTH_INIT = 100.8
	self.taser_summers.headshot_dmg_mul = normal_headshot
	self.taser_summers.tags = {"female_enemy","taser", "medic_summers", "custom", "special"}
	self.taser_summers.ignore_medic_revive_animation = false
	self.taser_summers.flammable = false
	self.taser_summers.use_animation_on_fire_damage = false
	self.taser_summers.damage.hurt_severity = presets.hurt_severities.taser_summers
	self.taser_summers.ecm_vulnerability = 0
	self.taser_summers.ecm_hurts = {}
	self.taser_summers.chatter = presets.enemy_chatter.summers
	self.taser_summers.no_retreat = true
	self.taser_summers.no_limping = true
	self.taser_summers.rescue_hostages = false
	self.taser_summers.steal_loot = nil
	self.taser_summers.immune_to_concussion = true
	self.taser_summers.no_damage_mission = true
	self.taser_summers.no_arrest = true
	self.taser_summers.immune_to_knock_down = true
	self.taser_summers.priority_shout = "f45"
	self.taser_summers.bot_priority_shout = "f45x_any"
	self.taser_summers.speech_prefix_p1 = "fl"
	self.taser_summers.speech_prefix_p2 = "n"
	self.taser_summers.speech_prefix_count = 1
	self.taser_summers.spawn_sound_event = nil
	self.taser_summers.custom_voicework = nil
	self.taser_summers.is_special = true
	self.taser_summers.follower = true
	self.taser_summers.tase_on_melee = true
	self.taser_summers.slowing_bullets = {
		duration = 3,
		power = 1,
		taunt = true
	}
	table.insert(self._enemy_list, "taser_summers")

	self.taser_titan = deep_clone(self.taser) --titan taser
	self.taser_titan.weapon = presets.weapon.good
	self.taser_titan.tags = {"taser", "taser_titan", "custom", "special"}
	self.taser_titan.HEALTH_INIT = 57.6
	self.taser_titan.headshot_dmg_mul = normal_headshot
	self.taser_titan.priority_shout = "f32"
	self.taser_titan.bot_priority_shout = "f32x_any"
	self.taser_titan.immune_to_concussion = true
	self.taser_titan.use_animation_on_fire_damage = false
	self.taser_titan.can_be_tased = false
	if self:get_ai_group_type() == "russia" then
		self.taser_titan.spawn_sound_event = "rtsr_elite"
	else
		self.taser_titan.spawn_sound_event = "tsr_elite"
	end
	self.taser_titan.custom_voicework = nil
	self.taser_titan.surrender = nil
	self.taser_titan.dodge = presets.dodge.elite
	self.taser_titan.is_special = true
	self.taser_titan.move_speed = presets.move_speed.fast
	self.taser_titan.tase_on_melee = true
	self.taser_titan.slowing_bullets = {
		duration = 3,
		power = 1,
		taunt = true
	}
	table.insert(self._enemy_list, "taser_titan")
end

function CharacterTweakData:_init_boom(presets) --grenadier
	self.boom = deep_clone(presets.base)
	self.boom.tags = {"law", "boom", "custom", "special", "customvo"}
	self.boom.experience = {}
	self.boom.weapon = presets.weapon.good
	self.boom.melee_weapon = "baton"
	self.boom.weapon_safety_range = 1000
	self.boom.detection = presets.detection.normal
	self.boom.HEALTH_INIT = 48
	self.boom.headshot_dmg_mul = normal_headshot
	self.boom.HEALTH_SUICIDE_LIMIT = 0.25
	self.boom.flammable = true
	self.boom.use_animation_on_fire_damage = true
	self.boom.damage.explosion_damage_mul = 0.5
	self.boom.damage.hurt_severity = presets.hurt_severities.boom
	self.boom.bag_dmg_mul = 6
	self.boom.move_speed = presets.move_speed.fast
	self.boom.no_retreat = true
	self.boom.no_arrest = true
	self.boom.surrender = nil
	self.boom.ecm_vulnerability = 1
	self.boom.ecm_hurts = {
		ears = {min_duration = 3, max_duration = 3}
	}
	self.boom.surrender_break_time = {4, 6}
	self.boom.suppression = nil
	self.boom.weapon_voice = "3"
	self.boom.experience.cable_tie = "tie_swat"
	self.boom.speech_prefix_p1 = nil
	self.boom.speech_prefix_p2 = nil
	self.boom.speech_prefix_count = nil
	self.boom.access = "taser"
	self.boom.dodge = presets.dodge.athletic
	self.boom.use_gas = true
	self.boom.grenade = tear_gas
	self.boom.priority_shout = "g29"
	self.boom.bot_priority_shout = "g29"
	self.boom.priority_shout_max_dis = 3000
	self.boom.custom_shout = true
	self.boom.rescue_hostages = false
	self.boom.deathguard = true
	self.boom.chatter = {
		aggressive = true,
		retreat = true,
		go_go = true,
		contact = true,
		entrance = true
	}
	self.boom.announce_incomming = "incomming_gren"
	self.boom.steal_loot = nil
	if self:get_ai_group_type() == "federales" then
		self.boom.custom_voicework = "grenadier_bex"
	else
		self.boom.custom_voicework = "grenadier"
	end
	self.boom.is_special = true
	table.insert(self._enemy_list, "boom")

	self.boom_summers = deep_clone(self.boom) --molly
	self.boom_summers.weapon = presets.weapon.expert
	self.boom_summers.use_animation_on_fire_damage = false
	self.boom_summers.damage.explosion_damage_mul = 1
	self.boom_summers.damage.fire_damage_mul = 1
	self.boom_summers.damage.hurt_severity = presets.hurt_severities.boom_summers
	self.boom_summers.chatter = presets.enemy_chatter.summers
	self.boom_summers.speech_prefix_p1 = "fl"
	self.boom_summers.speech_prefix_p2 = "n"
	self.boom_summers.speech_prefix_count = 1
	self.boom_summers.custom_voicework = nil
	self.boom_summers.HEALTH_INIT = 100.8
	self.boom_summers.headshot_dmg_mul = normal_headshot
	self.boom_summers.tags = {"female_enemy", "medic_summers", "custom", "special"}
	self.boom_summers.ignore_medic_revive_animation = false
	self.boom_summers.grenade = molotov
	self.boom_summers.no_retreat = true
	self.boom_summers.no_limping = true
	self.boom_summers.no_arrest = true
	self.boom_summers.immune_to_knock_down = true
	self.boom_summers.immune_to_concussion = true
	self.boom_summers.no_damage_mission = true
	self.boom_summers.priority_shout = "f45"
	self.boom_summers.bot_priority_shout = "f45x_any"
	self.boom_summers.custom_shout = false
	self.boom_summers.rescue_hostages = false
	self.boom_summers.steal_loot = nil
	self.boom_summers.follower = true
	self.boom_summers.ecm_vulnerability = 0
	self.boom_summers.ecm_hurts = {}
	table.insert(self._enemy_list, "boom_summers")
end

function CharacterTweakData:_init_inside_man(presets) --fwb insider
	self.inside_man = deep_clone(presets.base)
	self.inside_man.experience = {}
	self.inside_man.weapon = presets.weapon.good
	self.inside_man.detection = presets.detection.blind
	self.inside_man.HEALTH_INIT = 10
	self.inside_man.headshot_dmg_mul = normal_headshot
	self.inside_man.move_speed = presets.move_speed.normal
	self.inside_man.surrender_break_time = {10, 15}
	self.inside_man.suppression = nil
	self.inside_man.surrender = nil
	self.inside_man.unintimidateable = true
	self.inside_man.ecm_vulnerability = nil
	self.inside_man.ecm_hurts = {
		ears = {min_duration = 0, max_duration = 0}
	}
	self.inside_man.weapon_voice = "1"
	self.inside_man.experience.cable_tie = "tie_swat"
	self.inside_man.speech_prefix_p1 = "l"
	self.inside_man.speech_prefix_p2 = "n"
	self.inside_man.speech_prefix_count = 4
	self.inside_man.access = "cop"
	self.inside_man.dodge = presets.dodge.average
	self.inside_man.chatter = presets.enemy_chatter.no_chatter
	self.inside_man.melee_weapon = "baton"
	self.inside_man.calls_in = nil
end

function CharacterTweakData:_init_civilian(presets) --civilian (shoot on sight)
	self.civilian = {
		experience = {}
	}
	self.civilian.tags = {"civilian"}
	self.civilian.detection = presets.detection.civilian
	self.civilian.HEALTH_INIT = 0.9 --Some day these poor guys will get proper health
	self.civilian.headshot_dmg_mul = normal_headshot
	self.civilian.move_speed = presets.move_speed.civ_fast
	self.civilian.flee_type = "escape"
	self.civilian.scare_max = {10, 20}
	self.civilian.scare_shot = 1
	self.civilian.scare_intimidate = -5
	self.civilian.submission_max = {60, 120}
	self.civilian.submission_intimidate = 120
	self.civilian.run_away_delay = {5, 20}
	self.civilian.damage = {
		hurt_severity = presets.hurt_severities.no_hurts
	}
	self.civilian.flammable = false
	self.civilian.ecm_vulnerability = nil
	self.civilian.ecm_hurts = {
		ears = {min_duration = 0, max_duration = 0}
	}
	self.civilian.experience.cable_tie = "tie_civ"
	self.civilian.die_sound_event = "a01x_any"
	self.civilian.silent_priority_shout = "f37"
	self.civilian.speech_prefix_p1 = "cm"
	self.civilian.speech_prefix_count = 2
	self.civilian.access = "civ_male"
	self.civilian.intimidateable = true
	self.civilian.challenges = {type = "civilians"}
	if job == "nmh" or job == "nmh_res" then
		self.civilian.calls_in = false
	else
		self.civilian.calls_in = true
	end
	self.civilian.hostage_move_speed = 1.5
	self.civilian_female = deep_clone(self.civilian)
	self.civilian_female.die_sound_event = "a02x_any"
	self.civilian_female.speech_prefix_p1 = "cf"
	self.civilian_female.speech_prefix_count = 5
	self.civilian_female.female = true
	self.civilian_female.access = "civ_female"
	self.robbers_safehouse = deep_clone(self.civilian)
	self.robbers_safehouse.scare_shot = 0
	self.robbers_safehouse.scare_intimidate = 0
	self.robbers_safehouse.intimidateable = false
	self.robbers_safehouse.ignores_aggression = true
	self.robbers_safehouse.calls_in = nil
	self.robbers_safehouse.ignores_contours = true
	self.robbers_safehouse.HEALTH_INIT = 20
	self.robbers_safehouse.headshot_dmg_mul = 1
	self.robbers_safehouse.use_ik = true
end

function CharacterTweakData:_init_civilian_mariachi(presets)
	self.civilian_mariachi = deep_clone(self.civilian)
end

function CharacterTweakData:_init_bank_manager(presets) --i think this is Bo
	self.bank_manager = {
		experience = {},
		escort = {}
	}
	self.bank_manager.tags = {"civilian"}
	self.bank_manager.die_sound_event = "a01x_any"
	self.bank_manager.detection = presets.detection.civilian
	self.bank_manager.HEALTH_INIT = self.civilian.HEALTH_INIT
	self.bank_manager.headshot_dmg_mul = self.civilian.headshot_dmg_mul
	self.bank_manager.move_speed = presets.move_speed.normal
	self.bank_manager.flee_type = "hide"
	self.bank_manager.scare_max = {10, 20}
	self.bank_manager.scare_shot = 1
	self.bank_manager.scare_intimidate = -5
	self.bank_manager.submission_max = {60, 120}
	self.bank_manager.submission_intimidate = 120
	self.bank_manager.damage = {
		hurt_severity = presets.hurt_severities.no_hurts
	}
	self.bank_manager.flammable = false
	self.bank_manager.ecm_vulnerability = nil
	self.bank_manager.ecm_hurts = {
		ears = {min_duration = 0, max_duration = 0}
	}
	self.bank_manager.experience.cable_tie = "tie_civ"
	self.bank_manager.speech_prefix_p1 = "cm"
	self.bank_manager.speech_prefix_count = 2
	self.bank_manager.access = "civ_male"
	self.bank_manager.intimidateable = true
	self.bank_manager.hostage_move_speed = 1.5
	self.bank_manager.challenges = {type = "civilians"}
	self.bank_manager.calls_in = true
end

function CharacterTweakData:_init_drunk_pilot(presets) --almir on white xmas
	self.drunk_pilot = deep_clone(self.civilian)
	self.drunk_pilot.move_speed = presets.move_speed.civ_fast
	self.drunk_pilot.flee_type = "hide"
	self.drunk_pilot.access = "civ_male"
	self.drunk_pilot.intimidateable = nil
	self.drunk_pilot.challenges = {type = "civilians"}
	self.drunk_pilot.calls_in = nil
	self.drunk_pilot.ignores_aggression = true
end

function CharacterTweakData:_init_boris(presets) --goat sim 2 feller
	self.boris = deep_clone(self.civilian)
	self.boris.flee_type = "hide"
	self.boris.access = "civ_male"
	self.boris.intimidateable = nil
	self.boris.challenges = {type = "civilians"}
	self.boris.calls_in = nil
	self.boris.ignores_aggression = true
end

function CharacterTweakData:_init_old_hoxton_mission(presets) --prison hoxton
	self.old_hoxton_mission = deep_clone(presets.base)
	self.old_hoxton_mission.experience = {}
	self.old_hoxton_mission.no_run_start = true
	self.old_hoxton_mission.no_run_stop = true
	self.old_hoxton_mission.weapon = presets.weapon.good
	self.old_hoxton_mission.detection = presets.detection.gang_member
	self.old_hoxton_mission.damage = presets.gang_member_damage
	self.old_hoxton_mission.damage.explosion_damage_mul = 0
	self.old_hoxton_mission.HEALTH_INIT = 20
	self.old_hoxton_mission.headshot_dmg_mul = 1
	self.old_hoxton_mission.move_speed = presets.move_speed.gang_member
	--Cause they don't like being told what to do
	self.old_hoxton_mission.allowed_poses = {stand = true}
	self.old_hoxton_mission.surrender_break_time = {6, 10}
	self.old_hoxton_mission.suppression = nil
	self.old_hoxton_mission.surrender = false
	self.old_hoxton_mission.weapon_voice = "1"
	self.old_hoxton_mission.experience.cable_tie = "tie_swat"
	self.old_hoxton_mission.speech_prefix_p1 = "rb2"
	self.old_hoxton_mission.access = "teamAI4"
	self.old_hoxton_mission.dodge = nil
	self.old_hoxton_mission.no_arrest = true
	self.old_hoxton_mission.chatter = presets.enemy_chatter.no_chatter
	self.old_hoxton_mission.use_radio = nil
	self.old_hoxton_mission.melee_weapon = "toothbrush"
	self.old_hoxton_mission.steal_loot = false
	self.old_hoxton_mission.rescue_hostages = false
	self.old_hoxton_mission.crouch_move = false
	--No more being mean to Hoxton
	self.old_hoxton_mission.is_escort = true
	self.old_hoxton_mission.speech_escort = "f38"
	self.old_hoxton_mission.escort_idle_talk = false

	self.anubis = deep_clone(self.old_hoxton_mission)	 --m?--
end

function CharacterTweakData:_init_spa_vip(presets) --charon
	self.spa_vip = deep_clone(self.old_hoxton_mission)
	self.spa_vip.melee_weapon = "fists"
	self.spa_vip.spotlight_important = 100
	self.spa_vip.is_escort = true
	self.spa_vip.escort_idle_talk = false
	self.spa_vip.escort_scared_dist = 100
end

function CharacterTweakData:_init_spa_vip_hurt(presets) --unused i thinks
	self.spa_vip_hurt = deep_clone(self.civilian)
	self.spa_vip_hurt.move_speed = presets.move_speed.slow
	self.spa_vip_hurt.flee_type = "hide"
	self.spa_vip_hurt.access = "civ_male"
	self.spa_vip_hurt.intimidateable = nil
	self.spa_vip_hurt.challenges = {type = "civilians"}
	self.spa_vip_hurt.calls_in = nil
	self.spa_vip_hurt.ignores_aggression = true
end

function CharacterTweakData:_init_russian(presets)
	self.russian = {}
	self.russian.always_face_enemy = true
	self.russian.no_run_start = true
	self.russian.no_run_stop = true
	self.russian.flammable = false
	self.russian.damage = presets.gang_member_damage
	self.russian.weapon = deep_clone(presets.weapon.gang_member)
	self.russian.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.dallas.primaries,
		secondary = self.char_wep_tables.dallas.secondaries
	}
	self.russian.detection = presets.detection.gang_member
	self.russian.move_speed = presets.move_speed.very_fast_teamai
	self.russian.crouch_move = false
	self.russian.speech_prefix = "rb2"
	self.russian.weapon_voice = "1"
	self.russian.access = "teamAI1"
	self.russian.dodge = presets.dodge.athletic_bot
	self.russian.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_german(presets)
	self.german = {}
	self.german.always_face_enemy = true
	self.german.no_run_start = true
	self.german.no_run_stop = true
	self.german.flammable = false
	self.german.melee_weapon = "nin"
	self.german.damage = presets.gang_member_damage
	self.german.weapon = deep_clone(presets.weapon.gang_member)
	self.german.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.wolf.primaries,
		secondary = self.char_wep_tables.wolf.secondaries
	}
	self.german.detection = presets.detection.gang_member
	self.german.move_speed = presets.move_speed.very_fast_teamai
	self.german.crouch_move = false
	self.german.speech_prefix = "rb2"
	self.german.weapon_voice = "2"
	self.german.access = "teamAI1"
	self.german.dodge = presets.dodge.athletic_bot
	self.german.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_spanish(presets)
	self.spanish = {}
	self.spanish.always_face_enemy = true
	self.spanish.no_run_start = true
	self.spanish.no_run_stop = true
	self.spanish.flammable = false
	self.spanish.melee_weapon = "gerber"
	self.spanish.damage = presets.gang_member_damage
	self.spanish.weapon = deep_clone(presets.weapon.gang_member)
	self.spanish.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.chains.primaries,
		secondary = self.char_wep_tables.chains.secondaries
	}
	self.spanish.detection = presets.detection.gang_member
	self.spanish.move_speed = presets.move_speed.very_fast_teamai
	self.spanish.crouch_move = false
	self.spanish.speech_prefix = "rb2"
	self.spanish.weapon_voice = "3"
	self.spanish.access = "teamAI1"
	self.spanish.dodge = presets.dodge.athletic_bot
	self.spanish.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_american(presets)
	self.american = {}
	self.american.always_face_enemy = true
	self.american.no_run_start = true
	self.american.no_run_stop = true
	self.american.flammable = false
	self.american.damage = presets.gang_member_damage
	self.american.weapon = deep_clone(presets.weapon.gang_member)
	self.american.melee_weapon = "baton"
	self.american.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.houston.primaries,
		secondary = self.char_wep_tables.houston.secondaries
	}
	self.american.detection = presets.detection.gang_member
	self.american.move_speed = presets.move_speed.very_fast_teamai
	self.american.crouch_move = false
	self.american.speech_prefix = "rb2"
	self.american.weapon_voice = "3"
	self.american.access = "teamAI1"
	self.american.dodge = presets.dodge.athletic_bot
	self.american.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_jowi(presets)
	self.jowi = {}
	self.jowi.always_face_enemy = true
	self.jowi.no_run_start = true
	self.jowi.no_run_stop = true
	self.jowi.melee_weapon = "kabartanto"
	self.jowi.damage = presets.gang_member_damage
	self.jowi.weapon = deep_clone(presets.weapon.gang_member)
	self.jowi.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.wick.primaries,
		secondary = self.char_wep_tables.wick.secondaries
	}
	self.jowi.detection = presets.detection.gang_member
	self.jowi.move_speed = presets.move_speed.very_fast_teamai
	self.jowi.crouch_move = false
	self.jowi.speech_prefix = "rb2"
	self.jowi.weapon_voice = "3"
	self.jowi.access = "teamAI1"
	self.jowi.dodge = presets.dodge.athletic_bot
	self.jowi.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_old_hoxton(presets)
	self.old_hoxton = {}
	self.old_hoxton.always_face_enemy = true
	self.old_hoxton.no_run_start = true
	self.old_hoxton.no_run_stop = true
	self.old_hoxton.melee_weapon = "switchblade"
	self.old_hoxton.damage = presets.gang_member_damage
	self.old_hoxton.weapon = deep_clone(presets.weapon.gang_member)
	self.old_hoxton.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.hoxton.primaries,
		secondary = self.char_wep_tables.hoxton.secondaries
	}
	self.old_hoxton.detection = presets.detection.gang_member
	self.old_hoxton.move_speed = presets.move_speed.very_fast_teamai
	self.old_hoxton.crouch_move = false
	self.old_hoxton.speech_prefix = "rb2"
	self.old_hoxton.weapon_voice = "3"
	self.old_hoxton.access = "teamAI1"
	self.old_hoxton.dodge = presets.dodge.athletic_bot
	self.old_hoxton.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_clover(presets)
	self.female_1 = {}
	self.female_1.always_face_enemy = true
	self.female_1.no_run_start = true
	self.female_1.no_run_stop = true
	self.female_1.melee_weapon = "shillelagh"
	self.female_1.damage = presets.gang_member_damage
	self.female_1.weapon = deep_clone(presets.weapon.gang_member)
	self.female_1.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.clover.primaries,
		secondary = self.char_wep_tables.clover.secondaries
	}
	self.female_1.detection = presets.detection.gang_member
	self.female_1.move_speed = presets.move_speed.very_fast_teamai
	self.female_1.crouch_move = false
	self.female_1.speech_prefix = "rb7"
	self.female_1.weapon_voice = "3"
	self.female_1.access = "teamAI1"
	self.female_1.dodge = presets.dodge.athletic_bot
	self.female_1.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_dragan(presets)
	self.dragan = {}
	self.dragan.always_face_enemy = true
	self.dragan.no_run_start = true
	self.dragan.no_run_stop = true
	self.dragan.melee_weapon = "meat_cleaver"
	self.dragan.damage = presets.gang_member_damage
	self.dragan.weapon = deep_clone(presets.weapon.gang_member)
	self.dragan.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.dragan.primaries,
		secondary = self.char_wep_tables.dragan.secondaries
	}
	self.dragan.detection = presets.detection.gang_member
	self.dragan.move_speed = presets.move_speed.very_fast_teamai
	self.dragan.crouch_move = false
	self.dragan.speech_prefix = "rb8"
	self.dragan.weapon_voice = "3"
	self.dragan.access = "teamAI1"
	self.dragan.dodge = presets.dodge.athletic_bot
	self.dragan.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_jacket(presets)
	self.jacket = {}
	self.jacket.always_face_enemy = true
	self.jacket.no_run_start = true
	self.jacket.no_run_stop = true
	self.jacket.melee_weapon = "hammer"
	self.jacket.damage = presets.gang_member_damage
	self.jacket.weapon = deep_clone(presets.weapon.gang_member)
	self.jacket.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.jacket.primaries,
		secondary = self.char_wep_tables.jacket.secondaries
	}
	self.jacket.detection = presets.detection.gang_member
	self.jacket.move_speed = presets.move_speed.very_fast_teamai
	self.jacket.crouch_move = false
	self.jacket.speech_prefix = "rb9"
	self.jacket.weapon_voice = "3"
	self.jacket.access = "teamAI1"
	self.jacket.dodge = presets.dodge.athletic_bot
	self.jacket.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_bonnie(presets)
	self.bonnie = {}
	self.bonnie.always_face_enemy = true
	self.bonnie.no_run_start = true
	self.bonnie.no_run_stop = true
	self.bonnie.melee_weapon = "croupier_rake"
	self.bonnie.damage = presets.gang_member_damage
	self.bonnie.weapon = deep_clone(presets.weapon.gang_member)
	self.bonnie.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.bonnie.primaries,
		secondary = self.char_wep_tables.bonnie.secondaries
	}
	self.bonnie.detection = presets.detection.gang_member
	self.bonnie.move_speed = presets.move_speed.very_fast_teamai
	self.bonnie.dodge = presets.dodge.athletic_bot
	self.bonnie.crouch_move = false
	self.bonnie.speech_prefix = "rb10"
	self.bonnie.weapon_voice = "3"
	self.bonnie.access = "teamAI1"
	self.bonnie.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_sokol(presets)
	self.sokol = {}
	self.sokol.always_face_enemy = true
	self.sokol.no_run_start = true
	self.sokol.no_run_stop = true
	self.sokol.melee_weapon = "hockey"
	self.sokol.damage = presets.gang_member_damage
	self.sokol.weapon = deep_clone(presets.weapon.gang_member)
	self.sokol.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.sokol.primaries,
		secondary = self.char_wep_tables.sokol.secondaries
	}
	self.sokol.detection = presets.detection.gang_member
	self.sokol.move_speed = presets.move_speed.very_fast_teamai
	self.sokol.crouch_move = false
	self.sokol.speech_prefix = "rb11"
	self.sokol.weapon_voice = "3"
	self.sokol.access = "teamAI1"
	self.sokol.dodge = presets.dodge.athletic_bot
	self.sokol.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_dragon(presets)
	self.dragon = {}
	self.dragon.always_face_enemy = true
	self.dragon.no_run_start = true
	self.dragon.no_run_stop = true
	self.dragon.melee_weapon = "sandsteel"
	self.dragon.damage = presets.gang_member_damage
	self.dragon.weapon = deep_clone(presets.weapon.gang_member)
	self.dragon.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.jiro.primaries,
		secondary = self.char_wep_tables.jiro.secondaries
	}
	self.dragon.detection = presets.detection.gang_member
	self.dragon.move_speed = presets.move_speed.very_fast_teamai
	self.dragon.crouch_move = false
	self.dragon.speech_prefix = "rb12"
	self.dragon.weapon_voice = "3"
	self.dragon.access = "teamAI1"
	self.dragon.dodge = presets.dodge.athletic_bot
	self.dragon.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_bodhi(presets)
	self.bodhi = {}
	self.bodhi.always_face_enemy = true
	self.bodhi.no_run_start = true
	self.bodhi.no_run_stop = true
	self.bodhi.melee_weapon = "iceaxe"
	self.bodhi.damage = presets.gang_member_damage
	self.bodhi.weapon = deep_clone(presets.weapon.gang_member)
	self.bodhi.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.bodhi.primaries,
		secondary = self.char_wep_tables.bodhi.secondaries
	}
	self.bodhi.detection = presets.detection.gang_member
	self.bodhi.move_speed = presets.move_speed.very_fast_teamai
	self.bodhi.crouch_move = false
	self.bodhi.speech_prefix = "rb13"
	self.bodhi.weapon_voice = "3"
	self.bodhi.access = "teamAI1"
	self.bodhi.dodge = presets.dodge.athletic_bot
	self.bodhi.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_jimmy(presets)
	self.jimmy = {}
	self.jimmy.always_face_enemy = true
	self.jimmy.no_run_start = true
	self.jimmy.no_run_stop = true
	self.jimmy.melee_weapon = "ballistic"
	self.jimmy.damage = presets.gang_member_damage
	self.jimmy.weapon = deep_clone(presets.weapon.gang_member)
	self.jimmy.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.jimmy.primaries,
		secondary = self.char_wep_tables.jimmy.secondaries
	}
	self.jimmy.detection = presets.detection.gang_member
	self.jimmy.move_speed = presets.move_speed.very_fast_teamai
	self.jimmy.crouch_move = false
	self.jimmy.speech_prefix = "rb14"
	self.jimmy.weapon_voice = "3"
	self.jimmy.access = "teamAI1"
	self.jimmy.dodge = presets.dodge.athletic_bot
	self.jimmy.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_sydney(presets)
	self.sydney = {}
	self.sydney.always_face_enemy = true
	self.sydney.no_run_start = true
	self.sydney.no_run_stop = true
	self.sydney.melee_weapon = "wing"
	self.sydney.damage = presets.gang_member_damage
	self.sydney.weapon = deep_clone(presets.weapon.gang_member)
	self.sydney.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.sydney.primaries,
		secondary = self.char_wep_tables.sydney.secondaries
	}
	self.sydney.detection = presets.detection.gang_member
	self.sydney.move_speed = presets.move_speed.very_fast_teamai
	self.sydney.crouch_move = false
	self.sydney.speech_prefix = "rb15"
	self.sydney.weapon_voice = "3"
	self.sydney.access = "teamAI1"
	self.sydney.dodge = presets.dodge.athletic_bot
	self.sydney.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_wild(presets)
	self.wild = {}
	self.wild.always_face_enemy = true
	self.wild.no_run_start = true
	self.wild.no_run_stop = true
	self.wild.melee_weapon = "road"
	self.wild.damage = presets.gang_member_damage
	self.wild.weapon = deep_clone(presets.weapon.gang_member)
	self.wild.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.rust.primaries,
		secondary = self.char_wep_tables.rust.secondaries
	}
	self.wild.detection = presets.detection.gang_member
	self.wild.move_speed = presets.move_speed.very_fast_teamai
	self.wild.crouch_move = false
	self.wild.speech_prefix = "rb16"
	self.wild.weapon_voice = "3"
	self.wild.access = "teamAI1"
	self.wild.dodge = presets.dodge.athletic_bot
	self.wild.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_chico(presets)
	self.chico = {}
	self.chico.always_face_enemy = true
	self.chico.no_run_start = true
	self.chico.no_run_stop = true
	self.chico.melee_weapon = "brick"
	self.chico.damage = presets.gang_member_damage
	self.chico.weapon = deep_clone(presets.weapon.gang_member)
	self.chico.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.tony.primaries,
		secondary = self.char_wep_tables.tony.secondaries
	}
	self.chico.detection = presets.detection.gang_member
	self.chico.move_speed = presets.move_speed.very_fast_teamai
	self.chico.crouch_move = false
	self.chico.speech_prefix = "rb17"
	self.chico.weapon_voice = "3"
	self.chico.access = "teamAI1"
	self.chico.dodge = presets.dodge.athletic_bot
	self.chico.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_max(presets)
	self.max = {}
	self.max.always_face_enemy = true
	self.max.no_run_start = true
	self.max.no_run_stop = true
	self.max.melee_weapon = "agave"
	self.max.damage = presets.gang_member_damage
	self.max.weapon = deep_clone(presets.weapon.gang_member)
	self.max.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.sangres.primaries,
		secondary = self.char_wep_tables.sangres.secondaries
	}
	self.max.detection = presets.detection.gang_member
	self.max.move_speed = presets.move_speed.very_fast_teamai
	self.max.crouch_move = false
	self.max.speech_prefix = "rb18"
	self.max.weapon_voice = "3"
	self.max.access = "teamAI1"
	self.max.dodge = presets.dodge.athletic_bot
	self.max.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_myh(presets)
	self.myh = {}
	self.myh.always_face_enemy = true
	self.myh.no_run_start = true
	self.myh.no_run_stop = true
	self.myh.flammable = false
	self.myh.melee_weapon = "sap"
	self.myh.damage = presets.gang_member_damage
	self.myh.weapon = deep_clone(presets.weapon.gang_member)
	self.myh.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.duke.primaries,
		secondary = self.char_wep_tables.duke.secondaries
	}
	self.myh.detection = presets.detection.gang_member
	self.myh.move_speed = presets.move_speed.very_fast_teamai
	self.myh.crouch_move = false
	self.myh.speech_prefix = "rb2"
	self.myh.weapon_voice = "1"
	self.myh.access = "teamAI1"
	self.myh.dodge = presets.dodge.athletic_bot
	self.myh.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_ecp(presets)
	self.ecp_female = {
		damage = presets.gang_member_damage,
		weapon = deep_clone(presets.weapon.gang_member)
	}
	self.ecp_female.weapon.weapons_of_choice = {
		primary = "wpn_fps_ass_m4_npc",
		secondary = "wpn_fps_smg_mp5_npc"
	}
	self.ecp_female.always_face_enemy = true
	self.ecp_female.no_run_start = true
	self.ecp_female.no_run_stop = true
	self.ecp_female.flammable = false
	self.ecp_female.melee_weapon = "clean"
	self.ecp_female.detection = presets.detection.gang_member
	self.ecp_female.move_speed = presets.move_speed.very_fast_teamai
	self.ecp_female.crouch_move = false
	self.ecp_female.speech_prefix = "rb21"
	self.ecp_female.weapon_voice = "3"
	self.ecp_female.access = "teamAI1"
	self.ecp_female.dodge = presets.dodge.athletic_bot
	self.ecp_female.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
	self.ecp_male = {
		damage = presets.gang_member_damage,
		weapon = deep_clone(presets.weapon.gang_member)
	}
	self.ecp_male.weapon.weapons_of_choice = {
		primary = "wpn_fps_ass_m4_npc",
		secondary = "wpn_fps_smg_mp5_npc"
	}
	self.ecp_male.always_face_enemy = true
	self.ecp_male.no_run_start = true
	self.ecp_male.no_run_stop = true
	self.ecp_male.flammable = false
	self.ecp_male.melee_weapon = "clean"
	self.ecp_male.detection = presets.detection.gang_member
	self.ecp_male.move_speed = presets.move_speed.very_fast_teamai
	self.ecp_male.crouch_move = false
	self.ecp_male.speech_prefix = "rb20"
	self.ecp_male.weapon_voice = "3"
	self.ecp_male.access = "teamAI1"
	self.ecp_male.dodge = presets.dodge.athletic_bot
	self.ecp_male.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_init_joy(presets)
	self.joy = {
		damage = presets.gang_member_damage,
		weapon = deep_clone(presets.weapon.gang_member)
	}
	self.joy.weapon.weapons_of_choice = {
		primary = self.char_wep_tables.joy.primaries,
		secondary = self.char_wep_tables.joy.secondaries
	}
	self.joy.always_face_enemy = true
	self.joy.no_run_start = true
	self.joy.no_run_stop = true
	self.joy.flammable = false
	self.joy.detection = presets.detection.gang_member
	self.joy.move_speed = presets.move_speed.very_fast_teamai
	self.joy.crouch_move = false
	self.joy.speech_prefix = "rb19"
	self.joy.weapon_voice = "3"
	self.joy.access = "teamAI1"
	self.joy.dodge = presets.dodge.athletic_bot
	self.joy.arrest = {
		timeout = 240,
		aggression_timeout = 6,
		arrest_timeout = 240
	}
end

function CharacterTweakData:_presets(tweak_data)
	local presets = {}
	presets.enemy_chatter = {
		no_chatter = {},
		guard = {
			aggressive = true,
			contact = true,
			clear = true,
			clear_whisper = true,
			clear_whisper_2 = true,
			reload = true,
			look_for_angle = true,
			ecm = true,
			saw = true,
			trip_mines = true,
			sentry = true,
			suppress = true
		},
		cop = {
			entry = true,
			aggressive = true,
			enemyidlepanic = true,
			controlpanic = true,
			dodge = true,
			cuffed = true,
			incomming_captain = true,
			incomming_gren = true,
			incomming_tank = true,
			incomming_spooc = true,
			incomming_shield = true,
			incomming_taser = true,
			entry = true,
			aggressive_assault = true,
			retreat = true,
			contact = true,
			clear = true,
			clear_whisper = true,
			go_go = true,
			push = true,
			reload = true,
			look_for_angle = true,
			ecm = true,
			saw = true,
			trip_mines = true,
			sentry = true,
			ready = true,
			smoke = true,
			flash_grenade = true,
			follow_me = true,
			deathguard = true,
			open_fire = true,
			suppress = true
		},
		swat = {
			entry = true,
			aggressive = true,
			enemyidlepanic = true,
			controlpanic = true,
			dodge = true,
			cuffed = true,
			incomming_captain = true,
			incomming_gren = true,
			incomming_tank = true,
			incomming_spooc = true,
			incomming_shield = true,
			incomming_taser = true,
			entry = true,
			aggressive_assault = true,
			retreat = true,
			contact = true,
			clear = true,
			clear_whisper = true,
			go_go = true,
			push = true,
			reload = true,
			look_for_angle = true,
			ecm = true,
			saw = true,
			trip_mines = true,
			sentry = true,
			ready = true,
			smoke = true,
			flash_grenade = true,
			follow_me = true,
			deathguard = true,
			open_fire = true,
			suppress = true
		},
		omnia_lpf = {
			aggressive = true,
			retreat = true,
			contact = true,
			clear = true,
			clear_whisper = true,
			heal_chatter = true,
			go_go = true,
			push = true,
			reload = true,
			look_for_angle = true,
			ecm = true,
			saw = true,
			trip_mines = true,
			sentry = true,
			ready = true,
			smoke = true,
			flash_grenade = true,
			follow_me = true,
			suppress = true
		},
		summers = {
			aggressive = true,
			retreat = true,
			contact = true,
			clear = true,
			clear_whisper = true,
			go_go = true,
			push = true,
			reload = true,
			look_for_angle = true,
			ecm = true,
			saw = true,
			trip_mines = true,
			sentry = true,
			ready = true,
			smoke = true,
			flash_grenade = true,
			follow_me = true,
			suppress = true
		},
		shield = {
			entry = true,
			aggressive = true,
			enemyidlepanic = true,
			controlpanic = true,
			dodge = true,
			cuffed = true,
			incomming_captain = true,
			incomming_gren = true,
			incomming_tank = true,
			incomming_spooc = true,
			incomming_taser = true,
			entry = true,
			aggressive_assault = true,
			retreat = true,
			contact = true,
			clear = true,
			clear_whisper = true,
			go_go = true,
			push = true,
			reload = true,
			look_for_angle = true,
			ecm = true,
			saw = true,
			trip_mines = true,
			sentry = true,
			ready = true,
			smoke = true,
			flash_grenade = true,
			follow_me = true,
			deathguard = true,
			open_fire = true,
			suppress = true
		},
		cloaker = {
			contact = true,
			cloakercontact = true,
			cloakeravoidance = true,
			aggressive = true
		},
	}

	presets.hurt_severities = {}

	local NO_HURTS = {
		health_reference = 1,
		zones = {{none = 1}}
	}

	local RESIST_HURTS = {
		health_reference = 1,
		zones = {{light = 1}}
	}

	presets.hurt_severities.base = {
		bullet = {
			health_reference = "current",
			zones = {
				{
					health_limit = 0.25,
					none = 0.5,
					light = 0.4,
					moderate = 0.1
				},
				{
					health_limit = 0.5,
					light = 0.5,
					moderate = 0.3,
					heavy = 0.2
				},
				{
					health_limit = 0.75,
					moderate = 0.6,
					heavy = 0.4
				},
				{
					heavy = 1
				}
			}
		},
		explosion = {
			health_reference = "current",
			zones = {
				{
					health_limit = 0.2,
					none = 0.6,
					heavy = 0.4
				},
				{
					health_limit = 0.5,
					heavy = 0.6,
					explode = 0.4
				},
				{heavy = 0.2, explode = 0.8}
			}
		},
		melee = {
			health_reference = "current",
			zones = {
				{
					health_limit = 0.5,
					none = 1
				},
				{
					health_limit = 1,
					light = 1
				},
				{
					health_limit = 2,
					moderate = 1
				},
				{
					heavy = 1
				}
			}
		},
		fire = {
			health_reference = "current",
			zones = {
				{
					health_limit = 0.75,
					fire = 0.75,
					light = 0.25
				},
				{
					fire = 1
				}
			}
		},
		poison = {
			health_reference = "current",
			zones = {
				{
					health_limit = 0.75,
					poison = 0.25,
					none = 0.75
				},
				{
					poison = 1
				}
			}
		},
		bleed = NO_HURTS,
		tase = true
	}
	presets.hurt_severities.medic = deep_clone(presets.hurt_severities.base)
	presets.hurt_severities.medic.poison = NO_HURTS
	presets.hurt_severities.medic_summers = deep_clone(presets.hurt_severities.medic)
	presets.hurt_severities.medic_summers.melee = {
		health_reference = "current",
		resist_stack_multiplier = 0.85,
		resist_stacking = {
			moderate = 1,
			heavy = 1.5
		},
		zones = {
			{
				health_limit = 0.2,
				none = 1
			},
			{
				health_limit = 0.4,
				light = 1
			},
			{
				health_limit = 0.6,
				moderate = 1
			},
			{
				heavy = 1
			}
		}
	}
	presets.hurt_severities.medic_summers.tase = false

	presets.hurt_severities.summers = deep_clone(presets.hurt_severities.base)
	presets.hurt_severities.summers.fire = RESIST_HURTS
	presets.hurt_severities.summers.melee = presets.hurt_severities.medic_summers.melee
	presets.hurt_severities.summers.tase = false

	presets.hurt_severities.bravo = deep_clone(presets.hurt_severities.base)
	presets.hurt_severities.bravo.bullet = {
			health_reference = "current",
			zones = {
			{
				health_limit = 0.25,
				none = 0.8,
				light = 0.2
			},
			{
				health_limit = 0.5,
				none = 0.5,
				light = 0.4,
				moderate = 0.1
			},
			{
				health_limit = 0.75,
				light = 0.4,
				moderate = 0.4,
				heavy = 0.2
			},
			{
				moderate = 0.5,
				heavy = 0.5
			}
		}
	}
	presets.hurt_severities.bravo_lmg = deep_clone(presets.hurt_severities.bravo)
	presets.hurt_severities.bravo_lmg.explosion = RESIST_HURTS

	presets.hurt_severities.strong = deep_clone(presets.hurt_severities.bravo)
	presets.hurt_severities.strong.tase = false

	presets.hurt_severities.tank = {
		bullet = RESIST_HURTS,
		explosion = RESIST_HURTS,
		melee =  {
			health_reference = "current",
			resist_stack_multiplier = 0.75,
			resist_stacking = {
				moderate = 1,
				heavy = 1.5
			},
			zones = {
				{
					health_limit = 80 / 900,
					none = 1
				},
				{
					health_limit = 210 / 900,
					light = 1
				},
				{
					health_limit = 380 / 900,
					moderate = 1
				},
				{
					heavy = 1
				}
			}
		},
		fire = RESIST_HURTS,
		poison = NO_HURTS,
		bleed = NO_HURTS,
		tase = false
	}
	presets.hurt_severities.tank_titan = deep_clone(presets.hurt_severities.tank) --Also used for generic level bosses.
	presets.hurt_severities.tank_titan.melee = {
		health_reference = "current",
		resist_stack_multiplier = 0.75,
		resist_stacking = {
			moderate = 1,
			heavy = 1.5
		},
		zones = {
			{
				health_limit = 120 / 1440,
				none = 1
			},
			{
				health_limit = 266 / 1440,
				light = 1
			},
			{
				health_limit = 480 / 1440,
				moderate = 1
			},
			{
				heavy = 1
			}
		}
	}
	presets.hurt_severities.spring = deep_clone(presets.hurt_severities.tank)
	presets.hurt_severities.spring.melee = {
		health_reference = "current",
		resist_stack_multiplier = 0.75,
		resist_stacking = {
			moderate = 1,
			heavy = 1.5
		},
		zones = {
			{
				health_limit = 140 / 5400,
				none = 1
			},
			{
				health_limit = 570 / 5400,
				light = 1
			},
			{
				health_limit = 760 / 5400,
				moderate = 1
			},
			{
				heavy = 1
			}
		}
	}

	presets.hurt_severities.spooc = deep_clone(presets.hurt_severities.strong)
	presets.hurt_severities.spooc.bullet = {
		health_reference = "current",
		zones = {
			{
				health_limit = 0.33333,
				light = 0.3,
				moderate = 0.4,
				heavy = 0.3
			},
			{
				health_limit = 0.66667,
				light = 0.2,
				moderate = 0.2,
				heavy = 0.6
			},
			{
				light = 0,
				moderate = 0,
				heavy = 1
			}
		}
	}

	presets.hurt_severities.taser = deep_clone(presets.hurt_severities.base)
	presets.hurt_severities.taser.bullet = NO_HURTS
	presets.hurt_severities.taser_summers = deep_clone(presets.hurt_severities.taser)
	presets.hurt_severities.taser_summers.melee = presets.hurt_severities.medic_summers.melee
	presets.hurt_severities.taser_summers.tase = false

	presets.hurt_severities.boom = deep_clone(presets.hurt_severities.base)
	presets.hurt_severities.boom.explosion = RESIST_HURTS
	presets.hurt_severities.boom.fire = RESIST_HURTS
	presets.hurt_severities.boom_summers = deep_clone(presets.hurt_severities.boom)
	presets.hurt_severities.boom_summers.melee = presets.hurt_severities.medic_summers.melee
	presets.hurt_severities.boom_summers.tase = false

	presets.hurt_severities.autumn = deep_clone(presets.hurt_severities.base)
	presets.hurt_severities.autumn.fire = RESIST_HURTS
	presets.hurt_severities.autumn.bullet = RESIST_HURTS
	presets.hurt_severities.autumn.melee = {
		health_reference = "current",
		resist_stack_multiplier = 0.85,
		resist_stacking = {
			moderate = 1,
			heavy = 1.5
		},
		zones = {
			{
				health_limit = 60 / 1440,
				none = 1
			},
			{
				health_limit = 100 / 1440,
				light = 1
			},
			{
				health_limit = 150 / 1440,
				moderate = 1
			},
			{
				heavy = 1
			}
		}
	}
	presets.hurt_severities.autumn.tase = false

	--Used for shields and gang members.
	presets.hurt_severities.shield = {
		bullet = NO_HURTS,
		explosion = presets.hurt_severities.base.explosion,
		melee = NO_HURTS,
		fire = NO_HURTS,
		poison = NO_HURTS,
		bleed = NO_HURTS,
		tase = false
	}
	presets.hurt_severities.no_hurts = deep_clone(presets.hurt_severities.shield)
	presets.hurt_severities.no_hurts.explosion = NO_HURTS

	presets.base = {}
	presets.base.HEALTH_INIT = 2
	presets.base.headshot_dmg_mul = normal_headshot
	presets.base.use_animation_on_fire_damage = true
	presets.base.SPEED_WALK = {
		ntl = 120,
		hos = 180,
		cbt = 160,
		pnc = 160
	}
	presets.base.SPEED_RUN = 370
	presets.base.chatter = presets.enemy_chatter.no_chatter
	presets.base.crouch_move = true
	presets.base.shooting_death = true
	presets.base.suspicious = true
	presets.base.surrender_break_time = {20, 30}
	presets.base.submission_max = {45, 60}
	presets.base.submission_intimidate = 15
	presets.base.speech_prefix = "po"
	presets.base.speech_prefix_count = 1
	presets.base.follower = false
	presets.base.rescue_hostages = false
	presets.base.use_radio = self._default_chatter
	presets.base.dodge = nil
	presets.base.challenges = {type = "law"}
	presets.base.calls_in = true
	presets.base.ignore_medic_revive_animation = false
	presets.base.spotlight_important = false
	presets.base.experience = {}
	presets.base.experience.cable_tie = "tie_swat"
	presets.base.damage = {}
	presets.base.damage.hurt_severity = presets.hurt_severities.base
	presets.base.damage.death_severity = 0.5
	presets.base.damage.explosion_damage_mul = 1
	presets.base.damage.tased_response = {
		light = {tased_time = 5, down_time = 5},
		heavy = {tased_time = 5, down_time = 10}
	}
	presets.gang_member_damage = {}
	presets.gang_member_damage.HEALTH_INIT = 120
	presets.gang_member_damage.no_run_start = true
	presets.gang_member_damage.no_run_stop = true
	presets.gang_member_damage.headshot_dmg_mul = normal_headshot
	presets.gang_member_damage.LIVES_INIT = 4
	presets.gang_member_damage.explosion_damage_mul = 0
	presets.gang_member_damage.REGENERATE_TIME = 5
	presets.gang_member_damage.REGENERATE_TIME_AWAY = 2.5
	presets.gang_member_damage.DOWNED_TIME = tweak_data.player.damage.DOWNED_TIME
	presets.gang_member_damage.TASED_TIME = tweak_data.player.damage.TASED_TIME
	presets.gang_member_damage.BLEED_OUT_HEALTH_INIT = 40
	presets.gang_member_damage.ARRESTED_TIME = 30
	presets.gang_member_damage.INCAPACITATED_TIME = tweak_data.player.damage.INCAPACITATED_TIME
	presets.gang_member_damage.hurt_severity = presets.hurt_severities.no_hurts
	presets.gang_member_damage.MIN_DAMAGE_INTERVAL = 0.6
	presets.gang_member_damage.respawn_time_penalty = 0
	presets.gang_member_damage.base_respawn_time_penalty = 5
	presets.weapon = {}

	presets.weapon.expert = {}

	--Has quick response in close range, and extremely consistent long range plinking. Generally mediocre and flatish damage to compensate.
	presets.weapon.expert.is_pistol = {
		aim_delay = {0.1, 0.4}, --Delay to acquire target. Scales based on range vs max falloff range.
		focus_delay = 3, --Delay to reach max accuracy and recoil control from when shooting starts.
		focus_dis = 500,
		spread = 8,
		miss_dis = 16, --Distance to offset vector on missed shots.
		RELOAD_SPEED = 1.25,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		range = {
			close = 900, --Should be ~half optimal range.
			optimal = 1800, --Should generally match range where damage falloff kicks in.
			far = 5400 --Should generally match 150% of range where damage falloff kicks in.
		},
		FALLOFF = {
			{
				r = 200,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {0.3, 0.3},
				burst_size = 3
			},
			{
				r = 450,
				acc = {0.4, 0.7},
				dmg_mul = 1,
				recoil = {0.3, 0.3},
				burst_size = 3
			},
			{
				r = 900,
				acc = {0.4, 0.7},
				dmg_mul = 1,
				recoil = {0.4, 0.4},
				burst_size = 3
			},
			{
				r = 901,
				acc = {0.4, 0.7},
				dmg_mul = 1,
				recoil = {0.4, 0.4},
				burst_size = 1
			},
			{
				r = 1800,
				acc = {0.3, 0.6},
				dmg_mul = 1,
				recoil = {0.6, 0.6},
				burst_size = 1
			},
			{
				r = 3600,
				acc = {0.25, 0.5},
				dmg_mul = 0.5,
				recoil = {0.9, 0.9},
				burst_size = 1
			},
			{
				r = 5400,
				acc = {0, 0},
				dmg_mul = 0.0,
				recoil = {1.8, 1.8},
				burst_size = 1
			}
		}
	}

	--Keeps the Pistol's close range responsiveness, but loses the long range plinking via terrible ranged aim delay, and more aggressive falloff.
	--Doubled ROF but reduced accuracy at range, because akimbo.
	presets.weapon.expert.is_akimbo_pistol = {
		aim_delay = {0.1, 0.6},
		focus_delay = 3,
		focus_dis = 500,
		spread = 10,
		miss_dis = 20,
		RELOAD_SPEED = 1,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		range = {
			close = 750,
			optimal = 1500,
			far = 4500
		},
		FALLOFF = {
			{
				r = 200,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {0.15, 0.15},
				burst_size = 4
			},
			{
				r = 325,
				acc = {0.3, 0.6},
				dmg_mul = 1,
				recoil = {0.15, 0.15},
				burst_size = 4
			},
			{
				r = 750,
				acc = {0.275, 0.5},
				dmg_mul = 1,
				recoil = {0.2, 0.2},
				burst_size = 4
			},
			{
				r = 751,
				acc = {0.275, 0.5},
				dmg_mul = 1,
				recoil = {0.2, 0.2},
				burst_size = 1
			},
			{
				r = 1500,
				acc = {0.25, 0.4},
				dmg_mul = 1,
				recoil = {0.3, 0.3},
				burst_size = 1
			},
			{
				r = 3000,
				acc = {0.25, 0.4},
				dmg_mul = 0.5,
				recoil = {0.45, 0.45},
				burst_size = 1
			},
			{
				r = 4500,
				acc = {0, 0},
				dmg_mul = 0.0,
				recoil = {0.9, 0.9},
				burst_size = 1
			}
		}
	}

	--Quick to react. Big damage, but fairly inaccurate.
	presets.weapon.expert.is_revolver = {
		aim_delay = {0.4, 0.8},
		focus_delay = 3,
		focus_dis = 500,
		spread = 6,
		miss_dis = 24,
		RELOAD_SPEED = 1,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		range = {
			close = 900,
			optimal = 1800,
			far = 5400
		},
		FALLOFF = {
			{
				r = 200,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {0.5, 0.5},
				burst_size = 1
			},
			{
				r = 450,
				acc = {0.3, 0.6},
				dmg_mul = 1,
				recoil = {0.8, 0.6},
				burst_size = 1
			},
			{
				r = 900,
				acc = {0.25, 0.5},
				dmg_mul = 1,
				recoil = {1.0, 0.8},
				burst_size = 1
			},
			{
				r = 1800,
				acc = {0.2, 0.4},
				dmg_mul = 1,
				recoil = {1.5, 1.2},
				burst_size = 1
			},
			{
				r = 3600,
				acc = {0.2, 0.4},
				dmg_mul = 0.5,
				recoil = {1.5, 1.5},
				burst_size = 1
			},
			{
				r = 5400,
				acc = {0, 0},
				dmg_mul = 0.0,
				recoil = {1.8, 1.8},
				burst_size = 1
			}
		}
	}

	--Pretty average all-round. Threatening at any range, but not quite as much as more specialized guns.
	presets.weapon.expert.is_rifle = {
		aim_delay = {0.3, 1.5},
		focus_delay = 6,
		focus_dis = 300,
		spread = 10,
		miss_dis = 20,
		RELOAD_SPEED = 0.75,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		range = {
			close = 1125,
			optimal = 2250,
			far = 6750
		},
		FALLOFF = {
			{
				r = 200,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {0.6, 0.6},
				burst_size = 30
			},
			{
				r = 600,
				acc = {0.25, 0.55},
				dmg_mul = 1,
				recoil = {0.6, 0.6},
				burst_size = 30
			},
			{
				r = 601,
				acc = {0.3, 0.7},
				dmg_mul = 1,
				recoil = {0.3, 0.3},
				burst_size = 3
			},
			{
				r = 1125,
				acc = {0.3, 0.7},
				dmg_mul = 1,
				recoil = {0.8, 0.4},
				burst_size = 3
			},
			{
				r = 2250,
				acc = {0.3, 0.7},
				dmg_mul = 1,
				recoil = {0.8, 0.4},
				burst_size = 3
			},
			{
				r = 4500,
				acc = {0.15, 0.35},
				dmg_mul = 0.5,
				recoil = {0.8, 0.4},
				burst_size = 2
			},
			{
				r = 6750,
				acc = {0, 0},
				dmg_mul = 0.0,
				recoil = {0.9, 0.6},
				burst_size = 1
			}
		}
	}

	--Long range burst, takes a while to become accurate enough to hit perfectly consistently, with the time it takes varying based on range.
	--Abuses acc values > 1 to achieve this.
	presets.weapon.expert.is_dmr = {
		aim_delay = {0.4, 2.0},
		focus_delay = 6,
		focus_dis = 150,
		spread = 10,
		miss_dis = 20,
		RELOAD_SPEED = 0.75,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		range = {
			close = 1500,
			optimal = 3000,
			far = 9000
		},
		FALLOFF = {
			{
				r = 200,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {0.8, 0.4},
				burst_size = 1
			},
			{
				r = 750,
				acc = {0.0, 6.0}, --1 second to max acc.
				dmg_mul = 1,
				recoil = {1.2, 0.6},
				burst_size = 1
			},
			{
				r = 1500,
				acc = {0.0, 4.0}, --1.5 seconds to max acc.
				dmg_mul = 1,
				recoil = {1.6, 0.8},
				burst_size = 1
			},
			{
				r = 3000,
				acc = {0.0, 3.0}, --2 seconds to max acc.
				dmg_mul = 1,
				recoil = {1.6, 0.8},
				burst_size = 1
			},
			{
				r = 6000,
				acc = {0.0, 2.0}, --3 seconds to max acc.
				dmg_mul = 0.5,
				recoil = {1.6, 0.8},
				burst_size = 1
			},
			{
				r = 9000,
				acc = {0, 0},
				dmg_mul = 0.0,
				recoil = {1.8, 1.2},
				burst_size = 1
			}
		}
	}

	--Similar to ARs, but with more threat up close and less from far away.
	presets.weapon.expert.is_smg = {
		aim_delay = {0.2, 1.2},
		focus_delay = 6,
		focus_dis = 400,
		spread = 14,
		miss_dis = 28,
		RELOAD_SPEED = 1,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		range = {
			close = 900,
			optimal = 1800,
			far = 5400
		},
		FALLOFF = {
			{
				r = 200,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {0.3, 0.3},
				burst_size = 30
			},
			{
				r = 450,
				acc = {0.3, 0.9},
				dmg_mul = 1,
				recoil = {0.4, 0.3},
				burst_size = 10
			},
			{
				r = 900,
				acc = {0.25, 0.75},
				dmg_mul = 1,
				recoil = {0.4, 0.3},
				burst_size = 10
			},
			{
				r = 1800,
				acc = {0.2, 0.6},
				dmg_mul = 1,
				recoil = {0.6, 0.4},
				burst_size = 5
			},
			{
				r = 3600,
				acc = {0.1, 0.3},
				dmg_mul = 0.5,
				recoil = {0.9, 0.6},
				burst_size = 3
			},
			{
				r = 5400,
				acc = {0, 0},
				dmg_mul = 0.0,
				recoil = {0.6, 0.3},
				burst_size = 1
			}
		}
	}

	--Focus on suppressing player with high volume+damage inaccurate fire. Players that remain in it too long will get torn apart if the focus_delay is left to tick down.
	presets.weapon.expert.is_lmg = {
		aim_delay = {0.4, 2.0},
		focus_delay = 12,
		focus_dis = 150,
		spread = 16,
		miss_dis = 48,
		RELOAD_SPEED = 0.5,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		range = {
			close = 1125,
			optimal = 2250,
			far = 6750
		},
		FALLOFF = {
			{
				r = 200,
				acc = {0.75, 1.0},
				dmg_mul = 1,
				recoil = {0.4, 0.4},
				burst_size = 30
			},
			{
				r = 600,
				acc = {0.2, 0.7},
				dmg_mul = 1,
				recoil = {0.4, 0.4},
				burst_size = 30
			},
			{
				r = 1125,
				acc = {0.15, 0.6},
				dmg_mul = 1,
				recoil = {0.4, 0.4},
				burst_size = 15
			},
			{
				r = 2250,
				acc = {0.1, 0.5},
				dmg_mul = 1,
				recoil = {0.6, 0.4},
				burst_size = 12
			},
			{
				r = 4500,
				acc = {0.0, 0.4},
				dmg_mul = 0.5,
				recoil = {0.6, 0.4},
				burst_size = 9
			},
			{
				r = 6750,
				acc = {0, 0},
				dmg_mul = 0,
				recoil = {0.9, 0.6},
				burst_size = 6
			}
		}
	}

	--LMG but with more close range grunt and even more extreme stats.
	presets.weapon.expert.is_mini = {
		aim_delay = {0.6, 1.8},
		focus_delay = 12,
		focus_dis = 150,
		spread = 20,
		miss_dis = 48,
		RELOAD_SPEED = 0.5,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		range = {
			close = 1125,
			optimal = 2250,
			far = 6750
		},
		FALLOFF = {
			{
				r = 200,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {1.0, 1.0},
				burst_size = 300
			},
			{
				r = 600,
				acc = {0.5, 1.0},
				dmg_mul = 1,
				recoil = {1.0, 1.0},
				burst_size = 300
			},
			{
				r = 1125,
				acc = {0.0, 0.5},
				dmg_mul = 1,
				recoil = {1.0, 1.0},
				burst_size = 150
			},
			{
				r = 2250,
				acc = {0.0, 0.25},
				dmg_mul = 1,
				recoil = {1.0, 1.0},
				burst_size = 100
			},
			{
				r = 4500,
				acc = {0.0, 0.125},
				dmg_mul = 0.5,
				recoil = {1.0, 1.0},
				burst_size = 75
			},
			{
				r = 6750,
				acc = {0, 0},
				dmg_mul = 0,
				recoil = {1.0, 1.0},
				burst_size = 50
			}
		}
	}

	--Close range burst. Takes a moment to react, but is highly consistent once it does. First shot is usually a warning shot.
	presets.weapon.expert.is_shotgun_pump = {
		aim_delay = {0.2, 0.3},
		focus_delay = 1.5,
		focus_dis = 100,
		spread = 20,
		miss_dis = 20,
		RELOAD_SPEED = 0.4,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		range = {
			close = 400,
			optimal = 800,
			far = 2400
		},
		FALLOFF = {
			{
				r = 400,
				acc = {0.6, 1.0},
				dmg_mul = 1,
				recoil = {0.8, 0.8},
				burst_size = 1
			},
			{
				r = 800,
				acc = {0.0, 1.0},
				dmg_mul = 1,
				recoil = {0.8, 0.8},
				burst_size = 1
			},
			{
				r = 1600,
				acc = {0.0, 0.6},
				dmg_mul = 0.5,
				recoil = {1.4, 0.8},
				burst_size = 1
			},
			{
				r = 2400,
				acc = {0, 0},
				dmg_mul = 0.0,
				recoil = {2, 1},
				burst_size = 1
			}
		}
	}

	--Close range murder if left unchecked. Somewhat inconsistent.
	presets.weapon.expert.is_shotgun_mag = {
		aim_delay = {0.3, 0.4},
		focus_delay = 6,
		focus_dis = 100,
		spread = 20,
		miss_dis = 20,
		RELOAD_SPEED = 0.6,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		range = {
			close = 350,
			optimal = 700,
			far = 2100
		},
		FALLOFF = {
			{
				r = 400,
				acc = {0.6, 1.0},
				dmg_mul = 1,
				recoil = {0.3, 0.3},
				burst_size = 6
			},
			{
				r = 700,
				acc = {0.4, 0.6},
				dmg_mul = 1,
				recoil = {0.5, 0.4},
				burst_size = 4
			},
			{
				r = 1400,
				acc = {0.2, 0.4},
				dmg_mul = 0.5,
				recoil = {1.0, 0.5},
				burst_size = 2
			},
			{
				r = 2100,
				acc = {0, 0},
				dmg_mul = 0,
				recoil = {1.5, 1.0},
				burst_size = 1
			}
		}
	}

	--Murder at <14m. Useless beyond that. Similar to autoshotgun beyond that.
	presets.weapon.expert.is_flamethrower = {
		aim_delay = {0.7, 0.9},
		focus_delay = 1,
		focus_dis = 200,
		spread = 20,
		miss_dis = 20,
		RELOAD_SPEED = 0.4,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		range = {
			close = 700,
			optimal = 1000,
			far = 1500
		},
		FALLOFF = {
			{
				r = 700,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {1, 1},
				burst_size = 100
			},
			{
				r = 1400,
				acc = {1.0, 1.0},
				dmg_mul = 0.4,
				recoil = {1, 1},
				burst_size = 100
			},
			{
				r = 1401,
				acc = {0, 0},
				dmg_mul = 0,
				recoil = {1, 1},
				burst_size = 100
			}
		}
	}

	presets.weapon.good = deep_clone(presets.weapon.expert) --Good presets typically lose reload speed and some reaction speed. But have similar peak perf to expert.
	--preset, accuracy_mul, aim_delay_mul, focus_delay_mul, recoil_mul, reload_speed_mul
	self:_multiply_weapon_preset(presets.weapon.good.is_pistol,        1.00, 1.20, 1.20, 1.00, 0.90)
	self:_multiply_weapon_preset(presets.weapon.good.is_akimbo_pistol, 1.00, 1.15, 1.15, 1.00, 0.80)
	self:_multiply_weapon_preset(presets.weapon.good.is_revolver,      1.00, 1.00, 1.30, 1.00, 0.80)
	self:_multiply_weapon_preset(presets.weapon.good.is_rifle,         1.00, 1.10, 1.30, 1.00, 0.90)
	self:_multiply_weapon_preset(presets.weapon.good.is_dmr,           1.00, 1.00, 1.40, 1.00, 0.90)
	self:_multiply_weapon_preset(presets.weapon.good.is_smg,           1.00, 1.15, 1.20, 1.00, 0.85)
	self:_multiply_weapon_preset(presets.weapon.good.is_lmg,           1.00, 1.10, 1.30, 1.00, 0.80)
	--Minigun retains expert stats
	self:_multiply_weapon_preset(presets.weapon.good.is_shotgun_pump,  1.00, 1.40, 1.00, 1.00, 0.8)
	self:_multiply_weapon_preset(presets.weapon.good.is_shotgun_mag,   1.00, 1.30, 1.10, 1.00, 0.8)
	--Flamethrower retains expert stats

	presets.weapon.normal = deep_clone(presets.weapon.expert) --Normal presets also lose out on effective damage output via longer recoil and/or worse accuracy.
	self:_multiply_weapon_preset(presets.weapon.normal.is_pistol,        1.00, 1.20, 1.20, 1.50, 0.90)
	self:_multiply_weapon_preset(presets.weapon.normal.is_akimbo_pistol, 1.00, 1.15, 1.15, 1.50, 0.80)
	self:_multiply_weapon_preset(presets.weapon.normal.is_revolver,      1.00, 1.00, 1.30, 1.50, 0.80)
	self:_multiply_weapon_preset(presets.weapon.normal.is_rifle,         0.80, 1.10, 1.30, 1.30, 0.90)
	self:_multiply_weapon_preset(presets.weapon.normal.is_dmr,           0.80, 1.00, 1.40, 1.30, 0.90)
	self:_multiply_weapon_preset(presets.weapon.normal.is_smg,           0.70, 1.15, 1.20, 1.20, 0.85)
	self:_multiply_weapon_preset(presets.weapon.normal.is_lmg,           0.90, 1.10, 1.30, 1.40, 0.80)
	--Minigun retains expert stats
	self:_multiply_weapon_preset(presets.weapon.normal.is_shotgun_pump,  1.00, 1.40, 1.00, 1.50, 0.8)
	self:_multiply_weapon_preset(presets.weapon.normal.is_shotgun_mag,   0.70, 1.30, 1.10, 1.20, 0.8)
	--Flamethrower retains expert stats

	presets.weapon.shield = deep_clone(presets.weapon.normal) --Normal, but with no melee attacks.
	for preset_name, preset in pairs(presets.weapon.shield) do
		preset.melee_dmg = nil
		preset.melee_speed = nil
		preset.melee_retry_delay = nil
	end

	presets.weapon.taser = {}
	presets.weapon.taser.is_rifle = deep_clone(presets.weapon.good.is_rifle)
	presets.weapon.taser.is_rifle.tase_distance = 1400
	presets.weapon.taser.is_rifle.aim_delay_tase = {0.75, 0.75}
	presets.weapon.taser.is_rifle.tase_sphere_cast_radius = 10
	presets.weapon.taser.is_rifle.tase_charge_duration = 1

	presets.weapon.taser_summers = {}
	presets.weapon.taser_summers.is_rifle = deep_clone(presets.weapon.expert.is_rifle)
	presets.weapon.taser_summers.is_rifle.tase_distance = 1400
	presets.weapon.taser_summers.is_rifle.aim_delay_tase = {0.75, 0.75}
	presets.weapon.taser_summers.is_rifle.tase_sphere_cast_radius = 10

	presets.weapon.dozer = deep_clone(presets.weapon.good) --Good, but with slow melee attacks.
	for preset_name, preset in pairs(presets.weapon.dozer) do
		preset.melee_speed = 0.6667
		preset.melee_retry_delay = {3, 3}
	end

	presets.weapon.gangster = deep_clone(presets.weapon.normal) --Normal but with 1.5x damage.
	presets.weapon.meme_man = deep_clone(presets.weapon.expert) --Idk yet, gotta think of something dumb.
	presets.weapon.deathwish = deep_clone(presets.weapon.expert) --Unused, needed to prevent crash.

	--Will hit every 2.5 seconds after a 3 second wait time.
	presets.weapon.sniper = {}
	presets.weapon.sniper.is_rifle = {
		aim_delay = {3, 3},
		focus_delay = 3,
		focus_dis = 0,
		spread = 0,
		miss_dis = 20,
		RELOAD_SPEED = 1,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		use_laser = true,
		sniper_charge_attack = true,
		range = {
			close = 3000,
			optimal = 6000,
			far = 9000
		},
		FALLOFF = {
			{
				r = 3000,
				acc = {1, 1},
				dmg_mul = 1,
				recoil = {2.55, 2.55},
				burst_size = 1
			},
			{
				r = 6000,
				acc = {1, 1},
				dmg_mul = 0.9,
				recoil = {2.55, 2.55},
				burst_size = 1
			},
			{
				r = 9000,
				acc = {1, 1},
				dmg_mul = 0.8,
				recoil = {2.55, 2.55},
				burst_size = 1
			},
			{
				r = 18000,
				acc = {1, 1},
				dmg_mul = 0.7,
				recoil = {2.55, 2.55},
				burst_size = 1
			},
		}
	}

	--Bot weapon presets
	presets.weapon.gang_member = deep_clone(presets.weapon.expert)

	presets.weapon.gang_member.is_pistol = {
		aim_delay = {0.3, 0.9},
		focus_delay = 2,
		focus_dis = 600,
		spread = 6,
		miss_dis = 12,
		RELOAD_SPEED = 1.5,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		crew = true,
		range = {
			close = 1125,
			optimal = 2250,
			far = 6750
		},
		FALLOFF = {
			{ --200 dps.
				r = 300,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {0.3, 0.3},
				burst_size = 1
			},
			{ --80/160 dps
				r = 600,
				acc = {0.5, 1.0},
				dmg_mul = 1,
				recoil = {0.3, 0.3},
				burst_size = 1
			},
			{ --60/120 dps
				r = 1125,
				acc = {0.4, 0.8},
				dmg_mul = 1,
				recoil = {0.3, 0.3},
				burst_size = 1
			},
			{ --40/80 dps
				r = 2250,
				acc = {0.4, 0.8},
				dmg_mul = 1,
				recoil = {0.45, 0.45},
				burst_size = 1
			},
			{ --10/20 dps
				r = 4500,
				acc = {0.3, 0.6},
				dmg_mul = 0.5,
				recoil = {0.9, 0.9},
				burst_size = 1
			},
			{
				r = 6750,
				acc = {0, 0},
				dmg_mul = 0.0,
				recoil = {1.8, 1.8},
				burst_size = 1
			}
		}
	}

	presets.weapon.gang_member.is_revolver = {
		aim_delay = {0.3, 0.9},
		focus_delay = 2,
		focus_dis = 600,
		spread = 6,
		miss_dis = 12,
		RELOAD_SPEED = 0.4,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		crew = true,
		range = {
			close = 1125,
			optimal = 2250,
			far = 6750
		},
		FALLOFF = {
			{ --200 dps.
				r = 300,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {0.5, 0.5},
				burst_size = 1
			},
			{ --80/160 dps
				r = 600,
				acc = {0.5, 1.0},
				dmg_mul = 1,
				recoil = {0.5, 0.5},
				burst_size = 1
			},
			{ --60/120 dps
				r = 1125,
				acc = {0.4, 0.8},
				dmg_mul = 1,
				recoil = {0.5, 0.5},
				burst_size = 1
			},
			{ --40/80 dps
				r = 2250,
				acc = {0.4, 0.8},
				dmg_mul = 1,
				recoil = {0.75, 0.75},
				burst_size = 1
			},
			{ --10/20 dps
				r = 4500,
				acc = {0.3, 0.6},
				dmg_mul = 0.5,
				recoil = {1.5, 1.5},
				burst_size = 1
			},
			{
				r = 6750,
				acc = {0, 0},
				dmg_mul = 0.0,
				recoil = {1.8, 1.8},
				burst_size = 1
			}
		}
	}

	presets.weapon.gang_member.is_rifle = {
		aim_delay = {0.6, 1.8},
		focus_delay = 4,
		focus_dis = 450,
		spread = 8,
		miss_dis = 16,
		RELOAD_SPEED = 1,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		crew = true,
		range = {
			close = 1400,
			optimal = 2800,
			far = 8400
		},
		FALLOFF = {
			{
				r = 350,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {0.6, 0.6},
				burst_size = 30
			},
			{
				r = 700,
				acc = {0.176, 0.528},
				dmg_mul = 1,
				recoil = {0.6, 0.6},
				burst_size = 30
			},
			{
				r = 701,
				acc = {0.225, 0.675},
				dmg_mul = 1,
				recoil = {0.3, 0.3},
				burst_size = 3
			},
			{
				r = 1400,
				acc = {0.2, 0.6},
				dmg_mul = 1,
				recoil = {0.3, 0.3},
				burst_size = 3
			},
			{
				r = 2800,
				acc = {0.15, 0.45},
				dmg_mul = 1,
				recoil = {0.45, 0.45},
				burst_size = 3
			},
			{
				r = 5600,
				acc = {0.1, 0.3},
				dmg_mul = 0.5,
				recoil = {0.6, 0.6},
				burst_size = 2
			},
			{
				r = 8400,
				acc = {0, 0},
				dmg_mul = 0.0,
				recoil = {1.2, 1.2},
				burst_size = 1
			}
		}
	}

	presets.weapon.gang_member.is_rifle_underbarrel = {
		aim_delay = {0.6, 1.8},
		focus_delay = 4,
		focus_dis = 450,
		spread = 8,
		miss_dis = 16,
		RELOAD_SPEED = 1,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		grenade = gang_member_launcher_frag,
		crew = true,
		range = {
			close = 1400,
			optimal = 2800,
			far = 8400
		},
		FALLOFF = {
			{
				r = 350,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {0.6, 0.6},
				burst_size = 3
			},
			{
				r = 700,
				acc = {0.201, 0.603},
				dmg_mul = 1,
				recoil = {0.6, 0.6},
				burst_size = 3
			},
			{
				r = 701,
				acc = {0.225, 0.675},
				dmg_mul = 1,
				recoil = {0.3, 0.3},
				burst_size = 2
			},
			{
				r = 1400,
				acc = {0.2, 0.6},
				dmg_mul = 1,
				recoil = {0.3, 0.3},
				burst_size = 2
			},
			{
				r = 2800,
				acc = {0.15, 0.45},
				dmg_mul = 1,
				recoil = {0.45, 0.45},
				burst_size = 2
			},
			{
				r = 5600,
				acc = {0.1, 0.3},
				dmg_mul = 0.5,
				recoil = {0.6, 0.6},
				burst_size = 2
			},
			{
				r = 8400,
				acc = {0, 0},
				dmg_mul = 0.0,
				recoil = {1.2, 1.2},
				burst_size = 1
			}
		}
	}

	presets.weapon.gang_member.is_smg = {
		aim_delay = {0.3, 0.9},
		focus_delay = 2,
		focus_dis = 600,
		spread = 10,
		miss_dis = 20,
		RELOAD_SPEED = 1.5,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		crew = true,
		range = {
			close = 1125,
			optimal = 2250,
			far = 6750
		},
		FALLOFF = {
			{
				r = 300,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {0.4, 0.4},
				burst_size = 20
			},
			{
				r = 600,
				acc = {0.35, 0.7},
				dmg_mul = 1,
				recoil = {0.4, 0.4},
				burst_size = 20
			},
			{
				r = 1125,
				acc = {0.3, 0.6},
				dmg_mul = 1,
				recoil = {0.4, 0.4},
				burst_size = 20
			},
			{
				r = 2250,
				acc = {0.14, 0.28},
				dmg_mul = 1,
				recoil = {0.4, 0.4},
				burst_size = 20
			},
			{
				r = 2251,
				acc = {0.19, 0.38},
				dmg_mul = 1,
				recoil = {0.3, 0.3},
				burst_size = 3
			},
			{
				r = 4500,
				acc = {0.1, 0.2},
				dmg_mul = 0.5,
				recoil = {0.6, 0.6},
				burst_size = 3
			},
			{
				r = 6750,
				acc = {0, 0},
				dmg_mul = 0.0,
				recoil = {1.8, 1.8},
				burst_size = 1
			}
		}
	}

	presets.weapon.gang_member.is_lmg = {
		aim_delay = {0.9, 2.7},
		focus_delay = 6,
		focus_dis = 300,
		spread = 12,
		miss_dis = 24,
		RELOAD_SPEED = 0.4,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		crew = true,
		range = {
			close = 1400,
			optimal = 2800,
			far = 8400
		},
		FALLOFF = {
			{
				r = 350,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {1.0, 1.0},
				burst_size = 90
			},
			{
				r = 700,
				acc = {0.2, 0.8},
				dmg_mul = 1,
				recoil = {1.0, 1.0},
				burst_size = 90
			},
			{
				r = 1400,
				acc = {0.15, 0.6},
				dmg_mul = 1,
				recoil = {1.0, 1.0},
				burst_size = 90
			},
			{
				r = 2800,
				acc = {0.06, 0.3},
				dmg_mul = 1,
				recoil = {1.0, 1.0},
				burst_size = 3
			},
			{
				r = 2801,
				acc = {0.1, 0.4},
				dmg_mul = 1,
				recoil = {0.3, 0.3},
				burst_size = 3
			},
			{
				r = 5600,
				acc = {0.05, 0.2},
				dmg_mul = 0.5,
				recoil = {0.6, 0.6},
				burst_size = 3
			},
			{
				r = 8400,
				acc = {0, 0},
				dmg_mul = 0.0,
				recoil = {1.2, 1.2},
				burst_size = 1
			}
		}
	}

	presets.weapon.gang_member.is_dmr = {
		aim_delay = {0.9, 2.7},
		focus_delay = 6,
		focus_dis = 300,
		spread = 4,
		miss_dis = 8,
		RELOAD_SPEED = 1,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		crew = true,
		range = {
			close = 1875,
			optimal = 3750,
			far = 11250
		},
		FALLOFF = {
			{
				r = 470,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {0.5, 0.5},
				burst_size = 1
			},
			{
				r = 940,
				acc = {0.25, 0.75},
				dmg_mul = 1,
				recoil = {0.5, 0.5},
				burst_size = 1
			},
			{
				r = 1875,
				acc = {0.25, 0.75},
				dmg_mul = 1,
				recoil = {0.75, 0.75},
				burst_size = 1
			},
			{
				r = 3750,
				acc = {0.2, 0.6},
				dmg_mul = 1,
				recoil = {1.0, 1.0},
				burst_size = 1
			},
			{
				r = 7500,
				acc = {0.15, 0.45},
				dmg_mul = 0.5,
				recoil = {1.5, 1.5},
				burst_size = 1
			},
			{
				r = 11250,
				acc = {0, 0},
				dmg_mul = 0.0,
				recoil = {1.8, 1.8},
				burst_size = 1
			}
		}
	}

	presets.weapon.gang_member.is_sniper = {
		aim_delay = {0.9, 2.7},
		focus_delay = 6,
		focus_dis = 300,
		spread = 2,
		miss_dis = 6,
		RELOAD_SPEED = 0.7,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		crew = true,
		range = {
			close = 1875,
			optimal = 3750,
			far = 11250
		},
		FALLOFF = {
			{
				r = 470,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {0.75, 0.75},
				burst_size = 1
			},
			{
				r = 940,
				acc = {0.25, 0.75},
				dmg_mul = 1,
				recoil = {0.75, 0.75},
				burst_size = 1
			},
			{
				r = 1875,
				acc = {0.25, 0.75},
				dmg_mul = 1,
				recoil = {1.125, 1.125},
				burst_size = 1
			},
			{
				r = 3750,
				acc = {0.2, 0.6},
				dmg_mul = 1,
				recoil = {1.5, 1.5},
				burst_size = 1
			},
			{
				r = 7500,
				acc = {0.15, 0.45},
				dmg_mul = 0.5,
				recoil = {1.8, 1.8},
				burst_size = 1
			},
			{
				r = 11250,
				acc = {0, 0},
				dmg_mul = 0.0,
				recoil = {1.8, 1.8},
				burst_size = 1
			}
		}
	}

	presets.weapon.gang_member.is_shotgun_mag = {
		aim_delay = {0.9, 2.7},
		focus_delay = 6,
		focus_dis = 300,
		spread = 20,
		miss_dis = 20,
		RELOAD_SPEED = 0.8,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		crew = true,
		range = {
			close = 400,
			optimal = 800,
			far = 2400
		},
		FALLOFF = {
			{
				r = 400,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {0.4, 0.4},
				burst_size = 10
			},
			{
				r = 800,
				acc = {0.75, 1.0},
				dmg_mul = 1,
				recoil = {0.4, 0.4},
				burst_size = 5
			},
			{
				r = 1600,
				acc = {0.4, 1.0},
				dmg_mul = 0.5,
				recoil = {0.4, 0.4},
				burst_size = 2
			},
			{
				r = 2400,
				acc = {0, 0},
				dmg_mul = 0,
				recoil = {0.8, 0.8},
				burst_size = 1
			}
		}
	}

	presets.weapon.gang_member.is_shotgun_pump = {
		aim_delay = {0.6, 1.8},
		focus_delay = 4,
		focus_dis = 450,
		spread = 20,
		miss_dis = 20,
		RELOAD_SPEED = 0.5,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		crew = true,
		range = {
			close = 450,
			optimal = 900,
			far = 3600
		},
		FALLOFF = {
			{
				r = 450,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {0.5, 0.5},
				burst_size = 1
			},
			{
				r = 900,
				acc = {0.75, 1.0},
				dmg_mul = 1,
				recoil = {0.65, 0.65},
				burst_size = 1
			},
			{
				r = 1800,
				acc = {0.4, 0.8},
				dmg_mul = 0.5,
				recoil = {0.8, 0.8},
				burst_size = 1
			},
			{
				r = 3600,
				acc = {0, 0},
				dmg_mul = 0,
				recoil = {1.6, 1.6},
				burst_size = 1
			}
		}
	}

	presets.weapon.gang_member.is_shotgun_double = {
		aim_delay = {0.3, 0.9},
		focus_delay = 2,
		focus_dis = 600,
		spread = 20,
		miss_dis = 20,
		RELOAD_SPEED = 1.2,
		melee_dmg = 1,
		melee_speed = 1,
		melee_retry_delay = {2, 2},
		crew = true,
		range = {
			close = 500,
			optimal = 1000,
			far = 4000
		},
		FALLOFF = {
			{
				r = 500,
				acc = {1.0, 1.0},
				dmg_mul = 1,
				recoil = {0.3, 0.3},
				burst_size = 1
			},
			{
				r = 1000,
				acc = {0.75, 1.0},
				dmg_mul = 1,
				recoil = {0.6, 0.6},
				burst_size = 1
			},
			{
				r = 2000,
				acc = {0.4, 0.8},
				dmg_mul = 0.5,
				recoil = {1.0, 1.0},
				burst_size = 1
			},
			{
				r = 4000,
				acc = {0, 0},
				dmg_mul = 0,
				recoil = {2.0, 2.0},
				burst_size = 1
			}
		}
	}

	presets.detection = {}
	presets.detection.normal = {
		idle = {},
		combat = {},
		recon = {},
		guard = {},
		ntl = {}
	}
	presets.detection.normal.idle.dis_max = 10000
	presets.detection.normal.idle.angle_max = 120
	presets.detection.normal.idle.delay = {0, 0}
	presets.detection.normal.idle.use_uncover_range = true
	presets.detection.normal.combat.dis_max = 10000
	presets.detection.normal.combat.angle_max = 120
	presets.detection.normal.combat.delay = {0, 0}
	presets.detection.normal.combat.use_uncover_range = true
	presets.detection.normal.recon.dis_max = 10000
	presets.detection.normal.recon.angle_max = 120
	presets.detection.normal.recon.delay = {0, 0}
	presets.detection.normal.recon.use_uncover_range = true
	presets.detection.normal.guard.dis_max = 10000
	presets.detection.normal.guard.angle_max = 120
	presets.detection.normal.guard.delay = {0, 0}
	presets.detection.normal.ntl.dis_max = 4000
	presets.detection.normal.ntl.angle_max = 60
	presets.detection.normal.ntl.delay = {0.2, 2}
	presets.detection.normal_undercover = {
		idle = {},
		combat = {},
		recon = {},
		guard = {},
		ntl = {}
	}
	presets.detection.normal_undercover.idle.dis_max = 700
	presets.detection.normal_undercover.idle.angle_max = 60
	presets.detection.normal_undercover.idle.delay = {0, 0}
	presets.detection.normal_undercover.idle.use_uncover_range = false
	presets.detection.normal_undercover.combat.dis_max = 10000
	presets.detection.normal_undercover.combat.angle_max = 120
	presets.detection.normal_undercover.combat.delay = {0, 0}
	presets.detection.normal_undercover.combat.use_uncover_range = true
	presets.detection.normal_undercover.recon.dis_max = 10000
	presets.detection.normal_undercover.recon.angle_max = 120
	presets.detection.normal_undercover.recon.delay = {0, 0}
	presets.detection.normal_undercover.recon.use_uncover_range = true
	presets.detection.normal_undercover.guard.dis_max = 10000
	presets.detection.normal_undercover.guard.angle_max = 120
	presets.detection.normal_undercover.guard.delay = {0, 0}
	presets.detection.normal_undercover.ntl.dis_max = 4000
	presets.detection.normal_undercover.ntl.angle_max = 60
	presets.detection.normal_undercover.ntl.delay = {0.2, 2}
	presets.detection.guard = {
		idle = {},
		combat = {},
		recon = {},
		guard = {},
		ntl = {}
	}
	presets.detection.guard.idle.dis_max = 10000
	presets.detection.guard.idle.angle_max = 120
	presets.detection.guard.idle.delay = {0, 0}
	presets.detection.guard.idle.use_uncover_range = true
	presets.detection.guard.combat.dis_max = 10000
	presets.detection.guard.combat.angle_max = 120
	presets.detection.guard.combat.delay = {0, 0}
	presets.detection.guard.combat.use_uncover_range = true
	presets.detection.guard.recon.dis_max = 10000
	presets.detection.guard.recon.angle_max = 120
	presets.detection.guard.recon.delay = {0, 0}
	presets.detection.guard.recon.use_uncover_range = true
	presets.detection.guard.guard.dis_max = 10000
	presets.detection.guard.guard.angle_max = 120
	presets.detection.guard.guard.delay = {0, 0}
	presets.detection.guard.ntl = presets.detection.normal.ntl
	presets.detection.sniper = {
		idle = {},
		combat = {},
		recon = {},
		guard = {},
		ntl = {}
	}
	presets.detection.sniper.idle.dis_max = 10000
	presets.detection.sniper.idle.angle_max = 180
	presets.detection.sniper.idle.delay = {0.5, 1}
	presets.detection.sniper.idle.use_uncover_range = true
	presets.detection.sniper.combat.dis_max = 10000
	presets.detection.sniper.combat.angle_max = 120
	presets.detection.sniper.combat.delay = {0.5, 1}
	presets.detection.sniper.combat.use_uncover_range = true
	presets.detection.sniper.recon.dis_max = 10000
	presets.detection.sniper.recon.angle_max = 120
	presets.detection.sniper.recon.delay = {0.5, 1}
	presets.detection.sniper.recon.use_uncover_range = true
	presets.detection.sniper.guard.dis_max = 10000
	presets.detection.sniper.guard.angle_max = 150
	presets.detection.sniper.guard.delay = {0.3, 1}
	presets.detection.sniper.ntl = presets.detection.normal.ntl
	presets.detection.gang_member = {
		idle = {},
		combat = {},
		recon = {},
		guard = {},
		ntl = {}
	}
	presets.detection.gang_member.idle.dis_max = 10000
	presets.detection.gang_member.idle.angle_max = 240
	presets.detection.gang_member.idle.delay = {0, 0}
	presets.detection.gang_member.idle.use_uncover_range = true
	presets.detection.gang_member.combat.dis_max = 10000
	presets.detection.gang_member.combat.angle_max = 240
	presets.detection.gang_member.combat.delay = {0, 0}
	presets.detection.gang_member.combat.use_uncover_range = true
	presets.detection.gang_member.recon.dis_max = 10000
	presets.detection.gang_member.recon.angle_max = 240
	presets.detection.gang_member.recon.delay = {0, 0}
	presets.detection.gang_member.recon.use_uncover_range = true
	presets.detection.gang_member.guard.dis_max = 10000
	presets.detection.gang_member.guard.angle_max = 240
	presets.detection.gang_member.guard.delay = {0, 0}
	presets.detection.gang_member.ntl = presets.detection.normal.ntl
	presets.detection.civilian = {
		cbt = {},
		ntl = {}
	}
	presets.detection.civilian.cbt.dis_max = 700
	presets.detection.civilian.cbt.angle_max = 120
	presets.detection.civilian.cbt.delay = {0, 0}
	presets.detection.civilian.cbt.use_uncover_range = true
	presets.detection.civilian.ntl.dis_max = 2000
	presets.detection.civilian.ntl.angle_max = 60
	presets.detection.civilian.ntl.delay = {0.2, 3}
	presets.detection.blind = {
		idle = {},
		combat = {},
		recon = {},
		guard = {},
		ntl = {}
	}
	presets.detection.blind.idle.dis_max = 1
	presets.detection.blind.idle.angle_max = 0
	presets.detection.blind.idle.delay = {0, 0}
	presets.detection.blind.idle.use_uncover_range = false
	presets.detection.blind.combat.dis_max = 1
	presets.detection.blind.combat.angle_max = 0
	presets.detection.blind.combat.delay = {0, 0}
	presets.detection.blind.combat.use_uncover_range = false
	presets.detection.blind.recon.dis_max = 1
	presets.detection.blind.recon.angle_max = 0
	presets.detection.blind.recon.delay = {0, 0}
	presets.detection.blind.recon.use_uncover_range = false
	presets.detection.blind.guard.dis_max = 1
	presets.detection.blind.guard.angle_max = 0
	presets.detection.blind.guard.delay = {0, 0}
	presets.detection.blind.guard.use_uncover_range = false
	presets.detection.blind.ntl.dis_max = 1
	presets.detection.blind.ntl.angle_max = 0
	presets.detection.blind.ntl.delay = {0, 0}
	presets.detection.blind.ntl.use_uncover_range = false
	presets.dodge = {
		poor = {
			speed = 1,
			occasions = {
				hit = {
					chance = 0.8,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 1,
							timeout = {2, 3}
						}
					}
				},
				scared = {
					chance = 0.8,
					check_timeout = {1, 2},
					variations = {
						side_step = {
							chance = 1,
							timeout = {2, 3}
						}
					}
				}
			}
		},
		average = {
			speed = 1,
			occasions = {
				hit = {
					chance = 0.8,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 1,
							timeout = {2, 3}
						}
					}
				},
				scared = {
					chance = 0.8,
					check_timeout = {4, 7},
					variations = {
						dive = {
							chance = 1,
							timeout = {5, 8}
						}
					}
				}
			}
		},
		heavy = {
			speed = 1,
			occasions = {
				hit = {
					chance = 0.65,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 9,
							timeout = {0, 7},
							shoot_chance = 0.8,
							shoot_accuracy = 0.5
						},
						roll = {
							chance = 1,
							timeout = {8, 10}
						}
					}
				},
				preemptive = {
					chance = 0.325,
					check_timeout = {1, 7},
					variations = {
						side_step = {
							chance = 1,
							timeout = {1, 7},
							shoot_chance = 1,
							shoot_accuracy = 0.7
						}
					}
				},
				scared = {
					chance = 0.65,
					check_timeout = {1, 2},
					variations = {
						side_step = {
							chance = 5,
							timeout = {1, 2},
							shoot_chance = 0.5,
							shoot_accuracy = 0.4
						},
						roll = {
							chance = 1,
							timeout = {8, 10}
						},
						dive = {
							chance = 2,
							timeout = {8, 10}
						}
					}
				}
			}
		},
		athletic = {
			speed = 1.1,
			occasions = {
				hit = {
					chance = 0.9,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 5,
							timeout = {1, 3},
							shoot_chance = 0.8,
							shoot_accuracy = 0.5
						},
						roll = {
							chance = 1,
							timeout = {3, 4}
						}
					}
				},
				preemptive = {
					chance = 0.45,
					check_timeout = {2, 3},
					variations = {
						side_step = {
							chance = 3,
							timeout = {1, 2},
							shoot_chance = 1,
							shoot_accuracy = 0.7
						},
						roll = {
							chance = 1,
							timeout = {3, 4}
						}
					}
				},
				scared = {
					chance = 0.9,
					check_timeout = {1, 2},
					variations = {
						side_step = {
							chance = 5,
							timeout = {1, 2},
							shoot_chance = 0.5,
							shoot_accuracy = 0.4
						},
						roll = {
							chance = 3,
							timeout = {3, 5}
						},
						dive = {
							chance = 1,
							timeout = {3, 5}
						}
					}
				}
			}
		},
		athletic_bot = {
			speed = 1.1,
			occasions = {
				hit = {
					chance = 0.8,
					check_timeout = {1, 2},
					variations = {
						side_step = {
							chance = 7,
							timeout = {1, 3},
							shoot_chance = 1,
							shoot_accuracy = 0.8 --set this to a, better value please
						},
						roll = {
							chance = 3,
							timeout = {3, 4},
							shoot_chance = 1,
							shoot_accuracy = 0.8
						},
						wheel = {
							chance = 1,
							timeout = {1.2, 2},
							shoot_chance = 1,
							shoot_accuracy = 0.8
						}
					}
				},
				preemptive = {
					chance = 0.35,
					check_timeout = {2, 3},
					variations = {
						side_step = {
							chance = 3,
							timeout = {1, 2},
							shoot_chance = 1,
							shoot_accuracy = 0.8
						},
						roll = {
							chance = 1,
							timeout = {3, 4},
							shoot_chance = 1,
							shoot_accuracy = 0.8
						},
						wheel = {
							chance = 1,
							timeout = {1.2, 2},
							shoot_chance = 1,
							shoot_accuracy = 0.8
						}
					}
				},
				scared = {
					chance = 0.8,
					check_timeout = {1, 2},
					variations = {
						side_step = {
							chance = 5,
							timeout = {1, 2},
							shoot_chance = 1,
							shoot_accuracy = 0.8
						},
						roll = {
							chance = 3,
							timeout = {3, 5},
							shoot_chance = 1,
							shoot_accuracy = 0.8
						},
						wheel = {
							chance = 1,
							timeout = {1.2, 2},
							shoot_chance = 1,
							shoot_accuracy = 0.8
						}
					}
				}
			}
		},
		athletic_very_hard = {
			speed = 1,
			occasions = {
				hit = {
					chance = 1,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 5,
							timeout = {1, 3},
							shoot_chance = 0.8,
							shoot_accuracy = 0.5
						},
						roll = {
							chance = 1,
							timeout = {3, 4}
						}
					}
				},
				preemptive = {
					chance = 0.5,
					check_timeout = {1, 2},
					variations = {
						side_step = {
							chance = 3,
							timeout = {1, 2},
							shoot_chance = 1,
							shoot_accuracy = 0.7
						},
						roll = {
							chance = 1,
							timeout = {3, 4}
						}
					}
				},
				scared = {
					chance = 1,
					check_timeout = {0, 1},
					variations = {
						side_step = {
							chance = 5,
							timeout = {1, 2},
							shoot_chance = 0.5,
							shoot_accuracy = 0.4
						},
						roll = {
							chance = 3,
							timeout = {3, 5}
						},
						dive = {
							chance = 1,
							timeout = {3, 5}
						}
					}
				}
			}
		},
		heavy_very_hard = {
			speed = 0.9,
			occasions = {
				hit = {
					chance = 0.75,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 9,
							timeout = {0, 7},
							shoot_chance = 0.8,
							shoot_accuracy = 0.5
						},
						roll = {
							chance = 1,
							timeout = {8, 10}
						}
					}
				},
				preemptive = {
					chance = 0.375,
					check_timeout = {0, 6},
					variations = {
						side_step = {
							chance = 1,
							timeout = {1, 7},
							shoot_chance = 1,
							shoot_accuracy = 0.7
						}
					}
				},
				scared = {
					chance = 0.75,
					check_timeout = {0, 1},
					variations = {
						side_step = {
							chance = 5,
							timeout = {1, 2},
							shoot_chance = 0.5,
							shoot_accuracy = 0.4
						},
						roll = {
							chance = 1,
							timeout = {8, 10}
						},
						dive = {
							chance = 2,
							timeout = {8, 10}
						}
					}
				}
			}
		},
		athletic_overkill = {
			speed = 1.1,
			occasions = {
				hit = {
					chance = 1,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 5,
							timeout = {1, 3},
							shoot_chance = 0.8,
							shoot_accuracy = 0.5
						},
						roll = {
							chance = 1,
							timeout = {3, 4}
						}
					}
				},
				preemptive = {
					chance = 0.75,
					check_timeout = {0, 1},
					variations = {
						side_step = {
							chance = 3,
							timeout = {1, 2},
							shoot_chance = 1,
							shoot_accuracy = 0.7
						},
						roll = {
							chance = 1,
							timeout = {3, 4}
						}
					}
				},
				scared = {
					chance = 1,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 5,
							timeout = {1, 2},
							shoot_chance = 0.5,
							shoot_accuracy = 0.4
						},
						roll = {
							chance = 3,
							timeout = {3, 5}
						},
						dive = {
							chance = 1,
							timeout = {3, 5}
						}
					}
				}
			}
		},
		heavy_overkill = {
			speed = 1,
			occasions = {
				hit = {
					chance = 0.75,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 9,
							timeout = {0, 7},
							shoot_chance = 0.8,
							shoot_accuracy = 0.5
						},
						roll = {
							chance = 1,
							timeout = {8, 10}
						}
					}
				},
				preemptive = {
					chance = 0.5,
					check_timeout = {0, 5},
					variations = {
						side_step = {
							chance = 1,
							timeout = {1, 7},
							shoot_chance = 1,
							shoot_accuracy = 0.7
						}
					}
				},
				scared = {
					chance = 0.75,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 5,
							timeout = {1, 2},
							shoot_chance = 0.5,
							shoot_accuracy = 0.4
						},
						roll = {
							chance = 1,
							timeout = {8, 10}
						},
						dive = {
							chance = 2,
							timeout = {8, 10}
						}
					}
				}
			}
		},
		ninja = {
			speed = 1.6,
			occasions = {
				hit = {
					chance = 0.9,
					check_timeout = {0, 3},
					variations = {
						side_step = {
							chance = 3,
							timeout = {1, 2},
							shoot_chance = 1,
							shoot_accuracy = 0.7
						},
						roll = {
							chance = 1,
							timeout = {1.2, 2}
						},
						wheel = {
							chance = 2,
							timeout = {1.2, 2}
						}
					}
				},
				preemptive = {
					chance = 0.7,
					check_timeout = {0, 3},
					variations = {
						side_step = {
							chance = 3,
							timeout = {1, 2},
							shoot_chance = 1,
							shoot_accuracy = 0.8
						},
						roll = {
							chance = 1,
							timeout = {1.2, 2}
						},
						wheel = {
							chance = 2,
							timeout = {1.2, 2}
						}
					}
				},
				scared = {
					chance = 0.9,
					check_timeout = {0, 3},
					variations = {
						side_step = {
							chance = 5,
							timeout = {1, 2},
							shoot_chance = 0.8,
							shoot_accuracy = 0.6
						},
						roll = {
							chance = 3,
							timeout = {1.2, 2}
						},
						wheel = {
							chance = 3,
							timeout = {1.2, 2}
						},
						dive = {
							chance = 1,
							timeout = {1.2, 2}
						}
					}
				}
			}
		},
		ninja_complex = {
			speed = 1.6,
			occasions = {
				hit = {
					chance = 1,
					check_timeout = {
						0,
						0
					},
					variations = {
						roll = {
							chance = 0.5,
							shoot_chance = 1,
							shoot_accuracy = 1,
							timeout = {
								0.5,
								0.5
							}
						},
						wheel = {
							chance = 0.5,
							shoot_chance = 1,
							shoot_accuracy = 1,
							timeout = {
								0.35,
								0.35
							}
						}
					}
				},
				preemptive = {
					chance = 1,
					check_timeout = {
						0,
						0
					},
					variations = {
						side_step = {
							chance = 0.33,
							shoot_chance = 1,
							shoot_accuracy = 1,
							timeout = {
								0.5,
								0.5
							}
						},
						roll = {
							chance = 0.33,
							shoot_chance = 1,
							shoot_accuracy = 1,
							timeout = {
								0.5,
								0.5
							}
						},
						wheel = {
							chance = 0.34,
							shoot_chance = 1,
							shoot_accuracy = 1,
							timeout = {
								0.35,
								0.35
							}
						}
					}
				},
				scared = {
					chance = 1,
					check_timeout = {
						0,
						0
					},
					variations = {
						wheel = {
							chance = 1,
							shoot_chance = 1,
							shoot_accuracy = 1,
							timeout = {
								0.35,
								0.35
							}
						}
					}
				}
			}
		},
		autumn = {
			speed = 1.6,
			occasions = {
				hit = {
					chance = 1,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 3,
							timeout = {1, 2},
							shoot_chance = 1,
							shoot_accuracy = 0.7
						},
						roll = {
							chance = 1,
							timeout = {1.2, 2}
						},
						wheel = {
							chance = 2,
							timeout = {1.2, 2}
						}
					}
				},
				preemptive = {
					chance = 0.9,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 3,
							timeout = {1, 2},
							shoot_chance = 1,
							shoot_accuracy = 0.8
						},
						roll = {
							chance = 1,
							timeout = {1.2, 2}
						},
						wheel = {
							chance = 2,
							timeout = {1.2, 2}
						}
					}
				},
				scared = {
					chance = 0.9,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 5,
							timeout = {1, 2},
							shoot_chance = 0.8,
							shoot_accuracy = 0.6
						},
						roll = {
							chance = 3,
							timeout = {1.2, 2}
						},
						wheel = {
							chance = 3,
							timeout = {1.2, 2}
						},
						dive = {
							chance = 1,
							timeout = {1.2, 2}
						}
					}
				}
			}
		},
		deathwish = {
			speed = 1.3,
			occasions = {
				hit = {
					chance = 1,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 3,
							timeout = {1, 2},
							shoot_chance = 1,
							shoot_accuracy = 0.7
						},
						roll = {
							chance = 1,
							timeout = {1.2, 2}
						}
					}
				},
				preemptive = {
					chance = 1,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 3,
							timeout = {1, 2},
							shoot_chance = 1,
							shoot_accuracy = 0.8
						},
						roll = {
							chance = 1,
							timeout = {1.2, 2}
						}
					}
				},
				scared = {
					chance = 1,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 5,
							timeout = {1, 2},
							shoot_chance = 0.8,
							shoot_accuracy = 0.6
						},
						roll = {
							chance = 3,
							timeout = {1.2, 2}
						},
						dive = {
							chance = 1,
							timeout = {1.2, 2}
						}
					}
				}
			}
		},
		elite = {
			speed = 1.3,
			occasions = {
				hit = {
					chance = 1,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 3,
							timeout = {1, 2},
							shoot_chance = 1,
							shoot_accuracy = 0.7
						},
						roll = {
							chance = 1,
							timeout = {1.2, 2}
						}
					}
				},
				preemptive = {
					chance = 0.9,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 3,
							timeout = {1, 2},
							shoot_chance = 1,
							shoot_accuracy = 0.8
						},
						roll = {
							chance = 1,
							timeout = {1.2, 2}
						}
					}
				},
				scared = {
					chance = 1,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 5,
							timeout = {1, 2},
							shoot_chance = 0.8,
							shoot_accuracy = 0.6
						},
						roll = {
							chance = 3,
							timeout = {1.2, 2}
						},
						dive = {
							chance = 1,
							timeout = {1.2, 2}
						}
					}
				}
			}
		},
		veteran = {
			speed = 1.6,
			occasions = {
				hit = {
					chance = 1,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 3,
							timeout = {1, 1},
							shoot_chance = 1,
							shoot_accuracy = 0.7
						},
						roll = {
							chance = 1,
							timeout = {1, 1}
						},
						wheel = {
							chance = 2,
							timeout = {1, 1}
						}
					}
				},
				preemptive = {
					chance = 1,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 3,
							timeout = {1, 1},
							shoot_chance = 1,
							shoot_accuracy = 0.8
						},
						roll = {
							chance = 1,
							timeout = {1, 1}
						},
						wheel = {
							chance = 2,
							timeout = {1, 1}
						}
					}
				},
				scared = {
					chance = 1,
					check_timeout = {0, 0},
					variations = {
						side_step = {
							chance = 5,
							timeout = {1, 1},
							shoot_chance = 0.8,
							shoot_accuracy = 0.6
						},
						roll = {
							chance = 3,
							timeout = {1, 1}
						},
						wheel = {
							chance = 3,
							timeout = {1, 1}
						},
						dive = {
							chance = 1,
							timeout = {1, 1}
						}
					}
				}
			}
		}
	}
	for preset_name, preset_data in pairs(presets.dodge) do
		for reason_name, reason_data in pairs(preset_data.occasions) do
			local total_w = 0
			for variation_name, variation_data in pairs(reason_data.variations) do
				total_w = total_w + variation_data.chance
			end
			if total_w > 0 then
				for variation_name, variation_data in pairs(reason_data.variations) do
					variation_data.chance = variation_data.chance / total_w
				end
			end
		end
	end
	presets.move_speed = {
		civ_fast = {
			stand = {
				walk = {
					ntl = {
						fwd = 150,
						strafe = 120,
						bwd = 100
					},
					hos = {
						fwd = 210,
						strafe = 190,
						bwd = 160
					},
					cbt = {
						fwd = 210,
						strafe = 175,
						bwd = 160
					}
				},
				run = {
					hos = {
						fwd = 500,
						strafe = 192,
						bwd = 230
					},
					cbt = {
						fwd = 500,
						strafe = 250,
						bwd = 230
					}
				}
			},
			crouch = {
				walk = {
					hos = {
						fwd = 174,
						strafe = 160,
						bwd = 163
					},
					cbt = {
						fwd = 174,
						strafe = 160,
						bwd = 163
					}
				},
				run = {
					hos = {
						fwd = 312,
						strafe = 245,
						bwd = 260
					},
					cbt = {
						fwd = 312,
						strafe = 245,
						bwd = 260
					}
				}
			}
		},
		gang_member = {
			stand = {
				walk = {
					ntl = {
						fwd = 150,
						strafe = 150,
						bwd = 150
					},
					hos = {
						fwd = 437.5,
						strafe = 437.5,
						bwd = 437.5
					},
					cbt = {
						fwd = 437.5,
						strafe = 437.5,
						bwd = 437.5
					}
				},
				run = {
					hos = {
						fwd = 718.75,
						strafe = 718.75,
						bwd = 718.75
					},
					cbt = {
						fwd = 718.75,
						strafe = 718.75,
						bwd = 718.75
					}
				}
			},
			crouch = {
				walk = {
					hos = {
						fwd = 281.25,
						strafe = 281.25,
						bwd = 281.25
					},
					cbt = {
						fwd = 281.25,
						strafe = 281.25,
						bwd = 281.25
					}
				},
				run = {
					hos = {
						fwd = 281.25,
						strafe = 281.25,
						bwd = 281.25
					},
					cbt = {
						fwd = 281.25,
						strafe = 281.25,
						bwd = 281.25
					}
				}
			}
		},
		lightning = {
			stand = {
				walk = {
					ntl = {
						fwd = 150,
						strafe = 120,
						bwd = 110
					},
					hos = {
						fwd = 350,
						strafe = 350,
						bwd = 350
					},
					cbt = {
						fwd = 350,
						strafe = 350,
						bwd = 350
					}
				},
				run = {
					hos = {
						fwd = 800,
						strafe = 350,
						bwd = 350
					},
					cbt = {
						fwd = 800,
						strafe = 350,
						bwd = 350
					}
				}
			},
			crouch = {
				walk = {
					hos = {
						fwd = 225,
						strafe = 225,
						bwd = 225
					},
					cbt = {
						fwd = 225,
						strafe = 225,
						bwd = 225
					}
				},
				run = {
					hos = {
						fwd = 360,
						strafe = 225,
						bwd = 225
					},
					cbt = {
						fwd = 360,
						strafe = 225,
						bwd = 225
					}
				}
			}
		},
		very_slow = {
			stand = {
				walk = {
					ntl = {
						fwd = 144,
						strafe = 120,
						bwd = 110
					},
					hos = {
						fwd = 144,
						strafe = 144,
						bwd = 144
					},
					cbt = {
						fwd = 144,
						strafe = 144,
						bwd = 144
					}
				},
				run = {
					hos = {
						fwd = 144,
						strafe = 144,
						bwd = 144
					},
					cbt = {
						fwd = 144,
						strafe = 144,
						bwd = 144
					}
				}
			},
			crouch = {
				walk = {
					hos = {
						fwd = 130,
						strafe = 130,
						bwd = 130
					},
					cbt = {
						fwd = 130,
						strafe = 130,
						bwd = 130
					}
				},
				run = {
					hos = {
						fwd = 130,
						strafe = 130,
						bwd = 130
					},
					cbt = {
						fwd = 130,
						strafe = 130,
						bwd = 130
					}
				}
			}
		},
		slow = {
			stand = {
				walk = {
					ntl = {
						fwd = 144,
						strafe = 120,
						bwd = 110
					},
					hos = {
						fwd = 144,
						strafe = 144,
						bwd = 144
					},
					cbt = {
						fwd = 144,
						strafe = 144,
						bwd = 144
					}
				},
				run = {
					hos = {
						fwd = 360,
						strafe = 144,
						bwd = 144
					},
					cbt = {
						fwd = 360,
						strafe = 144,
						bwd = 144
					}
				}
			},
			crouch = {
				walk = {
					hos = {
						fwd = 130,
						strafe = 130,
						bwd = 130
					},
					cbt = {
						fwd = 130,
						strafe = 130,
						bwd = 130
					}
				},
				run = {
					hos = {
						fwd = 208,
						strafe = 130,
						bwd = 130
					},
					cbt = {
						fwd = 208,
						strafe = 130,
						bwd = 130
					}
				}
			}
		},
		normal = {
			stand = {
				walk = {
					ntl = {
						fwd = 150,
						strafe = 120,
						bwd = 110
					},
					hos = {
						fwd = 262,
						strafe = 262,
						bwd = 262
					},
					cbt = {
						fwd = 262,
						strafe = 262,
						bwd = 262
					}
				},
				run = {
					hos = {
						fwd = 431,
						strafe = 262,
						bwd = 262
					},
					cbt = {
						fwd = 431,
						strafe = 262,
						bwd = 262
					}
				}
			},
			crouch = {
				walk = {
					hos = {
						fwd = 168,
						strafe = 168,
						bwd = 168
					},
					cbt = {
						fwd = 168,
						strafe = 168,
						bwd = 168
					}
				},
				run = {
					hos = {
						fwd = 268,
						strafe = 168,
						bwd = 168
					},
					cbt = {
						fwd = 268,
						strafe = 168,
						bwd = 168
					}
				}
			}
		},
		fast = {
			stand = {
				walk = {
					ntl = {
						fwd = 150,
						strafe = 120,
						bwd = 110
					},
					hos = {
						fwd = 297,
						strafe = 297,
						bwd = 297
					},
					cbt = {
						fwd = 297,
						strafe = 297,
						bwd = 297
					}
				},
				run = {
					hos = {
						fwd = 488,
						strafe = 297,
						bwd = 297
					},
					cbt = {
						fwd = 488,
						strafe = 297,
						bwd = 297
					}
				}
			},
			crouch = {
				walk = {
					hos = {
						fwd = 191,
						strafe = 191,
						bwd = 191
					},
					cbt = {
						fwd = 191,
						strafe = 191,
						bwd = 191
					}
				},
				run = {
					hos = {
						fwd = 305,
						strafe = 191,
						bwd = 191
					},
					cbt = {
						fwd = 305,
						strafe = 191,
						bwd = 191
					}
				}
			}
		},
		very_fast_teamai = {
			stand = {
				walk = {
					ntl = {
						fwd = 150,
						strafe = 120,
						bwd = 110
					},
					hos = {
						fwd = 332,
						strafe = 332,
						bwd = 332
					},
					cbt = {
						fwd = 332,
						strafe = 332,
						bwd = 332
					}
				},
				run = {
					hos = {
						fwd = 640,
						strafe = 640,
						bwd = 640
					},
					cbt = {
						fwd = 640,
						strafe = 640,
						bwd = 640
					}
				}
			},
			crouch = {
				walk = {
					hos = {
						fwd = 213,
						strafe = 213,
						bwd = 213
					},
					cbt = {
						fwd = 213,
						strafe = 213,
						bwd = 213
					}
				},
				run = {
					hos = {
						fwd = 420,
						strafe = 420,
						bwd = 420
					},
					cbt = {
						fwd = 420,
						strafe = 420,
						bwd = 420
					}
				}
			}
		},
		very_fast = {
			stand = {
				walk = {
					ntl = {
						fwd = 150,
						strafe = 120,
						bwd = 110
					},
					hos = {
						fwd = 332,
						strafe = 332,
						bwd = 332
					},
					cbt = {
						fwd = 332,
						strafe = 332,
						bwd = 332
					}
				},
				run = {
					hos = {
						fwd = 546,
						strafe = 332,
						bwd = 332
					},
					cbt = {
						fwd = 546,
						strafe = 332,
						bwd = 332
					}
				}
			},
			crouch = {
				walk = {
					hos = {
						fwd = 213,
						strafe = 213,
						bwd = 213
					},
					cbt = {
						fwd = 213,
						strafe = 213,
						bwd = 213
					}
				},
				run = {
					hos = {
						fwd = 340,
						strafe = 213,
						bwd = 213
					},
					cbt = {
						fwd = 340,
						strafe = 213,
						bwd = 213
					}
				}
			}
		}
	}
	for speed_preset_name, poses in pairs(presets.move_speed) do
		for pose, hastes in pairs(poses) do
			hastes.run.ntl = hastes.run.hos
		end
		poses.crouch.walk.ntl = poses.crouch.walk.hos
		poses.crouch.run.ntl = poses.crouch.run.hos
		poses.stand.run.ntl = poses.stand.run.hos
		poses.panic = poses.stand
	end
	presets.surrender = {}
	presets.surrender.always = {base_chance = 1}
	presets.surrender.never = {base_chance = 0}
	presets.surrender.easy = {
		base_chance = 0.75,
		significant_chance = 0.35,
		violence_timeout = 2,
		reasons = {
			health = {
				[1] = 0.25,
				[0.75] = 0.5,
				[0.5] = 0.75,
			},
			weapon_down = 0.5,
			pants_down = 1,
			isolated = 0.08
		},
		factors = {
			flanked = 0.05,
			unaware_of_aggressor = 0.1,
			enemy_weap_cold = 0.11,
			aggressor_dis = {
				[1000] = 0,
				[300] = 0.2
			}
		}
	}
	presets.surrender.hard = {
		base_chance = 0.5,
		significant_chance = 0.35,
		violence_timeout = 2,
		reasons = {
			health = {
				[1] = 0.25,
				[0.75] = 0.5,
				[0.5] = 0.75,
			},
			weapon_down = 0.5,
			pants_down = 1,
			isolated = 0.08
		},
		factors = {
			flanked = 0.05,
			unaware_of_aggressor = 0.1,
			enemy_weap_cold = 0.11,
			aggressor_dis = {
				[1000] = 0,
				[300] = 0.2
			}
		}
	}
	presets.surrender.bravo = {
		base_chance = 0.3,
		significant_chance = 0.35,
		violence_timeout = 2,
		reasons = {
			health = {
				[1] = 0.25,
				[0.75] = 0.5,
				[0.5] = 0.75,
			},
			weapon_down = 0.5,
			pants_down = 1,
			isolated = 0.08
		},
		factors = {
			flanked = 0.05,
			unaware_of_aggressor = 0.1,
			enemy_weap_cold = 0.11,
			aggressor_dis = {
				[1000] = 0,
				[300] = 0.2
			}
		}
	}
	presets.surrender.special = {
		base_chance = 0.25,
		significant_chance = 0.35,
		violence_timeout = 2,
		reasons = {
			health = {
				[1] = 0.25,
				[0.75] = 0.5,
				[0.5] = 0.75,
			},
			weapon_down = 0.5,
			pants_down = 1,
			isolated = 0.08
		},
		factors = {
			flanked = 0.05,
			unaware_of_aggressor = 0.1,
			enemy_weap_cold = 0.11,
			aggressor_dis = {
				[1000] = 0,
				[300] = 0.2
			}
		}
	}
	presets.suppression = {
		easy = {
			panic_chance_mul = 1,
			duration = {
				5,
				10
			},
			react_point = {
				0.25,
				0.5
			},
			brown_point = {
				1,
				2
			}
		},
		hard_def = {
			panic_chance_mul = 1,
			duration = {
				4,
				8
			},
			react_point = {
				0.5,
				1
			},
			brown_point = {
				2,
				4
			}
		},
		hard_agg = {
			panic_chance_mul = 1,
			duration = {
				3,
				6
			},
			react_point = {
				1,
				2
			},
			brown_point = {
				4,
				8
			}
		},
		no_supress = {
			panic_chance_mul = 0,
			duration = {
				0.1,
				0.15
			},
			react_point = {
				100,
				200
			},
			brown_point = {
				400,
				500
			}
		}
	}

	--bot weapon randomizer bs--
	self.char_wep_tables = {}

	self.char_wep_tables.dallas = {
		primaries = {
			[1] = {
				--weapon factory id/name, found in weaponfactorytweakdata, usually at the bottom of an init function
				--in the case of this weapon, you can find it like this: self.wpn_fps_ass_74_npc = deep_clone(self.wpn_fps_ass_74)
				--you want the first part without the self., so wpn_fps_ass_74_npc
				factory_name = "wpn_fps_ass_74_npc",
				--blueprint table used to build a weapon with certain weapon mods/parts, which can be found in weaponfactorytweakdata
				--these can be found as variables or strings, depending on where you're looking, but you need to type them as a string here
				--if the weapon is not gonna use any mods, just leave the table empty or don't even define it
				blueprint = {
					"wpn_fps_upg_ak_b_ak105",
					"wpn_fps_upg_o_ak_scopemount",
					"wpn_fps_upg_fg_midwest",
					"wpn_fps_upg_fl_ass_smg_sho_surefire",
					"wpn_fps_upg_ak_g_pgrip",
					"wpn_fps_upg_ak_m_uspalm",
					"wpn_fps_upg_o_cmore",
					"wpn_upg_ak_s_folding"
				},
				--cosmetics table used to add a skin or color to the weapon
				--haven't fully looked into where these are stored and how this works, so leave it blank for now
				cosmetics = {}
			},
			[2] = {
				factory_name = "wpn_fps_ass_amcar_npc",
				blueprint = {
					"wpn_fps_upg_o_eotech",
					"wpn_fps_m4_uupg_m_std",
					"wpn_fps_upg_m4_s_standard",
					"wpn_fps_upg_fl_ass_smg_sho_surefire",
					"wpn_fps_upg_charm_dallas"
				},
				cosmetics = {
					id = "amcar_same",
					quality = "mint"
				}
			},
			[3] = {
				factory_name = "wpn_fps_ass_g36_npc",
				blueprint = {
					"wpn_fps_ass_g36_o_vintage",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_pis_1911_npc",
				blueprint = {
					"wpn_fps_pis_1911_g_bling",
					"wpn_fps_pis_1911_b_long",
					"wpn_upg_o_marksmansight_rear",
					"wpn_fps_upg_fl_pis_tlr1",
					"wpn_fps_upg_charm_dallas"
				},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.wolf = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_shot_r870_npc",
				blueprint = {
					"wpn_fps_shot_r870_s_solid_big",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[2] = {
				factory_name = "wpn_fps_ass_s552_npc",
				blueprint = {
					"wpn_fps_ass_s552_b_long",
					"wpn_fps_ass_s552_fg_standard_green",
					"wpn_fps_ass_s552_g_standard_green",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_smg_mp5_npc",
				blueprint = {
					"wpn_fps_smg_mp5_fg_m5k"
				},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.chains = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_lmg_m249_npc",
				blueprint = {
					"wpn_fps_lmg_m249_s_solid",
					"wpn_fps_lmg_m249_b_long",
					"wpn_fps_upg_o_eotech",
					"wpn_fps_upg_fl_ass_peq15"
				},
				cosmetics = {}
			},
			[2] = {
				factory_name = "wpn_fps_ass_g3_npc",
				blueprint = {
					"wpn_fps_ass_g3_fg_railed",
					"wpn_fps_ass_g3_g_retro",
					"wpn_fps_ass_g3_s_sniper",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[3] = {
				factory_name = "wpn_fps_ass_scar_npc",
				blueprint = {
					"wpn_fps_ass_scar_fg_railext",
					"wpn_fps_ass_scar_s_sniper",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[4] = {
				factory_name = "wpn_fps_lmg_hk21_npc",
				blueprint = {},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_smg_mac10_npc",
				blueprint = {
					"wpn_fps_smg_cobray_ns_silencer",
					"wpn_fps_smg_mac10_m_extended",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.houston = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_ass_aug_npc",
				blueprint = {
					"wpn_fps_aug_b_short",
					"wpn_fps_upg_o_acog",
					"wpn_fps_aug_fg_a3",
					"wpn_fps_aug_body_f90",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[2] = {
				factory_name = "wpn_fps_ass_ak5_npc",
				blueprint = {
					"wpn_fps_ass_ak5_b_short",
					"wpn_fps_ass_ak5_fg_ak5c",
					"wpn_fps_ass_ak5_s_ak5c",
					"wpn_fps_upg_o_rx30",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_smg_mp5_npc",
				blueprint = {
					"wpn_fps_smg_mp5_fg_mp5sd",
					"wpn_fps_smg_mp5_s_adjust"
				},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.wick = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_snp_tti_npc",
				blueprint = {
					"wpn_fps_snp_tti_g_grippy",
					"wpn_fps_snp_tti_s_vltor",
					"wpn_fps_upg_fl_ass_peq15"
				},
				cosmetics = {}
			},
			[2] = {
				factory_name = "wpn_fps_sho_ksg_npc",
				blueprint = {
					"wpn_fps_sho_ksg_b_long",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[3] = {
				factory_name = "wpn_fps_ass_m4_npc",
				blueprint = {
					"wpn_fps_m4_uupg_b_sd",
					"wpn_fps_upg_ass_m4_lower_reciever_core",
					"wpn_fps_upg_o_reflex",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_smg_schakal_npc",
				blueprint = {
					"wpn_fps_smg_schakal_vg_surefire",
					"wpn_fps_upg_o_reflex",
					"wpn_fps_smg_schakal_ns_silencer",
					"wpn_fps_smg_schakal_m_short",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[2] = {
				factory_name = "wpn_fps_pis_packrat_npc",
				blueprint = {
					"wpn_fps_pis_packrat_o_expert",
					"wpn_fps_upg_ns_pis_medium_slim",
					"wpn_fps_upg_fl_pis_tlr1"

				},
				cosmetics = {}
			}
		}
	}

	local hox_m14 = {
		factory_name = "wpn_fps_ass_m14_npc",
		blueprint = {
			"wpn_fps_upg_o_t1micro",
			"wpn_fps_upg_o_m14_scopemount",
			"wpn_fps_upg_fl_ass_smg_sho_surefire"
		},
		cosmetics = {}
	}

	local hox_famas = {
		factory_name = "wpn_fps_ass_famas_npc",
		blueprint = {
			"wpn_fps_ass_famas_b_sniper",
			"wpn_fps_ass_famas_g_retro",
			"wpn_fps_upg_fl_ass_smg_sho_surefire"
		},
		cosmetics = {}
	}

	self.char_wep_tables.hoxton = {
		primaries = {
			[1] = hox_m14,
			[2] = hox_m14,
			[3] = hox_m14,
			[4] = hox_m14,
			[5] = hox_m14,
			[6] = hox_famas,
			[7] = hox_famas,
			[8] = hox_famas,
			[9] = hox_famas,
			[10] = hox_famas,
			[11] = hox_famas,
			--cursed--
			[12] = {
				factory_name = "wpn_fps_ass_m14_npc",
				blueprint = {
					"wpn_fps_ass_m14_body_ruger",
					"wpn_fps_upg_fl_ass_smg_sho_surefire",
					"wpn_fps_upg_ass_ns_surefire",
					"wpn_fps_upg_o_spot",
					"wpn_fps_upg_o_m14_scopemount"
				},
				cosmetics = {
					id = "new_m14_golddigger",
					quality = "mint"
				}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_pis_usp_npc",
				blueprint = {
					"wpn_fps_upg_ns_pis_ipsccomp",
					"wpn_fps_pis_usp_b_match",
					"wpn_fps_pis_usp_m_extended"
				},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.clover = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_ass_l85a2_npc",
				blueprint = {
					"wpn_fps_ass_l85a2_fg_short",
					"wpn_fps_ass_l85a2_b_short",
					"wpn_fps_upg_ns_ass_smg_large",
					"wpn_fps_ass_l85a2_g_worn",
					"wpn_fps_ass_l85a2_m_emag",
					"wpn_fps_upg_o_eotech",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[2] = {
				factory_name = "wpn_fps_ass_sub2000_npc",
				blueprint = {
					"wpn_fps_ass_sub2000_fg_suppressed",
					"wpn_fps_upg_o_eotech_xps",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[3] = {
				factory_name = "wpn_fps_sho_ksg_npc",
				blueprint = {
					"wpn_fps_sho_ksg_b_short",
					"wpn_fps_upg_ns_sho_salvo_large",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_smg_mp5_npc",
				blueprint = {
					"wpn_fps_smg_mp5_fg_mp5sd",
					"wpn_fps_smg_mp5_s_ring"
				},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.dragan = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_ass_vhs_npc",
				blueprint = {
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[2] = {
				factory_name = "wpn_fps_sho_spas12_npc",
				blueprint = {
					"wpn_fps_sho_s_spas12_folded",
					"wpn_fps_sho_b_spas12_long",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_pis_hs2000_npc",
				blueprint = {
					"wpn_fps_upg_pis_ns_flash",
					"wpn_fps_pis_hs2000_m_extended",
					"wpn_fps_pis_hs2000_sl_custom",
					"wpn_fps_upg_o_rmr",
					"wpn_fps_upg_fl_pis_tlr1"
				},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.jacket = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_ass_akm_npc",
				blueprint = {
					"wpn_fps_upg_ak_s_solidstock",
					"wpn_fps_upg_ak_g_wgrip",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[2] = {
				factory_name = "wpn_fps_ass_m16_npc",
				blueprint = {
					"wpn_fps_m16_fg_vietnam",
					"wpn_fps_upg_m4_m_straight",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[3] = {
				factory_name = "wpn_fps_shot_huntsman_npc",
				blueprint = {},
				cosmetics = {}
			},
			[4] = {
				factory_name = "wpn_fps_shot_r870_npc",
				blueprint = {
					"wpn_fps_shot_r870_s_nostock_big",
					"wpn_fps_shot_r870_body_rack",
					"wpn_fps_shot_r870_fg_wood",
					"wpn_fps_upg_ns_shot_shark",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_smg_cobray_npc",
				blueprint = {
					"wpn_fps_smg_cobray_body_upper_jacket",
					"wpn_fps_smg_cobray_ns_barrelextension",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.bonnie = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_lmg_mg42_npc",
				blueprint = {
					"wpn_fps_lmg_mg42_b_mg34",
					"wpn_fps_upg_bp_lmg_lionbipod",
					"wpn_fps_upg_fl_ass_peq15"
				},
				cosmetics = {}
			},
			[2] = {
				factory_name = "wpn_fps_shot_b682_npc",
				blueprint = {
					"wpn_fps_shot_b682_s_ammopouch"
				},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_pis_judge_npc",
				blueprint = {
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.sokol = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_ass_asval_npc",
				blueprint = {
					"wpn_fps_ass_asval_s_solid",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[2] = {
				factory_name = "wpn_fps_smg_vityaz_npc",
				blueprint = {
					"wpn_fps_smg_vityaz_b_supressed",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_smg_mp5_npc", ----placeholder
				blueprint = {},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.jiro = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_smg_polymer_npc",
				blueprint = {
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_smg_baka_npc",
				blueprint = {
					"wpn_fps_smg_baka_b_comp",
					"wpn_fps_smg_baka_s_standard"
				},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.bodhi = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_snp_model70_npc",
				blueprint = {
					"wpn_fps_upg_fl_ass_peq15"
				},
				cosmetics = {}
			}
			--[2] = {
			--	factory_name = "wpn_fps_ass_galil_npc",
				--blueprint = {
				--	"wpn_fps_ass_galil_fg_sniper",
				--	"wpn_fps_ass_galil_s_sniper",
				--	"wpn_fps_upg_o_specter",
				--	"wpn_fps_upg_fl_ass_smg_sho_surefire"
			--	},
			--	cosmetics = {}
			--}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_pis_sparrow_npc",
				blueprint = {
					"wpn_fps_pis_sparrow_b_comp",
					"wpn_fps_pis_sparrow_body_941",
					"wpn_fps_pis_sparrow_g_cowboy",
					"wpn_fps_upg_fl_pis_tlr1"
				},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.jimmy = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_sho_ben_npc",
				blueprint = {
					"wpn_fps_sho_ben_b_short",
					"wpn_fps_sho_ben_s_collapsed",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[2] = {
				factory_name = "wpn_fps_pis_beer_npc",
				blueprint = {},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_smg_sr2_npc",
				blueprint = {
				"wpn_fps_smg_sr2_ns_silencer",
				"wpn_fps_smg_sr2_s_unfolded",
				"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.sydney = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_ass_tecci_npc",
				blueprint = {
					"wpn_fps_ass_tecci_b_long",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[2] = {
				factory_name = "wpn_fps_sho_aa12_npc",
				blueprint = {
					"wpn_fps_sho_aa12_barrel_long",
					"wpn_fps_upg_shot_ns_king",
					"wpn_fps_sho_aa12_mag_drum",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_pis_deagle_npc",
				blueprint = {
					"wpn_fps_pis_deagle_g_bling",
					"wpn_fps_upg_fl_pis_tlr1"
				},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.rust = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_sho_boot_npc",
				blueprint = {
					"wpn_fps_sho_boot_body_exotic",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_smg_mp5_npc", ----placeholder
				blueprint = {},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.tony = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_ass_contraband_npc",
				blueprint = {
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[2] = {
				factory_name = "wpn_fps_shot_m37_npc",
				blueprint = {
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_smg_uzi_npc",
				blueprint = {
					"wpn_fps_smg_uzi_s_standard",
					"wpn_fps_smg_uzi_fg_rail",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.sangres = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_ass_akm_gold_npc",
				blueprint = {
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_pis_chinchilla_npc",
				blueprint = {
					"wpn_fps_pis_chinchilla_g_death"
				},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.duke = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_ass_ching_npc",
				blueprint = {
					"wpn_fps_ass_ching_s_pouch",
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[2] = {
				factory_name = "wpn_fps_smg_erma_npc",
				blueprint = {
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			},
			[3] = {
				factory_name = "wpn_fps_shot_m1897_npc",
				blueprint = {
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_pis_shrew_npc",
				blueprint = {
					"wpn_fps_pis_shrew_g_bling",
					"wpn_fps_upg_fl_pis_tlr1"
				},
				cosmetics = {}
			}
		}
	}

	self.char_wep_tables.joy = {
		primaries = {
			[1] = {
				factory_name = "wpn_fps_smg_shepheard_npc",
				blueprint = {
					"wpn_fps_upg_fl_ass_smg_sho_surefire"
				},
				cosmetics = {}
			}
		},
		secondaries = {
			[1] = {
				factory_name = "wpn_fps_smg_mp5_npc", ----placeholder
				blueprint = {},
				cosmetics = {}
			}
		}
	}

	presets.generic_boss_stats = {
		tags = {"special"},
		weapon = presets.weapon.gangster,
		HEALTH_INIT = 480,
		headshot_dmg_mul = strong_headshot,
		damage = {
			hurt_severity = presets.hurt_severities.tank_titan,
			explosion_damage_mul = 2
		},
		crouch_move = false,
		no_run_stop = true,
		no_run_start = true,
		allowed_poses = {stand = true},
		move_speed = presets.move_speed.slow,
		melee_weapon = "fists_dozer",
		immune_to_knock_down = true,
		always_drop = true,
		can_be_tased = false,
		priority_shout_max_dis = 3000,
		use_animation_on_fire_damage = false,
		is_special = true,
		ecm_vulnerability = 0,
		ecm_hurts = {},
		DAMAGE_CLAMP_BULLET = false,
		DAMAGE_CLAMP_EXPLOSION = false
	}

	return presets
end


local orig_create_table_structure = CharacterTweakData._create_table_structure
function CharacterTweakData:_create_table_structure()
	orig_create_table_structure(self)
	local function register_gun(weap_id, unit_name)
		table.insert(self.weap_ids, weap_id)
		table.insert(self.weap_unit_names, unit_name)
	end

	register_gun("peacemaker", Idstring("units/payday2/weapons/wpn_npc_peacemaker/wpn_npc_peacemaker"))
	register_gun("x_akmsu", Idstring("units/pd2_dlc_mad/weapons/wpn_npc_akmsu/wpn_npc_x_akmsu"))
	register_gun("m4_boom", Idstring("units/payday2/weapons/wpn_npc_m4_boom/wpn_npc_m4_boom"))
	register_gun("hk21_sc", Idstring("units/payday2/weapons/wpn_npc_hk21_sc/wpn_npc_hk21_sc"))
	register_gun("mp5_zeal", Idstring("units/payday2/weapons/wpn_npc_mp5/wpn_npc_mp5"))
	register_gun("p90_summer", Idstring("units/payday2/weapons/wpn_npc_mp5/wpn_npc_mp5"))
	register_gun("m16_summer", Idstring("units/payday2/weapons/wpn_npc_m4/wpn_npc_m4"))
	register_gun("mp5_cloak", Idstring("units/payday2/weapons/wpn_npc_mp5_cloak/wpn_npc_mp5_cloak"))
	register_gun("s552_sc", Idstring("units/payday2/weapons/wpn_npc_s552_sc/wpn_npc_s552_sc"))
	register_gun("r870_taser", Idstring("units/payday2/weapons/wpn_npc_r870_taser_sc/wpn_npc_r870_taser_sc"))
	register_gun("oicw", Idstring("units/payday2/weapons/wpn_npc_oicw/wpn_npc_oicw"))
	register_gun("hmg_spring", Idstring("units/pd2_dlc_drm/weapons/wpn_npc_mini/wpn_npc_mini"))
	register_gun("ak47_ass_elite", Idstring("units/pd2_dlc_mad/weapons/wpn_npc_ak47/wpn_npc_ak47"))
	register_gun("asval_smg_elite", Idstring("units/pd2_dlc_mad/weapons/wpn_npc_asval/wpn_npc_asval"))
	register_gun("ak47_ass_boom", Idstring("units/payday2/weapons/wpn_npc_m4_boom/wpn_npc_m4_boom"))
	register_gun("autumn_smg", Idstring("units/pd2_dlc_vip/weapons/wpn_npc_mpx/wpn_npc_mpx"))
	register_gun("s553_zeal", Idstring("units/payday2/weapons/wpn_npc_s553/wpn_npc_s553"))
	register_gun("lmg_titan", Idstring("units/payday2/weapons/wpn_npc_hk23_sc/wpn_npc_hk23_sc"))
	register_gun("x_mini_npc", Idstring("units/payday2/weapons/wpn_npc_mini/x_mini_npc"))
	register_gun("x_raging_bull_npc", Idstring("units/payday2/weapons/wpn_npc_raging_bull/x_raging_bull_npc"))
	register_gun("bravo_rifle", Idstring("units/pd2_mod_bravo/weapons/wpn_npc_swamp/wpn_npc_swamp"))
	register_gun("bravo_shotgun", Idstring("units/pd2_mod_bravo/weapons/wpn_npc_bayou/wpn_npc_bayou"))
	register_gun("bravo_lmg", Idstring("units/pd2_mod_bravo/weapons/wpn_npc_lmg_m249_bravo/wpn_npc_lmg_m249_bravo"))
	register_gun("bravo_dmr", Idstring("units/payday2/weapons/wpn_npc_scar_murkywater/wpn_npc_scar_murkywater"))
	register_gun("flamethrower_mk2_flamer_summers", Idstring("units/pd2_dlc_vip/weapons/wpn_npc_flamethrower_summers/wpn_npc_flamethrower_summers"))
	register_gun("scar_npc", Idstring("units/payday2/weapons/wpn_npc_scar_light/wpn_npc_scar_light"))
	register_gun("m1911_npc", Idstring("units/payday2/weapons/wpn_npc_1911/wpn_npc_1911"))
	register_gun("vet_cop_boss_pistol", Idstring("units/payday2/weapons/wpn_npc_raging_bull/x_raging_bull_npc"))
	register_gun("m60", Idstring("units/payday2/weapons/wpn_npc_m60/wpn_npc_m60"))
	register_gun("m60_bravo", Idstring("units/pd2_mod_bravo/weapons/wpn_npc_m60_bravo/wpn_npc_m60_bravo"))
	register_gun("m60_om", Idstring("units/payday2/weapons/wpn_npc_m60_om/wpn_npc_m60_om"))
	register_gun("mp9_titan", Idstring("units/payday2/weapons/wpn_npc_smg_mp9_titan/wpn_npc_smg_mp9_titan"))
	register_gun("sr2_titan", Idstring("units/pd2_dlc_mad/weapons/wpn_npc_sr2_titan/wpn_npc_sr2_titan"))
	register_gun("beretta92_titan", Idstring("units/payday2/weapons/wpn_npc_beretta92_titan/wpn_npc_beretta92_titan"))
	register_gun("hajk_cop", Idstring("units/pd2_dlc_bex/weapons/wpn_npc_hajk/wpn_npc_hajk"))
	register_gun("uzi_cop", Idstring("units/pd2_dlc_bex/weapons/wpn_npc_uzi/wpn_npc_uzi"))
	register_gun("m4_blue", Idstring("units/payday2/weapons/wpn_npc_mp5/wpn_npc_mp5"))
	register_gun("ak_blue", Idstring("units/pd2_dlc_mad/weapons/wpn_npc_akmsu/wpn_npc_akmsu"))
	register_gun("amcar", Idstring("units/payday2/weapons/wpn_npc_amcar/wpn_npc_amcar"))
	register_gun("ak102", Idstring("units/pd2_dlc_mad/weapons/wpn_npc_ak102/wpn_npc_ak102"))
	register_gun("m416_npc", Idstring("units/pd2_mod_lapd/weapons/wpn_npc_m416/wpn_npc_m416"))
	register_gun("socom_npc", Idstring("units/payday2/weapons/wpn_npc_socom/wpn_npc_socom"))
	register_gun("white_streak_npc", Idstring("units/pd2_dlc_mad/weapons/wpn_npc_pl14/wpn_npc_pl14"))
end

local orig_character_map = CharacterTweakData.character_map
function CharacterTweakData:character_map()
	local char_map = orig_character_map()
	--Basic
		table.insert(char_map.basic.list, "ene_bulldozer_2_hw")
		table.insert(char_map.basic.list, "ene_city_swat_1_sc")
		table.insert(char_map.basic.list, "ene_city_swat_heavy_1")
		table.insert(char_map.basic.list, "ene_city_swat_heavy_2")
		table.insert(char_map.basic.list, "ene_fbi_heavy_r870")
		table.insert(char_map.basic.list, "ene_fbi_heavy_r870_sc")
		table.insert(char_map.basic.list, "ene_fbi_swat_3")
		table.insert(char_map.basic.list, "ene_city_shield")
		table.insert(char_map.basic.list, "ene_shield_gensec")
		table.insert(char_map.basic.list, "ene_vip_2")
		table.insert(char_map.basic.list, "ene_sniper_3")
		table.insert(char_map.basic.list, "ene_swat_heavy_r870")
		table.insert(char_map.basic.list, "ene_swat_heavy_r870_sc")
		table.insert(char_map.basic.list, "ene_grenadier_1")
		table.insert(char_map.basic.list, "ene_veteran_cop_2")
		table.insert(char_map.basic.list, "ene_veteran_lod_1")
		table.insert(char_map.basic.list, "ene_veteran_lod_2")
		table.insert(char_map.basic.list, "ene_spook_cloak_1")
		table.insert(char_map.basic.list, "ene_mememan_1")
		table.insert(char_map.basic.list, "ene_mememan_2")
		table.insert(char_map.basic.list, "ene_bulldozer_biker_1")
		table.insert(char_map.basic.list, "ene_guard_biker_1")
		table.insert(char_map.basic.list, "ene_murky_heavy_m4")
		table.insert(char_map.basic.list, "ene_murky_heavy_r870")
	--dlc1
		table.insert(char_map.dlc1.list, "ene_security_gensec_3")
	--vip
		table.insert(char_map.vip.list, "ene_vip_2")
		table.insert(char_map.vip.list, "ene_vip_2_assault")
		table.insert(char_map.vip.list, "ene_spring")
		table.insert(char_map.vip.list, "ene_vip_autumn")
		table.insert(char_map.vip.list, "ene_summers")
		table.insert(char_map.vip.list, "ene_phalanx_medic")
		table.insert(char_map.vip.list, "ene_phalanx_grenadier")
		table.insert(char_map.vip.list, "ene_phalanx_taser")
		table.insert(char_map.vip.list, "ene_phalanx_1_assault")
		table.insert(char_map.vip.list, "ene_titan_shotgun")
		table.insert(char_map.vip.list, "ene_titan_rifle")
		table.insert(char_map.vip.list, "ene_omnia_lpf")
		table.insert(char_map.vip.list, "ene_fbi_titan_1")
		table.insert(char_map.vip.list, "ene_titan_taser")
	--mad
		table.insert(char_map.mad.list, "ene_akan_fbi_heavy_r870")
		table.insert(char_map.mad.list, "ene_akan_cs_cop_c45_sc")
		table.insert(char_map.mad.list, "ene_akan_cs_cop_raging_bull_sc")
		table.insert(char_map.mad.list, "ene_akan_fbi_swat_dw_ak47_ass_sc")
		table.insert(char_map.mad.list, "ene_akan_fbi_swat_dw_ak")
		table.insert(char_map.mad.list, "ene_akan_fbi_swat_dw_r870_sc")
		table.insert(char_map.mad.list, "ene_akan_fbi_swat_dw_ump")
		table.insert(char_map.mad.list, "ene_akan_fbi_swat_ump")
		table.insert(char_map.mad.list, "ene_akan_cs_cop_akmsu_smg_sc")
		table.insert(char_map.mad.list, "ene_akan_fbi_heavy_dw")
		table.insert(char_map.mad.list, "ene_akan_fbi_heavy_dw_r870")
		table.insert(char_map.mad.list, "ene_akan_fbi_1")
		table.insert(char_map.mad.list, "ene_akan_fbi_2")
		table.insert(char_map.mad.list, "ene_akan_veteran_1")
		table.insert(char_map.mad.list, "ene_akan_veteran_2")
		table.insert(char_map.mad.list, "ene_akan_grenadier_1")
		table.insert(char_map.mad.list, "ene_akan_medic_bob")
		table.insert(char_map.mad.list, "ene_akan_medic_zdann")
		table.insert(char_map.mad.list, "ene_vip_2")
		table.insert(char_map.mad.list, "ene_titan_shotgun")
		table.insert(char_map.mad.list, "ene_titan_rifle")
		table.insert(char_map.mad.list, "ene_akan_lpf")
		table.insert(char_map.mad.list, "ene_fbi_titan_1")
		table.insert(char_map.mad.list, "ene_phalanx_1_assault")
		table.insert(char_map.mad.list, "ene_spook_cloak_1")
		table.insert(char_map.mad.list, "ene_titan_taser")
	--gitgud
		table.insert(char_map.gitgud.list, "ene_zeal_city_1")
		table.insert(char_map.gitgud.list, "ene_zeal_city_2")
		table.insert(char_map.gitgud.list, "ene_zeal_city_3")
		table.insert(char_map.gitgud.list, "ene_zeal_medic")
		table.insert(char_map.gitgud.list, "ene_zeal_grenadier_1")
		table.insert(char_map.gitgud.list, "ene_zeal_sniper")
		table.insert(char_map.gitgud.list, "ene_zeal_heavy_shield")
		table.insert(char_map.gitgud.list, "ene_zeal_fbi_1")
		table.insert(char_map.gitgud.list, "ene_zeal_fbi_m4")
		table.insert(char_map.gitgud.list, "ene_zeal_fbi_mp5")
		table.insert(char_map.gitgud.list, "ene_zeal_swat_heavy_sc")
		table.insert(char_map.gitgud.list, "ene_zeal_swat_heavy_r870_sc")
	--drm
		table.insert(char_map.drm.list, "ene_bulldozer_medic_classic")
	--bex
		table.insert(char_map.bex.list, "ene_swat_policia_federale_sc")
		table.insert(char_map.bex.list, "ene_swat_policia_federale_city_ump")
		table.insert(char_map.bex.list, "ene_swat_policia_federale_zeal")
		table.insert(char_map.bex.list, "ene_swat_policia_federale_zeal_r870")
		table.insert(char_map.bex.list, "ene_swat_policia_federale_zeal_ump")
		table.insert(char_map.bex.list, "ene_swat_policia_federale_city_fbi_ump")
		table.insert(char_map.bex.list, "ene_swat_policia_federale_fbi")
		table.insert(char_map.bex.list, "ene_swat_policia_federale_fbi_r870")
		table.insert(char_map.bex.list, "ene_swat_policia_federale_fbi_ump")
		table.insert(char_map.bex.list, "ene_swat_cloaker_policia_federale_sc")
		table.insert(char_map.bex.list, "ene_swat_shield_policia_federale_mp9_fbi")
		table.insert(char_map.bex.list, "ene_swat_shield_policia_federale_mp9_sc")
		table.insert(char_map.bex.list, "ene_swat_heavy_policia_federale_city_r870")
		table.insert(char_map.bex.list, "ene_swat_heavy_policia_federale_city_g36")
		table.insert(char_map.bex.list, "ene_swat_heavy_policia_federale_zeal_r870")
		table.insert(char_map.bex.list, "ene_swat_heavy_policia_federale_zeal_g36")
		table.insert(char_map.bex.list, "ene_policia_03")
		table.insert(char_map.bex.list, "ene_policia_04")
		table.insert(char_map.bex.list, "ene_fbi_1")
		table.insert(char_map.bex.list, "ene_fbi_2")
		table.insert(char_map.bex.list, "ene_fbi_3")
		table.insert(char_map.bex.list, "ene_grenadier_1")
		table.insert(char_map.bex.list, "ene_veteran_enrique_1")
		table.insert(char_map.bex.list, "ene_veteran_enrique_2")
	--fully custom
		char_map.sharks = {
			path = "units/pd2_mod_sharks/characters/",
			list = {
				"ene_murky_cs_cop_c45",
				"ene_murky_cs_cop_mp5",
				"ene_murky_cs_cop_r870",
				"ene_murky_cs_cop_raging_bull",
				"ene_fbi_3",
				"ene_murky_swat_r870",
				"ene_fbi_1",
				"ene_fbi_2",
				"ene_fbi_swat_1",
				"ene_fbi_swat_2",
				"ene_fbi_swat_3",
				"ene_fbi_heavy_1",
				"ene_fbi_heavy_r870",
				"ene_swat_heavy_1",
				"ene_swat_heavy_r870",
				"ene_murky_shield_yellow",
				"ene_murky_shield_fbi",
				"ene_city_swat_1",
				"ene_city_swat_2",
				"ene_city_swat_3",
				"ene_murky_fbi_tank_m249",
				"ene_murky_fbi_tank_medic",
				"ene_murky_fbi_tank_saiga",
				"ene_murky_fbi_tank_r870",
				"ene_murky_spook",
				"ene_murky_veteran_1",
				"ene_grenadier_1",
				"ene_murky_medic_m4",
				"ene_murky_tazer",
				"ene_swat_1",
				"ene_swat_2",
				"ene_murky_sniper"
			}
		}

		char_map.omnia = {
			path = "units/pd2_mod_omnia/characters/",
			list = {
				"ene_omnia_hrt_1",
				"ene_omnia_hrt_2",
				"ene_omnia_hrt_3",
				"ene_omnia_crew",
				"ene_omnia_crew_2",
				"ene_omnia_city",
				"ene_omnia_city_2",
				"ene_omnia_city_3",
				"ene_omnia_heavy",
				"ene_omnia_heavy_r870",
				"ene_bulldozer_1",
				"ene_bulldozer_2",
				"ene_bulldozer_3",
				"ene_omnia_spook",
				"ene_grenadier_1",
				"ene_omnia_medic",
				"ene_omnia_taser",
				"ene_omnia_shield"
			}
		}

		char_map.nypd = {
			path = "units/pd2_mod_nypd/characters/",
			list = {
				"ene_shield_1",
				"ene_sniper_1",
				"ene_fbi_swat_1",
				"ene_fbi_swat_2",
				"ene_fbi_swat_3",
				"ene_fbi_heavy_1",
				"ene_fbi_heavy_r870",
				"ene_fbi_heavy_r870_sc",
				"ene_spook_1",
				"ene_bulldozer_1",
				"ene_bulldozer_2",
				"ene_nypd_heavy_m4",
				"ene_nypd_medic",
				"ene_tazer_1",
				"ene_fbi_2",
				"ene_fbi_3",
				"ene_nypd_veteran_cop_1",
				"ene_nypd_veteran_cop_2",
				"ene_nypd_heavy_r870",
				"ene_nypd_swat_1",
				"ene_nypd_swat_2",
				"ene_nypd_shield",
				"ene_nypd_murky_1",
				"ene_nypd_murky_2",
				"ene_cop_1",
				"ene_cop_2",
				"ene_cop_3",
				"ene_cop_4"
			}
		}

		char_map.lapd = {
			path = "units/pd2_mod_lapd/characters/",
			list = {
				"ene_shield_1",
				"ene_shield_2",
				"ene_cop_1",
				"ene_cop_2",
				"ene_cop_3",
				"ene_cop_4",
				"ene_sniper_1",
				"ene_fbi_swat_1",
				"ene_fbi_swat_2",
				"ene_fbi_3",
				"ene_city_shield",
				"ene_fbi_2",
				"ene_fbi_swat_3",
				"ene_city_swat_1",
				"ene_city_swat_2",
				"ene_city_swat_3",
				"ene_bulldozer_3",
				"ene_fbi_heavy_1",
				"ene_fbi_heavy_r870",
				"ene_fbi_heavy_r870_sc",
				"ene_city_heavy_g36",
				"ene_city_heavy_r870_sc",
				"ene_swat_1",
				"ene_swat_2",
				"ene_swat_heavy_1",
				"ene_swat_heavy_r870",
				"ene_lapd_veteran_cop_1",
				"ene_lapd_veteran_cop_2"
			}
		}

		char_map.bravo = {
			path = "units/pd2_mod_bravo/characters/",
			list = {
				"ene_bravo_dmr",
				"ene_bravo_lmg",
				"ene_bravo_rifle",
				"ene_bravo_shotgun",
				"ene_bravo_dmr_ru",
				"ene_bravo_lmg_ru",
				"ene_bravo_rifle_ru",
				"ene_bravo_shotgun_ru",
				"ene_bravo_dmr_murky",
				"ene_bravo_lmg_murky",
				"ene_bravo_rifle_murky",
				"ene_bravo_shotgun_murky",
				"ene_bravo_dmr_mex",
				"ene_bravo_lmg_mex",
				"ene_bravo_rifle_mex",
				"ene_bravo_shotgun_mex"
			}
		}

		char_map.dave = {
			path = "units/pd2_mod_dave/characters/",
			list = {
				"ene_big_dave"
			}
		}

		char_map.halloween = {
			path = "units/pd2_mod_halloween/characters/",
			list = {
				"ene_skele_swat",
				"ene_skele_swat_2",
				"ene_zeal_city_1",
				"ene_zeal_city_2",
				"ene_zeal_city_3",
				"ene_zeal_swat_heavy_sc",
				"ene_zeal_swat_heavy_r870_sc",
				"ene_city_swat_1",
				"ene_city_swat_2",
				"ene_city_swat_3",
				"ene_fbi_swat_3",
				"ene_medic_mp5",
				"ene_zeal_fbi_m4",
				"ene_zeal_fbi_mp5",
				"ene_zeal_swat_shield",
				"ene_zeal_bulldozer",
				"ene_zeal_bulldozer_2",
				"ene_zeal_bulldozer_3",
				"ene_zeal_cloaker",
				"ene_grenadier_1",
				"ene_zeal_tazer",
				"ene_shield_gensec",
				"ene_fbi_heavy_r870_sc",
				"ene_city_heavy_r870_sc",
				"ene_swat_heavy_r870_sc",
				"ene_headless_hatman",
				"ene_spook_cloak_1",
				"ene_omnia_lpf",
				"ene_fbi_titan_1",
				"ene_titan_taser",
				"ene_veteran_cop_1",
				"ene_phalanx_1_assault"
			}
		}

	return char_map
end

function CharacterTweakData:_process_weapon_usage_table(weap_usage_table)
	--This space intentionally left blank.
end

function CharacterTweakData:_set_normal()
	self:_multiply_all_hp(0.5, 1)
	self:_multiply_all_damage(0.3, 0.45, 0.5)
	self:_multiply_teamai_health(0.3, 0.3)
	self:_multiply_all_speeds(1, 1)

	--No normal tase for Elektra on lower difficulties
	self.taser_summers.weapon.is_rifle.tase_distance = 0

	--No Frags on Spring on lower difficulties
	self.spring.grenade = nil
	self.headless_hatman.grenade = nil

	self.flashbang_multiplier = 10
	self.concussion_multiplier = 10


	self.weap_unit_names[19] = Idstring("units/payday2/weapons/wpn_npc_m4/wpn_npc_m4")
	self.weap_unit_names[23] = Idstring("units/payday2/weapons/wpn_npc_mp5_tactical/wpn_npc_mp5_tactical")
	self.weap_unit_names[31] = Idstring("units/payday2/weapons/wpn_npc_benelli/wpn_npc_benelli")
	if job == "tag" or job == "xmn_tag" then
		self.weap_unit_names[59] = Idstring("units/payday2/weapons/wpn_npc_raging_bull/wpn_npc_raging_bull")
	end
end
CharacterTweakData._set_easy = CharacterTweakData._set_normal

function CharacterTweakData:_set_hard()
	self:_multiply_all_hp(0.625, 1)
	self:_multiply_all_damage(0.5, 0.75, 0.625)
	self:_multiply_teamai_health(0.5, 0.3)
	self:_multiply_all_speeds(1, 1)

	--No normal tase for Elektra on lower difficulties
	self.taser_summers.weapon.is_rifle.tase_distance = 0

	--No Frags on Spring on lower difficulties
	self.spring.grenade = nil
	self.headless_hatman.grenade = nil

	self.flashbang_multiplier = 10
	self.concussion_multiplier = 10
	self.weap_unit_names[6] = Idstring("units/payday2/weapons/wpn_npc_m4/wpn_npc_m4")
	self.weap_unit_names[19] = Idstring("units/payday2/weapons/wpn_npc_m4/wpn_npc_m4")
	self.weap_unit_names[23] = Idstring("units/payday2/weapons/wpn_npc_mp5_tactical/wpn_npc_mp5_tactical")
	self.weap_unit_names[31] = Idstring("units/payday2/weapons/wpn_npc_benelli/wpn_npc_benelli")
	self.weap_unit_names[69] = Idstring("units/payday2/weapons/wpn_npc_m4/wpn_npc_m4")
	self.weap_unit_names[70] = Idstring("units/pd2_dlc_mad/weapons/wpn_npc_ak47/wpn_npc_ak47")
	if job == "tag" or job == "xmn_tag" then
		self.weap_unit_names[59] = Idstring("units/payday2/weapons/wpn_npc_raging_bull/wpn_npc_raging_bull")
	end
end

function CharacterTweakData:_set_overkill()
	self:_multiply_all_hp(0.75, 1)
	self:_multiply_all_damage(0.7, 1.05, 0.75)
	self:_multiply_teamai_health(0.7, 0.3)
	self:_multiply_all_speeds(1, 1)

	--No normal tase for Elektra on lower difficulties
	self.taser_summers.weapon.is_rifle.tase_distance = 0

	--No Frags on Spring on lower difficulties
	self.spring.grenade = nil
	self.headless_hatman.grenade = nil

	self.flashbang_multiplier = 10
	self.concussion_multiplier = 10
	self.weap_unit_names[19] = Idstring("units/payday2/weapons/wpn_npc_m4/wpn_npc_m4")
	self.weap_unit_names[23] = Idstring("units/payday2/weapons/wpn_npc_mp5_tactical/wpn_npc_mp5_tactical")
	self.weap_unit_names[31] = Idstring("units/payday2/weapons/wpn_npc_benelli/wpn_npc_benelli")
	self.weap_unit_names[69] = Idstring("units/payday2/weapons/wpn_npc_m4/wpn_npc_m4")
	self.weap_unit_names[70] = Idstring("units/pd2_dlc_mad/weapons/wpn_npc_ak47/wpn_npc_ak47")
	if job == "tag" or job == "xmn_tag" then
		self.weap_unit_names[59] = Idstring("units/payday2/weapons/wpn_npc_raging_bull/wpn_npc_raging_bull")
	end
end

function CharacterTweakData:_set_overkill_145()
	self:_multiply_all_hp(0.825, 2)
	self:_multiply_all_damage(0.9, 1.35, 0.825)
	self:_multiply_teamai_health(0.9, 0.25)
	self:_multiply_all_speeds(1, 1)

	self.fbi.can_shoot_while_dodging = true
	self.swat.can_shoot_while_dodging = true
	self.hrt.can_shoot_while_dodging = true
	self.fbi.can_slide_on_suppress = true
	self.swat.can_slide_on_suppress = true
	self.hrt.can_slide_on_suppress = true

	self.flashbang_multiplier = 10
	self.concussion_multiplier = 10
	self.weap_unit_names[19] = Idstring("units/payday2/weapons/wpn_npc_m4/wpn_npc_m4")
	self.weap_unit_names[23] = Idstring("units/payday2/weapons/wpn_npc_mp5_tactical/wpn_npc_mp5_tactical")
	self.weap_unit_names[31] = Idstring("units/payday2/weapons/wpn_npc_benelli/wpn_npc_benelli")
	if job == "tag" or job == "xmn_tag" then
		self.weap_unit_names[59] = Idstring("units/payday2/weapons/wpn_npc_raging_bull/wpn_npc_raging_bull")
	end
end

function CharacterTweakData:_set_easy_wish()
	self:_multiply_all_hp(1, 2)
	self:_multiply_all_damage(1, 1.5, 1)
	self:_multiply_teamai_health(1, 0.25)
	self:_multiply_all_speeds(1, 1)

	self:_set_characters_weapon_preset("expert", "good")
	self.fbi.can_shoot_while_dodging = true
	self.swat.can_shoot_while_dodging = true
	self.hrt.can_shoot_while_dodging = true
	self.fbi.can_slide_on_suppress = true
	self.swat.can_slide_on_suppress = true
	self.hrt.can_slide_on_suppress = true
	self.fbi_swat.can_slide_on_suppress = true
	self.city_swat.can_slide_on_suppress = true

	self.flashbang_multiplier = 10
	self.concussion_multiplier = 10
	self.weap_unit_names[19] = Idstring("units/payday2/weapons/wpn_npc_m4/wpn_npc_m4")
	self.weap_unit_names[23] = Idstring("units/payday2/weapons/wpn_npc_mp5_tactical/wpn_npc_mp5_tactical")
	self.weap_unit_names[31] = Idstring("units/payday2/weapons/wpn_npc_benelli/wpn_npc_benelli")
	if job == "tag" or job == "xmn_tag" then
		self.weap_unit_names[59] = Idstring("units/payday2/weapons/wpn_npc_raging_bull/wpn_npc_raging_bull")
	end
end

function CharacterTweakData:_set_overkill_290()
	self:_multiply_all_hp(1, 2)
	self:_multiply_all_damage(1, 1.5, 1)
	self:_multiply_teamai_health(1, 0.25)
	self:_multiply_all_speeds(1, 1)

	self.fbi.can_shoot_while_dodging = true
	self.swat.can_shoot_while_dodging = true
	self.hrt.can_shoot_while_dodging = true
	self.fbi.can_slide_on_suppress = true
	self.swat.can_slide_on_suppress = true
	self.hrt.can_slide_on_suppress = true
	self.fbi_swat.can_slide_on_suppress = true
	self.city_swat.can_slide_on_suppress = true

	--Fast HRTs
	self.fbi.move_speed = self.presets.move_speed.lightning
	self.hrt.move_speed = self.presets.move_speed.lightning

	--Winters can now overheal special enemies
	self.phalanx_vip.do_omnia.overheal_specials = true

	self.flashbang_multiplier = 10
	self.concussion_multiplier = 10
	self.weap_unit_names[19] = Idstring("units/payday2/weapons/wpn_npc_m4/wpn_npc_m4")
	self.weap_unit_names[23] = Idstring("units/payday2/weapons/wpn_npc_mp5_tactical/wpn_npc_mp5_tactical")
	self.weap_unit_names[31] = Idstring("units/payday2/weapons/wpn_npc_benelli/wpn_npc_benelli")
	if job == "tag" or job == "xmn_tag" then
		self.weap_unit_names[59] = Idstring("units/payday2/weapons/wpn_npc_raging_bull/wpn_npc_raging_bull")
	end
end

function CharacterTweakData:_set_sm_wish()
	self:_multiply_all_hp(1, 3)
	self:_multiply_all_damage(1, 1.5, 1)
	self:_multiply_teamai_health(1, 0.2)
	self:_multiply_all_speeds(1, 1)

	self.fbi.can_shoot_while_dodging = true
	self.swat.can_shoot_while_dodging = true
	self.hrt.can_shoot_while_dodging = true
	self.fbi.can_slide_on_suppress = true
	self.swat.can_slide_on_suppress = true
	self.hrt.can_slide_on_suppress = true
	self.fbi_swat.can_slide_on_suppress = true
	self.city_swat.can_slide_on_suppress = true
	self.fbi_heavy_swat.can_slide_on_suppress = true

	self.weap_unit_names[13] = Idstring("units/payday2/weapons/wpn_npc_sniper_sc/wpn_npc_sniper_sc")
	self.weap_unit_names[21] = Idstring("units/pd2_dlc_mad/weapons/wpn_npc_svd_sc/wpn_npc_svd_sc")

	self.city_swat.can_shoot_while_dodging = true

	self.flashbang_multiplier = 10
	self.concussion_multiplier = 10

	--Titan SWAT smoke dodging
	self.heavy_swat.dodge_with_grenade = {
		smoke = {duration = {
			12,
			12
		}},
		check = function (t, nr_grenades_used)
			local delay_till_next_use = 30
			local chance = 0.15

			if math.random() < chance then
				return true, t + delay_till_next_use
			end

			return false, t + delay_till_next_use
		end
	}
	self.fbi_swat.dodge_with_grenade = {
		smoke = {duration = {
			12,
			12
		}},
		check = function (t, nr_grenades_used)
			local delay_till_next_use = 30
			local chance = 0.15

			if math.random() < chance then
				return true, t + delay_till_next_use
			end

			return false, t + delay_till_next_use
		end
	}
	self.city_swat.dodge_with_grenade = {
		smoke = {duration = {
			12,
			12
		}},
		check = function (t, nr_grenades_used)
			local delay_till_next_use = 30
			local chance = 0.15

			if math.random() < chance then
				return true, t + delay_till_next_use
			end

			return false, t + delay_till_next_use
		end
	}
	self.weekend.dodge_with_grenade = {
		smoke = {duration = {
			12,
			12
		}},
		check = function (t, nr_grenades_used)
			local delay_till_next_use = 30
			local chance = 0.15

			if math.random() < chance then
				return true, t + delay_till_next_use
			end

			return false, t + delay_till_next_use
		end
	}
	self.weekend_lmg.dodge_with_grenade = {
		smoke = {duration = {
			12,
			12
		}},
		check = function (t, nr_grenades_used)
			local delay_till_next_use = 30
			local chance = 0.1

			if math.random() < chance then
				return true, t + delay_till_next_use
			end

			return false, t + delay_till_next_use
		end
	}

	--Fast HRTs
	self.fbi.move_speed = self.presets.move_speed.lightning
	self.hrt.move_speed = self.presets.move_speed.lightning

	--Winters can now overheal special enemies
	self.phalanx_vip.do_omnia.overheal_specials = true

	self.weap_unit_names[19] = Idstring("units/payday2/weapons/wpn_npc_m4/wpn_npc_m4")
	self.weap_unit_names[23] = Idstring("units/payday2/weapons/wpn_npc_mp5_tactical/wpn_npc_mp5_tactical")
	self.weap_unit_names[31] = Idstring("units/payday2/weapons/wpn_npc_benelli/wpn_npc_benelli")
	if job == "tag" or job == "xmn_tag" then
		self.weap_unit_names[59] = Idstring("units/payday2/weapons/wpn_npc_raging_bull/wpn_npc_raging_bull")
	end
end

function CharacterTweakData:is_special_unit(enemy_tweak)
	local is_special = false
	if self[enemy_tweak].is_special then
		is_special = true
	end
	return is_special
end

function CharacterTweakData:_multiply_all_hp(health_mul, headshot_index)
	--Get new headshot multiplier.
	local hs_mul = headshot_difficulty_array[headshot_index] --Get headshot multiplier.
	local hp_mul = health_mul * (hs_mul / headshot_difficulty_array[3]) --Get overall hp mul. Compensate for lower headshot mults by reducing body health.

	for _, enemy_tweak in ipairs(self._enemy_list) do
		local enemy = self[enemy_tweak]
		if enemy then
			enemy.HEALTH_INIT = enemy.HEALTH_INIT * hp_mul
			enemy.headshot_dmg_mul = enemy.headshot_dmg_mul * hs_mul
		end
	end
end

function CharacterTweakData:_multiply_all_speeds(walk_mul, run_mul)
	for _, enemy_tweak in ipairs(self._enemy_list) do
		if self[enemy_tweak] then
			local speed_preset = deep_clone(self[enemy_tweak].move_speed)

			self[enemy_tweak].move_speed = speed_preset

			speed_preset.stand.walk.hos.fwd = speed_preset.stand.walk.hos.fwd * walk_mul
			speed_preset.stand.walk.hos.strafe = speed_preset.stand.walk.hos.strafe * walk_mul
			speed_preset.stand.walk.hos.bwd = speed_preset.stand.walk.hos.bwd * walk_mul
			speed_preset.stand.walk.cbt.fwd = speed_preset.stand.walk.cbt.fwd * walk_mul
			speed_preset.stand.walk.cbt.strafe = speed_preset.stand.walk.cbt.strafe * walk_mul
			speed_preset.stand.walk.cbt.bwd = speed_preset.stand.walk.cbt.bwd * walk_mul
			speed_preset.stand.run.hos.fwd = speed_preset.stand.run.hos.fwd * run_mul
			speed_preset.stand.run.hos.strafe = speed_preset.stand.run.hos.strafe * run_mul
			speed_preset.stand.run.hos.bwd = speed_preset.stand.run.hos.bwd * run_mul
			speed_preset.stand.run.cbt.fwd = speed_preset.stand.run.cbt.fwd * run_mul
			speed_preset.stand.run.cbt.strafe = speed_preset.stand.run.cbt.strafe * run_mul
			speed_preset.stand.run.cbt.bwd = speed_preset.stand.run.cbt.bwd * run_mul
			speed_preset.crouch.walk.hos.fwd = speed_preset.crouch.walk.hos.fwd * walk_mul
			speed_preset.crouch.walk.hos.strafe = speed_preset.crouch.walk.hos.strafe * walk_mul
			speed_preset.crouch.walk.hos.bwd = speed_preset.crouch.walk.hos.bwd * walk_mul
			speed_preset.crouch.walk.cbt.fwd = speed_preset.crouch.walk.cbt.fwd * walk_mul
			speed_preset.crouch.walk.cbt.strafe = speed_preset.crouch.walk.cbt.strafe * walk_mul
			speed_preset.crouch.walk.cbt.bwd = speed_preset.crouch.walk.cbt.bwd * walk_mul
			speed_preset.crouch.run.hos.fwd = speed_preset.crouch.run.hos.fwd * run_mul
			speed_preset.crouch.run.hos.strafe = speed_preset.crouch.run.hos.strafe * run_mul
			speed_preset.crouch.run.hos.bwd = speed_preset.crouch.run.hos.bwd * run_mul
			speed_preset.crouch.run.cbt.fwd = speed_preset.crouch.run.cbt.fwd * run_mul
			speed_preset.crouch.run.cbt.strafe = speed_preset.crouch.run.cbt.strafe * run_mul
			speed_preset.crouch.run.cbt.bwd = speed_preset.crouch.run.cbt.bwd * run_mul
		end
	end
end

function CharacterTweakData:_set_characters_ecm_hurts()
	local no_ecm_hurts = {}
	local ecm_hurts = {ears = {max_duration = 3, min_duration = 3}}
	for _, enemy_tweak in ipairs(self._enemy_list) do
		if self[enemy_tweak] then
			if self[enemy_tweak].ecm_vulnerability == 1 then
				self[enemy_tweak].ecm_hurts = ecm_hurts
			else
				self[enemy_tweak].ecm_hurts = no_ecm_hurts
			end
		end
	end
end

function CharacterTweakData:_multiply_weapon_preset(preset, accuracy_mul, aim_delay_mul, focus_delay_mul, recoil_mul, reload_speed_mul)
	preset.aim_delay = {preset.aim_delay[1] * aim_delay_mul, preset.aim_delay[2] * aim_delay_mul}
	preset.RELOAD_SPEED = preset.RELOAD_SPEED * reload_speed_mul
	preset.focus_delay = preset.focus_delay * focus_delay_mul
	for i = 1, #preset.FALLOFF do
		if preset.FALLOFF[i].r > 300 then
			preset.FALLOFF[i].acc = {preset.FALLOFF[i].acc[1] * accuracy_mul, preset.FALLOFF[i].acc[2] * accuracy_mul}
		end
		preset.FALLOFF[i].recoil = {preset.FALLOFF[i].recoil[1] * recoil_mul, preset.FALLOFF[i].recoil[2] * recoil_mul}
	end
end

local function multiply_raw_damage(damage, mul)
	return 0.1 * (math.ceil(damage * 10 * mul))
end
function CharacterTweakData:_multiply_all_damage(mul, gang_mul, teamai_mul)
	for tier_name, preset_tier in pairs(self.presets.weapon) do

		--Select relevant multiplier.
		local current_dmg_mul = mul
		if tier_name == "gangster" then
			current_dmg_mul = gang_mul
		elseif tier_name == "gang_member" then
			current_dmg_mul = teamai_mul
		end

		--Apply multiplier.
		for preset_name, preset in pairs(preset_tier) do
			if preset.melee_dmg then
				preset.melee_dmg = preset.melee_dmg * current_dmg_mul
			end

			for weapon, falloff_tier in pairs(preset.FALLOFF) do
				falloff_tier.dmg_mul = falloff_tier.dmg_mul * current_dmg_mul
			end
		end
	end

	self.team_ai_perk_damage_mul = teamai_mul
	self.spooc.kick_damage = multiply_raw_damage(self.spooc.kick_damage, mul)
	self.spooc.jump_kick_damage = multiply_raw_damage(self.spooc.jump_kick_damage, mul)
	self.taser.shock_damage = multiply_raw_damage(self.taser.shock_damage, mul)
end

function CharacterTweakData:_multiply_teamai_health(mul, grace_period)
	self.presets.gang_member_damage.HEALTH_INIT = self.presets.gang_member_damage.HEALTH_INIT * mul
	self.presets.gang_member_damage.MIN_DAMAGE_INTERVAL = grace_period
	self.old_hoxton_mission.HEALTH_INIT = self.presets.gang_member_damage.HEALTH_INIT
	self.spa_vip.HEALTH_INIT = self.presets.gang_member_damage.HEALTH_INIT
end