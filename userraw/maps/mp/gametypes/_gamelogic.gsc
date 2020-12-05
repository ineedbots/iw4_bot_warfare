/*
	_gamelogic modded
	Author: INeedGames
	Date: 09/22/2020
	Adds DVARs for customization.

	DVARS:
		- scr_extraDamageFeedback <bool>
			false - (default) players receive hitmarkers for helicopters, hitting equipment, etc.

		- scr_printDamage <bool>
			false - (default) allows players to receive numbered feedback how much damage they delt

		- scr_disableKnife <bool>
			false - (default) disables knife damage

		- scr_intermissionTime <float>
			30.0 - (default) how long to wait in intermission after a match completes

		- scr_forceKillcam <bool>
			false - (default) show final killcams even if a kill didn't end the game

		- scr_forceKillcam_winnersKill <bool>
			true - (default) only show the winner's killcam as a final killcam

		- scr_game_allowFinalKillcam <bool>
			true - (default) allows if a final killcam is shown

		- scr_disableTurret <bool>
			false - (default) disables mountable turret damage

		- scr_failCam <bool>
			false - (default) show suicides as killcams

		- scr_voting <bool>
			false - (default) allow players to vote for a map at the end of a match

		- scr_voting_maps <comma seperate string list>
			"mp_rust,mp_terminal" - (default) list of maps to be allowed for voting

		- scr_voting_time <bool>
			26.0 - (default) how long should polls be open for

		- scr_voting_winTime <bool>
			4.0 - (default) how long to show the winning map for

		- scr_allow_intermission <bool>
			false - (default) allow an intermission time after a match ends

		- scr_voting_bots <bool>
			false - (default) bots are allowed to pick a map to vote

		- scr_nuke_increases_streak <bool>
			true - (default) nukes (if they don't end the game) increase a player's killstreak

		- headshot_detach_head <bool>
			false - (default) headshots dismember the victim's head

		- scr_postDeathDelayMod <float>
			1.0 - (default) Multiplier of how long to wait after death (watching your dead body before the killcam starts)
			
	Thanks: banz, 23Furious
*/

#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include common_scripts\utility;

FACTION_REF_COL 					= 0;
FACTION_NAME_COL 					= 1;
FACTION_SHORT_NAME_COL 				= 1;
FACTION_WIN_GAME_COL 				= 3; 
FACTION_WIN_ROUND_COL 				= 4;
FACTION_MISSION_ACCOMPLISHED_COL 	= 5;
FACTION_ELIMINATED_COL 				= 6;
FACTION_FORFEITED_COL 				= 7;
FACTION_ICON_COL 					= 8;
FACTION_HUD_ICON_COL 				= 9;
FACTION_VOICE_PREFIX_COL 			= 10;
FACTION_SPAWN_MUSIC_COL 			= 11;
FACTION_WIN_MUSIC_COL 				= 12;
FACTION_COLOR_R_COL 				= 13;
FACTION_COLOR_G_COL 				= 14;
FACTION_COLOR_B_COL 				= 15;

