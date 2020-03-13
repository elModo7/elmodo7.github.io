
init()
{
	if(level.ex_designer) markPrecache();

	// do not allow custom spawnpoints in mbot mode. It will confuse the bots
	if(level.ex_mbot && level.ex_mbot_dev) return;

	// Set new spawnpoints for specific map
	if(level.ex_currentmap == "mp_camp")
	{
		// Set new spawnpoints for specific game type(s)
		if(level.ex_currentgt == "dm" || level.ex_currentgt == "tdm")
		{
			level.ex_spawnpoints = [];

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (561.257, 199.381, 32.125));
			level.ex_spawnpoints[i].angles = (8.31116, 138.153, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (-367.193, 339.405, 0.125));
			level.ex_spawnpoints[i].angles = (7.21802, 39.3365, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (710.978, 455.738, 0.125));
			level.ex_spawnpoints[i].angles = (5.47119, -158.637, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (633.327, 835.543, 0.125));
			level.ex_spawnpoints[i].angles = (6.56433, -128.666, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (265.897, 1217.69, 0.125));
			level.ex_spawnpoints[i].angles = (4.59778, -112.917, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (-566.213, 463.966, 0.125));
			level.ex_spawnpoints[i].angles = (6.3446, 9.14063, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (-195.383, -129.597, 0));
			level.ex_spawnpoints[i].angles = (5.03174, 55.2997, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();
		}
	}

	// Set new spawnpoints for specific map
	if(level.ex_currentmap == "mp_houses_beta1")
	{
		// Set new spawnpoints for specific game type(s)
		if(level.ex_currentgt == "dm" || level.ex_currentgt == "tdm")
		{
			level.ex_spawnpoints = [];

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (869.167, 798.134, 8.125));
			level.ex_spawnpoints[i].angles = (12.5189, 172.332, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (303.053, -306.811, 16.125));
			level.ex_spawnpoints[i].angles = (23.7744, 40.8362, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (180.131, 550.52, 8.125));
			level.ex_spawnpoints[i].angles = (15.4248, -6.25671, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (857.358, -1542.99, 8.125));
			level.ex_spawnpoints[i].angles = (11.618, 174.216, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (-187.004, -1941.52, 8.125));
			level.ex_spawnpoints[i].angles = (5.625, 82.738, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (-99.6374, -639.624, 180.125));
			level.ex_spawnpoints[i].angles = (18.1494, -144.767, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (950.514, -965.326, 8.125));
			level.ex_spawnpoints[i].angles = (13.2495, 173.82, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();
			
			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (-898.792, -1910.97, 8.125));
			level.ex_spawnpoints[i].angles = (13.7933, 45.7306, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();
			
			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (114.276, 951.783, 8.125));
			level.ex_spawnpoints[i].angles = (13.7933, -49.1528, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();
			
			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (-469.005, 456.738, 8.125));
			level.ex_spawnpoints[i].angles = (3.08167, -82.337, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();
			
			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (-794.848, -159.125, 24.125));
			level.ex_spawnpoints[i].angles = (15.4248, -97.8552, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();
			
			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (-944.015, 958.786, 8.125));
			level.ex_spawnpoints[i].angles = (5.98755, -5.3833, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();
		}
	}
	
	// Set new spawnpoints for specific map
	if(level.ex_currentmap == "mp_remagen2")
	{
		// Set new spawnpoints for specific game type(s)
		if(level.ex_currentgt == "dm")
		{
			level.ex_spawnpoints = [];

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (1335.76, -137.375, 304.125));
			level.ex_spawnpoints[i].angles = (26.6748, -106.979, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (2218.35, -1052.63, 146.125));
			level.ex_spawnpoints[i].angles = (15.2435, -46.3568, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (3663.57, -3082.46, 193.125));
			level.ex_spawnpoints[i].angles = (16.3312, 118.444, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (4137.33, -1648.28, 193.125));
			level.ex_spawnpoints[i].angles = (8.88794, -38.2709, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (4458.99, -3158.23, 222.125));
			level.ex_spawnpoints[i].angles = (8.16284, 108.924, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (2097.13, -1918.08, 291.125));
			level.ex_spawnpoints[i].angles = (16.1499, 42.0337, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (4425.75, -965.326, 8.125));
			level.ex_spawnpoints[i].angles = (13.2495, 173.82, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (-898.792, -3156, 389.125));
			level.ex_spawnpoints[i].angles = (17.2375, 90.4068, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (2945.32, -3388.08, 193.125));
			level.ex_spawnpoints[i].angles = (3.98804, 74.361, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (2659.44, -2507.29, 193.125));
			level.ex_spawnpoints[i].angles = (16.1499, -8.48694, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (1642.84, -2443.6, 208.125));
			level.ex_spawnpoints[i].angles = (13.244, -0.686646, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();

			i = level.ex_spawnpoints.size;
			level.ex_spawnpoints[i] = spawn("script_origin", (3757.54, -1192.91, 199.125));
			level.ex_spawnpoints[i].angles = (9.43726, -106.496, 0);
			level.ex_spawnpoints[i].custom_classname = "mp_custom_spawn";
			level.ex_spawnpoints[i] placeSpawnpoint();
		}
	}

	if(level.ex_designer) prepSpawnpoints();
}

