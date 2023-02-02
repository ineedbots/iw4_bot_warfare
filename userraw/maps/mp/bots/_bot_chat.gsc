/*
	_bot_chat
	Author: INeedGames
	Date: 04/17/2022
	Does bot chatter.
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;
#include maps\mp\bots\_bot_language_en;

/*
	Init
*/
init()
{
	if ( getDvar( "bots_main_chat" ) == "" )
		setDvar( "bots_main_chat", 1.0 );

	level thread onBotConnected();
}

/*
	Bot connected
*/
onBotConnected()
{
	for ( ;; )
	{
		level waittill( "bot_connected", bot );

		bot thread start_chat_threads();
	}
}

/*
	Does the chatter
*/
BotDoChat( chance, string, isTeam )
{
	mod = getDvarFloat( "bots_main_chat" );

	if ( mod <= 0.0 )
		return;

	if ( chance >= 100 || mod >= 100.0 ||
	    ( RandomInt( 100 ) < ( chance * mod ) + 0 ) )
	{
		if ( isDefined( isTeam ) && isTeam )
			self sayteam( string );
		else
			self sayall( string );
	}
}

/*
	Threads for bots
*/
start_chat_threads()
{
	self endon( "disconnect" );

	self thread start_onnuke_call();
	self thread start_random_chat();
	self thread start_chat_watch();
	self thread start_killed_watch();
	self thread start_death_watch();
	self thread start_endgame_watch();

	self thread start_startgame_watch();
}

/*
	Nuke gets called
*/
start_onnuke_call()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		while ( !isDefined( level.nukeIncoming ) && !isDefined( level.moabIncoming ) )
			wait 0.05 + randomInt( 4 );

		self thread bot_onnukecall_watch();

		wait level.nukeTimer + 5;
	}
}

/*
	death
*/
start_death_watch()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "death" );

		self thread bot_chat_death_watch( self.lastAttacker, self.bots_lastKS );

		self.bots_lastKS = 0;
	}
}

/*
	start_endgame_watch
*/
start_endgame_watch()
{
	self endon( "disconnect" );

	level waittill ( "game_ended" );

	self thread endgame_chat();
}

/*
	Random chatting
*/
start_random_chat()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		wait 1;

		if ( randomInt( 100 ) < 1 )
		{
			if ( randomInt( 100 ) < 1 && isReallyAlive( self ) )
				self thread doQuickMessage();
		}
	}
}

/*
	Got a kill
*/
start_killed_watch()
{
	self endon( "disconnect" );

	self.bots_lastKS = 0;

	for ( ;; )
	{
		self waittill( "killed_enemy" );

		if ( self.bots_lastKS < self.pers["cur_kill_streak"] )
		{
			for ( i = self.bots_lastKS + 1; i <= self.pers["cur_kill_streak"]; i++ )
			{
				self thread bot_chat_streak( i );
			}
		}

		self.bots_lastKS = self.pers["cur_kill_streak"];

		self thread bot_chat_killed_watch( self.lastKilledPlayer );
	}
}

/*
	Starts things for the bot
*/
start_chat_watch()
{
	self endon( "disconnect" );
	level endon ( "game_ended" );

	for ( ;; )
	{
		self waittill( "bot_event", msg, a, b, c, d, e, f, g );

		switch ( msg )
		{
			case "revive":
				self thread bot_chat_revive_watch( a, b, c, d, e, f, g );
				break;

			case "killcam":
				self thread bot_chat_killcam_watch( a, b, c, d, e, f, g );
				break;

			case "stuck":
				self thread bot_chat_stuck_watch( a, b, c, d, e, f, g );
				break;

			case "tube":
				self thread bot_chat_tube_watch( a, b, c, d, e, f, g );
				break;

			case "killstreak":
				self thread bot_chat_killstreak_watch( a, b, c, d, e, f, g );
				break;

			case "crate_cap":
				self thread bot_chat_crate_cap_watch( a, b, c, d, e, f, g );
				break;

			case "attack_vehicle":
				self thread bot_chat_attack_vehicle_watch( a, b, c, d, e, f, g );
				break;

			case "follow_threat":
				self thread bot_chat_follow_threat_watch( a, b, c, d, e, f, g );
				break;

			case "camp":
				self thread bot_chat_camp_watch( a, b, c, d, e, f, g );
				break;

			case "follow":
				self thread bot_chat_follow_watch( a, b, c, d, e, f, g );
				break;

			case "equ":
				self thread bot_chat_equ_watch( a, b, c, d, e, f, g );
				break;

			case "nade":
				self thread bot_chat_nade_watch( a, b, c, d, e, f, g );
				break;

			case "jav":
				self thread bot_chat_jav_watch( a, b, c, d, e, f, g );
				break;

			case "throwback":
				self thread bot_chat_throwback_watch( a, b, c, d, e, f, g );
				break;

			case "rage":
				self thread bot_chat_rage_watch( a, b, c, d, e, f, g );
				break;

			case "tbag":
				self thread bot_chat_tbag_watch( a, b, c, d, e, f, g );
				break;

			case "revenge":
				self thread bot_chat_revenge_watch( a, b, c, d, e, f, g );
				break;

			case "heard_target":
				self thread bot_chat_heard_target_watch( a, b, c, d, e, f, g );
				break;

			case "uav_target":
				self thread bot_chat_uav_target_watch( a, b, c, d, e, f, g );
				break;

			case "attack_equ":
				self thread bot_chat_attack_equ_watch( a, b, c, d, e, f, g );
				break;

			case "turret_attack":
				self thread bot_chat_turret_attack_watch( a, b, c, d, e, f, g );
				break;

			case "dom":
				self thread bot_chat_dom_watch( a, b, c, d, e, f, g );
				break;

			case "hq":
				self thread bot_chat_hq_watch( a, b, c, d, e, f, g );
				break;

			case "sab":
				self thread bot_chat_sab_watch( a, b, c, d, e, f, g );
				break;

			case "sd":
				self thread bot_chat_sd_watch( a, b, c, d, e, f, g );
				break;

			case "cap":
				self thread bot_chat_cap_watch( a, b, c, d, e, f, g );
				break;

			case "dem":
				self thread bot_chat_dem_watch( a, b, c, d, e, f, g );
				break;

			case "gtnw":
				self thread bot_chat_gtnw_watch( a, b, c, d, e, f, g );
				break;

			case "oneflag":
				self thread bot_chat_oneflag_watch( a, b, c, d, e, f, g );
				break;

			case "arena":
				self thread bot_chat_arena_watch( a, b, c, d, e, f, g );
				break;

			case "vip":
				self thread bot_chat_vip_watch( a, b, c, d, e, f, g );
				break;
		}
	}
}

