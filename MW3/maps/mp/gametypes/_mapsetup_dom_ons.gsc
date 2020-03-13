
init()
{
	switch(level.ex_currentmap)
	{
		// stock maps
		case "mp_breakout": breakout(); break;
		case "mp_brecourt": brecourt(); break;
		case "mp_burgundy": burgundy(); break;
		case "mp_carentan": carentan(); break;
		case "mp_dawnville": dawnville(); break;
		case "mp_decoy": decoy(); break;
		case "mp_downtown": downtown(); break;
		case "mp_farmhouse": farmhouse(); break;
		case "mp_harbor": harbor(); break;
		case "mp_leningrad": leningrad(); break;
		case "mp_matmata": matmata(); break;
		case "mp_railyard": railyard(); break;
		case "mp_rhine": rhine(); break;
		case "mp_toujane": toujane(); break;
		case "mp_trainstation": trainstation(); break;
		// custom maps
		case "mp_anzio": anzio(); break;
		case "mp_bigred": bigred(); break;
		case "mp_border": border(); break;
		case "mp_bridge": bridge(); break;
		case "mp_castle_assault": castle_assault(); break;
		case "mp_chelm": chelm(); break;
		case "mp_destroyed_village": destroyed_village(); break;
		case "mp_draguignan": draguignan(); break;
		case "mp_edelweiss": edelweiss(); break;
		case "mp_eindhoven_beta": eindhoven_beta(); break;
		case "mp_farm_assault": farm_assault(); break;
		case "mp_foucarville": foucarville(); break;
		case "mp_louretbeta": louretbeta(); break;
		case "mp_panodra": panodra(); break;
		case "mp_salerno_beachhead_b": salerno_beachhead_b(); break;
		case "mp_sevastopol": sevastopol(); break;
		case "mp_simmerath": simmerath(); break;
		case "mp_townville": townville(); break;
		case "tigertownfinal": tigertownfinal(); break;
	}
}

matmata()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (3167.98,5551.63,12.125));
	level.flags[0].angles = (0,172.48, 0);

	level.flags[1] = spawn("script_model", (4892.72,4584.63,16.5933));
	level.flags[1].angles = (0,-93.219, 0);

	level.flags[2] = spawn("script_model", (4145.6,6764.75,18.5135));
	level.flags[2].angles = (0,147.145, 0);

	level.flags[3] = spawn("script_model", (3702.36,7798.29,-10.6672));
	level.flags[3].angles = (0,-145.475, 0);

	level.flags[4] = spawn("script_model", (5600.07,6822.53,37.9192));
	level.flags[4].angles = (0,76.4374, 0);
}

carentan()
{
	level.spawntype = "ctf";

	level.flags = [];

	level.flags[0] = spawn("script_model", (486.901,130.772,-6.39336));
	level.flags[0].angles = (0,-105.04, 0);

	level.flags[1] = spawn("script_model", (-304.891,1825.56,-7.87498));
	level.flags[1].angles = (0,91.4612, 0);

	level.flags[2] = spawn("script_model", (658.575,1433.55,-35.2424));
	level.flags[2].angles = (0,42.594, 0);

	level.flags[3] = spawn("script_model", (1549.77,1393.82,-31.875));
	level.flags[3].angles = (0,86.6382, 0);

	level.flags[4] = spawn("script_model", (404.281,2750.76,-31.875));
	level.flags[4].angles = (0,84.8419, 0);
}

farmhouse()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (105.564,-23.5597,200.125));
	level.flags[0].angles = (0,-174.227, 0);

	level.flags[1] = spawn("script_model", (-862,-2033,23));
	level.flags[1].angles = (0,0, 0);

	level.flags[2] = spawn("script_model", (-1156.16,-180.643,-54.3344));
	level.flags[2].angles = (0,-0.719604, 0);

	level.flags[3] = spawn("script_model", (-1275,1540,14));
	level.flags[3].angles = (0,222, 0);

	level.flags[4] = spawn("script_model", (-2512,390,-43));
	level.flags[4].angles = (0,178, 0);
}

burgundy()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (-45.9305,395.658,8.125));
	level.flags[0].angles = (0,-17.7209, 0);

	level.flags[1] = spawn("script_model", (187.999,1873.77,8.125));
	level.flags[1].angles = (0,170.799, 0);

	level.flags[2] = spawn("script_model", (1586.25,2153.95,0.124999));
	level.flags[2].angles = (0,-152.133, 0);

	level.flags[3] = spawn("script_model", (-1109.64,1445.29,8.125));
	level.flags[3].angles = (0,-87.1985, 0);
}

