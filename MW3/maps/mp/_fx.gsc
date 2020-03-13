#include maps\mp\_utility;

/*
	******************************************************************************
	OneShotfx: Fires an effect once.
	maps\_fx::OneShotfx( effectname, (x y z), predelay);

	Example:
	maps\_fx::OneShotfx(level.medFire, (-701, -18361, 148), 5);
	******************************************************************************


	******************************************************************************
	Loopfx: Loops an effect with a waittime.
	maps\_fx::loopfx( effectname, (x y z), delay_between_shots);

	Example:
	maps\_fx::loopfx(level.medFire, (-701, -18361, 148), 0.3);
	******************************************************************************


	******************************************************************************
	GunFireLoopfx: Simulates bursts of fire.
	maps\_fx::gunfireloopfx(fxId, fxPos, shotsMin, shotsMax, shotdelayMin, shotdelayMax, betweenSetsMin, betweenSetsMax)

	Example:
	maps\_fx::gunfireloopfx (level.medFire, (-701, -18361, 148), 10, 15, 0.1, 0.3, 2.5, 9);
	******************************************************************************


	******************************************************************************
	GrenadeExplosionfx: Creates a grenade explosion with view jitter.
	maps\_fx::GrenadeExplosionfx((x y z));

	Example:
	maps\_fx::GrenadeExplosionfx( (-701, -18361, 148) ); // origin
	******************************************************************************
*/

/*
{
"origin" "-451 -14930 26"
"targetname" "auto1166"
"classname" "script_origin"
}
*/

print_org(fxcommand, fxId, fxPos, waittime)
{
	if(getcvar("debug") == "1")
	{
		println("{");
		println("\"origin\" \"" + fxPos[0] + " " + fxPos[1] + " " + fxPos[2] + "\"");
		println("\"classname\" \"script_model\"");
		println("\"model\" \"xmodel/fx\"");
		println("\"script_fxcommand\" \"" + fxcommand + "\"");
		println("\"script_fxid\" \"" + fxId + "\"");
		println("\"script_delay\" \"" + waittime + "\"");
		println("}");
	}
}

OneShotfx(fxId, fxPos, waittime, fxPos2)
{
	level thread print_org("OneShotfx", fxId, fxPos, waittime);
	level thread OneShotfxthread(fxId, fxPos, waittime, fxPos2);
}

OneShotfxthread(fxId, fxPos, waittime, fxPos2)
{
	wait( [[level.ex_fpstime]](0.05) );

	wait( [[level.ex_fpstime]](waittime) );
	if(isdefined(fxPos2))
		fxPos2 = vectornormalize(fxPos2 - fxPos);

	if(isdefined(level._effect[fxId]))
	{
		if(isdefined(fxPos2))
			playfx( level._effect[fxId], fxPos, fxPos2 );
		else
			playfx( level._effect[fxId], fxPos);
	}
}

exploderfx(num, fxId, fxPos, waittime, fxPos2, fireFx, fireFxDelay, fireFxSound, fxSound, fxQuake, fxDamage, soundalias)
{
	fx = spawn("script_origin", (0,0,0));
	println("total ", getentarray ("script_origin","classname").size);
	fx.origin = fxPos;
	fx.angles = vectortoangles (fxPos2 - fxPos);
	//fx.targetname = "exploder";
	fx.script_exploder = num;
	fx.script_fxid = fxId;
	fx.script_delay = waittime;

	fx.script_firefx = fireFx;
	fx.script_firedelay = fireFxDelay;
	fx.script_firefxsound = fireFxSound;

	fx.script_sound = fxSound;
	fx.script_earthquake = fxQuake;
	fx.script_damage = fxDamage;
	fx.script_soundalias = soundalias;

	forward = anglestoforward (fx.angles);
	forward = vectorScale(forward, 150);
	fx.targetPos = fxPos + forward;

	if(!isdefined(level._script_exploders))
		level._script_exploders = [];
	level._script_exploders[level._script_exploders.size] = fx;

	maps\mp\_createfx::createfx_showOrigin(fxid, fxPos, waittime, fxpos2, "exploderfx", fx);
}

loopfx(fxId, fxPos, waittime, fxPos2, fxStart, fxStop, timeout)
{
	level thread print_org ("loopfx", fxId, fxPos, waittime);
	level thread loopfxthread (fxId, fxPos, waittime, fxPos2, fxStart, fxStop, timeout);
}

