
playerRankMonitor()
{
	self endon("kill_thread");

	self.ex_artillery_strike = false;
	self.ex_mortar_strike = false;
	self.ex_air_strike = false;
	self.ex_gunship = false;

	if(!isDefined(self.pers["rank"])) self.pers["rank"] = self getRank();

	self waittill("spawned_player");

	while(isPlayer(self) && !level.ex_gameover)
	{
		self.pers["newrank"] = self getRank();

		// If old "rank" isnt the same as the new rank check
		if(self.pers["rank"] != self.pers["newrank"])
		{
			if(self.pers["rank"] < self.pers["newrank"])
			{
				// PROMOTED: update here, so the weapon update is based on the new rank
				self.pers["rank"] = self.pers["newrank"];
				self thread rankupdate(true);
			}
			else if(self.pers["rank"] > self.pers["newrank"])
			{
				// DEMOTED: update here, so the weapon update is based on the new rank
				self.pers["rank"] = self.pers["newrank"];
				self thread rankupdate(false);
			}
		}

		// update head icon if not spawn protected
		if(!isDefined(self.ex_spawnprotected))
		{
			if(level.drawfriend && level.ex_teamplay && level.ex_currentgt != "hm")
			{
				self.headicon = extreme\_ex_ranksystem::getHeadIcon();
			}
			else if(level.ex_currentgt != "hm")
			{
				self.headicon = "";
			}
		}

		// update status icon
		if(level.ex_rank_statusicons) self.statusicon = self thread getStatusIcon();

		// check for WMD
		if(level.ex_rank_wmdtype && isDefined(self.ex_haswmdbinocs) && self.ex_haswmdbinocs) self thread checkWmd();

		// if player is in gunship, suspend rank updates until old weapons are restored
		while( (level.ex_gunship && isDefined(level.ex_gunship_player) && level.ex_gunship_player == self) ||
		       (level.ex_gunship_special && isDefined(level.ex_gunship_splayer) && level.ex_gunship_splayer == self) ) wait( [[level.ex_fpstime]](0.05) );

		wait( [[level.ex_fpstime]](1) );
	}
}

checkWmd()
{
	self endon("kill_thread");

	// return if already checking
	if(isDefined(self.ex_checkingwmd)) return;

	// if playing LIB and player is jailed, do not give WMD
	if(level.ex_currentgt == "lib" && isDefined(self.in_jail) && self.in_jail)
	{
		if(isDefined(self.ex_wmd_icon)) self wmdStop();
		return;
	}

	// if entities monitor in defcon 2, suspend all WMD
	if(level.ex_entities_defcon == 2) return;

	// no checking if in gunship
	if( (level.ex_gunship && isDefined(level.ex_gunship_player) && level.ex_gunship_player == self) ||
	    (level.ex_gunship_special && isDefined(level.ex_gunship_splayer) && level.ex_gunship_splayer == self) ) return;

	// no checking if frozen in FreezeTag
	if(level.ex_currentgt == "ft" && isDefined(self.frozenstate) && self.frozenstate == "frozen") return;

	self.ex_checkingwmd = true;

	if(level.ex_rank_wmdtype == 1) self wmdFixed();
	else if(level.ex_rank_wmdtype == 2) self wmdRandom();
	else if(level.ex_rank_wmdtype == 3) self wmdAllowedRandom();

	wait( [[level.ex_fpstime]](5) );
	if(isPlayer(self)) self.ex_checkingwmd = undefined;
}

