
main()
{
	self endon("kill_thread");

	if(!isDefined(self.ex_firstaidicon))
	{
		self.ex_firstaidicon = newClientHudElem(self);			
		self.ex_firstaidicon.archived = true;
		self.ex_firstaidicon.horzAlign = "fullscreen";
		self.ex_firstaidicon.vertAlign = "fullscreen";
		self.ex_firstaidicon.alignX = "center";
		self.ex_firstaidicon.alignY = "middle";
		self.ex_firstaidicon.x = 575;
		self.ex_firstaidicon.y = 470;
		self.ex_firstaidicon.alpha = 1;
		self.ex_firstaidicon setShader(game["firstaidicon"], 16, 16);
	}

	if(!isDefined(self.ex_firstaidval))
	{
		self.ex_firstaidval = newClientHudElem(self);
		self.ex_firstaidval.archived = true;
		self.ex_firstaidval.horzAlign = "fullscreen";
		self.ex_firstaidval.vertAlign = "fullscreen";
		self.ex_firstaidval.alignX = "center";
		self.ex_firstaidval.alignY = "middle";
		self.ex_firstaidval.x = 565;
		self.ex_firstaidval.y = 469;
		self.ex_firstaidval.fontScale = 1;
		self.ex_firstaidval.alpha = 1;
		if(self.ex_firstaidkits > 0) self.ex_firstaidval.color = (1, 1, 1);
			else self.ex_firstaidval.color = (1, 0, 0);
		self.ex_firstaidval setValue(self.ex_firstaidkits);
	}

	self.ex_canheal = true;
	self.ex_targetplayer = undefined;

	while(isPlayer(self) && isDefined(self.ex_firstaidicon) && self.sessionstate != "spectator")
	{
		wait( [[level.ex_fpstime]](0.5) );

		if(isPlayer(self) && (self useButtonPressed()) && self isOnGround() && self.ex_canheal)
		{
			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				if(players[i] == self && !level.ex_medic_self) continue; // not allowed to heal yourself
				if(players[i].sessionstate == "dead" || players[i].sessionstate == "spectator") continue; // not playing
				if(level.ex_teamplay && players[i].pers["team"] != self.pers["team"]) continue; // not a teammate

				if(players[i].health <= 80 && // must be injured
					!isDefined(players[i].gettingfirstaid) && // and not currently being treated
					distance(players[i].origin, self.origin) < 12) // and within 4 feet of player
				{
					if(!level.ex_teamplay)
					{
						if(players[i] == self)
						{
							self.ex_targetplayer = players[i];
							break;
						}
					}
					else
					{
						self.ex_targetplayer = players[i];
						break;
					}					
				}
			}

			// not in range of any friendlies that need healing
			if(!isDefined(self.ex_targetplayer)) continue;

			// all systems go, commence healing
			// make sure they mean it, are holding USE for half a second
			holdtime = 0;

			while(isalive(self) && isalive(self.ex_targetplayer) // both still alive
				&& self useButtonPressed() && holdtime < 0.5
				&& self isOnGround() && self.ex_targetplayer isOnGround()
				&& distance(self.ex_targetplayer.origin, self.origin) < 12)
			{
				holdtime += 0.05;
				wait( [[level.ex_fpstime]](0.05) );
			}

			if(holdtime < 0.5) continue;

			if(isPlayer(self))
			{
				// can't heal while defusing a bomb	
				if(isDefined(self.defuseicon)) continue;
	
				// can't heal while moving
				if(isDefined(self.ex_moving) && self.ex_moving) continue;
	
				// can't heal if calling in mortars, artillery or an airstrike
				if(self.ex_binocuse) continue;
	
				// can't heal if target players health is 100%
				if(self.ex_targetplayer.health == 100) continue;
	
				// can't heal near ammo crates
				if(isDefined(self.ex_amc_check)) continue;
	
				//stop them flashing on compass as needing medic
				self.ex_targetplayer.needshealing = false;
		
				healamount = (level.ex_medic_minheal + randomInt(level.ex_medic_maxheal - level.ex_medic_minheal));
				healtime = int(healamount / 2) * .1;
				
				self playlocalsound("medi_bag");
				self.ex_targetplayer shellshock("medical", 4);
				self [[level.ex_dWeapon]]();
	
				// fade counter
				if(isDefined(self.ex_firstaidval))
				{
					self.ex_firstaidval fadeOverTime(1);
					self.ex_firstaidval.alpha = 0;
				}
	
				if(isDefined(self.ex_firstaidicon))
					self.ex_firstaidicon scaleOverTime(healtime, 20, 20);
		
				healnow = 0;
				holdtime = 0;
				beepcount = 0;
				sprintcount = 0;
	
				while(isalive(self) && isalive(self.ex_targetplayer) // both still alive
					&& self useButtonPressed() // still holding the USE key
					&& !(self meleeButtonPressed()) // player hasn't melee'd
					&& !(self.ex_targetplayer meleeButtonPressed()) // target hasn't melee'd
					&& !(self attackButtonPressed()) // player hasn't fired
					&& !(self.ex_targetplayer attackButtonPressed()) // target hasn't fired
					&& self.ex_targetplayer.health < 100 // hasn't filled target's health
					&& healamount > 0) // hasn't run out of healamount
				{
					if(healnow == 1)
					{
						self.ex_targetplayer.health++;	 // 10 health per second, 1 point every other 1/20th of a second (server frame) had to do that 'cause of integer rounding issues
						healamount--;
						healnow = -1;
	
						self.ex_ishealing = true;
					}
	
					healnow++;
					beepcount++;
					sprintcount++;
					holdtime += 0.05;
					wait( [[level.ex_fpstime]](0.05) );
	
					// still recover from sprint
					if(level.ex_sprint && sprintcount > 1)
					{
						if(self.ex_sprinttime < level.ex_sprinttime)
							self.ex_sprinttime++;
						
						sprintcount = 0;
					}

					if(beepcount > 20)
					{
						if(self.health >70)
						{
							self playlocalsound("medi_use_high");
							beepcount = 0;
						}
						else
						{
							self playlocalsound("medi_use_low");
							beepcount = 0;
						}
					}
				}
	
				if(isDefined(self.ex_ishealing)) self.ex_ishealing = undefined;
	
				if(isPlayer(self.ex_targetplayer)) self.ex_targetplayer playsound("sprintover");
	
				if((healamount == 0 || self.ex_targetplayer.health == 100) && isalive(self.ex_targetplayer) && isalive(self))
				{
					if(self.name == self.ex_targetplayer.name)
					{
						iprintln(&"FIRSTAID_APPLIED_SELF", [[level.ex_pname]](self));
						self playSound("health_pickup_medium");
					}
					else
					{
						iprintln(&"FIRSTAID_APPLIED_TEAM_MSG1", [[level.ex_pname]](self.ex_targetplayer));
						iprintln(&"FIRSTAID_APPLIED_TEAM_MSG2", [[level.ex_pname]](self));
						self playSound("health_pickup_medium");
						self.score++;
						self.pers["bonus"]++;
						self notify("update_playerscore_hud");
					}
				}
	
				if(isDefined(self.ex_firstaidicon)) self.ex_firstaidicon scaleOverTime(1, 16, 16);
	
				self.ex_firstaidkits--;
				self [[level.ex_eWeapon]]();
	
				if(isDefined(self.ex_firstaidval))
				{
					self.ex_firstaidval setValue(self.ex_firstaidkits);
					if(self.ex_firstaidkits > 0) self.ex_firstaidval.color = (1, 1, 1);
						else self.ex_firstaidval.color = (1, 0, 0);
				}
	
				// fadein counter
				if(isDefined(self.ex_firstaidval))
				{
					self.ex_firstaidval fadeOverTime(1);
					self.ex_firstaidval.alpha = 1;
				}
	
				wait( [[level.ex_fpstime]](0.5) );

				if(isPlayer(self))
				{				
					if(self.ex_firstaidkits == 0) self.ex_canheal = false;
		
					if(level.ex_firstaid_kits_msg)
					{
						if(self.ex_firstaidkits >= 2) self iprintlnbold(&"FIRSTAID_YOU_HAVE_NUMBER_LEFT", self.ex_firstaidkits);
							else if(self.ex_firstaidkits == 1) self iprintlnbold(&"FIRSTAID_ONE_KIT_LEFT");
								else if (self.ex_firstaidkits == 0) self iprintlnbold(&"FIRSTAID_NO_KIT_LEFT");
					}
	
					// Remove bulletholes if present
					if(level.ex_bulletholes && isDefined(self.ex_targetplayer.ex_bulletholes) && self.ex_targetplayer.health == 100 && isalive(self.ex_targetplayer))
					{
						for(i=0;i<self.ex_targetplayer.ex_bulletholes.size;i++)
						{
							if(isDefined(self.ex_targetplayer.ex_bulletholes[i])) self.ex_targetplayer.ex_bulletholes[i] destroy();
						}
					}
				
					if(isDefined(self.spamdelay)) self.spamdelay = undefined;
				}
			}
		}
	}
}

