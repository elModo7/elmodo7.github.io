prep()
{
	level endon("ex_gameover");
	self endon("disconnect");

	self.ex_willparachute = undefined;
	self.ex_isparachuting = undefined;

	// skip during ready-up
	if(level.ex_readyup && !isDefined(game["readyup_done"])) return;

	// if entities monitor in defcon 1 or 2, suspend
	if(level.ex_entities_defcon) return;

	// mbots do not like parachutes
	if(level.ex_mbot && isDefined(self.pers["isbot"])) return;

	// Abort if round based and match started
	if(level.ex_parachutes == 4 && level.ex_roundbased && game["roundnumber"] > 0) return;

	// If player has already parachuted and parachutes is set to parachute only once per map/round
	if(isDefined(self.pers["ex_haveparachuted"])) return;

	// If parachutes is set for attackers only then check for attacker self team
	if(level.ex_teamplay && level.ex_parachutesonlyattackers && game["attackers"] != self.pers["team"]) return;

	// If playing LIB and player is jailed, do not parachute in
	if(level.ex_currentgt == "lib" && isDefined(self.in_jail) && self.in_jail) return;

	// If playing FT and player should spawn frozen, do not parachute in
	if(level.ex_currentgt == "ft" && isDefined(self.spawnfrozen) && self.spawnfrozen) return;

	// Once per map on first spawn: set flag regardless of ability to chute in
	if(level.ex_parachutes == 1) self.pers["ex_haveparachuted"] = true;

	// Randomizer
	if((level.ex_parachutes == 2 || level.ex_parachutes == 3) && randomInt(100) > level.ex_parachutes_chance) return;

	self.ex_willparachute = true;
	self hide();
}

main()
{
	level endon("ex_gameover");
	self endon("disconnect");

	// Starting point for player
	ix = self.origin[0] - 150 + randomint(300);
	iy = self.origin[1] - 150 + randomint(300);

	// Calculate starting altitude
	if(level.ex_planes_altitude) iz = level.ex_planes_altitude - randomint(100);
		else iz = 6000 - randomint(100);

	// Endpoint for player is a couple of units above spawn point (origin)
	// Use a low value here to avoid getting stuck
	endpoint = self.origin + ( 0, 0, 30);

	// Check how high the path is clear
	trace = bulletTrace(endpoint, (endpoint + (0,0,iz)), false, undefined);
	pos = trace["position"];
	iz = pos[2];

	// Limit the altitude
	if(level.ex_parachuteslimitaltitude)
	{
		if((iz-endpoint[2]) > level.ex_parachuteslimitaltitude)
			iz = endpoint[2] + level.ex_parachuteslimitaltitude - randomint(100);
	}

	// Starting point ready
	startpoint = ( ix, iy, iz);

	// Calculate distance between start and end
	distance = distance(startpoint, endpoint);

	// Set hidden status before checking distance, so we can unhide if needed
	if(level.ex_spwn_time && level.ex_spwn_invisible && isDefined(self.ex_spawnprotected)) chute_hide = true;
		else chute_hide = false;

	// Don't parachute distances below 350 units (3.5 seconds)
	if(distance < 350)
	{
		if(!chute_hide) self show();
		return;
	}

	// Now we are clear to parachute
	self.ex_isparachuting = true;
	if(level.ex_parachutes == 2 || level.ex_parachutes == 4) self.pers["ex_haveparachuted"] = true;

	// Create an anchor and a parachute model
	chute = level createParachute(startpoint, self.angles, chute_hide);

	// Link the player to the anchor
	self.origin = startpoint;
	self linkto(level.chutes[chute].anchor);

	// If not supposed to be hidden (hidden spawn protection), unhide player
	if(!chute_hide) self show();

	// Disable weapon & make player invulnerable
	if(level.ex_parachutesprotection)
	{
		if(level.ex_parachutesprotection == 1) self [[level.ex_dWeapon]]();
		self.ex_invulnerable = true;
	}

	// wait until parachute is released by main player threads
	self waittill("parachute_release");

	// Parachute into the map
	level thread dropOnParachute(chute, startpoint, endpoint);

	self playLocalSound("para_plane");

	while(isPlayer(self) && isAlive(self) && level.chutes[chute].anchor.origin[2] > endpoint[2])
	{
		self setClientCvar("cl_stance", "0");
		if(level.ex_spwn_time && level.ex_spwn_invisible && !isDefined(self.ex_spawnprotected)) showParachute(chute);
		wait( [[level.ex_fpstime]](0.2) );
	}

	if(isPlayer(self))
	{
		self unlink();
		if(isAlive(self))
		{
			self playSound("para_land");
			earthquake(0.4, 1.2, self.origin, 70);

			if(level.ex_parachutesprotection)
			{
				if(level.ex_parachutesprotection == 1) self [[level.ex_eWeapon]]();
				if(!isDefined(self.ex_spawnprotected)) self.ex_invulnerable = false;
			}
		}
		self.ex_isparachuting = undefined;
	}
}

