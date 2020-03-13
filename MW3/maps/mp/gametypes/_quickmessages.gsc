init()
{
	game["menu_quickcommands"] = "quickcommands";
	game["menu_quickstatements"] = "quickstatements";
	game["menu_quickresponses"] = "quickresponses";
	game["menu_quickrequests"] = "quickrequests";

	[[level.ex_PrecacheMenuItem]](game["menu_quickcommands"]);
	[[level.ex_PrecacheMenuItem]](game["menu_quickstatements"]);
	[[level.ex_PrecacheMenuItem]](game["menu_quickresponses"]);
	[[level.ex_PrecacheMenuItem]](game["menu_quickrequests"]);

	if(level.ex_taunts == 1 || level.ex_taunts ==3)
	{
		game["menu_quicktaunts"] = "quicktaunts";		
		[[level.ex_PrecacheMenuItem]](game["menu_quicktaunts"]);
		game["menu_quicktauntsb"] = "quicktauntsb";		
		[[level.ex_PrecacheMenuItem]](game["menu_quicktauntsb"]);
	}

	if(level.ex_currentgt == "lib")
	{
		game["menu_quickresponseslib"] = "quickresponseslib";
		[[level.ex_PrecacheMenuItem]](game["menu_quickresponseslib"]);
	}

	if(level.ex_currentgt == "ft")
	{
		game["menu_quickresponsesft"] = "quickresponsesft";
		[[level.ex_PrecacheMenuItem]](game["menu_quickresponsesft"]);
	}

	if(level.ex_specials)
	{
		game["menu_quickspecials"] = "quickspecials";
		[[level.ex_PrecacheMenuItem]](game["menu_quickspecials"]);
	}

	if(level.ex_jukebox)
	{
		game["menu_quickjukebox"] = "quickjukebox";
		[[level.ex_PrecacheMenuItem]](game["menu_quickjukebox"]);
	}

	[[level.ex_PrecacheHeadIcon]]("talkingicon");
}

quicktaunts(response, allowed)
{
	self endon("disconnect");

	if(!isDefined(self.pers["team"]) || self.pers["team"] == "spectator" || isDefined(self.spamdelay)) return;

	if(!isDefined(allowed)) allowed = false;

	// taunts disabled
	if(!allowed && level.ex_taunts != 1 && level.ex_taunts != 3) return;

	self.spamdelay = true;

	if(self.pers["team"] == "allies")
	{
		switch(game["allies"])		
		{
		case "american":
			switch(response)		
			{
			case "1":
				soundalias = "american_hitler_punk";
				saytext = &"QUICKMESSAGE_AMERICAN_TAUNT1";
				break;

			case "2":
				soundalias = "american_shoot_back";
				saytext = &"QUICKMESSAGE_AMERICAN_TAUNT2";
				break;

			case "3":
				soundalias = "american_kiss_ass";
				saytext = &"QUICKMESSAGE_AMERICAN_TAUNT3";
				break;

			case "4":
				temp = randomInt(2);
				if(temp == 0)
				{
					soundalias = "american_got_one";
					saytext = &"QUICKMESSAGE_AMERICAN_TAUNT4";
				}
				else
				{
					soundalias = "american_got_him";
					saytext = &"QUICKMESSAGE_AMERICAN_TAUNT5";
				}
				break;

			case "5":
				soundalias = "american_heil_hell";
				saytext = &"QUICKMESSAGE_AMERICAN_TAUNT6";
				break;

			case "6":
				soundalias = "american_one_less";
				saytext = &"QUICKMESSAGE_AMERICAN_TAUNT7";
				break;

			case "7":
				soundalias = "american_hitler_dolls";
				saytext = &"QUICKMESSAGE_AMERICAN_TAUNT8";
				break;
				
			case "8":
				soundalias = "american_sister_hi";
				saytext =&"QUICKMESSAGE_AMERICAN_TAUNT9";
				break;

			default:
				soundalias = "american_coffin";
				saytext = &"QUICKMESSAGE_AMERICAN_TAUNT10";
				break;
			}
			break;

		case "british":
			switch(response)		
			{
			case "1":
				soundalias = "british_hell_or_berlin";
				saytext = &"QUICKMESSAGE_BRITISH_TAUNT1";
				break;

			case "2":
				soundalias = "british_come_ahead";
				saytext = &"QUICKMESSAGE_BRITISH_TAUNT2";
				break;

			case "3":
				soundalias = "british_die_jerry";
				saytext = &"QUICKMESSAGE_BRITISH_TAUNT3";
				break;

			case "4":
				temp = randomInt(2);
				if(temp == 0)
				{
					soundalias = "british_got_one";
					saytext = &"QUICKMESSAGE_BRITISH_TAUNT4";
				}
				else
				{
					soundalias = "british_got_him";
					saytext = &"QUICKMESSAGE_BRITISH_TAUNT5";
				}
				break;

			case "5":
				soundalias = "british_got_wanker";
				saytext = &"QUICKMESSAGE_BRITISH_TAUNT6";
				break;

			case "6":
				soundalias = "british_one_less";
				saytext = &"QUICKMESSAGE_BRITISH_TAUNT7";
				break;

			case "7":
				soundalias = "british_daisies";
				saytext = &"QUICKMESSAGE_BRITISH_TAUNT8";
				break;
				
			case "8":
				soundalias = "british_bastard";
				saytext = &"QUICKMESSAGE_BRITISH_TAUNT9";
				break;

			default:
				soundalias = "british_waiting";
				saytext = &"QUICKMESSAGE_BRITISH_TAUNT10";
				break;
			}
			break;

		default:
			assert(game["allies"] == "russian");
			switch(response)		
			{
			case "1":
				soundalias = "russian_just_to_die";
				saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT1";
				break;

			case "2":
				soundalias = "russian_die_on_front";
				saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT2";
				break;

			case "3":
				soundalias = "russian_die";
				saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT3";
				break;

			case "4":
				temp = randomInt(2);
				if(temp == 0)
				{
					soundalias = "russian_got_one";
					saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT4";
				}
				else
				{
					soundalias = "russian_got_him";
					saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT5";
				}
				break;
				
			case "5":
				temp = randomInt(5);
				if(temp == 0)
				{
					soundalias = "russian_for_my_mother";
					saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT6";
				}
				else if(temp == 1)
				{
					soundalias = "russian_for_valentina";
					saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT7";
				}
				else if(temp == 2)
				{
					soundalias = "russian_for_my_father";
					saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT8";
				}
				else if(temp == 3)
				{
					soundalias = "russian_for_my_little_sister";
					saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT9";
				}
				else
				{
					soundalias = "russian_for_my_dog";
					saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT10";
				}
				break;

			case "6":
				soundalias = "russian_one_less";
				saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT11";
				break;

			case "7":
				soundalias = "russian_german_bastards";
				saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT12";
				break;
				
			case "8":
				soundalias = "russian_for_russia";
				saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT13";
				break;

			default:
				soundalias = "russian_charge";
				saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT14";
				break;
			}
			break;
		}
	}
	else
	{
		assert(self.pers["team"] == "axis");
		switch(game["axis"])
		{
		default:
			assert(game["axis"] == "german");
			switch(response)		
			{
			case "1":
				soundalias = "german_wet_pants";
				saytext = &"QUICKMESSAGE_GERMAN_TAUNT1";
				break;

			case "2":
				soundalias = "german_die_easier";
				saytext = &"QUICKMESSAGE_GERMAN_TAUNT2";
				break;

			case "3":
				soundalias = "german_die";
				saytext = &"QUICKMESSAGE_GERMAN_TAUNT3";
				break;

			case "4":
				soundalias = "german_got_one";
				saytext = &"QUICKMESSAGE_GERMAN_TAUNT4";
				break;

			case "5":
				soundalias = "german_give_up";
				saytext = &"QUICKMESSAGE_GERMAN_TAUNT5";
				break;

			case "6":
				soundalias = "german_the_end";
				saytext = &"QUICKMESSAGE_GERMAN_TAUNT6";
				break;

			case "7":
				if(game["allies"] == "american")
				{
					soundalias = "german_us_president";
					saytext = &"QUICKMESSAGE_GERMAN_TAUNT7";
				}
				else if(game["allies"] == "british")
				{
					soundalias = "german_uk_island";
					saytext = &"QUICKMESSAGE_GERMAN_TAUNT8";
				}
				else
				{
					soundalias = "german_ru_hell";
					saytext = &"QUICKMESSAGE_GERMAN_TAUNT9";
				}
				break;
				
			case "8":
				if(game["allies"] == "american")
				{
					soundalias = "german_us_ny";
					saytext = &"QUICKMESSAGE_GERMAN_TAUNT10";
				}
				else if(game["allies"] == "british")
				{
					soundalias = "german_uk_tea";
					saytext = &"QUICKMESSAGE_GERMAN_TAUNT11";
				}
				else
				{
					soundalias = "german_ru_home";
					saytext = &"QUICKMESSAGE_GERMAN_TAUNT12";
				}
				break;

			default:
				soundalias = "german_like_girls";
				saytext = &"QUICKMESSAGE_GERMAN_TAUNT13";
				break;
			}
			break;
		}			
	}

	self doQuickMessage(soundalias, saytext, false);
	if(isPlayer(self)) self.spamdelay = undefined;
}