markPrecache()
{
	level.ex_spawnmarkers_type = [];
	markPrecacheSet("marker_custom");

	if(level.ex_designer_showall)
	{
		level.ex_spawnmarkers_type["ctf"] = true;
		markPrecacheSet("marker_ctf_allies");
		markPrecacheSet("marker_ctf_axis");

		level.ex_spawnmarkers_type["ctff"] = true;
		markPrecacheSet("marker_ctf_flag");

		level.ex_spawnmarkers_type["dm"] = true;
		markPrecacheSet("marker_dm");

		level.ex_spawnmarkers_type["hqr"] = true;
		markPrecacheSet("marker_hq_radio");

		level.ex_spawnmarkers_type["lib"] = true;
		markPrecacheSet("marker_lib_allies_free");
		markPrecacheSet("marker_lib_allies_jail");
		markPrecacheSet("marker_lib_axis_free");
		markPrecacheSet("marker_lib_axis_jail");

		level.ex_spawnmarkers_type["sd"] = true;
		markPrecacheSet("marker_sd_attack");
		markPrecacheSet("marker_sd_defend");

		level.ex_spawnmarkers_type["sdb"] = true;
		markPrecacheSet("marker_sd_bomb");

		level.ex_spawnmarkers_type["tdm"] = true;
		markPrecacheSet("marker_tdm");

		level.ex_spawnmarkers_type["tkoth"] = true;
		markPrecacheSet("marker_tkoth_allies");
		markPrecacheSet("marker_tkoth_axis");

		return;
	}

	switch(level.ex_currentgt)
	{
		case "hq":
			level.ex_spawnmarkers_type["tdm"] = true;
			markPrecacheSet("marker_tdm");
			level.ex_spawnmarkers_type["hqr"] = true;
			markPrecacheSet("marker_hq_radio");
			break;
		case "chq":
		case "cnq":
		case "ft":
		case "htf":
		case "lts":
		case "rbcnq":
		case "tdm":
		case "vip":
			level.ex_spawnmarkers_type["tdm"] = true;
			markPrecacheSet("marker_tdm");
			break;
		case "ctf":
		case "rbctf":
			level.ex_spawnmarkers_type["ctf"] = true;
			markPrecacheSet("marker_ctf_allies");
			markPrecacheSet("marker_ctf_axis");
			level.ex_spawnmarkers_type["ctff"] = true;
			markPrecacheSet("marker_ctf_flag");
			break;
		case "ctfb":
			level.ex_spawnmarkers_type["ctf"] = true;
			markPrecacheSet("marker_ctf_allies");
			markPrecacheSet("marker_ctf_axis");
			level.ex_spawnmarkers_type["ctff"] = true;
			markPrecacheSet("marker_ctf_flag");
			if(level.random_flag_position)
			{
				level.ex_spawnmarkers_type["dm"] = true;
				markPrecacheSet("marker_dm");
			}
			break;
		case "dm":
		case "hm":
		case "lms":
			level.ex_spawnmarkers_type["dm"] = true;
			markPrecacheSet("marker_dm");
			break;
		case "dom":
		case "ons":
			if(isDefined(level.spawntype))
			{
				switch(level.spawntype)
				{
					case "tdm":
						level.ex_spawnmarkers_type["tdm"] = true;
						markPrecacheSet("marker_tdm");
						if(!level.use_static_flags)
						{
							level.ex_spawnmarkers_type["dm"] = true;
							markPrecacheSet("marker_dm");
						}
						break;
					case "sd":
						level.ex_spawnmarkers_type["sd"] = true;
						markPrecacheSet("marker_sd_attack");
						markPrecacheSet("marker_sd_defend");
						if(!level.use_static_flags)
						{
							level.ex_spawnmarkers_type["dm"] = true;
							markPrecacheSet("marker_dm");
						}
						break;
					case "ctf":
						level.ex_spawnmarkers_type["ctf"] = true;
						markPrecacheSet("marker_ctf_allies");
						markPrecacheSet("marker_ctf_axis");
						if(!level.use_static_flags)
						{
							level.ex_spawnmarkers_type["dm"] = true;
							markPrecacheSet("marker_dm");
						}
						break;
					default:
						level.ex_spawnmarkers_type["dm"] = true;
						markPrecacheSet("marker_dm");
						break;
				}
			}
			else
			{
				level.ex_spawnmarkers_type["dm"] = true;
				markPrecacheSet("marker_dm");
			}
			break;
		case "esd":
		case "sd":
			level.ex_spawnmarkers_type["sd"] = true;
			markPrecacheSet("marker_sd_attack");
			markPrecacheSet("marker_sd_defend");
			break;
		case "ihtf":
			spawntype_array = strtok(level.playerspawnpointsmode, " ");
			spawntype_active = [];
			for(i = 0; i < spawntype_array.size; i ++)
			{
				switch(spawntype_array[i])
				{
					case "dm" :
					case "tdm" :
					case "ctfp" :
					case "ctff" :
					case "sdp" :
					case "sdb" :
					case "hq" :
						spawntype_active[spawntype_array[i]] = true;
					break;
				}
			}

			if(isdefined(spawntype_active["dm"]))
			{
				level.ex_spawnmarkers_type["dm"] = true;
				markPrecacheSet("marker_dm");
			}

			if(isdefined(spawntype_active["tdm"]) || isdefined(spawntype_active["hq"]))
			{
				level.ex_spawnmarkers_type["tdm"] = true;
				markPrecacheSet("marker_tdm");
			}

			if(isdefined(spawntype_active["ctfp"]))
			{
				level.ex_spawnmarkers_type["ctf"] = true;
				markPrecacheSet("marker_ctf_allies");
				markPrecacheSet("marker_ctf_axis");
			}

			if(isdefined(spawntype_active["sdp"]))
			{
				level.ex_spawnmarkers_type["sd"] = true;
				markPrecacheSet("marker_sd_attack");
				markPrecacheSet("marker_sd_defend");
			}

			if(isdefined(spawntype_active["ctff"]))
			{
				level.ex_spawnmarkers_type["ctff"] = true;
				markPrecacheSet("marker_ctf_flag");
			}

			if(isdefined(spawntype_active["sdb"]))
			{
				level.ex_spawnmarkers_type["sdb"] = true;
				markPrecacheSet("marker_sd_bomb");
			}

			if(isdefined(spawntype_active["hq"]))
			{
				level.ex_spawnmarkers_type["hqr"] = true;
				markPrecacheSet("marker_hq_radio");
			}
			break;
		case "lib":
			level.ex_spawnmarkers_type["lib"] = true;
			markPrecacheSet("marker_lib_allies_free");
			markPrecacheSet("marker_lib_allies_jail");
			markPrecacheSet("marker_lib_axis_free");
			markPrecacheSet("marker_lib_axis_jail");
			break;
		case "tkoth":
			if(isDefined(level.spawn))
			{
				switch(level.spawn)
				{
					case "tkoth":
						level.ex_spawnmarkers_type["tkoth"] = true;
						markPrecacheSet("marker_tkoth_allies");
						markPrecacheSet("marker_tkoth_axis");
						break;
					case "sd":
						level.ex_spawnmarkers_type["sd"] = true;
						markPrecacheSet("marker_sd_attack");
						markPrecacheSet("marker_sd_defend");
						break;
					case "ctf":
						level.ex_spawnmarkers_type["ctf"] = true;
						markPrecacheSet("marker_ctf_allies");
						markPrecacheSet("marker_ctf_axis");
						break;
				}
			}
			break;
	}
}

