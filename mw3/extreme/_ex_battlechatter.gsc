
teamchatter(msg, team)
{
	if(!isdefined(msg)) return;

	// get nationality prefix for allies
	switch(game["allies"])
	{
		case "american":
			allies_prefix = "US_";
			break;
		case "british":
			allies_prefix = "UK_";
			break;
		default:
			allies_prefix = "RU_";
			break;
	}

	num = randomInt(4);
	
	allies_soundalias = allies_prefix + num + "_" + msg;
	axis_soundalias = "GE_" + num + "_" + msg;

	switch(team)
	{
		case "allies":
			thread extreme\_ex_utils::playSoundOnPlayers(allies_soundalias, "allies", false);
			break;
		case "axis":
			thread extreme\_ex_utils::playSoundOnPlayers(axis_soundalias, "axis", false);
			break;
		default:
			thread extreme\_ex_utils::playSoundOnPlayers(allies_soundalias, "allies", false);
			thread extreme\_ex_utils::playSoundOnPlayers(axis_soundalias, "axis", false);
			break;
	}
}
