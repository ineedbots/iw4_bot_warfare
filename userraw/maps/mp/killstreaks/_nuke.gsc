/*
	_nuke modded
	Author: INeedGames
	Date: 09/22/2020

	DVARS:
		- scr_nuke_is_moab <bool>
			false - (default) if a nuke ends the game or is a mw3 moab

		- scr_nuke_kills_all <bool>
			true - (default) if a nuke kills all, even friendly fire

		- scr_nuke_emp_duration <float>
			60.0 - (default) how long to have the emp effect on for the nuked

		- scr_nuke_perm_vision <bool>
			true - (default) if to never change the vision back to normal after a bomb

		- scr_nuke_canCall_whenTimePassed <float>
			0 - (default) time in seconds that must pass before someone can call in a nuke

		- scr_nuke_canCall_whenScoreLimitClose <float>
			0 - (default) ratio of current score to the scorelimit before someone can call a nuke in

		- scr_nuke_canCall_whenScoreLimitClose_selfOnly <bool>
			false - (default) wether or not to take into account just the caller's score, or everyone's score

		- scr_nuke_doSlowmo <int>
			0 - none
			1 - (default) should do a slowmo effect when nuke
			2 - only do slowmo effect if its the first nuke of the game

	Thanks: H3X1C, Emosewaj, RaidMax
*/

#include common_scripts\utility;
#include maps\mp\_utility;

init()
{
	precacheItem( "nuke_mp" );
	precacheLocationSelector( "map_nuke_selector" );
	precacheString( &"MP_TACTICAL_NUKE_CALLED" );
	precacheString( &"MP_FRIENDLY_TACTICAL_NUKE" );
	precacheString( &"MP_TACTICAL_NUKE" );

	level._effect[ "nuke_player" ] = loadfx( "explosions/player_death_nuke" );
	level._effect[ "nuke_flash" ] = loadfx( "explosions/player_death_nuke_flash" );
	level._effect[ "nuke_aftermath" ] = loadfx( "dust/nuke_aftermath_mp" );

	game["strings"]["nuclear_strike"] = &"MP_TACTICAL_NUKE";
	
	level.killstreakFuncs["nuke"] = ::tryUseNuke;

	setDvarIfUninitialized( "scr_nukeTimer", 10 );
	setDvarIfUninitialized( "scr_nukeCancelMode", 0 );

	setDvarIfUninitialized( "scr_nuke_is_moab", false );
	setDvarIfUninitialized( "scr_nuke_doSlowmo", 1 );
	setDvarIfUninitialized( "scr_nuke_kills_all", true );
	setDvarIfUninitialized( "scr_nuke_emp_duration", 60.0 );
	setDvarIfUninitialized( "scr_nuke_perm_vision", true );
	
	setDvarIfUninitialized( "scr_nuke_canCall_whenTimePassed", 0 );
	setDvarIfUninitialized( "scr_nuke_canCall_whenScoreLimitClose", 0 );
	setDvarIfUninitialized( "scr_nuke_canCall_whenScoreLimitClose_selfOnly", false );
	
	level.nukeTimer = getDvarInt( "scr_nukeTimer" );
	level.cancelMode = getDvarInt( "scr_nukeCancelMode" );

	level.nukeEndsGame = !getDvarInt( "scr_nuke_is_moab" );
	level.nukeDoSlowmo = getDvarInt( "scr_nuke_doSlowmo" );
	level.nukeKillsAll = getDvarInt( "scr_nuke_kills_all" );
	level.nukeEmpDuration = getDvarFloat( "scr_nuke_emp_duration" );
	level.nukePermAftermath = getDvarFloat( "scr_nuke_perm_vision" );

	level.canCallNukeAfter = getDvarFloat( "scr_nuke_canCall_whenTimePassed" );
	level.canCallNukeCloseScore = getDvarFloat( "scr_nuke_canCall_whenScoreLimitClose" );
	level.canCallNukeCloseScore_self = getDvarFloat( "scr_nuke_canCall_whenScoreLimitClose_selfOnly" );
	
	/#
	setDevDvarIfUninitialized( "scr_nukeDistance", 5000 );
	setDevDvarIfUninitialized( "scr_nukeEndsGame", true );
	setDevDvarIfUninitialized( "scr_nukeDebugPosition", false );
	#/
	level.moabXP = [];
	
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
		
		if(isDefined(level.moabXP[self.team]) || isDefined(level.moabXP[self.guid]))
			self.xpScaler = 2;

		if (isDefined(level.nukeVision))
			self visionSetNakedForPlayer( level.nukeVision, 0 );
	}
}