quicktauntsb(response, allowed)
{
	self endon("disconnect");

	if(!isDefined(self.pers["team"]) || self.pers["team"] == "spectator" || isDefined(self.spamdelay)) return;

	if(!isDefined(allowed)) allowed = false;

	// taunts disabled
	if(!allowed && level.ex_taunts != 1 && level.ex_taunts != 3) return;

	self.spamdelay = true;

	if(self.pers["team"] == "allies")
	{
		switch(game["allies"])		
		{
		case "american":
			switch(response)		
			{
				case "1":
					soundalias = "american_ny_ass";
					saytext = &"QUICKMESSAGE_AMERICAN_TAUNT1B";
					break;

				case "2":
					soundalias = "american_rats_ass";
					saytext = &"QUICKMESSAGE_AMERICAN_TAUNT2B";
					break;
	
				case "3":
					soundalias = "american_piss_hell";
					saytext = &"QUICKMESSAGE_AMERICAN_TAUNT3B";
					break;
	
				case "4":
					soundalias = "american_tenessee";
					saytext = &"QUICKMESSAGE_AMERICAN_TAUNT4B";
					break;
	
				case "5":
					soundalias = "american_new_york";
					saytext = &"QUICKMESSAGE_AMERICAN_TAUNT5B";
					break;
	
				case "6":
					soundalias = "american_co_dress";
					saytext = &"QUICKMESSAGE_AMERICAN_TAUNT6B";
					break;
	
				case "7":
					soundalias = "american_fatherland";
					saytext = &"QUICKMESSAGE_AMERICAN_TAUNT7B";
					break;
				
				default:
					soundalias = "american_cheers";
					saytext = &"QUICKMESSAGE_AMERICAN_TAUNT8B";
					break;
			}
			break;

		case "british":
			switch(response)		
			{
				case "1":
					soundalias = "british_goosestep";
					saytext = &"QUICKMESSAGE_BRITISH_TAUNT1B";
					break;
	
				case "2":
					soundalias = "british_packing";
					saytext = &"QUICKMESSAGE_BRITISH_TAUNT2B";
					break;
	
				case "3":
					soundalias = "british_master_race";
					saytext = &"QUICKMESSAGE_BRITISH_TAUNT3B";
					break;
	
				case "4":
					soundalias = "british_pack_it";
					saytext = &"QUICKMESSAGE_BRITISH_TAUNT4B";
					break;
	
				case "5":
					soundalias = "british_nailed_him";
					saytext = &"QUICKMESSAGE_BRITISH_TAUNT5B";
					break;
	
				case "6":
					soundalias = "british_pipe";
					saytext = &"QUICKMESSAGE_BRITISH_TAUNT6B";
					break;
	
				case "7":
					soundalias = "british_another_one";
					saytext = &"QUICKMESSAGE_BRITISH_TAUNT7B";
					break;
				
				default:
					soundalias = "british_run";
					saytext = &"QUICKMESSAGE_BRITISH_TAUNT8B";
					break;
			}
			break;

			default:
			assert(game["allies"] == "russian");
			switch(response)		
			{
				case "1":
					soundalias = "russian_spring";
					saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT1B";
					break;
	
				case "2":
					soundalias = "russian_invaders";
					saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT2B";
					break;
	
				case "3":
					soundalias = "russian_kill_fascists";
					saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT3B";
					break;
	
				case "4":
					soundalias = "russian_another_room";
					saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT4B";
					break;
	
				case "5":
					soundalias = "russian_better";
					saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT5B";
					break;
	
				case "6":
					soundalias = "russian_building";
					saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT6B";
					break;
	
				case "7":
					soundalias = "russian_eat_dirt";
					saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT7B";
					break;
				
				default:
					soundalias = "russian_motherland";
					saytext = &"QUICKMESSAGE_RUSSIAN_TAUNT8B";
					break;
			}
			break;
		}
	}
	else
	{
		assert(self.pers["team"] == "axis");
		switch(game["axis"])
		{
		default:
			assert(game["axis"] == "german");
			switch(response)		
			{
				case "1":
					soundalias = "german_give_up";
					saytext = &"QUICKMESSAGE_GERMAN_TAUNT1B";
					break;
	
				case "2":
					soundalias = "german_the_end";
					saytext = &"QUICKMESSAGE_GERMAN_TAUNT2B";
					break;
	
				case "3":
					soundalias = "german_girly";
					saytext = &"QUICKMESSAGE_GERMAN_TAUNT3B";
					break;
	
				case "4":
					if(game["allies"] == "american")
					{
						soundalias = "german_us_swim";
						saytext = &"QUICKMESSAGE_GERMAN_TAUNT4B";
					}
					else if(game["allies"] == "british")
					{
						soundalias = "german_uk_soepschotel";
						saytext = &"QUICKMESSAGE_GERMAN_TAUNT5B";
					}
					else
					{
						soundalias = "german_ru_target";
						saytext = &"QUICKMESSAGE_GERMAN_TAUNT6B";
					}
					break;	

				case "5":
					if(game["allies"] == "american")
					{
						soundalias = "german_us_better";
						saytext = &"QUICKMESSAGE_GERMAN_TAUNT7B";
					}
					else if(game["allies"] == "british")
					{
						soundalias = "german_uk_better";
						saytext = &"QUICKMESSAGE_GERMAN_TAUNT8B";
					}
					else
					{
						soundalias = "german_ru_better";
						saytext = &"QUICKMESSAGE_GERMAN_TAUNT9B";
					}
					break;
	
				case "6":
					if(game["allies"] == "american")
					{
						soundalias = "german_us_wife";
						saytext = &"QUICKMESSAGE_GERMAN_TAUNT10B";
					}
					else if(game["allies"] == "british")
					{
						soundalias = "german_uk_insult";
						saytext = &"QUICKMESSAGE_GERMAN_TAUNT11B";
					}
					else
					{
						soundalias = "german_ru_city";
						saytext = &"QUICKMESSAGE_GERMAN_TAUNT12B";
					}
					break;
	
				case "7":
					if(game["allies"] == "american")
					{
						soundalias = "german_us_target";
						saytext = &"QUICKMESSAGE_GERMAN_TAUNT13B";
					}
					else if(game["allies"] == "british")
					{
						soundalias = "german_uk_london";
						saytext = &"QUICKMESSAGE_GERMAN_TAUNT14B";
					}
					else
					{
						soundalias = "german_ru_wife";
						saytext = &"QUICKMESSAGE_GERMAN_TAUNT15B";
					}
					break;
				
				default:
					if(game["allies"] == "american")
					{
						soundalias = "german_us_french";
						saytext = &"QUICKMESSAGE_GERMAN_TAUNT16B";
					}
					else if(game["allies"] == "british")
					{
						soundalias = "german_uk_machinegun";
						saytext = &"QUICKMESSAGE_GERMAN_TAUNT17B";
					}
					else
					{
						soundalias = "german_ru_decorate";
						saytext = &"QUICKMESSAGE_GERMAN_TAUNT18B";
					}
					break;
			}
			break;
		}			
	}

	self doQuickMessage(soundalias, saytext, false);
	if(isPlayer(self)) self.spamdelay = undefined;
}

