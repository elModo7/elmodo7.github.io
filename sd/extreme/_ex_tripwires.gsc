#include extreme\_ex_weapons;

main()
{
	self endon("kill_thread");

	while(isPlayer(self) && self.sessionstate == "playing")
	{
		wait( [[level.ex_fpstime]](0.5) );

		frag = false;
		smoke = false;
		combo = false;
		trip = "none";

		// if not planting or defusing a tripwire and the tripwire message is displayed, clear the message from the hud
		if((!self.ex_plantwire && !self.ex_defusewire) && self [[level.ex_getstance]](false) != 2 && (isDefined(self.ex_expmsg1) || isDefined(self.ex_pb)))
		{
			self thread cleanMessages();

			// if ammo crates is on, and they are not rearming at an ammo crate then make sure the bar graphic is not showing
			if(level.ex_amc_perteam && !isDefined(self.ex_amc_rearm)) self thread extreme\_ex_utils::cleanBarGraphic();
		}

		// if not prone, continue monitoring
		if(self [[level.ex_getstance]](false) != 2)
		{
			// show WMD deployment
			if(isDefined(self.ex_binocular_hint) && !isDefined(self.ex_actimer)) self.ex_binocular_hint.alpha = 1;
		 	// hide WMD display if they are on turret
			if(isDefined(self.onturret) && isDefined(self.ex_binocular_hint)) self.ex_binocular_hint.alpha = 0;
			continue;
		}

		// disable tripwire & displays while using or with turret
		if(isDefined(self.onturret) || isWeaponType(self getCurrentWeapon(), "turret")) 
		{   
			self thread cleanMessages();
			if(isDefined(self.ex_binocular_hint)) self.ex_binocular_hint.alpha = 0;
			continue;
		}

		// check available nades
		frags = getCurrentAmmo(self.pers["fragtype"]);
		smokes = getCurrentAmmo(self.pers["smoketype"]);

		// teams share the same weapon file for special frags, so if one them is enabled, skip enemy frags
		if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) enemy_frags = 0;
			else enemy_frags = getCurrentAmmo(self.pers["enemy_fragtype"]);
		enemy_smokes = getCurrentAmmo(self.pers["enemy_smoketype"]);

		total_frags = frags + enemy_frags;
		total_smokes = smokes + enemy_smokes;

		// need at least 2. If not enough nades, continue monitoring
		if((total_frags + total_smokes < 2) || self.ex_plantwire || self.ex_defusewire) continue;

		// hide WMD deployment
		if(isDefined(self.ex_binocular_hint)) self.ex_binocular_hint.alpha = 0;

		// player has enough nades, but is planting/defusing in progress?
		if(!self.ex_plantwire && !self.ex_defusewire)
		{
			if(isPlayer(self) && !isDefined(self.ex_expmsg1) && !isWeaponType(self getCurrentWeapon(), "sniper")) // no sniper rifle
				self showTripwireMessage(undefined, undefined, &"TRIPWIRE_CHOOSE_GRENADE");

			// hide WMD deployment
			if(isDefined(self.ex_binocular_hint)) self.ex_binocular_hint.alpha = 0;

			// if they're not holding down the melee key, loop
			if(!self meleeButtonPressed()) continue;

			// if this is a sniper (chance of ADS) trying to plant a tripwire, display message and abort
			if(isPlayer(self) && !isDefined(self.ex_expmsg1) && isWeaponType(self getCurrentWeapon(), "sniper"))
			{
				if(level.ex_wepo_class == 2 && !level.ex_wepo_sidearm) self showTripwireMessage(undefined, undefined, &"TRIPWIRE_SNIPER_ONLY");
					else self showTripwireMessage(undefined, undefined, &"TRIPWIRE_CHANGE_SNIPER");

				wait( [[level.ex_fpstime]](2) );
				if(isPlayer(self)) self cleanMessages();
				continue;
			}

			// check for frags
			frag1type = self.pers["fragtype"];
			frag2type = self.pers["fragtype"];

			// not enough of their own teams, so check for enemy frags too
			if(frags <= 1)
			{
				if(frags == 1 && enemy_frags >= 1) // mix own frag and enemy frags
				{
					frag2type = self.pers["enemy_fragtype"];
					frag = true;
				}
				else if(frags == 0 && enemy_frags >= 2) // enemy frags only
				{
					frag1type = self.pers["enemy_fragtype"];
					frag2type = self.pers["enemy_fragtype"];
					frag = true;
				}
			}
			else frag = true; // got enough of their own frags

			// check for frag/smoke combination
			comb1type = self.pers["fragtype"];
			comb2type = self.pers["fragtype"];

			if(frags >= 1)
			{
				if(smokes >= 1) // mix own frag and own smoke
				{
					comb2type = self.pers["smoketype"];
					combo = true;
				}
				else if(enemy_smokes >= 1) // mix own frag and enemy smoke
				{
					comb2type = self.pers["enemy_smoketype"];
					combo = true;
				}
			}

			if(!combo && enemy_frags >= 1)
			{
				if(smokes >= 1) // mix enemy frag and own smoke
				{
					comb1type = self.pers["enemy_fragtype"];
					comb2type = self.pers["smoketype"];
					combo = true;
				}
				else if(enemy_smokes >= 1) // mix own frag and enemy smoke
				{
					comb1type = self.pers["enemy_fragtype"];
					comb2type = self.pers["enemy_smoketype"];
					combo = true;
				}
			}

			// check for smokes
			smoke1type = self.pers["smoketype"];
			smoke2type = self.pers["smoketype"];

			// not enough of their own teams, so check for enemy frags too
			if(smokes <= 1)
			{
				if(smokes == 1 && enemy_smokes >= 1) // mix own smoke and enemy smoke
				{
					smoke2type = self.pers["enemy_smoketype"];
					smoke = true;
				}
				else if(smokes == 0 && enemy_smokes >= 2) // enemy smokes only
				{
					smoke1type = self.pers["enemy_smoketype"];
					smoke2type = self.pers["enemy_smoketype"];
					smoke = true;
				}
			}
			else smoke = true; // got enough of their own smokes

			// ok, lets see what they want to plant
			count = 0;
			while(self meleeButtonPressed() && count < level.ex_tweapon_htime && self [[level.ex_getstance]](true) == 2)
			{
				wait( [[level.ex_fpstime]](0.05) );
				count++;
			}
	
			// didn't hold down long enough, loop
			if(count < level.ex_tweapon_htime) continue;
			
			// check if too close to spawn/flag points
			if(isPlayer(self) && (self tooCloseSpawnpointsorFlag()))
			{
				self cleanMessages();
				continue;
			}
			
			// if they have enough frags, display the frag tripwire message
			if(frag)
			{
				self playLocalSound("tripclick");
				trip = "frag";
				if(combo) self showTripwireMessage(frag1type, frag2type, &"TRIPWIRE_HOLD_COMBO");
					else if(smoke) self showTripwireMessage(frag1type, frag2type, &"TRIPWIRE_HOLD_SMOKE");
						else self showTripwireMessage(frag1type, frag2type, &"TRIPWIRE_RELEASE_CANCEL");

				// if they let go here, they want to use frag grenades		
				count = 0;
				while(self meleeButtonPressed() && count < level.ex_tweapon_htime && self [[level.ex_getstance]](true) == 2)
				{
					wait( [[level.ex_fpstime]](0.05) );
					count++;
				}
			}
			else count = level.ex_tweapon_htime; // no frags!

			// if they have a combination of frag and smoke, display the combo tripwire message
			if(combo)
			{
				if(count >= level.ex_tweapon_htime) // they kept holding so show the combo
				{
					self playLocalSound("tripclick");
					trip = "combo";
					if(smoke) self showTripwireMessage(comb1type, comb2type, &"TRIPWIRE_HOLD_SMOKE");
						else self showTripwireMessage(comb1type, comb2type, &"TRIPWIRE_RELEASE_CANCEL");
				}	

				// if they let go here, they want to use combo trip
				count = 0;
				while(self meleeButtonPressed() && count < level.ex_tweapon_htime && self [[level.ex_getstance]](true) == 2)
				{
					wait( [[level.ex_fpstime]](0.05) );
					count++;
				}
			}
			else count = level.ex_tweapon_htime; // no combo!

			// if they have enough smokes, display the smoke tripwire message
			if(smoke)
			{
				if(count >= level.ex_tweapon_htime) // they kept holding so show the smokes
				{
					self playLocalSound("tripclick");
					trip = "smoke";
					if(frag) self showTripwireMessage(smoke1type, smoke2type, &"TRIPWIRE_HOLD_FRAG");
						else self showTripwireMessage(smoke1type, smoke2type, &"TRIPWIRE_RELEASE_CANCEL");
				}
			}

			// if they let go here, it will use the smokes. continue to hold and it will cancel planting a tripwire
			count = 0;
			while(self meleeButtonPressed() && count < level.ex_tweapon_htime && self [[level.ex_getstance]](true) == 2)
			{
				wait( [[level.ex_fpstime]](0.05) );
				count++;
			}

			// they held on, so they don't want to plant a tripwire, or missed the one they wanted...doh!
			if(count >= level.ex_tweapon_htime)
			{
				trip = "none";
				self cleanMessages();
			}

			// check to see if they got up during this process?	
			if(self [[level.ex_getstance]](true) != 2) continue;

			// ok, good to go...
			if(trip == "frag") self thread plantTripwire(frag1type, frag2type);
				else if(trip == "combo") self thread plantTripwire(comb1type, comb2type);
					else if(trip == "smoke") self thread plantTripwire(smoke1type, smoke2type);
		}
	}
}

