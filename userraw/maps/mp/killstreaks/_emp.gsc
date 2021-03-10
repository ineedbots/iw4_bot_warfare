/*
	_emp modded
	Author: INeedGames
	Date: 09/22/2020
	Adds a friendly fire check when destroying killstreaks and a duration dvar.
	> gets emp'd
	> hears on an electric radio: WE'VE BEEN EMP'D  ELECTRONICS ARE DOWN!

	DVARS:
		- scr_emp_duration <int>
			60 - (default) amount of seconds for an emp to last

		- scr_emp_doesFriendlyFire <bool>
			true - (default) whether or not if an emp destroies all killstreaks reguardless of friendly fire

		- scr_emp_checkHeliQueue <bool>
			false - (default) whether or not if an emp destroies helicopters in the queue

	Thanks: H3X1C, Emosewaj
*/

#include maps\mp\_utility;
#include common_scripts\utility;


init()
{
	level._effect[ "emp_flash" ] = loadfx( "explosions/emp_flash_mp" );

	level.teamEMPed["allies"] = false;
	level.teamEMPed["axis"] = false;
	level.empPlayer = undefined;
	
	if ( level.teamBased )
		level thread EMP_TeamTracker();
	else
		level thread EMP_PlayerTracker();
	
	level.killstreakFuncs["emp"] = ::EMP_Use;
	
	setDvarIfUninitialized( "scr_emp_duration", 60 );
	setDvarIfUninitialized( "scr_emp_doesFriendlyFire", true );
	setDvarIfUninitialized( "scr_emp_checkHeliQueue", false );

  level.empduration  = getDvarInt( "scr_emp_duration" ); 
	level.empDoesFriendlyFire = getDvarInt( "scr_emp_doesFriendlyFire" );
	level.empCheckHeliQueue = getDvarInt( "scr_emp_checkHeliQueue" );
	
	level thread onPlayerConnect();
}



onPlayerConnect()
{
	for(;;)
	{
		level waittill("connected", player);
		player thread onPlayerSpawned();
	}
}


onPlayerSpawned()
{
	self endon("disconnect");

	for(;;)
	{
		self waittill( "spawned_player" );
		
		if ( (level.teamBased && level.teamEMPed[self.team]) || (!level.teamBased && isDefined( level.empPlayer ) && level.empPlayer != self) )
			self setEMPJammed( true );
	}
}


EMP_Use( lifeId, delay )
{
	assert( isDefined( self ) );

	if ( !isDefined( delay ) )
		delay = 5.0;

	myTeam = self.pers["team"];
	otherTeam = level.otherTeam[myTeam];
	
	if ( level.teamBased )
		self thread EMP_JamTeam( otherTeam, level.empduration, delay );
	else
		self thread EMP_JamPlayers( self, level.empduration, delay );

	self maps\mp\_matchdata::logKillstreakEvent( "emp", self.origin );
	self notify( "used_emp" );

	return true;
}


EMP_JamTeam( teamName, duration, delay, silent )
{
	level endon ( "game_ended" );
	
	assert( teamName == "allies" || teamName == "axis" );

	//wait ( delay );

	if (!isDefined(silent))
		thread teamPlayerCardSplash( "used_emp", self );

	level notify ( "EMP_JamTeam" + teamName );
	level endon ( "EMP_JamTeam" + teamName );
	
	foreach ( player in level.players )
	{
		player playLocalSound( "emp_activate" );
		
		if ( player.team != teamName )
			continue;
		
		if ( player _hasPerk( "specialty_localjammer" ) )
			player RadarJamOff();
	}
	
	if (!isDefined(silent))
	{
		visionSetNaked( "coup_sunblind", 0.1 );
		thread empEffects();
		
		wait ( 0.1 );
		
		// resetting the vision set to the same thing won't normally have an effect.
		// however, if the client receives the previous visionset change in the same packet as this one,
		// this will force them to lerp from the bright one to the normal one.
		visionSetNaked( "coup_sunblind", 0 );
		visionSetNaked( getMapVision(), 3.0 );
	}
	
	level.teamEMPed[teamName] = true;
	level notify ( "emp_update" );
	
	level destroyActiveVehicles( self, !level.empDoesFriendlyFire, teamName );
	
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( duration );
	
	level.teamEMPed[teamName] = false;
	
	foreach ( player in level.players )
	{
		if ( player.team != teamName )
			continue;
		
		if ( player _hasPerk( "specialty_localjammer" ) )
			player RadarJamOn();
	}
	
	level notify ( "emp_update" );
}