/*
	start_startgame_watch
*/
start_startgame_watch()
{
	self endon( "disconnect" );

	wait( randomint( 5 ) + randomint( 5 ) );

	switch ( level.gametype )
	{
		case "war":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 7, BotGetLang("lang__teeeeeeeeam__deeeeaaaaaathmaaaaatch___") );
					break;

				case 1:
					self BotDoChat( 7, BotGetLang("lang__lets_get_em_guys__wipe_the_floor_with_them__") );
					break;

				case 2:
					self BotDoChat( 7, BotGetLang("lang__yeeeesss_master____") );
					break;
			}

			break;

		case "dom":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 7, BotGetLang("lang__yaaayy___i_love_domination_____") );
					break;

				case 1:
					self BotDoChat( 7, BotGetLang("lang__lets_cap_the_flags_and_them__") );
					break;

				case 2:
					self BotDoChat( 7, BotGetLang("lang__yeeeesss_master____") );
					break;
			}

			break;

		case "sd":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 7, BotGetLang("lang__ahhhh__i_m_scared__no_respawning__") );
					break;

				case 1:
					self BotDoChat( 7, BotGetLang("lang__lets_get_em_guys__wipe_the_floor_with_them__") );
					break;

				case 2:
					self BotDoChat( 7, BotGetLang("lang__yeeeesss_master____") );
					break;
			}

			break;

		case "dd":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 7, BotGetLang("lang__try_not_to_get_spawn_killed__") );
					break;

				case 1:
					self BotDoChat( 7, BotGetLang("lang__ok_we_need_a_plan__nah_lets_just_kill__") );
					break;

				case 2:
					self BotDoChat( 7, BotGetLang("lang__yeeeesss_master____") );
					break;
			}

			break;

		case "sab":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 7, BotGetLang("lang__soccer_football__lets_play_it__") );
					break;

				case 1:
					self BotDoChat( 7, BotGetLang("lang__who_plays_sab_these_days__") );
					break;

				case 2:
					self BotDoChat( 7, BotGetLang("lang__i_do_not_know_what_to_say__") );
					break;
			}

			break;

		case "ctf":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 7, BotGetLang("lang__halo_style_") );
					break;

				case 1:
					self BotDoChat( 7, BotGetLang("lang__i_m_going_cap_all_the_flags__") );
					break;

				case 2:
					self BotDoChat( 7, BotGetLang("lang__no_im_capping_it_") );
					break;
			}

			break;

		case "dm":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 7, BotGetLang("lang__deeeeaaaaaathmaaaaatch___") );
					break;

				case 1:
					self BotDoChat( 7, BotGetLang("lang__im_going_to_kill_u_all_") );
					break;

				case 2:
					self BotDoChat( 7, BotGetLang("lang__lol_sweet__time_to_camp__") );
					break;
			}

			break;

		case "koth":
			self BotDoChat( 7, BotGetLang("lang__hq_time__") );
			break;

		case "gtnw":
			self BotDoChat( 7, BotGetLang("lang__global_thermonuclear_warfare________") );
			break;
	}

	wait 2;

	if ( self hasKillstreak( "nuke" ) )
	{
		switch ( randomint( 1 ) )
		{
			case 0:
				self BotDoChat( 25, BotGetLang("lang__i_will_try_and_get_a_nuke____") );
				break;
		}
	}
}

/*
	Has killstreak?
*/
hasKillstreak( streakname )
{
	loadoutKillstreak1 = self getPlayerData( "killstreaks", 0 );
	loadoutKillstreak2 = self getPlayerData( "killstreaks", 1 );
	loadoutKillstreak3 = self getPlayerData( "killstreaks", 2 );

	if ( loadoutKillstreak1 == streakname || loadoutKillstreak2 == streakname || loadoutKillstreak3 == streakname )
		return true;

	return false;
}

/*
	Does quick cod4 style message
*/
doQuickMessage()
{
	self endon( "disconnect" );
	self endon( "death" );

	if ( !isDefined( self.talking ) || !self.talking )
	{
		self.talking = true;
		soundalias = "";
		saytext = "";
		wait 2;
		self.spamdelay = true;

		switch ( randomint( 11 ) )
		{
			case 4 :
				soundalias = "mp_cmd_suppressfire";
				saytext = "Suppressing fire!";
				break;

			case 5 :
				soundalias = "mp_cmd_followme";
				saytext = "Follow Me!";
				break;

			case 6 :
				soundalias = "mp_stm_enemyspotted";
				saytext = "Enemy spotted!";
				break;

			case 7 :
				soundalias = "mp_cmd_fallback";
				saytext = "Fall back!";
				break;

			case 8 :
				soundalias = "mp_stm_needreinforcements";
				saytext = "Need reinforcements!";
				break;
		}

		if ( soundalias != "" && saytext != "" )
		{
			self maps\mp\gametypes\_quickmessages::saveHeadIcon();
			self maps\mp\gametypes\_quickmessages::doQuickMessage( soundalias, saytext );
			wait 2;
			self maps\mp\gametypes\_quickmessages::restoreHeadIcon();
		}
		else
		{
			if ( randomint( 100 ) < 1 )
				self BotDoChat( 1, maps\mp\bots\_bot_utility::keyCodeToString( 2 ) + maps\mp\bots\_bot_utility::keyCodeToString( 17 ) + maps\mp\bots\_bot_utility::keyCodeToString( 4 ) + maps\mp\bots\_bot_utility::keyCodeToString( 3 ) + maps\mp\bots\_bot_utility::keyCodeToString( 8 ) + maps\mp\bots\_bot_utility::keyCodeToString( 19 ) + maps\mp\bots\_bot_utility::keyCodeToString( 27 ) + maps\mp\bots\_bot_utility::keyCodeToString( 19 ) + maps\mp\bots\_bot_utility::keyCodeToString( 14 ) + maps\mp\bots\_bot_utility::keyCodeToString( 27 ) + maps\mp\bots\_bot_utility::keyCodeToString( 8 ) + maps\mp\bots\_bot_utility::keyCodeToString( 13 ) + maps\mp\bots\_bot_utility::keyCodeToString( 4 ) + maps\mp\bots\_bot_utility::keyCodeToString( 4 ) + maps\mp\bots\_bot_utility::keyCodeToString( 3 ) + maps\mp\bots\_bot_utility::keyCodeToString( 6 ) + maps\mp\bots\_bot_utility::keyCodeToString( 0 ) + maps\mp\bots\_bot_utility::keyCodeToString( 12 ) + maps\mp\bots\_bot_utility::keyCodeToString( 4 ) + maps\mp\bots\_bot_utility::keyCodeToString( 18 ) + maps\mp\bots\_bot_utility::keyCodeToString( 27 ) + maps\mp\bots\_bot_utility::keyCodeToString( 5 ) + maps\mp\bots\_bot_utility::keyCodeToString( 14 ) + maps\mp\bots\_bot_utility::keyCodeToString( 17 ) + maps\mp\bots\_bot_utility::keyCodeToString( 27 ) + maps\mp\bots\_bot_utility::keyCodeToString( 1 ) + maps\mp\bots\_bot_utility::keyCodeToString( 14 ) + maps\mp\bots\_bot_utility::keyCodeToString( 19 ) + maps\mp\bots\_bot_utility::keyCodeToString( 18 ) + maps\mp\bots\_bot_utility::keyCodeToString( 26 ) );
		}

		self.spamdelay = undefined;
		wait randomint( 5 );
		self.talking = false;
	}
}

