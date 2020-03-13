init()
{
	// Conversion of stock server Cvars
	setCvar("g_allowvote", [[level.ex_drm]]("g_allowvote", 1, 0, 1, "int")); // level.allowvote in _serversettings.gsc
	setCvar("g_deadchat", [[level.ex_drm]]("g_deadchat", 1, 0, 1, "int")); // not script or menu related
	setCvar("g_debugdamage", [[level.ex_drm]]("g_debugdamage", 0, 0, 1, "int")); // cvar read by gametype scripts
	setCvar("g_oldvoting", [[level.ex_drm]]("g_oldvoting", 1, 0, 1, "int")); // not script or menu related
	setCvar("scr_friendlyfire", [[level.ex_drm]]("scr_friendlyfire", 0, 0, 3, "int")); // level.friendlyfire in _serversettings.gsc
	setCvar("scr_killcam", [[level.ex_drm]]("scr_killcam", 0, 0, 1, "int")); // level.killcam in _killcam.gsc
	setCvar("scr_spectateenemy", [[level.ex_drm]]("scr_spectateenemy", 0, 0, 1, "int")); // level.spectateenemy in _spectating.gsc
	setCvar("scr_spectatefree", [[level.ex_drm]]("scr_spectatefree", 1, 0, 1, "int")); // level.spectatefree in _spectating.gsc

	// Percentage of original damage to reflect (scr_friendlyfire 2)
	level.ex_friendlyfire_reflect = [[level.ex_drm]]("ex_friendlyfire_reflect", 50, 1, 100, "int") / 100;

	// Points for killing a player
	level.ex_points_kill = [[level.ex_drm]]("ex_points_kill", 1, 1, 999, "int");

	// Hide objectives when in killcam mode
	level.ex_killcam_hideobj = [[level.ex_drm]]("ex_killcam_hideobj", 0, 0, 1, "int");

	// Draws a team icon over teammates (_friendicons.gsc)
	level.drawfriend = [[level.ex_drm]]("scr_drawfriend", 1, 0, 1, "int");
	setCvar("scr_drawfriend", level.drawfriend);

	// Force respawning (gametype scripts)
	level.forcerespawn = [[level.ex_drm]]("scr_forcerespawn", 0, 0, 1,"int");
	setCvar("scr_forcerespawn", level.forcerespawn);

	// If death music is on, this overrides forcespawn
	if(level.forcerespawn && level.ex_deathmusic)
	{
		setCvar("scr_forcerespawn", "0");
		level.forcerespawn = false;
	}

	// Respawn delay
	level.respawndelay = [[level.ex_drm]]("scr_respawndelay", 0, 0, 60, "int");
	setCvar("scr_respawndelay", level.respawndelay);

	// Additional respawn delay
	if(level.respawndelay)
	{
		level.ex_respawndelay_subzero = [[level.ex_drm]]("ex_respawndelay_subzero", 0, 0, 60, "int");
		level.ex_respawndelay_class = [[level.ex_drm]]("ex_respawndelay_class", 0, 0, 2, "int");
		if(level.ex_respawndelay_class)
		{
			level.ex_respawndelay_sniper = [[level.ex_drm]]("ex_respawndelay_sniper", 0, 0, 60, "int");
			level.ex_respawndelay_rifle = [[level.ex_drm]]("ex_respawndelay_rifle", 0, 0, 60, "int");
			level.ex_respawndelay_mg = [[level.ex_drm]]("ex_respawndelay_mg", 0, 0, 60, "int");
			level.ex_respawndelay_smg = [[level.ex_drm]]("ex_respawndelay_smg", 0, 0, 60, "int");
			level.ex_respawndelay_shot = [[level.ex_drm]]("ex_respawndelay_shot", 0, 0, 60, "int");
			level.ex_respawndelay_rl = [[level.ex_drm]]("ex_respawndelay_rl", 0, 0, 60, "int");
		}
	}

	// Auto Team Balancing (_teams.gsc)
	level.teambalance = [[level.ex_drm]]("scr_teambalance", 1, 0, 1, "int");
	setCvar("scr_teambalance", level.teambalance);

	level.ex_teambalance_delay = [[level.ex_drm]]("ex_teambalance_delay", 60, 0, 300, "int");

	// Voiceover on flag events
	level.ex_flag_voiceover = [[level.ex_drm]]("ex_flag_voiceover", 15, 0, 15, "int");

	// Drop flag at will
	level.ex_flag_drop = [[level.ex_drm]]("ex_flag_drop", 0, 0, 1, "int");

	// Retreat monitor
	level.ex_flag_retreat = [[level.ex_drm]]("ex_flag_retreat", 0, 0, 31, "int");
	if(level.ex_currentgt != "ctf" && level.ex_currentgt != "ctfb" && level.ex_currentgt != "rbctf") level.ex_flag_retreat = 0;

	// Time limit per map
	level.timelimit = [[level.ex_drm]]("scr_" + level.ex_currentgt + "_timelimit", 30, 0, 1440, "float");
	setCvar("scr_" + level.ex_currentgt + "_timelimit", level.timelimit);

	// Score limit per map
	level.scorelimit = [[level.ex_drm]]("scr_" + level.ex_currentgt + "_scorelimit", 1, 0, 99999, "int");
	setCvar("scr_" + level.ex_currentgt + "_scorelimit", level.scorelimit);

	// DOM, ESD, LTS, ONS, RBCNQ, RBCTF, SD
	if(level.ex_roundbased)
	{
		// Round limit
		level.roundlimit = [[level.ex_drm]]("scr_" + level.ex_currentgt + "_roundlimit", 5, 0, 99, "int");
		setCvar("scr_" + level.ex_currentgt + "_roundlimit", level.roundlimit);

		// Round length
		level.roundlength = [[level.ex_drm]]("scr_" + level.ex_currentgt + "_roundlength", 5, 1, 1440, "float");
		setCvar("scr_" + level.ex_currentgt + "_roundlength", level.roundlength);

		// Timers
		if(level.ex_currentgt == "sd" || level.ex_currentgt == "esd")
		{
			level.bombtimer = [[level.ex_drm]]("scr_" + level.ex_currentgt + "_bombtimer", 60, 30, 120, "int");
			level.planttime = [[level.ex_drm]]("scr_" + level.ex_currentgt + "_planttime", 5, 1, 60, "int");
			level.defusetime = [[level.ex_drm]]("scr_" + level.ex_currentgt + "_defusetime", 10, 1, 60, "int");
		}
	}

	switch(level.ex_currentgt)
	{
		case "chq": chq_init(); break;
		case "cnq": cnq_init(); break;
		case "ctf": ctf_init(); break;
		case "ctfb": ctfb_init(); break;
		case "dm": dm_init(); break;
		case "dom": dom_init(); break;
		case "esd": esd_init(); break;
		case "ft": ft_init(); break;
		case "hm": hm_init(); break;
		case "hq": hq_init(); break;
		case "htf": htf_init(); break;
		case "ihtf": ihtf_init(); break;
		case "lib": lib_init(); break;
		case "lms": lms_init(); break;
		case "lts": lts_init(); break;
		case "ons": ons_init(); break;
		case "rbcnq": rbcnq_init(); break;
		case "rbctf": rbctf_init(); break;
		case "sd": sd_init(); break;
		case "tdm": tdm_init(); break;
		case "tkoth": tkoth_init(); break;
		case "vip": vip_init(); break;
	}
}

