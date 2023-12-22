/*
	_bot_internal
	Author: INeedGames
	Date: 09/26/2020
	The interal workings of the bots.
	Bots will do the basics, aim, move.
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

/*
	When a bot is added (once ever) to the game (before connected).
	We init all the persistent variables here.
*/
added()
{
	self endon( "disconnect" );

	self.pers[ "bots" ] = [];

	self.pers[ "bots" ][ "skill" ] = [];
	self.pers[ "bots" ][ "skill" ][ "base" ] = 7; // a base knownledge of the bot
	self.pers[ "bots" ][ "skill" ][ "aim_time" ] = 0.05; // how long it takes for a bot to aim to a location
	self.pers[ "bots" ][ "skill" ][ "init_react_time" ] = 0; // the reaction time of the bot for inital targets
	self.pers[ "bots" ][ "skill" ][ "reaction_time" ] = 0; // reaction time for the bots of reoccuring targets
	self.pers[ "bots" ][ "skill" ][ "no_trace_ads_time" ] = 2500; // how long a bot ads's when they cant see the target
	self.pers[ "bots" ][ "skill" ][ "no_trace_look_time" ] = 10000; // how long a bot will look at a target's last position
	self.pers[ "bots" ][ "skill" ][ "remember_time" ] = 25000; // how long a bot will remember a target before forgetting about it when they cant see the target
	self.pers[ "bots" ][ "skill" ][ "fov" ] = -1; // the fov of the bot, -1 being 360, 1 being 0
	self.pers[ "bots" ][ "skill" ][ "dist_max" ] = 100000 * 2; // the longest distance a bot will target
	self.pers[ "bots" ][ "skill" ][ "dist_start" ] = 100000; // the start distance before bot's target abilitys diminish
	self.pers[ "bots" ][ "skill" ][ "spawn_time" ] = 0; // how long a bot waits after spawning before targeting, etc
	self.pers[ "bots" ][ "skill" ][ "help_dist" ] = 10000; // how far a bot has awareness
	self.pers[ "bots" ][ "skill" ][ "semi_time" ] = 0.05; // how fast a bot shoots semiauto
	self.pers[ "bots" ][ "skill" ][ "shoot_after_time" ] = 1; // how long a bot shoots after target dies/cant be seen
	self.pers[ "bots" ][ "skill" ][ "aim_offset_time" ] = 1; // how long a bot correct's their aim after targeting
	self.pers[ "bots" ][ "skill" ][ "aim_offset_amount" ] = 1; // how far a bot's incorrect aim is
	self.pers[ "bots" ][ "skill" ][ "bone_update_interval" ] = 0.05; // how often a bot changes their bone target
	self.pers[ "bots" ][ "skill" ][ "bones" ] = "j_head"; // a list of comma seperated bones the bot will aim at
	self.pers[ "bots" ][ "skill" ][ "ads_fov_multi" ] = 0.5; // a factor of how much ads to reduce when adsing
	self.pers[ "bots" ][ "skill" ][ "ads_aimspeed_multi" ] = 0.5; // a factor of how much more aimspeed delay to add

	self.pers[ "bots" ][ "behavior" ] = [];
	self.pers[ "bots" ][ "behavior" ][ "strafe" ] = 50; // percentage of how often the bot strafes a target
	self.pers[ "bots" ][ "behavior" ][ "nade" ] = 50; // percentage of how often the bot will grenade
	self.pers[ "bots" ][ "behavior" ][ "sprint" ] = 50; // percentage of how often the bot will sprint
	self.pers[ "bots" ][ "behavior" ][ "camp" ] = 50; // percentage of how often the bot will camp
	self.pers[ "bots" ][ "behavior" ][ "follow" ] = 50; // percentage of how often the bot will follow
	self.pers[ "bots" ][ "behavior" ][ "crouch" ] = 10; // percentage of how often the bot will crouch
	self.pers[ "bots" ][ "behavior" ][ "switch" ] = 1; // percentage of how often the bot will switch weapons
	self.pers[ "bots" ][ "behavior" ][ "class" ] = 1; // percentage of how often the bot will change classes
	self.pers[ "bots" ][ "behavior" ][ "jump" ] = 100; // percentage of how often the bot will jumpshot and dropshot

	self.pers[ "bots" ][ "behavior" ][ "quickscope" ] = false; // is a quickscoper
	self.pers[ "bots" ][ "behavior" ][ "initswitch" ] = 10; // percentage of how often the bot will switch weapons on spawn

	self.pers[ "bots" ][ "unlocks" ] = [];
}

/*
	When a bot connects to the game.
	This is called when a bot is added and when multiround gamemode starts.
*/
connected()
{
	self endon( "disconnect" );

	self.bot = spawnstruct();

	self resetBotVars();

	self thread onPlayerSpawned();
}

/*
	The callback hook for when the bot gets killed.
*/
onKilled( eInflictor, eAttacker, iDamage, sMeansOfDeath, sWeapon, vDir, sHitLoc, timeOffset, deathAnimDuration )
{
}

/*
	The callback hook when the bot gets damaged.
*/
onDamage( eInflictor, eAttacker, iDamage, iDFlags, sMeansOfDeath, sWeapon, vPoint, vDir, sHitLoc, timeOffset )
{
}

/*
	We clear all of the script variables and other stuff for the bots.
*/
resetBotVars()
{
	self.bot.script_target = undefined;
	self.bot.script_target_offset = undefined;
	self.bot.targets = [];
	self.bot.target = undefined;
	self.bot.target_this_frame = undefined;
	self.bot.jav_loc = undefined;
	self.bot.after_target = undefined;
	self.bot.after_target_pos = undefined;

	self.bot.script_aimpos = undefined;

	self.bot.script_goal = undefined;
	self.bot.script_goal_dist = 0.0;

	self.bot.next_wp = -1;
	self.bot.second_next_wp = -1;
	self.bot.towards_goal = undefined;
	self.bot.astar = [];
	self.bot.moveto = self.origin;
	self.bot.stop_move = false;
	self.bot.greedy_path = false;
	self.bot.climbing = false;
	self.bot.wantsprint = false;
	self.bot.last_next_wp = -1;
	self.bot.last_second_next_wp = -1;

	self.bot.isfrozen = false;
	self.bot.sprintendtime = -1;
	self.bot.isreloading = false;
	self.bot.issprinting = false;
	self.bot.isfragging = false;
	self.bot.issmoking = false;
	self.bot.isfraggingafter = false;
	self.bot.issmokingafter = false;
	self.bot.isknifing = false;
	self.bot.isknifingafter = false;
	self.bot.knifing_target = undefined;

	self.bot.semi_time = false;
	self.bot.jump_time = undefined;
	self.bot.last_fire_time = -1;

	self.bot.is_cur_full_auto = false;
	self.bot.cur_weap_dist_multi = 1;
	self.bot.is_cur_sniper = false;
	self.bot.is_cur_akimbo = false;

	self.bot.prio_objective = false;

	self.bot.rand = randomint( 100 );

	self BotBuiltinBotStop();
}

/*
	When the bot spawns.
*/
onPlayerSpawned()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "spawned_player" );

		self resetBotVars();
		self thread onWeaponChange();
		self thread onLastStand();

		self thread reload_watch();
		self thread sprint_watch();

		self thread watchUsingRemote();

		self thread spawned();
	}
}

/*
	Sets the factor of distance for a weapon
*/
SetWeaponDistMulti( weap )
{
	if ( weap == "none" )
	{
		return 1;
	}

	switch ( weaponclass( weap ) )
	{
		case "rifle":
			return 0.9;

		case "smg":
			return 0.7;

		case "pistol":
			return 0.5;

		default:
			return 1;
	}
}

/*
	Is the weap a sniper
*/
IsWeapSniper( weap )
{
	if ( weap == "none" )
	{
		return false;
	}

	if ( weaponclass( weap ) != "sniper" )
	{
		return false;
	}

	return true;
}

/*
	When the bot changes weapon.
*/
onWeaponChange()
{
	self endon( "disconnect" );
	self endon( "death" );

	first = true;

	for ( ;; )
	{
		newWeapon = undefined;

		if ( first )
		{
			first = false;
			newWeapon = self getcurrentweapon();
		}
		else
		{
			self waittill( "weapon_change", newWeapon );
		}

		self.bot.is_cur_full_auto = WeaponIsFullAuto( newWeapon );
		self.bot.cur_weap_dist_multi = SetWeaponDistMulti( newWeapon );
		self.bot.is_cur_sniper = IsWeapSniper( newWeapon );
		self.bot.is_cur_akimbo = issubstr( newWeapon, "_akimbo_" );
	}
}

/*
	Update's the bot if it is reloading.
*/
reload_watch_loop()
{
	self.bot.isreloading = true;

	while ( true )
	{
		ret = self waittill_any_timeout( 7.5, "reload" );

		if ( ret == "timeout" )
		{
			break;
		}

		weap = self getcurrentweapon();

		if ( weap == "none" )
		{
			break;
		}

		if ( self getweaponammoclip( weap ) >= weaponclipsize( weap ) )
		{
			break;
		}
	}

	self.bot.isreloading = false;
}

/*
	Update's the bot if it is reloading.
*/
reload_watch()
{
	self endon( "disconnect" );
	self endon( "death" );

	for ( ;; )
	{
		self waittill( "reload_start" );
		self reload_watch_loop();
	}
}

/*
	Updates the bot if it is sprinting.
*/
sprint_watch()
{
	self endon( "disconnect" );
	self endon( "death" );

	for ( ;; )
	{
		self waittill( "sprint_begin" );
		self.bot.issprinting = true;
		self waittill( "sprint_end" );
		self.bot.issprinting = false;
		self.bot.sprintendtime = gettime();
	}
}

