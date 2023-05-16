/*
	_bot
	Author: INeedGames, diamante0018
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
	level.bw_VERSION = "2.3.3";

	if ( getDvar( "bots_main" ) == "" )
		setDvar( "bots_main", true );

	if ( !getDvarInt( "bots_main" ) )
		return;

	thread load_waypoints();
	thread hook_callbacks();

	if ( getDvar( "bots_main_GUIDs" ) == "" )
		setDvar( "bots_main_GUIDs", "" ); //guids of players who will be given host powers, comma seperated

	if ( getDvar( "bots_main_firstIsHost" ) == "" )
		setDvar( "bots_main_firstIsHost", false ); //first play to connect is a host

	if ( getDvar( "bots_main_waitForHostTime" ) == "" )
		setDvar( "bots_main_waitForHostTime", 10.0 ); //how long to wait to wait for the host player

	if ( getDvar( "bots_main_kickBotsAtEnd" ) == "" )
		setDvar( "bots_main_kickBotsAtEnd", false ); //kicks the bots at game end

	if ( getDvar( "bots_manage_add" ) == "" )
		setDvar( "bots_manage_add", 0 ); //amount of bots to add to the game

	if ( getDvar( "bots_manage_fill" ) == "" )
		setDvar( "bots_manage_fill", 0 ); //amount of bots to maintain

	if ( getDvar( "bots_manage_fill_spec" ) == "" )
		setDvar( "bots_manage_fill_spec", true ); //to count for fill if player is on spec team

	if ( getDvar( "bots_manage_fill_mode" ) == "" )
		setDvar( "bots_manage_fill_mode", 0 ); //fill mode, 0 adds everyone, 1 just bots, 2 maintains at maps, 3 is 2 with 1

	if ( getDvar( "bots_manage_fill_kick" ) == "" )
		setDvar( "bots_manage_fill_kick", false ); //kick bots if too many

	if ( getDvar( "bots_team" ) == "" )
		setDvar( "bots_team", "autoassign" ); //which team for bots to join

	if ( getDvar( "bots_team_amount" ) == "" )
		setDvar( "bots_team_amount", 0 ); //amount of bots on axis team

	if ( getDvar( "bots_team_force" ) == "" )
		setDvar( "bots_team_force", false ); //force bots on team

	if ( getDvar( "bots_team_mode" ) == "" )
		setDvar( "bots_team_mode", 0 ); //counts just bots when 1

	if ( getDvar( "bots_skill" ) == "" )
		setDvar( "bots_skill", 0 ); //0 is random, 1 is easy 7 is hard, 8 is custom, 9 is completely random

	if ( getDvar( "bots_skill_axis_hard" ) == "" )
		setDvar( "bots_skill_axis_hard", 0 ); //amount of hard bots on axis team

	if ( getDvar( "bots_skill_axis_med" ) == "" )
		setDvar( "bots_skill_axis_med", 0 );

	if ( getDvar( "bots_skill_allies_hard" ) == "" )
		setDvar( "bots_skill_allies_hard", 0 );

	if ( getDvar( "bots_skill_allies_med" ) == "" )
		setDvar( "bots_skill_allies_med", 0 );

	if ( getDvar( "bots_skill_min" ) == "" )
		setDvar( "bots_skill_min", 1 );

	if ( getDvar( "bots_skill_max" ) == "" )
		setDvar( "bots_skill_max", 7 );

	if ( getDvar( "bots_loadout_reasonable" ) == "" ) //filter out the bad 'guns' and perks
		setDvar( "bots_loadout_reasonable", false );

	if ( getDvar( "bots_loadout_allow_op" ) == "" ) //allows jug, marty and laststand
		setDvar( "bots_loadout_allow_op", true );

	if ( getDvar( "bots_loadout_rank" ) == "" ) // what rank the bots should be around, -1 is around the players, 0 is all random
		setDvar( "bots_loadout_rank", -1 );

	if ( getDvar( "bots_loadout_prestige" ) == "" ) // what pretige the bots will be, -1 is the players, -2 is random
		setDvar( "bots_loadout_prestige", -1 );

	if ( getDvar( "bots_play_move" ) == "" ) //bots move
		setDvar( "bots_play_move", true );

	if ( getDvar( "bots_play_knife" ) == "" ) //bots knife
		setDvar( "bots_play_knife", true );

	if ( getDvar( "bots_play_fire" ) == "" ) //bots fire
		setDvar( "bots_play_fire", true );

	if ( getDvar( "bots_play_nade" ) == "" ) //bots grenade
		setDvar( "bots_play_nade", true );

	if ( getDvar( "bots_play_take_carepackages" ) == "" ) //bots take carepackages
		setDvar( "bots_play_take_carepackages", true );

	if ( getDvar( "bots_play_obj" ) == "" ) //bots play the obj
		setDvar( "bots_play_obj", true );

	if ( getDvar( "bots_play_camp" ) == "" ) //bots camp and follow
		setDvar( "bots_play_camp", true );

	if ( getDvar( "bots_play_jumpdrop" ) == "" ) //bots jump and dropshot
		setDvar( "bots_play_jumpdrop", true );

	if ( getDvar( "bots_play_target_other" ) == "" ) //bot target non play ents (vehicles)
		setDvar( "bots_play_target_other", true );

	if ( getDvar( "bots_play_killstreak" ) == "" ) //bot use killstreaks
		setDvar( "bots_play_killstreak", true );

	if ( getDvar( "bots_play_ads" ) == "" ) //bot ads
		setDvar( "bots_play_ads", true );

	if ( getDvar( "bots_play_aim" ) == "" )
		setDvar( "bots_play_aim", true );

	if ( !isDefined( game["botWarfare"] ) )
		game["botWarfare"] = true;

	level.defuseObject = undefined;
	level.bots_smokeList = List();
	level.bots_fragList = List();

	level.bots_minSprintDistance = 315;
	level.bots_minSprintDistance *= level.bots_minSprintDistance;
	level.bots_minGrenadeDistance = 256;
	level.bots_minGrenadeDistance *= level.bots_minGrenadeDistance;
	level.bots_maxGrenadeDistance = 1024;
	level.bots_maxGrenadeDistance *= level.bots_maxGrenadeDistance;
	level.bots_maxKnifeDistance = 80;
	level.bots_maxKnifeDistance *= level.bots_maxKnifeDistance;
	level.bots_goalDistance = 27.5;
	level.bots_goalDistance *= level.bots_goalDistance;
	level.bots_noADSDistance = 200;
	level.bots_noADSDistance *= level.bots_noADSDistance;
	level.bots_maxShotgunDistance = 500;
	level.bots_maxShotgunDistance *= level.bots_maxShotgunDistance;
	level.bots_listenDist = 100;

	level.smokeRadius = 255;

	level.bots = [];

	level.bots_fullautoguns = [];
	level.bots_fullautoguns["aa12"] = true;
	level.bots_fullautoguns["ak47"] = true;
	level.bots_fullautoguns["aug"] = true;
	level.bots_fullautoguns["fn2000"] = true;
	level.bots_fullautoguns["glock"] = true;
	level.bots_fullautoguns["kriss"] = true;
	level.bots_fullautoguns["m4"] = true;
	level.bots_fullautoguns["m240"] = true;
	level.bots_fullautoguns["masada"] = true;
	level.bots_fullautoguns["mg4"] = true;
	level.bots_fullautoguns["mp5k"] = true;
	level.bots_fullautoguns["p90"] = true;
	level.bots_fullautoguns["pp2000"] = true;
	level.bots_fullautoguns["rpd"] = true;
	level.bots_fullautoguns["sa80"] = true;
	level.bots_fullautoguns["scar"] = true;
	level.bots_fullautoguns["tavor"] = true;
	level.bots_fullautoguns["tmp"] = true;
	level.bots_fullautoguns["ump45"] = true;
	level.bots_fullautoguns["uzi"] = true;

	level.bots_fullautoguns["ac130"] = true;
	level.bots_fullautoguns["heli"] = true;

	level.bots_fullautoguns["ak47classic"] = true;
	level.bots_fullautoguns["ak74u"] = true;
	level.bots_fullautoguns["peacekeeper"] = true;

	level thread fixGamemodes();

	level thread onPlayerConnect();
	level thread addNotifyOnAirdrops();
	level thread watchScrabler();

	level thread handleBots();

	level thread maps\mp\bots\_bot_http::doVersionCheck();
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
		wait 0.05;

	setDvar( "bots_manage_add", getBotArray().size );

	if ( !getDvarInt( "bots_main_kickBotsAtEnd" ) )
		return;

	bots = getBotArray();

	for ( i = 0; i < bots.size; i++ )
	{
		kick( bots[i] getEntityNumber(), "EXE_PLAYERKICKED" );
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

	self [[level.prevCallbackPlayerDamage]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
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

	self [[level.prevCallbackPlayerKilled]]( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration );
}

/*
	Starts the callbacks.
*/
hook_callbacks()
{
	level waittill( "prematch_over" ); // iw4madmin waits this long for some reason...
	wait 0.05; // so we need to be one frame after it sets up its callbacks.
	level.prevCallbackPlayerDamage = level.callbackPlayerDamage;
	level.callbackPlayerDamage = ::onPlayerDamage;

	level.prevCallbackPlayerKilled = level.callbackPlayerKilled;
	level.callbackPlayerKilled = ::onPlayerKilled;
}

