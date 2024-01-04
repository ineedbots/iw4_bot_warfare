/*
	_bot
	Author: INeedGames
	Date: 09/26/2020
	The entry point and manager of the bots.
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

/*
	Initiates the whole bot scripts.
*/
init()
{
	level.bw_version = "2.1.0";
	
	if ( getdvar( "bots_main" ) == "" )
	{
		setdvar( "bots_main", true );
	}
	
	if ( !getdvarint( "bots_main" ) )
	{
		return;
	}
	
	if ( !wait_for_builtins() )
	{
		println( "FATAL: NO BUILT-INS FOR BOTS" );
	}
	
	thread load_waypoints();
	thread hook_callbacks();
	
	if ( getdvar( "bots_main_GUIDs" ) == "" )
	{
		setdvar( "bots_main_GUIDs", "" ); // guids of players who will be given host powers, comma seperated
	}
	
	if ( getdvar( "bots_main_firstIsHost" ) == "" )
	{
		setdvar( "bots_main_firstIsHost", false ); // first play to connect is a host
	}
	
	if ( getdvar( "bots_main_waitForHostTime" ) == "" )
	{
		setdvar( "bots_main_waitForHostTime", 10.0 ); // how long to wait to wait for the host player
	}
	
	if ( getdvar( "bots_main_kickBotsAtEnd" ) == "" )
	{
		setdvar( "bots_main_kickBotsAtEnd", false ); // kicks the bots at game end
	}
	
	if ( getdvar( "bots_manage_add" ) == "" )
	{
		setdvar( "bots_manage_add", 0 ); // amount of bots to add to the game
	}
	
	if ( getdvar( "bots_manage_fill" ) == "" )
	{
		setdvar( "bots_manage_fill", 0 ); // amount of bots to maintain
	}
	
	if ( getdvar( "bots_manage_fill_spec" ) == "" )
	{
		setdvar( "bots_manage_fill_spec", true ); // to count for fill if player is on spec team
	}
	
	if ( getdvar( "bots_manage_fill_mode" ) == "" )
	{
		setdvar( "bots_manage_fill_mode", 0 ); // fill mode, 0 adds everyone, 1 just bots, 2 maintains at maps, 3 is 2 with 1
	}
	
	if ( getdvar( "bots_manage_fill_kick" ) == "" )
	{
		setdvar( "bots_manage_fill_kick", false ); // kick bots if too many
	}
	
	if ( getdvar( "bots_team" ) == "" )
	{
		setdvar( "bots_team", "autoassign" ); // which team for bots to join
	}
	
	if ( getdvar( "bots_team_amount" ) == "" )
	{
		setdvar( "bots_team_amount", 0 ); // amount of bots on axis team
	}
	
	if ( getdvar( "bots_team_force" ) == "" )
	{
		setdvar( "bots_team_force", false ); // force bots on team
	}
	
	if ( getdvar( "bots_team_mode" ) == "" )
	{
		setdvar( "bots_team_mode", 0 ); // counts just bots when 1
	}
	
	if ( getdvar( "bots_skill" ) == "" )
	{
		setdvar( "bots_skill", 0 ); // 0 is random, 1 is easy 7 is hard, 8 is custom, 9 is completely random
	}
	
	if ( getdvar( "bots_skill_axis_hard" ) == "" )
	{
		setdvar( "bots_skill_axis_hard", 0 ); // amount of hard bots on axis team
	}
	
	if ( getdvar( "bots_skill_axis_med" ) == "" )
	{
		setdvar( "bots_skill_axis_med", 0 );
	}
	
	if ( getdvar( "bots_skill_allies_hard" ) == "" )
	{
		setdvar( "bots_skill_allies_hard", 0 );
	}
	
	if ( getdvar( "bots_skill_allies_med" ) == "" )
	{
		setdvar( "bots_skill_allies_med", 0 );
	}
	
	if ( getdvar( "bots_skill_min" ) == "" )
	{
		setdvar( "bots_skill_min", 1 );
	}
	
	if ( getdvar( "bots_skill_max" ) == "" )
	{
		setdvar( "bots_skill_max", 7 );
	}
	
	if ( getdvar( "bots_loadout_reasonable" ) == "" ) // filter out the bad 'guns' and perks
	{
		setdvar( "bots_loadout_reasonable", false );
	}
	
	if ( getdvar( "bots_loadout_allow_op" ) == "" ) // allows jug, marty and laststand
	{
		setdvar( "bots_loadout_allow_op", true );
	}
	
	if ( getdvar( "bots_loadout_rank" ) == "" ) // what rank the bots should be around, -1 is around the players, 0 is all random
	{
		setdvar( "bots_loadout_rank", -1 );
	}
	
	if ( getdvar( "bots_loadout_prestige" ) == "" ) // what pretige the bots will be, -1 is the players, -2 is random
	{
		setdvar( "bots_loadout_prestige", -1 );
	}
	
	if ( getdvar( "bots_play_move" ) == "" ) // bots move
	{
		setdvar( "bots_play_move", true );
	}
	
	if ( getdvar( "bots_play_knife" ) == "" ) // bots knife
	{
		setdvar( "bots_play_knife", true );
	}
	
	if ( getdvar( "bots_play_fire" ) == "" ) // bots fire
	{
		setdvar( "bots_play_fire", true );
	}
	
	if ( getdvar( "bots_play_nade" ) == "" ) // bots grenade
	{
		setdvar( "bots_play_nade", true );
	}
	
	if ( getdvar( "bots_play_take_carepackages" ) == "" ) // bots take carepackages
	{
		setdvar( "bots_play_take_carepackages", true );
	}
	
	if ( getdvar( "bots_play_obj" ) == "" ) // bots play the obj
	{
		setdvar( "bots_play_obj", true );
	}
	
	if ( getdvar( "bots_play_camp" ) == "" ) // bots camp and follow
	{
		setdvar( "bots_play_camp", true );
	}
	
	if ( getdvar( "bots_play_jumpdrop" ) == "" ) // bots jump and dropshot
	{
		setdvar( "bots_play_jumpdrop", true );
	}
	
	if ( getdvar( "bots_play_target_other" ) == "" ) // bot target non play ents (vehicles)
	{
		setdvar( "bots_play_target_other", true );
	}
	
	if ( getdvar( "bots_play_killstreak" ) == "" ) // bot use killstreaks
	{
		setdvar( "bots_play_killstreak", true );
	}
	
	if ( getdvar( "bots_play_ads" ) == "" ) // bot ads
	{
		setdvar( "bots_play_ads", true );
	}
	
	if ( getdvar( "bots_play_aim" ) == "" )
	{
		setdvar( "bots_play_aim", true );
	}
	
	if ( !isdefined( game[ "botWarfare" ] ) )
	{
		game[ "botWarfare" ] = true;
	}
	
	level.defuseobject = undefined;
	level.bots_smokelist = List();
	level.bots_fraglist = List();
	
	level.bots_minsprintdistance = 315;
	level.bots_minsprintdistance *= level.bots_minsprintdistance;
	level.bots_mingrenadedistance = 256;
	level.bots_mingrenadedistance *= level.bots_mingrenadedistance;
	level.bots_maxgrenadedistance = 1024;
	level.bots_maxgrenadedistance *= level.bots_maxgrenadedistance;
	level.bots_maxknifedistance = 128;
	level.bots_maxknifedistance *= level.bots_maxknifedistance;
	level.bots_goaldistance = 27.5;
	level.bots_goaldistance *= level.bots_goaldistance;
	level.bots_noadsdistance = 200;
	level.bots_noadsdistance *= level.bots_noadsdistance;
	level.bots_maxshotgundistance = 500;
	level.bots_maxshotgundistance *= level.bots_maxshotgundistance;
	level.bots_listendist = 100;
	
	level.smokeradius = 255;
	
	level.bots = [];
	
	level.bots_fullautoguns = [];
	level.bots_fullautoguns[ "aa12" ] = true;
	level.bots_fullautoguns[ "ak47" ] = true;
	level.bots_fullautoguns[ "aug" ] = true;
	level.bots_fullautoguns[ "fn2000" ] = true;
	level.bots_fullautoguns[ "glock" ] = true;
	level.bots_fullautoguns[ "kriss" ] = true;
	level.bots_fullautoguns[ "m4" ] = true;
	level.bots_fullautoguns[ "m240" ] = true;
	level.bots_fullautoguns[ "masada" ] = true;
	level.bots_fullautoguns[ "mg4" ] = true;
	level.bots_fullautoguns[ "mp5k" ] = true;
	level.bots_fullautoguns[ "p90" ] = true;
	level.bots_fullautoguns[ "pp2000" ] = true;
	level.bots_fullautoguns[ "rpd" ] = true;
	level.bots_fullautoguns[ "sa80" ] = true;
	level.bots_fullautoguns[ "scar" ] = true;
	level.bots_fullautoguns[ "tavor" ] = true;
	level.bots_fullautoguns[ "tmp" ] = true;
	level.bots_fullautoguns[ "ump45" ] = true;
	level.bots_fullautoguns[ "uzi" ] = true;
	
	level.bots_fullautoguns[ "ac130" ] = true;
	level.bots_fullautoguns[ "heli" ] = true;
	
	level.bots_fullautoguns[ "ak47classic" ] = true;
	level.bots_fullautoguns[ "ak74u" ] = true;
	level.bots_fullautoguns[ "peacekeeper" ] = true;
	
	level thread fixGamemodes();
	
	level thread onPlayerConnect();
	level thread addNotifyOnAirdrops();
	level thread watchScrabler();
	
	level thread handleBots();
}

