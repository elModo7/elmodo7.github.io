init()
{
	[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
}

onPlayerConnected()
{
	self thread updateGrenadeIndicators();
}

updateGrenadeIndicators()
{
	self endon("disconnect");

	if(!level.ex_grenadeind)
	{
		self setClientCvar("cg_hudGrenadeIconHeight", "0");
		self setClientCvar("cg_hudGrenadeIconWidth", "0");
		self setClientCvar("cg_hudGrenadeIconOffset", "0");
		self setClientCvar("cg_hudGrenadePointerHeight", "0");
		self setClientCvar("cg_hudGrenadePointerWidth", "0");
		self setClientCvar("cg_hudGrenadePointerPivot", "0");
		self setClientCvar("cg_fovscale", "1");
	}
	else
	{
		// Fullscreen scale
		self setClientCvar("cg_hudGrenadeIconHeight", "25");
		self setClientCvar("cg_hudGrenadeIconWidth", "25");
		self setClientCvar("cg_hudGrenadeIconOffset", "50");
		self setClientCvar("cg_hudGrenadePointerHeight", "12");
		self setClientCvar("cg_hudGrenadePointerWidth", "25");
		self setClientCvar("cg_hudGrenadePointerPivot", "12 27");
		self setClientCvar("cg_fovscale", "1");
	}
}