markPrecacheSet(marker)
{
	[[level.ex_PrecacheModel]]("xmodel/" + marker + "0");
	[[level.ex_PrecacheModel]]("xmodel/" + marker + "1");
}

prepSpawnpoints()
{
	level.ex_spawnmarkers = [];
	if(level.ex_mbot && level.ex_mbot_dev) return;

	level.ex_spawnmarkers[0] = spawnstruct();
	level.ex_spawnmarkers[0].origin = (0,0,0);
	level.ex_spawnmarkers[0].org_origin = (0,0,0);
	level.ex_spawnmarkers[0].angles = (0,0,0);
	level.ex_spawnmarkers[0].org_angles = (0,0,0);
	level.ex_spawnmarkers[0].entity_stock = 0;
	level.ex_spawnmarkers[0].entity_name = "marker_select";

	entities = getentarray();
	for(i = 0; i < entities.size; i++)
	{
		if(isDefined(entities[i].custom_classname) && isDefined(entities[i].origin))
		{
			switch(entities[i].custom_classname)
			{
				case "mp_custom_spawn":
					prepSpawnpoint(entities[i], entities[i].custom_classname, "marker_custom", false);
					break;
			}
		}

		if(isDefined(entities[i].targetname) && isDefined(entities[i].origin))
		{
			switch(entities[i].targetname)
			{
				case "allied_flag":
					if(isDefined(level.ex_spawnmarkers_type["ctff"]))
						prepSpawnpoint(entities[i], entities[i].targetname, "marker_ctf_flag");
					break;
				case "axis_flag":
					if(isDefined(level.ex_spawnmarkers_type["ctff"]))
						prepSpawnpoint(entities[i], entities[i].targetname, "marker_ctf_flag");
					break;
				case "bombzone":
					if(isDefined(level.ex_spawnmarkers_type["sdb"]))
						prepSpawnpoint(entities[i], entities[i].targetname, "marker_sd_bomb");
					break;
				case "hqradio":
					if(isDefined(level.ex_spawnmarkers_type["hqr"]))
						prepSpawnpoint(entities[i], entities[i].targetname, "marker_hq_radio");
					break;
			}
		}

		if(isDefined(entities[i].classname) && isDefined(entities[i].origin))
		{
			switch(entities[i].classname)
			{
				case "mp_ctf_spawn_allied":
					if(isDefined(level.ex_spawnmarkers_type["ctf"]))
						prepSpawnpoint(entities[i], entities[i].classname, "marker_ctf_allies");
					break;
				case "mp_ctf_spawn_axis":
					if(isDefined(level.ex_spawnmarkers_type["ctf"]))
						prepSpawnpoint(entities[i], entities[i].classname, "marker_ctf_axis");
					break;
				case "mp_dm_spawn":
					if(isDefined(level.ex_spawnmarkers_type["dm"]))
						prepSpawnpoint(entities[i], entities[i].classname, "marker_dm");
					break;
				case "mp_lib_spawn_alliesnonjail":
					if(isDefined(level.ex_spawnmarkers_type["lib"]))
						prepSpawnpoint(entities[i], entities[i].classname, "marker_lib_allies_free");
					break;
				case "mp_lib_spawn_axisnonjail":
					if(isDefined(level.ex_spawnmarkers_type["lib"]))
						prepSpawnpoint(entities[i], entities[i].classname, "marker_lib_axis_free");
					break;
				case "mp_lib_spawn_alliesinjail":
					if(isDefined(level.ex_spawnmarkers_type["lib"]))
						prepSpawnpoint(entities[i], entities[i].classname, "marker_lib_allies_jail");
					break;
				case "mp_lib_spawn_axisinjail":
					if(isDefined(level.ex_spawnmarkers_type["lib"]))
						prepSpawnpoint(entities[i], entities[i].classname, "marker_lib_axis_jail");
					break;
				case "mp_sd_spawn_attacker":
					if(isDefined(level.ex_spawnmarkers_type["sd"]))
						prepSpawnpoint(entities[i], entities[i].classname, "marker_sd_attack");
					break;
				case "mp_sd_spawn_defender":
					if(isDefined(level.ex_spawnmarkers_type["sd"]))
						prepSpawnpoint(entities[i], entities[i].classname, "marker_sd_defend");
					break;
				case "mp_tdm_spawn":
					if(isDefined(level.ex_spawnmarkers_type["tdm"]))
						prepSpawnpoint(entities[i], entities[i].classname, "marker_tdm");
					break;
				case "mp_tkoth_spawn_allied":
					if(isDefined(level.ex_spawnmarkers_type["tkoth"]))
						prepSpawnpoint(entities[i], entities[i].classname, "marker_tkoth_allies");
					break;
				case "mp_tkoth_spawn_axis":
					if(isDefined(level.ex_spawnmarkers_type["tkoth"]))
						prepSpawnpoint(entities[i], entities[i].classname, "marker_tkoth_axis");
					break;
			}
		}
	}

	if(isDefined(level.radio))
	{
		for(i = 0; i < level.radio.size; i++)
		{
			if(isDefined(level.ex_spawnmarkers_type["hqr"]))
				prepSpawnpoint(level.radio[i], "hqradio", "marker_hq_radio");
		}
	}
}