wmdFixed()
{
	self endon("kill_thread");

	wmd_assigned = false;
	if(self.ex_mortar_strike || self.ex_artillery_strike || self.ex_air_strike || self.ex_gunship) wmd_assigned = true;
	if(wmd_assigned && !level.ex_rank_wmd_upgrade) return;

	if(self.pers["rank"] < 3)
	{
		if(wmd_assigned) self wmdStop();
		return;
	}

	mortar_allowed = false;
	if(self.pers["rank"] == 3) mortar_allowed = true;
	artillery_allowed = false;
	if(self.pers["rank"] == 4) artillery_allowed = true;
	airstrike_allowed = false;
	gunship_allowed = false;
	if(level.ex_gunship == 2)
	{
		if(self.pers["rank"] == 5 || self.pers["rank"] == 6) airstrike_allowed = true;
		else
		{
			if(!level.ex_rank_gunship_next && isDefined(self.pers["gunship"])) airstrike_allowed = true;
				else gunship_allowed = true;
		}
	}
	else if(self.pers["rank"] >= 5) airstrike_allowed = true;

	if(wmd_assigned)
	{
		if(mortar_allowed && self.ex_mortar_strike) return;
		if(artillery_allowed && self.ex_artillery_strike) return;
		if(airstrike_allowed && self.ex_air_strike) return;
		if(gunship_allowed && self.ex_gunship) return;
	}

	if(isPlayer(self))
	{
		self wmdStop();
		if(mortar_allowed)
		{
			if(!wmd_assigned) delay = level.ex_rank_mortar_first;
				else delay = 0;
			self thread extreme\_ex_mortar_player::start(delay);
		}
		else if(artillery_allowed)
		{
			if(!wmd_assigned) delay = level.ex_rank_artillery_first;
				else delay = 0;
			self thread extreme\_ex_artillery_player::start(delay);
		}
		else if(airstrike_allowed)
		{
			if(!wmd_assigned) delay = level.ex_rank_airstrike_first;
				else delay = 0;
			self thread extreme\_ex_airstrike_player::start(delay);
		}
		else if(gunship_allowed)
		{
			if(!wmd_assigned) delay = level.ex_rank_gunship_first;
				else delay = 0;
			self thread extreme\_ex_gunship::gunshipPerk(delay);
		}
	}
}

wmdRandom()
{
	self endon("kill_thread");

	wmd_assigned = false;
	if(self.ex_mortar_strike || self.ex_artillery_strike || self.ex_air_strike || self.ex_gunship) wmd_assigned = true;
	if(wmd_assigned && !level.ex_rank_wmd_upgrade) return;

	mortar_allowed = false;
	if(self.pers["rank"] >= level.ex_rank_mortar) mortar_allowed = true;
	artillery_allowed = false;
	if(self.pers["rank"] >= level.ex_rank_artillery) artillery_allowed = true;
	airstrike_allowed = false;
	if((self.pers["rank"] >= level.ex_rank_airstrike) || (level.ex_gunship != 2 && self.pers["rank"] >= level.ex_rank_special)) airstrike_allowed = true;
	gunship_allowed = false;
	if(level.ex_gunship == 2 && self.pers["rank"] >= level.ex_rank_special && (level.ex_rank_gunship_next || !isDefined(self.pers["gunship"]))) gunship_allowed = true;

	if(!mortar_allowed && !artillery_allowed && !airstrike_allowed && !gunship_allowed)
	{
		if(wmd_assigned) self wmdStop();
		return;
	}

	for(;;)
	{
		wmdtodo = randomInt(4) + 1;

		if(wmdtodo == 1 && mortar_allowed) break;
		if(wmdtodo == 2 && artillery_allowed) break;
		if(wmdtodo == 3 && airstrike_allowed) break;
		if(wmdtodo == 4 && gunship_allowed) break;

		wait( [[level.ex_fpstime]](0.1) );
	}

	if(wmd_assigned)
	{
		if(wmdtodo == 1) return;
		if(wmdtodo == 2 && (self.ex_artillery_strike || self.ex_air_strike || self.ex_gunship)) return;
		if(wmdtodo == 3 && (self.ex_air_strike || self.ex_gunship)) return;
		if(wmdtodo == 4 && self.ex_gunship) return;
	}

	if(isPlayer(self))
	{
		self wmdStop();
		if(wmdtodo == 1)
		{
			if(!wmd_assigned) delay = level.ex_rank_mortar_first;
				else delay = 0;
			self thread extreme\_ex_mortar_player::start(delay);
		}
		else if(wmdtodo == 2)
		{
			if(!wmd_assigned) delay = level.ex_rank_artillery_first;
				else delay = 0;
			self thread extreme\_ex_artillery_player::start(delay);
		}
		else if(wmdtodo == 3)
		{
			if(!wmd_assigned) delay = level.ex_rank_airstrike_first;
				else delay = 0;
			self thread extreme\_ex_airstrike_player::start(delay);
		}
		else
		{
			if(!wmd_assigned) delay = level.ex_rank_gunship_first;
				else delay = 0;
			self thread extreme\_ex_gunship::gunshipPerk(delay);
		}
	}
}