plantTripwire(grenadetype1, grenadetype2)
{
	self endon("kill_thread");
	self endon("defusingtripwire");

	if(isPlayer(self))
	{
		// Make sure to only run one instance
		if(self.ex_plantwire) return;
	
		self.ex_plantwire = true;

		// show the plant message
		self showTripwireMessage(grenadetype1, grenadetype2, &"TRIPWIRE_PLANT");

		// while there not pressing the melee key, monitor to see if they leave the prone position
		while(isPlayer(self) && self.sessionstate == "playing" && !(self meleeButtonPressed()))
		{
			if(self [[level.ex_getstance]](true) != 2)
			{
				self cleanMessages();
				self.ex_plantwire = false;
				return;
			}
			
			wait( [[level.ex_fpstime]](0.05) );
		}

		// loop
		if(isPlayer(self))
		{
			for(;;)
			{
				// check the amount of ammo, might have thrown a grenade
				if(grenadetype1 == grenadetype2) iAmmo = self getCurrentAmmo(grenadetype1);
					else iAmmo = self getCurrentAmmo(grenadetype1) + self getCurrentAmmo(grenadetype2);
	
				// not enough ammo?
				if(iAmmo < 2) break;
		
				// check they're still prone
				if(self [[level.ex_getstance]](false) != 2) break;
		
				// get the position 15" in front of the player
				position = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles),15);
		
				// check that there is room.
				trace=bulletTrace(self.origin+(0,0,10),position+(0,0,10),false,undefined);
				if(trace["fraction"] !=1)
				{
					self iprintlnbold(&"TRIPWIRE_REASON_NO_ROOM");
					break;
				}
			
				// find ground
				trace=bulletTrace(position+(0,0,10),position+(0,0,-10),false,undefined);
				if(trace["fraction"] ==1)
				{
					self iprintlnbold(&"TRIPWIRE_REASON_UNEVEN_GROUND");
					break;
				}
		
				if(isDefined(trace["entity"]) && isDefined(trace["entity"].classname) && trace["entity"].classname == "script_vehicle") break;
		
				position=trace["position"];
				tracestart = position + (0,0,10);
		
				// find position 1
				traceend = tracestart + [[level.ex_vectorscale]](anglesToForward(self.angles + (0,90,0)),50);
				trace=bulletTrace(tracestart,traceend,false,undefined);
		
				if(trace["fraction"]!= 1)
				{
					distance = distance(tracestart,trace["position"]);
					if(distance>5) distance = distance - 2;
					position1=tracestart + [[level.ex_vectorscale]](vectorNormalize(trace["position"]-tracestart),distance);
				}
				else position1 = trace["position"];
		
				// find ground
				trace=bulletTrace(position1,position1+(0,0,-20),false,undefined);
		
				if(trace["fraction"]==1)
				{
					self iprintlnbold(&"TRIPWIRE_REASON_UNEVEN_GROUND");
					break;
				}
		
				vPos1 = trace["position"] + (0,0,3);
		
				// find position 2
				traceend = tracestart + [[level.ex_vectorscale]](anglesToForward(self.angles + (0,-90,0)),50);
				trace = bulletTrace(tracestart,traceend,false,undefined);
		
				if(trace["fraction"] != 1)
				{
					distance = distance(tracestart,trace["position"]);
					if(distance > 5) distance = distance - 2;
					position2 = tracestart + [[level.ex_vectorscale]](vectorNormalize(trace["position"]-tracestart),distance);
				}
				else position2 = trace["position"];
		
				// find ground
				trace = bulletTrace(position2,position2+(0,0,-20),false,undefined);
		
				if(trace["fraction"] == 1)
				{
					self iprintlnbold(&"TRIPWIRE_REASON_UNEVEN_GROUND");
					break;
				}
		
				vPos2 = trace["position"] + (0,0,3);
		
				maxlimit = level.ex_tweaponlimit;
				curval = 0;
				msg = "";
	
				// Ok to plant, kill checktripwireplacement and set up new hud message
				self notify("ex_checkdefusetripwire");
	
				// check to see if they are pressing their melee key
				if(isPlayer(self) && self.sessionstate == "playing" && self meleeButtonPressed())
				{
					// Check tripwire limit before planting
					if(level.ex_teamplay)
					{
						curval = level.ex_tweapons[self.sessionteam];
						msg = &"TRIPWIRE_LIMIT_TEAM_REACHED";
					}
					else
					{
						curval = level.ex_tweapons;
						maxlimit = maxlimit * 2;
						msg = &"TRIPWIRE_LIMIT_REACHED";
					}
					
					if(curval >= maxlimit)
					{
						self thread [[level.ex_bclear]]("self", 5);
						self iprintlnbold(msg);
						break;
					}
		
					// lock the player to the spot while defusing the tripwire	
					self extreme\_ex_utils::punishment("disable", "freeze");
	
					// get player origin and angles
					oldorigin = self.origin;
					angles = self.angles;
	
					// display new message and progress bar
					self thread extreme\_ex_utils::createBarGraphic(288, level.ex_tweapon_ptime);
					self showTripwireMessage(grenadetype1, grenadetype2, &"TRIPWIRE_PLANTING");
		
					// play plant sound
					self playSound("MP_bomb_plant");
	
					// set the bar colour and zero the count		
					colour = 1;
					count = 0;
	
					// count how long they hold the melee button for
					while(isPlayer(self) && self meleeButtonPressed() && self.origin == oldorigin && self [[level.ex_getstance]](false) == 2 && count < level.ex_tweapon_ptime)
					{
						count += level.ex_fps_frame;
						if(isPlayer(self) && isDefined(self.ex_pb)) self.ex_pb.color = (1,colour,colour);
						colour -= 0.05 / 5;
						wait( [[level.ex_fpstime]](level.ex_fps_frame) );
					}
	
					// remove messages and progress bar
					self cleanMessages();
					self extreme\_ex_utils::cleanBarGraphic();
	
					// did they hold the key down long enough?
					if(count < level.ex_tweapon_ptime) break;
	
					// check the tripwire limits again	
					maxlimit = level.ex_tweaponlimit;
					curval = 0;
		
					// Check tripwire limit before final deployment, in case someone beat them to it!
					if(level.ex_teamplay)
					{
						curval = level.ex_tweapons[self.sessionteam];
						msg = &"TRIPWIRE_LIMIT_TEAM_REACHED";
					}
					else
					{
						curval = level.ex_tweapons;
						maxlimit = maxlimit * 2;
						msg = &"TRIPWIRE_LIMIT_REACHED";
					}
					
					if(curval >= maxlimit)
					{
						self thread [[level.ex_bclear]]("self", 5);
						self iprintlnbold(msg);
						break;
					}
	
					// adjust the amount of tripwires available	
					if(level.ex_teamplay) level.ex_tweapons[self.sessionteam]++;
					else level.ex_tweapons++;
		
					// calculate the tripwire centre
					x = (vPos1[0] + vPos2[0])/2;
					y = (vPos1[1] + vPos2[1])/2;
					z = (vPos1[2] + vPos2[2])/2;
					vPos = (x,y,z);
		
					// decrease the players grenade ammo
					self takeAmmo(grenadetype1, 1);
					self takeAmmo(grenadetype2, 1);
			
					// spawn the tripwire
					tripwep = spawn("script_origin",vPos);
					tripwep.angles = angles;
					tripwep.triparrayindex = getTriparrayIndex();
					//logprint("TRIPWIRE DEBUG: planted tripwire has array index " + tripwep.triparrayindex + "\n");
					level.ex_triparray[tripwep.triparrayindex] = tripwep;
					tripwep thread monitorTripwire(self, grenadetype1, grenadetype2, vPos1, vPos2);
					break;
				}
			}
		}
	}

	if(isPlayer(self))
	{
		// enable the players weapon and release them
		self thread extreme\_ex_utils::punishment("enable", "release");

		// remove the messages and progress bar
		self cleanMessages();
		self extreme\_ex_utils::cleanBarGraphic();

		// not planting anymore!
		self.ex_plantwire = false;
	}
}

