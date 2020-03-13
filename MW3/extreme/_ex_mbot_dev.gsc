#using_animtree("multiplayer");

init()
{
	level.model = [];

	level.wp_selected = -1;
	level.wp_startspawn = -1;
	level.wp_followme = false;
	level.wp_movemode = false;
	level.wp_botfreeze = false;
	level.wp_modelview = true;
}

menuWaypointSelect(response)
{
	self endon("disconnect");

	if(!checkMoveOff()) return;

	switch(response)
	{
		case "1": // go to selected
			if(!checkFollowMeOff()) return;
			if(!checkSelected()) return;
			self setOrigin(level.wp[level.wp_selected].origin);
			break;
		case "2": // go to next same type
			if(!checkFollowMeOff()) return;
			if(!checkSelected()) return;
			next = getSameType(level.wp_selected);
			if(next > 0 && next != level.wp_selected)
			{
				self setOrigin(level.wp[next].origin);
				markSelected(next);
			}
			break;
		case "3": // go to first waypoint
			if(!checkFollowMeOff()) return;
			self setOrigin(level.wp[0].origin);
			break;
		case "4": // go to last waypoint
			if(!checkFollowMeOff()) return;
			self setOrigin(level.wp[level.wp.size - 1].origin);
			break;
		case "5": // go to next junction
			if(!checkFollowMeOff()) return;
			if(!checkSelected()) return;
			next = getNextJunction(level.wp_selected);
			if(next > 0 && next != level.wp_selected)
			{
				self setOrigin(level.wp[next].origin);
				markSelected(next);
			}
			break;
		case "6": // go to previous junction
			if(!checkFollowMeOff()) return;
			if(!checkSelected()) return;
			next = getPreviousJunction(level.wp_selected);
			if(next > 0 && next != level.wp_selected)
			{
				self setOrigin(level.wp[next].origin);
				markSelected(next);
			}
			break;
		case "7": // go to next spawnpoint
			if(!checkFollowMeOff()) return;
			level.wp_startspawn++;
			if(level.wp_startspawn >= level.ex_mbot_spawnpoints.size) level.wp_startspawn = 0;
			self setOrigin(level.wp[level.wp_startspawn].origin);
			break;
		case "8": // go to previous spawnpoint
			if(!checkFollowMeOff()) return;
			level.wp_startspawn--;
			if(level.wp_startspawn < 0) level.wp_startspawn = level.ex_mbot_spawnpoints.size - 1;
			self setOrigin(level.wp[level.wp_startspawn].origin);
			break;
		case "9": // clear selections
			markSelected(-1);
			markBotStart(-1);
			markBotEnd(-1);
			break;
	}
}

menuWaypointType(response)
{
	self endon("disconnect");

	if(!checkMoveOff()) return;
	if(!checkSelected()) return;
	if(checkStart(level.wp_selected)) return;

	switch(response)
	{
		case "1": // camp [my angles]
			setNodeType(level.wp_selected, "c");
			break;
		case "2": // fall
			setNodeType(level.wp_selected, "f");
			break;
		case "3": // grenade [my angles]
			setNodeType(level.wp_selected, "g");
			break;
		case "4": // jump
			setNodeType(level.wp_selected, "j");
			break;
		case "5": // ladder
			setNodeType(level.wp_selected, "l");
			break;
		case "6": // mantle up (mode 0)
			setNodeType(level.wp_selected, "m", 0);
			break;
		case "7": // mantle over (mode 1)
			setNodeType(level.wp_selected, "m", 1);
			break;
		case "8": // waypoint
			setNodeType(level.wp_selected, "w");
			break;
		case "9": // -
			break;
	}
}

menuWaypointAction(response)
{
	self endon("disconnect");

	if(!checkMoveOff()) return;

	switch(response)
	{
		case "1": // place [my origin]
			if(!checkFollowMeOff()) return;
			if(isAlive(self)) spawnNode("w", self.origin, true);
			break;
		case "2": // move up and down
			if(!checkFollowMeOff()) return;
			if(!checkSelected()) return;
			if(checkStart(level.wp_selected)) return;
			moveNodeZ(level.wp_selected);
			break;
		case "3": // move parallel
			if(!checkFollowMeOff()) return;
			if(!checkSelected()) return;
			if(checkStart(level.wp_selected)) return;
			moveNodeX(level.wp_selected);
			break;
		case "4": // move perpendicular
			if(!checkFollowMeOff()) return;
			if(!checkSelected()) return;
			if(checkStart(level.wp_selected)) return;
			moveNodeY(level.wp_selected);
			break;
		case "5": // delete
			if(!checkFollowMeOff()) return;
			if(!checkSelected()) return;
			if(checkStart(level.wp_selected)) return;
			deleteNode(level.wp_selected);
			break;
		case "6": // set to ground level
			if(!checkFollowMeOff()) return;
			if(!checkSelected()) return;
			setNodeGround(level.wp_selected);
			break;
		case "7": // set origin [my origin]
			if(!checkFollowMeOff()) return;
			if(!checkSelected()) return;
			setNodeOrigin(level.wp_selected);
			break;
		case "8": // set angles [my angles]
			if(!checkFollowMeOff()) return;
			if(!checkSelected()) return;
			setNodeAngles(level.wp_selected);
			break;
		case "9": // set origin and angles
			if(!checkFollowMeOff()) return;
			if(!checkSelected()) return;
			setNodeOrigin(level.wp_selected);
			setNodeAngles(level.wp_selected);
			break;
	}
}

menuBuddy(response)
{
	self endon("disconnect");

	if(!checkMoveOff()) return;

	switch(response)
	{
		case "1": // toggle test start
			if(!checkSelected()) return;
			if(level.ex_botstart == -1 || level.ex_botstart != level.wp_selected)
			{
				markBotStart(level.wp_selected);
				iprintln(&"MBOT_INF_TESTSTART_SET", level.ex_botstart);
				thread botInstruct("goto", level.ex_botstart);
			}
			else
			{
				markBotStart(-1);
				iprintln(&"MBOT_INF_TESTSTART_DEL");
			}
			break;
		case "2": // toggle test end
			if(!checkSelected()) return;
			if(level.ex_botend == -1 || level.ex_botend != level.wp_selected)
			{
				markBotEnd(level.wp_selected);
				iprintln(&"MBOT_INF_TESTEND_SET", level.ex_botend);
			}
			else
			{
				markBotEnd(-1);
				iprintln(&"MBOT_INF_TESTEND_DEL");
			}
			break;
		case "3": // send bot to test start
			if(!checkBotStart()) return;
			thread botInstruct("goto", level.ex_botstart);
			break;
		case "4": // send bot to first
			thread botInstruct("goto", 0);
			break;
		case "5": // send bot to last
			thread botInstruct("goto", level.wp.size - 1);
			break;
		case "6": // toggle freeze bot
			thread botInstruct("freeze");
			break;
		case "7": // spawn bot into game
			thread botInstruct("spawn");
			break;
		case "8": // spawn teams into game
			thread botInstruct("spawnteam");
			break;
		case "9": // move bots to spectators
			thread botInstruct("spec");
			break;
	}
}

