Hooks:PostHook(HUDAssaultCorner, "init", "SCHUDAssaultInit", function(self)
	local buff_icon = "guis/textures/pd2/hud_buff_shield"
	local job = Global.level_data and Global.level_data.level_id        
	for _,j in ipairs(restoration.captain_teamwork) do
		if job == j then
			buff_icon = "guis/textures/pd2/hud_buff_fire"
			break
		end
	end
	for _,j2 in ipairs(restoration.captain_murderdozer) do
		 if job == j2 then
			buff_icon = "guis/textures/pd2/hud_buff_skull"
			break
		end
	end
	for _,j3 in ipairs(restoration.captain_stelf) do
		 if job == j3 then
			buff_icon = "guis/textures/pd2/hud_buff_spooc"
			break
		end
	end		
	for _,j4 in ipairs(restoration.what_a_horrible_heist_to_have_a_curse) do
		if job == j4 then
			buff_icon = "guis/textures/pd2/hud_buff_halloween"
			break
		end
	end	
	
	--Skirmish exclusive stuff
	if managers.skirmish:is_skirmish() then		
		buff_icon = "guis/textures/pd2/hud_buff_generic"
	end	
	
	if alive(self._vip_bg_box) and alive(self._vip_bg_box:child("vip_icon")) then
		self._vip_bg_box:child("vip_icon"):set_image(buff_icon)
	end
end)