// selects a spawnpoint, preferring ones with heigher weights (or toward the beginning of the array if no weights).
// also does final things like setting self.lastspawnpoint to the one chosen.
// this takes care of avoiding telefragging, so it doesn't have to be considered by any other function.
getSpawnpoint_Final(spawnpoints, weights)
{
	bestspawnpoint = undefined;
	
	if(!isdefined(spawnpoints) || spawnpoints.size == 0) return undefined;
	
	if(isdefined(weights) && weights.size == spawnpoints.size)
	{
		// choose spawnpoint with best weight
		// (if a tie, choose randomly from the best)
		bestspawnpoints = [];
		bestweight = undefined;
		for(i = 0; i < spawnpoints.size; i++)
		{
			if(positionWouldTelefrag(spawnpoints[i].origin)) continue;
	
			if(!isdefined(bestweight) || weights[i] > bestweight)
			{
				bestspawnpoints = [];
				bestspawnpoints[0] = spawnpoints[i];
				bestweight = weights[i];
			}
			else if(weights[i] == bestweight)
			{
				bestspawnpoints[bestspawnpoints.size] = spawnpoints[i];
			}
		}
		if(bestspawnpoints.size > 0)
		{
			// pick randomly from the available spawnpoints with the best weight
			bestspawnpoint = bestspawnpoints[randomint(bestspawnpoints.size)];
		}
	}
	else
	{
		// (only place we actually get here from is getSpawnpoint_Random() )
		// no weights. prefer spawnpoints toward beginning of array
		for(i = 0; i < spawnpoints.size; i++)
		{
			if(positionWouldTelefrag(spawnpoints[i].origin)) continue;
			if(isdefined(self.lastspawnpoint) && self.lastspawnpoint == spawnpoints[i]) continue;
			
			bestspawnpoint = spawnpoints[i];
			break;
		}
		if(!isdefined(bestspawnpoint))
		{
			// Couldn't find a useable spawnpoint. All spawnpoints either telefragged or were our last spawnpoint
			// Our only hope is our last spawnpoint - unless it too will telefrag...
			if(isdefined(self.lastspawnpoint) && !positionWouldTelefrag(self.lastspawnpoint.origin))
			{
				// (make sure our last spawnpoint is in the valid array of spawnpoints to use)
				for(i = 0; i < spawnpoints.size; i++)
				{
					if(spawnpoints[i] == self.lastspawnpoint)
					{
						bestspawnpoint = spawnpoints[i];
						break;
					}
				}
			}
		}
	}

	if(!isdefined(bestspawnpoint))
	{
		// couldn't find a useable spawnpoint! all will telefrag.
		if(isdefined(weights))
		{
			// at this point, forget about weights. just take a random one.
			bestspawnpoint = spawnpoints[randomint(spawnpoints.size)];
		}
		else bestspawnpoint = spawnpoints[0];
	}
	
	time = getTime();
	
	self.lastspawnpoint = bestspawnpoint;
	self.lastspawntime = time;
	bestspawnpoint.lastspawnedplayer = self;
	bestspawnpoint.lastspawntime = time;
	return bestspawnpoint;
}

getSpawnpoint_Random(spawnpoints)
{
	// There are no valid spawnpoints in the map
	if(!isdefined(spawnpoints)) return undefined;

	// If available, append spawnpoints added by script _ex_spawnpoints.gsc
	if(isDefined(level.ex_spawnpoints))
	{
		for(i = 0; i < level.ex_spawnpoints.size; i++)
			spawnpoints[spawnpoints.size] = level.ex_spawnpoints[i];
	}

	// randomize order
	for(i = 0; i < spawnpoints.size; i++)
	{
		j = randomInt(spawnpoints.size);
		spawnpoint = spawnpoints[i];
		spawnpoints[i] = spawnpoints[j];
		spawnpoints[j] = spawnpoint;
	}
	
	return getSpawnpoint_Final(spawnpoints);
}

getAllOtherPlayers()
{
	aliveplayers = [];

	// Make a list of fully connected, non-spectating, alive players
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(player.sessionstate == "spectator" || player.sessionstate == "dead" || player == self) continue;
		aliveplayers = add_to_array(aliveplayers, player);
	}
	return aliveplayers;
}