EMP_JamPlayers( owner, duration, delay, silent )
{
	level notify ( "EMP_JamPlayers" );
	level endon ( "EMP_JamPlayers" );
	
	//assert( isDefined( owner ) );
	
	//wait ( delay );
	
	foreach ( player in level.players )
	{
		player playLocalSound( "emp_activate" );
		
		if ( isDefined( owner ) && player == owner )
			continue;
		
		if ( player _hasPerk( "specialty_localjammer" ) )
			player RadarJamOff();
	}
	
	if (!isDefined(silent))
	{
		visionSetNaked( "coup_sunblind", 0.1 );
		thread empEffects();

		wait ( 0.1 );
		
		// resetting the vision set to the same thing won't normally have an effect.
		// however, if the client receives the previous visionset change in the same packet as this one,
		// this will force them to lerp from the bright one to the normal one.
		visionSetNaked( "coup_sunblind", 0 );
		visionSetNaked( getMapVision(), 3.0 );
	}
	
	level notify ( "emp_update" );
	
	level.empPlayer = owner;
	level.empPlayer thread empPlayerFFADisconnect();
	level destroyActiveVehicles( owner, !level.empDoesFriendlyFire );
	
	level notify ( "emp_update" );
	
	maps\mp\gametypes\_hostmigration::waitLongDurationWithHostMigrationPause( duration );
	
	foreach ( player in level.players )
	{
		if ( isDefined( owner ) && player == owner )
			continue;
		
		if ( player _hasPerk( "specialty_localjammer" ) )
			player RadarJamOn();
	}
	
	level.empPlayer = undefined;
	level notify ( "emp_update" );
	level notify ( "emp_ended" );
}

empPlayerFFADisconnect()
{
	level endon ( "EMP_JamPlayers" );	
	level endon ( "emp_ended" );
	
	self waittill( "disconnect" );
	level notify ( "emp_update" );
}

empEffects()
{
	foreach( player in level.players )
	{
		playerForward = anglestoforward( player.angles );
		playerForward = ( playerForward[0], playerForward[1], 0 );
		playerForward = VectorNormalize( playerForward );
	
		empDistance = 20000;

		empEnt = Spawn( "script_model", player.origin + ( 0, 0, 8000 ) + Vector_Multiply( playerForward, empDistance ) );
		empEnt setModel( "tag_origin" );
		empEnt.angles = empEnt.angles + ( 270, 0, 0 );
		empEnt thread empEffect( player );
	}
}

empEffect( player )
{
	player endon( "disconnect" );

	wait( 0.5 );
	PlayFXOnTagForClients( level._effect[ "emp_flash" ], self, "tag_origin", player );
}

EMP_TeamTracker()
{
	level endon ( "game_ended" );
	
	for ( ;; )
	{
		level waittill_either ( "joined_team", "emp_update" );
		
		foreach ( player in level.players )
		{
			if ( player.team == "spectator" )
				continue;
				
			player setEMPJammed( level.teamEMPed[player.team] );
		}
	}
}


EMP_PlayerTracker()
{
	level endon ( "game_ended" );
	
	for ( ;; )
	{
		level waittill_either ( "joined_team", "emp_update" );
		
		foreach ( player in level.players )
		{
			if ( player.team == "spectator" )
				continue;
				
			if ( isDefined( level.empPlayer ) && level.empPlayer != player )
				player setEMPJammed( true );
			else
				player setEMPJammed( false );				
		}
	}
}