quickresponseslib(response)
{
	self endon("disconnect");

	if(!isdefined(self.pers["team"]) || self.pers["team"] == "spectator" || isdefined(self.spamdelay))
		return;

	self.spamdelay = true;

	if(self.pers["team"] == "allies")
	{
		switch(game["allies"])
		{
		case "american":
			switch(response)
			{
			case "1":
				soundalias = "US_mp_cmd_WHOOHOO";
				saytext = &"LIB_QUICK_WHOOHOO";
				break;

			case "2":
				soundalias = "US_mp_cmd_CAPTURETHEENEMY";
				saytext = &"LIB_QUICK_CAPTURETHEENEMYJAIL";
				break;

			case "3":
				soundalias = "US_mp_cmd_GUARDOURJAIL";
				saytext = &"LIB_QUICK_GUARDOURJAIL";
				break;

			case "4":
				soundalias = "US_mp_cmd_FREEME";
				saytext = &"LIB_QUICK_FREEME";
				break;

			case "5":
				soundalias = "US_mp_cmd_IMATTACKING";
				saytext = &"LIB_QUICK_IMATTACKINGTHEENEMYJAIL";
				break;

			case "6":
				soundalias = "US_mp_cmd_IMDEFENDING";
				saytext = &"LIB_QUICK_IMDEFENDING";
				break;

			case "7":
				soundalias = "US_mp_cmd_THEENEMYISATTACKING";
				saytext = &"LIB_QUICK_THEENEMYISATTACKING";
				break;

			case "8":
				soundalias = "US_mp_cmd_YOUMESSWITH";
				saytext = &"LIB_QUICK_YOUMESSWITHTHEBEST";
				break;

			default:
				soundalias = "US_mp_cmd_THANKS";
				saytext = &"LIB_QUICK_THANKS";
				break;
			}
			break;

		case "british":
			switch(response)
			{
			case "1":
				soundalias = "UK_mp_cmd_WHOOHOO";
				saytext = &"LIB_QUICK_WHOOHOO";
				break;

			case "2":
				soundalias = "UK_mp_cmd_CAPTURETHEENEMY";
				saytext = &"LIB_QUICK_CAPTURETHEENEMYJAIL";
				break;

			case "3":
				soundalias = "UK_mp_cmd_GUARDOURJAIL";
				saytext = &"LIB_QUICK_GUARDOURJAIL";
				break;

			case "4":
				soundalias = "UK_mp_cmd_FREEME";
				saytext = &"LIB_QUICK_FREEME";
				break;

			case "5":
				soundalias = "UK_mp_cmd_IMATTACKING";
				saytext = &"LIB_QUICK_IMATTACKINGTHEENEMYJAIL";
				break;

			case "6":
				soundalias = "UK_mp_cmd_IMDEFENDING";
				saytext = &"LIB_QUICK_IMDEFENDING";
				break;

			case "7":
				soundalias = "UK_mp_cmd_THEENEMYISATTACKING";
				saytext = &"LIB_QUICK_THEENEMYISATTACKING";
				break;

			case "8":
				soundalias = "UK_mp_cmd_YOUMESSWITH";
				saytext = &"LIB_QUICK_YOUMESSWITHTHEBEST";
				break;

			default:
				soundalias = "UK_mp_cmd_THANKS";
				saytext = &"LIB_QUICK_THANKS";
				break;
			}
			break;

		default:
			assert(game["allies"] == "russian");
			switch(response)
			{
			case "1":
				soundalias = "RU_mp_cmd_WHOOHOO";
				saytext = &"LIB_QUICK_WHOOHOO";
				break;

			case "2":
				soundalias = "RU_mp_cmd_CAPTURETHEENEMY";
				saytext = &"LIB_QUICK_CAPTURETHEENEMYJAIL";
				break;

			case "3":
				soundalias = "RU_mp_cmd_GUARDOURJAIL";
				saytext = &"LIB_QUICK_GUARDOURJAIL";
				break;

			case "4":
				soundalias = "RU_mp_cmd_FREEME";
				saytext = &"LIB_QUICK_FREEME";
				break;

			case "5":
				soundalias = "RU_mp_cmd_IMATTACKING";
				saytext = &"LIB_QUICK_IMATTACKINGTHEENEMYJAIL";
				break;

			case "6":
				soundalias = "RU_mp_cmd_IMDEFENDING";
				saytext = &"LIB_QUICK_IMDEFENDING";
				break;

			case "7":
				soundalias = "RU_mp_cmd_THEENEMYISATTACKING";
				saytext = &"LIB_QUICK_THEENEMYISATTACKING";
				break;

			case "8":
				soundalias = "RU_mp_cmd_YOUMESSWITH";
				saytext = &"LIB_QUICK_YOUMESSWITHTHEBEST";
				break;

			default:
				soundalias = "RU_mp_cmd_THANKS";
				saytext = &"LIB_QUICK_THANKS";
				break;
			}
			break;
		}
	}
	else
	{
		assert(self.pers["team"] == "axis");
		switch(game["axis"])
		{
		default:
			assert(game["axis"] == "german");
			switch(response)
			{
			case "1":
				soundalias = "GE_mp_cmd_WHOOHOO";
				saytext = &"LIB_QUICK_WHOOHOO";
				break;

			case "2":
				soundalias = "GE_mp_cmd_CAPTURETHEENEMY";
				saytext = &"LIB_QUICK_CAPTURETHEENEMYJAIL";
				break;

			case "3":
				soundalias = "GE_mp_cmd_GUARDOURJAIL";
				saytext = &"LIB_QUICK_GUARDOURJAIL";
				break;

			case "4":
				soundalias = "GE_mp_cmd_FREEME";
				saytext = &"LIB_QUICK_FREEME";
				break;

			case "5":
				soundalias = "GE_mp_cmd_IMATTACKING";
				saytext = &"LIB_QUICK_IMATTACKINGTHEENEMYJAIL";
				break;

			case "6":
				soundalias = "GE_mp_cmd_IMDEFENDING";
				saytext = &"LIB_QUICK_IMDEFENDING";
				break;

			case "7":
				soundalias = "GE_mp_cmd_THEENEMYISATTACKING";
				saytext = &"LIB_QUICK_THEENEMYISATTACKING";
				break;

			case "8":
				soundalias = "GE_mp_cmd_YOUMESSWITH";
				saytext = &"LIB_QUICK_YOUMESSWITHTHEBEST";
				break;

			default:
				soundalias = "GE_mp_cmd_THANKS";
				saytext = &"LIB_QUICK_THANKS";
				break;
			}
			break;
		}
	}

	self doQuickMessage(soundalias, saytext, false);
	if(isPlayer(self)) self.spamdelay = undefined;
}