// gets an array of living players allied with self (assumes team-based game!)
getAllAlliedPlayers()
{
	livingallies = [];
	
	// Make a list of fully connected, non-spectating, alive players
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(player.sessionstate == "spectator" || player.sessionstate == "dead" || player == self) continue;
		if(player.pers["team"] == self.pers["team"]) livingallies = add_to_array(livingallies, player);
	}
	return livingallies;
}

// gets an array of living players that are enemies (assumes team-based game!)
getAllEnemyPlayers()
{
	livingenemies = [];
	
	// Make a list of fully connected, non-spectating, alive players
	players = level.players;
	for(i = 0; i < players.size; i++)
	{
		player = players[i];
		if(player.sessionstate == "spectator" || player.sessionstate == "dead" || player == self) continue;
		if(player.pers["team"] != self.pers["team"]) livingenemies = add_to_array(livingenemies, player);
	}
	return livingenemies;
}

// weight array manipulation code
initWeights(spawnpoints)
{
	weights = [];
	for(i = 0; i < spawnpoints.size; i++) weights[i] = 0;
	return weights;
}

//==============================================================================

getSpawnpoint_NearTeam(spawnpoints)
{
	// There are no valid spawnpoints in the map
	if(!isdefined(spawnpoints)) return undefined;
	
	// If available, append spawnpoints added by script _ex_spawnpoints.gsc
	if(isDefined(level.ex_spawnpoints))
	{
		for(i = 0; i < level.ex_spawnpoints.size; i++)
			spawnpoints[spawnpoints.size] = level.ex_spawnpoints[i];
	}

	Spawnlogic_Init();
	
	weights = initWeights(spawnpoints);
	
	allies = getAllAlliedPlayers();
	enemies = getAllEnemyPlayers();
	numplayers = allies.size + enemies.size;
	
	if(numplayers > 0)
	{
		for(i = 0; i < spawnpoints.size; i++)
		{
			allyDistSum = 0;
			enemyDistSum = 0;
			for(j = 0; j < allies.size; j++)
			{
				dist = distance(spawnpoints[i].origin, allies[j].origin);
				allyDistSum += dist;
			}
			for(j = 0; j < enemies.size; j++)
			{
				dist = distance(spawnpoints[i].origin, enemies[j].origin);
				enemyDistSum += dist;
			}
			
			weights[i] = (enemyDistSum - 2*allyDistSum) / numplayers; // high enemy distance is good, high ally distance is bad
		}
	}
	
	weights = avoidSameSpawn(spawnpoints, weights);
	// retaining old logic for tdm to keep the fast pace
	if(getcvar("g_gametype") != "tdm")
	{
		weights = avoidSpawnReuse(spawnpoints, weights, true);
		weights = avoidDangerousSpawns(spawnpoints, weights, true);
	}
	
	return getSpawnpoint_Final(spawnpoints, weights);
}

//==============================================================================

getSpawnpoint_NearTeam_Unfrozen(spawnpoints)
{
	// There are no valid spawnpoints in the map
	if(!isdefined(spawnpoints)) return undefined;

	// If available, append spawnpoints added by script _ex_spawnpoints.gsc
	if(isDefined(level.ex_spawnpoints))
	{
		for(i = 0; i < level.ex_spawnpoints.size; i++)
			spawnpoints[spawnpoints.size] = level.ex_spawnpoints[i];
	}

	Spawnlogic_Init();

	weights = initWeights(spawnpoints);

	allies = getAllAlliedPlayers();
	enemies = getAllEnemyPlayers();
	numplayers = allies.size + enemies.size;

	if(numplayers > 0)
	{
		for(i = 0; i < spawnpoints.size; i++)
		{
			allyDistSum = 0;
			enemyDistSum = 0;
			for(j = 0; j < allies.size; j++)
			{
				dist = distance(spawnpoints[i].origin, allies[j].origin);
				if(isDefined(allies[j].frozenstate) && allies[j].frozenstate == "frozen") dist += 5000;
				allyDistSum += dist;
			}
			for(j = 0; j < enemies.size; j++)
			{
				dist = distance(spawnpoints[i].origin, enemies[j].origin);
				enemyDistSum += dist;
			}

			weights[i] = (enemyDistSum - 2*allyDistSum) / numplayers; // high enemy distance is good, high ally distance is bad
		}
	}

	weights = avoidSameSpawn(spawnpoints, weights);
	// retaining old logic for tdm to keep the fast pace
	if(getcvar("g_gametype") != "tdm")
	{
		weights = avoidSpawnReuse(spawnpoints, weights, true);
		weights = avoidDangerousSpawns(spawnpoints, weights, true);
	}

	return getSpawnpoint_Final(spawnpoints, weights);
}