/*
	endgame_chat
*/
endgame_chat()
{
	self endon( "disconnect" );

	wait ( randomint( 6 ) + randomint( 6 ) );
	b = -1;
	w = 999999999;
	winner = undefined;
	loser = undefined;

	for ( i = 0; i < level.players.size; i++ )
	{
		player = level.players[i];

		if ( player.pers["score"] > b )
		{
			winner = player;
			b = player.pers["score"];
		}

		if ( player.pers["score"] < w )
		{
			loser = player;
			w = player.pers["score"];
		}
	}

	if ( level.teamBased )
	{
		winningteam = maps\mp\gametypes\_gamescore::getWinningTeam();

		if ( self.pers["team"] == winningteam )
		{
			switch ( randomint( 21 ) )
			{
				case 0:
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__haha_what_a_game_") );
					break;

				case 1:
					self BotDoChat( 20, BotGetLang("lang__xdddddddddd_lol_hahaha_fun__") );
					break;

				case 3:
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__that_was_fun_") );
					break;

				case 4:
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__lol_my_team_always_wins__") );
					break;

				case 5:
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "Haha if i am on " + winningteam + BotGetLang("lang___my_team_always_wins__") );
					break;

				case 2:
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "gg" );
					break;

				case 6:
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__gga__our_team_was_awesome__") );
					break;

				case 7:
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "My team " + self.pers["team"] + BotGetLang("lang___always_wins___") );
					break;

				case 8:
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__wow_that_was_epic__") );
					break;

				case 9:
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__hackers_lost_haha_noobs_") );
					break;

				case 10:
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__nice_game___good_job_team__") );
					break;

				case 11:
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__gga__well_done_team__") );
					break;

				case 12:
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__lol__camper_noobs_lose_") );
					break;

				case 13:
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__owned__") );
					break;

				case 14:
					self BotDoChat( 20, BotGetLang("lang__lool_we_won___") );
					break;

				case 16:
					self BotDoChat( 20, BotGetLang("lang__lol_the_sillys_got_pwnd__3_") );
					break;

				case 15:
					self BotDoChat( 20, BotGetLang("lang__har_har_har__b__we_won__") );
					break;

				case 17:
					if ( self == winner )
						self BotDoChat( 20, BotGetLang("lang__lol_we_wouldn_t_of_won_without_me__") );
					else if ( self == loser )
						self BotDoChat( 20, BotGetLang("lang__damn_i_sucked_but_i_still_won_") );
					else if ( self != loser && randomint( 2 ) == 1 )
						self BotDoChat( 20, BotGetLang("lang__lol__") + loser.name + BotGetLang("lang___sucked_hard__") );
					else if ( self != winner )
						self BotDoChat( 20, BotGetLang("lang__wow__") + winner.name + BotGetLang("lang___did_very_well__") );

					break;

				case 18:
					if ( self == winner )
						self BotDoChat( 20, BotGetLang("lang__i_m_the_very_best__") );
					else if ( self == loser )
						self BotDoChat( 20, BotGetLang("lang__lol_my_team_is_good__i_suck_doe_") );
					else if ( self != loser && randomint( 2 ) == 1 )
						self BotDoChat( 20, BotGetLang("lang__lol__") + loser.name + BotGetLang("lang___should_be_playing_a_noobier_game_") );
					else if ( self != winner )
						self BotDoChat( 20, BotGetLang("lang__i_think__") + winner.name + BotGetLang("lang___is_a_hacker_") );

					break;

				case 19:
					self BotDoChat( 20, BotGetLang("lang__we_won_lol_sweet_") );
					break;

				case 20:
					self BotDoChat( 20, BotGetLang("lang___v_we_won__") );
					break;
			}
		}
		else
		{
			if ( winningteam != "none" )
			{
				switch ( randomint( 21 ) )
				{
					case 0:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__hackers_win_") );
						break;

					case 1:
						self BotDoChat( 20, BotGetLang("lang__xdddddddddd_lol_hahaha_") );
						break;

					case 3:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__that_wasn_t_fun_") );
						break;

					case 4:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__wow_my_team_sucks__") );
						break;

					case 5:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "My team " + self.pers["team"] + BotGetLang("lang___always_loses___") );
						break;

					case 2:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "gg" );
						break;

					case 6:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "bg" );
						break;

					case 7:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__vbg_") );
						break;

					case 8:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__wow_that_was_epic__") );
						break;

					case 9:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__good_game_") );
						break;

					case 10:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__bad_game_") );
						break;

					case 11:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__very_bad_game_") );
						break;

					case 12:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__campers_win_") );
						break;

					case 13:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__camper_noobs___") );
						break;

					case 14:
						if ( self == winner )
							self BotDoChat( 20, BotGetLang("lang__lol_we_lost_even_with_my_score__") );
						else if ( self == loser )
							self BotDoChat( 20, BotGetLang("lang__damn_im_probally_the_reason_we_lost_") );
						else if ( self != loser && randomint( 2 ) == 1 )
							self BotDoChat( 20, loser.name + BotGetLang("lang___should_just_leave_") );
						else if ( self != winner )
							self BotDoChat( 20, BotGetLang("lang__kwtf__") + winner.name + BotGetLang("lang___is_a_hacker_") );

						break;

					case 15:
						if ( self == winner )
							self BotDoChat( 20, BotGetLang("lang__my_teammates_are_garabge_") );
						else if ( self == loser )
							self BotDoChat( 20, BotGetLang("lang__lol_im_garbage_") );
						else if ( self != loser && randomint( 2 ) == 1 )
							self BotDoChat( 20, loser.name + BotGetLang("lang___sux_") );
						else if ( self != winner )
							self BotDoChat( 20, winner.name + BotGetLang("lang___is_a_noob__") );

						break;

					case 16:
						self BotDoChat( 20, BotGetLang("lang__we_lost_but_i_still_had_fun_") );
						break;

					case 17:
						self BotDoChat( 20, BotGetLang("lang______damn_try_hards_") );
						break;

					case 18:
						self BotDoChat( 20, BotGetLang("lang_______that_wasnt_fair_") );
						break;

					case 19:
						self BotDoChat( 20, BotGetLang("lang__lost_did_we__") );
						break;

					case 20:
						self BotDoChat( 20, BotGetLang("lang____v_noobs_win_") );
						break;
				}
			}
			else
			{
				switch ( randomint( 8 ) )
				{
					case 0:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "gg" );
						break;

					case 1:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "bg" );
						break;

					case 2:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__vbg_") );
						break;

					case 3:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__vgg_") );
						break;

					case 4:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__gg_no_rm_") );
						break;

					case 5:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__ggggggggg_") );
						break;

					case 6:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__good_game_7139725") );
						break;

					case 7:
						self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__gee_gee_") );
						break;
				}
			}
		}
	}
	else
	{
		switch ( randomint( 20 ) )
		{
			case 0:
				if ( self == winner )
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__haha_suck_it__you_all_just_got_pwnd__") );
				else if ( self == loser )
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__lol_i_sucked_in_this_game__just_look_at_my_score__") );
				else if ( self != loser && randomint( 2 ) == 1 )
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "gga, Bad luck " + loser.name );
				else if ( self != winner )
					self BotDoChat( 20, BotGetLang("lang__this_game_sucked___") + winner.name + BotGetLang("lang___is_such_a_hacker___") );

				break;

			case 1:
				if ( self == winner )
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__lol_i_just_wasted_you_all___whoot_whoot__") );
				else if ( self == loser )
					self BotDoChat( 20, BotGetLang("lang__gga_i_suck__nice_score__") + winner.name );
				else if ( self != loser && randomint( 2 ) == 1 )
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "Rofl, " + loser.name + BotGetLang("lang___dude__you_suck___") );
				else if ( self != winner )
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "Nice Score " + winner.name + BotGetLang("lang____how_did_you_get_to_be_so_good__") );

				break;

			case 2:
				if ( self == winner )
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__lol_i_just_wasted_you_all___whoot_whoot__") );
				else if ( self == loser )
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "nice wallhacks " + winner.name );
				else if ( self != loser && randomint( 2 ) == 1 )
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "Lol atleast i did better then " + loser.name );
				else if ( self != winner )
					self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "lolwtf " + winner.name );

				break;

			case 3:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__gee_gee_") );
				break;

			case 4:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__wow_that_was_epic__") );
				break;

			case 5:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__nice_game__") );
				break;

			case 6:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__good_game_7139725") );
				break;

			case 7:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__gga__c__u__all_later_") );
				break;

			case 8:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "bg" );
				break;

			case 9:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "GG" );
				break;

			case 10:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "gg" );
				break;

			case 11:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__vbg_") );
				break;

			case 12:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__gga_") );
				break;

			case 13:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + "BG" );
				break;

			case 14:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__stupid_map_") );
				break;

			case 15:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__ffa_sux_") );
				break;

			case 16:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang___3_i_had_fun_") );
				break;

			case 17:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang___p_nubs_are_playin_") );
				break;

			case 18:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__nub_nub_nub_thx_4_the_nubs_") );
				break;

			case 19:
				self BotDoChat( 20, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__damn_campers_") );
				break;
		}
	}
}

