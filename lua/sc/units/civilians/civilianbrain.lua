function CivilianBrain:on_intimidated(n, unit)
	CivilianBrain.super.on_intimidated(self, n, unit)
	if Network:is_server() then
		managers.groupai:state():propagate_alert({
			"vo_distress",
			unit:movement():m_head_pos(),
			0,
			managers.groupai:state():get_unit_type_filter("civilians_enemies"),
			unit
		})
	end
end

function CivilianBrain:on_cool_state_changed(state)
	if self._logic_data then
		self._logic_data.cool = state
	end

	if self._alert_listen_key then
		managers.groupai:state():remove_alert_listener(self._alert_listen_key)
	else
		self._alert_listen_key = "CopBrain" .. tostring(self._unit:key())
	end

	local alert_listen_filter, alert_types = nil

	if state then
		alert_listen_filter = managers.groupai:state():get_unit_type_filter("criminals_enemies_civilians")
		alert_types = {
			vo_distress = true,
			fire = true,
			bullet = true,
			vo_intimidate = true,
			explosion = true,
			footstep = true,
			aggression = true,
			vo_cbt = true
		}
	else
		alert_listen_filter = managers.groupai:state():get_unit_type_filter("criminal")
		alert_types = {
			explosion = true,
			fire = true,
			aggression = true,
			bullet = true
		}
	end

	managers.groupai:state():add_alert_listener(self._alert_listen_key, callback(self, self, "on_alert"), alert_listen_filter, alert_types, self._unit:movement():m_head_pos())
end