quickresponsesft(response)
{
	self endon("disconnect");

	if(!isdefined(self.pers["team"]) || self.pers["team"] == "spectator" || isdefined(self.spamdelay))
		return;

	self.spamdelay = true;

	if(self.pers["team"] == "allies")
	{
		switch(game["allies"])
		{
		case "american":
			switch(response)
			{
			case "1":
				soundalias = "US_ft_iamfrozen";
				saytext = &"FT_QUICK_IAMFROZEN";
				break;

			case "2":
				soundalias = "US_ft_unfreezeme";
				saytext = &"FT_QUICK_UNFREEZEME";
				break;

			default:
				soundalias = "US_mp_cmd_THANKS";
				saytext = &"LIB_QUICK_THANKS";
				break;
			}
			break;

		case "british":
			switch(response)
			{
			case "1":
				soundalias = "UK_ft_iamfrozen";
				saytext = &"FT_QUICK_IAMFROZEN";
				break;

			case "2":
				soundalias = "UK_ft_unfreezeme";
				saytext = &"FT_QUICK_UNFREEZEME";
				break;

			default:
				soundalias = "UK_mp_cmd_THANKS";
				saytext = &"LIB_QUICK_THANKS";
				break;
			}
			break;

		default:
			assert(game["allies"] == "russian");
			switch(response)
			{
			case "1":
				soundalias = "RU_ft_iamfrozen";
				saytext = &"FT_QUICK_IAMFROZEN";
				break;

			case "2":
				soundalias = "RU_ft_unfreezeme";
				saytext = &"FT_QUICK_UNFREEZEME";
				break;

			default:
				soundalias = "RU_mp_cmd_THANKS";
				saytext = &"LIB_QUICK_THANKS";
				break;
			}
			break;
		}
	}
	else
	{
		assert(self.pers["team"] == "axis");
		switch(game["axis"])
		{
		default:
			assert(game["axis"] == "german");
			switch(response)
			{
			case "1":
				soundalias = "GE_ft_iamfrozen";
				saytext = &"FT_QUICK_IAMFROZEN";
				break;

			case "2":
				soundalias = "GE_ft_unfreezeme";
				saytext = &"FT_QUICK_UNFREEZEME";
				break;

			default:
				soundalias = "GE_mp_cmd_THANKS";
				saytext = &"LIB_QUICK_THANKS";
				break;
			}
			break;
		}
	}

	self doQuickMessage(soundalias, saytext, false);
	if(isPlayer(self)) self.spamdelay = undefined;
}