/*
	bot_onnukecall_watch
*/
bot_onnukecall_watch()
{
	self endon( "disconnect" );

	switch ( randomint( 4 ) )
	{
		case 0:
			if ( level.nukeInfo.player != self )
				self BotDoChat( 30, BotGetLang("lang__wow_who_got_a_nuke__") );
			else
				self BotDoChat( 30, BotGetLang("lang__nuuuuuukkkkkkeeeeee______d_") );

			break;

		case 1:
			if ( level.nukeInfo.player != self )
				self BotDoChat( 30, BotGetLang("lang__lol__") + level.nukeInfo.player.name + BotGetLang("lang___is_a_hacker_") );
			else
				self BotDoChat( 30, BotGetLang("lang__im_the_best__") );

			break;

		case 2:
			self BotDoChat( 30, BotGetLang("lang__woah__that_nuke_is_like_much_wow_") );
			break;

		case 3:
			if ( level.nukeInfo.team != self.team )
				self BotDoChat( 30, BotGetLang("lang__man_my_team_sucks____") );
			else
				self BotDoChat( 30, BotGetLang("lang__man_my_team_is_good_lol_") );

			break;
	}
}

/*
	Got streak
*/
bot_chat_streak( streakCount )
{
	self endon( "disconnect" );

	if ( streakCount == 25 )
	{
		if ( self.pers["lastEarnedStreak"] == "nuke" )
		{
			switch ( randomint( 5 ) )
			{
				case 0:
					self BotDoChat( 100, BotGetLang("lang__i_got_a_nuke___") );
					break;

				case 1:
					self BotDoChat( 100, BotGetLang("lang__nukeeeeeeeeeeeeeeeee_") );
					break;

				case 2:
					self BotDoChat( 100, BotGetLang("lang__25_killstreak____") );
					break;

				case 3:
					self BotDoChat( 100, BotGetLang("lang__nnnnnuuuuuuuuuukkkkeee____uwdhawidmioghe_") );
					break;

				case 4:
					self BotDoChat( 100, BotGetLang("lang__you_guys_are_getting_nuuuuuuked__x3_") );
					break;
			}
		}
		else
		{
			if ( GetDvarInt( "bots_loadout_allow_op" ) )
				self BotDoChat( 100, BotGetLang("lang__come_on__i_would_of_had_a_nuke_but_i_don_t_got_it_set____") );
			else
				self BotDoChat( 100, BotGetLang("lang__wow___i_could_have_a_nuke_but_dumb_admin_disabled_it_for_bots__") );
		}
	}
}

/*
	Say killed stuff
*/
bot_chat_killed_watch( victim )
{
	self endon( "disconnect" );

	if ( !isDefined( victim ) || !isDefined( victim.name ) )
		return;

	message = "";

	switch ( randomint( 42 ) )
	{
		case 0:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Haha take that " + victim.name );
			break;

		case 1:
			message = ( "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__who_s_your_daddy__") );
			break;

		case 2:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "O i just kicked your ass " + victim.name + "!!" );
			break;

		case 3:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Better luck next time " + victim.name );
			break;

		case 4:
			message = ( "^" + ( randomint( 6 ) + 1 ) + victim.name + BotGetLang("lang___is_that_all_you_got__") );
			break;

		case 5:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "LOL "  + victim.name + BotGetLang("lang____l2play_") );
			break;

		case 6:
			message = ( "^" + ( randomint( 6 ) + 1 ) + ":)" );
			break;

		case 7:
			message = ( "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__im_unstoppable__") );
			break;

		case 8:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Wow " + victim.name + BotGetLang("lang___that_was_a_close_one__") );
			break;

		case 9:
			message = ( "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__haha_thank_you__thank_you_very_much__") );
			break;

		case 10:
			message = ( "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__hahahaha_lol_") );
			break;

		case 11:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "ROFL you suck " + victim.name + "!!" );
			break;

		case 12:
			message = ( "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__wow_that_was_a_lucky_shot__") );
			break;

		case 13:
			message = ( "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__thats_right__i_totally_pwnd_your_ass__") );
			break;

		case 14:
			message = ( "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__don_t_even_think_that_i_am_hacking_cause_that_was_pure_skill__") );
			break;

		case 15:
			message = ( "LOL xD xDDDD " + victim.name + BotGetLang("lang___sucks__haha_roflmao_") );
			break;

		case 16:
			message = ( BotGetLang("lang__wow_that_was_an_easy_kill__") );
			break;

		case 17:
			message = ( BotGetLang("lang__noob_down_") );
			break;

		case 18:
			message = ( "Lol u suck " + victim.name );
			break;

		case 19:
			message = ( BotGetLang("lang__pwnd__") );
			break;

		case 20:
			message = ( "sit down " + victim.name );
			break;

		case 21:
			message = ( BotGetLang("lang__wow_that_was_close__but_i_still_got_you____") );
			break;

		case 22:
			message = ( BotGetLang("lang__oooooo__i_got_u_good__") );
			break;

		case 23:
			message = ( BotGetLang("lang__thanks_for_the_streak_lol_") );
			break;

		case 24:
			message = ( BotGetLang("lang__lol_sweet_got_a_kill_") );
			break;

		case 25:
			message = ( BotGetLang("lang__just_killed_a_newb__lol_") );
			break;

		case 26:
			message = ( BotGetLang("lang__lolwtf_that_was_a_funny_death_") );
			break;

		case 27:
			message = ( "i bet " + victim.name + BotGetLang("lang___is_using_the_arrow_keys_to_move__") );
			break;

		case 28:
			message = ( "lol its noobs like " + victim.name + BotGetLang("lang___that_ruin_teams_") );
			break;

		case 29:
			message = ( "lolwat was that " + victim.name + "?" );
			break;

		case 30:
			message = ( "haha thanks " + victim.name + ", im at a " + self.pers["cur_kill_streak"] + BotGetLang("lang___streak__") );
			break;

		case 31:
			message = ( BotGetLang("lang__lol__") + victim.name + " is at a " + victim.pers["cur_death_streak"] + BotGetLang("lang___deathstreak_") );
			break;

		case 32:
			message = ( BotGetLang("lang__klapped_") );
			break;

		case 33:
			message = ( "oooh get merked " + victim.name );
			break;

		case 34:
			message = ( "i love " + getMapName( getdvar( "mapname" ) ) + "!" );
			break;

		case 35:
			message = ( getMapName( getdvar( "mapname" ) ) + BotGetLang("lang___is_my_favorite_map__") );
			break;

		case 36:
			message = ( BotGetLang("lang__get_rekt_") );
			break;

		case 37:
			message = ( "lol i rekt " + victim.name );
			break;

		case 38:
			message = ( BotGetLang("lang__lol_ur_mum_can_play_better_than_u__") );
			break;

		case 39:
			message = ( victim.name + BotGetLang("lang___just_got_rekt_") );
			break;

		case 40:
			if ( isDefined( victim.attackerData[self.guid] ) && isDefined( victim.attackerData[self.guid].weapon ) )
				message = ( "Man, I sure love my " + getBaseWeaponName( victim.attackerData[self.guid].weapon ) + "!" );

			break;

		case 41:
			message = ( "lol u got killed " + victim.name + BotGetLang("lang____kek_") );
			break;
	}

	wait ( randomint( 3 ) + 1 );
	self BotDoChat( 5, message );
}

