#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

KILLSTREAK_STRING_TABLE = "mp/killstreakTable.csv";

init()
{
	// &&1 Kill Streak!
	precacheString( &"MP_KILLSTREAK_N" );
	precacheString( &"MP_NUKE_ALREADY_INBOUND" );
	precacheString( &"MP_UNAVILABLE_IN_LASTSTAND" );
	precacheString( &"MP_UNAVAILABLE_WHEN_EMP" );
	precacheString( &"MP_UNAVAILABLE_USING_TURRET" );
	precacheString( &"MP_UNAVAILABLE_WHEN_INCAP" );
	precacheString( &"MP_HELI_IN_QUEUE" );

	initKillstreakData();

	level.killstreakFuncs = [];
	level.killstreakSetupFuncs = [];
	level.killstreakWeapons = [];
	
	level.killStreakMod = 0;

	thread maps\mp\killstreaks\_ac130::init();
	thread maps\mp\killstreaks\_remotemissile::init();
	thread maps\mp\killstreaks\_uav::init();
	thread maps\mp\killstreaks\_airstrike::init();
	thread maps\mp\killstreaks\_airdrop::init();
	thread maps\mp\killstreaks\_helicopter::init();
	thread maps\mp\killstreaks\_autosentry::init();
	thread maps\mp\killstreaks\_tank::init();
	thread maps\mp\killstreaks\_emp::init();
	thread maps\mp\killstreaks\_nuke::init();

	level.killstreakRoundDelay = getIntProperty( "scr_game_killstreakdelay", 8 );

	level thread onPlayerConnect();
}


initKillstreakData()
{
	for ( i = 1; true; i++ )
	{
		retVal = tableLookup( KILLSTREAK_STRING_TABLE, 0, i, 1 );
		if ( !isDefined( retVal ) || retVal == "" )
			break;

		streakRef = tableLookup( KILLSTREAK_STRING_TABLE, 0, i, 1 );
		assert( streakRef != "" );

		streakUseHint = tableLookupIString( KILLSTREAK_STRING_TABLE, 0, i, 6 );
		assert( streakUseHint != &"" );
		precacheString( streakUseHint );

		streakEarnDialog = tableLookup( KILLSTREAK_STRING_TABLE, 0, i, 8 );
		assert( streakEarnDialog != "" );
		game[ "dialog" ][ streakRef ] = streakEarnDialog;

		streakAlliesUseDialog = tableLookup( KILLSTREAK_STRING_TABLE, 0, i, 9 );
		assert( streakAlliesUseDialog != "" );
		game[ "dialog" ][ "allies_friendly_" + streakRef + "_inbound" ] = "use_" + streakAlliesUseDialog;
		game[ "dialog" ][ "allies_enemy_" + streakRef + "_inbound" ] = "enemy_" + streakAlliesUseDialog;

		streakAxisUseDialog = tableLookup( KILLSTREAK_STRING_TABLE, 0, i, 10 );
		assert( streakAxisUseDialog != "" );
		game[ "dialog" ][ "axis_friendly_" + streakRef + "_inbound" ] = "use_" + streakAxisUseDialog;
		game[ "dialog" ][ "axis_enemy_" + streakRef + "_inbound" ] = "enemy_" + streakAxisUseDialog;

		streakWeapon = tableLookup( KILLSTREAK_STRING_TABLE, 0, i, 12 );
		precacheItem( streakWeapon );

		streakPoints = int( tableLookup( KILLSTREAK_STRING_TABLE, 0, i, 13 ) );
		assert( streakPoints != 0 );
		maps\mp\gametypes\_rank::registerScoreInfo( "killstreak_" + streakRef, streakPoints );

		streakShader = tableLookup( KILLSTREAK_STRING_TABLE, 0, i, 14 );
		precacheShader( streakShader );

		streakShader = tableLookup( KILLSTREAK_STRING_TABLE, 0, i, 15 );
		if ( streakShader != "" )
			precacheShader( streakShader );
	}
}


