
cleanAllHud()
{
	if(isDefined(level.ruhud_readyup)) level.ruhud_readyup destroy();
	if(isDefined(level.ruhud_status1)) level.ruhud_status1 destroy();
	if(isDefined(level.ruhud_status2)) level.ruhud_status2 destroy();
	if(isDefined(level.ruhud_status3)) level.ruhud_status3 destroy();
	if(isDefined(level.ruhud_timer)) level.ruhud_timer destroy();
	if(isDefined(level.ruhud_back)) level.ruhud_back destroy();
	if(isDefined(level.ruhud_front)) level.ruhud_front destroy();
	if(isDefined(level.ruhud_text)) level.ruhud_text destroy();

	if(isDefined(level.clock)) level.clock destroy();
	if(isDefined(level.roundclock)) level.roundclock destroy();

	if(isDefined(level.mylogo_img)) level.mylogo_img destroy();

	if(isDefined(level.compass_img)) level.compass_img destroy();
	if(isDefined(level.compass_imgA)) level.compass_imgA destroy();
	if(isDefined(level.compass_imgX)) level.compass_imgX destroy();

	if(isDefined(level.ex_axisicon)) level.ex_axisicon destroy();
	if(isDefined(level.ex_axisnumber)) level.ex_axisnumber destroy();
	if(isDefined(level.ex_deadaxisicon)) level.ex_deadaxisicon destroy();
	if(isDefined(level.ex_deadaxisnumber)) level.ex_deadaxisnumber destroy();
	if(isDefined(level.ex_alliedicon)) level.ex_alliedicon destroy();
	if(isDefined(level.ex_alliednumber)) level.ex_alliednumber destroy();
	if(isDefined(level.ex_deadalliedicon)) level.ex_deadalliedicon destroy();
	if(isDefined(level.ex_deadalliednumber)) level.ex_deadalliednumber destroy();

	if(isDefined(level.ex_mapannouncer)) level.ex_mapannouncer destroy();
	if(isDefined(level.ex_modeannouncer)) level.ex_modeannouncer destroy();
	if(isDefined(level.ex_clanannouncer)) level.ex_clanannouncer destroy();

	if(level.ex_sentrygun && isDefined(level.sentryguns))
	{
		for(i = 0; i < level.sentryguns.size; i++)
			if(level.sentryguns[i].inuse && !level.sentryguns[i].destroyed) thread extreme\_ex_specials_sentrygun::sentrygunRemove(i);
	}

	// clean all level based, game type specific hud elems
	switch(level.ex_currentgt)
	{
		case "chq":
			if(level.ex_objindicator) thread maps\mp\gametypes\_objpoints::removeObjpoints();
			if(isDefined(level.progressbar_axis_neutralize)) level.progressbar_axis_neutralize destroy();
			if(isDefined(level.progressbar_axis_neutralize2)) level.progressbar_axis_neutralize2 destroy();
			if(isDefined(level.progressbar_axis_neutralize3)) level.progressbar_axis_neutralize3 destroy();
			if(isDefined(level.progressbar_allies_neutralize)) level.progressbar_allies_neutralize destroy();
			if(isDefined(level.progressbar_allies_neutralize2)) level.progressbar_allies_neutralize2 destroy();
			if(isDefined(level.progressbar_allies_neutralize3)) level.progressbar_allies_neutralize3 destroy();
			break;
		case "cnq":
			if(isDefined(level._score_icons))
			{
				for(i = 0; i < level._score_icons.size; i++)
					if(isDefined(level._score_icons[i])) level._score_icons[i] destroy();
			}
			if(isDefined(level._team_objs))
			{
				for(i = 0; i < level._team_objs.size; i++)
					if(isDefined(level._team_objs[i])) level._team_objs[i] destroy();
			}
			if(isDefined(level.hud))
			{
			  for(i = 0; i < level.hud.size; i++)
					if(isDefined(level.hud[i])) level.hud[i] destroy();
			}
			break;
		case "ctf":
			allied_flag = getent("allied_flag", "targetname");
			if(isDefined(allied_flag.waypoint_flag)) allied_flag.waypoint_flag destroy();
			if(isDefined(allied_flag.waypoint_base)) allied_flag.waypoint_base destroy();
			axis_flag = getent("axis_flag", "targetname");
			if(isDefined(axis_flag.waypoint_flag)) axis_flag.waypoint_flag destroy();
			if(isDefined(axis_flag.waypoint_base)) axis_flag.waypoint_base destroy();
			break;
		case "ctfb":
			allied_flag = level.flags["allies"];
			if(isDefined(allied_flag.waypoint_flag)) allied_flag.waypoint_flag destroy();
			if(isDefined(allied_flag.waypoint_base)) allied_flag.waypoint_base destroy();
			axis_flag = level.flags["axis"];
			if(isDefined(axis_flag.waypoint_flag)) axis_flag.waypoint_flag destroy();
			if(isDefined(axis_flag.waypoint_base)) axis_flag.waypoint_base destroy();
			break;
		case "dm":
			break;
		case "dom":
			if(isDefined(level.waitmsg)) level.waitmsg destroy();
			if(isDefined(level.warmupcountdown)) level.warmupcountdown destroy();
			if(isDefined(level.flags))
			{
			  for(i = 0; i < level.flags.size; i++)
					if(isDefined(level.flags[i].waypoint_flag)) level.flags[i].waypoint_flag destroy();
			}
			if(isDefined(level.hud))
			{
			  for(i = 0; i < level.hud.size; i++)
					if(isDefined(level.hud[i])) level.hud[i] destroy();
			}
			break;
		case "esd":
			if(level.ex_objindicator) thread maps\mp\gametypes\_objpoints::removeObjpoints();
			if(isDefined(level.hud))
			{
			  for(i = 0; i < level.hud.size; i++)
					if(isDefined(level.hud[i])) level.hud[i] destroy();
			}
			break;
		case "hm":
			break;
		case "hq":
			if(level.ex_objindicator) thread maps\mp\gametypes\_objpoints::removeObjpoints();
			if(isDefined(level.progressbar_axis_neutralize)) level.progressbar_axis_neutralize destroy();
			if(isDefined(level.progressbar_axis_neutralize2)) level.progressbar_axis_neutralize2 destroy();
			if(isDefined(level.progressbar_axis_neutralize3)) level.progressbar_axis_neutralize3 destroy();
			if(isDefined(level.progressbar_allies_neutralize)) level.progressbar_allies_neutralize destroy();
			if(isDefined(level.progressbar_allies_neutralize2)) level.progressbar_allies_neutralize2 destroy();
			if(isDefined(level.progressbar_allies_neutralize3)) level.progressbar_allies_neutralize3 destroy();
			break;
		case "htf":
			if(isDefined(level.flag) && isDefined(level.flag.waypoint)) level.flag.waypoint destroy();
			if(isDefined(level.scoreback)) level.scoreback destroy();
			if(isDefined(level.scoreallies)) level.scoreallies destroy();
			if(isDefined(level.scoreaxis)) level.scoreaxis destroy();
			if(isDefined(level.iconallies)) level.iconallies destroy();
			if(isDefined(level.iconaxis)) level.iconaxis destroy();
			if(isDefined(level.numallies)) level.numallies destroy();
			if(isDefined(level.numaxis)) level.numaxis destroy();
			break;
		case "ihtf":
			if(isDefined(level.flag) && isDefined(level.flag.waypoint)) level.flag.waypoint destroy();
			if(isDefined(level.cursorleft)) level.cursorleft destroy();
			if(isDefined(level.scoreback)) level.scoreback destroy();
			if(isDefined(level.cursorright)) level.cursorright destroy();
			break;
		case "lib":
			if(isDefined(level.libhud_axisicon)) level.libhud_axisicon destroy();
			if(isDefined(level.libhud_alliesicon)) level.libhud_alliesicon destroy();
			if(isDefined(level.libhud_axisfree)) level.libhud_axisfree destroy();
			if(isDefined(level.libhud_alliesfree)) level.libhud_alliesfree destroy();
			if(isDefined(level.libhud_axis)) level.libhud_axis destroy();
			if(isDefined(level.libhud_allies)) level.libhud_allies destroy();
			break;
		case "lms":
			if(isDefined(level.aphud)) level.aphud destroy();
			if(isDefined(level.duelback)) level.duelback destroy();
			if(isDefined(level.duelfront)) level.duelfront destroy();
			if(isDefined(level.dueltext)) level.dueltext destroy();
			break;
		case "lts":
			break;
		case "ons":
			if(isDefined(level.waitmsg)) level.waitmsg destroy();
			if(isDefined(level.warmupcountdown)) level.warmupcountdown destroy();
			if(isDefined(level.flags))
			{
			  for(i = 0; i < level.flags.size; i++)
					if(isDefined(level.flags[i].waypoint_flag)) level.flags[i].waypoint_flag destroy();
			}
			if(isDefined(level.hud))
			{
			  for(i = 0; i < level.hud.size; i++)
					if(isDefined(level.hud[i])) level.hud[i] destroy();
			}
			break;
		case "rbcnq":
			if(isDefined(level.timeclock))
			{
				if(isDefined(level.timeclock.enclosure)) level.timeclock.enclosure destroy();
				level.timeclock destroy();
			}
			if(isDefined(level.axisicon)) level.axisicon destroy();
			if(isDefined(level.axisnumber)) level.axisnumber destroy();
			if(isDefined(level.deadaxisicon)) level.deadaxisicon destroy();
			if(isDefined(level.deadaxisnumber)) level.deadaxisnumber destroy();
			if(isDefined(level.alliedicon)) level.alliedicon destroy();
			if(isDefined(level.alliednumber)) level.alliednumber destroy();
			if(isDefined(level.deadalliesicon)) level.deadalliesicon destroy();
			if(isDefined(level.deadalliednumber)) level.deadalliednumber destroy();
			if(isDefined(level.hud))
			{
			  for(i = 0; i < level.hud.size; i++)
					if(isDefined(level.hud[i])) level.hud[i] destroy();
			}
			break;
		case "rbctf":
			allied_flag = getent("allied_flag", "targetname");
			if(isDefined(allied_flag.waypoint_flag)) allied_flag.waypoint_flag destroy();
			if(isDefined(allied_flag.waypoint_base)) allied_flag.waypoint_base destroy();
			axis_flag = getent("axis_flag", "targetname");
			if(isDefined(axis_flag.waypoint_flag)) axis_flag.waypoint_flag destroy();
			if(isDefined(axis_flag.waypoint_base)) axis_flag.waypoint_base destroy();
			if(isDefined(level.timeclock))
			{
				if(isDefined(level.timeclock.enclosure)) level.timeclock.enclosure destroy();
				level.timeclock destroy();
			}
			if(isDefined(level.axisicon)) level.axisicon destroy();
			if(isDefined(level.axisnumber)) level.axisnumber destroy();
			if(isDefined(level.deadaxisicon)) level.deadaxisicon destroy();
			if(isDefined(level.deadaxisnumber)) level.deadaxisnumber destroy();
			if(isDefined(level.alliedicon)) level.alliedicon destroy();
			if(isDefined(level.alliednumber)) level.alliednumber destroy();
			if(isDefined(level.deadalliesicon)) level.deadalliesicon destroy();
			if(isDefined(level.deadalliednumber)) level.deadalliednumber destroy();
			if(isDefined(level.hud))
			{
			  for(i = 0; i < level.hud.size; i++)
					if(isDefined(level.hud[i])) level.hud[i] destroy();
			}
			break;
		case "sd":
			if(level.ex_objindicator) thread maps\mp\gametypes\_objpoints::removeObjpoints();
			if(isDefined(level.hud))
			{
			  for(i = 0; i < level.hud.size; i++)
					if(isDefined(level.hud[i])) level.hud[i] destroy();
			}
			break;
		case "tdm":
			break;
		case "tkoth":
			if(level.ex_objindicator) thread maps\mp\gametypes\_objpoints::removeObjpoints();
			if(isDefined(level.inzoneallies)) level.inzoneallies destroy();
			if(isDefined(level.iconallies)) level.iconallies destroy();
			if(isDefined(level.timeallies)) level.timeallies destroy();
			if(isDefined(level.timeback)) level.timeback destroy();
			if(isDefined(level.timeaxis)) level.timeaxis destroy();
			if(isDefined(level.iconaxis)) level.iconaxis destroy();
			if(isDefined(level.inzoneaxis)) level.inzoneaxis destroy();
			if(isDefined(level.pspastatus)) level.pspastatus destroy();
			if(isDefined(level.pspbstatus)) level.pspbstatus destroy();
			if(isDefined(level.pspatimerbar)) level.pspatimerbar destroy();
			if(isDefined(level.pspatimer)) level.pspatimer destroy();
			if(isDefined(level.pspbtimerbar)) level.pspbtimerbar destroy();
			if(isDefined(level.pspbtimer)) level.pspbtimer destroy();
			break;
		case "vip":
			break;
	}

	// fade out modinfo, move to centre and fade in
	if(isDefined(level.ex_modinfo))
	{
		level.ex_modinfo fadeOverTime(1);
		level.ex_modinfo.alpha = 0;
		wait( [[level.ex_fpstime]](1) );
		level.ex_modinfo.x = 320;
		level.ex_modinfo.alignX = "center";
		level.ex_modinfo fadeOverTime(1);
		level.ex_modinfo.alpha = 0.8;
		wait( [[level.ex_fpstime]](1) );
	}
}