getTriparrayIndex()
{
	for(i = 0; i < level.ex_triparray.size; i++)
		if(!isDefined(level.ex_triparray[i])) return i;

	return level.ex_triparray.size;
}

defuseTripwire(tripwep, grenadetype1, grenadetype2)
{
	self endon("kill_thread");

	self notify("ex_checkdefusetripwire");
	self endon("ex_checkdefusetripwire");

	if(isPlayer(self))
	{
		// make sure to only run one instance
		if(self.ex_defusewire) return;

		self.ex_defusewire = true;
	
		// get the distance between the tripwire weapons and the player
		distance1 = distance(tripwep.tweapon1.origin, self.origin);
		distance2 = distance(tripwep.tweapon2.origin, self.origin);

		// check still in within range of the tripwire
		if(distance1 > 20 && distance2 > 20)
		{
			self cleanMessages();
			self.ex_defusewire = false;
			return;
		}
	
		grenadeicon = grenadetype1;
	
		// which grenade were they near to?
		if(distance2 >= 20) grenadeicon = grenadetype1;
		else grenadeicon = grenadetype2;
		
		// ok to defuse, end the plant routine
		self notify("defusingtripwire");

		// hide WMD deployment
		if(isDefined(self.ex_binocular_hint)) self.ex_binocular_hint.alpha = 0;
	
		// show new message
		self showTripwireMessage(grenadeicon, undefined, &"TRIPWIRE_DEFUSE");
	
		// loop
		for(;;)
		{
			wait( [[level.ex_fpstime]](0.5) );

			if(isPlayer(self) && self meleeButtonPressed())
			{
				// lock the player to the spot while defusing the tripwire	
				self extreme\_ex_utils::punishment("disable", "freeze");

				// get player origin and angles
				oldorigin = self.origin;
				angles = self.angles;

				// display new message and progress bar
				self thread extreme\_ex_utils::createBarGraphic(288, level.ex_tweapon_dtime);
				self showTripwireMessage(grenadetype1, grenadetype2, &"TRIPWIRE_DEFUSING");
	
				// play defuse sound
				self playSound("MP_bomb_defuse");

				// set the bar colour and zero the count	
				colour = 1;
				count = 0;

				// count how long they hold the melee button
				while(isPlayer(self) && self meleeButtonPressed() && isDefined(tripwep) && self.origin == oldorigin && self [[level.ex_getstance]](false) == 2 && count < level.ex_tweapon_dtime)
				{
					count += level.ex_fps_frame;
					if(isPlayer(self) && isDefined(self.ex_pb)) self.ex_pb.color = (colour,1,colour);
					colour -= 0.05 / 5;
					wait( [[level.ex_fpstime]](level.ex_fps_frame) );
				}

				// remove the messages and progress bar
				self cleanMessages();
				self extreme\_ex_utils::cleanBarGraphic();

				// did they hold the key down long enough?	
				if(count < level.ex_tweapon_dtime && isDefined(tripwep)) break;
	
				// adjust the amount of tripwires available
				if(isDefined(tripwep.team) && tripwep.team != "no_owner")
				{
					if(level.ex_teamplay) level.ex_tweapons[tripwep.team]--;
					else level.ex_tweapons--;
				}
	
				// stop monitor the tripwire
				if(isDefined(tripwep)) tripwep notify("endmonitoringtripwire");
				if(isDefined(tripwep)) tripwep.ex_warnplayers = false;
				wait( [[level.ex_fpstime]](0.05) );

				// bonus points for defusing
				if(level.ex_reward_tripwire)
				{
					if( (!level.ex_teamplay && isDefined(tripwep.owner) && tripwep.owner != self) ||
					    (level.ex_teamplay && isDefined(tripwep.team) && tripwep.team != self.pers["team"]) )
					{
						self.score += level.ex_reward_tripwire;
						self.pers["bonus"] += level.ex_reward_tripwire;
						self notify("update_playerscore_hud");
					}
				}

				// remove the tripwire
				if(isDefined(tripwep.tweapon1)) tripwep.tweapon1 delete();
				if(isDefined(tripwep.tweapon2)) tripwep.tweapon2 delete();
				if(isDefined(tripwep))
				{
					if(isDefined(level.ex_triparray[tripwep.triparrayindex]))
					{
						//logprint("TRIPWIRE DEBUG: deleting tripwire index " + tripwep.triparrayindex + " from array\n");
						level.ex_triparray[tripwep.triparrayindex] delete();
					}
				}
	
				wait( [[level.ex_fpstime]](0.2) );

				// play a defuse sound to everyone and give them the new grenades
				if(isPlayer(self))
				{
					self playlocalsound("defused");
					self playSound("MP_bomb_defuse");
					self addToNadeLoadout(grenadetype1, 1);
					self addToNadeLoadout(grenadetype2, 1);
				}

				break;
			}

			wait( [[level.ex_fpstime]](0.05) );
	
			// check still prone
			if(self [[level.ex_getstance]](false) != 2) break;

			// check that the tripwire is still there, another player may be defusing too?
			if(!isDefined(tripwep.tweapon1) || !isDefined(tripwep.tweapon2)) break;

			// check the player is still within distance of the tripwire
			distance1 = distance(tripwep.tweapon1.origin, self.origin);
			distance2 = distance(tripwep.tweapon2.origin, self.origin);
			if(distance1 >= 20 && distance2 >= 20) break;
		}
	}

	// show WMD deployment
	if(isDefined(self.ex_binocular_hint)) self.ex_binocular_hint.alpha = 1;

	// enable the players weapon and release them
	self thread extreme\_ex_utils::punishment("enable", "release");

	// remove the messages and progress bar
	self cleanMessages();
	self extreme\_ex_utils::cleanBarGraphic();

	// not defusing anymore!
	self.ex_defusewire = false;
}

