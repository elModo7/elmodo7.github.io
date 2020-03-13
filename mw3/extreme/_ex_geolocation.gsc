geoInit()
{
	level.geo_lookup_inprogress = false;
	level.geo_statelist = [];
	level.geo_index = -1;
}

geoFindIP(str, searchstr, lineno)
{
	// Example:
	// Client 0 connecting with 50 challenge ping from 192.168.1.10:28961
	// Connecting player #10 has a zero GUID
	// Going from CS_FREE to CS_CONNECTED for  (num 10 guid 0)

	ip_string = "";

	if(isSubStr(str, searchstr))
	{
		tokens = strtok(str, " ");
		if(tokens.size == 9)
		{
			ip_test = "";
			for(i = 0; i < tokens[8].size; i++)
				if(tokens[8][i] != ":") ip_test += tokens[8][i];
				  else break;

			if(geoVerifyIP(ip_test)) ip_string = ip_test;
		}
	}

	if(ip_string != "")
	{
		level.geo_index = geoAllocRec();
		level.geo_statelist[level.geo_index].ip = ip_string;

		// Uncomment for testing a specific IP address
		//level.geo_statelist[level.geo_index].ip = "8.8.8.8";

		level.geo_statelist[level.geo_index].status = 1;
		logprint("geoFindIP: record: " + level.geo_index + ", IP: " + level.geo_statelist[level.geo_index].ip + " (status " + level.geo_statelist[level.geo_index].status + ") (line " + lineno + ")\n");
	}
}

geoFindID(str, searchstr, lineno)
{
	// Example:
	// Client 0 connecting with 50 challenge ping from 192.168.1.10:28961
	// Connecting player #10 has a zero GUID
	// Going from CS_FREE to CS_CONNECTED for  (num 10 guid 0)
	if(level.geo_index == -1) return;

	id_string = "";

	if(isSubStr(str, searchstr))
	{
		tokens = strtok(str, " ");
		if(tokens.size == 10)
		{
			id_test = tokens[7];
			if(isIntStr(id_test)) id_string = id_test;
		}
	}

	if(id_string != "")
	{
		id_int = int(id_string);

		players = level.players;
		for(i = 0; i < players.size; i++)
		{
			player = players[i];
			if(isPlayer(player))
			{
				id_player = player getEntityNumber();
				if(id_player == id_int)
				{
					level.geo_statelist[level.geo_index].id = id_int;
					level.geo_statelist[level.geo_index].name = player.name;
					level.geo_statelist[level.geo_index].status = 2;
					logprint("geoFindID: record: " + level.geo_index + ", IP: " + level.geo_statelist[level.geo_index].ip + ", ID: " + level.geo_statelist[level.geo_index].id + ", player: " + level.geo_statelist[level.geo_index].name + " (status " + level.geo_statelist[level.geo_index].status + ") (line " + lineno + ")\n");
		      level.geo_index = -1;
					break;
				}
			}
		}
	}
}

geoAllocRec()
{
	// status 0: empty, waiting for IP address
	// status 1: incomplete, waiting for client slot
	// status 2: complete, but not handled yet
	// status 3: complete and handled (ready to be reused)

	// look for records that can be reused
	for(i = 0; i < level.geo_statelist.size; i++)
	{
		if(level.geo_statelist[i].status == 3)
		{
			level.geo_statelist[i].status = 0;
			return(i);
		}
	}

	// no free records found: create new one
	level.geo_statelist[i] = spawnstruct();
	level.geo_statelist[i].ip = "";
	level.geo_statelist[i].id = -1;
	level.geo_statelist[i].name = -1;
	level.geo_statelist[i].status = 0;
	return(i);
}