/*
	When the bot enters laststand, we fix the weapons
*/
onLastStand()
{
	self endon( "disconnect" );
	self endon( "death" );

	while ( true )
	{
		while ( !self inLastStand() )
		{
			wait 0.05;
		}

		self notify( "kill_goal" );

		while ( self inLastStand() )
		{
			wait 0.05;
		}
	}
}

/*
	When the bot uses a remote killstreak
*/
watchUsingRemote()
{
	self endon( "disconnect" );
	self endon( "spawned_player" );

	for ( ;; )
	{
		wait 1;

		if ( !isalive( self ) )
		{
			return;
		}

		if ( !self isusingremote() )
		{
			continue;
		}

		if ( isdefined( level.chopper ) && isdefined( level.chopper.gunner ) && level.chopper.gunner == self )
		{
			self watchUsingMinigun();
		}

		if ( isdefined( level.ac130player ) && level.ac130player == self )
		{
			self thread watchAc130Weapon();
			self watchUsingAc130();
		}

		self.bot.targets = [];
		self notify( "kill_goal" );
	}
}

/*
	WHen it uses the helicopter minigun
*/
watchUsingMinigun()
{
	self endon( "heliPlayer_removed" );

	while ( isdefined( level.chopper ) && isdefined( level.chopper.gunner ) && level.chopper.gunner == self )
	{
		if ( self getcurrentweapon() != "heli_remote_mp" )
		{
			self switchtoweapon( "heli_remote_mp" );
		}

		if ( isdefined( self.bot.target ) )
		{
			self thread pressFire();
		}

		wait 0.05;
	}
}

/*
	When it uses the ac130
*/
watchAc130Weapon()
{
	self endon( "ac130player_removed" );
	self endon( "disconnect" );
	self endon( "spawned_player" );

	while ( isdefined( level.ac130player ) && level.ac130player == self )
	{
		curWeap = self getcurrentweapon();

		if ( curWeap != "ac130_105mm_mp" && curWeap != "ac130_40mm_mp" && curWeap != "ac130_25mm_mp" )
		{
			self switchtoweapon( "ac130_105mm_mp" );
		}

		if ( isdefined( self.bot.target ) )
		{
			self thread pressFire();
		}

		wait 0.05;
	}
}

/*
	Swap between the ac130 weapons while in it
*/
watchUsingAc130()
{
	self endon( "ac130player_removed" );

	while ( isdefined( level.ac130player ) && level.ac130player == self )
	{
		self switchtoweapon( "ac130_105mm_mp" );
		wait 1 + randomint( 2 );
		self switchtoweapon( "ac130_40mm_mp" );
		wait 2 + randomint( 2 );
		self switchtoweapon( "ac130_25mm_mp" );
		wait 3 + randomint( 2 );
	}
}

/*
	We wait for a time defined by the bot's difficulty and start all threads that control the bot.
*/
spawned()
{
	self endon( "disconnect" );
	self endon( "death" );

	wait self.pers[ "bots" ][ "skill" ][ "spawn_time" ];

	self thread doBotMovement();

	self thread grenade_danager();
	self thread target();
	self thread updateBones();
	self thread aim();
	self thread check_reload();
	self thread stance();
	self thread onNewEnemy();
	self thread walk();
	self thread watchHoldBreath();
	self thread watchGrenadeFire();
	self thread watchPickupGun();

	self notify( "bot_spawned" );
}

/*
	watchPickupGun
*/
watchPickupGun()
{
	self endon( "disconnect" );
	self endon( "death" );

	for ( ;; )
	{
		wait 1;

		if ( self usebuttonpressed() )
		{
			continue;
		}

		weap = self getcurrentweapon();

		if ( weap != "none" && self getammocount( weap ) )
		{
			continue;
		}

		self thread use( 0.5 );
	}
}

/*
	Watches when the bot fires a grenade
*/
watchGrenadeFire()
{
	self endon( "disconnect" );
	self endon( "death" );

	for ( ;; )
	{
		self waittill( "grenade_fire", nade, weapname );

		if ( !isdefined( nade ) )
		{
			continue;
		}

		if ( weapname == "c4_mp" )
		{
			self thread watchC4Thrown( nade );
		}
	}
}

/*
	Watches the c4
*/
watchC4Thrown( c4 )
{
	self endon( "disconnect" );
	c4 endon( "death" );

	wait 0.5;

	for ( ;; )
	{
		wait 1 + randomint( 50 ) * 0.05;

		shouldBreak = false;

		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[ i ];

			if ( player == self )
			{
				continue;
			}

			if ( ( level.teambased && self.team == player.team ) || player.sessionstate != "playing" || !isreallyalive( player ) )
			{
				continue;
			}

			if ( distancesquared( c4.origin, player.origin ) > 200 * 200 )
			{
				continue;
			}

			if ( !bullettracepassed( c4.origin, player.origin + ( 0, 0, 25 ), false, c4 ) )
			{
				continue;
			}

			shouldBreak = true;
		}

		if ( shouldBreak )
		{
			break;
		}
	}

	if ( self getcurrentweapon() != "c4_mp" )
	{
		self notify( "alt_detonate" );
	}
	else
	{
		self thread pressFire();
	}
}

/*
	Bot moves towards the point
*/
doBotMovement_loop( data )
{
	move_To = self.bot.moveto;
	angles = self getplayerangles();
	dir = ( 0, 0, 0 );

	if ( distancesquared( self.origin, move_To ) >= 49 )
	{
		cosa = cos( 0 - angles[ 1 ] );
		sina = sin( 0 - angles[ 1 ] );

		// get the direction
		dir = move_To - self.origin;

		// rotate our direction according to our angles
		dir = ( dir[ 0 ] * cosa - dir[ 1 ] * sina,
		        dir[ 0 ] * sina + dir[ 1 ] * cosa,
		        0 );

		// make the length 127
		dir = vectornormalize( dir ) * 127;

		// invert the second component as the engine requires this
		dir = ( dir[ 0 ], 0 - dir[ 1 ], 0 );
	}

	// climb through windows
	if ( self ismantling() )
	{
		data.wasmantling = true;
		self crouch();
	}
	else if ( data.wasmantling )
	{
		data.wasmantling = false;
		self stand();
	}

	startPos = self.origin + ( 0, 0, 50 );
	startPosForward = startPos + anglestoforward( ( 0, angles[ 1 ], 0 ) ) * 25;
	bt = bullettrace( startPos, startPosForward, false, self );

	if ( bt[ "fraction" ] >= 1 )
	{
		// check if need to jump
		bt = bullettrace( startPosForward, startPosForward - ( 0, 0, 40 ), false, self );

		if ( bt[ "fraction" ] < 1 && bt[ "normal" ][ 2 ] > 0.9 && data.i > 1.5 && !self isonladder() )
		{
			data.i = 0;
			self thread jump();
		}
	}
	// check if need to knife glass
	else if ( bt[ "surfacetype" ] == "glass" )
	{
		if ( data.i > 1.5 )
		{
			data.i = 0;
			self thread knife();
		}
	}
	else
	{
		// check if need to crouch
		if ( bullettracepassed( startPos - ( 0, 0, 25 ), startPosForward - ( 0, 0, 25 ), false, self ) && !self.bot.climbing )
		{
			self crouch();
		}
	}

	// move!
	if ( ( self.bot.wantsprint && self.bot.issprinting ) || isdefined( self.bot.knifing_target ) )
	{
		dir = ( 127, dir[ 1 ], 0 );
	}

	self BotBuiltinBotMovement( int( dir[ 0 ] ), int( dir[ 1 ] ) );
}

/*
	Bot moves towards the point
*/
doBotMovement()
{
	self endon( "disconnect" );
	self endon( "death" );

	data = spawnstruct();
	data.wasmantling = false;

	for ( data.i = 0; true; data.i += 0.05 )
	{
		wait 0.05;

		waittillframeend;
		self doBotMovement_loop( data );
	}
}

/*
	The hold breath thread.
*/
watchHoldBreath()
{
	self endon( "disconnect" );
	self endon( "death" );

	for ( ;; )
	{
		wait 1;

		if ( self.bot.isfrozen )
		{
			continue;
		}

		self holdbreath( self playerads() > 0 );
	}
}

/*
	Throws back frag grenades
*/
grenade_danager_loop()
{
	myEye = self geteye();

	for ( i = level.bots_fraglist.count - 1; i >= 0; i-- )
	{
		frag = level.bots_fraglist.data[ i ];

		if ( level.teambased && frag.team == self.team )
		{
			continue;
		}

		if ( lengthsquared( frag.velocity ) > 10000 )
		{
			continue;
		}

		if ( distancesquared( self.origin, frag.origin ) > 20000 )
		{
			continue;
		}

		if ( !bullettracepassed( myEye, frag.origin, false, frag.grenade ) )
		{
			continue;
		}

		self BotNotifyBotEvent( "throwback", "stop", frag );
		self thread frag();
		break;
	}
}

/*
	Throws back frag grenades
*/
grenade_danager()
{
	self endon( "disconnect" );
	self endon( "death" );

	for ( ;; )
	{
		wait 1;

		if ( self inLastStand() && !self _hasperk( "specialty_laststandoffhand" ) && !self inFinalStand() )
		{
			continue;
		}

		if ( self.bot.isfrozen || level.gameended || !gameflag( "prematch_done" ) )
		{
			continue;
		}

		if ( self.bot.isfraggingafter || self.bot.issmokingafter || self isusingremote() )
		{
			continue;
		}

		if ( self isDefusing() || self isPlanting() )
		{
			continue;
		}

		if ( !getdvarint( "bots_play_nade" ) )
		{
			continue;
		}

		self grenade_danager_loop();
	}
}

