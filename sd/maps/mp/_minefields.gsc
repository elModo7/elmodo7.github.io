minefields()
{
	if(!level.ex_minefields) return;
	
	minefields = getentarray("minefield", "targetname");
	if(minefields.size > 0)
	{
		if(level.ex_minefields == 1) level._effect["mine_explosion"] = loadfx("fx/explosions/grenadeExp_dirt.efx");
			else if(level.ex_minefields == 2) level._effect["mine_explosion"] = loadfx("fx/smoke/orange_smoke_20sec.efx");
				else if(level.ex_minefields == 3) level._effect["mine_explosion"] = loadfx("fx/extreme_napalm/napalm.efx");
	}
	
	for(i = 0; i < minefields.size; i++)
	{
		minefields[i] thread minefield_think();
	}	
}

minefield_think()
{
	while(1)
	{
		self waittill("trigger", other);

		if(isPlayer(other))
		{
			if(isDefined(other.ex_isparachuting)) continue;
			if( (level.ex_gunship && isDefined(level.ex_gunship_player) && level.ex_gunship_player == other) ||
			    (level.ex_gunship_special && isDefined(level.ex_gunship_splayer) && level.ex_gunship_splayer == other) ) continue;

			other thread minefield_kill(self);
		}
	}
}

minefield_kill(trigger)
{
	if(isDefined(self.minefield))
		return;

	self.ex_invulnerable = false;
	self.minefield = true;
	self playsound("minefield_click");

	if(!level.ex_minefields_instant)
	{
		wait( [[level.ex_fpstime]](0.5) );
		wait( [[level.ex_fpstime]](randomFloat(0.5)) );
	}

	if(isdefined(self) && self istouching(trigger))
	{
		origin = self getorigin();
		
		range = 300;
		mindamage = 50;
		maxdamage = 2000;
		self playsound("explo_mine");

		if(level.ex_minefields == 2)
		{
			range = 200;
			mindamage = level.ex_gasmine_min;
			maxdamage = level.ex_gasmine_max;
			self playsound("smokegrenade_explode_default");
		}

		if(level.ex_minefields == 3)
		{
			range = 300;
			mindamage = level.ex_napalmmine_min;
			maxdamage = level.ex_napalmmine_max;
			self playsound("Nebelwerfer_fire");
		}
		
		playfx(level._effect["mine_explosion"], origin);
		extreme\_ex_utils::scriptedfxradiusdamage(self, undefined, "MOD_EXPLOSIVE", "minefield", range, maxdamage, mindamage, "none", undefined, false);
	}
	
	self.minefield = undefined;
}