menuFile(response)
{
	self endon("disconnect");

	if(!checkMoveOff()) return;

	switch(response)
	{
		case "1": // show errors
			checkErrors(true);
			break;
		case "2": // go to error
			i = checkErrors(false);
			if(i >= 0)
			{
				self setOrigin(level.wp[i].origin);
				markSelected(i);
			}
			break;
		case "3": // save
			saveWaypoints(level.wpfile, false);
			break;
		case "4": // save numbered [debug]
			saveWaypoints(level.wpfile + "debug", true);
			break;
		case "5": // toggle auto-save
			level.ex_mbot_dev_autosave = !level.ex_mbot_dev_autosave;
			if(level.ex_mbot_dev_autosave)
			{
				thread autoSaveWaypoints(level.wpfile);
				iprintln(&"MBOT_INF_AUTOSAVE_ON");
			}
			else
			{
				self notify("end_autosave");
				iprintln(&"MBOT_INF_AUTOSAVE_OFF");
			}
			break;
		case "6": // reload [last saved]
			reloadWaypoints(level.wpfile);
			break;
		case "7": // reposition starting points
			repositionWaypoints();
			break;
		case "8": // -
			break;
		case "9": // -
			break;
	}
}

menuMisc(response)
{
	self endon("disconnect");

	if(!checkMoveOff()) return;

	switch(response)
	{
		case "1": // toggle waypoint filter
			level.ex_mbot_dev_filter = !level.ex_mbot_dev_filter;
			break;
		case "2": // toggle connector filter
			level.ex_mbot_dev_confilter = !level.ex_mbot_dev_confilter;
			break;
		case "3": // toggle pointer
			level.ex_mbot_dev_pointer = !level.ex_mbot_dev_pointer;
			break;
		case "4": // toggle follow-me
			level.wp_followme = !level.wp_followme;
			if(level.wp_followme)
			{
				if(!checkSelected()) return;
				self thread autoWaypoints();
				iprintln(&"MBOT_INF_FOLLOWME_ON");
			}
			else
			{
				self notify("end_followme");
				iprintln(&"MBOT_INF_FOLLOWME_OFF");
			}
			break;
		case "5": // toggle kill mode
			level.ex_mbot_dev_killmode = !level.ex_mbot_dev_killmode;
			if(level.ex_mbot_dev_killmode) iprintln(&"MBOT_INF_KILLMODE_ON");
				else iprintln(&"MBOT_INF_KILLMODE_OFF");
			break;
		case "6": // toggle kill developer
			level.ex_mbot_dev_killdev = !level.ex_mbot_dev_killdev;
			if(level.ex_mbot_dev_killdev) iprintln(&"MBOT_INF_KILLDEV_ON");
				else iprintln(&"MBOT_INF_KILLDEV_OFF");
			break;
		case "7": // -
			break;
		case "8": // disconnect [no confirmation]
			extreme\_ex_utils::execClientCommand("disconnect");
			break;
		case "9": // quit game [no confirmation]
			extreme\_ex_utils::execClientCommand("quit");
			break;
	}
}

