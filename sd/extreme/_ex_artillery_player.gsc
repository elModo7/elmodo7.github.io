
start(delay)
{
	self endon("kill_thread");

	if(self.ex_artillery_strike) return;

	self notify("end_artillery");
	wait( [[level.ex_fpstime]](0.1) );
	self endon("end_artillery");

	self.ex_artillery_strike = true;

	// wait the first
	if(!isDefined(delay)) delay = level.ex_rank_artillery_first;
	wait( [[level.ex_fpstime]](delay) );

	while(self.ex_artillery_strike)
	{
		// let them know the artillery strike is available
		if(level.ex_arcade_shaders) self thread extreme\_ex_arcade::showArcadeShader("x2_artilleryunlock", level.ex_arcade_shaders_perk);
			else self iprintlnbold(&"ARTILLERY_READY");
		self teamSound("arty_ready", 1);

		//set up the on screen icon
		self hudNotify(game["wmd_artillery_hudicon"]);

		//monitor for binocular fire
		self thread waitForUse();

		// wait until they use artillery
		self waittill("artillery_over");

		if(!level.ex_arcade_shaders) self iprintlnbold(&"ARTILLERY_RELOAD");
		self teamSound("arty_reload", 3);

		// now wait for one interval
		wait( [[level.ex_fpstime]](level.ex_rank_artillery_next) );
	}
}

waitForUse()
{
	self endon("kill_thread");
	self endon("end_artillery");
	self endon("end_waitforuse");

	self.callingwmd = false;

	for(;;)
	{
		self waittill("binocular_enter");
		if(!self.callingwmd)
		{
			self thread waitForBinocUse();
			self thread binocHintHud();
		}
		wait( [[level.ex_fpstime]](0.2) );
	}
}

waitForBinocUse()
{
	self endon("kill_thread");
	self endon("binocular_exit");
	self endon("end_waitforuse");

	for(;;)
	{
		if(isPlayer(self) && self useButtonPressed() && !self.callingwmd)
		{
			self.callingwmd = true;
			self thread callRadio();
		}
		wait( [[level.ex_fpstime]](0.01) );
	}
}

callRadio()
{
	self endon("kill_thread");

	if(!level.ex_arcade_shaders) self iprintlnbold(&"ARTILLERY_RADIO_IN");

	targetPos = getTargetPosition();
	friendly = friendlyInstrikezone(targetPos);

	self teamSound("arty_firemission", 3.6);
	for(i = 1; i < 4; i++) self teamSound("arty_" + randomInt(8), 0.6);
	self teamSound("arty_pointfuse", 3);

	if(isDefined(targetPos) && isDefined(friendly) && friendly == false)
	{
		// notify threads
		self notify("end_waitforuse");

		// clear hud icon
		self hudNotifyRemove();

		// clear hint icon
		if(isdefined(self.ex_binocular_hint)) self.ex_binocular_hint destroy();

		if(!level.ex_arcade_shaders) self iprintlnbold(&"ARTILLERY_FIRED");
		self teamSound("arty_shot", 3);

		// player has used weapon
		self.usedweapons = true;

		artillery = spawn("script_origin", targetPos);
		artillery thread fireBarrage(self);
	}
	else if(!isDefined(targetPos) && !isDefined(friendly))
	{
		friendly = undefined;
		self iprintlnbold(&"ARTILLERY_NOT_VALID");
		self teamSound("arty_novalid", 3);
	}
	else if(isDefined(friendly) && friendly == true)
	{
		friendly = undefined;
		self iprintlnbold(&"ARTILLERY_FRIENDLY_WARNING");
		self teamSound("arty_frndly", 3);
	}
	else if(isDefined(targetPos) && !isDefined(friendly))
	{
		friendly = undefined;
		self iprintlnbold(&"ARTILLERY_TO_CLOSE_WARNING");
		self teamSound("arty_tooclose", 3);
	}

	self.callingwmd = false;
}

getTargetPosition()
{
	startOrigin = self getEye() + (0,0,20);
	forward = anglesToForward(self getplayerangles());
	forward = [[level.ex_vectorscale]](forward, 100000);
	endOrigin = startOrigin + forward;

	trace = bulletTrace( startOrigin, endOrigin, false, self );
	if(trace["fraction"] == 1.0 || trace["surfacetype"] == "default") return (undefined);
		else return (trace["position"]);
}