chq_init()
{
	// Height radius for radio (in feet)
	level.ex_chq_radio_zradius = [[level.ex_drm]]("ex_chq_radio_zradius", 6, 0, 12, "int") * 12;

	// Spawn time for radio
	level.ex_chq_radio_spawntime = [[level.ex_drm]]("ex_chq_radio_spawntime", 45, 0, 240, "int");

	// Holdtime for radio
	level.ex_chq_radio_holdtime = [[level.ex_drm]]("ex_chq_radio_holdtime", 120, 60, 1440, "int");

	// Team neutralize radio points
	level.ex_chqpoints_teamneut = [[level.ex_drm]]("ex_chqpoints_teamneut", 10, 0, 999, "int");

	// Player neutralize radio points
	level.ex_chqpoints_playerneut = [[level.ex_drm]]("ex_chqpoints_playerneut", 2, 0, 999, "int");

	// Team radio capture points
	level.ex_chqpoints_teamcap = [[level.ex_drm]]("ex_chqpoints_teamcap", 0, 0, 999, "int");

	// Player radio capture points
	level.ex_chqpoints_playercap = [[level.ex_drm]]("ex_chqpoints_playercap", 2, 0, 999, "int");

	// Defending team points per second
	level.ex_chqpoints_defpps = [[level.ex_drm]]("ex_chqpoints_defpps", 1, 0, 999, "int");

	// Player has to be within radius to radio to get points
	level.ex_chqpoints_radius = [[level.ex_drm]]("ex_chqpoints_radius", 0, 0, 9999, "int");

	// Custom radios
	level.custom_radios = [[level.ex_drm]]("ex_chq_custom_radios", 0, 0, 1, "int");
}

cnq_init()
{
	// Debug messages
	level.cnq_debug = [[level.ex_drm]]("scr_cnq_debug", 0, 0, 1, "int");

	// Objectives HUD
	level.showobj_hud = [[level.ex_drm]]("scr_cnq_showobj_hud", 1, 0, 1, "int");

	// Points to award player for achieving objective
	level.player_obj_points = [[level.ex_drm]]("scr_cnq_player_objective_points", 5, 0, 40, "int");

	// Points to award team for achieving objective
	level.team_obj_points = [[level.ex_drm]]("scr_cnq_team_objective_points", 5, 0, 30, "int");

	// Points to award player for achieving bonus objective
	level.player_bonus_points = [[level.ex_drm]]("scr_cnq_player_bonus_points", 10, 0, 50, "int");

	// Points to award team for achieving bonus objective
	level.team_bonus_points = [[level.ex_drm]]("scr_cnq_team_bonus_points", 10, 0, 40, "int");

	// Initial switch, optional mapper setting
	level.cnq_initialobj = [[level.ex_drm]]("scr_cnq_initialobjective", 1, 1, 3, "int");

	// Campaign mode per map
	level.cnq_campaign_mode = [[level.ex_drm]]("scr_cnq_campaign", 0, 0, 1, "int");

	// Spawn method
	level.spawnmethod = [[level.ex_drm]]("scr_cnq_spawnmethod", "default", "", "", "string");
}

