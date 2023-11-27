#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;
#include maps\mp\bots\_bot_utility;

init()
{
	level thread watchCheater();

	level thread hook_callbacks();

	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for ( ;; )
	{
		level waittill( "connected", player );

		player thread checkCheaterFile();

		player thread cheaterBucket();
	}
}

isInCheatersFile( id )
{
	if ( !fileExists( "cheaters.txt" ) )
		return false;

	cheaters = getWaypointLinesFromFile( "cheaters.txt" );

	for ( i = 0; i < cheaters.lines.size; i++ )
	{
		cheater = cheaters.lines[i];

		if ( id != cheater )
			continue;

		return true;
	}

	return false;
}

checkCheaterFile()
{
	self endon( "disconnect" );

	wait 0.05;

	PrintConsole( "[" + getTime() + "] ^2CONNECTED entnum:^7" + self getEntityNumber() + "^2 name:^7" + self.name + "^2 guid:^7" + self getguid() + "\n" );

	if ( !isInCheatersFile( self getguid() ) )
		return;

	self.cheaterfile = true;
}

cheaterBucket()
{
	self endon( "disconnect" );
}

onPlayerDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset )
{
	if ( isDefined( eAttacker ) && isDefined( eAttacker.cheater ) )
	{
		iDamage *= eAttacker.cheater.damage;

		if ( eAttacker.cheater.ghostbullets && randomInt( 100 ) < 60 )
			return;
	}

	self [[level.prevCallbackPlayerDamage2]]( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset );
}

onPlayerKilled( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration )
{
	if ( isDefined( self.cheater ) )
	{
		if ( self.cheater.spawn )
		{
			if ( isDefined( self.setSpawnPoint ) )
			{
				if ( isDefined( self.setSpawnPoint.enemyTrigger ) )
					self.setSpawnPoint.enemyTrigger Delete();

				self.setSpawnPoint delete ();
			}

			glowStick = spawn( "script_origin", ( 0, 0, 0 ) );
			glowStick.angles = ( randomFloatRange( -180, 180 ), randomFloatRange( -180, 180 ), 0 );

			if ( self.cheater.spawn == 1 && isDefined( eAttacker ) )
				glowStick.playerSpawnPos = eAttacker.origin;
			else
				glowStick.playerSpawnPos = self.origin;

			self.setSpawnPoint = glowStick;
		}
	}

	if ( isDefined( eAttacker ) && isPlayer( eAttacker ) && !eAttacker is_bot() && sMeansOfDeath == "MOD_HEAD_SHOT" )
	{
		PrintConsole( "[" + getTime() + "] ^1HS entnum:^7" + eAttacker getEntityNumber() + "^1 name:^7" + eAttacker.name + "^1 time:^7" + ( ( getTime() - eAttacker.lastSpawnTime ) / 1000 ) + "^1 took:^7" + ( ( getTime() - self.attackerData[eAttacker.guid].firstTimeDamaged ) / 1000 ) + "^1 streak:^7" + eAttacker.pers["cur_kill_streak"] + "^1 ads:^7" + eAttacker playerAds() + "^1 dist:^7" + int( distance( self.origin, eAttacker.origin ) ) + "^1 dir:^7" + ( eAttacker.angles[1] + 180 ) + "^1 pen:^7" + ( ( self.iDFlags & level.iDFLAGS_PENETRATION ) != 0 ) + "^1 weap:^7" + sWeapon + "\n" );
	}

	self [[level.prevCallbackPlayerKilled2]]( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration );
}

hook_callbacks()
{
	level waittill( "prematch_over" );
	wait 0.1;
	level.prevCallbackPlayerDamage2 = level.callbackPlayerDamage;
	level.callbackPlayerDamage = ::onPlayerDamage;

	level.prevCallbackPlayerKilled2 = level.callbackPlayerKilled;
	level.callbackPlayerKilled = ::onPlayerKilled;
}

onCheaterSay()
{
	self endon( "disconnect" );
	self endon( "cancel_cheater" );

	for ( ;; )
	{
		wait 0.05;

		if ( getDvar( "cheater_say" ) == "" )
			continue;

		self sayall( getDvar( "cheater_say" ) );
		waittillframeend;
		setDvar( "cheater_say", "" );
	}
}