geoShow()
{
	for(i = 0; i < level.geo_statelist.size; i++)
	{
		if(level.geo_statelist[i].status == 2)
		{
			players = level.players;
			for(p = 0; p < players.size; p++)
			{
				player = players[p];
				if(isPlayer(player))
				{
					id_player = player getEntityNumber();
					if(id_player == level.geo_statelist[i].id)
					{
						memory_ip = "0.0.0.0";
						memory_country = "UNKNOWN";

						memory = player extreme\_ex_memory::getMemory("geo", "ip");
						if(!memory.error) memory_ip = memory.value;
						if(memory_ip != "0.0.0.0")
						{
							memory = player extreme\_ex_memory::getMemory("geo", "country");
							if(!memory.error) memory_country = memory.value;
						}

						if(memory_ip == level.geo_statelist[i].ip && memory_country != "UNKNOWN")
						{
							country_loc = geoLocalize(memory_country);

							wait( [[level.ex_fpstime]](0.1) );
							//iprintlnbold(&"GEOLOCATION_WELCOME_GENERAL", country_loc);
							iprintlnbold(&"GEOLOCATION_WELCOME_PLAYER", level.geo_statelist[i].name , country_loc);
							logprint("  geoShow: record: " + i + ", IP: " + level.geo_statelist[i].ip + ", ID: " + level.geo_statelist[i].id + ", player: " + level.geo_statelist[i].name + " (status " + level.geo_statelist[i].status + ") (from memory " + memory_country + ")\n");
						}
						else
						{
							memory_ip = level.geo_statelist[i].ip;
							memory_country = geoLocate(memory_ip);
							country_loc = geoLocalize(memory_country);

							wait( [[level.ex_fpstime]](0.1) );
							//iprintlnbold(&"GEOLOCATION_WELCOME_GENERAL", country_loc);
							iprintlnbold(&"GEOLOCATION_WELCOME_PLAYER", level.geo_statelist[i].name , country_loc);
							logprint("  geoShow: record: " + i + ", IP: " + level.geo_statelist[i].ip + ", ID: " + level.geo_statelist[i].id + ", player: " + level.geo_statelist[i].name + " (status " + level.geo_statelist[i].status + ") (lookup " + memory_country + ")\n");
							if(isPlayer(player))
							{
								player extreme\_ex_memory::setMemory("geo", "ip", memory_ip, true);
								player extreme\_ex_memory::setMemory("geo", "country", memory_country, true);
							}
						}

						// disable other records with same player IP where ID or name matches (reconnect or back from download)
						for(j = i + 1; j < level.geo_statelist.size; j++)
							if(memory_ip == level.geo_statelist[j].ip && (id_player == level.geo_statelist[j].id || player.name == level.geo_statelist[j].name) )
								level.geo_statelist[j].status = 3;

						break;
					}
				}
			}

			// make the record available for reuse
			level.geo_statelist[i].status = 3;
		}
	}
}

geoLocate(ip_string)
{
	level.geo_lookup_inprogress = true;
	country = geoSearchLocation(ip_string);
	level.geo_lookup_inprogress = false;
	return(country);
}

geoSearchLocation(ip_string)
{
	if(!isDefined(ip_string) || ip_string == "0.0.0.0") return("ZZ");

	ip_country = geoSearchDatabase(ip_string);
	return(ip_country);
}