quickrequests(response)
{
	self endon("disconnect");

	if(!isDefined(self.pers["team"]) || self.pers["team"] == "spectator")
		return;

	if(self.pers["team"] == "allies")
	{
		switch(game["allies"])		
		{
			case "american": if(response == "1") thread extreme\_ex_firstaid::callformedic(); break;
			case "british" : if(response == "1") thread extreme\_ex_firstaid::callformedic(); break;
			case "russian" : if(response == "1") thread extreme\_ex_firstaid::callformedic(); break;
		}
	}
	else if(self.pers["team"] == "axis") thread extreme\_ex_firstaid::callformedic();
}

quickcommands(response)
{
	self endon("disconnect");

	if(!isDefined(self.pers["team"]) || self.pers["team"] == "spectator" || isDefined(self.spamdelay))
		return;

	self.spamdelay = true;

	if(self.pers["team"] == "allies")
	{
		switch(game["allies"])		
		{
		case "american":
			switch(response)		
			{
			case "1":
				soundalias = "US_mp_cmd_followme";
				saytext = &"QUICKMESSAGE_FOLLOW_ME";
				break;

			case "2":
				soundalias = "US_mp_cmd_movein";
				saytext = &"QUICKMESSAGE_MOVE_IN";
				break;

			case "3":
				soundalias = "US_mp_cmd_fallback";
				saytext = &"QUICKMESSAGE_FALL_BACK";
				break;

			case "4":
				soundalias = "US_mp_cmd_suppressfire";
				saytext = &"QUICKMESSAGE_SUPPRESSING_FIRE";
				break;

			case "5":
				soundalias = "US_mp_cmd_attackleftflank";
				saytext = &"QUICKMESSAGE_ATTACK_LEFT_FLANK";
				break;

			case "6":
				soundalias = "US_mp_cmd_attackrightflank";
				saytext = &"QUICKMESSAGE_ATTACK_RIGHT_FLANK";
				break;

			case "7":
				soundalias = "US_mp_cmd_holdposition";
				saytext = &"QUICKMESSAGE_HOLD_THIS_POSITION";
				break;

			case "8":
				soundalias = "US_mp_cmd_regroup";
				saytext = &"QUICKMESSAGE_REGROUP";
				break;

			default:
				soundalias = "US_mp_cmd_defendposition";
				saytext = &"QUICKMESSAGE_DEFEND";
				break;
			}
			break;

		case "british":
			switch(response)		
			{
			case "1":
				soundalias = "UK_mp_cmd_followme";
				saytext = &"QUICKMESSAGE_FOLLOW_ME";
				break;

			case "2":
				soundalias = "UK_mp_cmd_movein";
				saytext = &"QUICKMESSAGE_MOVE_IN";
				break;

			case "3":
				soundalias = "UK_mp_cmd_fallback";
				saytext = &"QUICKMESSAGE_FALL_BACK";
				break;

			case "4":
				soundalias = "UK_mp_cmd_suppressfire";
				saytext = &"QUICKMESSAGE_SUPPRESSING_FIRE";
				break;

			case "5":
				soundalias = "UK_mp_cmd_attackleftflank";
				saytext = &"QUICKMESSAGE_ATTACK_LEFT_FLANK";
				break;

			case "6":
				soundalias = "UK_mp_cmd_attackrightflank";
				saytext = &"QUICKMESSAGE_ATTACK_RIGHT_FLANK";
				break;

			case "7":
				soundalias = "UK_mp_cmd_holdposition";
				saytext = &"QUICKMESSAGE_HOLD_THIS_POSITION";
				break;

			case "8":
				soundalias = "UK_mp_cmd_regroup";
				saytext = &"QUICKMESSAGE_REGROUP";
				break;

			default:
				soundalias = "UK_mp_cmd_defendposition";
				saytext = &"QUICKMESSAGE_DEFEND";
				break;
			}
			break;

		default:
			assert(game["allies"] == "russian");
			switch(response)		
			{
			case "1":
				soundalias = "RU_mp_cmd_followme";
				saytext = &"QUICKMESSAGE_FOLLOW_ME";
				break;

			case "2":
				soundalias = "RU_mp_cmd_movein";
				saytext = &"QUICKMESSAGE_MOVE_IN";
				break;

			case "3":
				soundalias = "RU_mp_cmd_fallback";
				saytext = &"QUICKMESSAGE_FALL_BACK";
				break;

			case "4":
				soundalias = "RU_mp_cmd_suppressfire";
				saytext = &"QUICKMESSAGE_SUPPRESSING_FIRE";
				break;

			case "5":
				soundalias = "RU_mp_cmd_attackleftflank";
				saytext = &"QUICKMESSAGE_ATTACK_LEFT_FLANK";
				break;

			case "6":
				soundalias = "RU_mp_cmd_attackrightflank";
				saytext = &"QUICKMESSAGE_ATTACK_RIGHT_FLANK";
				break;

			case "8":
				soundalias = "RU_mp_cmd_regroup";
				saytext = &"QUICKMESSAGE_REGROUP";
				break;

			default:
				soundalias = "RU_mp_cmd_defendposition";
				saytext = &"QUICKMESSAGE_DEFEND";
				break;
			}
			break;
		}
	}
	else
	{
		assert(self.pers["team"] == "axis");
		switch(game["axis"])
		{
		default:
			assert(game["axis"] == "german");
			switch(response)		
			{
			case "1":
				soundalias = "GE_mp_cmd_followme";
				saytext = &"QUICKMESSAGE_FOLLOW_ME";
				break;

			case "2":
				soundalias = "GE_mp_cmd_movein";
				saytext = &"QUICKMESSAGE_MOVE_IN";
				break;

			case "3":
				soundalias = "GE_mp_cmd_fallback";
				saytext = &"QUICKMESSAGE_FALL_BACK";
				break;

			case "4":
				soundalias = "GE_mp_cmd_suppressfire";
				saytext = &"QUICKMESSAGE_SUPPRESSING_FIRE";
				break;

			case "5":
				soundalias = "GE_mp_cmd_attackleftflank";
				saytext = &"QUICKMESSAGE_ATTACK_LEFT_FLANK";
				break;

			case "6":
				soundalias = "GE_mp_cmd_attackrightflank";
				saytext = &"QUICKMESSAGE_ATTACK_RIGHT_FLANK";
				break;

			case "7":
				soundalias = "GE_mp_cmd_holdposition";
				saytext = &"QUICKMESSAGE_HOLD_THIS_POSITION";
				break;

			case "8":
				soundalias = "GE_mp_cmd_regroup";
				saytext = &"QUICKMESSAGE_REGROUP";
				break;

			default:
				soundalias = "GE_mp_cmd_defendposition";
				saytext = &"QUICKMESSAGE_DEFEND";
				break;
			}
			break;
		}			
	}

	self doQuickMessage(soundalias, saytext, false);
	if(isPlayer(self)) self.spamdelay = undefined;
}

