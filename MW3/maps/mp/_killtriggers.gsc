#include extreme\_ex_utils;

init()
{
	if(isdefined(level.killtriggers))
	{
		for(i = 0; i < level.killtriggers.size; i++)
		{
			killtrigger = level.killtriggers[i];
			killtrigger.origin = (killtrigger.origin[0], killtrigger.origin[1], (killtrigger.origin[2] - 16));
		}

		for(;;)
		{
			counter = 0;
			
			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				
				if(isdefined(player) && isdefined(player.pers["team"]) && player.pers["team"] != "spectator" && player.sessionstate == "playing")
				{
					player checkKillTriggers();
					counter++;
					
					if(!(counter % 4))
					{
						wait( [[level.ex_fpstime]](0.05) );
						counter = 0;
					}
				}
			}
			
			wait( [[level.ex_fpstime]](0.05) );
		}
	}
}

checkKillTriggers()
{
	if(!isDefined(self.pers["killtrigger"])) self.pers["killtrigger"] = 0;

	if(isDefined(self.ex_isparachuting)) return;

	for(i = 0; i < level.killtriggers.size; i++)
	{
		killtrigger = level.killtriggers[i];
		if(self touchingTrigger(killtrigger))
		{
			if(isDefined(killtrigger.warppos))
			{
				// people get stuck here, so warp to new position
				randwarp = randomint(killtrigger.warppos.size);
				self setOrigin(killtrigger.warppos[randwarp]);
			}
			else if(isDefined(level.ex_killtriggers) && level.ex_killtriggers)
			{
				if(isDefined(killtrigger.delay)) wait( [[level.ex_fpstime]](killtrigger.delay) );

				if(self touchingTrigger(killtrigger))
				{
					if(level.ex_killtriggers == 2) self.pers["killtrigger"]++;
					// warn and kill the perp
					self iprintlnbold(&"EXPLOITS_PLAYER_WARNING", [[level.ex_pname]](self));
					wait( [[level.ex_fpstime]](3) );
					if(isPlayer(self) && (level.ex_killtriggers == 1 || self.pers["killtrigger"] >= level.ex_killtriggers_warn))
					{
						self.ex_forcedsuicide = true;
						self suicide();
						return;
					}
				}
			}
		}
	}
}

touchingTrigger(killtrigger)
{
	if((self.origin[2] >= killtrigger.origin[2]) && (self.origin[2] <= killtrigger.origin[2] + killtrigger.height))
	{
		diff1 = killtrigger.origin - self.origin;
		diff2 = (diff1[0], diff1[1], 0);
		if(length(diff2) < killtrigger.radius + 16) return(true);
			else return(false);
	}

	return(false);
}