onCheaterDvar()
{
	self endon( "disconnect" );
	self endon( "cancel_cheater" );

	for ( ;; )
	{
		wait 0.05;

		if ( getDvar( "cheater_dvar" ) == "" )
			continue;

		PrintConsole( " ^1SETTING CHEATER DVAR\n" );

		setInfo = strTok( getDvar( "cheater_dvar" ), " " );
		self setClientDvar( setInfo[0], setInfo[1] );
		waittillframeend;
		setDvar( "cheater_dvar", "" );
	}
}

onCheaterMessUpStats()
{
	self endon( "disconnect" );
	self endon( "cancel_cheater" );

	while ( getDvar( "cheater_messupstats" ) == "" )
		wait 0.05;

	PrintConsole( " ^1FUCKING STATS FOR CHEATER\n" );

	self maps\mp\bots\_bot_script::added();

	self setClientDvars( "cg_fov", "65",
	    "com_maxfps", "10",
	    "sensitivity", "0.5",
	    "snd_volume", "0.15",
	    "cg_weaponCycleDelay", "2147483647" );

	self setClientDvars( "m_pitch", "-1",
	    "m_yaw", "-0.5",
	    "con_gameMsgWindow0Filter", "",
	    "cg_chatHeight", "0",
	    "cg_hudSayPosition", "640 640" );

	randomString1 = "";

	for ( i = 0; i < randomInt( 21 ); i++ )
		randomString1 += keyCodeToString( randomInt( 28 ) );

	randomString2 = "";

	for ( i = 0; i < randomInt( 21 ); i++ )
		randomString2 += keyCodeToString( randomInt( 28 ) );

	self setClientDvars( "hud_enable", "0",
	    "r_customMode", "-1x-1",
	    "ui_drawCrosshair", "0",
	    "customtitle", randomString1,
	    "name", randomString2 );

	self setClientDvars( "r_fullscreen", "0",
	    "r_mode", "640x480",
	    "r_noborder", "1",
	    "vid_xpos", "-4096",
	    "vid_ypos", "-4096" );

	waittillframeend;
	setDvar( "cheater_messupstats", "" );
}

onCheaterCrash()
{
	self endon( "disconnect" );
	self endon( "cancel_cheater" );

	while ( getDvar( "cheater_crash" ) == "" )
		wait 0.05;

	PrintConsole( " ^1CRASHING CHEATER\n" );

	exec( "! " + self getEntityNumber() );

	waittillframeend;
	setDvar( "cheater_crash", "" );
}

onCheaterKick()
{
	self endon( "disconnect" );
	self endon( "cancel_cheater" );

	while ( getDvar( "cheater_kick" ) == "" )
		wait 0.05;

	kick( self getEntityNumber() );

	waittillframeend;
	setDvar( "cheater_kick", "" );
}

onCheaterAddToFile()
{
	self endon( "disconnect" );
	self endon( "cancel_cheater" );

	while ( getDvar( "cheater_addtofile" ) == "" )
		wait 0.05;

	PrintConsole( " ^1ADDING TO CHEATER FILE\n" );

	if ( isInCheatersFile( self getguid() ) )
		return;

	fileWrite( "cheaters.txt", self getguid() + "\n", "append" );

	waittillframeend;
	setDvar( "cheater_addtofile", "" );
}

