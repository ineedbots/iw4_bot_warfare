/*
	_bot_utility
	Author: INeedGames
	Date: 09/26/2020
	The shared functions for bots
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

/*
	Returns if player is the host
*/
is_host()
{
	return ( isDefined( self.pers["bot_host"] ) && self.pers["bot_host"] );
}

/*
	Setups the host variable on the player
*/
doHostCheck()
{
	self.pers["bot_host"] = false;

	if ( self is_bot() )
		return;

	result = false;

	if ( getDvar( "bots_main_firstIsHost" ) != "0" )
	{
		PrintConsole( "WARNING: bots_main_firstIsHost is enabled\n" );

		if ( getDvar( "bots_main_firstIsHost" ) == "1" )
		{
			setDvar( "bots_main_firstIsHost", self getguid() );
		}

		if ( getDvar( "bots_main_firstIsHost" ) == self getguid() + "" )
			result = true;
	}

	DvarGUID = getDvar( "bots_main_GUIDs" );

	if ( DvarGUID != "" )
	{
		guids = strtok( DvarGUID, "," );

		for ( i = 0; i < guids.size; i++ )
		{
			if ( self getguid() + "" == guids[i] )
				result = true;
		}
	}

	if ( !self isHost() && !result )
		return;

	self.pers["bot_host"] = true;
}

/*
	Returns if the player is a bot.
*/
is_bot()
{
	assert( isDefined( self ) );
	assert( isPlayer( self ) );

	return ( ( isDefined( self.pers["isBot"] ) && self.pers["isBot"] ) || ( isDefined( self.pers["isBotWarfare"] ) && self.pers["isBotWarfare"] ) || isSubStr( self getguid() + "", "bot" ) );
}

/*
	Bot changes to the weap
*/
BotChangeToWeapon( weap )
{
	self maps\mp\bots\_bot_internal::changeToWeap( weap );
}

/*
	Bot presses the frag button for time.
*/
BotPressFrag( time )
{
	self maps\mp\bots\_bot_internal::frag( time );
}

/*
	Bot presses the smoke button for time.
*/
BotPressSmoke( time )
{
	self maps\mp\bots\_bot_internal::smoke( time );
}

/*
	Bot will press the ads button for the time
*/
BotPressADS( time )
{
	self maps\mp\bots\_bot_internal::pressAds( time );
}

/*
	Bot presses the use button for time.
*/
BotPressUse( time )
{
	self maps\mp\bots\_bot_internal::use( time );
}

/*
	Bots will press the attack button for a time
*/
BotPressAttack( time )
{
	self maps\mp\bots\_bot_internal::pressFire( time );
}

/*
	Returns a random number thats different everytime it changes target
*/
BotGetTargetRandom()
{
	if ( !isDefined( self.bot.target ) )
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
	return self.bot.isfraggingafter;
}

/*
	Returns if the bot is pressing smoke button.
*/
IsBotSmoking()
{
	return self.bot.issmokingafter;
}

/*
	Returns if the bot is sprinting.
*/
IsBotSprinting()
{
	return self.bot.issprinting;
}

/*
	Returns if the bot is reloading.
*/
IsBotReloading()
{
	return self.bot.isreloading;
}

/*
	Is bot knifing
*/
IsBotKnifing()
{
	return self.bot.isknifingafter;
}

/*
	Freezes the bot's controls.
*/
BotFreezeControls( what )
{
	self.bot.isfrozen = what;

	if ( what )
		self notify( "kill_goal" );
}

/*
	Returns if the bot is script frozen.
*/
BotIsFrozen()
{
	return self.bot.isfrozen;
}

/*
	Bot will stop moving
*/
BotStopMoving( what )
{
	self.bot.stop_move = what;

	if ( what )
		self notify( "kill_goal" );
}

/*
	Returns if the bot has a script goal.
	(like t5 gsc bot)
*/
HasScriptGoal()
{
	return ( isDefined( self GetScriptGoal() ) );
}

/*
	Sets the bot's goal, will acheive it when dist away from it.
*/
SetScriptGoal( goal, dist )
{
	if ( !isDefined( dist ) )
		dist = 16;

	self.bot.script_goal = goal;
	self.bot.script_goal_dist = dist;
	waittillframeend;
	self notify( "new_goal_internal" );
	self notify( "new_goal" );
}

/*
	Returns the pos of the bot's goal
*/
GetScriptGoal()
{
	return self.bot.script_goal;
}

/*
	Clears the bot's goal.
*/
ClearScriptGoal()
{
	self SetScriptGoal( undefined, 0 );
}

/*
	Returns the location of the bot's javelin target
*/
HasBotJavelinLocation()
{
	return isDefined( self.bot.jav_loc );
}

/*
	Sets the aim position of the bot
*/
SetScriptAimPos( pos )
{
	self.bot.script_aimpos = pos;
}

/*
	Clears the aim position of the bot
*/
ClearScriptAimPos()
{
	self SetScriptAimPos( undefined );
}

/*
	Returns the aim position of the bot
*/
GetScriptAimPos()
{
	return self.bot.script_aimpos;
}

/*
	Returns if the bot has a aim pos
*/
HasScriptAimPos()
{
	return isDefined( self GetScriptAimPos() );
}

/*
	Sets the bot's javelin target location
*/
SetBotJavelinLocation( loc )
{
	self.bot.jav_loc = loc;
	self notify( "new_enemy" );
}

/*
	Clears the bot's javelin location
*/
ClearBotJavelinLocation()
{
	self SetBotJavelinLocation( undefined );
}

/*
	Sets the bot's target to be this ent.
*/
SetAttacker( att )
{
	self.bot.target_this_frame = att;
}