tryUseNuke( lifeId, allowCancel )
{
	if( isDefined( level.nukeIncoming ) )
	{
		self iPrintLnBold( &"MP_NUKE_ALREADY_INBOUND" );
		return false;	
	}

	secondsPassed = getSecondsPassed();
	if (level.canCallNukeAfter > 0 && secondsPassed < level.canCallNukeAfter)
	{
		self iPrintLnBold( "You can call in the Nuke in " + (level.canCallNukeAfter - secondsPassed) + " seconds." );
		return false;
	}

	scoreLimit = getScoreLimit();
	if (level.canCallNukeCloseScore > 0 && scoreLimit > 0)
	{
		// get highest score
		if (level.teamBased)
			highestScore = game[ "teamScores" ][ self.team ];
		else
			highestScore = self.score;

		if (!level.canCallNukeCloseScore_self)
		{
			if (level.teamBased)
			{
				highestScore = game[ "teamScores" ][ "allies" ];
				if (game[ "teamScores" ][ "axis" ] > highestScore)
					highestScore = game[ "teamScores" ][ "axis" ];
			}
			else
			{
				for ( i = 0; i < level.players.size; i++ )
				{
					player = level.players[ i ];
					if ( isDefined( player.score ) && player.score > highestScore )
						highestScore = player.score;
				}
			}
		}

		if ( (highestScore / scoreLimit) < level.canCallNukeCloseScore )
		{
			prefix = "Your s";
			if (!level.canCallNukeCloseScore_self)
				prefix = "S";
			self iPrintLnBold( prefix + "core needs to pass " + (level.canCallNukeCloseScore * scoreLimit) + " before you can call the Nuke in." );
			return false;
		}
	}

	if ( self isUsingRemote() && ( !isDefined( level.gtnw ) || !level.gtnw ) )
		return false;

	if ( !isDefined( allowCancel ) )
		allowCancel = true;

	self thread doNuke( allowCancel );
	self notify( "used_nuke" );
	
	return true;
}

delaythread_nuke( delay, func )
{
	level endon ( "nuke_cancelled" );
	
	wait ( delay );
	
	thread [[ func ]]();
}

doNuke( allowCancel )
{
	level notify ( "nuke_cancelled" );
	level endon ( "nuke_cancelled" );
	
	level.nukeInfo = spawnStruct();
	level.nukeInfo.player = self;
	level.nukeInfo.team = self.pers["team"];

	level.nukeIncoming = true;

	if(level.nukeEndsGame)
		maps\mp\gametypes\_gamelogic::pauseTimer();
	
	level.timeLimitOverride = true;
	level.scoreLimitOverride = true;
	setGameEndTime( int( gettime() + (level.nukeTimer * 1000) ) );
	setDvar( "ui_bomb_timer", 4 ); // Nuke sets '4' to avoid briefcase icon showing
	
	if ( level.teambased )
	{
		thread teamPlayerCardSplash( "used_nuke", self, self.team );
		/*
		players = level.players;
		
		foreach( player in level.players )
		{
			playerteam = player.pers["team"];
			if ( isdefined( playerteam ) )
			{
				if ( playerteam == self.pers["team"] )
					player iprintln( &"MP_TACTICAL_NUKE_CALLED", self );
			}
		}
		*/
	}
	else
	{
		if ( !level.hardcoreMode )
			self iprintlnbold(&"MP_FRIENDLY_TACTICAL_NUKE");
	}

	level thread delaythread_nuke( (level.nukeTimer - 3.3), ::nukeSoundIncoming );
	level thread delaythread_nuke( level.nukeTimer, ::nukeSoundExplosion );
	level thread delaythread_nuke( level.nukeTimer, ::nukeSlowMo );
	level thread delaythread_nuke( level.nukeTimer, ::nukeEffects );
	level thread delaythread_nuke( (level.nukeTimer + 0.25), ::nukeVision );
	level thread delaythread_nuke( (level.nukeTimer + 1.5), ::nukeDeath );
	level thread delaythread_nuke( (level.nukeTimer + 1.5), ::nukeEarthquake );
	level thread nukeAftermathEffect();

	if ( level.cancelMode && allowCancel )
		level thread cancelNukeOnDeath( self ); 

	// leaks if lots of nukes are called due to endon above. FIXED
	clockObject = spawn( "script_origin", (0,0,0) );
	clockObject hide();
	level thread killClockObjectOnEndOn(clockObject);

	while ( !isDefined( level.nukeDetonated ) )
	{
		clockObject playSound( "ui_mp_nukebomb_timer" );
		wait( 1.0 );
	}
	
	clockObject delete();
}

