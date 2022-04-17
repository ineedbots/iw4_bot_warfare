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

	if ( mod <= 0.0 || chance <= 0 )
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

	self thread start_chat_watch();
	self thread start_killed_watch();
	self thread start_death_watch();
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
	Got streak
*/
bot_chat_streak( streakCount )
{
	self endon( "disconnect" );

	if ( streakCount == 25 )
	{
		if ( GetDvarInt( "bots_loadout_allow_op" ) )
		{
			if ( self.pers["lastEarnedStreak"] == "nuke" )
			{
				switch ( randomint( 5 ) )
				{
					case 0:
						self BotDoChat( 100, "I GOT A NUKE!!" );
						break;

					case 1:
						self BotDoChat( 100, "NUKEEEEEEEEEEEEEEEEE" );
						break;

					case 2:
						self BotDoChat( 100, "25 killstreak!!!" );
						break;

					case 3:
						self BotDoChat( 100, "NNNNNUUUUUUUUUUKKKKEEE!!! UWDHAWIDMIOGHE" );
						break;

					case 4:
						self BotDoChat( 100, "You guys are getting nuuuuuuked~ x3" );
						break;
				}
			}
			else
			{
				self BotDoChat( 100, "Come on! I would of had a nuke but I don't got it set..." );
			}
		}
		else
		{
			self BotDoChat( 100, "WOW.. I could have a nuke but dumb admin disabled it for bots." );
		}
	}
}

/*
	Say killed stuff
*/
bot_chat_killed_watch( victim )
{
	self endon( "disconnect" );

	message = "";

	switch ( randomint( 42 ) )
	{
		case 0:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Haha take that " + victim.name );
			break;

		case 1:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Who's your daddy!" );
			break;

		case 2:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "O i just kicked your ass " + victim.name + "!!" );
			break;

		case 3:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Better luck next time " + victim.name );
			break;

		case 4:
			message = ( "^" + ( randomint( 6 ) + 1 ) + victim.name + " Is that all you got?" );
			break;

		case 5:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "LOL "  + victim.name + ", l2play" );
			break;

		case 6:
			message = ( "^" + ( randomint( 6 ) + 1 ) + ":)" );
			break;

		case 7:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Im unstoppable!" );
			break;

		case 8:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Wow " + victim.name + " that was a close one!" );
			break;

		case 9:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Haha thank you, thank you very much." );
			break;

		case 10:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "HAHAHAHA LOL" );
			break;

		case 11:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "ROFL you suck " + victim.name + "!!" );
			break;

		case 12:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Wow that was a lucky shot!" );
			break;

		case 13:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Thats right, i totally pwnd your ass!" );
			break;

		case 14:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Don't even think that i am hacking cause that was pure skill!" );
			break;

		case 15:
			message = ( "LOL xD xDDDD " + victim.name + " sucks! HAHA ROFLMAO" );
			break;

		case 16:
			message = ( "Wow that was an easy kill." );
			break;

		case 17:
			message = ( "noob down" );
			break;

		case 18:
			message = ( "Lol u suck " + victim.name );
			break;

		case 19:
			message = ( "PWND!" );
			break;

		case 20:
			message = ( "sit down " + victim.name );
			break;

		case 21:
			message = ( "wow that was close, but i still got you ;)" );
			break;

		case 22:
			message = ( "oooooo! i got u good!" );
			break;

		case 23:
			message = ( "thanks for the streak lol" );
			break;

		case 24:
			message = ( "lol sweet got a kill" );
			break;

		case 25:
			message = ( "Just killed a newb, LOL" );
			break;

		case 26:
			message = ( "lolwtf that was a funny death" );
			break;

		case 27:
			message = ( "i bet " + victim.name + " is using the arrow keys to move." );
			break;

		case 28:
			message = ( "lol its noobs like " + victim.name + " that ruin teams" );
			break;

		case 29:
			message = ( "lolwat was that " + victim.name + "?" );
			break;

		case 30:
			message = ( "haha thanks " + victim.name + ", im at a " + self.pers["cur_kill_streak"] + " streak." );
			break;

		case 31:
			message = ( "lol " + victim.name + " is at a " + victim.pers["cur_death_streak"] + " deathstreak" );
			break;

		case 32:
			message = ( "KLAPPED" );
			break;

		case 33:
			message = ( "oooh get merked " + victim.name );
			break;

		case 34:
			message = ( "i love " + getMapName( getdvar( "mapname" ) ) + "!" );
			break;

		case 35:
			message = ( getMapName( getdvar( "mapname" ) ) + " is my favorite map!" );
			break;

		case 36:
			message = ( "get rekt" );
			break;

		case 37:
			message = ( "lol i rekt " + victim.name );
			break;

		case 38:
			message = ( "lol ur mum can play better than u!" );
			break;

		case 39:
			message = ( victim.name + " just got rekt" );
			break;

		case 40:
			message = ( "Man, I sure love my " + getBaseWeaponName( victim.attackerData[self.guid].weapon ) + "!" );
			break;

		case 41:
			message = ( "lol u got killed " + victim.name + ", kek" );
			break;
	}

	wait ( randomint( 3 ) + 1 );
	self BotDoChat( 10, message );
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
	Does death chat