onPlayerConnect()
{
	for ( ;; )
	{
		level waittill( "connected", player );
		
		if( !isDefined ( player.pers[ "killstreaks" ] ) )
			player.pers[ "killstreaks" ] = [];
		
		player.lifeId = 0;
			
		if ( isDefined( player.pers["deaths"] ) )
			player.lifeId = player.pers["deaths"];

		player VisionSetMissilecamForPlayer( game["thermal_vision"] );
	
		player thread onPlayerSpawned();
		player thread onPlayerChangeKit();
	}
}


onPlayerSpawned()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "spawned_player" );
		self thread killstreakUseWaiter();
		self thread waitForChangeTeam();
		
		self giveOwnedKillstreakItem( true );
	}
}

onPlayerChangeKit()
{
	self endon( "disconnect" );
	
	for ( ;; )
	{
		self waittill( "changed_kit" );
		self giveOwnedKillstreakItem();
	}
}


waitForChangeTeam()
{
	self endon ( "disconnect" );
	
	self notify ( "waitForChangeTeam" );
	self endon ( "waitForChangeTeam" );
	
	for ( ;; )
	{
		self waittill ( "joined_team" );
		clearKillstreaks();
	}
}


isRideKillstreak( streakName )
{
	switch( streakName )
	{
		case "helicopter_minigun":
		case "helicopter_mk19":
		case "ac130":
		case "predator_missile":
			return true;

		default:
			return false;
	}
}

isCarryKillstreak( streakName )
{
	switch( streakName )
	{
		case "sentry":
		case "sentry_gl":
			return true;

		default:
			return false;
	}
}


deadlyKillstreak( streakName )
{
	switch ( streakName )
	{
		case "predator_missile":
		case "precision_airstrike":
		case "harrier_airstrike":
		//case "helicopter":
		//case "helicopter_flares":
		case "stealth_airstrike":
		//case "helicopter_minigun":
		case "ac130":
			return true;
	}
	
	return false;
}


killstreakUsePressed()
{
	streakName = self.pers["killstreaks"][0].streakName;
	lifeId = self.pers["killstreaks"][0].lifeId;
	isEarned = self.pers["killstreaks"][0].earned;
	awardXp = self.pers["killstreaks"][0].awardXp;

	assert( isDefined( streakName ) );
	assert( isDefined( level.killstreakFuncs[ streakName ] ) );

	if ( !self isOnGround() && ( isRideKillstreak( streakName ) || isCarryKillstreak( streakName ) ) )
		return ( false );

	if ( self isUsingRemote() )
		return ( false );

	if ( isDefined( self.selectingLocation ) )
		return ( false );
		
	if ( deadlyKillstreak( streakName ) && level.killstreakRoundDelay && getGametypeNumLives() )
	{
		if ( level.gracePeriod - level.inGracePeriod < level.killstreakRoundDelay )
		{
			self iPrintLnBold( &"MP_UNAVAILABLE_FOR_N", (level.killstreakRoundDelay - (level.gracePeriod - level.inGracePeriod)) );
			return ( false );
		}
	}

	if ( (level.teamBased && level.teamEMPed[self.team]) || (!level.teamBased && isDefined( level.empPlayer ) && level.empPlayer != self) )
	{
		self iPrintLnBold( &"MP_UNAVAILABLE_WHEN_EMP" );
		return ( false );
	}

	if ( self IsUsingTurret() && ( isRideKillstreak( streakName ) || isCarryKillstreak( streakName ) ) )
	{
		self iPrintLnBold( &"MP_UNAVAILABLE_USING_TURRET" );
		return ( false );
	}
	
	if ( isDefined( self.lastStand )  && isRideKillstreak( streakName ) )
	{
		self iPrintLnBold( &"MP_UNAVILABLE_IN_LASTSTAND" );
		return ( false );
	}
	
	if ( !self isWeaponEnabled() )
		return ( false );
	
	if ( !self [[ level.killstreakFuncs[ streakName ] ]]( lifeId ) )
		return ( false );

	self usedKillstreak( streakName, awardXp );
	self shuffleKillStreaksFILO( streakName );	
	self giveOwnedKillstreakItem();		

	return ( true );
}