brecourt()
{
	level.spawntype = "ctf";

	level.flags = [];

	level.flags[0] = spawn("script_model", (-2341.83,-428.711,2.17551));
	level.flags[0].angles = (0,72.345, 0);

	level.flags[1] = spawn("script_model", (901.66,1236.71,-25.6092));
	level.flags[1].angles = (0,83.4741, 0);

	level.flags[2] = spawn("script_model", (655.919,-885.2,-26.676));
	level.flags[2].angles = (0,-11.261, 0);

	level.flags[3] = spawn("script_model", (783.281,-2969.24,-15.2079));
	level.flags[3].angles = (0,-40.0781, 0);

	level.flags[4] = spawn("script_model", (2923.94,-2150.43,68.5664));
	level.flags[4].angles = (0,170.947, 0);
}

trainstation()
{
	level.spawntype = "ctf";

	level.flags = [];

	level.flags[0] = spawn("script_model", (4444.4,-3472.96,-31.875));
	level.flags[0].angles = (0,-178.802, 0);

	level.flags[1] = spawn("script_model", (6174.42,-4800.29,-19.8365));
	level.flags[1].angles = (0,-173.051, 0);

	level.flags[2] = spawn("script_model", (5800.62,-3538.48,-7.875));
	level.flags[2].angles = (0,173.441, 0);

	level.flags[3] = spawn("script_model", (5925.73,-1681.53,-23.03));
	level.flags[3].angles = (0,-173.238, 0);

	level.flags[4] = spawn("script_model", (7629.13,-2983.96,-31.875));
	level.flags[4].angles = (0,-2.94434, 0);
}

decoy()
{
	level.spawntype = "ctf";

	level.flags = [];

	level.flags[0] = spawn("script_model", (6415.91,-14256,-376.79));
	level.flags[0].angles = (0,135.829, 0);

	level.flags[1] = spawn("script_model", (6562.89,-12646.7,-488.268));
	level.flags[1].angles = (0,-175.43, 0);

	level.flags[2] = spawn("script_model", (7504.71,-13461.8,-490.875));
	level.flags[2].angles = (0,-121.761, 0);

	level.flags[3] = spawn("script_model", (8619.2,-14441.6,-709.836));
	level.flags[3].angles = (0,18.5065, 0);

	level.flags[4] = spawn("script_model", (8796.72,-12604.5,-517.503));
	level.flags[4].angles = (0,-49.5099, 0);
}

dawnville()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (169.766,-18086,172.125));
	level.flags[0].angles = (0,-97.3663, 0);

	level.flags[1] = spawn("script_model", (-499.613,-16271.3,-41.3047));
	level.flags[1].angles = (0,-95.3119, 0);

	level.flags[2] = spawn("script_model", (498.116,-16815.3,69.3753));
	level.flags[2].angles = (0,-116.768, 0);

	level.flags[3] = spawn("script_model", (1852.43,-16668.1,-10.592));
	level.flags[3].angles = (0,-25.285, 0);

	level.flags[4] = spawn("script_model", (-255.35,-14753,-14.9754));
	level.flags[4].angles = (0,86.1108, 0);
}

toujane()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (141.286,2042.37,168.125));
	level.flags[0].angles = (0,-44.3573, 0);

	level.flags[1] = spawn("script_model", (1034.08,2724.28,43.9174));
	level.flags[1].angles = (0,51.1249, 0);

	level.flags[2] = spawn("script_model", (1311.35,1439.1,-1.352));
	level.flags[2].angles = (0,30.976, 0);

	level.flags[3] = spawn("script_model", (1501.27,171.589,-16.339));
	level.flags[3].angles = (0,-179.489, 0);

	level.flags[4] = spawn("script_model", (2721.92,1673.55,45.2191));
	level.flags[4].angles = (0,145.217, 0);
}

rhine()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (4521.52,15645.3,354.034));
	level.flags[0].angles = (0,-176.715, 0);

	level.flags[1] = spawn("script_model", (5386.22,16408.4,477.892));
	level.flags[1].angles = (0,172.766, 0);

	level.flags[2] = spawn("script_model", (5827.33,16124.1,607.125));
	level.flags[2].angles = (0,-90.1099, 0);

	level.flags[3] = spawn("script_model", (5201.1,14769,375.044));
	level.flags[3].angles = (0,178.643, 0);

	level.flags[4] = spawn("script_model", (6677.71,15718.5,410.088));
	level.flags[4].angles = (0,-15.1501, 0);
}

