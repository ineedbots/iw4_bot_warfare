/*
	_killstreaks modded
	Author: INeedGames
	Date: 09/22/2020
	Adds killstreak rollover and killstreak HUD

	DVARS:
		- scr_killstreak_rollover <int>
			0 - (default) killstreaks do not rollover, only get one set of killstreaks
			1 - killstreaks rollover, earn killstreaks over again without dying
			2 - killstreaks rollover only with hardline pro

		- scr_maxKillstreakRollover <int>
			10 - (default) allow to rollover killstreaks <int> times.

		- scr_currentRolloverKillstreaksOnlyIncrease <bool>
			0 - (default) if only killstreaks from their current rollover will increase streak

		- scr_killstreak_mod <int>
			0 - (default) offsets all killstreaks reward costs by <int> amount

		- scr_killstreakHud <int>
			0 - (default) no HUD
			1 - use Puffiamo's killstreak HUD
			2 - use NoFate's MW3 killstreak HUD

		- scr_killstreak_print <int>
			0 - (default) none
			1 - enables the CoD4 (10 Kill Streak!) messages
			2 - adds exp rewards for each 5 kills

		- scr_specialist <bool>
			false - (default) enable specialist from mw3, a player must only have the nuke selected as their killstreak

		- scr_specialist_perks1 <string>
			- perks that appear in the first slot (2 killstreak) of specialist

		- scr_specialist_perks2 <string>
			- perks that appear in the second slot (4 killstreak) of specialist

		- scr_specialist_perks3 <string>
			- perks that appear in the third slot (6 killstreak) of specialist


	Thanks: H3X1C, Emosewaj, NoFate, Puffiamo, Intricate
*/

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

	setDvarIfUninitialized( "scr_killstreak_rollover", false );
	setDvarIfUninitialized( "scr_currentRolloverKillstreaksOnlyIncrease", false );
	setDvarIfUninitialized( "scr_maxKillstreakRollover", 10 );
	setDvarIfUninitialized( "scr_killstreakHud", false );
	setDvarIfUninitialized( "scr_killstreak_mod", 0 );
	setDvarIfUninitialized( "scr_killstreak_print", false );

	setDvarIfUninitialized( "scr_specialist", false );
	setDvarIfUninitialized( "scr_specialist_perks1", "specialty_scavenger,specialty_fastreload,specialty_marathon" );
	setDvarIfUninitialized( "scr_specialist_perks2", "specialty_bulletdamage,specialty_lightweight,specialty_coldblooded,specialty_explosivedamage,specialty_hardline" );
	setDvarIfUninitialized( "scr_specialist_perks3", "specialty_bulletaccuracy,specialty_heartbreaker,specialty_detectexplosive,specialty_extendedmelee,specialty_localjammer" );

	level.killstreaksRollOver = getDvarInt("scr_killstreak_rollover");
	level.maxKillstreakRollover = getDvarInt("scr_maxKillstreakRollover");
	level.rolloverKillstreaksOnlyIncrease = getDvarInt("scr_currentRolloverKillstreaksOnlyIncrease");
	level.killstreakHud = getDvarInt("scr_killstreakHud");
	level.killStreakMod = getDvarInt( "scr_killstreak_mod" );
	level.killstreakPrint = getDvarInt( "scr_killstreak_print" );

	level.allowSpecialist = getDvarInt( "scr_specialist" );
	level.specialistPerk1 = getDvar("scr_specialist_perks1");
	level.specialistPerk2 = getDvar("scr_specialist_perks2");
	level.specialistPerk3 = getDvar("scr_specialist_perks3");
	level.specialistData = [];

	if (level.allowSpecialist)
	{
		initSpecialist();
	}
	
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

		if( !isDefined ( player.pers[ "kID" ] ) )
			player.pers[ "kID" ] = 10;

		if( !isDefined ( player.pers[ "kIDs_valid" ] ) )
			player.pers[ "kIDs_valid" ] = [];
		
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

		self startSpecialist();
		self startKSHud();

		if (level.killstreakPrint)
			self thread watchNotifyKSMessage();
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
		self clearKillstreaks();

		if ( self isUsingRemote() )
			self clearUsingRemote();
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
	kID = self.pers["killstreaks"][0].kID;

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

	if ( streakName == "airdrop" || streakName == "airdrop_sentry_minigun" || streakName == "airdrop_mega" )
	{
		if ( !self [[ level.killstreakFuncs[ streakName ] ]]( lifeId, kID ) )
			return ( false );
	}
	else
	{
		  if ( !self [[ level.killstreakFuncs[ streakName ] ]]( lifeId ) )
			  return ( false );
	}
	
	self usedKillstreak( streakName, awardXp );
	self shuffleKillStreaksFILO( streakName, kID );	
	self giveOwnedKillstreakItem();		

	return ( true );
}


