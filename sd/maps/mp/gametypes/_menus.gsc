
init()
{
	suffix = undefined;
	allteamweapons = false;
	allmodernweapons = false;

	if(level.ex_all_weapons) // all weapons for all teams
	{
			game["menu_weapon_allies"] = "weapon_all";
			game["menu_weapon_axis"] = "weapon_all";

			if(level.ex_wepo_secondary)
			{
				game["menu_weapon_allies_sec"] = "weapon_all_sec";
				game["menu_weapon_axis_sec"] = "weapon_all_sec";

				[[level.ex_PrecacheMenuItem]](game["menu_weapon_allies_sec"]);
				[[level.ex_PrecacheMenuItem]](game["menu_weapon_axis_sec"]);
			}
	}
	else if(level.ex_modern_weapons) // modern weapons
	{
		switch(level.ex_wepo_class)
		{
			case 1: suffix = "pistol_only"; break; // pistol only
			case 2: suffix = "sniper_only"; break; // sniper only
			case 3: suffix = "mg_only"; break; // mg only
			case 4: suffix = "smg_only"; break; // smg only
			case 7: suffix = "shotgun_only"; break; // shotgun only
			default: allmodernweapons = true; break; // all modern menus
		}

		if(allmodernweapons) // all modern menus
		{
			game["menu_weapon_allies"] = "weapon_modern";
			game["menu_weapon_axis"] = "weapon_modern";
		}
		else // weapon class menus
		{
			game["menu_weapon_allies"] = "weapon_modern_" + suffix;
			game["menu_weapon_axis"] = "weapon_modern_" + suffix;
		}

		if(level.ex_wepo_secondary)
		{
			game["menu_weapon_allies_sec"] = "weapon_modern_sec";
			game["menu_weapon_axis_sec"] = "weapon_modern_sec";

			[[level.ex_PrecacheMenuItem]](game["menu_weapon_allies_sec"]);
			[[level.ex_PrecacheMenuItem]](game["menu_weapon_axis_sec"]);
		}
	}
	else
	{
		switch(level.ex_wepo_class)
		{
			case 1: suffix = "pistol_only"; break; // pistol only
			case 2: suffix = "sniper_only"; break; // sniper only
			case 3: suffix = "mg_only"; break; // mg only
			case 4: suffix = "smg_only"; break; // smg only
			case 5: suffix = "rifle_only"; break; // rifle only
			case 6: suffix = "bolt_only"; break; // bolt action rifle only
			case 7: suffix = "shotgun_only"; break; // shotgun only
			case 9: suffix = "boltsniper_only"; break; // bolt and sniper only
			case 10: suffix = "knives_only"; break; // knives only
			default: allteamweapons = true; break; // stock menus
		}

		if(allteamweapons) // stock menus
		{
			game["menu_weapon_allies"] = "weapon_" + game["allies"];
			game["menu_weapon_axis"] = "weapon_" + game["axis"];
		}
		else // weapon class menus
		{
			// if team based, define allies and axis teams
			if(level.ex_wepo_team_only)
			{
				game["menu_weapon_allies"] = "weapon_" + game["allies"] + "_" + suffix;
				game["menu_weapon_axis"] = "weapon_" + game["axis"] + "_" + suffix;
			}
			else
			{
				game["menu_weapon_allies"] = "weapon_" + suffix;
				game["menu_weapon_axis"] = "weapon_" + suffix;
			}
		}

		if(level.ex_wepo_secondary)
		{
			if(!level.ex_wepo_sec_enemy)
			{
				game["menu_weapon_allies_sec"] = "weapon_" + game["allies"] + "_sec";
				game["menu_weapon_axis_sec"] = "weapon_" + game["axis"] + "_sec";
			}
			else
			{
				game["menu_weapon_axis_sec"] = "weapon_" + game["allies"] + "_sec";
				game["menu_weapon_allies_sec"] = "weapon_" + game["axis"] + "_sec";
			}

			[[level.ex_PrecacheMenuItem]](game["menu_weapon_allies_sec"]);
			[[level.ex_PrecacheMenuItem]](game["menu_weapon_axis_sec"]);
		}
	}

	game["menu_ingame"] = "ingame";
	game["menu_team"] = "team_" + game["allies"] + game["axis"];
	game["menu_callvote"] = "callvote";
	game["menu_muteplayer"] = "muteplayer";
	game["menu_serverinfo"] = "serverinfo_" + level.ex_currentgt;
	game["menu_clanlogin"] = "clanlogin";
	if(level.ex_bsod && level.ex_bsod_blockmenu) game["menu_blackscreen"] = "blackscreen";

	[[level.ex_PrecacheMenuItem]](game["menu_ingame"]);
	[[level.ex_PrecacheMenuItem]](game["menu_team"]);
	[[level.ex_PrecacheMenuItem]](game["menu_weapon_allies"]);
	[[level.ex_PrecacheMenuItem]](game["menu_weapon_axis"]);
	[[level.ex_PrecacheMenuItem]](game["menu_callvote"]);
	[[level.ex_PrecacheMenuItem]](game["menu_muteplayer"]);
	[[level.ex_PrecacheMenuItem]](game["menu_serverinfo"]);
	if(level.ex_clanlogin) [[level.ex_PrecacheMenuItem]](game["menu_clanlogin"]);
	if(level.ex_bsod && level.ex_bsod_blockmenu) [[level.ex_PrecacheMenuItem]](game["menu_blackscreen"]);

	if(level.ex_mbot && level.ex_mbot_dev)
	{
		game["quickmessages"] = "quickmbot_main";
		game["menu_mbot_wpsel"] = "quickmbot_wpsel";
		game["menu_mbot_wptype"] = "quickmbot_wptype";
		game["menu_mbot_wpact"] = "quickmbot_wpact";
		game["menu_mbot_buddy"] = "quickmbot_buddy";
		game["menu_mbot_file"] = "quickmbot_file";
		game["menu_mbot_misc"] = "quickmbot_misc";
		[[level.ex_PrecacheMenuItem]](game["quickmessages"]);
		[[level.ex_PrecacheMenuItem]](game["menu_mbot_wpsel"]);
		[[level.ex_PrecacheMenuItem]](game["menu_mbot_wptype"]);
		[[level.ex_PrecacheMenuItem]](game["menu_mbot_wpact"]);
		[[level.ex_PrecacheMenuItem]](game["menu_mbot_buddy"]);
		[[level.ex_PrecacheMenuItem]](game["menu_mbot_file"]);
		[[level.ex_PrecacheMenuItem]](game["menu_mbot_misc"]);
	}
	else
	{
		game["quickmessages"] = "quickmessages";
		[[level.ex_PrecacheMenuItem]](game["quickmessages"]);
	}

	if(level.ex_rcon)
	{
		game["menu_rcon_login"] = "rcon_login";
		game["menu_rcon_main"] = "rcon_main";
		game["menu_rcon_mapctrl"] = "rcon_mapctrl";
		game["menu_rcon_playerctrl"] = "rcon_playerctrl";
		game["menu_rcon_mbotctrl"] = "rcon_mbotctrl";
		game["menu_rcon_msgcenter"] = "rcon_msgcenter";
		game["menu_rcon_setsvr"] = "rcon_setsvr";
		game["menu_rcon_setclnt"] = "rcon_setclnt";
		game["menu_rcon_setwpn"] = "rcon_setwpn";

		[[level.ex_PrecacheMenuItem]](game["menu_rcon_login"]);
		[[level.ex_PrecacheMenuItem]](game["menu_rcon_main"]);
		[[level.ex_PrecacheMenuItem]](game["menu_rcon_mapctrl"]);
		[[level.ex_PrecacheMenuItem]](game["menu_rcon_playerctrl"]);
		[[level.ex_PrecacheMenuItem]](game["menu_rcon_mbotctrl"]);
		[[level.ex_PrecacheMenuItem]](game["menu_rcon_msgcenter"]);
		[[level.ex_PrecacheMenuItem]](game["menu_rcon_setsvr"]);
		[[level.ex_PrecacheMenuItem]](game["menu_rcon_setclnt"]);
		[[level.ex_PrecacheMenuItem]](game["menu_rcon_setwpn"]);
	}

	[[level.ex_registerCallback]]("onPlayerConnected", ::onPlayerConnected);
}