addToNadeLoadout(grenadetype, newnades)
{
	if(isWeaponType(grenadetype, "fraggrenade") || isWeaponType(grenadetype, "fragspecial"))
	{
		if(level.ex_firenades || level.ex_gasnades || level.ex_satchelcharges) currentfrags = self getammocount(self.pers["fragtype"]);
			else currentfrags = self getammocount(self.pers["fragtype"]) + self getammocount(self.pers["enemy_fragtype"]);
		if(!isDefined(currentfrags)) currentfrags = 0;

		totalfrags = currentfrags + newnades;
		if(totalfrags > level.ex_frag_cap) totalfrags = level.ex_frag_cap;
		self setWeaponClipAmmo(self.pers["fragtype"], totalfrags);
	}
	else if(isWeaponType(grenadetype, "smokegrenade") || isWeaponType(grenadetype, "smokespecial"))
	{
		currentsmokes = self getammocount(self.pers["smoketype"]) + self getammocount(self.pers["enemy_smoketype"]);
		if(!isDefined(currentsmokes)) currentsmokes = 0;

		totalsmokes = currentsmokes + newnades;
		if(totalsmokes > level.ex_smoke_cap) totalsmokes = level.ex_smoke_cap;
		self setWeaponClipAmmo(self.pers["smoketype"], totalsmokes);
	}
}