//this overwrites killstreak at index 0 and decrements all other killstreaks (FCLS style)
shuffleKillStreaksFILO( streakName, kID )
{
	self _setActionSlot( 4, "" );

	arraySize = self.pers["killstreaks"].size;

	streakIndex = -1;
	for ( i = 0; i < arraySize; i++ )
	{
		if ( self.pers["killstreaks"][i].streakName != streakName )
			continue;
		
		if ( isDefined( kID ) && self.pers["killstreaks"][i].kID != kID )
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

getFirstPrimaryWeapon()
{
	weaponsList = self getWeaponsListPrimaries();
	
	assert ( isDefined( weaponsList[0] ) );
	assert ( !isKillstreakWeapon( weaponsList[0] ) );

	if ( weaponsList[0] == "onemanarmy_mp" )
	{
		assert ( isDefined( weaponsList[1] ) );
		assert ( !isKillstreakWeapon( weaponsList[1] ) );
		
		return weaponsList[1];
	}

	return weaponsList[0];
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
		{
			if ( !self hasWeapon( self getLastWeapon() ) )
				self switchToWeapon( self getFirstPrimaryWeapon() );			
			else
				self switchToWeapon( self getLastWeapon() );
		}

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
	level endon ( "game_ended" );
	
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
		curRollover = 0;
		
		if ( actualVal > streakCount )
			break;
		
		if ( isDefined( self.pers["lastEarnedStreak"] ) && killStreaks[streakName] <= killStreaks[self.pers["lastEarnedStreak"]] )
			continue;

		if ( isSubStr( streakName, "-rollover" ) )
		{
			if (!level.killstreaksRollover || (level.killstreaksRollover == 2 && !self _hasPerk("specialty_rollover")))
				continue;
			else
			{
				curRollover = int(strtok(strtok(streakName, "-")[1], "rollover")[0]);
				if (curRollover > level.maxKillstreakRollover)
					continue;

				if ( isDefined( game["defcon"] ) && game["defcon"] > 2 )
				{
					self.pers["lastEarnedStreak"] = streakName;
					continue;
				}
				
				useStreakName = strTok( streakName, "-" )[0];
			}
		}
		else
		{
			useStreakName = streakName;
		}
		
		if ( self tryGiveKillstreak( useStreakName, int(max( actualVal, streakCount )), curRollover ) )
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
	data = level.specialistData[streakName];

	if (isDefined(data))
	{
		perk = streakName;
		name = data.name;
		description = data.description;
		shader = data.shader;

		proPerk = tablelookup( "mp/perktable.csv", 1, perk, 8 );
		hasProPerk = self isItemUnlocked(proPerk);

		if (hasProPerk)
			shader = data.shader_pro;

		notifyData = spawnStruct();

		notifyData.glowColor = getGoodColor();
		notifyData.hideWhenInMenu = false;
		notifyData.titleText = name;
		notifyData.notifyText = description;
		notifyData.iconName = shader;
		notifyData.sound = "mp_bonus_start";

		if (perk == "specialty_onemanarmy")
		{
			notifyData.titleText = "Specialist Bonus";
			notifyData.notifyText = "Received all Perks!";
		}

		self maps\mp\gametypes\_hud_message::notifyMessage( notifyData );
		return;
	}

	self maps\mp\gametypes\_hud_message::killstreakSplashNotify( streakName, streakVal );
}


tryGiveKillstreak( streakName, streakVal, curRollover )
{
	level notify ( "gave_killstreak", streakName );

	if ( !level.gameEnded )
		self thread rewardNotify( streakName, streakVal );

	self giveKillstreak( streakName, streakVal, true, self, curRollover );
	return true;
}


giveKillstreak( streakName, isEarned, awardXp, owner, curRollover )
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

	self.pers["killstreaks"][0].kID = self.pers["kID"];
	self.pers["kIDs_valid"][self.pers["kID"]] = true;

	self.pers["kID"]++;

	toLifeId = self.pers["deaths"];
	if (level.rolloverKillstreaksOnlyIncrease && isDefined(curRollover) && curRollover > 0)
	{
		if (curRollover == 1)
			toLifeId += 0.75;
		else
			toLifeId += 1/curRollover;
	}

	if ( !self.pers["killstreaks"][0].earned )
		self.pers["killstreaks"][0].lifeId = -1;
	else
		self.pers["killstreaks"][0].lifeId = toLifeId;
	
	// probably obsolete unless we bring back the autoshotty	
	if ( isdefined( level.killstreakSetupFuncs[ streakName ] ) )
		self [[ level.killstreakSetupFuncs[ streakName ] ]]( streakName );
		
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
	
	if ( isDefined( weapon ) && weapon != "" )
	{
		self _giveWeapon( weapon, 0 );
		self _setActionSlot( 4, "weapon", weapon );
	}
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
	data = level.specialistData[streakName];
	if (isDefined(data))
	{
		perk = streakName;
		shader = data.shader;
		proPerk = tablelookup( "mp/perktable.csv", 1, perk, 8 );
		hasProPerk = self isItemUnlocked(proPerk);

		if (hasProPerk)
			shader = data.shader_pro;

		return shader;
	}

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

	self VisionSetNakedForPlayer( getMapVision(), 0 );
}

destroyOnEvents(elem)
{
	self waittill_either("disconnect", "start_killstreak_hud");

	if ( isDefined( elem ) )
		elem destroy();
}

initKillstreakHud(inity)
{
	self endon( "disconnect" );
	self notify( "start_killstreak_hud" );
	self endon( "start_killstreak_hud" );

	streakVals = GetArrayKeys(self.killStreaks);

	self.killStreakHudElems = [];

	// the killstreak counter
	index = self.killStreakHudElems.size;
	self.killStreakHudElems[index] = self createFontString( "objective", 2 );
	self.killStreakHudElems[index].foreground = false;
	self.killStreakHudElems[index].hideWhenInMenu = true;
	self.killStreakHudElems[index].fontScale = 0.60;
	self.killStreakHudElems[index].font = "hudbig";
	self.killStreakHudElems[index].alpha = 1;
	self.killStreakHudElems[index].glow = 1;
	self.killStreakHudElems[index].glowColor = ( 0, 0, 1 );
	self.killStreakHudElems[index].glowAlpha = 1;
	self.killStreakHudElems[index].color = ( 1.0, 1.0, 1.0 );
	self thread destroyOnEvents(self.killStreakHudElems[index]);
	highestStreak = -1;

	for (i = 0; i < streakVals.size; i++)
	{
		streakVal = streakVals[i];
		streakName = self.killStreaks[streakVal];

		if (isSubStr(streakName, "-rollover"))
			continue;

		streakShader = getKillstreakIcon( streakName );
		streakCost = streakVal;

		// each killstreak icon
		index = self.killStreakHudElems.size;
		self.killStreakHudElems[index] = self createFontString( "objective", 2 );
		self.killStreakHudElems[index].foreground = false;
		self.killStreakHudElems[index].hideWhenInMenu = true;
		self.killStreakHudElems[index].fontScale = 0.60;
		self.killStreakHudElems[index].font = "hudbig";
		self.killStreakHudElems[index].glow = 1;
		self.killStreakHudElems[index].glowColor = ( 0, 0, 1 );
		self.killStreakHudElems[index].glowAlpha = 1;
		self.killStreakHudElems[index].color = ( 1.0, 1.0, 1.0 );
		self.killStreakHudElems[index] setPoint( "RIGHT", "RIGHT", 0, inity - 25 * i );
		self.killStreakHudElems[index] setShader( streakShader, 20, 20 );
		self.killStreakHudElems[index].ks_cost = streakCost;
		self.killStreakHudElems[index].ks_name = streakName;
		self thread destroyOnEvents(self.killStreakHudElems[index]);

		if (streakCost > highestStreak)
			highestStreak = streakCost;
	}

	for(first=true;;)
  {
		if (first)
			first = false;
		else
			self waittill( "killed_enemy" );

		curStreak = self.pers["cur_kill_streak"];
		timesRolledOver = int(curStreak / highestStreak);
		if (level.killstreaksRollover == 1 || (level.killstreaksRollover == 2 && self _hasPerk("specialty_rollover")))
			curStreak %= highestStreak;

		if (timesRolledOver > level.maxKillstreakRollover)
			curStreak = highestStreak;

		isUnderAStreak = false;

		for (i = self.killStreakHudElems.size - 1; i >= 1; i--)
		{
			streakElem = self.killStreakHudElems[i];
			if (curStreak >= streakElem.ks_cost || (timesRolledOver > 0 && isSubStr(streakElem.ks_name, "specialty_")))
				streakElem.alpha = 1;
			else
			{	
				isUnderAStreak = true;
				self.killStreakHudElems[0] setPoint( "RIGHT", "RIGHT", -25, inity - 25 * (i - 1) );
				self.killStreakHudElems[0] setText( streakElem.ks_cost - curStreak );
				streakElem.alpha = 0.5;
			}
		}

		if (!isUnderAStreak && self.killStreakHudElems.size)
		{
			self.killStreakHudElems[0] setPoint( "RIGHT", "RIGHT", -25, inity - 25 * (self.killStreakHudElems.size - 1 - 1) );
			self.killStreakHudElems[0] setText( "Done" );
		}
	}
}

initMW3KillstreakHud()
{
	self endon( "disconnect" );
	self notify( "start_killstreak_hud" );
	self endon( "start_killstreak_hud" );

	streakVals = GetArrayKeys(self.killStreaks);

	self.killStreakHudElems = [];
	self.killStreakShellsElems = [];
	highestStreak = -1;

	for (i = 0; i < streakVals.size; i++)
	{
		streakVal = streakVals[i];
		streakName = self.killStreaks[streakVal];

		if (isSubStr(streakName, "-rollover"))
			continue;

		streakShader = getKillstreakIcon( streakName );
		streakCost = streakVal;

		if (streakCost > highestStreak)
			highestStreak = streakCost;

		// the shader
		ksIcon = createIcon( streakShader, 20, 20 );
		ksIcon setPoint( "BOTTOM RIGHT", "BOTTOM RIGHT", -32, -90 + -25 * i );
		ksIcon.alpha = 0.4;
		ksIcon.hideWhenInMenu = true;
		ksIcon.foreground = true;
		ksIcon.ks_cost = streakCost;
		ksIcon.ks_name = streakName;
		self thread destroyOnEvents(ksIcon);
		self.killStreakHudElems[self.killStreakHudElems.size] = ksIcon;
	}

	// the shells
	if (highestStreak > 0)
	{
		h = -53;
		for(i = 0; i < highestStreak; i++)
		{
			ksShell = NewClientHudElem( self );
			ksShell.x = 40;
			ksShell.y = h;
			ksShell.alignX = "right";
			ksShell.alignY = "bottom";
			ksShell.horzAlign = "right";
			ksShell.vertAlign = "bottom";
			ksShell setshader("white", 10, 2);
			ksShell.alpha = 0.3;
			ksShell.hideWhenInMenu = true;
			ksShell.foreground = false;
			self thread destroyOnEvents(ksShell);
			self.killStreakShellsElems[i] = ksShell;
			
			h -= 4;
		}
	}

	for(first=true;;)
  {
		if (first)
			first = false;
		else
			self waittill( "killed_enemy" );

		curStreak = self.pers["cur_kill_streak"];
		timesRolledOver = int(curStreak / highestStreak);
		if (level.killstreaksRollover == 1 || (level.killstreaksRollover == 2 && self _hasPerk("specialty_rollover")))
			curStreak %= highestStreak;

		if (timesRolledOver > level.maxKillstreakRollover)
			curStreak = highestStreak;

		nextHighest = 999;
		// update the ks icons
		for (i = 0; i < self.killStreakHudElems.size; i++)
		{
			elem = self.killStreakHudElems[i];

			if (curStreak >= elem.ks_cost || (timesRolledOver > 0 && isSubStr(elem.ks_name, "specialty_")))
				elem.alpha = 0.9;
			else
			{
				elem.alpha = 0.4;

				if (nextHighest > elem.ks_cost)
					nextHighest = elem.ks_cost;
			}
		}

		// update the shells
		for (i = 0; i < self.killStreakShellsElems.size; i++)
		{
			elem = self.killStreakShellsElems[i];

			if (curStreak > i)
				elem.alpha = 0.85;
			else if (i >= nextHighest)
				elem.alpha = 0;
			else
				elem.alpha = 0.3;
		}
	}
}

getGoodColor()
{
	color = [];
	//Intricate - This is momo5502's code, rather interesting way too :D.
	for( i = 0; i < 3; i++ )
	{
		color[i] = randomint( 2 );
	}

	if( color[0] == color[1] && color[1] == color[2] )
	{
		rand = randomint(3);
		color[rand] += 1;
		color[rand] %= 2;
	}

	return ( color[0], color[1], color[2] );
}

getPerkMaterial( perk )
{
	return tableLookUp( "mp/perkTable.csv", 1, perk, 3 );
}

initSpecialist()
{
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_scavenger", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_fastreload", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_marathon", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_bulletdamage", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_lightweight", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_coldblooded", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_explosivedamage", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_hardline", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_bulletaccuracy", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_heartbreaker", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_detectexplosive", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_extendedmelee", 8 )));
	PrecacheShader(getPerkMaterial(tablelookup( "mp/perktable.csv", 1, "specialty_localjammer", 8 )));
	PrecacheShader(getPerkMaterial("specialty_scavenger"));
	PrecacheShader(getPerkMaterial("specialty_fastreload"));
	PrecacheShader(getPerkMaterial("specialty_marathon"));
	PrecacheShader(getPerkMaterial("specialty_bulletdamage"));
	PrecacheShader(getPerkMaterial("specialty_lightweight"));
	PrecacheShader(getPerkMaterial("specialty_coldblooded"));
	PrecacheShader(getPerkMaterial("specialty_explosivedamage"));
	PrecacheShader(getPerkMaterial("specialty_hardline"));
	PrecacheShader(getPerkMaterial("specialty_bulletaccuracy"));
	PrecacheShader(getPerkMaterial("specialty_heartbreaker"));
	PrecacheShader(getPerkMaterial("specialty_detectexplosive"));
	PrecacheShader(getPerkMaterial("specialty_extendedmelee"));
	PrecacheShader(getPerkMaterial("specialty_localjammer"));
	PrecacheShader("specialty_onemanarmy");
	PrecacheShader("specialty_onemanarmy_upgrade");
	PrecacheShader("specialty_none");
	
	//Strings
	PrecacheString( &"PERKS_MARATHON" );	
	PrecacheString( &"PERKS_SLEIGHT_OF_HAND" );	
	PrecacheString( &"PERKS_SCAVENGER" );	
	//--
	PrecacheString( &"PERKS_STOPPING_POWER" );	
	PrecacheString( &"PERKS_LIGHTWEIGHT" );	
	PrecacheString( &"PERKS_COLDBLOODED" );	
	PrecacheString( &"PERKS_DANGERCLOSE" );
	PrecacheString( &"PERKS_HARDLINE" );	
	//--
	PrecacheString( &"PERKS_EXTENDEDMELEE" );	
	PrecacheString( &"PERKS_STEADY_AIM" );	
	PrecacheString( &"PERKS_LOCALJAMMER" );	
	PrecacheString( &"PERKS_BOMB_SQUAD" );	
	PrecacheString( &"PERKS_NINJA" );
	//Description
	PrecacheString( &"PERKS_DESC_MARATHON" );
	PrecacheString( &"PERKS_FASTER_RELOADING" );
	PrecacheString( &"PERKS_DESC_SCAVENGER" );
	//--
	PrecacheString( &"PERKS_INCREASED_BULLET_DAMAGE" );
	PrecacheString( &"PERKS_DESC_LIGHTWEIGHT" );
	PrecacheString( &"PERKS_DESC_COLDBLOODED" );
	PrecacheString( &"PERKS_HIGHER_EXPLOSIVE_WEAPON" );
	PrecacheString( &"PERKS_DESC_HARDLINE" );
	//--
	PrecacheString( &"PERKS_DESC_EXTENDEDMELEE" );
	PrecacheString( &"PERKS_INCREASED_HIPFIRE_ACCURACY" );
	PrecacheString( &"PERKS_DESC_LOCALJAMMER" );
	PrecacheString( &"PERKS_ABILITY_TO_SEEK_OUT_ENEMY" );
	PrecacheString( &"PERKS_DESC_HEARTBREAKER" );

	perks = [];
	perks[perks.size] = strtok(level.specialistPerk1, ",");
	perks[perks.size] = strtok(level.specialistPerk2, ",");
	perks[perks.size] = strtok(level.specialistPerk3, ",");
	perks[perks.size] = strtok("specialty_none,specialty_onemanarmy", ",");

	for (i = 0; i < perks.size; i++)
	{
		for (h = 0; h < perks[i].size; h++)
		{
			perk = perks[i][h];

			data = spawnStruct();
			data.shader = getPerkMaterial(perk);
			data.shader_pro = getPerkMaterial(tablelookup( "mp/perktable.csv", 1, perk, 8 ));
			data.name = tableLookUpIString( "mp/perkTable.csv", 1, perk, 2 );
			data.description = tableLookUpIString( "mp/perkTable.csv", 1, perk, 4 );

			level.specialistData[perk] = data;
			level.killstreakSetupFuncs[perk] = ::onGetPerkStreak;
		}
	}
}

