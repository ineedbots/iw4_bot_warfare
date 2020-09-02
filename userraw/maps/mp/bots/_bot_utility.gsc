#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

/*
	Returns if the player is a bot.
*/
is_bot()
{
	assert(isDefined(self));
	assert(isPlayer(self));

	return ((isDefined(self.pers["isBot"]) && self.pers["isBot"]) || (isDefined(self.pers["isBotWarfare"]) && self.pers["isBotWarfare"]) || isSubStr( self.guid, "bot" ));
}

/*
	Returns how much the bot is ads'ing all the way.
*/
botAdsAmount()
{
	return (1 / (self.bot.ads_highest - self.bot.ads_lowest)) * self.bot.ads_tightness + (1 + (self.bot.ads_highest / (self.bot.ads_lowest - self.bot.ads_highest)));
}

BotPressADS(time)
{
	self maps\mp\bots\_bot_internal::pressAds(time);
}

BotPressAttack(time)
{
	self maps\mp\bots\_bot_internal::pressFire(time);
}

throwBotGrenade(gname)
{
	return self maps\mp\bots\_bot_internal::botThrowGrenade(gname);
}

botIsClimbing()
{
	return self.bot.climbing;
}

BotGetTargetRandom()
{
	if (!isDefined(self.bot.target))
		return undefined;

	return self.bot.target.rand;
}

/*
	Returns the bot's random assigned number.
*/
BotGetRandom()
{
	return self.bot.rand;
}

/*
	Returns if the bot is pressing frag button.
*/
IsBotFragging()
{
	return self.bot.isfragging;
}

/*
	Returns if the bot is sprinting.
*/
IsBotSprinting()
{
	return self.bot.running;
}

/*
	Returns if the bot is reloading.
*/
IsBotReloading()
{
	return self.bot.isreloading;
}

/*
	Freezes the bot's controls.
*/
BotFreezeControls(what)
{
	self.bot.isfrozen = what;
	if(what)
		self notify("kill_goal");
}

/*
	Returns if the bot is script frozen.
*/
BotIsFrozen()
{
	return self.bot.isfrozen;
}

/*
	Sets the bot's target to be this ent.
*/
SetAttacker(att)
{
	self.bot.target_this_frame = att;
}

/*
	Returns if the bot has a script goal.
	(like t5 gsc bot)
*/
HasScriptGoal()
{
	return (isDefined(self.bot.script_goal));
}

/*
	Sets the bot's goal, will acheive it when dist away from it.
*/
SetScriptGoal(goal, dist)
{
	self.bot.script_goal = goal;
	self.bot.script_goal_dist = dist;
	waittillframeend;
	self notify("new_goal_internal");
	self notify("new_goal");
}

/*
	Clears the bot's goal.
*/
ClearScriptGoal()
{
	self SetScriptGoal(undefined, 0);
}

HasBotJavelinLocation()
{
	return isDefined(self.bot.jav_loc);
}

SetScriptAimPos(pos)
{
	self.bot.script_aimpos = pos;
}

ClearScriptAimPos()
{
	self SetScriptAimPos(undefined);
}

SetBotJavelinLocation(loc)
{
	self.bot.jav_loc = loc;
	self notify("new_enemy");
}

ClearBotJavelinLocation()
{
	self SetBotJavelinLocation(undefined);
}

/*
	Sets the script enemy for a bot.
*/
SetScriptEnemy(enemy, offset)
{
	self.bot.script_target = enemy;
	self.bot.script_target_offset = offset;
}

/*
	Removes the script enemy of the bot.
*/
ClearScriptEnemy()
{
	self SetScriptEnemy(undefined, undefined);
}

/*
	Returns the entity of the bot's target.
*/
GetThreat()
{
	if(!isdefined(self.bot.target))
		return undefined;
		
	return self.bot.target.entity;
}

/*
	Returns if the bot has a script enemy.
*/
HasScriptEnemy()
{
	return (isDefined(self.bot.script_target));
}

/*
	Returns if the bot has a threat.
*/
HasThreat()
{
	return (isDefined(self GetThreat()));
}

IsBotKnifing()
{
	return self.bot.knifing;
}

getBotVelocity()
{
	return self.bot.velocity;
}

isWeaponPrimary(weap)
{
	return (maps\mp\gametypes\_weapons::isPrimaryWeapon(weap) || maps\mp\gametypes\_weapons::isAltModeWeapon(weap));
}

entIsVehicle(ent)
{
	return (ent.classname == "script_vehicle" || ent.model == "vehicle_uav_static_mp" || ent.model == "vehicle_ac130_coop");
}

/*
	Returns if the given weapon is full auto.
*/
WeaponIsFullAuto(weap)
{
	weaptoks = strtok(weap, "_");

	assert(isDefined(weaptoks[0]));
	assert(isString(weaptoks[0]));
	
	return !isDefined(level.bots_nonfullautoguns[weaptoks[0]]);
}

IsDefusing()
{
	return (isDefined(self.isDefusing) && self.isDefusing);
}

isPlanting()
{
	return (isDefined(self.isPlanting) && self.isPlanting);
}

inLastStand()
{
	return (isDefined(self.lastStand) && self.lastStand);
}

inFinalStand()
{
	return (isDefined(self.inFinalStand) && self.inFinalStand);
}

isFlagCarrier()
{
	return (isDefined(self.carryFlag) && self.carryFlag);
}

isWeaponDroppable(weap)
{
	return (maps\mp\gametypes\_weapons::mayDropWeapon(weap));
}

/*
	Returns if we are stunned.
*/
IsStunned()
{
	return (isdefined(self.concussionEndTime) && self.concussionEndTime > gettime());
}

/*
	Returns if we are beingArtilleryShellshocked 
*/
isArtShocked()
{
	return (isDefined(self.beingArtilleryShellshocked) && self.beingArtilleryShellshocked);
}

getEyeHeight()
{
	myEye = self getEye();

	return myEye[2] - self.origin[2];
}

notifyAfterDelay(delay, not)
{
	wait delay;
	self notify(not);
}

/*
	Pezbot's line sphere intersection.
*/
RaySphereIntersect(start, end, spherePos, radius)
{
   dp = end - start;
   a = dp[0] * dp[0] + dp[1] * dp[1] + dp[2] * dp[2];
   b = 2 * (dp[0] * (start[0] - spherePos[0]) + dp[1] * (start[1] - spherePos[1]) + dp[2] * (start[2] - spherePos[2]));
   c = spherePos[0] * spherePos[0] + spherePos[1] * spherePos[1] + spherePos[2] * spherePos[2];
   c += start[0] * start[0] + start[1] * start[1] + start[2] * start[2];
   c -= 2.0 * (spherePos[0] * start[0] + spherePos[1] * start[1] + spherePos[2] * start[2]);
   c -= radius * radius;
   bb4ac = b * b - 4.0 * a * c;
   
   return (bb4ac >= 0);
}

/*
	Returns if a smoke grenade would intersect start to end line.
*/
SmokeTrace(start, end, rad)
{
	for(i = level.bots_smokeList.count - 1; i >= 0; i--)
	{
		nade = level.bots_smokeList.data[i];
		
		if(nade.state != "smoking")
			continue;
			
		if(!RaySphereIntersect(start, end, nade.origin, rad))
			continue;
		
		return false;
	}
	
	return true;
}

/*
	Returns the cone dot (like fov, or distance from the center of our screen).
*/
getConeDot(to, from, dir)
{
    dirToTarget = VectorNormalize(to-from);
    forward = AnglesToForward(dir);
    return vectordot(dirToTarget, forward);
}

DistanceSquared2D(to, from)
{
	to = (to[0], to[1], 0);
	from = (from[0], from[1], 0);
	
	return DistanceSquared(to, from);
}

/*
	Rounds to the nearest whole number.
*/
Round(x)
{
	y = int(x);
	
	if(abs(x) - abs(y) > 0.5)
	{
		if(x < 0)
			return y - 1;
		else
			return y + 1;
	}
	else
		return y;
}