/*
	Sets the script enemy for a bot.
*/
SetScriptEnemy( enemy, offset )
{
	self.bot.script_target = enemy;
	self.bot.script_target_offset = offset;
}

/*
	Removes the script enemy of the bot.
*/
ClearScriptEnemy()
{
	self SetScriptEnemy( undefined, undefined );
}

/*
	Returns the entity of the bot's target.
*/
GetThreat()
{
	if ( !isdefined( self.bot.target ) )
		return undefined;

	return self.bot.target.entity;
}

/*
	Returns if the bot has a script enemy.
*/
HasScriptEnemy()
{
	return ( isDefined( self.bot.script_target ) );
}

/*
	Returns if the bot has a threat.
*/
HasThreat()
{
	return ( isDefined( self GetThreat() ) );
}

/*
	If the player is defusing
*/
IsDefusing()
{
	return ( isDefined( self.isDefusing ) && self.isDefusing );
}

/*
	If the play is planting
*/
isPlanting()
{
	return ( isDefined( self.isPlanting ) && self.isPlanting );
}

/*
	If the player is carrying a bomb
*/
isBombCarrier()
{
	return ( isDefined( self.isBombCarrier ) && self.isBombCarrier );
}

/*
	If the site is in use
*/
isInUse()
{
	return ( isDefined( self.inUse ) && self.inUse );
}

/*
	If the player is in laststand
*/
inLastStand()
{
	return ( isDefined( self.lastStand ) && self.lastStand );
}

/*
	Is being revived
*/
isBeingRevived()
{
	return ( isDefined( self.beingRevived ) && self.beingRevived );
}

/*
	If the player is in final stand
*/
inFinalStand()
{
	return ( isDefined( self.inFinalStand ) && self.inFinalStand );
}

/*
	If the player is the flag carrier
*/
isFlagCarrier()
{
	return ( isDefined( self.carryFlag ) && self.carryFlag );
}

/*
	Returns if we are stunned.
*/
IsStunned()
{
	return ( isdefined( self.concussionEndTime ) && self.concussionEndTime > gettime() );
}

/*
	Returns if we are beingArtilleryShellshocked
*/
isArtShocked()
{
	return ( isDefined( self.beingArtilleryShellshocked ) && self.beingArtilleryShellshocked );
}

/*
	Returns a valid grenade launcher weapon
*/
getValidTube()
{
	weaps = self getweaponslistall();

	for ( i = 0; i < weaps.size; i++ )
	{
		weap = weaps[i];

		if ( !self getAmmoCount( weap ) )
			continue;

		if ( ( isSubStr( weap, "gl_" ) && !isSubStr( weap, "_gl_" ) ) || weap == "m79_mp" )
			return weap;
	}

	return undefined;
}

/*
	iw5
*/
allowClassChoice()
{
	return true;
}

/*
	iw5
*/
allowTeamChoice()
{
	return true;
}

/*
	helper
*/
waittill_either_return_( str1, str2 )
{
	self endon( str1 );
	self waittill( str2 );
	return true;
}

/*
	Returns which string gets notified first
*/
waittill_either_return( str1, str2 )
{
	if ( !isDefined( self waittill_either_return_( str1, str2 ) ) )
		return str1;

	return str2;
}

/*
	Returns a random grenade in the bot's inventory.
*/
getValidGrenade()
{
	grenadeTypes = [];
	grenadeTypes[grenadeTypes.size] = "frag_grenade_mp";
	grenadeTypes[grenadeTypes.size] = "smoke_grenade_mp";
	grenadeTypes[grenadeTypes.size] = "flash_grenade_mp";
	grenadeTypes[grenadeTypes.size] = "concussion_grenade_mp";
	grenadeTypes[grenadeTypes.size] = "semtex_mp";
	grenadeTypes[grenadeTypes.size] = "throwingknife_mp";

	possibles = [];

	for ( i = 0; i < grenadeTypes.size; i++ )
	{
		if ( !self hasWeapon( grenadeTypes[i] ) )
			continue;

		if ( !self getAmmoCount( grenadeTypes[i] ) )
			continue;

		possibles[possibles.size] = grenadeTypes[i];
	}

	return random( possibles );
}

/*
	If the weapon is not a script weapon (bomb, killstreak, etc, grenades)
*/
isWeaponPrimary( weap )
{
	return ( maps\mp\gametypes\_weapons::isPrimaryWeapon( weap ) || maps\mp\gametypes\_weapons::isAltModeWeapon( weap ) );
}

/*
	If the ent is a vehicle
*/
entIsVehicle( ent )
{
	return ( ent.classname == "script_vehicle" || ent.model == "vehicle_uav_static_mp" || ent.model == "vehicle_ac130_coop" );
}

/*
	Returns if the given weapon is full auto.
*/
WeaponIsFullAuto( weap )
{
	weaptoks = strtok( weap, "_" );

	assert( isDefined( weaptoks[0] ) );
	assert( isString( weaptoks[0] ) );

	return isDefined( level.bots_fullautoguns[weaptoks[0]] );
}

/*
	If weap is a secondary gnade
*/
isSecondaryGrenade( gnade )
{
	return ( gnade == "concussion_grenade_mp" || gnade == "flash_grenade_mp" || gnade == "smoke_grenade_mp" );
}

/*
	If the weapon  is allowed to be dropped
*/
isWeaponDroppable( weap )
{
	return ( maps\mp\gametypes\_weapons::mayDropWeapon( weap ) );
}

/*
	Returns the height the viewpos is above the origin
*/
getEyeHeight()
{
	myEye = self getEye();

	return myEye[2] - self.origin[2];
}

/*
	Does a notify after a delay
*/
notifyAfterDelay( delay, not )
{
	wait delay;
	self notify( not );
}

/*
	Gets a player who is host
*/
GetHostPlayer()
{
	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];

		if ( !player is_host() )
			continue;

		return player;
	}

	return undefined;
}