quickstatements(response)
{
	self endon("disconnect");

	if(!isDefined(self.pers["team"]) || self.pers["team"] == "spectator" || isDefined(self.spamdelay))
		return;

	self.spamdelay = true;

	if(self.pers["team"] == "allies")
	{
		switch(game["allies"])		
		{
		case "american":
			switch(response)		
			{
			case "1":
				soundalias = "US_mp_stm_enemyspotted";
				saytext = &"QUICKMESSAGE_ENEMY_SPOTTED";
				break;

			case "2":
				soundalias = "US_mp_stm_enemydown";
				saytext = &"QUICKMESSAGE_ENEMY_DOWN";
				break;

			case "3":
				soundalias = "US_mp_stm_iminposition";
				saytext = &"QUICKMESSAGE_IM_IN_POSITION";
				break;

			case "4":
				soundalias = "US_mp_stm_areasecure";
				saytext = &"QUICKMESSAGE_AREA_SECURE";
				break;

			case "5":
				soundalias = "US_mp_stm_grenade";
				saytext = &"QUICKMESSAGE_GRENADE";
				break;

			case "6":
				soundalias = "US_mp_stm_sniper";
				saytext = &"QUICKMESSAGE_SNIPER";
				break;

			case "7":
				soundalias = "US_mp_stm_needreinforcements";
				saytext = &"QUICKMESSAGE_NEED_REINFORCEMENTS";
				break;

			case "8":
				soundalias = "US_mp_stm_holdyourfire";
				saytext = &"QUICKMESSAGE_HOLD_YOUR_FIRE";
				break;

			default:
				soundalias = "US_mp_stm_mandown";
				saytext = &"QUICKMESSAGE_MAN_DOWN";
				break;
			}
			break;

		case "british":
			switch(response)		
			{
			case "1":
				soundalias = "UK_mp_stm_enemyspotted";
				saytext = &"QUICKMESSAGE_ENEMY_SPOTTED";
				break;

			case "2":
				soundalias = "UK_mp_stm_enemydown";
				saytext = &"QUICKMESSAGE_ENEMY_DOWN";
				break;

			case "3":
				soundalias = "UK_mp_stm_iminposition";
				saytext = &"QUICKMESSAGE_IM_IN_POSITION";
				break;

			case "4":
				soundalias = "UK_mp_stm_areasecure";
				saytext = &"QUICKMESSAGE_AREA_SECURE";
				break;

			case "5":
				soundalias = "UK_mp_stm_grenade";
				saytext = &"QUICKMESSAGE_GRENADE";
				break;

			case "6":
				soundalias = "UK_mp_stm_sniper";
				saytext = &"QUICKMESSAGE_SNIPER";
				break;

			case "7":
				soundalias = "UK_mp_stm_needreinforcements";
				saytext = &"QUICKMESSAGE_NEED_REINFORCEMENTS";
				break;

			case "8":
				soundalias = "UK_mp_stm_holdyourfire";
				saytext = &"QUICKMESSAGE_HOLD_YOUR_FIRE";
				break;

			default:
				soundalias = "UK_mp_stm_mandown";
				saytext = &"QUICKMESSAGE_MAN_DOWN";
				break;
			}
			break;

		default:
			assert(game["allies"] == "russian");
			switch(response)		
			{
			case "1":
				soundalias = "RU_mp_stm_enemyspotted";
				saytext = &"QUICKMESSAGE_ENEMY_SPOTTED";
				break;

			case "2":
				soundalias = "RU_mp_stm_enemydown";
				saytext = &"QUICKMESSAGE_ENEMY_DOWN";
				break;

			case "3":
				soundalias = "RU_mp_stm_iminposition";
				saytext = &"QUICKMESSAGE_IM_IN_POSITION";
				break;

			case "4":
				soundalias = "RU_mp_stm_areasecure";
				saytext = &"QUICKMESSAGE_AREA_SECURE";
				break;

			case "5":
				soundalias = "RU_mp_stm_grenade";
				saytext = &"QUICKMESSAGE_GRENADE";
				break;

			case "6":
				soundalias = "RU_mp_stm_sniper";
				saytext = &"QUICKMESSAGE_SNIPER";
				break;

			case "7":
				soundalias = "RU_mp_stm_needreinforcements";
				saytext = &"QUICKMESSAGE_NEED_REINFORCEMENTS";
				break;

			case "8":
				soundalias = "RU_mp_stm_holdyourfire";
				saytext = &"QUICKMESSAGE_HOLD_YOUR_FIRE";
				break;

			default:
				soundalias = "RU_mp_stm_mandown";
				saytext = &"QUICKMESSAGE_MAN_DOWN";
				break;
			}
			break;
		}
	}
	else
	{
		assert(self.pers["team"] == "axis");
		switch(game["axis"])
		{
		default:
			assert(game["axis"] == "german");
			switch(response)		
			{
			case "1":
				temp = randomInt(4);
				if(temp == 0)
				{
					soundalias = "GE_mp_stm_enemyspotted";
					saytext = &"QUICKMESSAGE_ENEMY_SPOTTED";
				}
				else if(temp == 1)
				{
					soundalias = "GE_mp_stm_enemyspotted2";
					saytext = &"QUICKMESSAGE_ENEMY_SPOTTED";
				}
				else
				{
					if(game["allies"] == "american")
					{
						soundalias = "GE_mp_stm_enemyamerican";
						saytext = &"QUICKMESSAGE_ENEMY_SPOTTED";
					}
					else if(game["allies"] == "british")
					{
						soundalias = "GE_mp_stm_enemybritish";
						saytext = &"QUICKMESSAGE_ENEMY_SPOTTED";
					}
					else
					{
						soundalias = "Ge_mp_stm_enemyrussian";
						saytext = &"QUICKMESSAGE_ENEMY_SPOTTED";
					}
				}
				break;

			case "2":
				soundalias = "GE_mp_stm_enemydown";
				saytext = &"QUICKMESSAGE_ENEMY_DOWN";
				break;

			case "3":
				soundalias = "GE_mp_stm_iminposition";
				saytext = &"QUICKMESSAGE_IM_IN_POSITION";
				break;

			case "4":
				soundalias = "GE_mp_stm_areasecure";
				saytext = &"QUICKMESSAGE_AREA_SECURE";
				break;

			case "5":
				soundalias = "GE_mp_stm_grenade";
				saytext = &"QUICKMESSAGE_GRENADE";
				break;

			case "6":
				temp = randomInt(2);
				if(temp == 0)
				{
					soundalias = "GE_mp_stm_sniper";
					saytext = &"QUICKMESSAGE_SNIPER";
				}
				else
				{
					if(game["allies"] == "american")
					{
						soundalias = "GE_mp_stm_sniper_us";
						saytext = &"QUICKMESSAGE_SNIPER";
					}
					if(game["allies"] == "british")
					{
						soundalias = "GE_mp_stm_sniper_uk";
						saytext = &"QUICKMESSAGE_SNIPER";
					}
					else
					{
						soundalias = "GE_mp_stm_sniper_ru";
						saytext = &"QUICKMESSAGE_SNIPER";
					}
				}
				break;

			case "7":
				soundalias = "GE_mp_stm_needreinforcements";
				saytext = &"QUICKMESSAGE_NEED_REINFORCEMENTS";
				break;

			case "8":
				soundalias = "GE_mp_stm_holdyourfire";
				saytext = &"QUICKMESSAGE_HOLD_YOUR_FIRE";
				break;

			default:
				soundalias = "GE_mp_stm_mandown";
				saytext = &"QUICKMESSAGE_MAN_DOWN";
				break;
			}
			break;
		}			
	}

	self doQuickMessage(soundalias, saytext, false);
	if(isPlayer(self)) self.spamdelay = undefined;
}