killClockObjectOnEndOn(clockObject)
{
	clockObject endon("death");

	level waittill( "nuke_cancelled" );

	clockObject delete();
}

cancelNukeOnDeath( player )
{
	level endon ( "nuke_cancelled" );
	player waittill_any( "death", "disconnect" );

	if ( isDefined( player ) && level.cancelMode == 2 )
		player thread maps\mp\killstreaks\_emp::EMP_Use( 0, 0 );
	
	level.nukeIncoming = undefined;
	level.nukeDetonated = undefined;
	
	maps\mp\gametypes\_gamelogic::resumeTimer();
	level.timeLimitOverride = false;
	level.scoreLimitOverride = false;
	level notify( "update_scorelimit" );
	
	foreach(player in level.players)
		player.nuked = undefined;
	
	setDvar( "ui_bomb_timer", 0 ); // Nuke sets '4' to avoid briefcase icon showing

	level notify ( "nuke_cancelled" );
}

nukeSoundIncoming()
{
	level endon ( "nuke_cancelled" );
	
	foreach( player in level.players )
		player playlocalsound( "nuke_incoming" );
}

nukeSoundExplosion()
{
	level endon ( "nuke_cancelled" );

	foreach( player in level.players )
	{
		player playlocalsound( "nuke_explosion" );
		player playlocalsound( "nuke_wave" );
	}
}

nukeEffects()
{
	level endon ( "nuke_cancelled" );
	
	setDvar( "ui_bomb_timer", 0 );
	setGameEndTime( 0 );
	
	level.nukeDetonated = true;
	
	if ( !level.nukeEndsGame )
	{
		if ( level.teamBased )
		{
			if (level.nukeEmpDuration != 0)
				level.nukeInfo.player thread maps\mp\killstreaks\_emp::EMP_JamTeam(level.otherTeam[level.nukeInfo.team], level.nukeEmpDuration, 5, true);
			
			foreach (player in level.players)
			{
				if(level.nukeInfo.team == player.team)
				{
					player.xpScaler = 2;
				}
			}
			level.moabXP[level.nukeInfo.team] = true;
		}
		else
		{
			if (level.nukeEmpDuration != 0)
				level.nukeInfo.player thread maps\mp\killstreaks\_emp::EMP_JamPlayers(level.nukeInfo.player, level.nukeEmpDuration, 5, true);

			if(isDefined(level.nukeInfo.player))
			{
				level.nukeInfo.player.xpScaler = 2;
				level.moabXP[level.nukeInfo.player.guid] = true;
			}
		}
	}
	else
	{
		// clear the heli queue
		while (true)
		{
			chopper = queueRemoveFirst( "helicopter" );

			if (!isDefined(chopper))
				break;

			chopper delete();
		}

		level maps\mp\killstreaks\_emp::destroyActiveVehicles( level.nukeInfo.player, false );
	}

	foreach( player in level.players )
	{
		playerForward = anglestoforward( player.angles );
		playerForward = ( playerForward[0], playerForward[1], 0 );
		playerForward = VectorNormalize( playerForward );
	
		nukeDistance = 5000;
		/# nukeDistance = getDvarInt( "scr_nukeDistance" );	#/

		nukeEnt = Spawn( "script_model", player.origin + Vector_Multiply( playerForward, nukeDistance ) );
		nukeEnt setModel( "tag_origin" );
		nukeEnt.angles = ( 0, (player.angles[1] + 180), 90 );

		/#
		if ( getDvarInt( "scr_nukeDebugPosition" ) )
		{
			lineTop = ( nukeEnt.origin[0], nukeEnt.origin[1], (nukeEnt.origin[2] + 500) );
			thread draw_line_for_time( nukeEnt.origin, lineTop, 1, 0, 0, 10 );
		}
		#/

		nukeEnt thread nukeEffect( player );
		
		level thread killClockObjectOnEndOn(nukeEnt);
		level thread killNukeEntOn(nukeEnt);
	}
}

killNukeEntOn(nukeEnt)
{
	nukeEnt endon("death");
	level endon ( "nuke_cancelled" );

	level waittill("nuke_death");

	nukeEnt delete();
}

nukeEffect( player )
{
	level endon ( "nuke_cancelled" );

	player endon( "disconnect" );

	waitframe();
	PlayFXOnTagForClients( level._effect[ "nuke_flash" ], self, "tag_origin", player );
}