/*
    Waits for a host player
*/
bot_wait_for_host()
{
	host = undefined;

	while ( !isDefined( level ) || !isDefined( level.players ) )
		wait 0.05;

	for ( i = getDvarFloat( "bots_main_waitForHostTime" ); i > 0; i -= 0.05 )
	{
		host = GetHostPlayer();

		if ( isDefined( host ) )
			break;

		wait 0.05;
	}

	if ( !isDefined( host ) )
		return;

	for ( i = getDvarFloat( "bots_main_waitForHostTime" ); i > 0; i -= 0.05 )
	{
		if ( IsDefined( host.pers[ "team" ] ) )
			break;

		wait 0.05;
	}

	if ( !IsDefined( host.pers[ "team" ] ) )
		return;

	for ( i = getDvarFloat( "bots_main_waitForHostTime" ); i > 0; i -= 0.05 )
	{
		if ( host.pers[ "team" ] == "allies" || host.pers[ "team" ] == "axis" )
			break;

		wait 0.05;
	}
}

/*
	Pezbot's line sphere intersection.
	http://paulbourke.net/geometry/circlesphere/raysphere.c
*/
RaySphereIntersect( start, end, spherePos, radius )
{
	// check if the start or end points are in the sphere
	r2 = radius * radius;

	if ( DistanceSquared( start, spherePos ) < r2 )
		return true;

	if ( DistanceSquared( end, spherePos ) < r2 )
		return true;

	// check if the line made by start and end intersect the sphere
	dp = end - start;
	a = dp[0] * dp[0] + dp[1] * dp[1] + dp[2] * dp[2];
	b = 2 * ( dp[0] * ( start[0] - spherePos[0] ) + dp[1] * ( start[1] - spherePos[1] ) + dp[2] * ( start[2] - spherePos[2] ) );
	c = spherePos[0] * spherePos[0] + spherePos[1] * spherePos[1] + spherePos[2] * spherePos[2];
	c += start[0] * start[0] + start[1] * start[1] + start[2] * start[2];
	c -= 2.0 * ( spherePos[0] * start[0] + spherePos[1] * start[1] + spherePos[2] * start[2] );
	c -= radius * radius;
	bb4ac = b * b - 4.0 * a * c;

	if ( abs( a ) < 0.0001 || bb4ac < 0 )
		return false;

	mu1 = ( 0 - b + sqrt( bb4ac ) ) / ( 2 * a );
	//mu2 = (0-b - sqrt(bb4ac)) / (2 * a);

	// intersection points of the sphere
	ip1 = start + mu1 * dp;
	//ip2 = start + mu2 * dp;

	myDist = DistanceSquared( start, end );

	// check if both intersection points far
	if ( DistanceSquared( start, ip1 ) > myDist/* && DistanceSquared(start, ip2) > myDist*/ )
		return false;

	dpAngles = VectorToAngles( dp );

	// check if the point is behind us
	if ( getConeDot( ip1, start, dpAngles ) < 0/* || getConeDot(ip2, start, dpAngles) < 0*/ )
		return false;

	return true;
}

/*
	Returns if a smoke grenade would intersect start to end line.
*/
SmokeTrace( start, end, rad )
{
	for ( i = level.bots_smokeList.count - 1; i >= 0; i-- )
	{
		nade = level.bots_smokeList.data[i];

		if ( nade.state != "smoking" )
			continue;

		if ( !RaySphereIntersect( start, end, nade.origin, rad ) )
			continue;

		return false;
	}

	return true;
}

/*
	Returns the cone dot (like fov, or distance from the center of our screen).
*/
getConeDot( to, from, dir )
{
	dirToTarget = VectorNormalize( to - from );
	forward = AnglesToForward( dir );
	return vectordot( dirToTarget, forward );
}

/*
	Returns the distance squared in a 2d space
*/
DistanceSquared2D( to, from )
{
	to = ( to[0], to[1], 0 );
	from = ( from[0], from[1], 0 );

	return DistanceSquared( to, from );
}

