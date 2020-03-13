init()
{ 

predator()
{
	self setclientcvar("cg_thirdperson","0");
	self.predator=0;
	self.predator_act=1;
	self.pred=1;
	self.ac130_act=1;
	self.airstrike_act=1;
	jatekos = getentarray("player", "classname");
	for(i=0;i<jatekos.size;i++)
	{
		if(self.pers["team"]==jatekos[i].pers["team"])
			jatekos[i] playlocalsound("use_predator");
		else
			jatekos[i] playlocalsound("use_enemy_predator");
	}
	self.ppos=self.origin;
	self setorigin(ac_map()+(0,0,1000));
	self setplayerangles(85,self getplayerangles()[1],0);
	self._predator=spawn("script_model", self.origin+(0,0,0));
	self._predator setModel("xmodel/prop_stuka_bomb");
	self._predator playloopsound("predator_vegso");

	self hide();
	self disableweapon();
	self linkto(self._predator);
	self.inv=true;

	self.hud_predator = newClientHudElem(self);
	self.hud_predator setShader("gunship_overlay_105mm", 512, 512);
	self.hud_predator.alpha = 1;
	self.hud_predator.alignX = "center";
	self.hud_predator.alignY = "middle";
	self.hud_predator.sort = 9998;
	self.hud_predator.x = 320;
	self.hud_predator.y = 240;

	self thread predator_move();
	self thread predator_act();
	self thread predator_ang();
	self thread predator_end();
}
predator_end()
{
self endon("disconnect");
self endon("killed_player");
self endon("predator_end");
self endon("predator_go");

	self.hud_predator_timer = newClientHudElem(self);
	self.hud_predator_timer.x = 320;
	self.hud_predator_timer.y = 60;
	self.hud_predator_timer.alignX = "center";
	self.hud_predator_timer.fontScale = 1.4;
	self.hud_predator_timer settenthsTimer(10);
	self.hud_predator_timer.color = (1,0,0);
	wait 10;
	self.hud_predator_timer destroy();

	playfx(level._effect["predator2"], self._predator);
	playfx(level._effect["predator2"], self.predator);
	playfx(level._effect["predator2"], self.origin);
	playfx(level._effect["predator2"], self.ppos);
	self._predator playsound("predator_boom");
	

	players=getentarray("player","classname");
	for(p=0;p<players.size;p++)
	{
		if(players[p].pers["team"]!=self.pers["team"] && isAlive(players[p]))
		{
			if(distance(self._predator.origin,players[p].origin)<400)
			{
				earthquake(2,3, self._predator.origin, 400);
				players[p] FinishPlayerDamage(players[p], self, 3500, 0, "MOD_RIFLE_BULLET", "predator_mp", self._predator.origin, vectornormalize(players[p].origin - self._predator.origin ), "none",0);
			}
		}
	}
	self.inv=false;
	self thread predator_killed();
}
predator_ang()
{
self endon("disconnect");
self endon("killed_player");
self endon("predator_end");
	for(;;)
	{
		mennyi=30;
		if(self getPlayerAngles()[0]<mennyi)
			self setplayerangles((mennyi,self.angles[1],self.angles[2]));

		wait 0.05;
	}
}
predator_move()
{
self endon("disconnect");
self endon("killed_player");
self endon("predator_end");
self endon("predator_go");
	for(;;)
	{
		vec=anglestoforward(self getplayerangles());
		trace=bullettrace(self geteye()+(0,0,18),self geteye()+(20000*vec[0],20000*vec[1],20000*vec[2]+18),true,self);
		time=bombspeed(400, self.origin, trace["position"]);
		self._predator moveto(trace["position"],time);
		wait 0.05;
	}
}
predator_act()
{
self endon("disconnect");
self endon("killed_player");
self endon("predator_end");
	if(isDefined(level.predator_act))
	{
		self iprintlnbold("^1Go Go Go!!!!!xD");
		return;
	}
	for(;;)
	{
		self._predator.angles=self getplayerangles();
		if(self attackbuttonpressed() && isalive(self))
		{
			self notify("predator_go");
			self.hud_predator_timer destroy();
			self playsound("predator_fire");
			earthquake(1,1, self.origin, 80);
			vec=anglestoforward(self getplayerangles());
			trace=bullettrace(self geteye()+(0,0,18),self geteye()+(20000*vec[0],20000*vec[1],20000*vec[2]+18),true,self);

			self._predator.angles=self getplayerangles();

			time=bombspeed(1000, self.origin, trace["position"]);

			self._predator moveto(trace["position"],time,time/1.5,0);
			wait time;
			if(isDefined(trace["surfacetype"]) && trace["surfacetype"] == "water")
			{
				playfx(level._effect["water_big"],trace["position"]);
				self._predator playsound("rocket_explode_water");
			}
			else
			{
				playfx(level._effect["predator2"],trace["position"]);
				self._predator playsound("predator_boom");
			}
			earthquake(2,3, trace["position"], 400);
			players=getentarray("player","classname");
			for(p=0;p<players.size;p++)
			{
				if(players[p].pers["team"]!= self.pers["team"] && isAlive(players[p]))
				{
					if(distance(trace["position"],players[p].origin)<400)
					{
						players[p] FinishPlayerDamage(players[p], self, 150, 0, "MOD_RIFLE_BULLET", "predator_mp", players[p].origin, (0,0,0), "none",0);
					}
				}
			}
			self.inv=false;
			self thread predator_picture();
			wait 1;
			self thread predator_killed();
			wait 2;
		}
	wait 0.05;
	}
}
bombspeed(speed, origin1, origin2)
{
	dist = distance(origin1, origin2);
	time = (dist / speed);
	return time;	
}
predator_killed()
{
self endon("disconnect");
self endon("killed_player");
self endon("predator_end");
if(self.predator_act==1)
{
if(isAlive(self))
	self setorigin(self.ppos);
	
self unlink();
self._predator stoploopsound();
self.predator_px_1 destroy();
self.predator_px_2.alpha = 0;
self.predator_px_1.alpha = 0;
self.predator_px_2 destroy();
self show();
self.last_time_used_predator = gettime();
self._predator delete();
self.hud_predator destroy();
self.hud_predator_timer destroy();
self enableweapon();
self.predator_act=0;
self.ac130_act=0;
self.airstrike_act=0;
self notify("predator_end");
}
}

predator_picture()
{
	if (isDefined(self.predator_px_1))
		self.predator_px_1 destroy();
		
	if (isDefined(self.predator_px_2))
		self.predator_px_2 destroy();

	self.predator_px_1 = newClientHudElem(self);
	self.predator_px_1 setShader("pixels", 640, 480);
	self.predator_px_1.alpha = 1;
	self.predator_px_2.horzAlign = "fullscreen";
	self.predator_px_2.vertAlign = "fullscreen";
	self.predator_px_1.x = 0;
	self.predator_px_1.y = 0;
	
	self.predator_px_2 = newClientHudElem(self);
	self.predator_px_2 setShader("pixels1", 640, 480);
	self.predator_px_2.alpha = 1;
	self.predator_px_2.horzAlign = "fullscreen";
	self.predator_px_2.vertAlign = "fullscreen";
	self.predator_px_2.x = 0;
	self.predator_px_2.y = 0;
	
	
	wait 0.1;
	self._predator stoploopsound();
	self.predator_px_1.x += 100;
	wait 0.1;
	self.predator_px_1.x -= 100;
	wait 0.1;
	self.predator_px_2.y += 100;
	wait 0.1;
	self.predator_px_2.y -= 100;
	wait 0.1;
	self.predator_px_1.x += 100;
	wait 0.1;
	self.predator_px_1.x -= 100;
	wait 0.1;
	self.predator_px_2.y += 100;
	wait 0.1;
	self.predator_px_2.y -= 100;
