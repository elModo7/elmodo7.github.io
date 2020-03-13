#include extreme\_ex_utils;

init()
{
	if(!level.ex_jukebox) return;

	// Either set it to true or false. DO NOT DISABLE!
	level.ex_jukebox_log = false;

	level.ex_jukebox_tracks = [];
	if(level.ex_jukebox_log) logprint("JUKEBOX DEBUG: processing default profile\n");
	level.ex_jukebox_tracks["default"] = spawnstruct();
	level.ex_jukebox_tracks["default"].maxtracks = level.ex_jukebox_maxtracks;
	level.ex_jukebox_tracks["default"].length = [];
	for(i = 1; i <= level.ex_jukebox_tracks["default"].maxtracks; i++)
	{
		level.ex_jukebox_tracks["default"].length[i] = jukeboxMusicLengthConfig(i, "default");
		if(level.ex_jukebox_log) logprint("JUKEBOX DEBUG: track " + i + " is " + level.ex_jukebox_tracks["default"].length[i] + " seconds long\n");
	}

	count = 1;
	for(;;)
	{
		jukebox_name = [[level.ex_drm]]("ex_jukebox_name_" + count, "", "", "", "string");
		if(jukebox_name != "")
		{
			if(level.ex_jukebox_log) logprint("JUKEBOX DEBUG: request profile conversion for " + jukebox_name + "\n");
			jukebox_profile = [[level.ex_drm]]("ex_jukebox_prof_" + count, "", "", "", "string");
			if(jukebox_profile != "" && !isDefined(level.ex_jukebox_tracks[jukebox_profile]))
			{
				if(level.ex_jukebox_log) logprint("JUKEBOX DEBUG: " + jukebox_name + " linked to profile " + jukebox_profile + "\n");
				level.ex_jukebox_tracks[jukebox_profile] = spawnstruct();
				level.ex_jukebox_tracks[jukebox_profile].maxtracks = [[level.ex_drm]]("ex_jukebox_tracks_" + jukebox_profile, 1, 1, 99, "int");;
				if(level.ex_jukebox_log) logprint("JUKEBOX DEBUG: profile " + jukebox_profile + " has " + level.ex_jukebox_tracks[jukebox_profile].maxtracks + " tracks\n");
				level.ex_jukebox_tracks[jukebox_profile].addtracks = [[level.ex_drm]]("ex_jukebox_addition_" + jukebox_profile, 0, 0, 1, "int");;
				level.ex_jukebox_tracks[jukebox_profile].length = [];
				profile_starttrack = 1;
				profile_endtrack = level.ex_jukebox_tracks[jukebox_profile].maxtracks;
				if(level.ex_jukebox_tracks[jukebox_profile].addtracks)
				{
					if(level.ex_jukebox_log) logprint("JUKEBOX DEBUG: profile " + jukebox_profile + " is set to add " + level.ex_jukebox_tracks[jukebox_profile].maxtracks + " tracks to the default tracks\n");
					profile_starttrack = level.ex_jukebox_tracks["default"].maxtracks + 1;
					profile_endtrack = level.ex_jukebox_tracks["default"].maxtracks + level.ex_jukebox_tracks[jukebox_profile].maxtracks;
					level.ex_jukebox_tracks[jukebox_profile].maxtracks = profile_endtrack;
					for(i = 1; i <= level.ex_jukebox_tracks["default"].maxtracks; i++)
					{
						level.ex_jukebox_tracks[jukebox_profile].length[i] = level.ex_jukebox_tracks["default"].length[i];
						if(level.ex_jukebox_log) logprint("JUKEBOX DEBUG: track " + i + " is " + level.ex_jukebox_tracks[jukebox_profile].length[i] + " seconds long (default profile)\n");
					}
				}
				for(i = profile_starttrack; i <= profile_endtrack; i++)
				{
					profile_trackpointer = i;
					if(level.ex_jukebox_tracks[jukebox_profile].addtracks) profile_trackpointer = i - level.ex_jukebox_tracks["default"].maxtracks;
					level.ex_jukebox_tracks[jukebox_profile].length[i] = jukeboxMusicLengthConfig(profile_trackpointer, jukebox_profile);
					if(level.ex_jukebox_log) logprint("JUKEBOX DEBUG: track " + i + " is " + level.ex_jukebox_tracks[jukebox_profile].length[i] + " seconds long\n");
				}
			}
		}
		else break;

		count++;
	}
}

