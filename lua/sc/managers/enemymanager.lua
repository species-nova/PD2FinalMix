local mvec3_dir = mvector3.direction
local mvec3_dot = mvector3.dot
local mvec3_dis = mvector3.distance

local tmp_vec1 = Vector3()

local t_fv = table.find_value
local math_random = math.random
local pairs_g = pairs

local world_g = World
local alive_g = alive

function EnemyManager:init()
	self:_init_enemy_data()

	self._unit_clbk_key = "EnemyManager"
	self._corpse_disposal_upd_interval = 5
	self._shield_disposal_upd_interval = 15
	self._shield_disposal_lifetime = 60
	self._MAX_NR_SHIELDS = 8
	self._queue_buffer = 0
	self._registered_summers_crew = {}
	self._summers = {} -- for compatibility in case multiple summersers spawn somehow.
end

function EnemyManager:register_summers(summers)
	if self._summers then
		self._summers[#self._summers + 1] = summers
	else
		self._summers = {}
		self._summers[#self._summers + 1] = summers
	end
end

function EnemyManager:register_summers_crew(unit)
	if self._registered_summers_crew then
		self._registered_summers_crew[#self._registered_summers_crew + 1] = unit
	else
		self._registered_summers_crew = {}
		self._registered_summers_crew[#self._registered_summers_crew + 1] = unit
	end
end

function EnemyManager:on_enemy_unregistered(unit)
	self._enemy_data.nr_units = self._enemy_data.nr_units - 1

	managers.groupai:state():on_enemy_unregistered(unit)
	
	local summers = self._summers
	
	if summers then
		for i = 1, #summers do
			local summer = summers[i]
			if summer:key() == unit:key() then --was tempted to local the unit and name it sumers just to make everyone reading this feel like i sprayed their eyes with onion liquid
				table.remove(summers, i)
				break
			end
		end
	end
	
	local summers_crew = self._registered_summers_crew
	
	if summers_crew then
		for i = 1, #summers_crew do
			local enemy = summers_crew[i]
			if enemy:key() == unit:key() then
				table.remove(summers_crew, i)
				break
			end
		end
	end
end

function EnemyManager:_update_gfx_lod()
	local gfx_lod_data = self._gfx_lod_data

	if not gfx_lod_data.enabled or not managers.navigation:is_data_ready() then
		return
	end

	local player = managers.player:player_unit()
	local --[[pl_tracker,]] cam_pos, cam_fwd = nil

	if player then
		--pl_tracker = player:movement():nav_tracker()
		cam_pos = player:movement():m_head_pos()
		cam_fwd = player:camera():forward()
	elseif managers.viewport:get_current_camera() then
		cam_pos = managers.viewport:get_current_camera_position()
		cam_fwd = managers.viewport:get_current_camera_rotation():y()
	end

	if not cam_fwd then
		return
	end

	local entries = gfx_lod_data.entries
	local units = entries.units
	local states = entries.states
	local move_ext = entries.move_ext
	local trackers = entries.trackers
	local com = entries.com
	--local chk_vis_func = pl_tracker and pl_tracker.check_visibility
	--local unit_occluded = Unit.occluded
	local occ_manager = managers.occlusion
	local is_occluded = occ_manager.is_occluded
	local world_in_view_with_options = world_g.in_view_with_options

	for i = 1, #states do
		local state = states[i]

		if not state then
			--[[local visible = nil

			if occ_skip_units[units[i]:key()] then
				visible = true
			elseif not unit_occluded(units[i]) then
				if not pl_tracker or chk_vis_func(pl_tracker, trackers[i]) then
					visible = true
				end
			end]]

			local unit = units[i]

			if not is_occluded(occ_manager, unit) and world_in_view_with_options(world_g, com[i], 0, 110, 18000) then
				states[i] = 3

				unit:base():set_visibility_state(3)
			--else
				--unit:base():set_visibility_state(false)
			end
		end
	end

	if #states < 1 then
		return
	end

	local anim_lod = managers.user:get_setting("video_animation_lod")
	local nr_lod_1 = self._nr_i_lod[anim_lod][1]
	local nr_lod_2 = self._nr_i_lod[anim_lod][2]
	local nr_lod_total = nr_lod_1 + nr_lod_2
	local imp_i_list = gfx_lod_data.prio_i
	local imp_wgt_list = gfx_lod_data.prio_weights
	local nr_entries = #states
	local i = gfx_lod_data.next_chk_prio_i

	if nr_entries < i then
		i = 1
	end

	local start_i = i

	repeat
		if states[i] then
			--[[local not_visible = nil

			if not occ_skip_units[units[i]:key()] then
				if unit_occluded(units[i]) or pl_tracker and not chk_vis_func(pl_tracker, trackers[i]) then
					not_visible = true
				end
			end]]

			if is_occluded(occ_manager, units[i]) or not world_in_view_with_options(world_g, com[i], 0, 120, 18000) then
				states[i] = false

				units[i]:base():set_visibility_state(false)
				self:_remove_i_from_lod_prio(i, anim_lod)

				gfx_lod_data.next_chk_prio_i = i + 1

				break
			else
				local my_wgt = mvec3_dir(tmp_vec1, cam_pos, com[i])
				local dot = mvec3_dot(tmp_vec1, cam_fwd)
				local previous_prio = nil

				for prio = 1, #imp_i_list do
					local i_entry = imp_i_list[prio]

					if i == i_entry then
						previous_prio = prio

						break
					end
				end

				my_wgt = my_wgt * my_wgt * (1 - dot)
				local i_wgt = #imp_wgt_list

				while i_wgt > 0 do
					if previous_prio ~= i_wgt and imp_wgt_list[i_wgt] <= my_wgt then
						break
					end

					i_wgt = i_wgt - 1
				end

				if not previous_prio or i_wgt <= previous_prio then
					i_wgt = i_wgt + 1
				end

				if i_wgt ~= previous_prio then
					if previous_prio then
						local nr_imp_wgt_list = #imp_wgt_list
						local nr_imp_i_list = #imp_i_list
						local new_imp_wgt_list_table, new_imp_i_list_table = {}, {}

						for idx = 1, previous_prio - 1 do
							new_imp_wgt_list_table[#new_imp_wgt_list_table + 1] = imp_wgt_list[idx]
						end

						for idx = previous_prio + 1, nr_imp_wgt_list do
							new_imp_wgt_list_table[#new_imp_wgt_list_table + 1] = imp_wgt_list[idx]
						end

						for idx = 1, previous_prio - 1 do
							new_imp_i_list_table[#new_imp_i_list_table + 1] = imp_i_list[idx]
						end

						for idx = previous_prio + 1, nr_imp_i_list do
							new_imp_i_list_table[#new_imp_i_list_table + 1] = imp_i_list[idx]
						end

						imp_wgt_list = new_imp_wgt_list_table
						imp_i_list = new_imp_i_list_table

						gfx_lod_data.prio_weights = new_imp_wgt_list_table
						gfx_lod_data.prio_i = new_imp_i_list_table

						if previous_prio <= nr_lod_1 and nr_lod_1 < i_wgt and nr_lod_1 <= #imp_i_list then
							local promote_i = imp_i_list[nr_lod_1]
							states[promote_i] = 1

							units[promote_i]:base():set_visibility_state(1)
						elseif nr_lod_1 < previous_prio and i_wgt <= nr_lod_1 then
							local denote_i = imp_i_list[nr_lod_1]
							states[denote_i] = 2

							units[denote_i]:base():set_visibility_state(2)
						end
					elseif i_wgt <= nr_lod_total and #imp_i_list == nr_lod_total then
						local kick_i = imp_i_list[nr_lod_total]
						states[kick_i] = 3

						units[kick_i]:base():set_visibility_state(3)

						local nr_imp_wgt_list = #imp_wgt_list
						local nr_imp_i_list = #imp_i_list
						local new_imp_wgt_list_table = {}
						local new_imp_i_list_table = {}

						for idx = 1, nr_imp_wgt_list - 1 do
							new_imp_wgt_list_table[#new_imp_wgt_list_table + 1] = imp_wgt_list[idx]
						end

						for idx = 1, nr_imp_i_list - 1 do
							new_imp_i_list_table[#new_imp_i_list_table + 1] = imp_i_list[idx]
						end

						imp_wgt_list = new_imp_wgt_list_table
						imp_i_list = new_imp_i_list_table

						gfx_lod_data.prio_weights = new_imp_wgt_list_table
						gfx_lod_data.prio_i = new_imp_i_list_table
					end

					local lod_stage = nil

					if i_wgt <= nr_lod_total then
						local nr_imp_wgt_list = #imp_wgt_list
						local nr_imp_i_list = #imp_i_list
						local new_imp_wgt_list_table, new_imp_i_list_table = {}, {}

						for idx = 1, i_wgt - 1 do
							new_imp_wgt_list_table[#new_imp_wgt_list_table + 1] = imp_wgt_list[idx]
						end

						new_imp_wgt_list_table[#new_imp_wgt_list_table + 1] = my_wgt

						for idx = i_wgt, nr_imp_wgt_list do
							new_imp_wgt_list_table[#new_imp_wgt_list_table + 1] = imp_wgt_list[idx]
						end

						for idx = 1, i_wgt - 1 do
							new_imp_i_list_table[#new_imp_i_list_table + 1] = imp_i_list[idx]
						end

						new_imp_i_list_table[#new_imp_i_list_table + 1] = i

						for idx = i_wgt, nr_imp_i_list do
							new_imp_i_list_table[#new_imp_i_list_table + 1] = imp_i_list[idx]
						end

						imp_wgt_list = new_imp_wgt_list_table
						imp_i_list = new_imp_i_list_table

						gfx_lod_data.prio_weights = new_imp_wgt_list_table
						gfx_lod_data.prio_i = new_imp_i_list_table

						if i_wgt <= nr_lod_1 then
							lod_stage = 1
						else
							lod_stage = 2
						end
					else
						lod_stage = 3

						self:_remove_i_from_lod_prio(i, anim_lod)
					end

					if states[i] ~= lod_stage then
						states[i] = lod_stage

						units[i]:base():set_visibility_state(lod_stage)
					end
				end

				gfx_lod_data.next_chk_prio_i = i + 1

				break
			end
		end

		if i == nr_entries then
			i = 1
		else
			i = i + 1
		end
	until i == start_i
end

function EnemyManager:_remove_i_from_lod_prio(i, anim_lod)
	anim_lod = anim_lod or managers.user:get_setting("video_animation_lod")
	local nr_i_lod1 = self._nr_i_lod[anim_lod][1]
	local gfx_lod_data = self._gfx_lod_data
	local imp_i_list = gfx_lod_data.prio_i

	for prio = 1, #imp_i_list do
		local i_entry = imp_i_list[prio]

		if i == i_entry then
			local imp_wgt_list = gfx_lod_data.prio_weights
			local nr_imp_i_list = #imp_i_list
			local nr_imp_wgt_list = #imp_wgt_list
			--make new tables without the index
			local new_imp_i_list_table, new_imp_wgt_list_table = {}, {}

			for idx = 1, prio - 1 do
				new_imp_i_list_table[#new_imp_i_list_table + 1] = imp_i_list[idx]
			end

			for idx = prio + 1, nr_imp_i_list do
				new_imp_i_list_table[#new_imp_i_list_table + 1] = imp_i_list[idx]
			end

			for idx = 1, prio - 1 do
				new_imp_wgt_list_table[#new_imp_wgt_list_table + 1] = imp_wgt_list[idx]
			end

			for idx = prio + 1, nr_imp_wgt_list do
				new_imp_wgt_list_table[#new_imp_wgt_list_table + 1] = imp_wgt_list[idx]
			end

			if prio <= nr_i_lod1 and nr_i_lod1 < #new_imp_i_list_table then
				local promoted_i_entry = new_imp_i_list_table[prio]
				gfx_lod_data.entries.states[promoted_i_entry] = 1

				gfx_lod_data.entries.units[promoted_i_entry]:base():set_visibility_state(1)
			end

			gfx_lod_data.prio_i = new_imp_i_list_table
			gfx_lod_data.prio_weights = new_imp_wgt_list_table

			return
		end
	end
end

function EnemyManager:_create_unit_gfx_lod_data(unit)
	local lod_entries = self._gfx_lod_data.entries

	lod_entries.units[#lod_entries.units + 1] = unit
	lod_entries.states[#lod_entries.states + 1] = 1

	local mov_ext = unit:movement()

	lod_entries.move_ext[#lod_entries.move_ext + 1] = mov_ext
	lod_entries.trackers[#lod_entries.trackers + 1] = mov_ext:nav_tracker()
	lod_entries.com[#lod_entries.com + 1] = mov_ext:m_com()
end

function EnemyManager:_destroy_unit_gfx_lod_data(u_key, custom_vis_state)
	local gfx_lod_data = self._gfx_lod_data
	local lod_entries = gfx_lod_data.entries
	local units = lod_entries.units

	for i = 1, #units do
		local unit = units[i]

		if u_key == unit:key() then
			local states = lod_entries.states
			local fixed_vis_state = custom_vis_state == nil and 1 or custom_vis_state

			unit:base():set_visibility_state(fixed_vis_state)

			local nr_entries = #units

			self:_remove_i_from_lod_prio(i)

			local prio_i = gfx_lod_data.prio_i

			for prio = 1, #prio_i do
				local i_entry = prio_i[prio]

				if i_entry == nr_entries then
					prio_i[prio] = i

					break
				end
			end

			local mov_ext = lod_entries.move_ext
			local trackers = lod_entries.trackers
			local com = lod_entries.com

			units[i] = units[nr_entries]
			states[i] = states[nr_entries]
			mov_ext[i] = mov_ext[nr_entries]
			trackers[i] = trackers[nr_entries]
			com[i] = com[nr_entries]

			--make new tables without the entry
			local new_units_table, new_states_table, new_mov_ext_table, new_trackers_table, new_com_table = {}, {}, {}, {}, {}

			for idx = 1, nr_entries - 1 do
				new_units_table[#new_units_table + 1] = units[idx]
			end

			for idx = 1, nr_entries - 1 do
				new_states_table[#new_states_table + 1] = states[idx]
			end

			for idx = 1, nr_entries - 1 do
				new_mov_ext_table[#new_mov_ext_table + 1] = mov_ext[idx]
			end

			for idx = 1, nr_entries - 1 do
				new_trackers_table[#new_trackers_table + 1] = trackers[idx]
			end

			for idx = 1, nr_entries - 1 do
				new_com_table[#new_com_table + 1] = com[idx]
			end

			lod_entries.units = new_units_table
			lod_entries.states = new_states_table
			lod_entries.move_ext = new_mov_ext_table
			lod_entries.trackers = new_trackers_table
			lod_entries.com = new_com_table

			break
		end
	end
end

function EnemyManager:set_gfx_lod_enabled(state)
	local gfx_lod_data = self._gfx_lod_data

	if state then
		gfx_lod_data.enabled = state
	elseif gfx_lod_data.enabled then
		gfx_lod_data.enabled = state
		local entries = gfx_lod_data.entries
		local units = entries.units
		local states = entries.states

		for i = 1, #states do
			local lod_stage = states[i]

			if lod_stage ~= 1 then
				states[i] = 1

				units[i]:base():set_visibility_state(1)
			end
		end
	end
end

function EnemyManager:chk_any_unit_in_slotmask_visible(slotmask, cam_pos, cam_nav_tracker)
	local gfx_lod_data = self._gfx_lod_data

	if not gfx_lod_data.enabled or not managers.navigation:is_data_ready() then
		return
	end

	local entries = gfx_lod_data.entries
	local units = entries.units
	local states = entries.states
	local trackers = entries.trackers
	local move_exts = entries.move_ext
	local com = entries.com
	--local chk_vis_func = cam_nav_tracker and cam_nav_tracker.check_visibility
	--local unit_occluded = Unit.occluded
	--local occ_skip_units = managers.occlusion._skip_occlusion
	local occ_manager = managers.occlusion
	local is_occluded = occ_manager.is_occluded
	local vis_slotmask = managers.slot:get_mask("AI_visibility")

	for i = 1, #states do
		local unit = units[i]

		if unit:in_slot(slotmask) then
			--[[local visible = nil

			if occ_skip_units[unit:key()] then
				visible = true
			elseif not unit_occluded(unit) then
				if not cam_nav_tracker or chk_vis_func(cam_nav_tracker, trackers[i]) then
					visible = true
				end
			end]]

			if not is_occluded(occ_manager, unit) then
				local distance = mvec3_dis(cam_pos, com[i])

				if distance < 300 then
					return true
				elseif distance < 2000 then
					local u_m_head_pos = move_exts[i]:m_head_pos()
					local obstruction_ray = world_g:raycast("ray", cam_pos, u_m_head_pos, "slot_mask", vis_slotmask, "ray_type", "ai_vision", "report")

					if not obstruction_ray then
						return true
					else
						obstruction_ray = world_g:raycast("ray", cam_pos, com[i], "slot_mask", vis_slotmask, "ray_type", "ai_vision", "report")

						if not obstruction_ray then
							return true
						end
					end
				end
			end
		end
	end
end

function EnemyManager:queue_task(id, task_clbk, data, execute_t, verification_clbk, asap)
	if not execute_t and #self._queued_tasks < 1 and not self._queued_task_executed then
		--there are no queued tasks + no tasks were executed in this frame, execute this timerless task immediately

		self._queued_task_executed = true

		if verification_clbk then
			verification_clbk(id)
		end

		task_clbk(data)
	else
		local task_data = {
			clbk = task_clbk,
			id = id,
			data = data,
			t = execute_t,
			v_cb = verification_clbk,
			asap = asap
		}

		if not execute_t then
			--add timer-less tasks to the end of their table, the first one on the list is always the one to be executed on frame updates
			self._queued_tasks_no_t = self._queued_tasks_no_t or {}

			self._queued_tasks_no_t[#self._queued_tasks_no_t + 1] = task_data
		else
			local all_tasks = self._queued_tasks
			local nr_tasks = #all_tasks
			local new_i = nr_tasks

			--determine position in the table by checking the timers of all queued tasks
			while new_i > 0 and execute_t < all_tasks[new_i].t do
				new_i = new_i - 1
			end

			if new_i == nr_tasks then
				--new task goes all the way at the end of the table, no need to make a new one
				self._queued_tasks[#self._queued_tasks + 1] = task_data
			else
				--make a new table with the new task in it
				new_i = new_i + 1

				local new_tasks_table = {}

				for idx = 1, new_i - 1 do
					new_tasks_table[#new_tasks_table + 1] = all_tasks[idx]
				end

				new_tasks_table[#new_tasks_table + 1] = task_data

				for idx = new_i, nr_tasks do
					new_tasks_table[#new_tasks_table + 1] = all_tasks[idx]
				end

				self._queued_tasks = new_tasks_table
			end
		end
	end
end

function EnemyManager:update_queue_task(id, task_clbk, data, execute_t, verification_clbk, asap)
	local task_had_no_t = false
	local task_data, _ = t_fv(self._queued_tasks, function (td)
		return td.id == id
	end)

	--task wasn't in the normal table, check on the timer-less one
	if not task_data and self._queued_tasks_no_t then
		task_data, _ = t_fv(self._queued_tasks_no_t, function (td)
			return td.id == id
		end)

		if task_data then
			task_had_no_t = true
		end
	end

	if task_data then
		--needs moving as in, from having a timer to not having one, or viceversa, which would require it to be in the other table
		--or having a different timer than the original one, which would require its position in the table to be rearranged
		local needs_moving = nil

		--sending this as false means task_data.t won't be touched and the task won't be moved
		if execute_t ~= false then
			if execute_t and task_data.t then
				needs_moving = execute_t ~= task_data.t --original timer differs with new timer, needs relocation
				task_data.t = execute_t
			elseif execute_t then
				needs_moving = task_data.t == nil --task didn't have a timer
				task_data.t = execute_t
			else
				needs_moving = task_data.t and true --task had a timer
				task_data.t = nil
			end
		end

		task_data.clbk = task_clbk or task_data.clbk
		task_data.data = data or task_data.data
		task_data.v_cb = verification_clbk or task_data.v_cb
		task_data.asap = asap or task_data.asap

		if needs_moving then
			self:unqueue_task(id, task_had_no_t)
			self:queue_task(id, task_data.clbk, task_data.data, task_data.t, task_data.v_cb, task_data.asap)
		end
	end
end

function EnemyManager:unqueue_task(id, check_no_t)
	local all_tasks, use_no_t = nil

	if check_no_t then
		all_tasks = self._queued_tasks_no_t

		if not all_tasks then
			return
		end

		use_no_t = true
	else
		all_tasks = self._queued_tasks
	end

	local nr_tasks = #all_tasks
	local i = nr_tasks

	while i > 0 do
		if all_tasks[i].id == id then
			--make a new table without the task
			local new_tasks_table = {}

			for idx = 1, i - 1 do
				new_tasks_table[#new_tasks_table + 1] = all_tasks[idx]
			end

			for idx = i + 1, nr_tasks do
				new_tasks_table[#new_tasks_table + 1] = all_tasks[idx]
			end

			if use_no_t then
				self._queued_tasks_no_t = new_tasks_table
			else
				self._queued_tasks = new_tasks_table
			end

			return
		end

		i = i - 1
	end

	--should recurse and check on the other table
	if check_no_t == nil then
		self:unqueue_task(id, true)
	end
end

function EnemyManager:has_task(id, check_no_t)
	local tasks = nil

	if check_no_t then
		tasks = self._queued_tasks_no_t

		if not tasks then
			return false
		end
	else
		tasks = self._queued_tasks
	end

	local i = #tasks
	local count = 0

	while i > 0 do
		if tasks[i].id == id then
			count = count + 1
		end

		i = i - 1
	end

	return count > 0 and count or check_no_t == nil and self:has_task(id, true)
end

function EnemyManager:_execute_queued_task(i, no_t)
	local all_tasks = no_t and self._queued_tasks_no_t or self._queued_tasks
	local nr_tasks = #all_tasks
	local task = all_tasks[i]
	--make a new table without the executed task
	local new_tasks_table = {}

	for idx = 1, i - 1 do
		new_tasks_table[#new_tasks_table + 1] = all_tasks[idx]
	end

	for idx = i + 1, nr_tasks do
		new_tasks_table[#new_tasks_table + 1] = all_tasks[idx]
	end

	if no_t then
		self._queued_tasks_no_t = new_tasks_table
	else
		self._queued_tasks = new_tasks_table
	end

	self._queued_task_executed = true

	if task.v_cb then
		task.v_cb(task.id)
	end

	task.clbk(task.data)
end

function EnemyManager:_update_queued_tasks(t, dt)
	local out_of_buffer = nil

	--ignore tick rate during stealth for consistent detection (although indeed, at the cost of performance)
	--might not be needed due to other changes to the detection function in coplogicbase
	if managers.groupai:state():whisper_mode() then
		local all_tasks_no_t = self._queued_tasks_no_t

		--execute one timer-less task per frame
		if all_tasks_no_t and all_tasks_no_t[1] then
			self:_execute_queued_task(1, true)
		end

		local nr_tasks = #self._queued_tasks

		--since we're ordering them based on timers, if the first one on the table didn't expire, there's no need to keep checking
		--limit the amount of potential tasks to be executed in this frame based on the number of tasks when the loop started
		for i = 1, nr_tasks do
			if self._queued_tasks[1].t < t then
				self:_execute_queued_task(1)
			else
				break
			end
		end
	else
		self._queue_buffer = self._queue_buffer + dt
		local tick_rate = tweak_data.group_ai.ai_tick_rate

		if tick_rate <= self._queue_buffer then
			local all_tasks_no_t = self._queued_tasks_no_t

			--execute one timer-less task per frame
			if all_tasks_no_t and all_tasks_no_t[1] then
				self:_execute_queued_task(1, true)

				self._queue_buffer = self._queue_buffer - tick_rate

				if self._queue_buffer <= 0 then
					out_of_buffer = true
				end
			end

			if not out_of_buffer then
				local nr_tasks = #self._queued_tasks

				--since we're ordering them based on timers, if the first one on the table didn't expire, there's no need to keep checking
				--limit the amount of potential tasks to be executed in this frame based on the number of tasks when the loop started
				--that is, if the tick rate limit wasn't reached yet
				for i = 1, nr_tasks do
					if self._queued_tasks[1].t < t then
						self:_execute_queued_task(1)

						self._queue_buffer = self._queue_buffer - tick_rate

						if self._queue_buffer <= 0 then
							out_of_buffer = true

							break
						end
					else
						break
					end
				end
			end
		else
			out_of_buffer = true
		end

		if #self._queued_tasks == 0 then
			if not self._queued_tasks_no_t or #self._queued_tasks_no_t == 0 then
				self._queue_buffer = 0
			end
		end
	end

	--asap tasks are executed as usual, if no task was executed in this frame + tick rate allows it
	--the asap task with the lowest timer will be executed
	if not out_of_buffer and not self._queued_task_executed then
		local i_asap_task, asap_task_t = nil
		local all_tasks = self._queued_tasks

		for i = 1, #all_tasks do
			local task_data = all_tasks[i]

			if task_data.asap then
				if not asap_task_t or task_data.t < asap_task_t then
					i_asap_task = i
					asap_task_t = task_data.t
				end
			end
		end

		if i_asap_task then
			self:_execute_queued_task(i_asap_task)
		end
	end

	--this remains the same, execute the callback with the lowest timer (first in the table)
	--only one per frame update
	local all_clbks = self._delayed_clbks

	if all_clbks[1] and all_clbks[1][2] < t then
		local clbk = all_clbks[1][3]
		--make a new table without the executed callback
		local new_clbks_table = {}
		local nr_clbks = #all_clbks

		for idx = 2, nr_clbks do
			new_clbks_table[#new_clbks_table + 1] = all_clbks[idx]
		end

		self._delayed_clbks = new_clbks_table

		clbk()
	end
end

function EnemyManager:add_delayed_clbk(id, clbk, execute_t)
	local clbk_data = {
		id,
		execute_t,
		clbk
	}
	local all_clbks = self._delayed_clbks
	local nr_clbks = #all_clbks
	local i = nr_clbks

	while i > 0 and execute_t < all_clbks[i][2] do
		i = i - 1
	end

	if i == nr_clbks then
		--new callback goes all the way at the end of the table, no need to make a new one
		self._delayed_clbks[#self._delayed_clbks + 1] = clbk_data
	else
		--make a new table with the new callback in it
		i = i + 1

		local new_clbks_table = {}

		for idx = 1, i - 1 do
			new_clbks_table[#new_clbks_table + 1] = all_clbks[idx]
		end

		new_clbks_table[#new_clbks_table + 1] = clbk_data

		for idx = i, nr_clbks do
			new_clbks_table[#new_clbks_table + 1] = all_clbks[idx]
		end

		self._delayed_clbks = new_clbks_table
	end
end

function EnemyManager:remove_delayed_clbk(id, no_pause)
	local all_clbks = self._delayed_clbks
	local nr_clbks = #all_clbks
	local i = nr_clbks

	while i > 0 do
		if all_clbks[i][1] == id then
			local new_clbks_table = {}

			if i == 1 then
				--callback was at the beginning of the table, so just make a new table without it
				for idx = 2, nr_clbks do
					new_clbks_table[#new_clbks_table + 1] = all_clbks[idx]
				end
			else
				--make a new table without the callback
				for idx = 1, i - 1 do
					new_clbks_table[#new_clbks_table + 1] = all_clbks[idx]
				end

				for idx = i + 1, nr_clbks do
					new_clbks_table[#new_clbks_table + 1] = all_clbks[idx]
				end
			end

			self._delayed_clbks = new_clbks_table

			return
		end

		i = i - 1
	end
end

function EnemyManager:reschedule_delayed_clbk(id, execute_t)
	local all_clbks = self._delayed_clbks
	local nr_clbks = #all_clbks
	local clbk_data = nil
	local i = nr_clbks

	while i > 0 do
		if all_clbks[i][1] == id then
			clbk_data = all_clbks[i]

			break
		end

		i = i - 1
	end

	if clbk_data then
		self:remove_delayed_clbk(id)
		self:add_delayed_clbk(id, clbk_data[3], execute_t)
	end
end

function EnemyManager:force_delayed_clbk(id)
	local all_clbks = self._delayed_clbks
	local nr_clbks = #all_clbks
	local i = nr_clbks

	while i > 0 do
		if all_clbks[i][1] == id then
			local clbk = all_clbks[i][3]
			local new_clbks_table = {}

			if i == 1 then
				--callback was at the beginning of the table, so just make a new table without it
				for idx = 2, nr_clbks do
					new_clbks_table[#new_clbks_table + 1] = all_clbks[idx]
				end
			else
				--make a new table without the executed callback
				for idx = 1, i - 1 do
					new_clbks_table[#new_clbks_table + 1] = all_clbks[idx]
				end

				for idx = i + 1, nr_clbks do
					new_clbks_table[#new_clbks_table + 1] = all_clbks[idx]
				end
			end

			self._delayed_clbks = new_clbks_table

			clbk()

			return
		end

		i = i - 1
	end
end

function EnemyManager:on_enemy_died(dead_unit, damage_info)
	local u_key = dead_unit:key()
	local enemy_data = self._enemy_data
	local u_data = enemy_data.unit_data[u_key]

	if not u_data then
		u_data = {
			unit = dead_unit
		}
	end

	self:on_enemy_unregistered(dead_unit)

	enemy_data.unit_data[u_key] = nil

	managers.mission:call_global_event("enemy_killed")

	local corpse_disposal = self:is_corpse_disposal_enabled()

	if corpse_disposal and enemy_data.nr_corpses >= 0 and not self:has_task("EnemyManager._upd_corpse_disposal") then
		self:queue_task("EnemyManager._upd_corpse_disposal", EnemyManager._upd_corpse_disposal, self, self._t + self._corpse_disposal_upd_interval)
	end

	enemy_data.nr_corpses = enemy_data.nr_corpses + 1
	enemy_data.corpses[u_key] = u_data
	u_data.death_t = self._t

	self:_destroy_unit_gfx_lod_data(u_key, corpse_disposal and 4 - managers.user:get_setting("video_animation_lod") or nil)

	u_data.u_id = dead_unit:id()

	if corpse_disposal then
		Network:detach_unit(dead_unit)
	else
		--so that clients don't get sent to Brazil, where nothing despawns
		--basically this happens when trying to despawn a unit as client while they're still attached to the network and the server is authoritative on them
		--ammo bags used to cause it by setting the slot to 0 (despawn on the next frame) on a client but not on host due to decimals
		--medic bags and ECMs would technically be able to if not modified properly since they still set the slot to 0 for everyone instead of just the host
		self:_store_for_disposal_detach(u_key, dead_unit)
	end

	managers.hud:remove_waypoint("wp_hostage_trade" .. tostring(dead_unit:key()))
	managers.modifiers:run_func("OnEnemyDied", dead_unit, damage_info)
end

function EnemyManager:on_enemy_destroyed(enemy)
	local u_key = enemy:key()

	if self._units_to_detach then
		self._units_to_detach[u_key] = nil
	end

	local enemy_data = self._enemy_data

	if enemy_data.unit_data[u_key] then
		self:on_enemy_unregistered(enemy)

		enemy_data.unit_data[u_key] = nil

		self:_destroy_unit_gfx_lod_data(u_key, false)
	elseif enemy_data.corpses[u_key] then
		enemy_data.nr_corpses = enemy_data.nr_corpses - 1
		enemy_data.corpses[u_key] = nil

		if enemy_data.nr_corpses == 0 and self:is_corpse_disposal_enabled() then
			self:unqueue_task("EnemyManager._upd_corpse_disposal")
		end
	end
end

function EnemyManager:register_shield(shield_unit)
	local enemy_data = self._enemy_data

	if enemy_data.nr_shields >= 0 and self:is_corpse_disposal_enabled() and not self:has_task("EnemyManager._upd_shield_disposal") then
		self:queue_task("EnemyManager._upd_shield_disposal", EnemyManager._upd_shield_disposal, self, self._t + self._shield_disposal_upd_interval)
	end

	enemy_data.nr_shields = enemy_data.nr_shields + 1
	enemy_data.shields[shield_unit:key()] = {
		unit = shield_unit,
		death_t = self._t
	}
end

function EnemyManager:on_civilian_died(dead_unit, damage_info)
	local is_server = Network:is_server()

	if is_server and damage_info.attacker_unit and not dead_unit:base().enemy then
		managers.groupai:state():hostage_killed(damage_info.attacker_unit)
	end

	local u_key = dead_unit:key()
	local u_data = self._civilian_data.unit_data[u_key]

	if not u_data then
		u_data = {
			unit = dead_unit
		}
	end

	managers.groupai:state():on_civilian_unregistered(dead_unit)

	self._civilian_data.unit_data[u_key] = nil

	managers.mission:call_global_event("civilian_killed")

	local corpse_disposal = self:is_corpse_disposal_enabled()
	local enemy_data = self._enemy_data

	if corpse_disposal and enemy_data.nr_corpses >= 0 and not self:has_task("EnemyManager._upd_corpse_disposal") then
		self:queue_task("EnemyManager._upd_corpse_disposal", EnemyManager._upd_corpse_disposal, self, self._t + self._corpse_disposal_upd_interval)
	end

	enemy_data.nr_corpses = enemy_data.nr_corpses + 1
	enemy_data.corpses[u_key] = u_data
	u_data.death_t = self._t

	self:_destroy_unit_gfx_lod_data(u_key, corpse_disposal and 4 - managers.user:get_setting("video_animation_lod") or nil)

	u_data.u_id = dead_unit:id()

	if corpse_disposal then
		Network:detach_unit(dead_unit)
	else
		--so that clients don't get sent to Brazil, where nothing despawns
		--basically this happens when trying to despawn a unit as client while they're still attached to the network and the server is authoritative on them
		--ammo bags used to cause it by setting the slot to 0 (despawn on the next frame) on a client but not on host due to decimals
		--medic bags and ECMs would technically be able to if not modified properly since they still set the slot to 0 for everyone instead of just the host
		self:_store_for_disposal_detach(u_key, dead_unit)
	end

	managers.hud:remove_waypoint("wp_hostage_trade" .. tostring(dead_unit:key()))
end

function EnemyManager:on_civilian_destroyed(civilian)
	local u_key = civilian:key()

	if self._units_to_detach then
		self._units_to_detach[u_key] = nil
	end

	if self._civilian_data.unit_data[u_key] then
		managers.groupai:state():on_civilian_unregistered(civilian)

		self._civilian_data.unit_data[u_key] = nil

		self:_destroy_unit_gfx_lod_data(u_key, false)
	else
		local enemy_data = self._enemy_data

		if enemy_data.corpses[u_key] then
			enemy_data.nr_corpses = enemy_data.nr_corpses - 1
			enemy_data.corpses[u_key] = nil

			if enemy_data.nr_corpses == 0 and self:is_corpse_disposal_enabled() then
				self:unqueue_task("EnemyManager._upd_corpse_disposal")
			end
		end
	end
end

function EnemyManager:_store_for_disposal_detach(u_key, unit)
	self._units_to_detach = self._units_to_detach or {}

	self._units_to_detach[u_key] = unit
end

function EnemyManager:_chk_detach_stored_units()
	if self._units_to_detach then
		for u_key, unit in pairs_g(self._units_to_detach) do
			if alive_g(unit) then --still hasn't despawned
				Network:detach_unit(unit)
			end

			self._units_to_detach[u_key] = nil
		end

		self._units_to_detach = nil
	end
end

function EnemyManager:_upd_corpse_disposal()
	local t = self._t
	local enemy_data = self._enemy_data
	local nr_corpses = enemy_data.nr_corpses
	local disposals_needed = nr_corpses - self:corpse_limit()
	local corpses = enemy_data.corpses
	local player = managers.player:player_unit()
	local --[[pl_tracker,]] cam_pos, cam_fwd = nil

	if player then
		--pl_tracker = player:movement():nav_tracker()
		cam_pos = player:movement():m_head_pos()
		cam_fwd = player:camera():forward()
	elseif managers.viewport:get_current_camera() then
		cam_pos = managers.viewport:get_current_camera_position()
		cam_fwd = managers.viewport:get_current_camera_rotation():y()
	end

	local to_dispose = {}
	local nr_found = 0

	--[[if pl_tracker then
		for u_key, u_data in pairs_g(corpses) do
			local u_tracker = u_data.tracker

			--the game would dispose of corpses even if not really needed if you couldn't see them according to navigation
			--alas, the game just sets all visibility groups as visible with each other, the nav builder even has an option to do so
			if u_tracker and not pl_tracker:check_visibility(u_tracker) then
				to_dispose[u_key] = true
				nr_found = nr_found + 1
			end
		end
	end]]

	if disposals_needed > nr_found then
		if cam_pos then
			for u_key, u_data in pairs_g(corpses) do
				local u_pos = u_data.m_pos

				if --[[not to_dispose[u_key] and]] mvec3_dis(cam_pos, u_pos) > 300 and mvec3_dot(cam_fwd, u_pos - cam_pos) < 0 then
					to_dispose[u_key] = true
					nr_found = nr_found + 1

					if nr_found == disposals_needed then
						break
					end
				end
			end
		end

		if nr_found < disposals_needed then
			local oldest_u_key, oldest_t = nil

			for u_key, u_data in pairs_g(corpses) do
				if not oldest_t or u_data.death_t < oldest_t then
					if not to_dispose[u_key] then
						oldest_u_key = u_key
						oldest_t = u_data.death_t
					end
				end
			end

			if oldest_u_key then
				to_dispose[oldest_u_key] = true
				nr_found = nr_found + 1
			end
		end
	end

	for u_key, _ in pairs_g(to_dispose) do
		local u_data = corpses[u_key]
		local unit = u_data.unit

		if alive_g(unit) then
			unit:base():set_slot(unit, 0)
		end

		corpses[u_key] = nil
	end

	enemy_data.nr_corpses = nr_corpses - nr_found

	if nr_corpses > 0 then
		local delay = self:corpse_limit() < enemy_data.nr_corpses and 0 or self._corpse_disposal_upd_interval

		self:queue_task("EnemyManager._upd_corpse_disposal", EnemyManager._upd_corpse_disposal, self, t + delay)
	end
end

function EnemyManager:_upd_shield_disposal()
	local t = self._t
	local enemy_data = self._enemy_data
	local nr_shields = enemy_data.nr_shields
	local disposals_needed = nr_shields - self:shield_limit()
	local shields = enemy_data.shields
	local player = managers.player:player_unit()
	local cam_pos, cam_fwd = nil

	if player then
		cam_pos = player:movement():m_head_pos()
		cam_fwd = player:camera():forward()
	elseif managers.viewport:get_current_camera() then
		cam_pos = managers.viewport:get_current_camera_position()
		cam_fwd = managers.viewport:get_current_camera_rotation():y()
	end

	local to_dispose = {}
	local nr_found = 0

	if disposals_needed > nr_found then
		if cam_pos then
			for u_key, u_data in pairs_g(shields) do
				local dispose = false
				local unit = u_data.unit

				if alive_g(unit) then
					local u_pos = unit:position()

					if --[[not to_dispose[u_key] and]] t > u_data.death_t + self._shield_disposal_lifetime and mvec3_dis(cam_pos, u_pos) > 300 and mvec3_dot(cam_fwd, u_pos - cam_pos) < 0 then
						dispose = true
					end
				else
					dispose = true
					u_data.dead = true
				end

				if dispose then
					to_dispose[u_key] = true
					nr_found = nr_found + 1

					if nr_found == disposals_needed then
						break
					end
				end
			end
		end

		if nr_found < disposals_needed then
			local oldest_u_key, oldest_t = nil

			for u_key, u_data in pairs_g(shields) do
				local death_t = u_data.death_t

				if not oldest_t or death_t < oldest_t then
					if not to_dispose[u_key] then
						oldest_u_key = u_key
						oldest_t = death_t
					end
				end
			end

			if oldest_u_key then
				to_dispose[oldest_u_key] = true
				nr_found = nr_found + 1
			end
		end
	end

	for u_key, _ in pairs_g(to_dispose) do
		local u_data = shields[u_key]

		if not u_data.dead and alive_g(unit) then
			local unit = u_data.unit

			self:unregister_shield(unit)
			unit:set_slot(0)
		end

		shields[u_key] = nil
	end

	enemy_data.nr_shields = nr_shields - nr_found

	if enemy_data.nr_shields > 0 then
		local delay = self:shield_limit() < enemy_data.nr_shields and 0 or self._shield_disposal_upd_interval

		self:queue_task("EnemyManager._upd_shield_disposal", EnemyManager._upd_shield_disposal, self, t + delay)
	end
end

function EnemyManager:set_corpse_disposal_enabled(state)
	local was_enabled = self:is_corpse_disposal_enabled()
	local state_modifier = state and 1 or 0
	self._corpse_disposal_enabled = self._corpse_disposal_enabled + state_modifier
	local is_now_enabled = self:is_corpse_disposal_enabled()

	if was_enabled and not is_now_enabled then
		self:unqueue_task("EnemyManager._upd_corpse_disposal")
		self:unqueue_task("EnemyManager._upd_shield_disposal")
	elseif not was_enabled and is_now_enabled and self._enemy_data.nr_corpses > 0 then
		self:_chk_detach_stored_units()

		self:queue_task("EnemyManager._upd_corpse_disposal", EnemyManager._upd_corpse_disposal, self, self._t + self._corpse_disposal_upd_interval)
		self:queue_task("EnemyManager._upd_shield_disposal", EnemyManager._upd_shield_disposal, self, self._t + self._shield_disposal_upd_interval)
	end
end