//==============================================================================

getSpawnpoint_DM(spawnpoints)
{
//	level endon("intermission");

	// There are no valid spawnpoints in the map
	if(!isdefined(spawnpoints)) return undefined;

	// If available, append spawnpoints added by script _ex_spawnpoints.gsc
	if(isDefined(level.ex_spawnpoints))
	{
		for(i = 0; i < level.ex_spawnpoints.size; i++)
			spawnpoints[spawnpoints.size] = level.ex_spawnpoints[i];
	}

	Spawnlogic_Init();

	weights = initWeights(spawnpoints);
	
	aliveplayers = getAllOtherPlayers();
	
	// new logic: we want most players near idealDist units away.
	// players closer than badDist units will be considered negatively
	idealDist = 1600;
	badDist = 1200;
	
	if(aliveplayers.size > 0)
	{
		for(i = 0; i < spawnpoints.size; i++)
		{
			totalDistFromIdeal = 0;
			nearbyBadAmount = 0;
			for(j = 0; j < aliveplayers.size; j++)
			{
				dist = distance(spawnpoints[i].origin, aliveplayers[j].origin);
				
				if(dist < badDist) nearbyBadAmount += (badDist - dist) / badDist;

				distfromideal = maps\mp\_utility::abs(dist - idealDist);
				totalDistFromIdeal += distfromideal;
			}
			avgDistFromIdeal = totalDistFromIdeal / aliveplayers.size;
			
			wellDistancedAmount = (idealDist - avgDistFromIdeal) / idealDist;
			// if(wellDistancedAmount < 0) wellDistancedAmount = 0;
			
			// wellDistancedAmount is between -inf and 1, 1 being best (likely around 0 to 1)
			// nearbyBadAmount is between 0 and inf,
			// and it is very important that we get a bad weight if we have a high nearbyBadAmount.
			
			weights[i] = wellDistancedAmount - nearbyBadAmount * 2 + randomfloat(.2);
		}
	}
	
	weights = avoidSameSpawn(spawnpoints, weights);
	weights = avoidSpawnReuse(spawnpoints, weights, false);
	weights = avoidDangerousSpawns(spawnpoints, weights, false);
	
	return getSpawnpoint_Final(spawnpoints, weights);
}

//==============================================================================

getSpawnpoint_NearTeam_AwayfromRadios(spawnpoints)
{
	// There are no valid spawnpoints in the map
	if(!isdefined(spawnpoints)) return undefined;

	// If available, append spawnpoints added by script _ex_spawnpoints.gsc
	if(isDefined(level.ex_spawnpoints))
	{
		for(i = 0; i < level.ex_spawnpoints.size; i++)
			spawnpoints[spawnpoints.size] = level.ex_spawnpoints[i];
	}

	Spawnlogic_Init();

	weights = initWeights(spawnpoints);
	
	allies = getAllAlliedPlayers();
	enemies = getAllEnemyPlayers();
	numplayers = allies.size + enemies.size;
	
	if(level.captured_radios[self.pers["team"]] > 0) alliedBias = .5;
		else alliedBias = 1.6;

	for(i = 0; i < spawnpoints.size; i++)
	{
		nearbyEnemy = false;
		nearbyRadio = false;
		
		allyDistSum = 0;
		enemyDistSum = 0;
		for(j = 0; j < allies.size; j++)
		{
			dist = distance(spawnpoints[i].origin, allies[j].origin);
			allyDistSum += dist;
		}
		for(j = 0; j < enemies.size; j++)
		{
			dist = distance(spawnpoints[i].origin, enemies[j].origin);
			if(dist < 850) nearbyEnemy = true;
			enemyDistSum += dist;
		}
	
		if(isDefined(level.radio))
		{
			for(j = 0; j < level.radio.size; j++)
			{
				if(!isDefined(level.radio[j].hidden) || level.radio[j].hidden == true) continue;
				if(!isDefined(level.radio[j].team) || level.radio[j].team == "none") continue;

				// If the radio is within 700 units of an attacker, the attacker should not spawn there
				if(level.radio[j].team != self.pers["team"])
				{
					dist = (distance(spawnpoints[i].origin, level.radio[j].origin));
					if(dist <= 700)
					{
						nearbyRadio = true;
						break;
					}
				}
			}
		}
		
		// enemy distance is good, allied distance is bad (how much depends on whether we have the radio or not)
		if(numplayers > 0) weights[i] = (enemyDistSum*.8 - allyDistSum*alliedBias) / numplayers;
		if(nearbyEnemy) weights[i] -= 20000;
		if(nearbyRadio) weights[i] -= 20000;
	}
	
	weights = avoidSameSpawn(spawnpoints, weights);
	weights = avoidSpawnReuse(spawnpoints, weights, true);
	weights = avoidDangerousSpawns(spawnpoints, weights, true);
	
	return getSpawnpoint_Final(spawnpoints, weights);
}