*/
bot_chat_death_watch( killer, last_ks )
{
	self endon( "disconnect" );

	message = "";

	switch ( randomint( 68 ) )
	{
		case 0:
			message = "^" + ( randomint( 6 ) + 1 ) + "Damm, i just got pwnd by " + killer.name;
			break;

		case 1:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Hax ! Hax ! Hax !" );
			break;

		case 2:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "WOW n1 " + killer.name );
			break;

		case 3:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "How the?? How did you do that "  + killer.name + "?" );
			break;

		case 4:
			if ( last_ks > 0 )
				message = ( "^" + ( randomint( 6 ) + 1 ) + "Nooooooooo my killstreaks!! :( I had a " + last_ks + " killstreak!!" );
			else
				message = ( "man im getting spawn killed, i have a " + self.pers["cur_death_streak"] + " deathstreak!" );

			break;

		case 5:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Stop Spawn KILLING!!!" );
			break;

		case 6:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Haha Well done " + killer.name );
			break;

		case 7:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Agggghhhh " + killer.name + " you are such a noob!!!!" );
			break;

		case 8:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "n1 " + killer.name );
			break;

		case 9:
			message = ( "Sigh at my lag, it's totally killing me.. ^2Just Look at my ^1Ping!" );
			break;

		case 10:
			message = ( "omg wow that was LEGENDARY, well done " + killer.name );
			break;

		case 11:
			message = ( "Today is defnitly not my day" );
			break;

		case 12:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "Aaaaaaaagh!!!" );
			break;

		case 13:
			message = ( "^" + ( randomint( 6 ) + 1 ) + " Dude What the hell, " + killer.name + " is such a HACKER!! " );
			break;

		case 14:
			message = ( "^" + ( randomint( 6 ) + 1 ) + killer.name + " you Wallhacker!" );
			break;

		case 15:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "This is so frustrating!" );
			break;

		case 16:
			message = ( " :O I can't believe that just happened" );
			break;

		case 17:
			message = ( killer.name + " you ^1Noooo^2ooooooooo^3ooooo^5b" );
			break;

		case 18:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "LOL, " + killer.name + " how did you kill me?" );
			break;

		case 19:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "laaaaaaaaaaaaaaaaaaaag" );
			break;

		case 20:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "i hate this map!" );
			break;

		case 21:
			message = ( killer.name + " You tanker!!" );
			break;

		case 22:
			message = ( "Sigh at my isp" );
			break;

		case 23:
			message = ( "^1I'll ^2be ^6back" );
			break;

		case 24:
			message = ( "LoL that was random" );
			break;

		case 25:
			message = ( "ooohh that was so close " + killer.name + " and you know it !! " );
			break;

		case 26:
			message = ( "^" + ( randomint( 6 ) + 1 ) + "rofl" );
			break;

		case 27:
			message = ( "AAAAHHHHH! WTF! IM GOING TO KILL YOU " + killer.name );
			break;

		case 28:
			message = ( "AHH! IM DEAD BECAUSE " + level.players[randomint( level.players.size )].name + " is a noob!" );
			break;

		case 29:
			message = ( level.players[randomint( level.players.size )].name + ", please don't talk." );
			break;

		case 30:
			message = ( "Wow " + level.players[randomint( level.players.size )].name + " is a blocker noob!" );
			break;

		case 31:
			message = ( "Next time GET OUT OF MY WAY " + level.players[randomint( level.players.size )].name + "!!" );
			break;

		case 32:
			message = ( "Wow, I'm dead because " + killer.name + " is a tryhard..." );
			break;

		case 33:
			message = ( "Try harder " + killer.name + " please!" );
			break;

		case 34:
			message = ( "I bet " + killer.name + "'s fingers are about to break." );
			break;

		case 35:
			message = ( "WOW, USE A REAL GUN " + killer.name + "!" );
			break;

		case 36:
			message = ( "k wtf. " + killer.name + " is hacking" );
			break;

		case 37:
			message = ( "nice wallhacks " + killer.name );
			break;

		case 38:
			message = ( "wh " + killer.name );
			break;

		case 39:
			message = ( "cheetos!" );
			break;

		case 40:
			message = ( "wow " + getMapName( getdvar( "mapname" ) ) + " is messed up" );
			break;

		case 41:
			message = ( "lolwtf was that " + killer.name + "?" );
			break;

		case 42:
			message = ( "admin pls ban " + killer.name );
			break;

		case 43:
			message = ( "WTF IS WITH THESE SPAWNS??" );
			break;

		case 44:
			message = ( "im getting owned lol..." );
			break;

		case 45:
			message = ( "someone kill " + killer.name + ", they are on a streak of " + killer.pers["cur_kill_streak"] + "!" );
			break;

		case 46:
			message = ( "man i died" );
			break;

		case 47:
			message = ( "nice noob gun " + killer.name );
			break;

		case 48:
			message = ( "stop camping " + killer.name + "!" );
			break;

		case 49:
			message = ( "k THERE IS NOTHING I CAN DO ABOUT DYING!!" );
			break;

		case 50:
			message = ( "aw" );
			break;

		case 51:
			message = ( "lol " + getMapName( getdvar( "mapname" ) ) + " sux" );
			break;

		case 52:
			message = ( "why are we even playing on " + getMapName( getdvar( "mapname" ) ) + "?" );
			break;

		case 53:
			message = ( getMapName( getdvar( "mapname" ) ) + " is such an unfair map!!" );
			break;

		case 54:
			message = ( "what were they thinking when making " + getMapName( getdvar( "mapname" ) ) + "?!" );
			break;

		case 55:
			message = ( killer.name + " totally just destroyed me!" );
			break;

		case 56:
			message = ( "can i be admen plz? so i can ban " + killer.name );
			break;

		case 57:
			message = ( "wow " + killer.name + " is such a no life!!" );
			break;

		case 58:
			message = ( "man i got rekt by " + killer.name );
			break;

		case 59:
			message = ( "admen pls ben " + killer.name );
			break;

		case 60:
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
			message = ( "nice aimbot " + killer.name + "!!1" );
			break;

		case 66:
			message = ( "you are benned " + killer.name + "!!" );
			break;

		case 67:
			message = ( "that was topkek " + killer.name );
			break;
	}

	wait ( randomint( 3 ) + 1 );
	self BotDoChat( 15, message );
}

/*
	Starts things for the bot
*/
start_chat_watch()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "bot_chat", msg, a, b, c, d, e, f, g );

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
		}
	}
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
					self BotDoChat( 10, "i am going to revive " + revive.name );
					break;
			}

			break;

		case "start":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "i am reviving " + revive.name );
					break;
			}

			break;

		case "stop":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "i revived " + revive.name );
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
					self BotDoChat( 3, "WTF?!?!?!! Dude youre a hacker and a half!!" );
					break;

				case 1:
					self BotDoChat( 2, "Haa! Got my fraps ready, time to watch this killcam." );
					break;
			}

			break;

		case "stop":
			switch ( randomInt( 2 ) )
			{
				case 0:
					self BotDoChat( 3, "Wow... Im reporting you!!!" );
					break;

				case 1:
					self BotDoChat( 2, "Got it on fraps!" );
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

	self BotDoChat( 50, msg );
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
					self BotDoChat( 10, "i am going to go tube" );
					break;
			}

			break;

		case "start":
			switch ( randomInt( 1 ) )
			{
				case 0:
					self BotDoChat( 10, "i tubed" );
					break;
			}

			break;
	}
}
