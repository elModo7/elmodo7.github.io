#include extreme\_ex_weapons;

main()
{
	self endon("kill_thread");

	// Abort if modern weapons enabled
	if(level.ex_modern_weapons) return;

	// Do not check the allow status for flamethrowers if weapon limiter enabled.
	// It will stop all flamethrowers to function properly when the limit is reached
	if(!level.ex_wepo_limiter && !level.weapons["flamethrower_axis"].allow && !level.weapons["flamethrower_allies"].allow) return;

	self thread monitorFlamethrower();
}

monitorFlamethrower()
{
	self endon("kill_thread");

	flames = [];
	flame_range = level.ex_ft_range; // effective range of flamethrower in cod units
	flames_max = 20;   // Maximum number of array elements (= spawned flames)
	flame_life = 1;    // Every flame entity lives one second
	flame_damage = 20; // Damage per flame (remember: several flames hit the target p/sec)
	flame_damage_radius = 100;

	flame_index = 0;
	flames_alloc = 10; // Number of array elements pre-allocated
	for(i = 1; i <= flames_alloc; i++)
	{
		flames[i] = spawnstruct();
		flames[i].allocated = false;
		flames[i].flame = undefined;
	}

	self.tankonback = undefined;

	while(true)
	{
		wait( [[level.ex_fpstime]](0.1) );

		sWeapon = self getCurrentWeapon();

		// Check if player is (still) carrying a flamethrower (any slot)
		weapon1 = self.pers["weapon"];
		if(level.ex_wepo_secondary) weapon2 = self.pers["weapon2"];
			else weapon2 = "none";

		if(isFlamethrower(weapon1) || isFlamethrower(weapon2))
		{
			// Flamethrower found: attach the gas tank to the back if not attached already
			if(!isDefined(self.tankonback))
			{
				// Detach current weapon on back
				if(isDefined(self.weapononback))
				{
					if(checkAttached(self.weapononback)) self detach("xmodel/" + self.weapononback, "");
					self.weapononback = undefined;
				}
				self.tankonback = "ft_tank";
				if(!checkAttached(self.tankonback)) self attach("xmodel/" + self.tankonback, "j_spine4");
			}
		}
		else
		{
			// No flamethrower (anymore): detach the tank if attached
			if(isDefined(self.tankonback))
			{
				if(checkAttached(self.tankonback)) self detach("xmodel/" + self.tankonback, "j_spine4");
				self.tankonback = undefined;
			}
		}

		flame_index = 0;
		flame_refused = 0;
		
		while(self attackbuttonpressed() && isFlamethrower(sWeapon))
		{
			wait( [[level.ex_fpstime]](0.1) );

			// Check if player is on turret
			if(isdefined(self.onturret)) continue;

			// Check distance to object in front of player. Too close = no flame
			trace = self GetEyeTrace(1000);
			trace_dist = distance(trace["position"], self.origin);
			if(trace_dist < 100)
			{
				flame_refused++;
				if(flame_refused == 1 || flame_refused%5 == 0) self playsound("ft_refuse");
				continue;
			}
			else flame_refused = 0;

			// Next flame. Check if it has an allocated array element
			flame_index++;
			if(flame_index > flames_alloc)
			{
				// If first flame is still alive, expand array if within limits
				if(flames[1].allocated && flames_alloc <= flames_max)
				{
					flames_alloc++;
					flames[flames_alloc] = spawnstruct();
					flames[flames_alloc].allocated = false;
					flames[flames_alloc].flame = undefined;
					//logprint("FLAMETHROWER DEBUG: flame array for player " + self.name + " increased to " + flames_alloc +".\n");
				}
				else flame_index = 1;
			}
			// Did we cycle a full array?
			if(flames[flame_index].allocated) continue;

			// Play flamethrower sound on 1st and every 5th flame
			if(flame_index == 1 || flame_index%5 == 0) self playsound("ft_fire");

			// Now get a target
			trace_entity = self;
			// Unfortunately not supported in MP: flame_start = self gettagorigin("tag_flash");
			flame_start = self getTargetedPos(65);
			flame_target = GetTargetedPos(flame_range);

			trace = bulletTrace(flame_start, flame_target, true, undefined);
			if(trace["fraction"] != 1 && isDefined(trace["entity"]))
			{
				trace_entity = trace["entity"];
				flame_target = trace_entity.origin;
			}
			else
			{
				trace = bulletTrace(flame_start, flame_target, false, undefined);
				if(trace["fraction"] != 1 && trace["surfacetype"] != "default")
					flame_target = trace["position"];
			}

			if(!isDefined(flame_target))
				flame_target = GetTargetedPos(flame_range);

			// Limit how many times a flame may duplicate itself while traveling
			trace_dist = distance(flame_start, flame_target);
			if(trace_dist == 0) trace_dist = 1;
			flame_loop = (flame_range / trace_dist) * 0.05;

			// Play impact and decal fx only on 10th flame (long distance shot). Play normal fx for other flames
			flame_fx = 0;
			if(flame_index%10 == 0) flame_fx = 1;

			flames[flame_index].allocated = true;
			flames[flame_index].flame = spawn("script_model", flame_start);
			flames[flame_index].flame setModel("xmodel/weapon_knife"); // Substitution model (always precached)
			flames[flame_index].flame.angles = self.angles;
			flames[flame_index].flame hide();
			flames[flame_index].flame thread showFlame(flames[flame_index], flame_fx, flame_loop, flame_target, flame_life);

			players = level.players;
			for(i = 0; i < players.size; i++)
			{
				player = players[i];
					
				// Skip self
				if(player == self) continue;

				// Skip dead players, spectators and spawn protected players
				if(!isAlive(player) || player.sessionteam == "spectator" || player.ex_invulnerable) continue;

				// Respect friendly fire settings 0 (off) and 2 (reflect; it doesn't damage the attacker though)
				if(level.ex_teamplay && (level.friendlyfire == "0" || level.friendlyfire == "2"))
					if(player.pers["team"] == self.pers["team"]) continue;

				// If player is targeted and hit, set fixed damage and long burntime
				if(trace_entity == player)
				{
					iDamage = flame_damage;
					iBurntime = 10;
				}
				else
				{
					// Skip if player is not near flame target
					trace_dist = distance(flame_target, player.origin);
					if( !isAlive(player) || player.sessionstate != "playing" || trace_dist >= flame_damage_radius ) continue;

					// Check if free path between flame target and player
					trace = bullettrace(flame_target, player.origin, true, undefined);
					if(trace["fraction"] != 1 && isDefined(trace["entity"]) && trace["entity"] == player)
					{
						// Calculate damage and burntime (depending on distance)
						iDamage = int(flame_damage * (1 - (trace_dist / flame_damage_radius)));
						if(trace_dist <= (flame_damage_radius / 2)) iBurntime = 6;
							else iBurntime = 3;
					}
					else continue;
				}

				// If player is already on fire, damage depends on flame index
				if(isDefined(player.ex_isonfire))
					iDamage = int(iDamage * (flame_index / 10));

				// Burn and damage the player
				if(iDamage < player.health)
				{

					player.health = player.health - iDamage;
					player thread burnPlayer(self, sWeapon, iBurntime);
				}
				else
					player thread [[level.callbackPlayerDamage]](self, self, iDamage, 1, "MOD_PROJECTILE", sWeapon, undefined, (0,0,1), "none", 0);
			}

			// Check if still holding the flamethrower
			sWeapon = self getCurrentWeapon();
		}
	}
}