breakout()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (6039.67,4546.63,-11.2067));
	level.flags[0].angles = (0,-27.6691, 0);

	level.flags[1] = spawn("script_model", (5125.94,3129.76,-9.88507));
	level.flags[1].angles = (0,129.435, 0);

	level.flags[2] = spawn("script_model", (5316.1,4646.06,-5.91354));
	level.flags[2].angles = (0,169.986, 0);

	level.flags[3] = spawn("script_model", (4733.71,5716.08,-19.3323));
	level.flags[3].angles = (0,-175.128, 0);

	level.flags[4] = spawn("script_model", (4251.99,4784.12,-7.1119));
	level.flags[4].angles = (0,-163.087, 0);
}

leningrad()
{
	level.spawntype = "ctf";

	level.flags = [];

	level.flags[0] = spawn("script_model", (-208.573,-663.373,210.125));
	level.flags[0].angles = (0,-92.1698, 0);

	level.flags[1] = spawn("script_model", (695.277,301.251,230.125));
	level.flags[1].angles = (0,83.7488, 0);

	level.flags[2] = spawn("script_model", (-224.759,153.215,220.125));
	level.flags[2].angles = (0,-95.7623, 0);

	level.flags[3] = spawn("script_model", (-909.481,-230.318,228.125));
	level.flags[3].angles = (0,179.154, 0);

	level.flags[4] = spawn("script_model", (-248.566,1215.82,212.125));
	level.flags[4].angles = (0,171.815, 0);
}

downtown()
{
	level.spawntype = "ctf";

	level.flags = [];

	level.flags[0] = spawn("script_model", (1717.38,-2501.49,90.7412));
	level.flags[0].angles = (0,-97.652, 0);

	level.flags[1] = spawn("script_model", (574.094,-822.726,-12.0151));
	level.flags[1].angles = (0,-98.5199, 0);

	level.flags[2] = spawn("script_model", (1669.6,-701.788,54.2419));
	level.flags[2].angles = (0,81.7877, 0);

	level.flags[3] = spawn("script_model", (3213.12,-494.567,-50.9726));
	level.flags[3].angles = (0,-91.203, 0);

	level.flags[4] = spawn("script_model", (1780.27,455.46,47.1107));
	level.flags[4].angles = (0,-94.411, 0);
}

harbor()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (-7316.99,-8956.83,103.085));
	level.flags[0].angles = (0,0.565796, 0);

	level.flags[1] = spawn("script_model", (-8803.62,-8800.08,192.125));
	level.flags[1].angles = (0,1.46667, 0);

	level.flags[2] = spawn("script_model", (-8592.1,-7168.58,24.125));
	level.flags[2].angles = (0,-8.67371, 0);

	level.flags[3] = spawn("script_model", (-9489.08,-6827.65,17.8434));
	level.flags[3].angles = (0,178.077, 0);

	level.flags[4] = spawn("script_model", (-9884.67,-8570.23,224.125));
	level.flags[4].angles = (0,-98.3771, 0);

	level.flags[5] = spawn("script_model", (-10204.2,-7476.61,25.125));
	level.flags[5].angles = (0,-174.913, 0);
}

railyard()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (-2237.69,1576.37,0.125));
	level.flags[0].angles = (0,-177.396, 0);

	level.flags[1] = spawn("script_model", (-102.792,1494.74,0.124999));
	level.flags[1].angles = (0,91.203, 0);

	level.flags[2] = spawn("script_model", (-2430.11,480.661,403.125));
	level.flags[2].angles = (0,-76.1682, 0);

	level.flags[3] = spawn("script_model", (-1989.36,-524.978,67.3075));
	level.flags[3].angles = (0,-80.9143, 0);

	level.flags[4] = spawn("script_model", (-223.961,155.33,72.125));
	level.flags[4].angles = (0,-89.8187, 0);
}

bigred()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (3061,-688,17));
	level.flags[0].angles = (0, 115, 0);

	level.flags[1] = spawn("script_model", (5535,1805,4));
	level.flags[1].angles = (0, 130, 0);

	level.flags[2] = spawn("script_model", (3923,4262,-8));
	level.flags[2].angles = (0, 216, 0);

	level.flags[3] = spawn("script_model", (1326,3671,18));
	level.flags[3].angles = (0, 340, 0);

	level.flags[4] = spawn("script_model", (446,1446,10));
	level.flags[4].angles = (0, 19, 0);
}