createParachute(chute_origin, chute_angles, chute_hide)
{
	chute = allocateParachute();

	level.chutes[chute].anchor = spawn("script_model", chute_origin);
	level.chutes[chute].anchor.angles = chute_angles;

	level.chutes[chute].model = spawn("script_model", chute_origin);
	if(chute_hide) hideParachute(chute);
	level.chutes[chute].model setModel("xmodel/am_fallschirm");
	level.chutes[chute].model.angles = chute_angles + (0,0,90);
	level.chutes[chute].model linkto(level.chutes[chute].anchor);
	level.chutes[chute].autokill = 180;
	thread monitorParachute(chute);
	return chute;
}

dropOnParachute(chute, chute_start, chute_end)
{
	if(isDefined(level.chutes) && isDefined(level.chutes[chute]))
	{
		level.chutes[chute].endpoint = chute_end;
		level.chutes[chute].anchor.origin = chute_start;
		level.chutes[chute].anchor playLoopSound ("para_wind");
		falltime = distance(chute_start, chute_end) / 100 + randomint(6);
		level.chutes[chute].autokill = (falltime * 2) + 10;
		level.chutes[chute].anchor moveto(chute_end, falltime);
		wait( [[level.ex_fpstime]](falltime) );
		level.chutes[chute].anchor stopLoopSound();
		level.chutes[chute].flag = 2; // 2 = delete
	}
}

hideParachute(chute)
{
	if(isDefined(level.chutes) && isDefined(level.chutes[chute]))
		level.chutes[chute].model hide();
}

showParachute(chute)
{
	if(isDefined(level.chutes) && isDefined(level.chutes[chute]))
		level.chutes[chute].model show();
}

monitorParachute(chute)
{
	chute_time = 0;
	while(true)
	{
		wait( [[level.ex_fpstime]](0.5) );
		chute_time++;
		if(level.chutes[chute].flag == 2 || chute_time >= level.chutes[chute].autokill)
		{
			if(level.chutes[chute].flag == 2)
			{
				level.chutes[chute].model unlink();
				level.chutes[chute].model rotatepitch(85,10,9,1);
				level.chutes[chute].model moveto(level.chutes[chute].endpoint - (0,400,400), 7,6,1);
				wait( [[level.ex_fpstime]](5) );
			}
			freeParachute(chute);
			break;
		}
	}
}

allocateParachute()
{
	if(!isDefined(level.chutes)) level.chutes = [];

	for(i = 0; i < level.chutes.size; i++)
	{
		if(level.chutes[i].flag == 0) // 0 = free
		{
			level.chutes[i].flag = 1; // 1 = in use
			return i;
		}
	}
	level.chutes[i] = spawnstruct();
	level.chutes[i].flag = 1; // 1 = in use
	return i;
}

freeParachute(chute)
{
	if(isDefined(level.chutes) && isDefined(level.chutes[chute]))
	{
		if(isDefined(level.chutes[chute].model))
			level.chutes[chute].model delete();

		if(isDefined(level.chutes[chute].anchor))
			level.chutes[chute].anchor delete();

		level.chutes[chute].flag = 0; // 0 = free
	}
}
