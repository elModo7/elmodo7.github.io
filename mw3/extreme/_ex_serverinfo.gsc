
init()
{
	level.ex_cvarserverinfo = [];
	[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
}

onPlayerConnected()
{
	for(i = 0; i < level.ex_cvarserverinfo.size; i++)
		self setClientCvar(level.ex_cvarserverinfo[i].cvar, level.ex_cvarserverinfo[i].value);
}

registerCvarServerInfo(cvar, value)
{
	if(!isDefined(cvar) || !isDefined(cvar)) return;
	cvar = tolower(cvar);

	index = -1;
	for(i = 0; i < level.ex_cvarserverinfo.size; i++)
	{
	  if(level.ex_cvarserverinfo[i].cvar == cvar)
	  {
			index = i;
			break;
		}
	}

	if(index == -1)
	{
		index = level.ex_cvarserverinfo.size;
		level.ex_cvarserverinfo[index] = spawnstruct();
		level.ex_cvarserverinfo[index].cvar = cvar;
	}

	level.ex_cvarserverinfo[index].value = value;
	setCvar(cvar, value);
}

registerInfo()
{
	level endon("ex_gameover");

	// time limit
	registerCvarServerInfo("ui_timelimit", level.timelimit);

	// score limit
	registerCvarServerInfo("ui_scorelimit", level.scorelimit);

	// player spawn delay?
	registerCvarServerInfo("ui_spawndelay", level.respawndelay);

	// dom, esd, lts, ons, rbcnq, rbctf, sd
	if(level.ex_roundbased)
	{
		// round limit
		registerCvarServerInfo("ui_roundlimit", level.roundlimit);

		// round length
		registerCvarServerInfo("ui_roundlength", level.roundlength);

		// bomb timer?
		if(level.ex_currentgt == "sd" || level.ex_currentgt == "esd")
			registerCvarServerInfo("ui_bombtimer", level.bombtimer);
	}

	if(level.ex_currentgt == "htf" || level.ex_currentgt == "ihtf")
	{
		// flag hold time
		registerCvarServerInfo("ui_gtinfo_a", level.flagholdtime);

		// flag recover time
		registerCvarServerInfo("ui_gtinfo_b", level.flagrecovertime);

		// flag spawn delay
		registerCvarServerInfo("ui_gtinfo_c", level.flagspawndelay);
	}

	// rank system
	if(!level.ex_ranksystem) rank = 0;
		else rank = level.ex_rank_wmdtype + 1;
	registerCvarServerInfo("ui_rank", rank);

	// weapon class
	if(level.ex_bash_only)
	{
		wepclass = 100;
	}
	else if(level.ex_frag_fest)
	{
		wepclass = 200;
	}
	else if(level.ex_all_weapons)
	{
		wepclass = 300;
	}
	else if(level.ex_modern_weapons)
	{
		if(level.ex_wepo_class) wepclass = level.ex_wepo_class;
			else wepclass = 400;
	}
	else wepclass = level.ex_wepo_class;
	registerCvarServerInfo("ui_weapon_only", wepclass);
	
	// secondary weapons
	secwep = 0;
	if(level.ex_wepo_secondary) secwep = 1;
	if(level.ex_wepo_secondary && level.ex_wepo_sec_enemy) secwep = 2;
	registerCvarServerInfo("ui_secondarywep", secwep);

	// enemy weapons
	registerCvarServerInfo("ui_enemywep", level.ex_wepo_enemy);

	// damage modifier
	registerCvarServerInfo("ui_damagemod", level.ex_wdmodon);

	// grenades
	//  0 = none
	//  1 = frag nades
	//  2 = smoke nades
	//  4 = fire nades
	//  8 = gas nades
	// 16 = satchel charges
	frags = 0;
	if(getcvarint("scr_allow_fraggrenades"))
	{
		if(level.ex_firenades) frags = 4;
			else if(level.ex_gasnades) frags = 8;
				else if(level.ex_satchelcharges) frags = 16;
					else frags = 1;
	}
	smokes = 0;
	if(getcvarint("scr_allow_smokegrenades"))
	{
		if(level.ex_smoke["german"] == 7) smokes = 4;
			else if(level.ex_smoke["german"] == 8) smokes = 8;
				else if(level.ex_smoke["german"] == 9) smokes = 16;
				  else smokes = 2;
	}
	nades = (frags | smokes);
	registerCvarServerInfo("ui_nades", nades);

	// tripwires
	registerCvarServerInfo("ui_tripwire", level.ex_tweapon);

	// landmines
	registerCvarServerInfo("ui_landmines", level.ex_landmines);

	// spawn protection
	spro = 0;
	if(level.ex_spwn_time >= 1)
	{
		if(level.ex_spwn_invisible) spro = 2;
			else spro = 1;
	}
	registerCvarServerInfo("ui_spawnpro", spro);

	// health system
	registerCvarServerInfo("ui_healthsystem", level.ex_healthsystem);

	// firstaid system
	registerCvarServerInfo("ui_firstaid", level.ex_medicsystem);

	// sprinting
	if(level.ex_sprint >= 1) sprint = 1;
		else sprint = 0;
	registerCvarServerInfo("ui_sprinting", sprint);

	// forced autoassign
	registerCvarServerInfo("ui_forced_auto", level.ex_autoassign);
}