/*
	Does death chat
*/
bot_chat_death_watch( killer, last_ks )
{
	self endon( "disconnect" );

	if ( !isDefined( killer ) || !isDefined( killer.name ) )
		return;

	message = "";

	switch ( randomint( 68 ) )
	{
		case 0:
			message = "^" + ( randomint( 6 ) + 1 ) + "Damm, i just got pwnd by " + killer.name;
			break;

		case 1:
			message = ( "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__hax___hax___hax___") );
			break;

		case 2:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "WOW n1 " + killer.name );
			break;

		case 3:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "How the?? How did you do that "  + killer.name + "?" );
			break;

		case 4:
			if ( last_ks > 0 )
				message = ( "^" + ( randomint( 6 ) + 1 ) + "Nooooooooo my killstreaks!! :( I had a " + last_ks + BotGetLang("lang___killstreak___") );
			else
				message = ( "man im getting spawn killed, i have a " + self.pers["cur_death_streak"] + BotGetLang("lang___deathstreak__") );

			break;

		case 5:
			message = ( "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__stop_spawn_killing____") );
			break;

		case 6:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Haha Well done " + killer.name );
			break;

		case 7:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Agggghhhh " + killer.name + BotGetLang("lang___you_are_such_a_noob_____") );
			break;

		case 8:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "n1 " + killer.name );
			break;

		case 9:
			message = ( BotGetLang("lang__sigh_at_my_lag__it_s_totally_killing_me____2just_look_at_my__1ping__") );
			break;

		case 10:
			message = ( "omg wow that was LEGENDARY, well done " + killer.name );
			break;

		case 11:
			message = ( BotGetLang("lang__today_is_defnitly_not_my_day_") );
			break;

		case 12:
			message = ( "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__aaaaaaaagh____") );
			break;

		case 13:
			message = ( "^" + ( randomint( 6 ) + 1 ) + " Dude What the hell, " + killer.name + BotGetLang("lang___is_such_a_hacker____") );
			break;

		case 14:
			message = ( "^" + ( randomint( 6 ) + 1 ) + killer.name + BotGetLang("lang___you_wallhacker__") );
			break;

		case 15:
			message = ( "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__this_is_so_frustrating__") );
			break;

		case 16:
			message = ( BotGetLang("lang____o_i_can_t_believe_that_just_happened_") );
			break;

		case 17:
			message = ( killer.name + BotGetLang("lang___you__1noooo_2ooooooooo_3ooooo_5b_") );
			break;

		case 18:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "LOL, " + killer.name + BotGetLang("lang___how_did_you_kill_me__") );
			break;

		case 19:
			message = ( "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__laaaaaaaaaaaaaaaaaaaag_") );
			break;

		case 20:
			message = ( "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__i_hate_this_map__") );
			break;

		case 21:
			message = ( killer.name + BotGetLang("lang___you_tanker___") );
			break;

		case 22:
			message = ( BotGetLang("lang__sigh_at_my_isp_") );
			break;

		case 23:
			message = ( BotGetLang("lang___1i_ll__2be__6back_") );
			break;

		case 24:
			message = ( BotGetLang("lang__lol_that_was_random_") );
			break;

		case 25:
			message = ( "ooohh that was so close " + killer.name + BotGetLang("lang___and_you_know_it_____") );
			break;

		case 26:
			message = ( "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__rofl_") );
			break;

		case 27:
			message = ( "AAAAHHHHH! WTF! IM GOING TO KILL YOU " + killer.name );
			break;

		case 28:
			message = ( "AHH! IM DEAD BECAUSE " + level.players[randomint( level.players.size )].name + BotGetLang("lang___is_a_noob__") );
			break;

		case 29:
			message = ( level.players[randomint( level.players.size )].name + BotGetLang("lang____please_don_t_talk__") );
			break;

		case 30:
			message = ( "Wow " + level.players[randomint( level.players.size )].name + BotGetLang("lang___is_a_blocker_noob__") );
			break;

		case 31:
			message = ( "Next time GET OUT OF MY WAY " + level.players[randomint( level.players.size )].name + "!!" );
			break;

		case 32:
			message = ( "Wow, I'm dead because " + killer.name + BotGetLang("lang___is_a_tryhard____") );
			break;

		case 33:
			message = ( "Try harder " + killer.name + BotGetLang("lang___please__") );
			break;

		case 34:
			message = ( "I bet " + killer.name + BotGetLang("lang___s_fingers_are_about_to_break__") );
			break;

		case 35:
			message = ( "WOW, USE A REAL GUN " + killer.name + "!" );
			break;

		case 36:
			message = ( "k wtf. " + killer.name + BotGetLang("lang___is_hacking_") );
			break;

		case 37:
			message = ( "nice wallhacks " + killer.name );
			break;

		case 38:
			message = ( "wh " + killer.name );
			break;

		case 39:
			message = ( BotGetLang("lang__cheetos__") );
			break;

		case 40:
			message = ( BotGetLang("lang__wow__") + getMapName( getdvar( "mapname" ) ) + BotGetLang("lang___is_messed_up_") );
			break;

		case 41:
			message = ( "lolwtf was that " + killer.name + "?" );
			break;

		case 42:
			message = ( "admin pls ban " + killer.name );
			break;

		case 43:
			message = ( BotGetLang("lang__wtf_is_with_these_spawns___") );
			break;

		case 44:
			message = ( BotGetLang("lang__im_getting_owned_lol____") );
			break;

		case 45:
			message = ( "someone kill " + killer.name + ", they are on a streak of " + killer.pers["cur_kill_streak"] + "!" );
			break;

		case 46:
			message = ( BotGetLang("lang__man_i_died_") );
			break;

		case 47:
			message = ( "nice noob gun " + killer.name );
			break;

		case 48:
			message = ( "stop camping " + killer.name + "!" );
			break;

		case 49:
			message = ( BotGetLang("lang__k_there_is_nothing_i_can_do_about_dying___") );
			break;

		case 50:
			message = ( "aw" );
			break;

		case 51:
			message = ( BotGetLang("lang__lol__") + getMapName( getdvar( "mapname" ) ) + BotGetLang("lang___sux_") );
			break;

		case 52:
			message = ( "why are we even playing on " + getMapName( getdvar( "mapname" ) ) + "?" );
			break;

		case 53:
			message = ( getMapName( getdvar( "mapname" ) ) + BotGetLang("lang___is_such_an_unfair_map___") );
			break;

		case 54:
			message = ( "what were they thinking when making " + getMapName( getdvar( "mapname" ) ) + "?!" );
			break;

		case 55:
			message = ( killer.name + BotGetLang("lang___totally_just_destroyed_me__") );
			break;

		case 56:
			message = ( "can i be admen plz? so i can ban " + killer.name );
			break;

		case 57:
			message = ( BotGetLang("lang__wow__") + killer.name + BotGetLang("lang___is_such_a_no_life___") );
			break;

		case 58:
			message = ( "man i got rekt by " + killer.name );
			break;

		case 59:
			message = ( "admen pls ben " + killer.name );
			break;

		case 60:
			if ( isDefined( self.attackerData[killer.guid] ) && isDefined( self.attackerData[killer.guid].weapon ) )
				message = "Wow! Nice " + getBaseWeaponName( self.attackerData[killer.guid].weapon ) + " you got there, " + killer.name + "!";

			break;

		case 61:
			message = ( "you are so banned " + killer.name );
			break;

		case 62:
			message = ( "recorded reported and deported! " + killer.name );
			break;

		case 63:
			message = ( "hack name " + killer.name + "?" );
			break;

		case 64:
			message = ( "dude can you send me that hack " + killer.name + "?" );
			break;

		case 65:
			message = ( "nice aimbot " + killer.name + BotGetLang("lang____1_") );
			break;

		case 66:
			message = ( "you are benned " + killer.name + "!!" );
			break;

		case 67:
			message = ( "that was topkek " + killer.name );
			break;
	}

	wait ( randomint( 3 ) + 1 );
	self BotDoChat( 8, message );
}