/*
	Starts the threads for bots.
*/
handleBots()
{
	level thread teamBots();
	level thread diffBots();
	level addBots();
	
	while ( !level.intermission )
	{
		wait 0.05;
	}
	
	setdvar( "bots_manage_add", getBotArray().size );
	
	if ( !getdvarint( "bots_main_kickBotsAtEnd" ) )
	{
		return;
	}
	
	bots = getBotArray();
	
	for ( i = 0; i < bots.size; i++ )
	{
		kick( bots[ i ] getentitynumber(), "EXE_PLAYERKICKED" );
	}
}

/*
	The hook callback for when any player becomes damaged.
*/
onPlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset )
{
	if ( self is_bot() )
	{
		self maps\mp\bots\_bot_internal::onDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
		self maps\mp\bots\_bot_script::onDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
	}
	
	self [[ level.prevcallbackplayerdamage ]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
}

/*
	The hook callback when any player gets killed.
*/
onPlayerKilled( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration )
{
	if ( self is_bot() )
	{
		self maps\mp\bots\_bot_internal::onKilled( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration );
		self maps\mp\bots\_bot_script::onKilled( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration );
	}
	
	self [[ level.prevcallbackplayerkilled ]]( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration );
}

/*
	Starts the callbacks.
*/
hook_callbacks()
{
	level waittill( "prematch_over" ); // iw4madmin waits this long for some reason...
	wait 0.05; // so we need to be one frame after it sets up its callbacks.
	level.prevcallbackplayerdamage = level.callbackplayerdamage;
	level.callbackplayerdamage = ::onPlayerDamage;
	
	level.prevcallbackplayerkilled = level.callbackplayerkilled;
	level.callbackplayerkilled = ::onPlayerKilled;
}

/*
	Fixes gamemodes when level starts.
*/
fixGamemodes()
{
	for ( i = 0; i < 19; i++ )
	{
		if ( isdefined( level.bombzones ) && level.gametype == "sd" )
		{
			for ( i = 0; i < level.bombzones.size; i++ )
			{
				level.bombzones[ i ].onuse = ::onUsePlantObjectFix;
			}
			
			break;
		}
		
		if ( isdefined( level.radios ) && level.gametype == "koth" )
		{
			level thread fixKoth();
			
			break;
		}
		
		if ( isdefined( level.bombzones ) && level.gametype == "dd" )
		{
			level thread fixDem();
			
			break;
		}
		
		wait 0.05;
	}
}

/*
	Converts t5 dd to iw4
*/
fixDem()
{
	for ( ;; )
	{
		level.bombaplanted = level.aplanted;
		level.bombbplanted = level.bplanted;
		
		for ( i = 0; i < level.bombzones.size; i++ )
		{
			bombzone = level.bombzones[ i ];
			
			if ( isdefined( bombzone.trigger.trigger_off ) )
			{
				bombzone.bombexploded = true;
			}
			else
			{
				bombzone.bombexploded = undefined;
			}
		}
		
		wait 0.05;
	}
}

/*
	Fixes the king of the hill headquarters obj
*/
fixKoth()
{
	level.radio = undefined;
	
	for ( ;; )
	{
		wait 0.05;
		
		if ( !isdefined( level.radioobject ) )
		{
			continue;
		}
		
		for ( i = level.radios.size - 1; i >= 0; i-- )
		{
			if ( level.radioobject != level.radios[ i ].gameobject )
			{
				continue;
			}
			
			level.radio = level.radios[ i ];
			break;
		}
		
		while ( isdefined( level.radioobject ) && level.radio.gameobject == level.radioobject )
		{
			wait 0.05;
		}
	}
}

/*
	Adds a notify when the airdrop is dropped
*/
addNotifyOnAirdrops_loop()
{
	dropCrates = getentarray( "care_package", "targetname" );
	
	for ( i = dropCrates.size - 1; i >= 0; i-- )
	{
		airdrop = dropCrates[ i ];
		
		if ( isdefined( airdrop.doingphysics ) )
		{
			continue;
		}
		
		airdrop.doingphysics = true;
		airdrop thread doNotifyOnAirdrop();
	}
}

/*
	Adds a notify when the airdrop is dropped
*/
addNotifyOnAirdrops()
{
	for ( ;; )
	{
		wait 1;
		addNotifyOnAirdrops_loop();
	}
}

/*
	Does the notify
*/
doNotifyOnAirdrop()
{
	self endon( "death" );
	self waittill( "physics_finished" );
	
	self.doingphysics = false;
	
	if ( isdefined( self.owner ) )
	{
		self.owner notify( "crate_physics_done" );
	}
	
	self thread onCarepackageCaptured();
}

/*
	Waits to be captured
*/
onCarepackageCaptured()
{
	self endon( "death" );
	
	self waittill( "captured", player );
	
	if ( isdefined( self.owner ) && self.owner is_bot() )
	{
		self.owner BotNotifyBotEvent( "crate_cap", "captured", self, player );
	}
}

/*
	Thread when any player connects. Starts the threads needed.
*/
onPlayerConnect()
{
	for ( ;; )
	{
		level waittill( "connected", player );
		
		player.bot_isscrambled = false;
		
		player thread onGrenadeFire();
		player thread onWeaponFired();
		
		player thread connected();
	}
}

/*
	Watches players with scrambler perk
*/
watchScrabler_loop()
{
	for ( i = level.players.size - 1; i >= 0; i-- )
	{
		player = level.players[ i ];
		player.bot_isscrambled = false;
	}
	
	for ( i = level.players.size - 1; i >= 0; i-- )
	{
		player = level.players[ i ];
		
		if ( !player _hasperk( "specialty_localjammer" ) || !isreallyalive( player ) )
		{
			continue;
		}
		
		if ( player isemped() )
		{
			continue;
		}
		
		for ( h = level.players.size - 1; h >= 0; h-- )
		{
			player2 = level.players[ h ];
			
			if ( player2 == player )
			{
				continue;
			}
			
			if ( level.teambased && player2.team == player.team )
			{
				continue;
			}
			
			if ( distancesquared( player2.origin, player.origin ) > 256 * 256 )
			{
				continue;
			}
			
			player2.bot_isscrambled = true;
		}
	}
}

/*
	Watches players with scrambler perk
*/
watchScrabler()
{
	for ( ;; )
	{
		wait 1;
		
		watchScrabler_loop();
	}
}

/*
	When a bot disconnects.
*/
onDisconnect()
{
	self waittill( "disconnect" );
	
	level.bots = array_remove( level.bots, self );
}

/*
	Called when a player connects.
*/
connected()
{
	self endon( "disconnect" );
	
	if ( !isdefined( self.pers[ "bot_host" ] ) )
	{
		self thread doHostCheck();
	}
	
	if ( !self is_bot() )
	{
		return;
	}
	
	if ( !isdefined( self.pers[ "isBot" ] ) )
	{
		// fast_restart occured...
		self.pers[ "isBot" ] = true;
	}
	
	if ( !isdefined( self.pers[ "isBotWarfare" ] ) )
	{
		self.pers[ "isBotWarfare" ] = true;
		self thread added();
	}
	
	self thread maps\mp\bots\_bot_internal::connected();
	self thread maps\mp\bots\_bot_script::connected();
	
	level.bots[ level.bots.size ] = self;
	self thread onDisconnect();
	
	level notify( "bot_connected", self );
	
	self thread watchBotDebugEvent();
}

/*
	DEBUG
*/
watchBotDebugEvent()
{
	self endon( "disconnect" );
	
	for ( ;; )
	{
		self waittill( "bot_event", msg, str, b, c, d, e, f, g );
		
		if ( getdvarint( "bots_main_debug" ) >= 2 )
		{
			big_str = "Bot Warfare debug: " + self.name + ": " + msg;
			
			if ( isdefined( str ) && isstring( str ) )
			{
				big_str += ", " + str;
			}
			
			if ( isdefined( b ) && isstring( b ) )
			{
				big_str += ", " + b;
			}
			
			if ( isdefined( c ) && isstring( c ) )
			{
				big_str += ", " + c;
			}
			
			if ( isdefined( d ) && isstring( d ) )
			{
				big_str += ", " + d;
			}
			
			if ( isdefined( e ) && isstring( e ) )
			{
				big_str += ", " + e;
			}
			
			if ( isdefined( f ) && isstring( f ) )
			{
				big_str += ", " + f;
			}
			
			if ( isdefined( g ) && isstring( g ) )
			{
				big_str += ", " + g;
			}
			
			BotBuiltinPrintConsole( big_str );
		}
		else if ( msg == "debug" && getdvarint( "bots_main_debug" ) )
		{
			BotBuiltinPrintConsole( "Bot Warfare debug: " + self.name + ": " + str );
		}
	}
}

/*
	When a bot gets added into the game.
*/
added()
{
	self endon( "disconnect" );
	
	self thread maps\mp\bots\_bot_internal::added();
	self thread maps\mp\bots\_bot_script::added();
}

/*
	Adds a bot to the game.
*/
add_bot()
{
	bot = addtestclient();
	
	if ( isdefined( bot ) )
	{
		bot.pers[ "isBot" ] = true;
		bot.pers[ "isBotWarfare" ] = true;
		bot thread added();
	}
}

/*
	A server thread for monitoring all bot's difficulty levels for custom server settings.
*/
diffBots_loop()
{
	var_allies_hard = getdvarint( "bots_skill_allies_hard" );
	var_allies_med = getdvarint( "bots_skill_allies_med" );
	var_axis_hard = getdvarint( "bots_skill_axis_hard" );
	var_axis_med = getdvarint( "bots_skill_axis_med" );
	var_skill = getdvarint( "bots_skill" );
	
	allies_hard = 0;
	allies_med = 0;
	axis_hard = 0;
	axis_med = 0;
	
	if ( var_skill == 8 )
	{
		playercount = level.players.size;
		
		for ( i = 0; i < playercount; i++ )
		{
			player = level.players[ i ];
			
			if ( !isdefined( player.pers[ "team" ] ) )
			{
				continue;
			}
			
			if ( !player is_bot() )
			{
				continue;
			}
			
			if ( player.pers[ "team" ] == "axis" )
			{
				if ( axis_hard < var_axis_hard )
				{
					axis_hard++;
					player.pers[ "bots" ][ "skill" ][ "base" ] = 7;
				}
				else if ( axis_med < var_axis_med )
				{
					axis_med++;
					player.pers[ "bots" ][ "skill" ][ "base" ] = 4;
				}
				else
				{
					player.pers[ "bots" ][ "skill" ][ "base" ] = 1;
				}
			}
			else if ( player.pers[ "team" ] == "allies" )
			{
				if ( allies_hard < var_allies_hard )
				{
					allies_hard++;
					player.pers[ "bots" ][ "skill" ][ "base" ] = 7;
				}
				else if ( allies_med < var_allies_med )
				{
					allies_med++;
					player.pers[ "bots" ][ "skill" ][ "base" ] = 4;
				}
				else
				{
					player.pers[ "bots" ][ "skill" ][ "base" ] = 1;
				}
			}
		}
	}
	else if ( var_skill != 0 && var_skill != 9 )
	{
		playercount = level.players.size;
		
		for ( i = 0; i < playercount; i++ )
		{
			player = level.players[ i ];
			
			if ( !player is_bot() )
			{
				continue;
			}
			
			player.pers[ "bots" ][ "skill" ][ "base" ] = var_skill;
		}
	}
	
	playercount = level.players.size;
	min_diff = getdvarint( "bots_skill_min" );
	max_diff = getdvarint( "bots_skill_max" );
	
	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[ i ];
		
		if ( !player is_bot() )
		{
			continue;
		}
		
		player.pers[ "bots" ][ "skill" ][ "base" ] = int( clamp( player.pers[ "bots" ][ "skill" ][ "base" ], min_diff, max_diff ) );
	}
}