mainDeveloper()
{
	self endon("kill_thread");

	for(;;)
	{
		wait( [[level.ex_fpstime]](0.05) );
		if(!level.wp_modelview) continue;

		if(level.ex_mbot_dev_pointer && isDefined(self.mark))
		{
			endpoint = self.mark[0].origin + maps\mp\_utility::vectorScale(anglesToForward(self getplayerangles()), 128);
			line(self.mark[0].origin, endpoint, (0, .8, .8), false);
		}

		if(self usebuttonpressed() && isdefined(self.mark))
		{
			start = self.mark[0].origin;
			forward = anglesToForward(self getplayerangles());
			forward = maps\mp\_utility::vectorScale(forward, 1000);
			end = start + forward;
			trace = bulletTrace(start, end, true, self);

			if(isdefined(trace["entity"]))
			{
				for(i = 0; i < level.wp.size; i++)
				{
					if(isdefined(level.model[i]) && level.model[i] == trace["entity"])
					{
						if(level.wp_selected == i)
						{
							markSelected(-1);
							break;
						}
						else
						{
							markSelected(i);
							break;
						}
					}
				}
				while(self usebuttonpressed()) wait( [[level.ex_fpstime]](0.1) );
			}
		}

		if(self meleebuttonpressed() && (level.wp_selected != -1) && isdefined(self.mark))
		{
			start = self.mark[0].origin;
			forward = anglesToForward(self getplayerangles());
			forward = maps\mp\_utility::vectorScale(forward, 1000);
			end = start + forward;
			trace = bulletTrace(start, end, true, self);

			if(isdefined(trace["entity"]))
			{
				for(i = 0; i < level.wp.size; i++)
				{
					if(isdefined(level.model[i]) && level.model[i] == trace["entity"])
					{
						if(i == level.wp_selected) break;

						result = level.wp[level.wp_selected] setNextNode(i);
						if(result == "linked")
						{
							level.model[level.wp_selected] delete();
							markSelected(i);
						}
						else if(result == "unlinked")
						{
							level.model[level.wp_selected] delete();
							markSelected(level.wp_selected);
						}
						break;
					}
				}
			}
			while(self meleebuttonpressed()) wait( [[level.ex_fpstime]](0.1) );
		}

		if(level.ex_mbot_dev_filter && level.wp_selected != -1)
		{
			for(i = 0; i < level.wp.size; i++) level.wp[i].ring = -1;

			i = level.wp_selected;
			level.wp[i].ring = level.wp_selected;
			while(isdefined(level.wp[i].next) && level.wp[i].next.size == 1)
			{
				next = level.wp[i].next[0];
				if(level.wp[next].ring == level.wp_selected) break;
				level.wp[next].ring = level.wp_selected;
				i = next;
			}

			if(isdefined(level.wp[i].next) && level.wp[i].next.size > 1)
			{
				for(k = 0; k < level.wp[i].next.size; k++)
				{
					next = level.wp[i].next[k];
					level.wp[next].ring = level.wp_selected;
				}
			}

			for(i = 0; i < level.wp.size; i++)
			{
				if(!isdefined(level.wp[i].type)) continue;

				if(level.wp[i].ring == level.wp_selected)
				{
					if(!isdefined(level.model[i])) spawnModelForNode(i);
				}
				else
				{
					if(isdefined(level.model[i])) level.model[i] delete();
				}

				if(isdefined(level.model[i]))
				{
					print3d((level.wp[i].origin + (0, 0, 15)), i, (.3, .8, 1), 1, 0.3);

					if(isDefined(level.wp[i].angles))
					{
						endpoint = level.wp[i].origin + maps\mp\_utility::vectorScale(anglesToForward(level.wp[i].angles), 64);
						line(level.wp[i].origin, endpoint, (1, 0, 0), false);
					}

					if(isdefined(level.wp[i].next))
					{
						for(k = 0; k < level.wp[i].next.size; k++)
						{
							next = level.wp[i].next[k];
							if(isdefined(next) && isdefined(level.wp[next]) && level.wp[next].ring == level.wp_selected)
							{
								// connect line to next
								line(level.wp[i].origin, level.wp[next].origin, (0, 0, 0), false);
								// line to indicate direction
								startpoint = level.wp[i].origin;
								angles = vectorToAngles(vectorNormalize(level.wp[next].origin - startpoint));
								endpoint = startpoint + maps\mp\_utility::vectorScale(anglesToForward(angles), 12);
								line(startpoint, endpoint, (1, 1, 0), false);
							}
						}
					}
				}
			}
		}
		else
		{
			for(i = 0; i < level.wp.size; i++)
			{
				if(!isdefined(level.wp[i].type)) continue;

				dist = distance(self.origin, level.wp[i].origin);
				if(dist < 400 || i == level.wp_selected )
				{
					if(!isdefined(level.model[i]))
					{
						spawnModelForNode(i);
						if(i < level.ex_mbot_spawnpoints.size && !isdefined(level.ex_spawnmarkers[i])) spawnModelForSpawnpoint(i);
					}
				}
				else
				{
					if(isdefined(level.model[i]))
					{
						level.model[i] delete();
						if(i < level.ex_mbot_spawnpoints.size && isdefined(level.ex_spawnmarkers[i])) level.ex_spawnmarkers[i] delete();
					}
				}

				wp_connector = true;
				if(level.ex_mbot_dev_confilter && (abs(self.origin[2] - level.wp[i].origin[2]) > 100)) wp_connector = false;

				if(wp_connector && isdefined(level.model[i]))
				{
					print3d((level.wp[i].origin + (0, 0, 15)), i, (.3, .8, 1), 1, 0.3);
					if(isdefined(level.ex_spawnmarkers[i]))
						print3d(level.ex_spawnmarkers[i].origin + (0, 0, 15), level.ex_spawnmarkers[i].origin, (.3, .8, 1), 1, 0.3);

					if(isDefined(level.wp[i].angles))
					{
						endpoint = level.wp[i].origin + maps\mp\_utility::vectorScale(anglesToForward(level.wp[i].angles), 64);
						line(level.wp[i].origin, endpoint, (1, 0, 0), false);
					}

					if(isdefined(level.wp[i].next))
					{
						for(k = 0; k < level.wp[i].next.size; k++)
						{
							next = level.wp[i].next[k];
							if(isdefined(next) && isdefined(level.wp[next]))
							{
								// connect line to next
								line(level.wp[i].origin, level.wp[next].origin, (0, 0, 0), false);
								// line to indicate direction
								startpoint = level.wp[i].origin;
								angles = vectorToAngles(vectorNormalize(level.wp[next].origin - startpoint));
								endpoint = startpoint + maps\mp\_utility::vectorScale(anglesToForward(angles), 12);
								line(startpoint, endpoint, (1, 1, 0), false);
							}
						}
					}
				}
			}
		}
	}
}

botInstruct(command, waypoint)
{
	players = level.players;

	switch(command)
	{
		case "goto":
			if(!isDefined(waypoint) || waypoint > level.wp.size - 1 ) break;

			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(player.pers["team"] == "spectator" || !isDefined(player.pers["isbot"]) || !isDefined(player.state))
					continue;

				player.goto = waypoint;
				break;
			}
			break;
		case "freeze":
			level.wp_botfreeze = !level.wp_botfreeze;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(isDefined(player.pers["isbot"]) && player.sessionteam != "spectator")
				{
					if(!isDefined(player.freezeme)) player.freezeme = true;
						else player.freezeme = undefined;
					break;
				}
			}
			break;
		case "spawn":
			mbot_count = 0;
			mbot_spec = 0;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(isDefined(player.pers["isbot"]))
				{
					mbot_count++;
					if(player.sessionteam == "spectator") mbot_spec++;
				}
			}
			if(!mbot_count || mbot_spec) extreme\_ex_bots::addBot("autoassign");
			break;
		case "spawnteam":
			mbot_count = 0;
			mbot_allies = 0;
			mbot_axis = 0;
			mbot_spec = 0;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(isDefined(player.pers["isbot"]))
				{
					mbot_count++;
					if(player.sessionteam == "spectator") mbot_spec++;
						else if(player.pers["team"] == "allies") mbot_allies++;
							else if(player.pers["team"] == "axis") mbot_axis++;
				}
			}

			mbot_spawn_allies = level.ex_mbot_dev_allies;
			if(mbot_allies) mbot_spawn_allies -= mbot_allies;
			mbot_spawn_axis = level.ex_mbot_dev_axis;
			if(mbot_axis) mbot_spawn_axis -= mbot_axis;
			level thread botSpawnTeams(mbot_spawn_allies, mbot_spawn_axis);
			break;
		case "spec":
			mbot_count = 0;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
				if(isDefined(player.pers["isbot"]) && player.sessionteam != "spectator") mbot_count++;
			}
			if(mbot_count) extreme\_ex_bots::removeBot("all");
			break;
	}
}

botSpawnTeams(mbot_allies, mbot_axis)
{
	if(isDefined(level.ex_mbot_spawning_teams)) return;
	level.ex_mbot_spawning_teams = true;

	if(mbot_allies > 32) mbot_allies = 32;
	mbot_maxaxis = 32 - mbot_allies;
	if(mbot_axis > mbot_maxaxis) mbot_axis = mbot_maxaxis;

	mbot_selector = 1;
	while(mbot_allies > 0 || mbot_axis > 0)
	{
		wait( [[level.ex_fpstime]](5) );

		if( (mbot_selector&1) && (mbot_axis > 0) )
		{
			mbot_axis--;
			extreme\_ex_bots::addBot("axis");
		}
		else if(mbot_allies > 0)
		{
			mbot_allies--;
			extreme\_ex_bots::addBot("allies");
		}

		mbot_selector++;
	}

	level.ex_mbot_spawning_teams = undefined;
}