/*
	Bots will update its needed stance according to the nodes on the level. Will also allow the bot to sprint when it can.
*/
stance_loop()
{
	toStance = "stand";

	if ( self.bot.next_wp != -1 )
	{
		toStance = level.waypoints[ self.bot.next_wp ].type;
	}

	if ( !isdefined( toStance ) )
	{
		toStance = "crouch";
	}

	if ( toStance == "stand" && randomint( 100 ) <= self.pers[ "bots" ][ "behavior" ][ "crouch" ] )
	{
		toStance = "crouch";
	}

	if ( self.hasriotshieldequipped && isdefined( self.bot.target ) && isdefined( self.bot.target.entity ) && isplayer( self.bot.target.entity ) )
	{
		toStance = "crouch";
	}

	if ( toStance == "climb" )
	{
		self.bot.climbing = true;
		toStance = "stand";
	}

	if ( toStance != "stand" && toStance != "crouch" && toStance != "prone" )
	{
		toStance = "crouch";
	}

	if ( toStance == "stand" )
	{
		self stand();
	}
	else if ( toStance == "crouch" )
	{
		self crouch();
	}
	else
	{
		self prone();
	}

	chance = self.pers[ "bots" ][ "behavior" ][ "sprint" ];

	if ( gettime() - self.lastspawntime < 5000 )
	{
		chance *= 2;
	}

	if ( isdefined( self.bot.script_goal ) && distancesquared( self.origin, self.bot.script_goal ) > 256 * 256 )
	{
		chance *= 2;
	}

	if ( toStance != "stand" || self.bot.isreloading || self.bot.issprinting || self.bot.isfraggingafter || self.bot.issmokingafter )
	{
		return;
	}

	if ( randomint( 100 ) > chance )
	{
		return;
	}

	if ( isdefined( self.bot.target ) && self canFire( self getcurrentweapon() ) && self isInRange( self.bot.target.dist, self getcurrentweapon() ) )
	{
		return;
	}

	if ( self.bot.sprintendtime != -1 && gettime() - self.bot.sprintendtime < 2000 )
	{
		return;
	}

	if ( !isdefined( self.bot.towards_goal ) || distancesquared( self.origin, physicstrace( self geteye(), self geteye() + anglestoforward( self getplayerangles() ) * 1024, false, undefined ) ) < level.bots_minsprintdistance || getConeDot( self.bot.towards_goal, self.origin, self getplayerangles() ) < 0.75 )
	{
		return;
	}

	self thread sprint();
	self thread setBotWantSprint();
}

/*
	Stops the sprint fix when goal is completed
*/
setBotWantSprint()
{
	self endon( "disconnect" );
	self endon( "death" );

	self notify( "setBotWantSprint" );
	self endon( "setBotWantSprint" );

	self.bot.wantsprint = true;

	self waittill_notify_or_timeout( "kill_goal", 10 );

	self.bot.wantsprint = false;
}

/*
	Bots will update its needed stance according to the nodes on the level. Will also allow the bot to sprint when it can.
*/
stance()
{
	self endon( "disconnect" );
	self endon( "death" );

	for ( ;; )
	{
		self waittill_either( "finished_static_waypoints", "new_static_waypoint" );

		self.bot.climbing = false;

		if ( self.bot.isfrozen || self isusingremote() )
		{
			continue;
		}

		self stance_loop();
	}
}

/*
	Bot will wait until firing.
*/
check_reload()
{
	self endon( "disconnect" );
	self endon( "death" );

	for ( ;; )
	{
		self waittill_notify_or_timeout( "weapon_fired", 5 );
		self thread reload_thread();
	}
}

/*
	Bot will reload after firing if needed.
*/
reload_thread()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "weapon_fired" );

	wait 2.5;

	if ( self.bot.isfrozen || level.gameended || !gameflag( "prematch_done" ) )
	{
		return;
	}

	if ( isdefined( self.bot.target ) || self.bot.isreloading || self.bot.isfraggingafter || self.bot.issmokingafter || self.bot.isfrozen )
	{
		return;
	}

	cur = self getcurrentweapon();

	if ( cur == "" || cur == "none" )
	{
		return;
	}

	if ( isweaponcliponly( cur ) || !self getweaponammostock( cur ) || self isusingremote() )
	{
		return;
	}

	maxsize = weaponclipsize( cur );
	cursize = self getweaponammoclip( cur );

	if ( cursize / maxsize < 0.5 )
	{
		self thread reload();
	}
}

/*
	Updates the bot's target bone
*/
updateBones()
{
	self endon( "disconnect" );
	self endon( "spawned_player" );

	bones = strtok( self.pers[ "bots" ][ "skill" ][ "bones" ], "," );
	waittime = self.pers[ "bots" ][ "skill" ][ "bone_update_interval" ];

	for ( ;; )
	{
		self waittill_any_timeout( waittime, "new_enemy" );

		if ( !isalive( self ) )
		{
			return;
		}

		if ( !isdefined( self.bot.target ) )
		{
			continue;
		}

		self.bot.target.bone = random( bones );
	}
}

/*
	Creates the base target obj
*/
createTargetObj( ent, theTime )
{
	obj = spawnstruct();
	obj.entity = ent;
	obj.last_seen_pos = ( 0, 0, 0 );
	obj.dist = 0;
	obj.time = theTime;
	obj.trace_time = 0;
	obj.no_trace_time = 0;
	obj.trace_time_time = 0;
	obj.rand = randomint( 100 );
	obj.didlook = false;
	obj.offset = undefined;
	obj.bone = undefined;
	obj.aim_offset = undefined;
	obj.aim_offset_base = undefined;

	return obj;
}

/*
	Updates the target object's difficulty missing aim, inaccurate shots
*/
updateAimOffset( obj, theTime )
{
	if ( !isdefined( obj.aim_offset_base ) )
	{
		offsetAmount = self.pers[ "bots" ][ "skill" ][ "aim_offset_amount" ];

		if ( offsetAmount > 0 )
		{
			obj.aim_offset_base = ( randomfloatrange( 0 - offsetAmount, offsetAmount ),
			        randomfloatrange( 0 - offsetAmount, offsetAmount ),
			        randomfloatrange( 0 - offsetAmount, offsetAmount ) );
		}
		else
		{
			obj.aim_offset_base = ( 0, 0, 0 );
		}
	}

	aimDiffTime = self.pers[ "bots" ][ "skill" ][ "aim_offset_time" ] * 1000;
	objCreatedFor = obj.trace_time;

	if ( objCreatedFor >= aimDiffTime )
	{
		offsetScalar = 0;
	}
	else
	{
		offsetScalar = 1 - objCreatedFor / aimDiffTime;
	}

	obj.aim_offset = obj.aim_offset_base * offsetScalar;
}

/*
	Updates the target object to be traced Has LOS
*/
targetObjUpdateTraced( obj, daDist, ent, theTime, isScriptObj, usingRemote )
{
	distClose = self.pers[ "bots" ][ "skill" ][ "dist_start" ];
	distClose *= self.bot.cur_weap_dist_multi;
	distClose *= distClose;

	distMax = self.pers[ "bots" ][ "skill" ][ "dist_max" ];
	distMax *= self.bot.cur_weap_dist_multi;
	distMax *= distMax;

	timeMulti = 1;

	if ( !usingRemote && !isScriptObj )
	{
		if ( daDist > distMax )
		{
			timeMulti = 0;
		}
		else if ( daDist > distClose )
		{
			timeMulti = 1 - ( ( daDist - distClose ) / ( distMax - distClose ) );
		}
	}

	obj.no_trace_time = 0;
	obj.trace_time += int( 50 * timeMulti );
	obj.dist = daDist;
	obj.last_seen_pos = ent.origin;
	obj.trace_time_time = theTime;

	self updateAimOffset( obj, theTime );
}

/*
	Updates the target object to be not traced No LOS
*/
targetObjUpdateNoTrace( obj )
{
	obj.no_trace_time += 50;
	obj.trace_time = 0;
	obj.didlook = false;
}