onGetPerkStreak(perk, wasForced)
{
	proPerk = tablelookup( "mp/perktable.csv", 1, perk, 8 );
	hasProPerk = self isItemUnlocked(proPerk);

	if (!isDefined(wasForced))
	{
		self shuffleKillStreaksFILO( perk );	
		self giveOwnedKillstreakItem(true);
	}

	if (perk == "specialty_none")
	{
	}
	else if (perk == "specialty_onemanarmy")
	{
		perks = [];
		perks[perks.size] = strtok(level.specialistPerk1, ",");
		perks[perks.size] = strtok(level.specialistPerk2, ",");
		perks[perks.size] = strtok(level.specialistPerk3, ",");

		for (i = 0; i < perks.size; i++)
		{
			for (h = 0; h < perks[i].size; h++)
			{
				perk = perks[i][h];
				proPerk = tablelookup( "mp/perktable.csv", 1, perk, 8 );

				self _setPerk(perk);
				if ( self isItemUnlocked( proPerk ) )
					self _setPerk(proPerk);
			}
		}
	}
	else
	{
		self _setPerk(perk);
		if ( hasProPerk )
			self _setPerk(proPerk);
	}

	self applySpecialistKillstreaks(); // maybe hardline changes the values
}

chooseAPerk(perks)
{
	perks = strtok(perks, ",");

	while (perks.size)
	{
		perk = random(perks);
		perks = array_remove(perks, perk);

		if (self _hasPerk(perk))
			continue;

		return perk;
	}

	return "specialty_none";
}