autoWaypoints()
{
	self endon("kill_thread");
	self endon("end_followme");

	self setOrigin(level.wp[level.wp_selected].origin);
	wp_last = level.wp_selected;
	wp_lastorigin = level.wp[wp_last].origin;

	while(level.wp_followme)
	{
		wp_currentorigin = self.origin;
		dist = distance(wp_currentorigin, wp_lastorigin);
		if(dist > 75)
		{
			view = bullettracepassed(wp_lastorigin + (0,0,10), wp_currentorigin + (0,0,10), false, self);
			if(view)
			{
				spawnNode("w", wp_currentorigin, true);
				wp_index = level.wp.size - 1;
				level.wp[wp_last] setNextNode(wp_index);
				wp_last = wp_index;
			}
			wp_lastorigin = wp_currentorigin;
		}

		wait( [[level.ex_fpstime]](0.05) );
	}
}

markSelected(node)
{
	level.wp_selected = node;

	if(node != -1)
	{
		if(!isDefined(level.model[node])) spawnModelForNode(node);

		if(!isDefined(level.wp_selected_model))
		{
			level.wp_selected_model = spawn("script_model", (0,0,0));
			level.wp_selected_model setmodel("xmodel/marker_glow0");
		}

		level.wp_selected_model.origin = level.model[node].origin;
		level.wp_selected_model show();
	}
	else if(isDefined(level.wp_selected_model)) level.wp_selected_model hide();
}

markBotStart(node)
{
	level.ex_botstart = node;

	if(node != -1)
	{
		if(!isDefined(level.model[node])) spawnModelForNode(node);

		if(!isDefined(level.ex_botstart_model))
		{
			level.ex_botstart_model = spawn("script_model", (0,0,0));
			level.ex_botstart_model setmodel("xmodel/marker_glow1");
		}

		level.ex_botstart_model.origin = level.model[node].origin;
		level.ex_botstart_model show();
	}
	else if(isDefined(level.ex_botstart_model)) level.ex_botstart_model hide();
}

markBotEnd(node)
{
	level.ex_botend = node;

	if(node != -1)
	{
		if(!isDefined(level.model[node])) spawnModelForNode(node);

		if(!isDefined(level.ex_botend_model))
		{
			level.ex_botend_model = spawn("script_model", (0,0,0));
			level.ex_botend_model setmodel("xmodel/marker_glow2");
		}

		level.ex_botend_model.origin = level.model[node].origin;
		level.ex_botend_model show();
	}
	else if(isDefined(level.ex_botend_model)) level.ex_botend_model hide();
}

setNextNode(node)
{
	for(i = 0; i < self.next.size; i++)
	{
		if(self.next[i] == node)
		{
			temp = self.next;
			temp[i] = -1;
			self.next = undefined;
			self.next = [];

			for(l = 0; l < temp.size; l++)
			{
				if(temp[l] != -1)
					self.next[self.next.size] = temp[l];
			}
			return("unlinked");
		}
	}

	for(i = 0; i < level.wp[node].next.size; i++)
		if(level.wp[node].next[i] == level.wp_selected)
			return("nothing");

	self.next[self.next.size] = node;
	return("linked");
}

getSameType(node)
{
	start = node + 1;
	last = level.wp.size - 1;
	if(start >= last) start = 0;

	for(i = start; i < level.wp.size; i++)
	{
		if(level.wp[i].type == level.wp[node].type)
		{
			if(level.wp[i].type == "m" && (level.wp[i].mode != level.wp[node].mode)) continue;
			return(i);
		}
	}

	if(start > 0)
	{
		for(i = 0; i < node; i++)
		{
			if(level.wp[i].type == level.wp[node].type)
			{
				if(level.wp[i].type == "m" && (level.wp[i].mode != level.wp[node].mode)) continue;
				return(i);
			}
		}
	}

	iprintln(&"MBOT_INF_NO_SAMETYPE");
	return(-1);
}

getNextJunction(node)
{
	i = node;
	if(!isDefined(level.wp[i])) return(-1);

	if(isDefined(level.wp[i].next) && level.wp[i].next.size > 1)
	{
		iprintln(&"MBOT_WRN_ONJUNCTION");
		return(-1);
	}

	while(isDefined(level.wp[i].next) && level.wp[i].next.size == 1) i = level.wp[i].next[0];
	return(i);
}

getPreviousJunction(node)
{
	i = node;
	if(!isDefined(level.wp[i])) return(-1);

	if(isDefined(level.wp[i].next) && level.wp[i].next.size > 1)
	{
		iprintln(&"MBOT_WRN_ONJUNCTION");
		return(-1);
	}

	while(1)
	{
		wait( [[level.ex_fpstime]](0.01) );
		previous_node = -1;

		for(i = 0; i < level.wp.size; i++)
		{
			if(level.wp[i].next.size)
			{
				for(k = 0; k < level.wp[i].next.size; k++)
				{
					if(level.wp[i].next[k] == node)
					{
						previous_node = i;
						break;
					}
				}
			}

			if(previous_node != -1) break;
		}

		if(previous_node == -1) break;
		if(level.wp[previous_node].next.size > 1) return(previous_node);
			else node = previous_node;
	}

	return(-1);
}

spawnNode(type, origin, model)
{
	if(!isDefined(model)) model = true;

	i = level.wp.size;
	level.wp[i] = spawnstruct();
	level.wp[i].origin = origin;
	level.wp[i].next = [];
	level.wp[i].stance = 0;

	switch(type)
	{
		case "c":
			level.wp[i].type = "c";
			angles = self getplayerangles();
			level.wp[i].angles = (angles[0], angles[1], 0);
			break;
		case "f":
			level.wp[i].type = "f";
			break;
		case "g":
			level.wp[i].type = "g";
			angles = self getplayerangles();
			level.wp[i].angles = (angles[0], angles[1], 0);
			break;
		case "j":
			level.wp[i].type = "j";
			break;
		case "l":
			level.wp[i].type = "l";
			break;
		case "m":
			level.wp[i].type = "m";
			level.wp[i].mode = 0;
			break;
		case "w":
		default:
			level.wp[i].type = "w";
			break;
	}

	if(model) spawnModelForNode(i);
}

