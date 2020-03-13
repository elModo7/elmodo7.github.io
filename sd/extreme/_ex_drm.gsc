#include extreme\_ex_utils;

drm_init()
{
	if(isDefined(game["drm_initdone"]))
	{
		// DRM already initialized, but called again: this must be a round based game
		// so make sure varcache will use the correct map sizing cvar
		game["ex_modstate"] = undefined;
		drm_mapsizing();
		return;
	}

	game["drm"] = [];
	
	for(i = 1; i <= 100; i ++)
	{
		dvar = "scr_drm_cfg_" + i;
		fname = getcvar(dvar);
		if(fname != "")
		{
			fdesc = openfile(fname, "read");
			if(fdesc != -1)
				drm_parsefile(fname, fdesc);
		}
	}

	game["drm_initdone"] = true;
	
	drm_log("DRM: " + game["drm"].size + " vars have been set");
	drm_mapsizing();
}

drm_mapsizing()
{
	// Get the number of players for "small", "medium" and "large" extensions
	level.ex_drmplayers = 0;
	// If server just started, set number to startup preference
	if(getCvar("drm_players") == "")
	{
		level.ex_drmplayers = drm_getcvarint("ex_mapsizing_startup");
		logprint("DRM: Server just started. Simulating " + level.ex_drmplayers + " players on request\n");
		setCvar("drm_players", level.ex_drmplayers);
	}
	else
	{
		// Get the real number of players from the saved dvar
		level.ex_drmplayers = getCvarInt("drm_players");
		logprint("DRM: Server already running. Map sizing is based on " + level.ex_drmplayers + " players\n");
	}
}

// Just a logprint + newline
drm_log(str)
{
	logprint(str + "\n");
}

// Parse a config file
drm_parsefile(fname, fdesc)
{
	drm_log("DRM: Reading config file " + fname);
	
	for( ; ; )
	{
		elems = freadln(fdesc);
		
		if(elems == -1)
			break;
			
		if(elems == 0)
			continue;
	
		line = fgetarg(fdesc, 0);
		//drm_log("Line read : >" + line + "<");
		
		if((getsubstr(line, 0, 2) == "//") || (getsubstr(line, 0, 1) == "#"))
		{
			//drm_log("		comment -> ignored\n");
			continue;
		}
		
		cleanline = "";
		last = " ";
		
		for(i = 0; i < line.size; i ++)
		{
			//drm_log("line[i] : >" + line[i] + "<");
			switch(line[i])
			{
				case "	" :  // tab
				case " " :   // space 0xa0
				case " " :   // space 0x20
					if(last != " ")
					{
						//drm_log("added space");
						cleanline += " ";
						last = " ";
					}
					break;

				case "/" :
					if(last == "/")
					{
						//drm_log("exiting");
						cleanline = getsubstr(cleanline, 0, cleanline.size - 1);
						i = line.size; // exiting from for loop
						break;
					}
					else
					{
						//drm_log("adding slash");
						cleanline += "/";
						last = "/";
					}
					break;

				case "#" :
					//drm_log("exiting");
					i = line.size; // exiting from for loop
					break;

				default :
					//drm_log("adding : >" + line[i] + "<");
					cleanline += line[i];
					last = line[i];
					break;
			}
		}

		if((cleanline.size >= 2) && (getsubstr(cleanline, cleanline.size - 2) == " /"))
		{
			// Ends with " /"
			notsocleanline = cleanline;
			cleanline = getsubstr(notsocleanline, 0, notsocleanline.size - 2);
		}
		
		if((cleanline.size >= 1) && (cleanline[cleanline.size - 1] == " "))
		{
			// Ends with " "
			notsocleanline = cleanline;
			cleanline = getsubstr(notsocleanline, 0, notsocleanline.size - 1);
		}
				
		if(cleanline == "")
		{
			//drm_log("		nothing left -> ignored\n");
			continue;
		}
	
		//drm_log("cleanline : >" + cleanline + "<");

		array = strtok(cleanline, " ");
		setcmd = array[0];
		
		if((setcmd != "set") && (setcmd != "seta") && (setcmd != "sets"))
		{
			//drm_log("		does not begin with set, seta or sets -> ignored\n");
			continue;
		}
		
		if(array.size == 1)
		{
			//drm_log("		missing var name -> ignored\n");
			continue;
		}
		
		var = array[1];
		
		if(array.size == 2)
			// Value is null
			val = "";
		else
			// Value is not null
			val = getsubstr(cleanline, setcmd.size + var.size + 2);

		//drm_log("		OK ! var " + var + " will be set to \"" + val + "\"\n");

		game["drm"][var] = val;
	}

	closefile(fdesc);
}