monitorTripwire(owner, grenadetype1, grenadetype2, vPos1, vPos2)
{
	level endon("ex_gameover");
	self endon("endmonitoringtripwire");

	// save owner and team
	if(isPlayer(owner))
	{
		self.owner = owner;
		self.team = owner.pers["team"];
	}
	else
	{
		self.owner = undefined;
		self.team = "no_owner";
	}

	// Spawn nade one
	self.tweapon1 = spawn("script_model", vPos1);
	self.tweapon1 setModel(getWeaponModel(grenadetype1));
	self.tweapon1.angles = self.angles;
	self.tweapon1.damaged = false;

	// Spawn nade two
	self.tweapon2 = spawn("script_model", vPos2);
	self.tweapon2 setModel(getWeaponModel(grenadetype2));
	self.tweapon2.angles = self.angles;
	self.tweapon2.damaged = false;

	// Get detection spots
	nadedist = distance(vPos1, vPos2);
	vPos3 = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles), nadedist/3.33);
	vPos4 = self.origin + [[level.ex_vectorscale]](anglesToForward(self.angles + (0,180,0)), nadedist/3.33);

	// Set detection ranges
	tripwarnrange = distance(self.origin, vPos1) + 150;
	tripsphere = distance(vPos3, vPos1);

	//level thread tripDebug(vPos3, tripsphere, (1,0,0));
	//level thread tripDebug(vPos4, tripsphere, (1,1,0));

	if(isPlayer(owner) && owner.sessionstate == "playing")
	{
		owner thread tripwireActivate(5);
		wait( [[level.ex_fpstime]](5) );
	}

	self.ex_warnplayers = true;

	while(true)
	{
		wait( [[level.ex_fpstime]](0.05) );

		// Blow if one of the nades has taken enough damage
		if(self.tweapon1.damaged || self.tweapon2.damaged) break;

		players = level.players;
		
		// Loop through players to find out if one has triggered the wire
		for(i = 0; i < players.size; i++)
		{
			// Check if player still exist
			if(isPlayer(players[i]) && players[i].sessionstate == "playing") player = players[i];
				else continue;

			// Within range?
			distance = distance(self.origin, player.origin);
			if(distance >= tripwarnrange)
			{
				// Set warning to false
				player.ex_warningwire = undefined;
				continue;
			}

			// player is jumping over the tripwire?
			// mbots do not always pass the isOnGround test, so skip this test for them
			if(isPlayer(player) && !isDefined(player.pers["isbot"]) && !player isOnGround()) continue;

			// Check for defusal
			distance1 = distance(vPos1, player.origin);
			distance2 = distance(vPos2, player.origin);

			// if in range of either grenade and prone and not already defusing
			if(player [[level.ex_getstance]](false) == 2 && (distance1 <= 20 || distance2 <= 20) && !player.ex_defusewire)
			{
				// Prevent defusing while being frozen in freezetag
				if(level.ex_currentgt != "ft" || (isDefined(player.frozenstate) && player.frozenstate != "frozen"))
					player thread defuseTripwire(self, grenadetype1, grenadetype2);
			}

			// Warn if same team?
			if(level.ex_teamplay && isDefined(self.team) && self.team == player.pers["team"])
			{
				if(level.ex_tweapon == 3) continue; // don't blow on teammates!
				if(level.ex_tweaponwarning && !isDefined(player.ex_warningwire)) self thread tripwireWarning(player);
			}
			else if(!level.ex_teamplay && isDefined(self.owner) && self.owner == player)
			{
				if(level.ex_tweapon == 3) continue; // don't blow on owner!
				if(level.ex_tweaponwarning && !isDefined(player.ex_warningwire)) self thread tripwireWarning(player);
			}

			// Within sphere one?
			distance = distance(vPos3, player.origin);
			if(distance >= tripsphere) continue;

			// Within sphere two?
			distance = distance(vPos4, player.origin);
			if(distance >= tripsphere) continue;

			// Player is within both spheres, so trigger explosion. closer to nade 1 or 2?
			if(distance(vPos1, player.origin) < distance(vPos2, player.origin)) self.tweapon1.damaged = true;
				else self.tweapon2.damaged = true;
		}
	}

	if(isDefined(self.team) && self.team != "no_owner")
	{
		if(level.ex_teamplay) level.ex_tweapons[self.team]--;
		else level.ex_tweapons--;
	}

	self.tweapon1 notify("endtripwiredamagemonitor");
	self.tweapon2 notify("endtripwiredamagemonitor");

	if(isDefined(self.tweapon1.damaged))
	{
		self.tweapon1 playSound("weap_fraggrenade_pin");
		wait( [[level.ex_fpstime]](0.05) );
		self.tweapon2 playSound("weap_fraggrenade_pin");
		wait( [[level.ex_fpstime]](0.05) );
	}
	else
	{
		self.tweapon2 playSound("weap_fraggrenade_pin");
		wait( [[level.ex_fpstime]](0.05) );
		self.tweapon1 playSound("weap_fraggrenade_pin");
		wait( [[level.ex_fpstime]](0.05) );
	}

	wait( [[level.ex_fpstime]](randomFloat(0.25)) );

	// Check that damage owner still exists, if not tripwire just kills
	if(isPlayer(owner) && owner.sessionteam != "spectator") eAttacker = owner;
		else eAttacker = self;

	// blow 'em
	if(isDefined(self.tweapon1.damaged))
	{
		// blow 1
		playfx(level.ex_effect[getFX(grenadetype1)], self.tweapon1.origin);
		self.tweapon1 playSound(getSound(grenadetype1));
		self.tweapon1 tripwireDamage(self.tweapon1, eAttacker, grenadetype1, level.ex_tweapon);

		// A small, random, delay between the nades
		wait( [[level.ex_fpstime]](randomFloat(0.25)) );

		// blow 2
		playfx(level.ex_effect[getFX(grenadetype2)], self.tweapon2.origin);
		self.tweapon2 playSound(getSound(grenadetype2));
		self.tweapon2 tripwireDamage(self.tweapon2, eAttacker, grenadetype2, level.ex_tweapon);
	}
	else
	{
		// blow 2
		playfx(level.ex_effect[getFX(grenadetype2)], self.tweapon2.origin);
		self.tweapon2 playSound(getSound(grenadetype2));
		self.tweapon2 tripwireDamage(self.tweapon2, eAttacker, grenadetype2, level.ex_tweapon);

		// A small, random, delay between the effects
		wait( [[level.ex_fpstime]](randomFloat(0.25)) );

		// blow 1
		playfx(level.ex_effect[getFX(grenadetype1)], self.tweapon1.origin);
		self.tweapon1 playSound(getSound(grenadetype1));
		self.tweapon1 tripwireDamage(self.tweapon1, eAttacker, grenadetype1, level.ex_tweapon);
	}

	self.ex_warnplayers = false;

	origin1 = self.tweapon1.origin;
	self.tweapon1 delete();
	origin2 = self.tweapon2.origin;
	self.tweapon2 delete();

	wait( [[level.ex_fpstime]](0.25) );
	if(isDefined(self))
	{
		if(isDefined(level.ex_triparray[self.triparrayindex]))
		{
			//logprint("TRIPWIRE DEBUG: deleting tripwire index " + self.triparrayindex + " from array\n");
			level.ex_triparray[self.triparrayindex] delete();

			thread checkProximityTrips(origin1, level.ex_tweapon_cpx);
			thread extreme\_ex_landmines::checkProximityLandmines(origin1, level.ex_tweapon_cpx);
			thread extreme\_ex_specials_sentrygun::checkProximitySentryGuns(origin1, eAttacker, level.ex_tweapon_cpx);

			wait( [[level.ex_fpstime]](0.5) );

			thread checkProximityTrips(origin2, level.ex_tweapon_cpx);
			thread extreme\_ex_landmines::checkProximityLandmines(origin2, level.ex_tweapon_cpx);
			thread extreme\_ex_specials_sentrygun::checkProximitySentryGuns(origin2, eAttacker, level.ex_tweapon_cpx);
		}
	}
}