/*
	Rounds up the given value.
*/
RoundUp( floatVal )
{
	i = int( floatVal );
	if ( i != floatVal )
		return i + 1;
	else
		return i;
}

wpsFromCSV(mapname)
{
	fileName =  "waypoints/"+ toLower(mapname) + "_wp.csv";
	printLn( "Getting waypoints from csv: "+fileName );

	waypoints = [];

	waypointCount = int(tableLookupByRow(fileName, 0, 0));

	if (waypointCount == "" || waypointCount <= 0)
		return waypoints;

	for (i = 1; i <= waypointCount; i++)
	{
		waypoint = spawnStruct();

		orgStr = tableLookupByRow(fileName, i, 0);
		orgToks = strtok(orgStr, " ");
		waypoint.origin = (int(orgToks[0]), int(orgToks[1]), int(orgToks[2]));

		childStr = tableLookupByRow(fileName, i, 1);
		childToks = strtok(childStr, " ");
		waypoint.childCount = childToks.size;
		waypoint.children = [];
		for( j=0; j<childToks.size; j++ )
			waypoint.children[j] = int(childToks[j]);

		type = tableLookupByRow(fileName, i, 2);
		waypoint.type = type;

		anglesStr = tableLookupByRow(fileName, i, 3);
		if (anglesStr != "")
		{
			anglesToks = strtok(anglesStr, " ");
			waypoint.angles = (int(anglesToks[0]), int(anglesToks[1]), int(anglesToks[2]));
		}

		javStr = tableLookupByRow(fileName, i, 4);
		if (javStr != "")
		{
			javToks = strtok(javStr, " ");
			waypoint.jav_point = (int(javToks[0]), int(javToks[1]), int(javToks[2]));
		}

		waypoints[i-1] = waypoint;
	}

	return waypoints;
}

/*
	Loads the waypoints. Populating everything needed for the waypoints.
*/
load_waypoints()
{
	mapname = getDvar("mapname");

	wps = wpsFromCSV(mapname);
	
	if (wps.size)
	{
		level.waypoints = wps;
	}
	else
	{
		level.waypoints = [];
		switch(mapname)
		{
			case "mp_afghan":
				level.waypoints = maps\mp\bots\waypoints\afghan::Afghan();
			break;
			case "mp_derail":
				level.waypoints = maps\mp\bots\waypoints\derail::Derail();
			break;
			case "mp_estate":
			case "mp_estate_trop":
			case "mp_estate_tropical":
				level.waypoints = maps\mp\bots\waypoints\estate::Estate();
			break;
			case "mp_favela":
			case "mp_fav_tropical":
				level.waypoints = maps\mp\bots\waypoints\favela::Favela();
			break;
			case "mp_highrise":
				level.waypoints = maps\mp\bots\waypoints\highrise::Highrise();
			break;
			case "mp_invasion":
				level.waypoints = maps\mp\bots\waypoints\invasion::Invasion();
			break;
			case "mp_checkpoint":
				level.waypoints = maps\mp\bots\waypoints\karachi::Karachi();
			break;
			case "mp_quarry":
				level.waypoints = maps\mp\bots\waypoints\quarry::Quarry();
			break;
			case "mp_rundown":
				level.waypoints = maps\mp\bots\waypoints\rundown::Rundown();
			break;
			case "mp_rust":
				level.waypoints = maps\mp\bots\waypoints\rust::Rust();
			break;
			case "mp_boneyard":
				level.waypoints = maps\mp\bots\waypoints\scrapyard::Scrapyard();
			break;
			case "mp_nightshift":
				level.waypoints = maps\mp\bots\waypoints\skidrow::Skidrow();
			break;
			case "mp_subbase":
				level.waypoints = maps\mp\bots\waypoints\subbase::Subbase();
			break;
			case "mp_terminal":
				level.waypoints = maps\mp\bots\waypoints\terminal::Terminal();
			break;
			case "mp_underpass":
				level.waypoints = maps\mp\bots\waypoints\underpass::Underpass();
			break;
			case "mp_brecourt":
				level.waypoints = maps\mp\bots\waypoints\wasteland::Wasteland();
			break;
			
			case "mp_complex":
				level.waypoints = maps\mp\bots\waypoints\bailout::Bailout();
			break;
			case "mp_crash":
			case "mp_crash_trop":
			case "mp_crash_tropical":
				level.waypoints = maps\mp\bots\waypoints\crash::Crash();
			break;
			case "mp_overgrown":
				level.waypoints = maps\mp\bots\waypoints\overgrown::Overgrown();
			break;
			case "mp_compact":
				level.waypoints = maps\mp\bots\waypoints\salvage::Salvage();
			break;
			case "mp_storm":
			case "mp_storm_spring":
				level.waypoints = maps\mp\bots\waypoints\storm::Storm();
			break;
			
			case "mp_abandon":
				level.waypoints = maps\mp\bots\waypoints\carnival::Carnival();
			break;
			case "mp_fuel2":
				level.waypoints = maps\mp\bots\waypoints\fuel::Fuel();
			break;
			case "mp_strike":
				level.waypoints = maps\mp\bots\waypoints\strike::Strike();
			break;
			case "mp_trailerpark":
				level.waypoints = maps\mp\bots\waypoints\trailerPark::TrailerPark();
			break;
			case "mp_vacant":
				level.waypoints = maps\mp\bots\waypoints\vacant::Vacant();
			break;
			
			case "mp_nuked":
				level.waypoints = maps\mp\bots\waypoints\nuketown::Nuketown();
			break;
			
			case "mp_cross_fire":
				level.waypoints = maps\mp\bots\waypoints\crossfire::Crossfire();
			break;
			case "mp_bloc":
			case "mp_bloc_sh":
				level.waypoints = maps\mp\bots\waypoints\bloc::Bloc();
			break;
			case "mp_cargoship":
			case "mp_cargoship_sh":
				level.waypoints = maps\mp\bots\waypoints\wetwork::Wetwork();
			break;
			
			case "mp_killhouse":
				level.waypoints = maps\mp\bots\waypoints\killhouse::Killhouse();
			break;
			
			case "mp_bog_sh":
				level.waypoints = maps\mp\bots\waypoints\bog::Bog();
			break;
			
			case "mp_firingrange":
				level.waypoints = maps\mp\bots\waypoints\firingrange::Firingrange();
			break;
			case "mp_shipment":
				level.waypoints = maps\mp\bots\waypoints\shipment::Shipment();
			break;
			case "mp_shipment_long":
				level.waypoints = maps\mp\bots\waypoints\shipmentlong::ShipmentLong();
			break;
			case "mp_rust_long":
				level.waypoints = maps\mp\bots\waypoints\rustlong::Rustlong();
			break;
			
			case "invasion":
				level.waypoints = maps\mp\bots\waypoints\burgertown::Burgertown();
			break;
			case "iw4_credits":
				level.waypoints = maps\mp\bots\waypoints\testmap::Testmap();
			break;
			case "oilrig":
				level.waypoints = maps\mp\bots\waypoints\oilrig::Oilrig();
			break;
			case "co_hunted":
				level.waypoints = maps\mp\bots\waypoints\hunted::Hunted();
			break;
			case "contingency":
				level.waypoints = maps\mp\bots\waypoints\contingency::Contingency();
			break;
			case "gulag":
				level.waypoints = maps\mp\bots\waypoints\gulag::Gulag();
			break;
			case "so_ghillies":
				level.waypoints = maps\mp\bots\waypoints\pripyat::Pripyat();
			break;
			
			case "airport":
				level.waypoints = maps\mp\bots\waypoints\airport::Airport();
			break;
			case "ending":
				level.waypoints = maps\mp\bots\waypoints\museum::Museum();
			break;
			case "af_chase":
				level.waypoints = maps\mp\bots\waypoints\afghanchase::AfghanChase();
			break;
			case "trainer":
				level.waypoints = maps\mp\bots\waypoints\trainer::Trainer();
			break;
			case "roadkill":
				level.waypoints = maps\mp\bots\waypoints\roadkill::Roadkill();
			break;
			case "dcemp":
				level.waypoints = maps\mp\bots\waypoints\dcemp::DCEMP();
			break;
			
			case "dcburning":
				level.waypoints = maps\mp\bots\waypoints\dcburning::DCBurning();
			break;
			case "af_caves":
				level.waypoints = maps\mp\bots\waypoints\afghancaves::AfghanCaves();
			break;
			case "arcadia":
				level.waypoints = maps\mp\bots\waypoints\arcadia::Arcadia();
			break;
			case "boneyard":
				level.waypoints = maps\mp\bots\waypoints\boneyard::Boneyard();
			break;
			case "cliffhanger":
				level.waypoints = maps\mp\bots\waypoints\cliffhanger::Cliffhanger();
			break;
			case "downtown":
				level.waypoints = maps\mp\bots\waypoints\downtown::Downtown();
			break;
			case "estate":
				level.waypoints = maps\mp\bots\waypoints\estatesp::EstateSP();
			break;
			case "favela":
				level.waypoints = maps\mp\bots\waypoints\favelasp::FavelaSP();
			break;
			case "favela_escape":
				level.waypoints = maps\mp\bots\waypoints\favelaescape::FavelaEscape();
			break;
			case "so_bridge":
				level.waypoints = maps\mp\bots\waypoints\bridge::Bridge();
			break;
			case "dc_whitehouse":
				level.waypoints = maps\mp\bots\waypoints\whitehouse::Whitehouse();
			break;

			default:
				maps\mp\bots\waypoints\_custom_map::main(mapname);
			break;
		}
	}

	level.waypointCount = level.waypoints.size;
	
	for(i = 0; i < level.waypointCount; i++)
	{
		level.waypoints[i].index = i;
		level.waypoints[i].bots = [];
		level.waypoints[i].bots["allies"] = 1;
		level.waypoints[i].bots["axis"] = 1;
	}
	
	level.waypointsKDTree = WaypointsToKDTree();
	
	level.waypointsCamp = [];
	level.waypointsTube = [];
	level.waypointsGren = [];
	level.waypointsClay = [];
	level.waypointsJav = [];
	
	for(i = 0; i < level.waypointCount; i++)
		if(level.waypoints[i].type == "crouch" && level.waypoints[i].childCount == 1)
			level.waypointsCamp[level.waypointsCamp.size] = level.waypoints[i];
		else if(level.waypoints[i].type == "tube")
			level.waypointsTube[level.waypointsTube.size] = level.waypoints[i];
		else if(level.waypoints[i].type == "grenade")
			level.waypointsGren[level.waypointsGren.size] = level.waypoints[i];
		else if(level.waypoints[i].type == "claymore")
			level.waypointsClay[level.waypointsClay.size] = level.waypoints[i];
		else if(level.waypoints[i].type == "javelin")
			level.waypointsJav[level.waypointsJav.size] = level.waypoints[i];
}

