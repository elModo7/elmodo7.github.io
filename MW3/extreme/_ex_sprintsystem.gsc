#include extreme\_ex_weapons;

main()
{
	self endon("kill_thread");

	// bots do not sprint
	if(isDefined(self.pers["isbot"])) return;

	// set the variables
	self.ex_sprinttime = level.ex_sprinttime;
	self.ex_playsprint = false;

	// draw the hud elements
	if(level.ex_sprinthud) self thread sprintBar();

	// start the sprint function monitor
	self thread sprintMonitor();

	// start the sprint hud monitor
	if(level.ex_sprinthudhint) self thread sprintHintMonitor();
}

sprintMonitor()
{
	self endon("kill_thread");

	// set sprint control vars
	sprintstancetimer = 0;
	sprintstop = false;

	// reset the recover time
	recovertime = 0;

	// set the default ammo
	sprintammo = 100;

	while(isAlive(self) && self.sessionstate == "playing")
	{
		wait( [[level.ex_fpstime]](0.05) );

		sprint = (level.ex_sprinttime - self.ex_sprinttime) / level.ex_sprinttime;

		recover_check = self getWeaponSlotWeapon("primary");

		if(self.ex_sprinttime < level.ex_sprinttime && recover_check != game["sprint"])
		{
			// Don't increase sprinttime unless recovertime has passed
			if(recovertime > 0) recovertime--;
				else self.ex_sprinttime++;
		}

		// keep the sprint bar updated
		if(level.ex_sprinthud) self thread sprintBarUpdate(sprint);

		if(!self.ex_moving) continue;

		// no sprint check if player in gunship
		if( (level.ex_gunship && isDefined(level.ex_gunship_player) && level.ex_gunship_player == self) ||
		    (level.ex_gunship_special && isDefined(level.ex_gunship_splayer) && level.ex_gunship_splayer == self) ) continue;

		// wait here until they press the use key, unless they are sprinting!
		if(!self.ex_sprinting && !self useButtonPressed()) continue;

		// ok, they've pressed the use key, but for how long?
		if(!self.ex_sprinting && self useButtonPressed())
		{
			// they're still pressing use, stop the weapon monitor ready for sprinting
			self.ex_stopwepmon = true;

			count = 0;

			while(self useButtonPressed() && count < 5)
			{
				wait( [[level.ex_fpstime]](0.05) );
				count++;

				current = self getCurrentWeapon();

				if(current != self.weapon["current"].name && (current == self.weapon["oldprimary"].name || current == self.weapon["oldprimaryb"].name))
					self.weapon["current"].name = current;
			}

			// appears to be a normal weapons change
			if(count < 5)
			{
				// start the weapons monitor, false alarm!
				self.ex_stopwepmon = false;
				continue;
			}
		}

		// If sprinting and anti-run punishment in effect - stop sprinting
		if(self.ex_sprinting && level.ex_antirun && self.antirun_puninprog) sprintstop = true;

		// ok, they pressed it for long enough, maybe they want to sprint?
		if(isPlayer(self) && self useButtonPressed() && self.ex_sprinttime > 0 && !sprintstop)
		{
			// cannot sprint if weapons monitor has not stopped
			if(!self.ex_stopwepmon) continue;

			// cannot sprint if they are by an ammocrate possibly going to rearm
			if(isDefined(self.ex_amc_msg_displayed)) continue;

			// cannot sprint if planting or defusing bomb in SD or ESD
			if(isDefined(self.ex_planting) || isDefined(self.ex_defusing)) continue;
			
			// cannot sprint if not moving
			if(!self.ex_pace) continue;
			
			// cannot sprint if stance does not match
			if(self.ex_stance > (level.ex_sprint - 1))
			{
				// if already sprinting, allow stance changes for half a sec (bumps and hills)
				if(self.ex_sprinting)
				{
					if (sprintstancetimer < 10) sprintstancetimer += 1;
						else sprintstop = true;
				}
				else continue;
			}
			else sprintstancetimer = 0;

			// cannot sprint if carrying a flag (heavy flag setting)
			if(isdefined(self.flagAttached) && level.ex_sprintheavyflag)
			{
				if(self.ex_sprinting) sprintstop = true;
				self thread sprintMessage(&"SPRINT_FLAG_NO_SPRINT", 3);
				continue;
			}

			// cannot sprint if carrying a mobile mg (heavy mg setting)
			if((self.weapon["current"].name == "mobile_30cal" || self.weapon["current"].name == "mobile_mg42") && level.ex_sprintheavymg)
			{
				self thread sprintMessage(&"SPRINT_WEAPON_NO_SPRINT", 3);
				continue;
			}

			// cannot sprint if carrying a rocket launcher (heavy panzers setting)
			if(isWeaponType(self.weapon["current"].name, "rl") && level.ex_sprintheavypanzer)
			{
				self thread sprintMessage(&"SPRINT_WEAPON_NO_SPRINT", 3);
				continue;
			}

			// cannot sprint while healing
			if(isDefined(self.ex_ishealing)) continue;

			// cannot sprint while using binoculars
			if(self.ex_binocuse) continue;

			// almost ready to sprint...
			primary = self getWeaponSlotWeapon("primary");

			if(!self.ex_sprinting && primary != game["sprint"])
			{
				primaryb = self getWeaponSlotWeapon("primaryb");

				// check the primary and primaryb, have they picked up a weapon?
				if(primary != self.weapon["oldprimary"].name || primaryb != self.weapon["oldprimaryb"].name)
				{
					dupeslot = undefined;

					// which slot is this new weapon in?
					if(primary != self.weapon["oldprimary"].name) // yes it's in the primary slot!
					{
						if(!isDummy(primary)) dupeslot = "primary";
					}
					else if(primaryb != self.weapon["oldprimaryb"].name) // yes it's in the primaryb slot!
					{
						if(!isDummy(primaryb)) dupeslot = "primaryb";
					}
					else dupeslot = undefined; // no, they haven't so lets sprint!

					if(isDefined(dupeslot)) // if they have picked up a weapon by mistake, give them back the original one
					{
						debugLog(false, "sprintMonitor() detected accidental weapon pick-up (" + self getCurrentWeapon() + ")");

						// remove the original dropped weapon from the map first, so they can't get ammo from it
						entities = getentarray("weapon_" + self.weapon["old"+dupeslot].name, "classname");
						for(i = 0; i < entities.size; i++)
						{
							entity = entities[i];
							if(distance(entity.origin, self.origin) < 200) entities[i] delete();
						}

						// weapon class enabled without sidearm -- do not allow secondary weapon
						// weaponChangeMonitor is off, so we have to handle it here and now
						if(level.ex_wepo_class && !level.ex_wepo_sidearm && primaryb != "none")
						{
							debugLog(true, "sprintMonitor() detected illegal secondary weapon"); // DEBUG
							self dropItem(primaryb);
						}

						// this is the wrong weapon so drop it!
						self dropcurrentweapon();

						// give them back the right weapon for that slot
						if(isValidWeapon(self.weapon["old"+dupeslot].name))
						{
							self setWeaponSlotWeapon(dupeslot, self.weapon["old"+dupeslot].name);
							self setWeaponSlotClipAmmo(dupeslot, self.weapon["old"+dupeslot].clip);
							self setWeaponSlotAmmo(dupeslot, self.weapon["old"+dupeslot].reserve);
						}
					}
				}

				// code for dropAnim to show
				self [[level.ex_dWeapon]]();
				wait( [[level.ex_fpstime]](0.2) );

				// everything's cool, save the weapons we have now
				self notify("weaponsave");
				self waittill("weaponsaved");

				// ok, time to run... lets get the sprint weapon in the primary slot
				self setWeaponSlotWeapon("primary", game["sprint"]);
				self setWeaponSlotAmmo("primary", 0);
				self switchToWeapon(game["sprint"]);
				self [[level.ex_eWeapon]]();
				self.ex_playsprint = true;
				self thread sprintSound();
				self.ex_stopwepmon = true;
				self.ex_sprinting = true;
			}
			else
			{
				// decrease the available sprint time depending on stance
				rate = 3; // prone
				if(self.ex_stance == 0) rate = 1; // standing
				else if(self.ex_stance == 1) rate = 2; // crouching
	
				self.ex_sprinttime-= rate;
				self.ex_sprinting = true;
	
				// update the sprint ammo counter
				sprintammo = int(100 * (1.0 - sprint));
				self setWeaponSlotAmmo("primary", sprintammo);
			}
		}
		else
		{
			// stopped sprinting
			self.ex_playsprint = false;
			self.ex_sprinting = false;
			sprintstancetimer = 0;
			sprintstop = false;

			if(self getWeaponSlotWeapon("primary") == game["sprint"])
			{
				// restore the primary they had when sprint began
				if(isValidWeapon(self.weapon["oldprimary"].name))
				{
					self setWeaponSlotWeapon("primary", self.weapon["oldprimary"].name);
					self setWeaponSlotClipAmmo("primary", self.weapon["oldprimary"].clip);
					self setWeaponSlotAmmo("primary", self.weapon["oldprimary"].reserve);
				}
				else self setWeaponSlotWeapon("primary", "none");

				// restore the secondary they had when sprint began
				if(isValidWeapon(self.weapon["oldprimaryb"].name))
				{
					self setWeaponSlotWeapon("primaryb", self.weapon["oldprimaryb"].name);
					self setWeaponSlotClipAmmo("primaryb", self.weapon["oldprimaryb"].clip);
					self setWeaponSlotAmmo("primaryb", self.weapon["oldprimaryb"].reserve);
				}
				else self setWeaponSlotWeapon("primaryb", "none");

				// restore old current weapon that we have saved
				if(isValidWeapon(self.weapon["current"].name)) self switchToWeapon(self.weapon["current"].name);
				
				// reset the recover time variable
				recovertime = level.ex_sprintrecovertime;

				// calculate the recover time if full sprint time has not been used
				if(self.ex_sprinttime > 0) recovertime = int(recovertime * sprint + 0.5);

				// start the weapons monitor again
				self.ex_stopwepmon = false;
			}
		}
	}
}