setNodeType(node, type, mode)
{
	i = node;
	if(!isDefined(level.wp[i])) return;
	if(!isDefined(mode)) mode = 0;

	switch(type)
	{
		case "c":
			level.wp[i].type = "c";
			angles = self getplayerangles();
			level.wp[i].angles = (angles[0], angles[1], 0);
			if(isDefined(level.wp[i].mode)) level.wp[i].mode = undefined;
			break;
		case "f":
			level.wp[i].type = "f";
			if(isDefined(level.wp[i].mode)) level.wp[i].mode = undefined;
			if(isDefined(level.wp[i].angles)) level.wp[i].angles = undefined;
			break;
		case "g":
			level.wp[i].type = "g";
			angles = self getplayerangles();
			level.wp[i].angles = (angles[0], angles[1], 0);
			if(isDefined(level.wp[i].mode)) level.wp[i].mode = undefined;
			break;
		case "j":
			level.wp[i].type = "j";
			if(isDefined(level.wp[i].mode)) level.wp[i].mode = undefined;
			if(isDefined(level.wp[i].angles)) level.wp[i].angles = undefined;
			break;
		case "l":
			level.wp[i].type = "l";
			if(isDefined(level.wp[i].mode)) level.wp[i].mode = undefined;
			if(isDefined(level.wp[i].angles)) level.wp[i].angles = undefined;
			break;
		case "m":
			level.wp[i].type = "m";
			level.wp[i].mode = mode;
			if(isDefined(level.wp[i].angles)) level.wp[i].angles = undefined;
			break;
		case "w":
		default:
			level.wp[i].type = "w";
			if(isDefined(level.wp[i].mode)) level.wp[i].mode = undefined;
			if(isDefined(level.wp[i].angles)) level.wp[i].angles = undefined;
			break;
	}

	if(isDefined(level.model[i])) level.model[i] delete();
	spawnModelForNode(i);
}

setNodeGround(node)
{
	i = node;
	if(!isDefined(level.wp[i])) return;

	repositionWaypoint(i);
	markSelected(i);
	if(level.ex_botstart == i) markBotStart(i);
	if(level.ex_botend == i) markBotEnd(i);
}

setNodeOrigin(node)
{
	i = node;
	if(!isDefined(level.wp[i])) return;

	dist = distance(self.origin, level.wp[i].origin);
	if(level.wp[i].next.size >= 1 && dist > 200)
	{
		iprintln(&"MBOT_WRN_TOFAR");
		return;
	}

	level.wp[i].origin = self.origin;
	if(isDefined(level.model[i])) level.model[i] delete();
	markSelected(i);
	if(level.ex_botstart == i) markBotStart(i);
	if(level.ex_botend == i) markBotEnd(i);
}

setNodeAngles(node)
{
	i = node;
	if(!isDefined(level.wp[i])) return;
	type = level.wp[i].type;

	switch(type)
	{
		case "c":
			angles = self getplayerangles();
			level.wp[i].angles = (angles[0], angles[1], 0);
			if(isDefined(level.model[i])) level.model[i] delete();
			spawnModelForNode(i);
			break;
		case "g":
			angles = self getplayerangles();
			level.wp[i].angles = (angles[0], angles[1], 0);
			if(isDefined(level.model[i])) level.model[i] delete();
			spawnModelForNode(i);
			break;
	}
}

moveNodeZ(node)
{
	level.wp_movemode = true;

	old_origin = level.wp_selected_model.origin;
	level.wp_selected_model.origin = level.wp[node].origin;

	org_angles = self getplayerangles();
	angles = vectortoangles(level.wp_selected_model.origin - self.ex_eyemarker.origin);
	if(org_angles[0] < 0 && angles[0] > 0) angles = (angles[0]-360, angles[1], angles[2]);
	self setplayerangles(angles);

	old_angles = self getplayerangles();
	move_multiplier = distance(level.wp_selected_model.origin, self.ex_eyemarker.origin) / 100;
	angles_uplock = undefined;
	angles_downlock = undefined;

	while(1)
	{
		wait( [[level.ex_fpstime]](0.05) );

		if(self usebuttonpressed())
		{
			level.wp[node].origin = level.wp_selected_model.origin;
			if(isDefined(level.model[node])) level.model[node] delete();
			break;
		}
		else if(self meleebuttonpressed()) break;

		angles = self getplayerangles();

		if(angles[0] > old_angles[0]) // moved down
		{
			if((isDefined(angles_downlock) && angles[0] > angles_downlock) ||
			   (isDefined(angles_uplock) && angles[0] < angles_uplock)) continue;

			move_val = (angles[0] - old_angles[0]) * move_multiplier;
			new_origin = level.wp_selected_model.origin - (0, 0, move_val);
			trace = bulletTrace(level.wp_selected_model.origin, new_origin, true, level.model[node]);
			if(trace["fraction"] == 1) level.wp_selected_model.origin = new_origin;
				else if(!isDefined(angles_downlock)) angles_downlock = angles[0];
		}
		else // moved up
		{
			if((isDefined(angles_downlock) && angles[0] > angles_downlock) ||
			   (isDefined(angles_uplock) && angles[0] < angles_uplock) ) continue;

			move_val = (old_angles[0] - angles[0]) * move_multiplier;
			new_origin = level.wp_selected_model.origin + (0, 0, move_val);
			trace = bulletTrace(level.wp_selected_model.origin, new_origin, true, level.model[node]);
			if(trace["fraction"] == 1) level.wp_selected_model.origin = new_origin;
				else if(!isDefined(angles_uplock)) angles_uplock = angles[0];

		}

		old_angles = angles;
	}

	markSelected(node);
	level.wp_movemode = false;
}

moveNodeX(node)
{
	level.wp_movemode = true;

	old_origin = level.wp_selected_model.origin;
	level.wp_selected_model.origin = level.wp[node].origin;

	org_angles = self getplayerangles();
	angles = vectortoangles(level.wp_selected_model.origin - self.ex_eyemarker.origin);
	if(org_angles[0] < 0 && angles[0] > 0) angles = (angles[0]-360, angles[1], angles[2]);
	self setplayerangles(angles);

	old_angles = self getplayerangles();
	move_multiplier = distance(level.wp_selected_model.origin, self.ex_eyemarker.origin) / 100;

	while(1)
	{
		wait( [[level.ex_fpstime]](0.05) );

		angles = self getplayerangles();

		if(angles[1] < old_angles[1]) // moved left
		{
			move_val = (old_angles[1] - angles[1]) * move_multiplier;
			forward = anglesToRight(level.model[node].angles);
			forward = [[level.ex_vectorscale]](forward, move_val);
			new_origin = level.wp_selected_model.origin + forward;
			trace = bulletTrace(level.wp_selected_model.origin, new_origin, true, level.model[node]);
			if(trace["fraction"] == 1) level.wp_selected_model.origin = new_origin;
		}
		else // moved right
		{
			move_val = (angles[1] - old_angles[1]) * move_multiplier;
			forward = anglesToRight(level.model[node].angles);
			forward = [[level.ex_vectorscale]](forward, move_val);
			new_origin = level.wp_selected_model.origin - forward;
			trace = bulletTrace(level.wp_selected_model.origin, new_origin, true, level.model[node]);
			if(trace["fraction"] == 1) level.wp_selected_model.origin = new_origin;
		}

		if(self usebuttonpressed())
		{
			level.wp[node].origin = level.wp_selected_model.origin;
			if(isDefined(level.model[node])) level.model[node] delete();
			break;
		}
		else if(self meleebuttonpressed()) break;

		old_angles = angles;
	}

	markSelected(node);
	level.wp_movemode = false;
}