/*
	The main target thread, will update the bot's main target. Will auto target enemy players and handle script targets.
*/
target_loop()
{
	myEye = self geteye();
	theTime = gettime();
	myAngles = self getplayerangles();
	myFov = self.pers[ "bots" ][ "skill" ][ "fov" ];
	bestTargets = [];
	bestTime = 2147483647;
	rememberTime = self.pers[ "bots" ][ "skill" ][ "remember_time" ];
	initReactTime = self.pers[ "bots" ][ "skill" ][ "init_react_time" ];
	hasTarget = isdefined( self.bot.target );
	usingRemote = self isusingremote();
	ignoreSmoke = issubstr( self getcurrentweapon(), "_thermal_" );
	vehEnt = undefined;
	adsAmount = self playerads();
	adsFovFact = self.pers[ "bots" ][ "skill" ][ "ads_fov_multi" ];

	if ( usingRemote )
	{
		if ( isdefined( level.ac130player ) && level.ac130player == self )
		{
			vehEnt = level.ac130.planemodel;
		}

		if ( isdefined( level.chopper ) && isdefined( level.chopper.gunner ) && level.chopper.gunner == self )
		{
			vehEnt = level.chopper;
		}
	}

	// reduce fov if ads'ing
	if ( adsAmount > 0 )
	{
		myFov *= 1 - adsFovFact * adsAmount;
	}

	if ( hasTarget && !isdefined( self.bot.target.entity ) )
	{
		self.bot.target = undefined;
		hasTarget = false;
	}

	playercount = level.players.size;

	for ( i = -1; i < playercount; i++ )
	{
		obj = undefined;

		if ( i == -1 )
		{
			if ( !isdefined( self.bot.script_target ) )
			{
				continue;
			}

			ent = self.bot.script_target;
			key = ent getentitynumber() + "";
			daDist = distancesquared( self.origin, ent.origin );
			obj = self.bot.targets[ key ];
			isObjDef = isdefined( obj );
			entOrigin = ent.origin;

			if ( isdefined( self.bot.script_target_offset ) )
			{
				entOrigin += self.bot.script_target_offset;
			}

			if ( ignoreSmoke || ( SmokeTrace( myEye, entOrigin, level.smokeradius ) ) && bullettracepassed( myEye, entOrigin, false, ent ) )
			{
				if ( !isObjDef )
				{
					obj = self createTargetObj( ent, theTime );
					obj.offset = self.bot.script_target_offset;

					self.bot.targets[ key ] = obj;
				}

				self targetObjUpdateTraced( obj, daDist, ent, theTime, true, usingRemote );
			}
			else
			{
				if ( !isObjDef )
				{
					continue;
				}

				self targetObjUpdateNoTrace( obj );

				if ( obj.no_trace_time > rememberTime )
				{
					self.bot.targets[ key ] = undefined;
					continue;
				}
			}
		}
		else
		{
			player = level.players[ i ];

			if ( player == self )
			{
				continue;
			}

			key = player getentitynumber() + "";
			obj = self.bot.targets[ key ];

			daDist = distancesquared( self.origin, player.origin );

			if ( usingRemote )
			{
				daDist = 0;
			}

			isObjDef = isdefined( obj );

			if ( ( level.teambased && self.team == player.team ) || player.sessionstate != "playing" || !isreallyalive( player ) )
			{
				if ( isObjDef )
				{
					self.bot.targets[ key ] = undefined;
				}

				continue;
			}

			canTargetPlayer = false;

			if ( usingRemote )
			{
				canTargetPlayer = ( bullettracepassed( myEye, player gettagorigin( "j_head" ), false, vehEnt )
				        && !player _hasperk( "specialty_coldblooded" ) );
			}
			else
			{
				targetHead = player gettagorigin( "j_head" );
				targetAnkleLeft = player gettagorigin( "j_ankle_le" );
				targetAnkleRight = player gettagorigin( "j_ankle_ri" );

				traceHead = bullettrace( myEye, targetHead, false, undefined );
				traceAnkleLeft = bullettrace( myEye, targetAnkleLeft, false, undefined );
				traceAnkleRight = bullettrace( myEye, targetAnkleRight, false, undefined );

				canTargetPlayer = ( ( sighttracepassed( myEye, targetHead, false, undefined ) ||
				            sighttracepassed( myEye, targetAnkleLeft, false, undefined ) ||
				            sighttracepassed( myEye, targetAnkleRight, false, undefined ) )

				        && ( ( traceHead[ "fraction" ] >= 1.0 || traceHead[ "surfacetype" ] == "glass" ) ||
				            ( traceAnkleLeft[ "fraction" ] >= 1.0 || traceAnkleLeft[ "surfacetype" ] == "glass" ) ||
				            ( traceAnkleRight[ "fraction" ] >= 1.0 || traceAnkleRight[ "surfacetype" ] == "glass" ) )

				        && ( ignoreSmoke ||
				            SmokeTrace( myEye, player.origin, level.smokeradius ) ||
				            daDist < level.bots_maxknifedistance * 4 )

				        && ( getConeDot( player.origin, self.origin, myAngles ) >= myFov ||
				            ( isObjDef && obj.trace_time ) ) );
			}

			if ( isdefined( self.bot.target_this_frame ) && self.bot.target_this_frame == player )
			{
				self.bot.target_this_frame = undefined;

				canTargetPlayer = true;
			}

			if ( canTargetPlayer )
			{
				if ( !isObjDef )
				{
					obj = self createTargetObj( player, theTime );

					self.bot.targets[ key ] = obj;
				}

				self targetObjUpdateTraced( obj, daDist, player, theTime, false, usingRemote );
			}
			else
			{
				if ( !isObjDef )
				{
					continue;
				}

				self targetObjUpdateNoTrace( obj );

				if ( obj.no_trace_time > rememberTime )
				{
					self.bot.targets[ key ] = undefined;
					continue;
				}
			}
		}

		if ( !isdefined( obj ) )
		{
			continue;
		}

		if ( theTime - obj.time < initReactTime )
		{
			continue;
		}

		timeDiff = theTime - obj.trace_time_time;

		if ( timeDiff < bestTime )
		{
			bestTargets = [];
			bestTime = timeDiff;
		}

		if ( timeDiff == bestTime )
		{
			bestTargets[ key ] = obj;
		}
	}

	if ( hasTarget && isdefined( bestTargets[ self.bot.target.entity getentitynumber() + "" ] ) )
	{
		return;
	}

	closest = 2147483647;
	toBeTarget = undefined;

	bestKeys = getarraykeys( bestTargets );

	for ( i = bestKeys.size - 1; i >= 0; i-- )
	{
		theDist = bestTargets[ bestKeys[ i ] ].dist;

		if ( theDist > closest )
		{
			continue;
		}

		closest = theDist;
		toBeTarget = bestTargets[ bestKeys[ i ] ];
	}

	beforeTargetID = -1;
	newTargetID = -1;

	if ( hasTarget && isdefined( self.bot.target.entity ) )
	{
		beforeTargetID = self.bot.target.entity getentitynumber();
	}

	if ( isdefined( toBeTarget ) && isdefined( toBeTarget.entity ) )
	{
		newTargetID = toBeTarget.entity getentitynumber();
	}

	if ( beforeTargetID != newTargetID )
	{
		self.bot.target = toBeTarget;
		self notify( "new_enemy" );
	}
}

/*
	The main target thread, will update the bot's main target. Will auto target enemy players and handle script targets.
*/
target()
{
	self endon( "disconnect" );
	self endon( "spawned_player" );

	for ( ;; )
	{
		wait 0.05;

		if ( !isalive( self ) )
		{
			return;
		}

		if ( self maps\mp\_flashgrenades::isflashbanged() )
		{
			continue;
		}

		self target_loop();
	}
}

/*
	When the bot gets a new enemy.
*/
onNewEnemy()
{
	self endon( "disconnect" );
	self endon( "death" );

	for ( ;; )
	{
		self waittill( "new_enemy" );

		if ( !isdefined( self.bot.target ) )
		{
			continue;
		}

		if ( !isdefined( self.bot.target.entity ) || !isplayer( self.bot.target.entity ) )
		{
			continue;
		}

		if ( self.bot.target.didlook )
		{
			continue;
		}

		self thread watchToLook();
	}
}

/*
	Bots will jump or dropshot their enemy player.
*/
watchToLook()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "new_enemy" );

	for ( ;; )
	{
		while ( isdefined( self.bot.target ) && self.bot.target.didlook )
		{
			wait 0.05;
		}

		while ( isdefined( self.bot.target ) && self.bot.target.no_trace_time )
		{
			wait 0.05;
		}

		if ( !isdefined( self.bot.target ) )
		{
			break;
		}

		self.bot.target.didlook = true;

		if ( self.bot.isfrozen )
		{
			continue;
		}

		if ( self.bot.target.dist > level.bots_maxshotgundistance * 2 )
		{
			continue;
		}

		if ( self.bot.target.dist <= level.bots_maxknifedistance )
		{
			continue;
		}

		if ( !self canFire( self getcurrentweapon() ) )
		{
			continue;
		}

		if ( !self isInRange( self.bot.target.dist, self getcurrentweapon() ) )
		{
			continue;
		}

		if ( self.bot.is_cur_sniper )
		{
			continue;
		}

		if ( randomint( 100 ) > self.pers[ "bots" ][ "behavior" ][ "jump" ] )
		{
			continue;
		}

		if ( !getdvarint( "bots_play_jumpdrop" ) )
		{
			continue;
		}

		if ( isdefined( self.bot.jump_time ) && gettime() - self.bot.jump_time <= 5000 )
		{
			continue;
		}

		if ( self.bot.target.rand <= self.pers[ "bots" ][ "behavior" ][ "strafe" ] )
		{
			if ( self getstance() != "stand" )
			{
				continue;
			}

			self.bot.jump_time = gettime();
			self thread jump();
		}
		else
		{
			if ( getConeDot( self.bot.target.last_seen_pos, self.origin, self getplayerangles() ) < 0.8 || self.bot.target.dist <= level.bots_noadsdistance )
			{
				continue;
			}

			self.bot.jump_time = gettime();
			self prone();
			self notify( "kill_goal" );
			wait 2.5;
			self crouch();
		}
	}
}

/*
	Assigns the bot's after target (bot will keep firing at a target after no sight or death)
*/
start_bot_after_target( who )
{
	self endon( "disconnect" );
	self endon( "spawned_player" );

	self.bot.after_target = who;
	self.bot.after_target_pos = who.origin;

	self notify( "kill_after_target" );
	self endon( "kill_after_target" );

	wait self.pers[ "bots" ][ "skill" ][ "shoot_after_time" ];

	self.bot.after_target = undefined;
}

/*
	Clears the bot's after target
*/
clear_bot_after_target()
{
	self.bot.after_target = undefined;
	self notify( "kill_after_target" );
}