checkProximityTrips(origin, cpx)
{
	if(level.ex_tweapon && level.ex_tweapon_cpx)
	{
		for(i = 0; i < level.ex_triparray.size; i ++)
		{
			tripwire = level.ex_triparray[i];
			if(!isDefined(tripwire)) continue;

			origin1 = tripwire.tweapon1.origin;
			origin2 = tripwire.tweapon2.origin;
			if(!isDefined(origin1) || !isDefined(origin2)) continue;

			tripwire_damage = 0;
			if(distance(origin, origin1) <= cpx) tripwire_damage += 1;
			if(distance(origin, origin2) <= cpx) tripwire_damage += 2;

			if(tripwire_damage)
			{
				if(tripwire_damage == 3)
				{
					if(distance(origin, origin1) < distance(origin, origin2)) tripwire.tweapon1.damaged = true;
						else tripwire.tweapon2.damaged = true;
				}
				else if(tripwire_damage == 2) tripwire.tweapon2.damaged = true;
					else tripwire.tweapon1.damaged = true;
			}
		}
	}
}

tripwireWarning(player)
{
	level endon("ex_gameover");

	if(isDefined(player.ex_warningwire)) return;

	player.ex_warningwire = true;

	while(isPlayer(player) && isDefined(player.ex_warningwire) && isDefined(self) && self.ex_warnplayers)
	{
		if(!isDefined(player.ex_tripwarning))
		{
			player.ex_tripwarning = newClientHudElem(player);	
			player.ex_tripwarning.archived = false;
			player.ex_tripwarning.horzAlign = "fullscreen";
			player.ex_tripwarning.vertAlign = "fullscreen";
			player.ex_tripwarning.alignX = "center";
			player.ex_tripwarning.alignY = "middle";
			player.ex_tripwarning.x = 320;
			player.ex_tripwarning.y = 200;
			player.ex_tripwarning.alpha = 0;
			player.ex_tripwarning.scale = 0.6;
			player.ex_tripwarning setShader("killiconsuicide",40,40);
		}

		if(isPlayer(player) && isDefined(player.ex_tripwarning))
		{
			player.ex_tripwarning fadeOverTime(0.8);
			player.ex_tripwarning.alpha = 0.8;
			player playLocalSound("expalert");
		}
	
		wait( [[level.ex_fpstime]](1.6) );

		if(isPlayer(player) && isDefined(player.ex_tripwarning))
		{		
			player.ex_tripwarning fadeOverTime(0.8);
			player.ex_tripwarning.alpha = 0;
			wait( [[level.ex_fpstime]](0.8) );
		}
	}

	if(isPlayer(player) && isDefined(player.ex_tripwarning)) player.ex_tripwarning destroy();
}

tripwireDamage(who, eAttacker, grenadetype, teamkill)
{
	deviceID = getDeviceID(grenadetype);
	switch(deviceID)
	{
		// only frags, fire, gas and satchel charges cause damage
		case 1:
		case 2:
		case 3:
		case 4:
		case 50:
		case 51:
		case 52:
		case 53:
		case 54:
		case 60:
		case 61:
		case 62:
		case 63:
		case 64:
		case 70:
		case 71:
		case 72:
		case 73:
		case 74:
		who extreme\_ex_utils::scriptedfxradiusdamage(eAttacker, undefined, "MOD_EXPLOSIVE","tripwire_mp", level.ex_tweapon_radius, 600, 400, undefined, true, true);
		break;
	}
}

showTripwireMessage(grenadetype1, grenadetype2, msg)
{
	self endon("kill_thread");

	if(isPlayer(self))
	{
		self cleanMessages();

		if(isDefined(msg))
		{
			self.ex_expmsg1 = newClientHudElem( self );
			self.ex_expmsg1.archived = false;
			self.ex_expmsg1.horzAlign = "fullscreen";
			self.ex_expmsg1.vertAlign = "fullscreen";
			self.ex_expmsg1.alignX = "center";
			self.ex_expmsg1.alignY = "middle";
			self.ex_expmsg1.x = 320;
			self.ex_expmsg1.y = 408;
			self.ex_expmsg1.alpha = 1;
			self.ex_expmsg1.fontScale = 0.80;
			self.ex_expmsg1.sort = 1;
			self.ex_expmsg1 setText(msg);
		}

		if(isDefined(grenadetype1))
		{
			self.ex_expmsg2 = newClientHudElem(self);
			self.ex_expmsg2.archived = false;
			self.ex_expmsg2.horzAlign = "fullscreen";
			self.ex_expmsg2.vertAlign = "fullscreen";

			if(isDefined(grenadetype2)) self.ex_expmsg2.alignX = "left";
				else self.ex_expmsg2.alignX = "center";

			self.ex_expmsg2.alignY = "top";
			self.ex_expmsg2.x = 320;
			self.ex_expmsg2.y = 415;
			self.ex_expmsg2 setShader(getWeaponHud(grenadetype1),40,40);
		}

		if(isDefined(grenadetype2))
		{
			self.ex_expmsg3 = newClientHudElem(self);
			self.ex_expmsg3.archived = false;
			self.ex_expmsg3.horzAlign = "fullscreen";
			self.ex_expmsg3.vertAlign = "fullscreen";
			self.ex_expmsg3.alignX = "right";
			self.ex_expmsg3.alignY = "top";
			self.ex_expmsg3.x = 320;
			self.ex_expmsg3.y = 415;
			self.ex_expmsg3 setShader(getWeaponHud(grenadetype2),40,40);
		}

		self.ex_istwepmsg = true;
	}
}