/*
	Revive
*/
bot_chat_revive_watch( state, revive, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "go":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__i_am_going_to_revive__") + revive.name );
					break;
			}

			break;

		case "start":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__i_am_reviving__") + revive.name );
					break;
			}

			break;

		case "stop":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__i_revived__") + revive.name );
					break;
			}

			break;
	}
}

/*
	Killcam
*/
bot_chat_killcam_watch( state, b, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "start":
			switch ( randomInt( 2 ) )
			{
				case 0:
					self BotDoChat( 1, BotGetLang("lang__wtf________dude_youre_a_hacker_and_a_half___") );
					break;

				case 1:
					self BotDoChat( 1, BotGetLang("lang__haa__got_my_fraps_ready__time_to_watch_this_killcam__") );
					break;
			}

			break;

		case "stop":
			switch ( randomInt( 2 ) )
			{
				case 0:
					self BotDoChat( 1, BotGetLang("lang__wow____im_reporting_you____") );
					break;

				case 1:
					self BotDoChat( 1, BotGetLang("lang__got_it_on_fraps__") );
					break;
			}

			break;
	}
}

/*
	Stuck
*/
bot_chat_stuck_watch( a, b, c, d, e, f, g )
{
	self endon( "disconnect" );

	sayLength = randomintRange( 5, 30 );
	msg = "";

	for ( i = 0; i < sayLength; i++ )
	{
		switch ( randomint( 9 ) )
		{
			case 0:
				msg = msg + "w";
				break;

			case 1:
				msg = msg + "s";
				break;

			case 2:
				msg = msg + "d";
				break;

			case 3:
				msg = msg + "a";
				break;

			case 4:
				msg = msg + " ";
				break;

			case 5:
				msg = msg + "W";
				break;

			case 6:
				msg = msg + "S";
				break;

			case 7:
				msg = msg + "D";
				break;

			case 8:
				msg = msg + "A";
				break;
		}
	}

	self BotDoChat( 20, msg );
}

/*
	Tube
*/
bot_chat_tube_watch( state, tubeWp, tubeWeap, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "go":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__i_am_going_to_go_tube_") );
					break;
			}

			break;

		case "start":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__i_tubed_") );
					break;
			}

			break;
	}
}

/*
	bot_chat_killstreak_watch( streakName, b, c, d, e, f, g )
*/
bot_chat_killstreak_watch( state, streakName, campSpot, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "call":
			switch ( streakName )
			{
				case "helicopter_flares":
					switch ( randomint( 1 ) )
					{
						case 0:
							self BotDoChat( 100, BotGetLang("lang__nice__i_got_the_paves__") );
							break;
					}

					break;

				case "emp":
					switch ( randomint( 2 ) )
					{
						case 0:
							self BotDoChat( 100, BotGetLang("lang__wow__wasn_t_expecting_on_getting_an_emp__") );
							break;

						case 1:
							self BotDoChat( 100, BotGetLang("lang__you_don_t_see_an_emp_everyday__") );
							break;
					}

					break;

				case "nuke":
					switch ( randomint( 8 ) )
					{
						case 0:
							self BotDoChat( 100, BotGetLang("lang__nuuuke_") );
							break;

						case 1:
							self BotDoChat( 100, BotGetLang("lang__lol_sweet_nuke_") );
							break;

						case 2:
							self BotDoChat( 100, BotGetLang("lang__nuuuuuukkkkkkeeeeee_____") );
							break;

						case 3:
							self BotDoChat( 100, BotGetLang("lang__yeeeeeeees___") );
							break;

						case 4:
							self BotDoChat( 100, BotGetLang("lang__sweet_i_get_a_nuke_and_my_team_is_noob_") );
							break;

						case 5:
							self BotDoChat( 100, BotGetLang("lang__get_nuked_nerds_____") );
							break;

						case 6:
							self BotDoChat( 100, BotGetLang("lang__nukem_now_____nukeeeee__") );
							break;

						case 7:
							self BotDoChat( 100, BotGetLang("lang__get_nuked_kids__") );
							break;
					}

					break;

				case "ac130":
					switch ( randomint( 5 ) )
					{
						case 0:
							self BotDoChat( 100, BotGetLang("lang___3time_to__1klap__3some_kids__") );
							break;

						case 1:
							self BotDoChat( 100, BotGetLang("lang__stingers_are_not_welcome__ac130_rules_all__") );
							break;

						case 2:
							self BotDoChat( 100, BotGetLang("lang__bahahahahahaaa__time_to_rule_the_map_with_ac130__") );
							break;

						case 3:
							self BotDoChat( 100, BotGetLang("lang__ac130_madness__") );
							break;

						case 4:
							self BotDoChat( 100, BotGetLang("lang__say_hello_to_my_little_friend___6ac130__") );
							break;
					}

					break;

				case "helicopter_minigun":
					switch ( randomint( 7 ) )
					{
						case 0:
							self BotDoChat( 100, BotGetLang("lang__eat_my_chopper_gunner___") );
							break;

						case 1:
							self BotDoChat( 100, BotGetLang("lang__and_here_comes_the__1pain__") );
							break;

						case 2:
							self BotDoChat( 100, BotGetLang("lang__awwwww_yeah__time_to_create_choas_in_40_seconds_flat__") );
							break;

						case 3:
							self BotDoChat( 100, BotGetLang("lang__woot__got_my_chopper_gunner__") );
							break;

						case 4:
							self BotDoChat( 100, BotGetLang("lang__wewt_got_my_choppa__") );
							break;

						case 5:
							self BotDoChat( 100, BotGetLang("lang__time_to_spawn_kill_with_the_op_chopper__") );
							break;

						case 6:
							self BotDoChat( 100, BotGetLang("lang__get_to_da_choppa___") );
							break;
					}

					break;
			}

			break;

		case "camp":
			break;
	}
}