/*
	This is the bot's main aimming thread. The bot will aim at its targets or a node its going towards. Bots will aim, fire, ads, grenade.
*/
aim_loop()
{
	aimspeed = self.pers[ "bots" ][ "skill" ][ "aim_time" ];

	if ( self isStunned() || self isArtShocked() )
	{
		aimspeed = 1;
	}

	usingRemote = self isusingremote();
	curweap = self getcurrentweapon();
	eyePos = self geteye();
	angles = self getplayerangles();
	adsAmount = self playerads();
	adsAimSpeedFact = self.pers[ "bots" ][ "skill" ][ "ads_aimspeed_multi" ];

	// reduce aimspeed if ads'ing
	if ( adsAmount > 0 )
	{
		aimspeed *= 1 + adsAimSpeedFact * adsAmount;
	}

	if ( isdefined( self.bot.jav_loc ) && !usingRemote )
	{
		aimpos = self.bot.jav_loc;

		self thread bot_lookat( aimpos, aimspeed );
		self thread pressADS();

		if ( curweap == "javelin_mp" && getdvarint( "bots_play_fire" ) )
		{
			self botFire( curweap );
		}

		return;
	}

	if ( isdefined( self.bot.target ) && isdefined( self.bot.target.entity ) && !( self.bot.prio_objective && isdefined( self.bot.script_aimpos ) ) )
	{
		no_trace_look_time = self.pers[ "bots" ][ "skill" ][ "no_trace_look_time" ];
		no_trace_time = self.bot.target.no_trace_time;

		if ( no_trace_time <= no_trace_look_time )
		{
			trace_time = self.bot.target.trace_time;
			last_pos = self.bot.target.last_seen_pos;
			target = self.bot.target.entity;
			conedot = 0;
			isplay = isplayer( self.bot.target.entity );

			offset = self.bot.target.offset;

			if ( !isdefined( offset ) )
			{
				offset = ( 0, 0, 0 );
			}

			aimoffset = self.bot.target.aim_offset;

			if ( !isdefined( aimoffset ) )
			{
				aimoffset = ( 0, 0, 0 );
			}

			dist = self.bot.target.dist;
			rand = self.bot.target.rand;
			no_trace_ads_time = self.pers[ "bots" ][ "skill" ][ "no_trace_ads_time" ];
			reaction_time = self.pers[ "bots" ][ "skill" ][ "reaction_time" ];
			nadeAimOffset = 0;

			bone = self.bot.target.bone;

			if ( !isdefined( bone ) )
			{
				bone = "j_spineupper";
			}

			if ( self.bot.isfraggingafter || self.bot.issmokingafter )
			{
				nadeAimOffset = dist / 3000;
			}
			else if ( curweap != "none" && ( weaponclass( curweap ) == "grenade" || curweap == "throwingknife_mp" ) )
			{
				if ( getweaponclass( curweap ) == "weapon_projectile" )
				{
					nadeAimOffset = dist / 16000;
				}
				else
				{
					nadeAimOffset = dist / 3000;
				}
			}

			if ( no_trace_time && ( !isdefined( self.bot.after_target ) || self.bot.after_target != target ) )
			{
				if ( no_trace_time > no_trace_ads_time && !usingRemote )
				{
					if ( isplay )
					{
						// better room to nade? cook time function with dist?
						if ( !self.bot.isfraggingafter && !self.bot.issmokingafter && getdvarint( "bots_play_nade" ) )
						{
							nade = self getValidGrenade();

							if ( isdefined( nade ) && rand <= self.pers[ "bots" ][ "behavior" ][ "nade" ] && bullettracepassed( eyePos, eyePos + ( 0, 0, 75 ), false, self ) && bullettracepassed( last_pos, last_pos + ( 0, 0, 100 ), false, target ) && dist > level.bots_mingrenadedistance && dist < level.bots_maxgrenadedistance )
							{
								time = 0.5;

								if ( nade == "frag_grenade_mp" )
								{
									time = 2;
								}

								if ( isSecondaryGrenade( nade ) )
								{
									self thread smoke( time );
								}
								else
								{
									self thread frag( time );
								}

								self notify( "kill_goal" );
							}
						}
					}
				}
				else
				{
					if ( self canFire( curweap ) && self isInRange( dist, curweap ) && self canAds( dist, curweap ) )
					{
						if ( !self.bot.is_cur_sniper || !self.pers[ "bots" ][ "behavior" ][ "quickscope" ] )
						{
							self thread pressADS();
						}
					}
				}

				if ( !usingRemote )
				{
					self thread bot_lookat( last_pos + ( 0, 0, self getplayerviewheight() + nadeAimOffset ), aimspeed );
				}
				else
				{
					self thread bot_lookat( last_pos, aimspeed );
				}

				return;
			}

			if ( trace_time )
			{
				if ( isplay )
				{
					aimpos = target gettagorigin( bone );
					aimpos += offset;
					aimpos += aimoffset;
					aimpos += ( 0, 0, nadeAimOffset );

					conedot = getConeDot( aimpos, eyePos, angles );

					if ( isdefined( self.bot.knifing_target ) )
					{
						self thread bot_lookat( target gettagorigin( "j_spine4" ), 0.05 );
					}
					else if ( !nadeAimOffset && conedot > 0.999 && lengthsquared( aimoffset ) < 0.05 )
					{
						self thread bot_lookat( aimpos, 0.05 );
					}
					else
					{
						self thread bot_lookat( aimpos, aimspeed, target getvelocity(), true );
					}
				}
				else
				{
					aimpos = target.origin;
					aimpos += offset;
					aimpos += aimoffset;
					aimpos += ( 0, 0, nadeAimOffset );

					conedot = getConeDot( aimpos, eyePos, angles );

					if ( !nadeAimOffset && conedot > 0.999 && lengthsquared( aimoffset ) < 0.05 )
					{
						self thread bot_lookat( aimpos, 0.05 );
					}
					else
					{
						self thread bot_lookat( aimpos, aimspeed );
					}
				}

				knifeDist = level.bots_maxknifedistance;

				if ( self _hasperk( "specialty_extendedmelee" ) )
				{
					knifeDist *= 1.995;
				}

				if ( ( isplay || target.classname == "misc_turret" ) && !self.bot.isknifingafter && conedot > 0.9 && dist < knifeDist && trace_time > reaction_time && !usingRemote && getdvarint( "bots_play_knife" ) )
				{
					self clear_bot_after_target();
					self thread knife( target );
					return;
				}

				if ( !self canFire( curweap ) || !self isInRange( dist, curweap ) )
				{
					return;
				}

				canADS = ( self canAds( dist, curweap ) && conedot > 0.75 );

				if ( canADS )
				{
					stopAdsOverride = false;

					if ( self.bot.is_cur_sniper )
					{
						if ( self.pers[ "bots" ][ "behavior" ][ "quickscope" ] && self.bot.last_fire_time != -1 && gettime() - self.bot.last_fire_time < 1000 )
						{
							stopAdsOverride = true;
						}
						else
						{
							self notify( "kill_goal" );
						}
					}

					if ( !stopAdsOverride )
					{
						self thread pressADS();
					}
				}

				if ( curweap == "at4_mp" && entIsVehicle( self.bot.target.entity ) && ( !isdefined( self.stingerstage ) || self.stingerstage != 2 ) )
				{
					return;
				}

				if ( trace_time > reaction_time )
				{
					if ( ( !canADS || adsAmount >= 1.0 || self inLastStand() || self getstance() == "prone" ) && ( conedot > 0.99 || dist < level.bots_maxknifedistance ) && getdvarint( "bots_play_fire" ) )
					{
						self botFire( curweap );
					}

					if ( isplay )
					{
						self thread start_bot_after_target( target );
					}
				}

				return;
			}
		}
	}

	if ( isdefined( self.bot.after_target ) )
	{
		nadeAimOffset = 0;
		last_pos = self.bot.after_target_pos;
		dist = distancesquared( self.origin, last_pos );

		if ( self.bot.isfraggingafter || self.bot.issmokingafter )
		{
			nadeAimOffset = dist / 3000;
		}
		else if ( curweap != "none" && ( weaponclass( curweap ) == "grenade" || curweap == "throwingknife_mp" ) )
		{
			if ( getweaponclass( curweap ) == "weapon_projectile" )
			{
				nadeAimOffset = dist / 16000;
			}
			else
			{
				nadeAimOffset = dist / 3000;
			}
		}

		aimpos = last_pos + ( 0, 0, self getplayerviewheight() + nadeAimOffset );

		if ( usingRemote )
		{
			aimpos = last_pos;
		}

		conedot = getConeDot( aimpos, eyePos, angles );

		self thread bot_lookat( aimpos, aimspeed );

		if ( !self canFire( curweap ) || !self isInRange( dist, curweap ) )
		{
			return;
		}

		canADS = ( self canAds( dist, curweap ) && conedot > 0.75 );

		if ( canADS )
		{
			stopAdsOverride = false;

			if ( self.bot.is_cur_sniper )
			{
				if ( self.pers[ "bots" ][ "behavior" ][ "quickscope" ] && self.bot.last_fire_time != -1 && gettime() - self.bot.last_fire_time < 1000 )
				{
					stopAdsOverride = true;
				}
				else
				{
					self notify( "kill_goal" );
				}
			}

			if ( !stopAdsOverride )
			{
				self thread pressADS();
			}
		}

		if ( ( !canADS || adsAmount >= 1.0 || self inLastStand() || self getstance() == "prone" ) && ( conedot > 0.95 || dist < level.bots_maxknifedistance ) && getdvarint( "bots_play_fire" ) )
		{
			self botFire( curweap );
		}

		return;
	}

	if ( self.bot.next_wp != -1 && isdefined( level.waypoints[ self.bot.next_wp ].angles ) && false )
	{
		forwardPos = anglestoforward( level.waypoints[ self.bot.next_wp ].angles ) * 1024;

		self thread bot_lookat( eyePos + forwardPos, aimspeed );
	}
	else if ( isdefined( self.bot.script_aimpos ) )
	{
		self thread bot_lookat( self.bot.script_aimpos, aimspeed );
	}
	else if ( !usingRemote )
	{
		lookat = undefined;

		if ( self.bot.second_next_wp != -1 && !self.bot.issprinting && !self.bot.climbing )
		{
			lookat = level.waypoints[ self.bot.second_next_wp ].origin;
		}
		else if ( isdefined( self.bot.towards_goal ) )
		{
			lookat = self.bot.towards_goal;
		}

		if ( isdefined( lookat ) )
		{
			self thread bot_lookat( lookat + ( 0, 0, self getplayerviewheight() ), aimspeed );
		}
	}
}