ctf_init()
{
	// Team capture points
	level.ex_ctfpoints_teamcf = [[level.ex_drm]]("ex_ctfpoints_teamcf", 1, 1, 999, "int");

	// Player capture points
	level.ex_ctfpoints_playercf = [[level.ex_drm]]("ex_ctfpoints_playercf", 10, 0, 999, "int");

	// Player return flag points
	level.ex_ctfpoints_playerrf = [[level.ex_drm]]("ex_ctfpoints_playerrf", 2, 0, 999, "int");

	// Player stealing eneny flag points
	level.ex_ctfpoints_playersf = [[level.ex_drm]]("ex_ctfpoints_playersf", 2, 0, 999, "int");

	// Player taking over eneny flag points
	level.ex_ctfpoints_playertf = [[level.ex_drm]]("ex_ctfpoints_playertf", 1, 0, 999, "int");

	// Player killing flag runner points
	level.ex_ctfpoints_playerkf = [[level.ex_drm]]("ex_ctfpoints_playerkf", 1, 0, 999, "int");

	// Delay before an abandoned flag is returned to its base
	level.flagautoreturndelay = [[level.ex_drm]]("scr_ctf_flagautoreturndelay", 120, 0, 99999, "int");
}

ctfb_init()
{
	// Random flag position
	level.random_flag_position = [[level.ex_drm]]("scr_ctfb_random_flag_position", 0, 0, 1, "int");

	// Show enemy own flag
	level.show_enemy_own_flag = [[level.ex_drm]]("scr_ctfb_show_enemy_own_flag", 1, 0, 1, "int");

	// Show enemy own flag after x seconds
	level.show_enemy_own_flag_after_sec = [[level.ex_drm]]("scr_ctfb_show_enemy_own_flag_after_sec", 60, 20, 900, "int");

	// Show enemy own flag for x seconds
	level.show_enemy_own_flag_time = [[level.ex_drm]]("scr_ctfb_show_enemy_own_flag_time", 60, 20, 900, "int");

	// Flag protection distance
	level.flagprotectiondistance = [[level.ex_drm]]("scr_ctfb_flagprotectiondistance", 800, 0, 99999, "int");

	// Delay before an abandoned flag is returned
	level.flagautoreturndelay = [[level.ex_drm]]("scr_ctfb_flagautoreturndelay", 120, 0, 99999, "int");

	// Team capture points
	level.ex_ctfbpoints_teamcf = [[level.ex_drm]]("ex_ctfbpoints_teamcf", 1, 1, 999, "int");

	// Player capture points
	level.ex_ctfbpoints_playercf = [[level.ex_drm]]("ex_ctfbpoints_playercf", 10, 0, 999, "int");

	// Player picking up own flag points
	level.ex_ctfbpoints_playerpf = [[level.ex_drm]]("ex_ctfbpoints_playerpf", 1, 0, 999, "int");

	// Player return own flag points
	level.ex_ctfbpoints_playerrf = [[level.ex_drm]]("ex_ctfbpoints_playerrf", 5, 0, 999, "int");

	// Player stealing eneny flag points
	level.ex_ctfbpoints_playersf = [[level.ex_drm]]("ex_ctfbpoints_playersf", 2, 0, 999, "int");

	// Player taking over eneny flag points
	level.ex_ctfbpoints_playertf = [[level.ex_drm]]("ex_ctfbpoints_playertf", 1, 0, 999, "int");

	// Player killing flag runner points (own flag)
	level.ex_ctfbpoints_playerkfo = [[level.ex_drm]]("ex_ctfbpoints_playerkfo", 1, 0, 999, "int");

	// Player killing flag runner points (enemy flag)
	level.ex_ctfbpoints_playerkfe = [[level.ex_drm]]("ex_ctfbpoints_playerkfe", 1, 0, 999, "int");

	// Points for defending flag
	level.ex_ctfbpoints_defend = [[level.ex_drm]]("ex_ctfbpoints_defend", 1, 0, 999, "int");

	// Points for assisting flag carrier
	level.ex_ctfbpoints_assist = [[level.ex_drm]]("ex_ctfbpoints_assist", 1, 0, 999, "int");
}

dm_init()
{
	// No additional settings
}

dom_init()
{
	// Score limit override for DOM
	level.scorelimit = 0;

	// Points for capturing flag
	level.pointscaptureflag = [[level.ex_drm]]("scr_dom_pointscaptureflag", 5, 1, 50, "int");

	// Time before flag is considered captured
	level.flagcapturetime = [[level.ex_drm]]("scr_dom_flagcapturetime", 20, 1, 45, "int");

	// Distance to trigger flag capture process
	level.spawndistance = [[level.ex_drm]]("scr_dom_spawndistance", 250, 1, 99999, "int");

	// Number of flags
	level.flagsnumber = [[level.ex_drm]]("scr_dom_flagsnumber", 5, 0, 99, "int");

	// Dynamically move flags after timout has elapsed
	level.flagtimeout = [[level.ex_drm]]("scr_dom_flagtimeout", 120, 0, 9999, "int");

	// Cool down time
	level.cooldowntime = [[level.ex_drm]]("scr_dom_cooldowntime", 10, 1, 30, "int");

	// Show flag points
	level.showflagwaypoints = [[level.ex_drm]]("scr_dom_showflagwaypoints", 0, 0, 1, "int");

	// Set up flag points for dom
	level.use_static_flags = [[level.ex_drm]]("scr_dom_static_flags", 1, 0, 1, "int");
	if(level.use_static_flags) maps\mp\gametypes\_mapsetup_dom_ons::init();
}

