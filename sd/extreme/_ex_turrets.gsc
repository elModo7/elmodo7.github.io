#include extreme\_ex_weapons;

main()
{
	// get all the turrets on map and monitor them
	num = 0;
	turrets = getentarray("misc_turret", "classname");
	for(i = 0; i < turrets.size; i++)	
	{
		if(isDefined(turrets[i])) 
		{
			level.turret_origin[num] = turrets[i].origin;
			level.turret_model[num] = turrets[i].model;
			level.turret_name[num] = turrets[i].name;
			level.turret_angles[num] = turrets[i].angles;
			turrets[i].id = num;
			num ++;
			turrets[i] thread turretThink();
		}
	}

	turrets = getentarray("misc_mg42", "classname");
	for(i = 0; i < turrets.size; i++)	
	{
		if(isDefined(turrets[i])) 
		{
			level.turret_origin[num] = turrets[i].origin;
			level.turret_model[num] = turrets[i].model;
			level.turret_name[num] = turrets[i].name;
			level.turret_angles[num] = turrets[i].angles;
			turrets[i].id = num;
			num ++;
			turrets[i] thread turretThink();
		}
	}
}

turretCount()
{
	turretno = 0;
	turrets = getentarray("misc_turret", "classname");
	if(isDefined(turrets)) turretno = turrets.size;
	turrets = getentarray("misc_mg42", "classname");
	if(isDefined(turrets)) turretno = turretno + turrets.size;
	return turretno;
}

turretThink()
{
	level endon("ex_gameover");

	self.heat_rate = level.ex_turretoverheat_heatrate;
	self.heat_status = 1;
	self.heat_danger = 80;
	self.heat_max = 114;
	self.cool_rate = level.ex_turretoverheat_coolrate;
	if(level.ex_turretoverheat) self thread turretOverheatDrain();

	while(1)
	{
		// wait for player to use turret
		self waittill ("trigger", other);
		if(isPlayer(other))
		{
			other.onturret = self;
			if(level.ex_turretoverheat) other thread playerOverheatShowHUD(self);

			if(other useButtonPressed())
			{
				other thread extreme\_ex_utils::execClientCommand("-activate");
				while(isAlive(other) && other useButtonPressed()) wait( [[level.ex_fpstime]](0.05) );
			}

			if(!isPlayer(other)) continue;

			allow_detach = true;
			if(level.ex_turrets != 2 || other hasMobileMG()) allow_detach = false;
			if(allow_detach && level.ex_wepo_sidearm == 1 && isWeaponType(other getcurrentweapon(), "pistol")) allow_detach = false;
			if(allow_detach && level.ex_currentgt == "ft" && other.frozenstate == "frozen") allow_detach = false;
			if(allow_detach)
			{
				if(isDefined(other.ex_binocular_hint)) other.ex_binocular_hint.alpha = 0;
				other playerShowMsg(&"TURRET_MELEE_TO_PICKUP");
			}

			for(;;)
			{
				wait( [[level.ex_fpstime]](0.1) );

				// player detaching turret
				if(allow_detach && isDefined(other) && other meleeButtonPressed())
				{	
					if(level.ex_turretoverheat)
					{
						self notify("stop_overheat_fx");
						waittillframeend;
						self notify("stop_overheat_drain");
						other thread playerOverheatRemoveHUD();
					}
					other turretUnfix(self);
					other.onturret = undefined;
					break;
				}

				// turret overheating
				if(level.ex_turretoverheat && isDefined(other) && isDefined(other.onturret) && other attackButtonPressed())
				{
					if(self.heat_status < self.heat_max)
					{
						self.heat_status = self.heat_status + self.heat_rate;
						if(self.heat_status > self.heat_max) self.heat_status = self.heat_max;
					}
					if(self.heat_status == self.heat_max)
					{
						self playsound("turret_overheat");
						self thread turretOverheat();
						// release the fire button to stop firing, and press the use button to get off the turret
						other thread extreme\_ex_utils::execClientCommand("-attack; +activate; wait 10; -activate");
					}
					else if(isDefined(other.forceoffturret))
					{
						// release the fire button to stop firing, and press the use button to get off the turret
						other thread extreme\_ex_utils::execClientCommand("-attack; +activate; wait 10; -activate");
					}
				}

				// player getting off turret
				if(isDefined(other) && (other useButtonPressed() || other isonground() || isDefined(other.forceoffturret)) )
				{
					other.onturret = undefined;
					other.forceoffturret = undefined;
					other playerRemoveMsg();
					if(level.ex_turretoverheat) other thread playerOverheatRemoveHUD();
					if(isDefined(other.ex_binocular_hint)) other.ex_binocular_hint.alpha = 1;
					break;
				}

				if(level.ex_turretoverheat && isDefined(other) && isDefined(other.onturret))
					other thread playerOverheatUpdateHUD(self);
			}
		}
	}
}