sprintMessage(msg, time)
{
	self endon("kill_thread");

	if(!isDefined(self.ex_sprintmsg))
	{
		self.ex_sprintmsg = true;
		self iprintlnbold(msg);
		wait( [[level.ex_fpstime]](time) );
		[[level.ex_bclear]]("self", 5);
		self.ex_sprintmsg = undefined;
	}
}

sprintBar()
{
	self endon("kill_thread");

	self.ex_sprinthud_back = newClientHudElem(self);
	self.ex_sprinthud_back.horzAlign = "fullscreen";
	self.ex_sprinthud_back.vertAlign = "fullscreen";
	self.ex_sprinthud_back.alignX = "center";
	self.ex_sprinthud_back.alignY = "middle";
	self.ex_sprinthud_back.x = 585;
	self.ex_sprinthud_back.y = 400;
	self.ex_sprinthud_back.alpha = 1;
	self.ex_sprinthud_back setShader("gfx/hud/hud@health_back.tga", 12, 34);

	self.ex_sprinthud = newClientHudElem(self);
	self.ex_sprinthud.horzAlign = "fullscreen";
	self.ex_sprinthud.vertAlign = "fullscreen";
	self.ex_sprinthud.alignX = "center";
	self.ex_sprinthud.alignY = "middle";
	self.ex_sprinthud.x = 585;
	self.ex_sprinthud.y = 400;
	self.ex_sprinthud.alpha = 0;
	self.ex_sprinthud.color = ( 0, 0, 1);
	self.ex_sprinthud setShader("gfx/hud/hud@health_bar.tga", 10, 32);
}