getMapName(mapname)
{
  switch(mapname)
	{
		case "mp_abandon":
			return "Carnival";
		case "mp_rundown":
			return "Rundown";
		case "mp_afghan":
			return "Afghan";
		case "mp_boneyard":
			return "Scrapyard";
		case "mp_brecourt":
			return "Wasteland";
		case "mp_cargoship":
			return "Wetwork";
		case "mp_checkpoint":
			return "Karachi";
		case "mp_compact":
			return "Salvage";
		case "mp_complex":
			return "Bailout";
		case "mp_crash":
			return "Crash";
		case "mp_cross_fire":
			return "Crossfire";
		case "mp_derail":
			return "Derail";
		case "mp_estate":
			return "Estate";
		case "mp_favela":
			return "Favela";
		case "mp_fuel2":
			return "Fuel";
		case "mp_highrise":
			return "Highrise";
		case "mp_invasion":
			return "Invasion";
		case "mp_killhouse":
			return "Killhouse";
		case "mp_nightshift":
			return "Skidrow";
		case "mp_nuked":
			return "Nuketown";
		case "oilrig":
			return "Oilrig";
		case "mp_quarry":
			return "Quarry";
		case "mp_rust":
			return "Rust";
		case "mp_storm":
			return "Storm";
		case "mp_strike":
			return "Strike";
		case "mp_subbase":
			return "Subbase";
		case "mp_terminal":
			return "Terminal";
		case "mp_trailerpark":
			return "Trailer Park";
		case "mp_overgrown":
			return "Overgrown";
		case "mp_underpass":
			return "Underpass";
		case "mp_vacant":
			return "Vacant";
		case "iw4_credits":
			return "IW4 Test Map";
		case "airport":
			return "Airport";
		case "co_hunted":
			return "Hunted";
		case "invasion":
			return "Burgertown";
		case "mp_bloc":
			return "Bloc";
		case "mp_bog_sh":
			return "Bog";
		case "contingency":
			return "Contingency";
		case "gulag":
			return "Gulag";
		case "so_ghillies":
			return "Pripyat";
		case "ending":
			return "Museum";
		case "af_chase":
			return "Afghan Chase";
		case "af_caves":
			return "Afghan Caves";
		case "arcadia":
			return "Arcadia";
		case "boneyard":
			return "Boneyard";
		case "cliffhanger":
			return "Cliffhanger";
		case "dcburning":
			return "DCBurning";
		case "dcemp":
			return "DCEMP";
		case "downtown":
			return "Downtown";
		case "estate":
			return "EstateSP";
		case "favela":
			return "FavelaSP";
		case "favela_escape":
			return "Favela Escape";
		case "roadkill":
			return "Roadkill";
		case "trainer":
			return "TH3 PIT";
		case "so_bridge":
			return "Bridge";
		case "dc_whitehouse":
			return "Whitehouse";
		case "mp_shipment_long":
			return "ShipmentLong";
		case "mp_shipment":
			return "Shipment";
		case "mp_firingrange":
			return "Firing Range";
		case "mp_rust_long":
			return "RustLong";
		case "mp_cargoship_sh":
			return "Freighter";
		case "mp_storm_spring":
			return "Chemical Plant";
		case "mp_crash_trop":
		case "mp_crash_tropical":
			return "Crash Tropical";
		case "mp_fav_tropical":
			return "Favela Tropical";
		case "mp_estate_trop":
		case "mp_estate_tropical":
			return "Estate Tropical";
		case "mp_bloc_sh":
			return "Forgotten City";
		default:
			return mapname;
	}
}

/*
	Returns a good amount of players.
*/
getGoodMapAmount()
{
	switch(getdvar("mapname"))
	{
		case "mp_rust":
		case "iw4_credits":
		case "mp_nuked":
		case "oilrig":
		case "mp_killhouse":
		case "invasion":
		case "mp_bog_sh":
		case "co_hunted":
		case "contingency":
		case "gulag":
		case "so_ghillies":
		case "ending":
		case "af_chase":
		case "af_caves":
		case "arcadia":
		case "boneyard":
		case "cliffhanger":
		case "dcburning":
		case "dcemp":
		case "downtown":
		case "estate":
		case "favela":
		case "favela_escape":
		case "roadkill":
		case "so_bridge":
		case "trainer":
		case "dc_whitehouse":
		case "mp_shipment":
			if(level.teambased)
				return 8;
			else
				return 4;
		case "mp_vacant":
		case "mp_terminal":
		case "mp_nightshift":
		case "mp_favela":
		case "mp_highrise":
		case "mp_boneyard":
		case "mp_subbase":
		case "mp_firingrange":
		case "mp_fav_tropical":
		case "mp_shipment_long":
		case "mp_rust_long":
			if(level.teambased)
				return 12;
			else
				return 8;
		case "mp_afghan":
		case "mp_crash":
		case "mp_brecourt":
		case "mp_cross_fire":
		case "mp_overgrown":
		case "mp_trailerpark":
		case "mp_underpass":
		case "mp_checkpoint":
		case "mp_quarry":
		case "mp_rundown":
		case "mp_cargoship":
		case "mp_estate":
		case "mp_bloc":
		case "mp_storm":
		case "mp_strike":
		case "mp_abandon":
		case "mp_complex":
		case "airport":
		case "mp_storm_spring":
		case "mp_crash_trop":
		case "mp_cargoship_sh":
		case "mp_estate_trop":
		case "mp_compact":
		case "mp_crash_tropical":
		case "mp_estate_tropical":
		case "mp_bloc_sh":
			if(level.teambased)
				return 14;
			else
				return 9;
		case "mp_fuel2":
		case "mp_invasion":
		case "mp_derail":
			if(level.teambased)
				return 16;
			else
				return 10;
		default:
			return 2;
	}
}