playerOverheatUpdateHUD(turret)
{
	self endon("kill_thread");

	if(isDefined(self.overheat_status) && turret.heat_status > 1)
	{
		self.overheat_status scaleovertime( 0.1, 10, int(turret.heat_status));
		self.overheat_status.color = playerOverheatSetColor(turret);
		wait( [[level.ex_fpstime]](0.1) );
	}
}

playerOverheatSetColor(turret)
{
	self endon("kill_thread");

	// define what colors to use
	color_cold = [];
	color_cold[0] = 1.0;
	color_cold[1] = 1.0;
	color_cold[2] = 0.0;
	color_warm = [];
	color_warm[0] = 1.0;
	color_warm[1] = 0.5;
	color_warm[2] = 0.0;
	color_hot = [];
	color_hot[0] = 1.0;
	color_hot[1] = 0.0;
	color_hot[2] = 0.0;

	// default color
	SetValue = [];
	SetValue[0] = color_cold[0];
	SetValue[1] = color_cold[1];
	SetValue[2] = color_cold[2];

	// define where the non blend points are
	cold = 0;
	warm = (turret.heat_max / 2);
	hot = turret.heat_max;
	value = turret.heat_status;

	iPercentage = undefined;
	difference = undefined;
	increment = undefined;

	if( (value > cold) && (value <= warm) )
	{
		iPercentage = int(value * (100 / warm));
		for( colorIndex = 0 ; colorIndex < SetValue.size ; colorIndex++ )
		{
			difference = (color_warm[colorIndex] - color_cold[colorIndex]);
			increment = (difference / 100);
			SetValue[colorIndex] = color_cold[colorIndex] + (increment * iPercentage);
		}
	}
	else if( (value > warm) && (value <= hot) )
	{
		iPercentage = int( (value - warm) * (100 / (hot - warm) ) );
		for( colorIndex = 0 ; colorIndex < SetValue.size ; colorIndex++ )
		{
			difference = (color_hot[colorIndex] - color_warm[colorIndex]);
			increment = (difference / 100);
			SetValue[colorIndex] = color_warm[colorIndex] + (increment * iPercentage);
		}
	}

	return (SetValue[0], SetValue[1], SetValue[2]);
}

turretOverheatDrain()
{
	level endon("ex_gameover");
	self endon("stop_overheat_drain");

	frames = 20;

	for(;;)
	{
		wait( [[level.ex_fpstime]](0.05) );

		if(self.heat_status > 1)
		{
			difference = self.heat_status - (self.heat_status - self.cool_rate);
			frame_difference = (difference / frames);

			if(self.heat_status >= self.heat_danger) thread turretOverheatOneShotFX();

			for(i = 0; i < frames; i++)
			{
				self.heat_status -= frame_difference;
				if(self.heat_status < 1)
				{
					self.heat_status = 1;
					break;
				}
				wait( [[level.ex_fpstime]](0.05) );
			}
		}
	}
}

turretOverheat()
{
	level endon("ex_gameover");

	self notify("stop_overheat_fx");
	waittillframeend;
	self endon("stop_overheat_fx");

	thread turretOverheatFX();
	wait( [[level.ex_fpstime]](5) );
	self notify("stop_overheat_fx");
}

turretOverheatFX()
{
	level endon("ex_gameover");
	self endon("stop_overheat_fx");

	for(;;)
	{
		turretOverheatOneShotFX();
		wait( [[level.ex_fpstime]](0.2) );
	}
}

turretOverheatOneShotFX()
{
	self endon("stop_overheat_fx");

	playfxOnTag(level.ex_effect["armored_car_overheat"], self, "tag_flash");
}


