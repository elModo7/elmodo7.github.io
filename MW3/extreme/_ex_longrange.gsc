#include extreme\_ex_weapons;

init()
{
	game["menu_keys"] = "keys";
	[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
	if(level.ex_longrange)
	{
		[[level.ex_PrecacheMenuItem]](game["menu_keys"]);
		[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	}
}

onPlayerConnected()
{
	longrange_server = (level.ex_longrange != 0);
	//if(!longrange_server && level.ex_longrange_memory) longrange_server = 2;
	self setClientCvar("ui_longrange", longrange_server);
}

onPlayerSpawned()
{
	if(isDefined(self.pers["isbot"])) return;

	if(level.ex_longrange_autoswitch) self thread autoSwitcher();
	if(isDefined(self.monitorExtraKeys)) self thread monitorZoom();
		else self thread monitorExtraKeys();
}

monitorExtraKeys()
{
	self endon("disconnect");

	self.pers["scopezoom"] = "m";
	memory = self extreme\_ex_memory::getMemory("lrbind", "key");
	if(!memory.error) self.pers["scopezoom"] = memory.value;
	self thread extreme\_ex_utils::execClientCommand("bind " + self.pers["scopezoom"] + " openScriptMenu keysMenu " + self.pers["scopezoom"]);

	self.monitorExtraKeys = true;
	self thread monitorZoom();

	while(isDefined(self))
	{
		self waittill("menuresponse", menu, response);

		if(menu == "-1" && isAlive(self)) self notify( "key_" + response);
	}
}

monitorZoom()
{
	self endon("kill_thread");
	self endon("ex_endzoommonitor");

	wait( [[level.ex_fpstime]](randomFloat(.5)) );
	self notify("ex_startswitcher");

	while(isPlayer(self) && self.sessionstate == "playing")
	{
		if(!isDefined(self.pers["scopezoom"])) self.pers["scopezoom"] = "m";
		self waittill("key_" + self.pers["scopezoom"]);

		weapon = self getCurrentWeapon();
		alterego = getWeaponCounterpart(weapon);
		if(alterego == "none") continue;

		if(weapon == self getWeaponSlotWeapon("primary")) weaponslot = "primary";
			else if(weapon == self getWeaponSlotWeapon("primaryb")) weaponslot = "primaryb";
				else continue;

		ammo = self getweaponslotammo(weaponslot);
		clipammo = self getweaponslotclipammo(weaponslot);
		self takeWeapon(weapon);
		self setWeaponSlotWeapon(weaponslot, alterego);
		self setweaponslotammo(weaponslot, ammo);
		self setweaponslotclipammo(weaponslot, clipammo);
		self switchToWeapon(alterego);
		wait( [[level.ex_fpstime]](1) );
	}
}

autoSwitcher()
{
	self endon("kill_thread");

	self waittill("ex_startswitcher");

	while(true)
	{
		wait( [[level.ex_fpstime]](0.5) );

		sWeapon = self getCurrentWeapon();
		if(isWeaponType(sWeapon, "sniper"))
		{
			self notify("key_" + self.pers["scopezoom"]);
			break;
		}
	}
}

changeBind(command)
{
	keys = "1234567890abcdefghijklmnopqrstuvwxyz";
	newbind = "";
	for(i = 0; i < keys.size; i++)
	{
		checkkey = "key_" + keys[i];
		if(command == checkkey)
		{
			newbind = keys[i];
			break;
		}
	}

	if(newBind != "")
	{
		self closeMenu();
		self notify("ex_endzoommonitor");
		wait( [[level.ex_fpstime]](0.05) );
		if(isDefined(self.pers["scopezoom"])) self thread extreme\_ex_utils::execClientCommand("unbind " + self.pers["scopezoom"]);
		self.pers["scopezoom"] = newbind;
		self thread extreme\_ex_utils::execClientCommand("bind " + self.pers["scopezoom"] + " openScriptMenu keysMenu " + self.pers["scopezoom"]);
		self thread extreme\_ex_memory::setMemory("lrbind", "key", self.pers["scopezoom"]);
		if(level.ex_longrange) self thread monitorZoom();
	}
}

getWeaponCounterpart(weapon)
{
	switch(weapon)
	{
		case "ar_10_mp": return "ar_10_2_mp";
		case "ar_10_2_mp": return "ar_10_mp";
		case "barrett_mp": return "barrett_2_mp";
		case "barrett_2_mp": return "barrett_mp";
		case "dragunov_mp": return "dragunov_2_mp";
		case "dragunov_2_mp": return "dragunov_mp";
		case "m40a3_mp": return "m40a3_2_mp";
		case "m40a3_2_mp": return "m40a3_mp";
		case "springfield_mp": return "springfield_2_mp";
		case "springfield_2_mp": return "springfield_mp";
		case "enfield_scope_mp": return "enfield_scope_2_mp";
		case "enfield_scope_2_mp": return "enfield_scope_mp";
		case "mosin_nagant_sniper_mp": return "mosin_nagant_sniper_2_mp";
		case "mosin_nagant_sniper_2_mp": return "mosin_nagant_sniper_mp";
		case "g43_sniper": return "g43_sniper_2";
		case "g43_sniper_2": return "g43_sniper";
		case "kar98k_sniper_mp": return "kar98k_sniper_2_mp";
		case "kar98k_sniper_2_mp": return "kar98k_sniper_mp";
		default: return "none";
	}
}

main(eAttacker, sWeapon, vPoint, aInfo)
{
	self endon("disconnect");

	//logprint("LRHITLOC: passed sMeansOfDeath \"" + aInfo.sMeansOfDeath + "\", sHitLoc \"" + aInfo.sHitLoc + "\", iDamage \"" + aInfo.iDamage + "\"\n");

	rangehm = int(distance(vPoint, self.ex_headmarker.origin));
	rangeem = int(distance(vPoint, self.ex_eyemarker.origin));
	rangesm = int(distance(vPoint, self.ex_spinemarker.origin));
	rangela = int(distance(vPoint, self.ex_lankmarker.origin));
	rangera = int(distance(vPoint, self.ex_rankmarker.origin));
	rangelw = int(distance(vPoint, self.ex_lwristmarker.origin));
	rangerw = int(distance(vPoint, self.ex_rwristmarker.origin));

	if(!isDefined(level.lrhitlocno)) level.lrhitlocno = 0;
	level.lrhitlocno++;
	//logprint("LRHITLOC: hit " + level.lrhitlocno + " distance to hm:" + rangehm + " em:" + rangeem + " sm:" + rangesm + " la:" + rangela + " ra:" + rangera + " lw:" + rangelw + " rw:" + rangerw + "\n");

	aInfo.sMeansOfDeath = "MOD_RIFLE_BULLET";
	aInfo.sHitLoc = "none";
	aInfo.iDamage = 50;

	// Head
	if(rangeem <= 8)
	{
		aInfo.sMeansOfDeath = "MOD_HEAD_SHOT";
		aInfo.sHitLoc = "head";
		aInfo.iDamage = level.ex_lrhitloc_head;
	}
	// Neck
	else if(rangeem > 8 && rangehm <= 5 && rangesm <= 8)
	{
		aInfo.sHitLoc = "neck";
		aInfo.iDamage = level.ex_lrhitloc_neck;
	}
	// Feet
	else if(rangera <= 10 && rangeem > 30)
	{
		aInfo.sHitLoc = "right_foot";
		aInfo.iDamage = level.ex_lrhitloc_right_foot;
	}
	else if(rangela <= 10 && rangeem > 30)
	{
		aInfo.sHitLoc = "left_foot";
		aInfo.iDamage = level.ex_lrhitloc_left_foot;
	}
	// Hands
	else if(rangerw <= 6)
	{
		aInfo.sHitLoc = "right_hand";
		aInfo.iDamage = level.ex_lrhitloc_right_hand;
	}
	else if(rangelw <= 6)
	{
		aInfo.sHitLoc = "left_hand";
		aInfo.iDamage = level.ex_lrhitloc_left_hand;
	}
	// Torso
	else if(rangeem > 6 && rangesm <= 6)
	{
		aInfo.sHitLoc = "torso_upper";
		aInfo.iDamage = level.ex_lrhitloc_torso_upper;
	}
	else if(rangeem > 8 && rangeem < 25 && rangesm > 6 && rangesm <= 18)
	{
		aInfo.sHitLoc = "torso_lower";
		aInfo.iDamage = level.ex_lrhitloc_torso_lower;
	}
	// Legs
	else if(rangeem > 25 && rangera > 10 && rangera < 30)
	{
		aInfo.sHitLoc = "right_leg_upper";
		aInfo.iDamage = level.ex_lrhitloc_right_leg_upper;
	}
	else if(rangeem > 25 && rangera > 1 && rangera < 15)
	{
		aInfo.sHitLoc = "right_leg_lower";
		aInfo.iDamage = level.ex_lrhitloc_right_leg_lower;
	}
	else if(rangeem > 25 && rangela > 10 && rangela < 30)
	{
		aInfo.sHitLoc = "left_leg_upper";
		aInfo.iDamage = level.ex_lrhitloc_left_leg_upper;
	}
	else if(rangeem > 25 && rangela > 1 && rangela < 15)
	{
		aInfo.sHitLoc = "left_leg_lower";
		aInfo.iDamage = level.ex_lrhitloc_left_leg_lower;
	}
	// Arms
	else if(rangesm > 18 && rangerw > 10 && rangerw < 30)
	{
		aInfo.sHitLoc = "right_arm_upper";
		aInfo.iDamage = level.ex_lrhitloc_right_arm_upper;
	}
	else if(rangesm > 18 && rangerw > 1 && rangerw < 15)
	{
		aInfo.sHitLoc = "right_arm_lower";
		aInfo.iDamage = level.ex_lrhitloc_right_arm_lower;
	}
	else if(rangesm > 18 && rangelw > 10 && rangelw < 30)
	{
		aInfo.sHitLoc = "left_arm_upper";
		aInfo.iDamage = level.ex_lrhitloc_left_arm_upper;
	}
	else if(rangesm > 18 && rangelw > 1 && rangelw < 15)
	{
		aInfo.sHitLoc = "left_arm_lower";
		aInfo.iDamage = level.ex_lrhitloc_left_arm_lower;
	}
}

hitlocMessage(eAttacker, sHitLoc)
{
	hitloc = getHitlocStringname(sHitLoc);
	range = int(distance(eAttacker.origin, self.origin));
	if(level.ex_lrhitloc_unit) rangedist = int(range * 0.02778); // Range in Yards
		else rangedist = int(range * 0.0254); // Range in Metres

	switch(level.ex_lrhitloc_msg)
	{
		case 1:
		{
			eAttacker iprintln(&"LONGRANGE_HIT", [[level.ex_pname]](self), hitloc);
			if(level.ex_lrhitloc_unit) eAttacker iprintln(&"OBITUARY_YARDS", rangedist);
				else eAttacker iprintln(&"OBITUARY_METRES", rangedist);
			break;
		}
		case 2:
		{
			eAttacker iprintlnbold(&"LONGRANGE_HIT", [[level.ex_pname]](self), hitloc);
			if(level.ex_lrhitloc_unit) eAttacker iprintlnbold(&"OBITUARY_YARDS", rangedist);
				else eAttacker iprintlnbold(&"OBITUARY_METRES", rangedist);
			break;
		}
	}
}

getHitlocStringname(location)
{
	switch(location)
	{
		case "right_hand":      return &"HITLOC_RIGHT_HAND";
		case "left_hand":       return &"HITLOC_LEFT_HAND";
		case "right_arm_upper": return &"HITLOC_RIGHT_UPPER_ARM";
		case "right_arm_lower": return &"HITLOC_RIGHT_FOREARM";
		case "left_arm_upper":  return &"HITLOC_LEFT_UPPER_ARM";
		case "left_arm_lower":  return &"HITLOC_LEFT_FOREARM";
		case "head":            return &"HITLOC_HEAD";
		case "neck":            return &"HITLOC_NECK";
		case "right_foot":      return &"HITLOC_RIGHT_FOOT";
		case "left_foot":       return &"HITLOC_LEFT_FOOT";
		case "right_leg_lower": return &"HITLOC_RIGHT_LOWER_LEG";
		case "left_leg_lower":  return &"HITLOC_LEFT_LOWER_LEG";
		case "right_leg_upper": return &"HITLOC_RIGHT_UPPER_LEG";
		case "left_leg_upper":  return &"HITLOC_LEFT_UPPER_LEG";
		case "torso_upper":     return &"HITLOC_UPPER_TORSO";
		case "torso_lower":     return &"HITLOC_LOWER_TORSO";
		default:                return &"HITLOC_UNKNOWN";
	}
}