louretbeta()
{
	level.spawntype = "ctf";

	level.flags = [];

	level.flags[0] = spawn("script_model", (-352.949,288.474,9.125));
	level.flags[0].angles = (0,-93.8013, 0);

	level.flags[1] = spawn("script_model", (25.1227,1751.77,78.5587));
	level.flags[1].angles = (0,-91.5161, 0);

	level.flags[2] = spawn("script_model", (-1088,2392.94,84.125));
	level.flags[2].angles = (0,-114.944, 0);

	level.flags[3] = spawn("script_model", (1097.68,2443.08,78.125));
	level.flags[3].angles = (0,-101.755, 0);

	level.flags[4] = spawn("script_model", (868.228,3705.14,78.125));
	level.flags[4].angles = (0,-38.6169, 0);
}

anzio()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (-711.12,-345.073,416.125));
	level.flags[0].angles = (0,1.97205, 0);

	level.flags[1] = spawn("script_model", (-1895.71,675.199,408.125));
	level.flags[1].angles = (0,76.4044, 0);

	level.flags[2] = spawn("script_model", (-2551.05,541.521,568.125));
	level.flags[2].angles = (0,-91.4777, 0);

	level.flags[3] = spawn("script_model", (-627.655,2688.73,536.125));
	level.flags[3].angles = (0,-112.165, 0);

	level.flags[4] = spawn("script_model", (-2783.32,3322.55,729.125));
	level.flags[4].angles = (0,-0.900879, 0);
}

castle_assault()
{
	level.spawntype = "ctf";
 
	level.flags = [];

	level.flags[0] = spawn("script_model", (-6.78614,-445.12,14.5254));
	level.flags[0].angles = (0,91.8951, 0);

	level.flags[1] = spawn("script_model", (-200.662,960.15,176.125));
	level.flags[1].angles = (0,-93.0817, 0);

	level.flags[2] = spawn("script_model", (-648.951,1556.55,8.125));
	level.flags[2].angles = (0,-90.5658, 0);

	level.flags[3] = spawn("script_model", (-1647.97,248.099,8.125));
	level.flags[3].angles = (0,50.8557, 0);

	level.flags[4] = spawn("script_model", (1304.26,603.151,8.12485));
	level.flags[4].angles = (0,-5.22949, 0);
}

bridge()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (-147.606,315.229,486.013));
	level.flags[0].angles = (0,-94.2242, 0);

	level.flags[1] = spawn("script_model", (-168.292,2619.33,424.125));
	level.flags[1].angles = (0,-89.7583, 0);

	level.flags[2] = spawn("script_model", (-147.62,2338.28,256.125));
	level.flags[2].angles = (0,89.6484, 0);

	level.flags[3] = spawn("script_model", (-1115.16,1781.1,424.125));
	level.flags[3].angles = (0,-101.195, 0);

	level.flags[4] = spawn("script_model", (837.216,1813.05,382.125));
	level.flags[4].angles = (0,179.984, 0);
}

chelm()
{
	level.spawntype = "ctf";

	level.flags = [];

	level.flags[0] = spawn("script_model", (-1103.25,-795.24,-56.2571));
	level.flags[0].angles = (0,-3.19153, 0);

	level.flags[1] = spawn("script_model", (-1475.1,-1853.6,-77.8582));
	level.flags[1].angles = (0,-172.82, 0);

	level.flags[2] = spawn("script_model", (-2768.26,-42.6851,-75.9328));
	level.flags[2].angles = (0,143.245, 0);

	level.flags[3] = spawn("script_model", (-2736.2,-2299.72,-69.2502));
	level.flags[3].angles = (0,-131.495, 0);

	level.flags[4] = spawn("script_model", (-2505.38,-795.794,-57.5135));
	level.flags[4].angles = (0,123.761, 0);

	level.flags[5] = spawn("script_model", (-977.009,160.63,-60.9473));
	level.flags[5].angles = (0,-117.285, 0);
}