cleanMessages()
{
	if(isDefined(self.ex_expmsg1)) self.ex_expmsg1 destroy();
	if(isDefined(self.ex_expmsg2)) self.ex_expmsg2 destroy();
	if(isDefined(self.ex_expmsg3)) self.ex_expmsg3 destroy();
	if(isPlayer(self)) self.ex_istwepmsg = false;
}

tripwireActivate(time)
{
	self endon("kill_thread");

	if(isPlayer(self))
	{
		self.ex_actimer = newClientHudElem(self);
		self.ex_actimer.archived = false;
		self.ex_actimer.horzAlign = "fullscreen";
		self.ex_actimer.vertAlign = "fullscreen";
		self.ex_actimer.alignX = "center";
		self.ex_actimer.alignY = "middle";
		self.ex_actimer.x = 320;
		self.ex_actimer.y = 434;
		self.ex_actimer.alpha = 0.8;
		self.ex_actimer.fontScale = 1.2;
		self.ex_actimer.label = &"TRIPWIRE_ACTIVATE";
		self.ex_actimer.color = (0, 1, 0);
		self.ex_actimer setTimer(5);
	}

	for(a = 0; a < 5; a++) 
	{
		// hide WMD deployment
		if(isDefined(self.ex_binocular_hint)) self.ex_binocular_hint.alpha = 0;

		wait( [[level.ex_fpstime]](1) );
		
		if(isPlayer(self) && isDefined(self.ex_actimer))
		{
			if((5 - a) == 3) self.ex_actimer .color = (1, 1, 0);
			else if ( (5 - a) == 2) self.ex_actimer .color = (1, 0, 0);
		}

		if(isPlayer(self)) self playlocalsound("medi_use_high");
	}

	if(isPlayer(self))
	{
		self playlocalsound("medi_use_low");
		
		if(isDefined(self.ex_actimer))
		{
			self.ex_actimer fadeovertime(1);
			self.ex_actimer.alpha = 0;
		}
	}

	wait( [[level.ex_fpstime]](1) );

	if(isPlayer(self))
	{
		self playlocalsound("planted");
		self playlocalsound("MP_bomb_plant");
		if(isDefined(self.ex_actimer)) self.ex_actimer destroy();

		// show WMD deployment
		if(isDefined(self.ex_binocular_hint)) self.ex_binocular_hint.alpha = 1;
	}		
}

getDeviceID(grenadetype)
{
	switch(grenadetype)
	{
		// frag grenades
		case "frag_grenade_american_mp": return 1;
		case "frag_grenade_british_mp": return 2;
		case "frag_grenade_russian_mp": return 3;
		case "frag_grenade_german_mp": return 4;

		// american smoke grenades
		case "smoke_grenade_american_mp": return 10;
		case "smoke_grenade_american_blue_mp": return 11;
		case "smoke_grenade_american_green_mp": return 12;
		case "smoke_grenade_american_orange_mp": return 13;
		case "smoke_grenade_american_pink_mp": return 14;
		case "smoke_grenade_american_red_mp": return 15;
		case "smoke_grenade_american_yellow_mp": return 16;

		// british smoke grenades
		case "smoke_grenade_british_mp": return 20;
		case "smoke_grenade_british_blue_mp": return 21;
		case "smoke_grenade_british_green_mp": return 22;
		case "smoke_grenade_british_orange_mp": return 23;
		case "smoke_grenade_british_pink_mp": return 24;
		case "smoke_grenade_british_red_mp": return 25;
		case "smoke_grenade_british_yellow_mp": return 26;

		// russian smoke grenades
		case "smoke_grenade_russian_mp": return 30;
		case "smoke_grenade_russian_blue_mp": return 31;
		case "smoke_grenade_russian_green_mp": return 32;
		case "smoke_grenade_russian_orange_mp": return 33;
		case "smoke_grenade_russian_pink_mp": return 34;
		case "smoke_grenade_russian_red_mp": return 35;
		case "smoke_grenade_russian_yellow_mp": return 36;

		// german smoke grenades
		case "smoke_grenade_german_mp": return 40;
		case "smoke_grenade_german_blue_mp": return 41;
		case "smoke_grenade_german_green_mp": return 42;
		case "smoke_grenade_german_orange_mp": return 43;
		case "smoke_grenade_german_pink_mp": return 44;
		case "smoke_grenade_german_red_mp": return 45;
		case "smoke_grenade_german_yellow_mp": return 46;
		
		// gas grenades
		case "gas_mp": return 50;
		case "smoke_grenade_german_gas_mp": return 51;
		case "smoke_grenade_american_gas_mp": return 52;
		case "smoke_grenade_british_gas_mp": return 53;
		case "smoke_grenade_russian_gas_mp": return 54;

		// fire grenades
		case "fire_mp": return 60;
		case "smoke_grenade_british_fire_mp": return 61;
		case "smoke_grenade_russian_fire_mp": return 62;
		case "smoke_grenade_german_fire_mp": return 63;
		case "smoke_grenade_american_fire_mp": return 64;

		// satchel charges
		case "satchel_mp": return 70;
		case "smoke_grenade_german_satchel_mp": return 71;
		case "smoke_grenade_american_satchel_mp": return 72;
		case "smoke_grenade_british_satchel_mp": return 73;
		case "smoke_grenade_russian_satchel_mp": return 74;

	}
}

giveAmmo(grenadetype,var)
{
	self endon("disconnect");

	if(isPlayer(self))
	{	
		iAmmo = var + self getCurrentAmmo(grenadetype);

		if(iAmmo < 1) return;

		self setWeaponClipAmmo(grenadetype, iAmmo);
		self playSound("grenade_pickup");
	}
}