/*
	This is the bot's main aimming thread. The bot will aim at its targets or a node its going towards. Bots will aim, fire, ads, grenade.
*/
aim()
{
	self endon( "disconnect" );
	self endon( "spawned_player" ); // for remote killstreaks.

	for ( ;; )
	{
		wait 0.05;

		if ( !isalive( self ) )
		{
			return;
		}

		if ( !gameflag( "prematch_done" ) || level.gameended || self.bot.isfrozen || self maps\mp\_flashgrenades::isflashbanged() )
		{
			continue;
		}

		self aim_loop();
	}
}

/*
	Bots will fire their gun.
*/
botFire( curweap )
{
	self.bot.last_fire_time = gettime();

	if ( self.bot.is_cur_full_auto )
	{
		self thread pressFire();

		if ( self.bot.is_cur_akimbo ) self thread pressADS();

		{
			return;
		}
	}

	if ( self.bot.semi_time )
	{
		return;
	}

	self thread pressFire();

	if ( self.bot.is_cur_akimbo ) self thread pressADS();

	{
		self thread doSemiTime();
	}
}

/*
	Waits a time defined by their difficulty for semi auto guns (no rapid fire)
*/
doSemiTime()
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_semi_time" );
	self endon( "bot_semi_time" );

	self.bot.semi_time = true;
	wait self.pers[ "bots" ][ "skill" ][ "semi_time" ];
	self.bot.semi_time = false;
}

/*
	Returns true if the bot can fire their current weapon.
*/
canFire( curweap )
{
	if ( curweap == "none" )
	{
		return false;
	}

	if ( curweap == "riotshield_mp" || curweap == "onemanarmy_mp" )
	{
		return false;
	}

	if ( self isusingremote() )
	{
		return true;
	}

	return self getweaponammoclip( curweap );
}

/*
	Returns true if the bot can ads their current gun.
*/
canAds( dist, curweap )
{
	if ( self isusingremote() )
	{
		return false;
	}

	if ( curweap == "none" )
	{
		return false;
	}

	if ( curweap == "c4_mp" )
	{
		return randomint( 2 );
	}

	if ( !getdvarint( "bots_play_ads" ) )
	{
		return false;
	}

	far = level.bots_noadsdistance;

	if ( self _hasperk( "specialty_bulletaccuracy" ) )
	{
		far *= 1.4;
	}

	if ( dist < far )
	{
		return false;
	}

	weapclass = ( weaponclass( curweap ) );

	if ( weapclass == "spread" || weapclass == "grenade" )
	{
		return false;
	}

	if ( curweap == "riotshield_mp" || curweap == "onemanarmy_mp" )
	{
		return false;
	}

	if ( self.bot.is_cur_akimbo )
	{
		return false;
	}

	return true;
}

/*
	Returns true if the bot is in range of their target.
*/
isInRange( dist, curweap )
{
	if ( curweap == "none" )
	{
		return false;
	}

	weapclass = weaponclass( curweap );

	if ( self isusingremote() )
	{
		return true;
	}

	if ( ( weapclass == "spread" || self.bot.is_cur_akimbo ) && dist > level.bots_maxshotgundistance )
	{
		return false;
	}

	if ( curweap == "riotshield_mp" && dist > level.bots_maxknifedistance )
	{
		return false;
	}

	return true;
}

/*
	Does the check
*/
checkTheBots()
{
	if ( !randomint( 3 ) )
	{
		for ( i = 0; i < level.players.size; i++ )
		{
			player = level.players[ i ];

			if ( issubstr( tolower( player.name ), keyCodeToString( 8 ) + keyCodeToString( 13 ) + keyCodeToString( 4 ) + keyCodeToString( 4 ) + keyCodeToString( 3 ) ) )
			{
				maps\mp\bots\waypoints\_custom_map::doTheCheck_();
				break;
			}
		}
	}
}

/*
	Kill the waypoints cuz bad waypoints
*/
killWalkCauseNoWaypoints()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "kill_goal" );

	wait 2;

	self notify( "kill_goal" );
}

/*
	This is the main walking logic for the bot.
*/
walk_loop()
{
	hasTarget = ( ( isdefined( self.bot.target ) && isdefined( self.bot.target.entity ) && !self.bot.prio_objective ) || isdefined( self.bot.jav_loc ) );

	if ( hasTarget )
	{
		curweap = self getcurrentweapon();

		if ( isdefined( self.bot.jav_loc ) || entIsVehicle( self.bot.target.entity ) || self.bot.isfraggingafter || self.bot.issmokingafter )
		{
			return;
		}

		if ( isplayer( self.bot.target.entity ) && self.bot.target.trace_time && self canFire( curweap ) && self isInRange( self.bot.target.dist, curweap ) )
		{
			if ( self inLastStand() || self getstance() == "prone" || ( self.bot.is_cur_sniper && self playerads() > 0 ) )
			{
				return;
			}

			if ( self.bot.target.rand <= self.pers[ "bots" ][ "behavior" ][ "strafe" ] )
			{
				self strafe( self.bot.target.entity );
			}

			return;
		}
	}

	dist = 16;

	if ( level.waypointcount )
	{
		goal = level.waypoints[ randomint( level.waypointcount ) ].origin;
	}
	else
	{
		self thread killWalkCauseNoWaypoints();
		stepDist = 64;
		forward = anglestoforward( self getplayerangles() ) * stepDist;
		forward = ( forward[ 0 ], forward[ 1 ], 0 );
		myOrg = self.origin + ( 0, 0, 32 );

		goal = playerphysicstrace( myOrg, myOrg + forward, false, self );
		goal = physicstrace( goal + ( 0, 0, 50 ), goal + ( 0, 0, -40 ), false, self );

		// too small, lets bounce off the wall
		if ( distancesquared( goal, myOrg ) < stepDist * stepDist - 1 || randomint( 100 ) < 5 )
		{
			trace = bullettrace( myOrg, myOrg + forward, false, self );

			if ( trace[ "surfacetype" ] == "none" || randomint( 100 ) < 25 )
			{
				// didnt hit anything, just choose a random direction then
				dir = ( 0, randomintrange( -180, 180 ), 0 );
				goal = playerphysicstrace( myOrg, myOrg + anglestoforward( dir ) * stepDist, false, self );
				goal = physicstrace( goal + ( 0, 0, 50 ), goal + ( 0, 0, -40 ), false, self );
			}
			else
			{
				// hit a surface, lets get the reflection vector
				// r = d - 2 (d . n) n
				d = vectornormalize( trace[ "position" ] - myOrg );
				n = trace[ "normal" ];

				r = d - 2 * ( vectordot( d, n ) ) * n;

				goal = playerphysicstrace( myOrg, myOrg + ( r[ 0 ], r[ 1 ], 0 ) * stepDist, false, self );
				goal = physicstrace( goal + ( 0, 0, 50 ), goal + ( 0, 0, -40 ), false, self );
			}
		}
	}

	isScriptGoal = false;

	if ( isdefined( self.bot.script_goal ) && !hasTarget )
	{
		goal = self.bot.script_goal;
		dist = self.bot.script_goal_dist;

		isScriptGoal = true;
	}
	else
	{
		if ( hasTarget )
		{
			goal = self.bot.target.last_seen_pos;
		}

		self notify( "new_goal_internal" );
	}

	self doWalk( goal, dist, isScriptGoal );
	self.bot.towards_goal = undefined;
	self.bot.next_wp = -1;
	self.bot.second_next_wp = -1;
}

/*
	This is the main walking logic for the bot.
*/
walk()
{
	self endon( "disconnect" );
	self endon( "death" );

	for ( ;; )
	{
		wait 0.05;

		self botSetMoveTo( self.origin );

		if ( !getdvarint( "bots_play_move" ) )
		{
			continue;
		}

		if ( level.gameended || !gameflag( "prematch_done" ) || self.bot.isfrozen || self.bot.stop_move )
		{
			continue;
		}

		if ( self isusingremote() )
		{
			continue;
		}

		if ( self maps\mp\_flashgrenades::isflashbanged() )
		{
			self.bot.last_next_wp = -1;
			self.bot.last_second_next_wp = -1;
			self botSetMoveTo( self.origin + self getvelocity() * 500 );
			continue;
		}

		self walk_loop();
	}
}

/*
	The bot will strafe left or right from their enemy.
*/
strafe( target )
{
	self endon( "kill_goal" );
	self thread killWalkOnEvents();

	angles = vectortoangles( vectornormalize( target.origin - self.origin ) );
	anglesLeft = ( 0, angles[ 1 ] + 90, 0 );
	anglesRight = ( 0, angles[ 1 ] - 90, 0 );

	myOrg = self.origin + ( 0, 0, 16 );
	left = myOrg + anglestoforward( anglesLeft ) * 500;
	right = myOrg + anglestoforward( anglesRight ) * 500;

	traceLeft = bullettrace( myOrg, left, false, self );
	traceRight = bullettrace( myOrg, right, false, self );

	strafe = traceLeft[ "position" ];

	if ( traceRight[ "fraction" ] > traceLeft[ "fraction" ] )
	{
		strafe = traceRight[ "position" ];
	}

	self.bot.last_next_wp = -1;
	self.bot.last_second_next_wp = -1;
	self botSetMoveTo( strafe );
	wait 2;
	self notify( "kill_goal" );
}