quickresponses(response)
{
	self endon("disconnect");

	if(!isDefined(self.pers["team"]) || self.pers["team"] == "spectator" || isDefined(self.spamdelay))
		return;

	self.spamdelay = true;

	if(self.pers["team"] == "allies")
	{
		switch(game["allies"])		
		{
		case "american":
			switch(response)		
			{
			case "1":
				soundalias = "US_mp_rsp_yessir";
				saytext = &"QUICKMESSAGE_YES_SIR";
				break;

			case "2":
				soundalias = "US_mp_rsp_nosir";
				saytext = &"QUICKMESSAGE_NO_SIR";
				break;

			case "3":
				soundalias = "US_mp_rsp_onmyway";
				saytext = &"QUICKMESSAGE_IM_ON_MY_WAY";
				break;

			case "4":
				soundalias = "US_mp_rsp_sorry";
				saytext = &"QUICKMESSAGE_SORRY";
				break;

			case "5":
				soundalias = "US_mp_rsp_greatshot";
				saytext = &"QUICKMESSAGE_GREAT_SHOT";
				break;

			case "6":
				soundalias = "US_mp_rsp_tooklongenough";
				saytext = &"QUICKMESSAGE_TOOK_LONG_ENOUGH";
				break;

			case "7":
				soundalias = "US_mp_rsp_areyoucrazy";
				saytext = &"QUICKMESSAGE_ARE_YOU_CRAZY";
				break;	

			case "8":
				soundalias = "US_mp_rsp_thanks";
				saytext = &"QUICKMESSAGE_THANK_YOU";
				break;

			default:
				soundalias = "US_mp_rsp_noproblem";
				saytext = &"QUICKMESSAGE_NO_PROBLEM";
				break;
			}
			break;

		case "british":
			switch(response)		
			{
			case "1":
				soundalias = "UK_mp_rsp_yessir";
				saytext = &"QUICKMESSAGE_YES_SIR";
				break;

			case "2":
				soundalias = "UK_mp_rsp_nosir";
				saytext = &"QUICKMESSAGE_NO_SIR";
				break;

			case "3":
				soundalias = "UK_mp_rsp_onmyway";
				saytext = &"QUICKMESSAGE_IM_ON_MY_WAY";
				break;

			case "4":
				soundalias = "UK_mp_rsp_sorry";
				saytext = &"QUICKMESSAGE_SORRY";
				break;

			case "5":
				soundalias = "UK_mp_rsp_greatshot";
				saytext = &"QUICKMESSAGE_GREAT_SHOT";
				break;

			case "6":
				soundalias = "UK_mp_rsp_tooklongenough";
				saytext = &"QUICKMESSAGE_TOOK_LONG_ENOUGH";
				break;

			case "7":
				soundalias = "UK_mp_rsp_areyoucrazy";
				saytext = &"QUICKMESSAGE_ARE_YOU_CRAZY";
				break;

			case "8":
				soundalias = "UK_mp_rsp_thanks";
				saytext = &"QUICKMESSAGE_THANK_YOU";
				break;

			default:
				soundalias = "UK_mp_rsp_noproblem";
				saytext = &"QUICKMESSAGE_NO_PROBLEM";
				break;
			}
			break;

		default:
			assert(game["allies"] == "russian");
			switch(response)		
			{
			case "1":
				soundalias = "RU_mp_rsp_yessir";
				saytext = &"QUICKMESSAGE_YES_SIR";
				break;

			case "2":
				soundalias = "RU_mp_rsp_nosir";
				saytext = &"QUICKMESSAGE_NO_SIR";
				break;

			case "3":
				soundalias = "RU_mp_rsp_onmyway";
				saytext = &"QUICKMESSAGE_IM_ON_MY_WAY";
				break;

			case "4":
				soundalias = "RU_mp_rsp_sorry";
				saytext = &"QUICKMESSAGE_SORRY";
				break;

			case "5":
				soundalias = "RU_mp_rsp_greatshot";
				saytext = &"QUICKMESSAGE_GREAT_SHOT";
				break;

			case "6":
				soundalias = "RU_mp_rsp_tooklongenough";
				saytext = &"QUICKMESSAGE_TOOK_LONG_ENOUGH";
				break;

			case "7":
				soundalias = "RU_mp_rsp_areyoucrazy";
				saytext = &"QUICKMESSAGE_ARE_YOU_CRAZY";
				break;

			case "8":
				soundalias = "RU_mp_rsp_thanks";
				saytext = &"QUICKMESSAGE_THANK_YOU";
				break;

			default:
				soundalias = "RU_mp_rsp_noproblem";
				saytext = &"QUICKMESSAGE_NO_PROBLEM";
				break;
			}
			break;
		}
	}
	else
	{
		assert(self.pers["team"] == "axis");
		switch(game["axis"])
		{
		default:
			assert(game["axis"] == "german");
			switch(response)		
			{
			case "1":
				soundalias = "GE_mp_rsp_yessir";
				saytext = &"QUICKMESSAGE_YES_SIR";
				break;

			case "2":
				soundalias = "GE_mp_rsp_nosir";
				saytext = &"QUICKMESSAGE_NO_SIR";
				break;

			case "3":
				soundalias = "GE_mp_rsp_onmyway";
				saytext = &"QUICKMESSAGE_IM_ON_MY_WAY";
				break;

			case "4":
				soundalias = "GE_mp_rsp_sorry";
				saytext = &"QUICKMESSAGE_SORRY";
				break;

			case "5":
				soundalias = "GE_mp_rsp_greatshot";
				saytext = &"QUICKMESSAGE_GREAT_SHOT";
				break;

			case "6":
				soundalias = "GE_mp_rsp_tooklongenough";
				saytext = &"QUICKMESSAGE_TOOK_LONG_ENOUGH";
				break;

			case "7":
				soundalias = "GE_mp_rsp_areyoucrazy";
				saytext = &"QUICKMESSAGE_ARE_YOU_CRAZY";
				break;

			case "8":
				soundalias = "GE_mp_rsp_thanks";
				saytext = &"QUICKMESSAGE_THANK_YOU";
				break;

			default:
				soundalias = "GE_mp_rsp_noproblem";
				saytext = &"QUICKMESSAGE_NO_PROBLEM";
				break;
			}
			break;
		}			
	}

	self doQuickMessage(soundalias, saytext, false);
	if(isPlayer(self)) self.spamdelay = undefined;
}