moveNodeY(node)
{
	level.wp_movemode = true;

	old_origin = level.wp_selected_model.origin;
	level.wp_selected_model.origin = level.wp[node].origin;

	org_angles = self getplayerangles();
	angles = vectortoangles(level.wp_selected_model.origin - self.ex_eyemarker.origin);
	if(org_angles[0] < 0 && angles[0] > 0) angles = (angles[0]-360, angles[1], angles[2]);
	self setplayerangles(angles);

	old_angles = self getplayerangles();
	move_multiplier = distance(level.wp_selected_model.origin, self.ex_eyemarker.origin) / 100;

	while(1)
	{
		wait( [[level.ex_fpstime]](0.05) );

		angles = self getplayerangles();

		if(angles[1] < old_angles[1]) // moved left
		{
			move_val = (old_angles[1] - angles[1]) * move_multiplier;
			forward = anglesToRight(level.model[node].angles + (0,90,0));
			forward = [[level.ex_vectorscale]](forward, move_val);
			new_origin = level.wp_selected_model.origin + forward;
			trace = bulletTrace(level.wp_selected_model.origin, new_origin, true, level.model[node]);
			if(trace["fraction"] == 1) level.wp_selected_model.origin = new_origin;
		}
		else // moved right
		{
			move_val = (angles[1] - old_angles[1]) * move_multiplier;
			forward = anglesToRight(level.model[node].angles + (0,90,0));
			forward = [[level.ex_vectorscale]](forward, move_val);
			new_origin = level.wp_selected_model.origin - forward;
			trace = bulletTrace(level.wp_selected_model.origin, new_origin, true, level.model[node]);
			if(trace["fraction"] == 1) level.wp_selected_model.origin = new_origin;
		}

		if(self usebuttonpressed())
		{
			level.wp[node].origin = level.wp_selected_model.origin;
			if(isDefined(level.model[node])) level.model[node] delete();
			break;
		}
		else if(self meleebuttonpressed()) break;

		old_angles = angles;
	}

	markSelected(node);
	level.wp_movemode = false;
}

deleteNode(node)
{
	if(level.ex_botstart == node) markBotStart(-1);
	if(level.ex_botend == node) markBotEnd(-1);

	thread botInstruct("freeze");
	level.wp_modelview = false;

	last_node = level.wp.size - 1;
	old_selected = node;
	new_selected = undefined;

	for(i = 0; i < level.wp.size; i++)
	{
		for(k = 0; k < level.wp[i].next.size; k++)
		{
			if(level.wp[i].next[k] == node)
			{
				new_selected = i;
				temp = level.wp[i].next;
				temp[k] = -1;
				level.wp[i].next = undefined;
				level.wp[i].next = [];

				for(l = 0; l < temp.size; l++)
				{
					if(temp[l] != -1)
						level.wp[i].next[level.wp[i].next.size] = temp[l];
				}

				if(isDefined(level.model[i])) level.model[i] delete();
			}
		}
	}

	if(level.wp[old_selected].next.size >= 1)
		new_selected = level.wp[old_selected].next[0];

	markSelected(-1);
	wait( [[level.ex_fpstime]](1) );
	if(isDefined(level.model[old_selected])) level.model[old_selected] delete();

	if(old_selected != last_node)
	{
		if(level.ex_botstart == last_node) markBotStart(-1);
		if(level.ex_botend == last_node) markBotEnd(-1);

		level.wp[old_selected] = undefined;
		level.wp[old_selected] = spawnstruct();
		level.wp[old_selected] = level.wp[last_node];
		level.wp[last_node] = undefined;
		if(isdefined(level.model[last_node])) level.model[last_node] delete();
		spawnModelForNode(old_selected);

		for(i = 0; i < level.wp.size; i++)
		{
			for(k = 0; k < level.wp[i].next.size; k++)
			{
				if(level.wp[i].next[k] == last_node)
				{
					level.wp[i].next[k] = old_selected;
					break;
				}
			}
		}

	}
	else level.wp[old_selected] = undefined;

	level.wp_modelview = true;
	if(isdefined(new_selected)) markSelected(new_selected);
}

spawnModelForNode(node)
{
	i = node;
	if(!isDefined(level.wp[i])) return;

	switch(level.wp[i].type)
	{
		case "c":
			level.model[i] = spawn("script_model", level.wp[i].origin);
			level.model[i] setmodel("xmodel/marker_camp0");
			break;
		case "f":
			level.model[i] = spawn("script_model", level.wp[i].origin);
			level.model[i] setmodel("xmodel/marker_fall0");
			break;
		case "g":
			level.model[i] = spawn("script_model", level.wp[i].origin);
			level.model[i] setmodel("xmodel/marker_nade0");
			break;
		case "j":
			level.model[i] = spawn("script_model", level.wp[i].origin);
			level.model[i] setmodel("xmodel/marker_jump0");
			break;
		case "l":
			level.model[i] = spawn("script_model", level.wp[i].origin);
			level.model[i] setmodel("xmodel/marker_climb0");
			break;
		case "m":
			level.model[i] = spawn("script_model", level.wp[i].origin);
			if(isDefined(level.wp[i].mode) && level.wp[i].mode == 0)
				level.model[i] setmodel("xmodel/marker_mantle_up0");
			else
				level.model[i] setmodel("xmodel/marker_mantle_over0");
			break;
		case "w":
			level.model[i] = spawn("script_model", level.wp[i].origin);
			if(isDefined(level.ex_mbot_spawnpoints) && (i < level.ex_mbot_spawnpoints.size))
				level.model[i] setmodel("xmodel/marker_wpstart0");
			else if(isdefined(level.wp[i].next) && (level.wp[i].next.size > 1))
				level.model[i] setmodel("xmodel/marker_junction0");
			else
				level.model[i] setmodel("xmodel/marker_waypoint0");
			break;
	}

	if(isDefined(level.model[node]))
	{
		if(isDefined(level.wp[i].angles))
			level.model[i].angles = (0, level.wp[i].angles[1], 0);
		else
		{
			if(isdefined(level.wp[i].next) && level.wp[i].next.size)
			{
				next = level.wp[i].next[0];
				angles = vectortoangles(vectornormalize(level.wp[next].origin - level.wp[i].origin));
				level.model[i].angles = (0, angles[1] + 90, 0);
			}
			else level.model[i].angles = (0, 0, 0);
		}
	}
}