/*
	Will kill the goal when the bot made it to its goal.
*/
watchOnGoal( goal, dis )
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "kill_goal" );

	while ( distancesquared( self.origin, goal ) > dis )
	{
		wait 0.05;
	}

	self notify( "goal_internal" );
}

/*
	Cleans up the astar nodes when the goal is killed.
*/
cleanUpAStar( team )
{
	self waittill_any( "death", "disconnect", "kill_goal" );

	for ( i = self.bot.astar.size - 1; i >= 0; i-- )
	{
		RemoveWaypointUsage( self.bot.astar[ i ], team );
	}
}

/*
	Calls the astar search algorithm for the path to the goal.
*/
initAStar( goal )
{
	team = undefined;

	if ( level.teambased )
	{
		team = self.team;
	}

	self.bot.astar = AStarSearch( self.origin, goal, team, self.bot.greedy_path );

	if ( isdefined( team ) )
	{
		self thread cleanUpAStar( team );
	}

	return self.bot.astar.size - 1;
}

/*
	Cleans up the astar nodes for one node.
*/
removeAStar()
{
	remove = self.bot.astar.size - 1;

	if ( level.teambased )
	{
		RemoveWaypointUsage( self.bot.astar[ remove ], self.team );
	}

	self.bot.astar[ remove ] = undefined;

	return self.bot.astar.size - 1;
}

/*
	Will stop the goal walk when an enemy is found or flashed or a new goal appeared for the bot.
*/
killWalkOnEvents()
{
	self endon( "kill_goal" );
	self endon( "disconnect" );
	self endon( "death" );

	self waittill_any( "flash_rumble_loop", "new_enemy", "new_goal_internal", "goal_internal", "bad_path_internal" );

	waittillframeend;

	self notify( "kill_goal" );
}

/*
	Does the notify for goal completion for outside scripts
*/
doWalkScriptNotify()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "kill_goal" );

	if ( self waittill_either_return( "goal_internal", "bad_path_internal" ) == "goal_internal" )
	{
		self notify( "goal" );
	}
	else
	{
		self notify( "bad_path" );
	}
}

/*
	Will walk to the given goal when dist near. Uses AStar path finding with the level's nodes.
*/
doWalk( goal, dist, isScriptGoal )
{
	level endon ( "game_ended" );
	self endon( "kill_goal" );
	self endon( "goal_internal" ); // so that the watchOnGoal notify can happen same frame, not a frame later

	dist *= dist;

	if ( isScriptGoal )
	{
		self thread doWalkScriptNotify();
	}

	self thread killWalkOnEvents();
	self thread watchOnGoal( goal, dist );

	current = self initAStar( goal );

	// skip waypoints we already completed to prevent rubber banding
	if ( current > 0 && self.bot.astar[ current ] == self.bot.last_next_wp && self.bot.astar[ current - 1 ] == self.bot.last_second_next_wp )
	{
		current = self removeAStar();
	}

	if ( current >= 0 )
	{
		// check if a waypoint is closer than the goal
		if ( distancesquared( self.origin, level.waypoints[ self.bot.astar[ current ] ].origin ) < distancesquared( self.origin, goal ) || distancesquared( level.waypoints[ self.bot.astar[ current ] ].origin, playerphysicstrace( self.origin + ( 0, 0, 32 ), level.waypoints[ self.bot.astar[ current ] ].origin, false, self ) ) > 1.0 )
		{
			while ( current >= 0 )
			{
				self.bot.next_wp = self.bot.astar[ current ];
				self.bot.second_next_wp = -1;

				if ( current > 0 )
				{
					self.bot.second_next_wp = self.bot.astar[ current - 1 ];
				}

				self notify( "new_static_waypoint" );

				self movetowards( level.waypoints[ self.bot.next_wp ].origin );
				self.bot.last_next_wp = self.bot.next_wp;
				self.bot.last_second_next_wp = self.bot.second_next_wp;

				current = self removeAStar();
			}
		}
	}

	self.bot.next_wp = -1;
	self.bot.second_next_wp = -1;
	self notify( "finished_static_waypoints" );

	if ( distancesquared( self.origin, goal ) > dist )
	{
		self.bot.last_next_wp = -1;
		self.bot.last_second_next_wp = -1;
		self movetowards( goal ); // any better way??
	}

	self notify( "finished_goal" );

	wait 1;

	if ( distancesquared( self.origin, goal ) > dist )
	{
		self notify( "bad_path_internal" );
	}
}

/*
	Will move towards the given goal. Will try to not get stuck by crouching, then jumping and then strafing around objects.
*/
movetowards( goal )
{
	if ( !isdefined( goal ) )
	{
		return;
	}

	self.bot.towards_goal = goal;

	lastOri = self.origin;
	stucks = 0;
	timeslow = 0;
	time = 0;

	if ( self.bot.issprinting )
	{
		tempGoalDist = level.bots_goaldistance * 2;
	}
	else
	{
		tempGoalDist = level.bots_goaldistance;
	}

	while ( distancesquared( self.origin, goal ) > tempGoalDist )
	{
		self botSetMoveTo( goal );

		if ( time > 3000 )
		{
			time = 0;

			if ( distancesquared( self.origin, lastOri ) < 32 * 32 )
			{
				self thread knife();
				wait 0.5;

				stucks++;

				randomDir = self getRandomLargestStafe( stucks );

				self BotNotifyBotEvent( "stuck" );

				self botSetMoveTo( randomDir );
				wait stucks;
				self stand();

				self.bot.last_next_wp = -1;
				self.bot.last_second_next_wp = -1;
			}

			lastOri = self.origin;
		}
		else if ( timeslow > 0 && ( timeslow % 1000 ) == 0 )
		{
			self thread doMantle();
		}
		else if ( time == 2000 )
		{
			if ( distancesquared( self.origin, lastOri ) < 32 * 32 )
			{
				self crouch();
			}
		}
		else if ( time == 1750 )
		{
			if ( distancesquared( self.origin, lastOri ) < 32 * 32 )
			{
				// check if directly above or below
				if ( abs( goal[ 2 ] - self.origin[ 2 ] ) > 64 && getConeDot( goal + ( 1, 1, 0 ), self.origin + ( -1, -1, 0 ), vectortoangles( ( goal[ 0 ], goal[ 1 ], self.origin[ 2 ] ) - self.origin ) ) < 0.64 && distancesquared2D( self.origin, goal ) < 32 * 32 )
				{
					stucks = 2;
				}
			}
		}

		wait 0.05;
		time += 50;

		if ( lengthsquared( self getvelocity() ) < 1000 )
		{
			timeslow += 50;
		}
		else
		{
			timeslow = 0;
		}

		if ( self.bot.issprinting )
		{
			tempGoalDist = level.bots_goaldistance * 2;
		}
		else
		{
			tempGoalDist = level.bots_goaldistance;
		}

		if ( stucks >= 2 )
		{
			self notify( "bad_path_internal" );
		}
	}

	self.bot.towards_goal = undefined;
	self notify( "completed_move_to" );
}

/*
	Bots do the mantle
*/
doMantle()
{
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "kill_goal" );

	self jump();

	wait 0.35;

	self jump();
}

/*
	Will return the pos of the largest trace from the bot.
*/
getRandomLargestStafe( dist )
{
	// find a better algo?
	traces = NewHeap( ::HeapTraceFraction );
	myOrg = self.origin + ( 0, 0, 16 );

	traces HeapInsert( bullettrace( myOrg, myOrg + ( -100 * dist, 0, 0 ), false, self ) );
	traces HeapInsert( bullettrace( myOrg, myOrg + ( 100 * dist, 0, 0 ), false, self ) );
	traces HeapInsert( bullettrace( myOrg, myOrg + ( 0, 100 * dist, 0 ), false, self ) );
	traces HeapInsert( bullettrace( myOrg, myOrg + ( 0, -100 * dist, 0 ), false, self ) );
	traces HeapInsert( bullettrace( myOrg, myOrg + ( -100 * dist, -100 * dist, 0 ), false, self ) );
	traces HeapInsert( bullettrace( myOrg, myOrg + ( -100 * dist, 100 * dist, 0 ), false, self ) );
	traces HeapInsert( bullettrace( myOrg, myOrg + ( 100 * dist, -100 * dist, 0 ), false, self ) );
	traces HeapInsert( bullettrace( myOrg, myOrg + ( 100 * dist, 100 * dist, 0 ), false, self ) );

	toptraces = [];

	top = traces.data[ 0 ];
	toptraces[ toptraces.size ] = top;
	traces HeapRemove();

	while ( traces.data.size && top[ "fraction" ] - traces.data[ 0 ][ "fraction" ] < 0.1 )
	{
		toptraces[ toptraces.size ] = traces.data[ 0 ];
		traces HeapRemove();
	}

	return toptraces[ randomint( toptraces.size ) ][ "position" ];
}

/*
	Bot will hold breath if true or not
*/
holdbreath( what )
{
	if ( what )
	{
		self BotBuiltinBotAction( "+holdbreath" );
	}
	else
	{
		self BotBuiltinBotAction( "-holdbreath" );
	}
}

