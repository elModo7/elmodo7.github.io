init()
{
	// HOW TO USE THIS FILE:
	// 1. Copy the template for each CUSTOM map you want to add.
	// 2. Uncomment the lines.
	// 3. In the "longname" and "loclname" fields, replace the text between quotes
	//    with the map name and long name of the CUSTOM map.
	// 4. The "gametype" field is used in map vote mode 4, 5 and 6 (see mapcontrol.cfg)
	//    For this field, remove all game types the map doesn't support or you
	//    don't want to vote for (if you want "lib", you must add it yourself).
	// 5. The "playsize" field is used in map vote mode 4, 5 and 6 (see mapcontrol.cfg)
	//    when player based filtering is enabled. It defines the size of the map, which
	//    is linked to the number of players in the server during end-game voting.
	//    The "playsize" field must be "all", "large", "medium" or "small".

	// IMPORTANT:
	// - DO NOT ADD STOCK MAPS. They are already in here.
	//   If you don't want stock maps, see mapcontrol.cfg -- ex_stock_maps.
	// - ONLY REPLACE TEXT BETWEEN QUOTES. Otherwise you corrupt the structure.
	// - DO NOT REMOVE THE &-SIGN. This needs to be there.
	// - DO NOT ADD COLOR CODES TO THE GAMETYPES. It will mess up the system.
	// - KEEP THIS FILE UNDER 750 LINES (including comments)!
	//   You will then have about 160 maps configured (including stock maps),
	//   which is the maximum for the in-game and end-game voting systems.
	// - HITTING ERROR: G_FindConfigStringIndex: overflow (xxxx)?: see the
	//   Quick Setup Guide PDF for instructions.

	// Add stock maps
	if(level.ex_stock_maps)
	{


		level.ex_maps[level.ex_maps.size] = spawnstruct();
		level.ex_maps[level.ex_maps.size-1].mapname = "mp_dome";
		level.ex_maps[level.ex_maps.size-1].longname = "^1Dome";
		level.ex_maps[level.ex_maps.size-1].loclname = &"^1[]^3 Dome";
		level.ex_maps[level.ex_maps.size-1].gametype = "dm tdm ctf dom";
		level.ex_maps[level.ex_maps.size-1].playsize = "all";




	}
	// DON'T CHANGE ANYTHING ABOVE THIS LINE
	// (unless you want to restrict game types for stock maps in map vote mode 4/5)


	// Add custom maps
	// TEMPLATE:
	//level.ex_maps[level.ex_maps.size] = spawnstruct();
	//level.ex_maps[level.ex_maps.size-1].mapname  = "mapname";
	//level.ex_maps[level.ex_maps.size-1].longname = "longname";
	//level.ex_maps[level.ex_maps.size-1].loclname = &"longname";
	//level.ex_maps[level.ex_maps.size-1].gametype = "chq cnq ctf ctfb dm dom esd ft hm hq htf ihtf lms lts ons rbcnq rbctf sd tdm tkoth vip";
	//level.ex_maps[level.ex_maps.size-1].playsize = "all";

	// DON'T CHANGE ANYTHING BELOW THIS LINE
}