/*
	Rounds to the nearest whole number.
*/
Round( x )
{
	y = int( x );

	if ( abs( x ) - abs( y ) > 0.5 )
	{
		if ( x < 0 )
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

/*
	converts a string into a float
*/
float( num )
{
	setdvar( "temp_dvar_bot_util", num );

	return GetDvarFloat( "temp_dvar_bot_util" );
}

/*
	Tokenizes a string (strtok has limits...) (only one char tok)
*/
tokenizeLine( line, tok )
{
	tokens = [];

	token = "";

	for ( i = 0; i < line.size; i++ )
	{
		c = line[i];

		if ( c == tok )
		{
			tokens[tokens.size] = token;
			token = "";
			continue;
		}

		token += c;
	}

	tokens[tokens.size] = token;

	return tokens;
}

/*
	If the string starts with
*/
isStrStart( string1, subStr )
{
	return ( getSubStr( string1, 0, subStr.size ) == subStr );
}

/*
	Parses tokens into a waypoint obj
*/
parseTokensIntoWaypoint( tokens )
{
	waypoint = spawnStruct();

	orgStr = tokens[0];
	orgToks = strtok( orgStr, " " );
	waypoint.origin = ( float( orgToks[0] ), float( orgToks[1] ), float( orgToks[2] ) );

	childStr = tokens[1];
	childToks = strtok( childStr, " " );
	waypoint.children = [];

	for ( j = 0; j < childToks.size; j++ )
		waypoint.children[j] = int( childToks[j] );

	type = tokens[2];
	waypoint.type = type;

	anglesStr = tokens[3];

	if ( isDefined( anglesStr ) && anglesStr != "" )
	{
		anglesToks = strtok( anglesStr, " " );
		waypoint.angles = ( float( anglesToks[0] ), float( anglesToks[1] ), float( anglesToks[2] ) );
	}

	javStr = tokens[4];

	if ( isDefined( javStr ) && javStr != "" )
	{
		javToks = strtok( javStr, " " );
		waypoint.jav_point = ( float( javToks[0] ), float( javToks[1] ), float( javToks[2] ) );
	}

	return waypoint;
}

/*
	Returns an array of each line
*/
getWaypointLinesFromFile( filename )
{
	result = spawnStruct();
	result.lines = [];

	waypointStr = fileRead( filename );

	if ( !isDefined( waypointStr ) )
		return result;

	line = "";

	for ( i = 0; i < waypointStr.size; i++ )
	{
		c = waypointStr[i];

		if ( c == "\n" )
		{
			result.lines[result.lines.size] = line;

			line = "";
			continue;
		}

		line += c;
	}

	result.lines[result.lines.size] = line;

	return result;
}

/*
	Loads waypoints from file
*/
readWpsFromFile( mapname )
{
	waypoints = [];
	filename = "waypoints/" + mapname + "_wp.csv";

	if ( !fileExists( filename ) )
		return waypoints;

	res = getWaypointLinesFromFile( filename );

	if ( !res.lines.size )
		return waypoints;

	PrintConsole( "Attempting to read waypoints from " + filename + "\n" );

	waypointCount = int( res.lines[0] );

	for ( i = 1; i <= waypointCount; i++ )
	{
		tokens = tokenizeLine( res.lines[i], "," );

		waypoint = parseTokensIntoWaypoint( tokens );

		waypoints[i - 1] = waypoint;
	}

	return waypoints;
}

/*
	Loads the waypoints. Populating everything needed for the waypoints.
*/
load_waypoints()
{
	level.waypointCount = 0;
	level.waypoints = [];
	level.waypointUsage = [];
	level.waypointUsage["allies"] = [];
	level.waypointUsage["axis"] = [];

	mapname = getDvar( "mapname" );

	wps = readWpsFromFile( mapname );

	if ( wps.size )
	{
		level.waypoints = wps;
		PrintConsole( "Loaded " + wps.size + " waypoints from csv.\n" );
	}
	else
	{
		switch ( mapname )
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
				maps\mp\bots\waypoints\_custom_map::main( mapname );
				break;
		}

		if ( level.waypoints.size )
			PrintConsole( "Loaded " + level.waypoints.size + " waypoints from script.\n" );
	}

	if ( !level.waypoints.size )
	{
		maps\mp\bots\_bot_http::getRemoteWaypoints( mapname );
	}

	level.waypointCount = level.waypoints.size;

	for ( i = 0; i < level.waypointCount; i++ )
	{
		if ( !isDefined( level.waypoints[i].children ) || !isDefined( level.waypoints[i].children.size ) )
			level.waypoints[i].children = [];

		if ( !isDefined( level.waypoints[i].origin ) )
			level.waypoints[i].origin = ( 0, 0, 0 );

		if ( !isDefined( level.waypoints[i].type ) )
			level.waypoints[i].type = "crouch";

		level.waypoints[i].childCount = undefined;
	}
}

/*
	Is bot near any of the given waypoints
*/
nearAnyOfWaypoints( dist, waypoints )
{
	dist *= dist;

	for ( i = 0; i < waypoints.size; i++ )
	{
		waypoint = level.waypoints[waypoints[i]];

		if ( DistanceSquared( waypoint.origin, self.origin ) > dist )
			continue;

		return true;
	}

	return false;
}

/*
	Returns the waypoints that are near
*/
waypointsNear( waypoints, dist )
{
	dist *= dist;

	answer = [];

	for ( i = 0; i < waypoints.size; i++ )
	{
		wp = level.waypoints[waypoints[i]];

		if ( DistanceSquared( wp.origin, self.origin ) > dist )
			continue;

		answer[answer.size] = waypoints[i];
	}

	return answer;
}

/*
	Returns nearest waypoint of waypoints
*/
getNearestWaypointOfWaypoints( waypoints )
{
	answer = undefined;
	closestDist = 2147483647;

	for ( i = 0; i < waypoints.size; i++ )
	{
		waypoint = level.waypoints[waypoints[i]];
		thisDist = DistanceSquared( self.origin, waypoint.origin );

		if ( isDefined( answer ) && thisDist > closestDist )
			continue;

		answer = waypoints[i];
		closestDist = thisDist;
	}

	return answer;
}

/*
	Returns all waypoints of type
*/
getWaypointsOfType( type )
{
	answer = [];

	for ( i = 0; i < level.waypointCount; i++ )
	{
		wp = level.waypoints[i];

		if ( type == "camp" )
		{
			if ( wp.type != "crouch" )
				continue;

			if ( wp.children.size != 1 )
				continue;
		}
		else if ( type != wp.type )
			continue;

		answer[answer.size] = i;
	}

	return answer;
}

/*
	Returns the waypoint for index
*/
getWaypointForIndex( i )
{
	if ( !isDefined( i ) )
		return undefined;

	return level.waypoints[i];
}

/*
	Returns the friendly user name for a given map's codename
*/
getMapName( mapname )
{
	switch ( mapname )
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
	switch ( getdvar( "mapname" ) )
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
			if ( level.teambased )
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
			if ( level.teambased )
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
			if ( level.teambased )
				return 14;
			else
				return 9;

		case "mp_fuel2":
		case "mp_invasion":
		case "mp_derail":
			if ( level.teambased )
				return 16;
			else
				return 10;

		default:
			return 2;
	}
}