wmdAllowedRandom()
{
	self endon("kill_thread");

	if(!level.ex_rank_allow_mortar && !level.ex_rank_allow_artillery && !level.ex_rank_allow_airstrike && !level.ex_rank_allow_special) return;

	wmd_assigned = false;
	if(self.ex_mortar_strike || self.ex_artillery_strike || self.ex_air_strike || self.ex_gunship) wmd_assigned = true;
	if(wmd_assigned && !level.ex_rank_wmd_upgrade) return;

	if(self.pers["rank"] < level.ex_rank_allow_rank)
	{
		if(wmd_assigned) self wmdStop();
		return;
	}

	mortar_allowed = level.ex_rank_allow_mortar;
	artillery_allowed = level.ex_rank_allow_artillery;
	airstrike_allowed = level.ex_rank_allow_airstrike || (level.ex_gunship != 2 && level.ex_rank_allow_special);
	gunship_allowed = (level.ex_gunship == 2 && level.ex_rank_allow_special && (level.ex_rank_gunship_next || !isDefined(self.pers["gunship"])));

	for(;;)
	{
		wmdtodo = randomInt(4) + 1;

		if(wmdtodo == 1 && mortar_allowed) break;
		if(wmdtodo == 2 && artillery_allowed) break;
		if(wmdtodo == 3 && airstrike_allowed) break;
		if(wmdtodo == 4 && gunship_allowed) break;

		wait( [[level.ex_fpstime]](0.1) );
	}

	if(wmd_assigned)
	{
		if(wmdtodo == 1) return;
		if(wmdtodo == 2 && (self.ex_artillery_strike || self.ex_air_strike || self.ex_gunship)) return;
		if(wmdtodo == 3 && (self.ex_air_strike || self.ex_gunship)) return;
		if(wmdtodo == 4 && self.ex_gunship) return;
	}

	if(isPlayer(self))
	{
		self wmdStop();
		if(wmdtodo == 1)
		{
			if(!wmd_assigned) delay = level.ex_rank_mortar_first;
				else delay = 0;
			self thread extreme\_ex_mortar_player::start(delay);
		}
		else if(wmdtodo == 2)
		{
			if(!wmd_assigned) delay = level.ex_rank_artillery_first;
				else delay = 0;
			self thread extreme\_ex_artillery_player::start(delay);
		}
		else if(wmdtodo == 3)
		{
			if(!wmd_assigned) delay = level.ex_rank_airstrike_first;
				else delay = 0;
			self thread extreme\_ex_airstrike_player::start(delay);
		}
		else
		{
			if(!wmd_assigned) delay = level.ex_rank_gunship_first;
				else delay = 0;
			self thread extreme\_ex_gunship::gunshipPerk(delay);
		}
	}
}

wmdStop()
{
	// stop wmd binoc threads
	self notify("end_waitforuse");
	wait( [[level.ex_fpstime]](0.1) );

	// stop mortars
	self.ex_mortar_strike = false;
	self notify("mortar_over");
	self notify("end_mortar");
	wait( [[level.ex_fpstime]](0.1) );

	// stop artillery
	self.ex_artillery_strike = false;
	self notify("artillery_over");
	self notify("end_artillery");
	wait( [[level.ex_fpstime]](0.1) );

	// stop airstrike
	self.ex_air_strike = false;
	self notify("airstrike_over");
	self notify("end_airstike");
	wait( [[level.ex_fpstime]](0.1) );

	// stop gunship
	if(level.ex_gunship == 2)
	{
		self.ex_gunship = false;
		self notify("gunship_over");
		self notify("end_gunship");
		wait( [[level.ex_fpstime]](0.1) );
	}

	// clear old hud elems
	if(isDefined(self.ex_wmd_icon)) self.ex_wmd_icon destroy();
	if(isDefined(self.ex_binocular_hint)) self.ex_binocular_hint destroy();
	wait( [[level.ex_fpstime]](0.1) );
}