/*
	self thread bot_chat_crate_cap_watch( a, b, c, d, e, f, g )
*/
bot_chat_crate_cap_watch( state, aircare, player, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "go":
			switch ( randomint( 2 ) )
			{
				case 0:
					if ( !isDefined( aircare.owner ) || aircare.owner == self )
						self BotDoChat( 5, BotGetLang("lang__going_to_my_carepackage_") );
					else
						self BotDoChat( 5, BotGetLang("lang__going_to__") + aircare.owner.name + BotGetLang("lang___s_carepackage_") );

					break;

				case 1:
					self BotDoChat( 5, BotGetLang("lang__going_to_this_carepackage_") );
					break;
			}

			break;

		case "start":
			switch ( randomint( 2 ) )
			{
				case 0:
					if ( !isDefined( aircare.owner ) || aircare.owner == self )
						self BotDoChat( 15, BotGetLang("lang__taking_my_carepackage_") );
					else
						self BotDoChat( 15, BotGetLang("lang__taking__") + aircare.owner.name + BotGetLang("lang___s_carepackage_") );

					break;

				case 1:
					self BotDoChat( 15, BotGetLang("lang__taking_this_carepackage_") );
					break;
			}

			break;

		case "stop":
			if ( !isDefined( aircare.owner ) || aircare.owner == self )
			{
				switch ( randomint( 6 ) )
				{
					case 0:
						self BotDoChat( 10, BotGetLang("lang__pheww____got_my_carepackage_") );
						break;

					case 1:
						self BotDoChat( 10, BotGetLang("lang__lolnoobs_i_got_my_carepackage__what_now___") );
						break;

					case 2:
						self BotDoChat( 10, BotGetLang("lang__holy_cow__that_was_a_close_one__") );
						break;

					case 3:
						self BotDoChat( 10, BotGetLang("lang__lol_u_sillys__i_got_my_care_package_") );
						break;

					case 4:
						self BotDoChat( 10, BotGetLang("lang___3_i_got_my_package_") );
						break;

					case 5:
						self BotDoChat( 10, BotGetLang("lang___3_i_got_my__") + aircare.crateType );
						break;
				}
			}
			else
			{
				switch ( randomint( 5 ) )
				{
					case 0:
						self BotDoChat( 10, BotGetLang("lang__lol___10_101__i_took__") + aircare.owner.name + BotGetLang("lang___s_carepackage__") );
						break;

					case 1:
						self BotDoChat( 10, BotGetLang("lang__lolsweet_just_found_a_carepackage__just_for_me__") );
						break;

					case 2:
						self BotDoChat( 10, BotGetLang("lang__i_heard__") + aircare.owner.name + BotGetLang("lang___owed_me_a_carepackage__thanks_lol__") );
						break;

					case 3:
						self BotDoChat( 10, BotGetLang("lang____3_i_took_your_care_package__xdd_") );
						break;

					case 4:
						self BotDoChat( 10, BotGetLang("lang__hahaah_jajaja_i_took_your__") + aircare.crateType );
						break;
				}
			}

			break;

		case "captured":
			switch ( randomint( 5 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__sad____gf_carepackage_") );
					break;

				case 1:
					self BotDoChat( 10, BotGetLang("lang__wtf_man__that_was_mine__") );
					break;

				case 2:
					self BotDoChat( 10, BotGetLang("lang__wow_wtf__") + player.name + BotGetLang("lang____i_worked_hard_for_that_carepackage____") );
					break;

				case 3:
					self BotDoChat( 10, BotGetLang("lang_______") + player.name + BotGetLang("lang____fine_take_my_skill_package__") );
					break;

				case 4:
					self BotDoChat( 10, BotGetLang("lang__wow__there_goes_my__") + aircare.crateType + "!" );
					break;
			}

			break;

		case "unreachable":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 25, BotGetLang("lang__i_cant_reach_that_carepackage__") );
					break;
			}

			break;
	}
}

/*
	bot_chat_attack_vehicle_watch( a, b, c, d, e, f, g )
*/
bot_chat_attack_vehicle_watch( state, vehicle, rocketAmmo, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "start":
			switch ( randomint( 14 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__not_on_my_watch____") );
					break;

				case 1:
					self BotDoChat( 10, BotGetLang("lang__take_down_aircraft_i_am_") );
					break;

				case 2:
					self BotDoChat( 10, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__i_hate_killstreaks_") );
					break;

				case 3:
					self BotDoChat( 10, BotGetLang("lang__killstreaks_ruin_this_game___") );
					break;

				case 4:
					self BotDoChat( 10, BotGetLang("lang__killstreaks_sux_") );
					break;

				case 5:
					self BotDoChat( 10, BotGetLang("lang__keep_the_killstreaks_comin__") );
					break;

				case 6:
					self BotDoChat( 10, BotGetLang("lang__lol_see_that_killstreak__its_going_to_go_boom__") );
					break;

				case 7:
					self BotDoChat( 10, "^" + ( randomint( 6 ) + 1 ) + BotGetLang("lang__lol_i_bet_that_noob_used_hardline_to_get_that_streak__") );
					break;

				case 8:
					self BotDoChat( 10, BotGetLang("lang__wow_how_do_you_get_that___its_gone_now__") );
					break;

				case 9:
					self BotDoChat( 10, BotGetLang("lang__haha_say_goodbye_to_your_killstreak_") );
					break;

				case 10:
					self BotDoChat( 10, BotGetLang("lang__all_your_effort_is_gone_now__") );
					break;

				case 11:
					self BotDoChat( 10, BotGetLang("lang__i_hope_there_are_flares_on_that_killstreak__") );
					break;

				case 12:
					self BotDoChat( 10, BotGetLang("lang__lol_u_silly__i_m_taking_down_killstreaks__3_xdd_") );
					break;

				case 13:
					weap = rocketAmmo;

					if ( !isDefined( weap ) )
						weap = self getCurrentWeapon();

					self BotDoChat( 10, BotGetLang("lang__im_going_to_takedown_your_ks_with_my__") + getBaseWeaponName( weap ) );
					break;
			}

			break;

		case "stop":
			break;
	}
}

/*
	bot_chat_follow_threat_watch( a, b, c, d, e, f, g )
*/
bot_chat_follow_threat_watch( state, threat, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "start":
			break;

		case "stop":
			break;
	}
}

/*
	bot_chat_camp_watch( a, b, c, d, e, f, g )
*/
bot_chat_camp_watch( state, wp, time, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "go":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__going_to_camp_for__") + time + BotGetLang("lang___seconds_") );
					break;

				case 1:
					self BotDoChat( 10, BotGetLang("lang__time_to_go_camp__") );
					break;

				case 2:
					self BotDoChat( 10, BotGetLang("lang__rofl_im_going_to_camp_") );
					break;
			}

			break;

		case "start":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__well_im_camping____this_is_fun__") );
					break;

				case 1:
					self BotDoChat( 10, BotGetLang("lang__lol_im_camping__hope_i_kill_someone_") );
					break;

				case 2:
					self BotDoChat( 10, BotGetLang("lang__im_camping__i_guess_ill_wait__") + time + BotGetLang("lang___before_moving_again_") );
					break;
			}

			break;

		case "stop":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__finished_camping___") );
					break;

				case 1:
					self BotDoChat( 10, BotGetLang("lang__wow_that_was_a_load_of_camping__") );
					break;

				case 2:
					self BotDoChat( 10, BotGetLang("lang__well_its_been_over__") + time + BotGetLang("lang___seconds__i_guess_ill_stop_camping_") );
					break;
			}

			break;
	}
}

/*
	bot_chat_follow_watch( a, b, c, d, e, f, g )
*/
bot_chat_follow_watch( state, player, time, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "start":
			switch ( randomint( 3 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__well_im_going_to_follow__") + player.name + " for " + time + BotGetLang("lang___seconds_") );
					break;

				case 1:
					self BotDoChat( 10, BotGetLang("lang__lets_go_together__") + player.name + BotGetLang("lang____3____") );
					break;

				case 2:
					self BotDoChat( 10, BotGetLang("lang__lets_be_butt_buddies__") + player.name + BotGetLang("lang___and_ill_follow_you__") );
					break;
			}

			break;

		case "stop":
			switch ( randomint( 2 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__well_that_was_fun_following__") + player.name + " for " + time + BotGetLang("lang___seconds_") );
					break;

				case 1:
					self BotDoChat( 10, BotGetLang("lang__im_done_following_that_guy_") );
					break;
			}

			break;
	}
}

/*
	bot_chat_equ_watch
*/
bot_chat_equ_watch( state, wp, weap, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "go":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__going_to_place_a__") + getBaseWeaponName( weap ) );
					break;
			}

			break;

		case "start":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__placed_a__") + getBaseWeaponName( weap ) );
					break;
			}

			break;
	}
}