main()
{
	self endon("disconnect");

	if(!level.ex_jukebox) return;

	if(jukeboxDefaults() == true)
	{
		if(level.ex_jukebox_memory)
		{
			memory = self extreme\_ex_memory::getMemory("jukebox", "status");
			if(!memory.error) self.pers["jukebox"].enabled = memory.value;
			memory = self extreme\_ex_memory::getMemory("jukebox", "loop");
			if(!memory.error) self.pers["jukebox"].loop = memory.value;
			memory = self extreme\_ex_memory::getMemory("jukebox", "shuffle");
			if(!memory.error) self.pers["jukebox"].shuffle = memory.value;
			memory = self extreme\_ex_memory::getMemory("jukebox", "track");
			if(!memory.error) self.pers["jukebox"].track = memory.value;
		}
		self thread jukeboxInsertCoin();
	}
	else if(self.pers["jukebox"].restart)
	{
		self.pers["jukebox"].restart = false;
		self thread jukeboxPressButton(2); // Play (if jukebox enabled)
	}
}

jukeboxDefaults()
{
	self endon("disconnect");

	result = false; // returning false means checking variables only
	if(!isDefined(self.pers["jukebox"]))
	{
		self.pers["jukebox"] = spawnstruct();
		result = true; // returning true means initializing jukebox for first use
	}

	if(!isDefined(self.pers["jukebox"].profile))
	{
		self.pers["jukebox"].profile = self jukeboxGetProfile();
		if(level.ex_jukebox_log) logprint("JUKEBOX DEBUG: " + self.name + " linked to profile " + self.pers["jukebox"].profile + "\n");
	}
	if(!isDefined(self.pers["jukebox"].enabled))
		self.pers["jukebox"].enabled = level.ex_jukebox_power;
	if(!isDefined(self.pers["jukebox"].loop))
		self.pers["jukebox"].loop = false;
	if(!isDefined(self.pers["jukebox"].shuffle))
		self.pers["jukebox"].shuffle = false;
	if(!isDefined(self.pers["jukebox"].playing))
		self.pers["jukebox"].playing = false;
	if(!isDefined(self.pers["jukebox"].restart))
		self.pers["jukebox"].restart = false;
	if(!isDefined(self.pers["jukebox"].buttons))
		self.pers["jukebox"].buttons = 0;
	if(!isDefined(self.pers["jukebox"].track))
		self.pers["jukebox"].track = 0;
	if(!isDefined(self.pers["jukebox"].time))
		self.pers["jukebox"].time = 0;
	if(!isDefined(self.pers["jukebox"].tracks))
	{
		self.pers["jukebox"].tracks = [];
		for(i = 1; i <= level.ex_jukebox_tracks[self.pers["jukebox"].profile].maxtracks; i++)
			self.pers["jukebox"].tracks[i] = i;
	}

	// ready-up map restart fix
	if(level.ex_readyup)
	{
		if(isDefined(game["readyup_done"]))
		{
			if(isDefined(game[self.name + "-jukebox"]))
			{
				game[self.name + "-jukebox"] = undefined;
				result = true;
			}
		}
		else game[self.name + "-jukebox"] = true;
	}

	return result;
}

jukeboxGetProfile()
{
	count = 1;
	for(;;)
	{
		jukebox_name = [[level.ex_drm]]("ex_jukebox_name_" + count, "", "", "", "string");
		if(jukebox_name == "") break;
		if(jukebox_name == self.name) break;
			else count++;
	}

	jukebox_profile = "default";
	if(jukebox_name != "")
		jukebox_profile = [[level.ex_drm]]("ex_jukebox_prof_" + count, "default", "", "", "string");

	return jukebox_profile;
}