//==============================================================================

Spawnlogic_Init()
{
	if(isdefined(level.spawnlogic_inited))
	{
		updateDeathInfo();
		return;
	}
	level.spawnlogic_inited = true;
	
	// start keeping track of deaths
	level.spawnlogic_deaths = [];
	
	// we need the playerkilled callback, but the gametype is already making use of it.
	// set up our own callback inbetween.
	level.spawnlogic_oldCallbackPlayerKilled = level.callbackPlayerKilled;
	level.callbackPlayerKilled = ::spawnlogic_callbackPlayerKilled;
}

spawnlogic_callbackPlayerKilled(eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration)
{
	deathOccured(self, attacker);
	
	// call the usual callback.
	[[level.spawnlogic_oldCallbackPlayerKilled]](eInflictor, attacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, psOffsetTime, deathAnimDuration);
}

deathOccured(dier, killer)
{
	if(!isdefined(killer) || !isdefined(dier) || !isplayer(killer) || !isplayer(dier) || killer == dier) return;
	
	time = getTime();
	
	// record kill information
	deathInfo = spawnstruct();
	
	deathInfo.time = time;
	deathInfo.org = dier.origin;
	deathInfo.killOrg = killer.origin;
	deathInfo.killer = killer;
	
	checkForSimilarDeaths(deathInfo);
	level.spawnlogic_deaths[level.spawnlogic_deaths.size] = deathInfo;
	
	// keep track of the most dangerous players in terms of how far they have killed people recently
	dist = distance(dier.origin, killer.origin);
	if(!isdefined(killer.spawnlogic_killdist) || time - killer.spawnlogic_killtime > 1000*30 || dist > killer.spawnlogic_killdist)
	{
		killer.spawnlogic_killdist = dist;
		killer.spawnlogic_killtime = time;
	}
}

checkForSimilarDeaths(deathInfo)
{
	// check if this is really similar to any old deaths, and if so, mark them for removal later
	for(i = 0; i < level.spawnlogic_deaths.size; i++)
	{
		if(level.spawnlogic_deaths[i].killer == deathInfo.killer)
		{
			dist = distance(level.spawnlogic_deaths[i].org, deathInfo.org);
			if(dist > 200) continue;
			dist = distance(level.spawnlogic_deaths[i].killOrg, deathInfo.killOrg);
			if(dist > 200) continue;
			
			level.spawnlogic_deaths[i].remove = true;
		}
	}
}

updateDeathInfo()
{
	time = getTime();
	for(i = 0; i < level.spawnlogic_deaths.size; i++)
	{
		// if the killer has walked away or enough time has passed, get rid of this death information
		deathInfo = level.spawnlogic_deaths[i];
		
		if(time - deathInfo.time > 1000*90 || // if 90 seconds have passed
			!isdefined(deathInfo.killer) ||
			!isalive(deathInfo.killer) ||
			(deathInfo.killer.pers["team"] != "axis" && deathInfo.killer.pers["team"] != "allies") ||
			distance(deathInfo.killer.origin, deathInfo.killOrg) > 400) level.spawnlogic_deaths[i].remove = true;
	}
	
	// remove all deaths with remove set
	oldarray = level.spawnlogic_deaths;
	level.spawnlogic_deaths = [];
	
	// never keep more than the 1024 most recent entries in the array
	start = 0;
	if(oldarray.size - 1024 > 0) start = oldarray.size - 1024;
	
	for(i = start; i < oldarray.size; i++)
	{
		if(!isdefined(oldarray[i].remove))
			level.spawnlogic_deaths[level.spawnlogic_deaths.size] = oldarray[i];
	}
}