/*
	Matches a num to a char
*/
keyCodeToString( a )
{
	b = "";

	switch ( a )
	{
		case 0:
			b = "a";
			break;

		case 1:
			b = "b";
			break;

		case 2:
			b = "c";
			break;

		case 3:
			b = "d";
			break;

		case 4:
			b = "e";
			break;

		case 5:
			b = "f";
			break;

		case 6:
			b = "g";
			break;

		case 7:
			b = "h";
			break;

		case 8:
			b = "i";
			break;

		case 9:
			b = "j";
			break;

		case 10:
			b = "k";
			break;

		case 11:
			b = "l";
			break;

		case 12:
			b = "m";
			break;

		case 13:
			b = "n";
			break;

		case 14:
			b = "o";
			break;

		case 15:
			b = "p";
			break;

		case 16:
			b = "q";
			break;

		case 17:
			b = "r";
			break;

		case 18:
			b = "s";
			break;

		case 19:
			b = "t";
			break;

		case 20:
			b = "u";
			break;

		case 21:
			b = "v";
			break;

		case 22:
			b = "w";
			break;

		case 23:
			b = "x";
			break;

		case 24:
			b = "y";
			break;

		case 25:
			b = "z";
			break;

		case 26:
			b = ".";
			break;

		case 27:
			b = " ";
			break;
	}

	return b;
}

/*
	Returns an array of all the bots in the game.
*/
getBotArray()
{
	result = [];
	playercount = level.players.size;

	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[i];

		if ( !player is_bot() )
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

	kdTree _WaypointsToKDTree( level.waypoints, 0 );

	return kdTree;
}

