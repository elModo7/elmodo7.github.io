main(allowed)
{
	entitytypes = getentarray();
	turretorigins = [];
	for(i = 0; i < entitytypes.size; i++)
	{
		if(isdefined(entitytypes[i].script_gameobjectname))
		{
			dodelete = true;
			for(j = 0; j < allowed.size; j++)
			{
				if(entitytypes[i].script_gameobjectname == allowed[j])
				{	
					dodelete = false;
					break;
				}
			}

			// Keep spawnpoints for flags, radios and bombzones when in "showall" designer mode
			if(dodelete && level.ex_designer && level.ex_designer_showall)
			{
				if(isDefined(entitytypes[i].targetname) &&
					(entitytypes[i].targetname == "allied_flag" ||
					 entitytypes[i].targetname == "axis_flag" ||
					 entitytypes[i].targetname == "bombzone" ||
					 entitytypes[i].targetname == "hqradio")) dodelete = false;
			}

			// Keep all turrets on the map, but avoid multiple turrets at same origin
			if(isdefined(entitytypes[i].classname) && (entitytypes[i].classname == "misc_turret" || entitytypes[i].classname == "misc_mg42"))
			{
				newturret = true;
				for(j = 0; j < turretorigins.size; j++)
				{
					dist = distance(entitytypes[i].origin, turretorigins[j]);
					if(dist < 100)
					{
						newturret = false;
						break;
					}
				}
				
				if(newturret)
				{
					turretorigins[turretorigins.size] = entitytypes[i].origin;
					dodelete = false;
				}
				else dodelete = true;
			}

			if(dodelete) entitytypes[i] delete();
		}
	}
}