/*
	Returns an array of all the bots in the game.
*/
getBotArray()
{
	result = [];
	playercount = level.players.size;
	for(i = 0; i < playercount; i++)
	{
		player = level.players[i];
		
		if(!player is_bot())
			continue;
			
		result[result.size] = player;
	}
	
	return result;
}

/*
	We return a balanced KDTree from the waypoints.
*/
WaypointsToKDTree()
{
	kdTree = KDTree();
	
	kdTree _WaypointsToKDTree(level.waypoints, 0);
	
	return kdTree;
}

/*
	Recurive function. We construct a balanced KD tree by sorting the waypoints using heap sort.
*/
_WaypointsToKDTree(waypoints, dem)
{
	if(!waypoints.size)
		return;

	callbacksort = undefined;
	
	switch(dem)
	{
		case 0:
			callbacksort = ::HeapSortCoordX;
		break;
		case 1:
			callbacksort = ::HeapSortCoordY;
		break;
		case 2:
			callbacksort = ::HeapSortCoordZ;
		break;
	}
	
	heap = NewHeap(callbacksort);
	
	for(i = 0; i < waypoints.size; i++)
	{
		heap HeapInsert(waypoints[i]);
	}
	
	sorted = [];
	while(heap.data.size)
	{
		sorted[sorted.size] = heap.data[0];
		heap HeapRemove();
	}
	
	median = int(sorted.size/2);//use divide and conq
	
	left = [];
	right = [];
	for(i = 0; i < sorted.size; i++)
		if(i < median)
			right[right.size] = sorted[i];
		else if(i > median)
			left[left.size] = sorted[i];
	
	self KDTreeInsert(sorted[median]);
	
	_WaypointsToKDTree(left, (dem+1)%3);
	
	_WaypointsToKDTree(right, (dem+1)%3);
}

/*
	Returns a new list.
*/
List()
{
	list = spawnStruct();
	list.count = 0;
	list.data = [];
	
	return list;
}

/*
	Adds a new thing to the list.
*/
ListAdd(thing)
{
	self.data[self.count] = thing;
	
	self.count++;
}

/*
	Adds to the start of the list.
*/
ListAddFirst(thing)
{
	for (i = self.count - 1; i >= 0; i--)
	{
		self.data[i + 1] = self.data[i];
	}

	self.data[0] = thing;
	self.count++;
}

/*
	Removes the thing from the list.
*/
ListRemove(thing)
{
	for ( i = 0; i < self.count; i++ )
	{
		if ( self.data[i] == thing )
		{
			while ( i < self.count-1 )
			{
				self.data[i] = self.data[i+1];
				i++;
			}
			
			self.data[i] = undefined;
			self.count--;
			break;
		}
	}
}

/*
	Returns a new KDTree.
*/
KDTree()
{
	kdTree = spawnStruct();
	kdTree.root = undefined;
	kdTree.count = 0;
	
	return kdTree;
}

/*
	Called on a KDTree. Will insert the object into the KDTree.
*/
KDTreeInsert(data)//as long as what you insert has a .origin attru, it will work.
{
	self.root = self _KDTreeInsert(self.root, data, 0, -9999999999, -9999999999, -9999999999, 9999999999, 9999999999, 9999999999);
}

/*
	Recurive function that insert the object into the KDTree.
*/
_KDTreeInsert(node, data, dem, x0, y0, z0, x1, y1, z1)
{
	if(!isDefined(node))
	{
		r = spawnStruct();
		r.data = data;
		r.left = undefined;
		r.right = undefined;
		r.x0 = x0;
		r.x1 = x1;
		r.y0 = y0;
		r.y1 = y1;
		r.z0 = z0;
		r.z1 = z1;
		
		self.count++;
		
		return r;
	}
	
	switch(dem)
	{
		case 0:
			if(data.origin[0] < node.data.origin[0])
				node.left = self _KDTreeInsert(node.left, data, 1, x0, y0, z0, node.data.origin[0], y1, z1);
			else
				node.right = self _KDTreeInsert(node.right, data, 1, node.data.origin[0], y0, z0, x1, y1, z1);
		break;
		case 1:
			if(data.origin[1] < node.data.origin[1])
				node.left = self _KDTreeInsert(node.left, data, 2, x0, y0, z0, x1, node.data.origin[1], z1);
			else
				node.right = self _KDTreeInsert(node.right, data, 2, x0, node.data.origin[1], z0, x1, y1, z1);
		break;
		case 2:
			if(data.origin[2] < node.data.origin[2])
				node.left = self _KDTreeInsert(node.left, data, 0, x0, y0, z0, x1, y1, node.data.origin[2]);
			else
				node.right = self _KDTreeInsert(node.right, data, 0, x0, y0, node.data.origin[2], x1, y1, z1);
		break;
	}
	
	return node;
}

/*
	Called on a KDTree, will return the nearest object to the given origin.
*/
KDTreeNearest(origin)
{
	if(!isDefined(self.root))
		return undefined;
	
	return self _KDTreeNearest(self.root, origin, self.root.data, DistanceSquared(self.root.data.origin, origin), 0);
}

/*
	Recurive function that will retrieve the closest object to the query.
*/
_KDTreeNearest(node, point, closest, closestdist, dem)
{
	if(!isDefined(node))
	{
		return closest;
	}
	
	thisDis = DistanceSquared(node.data.origin, point);
	
	if(thisDis < closestdist)
	{
		closestdist = thisDis;
		closest = node.data;
	}
	
	if(node RectDistanceSquared(point) < closestdist)
	{
		near = node.left;
		far = node.right;
		if(point[dem] > node.data.origin[dem])
		{
			near = node.right;
			far = node.left;
		}
		
		closest = self _KDTreeNearest(near, point, closest, closestdist, (dem+1)%3);
		
		closest = self _KDTreeNearest(far, point, closest, DistanceSquared(closest.origin, point), (dem+1)%3);
	}
	
	return closest;
}

/*
	Called on a rectangle, returns the distance from origin to the rectangle.
*/
RectDistanceSquared(origin)
{
	dx = 0;
	dy = 0;
	dz = 0;
	
	if(origin[0] < self.x0)
		dx = origin[0] - self.x0;
	else if(origin[0] > self.x1)
		dx = origin[0] - self.x1;
		
	if(origin[1] < self.y0)
		dy = origin[1] - self.y0;
	else if(origin[1] > self.y1)
		dy = origin[1] - self.y1;

		
	if(origin[2] < self.z0)
		dz = origin[2] - self.z0;
	else if(origin[2] > self.z1)
		dz = origin[2] - self.z1;
		
	return dx*dx + dy*dy + dz*dz;
}

/*
	A heap invarient comparitor, used for objects, objects with a higher X coord will be first in the heap.
*/
HeapSortCoordX(item, item2)
{
	return item.origin[0] > item2.origin[0];
}

/*
	A heap invarient comparitor, used for objects, objects with a higher Y coord will be first in the heap.
*/
HeapSortCoordY(item, item2)
{
	return item.origin[1] > item2.origin[1];
}

/*
	A heap invarient comparitor, used for objects, objects with a higher Z coord will be first in the heap.
*/
HeapSortCoordZ(item, item2)
{
	return item.origin[2] > item2.origin[2];
}

/*
	A heap invarient comparitor, used for numbers, numbers with the highest number will be first in the heap.
*/
Heap(item, item2)
{
	return item > item2;
}

/*
	A heap invarient comparitor, used for numbers, numbers with the lowest number will be first in the heap.
*/
ReverseHeap(item, item2)
{
	return item < item2;
}