/*
	A server thread for monitoring all bot's difficulty levels for custom server settings.
*/
diffBots()
{
	for ( ;; )
	{
		wait 1.5;
		
		diffBots_loop();
	}
}

/*
	A server thread for monitoring all bot's teams for custom server settings.
*/
teamBots_loop()
{
	teamAmount = getdvarint( "bots_team_amount" );
	toTeam = getdvar( "bots_team" );
	
	alliesbots = 0;
	alliesplayers = 0;
	axisbots = 0;
	axisplayers = 0;
	
	playercount = level.players.size;
	
	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[ i ];
		
		if ( !isdefined( player.pers[ "team" ] ) )
		{
			continue;
		}
		
		if ( player is_bot() )
		{
			if ( player.pers[ "team" ] == "allies" )
			{
				alliesbots++;
			}
			else if ( player.pers[ "team" ] == "axis" )
			{
				axisbots++;
			}
		}
		else
		{
			if ( player.pers[ "team" ] == "allies" )
			{
				alliesplayers++;
			}
			else if ( player.pers[ "team" ] == "axis" )
			{
				axisplayers++;
			}
		}
	}
	
	allies = alliesbots;
	axis = axisbots;
	
	if ( !getdvarint( "bots_team_mode" ) )
	{
		allies += alliesplayers;
		axis += axisplayers;
	}
	
	if ( toTeam != "custom" )
	{
		if ( getdvarint( "bots_team_force" ) )
		{
			if ( toTeam == "autoassign" )
			{
				if ( abs( axis - allies ) > 1 )
				{
					toTeam = "axis";
					
					if ( axis > allies )
					{
						toTeam = "allies";
					}
				}
			}
			
			if ( toTeam != "autoassign" )
			{
				playercount = level.players.size;
				
				for ( i = 0; i < playercount; i++ )
				{
					player = level.players[ i ];
					
					if ( !isdefined( player.pers[ "team" ] ) )
					{
						continue;
					}
					
					if ( !player is_bot() )
					{
						continue;
					}
					
					if ( player.pers[ "team" ] == toTeam )
					{
						continue;
					}
					
					if ( toTeam == "allies" )
					{
						player thread [[ level.allies ]]();
					}
					else if ( toTeam == "axis" )
					{
						player thread [[ level.axis ]]();
					}
					else
					{
						player thread [[ level.spectator ]]();
					}
					
					break;
				}
			}
		}
	}
	else
	{
		playercount = level.players.size;
		
		for ( i = 0; i < playercount; i++ )
		{
			player = level.players[ i ];
			
			if ( !isdefined( player.pers[ "team" ] ) )
			{
				continue;
			}
			
			if ( !player is_bot() )
			{
				continue;
			}
			
			if ( player.pers[ "team" ] == "axis" )
			{
				if ( axis > teamAmount )
				{
					player thread [[ level.allies ]]();
					break;
				}
			}
			else
			{
				if ( axis < teamAmount )
				{
					player thread [[ level.axis ]]();
					break;
				}
				else if ( player.pers[ "team" ] != "allies" )
				{
					player thread [[ level.allies ]]();
					break;
				}
			}
		}
	}
}