esd_init()
{
	// Campaign mode per map
	level.esd_campaign_mode = [[level.ex_drm]]("scr_esd_campaign", 0, 0, 1, "int");

	// Campaign mode per round
	level.esd_swap_roundwinner = [[level.ex_drm]]("scr_esd_swap_roundwinner", 0, 0, 1, "int");

	// Spawn tickets
	level.spawnlimit = [[level.ex_drm]]("scr_esd_spawntickets", 4, 0, 999, "int");
	extreme\_ex_serverinfo::registerCvarServerInfo("ui_esd_spawntickets", level.spawnlimit);

	// ESD mode
	level.esd_mode = [[level.ex_drm]]("scr_esd_mode", 0, 0, 4, "int");
	extreme\_ex_serverinfo::registerCvarServerInfo("ui_esd_mode", level.esd_mode);

	// Points for planting
	level.plantscore = [[level.ex_drm]]("scr_esd_plantscore", 0, 0, 999, "int");

	// Points for defusing
	level.defusescore = [[level.ex_drm]]("scr_esd_defusescore", 0, 0, 999, "int");

	// Points for winning round
	level.roundwin_points = [[level.ex_drm]]("scr_esd_roundwin_points", 5, 0, 999, "int");
}

hm_init()
{
	// Show commander on compass
	level.showcommander = [[level.ex_drm]]("scr_hm_showcommander", 1, 0, 1, "int");

	// Seconds between commander updates on compass
	level.tposuptime = [[level.ex_drm]]("scr_hm_tposuptime", 5, 0, 10, "int");

	// Points for commander killing hitman
	level.ex_hmpoints_cmd_hitman = [[level.ex_drm]]("scr_hmpoints_cmd_hitman", 5, 0, 999, "int");

	// Points for guard killing hitman
	level.ex_hmpoints_guard_hitman = [[level.ex_drm]]("scr_hmpoints_guard_hitman", 3, 0, 999, "int");

	// Points for hitman killing commander
	level.ex_hmpoints_hitman_cmd = [[level.ex_drm]]("scr_hmpoints_hitman_cmd", 10, 0, 999, "int");

	// Points for hitman killing guard
	level.ex_hmpoints_hitman_guard = [[level.ex_drm]]("scr_hmpoints_hitman_guard", 1, 0, 999, "int");

	// Points for hitman killing another hitman
	level.ex_hmpoints_hitman_hitman = [[level.ex_drm]]("scr_hmpoints_hitman_hitman", 2, 0, 999, "int");

	// Additional respawn delay for hitman when killed by another hitman
	level.penalty_time = [[level.ex_drm]]("scr_hm_penaltytime", 5, 0, 10, "int");
}

hq_init()
{
	// Height radius for radio (in feet)
	level.ex_hq_radio_zradius = [[level.ex_drm]]("ex_hq_radio_zradius", 6, 0, 12, "int") * 12;

	// Spawn time for radio
	level.ex_hq_radio_spawntime = [[level.ex_drm]]("ex_hq_radio_spawntime", 45, 0, 240, "int");

	// Holdtime for radio
	level.ex_hq_radio_holdtime = [[level.ex_drm]]("ex_hq_radio_holdtime", 120, 60, 1440, "int");

	// Team neutralize radio points
	level.ex_hqpoints_teamneut = [[level.ex_drm]]("ex_hqpoints_teamneut", 10, 0, 999, "int");

	// Player neutralize radio points
	level.ex_hqpoints_playerneut = [[level.ex_drm]]("ex_hqpoints_playerneut", 2, 0, 999, "int");

	// Team radio capture points
	level.ex_hqpoints_teamcap = [[level.ex_drm]]("ex_hqpoints_teamcap", 0, 0, 999, "int");

	// Player radio capture points
	level.ex_hqpoints_playercap = [[level.ex_drm]]("ex_hqpoints_playercap", 2, 0, 999, "int");

	// Defending team points per second
	level.ex_hqpoints_defpps = [[level.ex_drm]]("ex_hqpoints_defpps", 1, 0, 999, "int");

	// Player has to be within radius to radio to get points
	level.ex_hqpoints_radius = [[level.ex_drm]]("ex_hqpoints_radius", 0, 0, 9999, "int");

	// Custom radios
	level.custom_radios = [[level.ex_drm]]("ex_hq_custom_radios", 0, 0, 1, "int");
}