/*
	A heap invarient comparitor, used for traces. Wanting the trace with the largest length first in the heap.
*/
HeapTraceFraction(item, item2)
{
	return item["fraction"] > item2["fraction"];
}

/*
	Returns a new heap.
*/
NewHeap(compare)
{
	heap_node = spawnStruct();
	heap_node.data = [];
	heap_node.compare = compare;
	
	return heap_node;
}

/*
	Inserts the item into the heap. Called on a heap.
*/
HeapInsert(item)
{
	insert = self.data.size;
	self.data[insert] = item;
	
	current = insert+1;
	
	while(current > 1)
	{
		last = current;
		current = int(current/2);
		
		if(![[self.compare]](item, self.data[current-1]))
			break;
			
		self.data[last-1] = self.data[current-1];
		self.data[current-1] = item;
	}
}

/*
	Helper function to determine what is the next child of the bst.
*/
_HeapNextChild(node, hsize)
{
	left = node * 2;
	right = left + 1;
	
	if(left > hsize)
		return -1;
		
	if(right > hsize)
		return left;
		
	if([[self.compare]](self.data[left-1], self.data[right-1]))
		return left;
	else
		return right;
}

/*
	Removes an item from the heap. Called on a heap.
*/
HeapRemove()
{
	remove = self.data.size;
	
	if(!remove)
		return remove;
	
	move = self.data[remove-1];
	self.data[0] = move;
	self.data[remove-1] = undefined;
	remove--;
	
	if(!remove)
		return remove;
	
	last = 1;
	next = self _HeapNextChild(1, remove);
	
	while(next != -1)
	{
		if([[self.compare]](move, self.data[next-1]))
			break;
			
		self.data[last-1] = self.data[next-1];
		self.data[next-1] = move;
		
		last = next;
		next = self _HeapNextChild(next, remove);
	}
	
	return remove;
}

/*
	A heap invarient comparitor, used for the astar's nodes, wanting the node with the lowest f to be first in the heap.
*/
ReverseHeapAStar(item, item2)
{
	return item.f < item2.f;
}

/*
	Will linearly search for the nearest waypoint to pos that has a direct line of sight.
*/
GetNearestWaypointWithSight(pos)
{
	candidate = undefined;
	dist = 9999999999;
	
	for(i = 0; i < level.waypointCount; i++)
	{
		if(!bulletTracePassed(pos + (0, 0, 15), level.waypoints[i].origin + (0, 0, 15), false, undefined))
			continue;
		
		curdis = DistanceSquared(level.waypoints[i].origin, pos);
		if(curdis > dist)
			continue;
			
		dist = curdis;
		candidate = level.waypoints[i];
	}
	
	return candidate;
}

/*
	Modified Pezbot astar search.
	This makes use of sets for quick look up and a heap for a priority queue instead of simple lists which require to linearly search for elements everytime.
	Also makes use of the KD tree to search for the nearest node to the goal. We only use the closest node from the KD tree if it has a direct line of sight, else we will have to linearly search for one that we have a line of sight on.
	It is also modified to make paths with bots already on more expensive and will try a less congested path first. Thus spliting up the bots onto more paths instead of just one (the smallest).
*/
AStarSearch(start, goal, team, greedy_path)
{
	open = NewHeap(::ReverseHeapAStar);//heap
	openset = [];//set for quick lookup
	
	closed = [];//set for quick lookup
	
	startwp = level.waypointsKDTree KDTreeNearest(start);//balanced kdtree, for nns
	if(!isDefined(startwp))
		return [];
	_startwp = undefined;
	if(!bulletTracePassed(start + (0, 0, 15), startwp.origin + (0, 0, 15), false, undefined))
		_startwp = GetNearestWaypointWithSight(start);
	if(isDefined(_startwp))
		startwp = _startwp;
	startwp = startwp.index;
	
	goalwp = level.waypointsKDTree KDTreeNearest(goal);
	if(!isDefined(goalwp))
		return [];
	_goalwp = undefined;
	if(!bulletTracePassed(goal + (0, 0, 15), goalwp.origin + (0, 0, 15), false, undefined))
		_goalwp = GetNearestWaypointWithSight(goal);
	if(isDefined(_goalwp))
		goalwp = _goalwp;
	goalwp = goalwp.index;
	
	goalorg = level.waypoints[goalWp].origin;
	
	node = spawnStruct();
	node.g = 0; //path dist so far
	node.h = DistanceSquared(level.waypoints[startWp].origin, goalorg); //herustic, distance to goal for path finding
	//node.f = node.h + node.g; // combine path dist and heru, use reverse heap to sort the priority queue by this attru
	node.f = node.h;
	node.index = startwp;
	node.parent = undefined; //we are start, so we have no parent
	
	//push node onto queue
	openset[node.index] = node;
	open HeapInsert(node);
	
	//while the queue is not empty
	while(open.data.size)
	{
		//pop bestnode from queue
		bestNode = open.data[0];
		open HeapRemove();
		openset[bestNode.index] = undefined;
		
		//check if we made it to the goal
		if(bestNode.index == goalwp)
		{
			path = [];
		
			while(isDefined(bestNode))
			{
				if(isdefined(team))
					level.waypoints[bestNode.index].bots[team]++;
					
				//construct path
				path[path.size] = bestNode.index;
				
				bestNode = bestNode.parent;
			}
			
			return path;
		}
		
		nodeorg = level.waypoints[bestNode.index].origin;
		childcount = level.waypoints[bestNode.index].childCount;
		//for each child of bestnode
		for(i = 0; i < childcount; i++)
		{
			child = level.waypoints[bestNode.index].children[i];
			childorg = level.waypoints[child].origin;
			
			penalty = 1;
			if(!greedy_path && isdefined(team))
			{
				temppen = level.waypoints[child].bots[team];//consider how many bots are taking this path
				if(temppen > 1)
					penalty = temppen;
			}
			
			//calc the total path we have took
			newg = bestNode.g + DistanceSquared(nodeorg, childorg)*penalty;//bots on same team's path are more expensive
			
			//check if this child is in open or close with a g value less than newg
			inopen = isDefined(openset[child]);
			if(inopen && openset[child].g <= newg)
				continue;
			
			inclosed = isDefined(closed[child]);
			if(inclosed && closed[child].g <= newg)
				continue;
			
			if(inopen)
				node = openset[child];
			else if(inclosed)
				node = closed[child];
			else
				node = spawnStruct();
				
			node.parent = bestNode;
			node.g = newg;
			node.h = DistanceSquared(childorg, goalorg);
			node.f = node.g + node.h;
			node.index = child;
			
			//check if in closed, remove it
			if(inclosed)
				closed[child] = undefined;
			
			//check if not in open, add it
			if(!inopen)
			{
				open HeapInsert(node);
				openset[child] = node;
			}
		}
		
		//done with children, push onto closed
		closed[bestNode.index] = bestNode;
	}
	
	return [];
}

/*
	Taken from t5 gsc.
	Returns an array of number's average.
*/
array_average( array )
{
	assert( array.size > 0 );
	total = 0;
	for ( i = 0; i < array.size; i++ )
	{
		total += array[i];
	}
	return ( total / array.size );
}

/*
	Taken from t5 gsc.
	Returns an array of number's standard deviation.
*/
array_std_deviation( array, mean )
{
	assert( array.size > 0 );
	tmp = [];
	for ( i = 0; i < array.size; i++ )
	{
		tmp[i] = ( array[i] - mean ) * ( array[i] - mean );
	}
	total = 0;
	for ( i = 0; i < tmp.size; i++ )
	{
		total = total + tmp[i];
	}
	return Sqrt( total / array.size );
}

/*
	Taken from t5 gsc.
	Will produce a random number between lower_bound and upper_bound but with a bell curve distribution (more likely to be close to the mean).
*/
random_normal_distribution( mean, std_deviation, lower_bound, upper_bound )
{
	x1 = 0;
	x2 = 0;
	w = 1;
	y1 = 0;
	while ( w >= 1 )
	{
		x1 = 2 * RandomFloatRange( 0, 1 ) - 1;
		x2 = 2 * RandomFloatRange( 0, 1 ) - 1;
		w = x1 * x1 + x2 * x2;
	}
	w = Sqrt( ( -2.0 * Log( w ) ) / w );
	y1 = x1 * w;
	number = mean + y1 * std_deviation;
	if ( IsDefined( lower_bound ) && number < lower_bound )
	{
		number = lower_bound;
	}
	if ( IsDefined( upper_bound ) && number > upper_bound )
	{
		number = upper_bound;
	}
	
	return( number );
}