jukeboxInsertCoin()
{
	self endon("disconnect");

	self setClientCvar("ui_jukebox_power", self.pers["jukebox"].enabled);
	self setClientCvar("ui_jukebox_loop", self.pers["jukebox"].loop);
	self setClientCvar("ui_jukebox_shuffle", self.pers["jukebox"].shuffle);

	if(self.pers["jukebox"].shuffle) jukeboxMusicShuffle();

	jukeboxPressButton(2); // Play (if jukebox enabled)

	while(!level.ex_gameover)
	{
		wait( [[level.ex_fpstime]](0.5) );

		if(!isPlayer(self) || !isDefined(self.pers["jukebox"])) break;

		if(level.ex_specmusic && self.sessionteam == "spectator")
		{
			// If spec music is on, it will mute the jukebox.
			// Set the flags so it will restart when joining a team
			self.pers["jukebox"].playing = false;
			self.pers["jukebox"].restart = true;
		}

		if(self.pers["jukebox"].buttons)
		{
			if( (self.pers["jukebox"].buttons &  1) ==  1) jukeboxActionPower();
			else if( (self.pers["jukebox"].buttons &  2) ==  2) jukeboxActionPlay();
			else if( (self.pers["jukebox"].buttons &  4) ==  4) jukeboxActionStop();
			else if( (self.pers["jukebox"].buttons &  8) ==  8) jukeboxActionNext();
			else if( (self.pers["jukebox"].buttons & 16) == 16) jukeboxActionPrevious();
			else if( (self.pers["jukebox"].buttons & 32) == 32) jukeboxActionLoop();
			else if( (self.pers["jukebox"].buttons & 64) == 64) jukeboxActionShuffle();
			self.pers["jukebox"].buttons = 0;
		}

		if(!self.pers["jukebox"].enabled) continue;
		
		if(jukeboxIsPlaying())
		{
			if(self.pers["jukebox"].time) self.pers["jukebox"].time--;
			passedtime = (getTime() - level.starttime) / 1000;
			secondsleft = int((level.timelimit*60) - (passedtime));

			if(secondsleft == 10) jukeboxMusicStop();
			else
			{
				if(self.pers["jukebox"].time == 0)
					thread jukeboxMusicStart("next");
			}
		}

		wait( [[level.ex_fpstime]](0.5) );
	}
	// Make sure it stops playing (in case of cmdmonitor "endmap")
	jukeboxMusicStop();
}

jukeboxMusicStart(mode)
{
	level endon("ex_gameover");
	self endon("disconnect");

	jukeboxMusicStop();

	if(self.pers["jukebox"].track <= 0 || self.pers["jukebox"].track > level.ex_jukebox_tracks[self.pers["jukebox"].profile].maxtracks)
		mode = "random";

	if(self.pers["jukebox"].loop) mode = "current";

	switch(mode)
	{
		case "previous":
			index = self.pers["jukebox"].track - 1;
			if(index == 0) index = level.ex_jukebox_tracks[self.pers["jukebox"].profile].maxtracks;
			break;
		case "current":
			index = self.pers["jukebox"].track;
			break;
		case "next":
			index = self.pers["jukebox"].track + 1;
			if(index > level.ex_jukebox_tracks[self.pers["jukebox"].profile].maxtracks) index = 1;
			break;
		case "random":
			index = randomInt(level.ex_jukebox_tracks[self.pers["jukebox"].profile].maxtracks) + 1;
			break;
		default:
			index = 1;
	}
	self.pers["jukebox"].track = index;
	self.pers["jukebox"].time = jukeboxMusicLengthProfile(self.pers["jukebox"].tracks[index]);
	if(level.ex_jukebox_log) logprint("JUKEBOX DEBUG: " + self.name + " playing track " + self.pers["jukebox"].tracks[index] + " (index " + index + ") for " + self.pers["jukebox"].time + " seconds\n");
	self playLocalSound("jukebox_" + self.pers["jukebox"].tracks[index]);
	self.pers["jukebox"].playing = true;
	jukeboxSaveMemory();
}

jukeboxMusicStop()
{
	level endon("ex_gameover");
	self endon("disconnect");

	if(jukeboxIsPlaying())
	{
		self playLocalSound("jukebox_stop");
		self.pers["jukebox"].playing = false;
		wait( [[level.ex_fpstime]](1) );
	}
}

jukeboxMusicLengthConfig(songno, profile)
{
	if(!isDefined(profile) || profile == "default") profile = "";

	seclength = 30;
	if(profile == "") rawlength = [[level.ex_drm]]("ex_jukebox_length_" + songno, "", "", "", "string");
		else rawlength = [[level.ex_drm]]("ex_jukebox_length_" + songno + "_" + profile, "", "", "", "string");
	array = strtok(rawlength, ":");
	switch(array.size)
	{
		case 1:
			seclength = atoi(array[0]);
			break;
		case 2:
		  seclength = (atoi(array[0]) * 60) + atoi(array[1]);
			break;
	}
	return(seclength);
}

jukeboxMusicLengthProfile(songno)
{
	seclength = level.ex_jukebox_tracks[self.pers["jukebox"].profile].length[songno];
	return(seclength);
}