startSpecialist()
{
	if (!level.allowSpecialist)
		return;

	// only start if we have only the nuke killstreak
	shouldDoSpecialist = undefined;
	streakVals = GetArrayKeys(self.killStreaks);

	for (i = 0; i < streakVals.size; i++)
	{
		streakVal = streakVals[i];
		streakName = self.killStreaks[streakVal];

		if (isSubStr(streakName, "-rollover"))
			continue;

		if (isDefined(shouldDoSpecialist) && !shouldDoSpecialist)
			break;

		if (streakName == "nuke")
			shouldDoSpecialist = true;
		else
			shouldDoSpecialist = false;
	}

	if (!isDefined(shouldDoSpecialist) || !shouldDoSpecialist)
		return;

	if (!isDefined(self.pers["specialist_perks"]))
		self.pers["specialist_perks"] = [];

	if (!isDefined(self.pers["specialist_perks"][self.class_num]))
	{
		self.pers["specialist_perks"][self.class_num] = [];
		self.pers["specialist_perks"][self.class_num][0] = chooseAPerk(level.specialistPerk1);
		self.pers["specialist_perks"][self.class_num][1] = chooseAPerk(level.specialistPerk2);
		self.pers["specialist_perks"][self.class_num][2] = chooseAPerk(level.specialistPerk3);
	}

	self.startKillStreaks = self.killStreaks;
	self.startedWithHardline = (self _hasPerk( "specialty_hardline" ));
	self applySpecialistKillstreaks();

	// check cur_streak for perks
	curStreak = self.pers["cur_kill_streak"];
	streakVals = GetArrayKeys(self.killStreaks);
	for (i = 0; i < streakVals.size; i++)
	{
		streakVal = streakVals[i];
		streakName = self.killStreaks[streakVal];

		if (!isSubStr(streakName, "specialty_"))
			continue;

		if (curStreak < streakVal)
			continue;

		self onGetPerkStreak(streakName, true);
	}
}