loopfxthread(fxId, fxPos, waittime, fxPos2, fxStart, fxStop, timeout)
{
	ent = undefined;
	if(getcvar("createfx") != "")
	{
		ent = level thread maps\mp\_createfx::createfx_showOrigin( fxId, fxPos, waittime, fxPos2, "loopfx" );
		ent endon("effect deleted");
	}
	else
	{
		ent = spawnstruct();
		ent.id = fxId;
		ent.org = fxPos;
		ent.delay = waittime;
		ent.org2 = fxPos2;
	}
	
	wait( [[level.ex_fpstime]](0.05) );
	if((isdefined(level.scr_sound)) && (isdefined(level.scr_sound[fxId])))
		loopSound(level.scr_sound[fxId], fxPos);

	dist = 0;

	if(isdefined(fxStart))
		level waittill("start fx" + fxStart);

	while(1)
	{
		if(isdefined(ent.org2))
		{
			fxAngle = vectorNormalize (ent.org2 - ent.org);
			looper = playLoopedFx( level._effect[fxId], ent.delay, ent.org, dist, fxAngle );
		}
		else
			looper = playLoopedFx( level._effect[fxId], ent.delay, ent.org, dist );

		if(getcvar("createfx") != "")
		{
			looper thread loopfxDeletion(ent);
			looper thread loopfxChangeID(ent);
			looper thread loopfxChangeOrg(ent);
			looper thread loopfxChangeDelay(ent);
		}
		
		if(isdefined(timeout))
			looper thread loopfxStop(timeout);
			
		if(isdefined(fxStop))
			level waittill("stop fx" + fxStop);
		else
			return;

		if(isdefined(looper))
			looper delete();

		if(isdefined(fxStart))
			level waittill("start fx" + fxStart);
		else
			return;
	}
}

loopfxChangeID(ent)
{
	self endon("death");
	ent waittill("effect id changed", change);
}

loopfxChangeOrg(ent)
{
	self endon ("death");
	for(;;)
	{
		ent waittill("effect org changed", change);
		self.origin = change;
	}
}

loopfxChangeDelay(ent)
{
	self endon("death");
	ent waittill("effect delay changed", change);
}

loopfxDeletion(ent)
{
	self endon("death");
	ent waittill("effect deleted");
	self delete();
}

loopfxStop(timeout)
{
	self endon("death");
	wait( [[level.ex_fpstime]](timeout) );
	self delete();
}

loopSound(sound, Pos, waittime)
{
	level thread loopSoundthread(sound, Pos, waittime);
}

loopSoundthread( sound, pos, waittime )
{
	org = spawn("script_origin", (pos));
	org.origin = pos;
	org playLoopSound( sound );
}

gunfireloopfx(fxId, fxPos, shotsMin, shotsMax, shotdelayMin, shotdelayMax, betweenSetsMin, betweenSetsMax)
{
	thread gunfireloopfxthread(fxId, fxPos, shotsMin, shotsMax, shotdelayMin, shotdelayMax, betweenSetsMin, betweenSetsMax);
}

gunfireloopfxthread(fxId, fxPos, shotsMin, shotsMax, shotdelayMin, shotdelayMax, betweenSetsMin, betweenSetsMax)
{
	level endon("stop all gunfireloopfx");
	wait( [[level.ex_fpstime]](0.05) );

	if(betweenSetsMax < betweenSetsMin)
	{
		temp = betweenSetsMax;
		betweenSetsMax = betweenSetsMin;
		betweenSetsMin = temp;
	}

	betweenSetsBase = betweenSetsMin;
	betweenSetsRange = betweenSetsMax - betweenSetsMin;

	if(shotdelayMax < shotdelayMin)
	{
		temp = shotdelayMax;
		shotdelayMax = shotdelayMin;
		shotdelayMin = temp;
	}

	shotdelayBase = shotdelayMin;
	shotdelayRange = shotdelayMax - shotdelayMin;

	if(shotsMax < shotsMin)
	{
		temp = shotsMax;
		shotsMax = shotsMin;
		shotsMin = temp;
	}

	shotsBase = shotsMin;
	shotsRange = shotsMax - shotsMin;

	for(;;)
	{
		shotnum = shotsBase + randomint (shotsRange);
		for(i = 0; i < shotnum; i++)
		{
			playfx( level._effect[fxId], fxPos );
			
			wait( [[level.ex_fpstime]](shotdelayBase + randomfloat (shotdelayRange)) );
		}
		wait( [[level.ex_fpstime]](betweenSetsBase + randomfloat(betweenSetsRange)) );
	}
}

gunfireloopfxVec(fxId, fxPos, fxPos2, shotsMin, shotsMax, shotdelayMin, shotdelayMax, betweenSetsMin, betweenSetsMax)
{
	thread gunfireloopfxVecthread(fxId, fxPos, fxPos2, shotsMin, shotsMax, shotdelayMin, shotdelayMax, betweenSetsMin, betweenSetsMax);
}