htf_init()
{
	// Balance mode
	level.mode = [[level.ex_drm]]("scr_htf_mode", 0, 0, 3, "int");

	// Flag hold time
	level.flagholdtime = [[level.ex_drm]]("scr_htf_flagholdtime", 90, 1, 999, "int");

	// Flag recover time
	level.flagrecovertime = [[level.ex_drm]]("scr_htf_flagrecovertime", 0, 0, 999, "int");

	// Flag spawn delay
	level.flagspawndelay = [[level.ex_drm]]("scr_htf_flagspawndelay", 15, 0, 999, "int");

	// Remove spawnpoint which is used by the flag?
	level.removeflagspawns = [[level.ex_drm]]("scr_htf_removeflagspawns", 0, 0, 1, "int");

	// Keep teamscores
	level.htf_teamscore = [[level.ex_drm]]("scr_htf_teamscore", 0, 0, 1, "int");

	// Points for killing flag carrier
	level.PointsForKillingFlagCarrier = [[level.ex_drm]]("scr_htf_pointsforkillingflagcarrier", 1, 0, 100, "int");

	// Points for stealing flag
	level.PointsForStealingFlag = [[level.ex_drm]]("scr_htf_pointsforstealingflag", 1, 0, 100, "int");
}

ihtf_init()
{
	// Max hold time
	level.flagmaxholdtime = [[level.ex_drm]]("scr_ihtf_flagmaxholdtime", 120, 1, 99999, "int");

	// Time to score
	level.flagholdtime = [[level.ex_drm]]("scr_ihtf_flagholdtime", 10, 1, 99999, "int");

	// Flag recover time
	level.flagrecovertime = [[level.ex_drm]]("scr_ihtf_flagrecovertime", 0, 0, 999, "int");

	// Flag spawn delay
	level.flagspawndelay = [[level.ex_drm]]("scr_ihtf_flagspawndelay", 15, 0, 9999, "int");

	// Random spawnpoints for the flag
	level.randomflagspawns = [[level.ex_drm]]("scr_ihtf_randomflagspawns", 1, 0, 1, "int");

	// Time out for stealing flag
	level.flagtimeout = [[level.ex_drm]]("scr_ihtf_flagtimeout", 180, 1, 9999, "int");

	// Flag spawn points creation mode
	level.flagspawnpointsmode = [[level.ex_drm]]("scr_ihtf_flagspawnpointsmode", "dm ctff sdb hq", "", "", "string");

	// Player spawn points creation mode
	level.playerspawnpointsmode = [[level.ex_drm]]("scr_ihtf_playerspawnpointsmode", "dm tdm", "", "", "string");

	// Minimum distance a player can spawn from the flag
	level.spawndistance = [[level.ex_drm]]("scr_ithf_spawndistance", 1000, 1, 99999, "int");

	// Points for killing players
	level.PointsForKillingPlayers = [[level.ex_drm]]("scr_ihtf_pointsforkillingplayers", 0, -100, 100, "int");

	// Points for killing flag carrier
	level.PointsForKillingFlagCarrier = [[level.ex_drm]]("scr_ihtf_pointsforkillingflagcarrier", 1, 0, 100, "int");

	// Points for stealing flag
	level.PointsForStealingFlag = [[level.ex_drm]]("scr_ihtf_pointsforstealingflag", 1, 0, 100, "int");

	// Points for holding flag
	level.PointsForHoldingFlag = [[level.ex_drm]]("scr_ihtf_pointsforholdingflag", 2, 0, 100, "int");
}

lib_init()
{
	// Time limit override for LIB
	level.timelimit = 0;

	// Round length (has to be set here, because level.ex_roundbased is not set for LIB)
	level.roundlength = [[level.ex_drm]]("scr_lib_roundlength", 5, 1, 1440, "float");
}

lms_init()
{
	// Minimum number of players
	level.minplayers = [[level.ex_drm]]("scr_lms_minplayers", 4, 3, 64, "int");

	// Time allowed to join
	level.joinperiodtime = [[level.ex_drm]]("scr_lms_joinperiod", 15, 1, 120, "int");

	// Duel time
	level.duelperiodtime = [[level.ex_drm]]("scr_lms_duelperiod", 60, 1, 120, "int");
	extreme\_ex_serverinfo::registerCvarServerInfo("ui_lms_duelperiod", level.duelperiodtime);

	// Kill-o-meter
	level.killometer = [[level.ex_drm]]("scr_lms_killometer", 60, 1, 1200, "int");
	extreme\_ex_serverinfo::registerCvarServerInfo("ui_lms_killometer", level.killometer);

	// Kill winner
	level.killwinner = [[level.ex_drm]]("scr_lms_killwinner", 0, 0, 1, "int");
}

lts_init()
{
	// No additional settings
}

ons_init()
{
	// Score limit override for ONS
	level.scorelimit = 0;

	// Points for capturing flag
	level.pointscaptureflag = [[level.ex_drm]]("scr_ons_pointscaptureflag", 5, 1, 50, "int");

	// Time before flag is considered captured
	level.flagcapturetime = [[level.ex_drm]]("scr_ons_flagcapturetime", 20, 1, 45, "int");

	// Minimum distance between flags
	level.spawndistance = [[level.ex_drm]]("scr_ons_spawndistance", 250, 1, 99999, "int");

	// Number of flags
	level.flagsnumber = [[level.ex_drm]]("scr_ons_flagsnumber", 5, 0, 99, "int");

	// Dynamically move flags after timout has elapsed
	level.flagtimeout = [[level.ex_drm]]("scr_ons_flagtimeout", 120, 0, 9999, "int");

	// Cool down time
	level.cooldowntime = [[level.ex_drm]]("scr_ons_cooldowntime", 10, 1, 30, "int");

	// Show flag points
	level.showflagwaypoints = [[level.ex_drm]]("scr_ons_showflagwaypoints", 0, 0, 1, "int");

	// Set up flag points for ons
	level.use_static_flags = [[level.ex_drm]]("scr_ons_static_flags", 1, 0, 1, "int");
	if(level.use_static_flags) maps\mp\gametypes\_mapsetup_dom_ons::init();
}

