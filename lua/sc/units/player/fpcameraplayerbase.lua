local mrot1 = Rotation()
local mrot2 = Rotation()
local mrot3 = Rotation()
local mvec1 = Vector3()
local mvec2 = Vector3()
local mvec3 = Vector3()

--Add limit constraints to recoil, to allow for recoil to occur with a bipod.
function FPCameraPlayerBase:_update_movement(t, dt)
	local data = self._camera_properties
	local new_head_pos = mvec2
	local new_shoulder_pos = mvec1
	local new_shoulder_rot = mrot1
	local new_head_rot = mrot2

	self._parent_unit:m_position(new_head_pos)

	if _G.IS_VR then
		local hmd_position = mvec1
		local mover_position = mvec3

		mvector3.set(mover_position, new_head_pos)
		mvector3.set(hmd_position, self._parent_movement_ext:hmd_position())
		mvector3.set(new_head_pos, self._parent_movement_ext:ghost_position())
		mvector3.set_x(hmd_position, 0)
		mvector3.set_y(hmd_position, 0)
		mvector3.add(new_head_pos, hmd_position)

		local mover_top = math.max(self._parent_unit:get_active_mover_offset() * 2, 45)

		mvector3.set_z(mover_position, mover_position.z + mover_top)

		self._output_data.mover_position = mvector3.copy(mover_position)

		self:_horizonatal_recoil_kick(t, dt)
		self:_vertical_recoil_kick(t, dt)
	else
		mvector3.add(new_head_pos, self._head_stance.translation)

		local stick_input_x = 0
		local stick_input_y = 0
		local aim_assist_x, aim_assist_y = self:_get_aim_assist(t, dt, self._tweak_data.aim_assist_snap_speed, self._aim_assist)
		stick_input_x = stick_input_x + self:_horizonatal_recoil_kick(t, dt) + aim_assist_x
		stick_input_y = stick_input_y + self:_vertical_recoil_kick(t, dt) + aim_assist_y
		local look_polar_spin = data.spin - stick_input_x
		local look_polar_pitch = math.clamp(data.pitch + stick_input_y, -85, 85)

		--Apply limits to recoil.
		if self._limits then
			if self._limits.spin then
				local d = (look_polar_spin - self._limits.spin.mid) / self._limits.spin.offset
				d = math.clamp(d, -1, 1)
				look_polar_spin = data.spin - math.lerp(stick_input_x, 0, math.abs(d))
			end

			if self._limits.pitch then
				local d = math.abs((look_polar_pitch - self._limits.pitch.mid) / self._limits.pitch.offset)
				d = math.clamp(d, -1, 1)
				look_polar_pitch = data.pitch + math.lerp(stick_input_y, 0, math.abs(d))
				look_polar_pitch = math.clamp(look_polar_pitch, -85, 85)
			end
		end

		if not self._limits or not self._limits.spin then
			look_polar_spin = look_polar_spin % 360
		end

		local look_polar = Polar(1, look_polar_pitch, look_polar_spin)
		local look_vec = look_polar:to_vector()
		local cam_offset_rot = mrot3

		mrotation.set_look_at(cam_offset_rot, look_vec, math.UP)
		mrotation.set_zero(new_head_rot)
		mrotation.multiply(new_head_rot, self._head_stance.rotation)
		mrotation.multiply(new_head_rot, cam_offset_rot)

		data.pitch = look_polar_pitch
		data.spin = look_polar_spin
		self._output_data.rotation = new_head_rot or self._output_data.rotation

		if self._camera_properties.current_tilt ~= self._camera_properties.target_tilt then
			self._camera_properties.current_tilt = math.step(self._camera_properties.current_tilt, self._camera_properties.target_tilt, 150 * dt)
		end

		if self._camera_properties.current_tilt ~= 0 then
			self._output_data.rotation = Rotation(self._output_data.rotation:yaw(), self._output_data.rotation:pitch(), self._output_data.rotation:roll() + self._camera_properties.current_tilt)
		end
	end

	self._output_data.position = new_head_pos

	mvector3.set(new_shoulder_pos, self._shoulder_stance.translation)
	mvector3.add(new_shoulder_pos, self._vel_overshot.translation)
	mvector3.rotate_with(new_shoulder_pos, self._output_data.rotation)
	mvector3.add(new_shoulder_pos, new_head_pos)
	mrotation.set_zero(new_shoulder_rot)
	mrotation.multiply(new_shoulder_rot, self._output_data.rotation)
	mrotation.multiply(new_shoulder_rot, self._shoulder_stance.rotation)
	mrotation.multiply(new_shoulder_rot, self._vel_overshot.rotation)
	self:set_position(new_shoulder_pos)
	self:set_rotation(new_shoulder_rot)
end


--Initializes recoil_kick values since they start null.
function FPCameraPlayerBase:start_shooting()
	self._recoil_kick.accumulated = self._recoil_kick.accumulated or 0 --Total amount of recoil to burn through in degrees.
	self._recoil_kick.h.accumulated = self._recoil_kick.h.accumulated or 0