//this overwrites killstreak at index 0 and decrements all other killstreaks (FCLS style)
shuffleKillStreaksFILO( streakName )
{
	self _setActionSlot( 4, "" );

	arraySize = self.pers["killstreaks"].size;

	streakIndex = -1;
	for ( i = 0; i < arraySize; i++ )
	{
		if ( self.pers["killstreaks"][i].streakName != streakName )
			continue;
			
		streakIndex = i;
		break;
	}
	assert( streakIndex >= 0 );

	self.pers["killstreaks"][streakIndex] = undefined;

	for( i = streakIndex + 1; i < arraySize; i++ )	
	{
		if ( i == arraySize - 1 ) 
		{	
			self.pers["killstreaks"][i-1] = self.pers["killstreaks"][i];
			self.pers["killstreaks"][i] = undefined;
		}	
		else
		{
			self.pers["killstreaks"][i-1] = self.pers["killstreaks"][i];
		}	
	}
}


usedKillstreak( streakName, awardXp )
{
	self playLocalSound( "weap_c4detpack_trigger_plr" );

	if ( awardXp )
		self thread [[ level.onXPEvent ]]( "killstreak_" + streakName );

	self thread maps\mp\gametypes\_missions::useHardpoint( streakName );
	
	awardref = maps\mp\_awards::getKillstreakAwardRef( streakName );
	if ( isDefined( awardref ) )
		self thread incPlayerStat( awardref, 1 );

	team = self.team;

	if ( level.teamBased )
	{
		thread leaderDialog( team + "_friendly_" + streakName + "_inbound", team );
		
		if ( getKillstreakInformEnemy( streakName ) )
			thread leaderDialog( team + "_enemy_" + streakName + "_inbound", level.otherTeam[ team ] );
	}
	else
	{
		self thread leaderDialogOnPlayer( team + "_friendly_" + streakName + "_inbound" );
		
		if ( getKillstreakInformEnemy( streakName ) )
		{
			excludeList[0] = self;
			thread leaderDialog( team + "_enemy_" + streakName + "_inbound", undefined, undefined, excludeList );
		}
	}
}


clearKillstreaks()
{
	foreach ( index, streakStruct in self.pers["killstreaks"] )
		self.pers["killstreaks"][index] = undefined;
}


killstreakUseWaiter()
{
	self endon( "disconnect" );
	self endon( "finish_death" );
	level endon( "game_ended" );

	self.lastKillStreak = 0;
	if ( !isDefined( self.pers["lastEarnedStreak"] ) )
		self.pers["lastEarnedStreak"] = undefined;
		
	self thread finishDeathWaiter();

	for ( ;; )
	{
		self waittill ( "weapon_change", newWeapon );
		
		if ( !isAlive( self ) )
			continue;

		if ( !isDefined( self.pers["killstreaks"][0] ) )
			continue;

		if ( newWeapon != getKillstreakWeapon( self.pers["killstreaks"][0].streakName ) )
			continue;

		waittillframeend;

		streakName = self.pers["killstreaks"][0].streakName;
		result = self killstreakUsePressed();

		//no force switching weapon for ridable killstreaks
		if ( !isRideKillstreak( streakName ) || !result )
			self switchToWeapon( self getLastWeapon() );

		// give time to switch to the near weapon; when the weapon is none (such as during a "disableWeapon()" period
		// re-enabling the weapon immediately does a "weapon_change" to the killstreak weapon we just used.  In the case that 
		// we have two of that killstreak, it immediately uses the second one
		if ( self getCurrentWeapon() == "none" )
		{
			while ( self getCurrentWeapon() == "none" )
				wait ( 0.05 );

			waittillframeend;
		}
	}
}