fireBarrage(owner)
{
	// drop flare
	if(level.ex_rank_wmd_flare) playfx(level.ex_effect["flare_indicator"], self.origin);
	wait( [[level.ex_fpstime]](1) );

	// create artillery start position (surface level)
	artilleryStartPos = (game["playArea_Min"][0], game["playArea_Min"][1], 0);

	// number of shells in barrage
	shellNumber = 6;

	// artillery firing sounds
	for(i = 0; i < shellNumber; i++ )
	{
		self thread firingSound();
		wait( [[level.ex_fpstime]](0.5) );
	}

	// create shell target positions
	shellTargetPos = [];
	for(i = 0; i < shellNumber; i++ )
		shellTargetPos[i] = calcShellPos(self.origin);

	self.artilleryGlobalDelay = 0;

	// fire shells
	for (i = 0; i < shellNumber; i++ )
		self thread fireShell(owner, artilleryStartPos, shellTargetPos[i]);

	// wait for all shells to explode
	shellImpacts = 0;
	while ( shellImpacts < shellNumber )
	{
		self waittill("artillery_shell_impact");
		shellImpacts++;
	}

	owner notify ("artillery_over");
	self delete();
}

calcShellPos(targetPos)
{
	shellPos = undefined;
	iterations = 0;

	while(!isDefined(shellPos) && iterations < 5)
	{
		shellPos = targetPos;
		angle = randomFloat(360);
		radius = randomFloat(level.ex_rank_artillery_radius);
		randomOffset = (cos(angle) * radius, sin(angle) * radius, 0);
		shellPos += randomOffset;
		startOrigin = shellPos + (0, 0, 800);
		endOrigin = shellPos + (0, 0, -2048);

		trace = bulletTrace( startOrigin, endOrigin, true, undefined );
		if(trace["fraction"] < 1.0) shellPos = trace["position"];
			else shellPos = undefined;

		iterations++;
	}

	if(!isDefined(shellPos)) shellPos = targetPos;
	return shellPos;
}

fireShell(owner, shellStartPos, shellTargetPos)
{
	// calculate the height of the artillery spawn point to let shells come in at a certain angle
	//shellAngle = 60;
	//shellDist = distance(shellTargetPos, shellStartPos);
	//shellHeight = int(shellDist * tan(shellAngle));
	//shellStartPos = (shellStartPos[0], shellStartPos[1], shellHeight);
	shellStartPos = (shellTargetPos[0]-100, shellTargetPos[1]-100, game["mapArea_Max"][2]-200);

	self.artilleryGlobalDelay += randomFloatRange( .5, 1.5 );
	wait( [[level.ex_fpstime]](self.artilleryGlobalDelay) );
	wait( [[level.ex_fpstime]](randomFloatRange(1.5, 2.5)) );

	// show visible artillery shell
	shell = spawn("script_model", shellStartPos);
	shell setModel("xmodel/prop_stuka_bomb");
	shell.angles = vectorToAngles(vectorNormalize(shellTargetPos - shellStartPos));

	// Play incoming sound
	//shell playSound("artillery_incoming");
	ms = randomInt(14) + 1;
	shell playsound("mortar_incoming" + ms);

	// calculate time in air (s) based on distance (m) and preferred shell speed (m/s)!
	shellSpeed = 50;
	shellInAir = calcTime(shellStartPos, shellTargetPos, shellSpeed);

	// move visible artillery shell (correct target to slam shells into the ground, and for more realistic FX)
	shell moveTo(shellTargetPos + (0,0,-100), shellInAir);

	// wait for shell to hit
	wait( [[level.ex_fpstime]](shellInAir) );

	shell shellImpact(owner);
	self notify("artillery_shell_impact");
}

shellImpact(owner)
{
	playfx(level.ex_effect["artillery"], self.origin);
	//self playSound("artillery_explosion");
	ms = randomInt(18) + 1;
	self playsound("mortar_explosion" + ms);

	surfaceFx = calcImpactSurface(self.origin);
	if(isPlayer(owner) && owner.sessionstate != "spectator")
		self thread extreme\_ex_utils::scriptedfxradiusdamage(owner, undefined, "MOD_EXPLOSIVE", "artillery_mp", level.ex_artillery_radius, 500, 350, "generic", surfaceFx, true, true, true);
	else
		self thread extreme\_ex_utils::scriptedfxradiusdamage(self, undefined, "MOD_EXPLOSIVE", "artillery_mp", level.ex_artillery_radius, 0, 0, "generic", surfaceFx, true, true, true);

	self hide();
	wait( [[level.ex_fpstime]](1) );
	self delete();
}

friendlyInStrikeZone(targetPos)
{
	// return if friendly fire check has been disabled
	if(level.ex_rank_wmd_checkfriendly == 0) return false;

	// dont need to check friendly if gametype is not teamplay
	if(!level.ex_teamplay) return false;

	if(!isDefined(targetPos)) return (undefined);

	if(distance(targetPos, self.origin) <= 1000) return (undefined);

	// check if players in the same team are in targetzone
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		if(isPlayer(self) && isPlayer(players[i]))
		{
			if(players[i].sessionstate == "playing" && players[i].pers["team"] == self.pers["team"])
			{
				if(distance(targetpos, players[i].origin) <= 1000)
					return true;
			}
		}
	}
	return false;
}