rbcnq_init()
{
	// Campaign mode per map
	level.rbcnq_campaign_mode = [[level.ex_drm]]("scr_rbcnq_campaign", 0, 0, 1, "int");

	// Campaign mode per round
	level.rbcnq_swap_roundwinner = [[level.ex_drm]]("scr_rbcnq_swap_roundwinner", 0, 0, 1, "int");

	// Debug messages
	level.cnq_debug = [[level.ex_drm]]("scr_rbcnq_debug", 0, 0, 1, "int");

	// Objectives HUD
	level.showobj_hud = [[level.ex_drm]]("scr_rbcnq_showobj_hud", 1, 0, 1, "int");

	// Points to award player for achieving objective
	level.player_obj_points = [[level.ex_drm]]("scr_rbcnq_player_objective_points", 5, 0, 40, "int");

	// Points to award team for achieving objective
	level.team_obj_points = [[level.ex_drm]]("scr_rbcnq_team_objective_points", 5, 0, 30, "int");

	// Points to award player for achieving bonus objective
	level.player_bonus_points = [[level.ex_drm]]("scr_rbcnq_player_bonus_points", 10, 0, 50, "int");

	// Points to award team for achieving bonus objective
	level.team_bonus_points = [[level.ex_drm]]("scr_rbcnq_team_bonus_points", 10, 0, 40, "int");

	// Initial switch, optional mapper setting
	level.rbcnq_initialobj = [[level.ex_drm]]("scr_rbcnq_initialobjective", 1, 1, 3, "int");

	// Show Total Time
	level.show_total_time = [[level.ex_drm]]("scr_rbcnq_showtotaltime", 1, 0, 1, "int");

	// Time to Cap Objective
	level.captime = [[level.ex_drm]]("scr_rbcnq_captime", 5, 0, 10, "int");

	// Spawn Tickets
	level.spawnlimit = [[level.ex_drm]]("scr_rbcnq_spawntickets", 4, 0, 999, "int");
	extreme\_ex_serverinfo::registerCvarServerInfo("ui_rbcnq_spawntickets", level.spawnlimit);

	// Points to award for winning round
	level.roundwin_points = [[level.ex_drm]]("scr_rbcnq_roundwin_points", 5, 0, 10, "int");

	// Reset score every round
	level.reset_scores = [[level.ex_drm]]("scr_rbcnq_round_reset_scores", 0, 0, 1, "int");

	// Spawn method
	level.spawnmethod = [[level.ex_drm]]("scr_rbcnq_spawnmethod", "default", "", "", "string");
}

rbctf_init()
{
	// Spawn tickets
	level.spawnlimit = [[level.ex_drm]]("scr_rbctf_spawntickets", 6, 0, 999, "int");
	extreme\_ex_serverinfo::registerCvarServerInfo("ui_rbctf_spawntickets", level.spawnlimit);

	// Show total time
	level.show_total_time = [[level.ex_drm]]("scr_rbctf_showtotaltime", 1, 0, 1, "int");

	// Return time for flags dropped
	level.flagautoreturndelay = [[level.ex_drm]]("scr_rbctf_returndelay", 60, 0, 120, "int");

	// Objectives HUD
	level.showobj_hud = [[level.ex_drm]]("scr_rbctf_showobj_hud", 1, 0, 1, "int");

	// Team capture points
	level.ex_rbctfpoints_teamcf = [[level.ex_drm]]("ex_rbctfpoints_teamcf", 10, 1, 999, "int");

	// Team round winner points
	level.ex_rbctfpoints_roundwin = [[level.ex_drm]]("ex_rbctfpoints_roundwin", 5, 1, 999, "int");

	// Player capture points
	level.ex_rbctfpoints_playercf = [[level.ex_drm]]("ex_rbctfpoints_playercf", 10, 0, 999, "int");

	// Player return own flag points
	level.ex_rbctfpoints_playerrf = [[level.ex_drm]]("ex_rbctfpoints_playerrf", 5, 0, 999, "int");

	// Player stealing eneny flag points
	level.ex_rbctfpoints_playersf = [[level.ex_drm]]("ex_rbctfpoints_playersf", 2, 0, 999, "int");

	// Player taking over eneny flag points
	level.ex_rbctfpoints_playertf = [[level.ex_drm]]("ex_rbctfpoints_playertf", 1, 0, 999, "int");

	// Player killing flag runner points
	level.ex_rbctfpoints_playerkf = [[level.ex_drm]]("ex_rbctfpoints_playerkf", 1, 0, 999, "int");
}