getSpecialistKillstreakCount(slot, count)
{
	dvarAmount = getDVarInt("scr_specialist_killCount_" + slot);
	if (dvarAmount < 2)
		return count;

	return dvarAmount;
}

applySpecialistKillstreaks()
{
	if ( self _hasPerk( "specialty_hardline" ) )
		modifier = -1;
	else
		modifier = 0;

	killstreaks = [];
	killstreaks[getSpecialistKillstreakCount(0, 2) + modifier] = self.pers["specialist_perks"][self.class_num][0];
	killstreaks[getSpecialistKillstreakCount(1, 4) + modifier] = self.pers["specialist_perks"][self.class_num][1];
	killstreaks[getSpecialistKillstreakCount(2, 6) + modifier] = self.pers["specialist_perks"][self.class_num][2];
	killstreaks[getSpecialistKillstreakCount(3, 8) + modifier] = "specialty_onemanarmy";

	maxVal = -1;
	oldStreaks = [];
	streakVals = GetArrayKeys(self.startKillStreaks);
	for (i = 0; i < streakVals.size; i++)
	{
		streakVal = streakVals[i];
		streakName = self.startKillStreaks[streakVal];

		if (isSubStr(streakName, "-rollover"))
			continue;

		if (!self.startedWithHardline)
			streakVal += modifier;

		if (streakVal > maxVal)
			maxVal = streakVal;

		oldStreaks[streakVal] = streakName;
	}

	if (maxVal < (8 + modifier))
		maxVal = 8 + modifier;

	// build new killstreaks with merged specialists
	newKillstreaks = [];
	for (i = 0; i <= maxVal; i++)
	{
		if (isDefined(killstreaks[i]))
		{
			newKillstreaks[i] = killstreaks[i];
			continue;
		}

		if (isDefined(oldStreaks[i]))
		{
			newKillstreaks[i] = oldStreaks[i];
			continue;
		}
	}

	// defcon rollover
	maxRollOvers = 10;
	for ( rollOver = 1; rollOver <= maxRollOvers; rollOver++ )
	{
		streakVals = GetArrayKeys(oldStreaks);

		for (i = 0; i < streakVals.size; i++)
		{
			streakVal = streakVals[i];
			streakName = oldStreaks[streakVal];

			newKillstreaks[ streakVal + (maxVal*rollOver) ] = streakName + "-rollover" + rollOver;
		}
	}

	self.killStreaks = newKillstreaks;

	// update the hud incase hardline changed the values
	self startKSHud();

	// give xp every second kill like in mw3
	self thread watchSpecialistOnKill();
}

