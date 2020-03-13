
init()
{
	if(!level.ex_rotateifempty) return;
	if(!isdefined(game["ex_emptytime"])) game["ex_emptytime"] = 0;
	[[level.ex_registerLevelEvent]]("onRandom", ::onRandom, false, 60);
}

onRandom(eventID)
{
	// Count clients that are playing
	activeplayers = 0;
	players = level.players;
	for(i = 0; i < players.size; i++)
		if(isdefined(players[i]) && isPlayer(players[i]) && players[i].sessionstate == "playing") activeplayers++;

	// Need at least 1 playing clients
	if(activeplayers >= 1) game["ex_emptytime"] = 0;
		else game["ex_emptytime"]++;

	if(game["ex_emptytime"] < level.ex_rotateifempty) return;
	exitLevel(false);
}