disablePlayerHealing()
{
	self endon("kill_thread");

	self.ex_canheal = false;

	if(isDefined(self.ex_firstaidval)) self.ex_firstaidval.alpha = 0;
	if(isDefined(self.ex_firstaidicon)) self.ex_firstaidicon.alpha = 0;
	
	self thread shownohealtime(level.ex_medic_penalty);
	self waittill("fa_punishover");

	if(isDefined(self.ex_firstaidval))
	{
		self.ex_firstaidval.alpha = 1;
		if(self.ex_firstaidkits > 0) self.ex_firstaidval.color = (1, 1, 1);
			else self.ex_firstaidval.color = (1, 0, 0);
	}

	if(isDefined(self.ex_firstaidicon)) self.ex_firstaidicon.alpha = 1;
}

shownohealtime(sec)
{
	self endon("kill_thread");

	if(isDefined(self.ex_noheal))
	{
		self.ex_extrapen = true;
		return;
	}

	msg1 = &"FIRSTAID_DISABLED";
	msg2 = extreme\_ex_utils::time_convert(sec);

	switch(level.ex_medic_penalty_msg)
	{
		case 0:
			self iprintln(msg1);
			self iprintln(msg2);
			break;
		default:
			self iprintlnbold(msg1);
			self iprintlnbold(msg2);
			break;
	}

	self.ex_noheal = true;

	while(isAlive(self) && sec >= 1 && self.sessionstate == "playing")
	{
		if(isDefined(self.ex_extrapen))
		{
			sec = sec + 10;
			if(sec >= 60) sec = 60;
			self.ex_extrapen = undefined;

			msg1 = &"FIRSTAID_DISABLED";
			msg2 = extreme\_ex_utils::time_convert(sec);

			switch(level.ex_medic_penalty_msg)
			{
				case 0:
					self iprintln(msg1);
					self iprintln(msg2);
					break;
				default:
					self iprintlnbold(msg1);
					self iprintlnbold(msg2);
					break;
			}
		}

		sec--;

		wait( [[level.ex_fpstime]](1) );
	}

	if(isPlayer(self))
	{
		self notify("fa_punishover");
		self.ex_canheal = true;
		self.ex_noheal = undefined;
	}
}