rankupdate(promotion)
{
	self endon("disconnect");
	
	if(level.ex_rankhud && isPlayer(self)) self thread rankHud();

	rankstring = self getRankstring();

	while(self.sessionstate != "playing") wait( [[level.ex_fpstime]](0.5) );

	if(promotion)
	{
		if(level.ex_rank_announce == 1)
		{
			self iprintlnbold(&"RANK_PROMOTION_MSG", [[level.ex_pname]](self));
			self iprintlnbold(&"RANK_PROMOTION_START", &"RANK_MIDDLE_MSG", rankstring);
			self notify("rank changed");
			
			if(level.ex_currentgt == "cnq" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq")
				self playLocalSound("ctf_touchown");
			else
				self playLocalSound("promotion");
			
			//self thread PromotionImage();
		}

		self extreme\_ex_weapons::updateLoadout(true);
	}
	else
	{
		if(level.ex_rank_announce == 1)
		{
			self iprintlnbold(&"RANK_DEMOTION_MSG", [[level.ex_pname]](self));
			self iprintlnbold(&"RANK_DEMOTION_START", &"RANK_MIDDLE_MSG", rankstring);
			self notify("rank changed");
			
			if(level.ex_currentgt == "cnq" || level.ex_currentgt == "rbctf" || level.ex_currentgt == "rbcnq")
				self playLocalSound("ctf_touchenemy");
			else
				self playLocalSound("demotion");

			//self thread PromotionImage();
		}

		self wmdStop();
		self extreme\_ex_weapons::updateLoadout(false);
	}
}

rankHud()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(level.ex_rankhud == 2)
	{
		rankstring = self getRankstring();

		if(!isDefined(self.ex_rankhud1))
		{
			self.ex_rankhud1 = newClientHudElem(self);
			self.ex_rankhud1.horzAlign = "fullscreen";
			self.ex_rankhud1.vertAlign = "fullscreen";
			self.ex_rankhud1.alignX = "left";
			self.ex_rankhud1.alignY = "middle";
			self.ex_rankhud1.x = 605;
			self.ex_rankhud1.y = 435;
			self.ex_rankhud1.alpha = 1;
			self.ex_rankhud1.fontScale = 0.8;
			self.ex_rankhud1.label = &"RANK_RANK";
		}

		if(isDefined(self.ex_rankhud1)) self.ex_rankhud1 setText(rankstring);
	}
	
	chevron = self getHudIcon();

	if(!isDefined(self.ex_rankhud2))
	{
		self.ex_rankhud2 = newClientHudElem(self);
		self.ex_rankhud2.horzAlign = "fullscreen";
		self.ex_rankhud2.vertAlign = "fullscreen";
		self.ex_rankhud2.alignx = "center";
		self.ex_rankhud2.aligny = "middle";
		self.ex_rankhud2.x = 620;
		self.ex_rankhud2.y = 415;
		self.ex_rankhud2.alpha = level.ex_iconalpha;
	}
	
	if(isDefined(self.ex_rankhud2))
	{	
		self.ex_rankhud2 setShader(chevron, 40, 40);
		self.ex_rankhud2 scaleOverTime(.5, 32, 32);
	}
}

getRank()
{
	self endon("disconnect");

	// check if player has a preset rank
	if(!isDefined(self.pers["preset_rank"])) self.pers["preset_rank"] = self checkPresetRank();

	// determine rank using
	points = 0;
	if(level.ex_rank_score == 0)
	{
		points = self.score + game["rank_" + self.pers["preset_rank"]];
		points = points + self.pers["specials_cash"];
	}
	else if(level.ex_rank_score == 1)
	{
		points = (self.pers["kill"] + self.pers["special"]) - (self.pers["teamkill"] + self.pers["death"]);
		points = points + game["rank_" + self.pers["preset_rank"]];
	}
	else
	{
		points = (self.pers["kill"] + self.pers["special"] + self.pers["bonus"]) - (self.pers["teamkill"] + self.pers["death"]);
		points = points + game["rank_" + self.pers["preset_rank"]];
	}

	if(points >= game["rank_7"]) return 7;
      else if(points >= game["rank_7"] && points < game["rank_8"]) return 7;
	else if(points >= game["rank_6"] && points < game["rank_7"]) return 6;
	else if(points >= game["rank_5"] && points < game["rank_6"]) return 5;
	else if(points >= game["rank_4"] && points < game["rank_5"]) return 4;
	else if(points >= game["rank_3"] && points < game["rank_4"]) return 3;
	else if(points >= game["rank_2"] && points < game["rank_3"]) return 2;
	else if(points >= game["rank_1"] && points < game["rank_2"]) return 1;
	else return 0;
}