sd_init()
{
	// Points for planting a bomb
	level.ex_sdpoints_plant = [[level.ex_drm]]("ex_sdpoints_plant", 0, 0, 999, "int");

	// Points for defusing a bomb
	level.ex_sdpoints_defuse = [[level.ex_drm]]("ex_sdpoints_defuse", 0, 0, 999, "int");
}

tdm_init()
{
	// No additional settings
}

tkoth_init()
{
	// Set up TKOTH flags
	maps\mp\gametypes\_mapsetup_tkoth::init();

	// Zone time limit
	level.zonetimelimit = [[level.ex_drm]]("scr_tkoth_zonetimelimit", 10, 1, 15, "int");
	extreme\_ex_serverinfo::registerCvarServerInfo("ui_tkoth_zonetimelimit", level.zonetimelimit);

	// Points for capturing the zone
	level.zonepoints_capture = [[level.ex_drm]]("ex_tkothpoints_capture", 1, 1, 10, "int");

	// Points for taking over the zone
	level.zonepoints_takeover = [[level.ex_drm]]("ex_tkothpoints_takeover", 2, 1, 10, "int");

	// Points for holding the zone max time
	level.zonepoints_holdmax = [[level.ex_drm]]("ex_tkothpoints_holdmax", 10, 1, 10, "int");

	// Debug mode
	level.debug = [[level.ex_drm]]("scr_tkoth_debug", 0, 0, 1, "int");
}

vip_init()
{
	// Delay for selecting a new VIP
	level.vipdelay = [[level.ex_drm]]("scr_vip_vipdelay", 5, 0, 600, "int");

	// VIP visibility on compass by team mates
	level.vipvisiblebyteammates = [[level.ex_drm]]("scr_vip_vipvisiblebyteammates", 1, 0, 1, "int");

	// VIP visibility on compass by enemies
	level.vipvisiblebyenemies = [[level.ex_drm]]("scr_vip_vipvisiblebyenemies", 1, 0, 1, "int");

	// Points for killing a VIP
	level.pointsforkillingvip = [[level.ex_drm]]("scr_vip_pointsforkillingvip", 5, -999, 999, "int");

	// Points for protecting VIP
	level.pointsforprotectingvip = [[level.ex_drm]]("scr_vip_pointsforprotectingvip", 3, -999, 999, "int");

	// Points for a VIP staying alive at each cycle
	level.vippoints = [[level.ex_drm]]("scr_vip_vippoints", 2, -999, 999, "int");

	// Cyclic delay after which a VIP scores points for staying alive
	level.vippointscycle = [[level.ex_drm]]("scr_vip_vippoints_cycle", 3, 0, 600, "int");

	// Distance max for VIP protection
	level.vipprotectiondistance = [[level.ex_drm]]("scr_vip_vipprotectiondistance", 800, 0, 99999, "int");

	// Time max for VIP protection
	level.vipprotectiontime = [[level.ex_drm]]("scr_vip_vipprotectiontime", 15, 0, 600, "int");

	// VIP pistol
	level.vippistol = [[level.ex_drm]]("scr_vip_vippistol", 1, 0, 1, "int");

	// VIP smoke grenades
	level.vipmaxsmokenades = 9;
	level.vipsmokenades = [[level.ex_drm]]("scr_vip_vipsmokenades", 3, 0, level.vipmaxsmokenades, "int");

	// VIP smoke radius
	level.vipsmokeradius = [[level.ex_drm]]("scr_vip_vipsmokeradius", 380, 0, 99999, "int");

	// VIP smoke duration
	level.vipsmokeduration = [[level.ex_drm]]("scr_vip_vipsmokeduration", 70, 0, 600, "int");

	// VIP frag grenades
	level.vipmaxfragnades = 9;
	level.vipfragnades = [[level.ex_drm]]("scr_vip_vipfragnades", 0, 0, level.vipmaxfragnades, "int");

	// VIP health
	level.viphealth = [[level.ex_drm]]("scr_vip_viphealth", 150, 0, 9999, "int");

	// Special binoculars
	level.vipbinoculars = [[level.ex_drm]]("scr_vip_binoculars", 1, 0, 1, "int");
}