takeAmmo(grenadetype,var)
{
	self endon("disconnect");

	if(isPlayer(self))
	{
		iAmmo = self getCurrentAmmo(grenadetype);

		if(iAmmo == 0) return;

		self setWeaponClipAmmo(grenadetype, iAmmo - var);
	}
}

getCurrentAmmo(grenadetype)
{
	return self getAmmoCount(grenadetype);
}

getWeaponModel(grenadetype)
{
	deviceID = getDeviceID(grenadetype);
	switch(deviceID)
	{
		// frag grenades
		case 1: return "xmodel/tc_m67_fraggrenade";
		case 2: return "xmodel/tc_m67_fraggrenade";
		case 3: return "xmodel/tc_m67_fraggrenade";
		case 4: return "xmodel/tc_m67_fraggrenade";

		// gas grenades
		case 50:
		case 51:
		case 52:
		case 53:
		case 54: return "xmodel/tc_m84_flashbang";

		// fire grenades
		case 60:
		case 61:
		case 62:
		case 63:
		case 64: return "xmodel/weapon_incendiary_grenade";

		// satchel charges
		case 70:
		case 71:
		case 72:
		case 73:
		case 74: return "xmodel/projectile_satchel";

		// smoke grenades
		default: return "xmodel/tc_m84_flashbang";
	}
}

getWeaponHud(grenadetype)
{
	deviceID = getDeviceID(grenadetype);
	switch(deviceID)
	{
		// frag grenades
		case 1: return "gfx/icons/hud@us_grenade_C.tga";
		case 2: return "gfx/icons/hud@british_grenade_C.tga";
		case 3: return "gfx/icons/hud@russian_grenade_C.tga";
		case 4: return "gfx/icons/hud@steilhandgrenate_C.tga";

		// gas grenades
		case 50:
		case 51:
		case 52:
		case 53:
		case 54: return "gas_grenade";

		// fire grenades
		case 60:
		case 61:
		case 62:
		case 63:
		case 64: return "gfx/icons/hud@incenhandgrenade_c.tga";

		// satchel charges
		case 70:
		case 71:
		case 72:
		case 73:
		case 74: return "gfx/icons/hud@satchel_charge1.tga";

		// smoke grenades
		default: return "hud_us_smokegrenade_C";
	}
}

getFX(grenadetype)
{
	deviceID = getDeviceID(grenadetype);
	switch(deviceID)
	{
		// frag grenade
		case 1:
		case 2:
		case 3:
		case 4: return "plane_bomb";	// temp explosion

		// smoke grey
		case 10:
		case 20:
		case 30:
		case 40: return "greysmoke";

		// smoke blue
		case 11:
		case 21:
		case 31:
		case 41: return "bluesmoke";

		// smoke green
		case 12:
		case 22:
		case 32:
		case 42: return "greensmoke";

		// smoke orange
		case 13:
		case 23:
		case 33:
		case 43: return "orangesmoke";

		// smoke pink
		case 14:
		case 24:
		case 34:
		case 44: return "pinksmoke";

		// smoke red
		case 15:
		case 25:
		case 35:
		case 45: return "redsmoke";

		// smoke yellow
		case 16:
		case 26:
		case 36:
		case 46: return "yellowsmoke";
		
		// gas grenades
		case 50:
		case 51:
		case 52:
		case 53:
		case 54: return "gas";

		// fire grenades
		case 60:
		case 61:
		case 62:
		case 63:
		case 64: return "fire";

		// satchel charges
		case 70:
		case 71:
		case 72:
		case 73:
		case 74: return "satchel";
	}
}

getSound(grenadetype)
{
	deviceID = getDeviceID(grenadetype);
	switch(deviceID)
	{
		// frag, satchel charges and fire grenades
		case 1:
		case 2:
		case 3:
		case 4:
		case 60:
		case 61:
		case 62:
		case 63:
		case 64:
		case 70:
		case 71:
		case 72:
		case 73:
		case 74: return "grenade_explode_default";

		// gas and smoke grenades
		default: return "smokegrenade_explode_default";
	}
}

tooCloseSpawnpointsorFlag()
{
	// Check for spawnpoints
	spawnpointname = undefined;

	switch(level.ex_currentgt)
	{
		case "sd":
		case "esd":
			return false;

		case "ctf":
		case "rbctf":
		case "ctfb":
			if(self.pers["team"] == "axis")
				spawnpointname = "mp_ctf_spawn_allied";
			else if(self.pers["team"] == "allies")
				spawnpointname = "mp_ctf_spawn_axis";
			break;
	
		case "dm":
		case "hm":
		case "lms":
		case "ihtf":
			spawnpointname = "mp_dm_spawn";
			break;
	
		case "tdm":
		case "cnq":
		case "rbcnq":
		case "hq":
		case "htf":
			spawnpointname = "mp_tdm_spawn";
			break;
	}

	// Check distance from all relevant spawnpoints
	if(isDefined(spawnpointname))
	{
		spawnpoints = getentarray(spawnpointname, "classname");

		for(i = 0; i < spawnpoints.size; i++)
		{
			spawnpoint = spawnpoints[i];
			if(distance(self.origin,spawnpoint.origin) < 120)
			{
				self iprintln(&"TRIPWIRE_TOO_CLOSE_BASE");
				return true;
			}
		}
	}

	// Extra check for CTF flag zones
	flag_name = undefined;

	if(level.ex_currentgt == "ctf" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "ctfb")
	{
		if(self.pers["team"] == "axis")
			flag_name = "axis_flag";
		else if(self.pers["team"] == "allies")
			flag_name = "allied_flag";
	}

	if(isDefined(flag_name))
	{
		flags = getentarray(flag_name, "targetname");

		for(i = 0; i < flags.size; i++)
		{
			flag = flags[i];

			if(distance(self.origin,flag.origin) < 150)
			{
				self iprintln(&"TRIPWIRE_TOO_CLOSE_FLAG");
				return true;
			}
		}
	}

	return false;
}

// Tripwire debugging

tripDebug(pos, range, color)
{
	timeout = 60 * level.ex_fps;

	while(timeout > 0)
	{
		start = pos + [[level.ex_vectorscale]](anglestoforward((0,0,0)), range);
		for(i = 10; i < 360; i += 10)
		{
			point = pos + [[level.ex_vectorscale]](anglestoforward((0,i,0)), range);
			line(start, point, color);
			start = point;
		}
		wait(.05);
		timeout--;
	}
}