showFlame(flame_pointer, flame_fx, flame_loop, flame_target, flame_life)
{
	self thread playFlameFX(flame_fx, flame_loop);

	self moveto(flame_target, flame_life);

	wait( [[level.ex_fpstime]](flame_life) );
	self delete();
	if(isDefined(flame_pointer)) flame_pointer.allocated = false;
}

playFlameFX(flame_fx, loopTime)
{
	fxName = level.ex_effect["ft_fire0"]; // fx without impact and decal

	count = 0;
	while(isDefined(self))
	{
		playfx(fxName, self.origin);
		wait( [[level.ex_fpstime]](loopTime) );
		count++;
		if(flame_fx && count == 10)
			fxName = level.ex_effect["ft_fire1"]; // fx with impact and decal
	}
}

getEyeTrace(num)
{
	self endon("kill_thread");

	startOrigin = self getEye() + self getPlayerEyeOffset();
	forward = anglesToForward(self getplayerangles());
	forward = (forward[0] * num, forward[1] * num, forward[2] * num);
	endOrigin = startOrigin + forward;
	trace = bulletTrace(startOrigin, endOrigin, false, undefined);

	return trace;
}

getTargetedPos(num)
{
	self endon("kill_thread");

	startOrigin = self getEye() + self getPlayerEyeOffset();
	forward = anglesToForward(self getplayerangles());
	forward = (forward[0] * num, forward[1] * num, forward[2] * num);
	endOrigin = startOrigin + forward;

	return endOrigin;
}