sprintBarUpdate(sprint)
{
	self endon("kill_thread");

	if(isPlayer(self) && isDefined(self.ex_sprinthud))
	{
		if(self.ex_sprinttime == level.ex_sprinttime) self.ex_sprinthud.alpha = 0;
			else self.ex_sprinthud.alpha = 1;

		if(!self.ex_sprinttime) self.ex_sprinthud.color = (1.0, 0.0, 0.0);
			else self.ex_sprinthud.color = (sprint, 0, 1.0-sprint);

		hudheight = 32 - int(32 * (1.0 - sprint));
		if(hudheight < 1) hudheight = 1;
		self.ex_sprinthud setShader("gfx/hud/hud@health_back.tga", 10, hudheight);
	}
}

sprintHintMonitor()
{
	self endon("kill_thread");

	self.ex_sprinthud_hint = newClientHudElem(self);
	self.ex_sprinthud_hint.horzAlign = "fullscreen";
	self.ex_sprinthud_hint.vertAlign = "fullscreen";
	self.ex_sprinthud_hint.alignX = "right";
	self.ex_sprinthud_hint.alignY = "middle";
	self.ex_sprinthud_hint.x = 575;
	self.ex_sprinthud_hint.y = 400;
	self.ex_sprinthud_hint.fontScale = 0.7;
	self.ex_sprinthud_hint.alpha = 0;
	self.ex_sprinthud_hint setText(&"SPRINT_HINT");

	sprinthintshow = false;

	while(isAlive(self) && self.sessionstate == "playing")
	{
		wait( [[level.ex_fpstime]](0.5) );
		
		if(isPlayer(self))
		{
			if(!sprinthintshow && self.ex_sprinttime && !self.ex_sprinting && self.ex_pace && (level.ex_sprint - 1) >= self.ex_stance)
			{
				self.ex_sprinthud_hint fadeOverTime (2);
				self.ex_sprinthud_hint.alpha = 0.8;
				sprinthintshow = true;
			}
			else if(sprinthintshow && (self.ex_sprinting || !self.ex_pace || (level.ex_sprint - 1) < self.ex_stance))
			{
				self.ex_sprinthud_hint fadeOverTime (2);
				self.ex_sprinthud_hint.alpha = 0;
				sprinthintshow = false;
			}
		}
	}
}

sprintSound()
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](2) );
	self.ex_headmarker playloopsound("sprint");

	while(isPlayer(self) && self.ex_playsprint) wait( [[level.ex_fpstime]](0.1) );

	if(isPlayer(self))
	{
		stage = int(level.ex_sprinttime / 3);
		if(self.ex_sprinttime >= stage * 2) duration = 2;
			else if(self.ex_sprinttime > stage && self.ex_sprinttime < stage * 2) duration = 4;
				else duration = 8;
		self.ex_sprintreco = true;

		wait( [[level.ex_fpstime]](duration) );

		if(isPlayer(self))
		{
			self.ex_sprintreco = false;
			self.ex_headmarker stoploopsound();
			self.ex_headmarker playsound("sprintover");
		}
	}
}
