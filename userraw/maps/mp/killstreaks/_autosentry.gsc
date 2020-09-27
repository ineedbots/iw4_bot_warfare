#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

SENTRY_MODE_ON			= "sentry";
SENTRY_MODE_OFF			= "sentry_offline";
SENTRY_TIME_OUT			= 90.0;
SENTRY_SPINUP_TIME		= .05;
SENTRY_OVERHEAT_TIME	= 8.0;
SENTRY_FX_TIME			= .3;

init()
{
	level.sentryType = [];
	level.sentryType[ "sentry_minigun" ] 	= "sentry";
	
	level.killStreakFuncs[ level.sentryType[ "sentry_minigun" ] ] 	= ::tryUseAutoSentry;
	
	level.sentrySettings = [];
	
	level.sentrySettings[ "sentry_minigun" ] = spawnStruct();
	level.sentrySettings[ "sentry_minigun" ].burstMin = 20;
	level.sentrySettings[ "sentry_minigun" ].burstMax = 120;
	level.sentrySettings[ "sentry_minigun" ].pauseMin = 0.15;
	level.sentrySettings[ "sentry_minigun" ].pauseMax = 0.35;
	level.sentrySettings[ "sentry_minigun" ].weaponInfo = "sentry_minigun_mp";
	level.sentrySettings[ "sentry_minigun" ].modelBase = "sentry_minigun";
	level.sentrySettings[ "sentry_minigun" ].modelPlacement = "sentry_minigun_obj";
	level.sentrySettings[ "sentry_minigun" ].modelPlacementFailed = "sentry_minigun_obj_red";
	level.sentrySettings[ "sentry_minigun" ].modelDestroyed = "sentry_minigun_destroyed";

	foreach ( sentryInfo in level.sentrySettings )
	{
		precacheItem( sentryInfo.weaponInfo );
		precacheModel( sentryInfo.modelBase );		
		precacheModel( sentryInfo.modelPlacement );		
		precacheModel( sentryInfo.modelPlacementFailed );		
		precacheModel( sentryInfo.modelDestroyed );		
	}

	level._effect[ "sentry_overheat_mp" ]	= loadfx( "smoke/sentry_turret_overheat_smoke" );
	level._effect[ "sentry_explode_mp" ]	= loadfx( "explosions/sentry_gun_explosion" );
	level._effect[ "sentry_smoke_mp" ]		= loadfx( "smoke/car_damage_blacksmoke" );
}

/* ============================
	Killstreak Functions
   ============================ */

tryUseAutoSentry( lifeId )
{
	result = self giveSentry( "sentry_minigun" );
	if ( result )
		self maps\mp\_matchdata::logKillstreakEvent( "sentry", self.origin );
	
	return ( result );
}


tryUseAutoGlSentry( lifeId )
{
	result = self giveSentry( "sentry_gun" );
	if ( result )
		self maps\mp\_matchdata::logKillstreakEvent( "sentry_gl", self.origin );
		
	return ( result );
}


giveSentry( sentryType )
{
	self.last_sentry = sentryType;

	sentryGun = createSentryForPlayer( sentryType, self );
	
	self setCarryingSentry( sentryGun, true );
	
	// if we failed to place the sentry, it will have been deleted at this point
	if ( isDefined( sentryGun ) )
		return true;
	else
		return false;
}


/* ============================
	Player Functions
   ============================ */


setCarryingSentry( sentryGun, allowCancel )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	
	assert( isReallyAlive( self ) );
	
	sentryGun sentry_setCarried( self );
	
	self _disableWeapon();

	self notifyOnPlayerCommand( "place_sentry", "+attack" );
	self notifyOnPlayerCommand( "cancel_sentry", "+actionslot 4" );
	
	for ( ;; )
	{
		result = waittill_any_return( "place_sentry", "cancel_sentry" );

		if ( result == "cancel_sentry" )
		{
			if ( !allowCancel )
				continue;
				
			sentryGun sentry_setCancelled();
			self _enableWeapon();
			return false;
		}

		if ( !sentryGun.canBePlaced )
			continue;
			
		sentryGun sentry_setPlaced();
		self _enableWeapon();

		return true;
	}
}


/* ============================
	Sentry Functions
   ============================ */

createSentryForPlayer( sentryType, owner )
{
	assertEx( isDefined( owner ), "createSentryForPlayer() called without owner specified" );

	sentryGun = spawnTurret( "misc_turret", owner.origin, level.sentrySettings[ sentryType ].weaponInfo );
	sentryGun.angles = owner.angles;
	
	sentryGun sentry_initSentry( sentryType, owner );
	
	return ( sentryGun );	
}