prepSpawnpoint(entity, entity_name, entity_marker, entity_stock)
{
	if(!isDefined(entity_stock)) entity_stock = true;
	if(entity_stock) entity_suffix = "0";
		else entity_suffix = "1";

	spawn_index = level.ex_spawnmarkers.size;
	level.ex_spawnmarkers[spawn_index] = spawnstruct();
	level.ex_spawnmarkers[spawn_index].entity = entity;
	level.ex_spawnmarkers[spawn_index].org_origin = entity.origin;
	//level.ex_spawnmarkers[spawn_index].angles = entity.angles;
	//level.ex_spawnmarkers[spawn_index].org_angles = entity.angles;
	//level.ex_spawnmarkers[spawn_index].entity_stock = entity_stock;
	//level.ex_spawnmarkers[spawn_index].entity_name = entity_name;
	level.ex_spawnmarkers[spawn_index].entity_marker = "xmodel/" + entity_marker + entity_suffix;

	logprint("[" + entity_name + "] origin: " + level.ex_spawnmarkers[spawn_index].org_origin + "\n");
}

markSpawnpoints()
{
	for(i = 1; i < level.ex_spawnmarkers.size; i++)
	{
		spawn_index = i;
		if(isDefined(level.ex_spawnmarkers[spawn_index].entity))
		{
			level.ex_spawnmarkers[spawn_index].model = spawn("script_model", level.ex_spawnmarkers[spawn_index].entity.origin);
			level.ex_spawnmarkers[spawn_index].model setmodel(level.ex_spawnmarkers[spawn_index].entity_marker);
			level.ex_spawnmarkers[spawn_index].model thread markOrigin(spawn_index);
			//level.ex_spawnmarkers[spawn_index].model thread markRotate();
		}
	}
}

