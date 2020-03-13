init()
{
	if(!level.ex_codhitblip) return;
	precacheShader("damage_feedback");
	[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
}

onPlayerConnected()
{
	self.hud_damagefeedback = newClientHudElem(self);
	self.hud_damagefeedback.horzAlign = "center";
	self.hud_damagefeedback.vertAlign = "middle";
	self.hud_damagefeedback.x = -12;
	self.hud_damagefeedback.y = -12;
	self.hud_damagefeedback.alpha = 0;
	self.hud_damagefeedback.archived = true;
	self.hud_damagefeedback setShader("damage_feedback", 24, 24);
}

updateDamageFeedback()
{
	if(level.ex_gameover || !level.ex_codhitblip) return;

	if(isPlayer(self))
	{
		self.hud_damagefeedback.alpha = 1;
		self.hud_damagefeedback fadeOverTime(1);
		self.hud_damagefeedback.alpha = 0;
		if(level.ex_codhitblip_alert) self playlocalsound("MP_hit_alert");
	}
}