PromotionImage()
{
	self endon("disconnect");

	chevron = getHudIcon();

	if(!isDefined(self.ex_rankhud0))
	{
		self.ex_rankhud0 = newClientHudElem(self);
		self.ex_rankhud0.horzAlign = "fullscreen";
		self.ex_rankhud0.vertAlign = "fullscreen";
		self.ex_rankhud0.alignX = "center";
		self.ex_rankhud0.alignY = "middle";
		self.ex_rankhud0.x = 100;
		self.ex_rankhud0.y = 350;
		self.ex_rankhud0.alpha =0.8;
	}

	if(isDefined(self.ex_rankhud0)) self.ex_rankhud0 setShader(chevron, 50,50);
	if(isDefined(self.ex_rankhud0)) self.ex_rankhud0 scaleOverTime(1, 30, 30);
	wait( [[level.ex_fpstime]](3) );
	if(isDefined(self.ex_rankhud0)) self.ex_rankhud0 fadeOverTime(1, 0);
	if(isDefined(self.ex_rankhud0)) self.ex_rankhud0.alpha = 0;
	wait( [[level.ex_fpstime]](1) );
	if(isDefined(self.ex_rankhud0)) self.ex_rankhud0 destroy();
}

getRankstring()
{
	self endon("disconnect");

	rank = &"RANK_AMERICAN_0";

	if(self.pers["team"] == "allies")
	{				
		switch(game["allies"])
		{
			case "american":
			{
				switch(self.pers["rank"])
				{

					case 10:
					rank = &"RANK_AMERICAN_10"; // General
					break; 

					case 9:
					rank = &"RANK_AMERICAN_9"; // General
					break;

					case 8:
					rank = &"RANK_AMERICAN_8"; // General
					break;

					case 7:
					rank = &"RANK_AMERICAN_7"; // General
					break;

					case 6:
					rank = &"RANK_AMERICAN_6"; // Colonel
					break;				

					case 5:
					rank = &"RANK_AMERICAN_5"; // Major
					break;

					case 4:
					rank = &"RANK_AMERICAN_4"; // Captain
					break;

					case 3:
					rank = &"RANK_AMERICAN_3"; // Lieutenant
					break;

					case 2:
					rank = &"RANK_AMERICAN_2"; // Sergeant
					break;

					case 1:
					rank = &"RANK_AMERICAN_1"; // Corporal
					break;

					case 0:
					rank = &"RANK_AMERICAN_0"; // Private
					break;
				}
				break;
			}	
			
			case "british":
			{
				switch(self.pers["rank"])
				{ 

					case 10:
					rank = &"RANK_BRITISH_10"; // General
					break;

					case 9:
					rank = &"RANK_BRITISH_9"; // General
					break;

					case 8:
					rank = &"RANK_BRITISH_8"; // General
					break;

					case 7:
					rank = &"RANK_BRITISH_7"; // General
					break;

					case 6:
					rank = &"RANK_BRITISH_6"; // Colonel
					break;

					case 5:
					rank = &"RANK_BRITISH_5"; // Major
					break;

					case 4:
					rank = &"RANK_BRITISH_4"; // Captain
					break;

					case 3:
					rank = &"RANK_BRITISH_3"; // Lieutenant
					break;

					case 2:
					rank = &"RANK_BRITISH_2"; // Sergeant
					break;

					case 1:
					rank = &"RANK_BRITISH_1"; // Corporal
					break;

					case 0:
					rank = &"RANK_BRITISH_0"; // Private
					break;
				}
				break;
			}
			
			case "russian":
			{
				switch(self.pers["rank"])
				{

					case 10:
					rank = &"RANK_RUSSIAN_10"; // General-Poruchik
					break;

					case 9:
					rank = &"RANK_RUSSIAN_9"; // General-Poruchik
					break;

					case 8:
					rank = &"RANK_RUSSIAN_8"; // General-Poruchik
					break;

					case 7:
					rank = &"RANK_RUSSIAN_7"; // General-Poruchik
					break;

					case 6:
					rank = &"RANK_RUSSIAN_6"; // Polkovnik
					break;

					case 5:
					rank = &"RANK_RUSSIAN_5"; // Mayor
					break;

					case 4:
					rank = &"RANK_RUSSIAN_4"; // Kapitan
					break;

					case 3:
					rank = &"RANK_RUSSIAN_3"; // Leytenant
					break;

					case 2:
					rank = &"RANK_RUSSIAN_2"; // Podpraporshchik
					break;

					case 1:
					rank = &"RANK_RUSSIAN_1"; // Kapral
					break;

					case 0:
					rank = &"RANK_RUSSIAN_0"; // Soldat
					break;
				}
				break;
			}
		}
	}
	else if (self.pers["team"] == "axis")
	{
		switch(game["axis"])
		{
			case "german":
			{
				switch(self.pers["rank"])
				{

					case 10:
					rank = &"RANK_GERMAN_10"; // General
					break;

					case 9:
					rank = &"RANK_GERMAN_9"; // General
					break;

					case 8:
					rank = &"RANK_GERMAN_8"; // General
					break;

					case 7:
					rank = &"RANK_GERMAN_7"; // General
					break;

					case 6:
					rank = &"RANK_GERMAN_6"; // Oberst
					break;

					case 5:
					rank = &"RANK_GERMAN_5"; // Major
					break;

					case 4:
					rank = &"RANK_GERMAN_4"; // Hauptmann
					break;

					case 3:
					rank = &"RANK_GERMAN_3"; // Leutnant
					break;

					case 2:
					rank = &"RANK_GERMAN_2"; // Unterfeldwebel
					break;

					case 1:
					rank = &"RANK_GERMAN_1"; // Unteroffizier
					break;

					case 0:
					rank = &"RANK_GERMAN_0"; // Grenadier
					break;
				}
				break;
			}
		}
	}
	
	return rank;
}