watchSpecialistOnKill()
{
	self endon("disconnect");
	
	waittillframeend;
	
	self notify("watchSpecialistOnKill");
	self endon("watchSpecialistOnKill");

	for (lastKs = self.pers["cur_kill_streak"];;)
	{
		self waittill( "killed_enemy" );

		for (curStreak = lastKs + 1; curStreak <= self.pers["cur_kill_streak"]; curStreak++)
		{
			if (curStreak % 2 == 1)
				continue;

			self thread maps\mp\gametypes\_rank::giveRankXP( "specialist_bonus", 50 );
			self thread underScorePopup("Specialist Bonus!", (1, 1, 0.5), 0);
		}

		lastKs = self.pers["cur_kill_streak"];
	}
}

watchNotifyKSMessage()
{
	self endon("disconnect");
	self endon("changed_kit");

	for (lastKs = self.pers["cur_kill_streak"];;)
	{
		self waittill( "killed_enemy" );

		for (curStreak = lastKs + 1; curStreak <= self.pers["cur_kill_streak"]; curStreak++)
		{
			//if (curStreak == 5)
			//	continue;

			if (curStreak % 5 != 0)
				continue;

			self thread streakNotify(curStreak);
		}

		lastKs = self.pers["cur_kill_streak"];
	}
}