spawnModelForSpawnpoint(node)
{
	level.ex_spawnmarkers[node] = spawn("script_model", level.ex_mbot_spawnpoints[node].origin);
	level.ex_spawnmarkers[node] setmodel("xmodel/marker_" + level.ex_currentgt + "0");
}

checkSelected()
{
	if(level.wp_selected == -1)
	{
		iprintln(&"MBOT_WRN_SELECTION");
		return(false);
	}
	else return(true);
}

checkMoveOff()
{
	if(level.wp_movemode == true)
	{
		iprintln(&"MBOT_WRN_MOVEMODE");
		return(false);
	}
	else return(true);
}

checkStart(node)
{
	if(node < level.ex_mbot_spawnpoints.size)
	{
		iprintln(&"MBOT_WRN_START");
		return(true);
	}
	else return(false);
}

checkFollowMeOff()
{
	if(level.wp_followme)
	{
		iprintln(&"MBOT_WRN_AUTO");
		return(false);
	}
	else return(true);
}

checkBotStart()
{
	if(level.ex_botstart == -1)
	{
		iprintln(&"MBOT_WRN_BOTSTART");
		return(false);
	}
	else return(true);
}

checkBotEnd()
{
	if(level.ex_botend == -1)
	{
		iprintln(&"MBOT_WRN_BOTEND");
		return(false);
	}
	else return(true);
}

checkErrors(showall)
{
	wp_errors = 0;
	wp_referenced = [];
	error_str = &"MBOT_INF_NO_ERRORS";

	for(i = 0; i < level.wp.size; i++)
	{
		wp_error = false;

		if(level.wp[i].next.size == 0)
		{
			wp_error = true;
			error_str = &"MBOT_WRN_NEXT";
		}
		else if(level.wp[i].next.size >= 1)
		{
			for(k = 0; k < level.wp[i].next.size; k++) wp_referenced[level.wp[i].next[k]] = true;

			if(level.wp[i].next.size > 1 && (level.wp[i].type == "f" || level.wp[i].type == "j" || level.wp[i].type == "m" || level.wp[i].type == "l"))
			{
				wp_error = true;
				error_str = &"MBOT_WRN_MULTIPLE";
			}
		}

		if(wp_error)
		{
			wp_errors++;
			iprintln(error_str, i, getTypeStr(level.wp[i].type));
			if(!showall) return(i);
		}
	}

	for(i = 0; i < level.wp.size; i++)
	{
		if(i >= level.ex_mbot_spawnpoints.size && !isDefined(wp_referenced[i]))
		{
			wp_errors++;
			error_str = &"MBOT_WRN_REFERENCE";
			iprintln(error_str, i, getTypeStr(level.wp[i].type));
			if(!showall) return(i);
		}
	}

	if(!wp_errors)
	{
		iprintln(error_str);
		return(-1);
	}

	return(wp_errors);
}

getTypeStr(type)
{
	if(!isDefined(type)) type = "unknown";

	switch(type)
	{
		case "c":
			type_str = &"MBOT_TYPE_C";
			break;
		case "f":
			type_str = &"MBOT_TYPE_F";
			break;
		case "g":
			type_str = &"MBOT_TYPE_G";
			break;
		case "j":
			type_str = &"MBOT_TYPE_J";
			break;
		case "l":
			type_str = &"MBOT_TYPE_L";
			break;
		case "m":
			type_str = &"MBOT_TYPE_M";
			break;
		case "w":
			type_str = &"MBOT_TYPE_W";
			break;
		default:
			type_str = &"MBOT_TYPE_UNKNOWN";
			break;
	}

	return(type_str);
}

repositionWaypoints()
{
	for(i = 0; i < level.ex_mbot_spawnpoints.size; i++)
		repositionWaypoint(i);
}

repositionWaypoint(node)
{
	if(isDefined(level.wp[node]))
	{
		startpoint = level.wp[node].origin + (0,0,50);
		endpoint = startpoint - (0, 0, 100);
		trace = bulletTrace(startpoint, endpoint, true, level.model[node]);
		if(trace["fraction"] < 1.0)
		{
			level.wp[node].origin = trace["position"];
			if(isDefined(level.model[node])) level.model[node] delete();
		}
	}
}

backupWaypoints()
{
	if(!isDefined(level.wp)) return;

	if(isDefined(level.wpbackup))
	{
		for(i = 0; i < level.wpbackup.size; i++)
			if(isDefined(level.wpbackup[i])) level.wpbackup[i] = undefined;
		level.wpbackup = undefined;
	}
	level.wpbackup = [];

	for(i = 0; i < level.wp.size; i++)
	{
		if(!isDefined(level.wp[i].type)) continue;

		index = level.wpbackup.size;
		level.wpbackup[index] = spawnstruct();
		level.wpbackup[index].type = level.wp[i].type;
		level.wpbackup[index].origin = level.wp[i].origin;
		level.wpbackup[index].stance = level.wp[i].stance;
		if(isDefined(level.wp[i].angles)) level.wpbackup[index].angles = level.wp[i].angles;
		if(isDefined(level.wp[i].mode)) level.wpbackup[index].mode = level.wp[i].mode;

		level.wpbackup[index].next = [];
		if(isDefined(level.wp[i].next))
		{
			for(k = 0; k < level.wp[i].next.size; k++)
				level.wpbackup[index].next[k] = level.wp[i].next[k];
		}
	}
}