getHudIcon()
{
	self endon("disconnect");

	if(!isdefined(self.pers["rank"]) || !isdefined(self.pers["team"]) || self.pers["team"] == "spectator") return "";
	return( game["hudicon_rank" + self.pers["rank"]] );
}

getStatusIcon()
{
	self endon("disconnect");

	if(!isdefined(self.pers["rank"]) || !isdefined(self.pers["team"]) || self.pers["team"] == "spectator") return "";
	return( game["statusicon_rank" + self.pers["rank"]] );
}

getHeadIcon()
{
	self endon("disconnect");

	if(!isdefined(self.pers["rank"]) || !isdefined(self.pers["team"]) || self.pers["team"] == "spectator") return "";
	return( game["headicon_rank" + self.pers["rank"]] );
}

checkPresetRank()
{
	self endon("disconnect");

	count = 0;
	clan_check = "";

	if(isDefined(self.ex_name))
	{
		// convert the players clan name
		playerclan = extreme\_ex_utils::convertMUJ(self.ex_name);

		for(;;)
		{
			// get the preset clan name
			clan_check = [[level.ex_drm]]("ex_psr_clan_" + count, "", "", "", "string");

			// check if there is a preset clan name, if not end here!
			if(clan_check == "") break;

			// convert clan name
			clan_check = extreme\_ex_utils::convertMUJ(clan_check);

			// if the names match, break here and set rank
			if(clan_check == playerclan) break;
				else count ++;
		}
	}

	if(clan_check != "")
		return [[level.ex_drm]]("ex_psr_rank_" + count, 0, 0, 8, "int");

	// convert the players name
	playername = extreme\_ex_utils::convertMUJ(self.name);

	count = 0;

	for(;;)
	{
		// get the preset player name
		name_check = [[level.ex_drm]]("ex_psr_name_" + count, "", "", "", "string");

		// check if there is a preset player name, if not end here!
		if(name_check == "") break;

		// convert name_check
		name_check = extreme\_ex_utils::convertMUJ(name_check);

		// if the names match, break here and set rank
		if(name_check == playername) break;
		else count ++;
	}

	if(name_check == "") return 0;
		else return [[level.ex_drm]]("ex_psr_rank_" + count, 0, 0, 8, "int");
}