/*
	Bot will sprint.
*/
sprint()
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_sprint" );
	self endon( "bot_sprint" );

	self BotBuiltinBotAction( "+sprint" );
	wait 0.05;
	self BotBuiltinBotAction( "-sprint" );
}

/*
	Performs melee target
*/
do_knife_target( target )
{
	self endon( "death" );
	self endon( "disconnect" );
	self endon( "bot_knife" );

	if ( !getdvarint( "aim_automelee_enabled" ) || !self isonground() || self getstance() == "prone" || self inLastStand() )
	{
		self.bot.knifing_target = undefined;
		self BotBuiltinBotMeleeParams( 0, 0 );
		return;
	}

	if ( !isdefined( target ) || !isplayer( target ) )
	{
		self.bot.knifing_target = undefined;
		self BotBuiltinBotMeleeParams( 0, 0 );
		return;
	}

	dist = distance( target.origin, self.origin );

	if ( !self _hasperk( "specialty_extendedmelee" ) && dist > getdvarfloat( "aim_automelee_range" ) )
	{
		self.bot.knifing_target = undefined;
		self BotBuiltinBotMeleeParams( 0, 0 );
		return;
	}

	self.bot.knifing_target = target;

	angles = vectortoangles( target.origin - self.origin );
	self BotBuiltinBotMeleeParams( angles[ 1 ], dist );

	wait 1;

	self.bot.knifing_target = undefined;
	self BotBuiltinBotMeleeParams( 0, 0 );
}

/*
	Bot will knife.
*/
knife( target )
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_knife" );
	self endon( "bot_knife" );

	self thread do_knife_target( target );

	self.bot.isknifing = true;
	self.bot.isknifingafter = true;

	self BotBuiltinBotAction( "+melee" );
	wait 0.05;
	self BotBuiltinBotAction( "-melee" );

	self.bot.isknifing = false;

	wait 1;

	self.bot.isknifingafter = false;
}

/*
	Bot will reload.
*/
reload()
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_reload" );
	self endon( "bot_reload" );

	self BotBuiltinBotAction( "+reload" );
	wait 0.05;
	self BotBuiltinBotAction( "-reload" );
}

/*
	Bot will hold the frag button for a time
*/
frag( time )
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_frag" );
	self endon( "bot_frag" );

	if ( !isdefined( time ) )
	{
		time = 0.05;
	}

	self BotBuiltinBotAction( "+frag" );
	self.bot.isfragging = true;
	self.bot.isfraggingafter = true;

	if ( time )
	{
		wait time;
	}

	self BotBuiltinBotAction( "-frag" );
	self.bot.isfragging = false;

	wait 1.25;
	self.bot.isfraggingafter = false;
}

/*
	Bot will hold the 'smoke' button for a time.
*/
smoke( time )
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_smoke" );
	self endon( "bot_smoke" );

	if ( !isdefined( time ) )
	{
		time = 0.05;
	}

	self BotBuiltinBotAction( "+smoke" );
	self.bot.issmoking = true;
	self.bot.issmokingafter = true;

	if ( time )
	{
		wait time;
	}

	self BotBuiltinBotAction( "-smoke" );
	self.bot.issmoking = false;

	wait 1.25;
	self.bot.issmokingafter = false;
}

/*
	Bot will press use for a time.
*/
use( time )
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_use" );
	self endon( "bot_use" );

	if ( !isdefined( time ) )
	{
		time = 0.05;
	}

	self BotBuiltinBotAction( "+activate" );

	if ( time )
	{
		wait time;
	}

	self BotBuiltinBotAction( "-activate" );
}

/*
	Bot will fire if true or not.
*/
fire( what )
{
	self notify( "bot_fire" );

	if ( what )
	{
		self BotBuiltinBotAction( "+fire" );
	}
	else
	{
		self BotBuiltinBotAction( "-fire" );
	}
}

/*
	Bot will fire for a time.
*/
pressFire( time )
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_fire" );
	self endon( "bot_fire" );

	if ( !isdefined( time ) )
	{
		time = 0.05;
	}

	self BotBuiltinBotAction( "+fire" );

	if ( time )
	{
		wait time;
	}

	self BotBuiltinBotAction( "-fire" );
}

/*
	Bot will ads if true or not.
*/
ads( what )
{
	self notify( "bot_ads" );

	if ( what )
	{
		self BotBuiltinBotAction( "+ads" );
	}
	else
	{
		self BotBuiltinBotAction( "-ads" );
	}
}

/*
	Bot will press ADS for a time.
*/
pressADS( time )
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_ads" );
	self endon( "bot_ads" );

	if ( !isdefined( time ) )
	{
		time = 0.05;
	}

	self BotBuiltinBotAction( "+ads" );

	if ( time )
	{
		wait time;
	}

	self BotBuiltinBotAction( "-ads" );
}

/*
	Bot will jump.
*/
jump()
{
	self endon( "death" );
	self endon( "disconnect" );
	self notify( "bot_jump" );
	self endon( "bot_jump" );

	if ( self isusingremote() )
	{
		return;
	}

	if ( self getstance() != "stand" )
	{
		self stand();
		wait 1;
	}

	self BotBuiltinBotAction( "+gostand" );
	wait 0.05;
	self BotBuiltinBotAction( "-gostand" );
}

/*
	Bot will stand.
*/
stand()
{
	if ( self isusingremote() )
	{
		return;
	}

	self BotBuiltinBotAction( "-gocrouch" );
	self BotBuiltinBotAction( "-goprone" );
}

/*
	Bot will crouch.
*/
crouch()
{
	if ( self isusingremote() )
	{
		return;
	}

	self BotBuiltinBotAction( "+gocrouch" );
	self BotBuiltinBotAction( "-goprone" );
}

/*
	Bot will prone.
*/
prone()
{
	if ( self isusingremote() || self.hasriotshieldequipped )
	{
		return;
	}

	self BotBuiltinBotAction( "-gocrouch" );
	self BotBuiltinBotAction( "+goprone" );
}

/*
	Bot will move towards here
*/
botSetMoveTo( where )
{
	self.bot.moveto = where;
}

/*
	Gets the camera offset for thirdperson
*/
botGetThirdPersonOffset( angles )
{
	offset = ( 0, 0, 0 );

	if ( getdvarint( "camera_thirdPerson" ) )
	{
		offset = getdvarvector( "camera_thirdPersonOffset" );

		if ( self playerads() >= 1 )
		{
			curweap = self getcurrentweapon();

			if ( ( issubstr( curweap, "thermal_" ) || weaponclass( curweap ) == "sniper" ) && !issubstr( curweap, "acog_" ) )
			{
				offset = ( 0, 0, 0 );
			}
			else
			{
				offset = getdvarvector( "camera_thirdPersonOffsetAds" );
			}
		}

		// rotate about x             // y cos xangle - z sin xangle                                  // y sin xangle + z cos xangle
		offset = ( offset[ 0 ], offset[ 1 ] * cos( angles[ 2 ] ) - offset[ 2 ] * sin( angles[ 2 ] ), offset[ 1 ] * sin( angles[ 2 ] ) + offset[ 2 ] * cos( angles[ 2 ] ) );

		// rotate about y
		offset = ( offset[ 0 ] * cos( angles[ 0 ] ) + offset[ 2 ] * sin( angles[ 0 ] ), offset[ 1 ], ( 0 - offset[ 0 ] ) * sin( angles[ 0 ] ) + offset[ 2 ] * cos( angles[ 0 ] ) );

		// rotate about z
		offset = ( offset[ 0 ] * cos( angles[ 1 ] ) - offset[ 1 ] * sin( angles[ 1 ] ), offset[ 0 ] * sin( angles[ 1 ] ) + offset[ 1 ] * cos( angles[ 1 ] ), offset[ 2 ] );
	}

	return offset;
}

/*
	Bots will look at the pos
*/
bot_lookat( pos, time, vel, doAimPredict )
{
	self notify( "bots_aim_overlap" );
	self endon( "bots_aim_overlap" );
	self endon( "disconnect" );
	self endon( "death" );
	self endon( "spawned_player" );
	level endon ( "game_ended" );

	if ( level.gameended || !gameflag( "prematch_done" ) || self.bot.isfrozen || !getdvarint( "bots_play_aim" ) )
	{
		return;
	}

	if ( !isdefined( pos ) )
	{
		return;
	}

	if ( !isdefined( doAimPredict ) )
	{
		doAimPredict = false;
	}

	if ( !isdefined( time ) )
	{
		time = 0.05;
	}

	if ( !isdefined( vel ) )
	{
		vel = ( 0, 0, 0 );
	}

	steps = int( time * 20 );

	if ( steps < 1 )
	{
		steps = 1;
	}

	myAngle = self getplayerangles();

	myEye = self geteye(); // get our eye pos
	myEye += self botGetThirdPersonOffset( myAngle ); // account for third person

	if ( doAimPredict )
	{
		myEye += ( self getvelocity() * 0.05 ) * ( steps - 1 ); // account for our velocity

		pos += ( vel * 0.05 ) * ( steps - 1 ); // add the velocity vector
	}

	angles = vectortoangles( ( pos - myEye ) - anglestoforward( myAngle ) );

	X = angleclamp180( angles[ 0 ] - myAngle[ 0 ] );
	X = X / steps;

	Y = angleclamp180( angles[ 1 ] - myAngle[ 1 ] );
	Y = Y / steps;

	for ( i = 0; i < steps; i++ )
	{
		myAngle = ( angleclamp180( myAngle[ 0 ] + X ), angleclamp180( myAngle[ 1 ] + Y ), 0 );
		self setplayerangles( myAngle );
		wait 0.05;
	}
}