sentry_initSentry( sentryType, owner )
{
	self.sentryType = sentryType;

	self setModel( level.sentrySettings[ self.sentryType ].modelBase );
	self.health = 1000;
	
	self setCanDamage( true );
	self makeTurretInoperable();
	
	self setTurretModeChangeWait( true );
//	self setConvergenceTime( .25, "pitch" );
//	self setConvergenceTime( .25, "yaw" );
	self sentry_setInactive();
	self setDefaultDropPitch( -89.0 );	// setting this mainly prevents Turret_RestoreDefaultDropPitch() from running
	
	self sentry_setOwner( owner );
	self thread sentry_handleOwner();
	self thread sentry_handleDamage();
	self thread sentry_handleDeath();
	self thread sentry_handleUse();
	self thread sentry_timeOut();
	self thread sentry_attackTargets();
	self thread sentry_beepSounds();
}


/* ============================
	Sentry Handlers
   ============================ */

sentry_handleDamage()
{
	// use a health buffer to prevent the turret from dying to friendly fire
	healthBuffer = 20000;
	self.health += healthbuffer;

	while ( self.health > 0 )
	{
		self waittill( "damage", amount, attacker, dir, point, type );
		
		if ( isDefined( attacker ) && isPlayer( attacker ) && attacker != self.owner && attacker isFriendlyToSentry( self ) && !isDefined( level.nukeDetonated ) )
		{
			self.health += amount;
			continue;
		}

		// 7x damage for explosives - GRENADES
		if ( isExplosiveDamage( type ) )
			self.health -= (amount * 1);
			
		if ( type == "MOD_MELEE" )
			self.health = 0;

		if ( isPlayer( attacker ) )
		{
			attacker maps\mp\gametypes\_damagefeedback::updateDamageFeedback( "sentry" );

			if ( attacker _hasPerk( "specialty_armorpiercing" ) )
			{
				damageAdd = amount*level.armorPiercingMod;
				self.health -= int(damageAdd);
			}			
		}
		
		if ( self.health - healthbuffer < 0 )
		{
			thread maps\mp\gametypes\_missions::vehicleKilled( self.owner, self, undefined, attacker, amount, type );

			if ( isPlayer( attacker ) && (!isDefined(self.owner) || attacker != self.owner) )
			{
				attacker thread maps\mp\gametypes\_rank::giveRankXP( "kill", 100 );				
				attacker notify( "destroyed_killstreak" );
			}
		
			if ( isDefined( self.owner ) )
				self.owner thread leaderDialogOnPlayer( "sentry_destroyed" );
		
			self notify ( "death" );
			return;
		}
	}
}

sentry_handleDeath()
{
	entNum = self GetEntityNumber();
	
	self addToTurretList( entNum );
	
	self waittill ( "death" );

	self removeFromTurretList( entNum );
	// this handles cases of deletion
	if ( !isDefined( self ) )
		return;
		
	self setModel( level.sentrySettings[ self.sentryType ].modelDestroyed );

	self sentry_setInactive();
	self setDefaultDropPitch( 40 );
	self SetSentryOwner( undefined );
	self SetTurretMinimapVisible( false );

	self playSound( "sentry_explode" );
	playFxOnTag( getFx( "sentry_explode_mp" ), self, "tag_aim" );

	// don't try to delete ourselves if we're deleted by other means
	self endon ( "death" );

	wait ( 1.5 );
	
	self playSound( "sentry_explode_smoke" );
	for ( smokeTime = 8; smokeTime > 0; smokeTime -= 0.4 )
	{
		playFxOnTag( getFx( "sentry_smoke_mp" ), self, "tag_aim" );
		wait ( 0.4 );
	}

	self delete();
}


sentry_handleUse()
{
	self endon ( "death" );
	level endon ( "game_ended" );
	
	for ( ;; )
	{
		self waittill ( "trigger", player );
		
		assert( player == self.owner );
		assert( !isDefined( self.carriedBy ) );

		if ( !isReallyAlive( player ) )
			continue;
		
		player setCarryingSentry( self, false );
	}
}


sentry_handleOwner()
{
	self endon ( "death" );
	level endon ( "game_ended" );
	
	self notify ( "sentry_handleOwner" );
	self endon ( "sentry_handleOwner" );
	
	self.owner waittill_any( "disconnect", "joined_team", "joined_spectators" );

	self notify( "death" );
}


/* ============================
	Sentry Utility Functions
   ============================ */