onUsePlantObjectFix( player )
{
	// planted the bomb
	if ( !self maps\mp\gametypes\_gameobjects::isFriendlyTeam( player.pers["team"] ) )
	{
		level thread bombPlantedFix( self, player );
		//player logString( "bomb planted: " + self.label );
		
		// disable all bomb zones except this one
		for ( index = 0; index < level.bombZones.size; index++ )
		{
			if ( level.bombZones[index] == self )
				continue;
				
			level.bombZones[index] maps\mp\gametypes\_gameobjects::disableObject();
		}
		
		player playSound( "mp_bomb_plant" );
		player notify ( "bomb_planted" );

		//if ( !level.hardcoreMode )
		//	iPrintLn( &"MP_EXPLOSIVES_PLANTED_BY", player );

		leaderDialog( "bomb_planted" );

		level thread teamPlayerCardSplash( "callout_bombplanted", player );

		level.bombOwner = player;
		player thread maps\mp\gametypes\_hud_message::SplashNotify( "plant", maps\mp\gametypes\_rank::getScoreInfoValue( "plant" ) );
		player thread maps\mp\gametypes\_rank::giveRankXP( "plant" );
		player.bombPlantedTime = getTime();
		maps\mp\gametypes\_gamescore::givePlayerScore( "plant", player );	
		player incPlayerStat( "bombsplanted", 1 );
		player thread maps\mp\_matchdata::logGameEvent( "plant", player.origin );
	}
}

bombPlantedFix( destroyedObj, player )
{
	maps\mp\gametypes\_gamelogic::pauseTimer();
	level.bombPlanted = true;
	
	destroyedObj.visuals[0] thread maps\mp\gametypes\_gamelogic::playTickingSound();
	level.tickingObject = destroyedObj.visuals[0];

	level.timeLimitOverride = true;
	setGameEndTime( int( gettime() + (level.bombTimer * 1000) ) );
	setDvar( "ui_bomb_timer", 1 );
	
	if ( !level.multiBomb )
	{
		level.sdBomb maps\mp\gametypes\_gameobjects::allowCarry( "none" );
		level.sdBomb maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
		level.sdBomb maps\mp\gametypes\_gameobjects::setDropped();
		level.sdBombModel = level.sdBomb.visuals[0];
	}
	else
	{
		
		for ( index = 0; index < level.players.size; index++ )
		{
			if ( isDefined( level.players[index].carryIcon ) )
				level.players[index].carryIcon destroyElem();
		}

		trace = bulletTrace( player.origin + (0,0,20), player.origin - (0,0,2000), false, player );
		
		tempAngle = randomfloat( 360 );
		forward = (cos( tempAngle ), sin( tempAngle ), 0);
		forward = vectornormalize( forward - common_scripts\utility::vector_multiply( trace["normal"], vectordot( forward, trace["normal"] ) ) );
		dropAngles = vectortoangles( forward );
		
		level.sdBombModel = spawn( "script_model", trace["position"] );
		level.sdBombModel.angles = dropAngles;
		level.sdBombModel setModel( "prop_suitcase_bomb" );
	}
	destroyedObj maps\mp\gametypes\_gameobjects::allowUse( "none" );
	destroyedObj maps\mp\gametypes\_gameobjects::setVisibleTeam( "none" );
	/*
	destroyedObj maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", undefined );
	destroyedObj maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", undefined );
	destroyedObj maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", undefined );
	destroyedObj maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", undefined );
	*/
	label = destroyedObj maps\mp\gametypes\_gameobjects::getLabel();
	
	// create a new object to defuse with.
	trigger = destroyedObj.bombDefuseTrig;
	trigger.origin = level.sdBombModel.origin;
	visuals = [];
	defuseObject = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, (0,0,32) );
	defuseObject maps\mp\gametypes\_gameobjects::allowUse( "friendly" );
	defuseObject maps\mp\gametypes\_gameobjects::setUseTime( level.defuseTime );
	defuseObject maps\mp\gametypes\_gameobjects::setUseText( &"MP_DEFUSING_EXPLOSIVE" );
	defuseObject maps\mp\gametypes\_gameobjects::setUseHintText( &"PLATFORM_HOLD_TO_DEFUSE_EXPLOSIVES" );
	defuseObject maps\mp\gametypes\_gameobjects::setVisibleTeam( "any" );
	defuseObject maps\mp\gametypes\_gameobjects::set2DIcon( "friendly", "waypoint_defuse" + label );
	defuseObject maps\mp\gametypes\_gameobjects::set2DIcon( "enemy", "waypoint_defend" + label );
	defuseObject maps\mp\gametypes\_gameobjects::set3DIcon( "friendly", "waypoint_defuse" + label );
	defuseObject maps\mp\gametypes\_gameobjects::set3DIcon( "enemy", "waypoint_defend" + label );
	defuseObject.label = label;
	defuseObject.onBeginUse = maps\mp\gametypes\sd::onBeginUse;
	defuseObject.onEndUse = maps\mp\gametypes\sd::onEndUse;
	defuseObject.onUse = maps\mp\gametypes\sd::onUseDefuseObject;
	defuseObject.useWeapon = "briefcase_bomb_defuse_mp";
	
	level.defuseObject = defuseObject;
	
	maps\mp\gametypes\sd::BombTimerWait();
	setDvar( "ui_bomb_timer", 0 );
	
	destroyedObj.visuals[0] maps\mp\gametypes\_gamelogic::stopTickingSound();
	
	if ( level.gameEnded || level.bombDefused )
		return;
	
	level.bombExploded = true;
	
	explosionOrigin = level.sdBombModel.origin;
	level.sdBombModel hide();
	
	if ( isdefined( player ) )
	{
		destroyedObj.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20, player );
		player incPlayerStat( "targetsdestroyed", 1 );
	}
	else
		destroyedObj.visuals[0] radiusDamage( explosionOrigin, 512, 200, 20 );
	
	rot = randomfloat(360);
	explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + (0,0,50), (0,0,1), (cos(rot),sin(rot),0) );
	triggerFx( explosionEffect );

	PlayRumbleOnPosition( "grenade_rumble", explosionOrigin );
	earthquake( 0.75, 2.0, explosionOrigin, 2000 );
	
	thread playSoundinSpace( "exp_suitcase_bomb_main", explosionOrigin );
	
	if ( isDefined( destroyedObj.exploderIndex ) )
		exploder( destroyedObj.exploderIndex );
	
	for ( index = 0; index < level.bombZones.size; index++ )
		level.bombZones[index] maps\mp\gametypes\_gameobjects::disableObject();
	defuseObject maps\mp\gametypes\_gameobjects::disableObject();
	
	setGameEndTime( 0 );
	
	wait 3;
	
	maps\mp\gametypes\sd::sd_endGame( game["attackers"], game["strings"]["target_destroyed"] );
}