callformedic()
{
	self endon("kill_thread");

	if(!isDefined(self.pers["team"]) || self.pers["team"] == "spectator") return;

	if(isDefined(self.spamdelay))
	{
		if(level.ex_medicsystem != 1) self iprintlnbold(&"FIRSTAID_SPAMMER");
		return;
	}

	if(!level.ex_teamplay)
	{
		if(level.ex_medicsystem == 2) self iprintlnbold(&"FIRSTAID_NOT_TEAM_BASED");
		return;
	}

	if(!isDefined(self.pers["team"]) || self.pers["team"] == "spectator" || !level.ex_medicsystem)
	{
		self iprintlnbold(&"FIRSTAID_UNAVAILABLE");
		return;
	}

	self.spamdelay = true;
	soundalias = undefined;

	if(level.ex_medicsystem)
	{
		if (self.pers["team"] == "allies")
		{
			switch(game["allies"])
			{
				case "american":
				soundalias = "american_medic";
				break;
				
				case "british":
				soundalias = "british_medic";
				break;
		
				default:
				soundalias = "russian_medic";
				break;
			}
		}
		else if (self.pers["team"] == "axis")
		{
			switch(game["axis"])
			{
				case "german":
				soundalias = "german_medic";
				break;
			}
		}
	}

	self maps\mp\gametypes\_quickmessages::doQuickMessage(soundalias, &"FIRSTAID_MEDIC_CALL", false);

	if(isPlayer(self) && level.ex_medic_showinjured)
	{
		self.needshealing = true;
		self thread ShowInjured();
	}

	wait( [[level.ex_fpstime]](2) );

	if(isPlayer(self)) self.spamdelay = undefined;
}

ShowInjured()
{
	self endon("kill_thread");

	while(isalive(self) && self.needshealing && self.sessionstate == "playing")
	{
		wait( [[level.ex_fpstime]](level.ex_medic_showinjured_time) );
		self pingPlayer();
	}
}