// when a team leaves completely, that team forfeited, team left wins round, ends game
onForfeit( team )
{
	if ( isDefined( level.forfeitInProgress ) )
		return;

	level endon( "abort_forfeit" );			//end if the team is no longer in forfeit status

	level.forfeitInProgress = true;
	
	// in 1v1 DM, give players time to change teams
	if ( !level.teambased && level.players.size > 1 )
		wait 10;
	
	forfeit_delay = 20.0;						//forfeit wait, for switching teams and such
	
	foreach ( player in level.players )
	{
		player setLowerMessage( "forfeit_warning", game["strings"]["opponent_forfeiting_in"], forfeit_delay, 100 );
		player thread forfeitWaitforAbort();
	}
		
	wait ( forfeit_delay );
	
	endReason = &"";
	if ( !isDefined( team ) )
	{
		endReason = game["strings"]["players_forfeited"];
		winner = level.players[0];
	}
	else if ( team == "allies" )
	{
		endReason = game["strings"]["allies_forfeited"];
		winner = "axis";
	}
	else if ( team == "axis" )
	{
		endReason = game["strings"]["axis_forfeited"];
		winner = "allies";
	}
	else
	{
		//shouldn't get here
		assertEx( isdefined( team ), "Forfeited team is not defined" );
		assertEx( 0, "Forfeited team " + team + " is not allies or axis" );
		winner = "tie";
	}
	//exit game, last round, no matter if round limit reached or not
	level.forcedEnd = true;
	
	if ( isPlayer( winner ) )
		logString( "forfeit, win: " + winner getXuid() + "(" + winner.name + ")" );
	else
		logString( "forfeit, win: " + winner + ", allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );
	thread endGame( winner, endReason );
}


forfeitWaitforAbort()
{
	self endon ( "disconnect" );
	level endon ( "game_ended" );
	
	level waittill ( "abort_forfeit" );
	
	self clearLowerMessage( "forfeit_warning" );
}


default_onDeadEvent( team )
{
	if ( team == "allies" )
	{
		iPrintLn( game["strings"]["allies_eliminated"] );

		logString( "team eliminated, win: opfor, allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );
		
		thread endGame( "axis", game["strings"]["allies_eliminated"] );
	}
	else if ( team == "axis" )
	{
		iPrintLn( game["strings"]["axis_eliminated"] );

		logString( "team eliminated, win: allies, allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );

		thread endGame( "allies", game["strings"]["axis_eliminated"] );
	}
	else
	{
		logString( "tie, allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );

		if ( level.teamBased )
			thread endGame( "tie", game["strings"]["tie"] );
		else
			thread endGame( undefined, game["strings"]["tie"] );
	}
}


default_onOneLeftEvent( team )
{
	if ( level.teamBased )
	{		
		assert( team == "allies" || team == "axis" );
		
		lastPlayer = getLastLivingPlayer( team );
		lastPlayer thread giveLastOnTeamWarning();
	}
	else
	{
		lastPlayer = getLastLivingPlayer();
		
		logString( "last one alive, win: " + lastPlayer.name );
		thread endGame( lastPlayer, &"MP_ENEMIES_ELIMINATED" );
	}

	return true;
}


default_onTimeLimit()
{
	winner = undefined;
	
	if ( level.teamBased )
	{
		if ( game["teamScores"]["allies"] == game["teamScores"]["axis"] )
			winner = "tie";
		else if ( game["teamScores"]["axis"] > game["teamScores"]["allies"] )
			winner = "axis";
		else
			winner = "allies";

		logString( "time limit, win: " + winner + ", allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );
	}
	else
	{
		winner = maps\mp\gametypes\_gamescore::getHighestScoringPlayer();

		if ( isDefined( winner ) )
			logString( "time limit, win: " + winner.name );
		else
			logString( "time limit, tie" );
	}
	
	thread endGame( winner, game["strings"]["time_limit_reached"] );
}


default_onHalfTime()
{
	winner = undefined;
	
	thread endGame( "halftime", game["strings"]["time_limit_reached"] );
}


forceEnd()
{
	if ( level.hostForcedEnd || level.forcedEnd )
		return;

	winner = undefined;
	
	if ( level.teamBased )
	{
		if ( game["teamScores"]["allies"] == game["teamScores"]["axis"] )
			winner = "tie";
		else if ( game["teamScores"]["axis"] > game["teamScores"]["allies"] )
			winner = "axis";
		else
			winner = "allies";
		logString( "host ended game, win: " + winner + ", allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );
	}
	else
	{
		winner = maps\mp\gametypes\_gamescore::getHighestScoringPlayer();
		if ( isDefined( winner ) )
			logString( "host ended game, win: " + winner.name );
		else
			logString( "host ended game, tie" );
	}
	
	level.forcedEnd = true;
	level.hostForcedEnd = true;
	
	if ( level.splitscreen )
		endString = &"MP_ENDED_GAME";
	else
		endString = &"MP_HOST_ENDED_GAME";
	
	thread endGame( winner, endString );
}


onScoreLimit()
{
	scoreText = game["strings"]["score_limit_reached"];	
	winner = undefined;
	
	if ( level.teamBased )
	{
		if ( game["teamScores"]["allies"] == game["teamScores"]["axis"] )
			winner = "tie";
		else if ( game["teamScores"]["axis"] > game["teamScores"]["allies"] )
			winner = "axis";
		else
			winner = "allies";
		logString( "scorelimit, win: " + winner + ", allies: " + game["teamScores"]["allies"] + ", opfor: " + game["teamScores"]["axis"] );
	}
	else
	{
		winner = maps\mp\gametypes\_gamescore::getHighestScoringPlayer();
		if ( isDefined( winner ) )
			logString( "scorelimit, win: " + winner.name );
		else
			logString( "scorelimit, tie" );
	}
	
	thread endGame( winner, scoreText );
	return true;
}


updateGameEvents()
{
	if ( matchMakingGame() && !level.inGracePeriod )
	{
		if ( level.teamBased )
		{
			// if allies disconnected, and axis still connected, axis wins round and game ends to lobby
			if ( level.teamCount["allies"] < 1 && level.teamCount["axis"] > 0 && game["state"] == "playing" )
			{
				//allies forfeited
				thread onForfeit( "allies" );
				return;
			}
			
			// if axis disconnected, and allies still connected, allies wins round and game ends to lobby
			if ( level.teamCount["axis"] < 1 && level.teamCount["allies"] > 0 && game["state"] == "playing" )
			{
				//axis forfeited
				thread onForfeit( "axis" );
				return;
			}
	
			if ( level.teamCount["axis"] > 0 && level.teamCount["allies"] > 0 )
			{
				level.forfeitInProgress = undefined;
				level notify( "abort_forfeit" );
			}
		}
		else
		{
			if ( level.teamCount["allies"] + level.teamCount["axis"] == 1 && level.maxPlayerCount > 1 )
			{
				thread onForfeit();
				return;
			}

			if ( level.teamCount["axis"] + level.teamCount["allies"] > 1 )
			{
				level.forfeitInProgress = undefined;
				level notify( "abort_forfeit" );
			}
		}
	}

	if ( !getGametypeNumLives() && (!isDefined( level.disableSpawning ) || !level.disableSpawning) )
		return;
		
	if ( !gameHasStarted() ) 
		return;
	
	if ( level.inGracePeriod )
		return;

	if ( level.teamBased )
	{
		livesCount["allies"] = level.livesCount["allies"];
		livesCount["axis"] = level.livesCount["axis"];

		if ( isDefined( level.disableSpawning ) && level.disableSpawning )
		{
			livesCount["allies"] = 0;
			livesCount["axis"] = 0;
		}
		
		// if both allies and axis were alive and now they are both dead in the same instance
		if ( !level.aliveCount["allies"] && !level.aliveCount["axis"] && !livesCount["allies"] && !livesCount["axis"] )
		{
			return [[level.onDeadEvent]]( "all" );
		}

		// if allies were alive and now they are not
		if ( !level.aliveCount["allies"] && !livesCount["allies"] )
		{
			return [[level.onDeadEvent]]( "allies" );
		}

		// if axis were alive and now they are not
		if ( !level.aliveCount["axis"] && !livesCount["axis"] )
		{
			return [[level.onDeadEvent]]( "axis" );
		}

		// one ally left
		if ( level.aliveCount["allies"] == 1 && !livesCount["allies"] )
		{
			if ( !isDefined( level.oneLeftTime["allies"] ) )
			{
				level.oneLeftTime["allies"] = getTime();
				return [[level.onOneLeftEvent]]( "allies" );
			}
		}

		// one axis left
		if ( level.aliveCount["axis"] == 1 && !livesCount["axis"] )
		{
			if ( !isDefined( level.oneLeftTime["axis"] ) )
			{
				level.oneLeftTime["axis"] = getTime();
				return [[level.onOneLeftEvent]]( "axis" );
			}
		}
	}
	else
	{
		// everyone is dead
		if ( (!level.aliveCount["allies"] && !level.aliveCount["axis"]) && (!level.livesCount["allies"] && !level.livesCount["axis"]) )
		{
			return [[level.onDeadEvent]]( "all" );
		}

		livePlayers = getPotentialLivingPlayers();
		
		if ( livePlayers.size == 1 )
		{
			return [[level.onOneLeftEvent]]( "all" );
		}
	}
}


waittillFinalKillcamDone()
{
	if ( level.forceFinalKillcam )
	{
		waittillframeend; // give "round_end_finished" notifies time to process
		
		if( level.showingFinalKillcam )
		{
			foreach ( player in level.players )
				player notify( "reset_outcome" );

			level notify( "game_cleanup" );
			
			while ( level.showingFinalKillcam )
				wait ( 0.05 );
		}
	}
	else
	{
		if ( !level.showingFinalKillcam )
			return false;
	
		while ( level.showingFinalKillcam )
			wait ( 0.05 );
		
		return true;
	}
}

timeLimitClock_Intermission( waitTime, clockColor )
{
	if( !isDefined( clockColor ) )
		clockColor = (0, 0, 0);
	
	NewWaitTime = waitTime*1000;
	
	setGameEndTime( getTime() + int(NewWaitTime) );
	clockObject = spawn( "script_origin", (0,0,0) );
	clockObject hide();
	
	matchStartTimer = createServerTimer("objective", 1.4);
    matchStartTimer setPoint( "TOPRIGHT", "TOPRIGHT", -5, 0 );  //("CENTER", "CENTER", 0, -45);
    matchStartTimer setTimer( waitTime - 1 );
    matchStartTimer.sort = 1001;
    matchStartTimer.foreground = false;
    matchStartTimer.hideWhenInMenu = false;
	matchStartTimer.color = clockColor;
	
	currentTime = getTime();
	timeRunning = ( getTime() - currentTime );
	while ( timeRunning <= NewWaitTime )
	{
		wait 0.05;
		if ( (timeRunning - NewWaitTime) >= -10000 && timeRunning%1000 == 0 )
			clockObject playSound( "ui_mp_timer_countdown" );
		
		timeRunning = ( getTime() - currentTime );
	}
	
	clockObject delete();
	matchStartTimer destroyElem();
}


waitForPlayers( maxTime )
{
	endTime = gettime() + maxTime * 1000 - 200;
	
	if ( level.teamBased )
		while( (!level.hasSpawned[ "axis" ] || !level.hasSpawned[ "allies" ]) && gettime() < endTime )
			wait ( 0.05 );
	else
		while ( level.maxPlayerCount < 2 && gettime() < endTime )
			wait ( 0.05 );
}


prematchPeriod()
{
	level endon( "game_ended" );

	if ( level.prematchPeriod > 0 )
	{
		if ( level.console )
		{
			thread matchStartTimer( "match_starting_in", level.prematchPeriod );
			wait ( level.prematchPeriod );
		}
		else
		{
			matchStartTimerPC();
		}
	}
	else
	{
		matchStartTimerSkip();
	}
	
	for ( index = 0; index < level.players.size; index++ )
	{
		level.players[index] freezeControlsWrapper( false );
		level.players[index] enableWeapons();

		hintMessage = getObjectiveHintText( level.players[index].pers["team"] );
		if ( !isDefined( hintMessage ) || !level.players[index].hasSpawned )
			continue;

		level.players[index] setClientDvar( "scr_objectiveText", hintMessage );
		level.players[index] thread maps\mp\gametypes\_hud_message::hintMessage( hintMessage );
	}

	if ( game["state"] != "playing" )
		return;
}


gracePeriod()
{
	level endon("game_ended");
	
	while ( level.inGracePeriod )
	{
		wait ( 1.0 );
		level.inGracePeriod--;
	}

	//wait ( level.gracePeriod );
	
	level notify ( "grace_period_ending" );
	wait ( 0.05 );
	
	gameFlagSet( "graceperiod_done" );
	level.inGracePeriod = false;
	
	if ( game["state"] != "playing" )
		return;
	
	if ( getGametypeNumLives() )
	{
		// Players on a team but without a weapon show as dead since they can not get in this round
		players = level.players;
		
		for ( i = 0; i < players.size; i++ )
		{
			player = players[i];
			
			if ( !player.hasSpawned && player.sessionteam != "spectator" && !isAlive( player ) )
				player.statusicon = "hud_status_dead";
		}
	}
	
	level thread updateGameEvents();
}


updateWinStats( winner )
{
	if ( !winner rankingEnabled() )
		return;
	
	winner maps\mp\gametypes\_persistence::statAdd( "losses", -1 );
	
	println( "setting winner: " + winner maps\mp\gametypes\_persistence::statGet( "wins" ) );
	winner maps\mp\gametypes\_persistence::statAdd( "wins", 1 );
	winner updatePersRatio( "winLossRatio", "wins", "losses" );
	winner maps\mp\gametypes\_persistence::statAdd( "currentWinStreak", 1 );
	
	cur_win_streak = winner maps\mp\gametypes\_persistence::statGet( "currentWinStreak" );
	if ( cur_win_streak > winner maps\mp\gametypes\_persistence::statGet( "winStreak" ) )
		winner maps\mp\gametypes\_persistence::statSet( "winStreak", cur_win_streak );
	
	winner maps\mp\gametypes\_persistence::statSetChild( "round", "win", true );
	winner maps\mp\gametypes\_persistence::statSetChild( "round", "loss", false );
}


updateLossStats( loser )
{
	if ( !loser rankingEnabled() )
		return;
	
	loser maps\mp\gametypes\_persistence::statAdd( "losses", 1 );
	loser updatePersRatio( "winLossRatio", "wins", "losses" );
	loser maps\mp\gametypes\_persistence::statSetChild( "round", "loss", true );
}


updateTieStats( loser )
{	
	if ( !loser rankingEnabled() )
		return;
	
	loser maps\mp\gametypes\_persistence::statAdd( "losses", -1 );
	
	loser maps\mp\gametypes\_persistence::statAdd( "ties", 1 );
	loser updatePersRatio( "winLossRatio", "wins", "losses" );
	loser maps\mp\gametypes\_persistence::statSet( "currentWinStreak", 0 );	
}


updateWinLossStats( winner )
{
	//if ( privateMatch() )
	//	return;
		
	if ( !wasLastRound() )
		return;
		
	players = level.players;

	if ( !isDefined( winner ) || ( isDefined( winner ) && isString( winner ) && winner == "tie" ) )
	{
		foreach ( player in level.players )
		{
			if ( isDefined( player.connectedPostGame ) )
				continue;

			if ( level.hostForcedEnd && player isHost() )
			{
				player maps\mp\gametypes\_persistence::statSet( "currentWinStreak", 0 );
				continue;
			}
				
			updateTieStats( player );
		}		
	} 
	else if ( isPlayer( winner ) )
	{
		if ( level.hostForcedEnd && winner isHost() )
		{
			winner maps\mp\gametypes\_persistence::statSet( "currentWinStreak", 0 );
			return;
		}
				
		updateWinStats( winner );
	}
	else if ( isString( winner ) )
	{
		foreach ( player in level.players )
		{
			if ( isDefined( player.connectedPostGame ) )
				continue;

			if ( level.hostForcedEnd && player isHost() )
			{
				player maps\mp\gametypes\_persistence::statSet( "currentWinStreak", 0 );
				continue;
			}

			if ( winner == "tie" )
				updateTieStats( player );
			else if ( player.pers["team"] == winner )
				updateWinStats( player );
			else
				player maps\mp\gametypes\_persistence::statSet( "currentWinStreak", 0 );
		}
	}
}


freezePlayerForRoundEnd( delay )
{
	self endon ( "disconnect" );
	self clearLowerMessages();
	
	if ( !isDefined( delay ) )
		delay = 0.05;
	
	self closepopupMenu();
	self closeInGameMenu();
	
	wait ( delay );
	self freezeControlsWrapper( true );
//	self disableWeapons();
}


updateMatchBonusScores( winner )
{
	if ( !game["timePassed"] )
		return;

	//if ( !matchMakingGame() )
	//	return;

	if ( !getTimeLimit() || level.forcedEnd )
	{
		gameLength = getTimePassed() / 1000;		
		// cap it at 20 minutes to avoid exploiting
		gameLength = min( gameLength, 1200 );
	}
	else
	{
		gameLength = getTimeLimit() * 60;
	}
		
	if ( level.teamBased )
	{
		if ( winner == "allies" )
		{
			winningTeam = "allies";
			losingTeam = "axis";
		}
		else if ( winner == "axis" )
		{
			winningTeam = "axis";
			losingTeam = "allies";
		}
		else
		{
			winningTeam = "tie";
			losingTeam = "tie";
		}

		if ( winningTeam != "tie" )
		{
			winnerScale = maps\mp\gametypes\_rank::getScoreInfoValue( "win" );
			loserScale = maps\mp\gametypes\_rank::getScoreInfoValue( "loss" );
			setWinningTeam( winningTeam );
		}
		else
		{
			winnerScale = maps\mp\gametypes\_rank::getScoreInfoValue( "tie" );
			loserScale = maps\mp\gametypes\_rank::getScoreInfoValue( "tie" );
		}
		
		foreach ( player in level.players )
		{
			if ( isDefined( player.connectedPostGame ) )
				continue;
			
			if ( !player rankingEnabled() )
				continue;
			
			if ( player.timePlayed["total"] < 1 || player.pers["participation"] < 1 )
			{
				player thread maps\mp\gametypes\_rank::endGameUpdate();
				continue;
			}
	
			// no bonus for hosts who force ends
			if ( level.hostForcedEnd && player isHost() )
				continue;

			spm = player maps\mp\gametypes\_rank::getSPM();				
			if ( winningTeam == "tie" )
			{
				playerScore = int( (winnerScale * ((gameLength/60) * spm)) * (player.timePlayed["total"] / gameLength) );
				player thread giveMatchBonus( "tie", playerScore );
				player.matchBonus = playerScore;
			}
			else if ( isDefined( player.pers["team"] ) && player.pers["team"] == winningTeam )
			{
				playerScore = int( (winnerScale * ((gameLength/60) * spm)) * (player.timePlayed["total"] / gameLength) );
				player thread giveMatchBonus( "win", playerScore );
				player.matchBonus = playerScore;
			}
			else if ( isDefined(player.pers["team"] ) && player.pers["team"] == losingTeam )
			{
				playerScore = int( (loserScale * ((gameLength/60) * spm)) * (player.timePlayed["total"] / gameLength) );
				player thread giveMatchBonus( "loss", playerScore );
				player.matchBonus = playerScore;
			}
		}
	}
	else
	{
		if ( isDefined( winner ) )
		{
			winnerScale = maps\mp\gametypes\_rank::getScoreInfoValue( "win" );
			loserScale = maps\mp\gametypes\_rank::getScoreInfoValue( "loss" );
		}
		else
		{
			winnerScale = maps\mp\gametypes\_rank::getScoreInfoValue( "tie" );
			loserScale = maps\mp\gametypes\_rank::getScoreInfoValue( "tie" );
		}
		
		foreach ( player in level.players )
		{
			if ( isDefined( player.connectedPostGame ) )
				continue;
			
			if ( player.timePlayed["total"] < 1 || player.pers["participation"] < 1 )
			{
				player thread maps\mp\gametypes\_rank::endGameUpdate();
				continue;
			}
			
			spm = player maps\mp\gametypes\_rank::getSPM();

			isWinner = false;
			for ( pIdx = 0; pIdx < min( level.placement["all"].size, 3 ); pIdx++ )
			{
				if ( level.placement["all"][pIdx] != player )
					continue;
				isWinner = true;				
			}
			
			if ( isWinner )
			{
				playerScore = int( (winnerScale * ((gameLength/60) * spm)) * (player.timePlayed["total"] / gameLength) );
				player thread giveMatchBonus( "win", playerScore );
				player.matchBonus = playerScore;
			}
			else
			{
				playerScore = int( (loserScale * ((gameLength/60) * spm)) * (player.timePlayed["total"] / gameLength) );
				player thread giveMatchBonus( "loss", playerScore );
				player.matchBonus = playerScore;
			}
		}
	}
}


giveMatchBonus( scoreType, score )
{
	self endon ( "disconnect" );

	level waittill ( "give_match_bonus" );
	
	self maps\mp\gametypes\_rank::giveRankXP( scoreType, score );
	//logXPGains();
	
	self maps\mp\gametypes\_rank::endGameUpdate();
}


setXenonRanks( winner )
{
	players = level.players;

	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];

		if( !isdefined(player.score) || !isdefined(player.pers["team"]) )
			continue;

	}

	for ( i = 0; i < players.size; i++ )
	{
		player = players[i];

		if( !isdefined(player.score) || !isdefined(player.pers["team"]) )
			continue;		
		
		setPlayerTeamRank( player, player.clientid, player.score - 5 * player.deaths );
	}
	sendranks();
}


checkTimeLimit( prevTimePassed )
{
	if ( isDefined( level.timeLimitOverride ) && level.timeLimitOverride )
		return;
	
	if ( game["state"] != "playing" )
	{
		setGameEndTime( 0 );
		return;
	}
		
	if ( getTimeLimit() <= 0 )
	{
		if ( isDefined( level.startTime ) )
			setGameEndTime( level.startTime );
		else
			setGameEndTime( 0 );
		return;
	}
		
	if ( !gameFlag( "prematch_done" ) )
	{
		setGameEndTime( 0 );
		return;
	}
	
	if ( !isdefined( level.startTime ) )
		return;
	
	timeLeft = getTimeRemaining();
	
	// want this accurate to the millisecond
//	if ( getHalfTime() && game["status"] != "halftime" )
//		setGameEndTime( getTime() + (int(timeLeft) - int(getTimeLimit()*60*1000*0.5)) );
//	else
		setGameEndTime( getTime() + int(timeLeft) );

	if ( timeLeft > 0 )
	{
		if ( getHalfTime() && checkHalfTime( prevTimePassed ) )
			[[level.onHalfTime]]();

		return;
	}
	
	[[level.onTimeLimit]]();
}


checkHalfTime( prevTimePassed )
{
	if ( !level.teamBased )
		return false;
		
	if ( getTimeLimit() )
	{
		halfTime = (getTimeLimit() * 60 * 1000) * 0.5;
		
		if ( getTimePassed() >= halfTime && prevTimePassed < halfTime && prevTimePassed > 0 )
		{
			game["roundMillisecondsAlreadyPassed"] = getTimePassed();
			return true;
		}
	}
	
	return false;
}



getTimeRemaining()
{
	return getTimeLimit() * 60 * 1000 - getTimePassed();
}


checkTeamScoreLimitSoon( team )
{
	assert( isDefined( team ) );

	if ( getWatchedDvar( "scorelimit" ) <= 0 || isObjectiveBased() )
		return;
		
	if ( isDefined( level.scoreLimitOverride ) && level.scoreLimitOverride )
		return;
		
	if ( !level.teamBased )
		return;

	// No checks until a minute has passed to let wild data settle
	if ( getTimePassed() < (60 * 1000) ) // 1 min
		return;
	
	timeLeft = estimatedTimeTillScoreLimit( team );

	if ( timeLeft < 2 )
		level notify( "match_ending_soon", "score" );
}


checkPlayerScoreLimitSoon()
{
	if ( getWatchedDvar( "scorelimit" ) <= 0 || isObjectiveBased() )
		return;
		
	if ( level.teamBased )
		return;

	// No checks until a minute has passed to let wild data settle
	if ( getTimePassed() < (60 * 1000) ) // 1 min
		return;

	timeLeft = self estimatedTimeTillScoreLimit();

	if ( timeLeft < 2 )
		level notify( "match_ending_soon", "score" );
}


checkScoreLimit()
{
	if ( isObjectiveBased() )
		return false;

	if ( isDefined( level.scoreLimitOverride ) && level.scoreLimitOverride )
		return false;
	
	if ( game["state"] != "playing" )
		return false;

	if ( getWatchedDvar( "scorelimit" ) <= 0 )
		return false;

	if ( level.teamBased )
	{
		if( game["teamScores"]["allies"] < getWatchedDvar( "scorelimit" ) && game["teamScores"]["axis"] < getWatchedDvar( "scorelimit" ) )
			return false;
	}
	else
	{
		if ( !isPlayer( self ) )
			return false;

		if ( self.score < getWatchedDvar( "scorelimit" ) )
			return false;
	}

	return onScoreLimit();
}


updateGameTypeDvars()
{
	level endon ( "game_ended" );
	
	while ( game["state"] == "playing" )
	{
		// make sure we check time limit right when game ends
		if ( isdefined( level.startTime ) )
		{
			if ( getTimeRemaining() < 3000 )
			{
				wait .1;
				continue;
			}
		}
		wait 1;
	}
}


matchStartTimerPC()
{
	thread matchStartTimer( "waiting_for_teams", level.prematchPeriod + level.prematchPeriodEnd );
	
	waitForPlayers( level.prematchPeriod );
	
	if ( level.prematchPeriodEnd > 0 )
		matchStartTimer( "match_starting_in", level.prematchPeriodEnd );
}

matchStartTimer_Internal( countTime, matchStartTimer )
{
	waittillframeend; // wait till cleanup of previous start timer if multiple happen at once
	visionSetNaked( "mpIntro", 0 );
	
	level endon( "match_start_timer_beginning" );
	while ( countTime > 0 && !level.gameEnded )
	{
		matchStartTimer thread maps\mp\gametypes\_hud::fontPulse( level );
		wait ( matchStartTimer.inFrames * 0.05 );
		matchStartTimer setValue( countTime );
		if ( countTime == 2 )
			visionSetNaked( getMapVision(), 3.0 );
		countTime--;
		wait ( 1 - (matchStartTimer.inFrames * 0.05) );
	}
}

matchStartTimer( type, duration )
{
	level notify( "match_start_timer_beginning" );
	
	matchStartText = createServerFontString( "objective", 1.5 );
	matchStartText setPoint( "CENTER", "CENTER", 0, -40 );
	matchStartText.sort = 1001;
	matchStartText setText( game["strings"]["waiting_for_teams"] );
	matchStartText.foreground = false;
	matchStartText.hidewheninmenu = true;
	
	matchStartText setText( game["strings"][type] ); // "match begins in:"
	
	matchStartTimer = createServerFontString( "hudbig", 1 );
	matchStartTimer setPoint( "CENTER", "CENTER", 0, 0 );
	matchStartTimer.sort = 1001;
	matchStartTimer.color = (1,1,0);
	matchStartTimer.foreground = false;
	matchStartTimer.hidewheninmenu = true;
	
	matchStartTimer maps\mp\gametypes\_hud::fontPulseInit();

	countTime = int( duration );
	
	if ( countTime >= 2 )
	{
		matchStartTimer_Internal( countTime, matchStartTimer );
		visionSetNaked( getMapVision(), 3.0 );
	}
	else
	{
		visionSetNaked( "mpIntro", 0 );
		visionSetNaked( getMapVision(), 1.0 );
	}
	
	matchStartTimer destroyElem();
	matchStartText destroyElem();
}

matchStartTimerSkip()
{
	visionSetNaked( getMapVision(), 0 );
}


onRoundSwitch()
{
	if ( !isDefined( game["switchedsides"] ) )
		game["switchedsides"] = false;
	
	// overtime
	if ( game["roundsWon"]["allies"] == getWatchedDvar( "winlimit" ) - 1 && game["roundsWon"]["axis"] == getWatchedDvar( "winlimit" ) - 1 )
	{
		aheadTeam = getBetterTeam();
		if ( aheadTeam != game["defenders"] )
		{
			game["switchedsides"] = !game["switchedsides"];
		}
		else
		{
			level.halftimeSubCaption = "";
		}
		level.halftimeType = "overtime";
	}
	else
	{
		level.halftimeType = "halftime";
		game["switchedsides"] = !game["switchedsides"];
	}
}


checkRoundSwitch()
{
	if ( !level.teamBased )
		return false;
		
	if ( !isDefined( level.roundSwitch ) || !level.roundSwitch )
		return false;
		
	assert( game["roundsPlayed"] > 0 );	
	if ( game["roundsPlayed"] % level.roundSwitch == 0 )
	{
		onRoundSwitch();
		return true;
	}
		
	return false;
}


// returns the best guess of the exact time until the scoreboard will be displayed and player control will be lost.
// returns undefined if time is not known
timeUntilRoundEnd()
{
	if ( level.gameEnded )
	{
		timePassed = (getTime() - level.gameEndTime) / 1000;
		timeRemaining = level.postRoundTime - timePassed;
		
		if ( timeRemaining < 0 )
			return 0;
		
		return timeRemaining;
	}
	
	if ( getTimeLimit() <= 0 )
		return undefined;
	
	if ( !isDefined( level.startTime ) )
		return undefined;
	
	tl = getTimeLimit();
	
	timePassed = (getTime() - level.startTime)/1000;
	timeRemaining = (getTimeLimit() * 60) - timePassed;
	
	if ( isDefined( level.timePaused ) )
		timeRemaining += level.timePaused; 
	
	return timeRemaining + level.postRoundTime;
}



freeGameplayHudElems()
{
	// free up some hud elems so we have enough for other things.
	
	// perk icons
	if ( isdefined( self.perkicon ) )
	{
		if ( isdefined( self.perkicon[0] ) )
		{
			self.perkicon[0] destroyElem();
			self.perkname[0] destroyElem();
		}
		if ( isdefined( self.perkicon[1] ) )
		{
			self.perkicon[1] destroyElem();
			self.perkname[1] destroyElem();
		}
		if ( isdefined( self.perkicon[2] ) )
		{
			self.perkicon[2] destroyElem();
			self.perkname[2] destroyElem();
		}
	}
	self notify("perks_hidden"); // stop any threads that are waiting to hide the perk icons
	
	// lower message
	self.lowerMessage destroyElem();
	self.lowerTimer destroyElem();
	
	// progress bar
	if ( isDefined( self.proxBar ) )
		self.proxBar destroyElem();
	if ( isDefined( self.proxBarText ) )
		self.proxBarText destroyElem();
}


getHostPlayer()
{
	players = getEntArray( "player", "classname" );
	
	for ( index = 0; index < players.size; index++ )
	{
		if ( players[index] isHost() )
			return players[index];
	}
}


hostIdledOut()
{
	hostPlayer = getHostPlayer();
	
	// host never spawned
	if ( isDefined( hostPlayer ) && !hostPlayer.hasSpawned && !isDefined( hostPlayer.selectedClass ) )
		return true;

	return false;
}



roundEndWait( defaultDelay, matchBonus )
{
	//setSlowMotion( 1.0, 0.15, defaultDelay / 2 );

	notifiesDone = false;
	while ( !notifiesDone )
	{
		players = level.players;
		notifiesDone = true;
		
		foreach ( player in players )
		{
			if ( !isDefined( player.doingSplash ) )
				continue;

			if ( !player maps\mp\gametypes\_hud_message::isDoingSplash() )
				continue;

			notifiesDone = false;
		}
		wait ( 0.5 );
	}

	if ( !matchBonus )
	{
		wait ( defaultDelay );
		level notify ( "round_end_finished" );
		//setSlowMotion( 1.0, 1.0, 0.05 );
		return;
	}

    wait ( defaultDelay / 2 );
	level notify ( "give_match_bonus" );
	wait ( defaultDelay / 2 );

	notifiesDone = false;
	while ( !notifiesDone )
	{
		players = level.players;
		notifiesDone = true;
		foreach ( player in players )
		{
			if ( !isDefined( player.doingSplash ) )
				continue;

			if ( !player maps\mp\gametypes\_hud_message::isDoingSplash() )
				continue;

			notifiesDone = false;
		}
		wait ( 0.5 );
	}
	//setSlowMotion( 1.0, 1.0, 0.05);
	
	level notify ( "round_end_finished" );
}


roundEndDOF( time )
{
	self setDepthOfField( 0, 128, 512, 4000, 6, 1.8 );
}

randomizeMaps()
{
	tok = strTok( level.votingMaps, "," );
	
	randomArray = [];
    for( i = 0; i < 9; i++ )
	{
		selectedRand = randomint( tok.size );
        randomArray[ i ] = tok[ selectedRand ];
        tok = restructMapArray( tok, selectedRand );
    }
	
	return randomArray;
}

restructMapArray(oldArray, index)
{
   restructArray = [];

	for( i=0; i < oldArray.size; i++ )
	{
		if( i < index ) 
			restructArray[ i ] = oldArray[ i ];
		else if( i > index ) 
			restructArray[ i - 1 ] = oldArray[ i ];
	}

	return restructArray;
}


Callback_StartGameType()
{
	maps\mp\_load::main();
	
	levelFlagInit( "round_over", false );
	levelFlagInit( "game_over", false );
	levelFlagInit( "block_notifies", false ); 

	level.prematchPeriod = 0;
	level.prematchPeriodEnd = 0;
	level.postGameNotifies = 0;
	
	level.intermission = false;
	
	
	setDvarIfUninitialized( "scr_extraDamageFeedback", false );
	setDvarIfUninitialized( "scr_printDamage", false );
	setDvarIfUninitialized( "scr_disableKnife", false );
	setDvarIfUninitialized( "scr_intermissionTime", 30.0 );
	setDvarIfUninitialized( "scr_forceKillcam", false );
	setDvarIfUninitialized( "scr_forceKillcam_winnersKill", true );
	setDvarIfUninitialized( "scr_game_allowFinalKillcam", true );
	setDvarIfUninitialized( "scr_disableTurret", false );
	setDvarIfUninitialized( "scr_failCam", false );
	setDvarIfUninitialized( "scr_voting", false );
	setDvarIfUninitialized( "scr_voting_maps", "mp_rust,mp_terminal" );
	setDvarIfUninitialized( "scr_voting_time", 26.0 );
	setDvarIfUninitialized( "scr_voting_winTime", 4.0 );
	setDvarIfUninitialized( "scr_allow_intermission", false );//vanilla as possible
	setDvarIfUninitialized( "scr_voting_bots", false );
	setDvarIfUninitialized( "scr_nuke_increases_streak", true );
	setDvarIfUninitialized( "headshot_detach_head", false );
	setDvarIfUninitialized( "scr_killstreaks_increase_killstreak", true );
	setDvarIfUninitialized( "scr_postDeathDelayMod", 1.0 );
	
	level.extraDamageFeedback = getDvarInt("scr_extraDamageFeedback");
	level.allowPrintDamage = getDvarInt("scr_printDamage");
	level.disableKnife = getDvarInt("scr_disableKnife");
	level.intermissionTime = getDvarFloat("scr_intermissionTime");
	level.forceFinalKillcam = getDvarInt("scr_forceKillcam");
	level.forceFinalKillcamWinnersKill = getDvarInt("scr_forceKillcam_winnersKill");
	level.allowFinalKillcam = getDvarInt("scr_game_allowFinalKillcam");
	level.disableTurret = getDvarInt( "scr_disableTurret" );
	level.failCam = getDvarInt( "scr_failCam" );
	level.voting = getDvarInt( "scr_voting" );
	level.votingMaps = getDvar( "scr_voting_maps" );
	level.voteWinTime = getDvarInt( "scr_voting_winTime" );
	level.voteTime = getDvarInt( "scr_voting_time" );
	level.allowIntermission = getDvarInt( "scr_allow_intermission" );
	level.botsVote = getDvarInt( "scr_voting_bots" );
	level.headShotDetachHead = getDvarInt("headshot_detach_head");
	level.nukeIncreasesStreak = getDvarInt( "scr_nuke_increases_streak" );
	level.killstreaksIncreaseKillstreak = getDvarInt( "scr_killstreaks_increase_killstreak" );
	level.postDeathDelayMod = getDvarFloat("scr_postDeathDelayMod");
	
	if ( level.voting )
		level.votingMapsTok = randomizeMaps();
	else
		level.votingMapsTok = strTok( level.votingMaps, "," );
	
	level.scriptIncKillstreak = false;
	
	level.mapVotes = [];
	for( i=0; i < level.votingMapsTok.size; i++ ) 
		level.mapVotes[ i ] = 0;
	
	level.inVoting = false;
	level.inShowingWinner = false;
	level.inIntermission = false;
	level.highestVotedMap = -1;
	
	
	makeDvarServerInfo( "cg_thirdPersonAngle", 356 );

	makeDvarServerInfo( "scr_gameended", 0 );

	if ( !isDefined( game["gamestarted"] ) )
	{
		game["clientid"] = 0;
		
		alliesCharSet = getMapCustom( "allieschar" );
		if ( (!isDefined( alliesCharSet ) || alliesCharSet == "") )
		{
			if ( !isDefined( game["allies"] ) )
				alliesCharSet = "us_army";
			else
				alliesCharSet = game["allies"];
		}

		axisCharSet = getMapCustom( "axischar" );
		if ( (!isDefined( axisCharSet ) || axisCharSet == "") )
		{
			if ( !isDefined( game["axis"] ) )
				axisCharSet = "opforce_composite";
			else
				axisCharSet = game["axis"];
		}

		game["allies"] = alliesCharSet;
		game["axis"] = axisCharSet;	

		if ( !isDefined( game["attackers"] ) || !isDefined( game["defenders"]  ) )
			thread error( "No attackers or defenders team defined in level .gsc." );

		if (  !isDefined( game["attackers"] ) )
			game["attackers"] = "allies";
		if (  !isDefined( game["defenders"] ) )
			game["defenders"] = "axis";

		if ( !isDefined( game["state"] ) )
			game["state"] = "playing";
	
		precacheStatusIcon( "hud_status_dead" );
		precacheStatusIcon( "hud_status_connecting" );
		precacheString( &"MPUI_REVIVING" );
		precacheString( &"MPUI_BEING_REVIVED" );
		
		precacheRumble( "damage_heavy" );

		precacheShader( "white" );
		precacheShader( "black" );
		
		game["menu_vote"] = "vote";
		
		if ( level.voting && level.voteTime > 0.0 && level.votingMapsTok.size )
			precacheMenu( game["menu_vote"] );
		
		game["menu_popup_summary"] = "popup_summary";
		
		if ( level.allowIntermission && level.intermissionTime > 0.0 )
			precacheMenu( game["menu_popup_summary"] );
		
		game["strings"]["press_to_spawn"] = &"PLATFORM_PRESS_TO_SPAWN";
		if ( level.teamBased )
		{
			game["strings"]["waiting_for_teams"] = &"MP_WAITING_FOR_TEAMS";
			game["strings"]["opponent_forfeiting_in"] = &"MP_OPPONENT_FORFEITING_IN";
		}
		else
		{
			game["strings"]["waiting_for_teams"] = &"MP_WAITING_FOR_MORE_PLAYERS";
			game["strings"]["opponent_forfeiting_in"] = &"MP_OPPONENT_FORFEITING_IN";
		}
		game["strings"]["match_starting_in"] = &"MP_MATCH_STARTING_IN";
		game["strings"]["match_resuming_in"] = &"MP_MATCH_RESUMING_IN";
		game["strings"]["waiting_for_players"] = &"MP_WAITING_FOR_PLAYERS";
		game["strings"]["spawn_next_round"] = &"MP_SPAWN_NEXT_ROUND";
		game["strings"]["waiting_to_spawn"] = &"MP_WAITING_TO_SPAWN";
		game["strings"]["waiting_to_safespawn"] = &"MP_WAITING_TO_SAFESPAWN";
		game["strings"]["match_starting"] = &"MP_MATCH_STARTING";
		game["strings"]["change_class"] = &"MP_CHANGE_CLASS_NEXT_SPAWN";
		game["strings"]["last_stand"] = &"MPUI_LAST_STAND";
		game["strings"]["final_stand"] = &"MPUI_FINAL_STAND";
		game["strings"]["c4_death"] = &"MPUI_C4_DEATH";
		
		game["strings"]["cowards_way"] = &"PLATFORM_COWARDS_WAY_OUT";
		
		game["strings"]["tie"] = &"MP_MATCH_TIE";
		game["strings"]["round_draw"] = &"MP_ROUND_DRAW";

		game["strings"]["grabbed_flag"] = &"MP_GRABBED_FLAG_FIRST";
		game["strings"]["enemies_eliminated"] = &"MP_ENEMIES_ELIMINATED";
		game["strings"]["score_limit_reached"] = &"MP_SCORE_LIMIT_REACHED";
		game["strings"]["round_limit_reached"] = &"MP_ROUND_LIMIT_REACHED";
		game["strings"]["time_limit_reached"] = &"MP_TIME_LIMIT_REACHED";
		game["strings"]["players_forfeited"] = &"MP_PLAYERS_FORFEITED";
		game["strings"]["S.A.S Win"] = &"SAS_WIN";
		game["strings"]["Spetsnaz Win"] = &"SPETSNAZ_WIN";

		game["colors"]["blue"] = (0.25,0.25,0.75);
		game["colors"]["red"] = (0.75,0.25,0.25);
		game["colors"]["white"] = (1.0,1.0,1.0);
		game["colors"]["black"] = (0.0,0.0,0.0);
		game["colors"]["green"] = (0.25,0.75,0.25);
		game["colors"]["yellow"] = (0.65,0.65,0.0);
		game["colors"]["orange"] = (1.0,0.45,0.0);

		game["strings"]["allies_eliminated"] = maps\mp\gametypes\_teams::getTeamEliminatedString( "allies" );
		game["strings"]["allies_forfeited"] = maps\mp\gametypes\_teams::getTeamForfeitedString( "allies" );
		game["strings"]["allies_name"] = maps\mp\gametypes\_teams::getTeamName( "allies" );	
		game["icons"]["allies"] = maps\mp\gametypes\_teams::getTeamIcon( "allies" );	
		game["colors"]["allies"] = maps\mp\gametypes\_teams::getTeamColor( "allies" );	

		game["strings"]["axis_eliminated"] = maps\mp\gametypes\_teams::getTeamEliminatedString( "axis" );
		game["strings"]["axis_forfeited"] = maps\mp\gametypes\_teams::getTeamForfeitedString( "axis" );
		game["strings"]["axis_name"] = maps\mp\gametypes\_teams::getTeamName( "axis" );	
		game["icons"]["axis"] = maps\mp\gametypes\_teams::getTeamIcon( "axis" );	
		game["colors"]["axis"] = maps\mp\gametypes\_teams::getTeamColor( "axis" );	
		
		if ( game["colors"]["allies"] == (0,0,0) )
			game["colors"]["allies"] = (0.5,0.5,0.5);

		if ( game["colors"]["axis"] == (0,0,0) )
			game["colors"]["axis"] = (0.5,0.5,0.5);

		[[level.onPrecacheGameType]]();

		if ( level.console )
		{
			if ( !level.splitscreen )
				level.prematchPeriod = maps\mp\gametypes\_tweakables::getTweakableValue( "game", "graceperiod" );
		}
		else
		{
			// first round, so set up prematch
			level.prematchPeriod = maps\mp\gametypes\_tweakables::getTweakableValue( "game", "playerwaittime" );
			level.prematchPeriodEnd = maps\mp\gametypes\_tweakables::getTweakableValue( "game", "matchstarttime" );
		}
	}

	if ( !isDefined( game["status"] ) )
		game["status"] = "normal";

	makeDvarServerInfo( "ui_overtime", (game["status"] == "overtime") );

	if ( game["status"] != "overtime" && game["status"] != "halftime" )
	{
		game["teamScores"]["allies"] = 0;
		game["teamScores"]["axis"] = 0;
	}
	
	if( !isDefined( game["timePassed"] ) )
		game["timePassed"] = 0;

	if( !isDefined( game["roundsPlayed"] ) )
		game["roundsPlayed"] = 0;

	if ( !isDefined( game["roundsWon"] ) )
		game["roundsWon"] = [];

	if ( level.teamBased )
	{
		if ( !isDefined( game["roundsWon"]["axis"] ) )
			game["roundsWon"]["axis"] = 0;
		if ( !isDefined( game["roundsWon"]["allies"] ) )		
			game["roundsWon"]["allies"] = 0;
	}
	
	level.gameEnded = false;
	level.forcedEnd = false;
	level.hostForcedEnd = false;

	level.hardcoreMode = getDvarInt( "g_hardcore" );
	if ( level.hardcoreMode )
		logString( "game mode: hardcore" );

	level.dieHardMode = getDvarInt( "scr_diehard" );
	
	if ( !level.teamBased )
		level.dieHardMode = 0;

	if ( level.dieHardMode )
		logString( "game mode: diehard" );

	level.killstreakRewards = getDvarInt( "scr_game_hardpoints" );

	/#
	printLn( "SESSION INFO" );
	printLn( "=====================================" );
	printLn( "  Map:         " + level.script );
	printLn( "  Script:      " + level.gametype );
	printLn( "  HardCore:    " + level.hardcoreMode );
	printLn( "  Diehard:     " + level.dieHardMode );
	printLn( "  3rd Person:  " + getDvarInt( "camera_thirdperson" ) );
	printLn( "  Round:       " + game[ "roundsPlayed" ] );
	printLn( "  scr_" + level.gametype + "_scorelimit " + getDvar( "scr_" + level.gametype + "_scorelimit" ) );
	printLn( "  scr_" + level.gametype + "_roundlimit " +getDvar( "scr_" + level.gametype + "_roundlimit" ) );
	printLn( "  scr_" + level.gametype + "_winlimit " + getDvar( "scr_" + level.gametype + "_winlimit" ) );
	printLn( "  scr_" + level.gametype + "_timelimit " + getDvar( "scr_" + level.gametype + "_timelimit" ) );
	printLn( "  scr_" + level.gametype + "_numlives " + getDvar( "scr_" + level.gametype + "_numlives" ) );
	printLn( "  scr_" + level.gametype + "_halftime " + getDvar( "scr_" + level.gametype + "_halftime" ) );
	printLn( "  scr_" + level.gametype + "_roundswitch " + getDvar( "scr_" + level.gametype + "_roundswitch" ) );
	printLn( "=====================================" );
	#/

	// this gets set to false when someone takes damage or a gametype-specific event happens.
	level.useStartSpawns = true;

	// multiplier for score from objectives
	level.objectivePointsMod = 1;

	if ( matchMakingGame() )	
		level.maxAllowedTeamKills = 2;
	else
		level.maxAllowedTeamKills = -1;
		
	thread maps\mp\gametypes\_persistence::init();
	thread maps\mp\gametypes\_menus::init();
	thread maps\mp\gametypes\_hud::init();
	thread maps\mp\gametypes\_serversettings::init();
	thread maps\mp\gametypes\_teams::init();
	thread maps\mp\gametypes\_weapons::init();
	thread maps\mp\gametypes\_killcam::init();
	thread maps\mp\gametypes\_shellshock::init();
	thread maps\mp\gametypes\_deathicons::init();
	thread maps\mp\gametypes\_damagefeedback::init();
	thread maps\mp\gametypes\_healthoverlay::init();
	thread maps\mp\gametypes\_spectating::init();
	thread maps\mp\gametypes\_objpoints::init();
	thread maps\mp\gametypes\_gameobjects::init();
	thread maps\mp\gametypes\_spawnlogic::init();
	thread maps\mp\gametypes\_battlechatter_mp::init();
	thread maps\mp\gametypes\_music_and_dialog::init();
	thread maps\mp\_matchdata::init();
	thread maps\mp\_awards::init();
	thread maps\mp\_skill::init();
	thread maps\mp\_areas::init();
	thread maps\mp\killstreaks\_killstreaks::init();
	//thread maps\mp\_perks::init(); // No longer in use, removed from common scripts. (smart arrow)
	thread maps\mp\perks\_perks::init();
	thread maps\mp\_events::init();
	thread maps\mp\_defcon::init();
	
	level thread onPlayerConnect();
	
	if ( level.teamBased )
		thread maps\mp\gametypes\_friendicons::init();
		
	thread maps\mp\gametypes\_hud_message::init();

	if ( !level.console )
		thread maps\mp\gametypes\_quickmessages::init();

	foreach ( locString in game["strings"] )
		precacheString( locString );

	foreach ( icon in game["icons"] )
		precacheShader( icon );

	game["gamestarted"] = true;

	level.maxPlayerCount = 0;
	level.waveDelay["allies"] = 0;
	level.waveDelay["axis"] = 0;
	level.lastWave["allies"] = 0;
	level.lastWave["axis"] = 0;
	level.wavePlayerSpawnIndex["allies"] = 0;
	level.wavePlayerSpawnIndex["axis"] = 0;
	level.alivePlayers["allies"] = [];
	level.alivePlayers["axis"] = [];
	level.activePlayers = [];

	makeDvarServerInfo( "ui_scorelimit", 0 );
	makeDvarServerInfo( "ui_allow_classchange", getDvar( "ui_allow_classchange" ) );
	makeDvarServerInfo( "ui_allow_teamchange", 1 );
	setDvar( "ui_allow_teamchange", 1 );
	
	if ( getGametypeNumLives() )
		setdvar( "g_deadChat", 0 );
	else
		setdvar( "g_deadChat", 1 );
	
	waveDelay = getDvarInt( "scr_" + level.gameType + "_waverespawndelay" );
	if ( waveDelay )
	{
		level.waveDelay["allies"] = waveDelay;
		level.waveDelay["axis"] = waveDelay;
		level.lastWave["allies"] = 0;
		level.lastWave["axis"] = 0;
		
		level thread maps\mp\gametypes\_gamelogic::waveSpawnTimer();
	}
	
	gameFlagInit( "prematch_done", false );
	
	level.gracePeriod = 15;
	
	level.inGracePeriod = level.gracePeriod;
	gameFlagInit( "graceperiod_done", false );
	
	level.roundEndDelay = 4;
	level.halftimeRoundEndDelay = 4;

	
	if ( level.teamBased )
	{
		maps\mp\gametypes\_gamescore::updateTeamScore( "axis" );
		maps\mp\gametypes\_gamescore::updateTeamScore( "allies" );
	}
	else
	{
		thread maps\mp\gametypes\_gamescore::initialDMScoreUpdate();
	}

	thread updateUIScoreLimit();
	level notify ( "update_scorelimit" );

	
	[[level.onStartGameType]]();
	
	// this must be after onstartgametype for scr_showspawns to work when set at start of game
	/#
	thread maps\mp\gametypes\_dev::init();
	#/
	
	thread startGame();

	level thread updateWatchedDvars();
	level thread timeLimitThread();
	
	level thread doFinalKillcam();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player );
		
		player thread onPlayerSpawned();
		
		player thread watchIntermissionAfterConnect();
	}
}

watchIntermissionAfterConnect()
{
	self endon("disconnect");
	
	wait 0.05;
	
	self notify("kill_menus_on_connect");
	if(level.inVoting || level.inShowingWinner)
	{
		self.sessionstate = "spectator";//allow player to leave while in intermission and make voting options
		self thread watchVoting();
		
		if(level.inVoting)
		{
			self setClientDvars( "hud_ShowWinner", "0",
								   "hud_voteText", "^3Vote for new map:",
								   "vote_map", "" );
		}
		else if(level.inShowingWinner)
		{
			self setClientDvars( "hud_WinningName", "preview_" + level.votingMapsTok[ level.highestVotedMap ],
								   "hud_WinningMap", consoleMapNameToMapName( level.votingMapsTok[ level.highestVotedMap ] ),
								   "hud_voteText", "^3Next Map:",
								   "hud_ShowWinner", "1" );
		}
		
		self openPopupMenu( game["menu_vote"] );
	}
	else if(level.inIntermission)
	{
		self.sessionstate = "spectator";//allow player to leave while in intermission
		self thread openSummaryOnMenuClose();
		self openPopupMenu( game["menu_popup_summary"] );
	}
}

onPlayerSpawned()
{
	self endon("disconnect");
	self.printDamage = false;
	firstTime = false;
	for(;;)
	{
		self waittill("spawned_player");
		if( !firstTime && level.allowPrintDamage )
		{
			firstTime = true;
			self iPrintlnBold( "^7Press ^3[{+actionslot 2}] ^7to toggle ^3Print Damage" );
		}
		self thread printDamage();
	}
}

printDamage()
{
	if( !level.allowPrintDamage )
		return;
	
	self endon("disconnect");
	self endon("death");
	
	self notifyOnPlayerCommand("printDamage", "+actionslot 2");
	for(;;)
	{
		self waittill("printDamage");
		self playLocalSound( "semtex_warning" );
		if(self.printDamage)
		{
			self iPrintlnBold("^7Print Damage ^1Disabled");
			self.printDamage = false;
		}
		else
		{
			self iPrintlnBold("^7Print Damage ^1Enabled");
			self.printDamage = true;
		}
	}
}


Callback_CodeEndGame()
{
	endparty();

	if ( !level.gameEnded )
		level thread maps\mp\gametypes\_gamelogic::forceEnd();
}


timeLimitThread()
{
	level endon ( "game_ended" );
	
	prevTimePassed = getTimePassed();
	
	while ( game["state"] == "playing" )
	{
		thread checkTimeLimit( prevTimePassed );
		prevTimePassed = getTimePassed();
		
		// make sure we check time limit right when game ends
		if ( isdefined( level.startTime ) )
		{
			if ( getTimeRemaining() < 3000 )
			{
				wait .1;
				continue;
			}
		}
		wait 1;
	}	
}


updateUIScoreLimit()
{
	for ( ;; )
	{
		level waittill_either ( "update_scorelimit", "update_winlimit" );
		
		if ( !isRoundBased() || !isObjectiveBased() )
		{
			setDvar( "ui_scorelimit", getWatchedDvar( "scorelimit" ) );
			thread checkScoreLimit();
		}
		else
		{
			setDvar( "ui_scorelimit", getWatchedDvar( "winlimit" ) );
		}
	}
}


playTickingSound()
{
	self endon("death");
	self endon("stop_ticking");
	level endon("game_ended");
	
	time = level.bombTimer;
	
	while(1)
	{
		self playSound( "ui_mp_suitcasebomb_timer" );
		
		if ( time > 10 )
		{
			time -= 1;
			wait 1;
		}
		else if ( time > 4 )
		{
			time -= .5;
			wait .5;
		}
		else if ( time > 1 )
		{
			time -= .4;
			wait .4;
		}
		else
		{
			time -= .3;
			wait .3;
		}
		maps\mp\gametypes\_hostmigration::waitTillHostMigrationDone();
	}
}

stopTickingSound()
{
	self notify("stop_ticking");
}

timeLimitClock()
{
	level endon ( "game_ended" );
	
	wait .05;
	
	clockObject = spawn( "script_origin", (0,0,0) );
	clockObject hide();
	
	while ( game["state"] == "playing" )
	{
		if ( !level.timerStopped && getTimeLimit() )
		{
			timeLeft = getTimeRemaining() / 1000;
			timeLeftInt = int(timeLeft + 0.5); // adding .5 and flooring rounds it.
			
			if ( getHalfTime() && timeLeftInt > (getTimeLimit()*60) * 0.5 )
				timeLeftInt -= int((getTimeLimit()*60) * 0.5);
			
			if ( (timeLeftInt >= 30 && timeLeftInt <= 60) )
				level notify ( "match_ending_soon", "time" );

			if ( timeLeftInt <= 10 || (timeLeftInt <= 30 && timeLeftInt % 2 == 0) )
			{
				level notify ( "match_ending_very_soon" );
				// don't play a tick at exactly 0 seconds, that's when something should be happening!
				if ( timeLeftInt == 0 )
					break;
				
				clockObject playSound( "ui_mp_timer_countdown" );
			}
			
			// synchronize to be exactly on the second
			if ( timeLeft - floor(timeLeft) >= .05 )
				wait timeLeft - floor(timeLeft);
		}

		wait ( 1.0 );
	}
}


gameTimer()
{
	level endon ( "game_ended" );
	
	level waittill("prematch_over");
	
	level.startTime = getTime();
	level.discardTime = 0;
	
	if ( isDefined( game["roundMillisecondsAlreadyPassed"] ) )
	{
		level.startTime -= game["roundMillisecondsAlreadyPassed"];
		game["roundMillisecondsAlreadyPassed"] = undefined;
	}
	
	prevtime = gettime();
	
	while ( game["state"] == "playing" )
	{
		if ( !level.timerStopped )
		{
			// the wait isn't always exactly 1 second. dunno why.
			game["timePassed"] += gettime() - prevtime;
		}
		prevtime = gettime();
		wait ( 1.0 );
	}
}

UpdateTimerPausedness()
{
	shouldBeStopped = level.timerStoppedForGameMode || isDefined( level.hostMigrationTimer );
	if ( !gameFlag( "prematch_done" ) )
		shouldBeStopped = false;
	
	if ( !level.timerStopped && shouldBeStopped )
	{
		level.timerStopped = true;
		level.timerPauseTime = gettime();
	}
	else if ( level.timerStopped && !shouldBeStopped )
	{
		level.timerStopped = false;
		level.discardTime += gettime() - level.timerPauseTime;
	}
}

pauseTimer()
{
	level.timerStoppedForGameMode = true;
	UpdateTimerPausedness();
}

resumeTimer()
{
	level.timerStoppedForGameMode = false;
	UpdateTimerPausedness();
}


startGame()
{
	thread gameTimer();
	level.timerStopped = false;
	level.timerStoppedForGameMode = false;
	thread maps\mp\gametypes\_spawnlogic::spawnPerFrameUpdate();

	prematchPeriod();
	gameFlagSet( "prematch_done" );	
	level notify("prematch_over");
	
	UpdateTimerPausedness();
	
	thread timeLimitClock();
	thread gracePeriod();

	thread maps\mp\gametypes\_missions::roundBegin();	
}


waveSpawnTimer()
{
	level endon( "game_ended" );

	while ( game["state"] == "playing" )
	{
		time = getTime();
		
		if ( time - level.lastWave["allies"] > (level.waveDelay["allies"] * 1000) )
		{
			level notify ( "wave_respawn_allies" );
			level.lastWave["allies"] = time;
			level.wavePlayerSpawnIndex["allies"] = 0;
		}

		if ( time - level.lastWave["axis"] > (level.waveDelay["axis"] * 1000) )
		{
			level notify ( "wave_respawn_axis" );
			level.lastWave["axis"] = time;
			level.wavePlayerSpawnIndex["axis"] = 0;
		}
		
		wait ( 0.05 );
	}
}


getBetterTeam()
{
	kills["allies"] = 0;
	kills["axis"] = 0;
	deaths["allies"] = 0;
	deaths["axis"] = 0;
	
	foreach ( player in level.players )
	{
		team = player.pers["team"];
		if ( isDefined( team ) && (team == "allies" || team == "axis") )
		{
			kills[ team ] += player.kills;
			deaths[ team ] += player.deaths;
		}
	}
	
	if ( kills["allies"] > kills["axis"] )
		return "allies";
	else if ( kills["axis"] > kills["allies"] )
		return "axis";
	
	// same number of kills

	if ( deaths["allies"] < deaths["axis"] )
		return "allies";
	else if ( deaths["axis"] < deaths["allies"] )
		return "axis";
	
	// same number of deaths
	
	if ( randomint(2) == 0 )
		return "allies";
	return "axis";
}


rankedMatchUpdates( winner )
{
	//if ( matchMakingGame() )
	//{
		setXenonRanks();
		
		//if ( hostIdledOut() )
		//{
		//	level.hostForcedEnd = true;
		//	logString( "host idled out" );
		//	endLobby();
		//}

		updateMatchBonusScores( winner );
	//}

	updateWinLossStats( winner );
}


displayRoundEnd( winner, endReasonText )
{
	foreach ( player in level.players )
	{
		if ( isDefined( player.connectedPostGame ) || player.pers["team"] == "spectator" )
			continue;
		
		if ( level.teamBased )
			player thread maps\mp\gametypes\_hud_message::teamOutcomeNotify( winner, true, endReasonText );
		else
			player thread maps\mp\gametypes\_hud_message::outcomeNotify( winner, endReasonText );
	}

	if ( !wasLastRound() )
		level notify ( "round_win", winner );
	
	if ( wasLastRound() )
		roundEndWait( level.roundEndDelay, false );
	else
		roundEndWait( level.roundEndDelay, true );	
}


displayGameEnd( winner, endReasonText )
{	
	// catching gametype, since DM forceEnd sends winner as player entity, instead of string
	foreach ( player in level.players )
	{
		if ( isDefined( player.connectedPostGame ) || player.pers["team"] == "spectator" )
			continue;
		
		if ( level.teamBased )
			player thread maps\mp\gametypes\_hud_message::teamOutcomeNotify( winner, false, endReasonText );
		else
			player thread maps\mp\gametypes\_hud_message::outcomeNotify( winner, endReasonText );
	}
	
	level notify ( "game_win", winner );
	
	roundEndWait( level.postRoundTime, true );
}


displayRoundSwitch()
{
	switchType = level.halftimeType;
	if ( switchType == "halftime" )
	{
		if ( getWatchedDvar( "roundlimit" ) )
		{
			if ( (game["roundsPlayed"] * 2) == getWatchedDvar( "roundlimit" ) )
				switchType = "halftime";
			else
				switchType = "intermission";
		}
		else if ( getWatchedDvar( "winlimit" ) )
		{
			if ( game["roundsPlayed"] == (getWatchedDvar( "winlimit" ) - 1) )
				switchType = "halftime";
			else
				switchType = "intermission";
		}
		else
		{
			switchType = "intermission";
		}
	}

	level notify ( "round_switch", switchType );

	foreach ( player in level.players )
	{
		if ( isDefined( player.connectedPostGame ) || player.pers["team"] == "spectator" )
			continue;
		
		player thread maps\mp\gametypes\_hud_message::teamOutcomeNotify( switchType, true, level.halftimeSubCaption );
	}
	
	roundEndWait( level.halftimeRoundEndDelay, false );
}


endGameOvertime( winner, endReasonText )
{
	visionSetNaked( "mpOutro", 0.5 );		
	setDvar( "scr_gameended", 2 );
	// freeze players
	foreach ( player in level.players )
	{
		player thread freezePlayerForRoundEnd( 0 );
		player thread roundEndDoF( 4.0 );
		
		player freeGameplayHudElems();

		player setClientDvars( "cg_everyoneHearsEveryone", 1 );
		player setClientDvars( "cg_drawSpectatorMessages", 0,
							   "g_compassShowEnemies", 0 );
							   
		if ( player.pers["team"] == "spectator" )
			player thread maps\mp\gametypes\_playerlogic::spawnIntermission();
	}

	level notify ( "round_switch", "overtime" );

	// catching gametype, since DM forceEnd sends winner as player entity, instead of string
	foreach ( player in level.players )
	{
		if ( isDefined( player.connectedPostGame ) || player.pers["team"] == "spectator" )
			continue;
		
		if ( level.teamBased )
			player thread maps\mp\gametypes\_hud_message::teamOutcomeNotify( winner, false, endReasonText );
		else
			player thread maps\mp\gametypes\_hud_message::outcomeNotify( winner, endReasonText );
	}
	
	roundEndWait( level.roundEndDelay, false );
	
	if ( level.forceFinalKillcam )
		waittillFinalKillcamDone();

	game["status"] = "overtime";
	level notify ( "restarting" );
    game["state"] = "playing";
    map_restart( true );
}



endGameHalfTime()
{
	visionSetNaked( "mpOutro", 0.5 );		
	setDvar( "scr_gameended", 2 );

	game["switchedsides"] = !game["switchedsides"];

	// freeze players
	foreach ( player in level.players )
	{
		player thread freezePlayerForRoundEnd( 0 );
		player thread roundEndDoF( 4.0 );
		
		player freeGameplayHudElems();

		player setClientDvars( "cg_everyoneHearsEveryone", 1 );
		player setClientDvars( "cg_drawSpectatorMessages", 0,
							   "g_compassShowEnemies", 0 );
							   
		if ( player.pers["team"] == "spectator" )
			player thread maps\mp\gametypes\_playerlogic::spawnIntermission();
	}

	foreach ( player in level.players )
		player.pers["stats"] = player.stats;

	level notify ( "round_switch", "halftime" );
		
	foreach ( player in level.players )
	{
		if ( isDefined( player.connectedPostGame ) || player.pers["team"] == "spectator" )
			continue;

		player thread maps\mp\gametypes\_hud_message::teamOutcomeNotify( "halftime", true, level.halftimeSubCaption );
	}
	
	roundEndWait( level.roundEndDelay, false );
	
	if ( level.forceFinalKillcam )
		waittillFinalKillcamDone();

	game["status"] = "halftime";
	level notify ( "restarting" );
    game["state"] = "playing";
    map_restart( true );
}


endGame( winner, endReasonText, nukeDetonated )
{
	if( !level.forceFinalKillcamWinnersKill || !isDefined( winner ) || !isString( winner ) || ( winner != "axis" && winner != "allies" ) )
		level.finalKillCam_winner = "none";
	else
		level.finalKillCam_winner = winner;
	
	if ( !isDefined(nukeDetonated) )
		nukeDetonated = false;
	
	// return if already ending via host quit or victory, or nuke incoming
	if ( game["state"] == "postgame" || level.gameEnded || (isDefined(level.nukeIncoming) && !nukeDetonated) && ( !isDefined( level.gtnw ) || !level.gtnw ) )
		return;

	game["state"] = "postgame";

	level.gameEndTime = getTime();
	level.gameEnded = true;
	level.inGracePeriod = false;
	level notify ( "game_ended", winner );
	levelFlagSet( "game_over" );
	levelFlagSet( "block_notifies" );
	waitframe(); // give "game_ended" notifies time to process
	
	setGameEndTime( 0 ); // stop/hide the timers
	
	maps\mp\gametypes\_playerlogic::printPredictedSpawnpointCorrectness();
	
	if ( isDefined( winner ) && isString( winner ) && winner == "overtime" )
	{
		endGameOvertime( winner, endReasonText );
		return;
	}
	
	if ( isDefined( winner ) && isString( winner ) && winner == "halftime" )
	{
		endGameHalftime();
		return;
	}

	game["roundsPlayed"]++;
	
	if ( level.teamBased )
	{
		if ( winner == "axis" || winner == "allies" )
			game["roundsWon"][winner]++;

		maps\mp\gametypes\_gamescore::updateTeamScore( "axis" );
		maps\mp\gametypes\_gamescore::updateTeamScore( "allies" );
	}
	else
	{
		if ( isDefined( winner ) && isPlayer( winner ) )
			game["roundsWon"][winner.guid]++;
	}
	
	maps\mp\gametypes\_gamescore::updatePlacement();

	rankedMatchUpdates( winner );

	foreach ( player in level.players )
	{
		player setClientDvar( "ui_opensummary", 1 );
	}
	
	setDvar( "g_deadChat", 1 );
	setDvar( "ui_allow_teamchange", 0 );

	// freeze players
	foreach ( player in level.players )
	{
		player thread freezePlayerForRoundEnd( 1.0 );
		player thread roundEndDoF( 4.0 );
		
		player freeGameplayHudElems();

		player setClientDvars( "cg_everyoneHearsEveryone", 1 );
		player setClientDvars( "cg_drawSpectatorMessages", 0,
							   "g_compassShowEnemies", 0 );
							   
		if ( player.pers["team"] == "spectator" )
			player thread maps\mp\gametypes\_playerlogic::spawnIntermission();
	}

	if( !nukeDetonated )
		visionSetNaked( "mpOutro", 0.5 );		
	
	// End of Round
	if ( !wasOnlyRound() && !nukeDetonated )
	{
		setDvar( "scr_gameended", 2 );
	
		displayRoundEnd( winner, endReasonText );

		if ( level.forceFinalKillcam )
		{
			waittillFinalKillcamDone();
		}
		else
		{
			if ( level.showingFinalKillcam )
			{
				foreach ( player in level.players )
					player notify ( "reset_outcome" );

				level notify ( "game_cleanup" );

				waittillFinalKillcamDone();
			}
		}
				
		if ( !wasLastRound() )
		{
			levelFlagClear( "block_notifies" );
			if ( checkRoundSwitch() )
				displayRoundSwitch();

			foreach ( player in level.players )
				player.pers["stats"] = player.stats;

        	level notify ( "restarting" );
            game["state"] = "playing";
            map_restart( true );
            return;
		}
		
		if ( !level.forcedEnd )
			endReasonText = updateEndReasonText( winner );
	}

	setDvar( "scr_gameended", 1 );
	
	if ( !isDefined( game["clientMatchDataDef"] ) )
	{
		game["clientMatchDataDef"] = "mp/clientmatchdata.def";
		setClientMatchDataDef( game["clientMatchDataDef"] );
	}

	maps\mp\gametypes\_missions::roundEnd( winner );

	if( isRoundBased() )    
        winner = getWinningTeam();

	displayGameEnd( winner, endReasonText );

	if( wasOnlyRound() )
	{
		if ( level.forceFinalKillcam )
		{
			waittillFinalKillcamDone();
		}
		else
		{
			if ( level.showingFinalKillcam )
			{
				foreach ( player in level.players )
					player notify ( "reset_outcome" );

				level notify ( "game_cleanup" );

				waittillFinalKillcamDone();
			}
		}
	}

	levelFlagClear( "block_notifies" );

	level.intermission = true;

	level notify ( "spawning_intermission" );
	
	foreach ( player in level.players )
	{
		player closepopupMenu();
		player closeInGameMenu();
		player notify ( "reset_outcome" );
		player thread maps\mp\gametypes\_playerlogic::spawnIntermission();
	}

	processLobbyData();

	wait ( 1.0 );

	if ( matchMakingGame() )
		sendMatchData();

	foreach ( player in level.players )
		player.pers["stats"] = player.stats;

	//logString( "game ended" );
	if( !nukeDetonated && !level.postGameNotifies )
	{
		if ( !wasOnlyRound() )
			wait 6.0;
		else
			wait 3.0;
	}
	else
	{
		wait ( min( 10.0, 4.0 + level.postGameNotifies ) );
	}
	
	if ( level.voting && level.voteTime > 0.0 && level.votingMapsTok.size )
	{
		level.inVoting = true;
		foreach (player in level.players)
		{
			player.sessionstate = "spectator";//allow player to leave while in intermission and make voting options
			player thread watchVoting();
			
			player setClientDvars( "hud_ShowWinner", "0",
								   "hud_voteText", "^3Vote for new map:",
								   "vote_map", "" );
			
			player openPopupMenu( game["menu_vote"] );
		}

		level thread doBotVoting();
		thread timeLimitClock_Intermission( level.voteTime, (84.7, 100, 0) );
		wait level.voteTime;
		level.inVoting = false;
		
		level.highestVotedMap = getHighestVotedMap();
		
		if ( level.voteWinTime > 0.0 )
		{
			level.inShowingWinner = true;
			foreach (player in level.players)
			{
				player setClientDvars( "hud_WinningName", "preview_" + level.votingMapsTok[ level.highestVotedMap ],
									   "hud_WinningMap", consoleMapNameToMapName( level.votingMapsTok[ level.highestVotedMap ] ),
									   "hud_voteText", "^3Next Map:",
									   "hud_ShowWinner", "1" );
			}
			
			thread timeLimitClock_Intermission( level.voteWinTime, (84.7, 100, 0) );
			wait level.voteWinTime;
			level.inShowingWinner = false;
		}
		
		foreach (player in level.players)
			player closeMenu( game["menu_vote"] );
			
		level notify( "voting_finished" );
		
		level setVoteVars( level.highestVotedMap );
	}
	
	if ( level.allowIntermission && level.intermissionTime > 0.0 )
	{
		level.inIntermission = true;
		foreach (player in level.players)
		{
			player.sessionstate = "spectator";//allow player to leave while in intermission
			player thread openSummaryOnMenuClose();
			player openPopupMenu( game["menu_popup_summary"] );
		}
		
		thread timeLimitClock_Intermission( level.intermissionTime );
		wait level.intermissionTime;
		level.inIntermission = false;
		
		level notify( "intermission_finished" );
	}
	
	level notify( "exitLevel_called" );
	exitLevel( false );
}

setVoteVars( highestVotedMap )
{
	setDvar( "sv_maprotation", "map " + level.votingMapsTok[ highestVotedMap ] );
	setDvar( "sv_maprotationCurrent", "map " + level.votingMapsTok[ highestVotedMap ] );
}

getHighestVotedMap()
{
	highest = 0;
	for( i = 0; i < level.mapVotes.size; i++ )
		if( level.mapVotes[ i ] > highest && i < 9 )
			highest = level.mapVotes[ i ];
	
	votes = [];
	for( i = 0; i < level.mapVotes.size; i++ )
		if( level.mapVotes[ i ] == highest && i < 9 )
			votes[votes.size] = i;
	
	if ( votes.size )
		return votes[ randomInt( votes.size ) ];
	else if ( level.mapVotes.size > 9 )
		return randomIntRange( 0, 8 );
	else
		return randomInt( level.mapVotes.size );
}

doBotVoting()
{
	if(!level.botsVote)
		return;
	
	level endon("voting_finished");
	
	bots = [];
	
	foreach(player in level.players)
	{
		if(!isDefined(player.pers["isBot"]) || !player.pers["isBot"])
			continue;
		
		player.botWillVoteFor = bots.size;
		bots[bots.size] = player;
	}
	
	while(bots.size)
	{
		wait 0.05;
		bot = bots[randomInt(bots.size)];
		if(!bot.hasVoted)
		{
			bot castMap(bot.botWillVoteFor);
			wait randomInt(3);
		}
	}
}

ridVoteOnDisconnect()
{
	level endon("voting_finished");
	
	self waittill_either( "disconnect", "kill_menus_on_connect" );
	
	if ( self.votedNum > -1 ) 
		level.mapVotes[ self.votedNum ]--;
}

updateVoteMenu()
{
	self endon("disconnect");
	self endon("kill_menus_on_connect");
	level endon("voting_finished");
	
	for(i = 0; i < 9; i++) 
	{
		if( i >= level.votingMapsTok.size )
		{
			self setClientDvar( "hud_picName" + i, "white" );
		}
		else
		{
			self setClientDvars( "hud_mapName" + i, consoleMapNameToMapName( level.votingMapsTok[ i ] ),
								 "hud_mapVotes" + i, level.mapVotes[ i ],
								 "hud_picName" + i, "preview_" + level.votingMapsTok[ i ] );
		}
	}
	
	for(;;)
	{
		wait 0.5;
		
		for( i = 0; i < level.votingMapsTok.size; i++ )
			self setClientDvar( "hud_mapVotes" + i, level.mapVotes[ i ] );
		
		highestVotedMap = getHighestVotedMap();
		self setClientDvars( "hud_gamesize", level.players.size,
							 "hud_mapVotes" + highestVotedMap, "^3" + level.mapVotes[ highestVotedMap ] );
	}
}

watchVoting()
{
	self endon("disconnect");
	self endon("kill_menus_on_connect");
	level endon("voting_finished");
	
	self thread ridVoteOnDisconnect();
	self thread updateVoteMenu();
	
	self.hasVoted = false;
	self.votedNum = -1;
	
	for(;;)
	{
		self waittill("menuresponse", menu, response);
		
		if( menu == game["menu_vote"] )
		{
			switch(response)
			{
				case "map1":
					self castMap(0);
					break;
				case "map2":
					self castMap(1);
					break;
				case "map3":
					self castMap(2);
					break;
				case "map4":
					self castMap(3);
					break;
				case "map5":
					self castMap(4);
					break;
				case "map6":
					self castMap(5);
					break;
				case "map7":
					self castMap(6);
					break;
				case "map8":
					self castMap(7);
					break;
				case "map9":
					self castMap(8);
					break;
				default:
					break;
			}
		}
		else if ( response == "back" )
		{
			self closepopupMenu();
			self closeInGameMenu();
			wait 0.25;
			self openPopupMenu( game["menu_vote"] );
			continue;
		}
	}
}

castMap( number )
{
	if ( !isDefined( level.votingMapsTok[ number ] ) || level.votingMapsTok[ number ] == "" )
	{
		if ( self.hasVoted )
		{
			self.hasVoted = false;
			level.mapVotes[ self.votedNum ]--;
			self.votedNum = -1;
		}
		self iprintln( "Invalid map selection" );
		return;
	}
	
	if( !self.hasVoted )
	{
		self.hasVoted = true;
		level.mapVotes[ number ]++;
		self.votedNum = number;
		self iprintln( "You voted for ^3" + consoleMapNameToMapName( level.votingMapsTok[ number ] ) );
	}
	else if( self.votedNum != number )
	{
		level.mapVotes[ self.votedNum ]--;
		level.mapVotes[ number ]++;
		self.votedNum = number;
		self iprintln( "You ^3re-voted ^7for ^3" + consoleMapNameToMapName( level.votingMapsTok[ number ] ) );
	}
}

consoleMapNameToMapName(mapname)
{
  switch(mapname)
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
		default:
			return mapname;
	}
}

openSummaryOnMenuClose()
{
	self endon("disconnect");
	self endon("kill_menus_on_connect");
	level endon("intermission_finished");
	
	for(;;)
	{
		self waittill("menuresponse", menu, response);
		
		if ( response == "back" && menu != game["menu_popup_summary"] )
		{
			self closepopupMenu();
			self closeInGameMenu();
			wait 0.25;
			self openPopupMenu( game["menu_popup_summary"] );
			continue;
		}
	}
}

updateEndReasonText( winner )
{
	if ( !level.teamBased )
		return true;

	if ( hitRoundLimit() )
		return &"MP_ROUND_LIMIT_REACHED";
	
	if ( hitWinLimit() )
		return &"MP_SCORE_LIMIT_REACHED";
	
	if ( winner == "axis" )
		return &"SPETSNAZ_WIN";
	else
		return &"SAS_WIN";
}

estimatedTimeTillScoreLimit( team )
{
	assert( isPlayer( self ) || isDefined( team ) );

	scorePerMinute = getScorePerMinute( team );
	scoreRemaining = getScoreRemaining( team );

	estimatedTimeLeft = 999999;
	if ( scorePerMinute )
		estimatedTimeLeft = scoreRemaining / scorePerMinute;
	
	//println( "estimatedTimeLeft: " + estimatedTimeLeft );
	return estimatedTimeLeft;
}

getScorePerMinute( team )
{
	assert( isPlayer( self ) || isDefined( team ) );

	scoreLimit = getWatchedDvar( "scorelimit" );
	timeLimit = getTimeLimit();
	minutesPassed = (getTimePassed() / (60*1000)) + 0.0001;

	if ( isPlayer( self ) )
		scorePerMinute = self.score / minutesPassed;
	else
		scorePerMinute = getTeamScore( team ) / minutesPassed;
		
	return scorePerMinute;
}

getScoreRemaining( team )
{
	assert( isPlayer( self ) || isDefined( team ) );

	scoreLimit = getWatchedDvar( "scorelimit" );

	if ( isPlayer( self ) )
		scoreRemaining = scoreLimit - self.score;
	else
		scoreRemaining = scoreLimit - getTeamScore( team );
		
	return scoreRemaining;
}

giveLastOnTeamWarning()
{
	self endon("death");
	self endon("disconnect");
	level endon( "game_ended" );

	self waitTillRecoveredHealth( 3 );

	otherTeam = getOtherTeam( self.pers["team"] );
	thread teamPlayerCardSplash( "callout_lastteammemberalive", self, self.pers["team"] );
	thread teamPlayerCardSplash( "callout_lastenemyalive", self, otherTeam );
	level notify ( "last_alive", self );
}

processLobbyData()
{
	curPlayer = 0;
	foreach ( player in level.players )
	{
		if ( !isDefined( player ) )
			continue;

		player.clientMatchDataId = curPlayer;
		curPlayer++;

		// on PS3 cap long names
		if ( level.ps3 && (player.name.size > level.MaxNameLength) )
		{
			playerName = "";
			for ( i = 0; i < level.MaxNameLength-3; i++ )
				playerName += player.name[i];

			playerName += "...";
		}
		else
		{
			playerName = player.name;
		}
		
		setClientMatchData( "players", player.clientMatchDataId, "xuid", playerName );		
	}
	
	maps\mp\_awards::assignAwards();
	maps\mp\_scoreboard::processLobbyScoreboards();
	
	sendClientMatchData();
}

getWinningTeam()
{
	if ( game["roundsWon"]["allies"] == game["roundsWon"]["axis"] )
			winner = "tie";
	else if ( game["roundsWon"]["axis"] > game["roundsWon"]["allies"] )
			winner = "axis";
	else
			winner = "allies";

	return winner;
}

doFinalKillCam()
{	
	level waittill ( "round_end_finished" );

	winner = level.finalKillCam_winner; // we want to show the winner's final kill cam
	delay = level.finalKillCam_delay[ winner ];
	victim = level.finalKillCam_victim[ winner ];
	attacker = level.finalKillCam_attacker[ winner ];
	attackerNum = level.finalKillCam_attackerNum[ winner ];
	killCamEntityIndex = level.finalKillCam_killCamEntityIndex[ winner ];
	killCamEntityStartTime = level.finalKillCam_killCamEntityStartTime[ winner ];
	sWeapon = level.finalKillCam_sWeapon[ winner ];
	deathTimeOffset = level.finalKillCam_deathTimeOffset[ winner ];
	psOffsetTime = level.finalKillCam_psOffsetTime[ winner ];
	timeRecorded = level.finalKillCam_timeRecorded[ winner ]/1000;
	timeGameEnded = level.gameEndTime/1000;

	if( !isDefined( victim ) || !isDefined( attacker ) )
		return;
	
	if( !level.forceFinalKillcam || !level.allowFinalKillcam )
		return;

	// if the killcam happened longer than 15 seconds ago, don't show it
	killCamBufferTime = 15;
	killCamOffsetTime = timeGameEnded - timeRecorded;
	
	if( killCamOffsetTime > killCamBufferTime )
		return;
	
	level.showingFinalKillcam = true;

	if ( isDefined( attacker ) )
	{
		maps\mp\_awards::addAwardWinner( "finalkill", attacker.clientid );
		attacker.finalKill = true;
	}

	postDeathDelay = (( getTime() - victim.deathTime ) / 1000);
	
	foreach ( player in level.players )
	{
		player closePopupMenu();
		player closeInGameMenu();
		
		if( isDefined( level.nukeDetonated ) )
			player VisionSetNakedForPlayer( "mpnuke_aftermath", 0 );
		else
			player VisionSetNakedForPlayer( getMapVision(), 0 );
		
		player.killcamentitylookat = victim getEntityNumber();
		
		if ( (player != victim || (!isRoundBased() || isLastRound())) && player _hasPerk( "specialty_copycat" ) )
			player _unsetPerk( "specialty_copycat" );
		
		player thread maps\mp\gametypes\_killcam::killcam( attackerNum, killcamentityindex, killcamentitystarttime, sWeapon, postDeathDelay + deathTimeOffset, psOffsetTime, 0, 10000, attacker, victim );
	}

	wait( 0.1 );

	while ( maps\mp\gametypes\_damage::anyPlayersInKillcam() )
		wait( 0.05 );
	
	level.showingFinalKillcam = false;
}

recordFinalKillCam( delay, victim, attacker, attackerNum, killCamEntityIndex, killCamEntityStartTime, sWeapon, deathTimeOffset, psOffsetTime )
{
	teams[0] = "none"; // none gets filled just in case we need something without a team or this is ffa
	
	if( level.teambased && IsDefined( attacker.team ) )
		teams[1] = attacker.team; // we want to save each team seperately so we can show the winning team's kill when applicable
	
	for( i = 0; i < teams.size; i++ )
	{
		team = teams[i];
		
		level.finalKillCam_delay[ team ]					= delay;
		level.finalKillCam_victim[ team ]					= victim;
		level.finalKillCam_attacker[ team ]				    = attacker;
		level.finalKillCam_attackerNum[ team ]			    = attackerNum;
		level.finalKillCam_killCamEntityIndex[ team ]		= killCamEntityIndex;
		level.finalKillCam_killCamEntityStartTime[ team ]	= killCamEntityStartTime;
		level.finalKillCam_sWeapon[ team ]					= sWeapon;
		level.finalKillCam_deathTimeOffset[ team ]			= deathTimeOffset;
		level.finalKillCam_psOffsetTime[ team ]				= psOffsetTime;
		level.finalKillCam_timeRecorded[ team ]				= getTime();
	}
}