botGiveLoadout( team, class, allowCopycat )
{
	self takeAllWeapons();
	
	primaryIndex = 0;
	
	// initialize specialty array
	self.specialty = [];

	if ( !isDefined( allowCopycat ) )
		allowCopycat = true;

	primaryWeapon = undefined;

	if ( isDefined( self.pers["copyCatLoadout"] ) && self.pers["copyCatLoadout"]["inUse"] && allowCopycat )
	{
		self maps\mp\gametypes\_class::setClass( "copycat" );
		self.class_num = maps\mp\gametypes\_class::getClassIndex( "copycat" );

		clonedLoadout = self.pers["copyCatLoadout"];

		loadoutPrimary = clonedLoadout["loadoutPrimary"];
		loadoutPrimaryAttachment = clonedLoadout["loadoutPrimaryAttachment"];
		loadoutPrimaryAttachment2 = clonedLoadout["loadoutPrimaryAttachment2"] ;
		loadoutPrimaryCamo = clonedLoadout["loadoutPrimaryCamo"];
		loadoutSecondary = clonedLoadout["loadoutSecondary"];
		loadoutSecondaryAttachment = clonedLoadout["loadoutSecondaryAttachment"];
		loadoutSecondaryAttachment2 = clonedLoadout["loadoutSecondaryAttachment2"];
		loadoutSecondaryCamo = clonedLoadout["loadoutSecondaryCamo"];
		loadoutEquipment = clonedLoadout["loadoutEquipment"];
		loadoutPerk1 = clonedLoadout["loadoutPerk1"];
		loadoutPerk2 = clonedLoadout["loadoutPerk2"];
		loadoutPerk3 = clonedLoadout["loadoutPerk3"];
		loadoutOffhand = clonedLoadout["loadoutOffhand"];
		loadoutDeathStreak = "specialty_copycat";		
	}
	else if ( isSubstr( class, "custom" ) )
	{
		class_num = maps\mp\gametypes\_class::getClassIndex( class );
		self.class_num = class_num;

		loadoutPrimary = maps\mp\gametypes\_class::cac_getWeapon( class_num, 0 );
		loadoutPrimaryAttachment = maps\mp\gametypes\_class::cac_getWeaponAttachment( class_num, 0 );
		loadoutPrimaryAttachment2 = maps\mp\gametypes\_class::cac_getWeaponAttachmentTwo( class_num, 0 );
		loadoutPrimaryCamo = maps\mp\gametypes\_class::cac_getWeaponCamo( class_num, 0 );
		loadoutSecondaryCamo = maps\mp\gametypes\_class::cac_getWeaponCamo( class_num, 1 );
		loadoutSecondary = maps\mp\gametypes\_class::cac_getWeapon( class_num, 1 );
		loadoutSecondaryAttachment = maps\mp\gametypes\_class::cac_getWeaponAttachment( class_num, 1 );
		loadoutSecondaryAttachment2 = maps\mp\gametypes\_class::cac_getWeaponAttachmentTwo( class_num, 1 );
		loadoutSecondaryCamo = maps\mp\gametypes\_class::cac_getWeaponCamo( class_num, 1 );
		loadoutEquipment = maps\mp\gametypes\_class::cac_getPerk( class_num, 0 );
		loadoutPerk1 = maps\mp\gametypes\_class::cac_getPerk( class_num, 1 );
		loadoutPerk2 = maps\mp\gametypes\_class::cac_getPerk( class_num, 2 );
		loadoutPerk3 = maps\mp\gametypes\_class::cac_getPerk( class_num, 3 );
		loadoutOffhand = maps\mp\gametypes\_class::cac_getOffhand( class_num );
		loadoutDeathStreak = maps\mp\gametypes\_class::cac_getDeathstreak( class_num );
	}
	else
	{
		class_num = maps\mp\gametypes\_class::getClassIndex( class );
		self.class_num = class_num;
		
		loadoutPrimary = maps\mp\gametypes\_class::table_getWeapon( level.classTableName, class_num, 0 );
		loadoutPrimaryAttachment = maps\mp\gametypes\_class::table_getWeaponAttachment( level.classTableName, class_num, 0 , 0);
		loadoutPrimaryAttachment2 = maps\mp\gametypes\_class::table_getWeaponAttachment( level.classTableName, class_num, 0, 1 );
		loadoutPrimaryCamo = maps\mp\gametypes\_class::table_getWeaponCamo( level.classTableName, class_num, 0 );
		loadoutSecondaryCamo = maps\mp\gametypes\_class::table_getWeaponCamo( level.classTableName, class_num, 1 );
		loadoutSecondary = maps\mp\gametypes\_class::table_getWeapon( level.classTableName, class_num, 1 );
		loadoutSecondaryAttachment = maps\mp\gametypes\_class::table_getWeaponAttachment( level.classTableName, class_num, 1 , 0);
		loadoutSecondaryAttachment2 = maps\mp\gametypes\_class::table_getWeaponAttachment( level.classTableName, class_num, 1, 1 );;
		loadoutSecondaryCamo = maps\mp\gametypes\_class::table_getWeaponCamo( level.classTableName, class_num, 1 );
		loadoutEquipment = maps\mp\gametypes\_class::table_getEquipment( level.classTableName, class_num, 0 );
		loadoutPerk1 = maps\mp\gametypes\_class::table_getPerk( level.classTableName, class_num, 1 );
		loadoutPerk2 = maps\mp\gametypes\_class::table_getPerk( level.classTableName, class_num, 2 );
		loadoutPerk3 = maps\mp\gametypes\_class::table_getPerk( level.classTableName, class_num, 3 );
		loadoutOffhand = maps\mp\gametypes\_class::table_getOffhand( level.classTableName, class_num );
		loadoutDeathstreak = maps\mp\gametypes\_class::table_getDeathstreak( level.classTableName, class_num );
	}

	if ( loadoutPerk1 != "specialty_bling" )
	{
		loadoutPrimaryAttachment2 = "none";
		loadoutSecondaryAttachment2 = "none";
	}
	
	if ( loadoutPerk1 != "specialty_onemanarmy" && loadoutSecondary == "onemanarmy" )
		loadoutSecondary = maps\mp\gametypes\_class::table_getWeapon( level.classTableName, 10, 1 );

	//loadoutSecondaryCamo = "none";


	if ( level.killstreakRewards )
	{
		if ( getDvarInt( "scr_classic" ) == 1 )
		{
			loadoutKillstreak1 = "uav";
			loadoutKillstreak2 = "precision_airstrike";
			loadoutKillstreak3 = "helicopter";
		}
		else
		{
			loadoutKillstreak1 = self getPlayerData( "killstreaks", 0 );
			loadoutKillstreak2 = self getPlayerData( "killstreaks", 1 );
			loadoutKillstreak3 = self getPlayerData( "killstreaks", 2 );
		}
	}
	else
	{
		loadoutKillstreak1 = "none";
		loadoutKillstreak2 = "none";
		loadoutKillstreak3 = "none";
	}
	
	secondaryName = maps\mp\gametypes\_class::buildWeaponName( loadoutSecondary, loadoutSecondaryAttachment, loadoutSecondaryAttachment2 );
	self _giveWeapon( secondaryName, int(tableLookup( "mp/camoTable.csv", 1, loadoutSecondaryCamo, 0 ) ) );

	self.loadoutPrimaryCamo = int(tableLookup( "mp/camoTable.csv", 1, loadoutPrimaryCamo, 0 ));
	self.loadoutPrimary = loadoutPrimary;
	self.loadoutSecondary = loadoutSecondary;
	self.loadoutSecondaryCamo = int(tableLookup( "mp/camoTable.csv", 1, loadoutSecondaryCamo, 0 ));
	
	self SetOffhandPrimaryClass( "other" );
	
	// Action Slots
	//self _SetActionSlot( 1, "" );
	self _SetActionSlot( 1, "nightvision" );
	self _SetActionSlot( 3, "altMode" );
	self _SetActionSlot( 4, "" );

	// Perks
	self _clearPerks();
	self maps\mp\gametypes\_class::_detachAll();
	
	// these special case giving pistol death have to come before
	// perk loadout to ensure player perk icons arent overwritten
	if ( level.dieHardMode )
		self maps\mp\perks\_perks::givePerk( "specialty_pistoldeath" );
	
	// only give the deathstreak for the initial spawn for this life.
	if ( loadoutDeathStreak != "specialty_null" && (getTime() - self.spawnTime) < 0.1 )
	{
		deathVal = int( tableLookup( "mp/perkTable.csv", 1, loadoutDeathStreak, 6 ) );
				
		if ( self botGetPerkUpgrade( loadoutPerk1 ) == "specialty_rollover" || self botGetPerkUpgrade( loadoutPerk2 ) == "specialty_rollover" || self botGetPerkUpgrade( loadoutPerk3 ) == "specialty_rollover" )
			deathVal -= 1;
		
		if ( self.pers["cur_death_streak"] == deathVal )
		{
			self thread maps\mp\perks\_perks::givePerk( loadoutDeathStreak );
			self thread maps\mp\gametypes\_hud_message::splashNotify( loadoutDeathStreak );
		}
		else if ( self.pers["cur_death_streak"] > deathVal )
		{
			self thread maps\mp\perks\_perks::givePerk( loadoutDeathStreak );
		}
	}

	self botLoadoutAllPerks( loadoutEquipment, loadoutPerk1, loadoutPerk2, loadoutPerk3 );
		
	self maps\mp\gametypes\_class::setKillstreaks( loadoutKillstreak1, loadoutKillstreak2, loadoutKillstreak3 );
		
	if ( self hasPerk( "specialty_extraammo", true ) && getWeaponClass( secondaryName ) != "weapon_projectile" )
		self giveMaxAmmo( secondaryName );

	// Primary Weapon
	primaryName = maps\mp\gametypes\_class::buildWeaponName( loadoutPrimary, loadoutPrimaryAttachment, loadoutPrimaryAttachment2 );
	self _giveWeapon( primaryName, self.loadoutPrimaryCamo );
	
	// fix changing from a riotshield class to a riotshield class during grace period not giving a shield
	if ( primaryName == "riotshield_mp" && level.inGracePeriod )
		self notify ( "weapon_change", "riotshield_mp" );

	if ( self hasPerk( "specialty_extraammo", true ) )
		self giveMaxAmmo( primaryName );

	self setSpawnWeapon( primaryName );
	
	primaryTokens = strtok( primaryName, "_" );
	self.pers["primaryWeapon"] = primaryTokens[0];
	
	// Primary Offhand was given by givePerk (it's your perk1)
	
	// Secondary Offhand
	offhandSecondaryWeapon = loadoutOffhand + "_mp";
	if ( loadoutOffhand == "flash_grenade" )
		self SetOffhandSecondaryClass( "flash" );
	else
		self SetOffhandSecondaryClass( "smoke" );
	
	self giveWeapon( offhandSecondaryWeapon );
	if( loadOutOffhand == "smoke_grenade" )
		self setWeaponAmmoClip( offhandSecondaryWeapon, 1 );
	else if( loadOutOffhand == "flash_grenade" )
		self setWeaponAmmoClip( offhandSecondaryWeapon, 2 );
	else if( loadOutOffhand == "concussion_grenade" )
		self setWeaponAmmoClip( offhandSecondaryWeapon, 2 );
	else
		self setWeaponAmmoClip( offhandSecondaryWeapon, 1 );
	
	primaryWeapon = primaryName;
	self.primaryWeapon = primaryWeapon;
	self.secondaryWeapon = secondaryName;

	self botPlayerModelForWeapon( self.pers["primaryWeapon"], getBaseWeaponName( secondaryName ) );
		
	self.isSniper = (weaponClass( self.primaryWeapon ) == "sniper");
	
	self maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );

	// cac specialties that require loop threads
	self maps\mp\perks\_perks::cac_selector();
	
	self notify ( "changed_kit" );
}