// uses death information to reduce the weights of spawns that might cause spawn kills
avoidDangerousSpawns(spawnpoints, weights, teambased) // (assign weights to the return value of this)
{
	if(getcvar("scr_spawnpointnewlogic") == "0") return weights;

	didSightChecks = [];
	
	maxDist = 400;
	maxDistSquared = maxDist*maxDist;
	for(i = 0; i < spawnpoints.size; i++)
	{
		didSightChecks[i] = false;
		for(d = 0; d < level.spawnlogic_deaths.size; d++)
		{
			// (we've got a lotta checks to do, want to rule them out quickly)
			distSqrd = distanceSquared(spawnpoints[i].origin, level.spawnlogic_deaths[d].org);
			if(distSqrd > maxDistSquared) continue;
			
			// make sure the killer in question is on the opposing team
			player = level.spawnlogic_deaths[d].killer;
			if(!isalive(player)) continue;
			if(player == self) continue;
			if(teambased && player.pers["team"] == self.pers["team"]) continue;
			
			// (no sqrt, must recalculate distance)
			dist = distance(spawnpoints[i].origin, level.spawnlogic_deaths[d].org);
			weights[i] -= (1 - dist/maxDist) * 100000; // possible spawn kills are *really* bad
		}
	}
	
	// do some sight checks to try to predict spawn kills before they happen
	maxNumSightChecks = 15;
	numSightChecks = 0;
	numFailures = 0; // after checking enough spawnpoints with all failed sight checks, we give up
	maxNumFailures = 5;
	
	nearbyDist = 1000; // we'll do sight checks for players within this range
	dangerDist = 1600; // or players who tend to kill at this range or higher
	
	lastweight = -1;
	
	time = getTime();
	
	players = level.players;

	permutation = [];
	for(i = 0; i < players.size; i++) permutation[i] = i;
	
	for(i = 0; i < spawnpoints.size; i++)
	{
		// find highest weighted spawnpoint that we haven't tried yet
		highest = undefined;
		for(j = 0; j < spawnpoints.size; j++)
		{
			if(!didSightChecks[j])
			{
				highest = j;
				break;
			}
		}
		if(!isdefined(highest)) break;
		for(j++; j < spawnpoints.size; j++)
		{
			if(!didSightChecks[j] && weights[j] > weights[highest]) highest = j;
		}
		
		j = highest;
		lastweight = weights[j];
		
		dir = anglestoforward(spawnpoints[j].angles);
		
		succeeded = false;
		
		// decide which players to do sight checks on
		checkplayers = [];
		numnearby = 0; // we'll pick 2 nearby players
		numdangerous = 0; // and 2 who tend to kill at a far distance
		
		// (start with a random permutation of all players)
		for(a = 0; a < players.size; a++)
		{
			b = randomInt(players.size);
			temp = permutation[a];
			permutation[a] = permutation[b];
			permutation[b] = temp;
		}
		
		// check each player in random order; if we think a sight check would be good, put them in the checkplayers array
		playersDidntUse = [];
		for(p = 0; p < players.size; p++)
		{
			player = players[permutation[p]];
			if(!isalive(player)) continue;
			if(player == self) continue;
			if(teambased && player.pers["team"] == self.pers["team"]) continue;
			if(player.pers["team"] != "axis" && player.pers["team"] != "allies") continue;
			
			diff = player.origin - spawnpoints[j].origin;
			pdir = anglestoforward(player.angles);
			if(vectordot(dir, diff) < 0 && vectordot(pdir, diff) > 0) continue; // both players looking away from each other

			dist = distance(player.origin, spawnpoints[j].origin);
			if(numnearby < 2 && dist <= nearbyDist)
			{
				checkplayers[numnearby] = player;
				numnearby++;
			}
			else if(numdangerous < 3 && isdefined(player.spawnlogic_killdist) && player.spawnlogic_killdist >= dangerDist)
			{
				checkplayers[2 + numdangerous] = player;
				numdangerous++;
			}
			else if(playersDidntUse.size < 3)
				playersDidntUse[playersDidntUse.size] = player;
			
			if(numnearby >= 2 && numdangerous >= 3) break;
		}
		// if we didn't find 5 players to do sight checks on, add up to 3 more random ones
		for(pduIndex = playersDidntUse.size; pduIndex < 5; pduIndex++) playersDidntUse[pduIndex] = undefined;
		pduIndex = 0;
		for(; numnearby < 2; numnearby++)
		{
			checkplayers[numnearby] = playersDidntUse[pduIndex];
			pduIndex++;
		}
		for(; numdangerous < 3; numdangerous++)
		{
			checkplayers[2 + numdangerous] = playersDidntUse[pduIndex];
			pduIndex++;
		}

		// do sight checks
		for(p = 0; p < 5; p++)
		{
			player = checkplayers[p];
			if(!isdefined(player)) continue;
			
			// using bullet trace instead of sight trace because sighttrace doesn't seem to see through trees
			losExists = bullettracepassed(player.origin + (0,0,48), spawnpoints[j].origin + (0,0,48), false, undefined);
			numSightChecks++;
			
			if(losExists)
			{
				succeeded = true;
				weights[j] -= 100000; // we don't want to spawn here!
				
				// pretend this player killed a person at this spawnpoint, so we don't try to use it again any time soon.
				deathInfo = spawnstruct();
				
				deathInfo.time = time;
				deathInfo.org = spawnpoints[j].origin;
				deathInfo.killOrg = player.origin;
				deathInfo.killer = player;
				deathInfo.los = true;
				
				checkForSimilarDeaths(deathInfo);
				level.spawnlogic_deaths[level.spawnlogic_deaths.size] = deathInfo;
				break;
			}
			
			if(numSightChecks >= maxNumSightChecks) break;
		}
		
		didSightChecks[j] = true;
		
		if(!succeeded) numFailures++;

		if(numFailures >= maxNumFailures || numSightChecks >= maxNumSightChecks) break;
	}
	
	return weights;
}

