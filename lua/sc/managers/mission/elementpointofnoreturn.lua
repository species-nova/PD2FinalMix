function ElementPointOfNoReturn:on_executed(instigator)
	if not self._values.enabled then
		return
	end

	local diff = Global.game_settings and Global.game_settings.difficulty or "hard"
	local job = Global.level_data and Global.level_data.level_id

	--Done to make the timer more fair
	if job == "cage" then 
		if diff == "easy" then
			managers.groupai:state():set_point_of_no_return_timer(420, self._id)
		elseif diff == "normal" then
			managers.groupai:state():set_point_of_no_return_timer(390, self._id)
		elseif diff == "hard" then
			managers.groupai:state():set_point_of_no_return_timer(360, self._id)
		elseif diff == "overkill" then
			managers.groupai:state():set_point_of_no_return_timer(330, self._id)
		elseif diff == "overkill_145" then
			managers.groupai:state():set_point_of_no_return_timer(300, self._id)
		elseif diff == "easy_wish" then
			managers.groupai:state():set_point_of_no_return_timer(270, self._id)
		elseif diff == "overkill_290" then
			managers.groupai:state():set_point_of_no_return_timer(270, self._id)
		elseif diff == "sm_wish" then
			managers.groupai:state():set_point_of_no_return_timer(240, self._id)
		end				
	--Done so you can actually hear the entirety of the 'loud' music
	elseif job == "tag" or job == "xmn_tag" or job == "run" or job == "kosugi" or job == "dark" or job == "fish" then 	
		if diff == "easy" then
			managers.groupai:state():set_point_of_no_return_timer(60, self._id)
		elseif diff == "normal" then
			managers.groupai:state():set_point_of_no_return_timer(60, self._id)
		elseif diff == "hard" then
			managers.groupai:state():set_point_of_no_return_timer(60, self._id)
		elseif diff == "overkill" then
			managers.groupai:state():set_point_of_no_return_timer(60, self._id)
		elseif diff == "overkill_145" then
			managers.groupai:state():set_point_of_no_return_timer(60, self._id)
		elseif diff == "easy_wish" then
			managers.groupai:state():set_point_of_no_return_timer(60, self._id)
		elseif diff == "overkill_290" then
			managers.groupai:state():set_point_of_no_return_timer(60, self._id)
		elseif diff == "sm_wish" then
			managers.groupai:state():set_point_of_no_return_timer(60, self._id)
		end		
	--Ditto, just to make this map less ass
	elseif job == "bph" then 
		if diff == "easy" then
			managers.groupai:state():set_point_of_no_return_timer(780, self._id)
		elseif diff == "normal" then
			managers.groupai:state():set_point_of_no_return_timer(750, self._id)
		elseif diff == "hard" then
			managers.groupai:state():set_point_of_no_return_timer(720, self._id)
		elseif diff == "overkill" then
			managers.groupai:state():set_point_of_no_return_timer(690, self._id)
		elseif diff == "overkill_145" then
			managers.groupai:state():set_point_of_no_return_timer(660, self._id)
		elseif diff == "easy_wish" then
			managers.groupai:state():set_point_of_no_return_timer(630, self._id)
		elseif diff == "overkill_290" then
			managers.groupai:state():set_point_of_no_return_timer(630, self._id)
		elseif diff == "sm_wish" then
			managers.groupai:state():set_point_of_no_return_timer(600, self._id)
		end	
	--Because does it really need one?
	elseif job == "vit" then 
		--Disabled
		return
	--Everything else, just uses what's defined in the mapdata
	else
		if diff == "easy" then
			managers.groupai:state():set_point_of_no_return_timer(self._values.time_easy, self._id)
		elseif diff == "normal" then
			managers.groupai:state():set_point_of_no_return_timer(self._values.time_normal, self._id)
		elseif diff == "hard" then
			managers.groupai:state():set_point_of_no_return_timer(self._values.time_hard, self._id)
		elseif diff == "overkill" then
			managers.groupai:state():set_point_of_no_return_timer(self._values.time_overkill, self._id)
		elseif diff == "overkill_145" then
			managers.groupai:state():set_point_of_no_return_timer(self._values.time_overkill_145, self._id)
		elseif diff == "easy_wish" then
			managers.groupai:state():set_point_of_no_return_timer(self._values.time_easy_wish, self._id)
		elseif diff == "overkill_290" then
			managers.groupai:state():set_point_of_no_return_timer(self._values.time_overkill_290, self._id)
		elseif diff == "sm_wish" then
			managers.groupai:state():set_point_of_no_return_timer(self._values.time_sm_wish, self._id)
		end
	end
				
	ElementPointOfNoReturn.super.on_executed(self, instigator)
end