finishDeathWaiter()
{
	self endon ( "disconnect" );
	
	self waittill ( "death" );
	wait ( 0.05 );
	self notify ( "finish_death" );
	self.pers["lastEarnedStreak"] = undefined;
}


checkKillstreakReward( streakCount )
{
	self notify( "got_killstreak", streakCount );

	maxVal = 0;
	killStreaks = [];
	foreach ( streakVal, streakName in self.killStreaks )
	{
		killStreaks[streakName] = streakVal;
		if ( streakVal > maxVal )
			maxVal = streakVal;
	}

	foreach ( streakVal, streakName in self.killStreaks )
	{
		actualVal = streakVal + level.killStreakMod;
		
		if ( actualVal > streakCount )
			break;
		
		if ( isDefined( self.pers["lastEarnedStreak"] ) && killStreaks[streakName] <= killStreaks[self.pers["lastEarnedStreak"]] )
			continue;

		if ( isSubStr( streakName, "-rollover" ) )
		{
			continue;
			/*
			if ( game["defcon"] > 2 )
			{
				self.pers["lastEarnedStreak"] = streakName;
				continue;
			}
			
			useStreakName = strTok( streakName, "-" )[0];
			*/
		}
		else
		{
			useStreakName = streakName;
		}
		
		if ( self tryGiveKillstreak( useStreakName, int(max( actualVal, streakCount )) ) )
		{
			self thread killstreakEarned( useStreakName );
			self.pers["lastEarnedStreak"] = streakName;
		}
	}
}


killstreakEarned( streakName )
{
	if ( self getPlayerData( "killstreaks", 0 ) == streakName )
	{
		self.firstKillstreakEarned = getTime();
	}	
	else if ( self getPlayerData( "killstreaks", 2 ) == streakName && isDefined( self.firstKillstreakEarned ) )
	{
		if ( getTime() - self.firstKillstreakEarned < 20000 )
			self thread maps\mp\gametypes\_missions::genericChallenge( "wargasm" );
	}
}


rewardNotify( streakName, streakVal )
{
	self endon( "disconnect" );

	self maps\mp\gametypes\_hud_message::killstreakSplashNotify( streakName, streakVal );
}


tryGiveKillstreak( streakName, streakVal )
{
	level notify ( "gave_killstreak", streakName );

	if ( !level.gameEnded )
		self thread rewardNotify( streakName, streakVal );

	self giveKillstreak( streakName, streakVal, true );
	return true;
}


giveKillstreak( streakName, isEarned, awardXp, owner )
{
	self endon ( "disconnect" );

	weapon = getKillstreakWeapon( streakName );

	self giveKillstreakWeapon( weapon );
	
	// shuffle existing killstreaks up a notch
	for( i = self.pers["killstreaks"].size; i >= 0; i-- )	
		self.pers["killstreaks"][i + 1] = self.pers["killstreaks"][i]; 	
	
	self.pers["killstreaks"][0] = spawnStruct();
	self.pers["killstreaks"][0].streakName = streakName;
	self.pers["killstreaks"][0].earned = isDefined( isEarned ) && isEarned;
	self.pers["killstreaks"][0].awardxp = isDefined( awardXp ) && awardXp;
	self.pers["killstreaks"][0].owner = owner;
	if ( !self.pers["killstreaks"][0].earned )
		self.pers["killstreaks"][0].lifeId = -1;
	else
		self.pers["killstreaks"][0].lifeId = self.pers["deaths"];
	
	// probably obsolete unless we bring back the autoshotty	
	if ( isdefined( level.killstreakSetupFuncs[ streakName ] ) )
		self [[ level.killstreakSetupFuncs[ streakName ] ]]();
		
	if ( isDefined( isEarned ) && isEarned && isDefined( awardXp ) && awardXp )
		self notify( "received_earned_killstreak" );
}