calcTime(startpos, endpos, speedvalue)
{
	distunit = 1;	// Metres
	speedunit = 1; // Metres per second
	distvalue = distance(startpos, endpos);
	distvalue = int(distvalue * 0.0254); // convert to metres
	timeinsec = (distvalue * distunit) / (speedvalue * speedunit);
	if(timeinsec <= 0) timeinsec = 0.1;
	return timeinsec;
}

calcImpactSurface(targetPos)
{
	startOrigin = targetPos + (0, 0, 800);
	endOrigin = targetPos + (0, 0, -2048);

	trace = bulletTrace(startOrigin, endOrigin, true, undefined);
	if(trace["fraction"] < 1.0) surface = trace["surfacetype"];
		else surface = "dirt";

	if(!isDefined(surface)) surface = "dirt";
	return surface;
}

firingSound()
{
	players = level.players;
	for(i = 0; i < players.size; i++)
		players[i] playLocalSound("artillery_fire");
}

teamSound(aliasPart, waitTime)
{
	if (self.pers["team"] == "allies")
	{
		switch(game["allies"])
		{
			case "american":
				self playLocalSound("us_" + aliasPart);
				wait( [[level.ex_fpstime]](waitTime) );
				break;
			case "british":
				self playLocalSound("uk_" + aliasPart);
				wait( [[level.ex_fpstime]](waitTime) );
				break;
			default:
				self playLocalSound("ru_" + aliasPart);
				wait( [[level.ex_fpstime]](waitTime) );
				break;
		}
	}
	else
	{
		self playLocalSound("ge_" + aliasPart);
		wait( [[level.ex_fpstime]](waitTime) );
	}
}

hudNotify(shader)
{
	self endon("kill_thread");

	self hudNotifyRemove();

	self.ex_wmd_icon = newClientHudElem(self);
	self.ex_wmd_icon.archived = true;
	self.ex_wmd_icon.horzAlign = "fullscreen";
	self.ex_wmd_icon.vertAlign = "fullscreen";
	self.ex_wmd_icon.alignX = "center";
	self.ex_wmd_icon.alignY = "middle";
	self.ex_wmd_icon.x = 620;
	self.ex_wmd_icon.y = 360;
	self.ex_wmd_icon.alpha = level.ex_iconalpha;
	self.ex_wmd_icon setShader(shader, 16, 16);
	self.ex_wmd_icon scaleOverTime(.5, 24, 24);

	if(!isDefined(self.ex_binocular_hint))
	{
		self.ex_binocular_hint = newClientHudElem( self );
		self.ex_binocular_hint.archived = false;
		self.ex_binocular_hint.horzAlign = "fullscreen";
		self.ex_binocular_hint.vertAlign = "fullscreen";
		self.ex_binocular_hint.alignX = "center";
		self.ex_binocular_hint.alignY = "middle";
		self.ex_binocular_hint.x = 350;
		self.ex_binocular_hint.y = 460;
		self.ex_binocular_hint.fontScale = 1;
		self.ex_binocular_hint.sort = 5;
		self.ex_binocular_hint setText(&"WMD_ACTIVATE_HINT");

		// do not show hint if planting a tripwire
		if(level.ex_tweapon)
		{
			if( !self.ex_plantwire && !self.ex_defusewire && !isDefined(self.ex_actimer) ||
				self [[level.ex_getstance]](false) != 2 && !isDefined(self.ex_actimer)) self.ex_binocular_hint.alpha = 1;
			else self.ex_binocular_hint.alpha = 0;
		}
		else self.ex_binocular_hint.alpha = 1;
	}
}

hudNotifyRemove()
{
	if(isDefined(self.ex_wmd_icon)) self.ex_wmd_icon destroy();
}

binocHintHud()
{
	self endon("binocular_exit");

	if(!isdefined(self.ex_binocular_hint))
	{
		self.ex_binocular_hint = newClientHudElem( self );
		self.ex_binocular_hint.archived = false;
		self.ex_binocular_hint.horzAlign = "fullscreen";
		self.ex_binocular_hint.vertAlign = "fullscreen";
		self.ex_binocular_hint.alignX = "center";
		self.ex_binocular_hint.alignY = "middle";
		self.ex_binocular_hint.x = 350;
		self.ex_binocular_hint.y = 460;
		self.ex_binocular_hint.fontScale = 1;
		self.ex_binocular_hint.sort = 5;
		self.ex_binocular_hint.alpha = 1;
	}

	self.ex_binocular_hint setText(&"WMD_ARTILLERY_HINT");
	self thread binocHintHudDestroy();
}

binocHintHudDestroy()
{
	self endon("kill_thread");
	self endon("binocular_enter");

	self waittill("binocular_exit");

	if(isDefined(self.ex_binocular_hint)) self.ex_binocular_hint destroy();
}
