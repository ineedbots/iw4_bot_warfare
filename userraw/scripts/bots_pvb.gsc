#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\bots\_bot_utility;

init()
{
	level thread onBotConnected();

	level thread onSomeoneSaid();

	level thread onBotSayVar();

	level thread watchTeams();

	level thread watchBotCrackedClass();

	level thread watchBoxmap();

	level thread watchNuke();

	level thread watchSniper();
}

watchSniper()
{
	if ( getDvar( "bot_sniperCheck" ) == "" )
		return;

	for ( ;; )
	{
		wait 15;
		logPrint("keepalive\n");

		numPlayers = 0;
		numSnipers = 0;

		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];

			if ( player is_bot() )
				continue;

			if ( !isDefined( player.team ) )
				continue;

			numPlayers++;

			if ( isDefined( player.isSniper ) && player.isSniper )
				numSnipers++;
		}

		if ( numPlayers > 0 )
		{
			if ( numSnipers / numPlayers >= 0.5 )
				setDvar( "bots_sniperLoadout", 1 );
			else
				setDvar( "bots_sniperLoadout", 0 );
		}
	}
}

watchNuke()
{
	setDvar( "scr_spawnpointfavorweight", "" );

	for ( i = 0; i < 3; i++ )
		level waittill( "nuke_death" );

	setDvar( "scr_spawnpointfavorweight", "499999" );
}

watchBoxmap()
{
	if ( getDvar( "mapname" ) == "iw4_credits" )
		setDvar( "scr_spawnsimple", 1 );
	else
		setDvar( "scr_spawnsimple", 0 );
}

watchBotCrackedClass()
{
	if ( getDvar( "bot_pvb_helper_customBotClassTeam" ) == "" )
		setDvar( "bot_pvb_helper_customBotClassTeam", "" );

	for ( ;; )
	{
		level waittill( "bot_connected", bot );

		bot thread watchBotLoadout();
	}
}

watchBotLoadout()
{
	self endon( "disconnect" );

	random = randomInt( 2 );

	for ( ;; )
	{
		self waittill( "bot_giveLoadout" );

		team = getDvar( "bot_pvb_helper_customBotClassTeam" );

		if ( team == "" )
			continue;

		if ( self.team != team )
			continue;

		// clear perks and weapons
		self takeAllWeapons();
		self.specialty = [];
		self _clearPerks();

		// give perks
		self maps\mp\perks\_perks::givePerk( "specialty_fastreload" );
		self maps\mp\perks\_perks::givePerk( "specialty_quickdraw" );
		self maps\mp\perks\_perks::givePerk( "specialty_bulletdamage" );
		self maps\mp\perks\_perks::givePerk( "specialty_armorpiercing" );
		self maps\mp\perks\_perks::givePerk( "specialty_bulletaccuracy" );
		self maps\mp\perks\_perks::givePerk( "specialty_holdbreath" );

		self maps\mp\perks\_perks::givePerk( "semtex_mp" );

		twoStreak = "helicopter_minigun";

		if ( random )
			twoStreak = "ac130";

		self maps\mp\gametypes\_class::setKillstreaks( "harrier_airstrike", twoStreak, "nuke" );

		// give weapons
		self _giveWeapon( "stun_grenade_mp", 0 );
		self _giveWeapon( "g18_xmags_mp", 0 );

		self _giveWeapon( "rpd_xmags_mp", 0 );
		self setSpawnWeapon( "rpd_xmags_mp" );
	}
}

watchTeams()
{
	if ( getDvar( "bot_pvb_helper_noPlayersOnTeam" ) == "" )
		setDvar( "bot_pvb_helper_noPlayersOnTeam", "" );

	for ( ;; )
	{
		wait 1;

		if ( getDvar( "bot_pvb_helper_noPlayersOnTeam" ) == "" )
			continue;

		team = getDvar( "bot_pvb_helper_noPlayersOnTeam" );

		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];

			if ( player is_bot() )
				continue;

			if ( player.team != team )
				continue;

			if ( team == "axis" )
				player [[level.allies]]();
			else
				player [[level.axis]]();
		}
	}
}

onBotSayVar()
{
	SetDvar( "bot_say", "" );

	for ( ;; )
	{
		wait 0.05;

		toSay = GetDvar( "bot_say" );

		if ( toSay == "" )
			continue;

		bot = random( getBotArray() );

		if ( !isDefined( bot ) )
			continue;

		SetDvar( "bot_say", "" );
		bot sayall( toSay );
	}
}

onSomeoneSaid()
{
	for ( ;; )
	{
		level waittill( "say", string, player );

		PrintConsole( player.name + ": ^7" + string + "\n" );
	}
}

onBotConnected()
{
	for ( ;; )
	{
		level waittill( "bot_connected", bot );

		bot thread setBotPing();
	}
}

setBotPing()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		wait 0.05;

		self SetPing( randomIntRange( 40, 60 ) );
	}
}
