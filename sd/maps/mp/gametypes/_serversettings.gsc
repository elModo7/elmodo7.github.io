
init()
{
	level.hostname = getCvar("sv_hostname");
	if(level.hostname == "")
	{
		level.hostname = "CoDHost";
		setCvar("sv_hostname", level.hostname);
	}
	setCvar("ui_hostname", level.hostname);
	makeCvarServerInfo("ui_hostname", level.hostname);

	level.motd = getCvar("scr_motd");
	/*
	if(level.motd == "")
	{
		level.motd = "";
		setCvar("scr_motd", level.motd);
	}
	*/
	setCvar("ui_motd", level.motd);
	makeCvarServerInfo("ui_motd", level.motd);

	level.allowvote = getCvar("g_allowvote");
	if(level.allowvote == "")
	{
		level.allowvote = "1";
		setCvar("g_allowvote", level.allowvote);
	}
	setCvar("ui_allowvote", level.allowvote);
	makeCvarServerInfo("ui_allowvote", level.allowvote);

	level.friendlyfire = getCvar("scr_friendlyfire");
	if(level.friendlyfire == "")
	{
		level.friendlyfire = "0";
		setCvar("scr_friendlyfire", level.friendlyfire);
	}
	setCvar("ui_friendlyfire", level.friendlyfire);
	makeCvarServerInfo("ui_friendlyfire", level.friendlyfire);

	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, false, 5);
}

onRandom(eventID)
{
	sv_hostname = getCvar("sv_hostname");
	if(level.hostname != sv_hostname)
	{
		level.hostname = sv_hostname;
		setCvar("ui_hostname", level.hostname);
	}

	scr_motd = getCvar("scr_motd");
	if(level.motd != scr_motd)
	{
		level.motd = scr_motd;
		setCvar("ui_motd", level.motd);
	}

	g_allowvote = getCvar("g_allowvote");
	if(level.allowvote != g_allowvote)
	{
		level.allowvote = g_allowvote;
		setCvar("ui_allowvote", level.allowvote);
	}

	scr_friendlyfire = getCvar("scr_friendlyfire");
	if(level.friendlyfire != scr_friendlyfire)
	{
		level.friendlyfire = scr_friendlyfire;
		setCvar("ui_friendlyfire", level.friendlyfire);
	}
}
