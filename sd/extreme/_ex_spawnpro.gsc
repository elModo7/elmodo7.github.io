#include extreme\_ex_weapons;

main()
{
	self endon("kill_thread");

	count = 0;
	beepcount = 0;
	exit_ads = false;
	exit_nadeuse = false;
	exit_attackuse = false;
	exit_meleeuse = false;
	exit_range = false;
	spos = self.origin;
	sdist = int(level.ex_spwn_range / 12);

	self.ex_invulnerable = true;
	self.ex_spawnprotected = true;

	if(level.ex_spwn_headicon)
	{
		self.headicon = game["headicon_protect"];
		self.headiconteam = "none";
	}

	if(level.ex_spwn_hud)
	{
		if(!isDefined(self.ex_spwpro)) self.ex_spwpro = newClientHudElem(self);
		self.ex_spwpro.horzAlign = "fullscreen";
		self.ex_spwpro.vertAlign = "fullscreen";
		self.ex_spwpro.alignX = "center";
		self.ex_spwpro.alignY = "middle";
		self.ex_spwpro.x = 620;
		self.ex_spwpro.y = 385;
		self.ex_spwpro.alpha = level.ex_iconalpha;
		self.ex_spwpro setShader(game["mod_protect_hudicon"], 28, 28);
		self.ex_spwpro scaleOverTime(.5, 26, 26);

		if(level.ex_spwn_hud == 2)
		{
			if(!isDefined(self.ex_spwpro_time1)) self.ex_spwpro_time1 = newClientHudElem(self);
			self.ex_spwpro_time1.horzAlign = "fullscreen";
			self.ex_spwpro_time1.vertAlign = "fullscreen";
			self.ex_spwpro_time1.alignX = "left";
			self.ex_spwpro_time1.alignY = "middle";
			self.ex_spwpro_time1.x = 140;
			self.ex_spwpro_time1.y = 375;
			self.ex_spwpro_time1.fontScale = 0.8;
			self.ex_spwpro_time1.color = (1,1,1);
			self.ex_spwpro_time1.alpha = 1;
			self.ex_spwpro_time1.label = &"SPAWNPROTECTION_TIME";
			self.ex_spwpro_time1 setValue(level.ex_spwn_time);

			if(!isDefined(self.ex_spwpro_time2)) self.ex_spwpro_time2 = newClientHudElem(self);
			self.ex_spwpro_time2.horzAlign = "fullscreen";
			self.ex_spwpro_time2.vertAlign = "fullscreen";
			self.ex_spwpro_time2.alignX = "left";
			self.ex_spwpro_time2.alignY = "middle";
			self.ex_spwpro_time2.x = 140;
			self.ex_spwpro_time2.y = 385;
			self.ex_spwpro_time2.fontScale = 1;
			self.ex_spwpro_time2.color = (0,1,0);
			self.ex_spwpro_time2.alpha = 1;
			self.ex_spwpro_time2 setValue(level.ex_spwn_time);

			if(level.ex_spwn_range)
			{
				if(!isDefined(self.ex_spwpro_dist1)) self.ex_spwpro_dist1 = newClientHudElem(self);
				self.ex_spwpro_dist1.horzAlign = "fullscreen";
				self.ex_spwpro_dist1.vertAlign = "fullscreen";
				self.ex_spwpro_dist1.alignX = "left";
				self.ex_spwpro_dist1.alignY = "middle";
				self.ex_spwpro_dist1.x = 140;
				self.ex_spwpro_dist1.y = 400;
				self.ex_spwpro_dist1.fontScale = 0.8;
				self.ex_spwpro_dist1.color = (1,1,1);
				self.ex_spwpro_dist1.alpha = 1;
				self.ex_spwpro_dist1.label = &"SPAWNPROTECTION_RANGE";
				self.ex_spwpro_dist1 setValue(sdist);

				if(!isDefined(self.ex_spwpro_dist2)) self.ex_spwpro_dist2 = newClientHudElem(self);
				self.ex_spwpro_dist2.horzAlign = "fullscreen";
				self.ex_spwpro_dist2.vertAlign = "fullscreen";
				self.ex_spwpro_dist2.alignX = "left";
				self.ex_spwpro_dist2.alignY = "middle";
				self.ex_spwpro_dist2.fontScale = 1;
				self.ex_spwpro_dist2.x = 140;
				self.ex_spwpro_dist2.y = 410;
				self.ex_spwpro_dist2.color = (0,1,0);
				self.ex_spwpro_dist2.alpha = 1;
				self.ex_spwpro_dist2 setValue(sdist);
			}
		}
	}

	if(level.ex_spwn_invisible) msg1 = &"SPAWNPROTECTION_ENABLED_INVISIBLE";
		else msg1 = &"SPAWNPROTECTION_ENABLED";
	msg2 = extreme\_ex_utils::time_convert(level.ex_spwn_time);

	switch(level.ex_spwn_msg)
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

	if(level.ex_spwn_wepdisable) self [[level.ex_dWeapon]]();

	// Invisible Spawn Protection ON
	// WARNING: also part of pre-spawn settings in ex_main::exPreSpawn()
	if(level.ex_spwn_invisible) self hide();

	while(isAlive(self) && self.sessionstate == "playing" && self.ex_invulnerable)
	{
		if(count >= level.ex_spwn_time) break;

		currweapon = self getCurrentWeapon();
		if( (!isDefined(self.ex_disabledWeapon) || !self.ex_disabledWeapon) && isValidWeapon(currweapon) && !isDummy(currweapon))
		{
			if(self playerAds())
			{
				exit_ads = true;
				break;
			}
			if(self.usedweapons)
			{
				exit_nadeuse = true;
				break;
			}
			if(self attackButtonPressed())
			{
				exit_attackuse = true;
				break;
			}
			if(self meleeButtonPressed())
			{
				exit_meleeuse = true;
				break;
			}
		}

		if(level.ex_spwn_range && !isdefined(self.ex_isparachuting))
		{
			distmoved = distance(spos, self.origin);
			if(level.ex_spwn_hud == 2)
			{
				sdist = level.ex_spwn_range - distmoved;
				sdistperc = 1 - (sdist / level.ex_spwn_range);
				self.ex_spwpro_dist2 setValue( int(sdist / 12) );
				self.ex_spwpro_dist2.color = (sdistperc, 1 - sdistperc, 0);
			}
			if(distmoved > level.ex_spwn_range)
			{
				exit_range = true;
				break;
			}
		}

		wait( [[level.ex_fpstime]](0.05) );

		beepcount++;
		if(beepcount == 20)
		{
			if(!isdefined(self.ex_isparachuting))
			{
				count++;
				if(level.ex_spwn_hud == 2 && isDefined(self.ex_spwpro_time2))
				{
					self.ex_spwpro_time2 setValue(level.ex_spwn_time - count);
					if(level.ex_spwn_time <= 3 || (count >= level.ex_spwn_time - 3) ) self.ex_spwpro_time2.color = (1,0,0);
				}
			}
			if(level.ex_spwn_headicon && !isDefined(self.ex_crybaby))
			{
				self.headicon = game["headicon_protect"];
				self.headiconteam = "none";
			}
			beepcount = 0;
		}
	}

	msg3 = undefined;

	if(exit_ads) msg3 = &"SPAWNPROTECTION_TOOK_AIM";
	if(exit_attackuse || exit_meleeuse) msg3 = &"SPAWNPROTECTION_FIRE_BUTTON_PRESSED";
	if(self.sessionstate == "playing" && exit_range) msg3 = &"SPAWNPROTECTION_MOVED_AWAY_AREA";

	if(isdefined(msg3))
	{
		switch(level.ex_spwn_msg)
		{
			case 0: self iprintln(msg3); break;
			default: self iprintlnbold(msg3); break;
		}
	}

	// restore the headicon if changed
	if(level.ex_spwn_headicon && self.sessionstate == "playing")
	{
		if(level.ex_currentgt == "hm")
			self thread maps\mp\gametypes\hm::Headicon_Restore();
		else
			self thread extreme\_ex_utils::restoreHeadicon(game["headicon_protect"]);
	}

	msg4 = &"SPAWNPROTECTION_DISABLED";

	switch(level.ex_spwn_msg)
	{
		case 0: self iprintln(msg4); break;
		default: self iprintlnbold(msg4); break;
	}

	if(isdefined(self.ex_spwpro)) self.ex_spwpro destroy();
	if(isdefined(self.ex_spwpro_time1)) self.ex_spwpro_time1 destroy();
	if(isdefined(self.ex_spwpro_time2)) self.ex_spwpro_time2 destroy();
	if(isdefined(self.ex_spwpro_dist1)) self.ex_spwpro_dist1 destroy();
	if(isdefined(self.ex_spwpro_dist2)) self.ex_spwpro_dist2 destroy();

	// Invisible Spawn Protection OFF
	if(level.ex_spwn_invisible) self show();

	if(level.ex_spwn_wepdisable) self [[level.ex_eWeapon]]();
	self.ex_spawnprotected = undefined;
	self.ex_invulnerable = false;
}

