Month = os.date("%m")
Day = os.date("%d")	

--///LEVEL TYPES\\\--
--The distinction of "NYPD" and "LAPD" is defunct in HEAT.  Internal names don't need to reflect this, but they no longer conform to the specific 'region' dictated by the title.  IE: we might use classics (NYPD) on stuff like Alaskan Deal.

LevelsTweakData.LevelType = {}
LevelsTweakData.LevelType.America = "america"
LevelsTweakData.LevelType.Russia = "russia"
LevelsTweakData.LevelType.Zombie = "zombie"
LevelsTweakData.LevelType.Murkywater = "murkywater"
LevelsTweakData.LevelType.Federales = "federales"
LevelsTweakData.LevelType.NYPD = "nypd"
LevelsTweakData.LevelType.LAPD = "lapd"
--///LEVELS\\\--
Hooks:PostHook( LevelsTweakData, "init", "SC_levels", function(self)
	
	local america = LevelsTweakData.LevelType.America
	local russia = LevelsTweakData.LevelType.Russia
	local zombie = LevelsTweakData.LevelType.Zombie
	local murkywater = LevelsTweakData.LevelType.Murkywater
	local nypd = LevelsTweakData.LevelType.NYPD
	local federales = LevelsTweakData.LevelType.Federales		
	local lapd = LevelsTweakData.LevelType.LAPD
	self.ai_groups = {}
	self.ai_groups.default = america
	self.ai_groups.america = america
	self.ai_groups.russia = russia
	self.ai_groups.zombie  = zombie
	self.ai_groups.murkywater = murkywater
	self.ai_groups.federales = federales
	self.ai_groups.nypd = nypd
	self.ai_groups.lapd = lapd
	
	--Christmas Dozer/Cloaker jingle bells
	if heat and heat.Options:GetValue("Holiday") then
		if Month == 12 then
			if not PackageManager:loaded("packages/event_xmas") then
				PackageManager:load("packages/event_xmas")
			end		
			
			for lvl_id, lvl_data in pairs(self) do
				if type(lvl_data) == "table" and lvl_data.name_id then
					self[lvl_id].is_christmas_heist = true
				end
			end					
		end
	end
	
	--///MEXICAN LEVELS\\\--
	self.bex.package = {"packages/mexicoassets", "packages/job_bex"}
	
	self.skm_bex.package = {"packages/mexicoassets", "packages/dlcs/skm/job_bex_skm"}

	self.mex_cooking.package = {"packages/mexicoassets", "levels/narratives/h_alex_must_die/stage_1/world_sounds", "levels/narratives/vlad/bex/world_sounds", "packages/job_bex", "packages/job_mex2"}
	self.mex_cooking.ai_group_type = federales
	
	self.pex.package = {"packages/mexicoassets", "packages/job_pex"}
	
	self.fex.package = {"packages/mexicoassets", "packages/job_fex"}
	
	--///MURKYWATER LEVELS\\\--
	self.shoutout_raid.package = {"packages/murkyassets", "packages/vlad_shout"}
	self.shoutout_raid.ai_group_type = murkywater
	
	self.pbr.package = {"packages/murkyassets", "packages/narr_jerry1"}
	self.pbr.ai_group_type = murkywater
	
	self.des.package = {"packages/murkyassets", "packages/job_des"}
	self.des.ai_group_type = murkywater 
	
	self.bph.package = {"packages/murkyassets", "packages/dlcs/bph/job_bph"}
	self.bph.ai_group_type = murkywater
	
	self.vit.package = {"packages/murkyassets", "packages/dlcs/vit/job_vit"}
	self.vit.ai_group_type = murkywater 
	
	self.arm_for.package = {"packages/murkyassets", "packages/narr_arm_for"}
	self.arm_for.ai_group_type = murkywater
	
	self.mex.package = {"packages/murkyassets", "levels/narratives/h_alex_must_die/stage_1/world_sounds", "packages/job_mex"}
	self.mex.ai_group_type = murkywater

	self.crojob2.package = {"packages/dlcs/the_bomb/crojob_stage_2", "packages/murkyassets"}
	self.crojob2.ai_group_type = murkywater

	self.dark.package = {"packages/job_dark", "packages/murkyassets"}
	self.dark.ai_group_type = murkywater
	
	self.kosugi.package = {"packages/kosugi", "packages/murkyassets"}
	self.kosugi.ai_group_type = murkywater		
	
	--///"NYPD" LEVELS\\\--
	self.spa.ai_group_type = nypd
	self.spa.package = {"packages/job_spa", "packages/nypdassets", "levels/narratives/dentist/mia/stage2/world_sounds"}
	
	self.brb.ai_group_type = nypd
	self.brb.package = {"packages/lvl_brb", "packages/nypdassets"}
	
	self.red2.ai_group_type = nypd
	self.red2.package = {"packages/narr_red2", "packages/nypdassets"}
	
	self.run.ai_group_type = nypd
	self.run.package = {"packages/narr_run", "packages/nypdassets"}
	
	self.flat.ai_group_type = nypd
	self.flat.package = {"packages/narr_flat", "packages/nypdassets"}
	
	self.wwh.package = {"packages/nypdassets", "packages/lvl_wwh"}
	self.wwh.ai_group_type = nypd
	
	self.mus.ai_group_type = nypd
	
	self.framing_frame_1.package = {"packages/nypdassets", "packages/narr_framing_1"}
	self.framing_frame_1.ai_group_type = nypd
	
	self.framing_frame_2.package = {"packages/nypdassets", "packages/narr_framing_3"}
	self.framing_frame_2.ai_group_type = nypd

	self.framing_frame_3.package = {"packages/nypdassets", "packages/narr_framing_3"}
	self.framing_frame_3.ai_group_type = nypd
	
	self.arena.package = {"packages/nypdassets", "packages/narr_arena"}
	self.arena.ai_group_type = nypd
	
	self.arm_hcm.package = {"packages/nypdassets", "packages/narr_arm_hcm"}
	self.arm_hcm.ai_group_type = nypd
	
	self.arm_und.package = {"packages/nypdassets", "packages/narr_arm_und"}
	self.arm_und.ai_group_type = nypd
	
	self.glace.ai_group_type = nypd
	self.glace.package = {"packages/narr_glace", "packages/nypdassets"}
	
	self.dah.ai_group_type = nypd
	self.dah.package = {"packages/lvl_dah", "packages/nypdassets"}
	
	self.dinner.ai_group_type = nypd
	self.dinner.package = {"packages/narr_dinner", "packages/nypdassets", "packages/miscassets", "packages/slaughter_murky"}
	
	self.man.package = {"packages/narr_man", "packages/secret_stash"}
	self.man.teams = {
		criminal1 = {
			foes = {
				law1 = true,
				mobster1 = true
			},
			friends = {
				converted_enemy = true
			}
		},
		law1 = {
			foes = {
				converted_enemy = true,
				criminal1 = true,
				hacked_turret = true
			},
			friends = {
				mobster1 = true
			}
		},
		mobster1 = {
			foes = {
				converted_enemy = true,
				criminal1 = true,
				hacked_turret = true
			},
			friends = {
				law1 = true
			}
		},
		converted_enemy = {
			foes = {
				law1 = true,
				mobster1 = true
			},
			friends = {
				criminal1 = true
			}
		},
		neutral1 = {
			foes = {},
			friends = {}
		},
		hacked_turret = {
			foes = {
				law1 = true,
				mobster1 = true
			},
			friends = {}
		}
	}
	
	self.jolly.ai_group_type = nypd
	self.jolly.package = {"packages/jolly", "levels/narratives/dentist/mia/stage2/world_sounds", "packages/nypdassets"}
	
	self.pal.ai_group_type = nypd
	self.pal.package = {"packages/narr_pal", "packages/nypdassets"}	
	
	self.kenaz.ai_group_type = nypd
	self.kenaz.package = {"packages/kenaz", "packages/rex_gold", "packages/nypdassets"}
	
	self.rvd1.ai_group_type = nypd
	self.rvd1.package = {"packages/job_rvd", "packages/nypdassets"}
	
	self.rvd2.ai_group_type = nypd
	self.rvd2.package = {"packages/job_rvd2", "packages/nypdassets"}
	
	self.nmh.ai_group_type = nypd
	self.nmh.package = {"packages/dlcs/nmh/job_nmh", "packages/nypdassets"}
	self.nmh.ghost_bonus = nil
	
	self.skm_run.ai_group_type = nypd
	self.skm_run.package = {"packages/dlcs/skm/job_skm", "packages/nypdassets"}
	
	self.skm_red2.ai_group_type = nypd
	self.skm_red2.package = {"packages/dlcs/skm/job_skm", "packages/nypdassets"}
	
	--///LAPD LEVELS\\\--			
	--self.friend.ai_group_type = lapd
	self.friend.package = {"levels/narratives/h_alex_must_die/stage_1/world_sounds", "packages/lvl_friend"} --, "packages/lapdassets"}
	
	--self.chas.ai_group_type = lapd
	self.chas.package = {"packages/job_chas"} --, "packages/lapdassets"}

	self.hox_2.package = {"packages/narr_hox_2", "packages/hoxout_2"}
	
	self.welcome_to_the_jungle_2.package = {"packages/narr_jungle2", "packages/murkyassets",}
	self.welcome_to_the_jungle_2.ai_group_type = murkywater

	self.pbr2.package = {"packages/narr_jerry2", "packages/miscassets"}

	self.mia_2.teams = {
		criminal1 = {
			foes = {
				mobster_boss = true,
				law1 = true,
				mobster1 = true
			},
			friends = {
				converted_enemy = true
			}
		},
		law1 = {
			foes = {
				converted_enemy = true,
				criminal1 = true,
				mobster1 = true,
				hacked_turret = true
			},
			friends = {}
		},
		mobster1 = {
			foes = {
				converted_enemy = true,
				law1 = true,
				criminal1 = true,
				hacked_turret = true
			},
			friends = {}
		},
		mobster_boss = {
			foes = {
				converted_enemy = true,
				criminal1 = true,
				hacked_turret = true
			},
			friends = {}
		},
		converted_enemy = {
			foes = {
				mobster_boss = true,
				law1 = true,
				mobster1 = true
			},
			friends = {
				criminal1 = true
			}
		},
		neutral1 = {
			foes = {},
			friends = {}
		},
		hacked_turret = {
			foes = {
				law1 = true,
				mobster1 = true,
				mobster_boss = true
			},
			friends = {}
		}
	}

	self.mia2_new.teams = self.mia_2.teams

	self.cane.package = {"packages/cane", "levels/narratives/e_welcome_to_the_jungle/stage_1/world_sounds"}
							
	self.mus.package = {"packages/nypdassets", "packages/narr_mus"}
	
	--///GANGSTER VOICEOVER\\\--
	self.short2_stage1.package = {"packages/job_short2_stage1", "levels/narratives/dentist/mia/stage2/world_sounds"}
	self.nightclub.package = {"packages/vlad_nightclub", "levels/narratives/dentist/mia/stage2/world_sounds"}
	
	--//CHRISTMAS HEISTS\\--
	
	--hoxton breakout xmas day 1
	table.insert(self._level_index, "xmn_hox1")
	
	self.xmn_hox1 = {
		name_id = "heist_xmn_hox1",
		briefing_id = "heist_hox_1_briefing",
		briefing_dialog = "Play_pln_hb1_brf_01",
		world_name = "narratives/dentist/hox/stage_1_xmn",
		intro_event = "Play_pln_hb1_intro_01",
		outro_event = {
			"Play_pln_hb1_end_01"
		},
		music = "heist",
		package = "packages/narr_hox_1",
		cube = "cube_apply_heist_bank",
		block_AIs = {
			old_hoxton = true
		},
		ai_group_type = america,
		load_screen = "guis/dlcs/xmn/textures/loading/job_hox_1_xmn_df"
	}

	--hoxton breakout xmas day 2
	table.insert(self._level_index, "xmn_hox2")

	self.xmn_hox2 = {
		name_id = "heist_xmn_hox2",
		briefing_id = "heist_hox_2_briefing",
		briefing_dialog = "Play_rb5_hb2_brf_01",
		world_name = "narratives/dentist/hox/stage_2_xmn",
		intro_event = "Play_rb5_hb2_intro_01",
		outro_event = {
			"Play_rb5_hb2_end_01"
		},
		music = "heist",
		package = "packages/narr_hox_2",
		cube = "cube_apply_heist_bank",
		block_AIs = {
			old_hoxton = true
		},
		ai_group_type = america,
		load_screen = "guis/dlcs/xmn/textures/loading/job_hox_2_xmn_df"
	}
	
	--breakin' feds xmas
	table.insert(self._level_index, "xmn_tag")
	self.xmn_tag = deep_clone(self.tag)
	self.xmn_tag.name_id = "heist_xmn_tag_name"
	self.xmn_tag.world_name = "narratives/locke/tag_xmn"
	self.xmn_tag.load_screen = "guis/dlcs/xmn/textures/loading/job_tag_xmn_df"
	
	--///ZOMBIE LEVELS\\\--
	self.haunted.package = {"packages/zombieassets", "packages/narr_haunted", "packages/narr_hvh", "levels/narratives/bain/hvh/world_sounds"}
	self.nail.package = {"packages/zombieassets", "packages/job_nail", "packages/narr_hvh", "levels/narratives/bain/hvh/world_sounds"}
	self.help.package = {"packages/zombieassets", "packages/lvl_help", "packages/narr_hvh", "levels/narratives/bain/hvh/world_sounds"}
	self.hvh.package = {"packages/zombieassets", "packages/narr_hvh"}
	
	self.haunted.ai_group_type = zombie		
	self.nail.ai_group_type = zombie
	self.help.ai_group_type = zombie

	--///SAFEHOUSE\\\--
	self.chill.ghost_bonus = nil
	
	self.cage.ghost_bonus = nil
	
	self.mallcrasher.ghost_bonus = 0.05
	
	--///REAPER LEVELS\\\--
	self.mad.package = {"packages/akanassets", "packages/lvl_mad"}
	--We're never actually told where the forest is ;)
	self.pines.package = {"packages/narr_pines", "packages/akanassets", "packages/lvl_mad"}
	self.pines.ai_group_type = russia	
	
	--Bomb: Forest--
	self.crojob3.package = {"packages/dlcs/the_bomb/crojob_stage_3", "packages/akanassets", "packages/lvl_mad"}
	self.crojob3.ai_group_type = russia

	self.crojob3_night.package = {"packages/dlcs/the_bomb/crojob_stage_3_night", "packages/akanassets", "packages/lvl_mad"}
	self.crojob3_night.ai_group_type = russia
	
	--///BAG FIXES\\\--
	self.pbr2.max_bags = 20
	self.spa.max_bags = 8
	self.fish.max_bags = 20
	--White House Heist Stelf Bonus--		
	self.vit.ghost_bonus = 0.15
	
	--///SKIRMISH FIXES\\\--
	self.skm_cas.package = {"packages/dlcs/skm/job_skm"}

	self.ukrainian_job.env_params = {color_grading = "color_nice"}