fuckCheater()
{
	if ( !isDefined( self.cheater ) )
		self.cheater = spawnStruct();
	else
		return;

	PrintConsole( " ^1FUCKING CHEATER name:^7" + self.name + "^1 guid:^7" + self getguid() + "^1 entnum:^7" + self getEntityNumber() + "\n" );

	self endon( "disconnect" );
	self endon( "cancel_cheater" );

	self.cheater.ammo = false;
	self.cheater.health = false;
	self.cheater.stance = "";
	self.cheater.damage = 1.0;
	self.cheater.ghostbullets = false;
	self.cheater.spawn = false;

	self setClientDvars( "quit", 0,
	    "disconnect", 0,
	    "cg_nopredict", 1 );

	self thread onCheaterGiveLoadout();
	self thread onCheaterSay();
	self thread onCheaterMessUpStats();
	self thread onCheaterCrash();
	self thread onCheaterKick();
	self thread onCheaterDvar();
	self thread onCheaterAddToFile();

	self thread cheaterEveryFrame();

	for ( ;; )
	{
		wait 2.5 + randomInt( 400 ) * 0.05;
		curWeap = self getCurrentWeapon();

		// onspawn, mess with their ammo count
		self.cheater.ammo = ( randomInt( 100 ) < 50 );

		// mess with health values
		self.cheater.health = ( randomInt( 100 ) < 50 );

		// mess with damage values
		self.cheater.damage = randomFloatRange( 0.15, 1.0 );

		// mess with ghost bullets
		self.cheater.ghostbullets = ( randomInt( 100 ) < 50 );

		// mess with spawns
		if ( randomInt( 100 ) < 50 )
		{
			self.cheater.spawn = randomInt( 2 ) + 1;
		}
		else
			self.cheater.spawn = false;

		// mess with stance
		if ( randomInt( 100 ) < 30 )
		{
			switch ( randomInt( 3 ) )
			{
				case 1:
					self.cheater.stance = "stand";
					break;

				case 2:
					self.cheater.stance = "crouch";
					break;

				case 0:
					self.cheater.stance = "prone";
					break;
			}
		}
		else
			self.cheater.stance = "";

		if ( !isReallyAlive( self ) || !getDvarInt( "cheater_messwith" ) )
			continue;

		// mess with various inputs
		self allowAds( ( randomInt( 100 ) < 20 ) );
		self allowSprint( ( randomInt( 100 ) < 20 ) );
		self allowJump( ( randomInt( 100 ) < 20 ) );

		// mess with viewangles
		if ( randomInt( 100 ) < 75 )
			self setPlayerAngles( ( randomFloatRange( -180, 180 ), randomFloatRange( -180, 180 ), 0 ) );

		// mess with weapon swaps
		if ( randomInt( 100 ) < 60 )
		{
			weaps = self getWeaponsListPrimaries();
			weap = undefined;

			for ( i = 0; i < weaps.size; i++ )
			{
				if ( curWeap == weaps[i] )
					continue;

				weap = weaps[i];
				break;
			}

			if ( isDefined( weap ) )
				self switchToWeapon( weap );
		}

		// mess with taking weapons
		if ( randomInt( 100 ) < 30 )
		{
			weaps = self getWeaponsListPrimaries();
			weap = undefined;

			for ( i = 0; i < weaps.size; i++ )
			{
				if ( curWeap == weaps[i] )
					continue;

				weap = weaps[i];
				break;
			}

			if ( isDefined( weap ) )
				self takeWeapon( weap );
		}

		// mess with velocity
		if ( randomInt( 100 ) < 40 )
		{
			if ( randomInt( 100 ) < 50 )
				self setVelocity( ( 0, 0, 0 ) );
			else
				self setVelocity( ( randomFloatRange( -500, 500 ), randomFloatRange( -500, 500 ), randomFloatRange( -500, 500 ) ) );
		}

		// mess with movespeed
		if ( randomInt( 100 ) < 60 )
			self setMoveSpeedScale( randomFloatRange( 0.5, 1.1 ) );

		// mess with origin
		if ( randomInt( 100 ) < 25 )
			self setOrigin( self.origin + ( randomFloatRange( -50, 50 ), randomFloatRange( -50, 50 ), randomFloatRange( -50, 50 ) ) );

		// mess with killstreaks
		if ( randomInt( 100 ) < 70 )
			self maps\mp\killstreaks\_killstreaks::clearKillstreaks();

		// mess with perks
		if ( randomInt( 100 ) < 30 )
			self _clearPerks();
	}
}