/*
	bot_chat_nade_watch
*/
bot_chat_nade_watch( state, wp, weap, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "go":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__going_to_throw_a__") + getBaseWeaponName( weap ) );
					break;
			}

			break;

		case "start":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__threw_a__") + getBaseWeaponName( weap ) );
					break;
			}

			break;
	}
}

/*
	bot_chat_jav_watch
*/
bot_chat_jav_watch( state, wp, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "go":
			break;

		case "start":
			break;
	}
}

/*
	bot_chat_throwback_watch
*/
bot_chat_throwback_watch( state, nade, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "start":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__i_am_going_to_throw_back_the_grenade__") );
					break;
			}

			break;

		case "stop":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__i_threw_back_the_grenade__") );
					break;
			}

			break;
	}
}

/*
	bot_chat_tbag_watch
*/
bot_chat_tbag_watch( state, who, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "go":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 50, BotGetLang("lang__im_going_to_go_tbag_xd_") );
					break;
			}

			break;

		case "start":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 50, BotGetLang("lang__im_going_to_tbag_xd_") );
					break;
			}

			break;

		case "stop":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 50, BotGetLang("lang__awwww_yea____how_do_you_like_that__xd_") );
					break;
			}

			break;
	}
}

/*
	bot_chat_rage_watch
*/
bot_chat_rage_watch( state, b, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "start":
			switch ( randomint( 5 ) )
			{
				case 0:
					self BotDoChat( 80, BotGetLang("lang__k_this_is_not_going_as_i_planned__") );
					break;

				case 1:
					self BotDoChat( 80, BotGetLang("lang__screw_this__i_m_out__") );
					break;

				case 2:
					self BotDoChat( 80, BotGetLang("lang__have_fun_being_owned__") );
					break;

				case 3:
					self BotDoChat( 80, BotGetLang("lang__my_team_is_garbage__") );
					break;

				case 4:
					self BotDoChat( 80, BotGetLang("lang__kthxbai_hackers_") );
					break;
			}

			break;
	}
}

/*
	bot_chat_revenge_watch
*/
bot_chat_revenge_watch( state, loc, killer, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "start":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__im_going_to_check_out_my_death_location__") );
					break;
			}

			break;

		case "stop":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__i_checked_out_my_deathlocation____") );
					break;
			}

			break;
	}
}

/*
	bot_chat_heard_target_watch
*/
bot_chat_heard_target_watch( state, heard, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "start":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 5, BotGetLang("lang__i_think_i_hear__") + heard.name + BotGetLang("lang______") );
					break;
			}

			break;

		case "stop":
			switch ( randomint( 1 ) )
			{
				case 0:
					self BotDoChat( 5, BotGetLang("lang__well_i_checked_out__") + heard.name + BotGetLang("lang___s_location____") );
					break;
			}

			break;
	}
}

/*
	bot_chat_uav_target_watch
*/
bot_chat_uav_target_watch( state, heard, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "start":
			break;

		case "stop":
			break;
	}
}

/*
	bot_chat_turret_attack_watch
*/
bot_chat_turret_attack_watch( state, turret, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "go":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 5, BotGetLang("lang__going_to_this_sentry____") );
					break;
			}

			break;

		case "start":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 5, BotGetLang("lang__attacking_this_sentry____") );
					break;
			}

			break;

		case "stop":
			break;
	}
}

/*
	bot_chat_attack_equ_watch
*/
bot_chat_attack_equ_watch( state, equ, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( state )
	{
		case "go_ti":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__going_to_this_ti____") );
					break;
			}

			break;

		case "camp_ti":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__lol_im_camping_this_ti__") );
					break;
			}

			break;

		case "trigger_ti":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 10, BotGetLang("lang__lol_i_destoryed_this_ti__") );
					break;
			}

			break;

		case "start":
			break;

		case "stop":
			break;
	}
}

/*
	bot_chat_dom_watch
*/
bot_chat_dom_watch( state, sub_state, flag, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( sub_state )
	{
		case "spawnkill":
			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "defend":
			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "cap":
			switch ( state )
			{
				case "go":
					break;

				case "start":
					break;

				case "stop":
					break;
			}

			break;
	}
}

/*
	bot_chat_hq_watch
*/
bot_chat_hq_watch( state, sub_state, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( sub_state )
	{
		case "cap":
			switch ( state )
			{
				case "go":
					break;

				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "defend":
			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;
	}
}

/*
	bot_chat_sab_watch
*/
bot_chat_sab_watch( state, sub_state, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( sub_state )
	{
		case "bomb":
			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "defuser":
			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "planter":
			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "plant":
			switch ( state )
			{
				case "go":
					break;

				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "defuse":
			switch ( state )
			{
				case "go":
					break;

				case "start":
					break;

				case "stop":
					break;
			}

			break;
	}
}

/*
	bot_chat_sd_watch
*/
bot_chat_sd_watch( state, sub_state, obj, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( sub_state )
	{
		case "bomb":
			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "defuser":
			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "planter":
			site = obj;

			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "plant":
			site = obj;

			switch ( state )
			{
				case "go":
					break;

				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "defuse":
			switch ( state )
			{
				case "go":
					break;

				case "start":
					break;

				case "stop":
					break;
			}

			break;
	}
}

/*
	bot_chat_cap_watch
*/
bot_chat_cap_watch( state, sub_state, obj, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( sub_state )
	{
		case "their_flag":
			flag = obj;

			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "my_flag":
			flag = obj;

			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "cap":
			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;
	}
}

/*
	bot_chat_dem_watch
*/
bot_chat_dem_watch( state, sub_state, obj, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( sub_state )
	{
		case "defuser":
			site = obj;

			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "planter":
			site = obj;

			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "plant":
			site = obj;

			switch ( state )
			{
				case "go":
					break;

				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "defuse":
			site = obj;

			switch ( state )
			{
				case "go":
					break;

				case "start":
					break;

				case "stop":
					break;
			}

			break;
	}
}

/*
	bot_chat_gtnw_watch
*/
bot_chat_gtnw_watch( state, sub_state, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( sub_state )
	{
		case "cap":
			switch ( state )
			{
				case "go":
					break;

				case "start":
					break;

				case "stop":
					break;
			}

			break;
	}
}

/*
	bot_chat_oneflag_watch
*/
bot_chat_oneflag_watch( state, sub_state, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( sub_state )
	{
		case "cap":
			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "their_flag":
			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;

		case "my_flag":
			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;
	}
}

/*
	bot_chat_arena_watch
*/
bot_chat_arena_watch( state, sub_state, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( sub_state )
	{
		case "cap":
			switch ( state )
			{
				case "go":
					break;

				case "start":
					break;

				case "stop":
					break;
			}

			break;
	}
}

/*
	bot_chat_vip_watch
*/
bot_chat_vip_watch( state, sub_state, c, d, e, f, g )
{
	self endon( "disconnect" );

	switch ( sub_state )
	{
		case "cap":
			switch ( state )
			{
				case "start":
					break;

				case "stop":
					break;
			}

			break;
	}
}