avoidSpawnReuse(spawnpoints, weights, teambased)
{
	if(getcvar("scr_spawnpointnewlogic") == "0") return weights;

	time = getTime();
	
	maxtime = 10*1000;
	maxdist = 800;
	
	for(i = 0; i < spawnpoints.size; i++)
	{
		if(!isdefined(spawnpoints[i].lastspawnedplayer) || !isdefined(spawnpoints[i].lastspawntime) || !isalive(spawnpoints[i].lastspawnedplayer)) continue;
		if(spawnpoints[i].lastspawnedplayer == self) continue;
		if(teambased && spawnpoints[i].lastspawnedplayer.pers["team"] == self.pers["team"]) continue;
		
		timepassed = time - spawnpoints[i].lastspawntime;
		if(timepassed < maxtime)
		{
			dist = distance(spawnpoints[i].lastspawnedplayer.origin, spawnpoints[i].origin);
			if(dist < maxdist) weights[i] -= 1000 * (1 - dist/maxdist) * (1 - timepassed/maxtime);
				else spawnpoints[i].lastspawnedplayer = undefined; // don't worry any more about this spawnpoint
		}
		else spawnpoints[i].lastspawnedplayer = undefined; // don't worry any more about this spawnpoint
	}
	return weights;
}

avoidSameSpawn(spawnpoints, weights)
{
	if(!isdefined(self.lastspawnpoint)) return weights;
	
	for(i = 0; i < spawnpoints.size; i++)
	{
		if(spawnpoints[i] == self.lastspawnpoint)
		{
			weights[i] -= 50000; // (half as bad as a likely spawn kill)
			break;
		}
	}
	return weights;
}

//==============================================================================

add_to_array(array, ent)
{
	if(!isdefined(ent)) return array;
		
	if(!isdefined(array)) array[0] = ent;
		else array[array.size] = ent;
	
	return array;	
}

addorigin_to_array(array, ent)
{
	if(!isdefined(ent)) return array;
		
	if(!isdefined(array)) array[0] = ent.origin;
		else array[array.size] = ent.origin;
	
	return array;	
}

//==============================================================================

// extreme+ addition: Returns the spawn point closest to the passed in position.
NearestSpawnpoint(spawnpoints, vPosition)
{
	// If available, append spawnpoints added by script _ex_spawnpoints.gsc
	if(isDefined(level.ex_spawnpoints))
	{
		for(i = 0; i < level.ex_spawnpoints.size; i++)
			spawnpoints[spawnpoints.size] = level.ex_spawnpoints[i];
	}

	eNearestSpot = spawnpoints[0];
	fNearestDist = distance(vPosition, spawnpoints[0].origin);
	for(i = 1; i < spawnpoints.size; i++)
	{
		fDist = distance(vPosition, spawnpoints[i].origin);
		if(fDist < fNearestDist)
		{
			eNearestSpot = spawnpoints[i];
			fNearestDist = fDist;
		}
	}
	
	return eNearestSpot;
}

