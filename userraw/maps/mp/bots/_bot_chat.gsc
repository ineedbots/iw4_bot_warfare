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
	Starts things for the bot
*/
start_chat_threads()
{
	self endon( "disconnect" );

	self thread bot_chat_revive_watch();
	self thread bot_chat_killcam_watch();
	self thread bot_chat_stuck_watch();
}

/*
	Revive
*/
bot_chat_revive_watch()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "bot_chat_revive", state, revive );

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
}

/*
	Killcam
*/
bot_chat_killcam_watch()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "bot_chat_killcam", state );

		switch ( state )
		{
			case "start":
				switch ( randomInt( 2 ) )
				{
					case 0:
						self BotDoChat( 10, "WTF?!?!?!! Dude youre a hacker and a half!!" );
						break;

					case 1:
						self BotDoChat( 10, "Haa! Got my fraps ready, time to watch this killcam." );
						break;
				}

				break;

			case "stop":
				switch ( randomInt( 2 ) )
				{
					case 0:
						self BotDoChat( 10, "Wow... Im reporting you!!!" );
						break;

					case 1:
						self BotDoChat( 10, "Got it on fraps!" );
						break;
				}

				break;
		}
	}
}

/*
	Stuck
*/
bot_chat_stuck_watch()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "bot_chat_stuck" );

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
}
