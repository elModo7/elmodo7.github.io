init()
{
	precacheShader("overlay_low_health");
	if(level.ex_healthsystem == 2) return;

	[[level.ex_registerCallback]]("onPlayerSpawned", ::onPlayerSpawned);
	[[level.ex_registerCallback]]("onPlayerKilled", ::onPlayerKilled);
	[[level.ex_registerCallback]]("onPlayerDisconnected", ::onPlayerDisconnected);
	[[level.ex_registerCallback]]("onJoinedTeam", ::onJoinedTeam);
	[[level.ex_registerCallback]]("onJoinedSpectators", ::onJoinedSpectators);
}

onPlayerSpawned()
{
	self thread playerHealthRegen();
}

onPlayerKilled()
{
	self notify("end_healthregen");
}

onPlayerDisconnected()
{
	self notify("end_healthregen");
}

onJoinedTeam()
{
	self notify("end_healthregen");
}

onJoinedSpectators()
{
	self notify("end_healthregen");
}

playerHealthRegen()
{
	self endon("end_healthregen");

	player = self;
	maxhealth = self.health;
	oldhealth = maxhealth;
	hurtTime = 0;

	regenRate = (20 - level.ex_healthregen_rate) + 1;
	regenTick = regenRate;

	if(level.ex_healthregen_heavybreathing) thread playerBreathingSound(maxhealth * (level.ex_healthregen_heavybreathing_cutoff / 100));

	for(;;)
	{
		wait( [[level.ex_fpstime]](0.05) );
		if(player.health == maxhealth) continue;

		if(player.health <= 0 || maxhealth <= 0) return;

		if(player.health >= oldhealth)
		{
			if(gettime() - hurtTime < level.ex_healthregen_delay) continue;

			regenTick--;
			if(!regenTick)
			{
				oldhealth = player.health;
				player.health++;
				regenTick = regenRate;
			}

			continue;
		}

		oldhealth = player.health;
		hurtTime = gettime();
	}
}

playerBreathingSound(healthcap)
{
	self endon("end_healthregen");
	
	wait( [[level.ex_fpstime]](2) );
	player = self;
	better = false;

	for(;;)
	{
		wait( [[level.ex_fpstime]](0.2) );
		if(player.health <= 0) return;

		if(isDefined(player.frozenstate) && player.frozenstate == "frozen") return;

		if(player.health >= healthcap)
		{
			if(!better)
			{
				player playLocalSound("breathing_better");
				better = true;
			}
		}
		else
		{
			better = false;
			player playLocalSound("breathing_hurt");
		}

		wait( [[level.ex_fpstime]](0.784) );
		wait( [[level.ex_fpstime]](0.1 + randomfloat (0.8)) );
	}
}
