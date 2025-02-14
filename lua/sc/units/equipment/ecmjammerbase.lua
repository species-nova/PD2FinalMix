local mvec3_cpy = mvector3.copy
local mvec3_norm = mvector3.normalize

local math_random = math.random

local world_g = World
local ipairs_g = ipairs

function ECMJammerBase._detect_and_give_dmg(from_pos, device_unit, user_unit, range)
	local enemies_in_range = world_g:find_units_quick("sphere", from_pos, range, managers.slot:get_mask("enemies"))
	local attacker = alive(user_unit) and user_unit or nil
	local weapon = alive(device_unit) and device_unit or nil

	for _, enemy in ipairs_g(enemies_in_range) do
		local dmg_ext = enemy:character_damage()

		if dmg_ext and dmg_ext.damage_explosion then
			local ecm_vuln = enemy:base() and enemy:base():char_tweak() and enemy:base():char_tweak().ecm_vulnerability

			if ecm_vuln and ecm_vuln ~= 0 then
				local can_stun = true
				local brain_ext = enemy:brain()

				if brain_ext then
					if brain_ext.is_hostage and brain_ext:is_hostage() or brain_ext.surrendered and brain_ext:surrendered() then
						can_stun = false
					end
				end

				if can_stun then
					if enemy:anim_data() and enemy:anim_data().act or enemy:movement():chk_action_forbidden("hurt") or ecm_vuln < math_random() then
						can_stun = false
					end
				end

				if can_stun then
					local hit_pos = mvec3_cpy(enemy:movement():m_head_pos())
					local attack_dir = hit_pos - from_pos
					mvec3_norm(attack_dir)

					local attack_data = {
						damage = 0,
						variant = "stun",
						attacker_unit = attacker,
						weapon_unit = weapon,
						col_ray = {
							position = hit_pos,
							ray = attack_dir
						}
					}

					dmg_ext:damage_explosion(attack_data)
				end
			end
		end
	end
end

local update_original = ECMJammerBase.update
function ECMJammerBase:update(...)
	--pain
	self._unit:m_position(self._position)
	self._unit:m_rotation(self._rotation)

	update_original(self, ...)
end

function ECMJammerBase:_check_body()
	local attached_body = self._attached_body

	--only the server is supposed to check this and despawn the unit if needed
	--clients have no authority to do the latter on network-attached units
	if not Network:is_server() then
		if attached_body then
			if not alive(attached_body) then
				self._attached_body = nil

				log("ecmjammerbase, client: attached body doesn't exist or was destroyed")
			elseif not attached_body:enabled() then
				self._attached_body = nil

				log("ecmjammerbase, client: attached body is disabled")

				if attached_body.name then
					log("ecmjammerbase, client: body name is: " .. tostring(attached_body:name()) .. "")
				end

				if attached_body.unit then
					log("ecmjammerbase, client: unit id of the body is: " .. tostring(attached_body:unit():id()) .. "")
				end
			end
		end

		return
	end

	if not alive(attached_body) or not attached_body:enabled() then
		self:_force_remove()
	elseif not self._logged_name then
		self._logged_name = true

		if attached_body.name then
			log("ecmjammerbase, server: body name is: " .. tostring(attached_body:name()) .. "")
		end

		if attached_body.unit then
			log("ecmjammerbase, server: unit id of the body is: " .. tostring(attached_body:unit():id()) .. "")
		end
	end
end