nukeAftermathEffect()
{
	level endon ( "nuke_cancelled" );

	level waittill ( "spawning_intermission" );
	
	afermathEnt = getEntArray( "mp_global_intermission", "classname" );
	afermathEnt = afermathEnt[0];
	up = anglestoup( afermathEnt.angles );
	right = anglestoright( afermathEnt.angles );

	PlayFX( level._effect[ "nuke_aftermath" ], afermathEnt.origin, up, right );
}

nukeSlowMo()
{
	if (!level.nukeDoSlowmo || (level.nukeDoSlowmo == 2 && isDefined(level.nuked)))
		return;

	//SetSlowMotion( <startTimescale>, <endTimescale>, <deltaTime> )
	setSlowMotion( 1.0, 0.25, 0.5 );
	level waittill_either( "nuke_death", "nuke_cancelled" );
	
	level.nuked = true;
	setSlowMotion( 0.25, 1, 2.0 );
}

nukeVision()
{
	level endon ( "nuke_cancelled" );

	level.nukeVisionInProgress = true;
	level.nukeVision = "mpnuke";
	visionSetNaked( level.nukeVision, 3 );

	level waittill( "nuke_death" );

	level.nukeVision = "mpnuke_aftermath";
	visionSetNaked( level.nukeVision, 5 );
	
	if( level.NukeEndsGame )
	{
		wait 5;
		level.nukeVisionInProgress = undefined;
	}
	else
	{
		wait 3.5;

		if (level.nukePermAftermath)
		{
			level.nukeVision = "aftermath";

			visionSetNaked( level.nukeVision, 1 );
			VisionSetPain( level.nukeVision );
		}
		else
		{
			level.nukeVision = undefined;
			level.nukeVisionInProgress = undefined;

			visionSetNaked( getMapVision(), 10 );
		}
	}
}

nukeDeath()
{
	level endon ( "nuke_cancelled" );
	
	level notify( "nuke_death" );
	
	maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();

	foreach( player in level.players )
	{
		if(level.teamBased)
		{
			if ( !level.nukeKillsAll && level.nukeInfo.team == player.pers["team"] )
				continue;
		}
		else
		{
			if ( !level.nukeKillsAll && level.nukeInfo.player == player )
				continue;	
		}
		
		player.nuked = true;
		
		if ( isAlive( player ) )
			player thread maps\mp\gametypes\_damage::finishPlayerDamageWrapper( level.nukeInfo.player, level.nukeInfo.player, 999999, 0, "MOD_EXPLOSIVE", "nuke_mp", player.origin, player.origin, "none", 0, 0 );
	}
	
	if( level.NukeEndsGame )
	{
		AmbientStop(1);
		
		level.postRoundTime = 10;
		
		if ( level.teamBased )
			thread maps\mp\gametypes\_gamelogic::endGame( level.nukeInfo.team, game["strings"]["nuclear_strike"], true );
		else
		{
			if ( isDefined( level.nukeInfo.player ) )
				thread maps\mp\gametypes\_gamelogic::endGame( level.nukeInfo.player, game["strings"]["nuclear_strike"], true );
			else
				thread maps\mp\gametypes\_gamelogic::endGame( level.nukeInfo, game["strings"]["nuclear_strike"], true );
		}
	}
	else
	{
		wait 0.05;
		
		maps\mp\gametypes\_gamelogic::resumeTimer();
		level.timeLimitOverride = false;
		level.scoreLimitOverride = false;
		level notify( "update_scorelimit" );
		
		//allow next nuke to be called in, reset nuke variables
		level.nukeIncoming = undefined;
		level.nukeDetonated = undefined;
		
		//allow ridable killstreaks
		foreach(player in level.players)
			player.nuked = undefined;
	}
}

nukeEarthquake()
{
	level endon ( "nuke_cancelled" );

	level waittill( "nuke_death" );

	// TODO: need to get a different position to call this on
	//earthquake( 0.6, 10, nukepos, 100000 );

	//foreach( player in level.players )
		//player PlayRumbleOnEntity( "damage_heavy" );
}


waitForNukeCancel()
{
	self waittill( "cancel_location" );
	self setblurforplayer( 0, 0.3 );
}

endSelectionOn( waitfor )
{
	self endon( "stop_location_selection" );
	self waittill( waitfor );
	self thread stopNukeLocationSelection( (waitfor == "disconnect") );
}

endSelectionOnGameEnd()
{
	self endon( "stop_location_selection" );
	level waittill( "game_ended" );
	self thread stopNukeLocationSelection( false );
}

stopNukeLocationSelection( disconnected )
{
	if ( !disconnected )
	{
		self setblurforplayer( 0, 0.3 );
		self endLocationSelection();
		self.selectingLocation = undefined;
	}
	self notify( "stop_location_selection" );
}