sentry_setOwner( owner )
{
	assertEx( isDefined( owner ), "sentry_setOwner() called without owner specified" );
	assertEx( isPlayer( owner ), "sentry_setOwner() called on non-player entity type: " + owner.classname );

	self.owner = owner;

	self SetSentryOwner( self.owner );
	self SetTurretMinimapVisible( true );
	
	if ( level.teamBased )
	{
		self.team = self.owner.team;
		self setTurretTeam( self.team );
	}
	
	self thread sentry_handleOwner();
}


sentry_setPlaced()
{
	self setModel( level.sentrySettings[ self.sentryType ].modelBase );

	self setSentryCarried( false );
	self setCanDamage( true );
	self sentry_makeSolid();

	self.carriedBy forceUseHintOff();
	self.carriedBy = undefined;

	self sentry_setActive();

	self playSound( "sentry_gun_plant" );

	self notify ( "placed" );
}


sentry_setCancelled()
{
	self.carriedBy forceUseHintOff();

	self delete();
}


sentry_setCarried( carrier )
{
	assert( isPlayer( carrier ) );
	assertEx( carrier == self.owner, "sentry_setCarried() specified carrier does not own this sentry" );

	self setModel( level.sentrySettings[ self.sentryType ].modelPlacement );

	self setSentryCarried( true );
	self setCanDamage( false );
	self sentry_makeNotSolid();

	self.carriedBy = carrier;
	
	carrier thread updateSentryPlacement( self );
	
	self thread sentry_onCarrierDeath( carrier );
	self thread sentry_onCarrierDisconnect( carrier );
	self thread sentry_onGameEnded();

	self sentry_setInactive();
	
	self notify ( "carried" );
}

updateSentryPlacement( sentryGun )
{
	self endon ( "death" );
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	sentryGun endon ( "placed" );
	sentryGun endon ( "death" );
	
	sentryGun.canBePlaced = true;
	lastCanPlaceSentry = -1; // force initial update

	for( ;; )
	{
		placement = self canPlayerPlaceSentry();

		sentryGun.origin = placement[ "origin" ];
		sentryGun.angles = placement[ "angles" ];
		sentryGun.canBePlaced = self isOnGround() && placement[ "result" ];
	
		if ( sentryGun.canBePlaced != lastCanPlaceSentry )
		{
			if ( sentryGun.canBePlaced )
			{
				sentryGun setModel( level.sentrySettings[ sentryGun.sentryType ].modelPlacement );
				self ForceUseHintOn( &"SENTRY_PLACE" );
			}
			else
			{
				sentryGun setModel( level.sentrySettings[ sentryGun.sentryType ].modelPlacementFailed );
				self ForceUseHintOn( &"SENTRY_CANNOT_PLACE" );
			}
		}
		
		lastCanPlaceSentry = sentryGun.canBePlaced;		
		wait ( 0.05 );
	}
}

sentry_onCarrierDeath( carrier )
{
	self endon ( "placed" );
	self endon ( "death" );

	carrier waittill ( "death" );
	
	if ( self.canBePlaced )
		self sentry_setPlaced();
	else
		self delete();
}


sentry_onCarrierDisconnect( carrier )
{
	self endon ( "placed" );
	self endon ( "death" );

	carrier waittill ( "disconnect" );
	
	self delete();
}

sentry_onGameEnded( carrier )
{
	self endon ( "placed" );
	self endon ( "death" );

	level waittill ( "game_ended" );
	
	self delete();
}


sentry_setActive()
{
	self setMode( SENTRY_MODE_ON );

	self setCursorHint( "HINT_NOICON" );
	self setHintString( &"SENTRY_PICKUP" );

	self makeUsable();

	foreach ( player in level.players )
	{
		if ( player == self.owner )
			self enablePlayerUse( player );
		else
			self disablePlayerUse( player );	
	}	

	if ( level.teamBased )
		self maps\mp\_entityheadicons::setTeamHeadIcon( self.team, (0,0,65) );
	else
		self maps\mp\_entityheadicons::setPlayerHeadIcon( self.owner, (0,0,65) );
}


sentry_setInactive()
{
	self setMode( SENTRY_MODE_OFF );
	self makeUnusable();

	if ( level.teamBased )
		self maps\mp\_entityheadicons::setTeamHeadIcon( "none", ( 0, 0, 0 ) );
	else if ( isDefined( self.owner ) )
		self maps\mp\_entityheadicons::setPlayerHeadIcon( undefined, ( 0, 0, 0 ) );
}


sentry_makeSolid()
{
	self makeTurretSolid();
}