border()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (-1825.54,-725.355,144.982));
	level.flags[0].angles = (0,175.814, 0);

	level.flags[1] = spawn("script_model", (-715.394,-973.177,107.848));
	level.flags[1].angles = (0,-94.1473, 0);

	level.flags[2] = spawn("script_model", (203.287,-2655.23,165.392));
	level.flags[2].angles = (0,3.30688, 0);

	level.flags[3] = spawn("script_model", (255.57,-965.352,106.909));
	level.flags[3].angles = (0,13.4198, 0);

	level.flags[4] = spawn("script_model", (-1149.54,398.288,228.016));
	level.flags[4].angles = (0,-165.141, 0);
}

destroyed_village()
{
	level.spawntype = "ctf";

	level.flags = [];

	level.flags[0] = spawn("script_model", (-2360.09,468.142,193.889));
	level.flags[0].angles = (0,-101.283, 0);

	level.flags[1] = spawn("script_model", (-2695.97,-1297.86,156.499));
	level.flags[1].angles = (0,76.2012, 0);

	level.flags[2] = spawn("script_model", (-1869.61,-1040.6,540.125));
	level.flags[2].angles = (0,-12.6068, 0);

	level.flags[3] = spawn("script_model", (-523.835,-1225.37,194.485));
	level.flags[3].angles = (0,-2.62024, 0);
}

draguignan()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (-3521,-4528.92,8.125));
	level.flags[0].angles = (0,-141.779, 0);

	level.flags[1] = spawn("script_model", (-3111.45,-3177.74,15.125));
	level.flags[1].angles = (0,83.2599, 0);

	level.flags[2] = spawn("script_model", (-1747.84,-5404.08,8.125));
	level.flags[2].angles = (0,137.395, 0);

	level.flags[3] = spawn("script_model", (-2088.2,-3811.47,121.125));
	level.flags[3].angles = (0,23.3295, 0);
}

edelweiss()
{
	level.spawntype = "ctf";

	level.flags = [];

	level.flags[0] = spawn("script_model", (1294.02,-1524.43,-135.875));
	level.flags[0].angles = (0,-95.8502, 0);

	level.flags[1] = spawn("script_model", (2594.99,158.944,-111.875));
	level.flags[1].angles = (0,-98.1738, 0);

	level.flags[2] = spawn("script_model", (816.125,-503.363,-108.156));
	level.flags[2].angles = (0,-97.0258, 0);

	level.flags[3] = spawn("script_model", (-1313.55,-142.838,60.125));
	level.flags[3].angles = (0,176.6, 0);

	level.flags[4] = spawn("script_model", (578.108,879.955,-111.875));
	level.flags[4].angles = (0,67.6208, 0);
}

eindhoven_beta()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (-1489.45,-609.869,120.125));
	level.flags[0].angles = (0,-5.5481, 0);

	level.flags[1] = spawn("script_model", (-852.031,1048.4,120.125));
	level.flags[1].angles = (0,84.1608, 0);

	level.flags[2] = spawn("script_model", (48.7692,341.192,120.125));
	level.flags[2].angles = (0,-158.154, 0);

	level.flags[3] = spawn("script_model", (-2427.24,417.817,96.5786));
	level.flags[3].angles = (0,-6.46545, 0);
}

panodra()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (-918.135,60.0678,-55.875));
	level.flags[0].angles = (0,119.696, 0);

	level.flags[1] = spawn("script_model", (-590.106,-1082.1,72.125));
	level.flags[1].angles = (0,85.7977, 0);

	level.flags[2] = spawn("script_model", (744.034,-1563.59,80.125));
	level.flags[2].angles = (0,-91.6919, 0);

	level.flags[3] = spawn("script_model", (-226.84,-1941.24,-55.875));
	level.flags[3].angles = (0,-90.5328, 0);
}

simmerath()
{
	level.spawntype = "sd";

	level.flags = [];

	level.flags[0] = spawn("script_model", (6152.01,223.573,-199.875));
	level.flags[0].angles = (0,21.6211, 0);

	level.flags[1] = spawn("script_model", (4991.04,-1253.91,-228.43));
	level.flags[1].angles = (0,-10.2557, 0);

	level.flags[2] = spawn("script_model", (3857.47,-293.589,-351.891));
	level.flags[2].angles = (0,178.418, 0);

	level.flags[3] = spawn("script_model", (1729.36,871.632,-39.875));
	level.flags[3].angles = (0,85.6329, 0);

	level.flags[4] = spawn("script_model", (1427.22,-296.153,-111.893));
	level.flags[4].angles = (0,-134.456, 0);
}