destroyActiveVehicles( attacker, friendlyFireCheck, teamName )
{
	if (!isDefined(friendlyFireCheck))
		friendlyFireCheck = false;

	if (level.empCheckHeliQueue && isDefined(level.queues) && isDefined(level.queues["helicopter"]))
	{
		newQueue = [];

		foreach ( element in level.queues[ "helicopter" ] )
		{
			if ( !isDefined( element ) )
				continue;

			if (!friendlyFireCheck || !isDefined(element.player) || !isDefined(element.player.team) || (level.teamBased && (!isDefined(teamName) || element.player.team == teamName)) || (!level.teamBased && (!isDefined(attacker) || element.player != attacker)))
			{
				element delete();
				continue;
			}

			newQueue[newQueue.size] = element;
		}

		level.queues[ "helicopter" ] = newQueue;
	}

	if ( isDefined( attacker ) )
	{
		foreach ( heli in level.helis )
			if (!friendlyFireCheck || (level.teamBased && (!isDefined(teamName) || heli.team == teamName)) || (!level.teamBased && (!isDefined(heli.owner) || heli.owner != attacker)))
				radiusDamage( heli.origin, 384, 5000, 5000, attacker );
	
		foreach ( littleBird in level.littleBird )
			if (!friendlyFireCheck || (level.teamBased && (!isDefined(teamName) || littleBird.team == teamName)) || (!level.teamBased && (!isDefined(littleBird.owner) || littleBird.owner != attacker)))
				radiusDamage( littleBird.origin, 384, 5000, 5000, attacker );
		
		foreach ( turret in level.turrets )
			if (!friendlyFireCheck || (level.teamBased && (!isDefined(teamName) || turret.team == teamName)) || (!level.teamBased && (!isDefined(turret.owner) || turret.owner != attacker)))
				radiusDamage( turret.origin, 16, 5000, 5000, attacker );
	
		foreach ( rocket in level.rockets )
			if (!friendlyFireCheck || (level.teamBased && (!isDefined(teamName) || rocket.team == teamName)) || (!level.teamBased && (!isDefined(rocket.owner) || rocket.owner != attacker)))
				rocket notify ( "death" );
		
		if ( level.teamBased )
		{
			foreach ( uav in level.uavModels["allies"] )
				if (!friendlyFireCheck || !isDefined(teamName) || uav.team == teamName)
					radiusDamage( uav.origin, 384, 5000, 5000, attacker );
	
			foreach ( uav in level.uavModels["axis"] )
				if (!friendlyFireCheck || !isDefined(teamName) || uav.team == teamName)
					radiusDamage( uav.origin, 384, 5000, 5000, attacker );
		}
		else
		{	
			foreach ( uav in level.uavModels )
				if (!friendlyFireCheck || !isDefined(uav.owner) || uav.owner != attacker)
					radiusDamage( uav.origin, 384, 5000, 5000, attacker );
		}
		
		if ( isDefined( level.ac130player ) )
			if (!friendlyFireCheck || (level.teamBased && (!isDefined(teamName) || level.ac130player.team == teamName)) || (!level.teamBased && level.ac130player != attacker))
				radiusDamage( level.ac130.planeModel.origin+(0,0,10), 1000, 5000, 5000, attacker );
	}
	else
	{
		foreach ( heli in level.helis )
			if (!friendlyFireCheck || (level.teamBased && (!isDefined(teamName) || heli.team == teamName)) || !level.teamBased)
				radiusDamage( heli.origin, 384, 5000, 5000 );
	
		foreach ( littleBird in level.littleBird )
			if (!friendlyFireCheck || (level.teamBased && (!isDefined(teamName) || littleBird.team == teamName)) || !level.teamBased)
				radiusDamage( littleBird.origin, 384, 5000, 5000 );
		
		foreach ( turret in level.turrets )
			if (!friendlyFireCheck || (level.teamBased && (!isDefined(teamName) || turret.team == teamName)) || !level.teamBased)
				radiusDamage( turret.origin, 16, 5000, 5000 );
	
		foreach ( rocket in level.rockets )
			if (!friendlyFireCheck || (level.teamBased && (!isDefined(teamName) || rocket.team == teamName)) || !level.teamBased)
				rocket notify ( "death" );
		
		if ( level.teamBased )
		{
			foreach ( uav in level.uavModels["allies"] )
				if (!friendlyFireCheck || !isDefined(teamName) || uav.team == teamName)
					radiusDamage( uav.origin, 384, 5000, 5000 );
	
			foreach ( uav in level.uavModels["axis"] )
				if (!friendlyFireCheck || !isDefined(teamName) || uav.team == teamName)
					radiusDamage( uav.origin, 384, 5000, 5000 );
		}
		else
		{	
			foreach ( uav in level.uavModels )
				radiusDamage( uav.origin, 384, 5000, 5000 );
		}
		
		if ( isDefined( level.ac130player ) )
			if (!friendlyFireCheck || (level.teamBased && (!isDefined(teamName) || level.ac130player.team == teamName)) || !level.teamBased)
				radiusDamage( level.ac130.planeModel.origin+(0,0,10), 1000, 5000, 5000 );
	}
}