/*
	Recurive function. We construct a balanced KD tree by sorting the waypoints using heap sort.
*/
_WaypointsToKDTree( waypoints, dem )
{
	if ( !waypoints.size )
		return;

	callbacksort = undefined;

	switch ( dem )
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

	heap = NewHeap( callbacksort );

	for ( i = 0; i < waypoints.size; i++ )
	{
		heap HeapInsert( waypoints[i] );
	}

	sorted = [];

	while ( heap.data.size )
	{
		sorted[sorted.size] = heap.data[0];
		heap HeapRemove();
	}

	median = int( sorted.size / 2 ); //use divide and conq

	left = [];
	right = [];

	for ( i = 0; i < sorted.size; i++ )
		if ( i < median )
			right[right.size] = sorted[i];
		else if ( i > median )
			left[left.size] = sorted[i];

	self KDTreeInsert( sorted[median] );

	_WaypointsToKDTree( left, ( dem + 1 ) % 3 );

	_WaypointsToKDTree( right, ( dem + 1 ) % 3 );
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
ListAdd( thing )
{
	self.data[self.count] = thing;

	self.count++;
}

/*
	Adds to the start of the list.
*/
ListAddFirst( thing )
{
	for ( i = self.count - 1; i >= 0; i-- )
	{
		self.data[i + 1] = self.data[i];
	}

	self.data[0] = thing;
	self.count++;
}

/*
	Removes the thing from the list.
*/
ListRemove( thing )
{
	for ( i = 0; i < self.count; i++ )
	{
		if ( self.data[i] == thing )
		{
			while ( i < self.count - 1 )
			{
				self.data[i] = self.data[i + 1];
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
KDTreeInsert( data ) //as long as what you insert has a .origin attru, it will work.
{
	self.root = self _KDTreeInsert( self.root, data, 0, -2147483647, -2147483647, -2147483647, 2147483647, 2147483647, 2147483647 );
}

/*
	Recurive function that insert the object into the KDTree.
*/
_KDTreeInsert( node, data, dem, x0, y0, z0, x1, y1, z1 )
{
	if ( !isDefined( node ) )
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

	switch ( dem )
	{
		case 0:
			if ( data.origin[0] < node.data.origin[0] )
				node.left = self _KDTreeInsert( node.left, data, 1, x0, y0, z0, node.data.origin[0], y1, z1 );
			else
				node.right = self _KDTreeInsert( node.right, data, 1, node.data.origin[0], y0, z0, x1, y1, z1 );

			break;

		case 1:
			if ( data.origin[1] < node.data.origin[1] )
				node.left = self _KDTreeInsert( node.left, data, 2, x0, y0, z0, x1, node.data.origin[1], z1 );
			else
				node.right = self _KDTreeInsert( node.right, data, 2, x0, node.data.origin[1], z0, x1, y1, z1 );

			break;

		case 2:
			if ( data.origin[2] < node.data.origin[2] )
				node.left = self _KDTreeInsert( node.left, data, 0, x0, y0, z0, x1, y1, node.data.origin[2] );
			else
				node.right = self _KDTreeInsert( node.right, data, 0, x0, y0, node.data.origin[2], x1, y1, z1 );

			break;
	}

	return node;
}

/*
	Called on a KDTree, will return the nearest object to the given origin.
*/
KDTreeNearest( origin )
{
	if ( !isDefined( self.root ) )
		return undefined;

	return self _KDTreeNearest( self.root, origin, self.root.data, DistanceSquared( self.root.data.origin, origin ), 0 );
}

/*
	Recurive function that will retrieve the closest object to the query.
*/
_KDTreeNearest( node, point, closest, closestdist, dem )
{
	if ( !isDefined( node ) )
	{
		return closest;
	}

	thisDis = DistanceSquared( node.data.origin, point );

	if ( thisDis < closestdist )
	{
		closestdist = thisDis;
		closest = node.data;
	}

	if ( node RectDistanceSquared( point ) < closestdist )
	{
		near = node.left;
		far = node.right;

		if ( point[dem] > node.data.origin[dem] )
		{
			near = node.right;
			far = node.left;
		}

		closest = self _KDTreeNearest( near, point, closest, closestdist, ( dem + 1 ) % 3 );

		closest = self _KDTreeNearest( far, point, closest, DistanceSquared( closest.origin, point ), ( dem + 1 ) % 3 );
	}

	return closest;
}

/*
	Called on a rectangle, returns the distance from origin to the rectangle.
*/
RectDistanceSquared( origin )
{
	dx = 0;
	dy = 0;
	dz = 0;

	if ( origin[0] < self.x0 )
		dx = origin[0] - self.x0;
	else if ( origin[0] > self.x1 )
		dx = origin[0] - self.x1;

	if ( origin[1] < self.y0 )
		dy = origin[1] - self.y0;
	else if ( origin[1] > self.y1 )
		dy = origin[1] - self.y1;


	if ( origin[2] < self.z0 )
		dz = origin[2] - self.z0;
	else if ( origin[2] > self.z1 )
		dz = origin[2] - self.z1;

	return dx * dx + dy * dy + dz * dz;
}

/*
	Does the extra check when adding bots
*/
doExtraCheck()
{
	maps\mp\bots\_bot_internal::checkTheBots();
}

/*
	A heap invarient comparitor, used for objects, objects with a higher X coord will be first in the heap.
*/
HeapSortCoordX( item, item2 )
{
	return item.origin[0] > item2.origin[0];
}

/*
	A heap invarient comparitor, used for objects, objects with a higher Y coord will be first in the heap.
*/
HeapSortCoordY( item, item2 )
{
	return item.origin[1] > item2.origin[1];
}

/*
	A heap invarient comparitor, used for objects, objects with a higher Z coord will be first in the heap.
*/
HeapSortCoordZ( item, item2 )
{
	return item.origin[2] > item2.origin[2];
}

/*
	A heap invarient comparitor, used for numbers, numbers with the highest number will be first in the heap.
*/
Heap( item, item2 )
{
	return item > item2;
}

/*
	A heap invarient comparitor, used for numbers, numbers with the lowest number will be first in the heap.
*/
ReverseHeap( item, item2 )
{
	return item < item2;
}

/*
	A heap invarient comparitor, used for traces. Wanting the trace with the largest length first in the heap.
*/
HeapTraceFraction( item, item2 )
{
	return item["fraction"] > item2["fraction"];
}

/*
	Returns a new heap.
*/
NewHeap( compare )
{
	heap_node = spawnStruct();
	heap_node.data = [];
	heap_node.compare = compare;

	return heap_node;
}

/*
	Inserts the item into the heap. Called on a heap.
*/
HeapInsert( item )
{
	insert = self.data.size;
	self.data[insert] = item;

	current = insert + 1;

	while ( current > 1 )
	{
		last = current;
		current = int( current / 2 );

		if ( ![[self.compare]]( item, self.data[current - 1] ) )
			break;

		self.data[last - 1] = self.data[current - 1];
		self.data[current - 1] = item;
	}
}

/*
	Helper function to determine what is the next child of the bst.
*/
_HeapNextChild( node, hsize )
{
	left = node * 2;
	right = left + 1;

	if ( left > hsize )
		return -1;

	if ( right > hsize )
		return left;

	if ( [[self.compare]]( self.data[left - 1], self.data[right - 1] ) )
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

	if ( !remove )
		return remove;

	move = self.data[remove - 1];
	self.data[0] = move;
	self.data[remove - 1] = undefined;
	remove--;

	if ( !remove )
		return remove;

	last = 1;
	next = self _HeapNextChild( 1, remove );

	while ( next != -1 )
	{
		if ( [[self.compare]]( move, self.data[next - 1] ) )
			break;

		self.data[last - 1] = self.data[next - 1];
		self.data[next - 1] = move;

		last = next;
		next = self _HeapNextChild( next, remove );
	}

	return remove;
}

/*
	A heap invarient comparitor, used for the astar's nodes, wanting the node with the lowest f to be first in the heap.
*/
ReverseHeapAStar( item, item2 )
{
	return item.f < item2.f;
}

/*
	Removes the waypoint usage
*/
RemoveWaypointUsage( wp, team )
{
	if ( !isDefined( level.waypointUsage ) )
		return;

	if ( !isDefined( level.waypointUsage[team][wp + ""] ) )
		return;

	level.waypointUsage[team][wp + ""]--;

	if ( level.waypointUsage[team][wp + ""] <= 0 )
		level.waypointUsage[team][wp + ""] = undefined;
}

/*
	Will linearly search for the nearest waypoint to pos that has a direct line of sight.
*/
GetNearestWaypointWithSight( pos )
{
	candidate = undefined;
	dist = 2147483647;

	for ( i = 0; i < level.waypointCount; i++ )
	{
		if ( !bulletTracePassed( pos + ( 0, 0, 15 ), level.waypoints[i].origin + ( 0, 0, 15 ), false, undefined ) )
			continue;

		curdis = DistanceSquared( level.waypoints[i].origin, pos );

		if ( curdis > dist )
			continue;

		dist = curdis;
		candidate = i;
	}

	return candidate;
}

/*
	Will linearly search for the nearest waypoint
*/
GetNearestWaypoint( pos )
{
	candidate = undefined;
	dist = 2147483647;

	for ( i = 0; i < level.waypointCount; i++ )
	{
		curdis = DistanceSquared( level.waypoints[i].origin, pos );

		if ( curdis > dist )
			continue;

		dist = curdis;
		candidate = i;
	}

	return candidate;
}

/*
	Modified Pezbot astar search.
	This makes use of sets for quick look up and a heap for a priority queue instead of simple lists which require to linearly search for elements everytime.
	It is also modified to make paths with bots already on more expensive and will try a less congested path first. Thus spliting up the bots onto more paths instead of just one (the smallest).
*/
AStarSearch( start, goal, team, greedy_path )
{
	open = NewHeap( ::ReverseHeapAStar ); //heap
	openset = [];//set for quick lookup
	closed = [];//set for quick lookup


	startWp = getNearestWaypoint( start );

	if ( !isDefined( startWp ) )
		return [];

	_startwp = undefined;

	if ( !bulletTracePassed( start + ( 0, 0, 15 ), level.waypoints[startWp].origin + ( 0, 0, 15 ), false, undefined ) )
		_startwp = GetNearestWaypointWithSight( start );

	if ( isDefined( _startwp ) )
		startWp = _startwp;


	goalWp = getNearestWaypoint( goal );

	if ( !isDefined( goalWp ) )
		return [];

	_goalWp = undefined;

	if ( !bulletTracePassed( goal + ( 0, 0, 15 ), level.waypoints[goalWp].origin + ( 0, 0, 15 ), false, undefined ) )
		_goalwp = GetNearestWaypointWithSight( goal );

	if ( isDefined( _goalwp ) )
		goalWp = _goalwp;


	node = spawnStruct();
	node.g = 0; //path dist so far
	node.h = DistanceSquared( level.waypoints[startWp].origin, level.waypoints[goalWp].origin ); //herustic, distance to goal for path finding
	node.f = node.h + node.g; // combine path dist and heru, use reverse heap to sort the priority queue by this attru
	node.index = startWp;
	node.parent = undefined; //we are start, so we have no parent

	//push node onto queue
	openset[node.index + ""] = node;
	open HeapInsert( node );

	//while the queue is not empty
	while ( open.data.size )
	{
		//pop bestnode from queue
		bestNode = open.data[0];
		open HeapRemove();
		openset[bestNode.index + ""] = undefined;
		wp = level.waypoints[bestNode.index];

		//check if we made it to the goal
		if ( bestNode.index == goalWp )
		{
			path = [];

			while ( isDefined( bestNode ) )
			{
				if ( isdefined( team ) && isDefined( level.waypointUsage ) )
				{
					if ( !isDefined( level.waypointUsage[team][bestNode.index + ""] ) )
						level.waypointUsage[team][bestNode.index + ""] = 0;

					level.waypointUsage[team][bestNode.index + ""]++;
				}

				//construct path
				path[path.size] = bestNode.index;

				bestNode = bestNode.parent;
			}

			return path;
		}

		//for each child of bestnode
		for ( i = wp.children.size - 1; i >= 0; i-- )
		{
			child = wp.children[i];
			childWp = level.waypoints[child];

			penalty = 1;

			if ( !greedy_path && isdefined( team ) && isDefined( level.waypointUsage ) )
			{
				temppen = 1;

				if ( isDefined( level.waypointUsage[team][child + ""] ) )
					temppen = level.waypointUsage[team][child + ""]; //consider how many bots are taking this path

				if ( temppen > 1 )
					penalty = temppen;
			}

			// have certain types of nodes more expensive
			if ( childWp.type == "climb" || childWp.type == "prone" )
				penalty += 4;

			//calc the total path we have took
			newg = bestNode.g + DistanceSquared( wp.origin, childWp.origin ) * penalty; //bots on same team's path are more expensive

			//check if this child is in open or close with a g value less than newg
			inopen = isDefined( openset[child + ""] );

			if ( inopen && openset[child + ""].g <= newg )
				continue;

			inclosed = isDefined( closed[child + ""] );

			if ( inclosed && closed[child + ""].g <= newg )
				continue;

			node = undefined;

			if ( inopen )
				node = openset[child + ""];
			else if ( inclosed )
				node = closed[child + ""];
			else
				node = spawnStruct();

			node.parent = bestNode;
			node.g = newg;
			node.h = DistanceSquared( childWp.origin, level.waypoints[goalWp].origin );
			node.f = node.g + node.h;
			node.index = child;

			//check if in closed, remove it
			if ( inclosed )
				closed[child + ""] = undefined;

			//check if not in open, add it
			if ( !inopen )
			{
				open HeapInsert( node );
				openset[child + ""] = node;
			}
		}

		//done with children, push onto closed
		closed[bestNode.index + ""] = bestNode;
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

	return ( number );
}

/*
	Patches the plant sites so it exposes the defuseObject
*/
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

/*
	Patches the plant sites so it exposes the defuseObject
*/
bombPlantedFix( destroyedObj, player )
{
	maps\mp\gametypes\_gamelogic::pauseTimer();
	level.bombPlanted = true;

	destroyedObj.visuals[0] thread maps\mp\gametypes\_gamelogic::playTickingSound();
	level.tickingObject = destroyedObj.visuals[0];

	level.timeLimitOverride = true;
	setGameEndTime( int( gettime() + ( level.bombTimer * 1000 ) ) );
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

		trace = bulletTrace( player.origin + ( 0, 0, 20 ), player.origin - ( 0, 0, 2000 ), false, player );

		tempAngle = randomfloat( 360 );
		forward = ( cos( tempAngle ), sin( tempAngle ), 0 );
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
	defuseObject = maps\mp\gametypes\_gameobjects::createUseObject( game["defenders"], trigger, visuals, ( 0, 0, 32 ) );
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

	rot = randomfloat( 360 );
	explosionEffect = spawnFx( level._effect["bombexplosion"], explosionOrigin + ( 0, 0, 50 ), ( 0, 0, 1 ), ( cos( rot ), sin( rot ), 0 ) );
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

/*
	Patches giveLoadout so that it doesn't use IsItemUnlocked
*/
botGiveLoadout( team, class, allowCopycat )
{
	self endon( "death" );

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
		loadoutPrimaryAttachment = maps\mp\gametypes\_class::table_getWeaponAttachment( level.classTableName, class_num, 0, 0 );
		loadoutPrimaryAttachment2 = maps\mp\gametypes\_class::table_getWeaponAttachment( level.classTableName, class_num, 0, 1 );
		loadoutPrimaryCamo = maps\mp\gametypes\_class::table_getWeaponCamo( level.classTableName, class_num, 0 );
		loadoutSecondaryCamo = maps\mp\gametypes\_class::table_getWeaponCamo( level.classTableName, class_num, 1 );
		loadoutSecondary = maps\mp\gametypes\_class::table_getWeapon( level.classTableName, class_num, 1 );
		loadoutSecondaryAttachment = maps\mp\gametypes\_class::table_getWeaponAttachment( level.classTableName, class_num, 1, 0 );
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

	// stop default class op'ness
	allowOp = ( getDvarInt( "bots_loadout_allow_op" ) >= 1 );

	if ( !allowOp )
	{
		loadoutDeathstreak = "specialty_none";

		if ( loadoutPrimary == "riotshield" )
			loadoutPrimary = "m4";

		if ( loadoutSecondary == "at4" )
			loadoutSecondary = "usp";

		if ( loadoutPrimaryAttachment == "gl" )
			loadoutPrimaryAttachment = "none";

		if ( loadoutPerk2 == "specialty_coldblooded" )
			loadoutPerk2 = "specialty_none";

		if ( loadoutPerk3 == "specialty_localjammer" )
			loadoutPerk3 = "specialty_none";
	}


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
	self _giveWeapon( secondaryName, int( tableLookup( "mp/camoTable.csv", 1, loadoutSecondaryCamo, 0 ) ) );

	self.loadoutPrimaryCamo = int( tableLookup( "mp/camoTable.csv", 1, loadoutPrimaryCamo, 0 ) );
	self.loadoutPrimary = loadoutPrimary;
	self.loadoutSecondary = loadoutSecondary;
	self.loadoutSecondaryCamo = int( tableLookup( "mp/camoTable.csv", 1, loadoutSecondaryCamo, 0 ) );

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
	if ( loadoutDeathStreak != "specialty_null" && ( getTime() - self.spawnTime ) < 0.1 )
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

	if ( loadOutOffhand == "smoke_grenade" )
		self setWeaponAmmoClip( offhandSecondaryWeapon, 1 );
	else if ( loadOutOffhand == "flash_grenade" )
		self setWeaponAmmoClip( offhandSecondaryWeapon, 2 );
	else if ( loadOutOffhand == "concussion_grenade" )
		self setWeaponAmmoClip( offhandSecondaryWeapon, 2 );
	else
		self setWeaponAmmoClip( offhandSecondaryWeapon, 1 );

	primaryWeapon = primaryName;
	self.primaryWeapon = primaryWeapon;
	self.secondaryWeapon = secondaryName;

	self botPlayerModelForWeapon( self.pers["primaryWeapon"], getBaseWeaponName( secondaryName ) );

	self.isSniper = ( weaponClass( self.primaryWeapon ) == "sniper" );

	self maps\mp\gametypes\_weapons::updateMoveSpeedScale( "primary" );

	// cac specialties that require loop threads
	self maps\mp\perks\_perks::cac_selector();

	self notify ( "changed_kit" );
	self notify( "bot_giveLoadout", allowCopycat );
}

/*
	Patches giveLoadout so that it doesn't use IsItemUnlocked
*/
botGetPerkUpgrade( perkName )
{
	perkUpgrade = tablelookup( "mp/perktable.csv", 1, perkName, 8 );

	if ( perkUpgrade == "" || perkUpgrade == "specialty_null" )
		return "specialty_null";

	if ( !isDefined( self.pers["bots"]["unlocks"]["upgraded_" + perkName] ) || !self.pers["bots"]["unlocks"]["upgraded_" + perkName] )
		return "specialty_null";

	return ( perkUpgrade );
}

/*
	Patches giveLoadout so that it doesn't use IsItemUnlocked
*/
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

	for ( i = 0; i < perkUpgrd.size; i++ )
	{
		upgrade = perkUpgrd[i];
		perk = perks[i];

		if ( upgrade == "" || upgrade == "specialty_null" )
			continue;

		if ( isDefined( self.pers["bots"]["unlocks"]["upgraded_" + perk] ) && self.pers["bots"]["unlocks"]["upgraded_" + perk] )
			self maps\mp\perks\_perks::givePerk( upgrade );
	}

}

/*
	Patches giveLoadout so that it doesn't use IsItemUnlocked
*/
botPlayerModelForWeapon( weapon, secondary )
{
	team = self.team;


	if ( isDefined( game[team + "_model"][weapon] ) )
	{
		[[game[team + "_model"][weapon]]]();
		return;
	}


	weaponClass = tablelookup( "mp/statstable.csv", 4, weapon, 2 );

	switch ( weaponClass )
	{
		case "weapon_smg":
			[[game[team + "_model"]["SMG"]]]();
			break;

		case "weapon_assault":
			weaponClass = tablelookup( "mp/statstable.csv", 4, secondary, 2 );

			if ( weaponClass == "weapon_shotgun" )
				[[game[team + "_model"]["SHOTGUN"]]]();
			else
				[[game[team + "_model"]["ASSAULT"]]]();

			break;

		case "weapon_sniper":
			if ( level.environment != "" && isDefined( self.pers["bots"]["unlocks"]["ghillie"] ) && self.pers["bots"]["unlocks"]["ghillie"] )
				[[game[team + "_model"]["GHILLIE"]]]();
			else
				[[game[team + "_model"]["SNIPER"]]]();

			break;

		case "weapon_lmg":
			[[game[team + "_model"]["LMG"]]]();
			break;

		case "weapon_riot":
			[[game[team + "_model"]["RIOT"]]]();
			break;

		default:
			[[game[team + "_model"]["ASSAULT"]]]();
			break;
	}
}