cleanplayerend()
{
	self thread maps\mp\gametypes\_hud_teamscore::removePlayerHUD();
	self thread maps\mp\gametypes\_hud_playerscore::removePlayerHUD();
	self thread cleanplayer();
}

cleanplayer()
{
	[[level.ex_bclear]]("self",5);

	if(isDefined(self.ruhud_status)) self.ruhud_status destroy();
	if(isDefined(self.ruhud_howto)) self.ruhud_howto destroy();

	if(level.ex_ranksystem)
	{
		if(isDefined(self.ex_rankhud0)) self.ex_rankhud0 destroy();
		if(isDefined(self.ex_rankhud1)) self.ex_rankhud1 destroy();
		if(isDefined(self.ex_rankhud2)) self.ex_rankhud2 destroy();
	}

	if(level.ex_statshud)
	{
		if(isDefined(self.statshud_left)) self.statshud_left destroy();
		if(isDefined(self.statshud_img))
		{
			for(i = 0; i < self.statshud_img.size; i++)
				if(isDefined(self.statshud_img[i])) self.statshud_img[i] destroy();
		}
		if(isDefined(self.statshud_val))
		{
			for(i = 0; i < self.statshud_val.size; i++)
				if(isDefined(self.statshud_val[i])) self.statshud_val[i] destroy();
		}
		if(isDefined(self.statshud_right)) self.statshud_right destroy();
	}

	if(isDefined(self.mine_hud_icon)) self.mine_hud_icon destroy();
	if(isDefined(self.mine_hud_ammo)) self.mine_hud_ammo destroy();
	if(isDefined(self.mine_hud_warn)) self.mine_hud_warn destroy();
	if(isDefined(self.mine_hud_defuse)) self.mine_hud_defuse destroy();
	if(isDefined(self.mine_hud_plant)) self.mine_hud_plant destroy();
	if(isDefined(self.mine_hud_progress_bg)) self.mine_hud_progress_bg destroy();
	if(isDefined(self.mine_hud_progress)) self.mine_hud_progress destroy();

	if(isDefined(self.turret_indicator)) self.turret_indicator destroy();
	if(isDefined(self.turret_msg)) self.turret_msg destroy();
	if(isDefined(self.overheat_bg)) self.overheat_bg destroy();
	if(isDefined(self.overheat_status)) self.overheat_status destroy();

	if(isDefined(self.ex_spwpro)) self.ex_spwpro destroy();
	if(isDefined(self.ex_spwpro_time1)) self.ex_spwpro_time1 destroy();
	if(isDefined(self.ex_spwpro_time2)) self.ex_spwpro_time2 destroy();
	if(isDefined(self.ex_spwpro_dist1)) self.ex_spwpro_dist1 destroy();
	if(isDefined(self.ex_spwpro_dist2)) self.ex_spwpro_dist2 destroy();

	if(isDefined(self.ex_sprinthud)) self.ex_sprinthud destroy();
	if(isDefined(self.ex_sprinthud_back)) self.ex_sprinthud_back destroy();
	if(isDefined(self.ex_sprinthud_hint)) self.ex_sprinthud_hint destroy();

	if(isDefined(self.ex_firstaidicon)) self.ex_firstaidicon destroy();
	if(isDefined(self.ex_firstaidval)) self.ex_firstaidval destroy();
	if(isDefined(self.ex_laserdot)) self.ex_laserdot destroy();
	if(isDefined(self.ex_wmd_icon)) self.ex_wmd_icon destroy();
	if(isDefined(self.ex_binocular_hint)) self.ex_binocular_hint destroy();
	if(isDefined(self.ex_scopedon)) self.ex_scopedon destroy();
	if(isDefined(self.ex_modeannouncer)) self.ex_modeannouncer destroy();
	if(isDefined(self.ex_clanannouncer)) self.ex_clanannouncer destroy();
	if(isDefined(self.ex_zoomhud)) self.ex_zoomhud destroy();
	if(isDefined(self.ex_parachute)) self.ex_parachute delete();
	if(isDefined(self.ex_anchor)) self.ex_anchor delete();
	if(isDefined(self.ex_lock)) self.ex_lock delete();

	if(isDefined(self.ex_heli_damage_health)) self.ex_heli_damage_health destroy();
	if(isDefined(self.ex_heli_damage_bg)) self.ex_heli_damage_bg destroy();

	if(isDefined(self.gunship_overlay)) self.gunship_overlay destroy();
	if(isDefined(self.gunship_grain)) self.gunship_grain destroy();
	if(isDefined(self.gunship_clock)) self.gunship_clock destroy();

	if(isDefined(self.sentry_progress_bg)) self.sentry_progress_bg destroy();
	if(isDefined(self.sentry_progress)) self.sentry_progress destroy();
	if(isDefined(self.sentry_action1)) self.sentry_action1 destroy();
	if(isDefined(self.sentry_action2)) self.sentry_action2 destroy();
	if(isDefined(self.sentry_action3)) self.sentry_action3 destroy();
	if(isDefined(self.sentry_action4)) self.sentry_action4 destroy();

	if(isDefined(self.ex_sentry_waypoints))
	{
		for(i = 0; i < self.ex_sentry_waypoints.size; i++)
			if(isDefined(self.ex_sentry_waypoints[i])) self.ex_sentry_waypoints[i] destroy();
	}

	if(isDefined(self.ex_bloodonscreen)) self.ex_bloodonscreen destroy();
	if(isDefined(self.ex_bloodonscreen1)) self.ex_bloodonscreen1 destroy();
	if(isDefined(self.ex_bloodonscreen2)) self.ex_bloodonscreen2 destroy();
	if(isDefined(self.ex_bloodonscreen3)) self.ex_bloodonscreen3 destroy();

	if(isDefined(self.ex_expmsg1)) self.ex_expmsg1 destroy();
	if(isDefined(self.ex_expmsg2)) self.ex_expmsg2 destroy();
	if(isDefined(self.ex_expmsg3)) self.ex_expmsg3 destroy();

	if(isDefined(self.ex_pbbgrd)) self.ex_pbbgrd destroy();
	if(isDefined(self.ex_pb)) self.ex_pb destroy();
	if(isDefined(self.ex_actimer)) self.ex_actimer destroy();
	if(isDefined(self.ex_tripwarning)) self.ex_tripwarning destroy();

	if(isDefined(self.ex_roundnumber)) self.ex_roundnumber destroy();
	if(isDefined(self.ex_rangehud)) self.ex_rangehud destroy();

	if(isDefined(self.crybaby_img)) self.crybaby_img destroy();
	if(isDefined(self.crybaby_txt)) self.crybaby_txt destroy();

	if(isDefined(self.obj_teamhud)) self.obj_teamhud destroy();
	if(isDefined(self.obj_enemyhud)) self.obj_enemyhud destroy();

	if(isDefined(self.drown_progrback)) self.drown_progrback destroy();
	if(isDefined(self.drown_progrbar)) self.drown_progrbar destroy();
	if(isDefined(self.drown_vision)) self.drown_vision destroy();

	if(level.ex_specials && isDefined(level.ex_perkcatalog))
	{
		for(i = 1; i <= level.ex_perkcatalog.size; i++)
		{
			hudelem = "spc_icon" + i;
			if(isDefined(self.pers[hudelem])) self.pers[hudelem] destroy();
		}
	}

	if(isDefined(self.ex_spc_proticon)) self.ex_spc_proticon destroy();
	if(isDefined(self.ex_hud_announce))
	{
		for(i = 0; i < self.ex_hud_announce.size; i++)
			if(isDefined(self.ex_hud_announce[i].hudelem)) self.ex_hud_announce[i].hudelem destroy();
	}

	if(level.ex_bulletholes && isDefined(self.ex_bulletholes))
	{
		for(i = 0; i < self.ex_bulletholes.size; i++)
		{
			if(isDefined(self.ex_bulletholes[i])) self.ex_bulletholes[i] destroy();
		}
	}

	if(isDefined(self.ex_healthbar)) self.ex_healthbar destroy();
	if(isDefined(self.ex_healthback)) self.ex_healthback destroy();
	if(isDefined(self.ex_healthcross)) self.ex_healthcross destroy();

	if(isDefined(self.ex_srvlogoback)) self.ex_srvlogoback destroy();
	if(isDefined(self.ex_srvlogofront)) self.ex_srvlogofront destroy();

	self thread extreme\_ex_camper::removeCamper();

	if(isDefined(self.ex_headmarker))
	{
		self.ex_headmarker stoploopsound();
		self.ex_sprintreco = false;
		self.ex_headmarker unlink();
		self.ex_headmarker delete();
	}

	if(isDefined(self.ex_spinemarker))
	{
		self.ex_spinemarker unlink();
		self.ex_spinemarker delete();
	}

	if(isDefined(self.ex_eyemarker))
	{
		self.ex_eyemarker unlink();
		self.ex_eyemarker delete();
	}

	if(isDefined(self.ex_thumbmarker))
	{
		self.ex_thumbmarker unlink();
		self.ex_thumbmarker delete();
	}

	if(isDefined(self.ex_lankmarker))
	{
		self.ex_lankmarker unlink();
		self.ex_lankmarker delete();
	}

	if(isDefined(self.ex_rankmarker))
	{
		self.ex_rankmarker unlink();
		self.ex_rankmarker delete();
	}

	if(isDefined(self.ex_lwristmarker))
	{
		self.ex_lwristmarker unlink();
		self.ex_lwristmarker delete();
	}

	if(isDefined(self.ex_rwristmarker))
	{
		self.ex_rwristmarker unlink();
		self.ex_rwristmarker delete();
	}

	if(!level.ex_bsod && isDefined(self.blackscreen)) self.blackscreen destroy();

	// clean all player based, game type specific hud elems
	if(isDefined(self.respawntext)) self.respawntext destroy();
	if(isDefined(self.respawntimer)) self.respawntimer destroy();

	if(!level.ex_gameover) return;

	if(isDefined(self.ex_arcade)) self.ex_arcade destroy();
	if(isDefined(self.ex_arcade_shader)) self.ex_arcade_shader destroy();

	if(level.ex_bsod) self thread extreme\_ex_main::killBlackScreen();
	if(isDefined(self.hud_damagefeedback)) self.hud_damagefeedback destroy();

	switch(level.ex_currentgt)
	{
		case "chq":
			if(isDefined(self.radioicon))
			{
				for(i = 0; i < self.radioicon.size; i++)
					if(isDefined(self.radioicon[i])) self.radioicon[i] destroy();
			}
			if(isDefined(self.progressbar_capture)) self.progressbar_capture destroy();
			if(isDefined(self.progressbar_capture2)) self.progressbar_capture2 destroy();
			if(isDefined(self.progressbar_capture3)) self.progressbar_capture3 destroy();
			if(isDefined(self.staydead)) self.staydead destroy();
			break;
		case "cnq":
			if(isDefined(self.cnq_teamhud)) self.cnq_teamhud destroy();
			if(isDefined(self.cnq_enemyhud)) self.cnq_enemyhud destroy();
			break;
		case "ctf":
			if(isDefined(self.hud_flag)) self.hud_flag destroy();
			if(isDefined(self.hud_flagflash)) self.hud_flagflash destroy();
			break;
		case "ctfb":
			if(isDefined(self.hud_flagown)) self.hud_flagown destroy();
			if(isDefined(self.hud_flagownflash)) self.hud_flagownflash destroy();
			if(isDefined(self.hud_flag)) self.hud_flag destroy();
			if(isDefined(self.hud_flagflash)) self.hud_flagflash destroy();
			break;
		case "dm":
			break;
		case "dom":
			break;
		case "esd":
			if(isDefined(self.bombtimer))
			{
			  for(i = 0; i < self.bombtimer.size; i++)
					if(isDefined(self.bombtimer[i])) self.bombtimer[i] destroy();
			}
			if(isDefined(self.progressbackground)) self.progressbackground destroy();
			if(isDefined(self.progressbar)) self.progressbar destroy();
			break;
		case "ft":
			if(isDefined(self.hud_frozen)) self.hud_frozen destroy();
			if(isDefined(self.hud_frozen_bar)) self.hud_frozen_bar destroy();
			if(isDefined(self.hud_frozen_clock)) self.hud_frozen_clock destroy();
			if(isDefined(self.hud_unfreeze)) self.hud_unfreeze destroy();
			if(isDefined(self.hud_unfreeze_bar)) self.hud_unfreeze_bar destroy();
			if(isDefined(self.hud_unfreeze_hint)) self.hud_unfreeze_hint destroy();
			if(isDefined(self.hud_steal)) self.hud_steal destroy();
			if(isDefined(self.staydead)) self.staydead destroy();
			break;
		case "hm":
			if(isDefined(self.hud_announce))
			{
			  for(i = 0; i < self.hud_announce.size; i++)
					if(isDefined(self.hud_announce[i])) self.hud_announce[i] destroy();
			}
			if(isDefined(self.statusHUDicon)) self.statusHUDicon destroy();
			if(isDefined(self.hud1text)) self.hud1text destroy();
			if(isDefined(self.hud1icon)) self.hud1icon destroy();
			if(isDefined(self.hud2text)) self.hud2text destroy();
			if(isDefined(self.hud2icon)) self.hud2icon destroy();
			if(isDefined(self.hud3text)) self.hud3text destroy();
			if(isDefined(self.hud3icon)) self.hud3icon destroy();
			break;
		case "hq":
			if(isDefined(self.radioicon))
			{
				for(i = 0; i < self.radioicon.size; i++)
					if(isDefined(self.radioicon[i])) self.radioicon[i] destroy();
			}
			if(isDefined(self.progressbar_capture)) self.progressbar_capture destroy();
			if(isDefined(self.progressbar_capture2)) self.progressbar_capture2 destroy();
			if(isDefined(self.progressbar_capture3)) self.progressbar_capture3 destroy();
			if(isDefined(self.staydead)) self.staydead destroy();
			break;
		case "htf":
			if(isDefined(self.flagAttached)) self.flagAttached destroy();
			break;
		case "ihtf":
			if(isDefined(self.flagAttached)) self.flagAttached destroy();
			break;
		case "lib":
			break;
		case "lms":
			if(isDefined(self.komback)) self.komback destroy();
			if(isDefined(self.komfront)) self.komfront destroy();
			if(isDefined(self.komtext)) self.komtext destroy();
			if(isDefined(self.duelback)) self.duelback destroy();
			if(isDefined(self.dueltitle)) self.dueltitle destroy();
			if(isDefined(self.dueldist)) self.dueldist destroy();
			if(isDefined(self.dueldist2)) self.dueldist2 destroy();
			if(isDefined(self.duelhealth)) self.duelhealth destroy();
			if(isDefined(self.duelhealth2)) self.duelhealth2 destroy();
			if(isDefined(self.duelweapon)) self.duelweapon destroy();
			if(isDefined(self.duelweapon2)) self.duelweapon2 destroy();
			if(isDefined(self.duelammo)) self.duelammo destroy();
			if(isDefined(self.duelammo2)) self.duelammo2 destroy();
			if(isDefined(self.spectatorback)) self.spectatorback destroy();
			if(isDefined(self.spectator2back)) self.spectator2back destroy();
			if(isDefined(self.spectatortitle)) self.spectatortitle destroy();
			if(isDefined(self.spectatordist)) self.spectatordist destroy();
			if(isDefined(self.spectatordist2)) self.spectatordist2 destroy();
			if(isDefined(self.spectator2dist)) self.spectator2dist destroy();
			if(isDefined(self.spectator2dist2)) self.spectator2dist2 destroy();
			if(isDefined(self.spectatorhealth)) self.spectatorhealth destroy();
			if(isDefined(self.spectatorhealth2)) self.spectatorhealth2 destroy();
			if(isDefined(self.spectator2health)) self.spectator2health destroy();
			if(isDefined(self.spectator2health2)) self.spectator2health2 destroy();
			if(isDefined(self.spectatorweapon)) self.spectatorweapon destroy();
			if(isDefined(self.spectatorweapon2)) self.spectatorweapon2 destroy();
			if(isDefined(self.spectator2weapon)) self.spectator2weapon destroy();
			if(isDefined(self.spectator2weapon2)) self.spectator2weapon2 destroy();
			if(isDefined(self.spectatorammo)) self.spectatorammo destroy();
			if(isDefined(self.spectatorammo2)) self.spectatorammo2 destroy();
			if(isDefined(self.spectator2ammo)) self.spectator2ammo destroy();
			if(isDefined(self.spectator2ammo2)) self.spectator2ammo2 destroy();
			if(isDefined(self.spectator2title)) self.spectator2title destroy();
			if(isDefined(self.objpointa)) self.objpointa destroy();
			if(isDefined(self.objpointb)) self.objpointb destroy();
			break;
		case "lts":
			break;
		case "ons":
			break;
		case "rbcnq":
			if(isDefined(self.obj_icon1)) self.obj_icon1 destroy();
			if(isDefined(self.obj_icon2)) self.obj_icon2 destroy();
			if(isDefined(self.obj_count_axis)) self.obj_count_axis destroy();
			if(isDefined(self.obj_count_allies)) self.obj_count_allies destroy();
			if(isDefined(self.progressbackground)) self.progressbackground destroy();
			if(isDefined(self.progressbar)) self.progressbar destroy();
			break;
		case "rbctf":
			if(isDefined(self.hud_flag)) self.hud_flag destroy();
			if(isDefined(self.hud_flagflash)) self.hud_flagflash destroy();
			if(isDefined(self.obj_icon1)) self.obj_icon1 destroy();
			if(isDefined(self.obj_icon2)) self.obj_icon2 destroy();
			if(isDefined(self.obj_count_axis)) self.obj_count_axis destroy();
			if(isDefined(self.obj_count_allies)) self.obj_count_allies destroy();
			break;
		case "sd":
			if(isDefined(self.bombtimer)) self.bombtimer destroy();
			if(isDefined(self.progressbackground)) self.progressbackground destroy();
			if(isDefined(self.progressbar)) self.progressbar destroy();
			break;
		case "tdm":
			break;
		case "tkoth":
			if(isDefined(self.zoneline)) self.zoneline destroy();
			if(isDefined(self.zonelinea)) self.zonelinea destroy();
			if(isDefined(self.zonelineb)) self.zonelineb destroy();
			if(isDefined(self.zonelinec)) self.zonelinec destroy();
			if(isDefined(self.zonetrace)) self.zonetrace destroy();
			if(isDefined(self.respawnatext)) self.respawnatext destroy();
			if(isDefined(self.respawnbtext)) self.respawnbtext destroy();
			break;
		case "vip":
			if(isDefined(self.vip_hudvipspotted)) self.vip_hudvipspotted destroy();
			break;
	}
}