geoSearchDatabase(ip_string)
{
	// Warning: do not include wait statements
	db_file = "geolocation/geolocation." + geoOctetToStr(ip_string, 1, 3);
	db_handle = openfile(db_file, "read");
	if(db_handle != -1)
	{
		ip_long = geoIPArray(ip_string);
		ip_start = geoIPArray("0.0.0.0");
		ip_end = geoIPArray("0.0.0.0");
		ip_country = "ZZ";
		ip_inrange = false;

		for(;;)
		{
			farg = freadln(db_handle);
			if(farg == -1 || farg == 0) break;

			memory = fgetarg(db_handle, 0);
			array = strtok(memory, " ");
			if(array.size == 3)
			{
				ip_start = geoIPArray(array[0]);
				ip_end = geoIPArray(array[1]);
				ip_country = array[2];

				ip_inrange = false;
				if(ip_long[0] >= ip_start[0])
				{
					if(ip_long[0] < ip_end[0])
					{
						ip_inrange = true;
						break;
					}
					else
					{
						if(ip_long[0] > ip_start[0]) ignore_start1 = true;
							else ignore_start1 = false;

						if(ip_long[0] == ip_end[0])
						{
							if(ignore_start1 || ip_long[1] >= ip_start[1])
							{
								if(ip_long[1] < ip_end[1])
								{
									ip_inrange = true;
									break;
								}
								else
								{
									if(ip_long[1] > ip_start[1]) ignore_start2 = true;
										else ignore_start2 = false;

									if(ip_long[1] == ip_end[1])
									{
										if(ignore_start2 || ip_long[2] >= ip_start[2])
										{
											if(ip_long[2] < ip_end[2])
											{
												ip_inrange = true;
												break;
											}
											else
											{
												if(ip_long[2] > ip_start[2]) ignore_start3 = true;
													else ignore_start3 = false;

												if(ip_long[2] == ip_end[2])
												{
													if(ignore_start3 || ip_long[3] >= ip_start[3])
													{
														if(ip_long[3] <= ip_end[3])
														{
															ip_inrange = true;
															break;
														}
													} else break;
												}
											}
										} else break;
									}
								}
							} else break;
						}
					}
				} else break;
			}
		}

		closefile(db_handle);
		if(ip_inrange) return(ip_country);
	}

	return("UNKNOWN");
}

geoVerifyIP(ip_string)
{
	ip_array = strtok(ip_string, ".");
	if(ip_array.size != 4 || !isIntStr(ip_array[0]) || !isIntStr(ip_array[1]) || !isIntStr(ip_array[2]) || !isIntStr(ip_array[3])) return(false);
	return(true);
}

geoIPArray(ip_string)
{
	ip_array = strtok(ip_string, ".");
	ip_result[0] = int(ip_array[0]);
	ip_result[1] = int(ip_array[1]);
	ip_result[2] = int(ip_array[2]);
	ip_result[3] = int(ip_array[3]);
	return(ip_result);
}

geoOctetToStr(ip_string, octet, length)
{
	ip_array = geoIPArray(ip_string);
	switch(octet)
	{
		case 4: string = "" + ip_array[3]; break;
		case 3: string = "" + ip_array[2]; break;
		case 2: string = "" + ip_array[1]; break;
		default: string = "" + ip_array[0]; break;
	}
	if(string.size > length) length = string.size;
	diff = length - string.size;
	if(diff) string = extreme\_ex_logmonitor::dupChar("0", diff) + string;
	return(string);
}

geoRandomIP()
{
	ip_intro = [];
	ip_intro[0] = randomInt(256);
	ip_intro[1] = randomInt(256);
	ip_intro[2] = randomInt(256);
	ip_intro[3] = randomInt(256);
	ip_string = ip_intro[0] + "." + ip_intro[1] + "." + ip_intro[2] + "." + ip_intro[3];
	return(ip_string);
}