// Replacement for cvardef
drm_cvardef(varname, vardefault, min, max, type)
{
	// Initialization must be done on 1st call
	if(!isDefined(game["drm_initdone"])) drm_init();

	//if(!isDefined(game["ex_modstate"]))
	//	logprint("DRM DEBUG: evaluating \"" + varname + "\" for " + level.ex_drmplayers + " players\n");
	//else
	//	logprint("DRM DEBUG: evaluating \"" + varname + "\" after precaching\n");

	basevar = varname;                     // remember the base variable
	gametype = getcvar("g_gametype");      // "ctf", "tdm", etc.
	mapname = getcvar("mapname");          // "mp_dawnville", "mp_rocket", etc.
	multigtmap = gametype + "_" + mapname;

	tempvar = basevar;									   // first use the base variable to check for sizing overrides

	if(!isDefined(game["ex_modstate"]))
	{
		// use the base variable and attach the proper extension
		if(level.ex_drmplayers < level.ex_mapsizing_medium) tempvar = tempvar + "_small";
			else if(level.ex_drmplayers < level.ex_mapsizing_large) tempvar = tempvar + "_medium";
				else tempvar = tempvar + "_large";

		if(drm_getcvar(tempvar) != "")       // if the sizing extension override is being used
			varname = tempvar;                 // use that instead of the standard variable
	}

	tempvar = basevar + "_" + gametype;    // use the base variable and attach the gametype
	if(drm_getcvar(tempvar) != "")         // if the gametype override is being used
		varname = tempvar;                   // use the gametype override instead of the standard variable

	if(!isDefined(game["ex_modstate"]))
	{
		// use the gametype variable and attach the proper extension
		if(level.ex_drmplayers < level.ex_mapsizing_medium) tempvar = tempvar + "_small";
			else if(level.ex_drmplayers < level.ex_mapsizing_large) tempvar = tempvar + "_medium";
				else tempvar = tempvar + "_large";

		if(drm_getcvar(tempvar) != "")       // if the sizing extension override is being used
			varname = tempvar;                 // use that instead of the standard variable
	}

	tempvar = basevar + "_" + mapname;     // use the base variable and attach the map
	if(drm_getcvar(tempvar) != "")         // if the map override is being used
		varname = tempvar;                   // use the map override instead of the standard variable

	if(!isDefined(game["ex_modstate"]))
	{
		// use the mapname variable and attach the proper extension
		if(level.ex_drmplayers < level.ex_mapsizing_medium) tempvar = tempvar + "_small";
			else if(level.ex_drmplayers < level.ex_mapsizing_large) tempvar = tempvar + "_medium";
				else tempvar = tempvar + "_large";

		if(drm_getcvar(tempvar) != "")       // if the sizing extension override is being used
			varname = tempvar;                 // use that instead of the standard variable
	}

	tempvar = basevar + "_" + multigtmap;  // use the base variable and attach the gametype and the map
	if(drm_getcvar(tempvar) != "")         // if the gametype_map override is being used
		varname = tempvar;                   // use the gametype_map override instead of the standard variable

	if(!isDefined(game["ex_modstate"]))
	{
		// use the multigtmap variable and attach the proper extension
		if(level.ex_drmplayers < level.ex_mapsizing_medium) tempvar = tempvar + "_small";
			else if(level.ex_drmplayers < level.ex_mapsizing_large) tempvar = tempvar + "_medium";
				else tempvar = tempvar + "_large";

		if(drm_getcvar(tempvar) != "")       // if the sizing extension override is being used
			varname = tempvar;                 // use that instead of the standard variable
	}

	// get the variable's definition
	switch(type)
	{
		case "int":
			if(drm_getcvar(varname) == "")     // if the cvar is blank
				definition = vardefault;         // set the default
			else
				definition = drm_getcvarint(varname);
			break;
		case "float":
			if(drm_getcvar(varname) == "")     // if the cvar is blank
				definition = vardefault;         // set the default
			else
				definition = drm_getcvarfloat(varname);
			break;
		case "string":
		default:
			if(drm_getcvar(varname) == "")     // if the cvar is blank
				definition = vardefault;         // set the default
			else
				definition = drm_getcvar(varname);
			break;
	}

	// if it's a number, with a minimum, that violates the parameter
	if((type == "int" || type == "float") && definition < min)
		definition = min;

	// if it's a number, with a maximum, that violates the parameter
	if((type == "int" || type == "float") && definition > max)
		definition = max;

	return definition;
}

// Replacement for getcvar
drm_getcvar(var)
{
	if(isDefined(game["drm"][var]))
		return(game["drm"][var]);
	
	return("");
}

// Replacement for getcvarint
drm_getcvarint(var)
{
	if(isDefined(game["drm"][var]))
		return(atoi(game["drm"][var]));
	
	return(0);
}

// Replacement for getcvarfloat
drm_getcvarfloat(var)
{
	if(isDefined(game["drm"][var]))
		return(atof(game["drm"][var]));
	
	return(0);
}