/*
	A server thread for monitoring all bot's teams for custom server settings.
*/
teamBots()
{
	for ( ;; )
	{
		wait 1.5;
		teamBots_loop();
	}
}

/*
	A server thread for monitoring all bot's in game. Will add and kick bots according to server settings.
*/
addBots_loop()
{
	botsToAdd = getdvarint( "bots_manage_add" );
	
	if ( botsToAdd > 0 )
	{
		setdvar( "bots_manage_add", 0 );
		
		if ( botsToAdd > 64 )
		{
			botsToAdd = 64;
		}
		
		for ( ; botsToAdd > 0; botsToAdd-- )
		{
			level add_bot();
			wait 0.25;
		}
	}
	
	fillMode = getdvarint( "bots_manage_fill_mode" );
	
	if ( fillMode == 2 || fillMode == 3 )
	{
		setdvar( "bots_manage_fill", getGoodMapAmount() );
	}
	
	fillAmount = getdvarint( "bots_manage_fill" );
	
	players = 0;
	bots = 0;
	spec = 0;
	
	playercount = level.players.size;
	
	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[ i ];
		
		if ( player is_bot() )
		{
			bots++;
		}
		else if ( !isdefined( player.pers[ "team" ] ) || ( player.pers[ "team" ] != "axis" && player.pers[ "team" ] != "allies" ) )
		{
			spec++;
		}
		else
		{
			players++;
		}
	}
	
	if ( !randomint( 999 ) )
	{
		setdvar( "testclients_doreload", true );
		wait 0.1;
		setdvar( "testclients_doreload", false );
		doExtraCheck();
	}
	
	if ( fillMode == 4 )
	{
		axisplayers = 0;
		alliesplayers = 0;
		
		playercount = level.players.size;
		
		for ( i = 0; i < playercount; i++ )
		{
			player = level.players[ i ];
			
			if ( player is_bot() )
			{
				continue;
			}
			
			if ( !isdefined( player.pers[ "team" ] ) )
			{
				continue;
			}
			
			if ( player.pers[ "team" ] == "axis" )
			{
				axisplayers++;
			}
			else if ( player.pers[ "team" ] == "allies" )
			{
				alliesplayers++;
			}
		}
		
		result = fillAmount - abs( axisplayers - alliesplayers ) + bots;
		
		if ( players == 0 )
		{
			if ( bots < fillAmount )
			{
				result = fillAmount - 1;
			}
			else if ( bots > fillAmount )
			{
				result = fillAmount + 1;
			}
			else
			{
				result = fillAmount;
			}
		}
		
		bots = result;
	}
	
	amount = bots;
	
	if ( fillMode == 0 || fillMode == 2 )
	{
		amount += players;
	}
	
	if ( getdvarint( "bots_manage_fill_spec" ) )
	{
		amount += spec;
	}
	
	if ( amount < fillAmount )
	{
		setdvar( "bots_manage_add", 1 );
	}
	else if ( amount > fillAmount && getdvarint( "bots_manage_fill_kick" ) )
	{
		tempBot = getBotToKick();
		
		if ( isdefined( tempBot ) )
		{
			kick( tempBot getentitynumber(), "EXE_PLAYERKICKED" );
		}
	}
}