sentry_makeNotSolid()
{
	self setContents( 0 );
}


isFriendlyToSentry( sentryGun )
{
	if ( level.teamBased && self.team == sentryGun.team )
		return true;
		
	return false;
}


addToTurretList( entNum )
{
	level.turrets[entNum] = self;	
}


removeFromTurretList( entNum )
{
	level.turrets[entNum] = undefined;
}

/* ============================
	Sentry Logic Functions
   ============================ */

sentry_attackTargets()
{
	self endon( "death" );
	level endon( "game_ended" );

	self.momentum = 0;
	self.heatLevel = 0;
	self.overheated = false;
	
	self thread sentry_heatMonitor();
	
	for ( ;; )
	{
		self waittill_either( "turretstatechange", "cooled" );

		if ( self isFiringTurret() )
		{
			self thread sentry_burstFireStart();
		}
		else
		{
			self sentry_spinDown();
			self thread sentry_burstFireStop();
		}
	}
}


sentry_timeOut()
{
	self endon( "death" );
	level endon ( "game_ended" );
	
	lifeSpan = SENTRY_TIME_OUT;
	
	while ( lifeSpan )
	{
		wait ( 1.0 );
		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
		
		if ( !isDefined( self.carriedBy ) )
			lifeSpan = max( 0, lifeSpan - 1.0 );
	}
	
	if ( isDefined( self.owner ) )
		self.owner thread leaderDialogOnPlayer( "sentry_gone" );
	
	self notify ( "death" );
}

sentry_targetLockSound()
{
	self endon ( "death" );
	
	self playSound( "sentry_gun_beep" );
	wait ( 0.1 );
	self playSound( "sentry_gun_beep" );
	wait ( 0.1 );
	self playSound( "sentry_gun_beep" );
}

sentry_spinUp()
{
	self thread sentry_targetLockSound();
	
	while ( self.momentum < SENTRY_SPINUP_TIME )
	{
		self.momentum += 0.1;
		
		wait ( 0.1 );
	}
}

sentry_spinDown()
{
	self.momentum = 0;
}


sentry_burstFireStart()
{
	self endon( "death" );
	self endon( "stop_shooting" );

	level endon( "game_ended" );

	self sentry_spinUp();

	fireTime = weaponFireTime( level.sentrySettings[ self.sentryType ].weaponInfo );
	minShots = level.sentrySettings[ self.sentryType ].burstMin;
	maxShots = level.sentrySettings[ self.sentryType ].burstMax;
	minPause = level.sentrySettings[ self.sentryType ].pauseMin;
	maxPause = level.sentrySettings[ self.sentryType ].pauseMax;

	for ( ;; )
	{		
		numShots = randomIntRange( minShots, maxShots + 1 );
		
		for ( i = 0; i < numShots && !self.overheated; i++ )
		{
			self shootTurret();
			self.heatLevel += fireTime;
			wait ( fireTime );
		}
		
		wait ( randomFloatRange( minPause, maxPause ) );
	}
}


sentry_burstFireStop()
{
	self notify( "stop_shooting" );
}


sentry_heatMonitor()
{
	self endon ( "death" );

	fireTime = weaponFireTime( level.sentrySettings[ self.sentryType ].weaponInfo );

	lastHeatLevel = 0;
	lastFxTime = 0;

	for ( ;; )
	{
		if ( self.heatLevel != lastHeatLevel )
			wait ( fireTime );
		else
			self.heatLevel = max( 0, self.heatLevel - 0.05 );

		if ( self.heatLevel > SENTRY_OVERHEAT_TIME )
		{
			self.overheated = true;
			self thread PlayHeatFX();
			
			while ( self.heatLevel )
			{
				self.heatLevel = max( 0, self.heatLevel - 0.1 );	
				wait ( 0.1 );
			}

			self.overheated = false;
			self notify( "not_overheated" );
		}

		lastHeatLevel = self.heatLevel;
		wait ( 0.05 );
	}
}

playHeatFX()
{
	self endon( "death" );
	self endon( "not_overheated" );
	level endon ( "game_ended" );
	
	for( ;; )
	{
		playFxOnTag( getFx( "sentry_overheat_mp" ), self, "tag_flash" );
	
		wait( SENTRY_FX_TIME );
	}
}

sentry_beepSounds()
{
	self endon( "death" );
	level endon ( "game_ended" );

	for ( ;; )
	{
		wait ( 3.0 );

		if ( !isDefined( self.carriedBy ) )
			self playSound( "sentry_gun_beep" );
	}
}