saveWaypoints(file, numbered)
{
	if(!isDefined(numbered)) numbered = false;

	f = openfile(file, "write");
	if(f == -1)
	{
		iprintln(&"MBOT_SAVE_FAILED", file);
		return(false);
	}

	fprintln(f, "mbotwp");
	closefile(f);

	f = openfile(file, "append");

	for(j = 0; j < level.wp.size; j++)
	{
		if(isdefined(level.wp[j].type))
		{
			if(numbered) wp_number = "[" + numToStr(j,4) + "]: ";
				else wp_number = "";

			switch(level.wp[j].type)
			{
				case "c":
					str = "\n" + wp_number + level.wp[j].origin[0] + " " + level.wp[j].origin[1] + " " + level.wp[j].origin[2] + " c " + level.wp[j].stance + " " + level.wp[j].next.size;
					for(k = 0; k < level.wp[j].next.size; k++)
						str += (" " + level.wp[j].next[k]);
					str += (" " + level.wp[j].angles[0] + " " + level.wp[j].angles[1]);
					fprintln(f, str);
					break;
				case "f":
					str = "\n" + wp_number + level.wp[j].origin[0] + " " + level.wp[j].origin[1] + " " + level.wp[j].origin[2] + " f " + level.wp[j].stance + " " + level.wp[j].next.size;
					for(k = 0; k < level.wp[j].next.size; k++)
						str += (" " + level.wp[j].next[k]);
					fprintln(f, str);
					break;
				case "g":
					str = "\n" + wp_number + level.wp[j].origin[0] + " " + level.wp[j].origin[1] + " " + level.wp[j].origin[2] + " g " + level.wp[j].stance + " " + level.wp[j].next.size;
					for(k = 0; k < level.wp[j].next.size; k++)
						str += (" " + level.wp[j].next[k]);
					str += (" " + level.wp[j].angles[0] + " " + level.wp[j].angles[1]);
					fprintln(f, str);
					break;
				case "j":
					str = "\n" + wp_number + level.wp[j].origin[0] + " " + level.wp[j].origin[1] + " " + level.wp[j].origin[2] + " j " + level.wp[j].stance + " " + level.wp[j].next.size;
					for(k = 0; k < level.wp[j].next.size; k++)
						str += (" " + level.wp[j].next[k]);
					fprintln(f, str);
					break;
				case "l":
					str = "\n" + wp_number + level.wp[j].origin[0] + " " + level.wp[j].origin[1] + " " + level.wp[j].origin[2] + " l " + level.wp[j].stance + " " + level.wp[j].next.size;
					for(k = 0; k < level.wp[j].next.size; k++)
					str += (" " + level.wp[j].next[k]);
					fprintln(f, str);
					break;
				case "m":
					str = "\n" + wp_number + level.wp[j].origin[0] + " " + level.wp[j].origin[1] + " " + level.wp[j].origin[2] + " m " + level.wp[j].stance + " " + level.wp[j].next.size;
					for(k = 0; k < level.wp[j].next.size; k++)
						str += (" " + level.wp[j].next[k]);
					str += (" " + level.wp[j].mode);
					fprintln(f, str);
					break;
				case "w":
					str = "\n" + wp_number + level.wp[j].origin[0] + " " + level.wp[j].origin[1] + " " + level.wp[j].origin[2] + " w " + level.wp[j].stance + " " + level.wp[j].next.size;
					for(k = 0; k < level.wp[j].next.size; k++)
						str += (" " + level.wp[j].next[k]);
					fprintln(f, str);
					break;
			}
		}
	}
	closefile(f);
	iprintln(&"MBOT_SAVE_SUCCESS", file);
	backupWaypoints();

	return(true);
}

autoSaveWaypoints(file)
{
	self endon("disconnect");
	self endon("end_autosave");

	if(!isDefined(level.ex_mbot_dev_autosave_counter)) level.ex_mbot_dev_autosave_counter = 1;

	while(level.ex_mbot_dev_autosave)
	{
		wait( [[level.ex_fpstime]](300) );
		thread saveWaypoints(file + ".auto" + level.ex_mbot_dev_autosave_counter, false);
		level.ex_mbot_dev_autosave_counter++;
		if(level.ex_mbot_dev_autosave_counter > 20) level.ex_mbot_dev_autosave_counter = 1;
	}
}

reloadWaypoints(file)
{
	level.wp_modelview = false;
	markSelected(-1);
	markBotStart(-1);
	markBotEnd(-1);
	extreme\_ex_bots::removeBot("all");
	wait( [[level.ex_fpstime]](1) );

	if(isDefined(level.model))
	{
		for(i = 0; i < level.wp.size; i++)
			if(isDefined(level.model[i])) level.model[i] delete();
		level.model = undefined;
	}
	level.model = [];

	if(isDefined(level.wp))
	{
		for(i = 0; i < level.wp.size; i++)
			if(isDefined(level.wp[i])) level.wp[i] = undefined;
		level.wp = undefined;
	}
	level.wp = [];

	for(i = 0; i < level.wpbackup.size; i++)
		level.wp[i] = level.wpbackup[i];

	level.wp_modelview = true;
}

numToStr(number, length)
{
	string = "" + number;
	if(string.size > length) length = string.size;
	diff = length - string.size;
	if(diff) string = dupChar("0", diff) + string;
	return(string);
}

dupChar(char, length)
{
	string = "";
	for(i = 0; i < length; i++) string = string + char;
	return(string);
}

strtoflt(str)
{
	if(!isstring(str)) return(0);
	setCvar("__tmp_f", str);
	flt = getCvarFloat("__tmp_f");
	return(flt);
}

abs(var)
{
	if(var < 0) var = var * (-1);
	return(var);
}

angleSubtract(a1, a2)
{
	a = a1-a2;
	if(abs(a) > 180)
	{
		if(a < -180)
			a += 360;
		else if(a > 180)
			a -= 360;
	}
	return(a);
}

anglesAdd(a1, a2)
{
	v = [];
	v[0] = a1[0] + a2[0];
	v[1] = a1[1] + a2[1];
	v[2] = a1[2] + a2[2];

	for(i=0; i<3; i++)
	{
		while(v[i] > 360)
			v[i] -= 360;
		while(v[i] < -360)
			v[i] += 360;
	}
	return(v[0], v[1], v[2]);
}

debugBot()
{
	logprint("\n" + self.name + " status:\n");
	logprint("-------------------------------------\n");
	logprint("Team: " + self.pers["team"] + "\n");
	logprint("State: " + self.state + "\n");
	logprint("IsAlive: " + isalive(self) + "\n");
	logprint("CurrentWeapon: " + (self getCurrentWeapon()) + "\n");
	logprint("PrimaryWeapon: " + (self getweaponslotweapon("primary")) + "\n");
	logprint("PrimaryAmmo: " + (self getweaponslotammo("primary")) + "\n");
	logprint("PrimaryClipAmmo: " + (self getweaponslotclipammo("primary")) + "\n");
	logprint("SecondaryWeapon: " + (self getweaponslotweapon("primaryb")) + "\n");
	logprint("SecondaryAmmo: " + (self getweaponslotammo("primaryb")) + "\n");
	logprint("SecondaryClipAmmo: " + (self getweaponslotclipammo("primaryb")) + "\n");
	if(isdefined(self.botgrenade))
		logprint("GrenadeType: " + self.botgrenade + "\n");
	else
		logprint("GrenadeType: undefined\n");

	if(isdefined(self.botgrenadecount))
		logprint("GrenadesCount: " + self.botgrenadecount + "\n");
	else
		logprint("GrenadesCount: undefined\n");

	logprint("Origin: " + self.origin + ")\n");

	if(isdefined(self.alert))
		logprint("Alert: " + self.alert + "\n");
	else
		logprint("Alert: undefined\n");

	if(isdefined(self.next))
		logprint("NextWP: " + self.next.next[0] + "\n");
	else
		logprint("NextWP: undefined\n");

	logprint("pClipAmmo: " + self.pclipammo + "\n");
	logprint("BotOrg: " + self.botorg.origin + "\n");
	logprint("-------------------------------------\n");
}