ft_init()
{
	// Show total time
	level.show_total_time = [[level.ex_drm]]("scr_ft_showtotaltime", 1, 0, 1, "int");

	// Set cool-down time in between rounds
	level.ft_roundend_delay = [[level.ex_drm]]("scr_ft_roundend_delay", 20, 5, 60, "int");

	// Set max times a person can be frozen per round
	level.ft_maxfreeze = [[level.ex_drm]]("scr_ft_maxfreeze", 5, 1, 999, "int");

	// Unfreeze mode
	level.ft_unfreeze_mode = [[level.ex_drm]]("scr_ft_unfreeze_mode", 0, 0, 2, "int");

	// Time for player to spec (mode 1) or player unfreeze (mode 2)
	level.ft_unfreeze_mode_window = [[level.ex_drm]]("scr_ft_unfreeze_mode_window", 120, 10, 999, "int");

	// Allow or disallow close proximity unfreezing
	level.ft_unfreeze_prox = [[level.ex_drm]]("scr_ft_unfreeze_prox", 1, 0, 1, "int");

	// Set the time it takes to unfreeze someone in proximity mode
	level.ft_unfreeze_prox_time = [[level.ex_drm]]("scr_ft_unfreeze_prox_time", 3, 1, 10, "int");

	// Set the maximum distance to unfreeze someone in proximity mode (inches)
	level.ft_unfreeze_prox_dist = [[level.ex_drm]]("scr_ft_unfreeze_prox_dist", 100, 100, 999, "int");

	// Allow or disallow laservision unfreezing (binoculars)
	level.ft_unfreeze_laser = [[level.ex_drm]]("scr_ft_unfreeze_laser", 0, 0, 1, "int");

	// Set the time it takes to unfreeze someone in laser mode
	level.ft_unfreeze_laser_time = [[level.ex_drm]]("scr_ft_unfreeze_laser_time", 3, 1, 10, "int");

	// Set the maximum distance to unfreeze someone in laser mode (inches)
	level.ft_unfreeze_laser_dist = [[level.ex_drm]]("scr_ft_unfreeze_laser_dist", 2000, 100, 9999, "int");

	// Respawn player at another location after being unfrozen
	level.ft_unfreeze_respawn = [[level.ex_drm]]("scr_ft_unfreeze_respawn", 1, 0, 1, "int");

	// Set mode for raygun weapon (raygun will replace pistols)
	level.ft_raygun = [[level.ex_drm]]("scr_ft_raygun", 3, 0, 3, "int");

	// Allow or disallow players to change teams while frozen
	level.ft_teamchange = [[level.ex_drm]]("scr_ft_teamchange", 1, 0, 1, "int");

	// Allow or disallow players to change weapons while frozen
	level.ft_weaponchange = [[level.ex_drm]]("scr_ft_weaponchange", 0, 0, 1, "int");

	// Allow or disallow players to exchange weapon with frozen enemies
	level.ft_weaponsteal = [[level.ex_drm]]("scr_ft_weaponsteal", 1, 0, 1, "int");

	// Set number of frag nades allowed to steal (ft_weaponsteal must be enabled)
	level.ft_weaponsteal_frag = [[level.ex_drm]]("scr_ft_weaponsteal_frag", 1, 0, 9, "int");

	// Set number of smoke nades allowed to steal (ft_weaponsteal must be enabled)
	level.ft_weaponsteal_smoke = [[level.ex_drm]]("scr_ft_weaponsteal_smoke", 0, 0, 9, "int");

	// Allow or disallow to keep stolen weapons after round ends (ft_weaponsteal must be enabled)
	level.ft_weaponsteal_keep = [[level.ex_drm]]("scr_ft_weaponsteal_keep", 1, 0, 1, "int");
	if(!level.ft_weaponsteal) level.ft_weaponsteal_keep = 0;

	// Chance to have sound during unfreeze
	level.ft_soundchance = [[level.ex_drm]]("scr_ft_soundchance", 50, 0, 100, "int");

	// Number of dvars to keep track of disconnects to prevent cheating (0 disables)
	level.ft_history = [[level.ex_drm]]("scr_ft_history", 10, 0, 64, "int");

	// Enable or disable auto-balance for frozen players
	level.ft_balance_frozen = [[level.ex_drm]]("scr_ft_balance_frozen", 0, 0, 1, "int");

	// Points for freezing a player
	level.ft_points_freeze = [[level.ex_drm]]("scr_ft_points_freeze", 1, 1, 999, "int");

	// Points for unfreezing a teammate
	level.ft_points_unfreeze = [[level.ex_drm]]("scr_ft_points_unfreeze", 5, 1, 999, "int");
}

createClock(clocktype, timer)
{
	if(!isDefined(clocktype)) clocktype = 1; // 1 = level.clock, 2 = level.roundclock
	if(!isDefined(timer)) timer = 0; // time for countdown

	clockx = 8;
	clocky = 2;

	if(clocktype == 1)
	{
		if(isDefined(level.roundclock))
		{
			level.roundclock.x = 100;
			level.roundclock.y = 2;
		}

		if(!isDefined(level.clock))
		{
			level.clock = newHudElem();
			level.clock.archived = true;
			level.clock.sort = 0;
			level.clock.horzAlign = "fullscreen";
			level.clock.vertAlign = "fullscreen";
			level.clock.alignX = "left";
			level.clock.alignY = "top";
			level.clock.x = clockx;
			level.clock.y = clocky;
			level.clock.font = "default";
			level.clock.color = (0.705, 0.705, 0.392);
			level.clock.fontscale = 2;
		}
		if(timer) level.clock setTimer(timer);
	}

	if(clocktype == 2)
	{
		if(isDefined(level.clock))
		{
			clockx = 100;
			clocky = 2;
		}

		if(!isDefined(level.roundclock))
		{
			level.roundclock = newHudElem();
			level.roundclock.archived = true;
			level.roundclock.sort = 0;
			level.roundclock.horzAlign = "left";
			level.roundclock.vertAlign = "top";
			level.roundclock.alignX = "left";
			level.roundclock.alignY = "top";
			level.roundclock.x = clockx;
			level.roundclock.y = clocky;
			level.roundclock.font = "default";
			level.roundclock.color = (0.98, 0.827, 0.58);
			level.roundclock.fontscale = 2;
		}
		if(timer) level.roundclock setTimer(timer);
	}
}