giveKillstreakWeapon( weapon )
{
	weaponList = self getWeaponsListItems();
	
	foreach ( item in weaponList )
	{
		if ( !isSubStr( item, "killstreak" ) )
			continue;
	
		if ( self getCurrentWeapon() == item )
			continue;
			
		self takeWeapon( item );
	}
	
	self _giveWeapon( weapon, 0 );
	self _setActionSlot( 4, "weapon", weapon );
}


getStreakCost( streakName )
{
	return int( tableLookup( KILLSTREAK_STRING_TABLE, 1, streakName, 4 ) );
}


getKillstreakHint( streakName )
{
	return tableLookupIString( KILLSTREAK_STRING_TABLE, 1, streakName, 6 );
}


getKillstreakInformEnemy( streakName )
{
	return int( tableLookup( KILLSTREAK_STRING_TABLE, 1, streakName, 11 ) );
}


getKillstreakSound( streakName )
{
	return tableLookup( KILLSTREAK_STRING_TABLE, 1, streakName, 7 );
}


getKillstreakDialog( streakName )
{
	return tableLookup( KILLSTREAK_STRING_TABLE, 1, streakName, 8 );
}


getKillstreakWeapon( streakName )
{
	return tableLookup( KILLSTREAK_STRING_TABLE, 1, streakName, 12 );
}

getKillstreakIcon( streakName )
{
	return tableLookup( KILLSTREAK_STRING_TABLE, 1, streakName, 14 );
}

getKillstreakCrateIcon( streakName )
{
	return tableLookup( KILLSTREAK_STRING_TABLE, 1, streakName, 15 );
}


giveOwnedKillstreakItem( skipDialog )
{
	if ( !isDefined( self.pers["killstreaks"][0] ) )
		return;
		
	streakName = self.pers["killstreaks"][0].streakName;

	weapon = getKillstreakWeapon( streakName );
	self giveKillstreakWeapon( weapon );

	if ( !isDefined( skipDialog ) && !level.inGracePeriod )
		self leaderDialogOnPlayer( streakName, "killstreak_earned" );
}


initRideKillstreak()
{
	self _disableUsability();
	result = self initRideKillstreak_internal();

	if ( isDefined( self ) )
		self _enableUsability();
		
	return result;
}

initRideKillstreak_internal()
{
	laptopWait = self waittill_any_timeout( 1.0, "disconnect", "death", "weapon_switch_started" );
	
	if ( laptopWait == "weapon_switch_started" )
		return ( "fail" );

	if ( !isAlive( self ) )
		return "fail";

	if ( laptopWait == "disconnect" || laptopWait == "death" )
	{
		if ( laptopWait == "disconnect" )
			return ( "disconnect" );

		if ( self.team == "spectator" )
			return "fail";

		return ( "success" );		
	}
	
	if ( self isEMPed() || self isNuked() )
	{
		return ( "fail" );
	}
	
	self VisionSetNakedForPlayer( "black_bw", 0.75 );
	blackOutWait = self waittill_any_timeout( 0.80, "disconnect", "death" );

	if ( blackOutWait != "disconnect" ) 
	{
		self thread clearRideIntro( 1.0 );
		
		if ( self.team == "spectator" )
			return "fail";
	}

	if ( !isAlive( self ) )
		return "fail";

	if ( self isEMPed() || self isNuked() )
		return "fail";
	
	if ( blackOutWait == "disconnect" )
		return ( "disconnect" );
	else
		return ( "success" );		
}


clearRideIntro( delay )
{
	self endon( "disconnect" );

	if ( isDefined( delay ) )
		wait( delay );

	//self freezeControlsWrapper( false );
	
	if ( !isDefined( level.nukeVisionInProgress ) )
		self VisionSetNakedForPlayer( getDvar( "mapname" ), 0 );
}