playerOverheatShowHUD(turret)
{
	self endon("kill_thread");

	if(!isDefined(self.overheat_bg))
	{
		self.overheat_bg = newclienthudelem(self);
		self.overheat_bg.archived = false;
		self.overheat_bg.horzAlign = "right";
		self.overheat_bg.vertAlign = "bottom";
		self.overheat_bg.alignX = "right";
		self.overheat_bg.alignY = "bottom";
		self.overheat_bg.x = -13;
		self.overheat_bg.y = -160;
		self.overheat_bg setShader("hud_temperature_gauge", 35, 150);
		self.overheat_bg.sort = 2;
	}

	barX = -25;
	barY = -192;

	// status bar
	if(!isDefined(self.overheat_status))
	{
		self.overheat_status = newclienthudelem(self);
		self.overheat_status.archived = false;
		self.overheat_status.horzAlign = "right";
		self.overheat_status.vertAlign = "bottom";
		self.overheat_status.alignX = "right";
		self.overheat_status.alignY = "bottom";
		self.overheat_status.x = barX;
		self.overheat_status.y = barY;
		self.overheat_status setShader("white", 10, int(turret.heat_status));
		self.overheat_status.color = playerOverheatSetColor(turret);
		self.overheat_status.alpha = 1;
		self.overheat_status.sort = 1;
	}
}

playerOverheatRemoveHUD()
{
	self endon("kill_thread");

	if(isDefined(self.overheat_bg)) self.overheat_bg destroy();
	if(isDefined(self.overheat_status)) self.overheat_status destroy();
}

turretUnfix(turret)
{
	self endon("kill_thread");

	self playLocalSound("MP_bomb_plant");
	self playerShowMsg(&"TURRET_DEPLANT");
	self [[level.ex_dWeapon]]();
	wait( [[level.ex_fpstime]](2) );
	self playerRemoveMsg();
	if(isDefined(turret))
	{
		self.turretid = turret.id;
		self thread monitorTurretReturn();
		if(turret.model == "xmodel/weapon_30cal") newwep = "mobile_30cal";
			else newwep = "mobile_mg42";
		turret delete();
		self [[level.ex_eWeapon]]();
		cslot = self getCurrentSlot();
		self dropCurrentWeapon();
		self setWeaponSlotWeapon(cslot, newwep);
	}
	else self [[level.ex_eWeapon]]();
}