punish(reason)
{
	self endon("kill_thread");

	if(isDefined(self.ex_spwn_punish)) return;
	self.ex_spwn_punish = true;

	// spawn protection punishment threshold reset
	if(level.ex_spwn_punish_threshold) self.ex_spwn_punish_counter = 0;

	if(isPlayer(self))
	{
		if(reason == "abusing")
		{
			iprintln(&"SPAWNPROTECTION_PUNISH_ABUSER_MSG", [[level.ex_pname]](self));
			self iprintlnbold(&"SPAWNPROTECTION_PUNISH_ABUSER_PMSG");
		}

		if(reason == "attacking" || reason == "turretattack")
		{
			iprintln(&"SPAWNPROTECTION_PUNISH_ATTACKER_MSG", [[level.ex_pname]](self));
			self iprintlnbold(&"SPAWNPROTECTION_PUNISH_ATTACKER_PMSG");
		}
	}

	if(reason == "turretattack")
	{
		if(isPlayer(self)) self thread extreme\_ex_utils::execClientCommand("-attack; +activate; wait 10; -activate");
	}
	else
	{
		pun = randomInt(100);

		if(pun < 50)
		{
			if(isPlayer(self)) self [[level.ex_dWeapon]]();
			wait( [[level.ex_fpstime]](2) );
		}
		else for(i = 0; i < 2; i++)
		{
			if(isPlayer(self)) self extreme\_ex_weapons::dropcurrentweapon();
			wait( [[level.ex_fpstime]](1) );
		}

		if(isPlayer(self))
		{
			if(reason == "abusing") self iprintlnbold(&"SPAWNPROTECTION_FREE_ABUSER_PMSG");
			else if(reason == "attacking") self iprintlnbold(&"SPAWNPROTECTION_FREE_ATTACKER_PMSG");

			self [[level.ex_eWeapon]]();
			self.ex_spwn_punish = undefined;
		}
	}
}