getPlayerEyeOffset()
{
	self endon("kill_thread");

	offset = (0,0,16); // Stand
	if(self.ex_stance == 1) offset = (0,0,2);   // Crouch
	if(self.ex_stance == 2) offset = (0,0,-27); // Prone

	return offset;
}

burnPlayer(eAttacker, sWeapon, burntime)
{
	self endon("kill_thread");

	if(isDefined(self.ex_isonfire)) return;
	self.ex_isonfire = 1;

	wait( [[level.ex_fpstime]](0.5) );
	if(randomint(100) > 10) self playsound("scream"); // 90% chance they scream

	if(!isDefined(self.pers["diana"])) tag = "j_spine1";
		else tag = "j_spine2";
	burntime = burntime * 4; // loop is quarter of a second, so x4 to convert to seconds

	for(i = 0; i < burntime; i++)
	{
		// For every second on fire, player will lose some health
		if(burntime%4 == 0)
		{
			iDamage = 5;
			if(iDamage < self.health)
				self.health = self.health - iDamage;
			else
				self thread [[level.callbackPlayerDamage]](eAttacker, eAttacker, iDamage, 1, "MOD_PROJECTILE", sWeapon, undefined, (0,0,1), "none", 0);
		}

		switch(randomint(13))
		{
			case 0: tag = "j_hip_le"; break;
			case 1: tag = "j_hip_ri"; break;
			case 2: tag = "j_knee_le"; break;
			case 3: tag = "j_ankle_ri"; break;
			case 4: tag = "j_knee_ri"; break;
			case 5:
				if(!isDefined(self.pers["diana"])) tag = "j_spine1";
					else tag = "j_spine2";
				break;
			case 6: tag = "j_wrist_ri"; break;
			case 7: tag = "j_head"; break;
			case 8: tag = "j_shoulder_le"; break;
			case 9: tag = "j_shoulder_ri"; break;
			case 10:tag = "j_elbow_le"; break;
			case 11: tag = "j_elbow_ri"; break;
			case 12: tag = "j_wrist_le"; break;
		}

		if(burntime == 4)
		{
			if(isDefined(self))
				self thread playBurnFX(tag, level.ex_effect["playerburn2"], .1);
		}
		else
		{
			if(isDefined(self))
			{
				playfxontag(level.ex_effect["playerburn2"], self, tag);
				if(!isDefined(self.pers["diana"])) playfxontag(level.ex_effect["playerburn"], self, "j_spine1");
					else playfxontag(level.ex_effect["playerburn"], self, "j_spine2");
			}
		}

		wait( [[level.ex_fpstime]](0.25) );
	}

	if(isAlive(self))
		self.ex_isonfire = undefined;
}

playBurnFX(tag, fxName, loopTime)
{
	self endon("kill_thread");

	while(isdefined(self) && isDefined(self.ex_isonfire))
	{
		playfxOnTag(fxName, self, tag);
		wait( [[level.ex_fpstime]](loopTime) );
	}
}

isFlamethrower(weapon)
{
	if(!isDefined(weapon)) return false;

	switch(weapon)
	{
		case "flamethrower_axis":
		case "flamethrower_allies": return true;
	}

	return false;
}

checkAttached(model)
{
	self endon("kill_thread");

	model_attached = false;
	model_full = "xmodel/" + model;

	attachedSize = self getAttachSize();
	for(i = 0; i < attachedSize; i++)
	{
		attachedModel = self getAttachModelName(i);
		if(attachedModel == model_full)
		{
			model_attached = true;
			break;
		}
	}

	return(model_attached);
}

tankExplosion(eVictim, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime)
{
	if(isDefined(eVictim.tankonback))
	{
		eVictim detach("xmodel/ft_tank", "j_spine4");
		eVictim.tankonback = undefined;

		explosion = spawn("script_origin", eVictim.origin);
		playfx(level.ex_effect["artillery"], explosion.origin);
		explosion playSound("artillery_explosion");
		eVictim [[level.ex_callbackPlayerDamage]](eAttacker, eAttacker, 100, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, psOffsetTime);
		explosion delete();
	}
}