markOrigin(spawn_index)
{
	while(1)
	{
		print3d(self.origin + (0, 0, 15), level.ex_spawnmarkers[spawn_index].org_origin, (.3, .8, 1), 1, 0.3);
		wait( [[level.ex_fpstime]](0.05) );
	}
}

markRotate()
{
	while(1)
	{
		self rotateyaw(-360, 3);
		wait( [[level.ex_fpstime]](3) );
	}
}

deleteSpawnPoint(oldspawn)
{
	entities = getentarray();
	for(i = 0; i < entities.size; i++)
	{
		if(isDefined(entities[i].classname))
		{
			switch(entities[i].classname)
			{
				case "mp_tdm_spawn":
				case "mp_ctf_spawn_allied":
				case "mp_ctf_spawn_axis":
				case "mp_dm_spawn":
				case "mp_sd_spawn_attacker":
				case "mp_sd_spawn_defender":
				case "mp_lib_spawn_alliesnonjail":
				case "mp_lib_spawn_axisnonjail":
				case "mp_lib_spawn_alliesinjail":
				case "mp_lib_spawn_axisinjail":
				case "mp_tkoth_spawn_allied":
				case "mp_tkoth_spawn_axis":
					if(entities[i].origin == oldspawn) entities[i] delete();
			}
		}
	}
}

moveSpawnPoint(oldspawn, newspawn)
{
	entities = getentarray();
	for(i = 0; i < entities.size; i++)
	{
		if(isDefined(entities[i].classname))
		{
			switch(entities[i].classname)
			{
				case "mp_tdm_spawn":
				case "mp_ctf_spawn_allied":
				case "mp_ctf_spawn_axis":
				case "mp_dm_spawn":
				case "mp_sd_spawn_attacker":
				case "mp_sd_spawn_defender":
				case "mp_lib_spawn_alliesnonjail":
				case "mp_lib_spawn_axisnonjail":
				case "mp_lib_spawn_alliesinjail":
				case "mp_lib_spawn_axisinjail":
				case "mp_tkoth_spawn_allied":
				case "mp_tkoth_spawn_axis":
					if(entities[i].origin == oldspawn) entities[i].origin = newspawn;
			}
		}
	}
}