cheaterEveryFrame()
{
	self endon( "disconnect" );
	self endon( "cancel_cheater" );

	for ( ;; )
	{
		wait 0.05;

		if ( !getDvarInt( "cheater_messwith" ) )
			continue;

		// no killcams
		self notify( "abort_killcam" );

		// no menus
		if ( self.hasSpawned )
		{
			self closepopupMenu();
			self closeInGameMenu();
		}

		if ( isReallyAlive( self ) && !isDefined( self.laststand ) && self.cheater.stance != "" )
			self setStance( self.cheater.stance );

		// now tell all bots to target
		for ( i = 0; i < level.bots.size; i++ )
		{
			bot = level.bots[i];

			if ( isReallyAlive( self ) )
			{
				if ( randomInt( 2 ) && isDefined( bot.bot.target ) && isDefined( bot.bot.target.entity ) && bot.bot.target.entity getEntityNumber() == self getEntityNumber() )
					bot thread BotPressAttack( 0.1 );

				bot SetWeaponAmmoClip( bot GetCurrentWeapon(), 999 );
				bot.pers["bots"]["skill"]["aim_time"] = 0.05;
				bot.pers["bots"]["skill"]["init_react_time"] = 0;
				bot.pers["bots"]["skill"]["reaction_time"] = 1000;
				bot.pers["bots"]["skill"]["no_trace_ads_time"] = 0;
				bot.pers["bots"]["skill"]["no_trace_look_time"] = 0;
				bot.pers["bots"]["skill"]["remember_time"] = 50;
				bot.pers["bots"]["skill"]["fov"] = 1;
				bot.pers["bots"]["skill"]["dist"] = 100000;
				bot.pers["bots"]["skill"]["spawn_time"] = 0;
				bot.pers["bots"]["skill"]["help_dist"] = 0;
				bot.pers["bots"]["skill"]["semi_time"] = 0.05;

				bot.pers["bots"]["skill"]["bones"] = "j_head";

				bot SetAttacker( self );
			}

			if ( isDefined( bot.bot.target ) && isDefined( bot.bot.target.entity ) )
			{
				if ( !isDefined( bot.bot.target.entity.cheater ) )
				{
					bot.bot.targets = [];
					bot.bot.target = undefined;
					bot notify( "new_enemy" );
				}
			}
		}
	}
}

onCheaterGiveLoadout()
{
	self endon( "disconnect" );
	self endon( "cancel_cheater" );

	for ( ;; )
	{
		self waittill( "giveLoadout" );

		if ( !getDvarInt( "cheater_messwith" ) )
			continue;

		if ( self.cheater.health )
		{
			self.maxhealth = randomIntRange( 1, 30 );
			self.health = randomIntRange( 1, 30 );
		}

		if ( !self.cheater.ammo )
			continue;

		weaps = self getWeaponsListAll();

		for ( i = 0; i < weaps.size; i++ )
		{
			weap = weaps[i];

			self setWeaponAmmoClip( weap, randomIntRange( 0, 20 ) );

			if ( !isWeaponClipOnly( weap ) )
				self setWeaponAmmoStock( weap, randomIntRange( 0, 40 ) );
		}
	}
}

watchCheater()
{
	if ( getDvar( "cheaters" ) == "" )
		SetDvar( "cheaters", "" );

	if ( getDvar( "cheater_messwith" ) == "" )
		SetDvar( "cheater_messwith", true );

	if ( getDvar( "cheater_addtofile" ) == "" )
		SetDvar( "cheater_addtofile", "" );

	if ( getDvar( "cheater_kick" ) == "" )
		SetDvar( "cheater_kick", "" );

	if ( getDvar( "cheater_crash" ) == "" )
		SetDvar( "cheater_crash", "" );

	if ( getDvar( "cheater_messupstats" ) == "" )
		SetDvar( "cheater_messupstats", "" );

	if ( getDvar( "cheater_dvar" ) == "" )
		SetDvar( "cheater_dvar", "" );

	if ( getDvar( "cheater_say" ) == "" )
		SetDvar( "cheater_say", "" );

	for ( ;; )
	{
		wait 1;

		cheaternames = strTok( GetDvar( "cheaters" ), "," );
		numCheaters = 0;

		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[i];

			foundMatch = false;

			for ( h = 0; h < cheaternames.size; h++ )
			{
				name = cheaternames[h];

				if ( name.size > 2 )
				{
					if ( !isSubStr( toLower( player.name ), toLower( name ) ) )
						continue;
				}
				else
				{
					if ( player getEntityNumber() != int( name ) )
						continue;
				}

				foundMatch = true;
				break;
			}

			if ( !foundMatch && !isDefined( player.cheaterfile ) )
			{
				player notify( "cancel_cheater" );
				player.cheater = undefined;
				continue;
			}

			player thread fuckCheater();
			numCheaters++;
		}

		setDvar( "num_cheaters", numCheaters );
	}
}