quickwarning(warning, range, selfteam, enemyteam)
{
	self endon("disconnect");

	if(self.pers["team"] == "spectator" || isDefined(self.spamdelay)) return;

	prefix1 = undefined;
	prefix2 = undefined;
	soundalias1 = undefined;
	soundalias2 = undefined;
	enemy = undefined;

	if(selfteam)
	{
		self.spamdelay = true;
	
		if(!isDefined(range)) range = 240; // 20ft
	
		// team mate near?
		inrange1 = self extreme\_ex_utils::friendlyInRange(range);
		inrange2 = self extreme\_ex_utils::friendlyInRangeView(range);
	
		if(self.pers["team"] == "allies")
		{
			switch(game["allies"])
			{
				case "american":
				prefix1 = "US_";
				break;
		
				case "british":
				prefix1 = "UK_";
				break;

				default:
				prefix1 = "RU_";
				break;
			}
		}
		else prefix1 = "GE_";

		rand = randomInt(3);

		if(inrange1 || isPlayer(inrange2))
		{
			if(warning == "frag") soundalias1 = prefix1 + rand + "_inform_attacking_grenade";
			self doQuickMessage(soundalias1, undefined, false);
		}
	}

	if(isPlayer(self) && enemyteam)
	{
		rand = randomInt(3);

		// enemy near?
		inrange3 = self extreme\_ex_utils::enemyInRangeView(range);
	
		if(randomInt(100) < 50) // 50% chance that enemy will warn their team
		{
			if(isPlayer(inrange3) || isDefined(self.ex_targetwarn))
			{
				if(isDefined(self.ex_targetwarn)) enemy = self.ex_targetwarn;
					else enemy = inrange3;
		
				if(isPlayer(enemy) && enemy.pers["team"] == "allies")
				{
					switch(game["allies"])
					{
						case "american":
						prefix2 = "US_";
						break;
			
						case "british":
						prefix2 = "UK_";
						break;
			
						default:
						prefix2 = "RU_";
						break;
					}
				}
				else prefix2 = "GE_";
		
				if(warning == "frag") soundalias2 = prefix2 + rand + "_inform_incoming_grenade";
				if(warning == "smoke") soundalias2 = prefix2 + rand + "_inform_incoming_smokegrenade";

				if(isPlayer(enemy))
				{		
					enemy.spamdelay = true;
					enemy doQuickMessage(soundalias2, undefined, false);
				}
			}
		}
	}

	if(isPlayer(self)) self.spamdelay = undefined;
	if(isDefined(enemy) && !isPlayer(enemy)) enemy.spamdelay = undefined;
}

doQuickMessage(soundalias, saytext, changeicon)
{
	self endon("disconnect");

	if(!isDefined(changeicon)) changeicon = true;

	if(self.sessionstate != "playing") return;

	if(changeicon) self saveHeadIcon();

	if(isDefined(level.QuickMessageToAll) && level.QuickMessageToAll)
	{
		if(changeicon)
		{
			self.headiconteam = "none";
			self.headicon = "talkingicon";
		}

		if(isDefined(soundalias) && soundalias != "") self playSound(soundalias);
		if(isDefined(saytext)) self sayAll(saytext);
	}
	else
	{
		if(changeicon)
		{
			if(self.sessionteam == "allies") self.headiconteam = "allies";
			else if(self.sessionteam == "axis") self.headiconteam = "axis";
		
			self.headicon = "talkingicon";
		}

		if(isDefined(soundalias) && soundalias != "") self playSound(soundalias);
		if(isDefined(saytext)) self sayTeam(saytext);
		if(level.ex_currentgt != "ft") self pingPlayer();
	}

	wait( [[level.ex_fpstime]](2) );

	if(changeicon && isPlayer(self)) self restoreHeadIcon();

	if(level.ex_antispam)
	{
		spamdelay = level.ex_antispam;
		while(isPlayer(self) && isAlive(self) && spamdelay)
		{
			wait( [[level.ex_fpstime]](1) );
			spamdelay--;
		}
	}
}

saveHeadIcon()
{
	if(isDefined(self.headicon)) self.oldheadicon = self.headicon;
	if(isDefined(self.headiconteam)) self.oldheadiconteam = self.headiconteam;
}

restoreHeadIcon()
{
	if(isDefined(self.oldheadicon)) self.headicon = self.oldheadicon;
	if(isDefined(self.oldheadiconteam) && self.oldheadiconteam != "spectator") self.headiconteam = self.oldheadiconteam;
}