end)

function LevelsTweakData:get_ai_group_type()
	if managers.mutators and managers.mutators:is_mutator_active(MutatorFactionsReplacer) then
		local MutatorCheck = managers.mutators:get_mutator(MutatorFactionsReplacer) or nil
		if MutatorCheck and MutatorCheck:get_faction_override() and MutatorCheck:get_faction_override() == "america" then
			return self.ai_groups.america
		elseif MutatorCheck and MutatorCheck:get_faction_override() and MutatorCheck:get_faction_override() == "russia" then
			if not PackageManager:loaded("packages/akanassets") then
				PackageManager:load("packages/akanassets")
			end
			if not PackageManager:loaded("packages/akanassetsnew") then
				PackageManager:load("packages/akanassetsnew")
			end
			if not PackageManager:loaded("levels/narratives/elephant/mad/world_sounds") then
				PackageManager:load("levels/narratives/elephant/mad/world_sounds")
			end
			return self.ai_groups.russia
		elseif MutatorCheck and MutatorCheck:get_faction_override() and MutatorCheck:get_faction_override() == "murkywater" then
			if not PackageManager:loaded("packages/murkyassets") then
				PackageManager:load("packages/murkyassets")
			end
			if not PackageManager:loaded("levels/narratives/locke/bph/world_sounds") then
				PackageManager:load("levels/narratives/locke/bph/world_sounds")
			end
			return self.ai_groups.murkywater
		end
	else
		local level_data = Global.level_data and Global.level_data.level_id and self[Global.level_data.level_id]

		if level_data then
			local ai_group_type = level_data.ai_group_type
			
			if ai_group_type then
				return ai_group_type
			end
		end
		return self.ai_groups.default
	end