botGetPerkUpgrade( perkName )
{
	perkUpgrade = tablelookup( "mp/perktable.csv", 1, perkName, 8 );
	
	if ( perkUpgrade == "" || perkUpgrade == "specialty_null" )
		return "specialty_null";
		
	if ( !isDefined(self.pers["bots"]["unlocks"]["upgraded_"+perkName]) || !self.pers["bots"]["unlocks"]["upgraded_"+perkName] )
		return "specialty_null";
		
	return ( perkUpgrade );
}

botLoadoutAllPerks( loadoutEquipment, loadoutPerk1, loadoutPerk2, loadoutPerk3 )
{
	loadoutEquipment = maps\mp\perks\_perks::validatePerk( 1, loadoutEquipment );
	loadoutPerk1 = maps\mp\perks\_perks::validatePerk( 1, loadoutPerk1 );
	loadoutPerk2 = maps\mp\perks\_perks::validatePerk( 2, loadoutPerk2 );
	loadoutPerk3 = maps\mp\perks\_perks::validatePerk( 3, loadoutPerk3 );

	self maps\mp\perks\_perks::givePerk( loadoutEquipment );
	self maps\mp\perks\_perks::givePerk( loadoutPerk1 );
	self maps\mp\perks\_perks::givePerk( loadoutPerk2 );
	self maps\mp\perks\_perks::givePerk( loadoutPerk3 );

	perks[0] = loadoutPerk1;
	perks[1] = loadoutPerk2;
	perks[2] = loadoutPerk3;
	
	perkUpgrd[0] = tablelookup( "mp/perktable.csv", 1, loadoutPerk1, 8 );
	perkUpgrd[1] = tablelookup( "mp/perktable.csv", 1, loadoutPerk2, 8 );
	perkUpgrd[2] = tablelookup( "mp/perktable.csv", 1, loadoutPerk3, 8 );

	for (i = 0; i < perkUpgrd.size; i++)
	{
		upgrade = perkUpgrd[i];
		perk = perks[i];

		if ( upgrade == "" || upgrade == "specialty_null" )
			continue;
			
		if ( isDefined(self.pers["bots"]["unlocks"]["upgraded_"+perk]) && self.pers["bots"]["unlocks"]["upgraded_"+perk] )
			self maps\mp\perks\_perks::givePerk( upgrade );
	}

}

botPlayerModelForWeapon( weapon, secondary )
{
	team = self.team;

	
	if ( isDefined( game[team + "_model"][weapon] ) )
	{
		[[game[team+"_model"][weapon]]]();
		return;
	}
	
	
	weaponClass = tablelookup( "mp/statstable.csv", 4, weapon, 2 );

	switch ( weaponClass )
	{
		case "weapon_smg":
			[[game[team+"_model"]["SMG"]]]();
			break;
		case "weapon_assault":
			weaponClass = tablelookup( "mp/statstable.csv", 4, secondary, 2 );
			if ( weaponClass == "weapon_shotgun" )
				[[game[team+"_model"]["SHOTGUN"]]]();
			else
				[[game[team+"_model"]["ASSAULT"]]]();
			break;
		case "weapon_sniper":
			if ( level.environment != "" && isDefined(self.pers["bots"]["unlocks"]["ghillie"]) && self.pers["bots"]["unlocks"]["ghillie"] )
				[[game[team+"_model"]["GHILLIE"]]]();
			else
				[[game[team+"_model"]["SNIPER"]]]();
			break;
		case "weapon_lmg":
			[[game[team+"_model"]["LMG"]]]();
			break;
		case "weapon_riot":
			[[game[team+"_model"]["RIOT"]]]();
			break;
		default:
			[[game[team+"_model"]["ASSAULT"]]]();
			break;
	}
}

claymoreDetonationBotFix()
{
	self endon( "death" );

	self waittill( "missile_stuck" );

	damagearea = spawn( "trigger_radius", self.origin + ( 0, 0, 0 - level.claymoreDetonateRadius ), 0, level.claymoreDetonateRadius, level.claymoreDetonateRadius * 2 );
	self thread maps\mp\gametypes\_weapons::deleteOnDeath( damagearea );

	while ( 1 )
	{
		damagearea waittill( "trigger", player );

		if (!player is_bot())
			continue;

		if ( getdvarint( "scr_claymoredebug" ) != 1 )
		{
			if ( isdefined( self.owner ) && player == self.owner )
				continue;
			if ( !maps\mp\gametypes\_weapons::friendlyFireCheck( self.owner, player, 0 ) )
				continue;
		}
		if ( lengthsquared( player getBotVelocity() ) < 10 )
			continue;

		if ( !player maps\mp\gametypes\_weapons::shouldAffectClaymore( self ) )
			continue;

		if ( player damageConeTrace( self.origin, self ) > 0 )
			break;
	}
	
	self playsound ("claymore_activated");
	
	
	if ( player _hasPerk( "specialty_delaymine" ) )
		wait 3.0;
	else 
		wait level.claymoreDetectionGracePeriod;
		
	self detonate();
}