geoLocalize(country)
{
	if(!isDefined(country)) country = "UNKNOWN";

	switch(country)
	{
		case "AC": return(&"GEOLOCATION_AC"); //"Ascension Island"
		case "AD": return(&"GEOLOCATION_AD"); //"Andorra"
		case "AE": return(&"GEOLOCATION_AE"); //"United Arab Emirates"
		case "AF": return(&"GEOLOCATION_AF"); //"Afghanistan"
		case "AG": return(&"GEOLOCATION_AG"); //"Antigua and Barbuda"
		case "AI": return(&"GEOLOCATION_AI"); //"Anguilla"
		case "AL": return(&"GEOLOCATION_AL"); //"Albania"
		case "AM": return(&"GEOLOCATION_AM"); //"Armenia"
		case "AN": return(&"GEOLOCATION_AN"); //"Netherlands Antilles"
		case "AO": return(&"GEOLOCATION_AO"); //"Angola"
		case "AP": return(&"GEOLOCATION_AP"); //"Asia Pas Location"
		case "AQ": return(&"GEOLOCATION_AQ"); //"Antarctica"
		case "AR": return(&"GEOLOCATION_AR"); //"Argentina"
		case "AS": return(&"GEOLOCATION_AS"); //"American Samoa"
		case "AT": return(&"GEOLOCATION_AT"); //"Austria"
		case "AU": return(&"GEOLOCATION_AU"); //"Australia"
		case "AW": return(&"GEOLOCATION_AW"); //"Aruba"
		case "AX": return(&"GEOLOCATION_AX"); //"Aland Islands"
		case "AZ": return(&"GEOLOCATION_AZ"); //"Azerbaijan"
		case "BA": return(&"GEOLOCATION_BA"); //"Bosnia and Herzegovina"
		case "BB": return(&"GEOLOCATION_BB"); //"Barbados"
		case "BD": return(&"GEOLOCATION_BD"); //"Bangladesh"
		case "BE": return(&"GEOLOCATION_BE"); //"Belgium"
		case "BF": return(&"GEOLOCATION_BF"); //"Burkina Faso"
		case "BG": return(&"GEOLOCATION_BG"); //"Bulgaria"
		case "BH": return(&"GEOLOCATION_BH"); //"Bahrain"
		case "BI": return(&"GEOLOCATION_BI"); //"Burundi"
		case "BJ": return(&"GEOLOCATION_BJ"); //"Benin"
		case "BM": return(&"GEOLOCATION_BM"); //"Bermuda"
		case "BN": return(&"GEOLOCATION_BN"); //"Brunei Darussalam"
		case "BO": return(&"GEOLOCATION_BO"); //"Bolivia"
		case "BR": return(&"GEOLOCATION_BR"); //"Brazil"
		case "BS": return(&"GEOLOCATION_BS"); //"Bahamas"
		case "BT": return(&"GEOLOCATION_BT"); //"Bhutan"
		case "BV": return(&"GEOLOCATION_BV"); //"Bouvet Island"
		case "BW": return(&"GEOLOCATION_BW"); //"Botswana"
		case "BY": return(&"GEOLOCATION_BY"); //"Belarus"
		case "BZ": return(&"GEOLOCATION_BZ"); //"Belize"
		case "CA": return(&"GEOLOCATION_CA"); //"Canada"
		case "CC": return(&"GEOLOCATION_CC"); //"Cocos (Keeling) Islands"
		case "CD": return(&"GEOLOCATION_CD"); //"Democratic Republic of the Congo"
		case "CF": return(&"GEOLOCATION_CF"); //"Central African Republic"
		case "CG": return(&"GEOLOCATION_CG"); //"Congo"
		case "CH": return(&"GEOLOCATION_CH"); //"Switzerland"
		case "CI": return(&"GEOLOCATION_CI"); //"Cote D'Ivoire (Ivory Coast)"
		case "CK": return(&"GEOLOCATION_CK"); //"Cook Islands"
		case "CL": return(&"GEOLOCATION_CL"); //"Chile"
		case "CM": return(&"GEOLOCATION_CM"); //"Cameroon"
		case "CN": return(&"GEOLOCATION_CN"); //"China"
		case "CO": return(&"GEOLOCATION_CO"); //"Colombia"
		case "CR": return(&"GEOLOCATION_CR"); //"Costa Rica"
		case "CS": return(&"GEOLOCATION_CS"); //"Serbia and Montenegro" >> RS and ME
		case "CU": return(&"GEOLOCATION_CU"); //"Cuba"
		case "CV": return(&"GEOLOCATION_CV"); //"Cape Verde"
		case "CX": return(&"GEOLOCATION_CX"); //"Christmas Island"
		case "CY": return(&"GEOLOCATION_CY"); //"Cyprus"
		case "CZ": return(&"GEOLOCATION_CZ"); //"Czech Republic"
		case "DE": return(&"GEOLOCATION_DE"); //"Germany"
		case "DJ": return(&"GEOLOCATION_DJ"); //"Djibouti"
		case "DK": return(&"GEOLOCATION_DK"); //"Denmark"
		case "DM": return(&"GEOLOCATION_DM"); //"Dominica"
		case "DO": return(&"GEOLOCATION_DO"); //"Dominican Republic"
		case "DZ": return(&"GEOLOCATION_DZ"); //"Algeria"
		case "EC": return(&"GEOLOCATION_EC"); //"Ecuador"
		case "EE": return(&"GEOLOCATION_EE"); //"Estonia"
		case "EG": return(&"GEOLOCATION_EG"); //"Egypt"
		case "EH": return(&"GEOLOCATION_EH"); //"Western Sahara"
		case "ER": return(&"GEOLOCATION_ER"); //"Eritrea"
		case "ES": return(&"GEOLOCATION_ES"); //"Spain"
		case "ET": return(&"GEOLOCATION_ET"); //"Ethiopia"
		case "EU": return(&"GEOLOCATION_EU"); //"European Union"
		case "FI": return(&"GEOLOCATION_FI"); //"Finland"
		case "FJ": return(&"GEOLOCATION_FJ"); //"Fiji"
		case "FK": return(&"GEOLOCATION_FK"); //"Falkland Islands"
		case "FM": return(&"GEOLOCATION_FM"); //"Federated States of Micronesia"
		case "FO": return(&"GEOLOCATION_FO"); //"Faroe Islands"
		case "FR": return(&"GEOLOCATION_FR"); //"France"
		case "FX": return(&"GEOLOCATION_FX"); //"France, Metropolitan"
		case "GA": return(&"GEOLOCATION_GA"); //"Gabon"
		case "GB": return(&"GEOLOCATION_GB"); //"United Kingdom"
		case "GD": return(&"GEOLOCATION_GD"); //"Grenada"
		case "GE": return(&"GEOLOCATION_GE"); //"Georgia"
		case "GF": return(&"GEOLOCATION_GF"); //"French Guiana"
		case "GG": return(&"GEOLOCATION_GG"); //"Guernsey"
		case "GH": return(&"GEOLOCATION_GH"); //"Ghana"
		case "GI": return(&"GEOLOCATION_GI"); //"Gibraltar"
		case "GL": return(&"GEOLOCATION_GL"); //"Greenland"
		case "GM": return(&"GEOLOCATION_GM"); //"Gambia"
		case "GN": return(&"GEOLOCATION_GN"); //"Guinea"
		case "GP": return(&"GEOLOCATION_GP"); //"Guadeloupe"
		case "GQ": return(&"GEOLOCATION_GQ"); //"Equatorial Guinea"
		case "GR": return(&"GEOLOCATION_GR"); //"Greece"
		case "GS": return(&"GEOLOCATION_GS"); //"S. Georgia and S. Sandwich Islands"
		case "GT": return(&"GEOLOCATION_GT"); //"Guatemala"
		case "GU": return(&"GEOLOCATION_GU"); //"Guam"
		case "GW": return(&"GEOLOCATION_GW"); //"Guinea-Bissau"
		case "GY": return(&"GEOLOCATION_GY"); //"Guyana"
		case "HK": return(&"GEOLOCATION_HK"); //"Hong Kong"
		case "HM": return(&"GEOLOCATION_HM"); //"Heard Island and McDonald Islands"
		case "HN": return(&"GEOLOCATION_HN"); //"Honduras"
		case "HR": return(&"GEOLOCATION_HR"); //"Croatia"
		case "HT": return(&"GEOLOCATION_HT"); //"Haiti"
		case "HU": return(&"GEOLOCATION_HU"); //"Hungary"
		case "ID": return(&"GEOLOCATION_ID"); //"Indonesia"
		case "IE": return(&"GEOLOCATION_IE"); //"Ireland"
		case "IL": return(&"GEOLOCATION_IL"); //"Israel"
		case "IM": return(&"GEOLOCATION_IM"); //"Isle of Man"
		case "IN": return(&"GEOLOCATION_IN"); //"India"
		case "IO": return(&"GEOLOCATION_IO"); //"British Indian Ocean Territory"
		case "IQ": return(&"GEOLOCATION_IQ"); //"Iraq"
		case "IR": return(&"GEOLOCATION_IR"); //"Iran"
		case "IS": return(&"GEOLOCATION_IS"); //"Iceland"
		case "IT": return(&"GEOLOCATION_IT"); //"Italy"
		case "JE": return(&"GEOLOCATION_JE"); //"Jersey"
		case "JM": return(&"GEOLOCATION_JM"); //"Jamaica"
		case "JO": return(&"GEOLOCATION_JO"); //"Jordan"
		case "JP": return(&"GEOLOCATION_JP"); //"Japan"
		case "KE": return(&"GEOLOCATION_KE"); //"Kenya"
		case "KG": return(&"GEOLOCATION_KG"); //"Kyrgyzstan"
		case "KH": return(&"GEOLOCATION_KH"); //"Cambodia"
		case "KI": return(&"GEOLOCATION_KI"); //"Kiribati"
		case "KM": return(&"GEOLOCATION_KM"); //"Comoros"
		case "KN": return(&"GEOLOCATION_KN"); //"Saint Kitts and Nevis"
		case "KP": return(&"GEOLOCATION_KP"); //"North Korea"
		case "KR": return(&"GEOLOCATION_KR"); //"Republic of Korea"
		case "KW": return(&"GEOLOCATION_KW"); //"Kuwait"
		case "KY": return(&"GEOLOCATION_KY"); //"Cayman Islands"
		case "KZ": return(&"GEOLOCATION_KZ"); //"Kazakhstan"
		case "LA": return(&"GEOLOCATION_LA"); //"Laos"
		case "LB": return(&"GEOLOCATION_LB"); //"Lebanon"
		case "LC": return(&"GEOLOCATION_LC"); //"Saint Lucia"
		case "LI": return(&"GEOLOCATION_LI"); //"Liechtenstein"
		case "LK": return(&"GEOLOCATION_LK"); //"Sri Lanka"
		case "LR": return(&"GEOLOCATION_LR"); //"Liberia"
		case "LS": return(&"GEOLOCATION_LS"); //"Lesotho"
		case "LT": return(&"GEOLOCATION_LT"); //"Lithuania"
		case "LU": return(&"GEOLOCATION_LU"); //"Luxembourg"
		case "LV": return(&"GEOLOCATION_LV"); //"Latvia"
		case "LY": return(&"GEOLOCATION_LY"); //"Libya"
		case "MA": return(&"GEOLOCATION_MA"); //"Morocco"
		case "MC": return(&"GEOLOCATION_MC"); //"Monaco"
		case "MD": return(&"GEOLOCATION_MD"); //"Moldova"
		case "ME": return(&"GEOLOCATION_ME"); //"Montenegro"
		case "MF": return(&"GEOLOCATION_MF"); //"Saint Martin"
		case "MG": return(&"GEOLOCATION_MG"); //"Madagascar"
		case "MH": return(&"GEOLOCATION_MH"); //"Marshall Islands"
		case "MK": return(&"GEOLOCATION_MK"); //"Macedonia"
		case "ML": return(&"GEOLOCATION_ML"); //"Mali"
		case "MM": return(&"GEOLOCATION_MM"); //"Myanmar"
		case "MN": return(&"GEOLOCATION_MN"); //"Mongolia"
		case "MO": return(&"GEOLOCATION_MO"); //"Macao"
		case "MP": return(&"GEOLOCATION_MP"); //"Northern Mariana Islands"
		case "MQ": return(&"GEOLOCATION_MQ"); //"Martinique"
		case "MR": return(&"GEOLOCATION_MR"); //"Mauritania"
		case "MS": return(&"GEOLOCATION_MS"); //"Montserrat"
		case "MT": return(&"GEOLOCATION_MT"); //"Malta"
		case "MU": return(&"GEOLOCATION_MU"); //"Mauritius"
		case "MV": return(&"GEOLOCATION_MV"); //"Maldives"
		case "MW": return(&"GEOLOCATION_MW"); //"Malawi"
		case "MX": return(&"GEOLOCATION_MX"); //"Mexico"
		case "MY": return(&"GEOLOCATION_MY"); //"Malaysia"
		case "MZ": return(&"GEOLOCATION_MZ"); //"Mozambique"
		case "NA": return(&"GEOLOCATION_NA"); //"Namibia"
		case "NC": return(&"GEOLOCATION_NC"); //"New Caledonia"
		case "NE": return(&"GEOLOCATION_NE"); //"Niger"
		case "NF": return(&"GEOLOCATION_NF"); //"Norfolk Island"
		case "NG": return(&"GEOLOCATION_NG"); //"Nigeria"
		case "NI": return(&"GEOLOCATION_NI"); //"Nicaragua"
		case "NL": return(&"GEOLOCATION_NL"); //"Netherlands"
		case "NO": return(&"GEOLOCATION_NO"); //"Norway"
		case "NP": return(&"GEOLOCATION_NP"); //"Nepal"
		case "NR": return(&"GEOLOCATION_NR"); //"Nauru"
		case "NU": return(&"GEOLOCATION_NU"); //"Niue"
		case "NZ": return(&"GEOLOCATION_NZ"); //"New Zealand"
		case "OM": return(&"GEOLOCATION_OM"); //"Oman"
		case "PA": return(&"GEOLOCATION_PA"); //"Panama"
		case "PE": return(&"GEOLOCATION_PE"); //"Peru"
		case "PF": return(&"GEOLOCATION_PF"); //"French Polynesia"
		case "PG": return(&"GEOLOCATION_PG"); //"Papua New Guinea"
		case "PH": return(&"GEOLOCATION_PH"); //"Philippines"
		case "PK": return(&"GEOLOCATION_PK"); //"Pakistan"
		case "PL": return(&"GEOLOCATION_PL"); //"Poland"
		case "PM": return(&"GEOLOCATION_PM"); //"Saint Pierre and Miquelon"
		case "PN": return(&"GEOLOCATION_PN"); //"Pitcairn"
		case "PR": return(&"GEOLOCATION_PR"); //"Puerto Rico"
		case "PS": return(&"GEOLOCATION_PS"); //"Palestinian Territory"
		case "PT": return(&"GEOLOCATION_PT"); //"Portugal"
		case "PW": return(&"GEOLOCATION_PW"); //"Palau"
		case "PY": return(&"GEOLOCATION_PY"); //"Paraguay"
		case "QA": return(&"GEOLOCATION_QA"); //"Qatar"
		case "RE": return(&"GEOLOCATION_RE"); //"Reunion"
		case "RO": return(&"GEOLOCATION_RO"); //"Romania"
		case "RS": return(&"GEOLOCATION_RS"); //"Serbia"
		case "RU": return(&"GEOLOCATION_RU"); //"Russian Federation"
		case "RW": return(&"GEOLOCATION_RW"); //"Rwanda"
		case "SA": return(&"GEOLOCATION_SA"); //"Saudi Arabia"
		case "SB": return(&"GEOLOCATION_SB"); //"Solomon Islands"
		case "SC": return(&"GEOLOCATION_SC"); //"Seychelles"
		case "SD": return(&"GEOLOCATION_SD"); //"Sudan"
		case "SE": return(&"GEOLOCATION_SE"); //"Sweden"
		case "SG": return(&"GEOLOCATION_SG"); //"Singapore"
		case "SH": return(&"GEOLOCATION_SH"); //"Saint Helena"
		case "SI": return(&"GEOLOCATION_SI"); //"Slovenia"
		case "SJ": return(&"GEOLOCATION_SJ"); //"Svalbard and Jan Mayen"
		case "SK": return(&"GEOLOCATION_SK"); //"Slovakia"
		case "SL": return(&"GEOLOCATION_SL"); //"Sierra Leone"
		case "SM": return(&"GEOLOCATION_SM"); //"San Marino"
		case "SN": return(&"GEOLOCATION_SN"); //"Senegal"
		case "SO": return(&"GEOLOCATION_SO"); //"Somalia"
		case "SR": return(&"GEOLOCATION_SR"); //"Suriname"
		case "ST": return(&"GEOLOCATION_ST"); //"Sao Tome and Principe"
		case "SV": return(&"GEOLOCATION_SV"); //"El Salvador"
		case "SY": return(&"GEOLOCATION_SY"); //"Syria"
		case "SZ": return(&"GEOLOCATION_SZ"); //"Swaziland"
		case "TC": return(&"GEOLOCATION_TC"); //"Turks and Caicos Islands"
		case "TD": return(&"GEOLOCATION_TD"); //"Chad"
		case "TG": return(&"GEOLOCATION_TG"); //"Togo"
		case "TH": return(&"GEOLOCATION_TH"); //"Thailand"
		case "TJ": return(&"GEOLOCATION_TJ"); //"Tajikistan"
		case "TK": return(&"GEOLOCATION_TK"); //"Tokelau"
		case "TL": return(&"GEOLOCATION_TL"); //"Timor-Leste"
		case "TM": return(&"GEOLOCATION_TM"); //"Turkmenistan"
		case "TN": return(&"GEOLOCATION_TN"); //"Tunisia"
		case "TO": return(&"GEOLOCATION_TO"); //"Tonga"
		case "TR": return(&"GEOLOCATION_TR"); //"Turkey"
		case "TT": return(&"GEOLOCATION_TT"); //"Trinidad and Tobago"
		case "TV": return(&"GEOLOCATION_TV"); //"Tuvalu"
		case "TW": return(&"GEOLOCATION_TW"); //"Taiwan"
		case "TZ": return(&"GEOLOCATION_TZ"); //"Tanzania"
		case "UA": return(&"GEOLOCATION_UA"); //"Ukraine"
		case "UG": return(&"GEOLOCATION_UG"); //"Uganda"
		case "UM": return(&"GEOLOCATION_UM"); //"United States Minor Outlying Islands"
		case "US": return(&"GEOLOCATION_US"); //"United States"
		case "UY": return(&"GEOLOCATION_UY"); //"Uruguay"
		case "UZ": return(&"GEOLOCATION_UZ"); //"Uzbekistan"
		case "VA": return(&"GEOLOCATION_VA"); //"Vatican City State"
		case "VC": return(&"GEOLOCATION_VC"); //"Saint Vincent and the Grenadines"
		case "VE": return(&"GEOLOCATION_VE"); //"Venezuela"
		case "VG": return(&"GEOLOCATION_VG"); //"Virgin Islands (British)"
		case "VI": return(&"GEOLOCATION_VI"); //"Virgin Islands (U.S.)"
		case "VN": return(&"GEOLOCATION_VN"); //"Viet Nam"
		case "VU": return(&"GEOLOCATION_VU"); //"Vanuatu"
		case "WF": return(&"GEOLOCATION_WF"); //"Wallis and Futuna"
		case "WS": return(&"GEOLOCATION_WS"); //"Samoa"
		case "YE": return(&"GEOLOCATION_YE"); //"Yemen"
		case "YT": return(&"GEOLOCATION_YT"); //"Mayotte"
		case "YU": return(&"GEOLOCATION_YU"); //"Serbia and Montenegro" (Yugoslavia) >> CS >> RS and ME
		case "ZA": return(&"GEOLOCATION_ZA"); //"South Africa"
		case "ZM": return(&"GEOLOCATION_ZM"); //"Zambia"
		case "ZW": return(&"GEOLOCATION_ZW"); //"Zimbabwe"
		case "ZZ": return(&"GEOLOCATION_ZZ"); //"Reserved Address Space"
		case "UNKNOWN":
		default: return(&"GEOLOCATION_UNKNOWN");
	}
}

isIntStr(str)
{
	if(!isDefined(str) || str == "") return(false);

	validchars = "-+0123456789";
	for(i = 0; i < str.size; i++)
		if(!issubstr(validchars, str[i])) return(false);

	return(true);
}