end

function LevelsTweakData:get_team_setup()
	local lvl_tweak = nil

	if not Application:editor() or not managers.editor or self[managers.editor:layer("Level Settings"):get_setting("simulation_level_id")] then
		if Global.level_data and Global.level_data.level_id then
			lvl_tweak = self[Global.level_data.level_id]
		end
	end

	local teams = lvl_tweak and lvl_tweak.teams

	if teams then
		teams = deep_clone(teams)
	else
		teams = {
			criminal1 = {
				foes = {
					law1 = true,
					mobster1 = true
				},
				friends = {
					converted_enemy = true
				}
			},
			law1 = {
				foes = {
					converted_enemy = true,
					criminal1 = true,
					mobster1 = true,
					hacked_turret = true
				},
				friends = {}
			},
			mobster1 = {
				foes = {
					converted_enemy = true,
					law1 = true,
					criminal1 = true,
					hacked_turret = true
				},
				friends = {}
			},
			converted_enemy = {
				foes = {
					law1 = true,
					mobster1 = true
				},
				friends = {
					criminal1 = true
				}
			},
			neutral1 = {
				foes = {},
				friends = {}
			},
			hacked_turret = {
				foes = {
					law1 = true,
					mobster1 = true
				},
				friends = {}
			}
		}

		for id, team in pairs(teams) do
			team.id = id
		end
	end

	return teams
end