onPlayerConnected()
{
	self thread onMenuResponse();
}

onMenuResponse()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill("menuresponse", menu, response);

		if(!isDefined(menu)) continue;
		//logprint("DEBUG MENU: " + self.name + " menu " + menu + ":" + response + "\n");

		if(response == "menuopen")
		{
			if(menu == game["menu_serverinfo"])
				self notify("start_motd_rotation");

			self.ex_inmenu = true;
			continue;
		}

		if(response == "menuclose")
		{
			self.ex_inmenu = false;
			continue;
		}

		if(menu == game["menu_clanlogin"])
		{
			self thread extreme\_ex_clanlogin::main(response);
			continue;
		}

		if(menu == game["menu_serverinfo"])
		{
			self notify("stop_motd_rotation");

			if(level.ex_clanlogin && isDefined(self.ex_name) && self.ex_clanlogin)
			{
				self setClientCvar("g_scriptMainMenu", game["menu_clanlogin"]);
				self closeMenu();
				self openMenu(game["menu_clanlogin"]);
				continue;
			}

			if(response == "team" && isDefined(self.pers["team"]) && self.pers["team"] == "spectator")
			{
				if(self.ex_autoassign)
				{
					if(level.ex_clanvsnonclan || level.ex_autoassign_bridge)
					{
						self.ex_autoassign_team = level.ex_autoassign_nonclanteam;
						//logprint("TEAM DEBUG (M): " + self.name + " bridging " + self.ex_autoassign_team + "\n");
						self thread autoAssignBridge(level.ex_autoassign_nonclanteam);
					}
					else
					{
						//logprint("TEAM DEBUG (M): " + self.name + " bridging autoassign\n");
						self thread autoAssignBridge("autoassign");
					}
				}
				else
				{
					if(level.ex_clanvsnonclan || level.ex_autoassign_bridge)
					{
						self.ex_autoassign_team = level.ex_autoassign_clanteam;
						//logprint("TEAM DEBUG (M): " + self.name + " bridging " + self.ex_autoassign_team + "\n");
						self thread autoAssignBridge(level.ex_autoassign_clanteam);
					}
					//else logprint("TEAM DEBUG (M): " + self.name + " free to select team\n");
				}

				self closeMenu();
				self openMenu(game["menu_team"]);
			}
			else
			{
				self closeMenu();
				self closeInGameMenu();
			}
		}

		if(response == "open" || response == "close") continue;

		if(response == "back")
		{
			self closeMenu();
			self closeInGameMenu();

			if(menu == game["menu_team"])
			{
				self openMenu(game["menu_ingame"]);
			}
			else if(menu == game["menu_weapon_allies"] || menu == game["menu_weapon_axis"])
				self openMenu(game["menu_team"]);
				
			continue;
		}

		if(response == "endgame") continue;

		if(menu == game["menu_ingame"])
		{
			switch(response)
			{
			case "changeweapon":
				self closeMenu();
				self closeInGameMenu();

				if(level.ex_frag_fest) continue;

				if(level.ex_currentgt == "ft")
				{
					if(!level.roundended && !level.ft_weaponchange && isDefined(self.frozenstate) && self.frozenstate == "frozen")
					{
						self closeMenu();
						self closeInGameMenu();
						self iprintlnbold(&"FT_NO_WEAPON_CHANGE");
						break;
					}
				}

				// do not show current weapons in use!
				self extreme\_ex_weapons::setWeaponClientStatus(false);

				if(level.ex_wepo_secondary)
				{
					self setClientCvar("ui_allow_primary", "1");
					self setClientCvar("ui_allow_secondary", "1");
				}
				else
				{
					self setClientCvar("ui_allow_primary", "0");
					self setClientCvar("ui_allow_secondary", "0");
				}

				if(isDefined(self.pers) && isDefined(self.pers["team"]))
				{
					if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies"]);
						else if(self.pers["team"] == "axis") self openMenu(game["menu_weapon_axis"]);
				}
				break;	

			case "changeteam":
				if(level.ex_currentgt == "ft")
				{
					if(!level.ft_teamchange && isDefined(self.frozenstate) && self.frozenstate == "frozen")
					{
						self closeMenu();
						self closeInGameMenu();
						self iprintlnbold(&"FT_NO_TEAM_CHANGE");
						break;
					}

					if(isDefined(self.spawned))
					{
						self closeMenu();
						self closeInGameMenu();
						self iprintlnbold(&"FT_NO_CHANGE_WAITING");
						break;
					}
				}

				self closeMenu();
				self closeInGameMenu();
				self openMenu(game["menu_team"]);
				break;

			case "muteplayer":
				self closeMenu();
				self closeInGameMenu();
				self openMenu(game["menu_muteplayer"]);
				break;

			case "callvote":
				self closeMenu();
				self closeInGameMenu();
				if(getCvarInt("g_allowvote") && (!level.ex_clanvoting || (isDefined(self.ex_name) && level.ex_clvote[self.ex_clid]))) self openMenu(game["menu_callvote"]);
					else self iprintln(&"GAME_VOTINGNOTENABLED");
				break;
				
			case "serverinfo":
				self closeMenu();
				self closeInGameMenu();
				self notify("start_motd_rotation");
				self openMenu(game["menu_serverinfo"]);
				break;

			case "togglediana":
				self closeMenu();
				self closeInGameMenu();
				self thread extreme\_ex_diana::toggleDiana();
				break;

			case "keys":
				self closeMenu();
				self closeInGameMenu();
				self openMenu(game["menu_keys"]);
				break;

			case "savezoom":
				self closeMenu();
				self closeInGameMenu();
				self thread extreme\_ex_zoom::saveZoom();
				break;

			case "rcon_main":
				self closeMenu();
				self closeInGameMenu();
				self openMenu(game["menu_rcon_main"]);
				break;

			case "hub_server1":
				if(level.ex_hub_server1_ip != "")
				{
					self closeMenu();
					self closeInGameMenu();
					self thread extreme\_ex_utils::execClientCommand("connect " + level.ex_hub_server1_ip);
				}
				break;

			case "hub_server2":
				if(level.ex_hub_server2_ip != "")
				{
					self closeMenu();
					self closeInGameMenu();
					self thread extreme\_ex_utils::execClientCommand("connect " + level.ex_hub_server2_ip);
				}
				break;

			case "hub_server3":
				if(level.ex_hub_server3_ip != "")
				{
					self closeMenu();
					self closeInGameMenu();
					self thread extreme\_ex_utils::execClientCommand("connect " + level.ex_hub_server3_ip);
				}
				break;

			case "hub_server4":
				if(level.ex_hub_server4_ip != "")
				{
					self closeMenu();
					self closeInGameMenu();
					self thread extreme\_ex_utils::execClientCommand("connect " + level.ex_hub_server4_ip);
				}
				break;
			}
		}
		else if(menu == game["menu_team"])
		{
			switch(response)
			{
			case "allies":
				if(level.ex_autoassign == 0 ||
					(level.ex_autoassign == 2 && isDefined(self.ex_name) && self.ex_clid == 1) ||
					(self.ex_autoassign && isDefined(self.ex_autoassign_team) && self.ex_autoassign_team == "allies") ||
					isDefined(self.pers["isbot"]) )
				{
					//logprint("TEAM DEBUG (M): " + self.name + " selecting " + response + "\n");
					self closeMenu();
					self closeInGameMenu();
					self [[level.allies]]();
				}
				break;

			case "axis":
				if(level.ex_autoassign == 0 ||
					(level.ex_autoassign == 2 && isDefined(self.ex_name) && self.ex_clid == 1) ||
					(self.ex_autoassign && isDefined(self.ex_autoassign_team) && self.ex_autoassign_team == "axis") ||
					isDefined(self.pers["isbot"]) )
				{
					//logprint("TEAM DEBUG (M): " + self.name + " selecting " + response + "\n");
					self closeMenu();
					self closeInGameMenu();
					self [[level.axis]]();
				}
				break;

			case "autoassign":
				if(level.ex_autoassign == 0 || level.ex_autoassign == 1 ||
					(!level.ex_clanvsnonclan && !level.ex_autoassign_bridge) ||
					(!level.ex_clanvsnonclan && isDefined(self.ex_name) && self.ex_clid == 1) ||
					isDefined(self.pers["isbot"]) )
				{
					//logprint("TEAM DEBUG (M): " + self.name + " selecting " + response + "\n");
					self closeMenu();
					self closeInGameMenu();
					self [[level.autoassign]]();
				}
				break;

			case "spectator":
				if(!level.ex_clanspectating || (level.ex_clanspectating && isDefined(self.ex_name) && level.ex_clspec[self.ex_clid])) allowspec = true;
					else allowspec = false;

				if(allowspec)
				{
					if(level.ex_specmusic && !self.pers["spec_on"])
					{
						self playLocalSound("spec_music_null");
						self.pers["spec_on"] = true;
						self playLocalSound("spec_music");
						self thread spec_monitor();
					}
					self closeMenu();
					self closeInGameMenu();
					self [[level.spectator]]();
				}
				break;

			case "serverinfo":
				self closeMenu();
				self closeInGameMenu();
				self notify("start_motd_rotation");
				self openMenu(game["menu_serverinfo"]);
				break;
			}
		}
		else if(menu == game["menu_weapon_allies"] || menu == game["menu_weapon_axis"])
		{
			if(response == "teamchange")
			{
				self closeMenu();
				self closeInGameMenu();
				self openMenu(game["menu_team"]);
			}
			else if(response == "secondary" && isDefined(self.pers["weapon2"]))
			{
				self closeMenu();
				self closeInGameMenu();

				if(isDefined(self.pers) && isDefined(self.pers["team"]))
				{
					if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies_sec"]);
						else if(self.pers["team"] == "axis") self openMenu(game["menu_weapon_axis_sec"]);
				}
			}
			else if(response != "secondary")
			{
				self closeMenu();
				self closeInGameMenu();
				self [[level.weapon]](response);
			}
		}
		else if(level.ex_wepo_secondary && (menu == game["menu_weapon_allies_sec"] || menu == game["menu_weapon_axis_sec"]))
		{
			if(response == "primary" && isDefined(self.pers["weapon1"]))
			{
				self closeMenu();
				self closeInGameMenu();

				if(isDefined(self.pers) && isDefined(self.pers["team"]))
				{
					if(self.pers["team"] == "allies") self openMenu(game["menu_weapon_allies"]);
						else if(self.pers["team"] == "axis") self openMenu(game["menu_weapon_axis"]);
				}
			}
			else
			{
				self closeMenu();
				self closeInGameMenu();
				self extreme\_ex_clientcontrol::menuSecWeapon(response);
			}
		}
		else if((level.ex_taunts == 1 || level.ex_taunts == 3) && isDefined(game["menu_quicktaunts"]) && menu == game["menu_quicktaunts"])
		{
			self thread maps\mp\gametypes\_quickmessages::quicktaunts(response);
		}
		else if((level.ex_taunts == 1 || level.ex_taunts == 3) && isDefined(game["menu_quicktauntsb"]) && menu == game["menu_quicktauntsb"])
		{
			self thread maps\mp\gametypes\_quickmessages::quicktauntsb(response);
		}
		else if(isDefined(game["menu_quickresponseslib"]) && menu == game["menu_quickresponseslib"])
		{
			self thread maps\mp\gametypes\_quickmessages::quickresponseslib(response);
		}
		else if(isDefined(game["menu_quickresponsesft"]) && menu == game["menu_quickresponsesft"])
		{
			self thread maps\mp\gametypes\_quickmessages::quickresponsesft(response);
		}
		else if(isDefined(game["menu_quickspecials"]) && menu == game["menu_quickspecials"])
		{
			self thread extreme\_ex_specials::quickrequests(response);
		}
		else if(isDefined(game["menu_quickjukebox"]) && menu == game["menu_quickjukebox"])
		{
			self thread extreme\_ex_jukebox::jukeboxMenuDispatch(response);
		}
		else
		{
			if(menu == game["menu_quickcommands"]) self thread maps\mp\gametypes\_quickmessages::quickcommands(response);
			else if(menu == game["menu_quickstatements"]) self thread maps\mp\gametypes\_quickmessages::quickstatements(response);
			else if(menu == game["menu_quickresponses"]) self thread maps\mp\gametypes\_quickmessages::quickresponses(response);
			else if(menu == game["menu_quickrequests"]) self thread maps\mp\gametypes\_quickmessages::quickrequests(response);
			else if(menu == game["menu_keys"]) self thread extreme\_ex_longrange::changeBind(response);
			else if(level.ex_rcon)
			{
				if(menu == game["menu_rcon_main"]) self thread extreme\_ex_rcon::rconMain(response);
				else if(menu == game["menu_rcon_mapctrl"]) self thread extreme\_ex_rcon::rconMapCtrl(response);
				else if(menu == game["menu_rcon_playerctrl"]) self thread extreme\_ex_rcon::rconPlayerCtrl(response);
				else if(menu == game["menu_rcon_mbotctrl"]) self thread extreme\_ex_rcon::rconMbotCtrl(response);
				else if(menu == game["menu_rcon_msgcenter"]) self thread extreme\_ex_rcon::rconMsgCenter(response);
				else if(menu == game["menu_rcon_setsvr"]) self thread extreme\_ex_rcon::rconSetSvr(response);
				else if(menu == game["menu_rcon_setclnt"]) self thread extreme\_ex_rcon::rconSetClnt(response);
				else if(menu == game["menu_rcon_setwpn"]) self thread extreme\_ex_rcon::rconSetWpn(response);
			}
			else if(level.ex_mbot && level.ex_mbot_dev)
			{
				if(menu == game["menu_mbot_wpsel"]) self thread extreme\_ex_mbot_dev::menuWaypointSelect(response);
				else if(menu == game["menu_mbot_wptype"]) self thread extreme\_ex_mbot_dev::menuWaypointType(response);
				else if(menu == game["menu_mbot_wpact"]) self thread extreme\_ex_mbot_dev::menuWaypointAction(response);
				else if(menu == game["menu_mbot_buddy"]) self thread extreme\_ex_mbot_dev::menuBuddy(response);
				else if(menu == game["menu_mbot_file"]) self thread extreme\_ex_mbot_dev::menuFile(response);
				else if(menu == game["menu_mbot_misc"]) self thread extreme\_ex_mbot_dev::menuMisc(response);
			}
		}
	}
}