gunfireloopfxVecthread(fxId, fxPos, fxPos2, shotsMin, shotsMax, shotdelayMin, shotdelayMax, betweenSetsMin, betweenSetsMax)
{
	level endon("stop all gunfireloopfx");
	wait( [[level.ex_fpstime]](0.05) );

	if(betweenSetsMax < betweenSetsMin)
	{
		temp = betweenSetsMax;
		betweenSetsMax = betweenSetsMin;
		betweenSetsMin = temp;
	}

	betweenSetsBase = betweenSetsMin;
	betweenSetsRange = betweenSetsMax - betweenSetsMin;

	if(shotdelayMax < shotdelayMin)
	{
		temp = shotdelayMax;
		shotdelayMax = shotdelayMin;
		shotdelayMin = temp;
	}

	shotdelayBase = shotdelayMin;
	shotdelayRange = shotdelayMax - shotdelayMin;

	if(shotsMax < shotsMin)
	{
		temp = shotsMax;
		shotsMax = shotsMin;
		shotsMin = temp;
	}

	shotsBase = shotsMin;
	shotsRange = shotsMax - shotsMin;

	fxPos2 = vectornormalize (fxPos2 - fxPos);

	for(;;)
	{
		shotnum = shotsBase + randomint (shotsRange);
		for (i=0;i<shotnum;i++)
		{
			playfx( level._effect[fxId], fxPos, fxPos2);
			wait( [[level.ex_fpstime]](shotdelayBase + randomfloat (shotdelayRange)) );
		}
		wait( [[level.ex_fpstime]](shotdelayBase + randomfloat (shotdelayRange)) );
		wait( [[level.ex_fpstime]](betweenSetsBase + randomfloat(betweenSetsRange)) );
	}
}

setup_fx()
{
	if((!isdefined(self.script_fxid)) || (!isdefined(self.script_fxcommand)) || (!isdefined(self.script_delay)))
		return;

	if(isdefined (self.model))
		if(self.model == "xmodel/toilet")
		{
			self thread burnville_paratrooper_hack();
			return;
		}

	org = undefined;
	if(isdefined(self.target))
	{
		ent = getent(self.target,"targetname");
		if(isdefined(ent)) org = ent.origin;
	}

	fxStart = undefined;
	if(isdefined(self.script_fxstart))
		fxStart = self.script_fxstart;

	fxStop = undefined;
	if(isdefined(self.script_fxstop))
		fxStop = self.script_fxstop;

	if(self.script_fxcommand == "OneShotfx")
		OneShotfx(self.script_fxId, self.origin, self.script_delay, org);
	if(self.script_fxcommand == "loopfx")
		loopfx(self.script_fxId, self.origin, self.script_delay, org, fxStart, fxStop);
	if(self.script_fxcommand == "loopsound")
		loopsound(self.script_fxId, self.origin, self.script_delay);

	self delete();
}

burnville_paratrooper_hack()
{
	normal = (0, 0, self.angles[1]);
	id = level._effect[self.script_fxId];
	origin = self.origin;

	//if(isdefined (self.script_delay)) wait( [[level.ex_fpstime]](self.script_delay) );

	wait( [[level.ex_fpstime]](1) );
	level thread burnville_paratrooper_hack_loop(normal, origin, id);
	self delete();
}

burnville_paratrooper_hack_loop(normal, origin, id)
{
	while(1)
	{
		playfx(id, origin);
		wait( [[level.ex_fpstime]](30 +randomfloat(40)) );
	}
}

script_print_fx()
{
	if((!isdefined (self.script_fxid)) || (!isdefined (self.script_fxcommand)) || (!isdefined (self.script_delay)))
	{
		println("Effect at origin ", self.origin," doesn't have script_fxid/script_fxcommand/script_delay");
		self delete();
		return;
	}

	if(isdefined(self.target)) org = getent (self.target).origin;
		else org = "undefined";

	if(self.script_fxcommand == "OneShotfx")
		println("maps\mp\_fx::OneShotfx(\"" + self.script_fxid + "\", " + self.origin + ", " + self.script_delay + ", " + org + ");");

	if(self.script_fxcommand == "loopfx")
		println("maps\mp\_fx::LoopFx(\"" + self.script_fxid + "\", " + self.origin + ", " + self.script_delay + ", " + org + ");");

	if(self.script_fxcommand == "loopsound")
		println("maps\mp\_fx::LoopSound(\"" + self.script_fxid + "\", " + self.origin + ", " + self.script_delay + ", " + org + ");");
}

script_playfx ( id, pos, pos2 )
{
	if(!id) return;

	if(isdefined(pos2)) playfx(id,pos,pos2);
		else playfx(id,pos);
}

script_playfxontag ( id, ent, tag )
{
	if(!id) return;

	playfxontag(id,ent,tag);
}

GrenadeExplosionfx(pos)
{
	playfx(level._effect["mechanical explosion"], pos);
	earthquake(0.15, 0.5, pos, 250);
}

soundfx(fxId, fxPos)
{
	org = spawn("script_origin",(0,0,0));
	org.origin = fxPos;
	org playloopsound(fxId);

	ent = level thread maps\mp\_createfx::createfx_showOrigin( fxId, fxPos, undefined, undefined, "soundfx" );
	ent.delay = 0;
	ent endon("effect deleted");
	ent.soundfx = org;
}