streakNotify( streakVal )
{
	self endon( "disconnect" );

	notifyData = spawnStruct();

	if (level.killstreakPrint > 1)
	{
		xpReward = streakVal * 100;

		self thread maps\mp\gametypes\_rank::giveRankXP( "killstreak_bonus", xpReward );

		notifyData.notifyText = "+" + xpReward;
	}

	wait .05;

	notifyData.titleLabel = &"MP_KILLSTREAK_N";
	notifyData.titleText = streakVal;
	
	self maps\mp\gametypes\_hud_message::notifyMessage( notifyData );
	
	iprintln( &"RANK_KILL_STREAK_N", self, streakVal );
}

underScorePopup(string, hudColor, glowAlpha)
{
	// Display text under the score popup
	self endon( "disconnect" );

	if ( string == "" )
		return;

	if (level.hardcoreMode)
		return;

	self notify( "underScorePopup" );
	self endon( "underScorePopup" );

	if (!isDefined(self.mw3_scorePopup))
	{
		// Create the under score popup element
		self.mw3_scorePopup = newClientHudElem( self );
		self.mw3_scorePopup.horzAlign = "center";
		self.mw3_scorePopup.vertAlign = "middle";
		self.mw3_scorePopup.alignX = "center";
		self.mw3_scorePopup.alignY = "middle";
		self.mw3_scorePopup.x = 35;
		self.mw3_scorePopup.y = -48;
		self.mw3_scorePopup.font = "hudbig";
		self.mw3_scorePopup.fontscale = 0.65;
		self.mw3_scorePopup.archived = false;
		self.mw3_scorePopup.color = (0.5, 0.5, 0.5);
		self.mw3_scorePopup.sort = 10000;
	}

	self.mw3_scorePopup.color = hudColor;
	self.mw3_scorePopup.glowColor = hudColor;
	self.mw3_scorePopup.glowAlpha = glowAlpha;

	self.mw3_scorePopup setText(string);
	self.mw3_scorePopup.alpha = 0.85;

	wait 1.0;

	self.mw3_scorePopup fadeOverTime( 0.75 );
	self.mw3_scorePopup.alpha = 0;

	wait 0.75;

	self.mw3_scorePopup destroy();
	self.mw3_scorePopup = undefined;
}

startKSHud()
{
	if (level.hardcoreMode)
		return;

	if (level.killstreakHud == 1)
		self thread initKillstreakHud( 145 );
	else if (level.killstreakHud == 2)
		self thread initMW3KillstreakHud();
}