turretPlant()
{
	self endon("kill_thread");

	self playerRemoveMsg();

	if(!isDefined(self.turret_indicator))
	{
		self.turret_indicator = newClientHudElem(self);
		self.turret_indicator.name = "turretIndicator";
		self.turret_indicator.archived = false;
		self.turret_indicator.horzAlign = "fullscreen";
		self.turret_indicator.vertAlign = "fullscreen";
		self.turret_indicator.alignX = "center";
		self.turret_indicator.alignY = "middle";
		self.turret_indicator.x = -1000;
		self.turret_indicator.y = -1000;
		self.turret_indicator.z = -1000;
		self.turret_indicator.alpha = .8;
		self.turret_indicator setShader("objpoint_star", 4, 4);
		self.turret_indicator setwaypoint(false);
	}

	allow_plant = false;

	while(isDefined(self) && self meleeButtonPressed())
	{
		wait( [[level.ex_fpstime]](0.1) );

		if(isDefined(self.onturret) || !isMobileMG() || turretCount() >= level.ex_turretsmax) return;

		trace = undefined;
		allow_plant = true;
		if(isNearTurret())
		{
			self playerShowMsg(&"TURRET_TOO_CLOSE_TURRET");
			allow_plant = false;
		}
		else
		{
			trace = self playerGetEyeTrace();
			if(trace["fraction"] == 1.0 || trace["surfacetype"] == "default") continue;
			if(distance(trace["position"],self.origin) < 20)
			{
				self playerShowMsg(&"TURRET_TOO_CLOSE");
				allow_plant = false;
			}
			if(distance(trace["position"],self.origin) > 60)
			{
				self playerShowMsg(&"TURRET_TOO_FAR");
				allow_plant = false;
			}
		}

		if(allow_plant)
		{
			self.turret_indicator setShader("objpoint_star", 4, 4);
			self.turret_indicator setwaypoint(false);
			self.turret_indicator.x = trace["position"][0];
			self.turret_indicator.y = trace["position"][1];
			self.turret_indicator.z = trace["position"][2] + 9;
			self playerShowMsg(&"TURRET_MELEE_TO PLANT");
		}
		else
		{
			self.turret_indicator.x = -1000;
			self.turret_indicator.y = -1000;
			self.turret_indicator.z = -1000;
		}
	}

	if(allow_plant && isDefined(self) && !self meleeButtonPressed())
	{
		trace = self playerGetEyeTrace();
		origin = trace["position"];
		angles = self.angles;
		forward = anglesToForward((0, angles[1], 0));
		forward = maps\mp\_utility::vectorScale( forward, 100000 );
		endOrigin = origin + forward;
		trace = bulletTrace( origin + (0,0,16), endOrigin + (0,0,16), false, self );
		player_high_pos = self.origin;
		target_high_pos = (self.origin[0], self.origin[1], trace["position"][2]);
		high = distance(player_high_pos, target_high_pos);
		stance = "stand";
		dis = 50;
		if(high < 30)
		{
			stance = "duck";
			dis = 80;
		}
		if(high < 20)
		{
			stance = "prone";
			dis = 100;
		}
		leftarc = 0;
		rightarc = 0;
		mgang = angles[1] + 180;

		for(i = -10; i > -55; i--)
		{
			forward = anglesToForward((0, mgang + i, 0));
			forward = maps\mp\_utility::vectorScale( forward, dis );
			endOrigin = origin + forward;
			lng = distance(origin,endOrigin);
			trace = bulletTrace( origin + (0,0,16), endOrigin + (0,0,16), false, self );
			if(distance(trace["position"], origin + (0,0,16)) < lng) break;
			rightarc ++;
		}

		for(i = 10; i < 55; i++)
		{
			forward = anglesToForward((0, mgang + i, 0));
			forward = maps\mp\_utility::vectorScale( forward, dis );
			endOrigin = origin + forward;
			lng = distance(origin,endOrigin);
			trace = bulletTrace( origin + (0,0,16), endOrigin + (0,0,16), false, self );
			if(distance(trace["position"], origin + (0,0,16)) < lng) break;
			leftarc ++;
		}

		if(i < 12) return;

		self playerShowMsg(&"TURRET_PLANTING");
		if(isDefined(self.turret_indicator)) self.turret_indicator destroy();
		self playLocalSound("MP_bomb_plant");

		cslot = self getCurrentSlot();
		model = self getcurrentweapon();
		if(model == "mobile_mg42")
		{
			type = "mg42_bipod_" + stance + "_mp";
			xmod = "xmodel/weapon_mg42";
		}
		else
		{
			type = "30cal_" + stance + "_mp";
			xmod = "xmodel/weapon_30cal";
		}

		// self.turretid must be removed before setting current slot weapon to "none"
		turretid = undefined;
		if(isDefined(self.turretid))
		{
			turretid = self.turretid;
			self.turretid = undefined;
		}
		self setWeaponSlotWeapon(cslot, "none");
		self [[level.ex_dWeapon]]();
		wait( [[level.ex_fpstime]](2) );

		turret = spawnturret("misc_turret", origin, type);
		turret setmodel(xmod);
		turret.angles = angles;
		turret SetTopArc(15);
		turret SetBottomArc(15);
		turret SetLeftArc(leftarc);
		turret SetRightArc(rightarc);
		turret.id = turretid;
		turret thread turretThink();
		self [[level.ex_eWeapon]]();
	}
}

monitorMobileMG()
{
	self endon("kill_thread");

	self.onturret = undefined;
	self.turretid = undefined;

	while(isDefined(self) && isalive(self) && self.sessionstate == "playing")
	{
		wait( [[level.ex_fpstime]](1) );

		if(isDefined(self) && isMobileMG())
		{
			if(turretCount() < level.ex_turretsmax) self playerShowMsg(&"TURRET_USE_SHOW_ICON");

			while(isDefined(self) && isMobileMG())
			{
				wait( [[level.ex_fpstime]](.5) );

				if(level.ex_mg_shoot_disable && isDefined(self) && self attackbuttonPressed()) self monitorFireMobileMG();

				if(isDefined(self) && self meleeButtonPressed())
				{
					self turretPlant();
					self playerRemoveMsg();
					if(isDefined(self.turret_indicator)) self.turret_indicator destroy();
				}
			}

			self playerRemoveMsg();
		}
	}
}

monitorFireMobileMG()
{
	self endon("kill_thread");

	count = 0;

	while(isDefined(self) && isMobileMG() && self attackbuttonPressed())
	{
		count++;
		earthquake(.5, .2, self.ex_thumbmarker.origin, 50);
		if(level.ex_mg_shoot_damage)
			self thread [[level.callbackPlayerDamage]](self, self, 1, 1, "MOD_TRIGGER_HURT", "turret", undefined, (0,0,1), "none", 0);
		wait( [[level.ex_fpstime]](0.2) );
		if(count >= 5)
		{
			self [[level.ex_dWeapon]]();
			wait( [[level.ex_fpstime]](3) );
			if(isDefined(self)) self [[level.ex_eWeapon]]();
			break;
		}
	}
}