autoAssignBridge(team)
{
	wait( [[level.ex_fpstime]](0.1) ); // DO NOT REMOVE, CHANGE OR DISABLE!
	self notify("menuresponse", game["menu_team"], team);
	//logprint("TEAM DEBUG: " + self.name + " bridged to " + team + "\n");
}

spec_monitor() //spectator music switch
{
	self endon("disconnect");

	mt = undefined;
	
	self.music_chg = newClientHudElem(self);	
	self.music_chg.x = 322;
	self.music_chg.y = 462;
	self.music_chg.alpha = 1;
	self.music_chg.fontscale = 1;
	self.music_chg.alignX = "center";
	self.music_chg.alignY = "middle";
	self.music_chg setText(&"MISC_MELEE_CHANGE_MUSIC");
	
	for(;;)
	{
		if(self meleeButtonPressed())
		{
			self.music_chg fadeovertime(.2);
			self.music_chg.alpha = 0;
			self playLocalSound("spec_music_null");
			self playLocalSound("spec_music_stop");
			wait( [[level.ex_fpstime]](0.2) );
			self.music_chg setText(&"MISC_MUSIC_CHNG");
			self.music_chg fadeovertime(.2);
			self.music_chg.alpha = 1;
			self playLocalSound("spec_music");
			mt = 30;
		}
		
		if(isdefined(mt) && mt <= 0)
		{
			mt = undefined;
			self.music_chg fadeovertime(.2);
			self.music_chg.alpha = 0;
			wait( [[level.ex_fpstime]](0.2) );
			self.music_chg setText(&"MISC_MELEE_CHANGE_MUSIC");
			self.music_chg fadeovertime(.2);
			self.music_chg.alpha = 1;
		}
		
		if(isdefined(mt) && mt > 0) mt--;
		
		if(!self.pers["spec_on"] || level.ex_gameover == true)
		{
			self.music_chg destroy();
			break;
		}

		wait( [[level.ex_fpstime]](0.01) );
	}
}