/*
	A server thread for monitoring all bot's in game. Will add and kick bots according to server settings.
*/
addBots()
{
	level endon( "game_ended" );
	
	bot_wait_for_host();
	
	for ( ;; )
	{
		wait 1.5;
		
		addBots_loop();
	}
}

/*
	A thread for ALL players, will monitor and grenades thrown.
*/
onGrenadeFire()
{
	self endon( "disconnect" );
	
	for ( ;; )
	{
		self waittill ( "grenade_fire", grenade, weaponName );
		
		if ( !isdefined( grenade ) )
		{
			continue;
		}
		
		grenade.name = weaponName;
		
		if ( weaponName == "smoke_grenade_mp" )
		{
			grenade thread AddToSmokeList();
		}
		else if ( issubstr( weaponName, "frag_" ) )
		{
			grenade thread AddToFragList( self );
		}
	}
}

/*
	Adds a frag grenade to the list of all frags
*/
AddToFragList( who )
{
	grenade = spawnstruct();
	grenade.origin = self getorigin();
	grenade.velocity = ( 0, 0, 0 );
	grenade.grenade = self;
	grenade.owner = who;
	grenade.team = who.team;
	grenade.throwback = undefined;
	
	grenade thread thinkFrag();
	
	level.bots_fraglist ListAdd( grenade );
}