townville()
{
	level.spawntype = "ctf";

	level.flags = [];

	level.flags[0] = spawn("script_model", (773.719,909.295,0.120053));
	level.flags[0].angles = (0,111.231, 0);

	level.flags[1] = spawn("script_model", (3027.03,1914.3,162.432));
	level.flags[1].angles = (0,-9.04175, 0);

	level.flags[2] = spawn("script_model", (3748.18,-75.4755,127.339));
	level.flags[2].angles = (0,-18.1549, 0);

	level.flags[3] = spawn("script_model", (2800.54,3609.64,208.125));
	level.flags[3].angles = (0,-158.89, 0);

	level.flags[4] = spawn("script_model", (4648.46,3973.46,-14.6974));
	level.flags[4].angles = (0,-68.335, 0);
}

sevastopol()
{
	level.spawntype = "ctf";

	level.flags = [];

	level.flags[0] = spawn("script_model", (3695.27,-810.52,4.125));
	level.flags[0].angles = (0,-102.502, 0);

	level.flags[1] = spawn("script_model", (2536.86,-306.775,-11.875));
	level.flags[1].angles = (0,87.3303, 0);

	level.flags[2] = spawn("script_model", (1129.33,904.009,-11.875));
	level.flags[2].angles = (0,-178.22, 0);

	level.flags[3] = spawn("script_model", (396.793,-1203.05,377.125));
	level.flags[3].angles = (0,146.442, 0);

	level.flags[4] = spawn("script_model", (-1548.21,49.1437,0.125));
	level.flags[4].angles = (0,174.408, 0);
}

salerno_beachhead_b()
{
	level.spawntype = "ctf";

	level.flags = [];

	level.flags[0] = spawn("script_model", (3270.15,4030.45,341.116));
	level.flags[0].angles = (0,-89.7473, 0);

	level.flags[1] = spawn("script_model", (1178.62,1062.76,224.125));
	level.flags[1].angles = (0,-93.2025, 0);

	level.flags[2] = spawn("script_model", (896.973,2946.2,201.238));
	level.flags[2].angles = (0,-82.9633, 0);

	level.flags[3] = spawn("script_model", (660.595,3917.92,402.125));
	level.flags[3].angles = (0,-3.63647, 0);
}

tigertownfinal()
{
	level.spawntype = "ctf";

	level.flags = [];

	level.flags[0] = spawn("script_model", (-472.787,100.062,-19.4343));
	level.flags[0].angles = (0,-86.1493, 0);

	level.flags[1] = spawn("script_model", (984.064,2001.76,136.212));
	level.flags[1].angles = (0,0.884399, 0);

	level.flags[2] = spawn("script_model", (-318.548,2645.5,140.562));
	level.flags[2].angles = (0,-4.91089, 0);

	level.flags[3] = spawn("script_model", (-1864.78,857.632,143.429));
	level.flags[3].angles = (0,-90.2527, 0);

	level.flags[4] = spawn("script_model", (-2325.39,1927.63,140.121));
	level.flags[4].angles = (0,153.325, 0);
}

foucarville()
{
	level.spawntype = "ctf";

	level.flags = [];

	level.flags[0] = spawn("script_model", (-1212.3,1076.12,-75.929));
	level.flags[0].angles = (0,157.813, 0);

	level.flags[1] = spawn("script_model", (-102.106,2202.75,8.125));
	level.flags[1].angles = (0,-174.166, 0);

	level.flags[2] = spawn("script_model", (669.785,1042.21,8.125));
	level.flags[2].angles = (0,-151.551, 0);

	level.flags[3] = spawn("script_model", (1764.62,-587.14,-52.0269));
	level.flags[3].angles = (0,-114.208, 0);
}

farm_assault()
{
	level.spawntype = "ctf";

	level.flags = [];

	level.flags[0] = spawn("script_model", (6328.9,1966.25,-114.564));
	level.flags[0].angles = (0,-58.8263, 0);

	level.flags[1] = spawn("script_model", (5743.71,3927.71,22.7647));
	level.flags[1].angles = (0,-100.432, 0);

	level.flags[2] = spawn("script_model", (4190.45,2814.95,84.1217));
	level.flags[2].angles = (0,-91.8347, 0);

	level.flags[3] = spawn("script_model", (2798.5,1208.28,8.125));
	level.flags[3].angles = (0,148.793, 0);

	level.flags[4] = spawn("script_model", (2011.79,2484.59,3.46782));
	level.flags[4].angles = (0,176.512, 0);
}