end

--Adds pauses between shots in full auto fire.
--No longer triggers automatic recoil compensation.
function FPCameraPlayerBase:stop_shooting(wait)
	self._recoil_wait = wait or 0
end

--Add more recoil to burn through.
--Also no longer arbitrarily caps vertical recoil.
function FPCameraPlayerBase:recoil_kick(v, h, h2, v2)
	--Trick to allow vanilla styled calls.
	--All non-gun related calls into this follow the format of -/+/-/+ to follow down/up/left/right.
	--But since they have symmetric values (IE: PlayerIncapacitated does -2/2/-2/2), we can swap the last 2 args and get the same
	--end results. Guns, on the other hand, gain full control over their recoil behavior and just need to provide.
	--Their vertical and horizontal motions.
	if h2 and v2 then
		local lerp_x, lerp_y
		if not lerp_x then
			lerp_x = math.random()
			lerp_y = math.random()
		end
		v = math.lerp(v, v2, lerp_y)
		h = math.lerp(h, h2, lerp_x)
	end

	self._recoil_kick.accumulated = (self._recoil_kick.accumulated or 0) + v
	self._recoil_kick.h.accumulated = (self._recoil_kick.h.accumulated or 0) + h
end

--Simplified vanilla function to remove auto-correction weirdness.
function FPCameraPlayerBase:_vertical_recoil_kick(t, dt)
	local r_value = 0

	if self._recoil_kick.accumulated and self._episilon < math.abs(self._recoil_kick.accumulated) then
		--Scale degrees to move up if there's a large amount of accumulated recoil to prevent camera from obviously recoiling when not firing.
		local degrees_to_move = math.max(40 * dt, self._recoil_kick.accumulated * self._recoil_kick.accumulated * dt)
		r_value = math.min(self._recoil_kick.accumulated, degrees_to_move)
		self._recoil_kick.accumulated = self._recoil_kick.accumulated - r_value
	elseif self._recoil_wait then
		self._recoil_wait = self._recoil_wait - dt

		if self._recoil_wait <= 0 then
			self._recoil_wait = nil
		end
	end

	return r_value
end

--Simplified vanilla function to remove auto-correction weirdness.
--Also adds more aggressive tracking for horizontal recoil.
function FPCameraPlayerBase:_horizonatal_recoil_kick(t, dt)
	local r_value = 0

	if self._recoil_kick.h.accumulated and self._episilon < math.abs(self._recoil_kick.h.accumulated) then
		local degrees_to_move = math.max(40 * dt, self._recoil_kick.accumulated * self._recoil_kick.accumulated * dt)
		r_value = math.min(self._recoil_kick.h.accumulated, degrees_to_move)
		self._recoil_kick.h.accumulated = self._recoil_kick.h.accumulated - r_value
	elseif self._recoil_wait then
		self._recoil_wait = self._recoil_wait - dt

		if self._recoil_wait <= 0 then
			self._recoil_wait = nil
		end
	end

	return r_value
end

function FPCameraPlayerBase:update(unit, t, dt)
	if self._tweak_data.aim_assist_use_sticky_aim then
		self:_update_aim_assist_sticky(t, dt)
	end

	if _G.IS_VR and self._hmd_tracking and not self._block_input then
		self._output_data.rotation = self._base_rotation * VRManager:hmd_rotation()
	end

	if not _G.IS_VR then
		self._parent_unit:base():controller():get_input_axis_clbk("look", callback(self, self, "_update_rot"))
	end
	
	if not self._has_set_far_range then
		self._has_set_far_range = true
		self._parent_unit:camera()._camera_object:set_far_range(500000)
	end

	self:_update_stance(t, dt)
	self:_update_movement(t, dt)

	if managers.player:current_state() ~= "driving" then
		self._parent_unit:camera():set_position(self._output_data.position)
		self._parent_unit:camera():set_rotation(self._output_data.rotation)
	else
		self:_set_camera_position_in_vehicle()
	end

	if _G.IS_VR then
		self:_update_fadeout(self._output_data.mover_position, self._output_data.position, self._output_data.rotation, t, dt)
		self._parent_unit:camera():update_transform()
	end

	if self._fov.dirty then
		self._parent_unit:camera():set_FOV(self._fov.fov)

		self._fov.dirty = nil
	end

	if alive(self._light) then
		local weapon = self._parent_unit:inventory():equipped_unit()

		if weapon then
			local object = weapon:get_object(Idstring("fire"))
			local pos = object:position() + object:rotation():y() * 10 + object:rotation():x() * 0 + object:rotation():z() * -2

			self._light:set_position(pos)
			self._light:set_rotation(Rotation(object:rotation():z(), object:rotation():x(), object:rotation():y()))
			World:effect_manager():move_rotate(self._light_effect, pos, Rotation(object:rotation():x(), -object:rotation():y(), -object:rotation():z()))
		end
	end
end