/*
	Watches while the frag exists
*/
thinkFrag()
{
	while ( isdefined( self.grenade ) )
	{
		nowOrigin = self.grenade getorigin();
		self.velocity = ( nowOrigin - self.origin ) * 20;
		self.origin = nowOrigin;
		
		wait 0.05;
	}
	
	level.bots_fraglist ListRemove( self );
}

/*
	Adds a smoke grenade to the list of smokes in the game. Used to prevent bots from seeing through smoke.
*/
AddToSmokeList()
{
	grenade = spawnstruct();
	grenade.origin = self getorigin();
	grenade.state = "moving";
	grenade.grenade = self;
	
	grenade thread thinkSmoke();
	
	level.bots_smokelist ListAdd( grenade );
}

/*
	The smoke grenade logic.
*/
thinkSmoke()
{
	while ( isdefined( self.grenade ) )
	{
		self.origin = self.grenade getorigin();
		self.state = "moving";
		wait 0.05;
	}
	
	self.state = "smoking";
	wait 11.5;
	
	level.bots_smokelist ListRemove( self );
}

/*
	A thread for ALL players when they fire.
*/
onWeaponFired()
{
	self endon( "disconnect" );
	self.bots_firing = false;
	
	for ( ;; )
	{
		self waittill( "weapon_fired" );
		self thread doFiringThread();
	}
}

/*
	Lets bot's know that the player is firing.
*/
doFiringThread()
{
	self endon( "disconnect" );
	self endon( "weapon_fired" );
	self.bots_firing = true;
	wait 1;
	self.bots_firing = false;
}