jukeboxMusicShuffle()
{
	if(self.pers["jukebox"].tracks.size == 1) return;

	for(i = 0; i < 20; i++)
	{
		for(j = 1; j <= level.ex_jukebox_tracks[self.pers["jukebox"].profile].maxtracks; j++)
		{
			r = randomInt(level.ex_jukebox_tracks[self.pers["jukebox"].profile].maxtracks) + 1;
			element = self.pers["jukebox"].tracks[j];
			self.pers["jukebox"].tracks[j] = self.pers["jukebox"].tracks[r];
			self.pers["jukebox"].tracks[r] = element;
		}
	}
	self.pers["jukebox"].track = level.ex_jukebox_tracks[self.pers["jukebox"].profile].maxtracks;
}

jukeboxIsPlaying()
{
	if(self.pers["jukebox"].playing) return(true);
		else return(false);
}

jukeboxMenuDispatch(response)
{
	self endon("disconnect");

	switch(response)
	{
		case "1":
			jukeboxPressButton(1); // Power
			break;
		case "2":
			jukeboxPressButton(2); // Play
			break;
		case "3":
			jukeboxPressButton(4); // Stop
			break;
		case "4":
			jukeboxPressButton(8); // Next
			break;
		case "5":
			jukeboxPressButton(16); // Previous
			break;
		case "6":
			jukeboxPressButton(32); // Loop
			break;
		case "7":
			jukeboxPressButton(64); // Shuffle
			break;
	}
}

jukeboxPressButton(button)
{
	self.pers["jukebox"].buttons = self.pers["jukebox"].buttons | button;
}

jukeboxActionPower()
{
	self.pers["jukebox"].enabled = !self.pers["jukebox"].enabled;
	if(self.pers["jukebox"].enabled) jukeboxMusicStart("current");
	else
	{
		jukeboxMusicStop();
		jukeboxSaveMemory();
	}
	self setClientCvar("ui_jukebox_power", self.pers["jukebox"].enabled);
}

jukeboxActionPlay()
{
	if(!self.pers["jukebox"].enabled) return;
	if(!jukeboxIsPlaying()) jukeboxMusicStart("current");
}

jukeboxActionStop()
{
	if(!self.pers["jukebox"].enabled) return;
	if(jukeboxIsPlaying()) jukeboxMusicStop();
}

jukeboxActionNext()
{
	if(!self.pers["jukebox"].enabled) return;
	self.pers["jukebox"].loop = false;
	jukeboxMusicStart("next");
}

jukeboxActionPrevious()
{
	if(!self.pers["jukebox"].enabled) return;
	self.pers["jukebox"].loop = false;
	jukeboxMusicStart("previous");
}

jukeboxActionLoop()
{
	if(!self.pers["jukebox"].enabled) return;
	self.pers["jukebox"].loop = !self.pers["jukebox"].loop;
	self setClientCvar("ui_jukebox_loop", self.pers["jukebox"].loop);
	jukeboxSaveMemory();
}

jukeboxActionShuffle()
{
	if(!self.pers["jukebox"].enabled) return;
	self.pers["jukebox"].shuffle = !self.pers["jukebox"].shuffle;
	self.pers["jukebox"].loop = false;
	if(self.pers["jukebox"].shuffle)
		jukeboxMusicShuffle();
	else
	{
		for(i = 1; i <= level.ex_jukebox_tracks[self.pers["jukebox"].profile].maxtracks; i++)
			self.pers["jukebox"].tracks[i] = i;
		self.pers["jukebox"].track = level.ex_jukebox_tracks[self.pers["jukebox"].profile].maxtracks;
	}
	self setClientCvar("ui_jukebox_loop", self.pers["jukebox"].loop);
	self setClientCvar("ui_jukebox_shuffle", self.pers["jukebox"].shuffle);
	jukeboxSaveMemory();
}

jukeboxSaveMemory()
{
	if(level.ex_jukebox_memory)
	{
		self thread extreme\_ex_memory::setMemory("jukebox", "status", self.pers["jukebox"].enabled, true);
		self thread extreme\_ex_memory::setMemory("jukebox", "loop", self.pers["jukebox"].loop, true);
		self thread extreme\_ex_memory::setMemory("jukebox", "shuffle", self.pers["jukebox"].shuffle, true);
		self thread extreme\_ex_memory::setMemory("jukebox", "track", self.pers["jukebox"].track);
	}
}