playerGetEyeTrace()
{
	self endon("kill_thread");

	startOrigin = self getEye() + self playerGetEyeOffset();
	forward = anglesToForward( self getplayerangles() );
	forward = maps\mp\_utility::vectorScale( forward, 100000 );
	endOrigin = startOrigin + forward;
	trace = bulletTrace( startOrigin, endOrigin, false, self );
	
	return trace;
}

playerGetEyeOffset()
{
	self endon("kill_thread");

	offset = (0,0,18);
	self.stance = [[level.ex_getStance]](false);
	if(self.stance == 1) offset = (0,0,2);
	if(self.stance == 2) offset = (0,0,-27);

	return offset;
}

playerShowMsg(msg)
{
	self endon("kill_thread");

	if(!isDefined(self.turret_msg))
	{
		self.turret_msg = newClientHudElem(self);
		self.turret_msg.archived = false;
		self.turret_msg.horzAlign = "fullscreen";
		self.turret_msg.vertAlign = "fullscreen";
		self.turret_msg.alignX = "center";
		self.turret_msg.alignY = "middle";
		self.turret_msg.x = 320;
		self.turret_msg.y = 420;
		self.turret_msg.alpha = 1;
		self.turret_msg.fontScale = 1;
		self.turret_msg.sort = 1;
	}	

	self.turret_msg setText(msg);
}

playerRemoveMsg()
{
	self endon("kill_thread");

	if(isDefined(self.turret_msg)) self.turret_msg destroy();
}

getCurrentSlot()
{
	current = self getCurrentWeapon();
	primary = self whatsInSlot("primary");
	primaryb = self whatsInSlot("primaryb");
	if(current == primary || primaryb == "ignore" || primary == "mobile_30cal" || primary == "mobile_mg42") return "primary";
		else return "primaryb";
}

isNearTurret()
{
	turrets = getentarray("misc_turret", "classname");
	for(i = 0; i < turrets.size; i++)
	{
		if(isDefined(self) && isDefined(turrets[i]) && distance(turrets[i].origin, self.origin) < 200) return true;
	}
	turrets = getentarray("misc_mg42", "classname");
	for(i = 0; i < turrets.size; i++)
	{
		if(isDefined(self) && isDefined(turrets[i]) && distance(turrets[i].origin, self.origin) < 200) return true;
	}
	return false;
}

isMobileMG()
{
	current = self getcurrentweapon();
	if(current == "mobile_30cal" || current == "mobile_mg42") return true;
	return false;
}

hasMobileMG()
{
	current = self getcurrentweapon();
	if(current == "mobile_30cal" || current == "mobile_mg42") return true;
	if(self.weapon["primary"].name == "mobile_30cal" || self.weapon["primary"].name == "mobile_mg42") return true;
	if(self.weapon["primaryb"].name == "mobile_30cal" || self.weapon["primaryb"].name == "mobile_mg42") return true;
	return false;
}

monitorTurretReturn()
{
	level endon("ex_gameover");

	self waittill("kill_thread");
	self thread restoreTurret();
}

restoreTurret()
{
	if(isDefined(self.turretid))
	{
		turretid = self.turretid;
		origin = self.origin;
		self.turretid = undefined;

		model = level.turret_model[turretid];
		if(model == "xmodel/weapon_mg42")
		{
			weapon = "mobile_mg42";
			type = "mg42_bipod_stand_mp";
		}
		else
		{
			weapon = "mobile_30cal";
			type = "30cal_stand_mp";
		}

		turret = spawnturret("misc_turret", level.turret_origin[turretid], type);
		turret setmodel(model);
		turret.angles = level.turret_angles[turretid];
		turret SetTopArc(15);
		turret SetBottomArc(15);
		turret SetLeftArc(45);
		turret SetRightArc(45);
		turret.id = turretid;
		turret thread turretThink();

		// if MG weapon drop is enabled, remove dropped mobile MG as it is already restored as a turret
		if(level.ex_wepo_drop_weps && level.allow_mg_drop)
		{
			// if called from monitorTurretReturn(), we have to wait a brief moment for Callback_playerKilled to finish
			wait( [[level.ex_fpstime]](0.2) );

			entities = getentarray("weapon_" + weapon, "classname");
			for(i = 0; i < entities.size; i++)
			{
				entity = entities[i];
				if(distance(entity.origin, origin) < 200) entities[i] delete();
			}
		}
	}
}