/*
	Fixes gamemodes when level starts.
*/
fixGamemodes()
{
	for ( i = 0; i < 19; i++ )
	{
		if ( isDefined( level.bombZones ) && level.gametype == "sd" )
		{
			for ( i = 0; i < level.bombZones.size; i++ )
				level.bombZones[i].onUse = ::onUsePlantObjectFix;

			break;
		}

		if ( isDefined( level.radios ) && level.gametype == "koth" )
		{
			level thread fixKoth();

			break;
		}

		if ( isDefined( level.bombZones ) && level.gametype == "dd" )
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
		level.bombAPlanted = level.aPlanted;
		level.bombBPlanted = level.bPlanted;

		for ( i = 0; i < level.bombZones.size; i++ )
		{
			bombzone = level.bombZones[i];

			if ( isDefined( bombzone.trigger.trigger_off ) )
				bombzone.bombExploded = true;
			else
				bombzone.bombExploded = undefined;
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

		if ( !isDefined( level.radioObject ) )
		{
			continue;
		}

		for ( i = level.radios.size - 1; i >= 0; i-- )
		{
			if ( level.radioObject != level.radios[i].gameobject )
				continue;

			level.radio = level.radios[i];
			break;
		}

		while ( isDefined( level.radioObject ) && level.radio.gameobject == level.radioObject )
			wait 0.05;
	}
}

/*
	Adds a notify when the airdrop is dropped
*/
addNotifyOnAirdrops_loop()
{
	dropCrates = getEntArray( "care_package", "targetname" );

	for ( i = dropCrates.size - 1; i >= 0; i-- )
	{
		airdrop = dropCrates[i];

		if ( isDefined( airdrop.doingPhysics ) )
			continue;

		airdrop.doingPhysics = true;
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

	self.doingPhysics = false;

	if ( isDefined( self.owner ) )
		self.owner notify( "crate_physics_done" );

	self thread onCarepackageCaptured();
}

/*
	Waits to be captured
*/
onCarepackageCaptured()
{
	self endon( "death" );

	self waittill( "captured", player );

	if ( isDefined( self.owner ) && self.owner is_bot() )
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

		player.bot_isScrambled = false;

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
		player = level.players[i];
		player.bot_isScrambled = false;
	}

	for ( i = level.players.size - 1; i >= 0; i-- )
	{
		player = level.players[i];

		if ( !player _HasPerk( "specialty_localjammer" ) || !isReallyAlive( player ) )
			continue;

		if ( player isEMPed() )
			continue;

		for ( h = level.players.size - 1; h >= 0; h-- )
		{
			player2 = level.players[h];

			if ( player2 == player )
				continue;

			if ( level.teamBased && player2.team == player.team )
				continue;

			if ( DistanceSquared( player2.origin, player.origin ) > 256 * 256 )
				continue;

			player2.bot_isScrambled = true;
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

	if ( !isDefined( self.pers["bot_host"] ) )
		self thread doHostCheck();

	if ( !self is_bot() )
		return;

	if ( !isDefined( self.pers["isBot"] ) )
	{
		// fast_restart occured...
		self.pers["isBot"] = true;
	}

	if ( !isDefined( self.pers["isBotWarfare"] ) )
	{
		self.pers["isBotWarfare"] = true;
		self thread added();
	}

	self thread maps\mp\bots\_bot_internal::connected();
	self thread maps\mp\bots\_bot_script::connected();

	level.bots[level.bots.size] = self;
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

		if ( msg == "debug" && GetDvarInt( "bots_main_debug" ) )
		{
			PrintConsole( "Bot Warfare debug: " + self.name + ": " + str );
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
		bot.pers["isBot"] = true;
		bot.pers["isBotWarfare"] = true;
		bot thread added();
	}
}

/*
	A server thread for monitoring all bot's difficulty levels for custom server settings.
*/
diffBots_loop()
{
	var_allies_hard = getDVarInt( "bots_skill_allies_hard" );
	var_allies_med = getDVarInt( "bots_skill_allies_med" );
	var_axis_hard = getDVarInt( "bots_skill_axis_hard" );
	var_axis_med = getDVarInt( "bots_skill_axis_med" );
	var_skill = getDvarInt( "bots_skill" );

	allies_hard = 0;
	allies_med = 0;
	axis_hard = 0;
	axis_med = 0;

	if ( var_skill == 8 )
	{
		playercount = level.players.size;

		for ( i = 0; i < playercount; i++ )
		{
			player = level.players[i];

			if ( !isDefined( player.pers["team"] ) )
				continue;

			if ( !player is_bot() )
				continue;

			if ( player.pers["team"] == "axis" )
			{
				if ( axis_hard < var_axis_hard )
				{
					axis_hard++;
					player.pers["bots"]["skill"]["base"] = 7;
				}
				else if ( axis_med < var_axis_med )
				{
					axis_med++;
					player.pers["bots"]["skill"]["base"] = 4;
				}
				else
					player.pers["bots"]["skill"]["base"] = 1;
			}
			else if ( player.pers["team"] == "allies" )
			{
				if ( allies_hard < var_allies_hard )
				{
					allies_hard++;
					player.pers["bots"]["skill"]["base"] = 7;
				}
				else if ( allies_med < var_allies_med )
				{
					allies_med++;
					player.pers["bots"]["skill"]["base"] = 4;
				}
				else
					player.pers["bots"]["skill"]["base"] = 1;
			}
		}
	}
	else if ( var_skill != 0 && var_skill != 9 )
	{
		playercount = level.players.size;

		for ( i = 0; i < playercount; i++ )
		{
			player = level.players[i];

			if ( !player is_bot() )
				continue;

			player.pers["bots"]["skill"]["base"] = var_skill;
		}
	}

	playercount = level.players.size;
	min_diff = GetDvarInt( "bots_skill_min" );
	max_diff = GetDvarInt( "bots_skill_max" );

	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[i];

		if ( !player is_bot() )
			continue;

		player.pers["bots"]["skill"]["base"] = int( clamp( player.pers["bots"]["skill"]["base"], min_diff, max_diff ) );
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
	teamAmount = getDvarInt( "bots_team_amount" );
	toTeam = getDvar( "bots_team" );

	alliesbots = 0;
	alliesplayers = 0;
	axisbots = 0;
	axisplayers = 0;

	playercount = level.players.size;

	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[i];

		if ( !isDefined( player.pers["team"] ) )
			continue;

		if ( player is_bot() )
		{
			if ( player.pers["team"] == "allies" )
				alliesbots++;
			else if ( player.pers["team"] == "axis" )
				axisbots++;
		}
		else
		{
			if ( player.pers["team"] == "allies" )
				alliesplayers++;
			else if ( player.pers["team"] == "axis" )
				axisplayers++;
		}
	}

	allies = alliesbots;
	axis = axisbots;

	if ( !getDvarInt( "bots_team_mode" ) )
	{
		allies += alliesplayers;
		axis += axisplayers;
	}

	if ( toTeam != "custom" )
	{
		if ( getDvarInt( "bots_team_force" ) )
		{
			if ( toTeam == "autoassign" )
			{
				if ( abs( axis - allies ) > 1 )
				{
					toTeam = "axis";

					if ( axis > allies )
						toTeam = "allies";
				}
			}

			if ( toTeam != "autoassign" )
			{
				playercount = level.players.size;

				for ( i = 0; i < playercount; i++ )
				{
					player = level.players[i];

					if ( !isDefined( player.pers["team"] ) )
						continue;

					if ( !player is_bot() )
						continue;

					if ( player.pers["team"] == toTeam )
						continue;

					if ( toTeam == "allies" )
						player thread [[level.allies]]();
					else if ( toTeam == "axis" )
						player thread [[level.axis]]();
					else
						player thread [[level.spectator]]();

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
			player = level.players[i];

			if ( !isDefined( player.pers["team"] ) )
				continue;

			if ( !player is_bot() )
				continue;

			if ( player.pers["team"] == "axis" )
			{
				if ( axis > teamAmount )
				{
					player thread [[level.allies]]();
					break;
				}
			}
			else
			{
				if ( axis < teamAmount )
				{
					player thread [[level.axis]]();
					break;
				}
				else if ( player.pers["team"] != "allies" )
				{
					player thread [[level.allies]]();
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
	botsToAdd = GetDvarInt( "bots_manage_add" );

	if ( botsToAdd > 0 )
	{
		SetDvar( "bots_manage_add", 0 );

		if ( botsToAdd > 64 )
			botsToAdd = 64;

		for ( ; botsToAdd > 0; botsToAdd-- )
		{
			level add_bot();
			wait 0.25;
		}
	}

	fillMode = getDVarInt( "bots_manage_fill_mode" );

	if ( fillMode == 2 || fillMode == 3 )
		setDvar( "bots_manage_fill", getGoodMapAmount() );

	fillAmount = getDvarInt( "bots_manage_fill" );

	players = 0;
	bots = 0;
	spec = 0;

	playercount = level.players.size;

	for ( i = 0; i < playercount; i++ )
	{
		player = level.players[i];

		if ( player is_bot() )
			bots++;
		else if ( !isDefined( player.pers["team"] ) || ( player.pers["team"] != "axis" && player.pers["team"] != "allies" ) )
			spec++;
		else
			players++;
	}

	if ( fillMode == 4 )
	{
		axisplayers = 0;
		alliesplayers = 0;

		playercount = level.players.size;

		for ( i = 0; i < playercount; i++ )
		{
			player = level.players[i];

			if ( player is_bot() )
				continue;

			if ( !isDefined( player.pers["team"] ) )
				continue;

			if ( player.pers["team"] == "axis" )
				axisplayers++;
			else if ( player.pers["team"] == "allies" )
				alliesplayers++;
		}

		result = fillAmount - abs( axisplayers - alliesplayers ) + bots;

		if ( players == 0 )
		{
			if ( bots < fillAmount )
				result = fillAmount - 1;
			else if ( bots > fillAmount )
				result = fillAmount + 1;
			else
				result = fillAmount;
		}

		bots = result;
	}

	amount = bots;

	if ( fillMode == 0 || fillMode == 2 )
		amount += players;

	if ( getDVarInt( "bots_manage_fill_spec" ) )
		amount += spec;

	if ( amount < fillAmount )
		setDvar( "bots_manage_add", 1 );
	else if ( amount > fillAmount && getDvarInt( "bots_manage_fill_kick" ) )
	{
		tempBot = random( getBotArray() );

		if ( isDefined( tempBot ) )
			kick( tempBot getEntityNumber(), "EXE_PLAYERKICKED" );
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

		if ( !isDefined( grenade ) )
			continue;

		grenade.name = weaponName;

		if ( weaponName == "smoke_grenade_mp" )
			grenade thread AddToSmokeList();
		else if ( isSubStr( weaponName, "frag_" ) )
			grenade thread AddToFragList( self );
	}
}

/*
	Adds a frag grenade to the list of all frags
*/
AddToFragList( who )
{
	grenade = spawnstruct();
	grenade.origin = self getOrigin();
	grenade.velocity = ( 0, 0, 0 );
	grenade.grenade = self;
	grenade.owner = who;
	grenade.team = who.team;
	grenade.throwback = undefined;

	grenade thread thinkFrag();

	level.bots_fragList ListAdd( grenade );
}

/*
	Watches while the frag exists
*/
thinkFrag()
{
	while ( isDefined( self.grenade ) )
	{
		nowOrigin = self.grenade getOrigin();
		self.velocity = ( nowOrigin - self.origin ) * 20;
		self.origin = nowOrigin;

		wait 0.05;
	}

	level.bots_fragList ListRemove( self );
}

/*
	Adds a smoke grenade to the list of smokes in the game. Used to prevent bots from seeing through smoke.
*/
AddToSmokeList()
{
	grenade = spawnstruct();
	grenade.origin = self getOrigin();
	grenade.state = "moving";
	grenade.grenade = self;

	grenade thread thinkSmoke();

	level.bots_smokeList ListAdd( grenade );
}

/*
	The smoke grenade logic.
*/
thinkSmoke()
{
	while ( isDefined( self.grenade ) )
	{
		self.origin = self.grenade getOrigin();
		self.state = "moving";
		wait 0.05;
	}

	self.state = "smoking";
	wait 11.5;

	level.bots_smokeList ListRemove( self );
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
