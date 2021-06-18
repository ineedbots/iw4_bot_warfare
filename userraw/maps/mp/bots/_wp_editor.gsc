/*
	_wp_editor
	Author: INeedGames
	Date: 09/26/2020
	The ingame waypoint editor.
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

init()
{
	if ( getDvar( "bots_main_debug" ) == "" )
		setDvar( "bots_main_debug", 0 );

	if ( !getDVarint( "bots_main_debug" ) )
		return;

	if ( !getDVarint( "developer" ) )
	{
		setdvar( "developer_script", 1 );
		setdvar( "developer", 1 );

		setdvar( "sv_mapRotation", "map " + getDvar( "mapname" ) );
		exitLevel( false );
	}

	setDvar( "bots_main", 0 );
	setdvar( "bots_main_menu", 0 );
	setdvar( "bots_manage_fill_mode", 0 );
	setdvar( "bots_manage_fill", 0 );
	setdvar( "bots_manage_add", 0 );
	setdvar( "bots_manage_fill_kick", 1 );
	setDvar( "bots_manage_fill_spec", 1 );

	if ( getDvar( "bots_main_debug_distance" ) == "" )
		setDvar( "bots_main_debug_distance", 512.0 );

	if ( getDvar( "bots_main_debug_cone" ) == "" )
		setDvar( "bots_main_debug_cone", 0.65 );

	if ( getDvar( "bots_main_debug_minDist" ) == "" )
		setDvar( "bots_main_debug_minDist", 32.0 );

	if ( getDvar( "bots_main_debug_drawThrough" ) == "" )
		setDvar( "bots_main_debug_drawThrough", false );

	setDvar( "player_sustainAmmo", 1 );

	level.waypoints = [];
	level.waypointCount = 0;

	level waittill( "connected", player );
	player thread onPlayerSpawned();
}

onPlayerSpawned()
{
	self endon( "disconnect" );

	for ( ;; )
	{
		self waittill( "spawned_player" );
		self thread startDev();
	}
}

StartDev()
{
	self endon( "disconnect" );
	self endon( "death" );

	level.wpToLink = -1;
	level.autoLink = false;
	self.nearest = -1;

	self takeAllWeapons();
	self giveWeapon( "m16_gl_mp" ); //to knife windows
	self giveWeapon( "javelin_mp" ); //to mark jav spots
	self SetOffhandPrimaryClass( "other" );
	self giveWeapon( "semtex_mp" );
	self _clearperks();
	self.specialty = [];
	self maps\mp\perks\_perks::givePerk( "specialty_fastmantle" );
	self maps\mp\perks\_perks::givePerk( "specialty_falldamage" );
	self maps\mp\perks\_perks::givePerk( "specialty_marathon" );
	self maps\mp\perks\_perks::givePerk( "specialty_lightweight" );
	self freezecontrols( false );

	self thread watchAddWaypointCommand();
	self thread watchDeleteAllWaypointsCommand();
	self thread watchDeleteWaypointCommand();
	self thread watchLinkWaypointCommand();
	self thread watchLoadWaypointsCommand();
	self thread watchSaveWaypointsCommand();
	self thread watchUnlinkWaypointCommand();
	self thread watchAutoLinkCommand();
	self thread updateWaypointsStats();
	self thread watchAstarCommand();

	self thread sayExtras();
}

sayExtras()
{
	self endon( "disconnect" );
	self endon( "death" );
	self iprintln( "Before adding waypoints, holding buttons:" );
	wait 4;
	self iprintln( "ADS - climb" );
	self iprintln( "Use + Attack - tube" );
	self iprintln( "Attack - grenade" );
	self iprintln( "Use - claymore" );
	wait 4;
	self iprintln( "Else the waypoint will be your stance." );
	self iprintln( "Making a crouch waypoint with only one link..." );
	self iprintln( "Makes a camping waypoint." );
}

watchAstarCommand()
{
	self endon( "disconnect" );
	self endon( "death" );

	self notifyOnPlayerCommand( "astar", "+gostand" );

	for ( ;; )
	{
		self waittill( "astar" );

		if ( 1 )
			continue;

		self iprintln( "Start AStar" );
		self.astar = undefined;
		astar = spawnStruct();
		astar.start = self.origin;

		self waittill( "astar" );
		self iprintln( "End AStar" );
		astar.goal = self.origin;

		astar.nodes = AStarSearch( astar.start, astar.goal, undefined, true );
		self iprintln( "AStar size: " + astar.nodes.size );

		self.astar = astar;
	}
}

updateWaypointsStats()
{
	self endon( "disconnect" );
	self endon( "death" );

	self initHudElem( "TotalWps:", 102, 5 );
	totalWpsHud = self initHudElem( "", 180, 5 );
	self initHudElem( "NearestWP:", 102, 15 );
	nearestWP = self initHudElem( "", 180, 15 );
	self initHudElem( "Childs:", 102, 25 );
	children = self initHudElem( "", 160, 25 );
	self initHudElem( "Type:", 102, 35 );
	type = self initHudElem( "", 160, 35 );
	self initHudElem( "ToLink:", 102, 45 );
	wpToLink = self initHudElem( "", 160, 45 );

	infotext = self initHudElem2();
	self initHudElem3();
	self initHudElem4();

	for ( time = 0;; time += 0.05 )
	{
		wait 0.05;

		totalWpsHud setText( level.waypointCount );

		closest = -1;
		myEye = self getEye();
		myAngles = self GetPlayerAngles();

		for ( i = 0; i < level.waypointCount; i++ )
		{
			if ( closest == -1 || closer( self.origin, level.waypoints[i].origin, level.waypoints[closest].origin ) )
				closest = i;

			wpOrg = level.waypoints[i].origin + ( 0, 0, 25 );

			if ( distance( level.waypoints[i].origin, self.origin ) < getDvarFloat( "bots_main_debug_distance" ) && ( bulletTracePassed( myEye, wpOrg, false, self ) || getDVarint( "bots_main_debug_drawThrough" ) ) )
			{
				for ( h = level.waypoints[i].children.size - 1; h >= 0; h-- )
					line( wpOrg, level.waypoints[level.waypoints[i].children[h]].origin + ( 0, 0, 25 ), ( 1, 0, 1 ) );

				if ( getConeDot( wpOrg, myEye, myAngles ) > getDvarFloat( "bots_main_debug_cone" ) )
					print3d( wpOrg, i, ( 1, 0, 0 ), 2 );

				if ( isDefined( level.waypoints[i].angles ) && level.waypoints[i].type != "stand" )
					line( wpOrg, wpOrg + AnglesToForward( level.waypoints[i].angles ) * 64, ( 1, 1, 1 ) );

				if ( isDefined( level.waypoints[i].jav_point ) )
					line( wpOrg, level.waypoints[i].jav_point, ( 0, 0, 0 ) );
			}
		}

		self.nearest = closest;

		nearestWP setText( self.nearest );

		children setText( buildChildCountString( self.nearest ) );

		type setText( buildTypeString( self.nearest ) );

		wpToLink setText( level.wpToLink );

		infotext.x = infotext.x - 2;

		if ( infotext.x <= -800 )
			infotext.x = 800;

		if ( self UseButtonPressed() && time > 2 )
		{
			time = 0;
			self iPrintLnBold( self.nearest + " children:  " + buildChildString( self.nearest ) );
		}

		if ( isDefined( self.astar ) )
		{
			print3d( self.astar.start + ( 0, 0, 35 ), "start", ( 0, 0, 1 ), 2 );
			print3d( self.astar.goal + ( 0, 0, 35 ), "goal", ( 0, 0, 1 ), 2 );

			prev = self.astar.start + ( 0, 0, 35 );

			for ( i = self.astar.nodes.size - 1; i >= 0; i-- )
			{
				node = self.astar.nodes[i];

				line( prev, level.waypoints[node].origin + ( 0, 0, 35 ), ( 0, 1, 1 ) );

				prev = level.waypoints[node].origin + ( 0, 0, 35 );
			}

			line( prev, self.astar.goal + ( 0, 0, 35 ), ( 0, 1, 1 ) );
		}
	}
}

watchLoadWaypointsCommand()
{
	self endon( "disconnect" );
	self endon( "death" );

	self notifyOnPlayerCommand( "[{+actionslot 2}]", "+actionslot 2" );

	for ( ;; )
	{
		self waittill( "[{+actionslot 2}]" );
		self LoadWaypoints();
	}
}

watchAddWaypointCommand()
{
	self endon( "disconnect" );
	self endon( "death" );

	self notifyOnPlayerCommand( "[{+smoke}]", "+smoke" );

	for ( ;; )
	{
		self waittill( "[{+smoke}]" );
		self AddWaypoint();
	}
}

watchAutoLinkCommand()
{
	self endon( "disconnect" );
	self endon( "death" );

	self notifyOnPlayerCommand( "[{+frag}]", "+frag" );

	for ( ;; )
	{
		self waittill( "[{+frag}]" );

		if ( level.autoLink )
		{
			self iPrintlnBold( "Auto link disabled" );
			level.autoLink = false;
			level.wpToLink = -1;
		}
		else
		{
			self iPrintlnBold( "Auto link enabled" );
			level.autoLink = true;
			level.wpToLink = self.nearest;
		}
	}
}

watchLinkWaypointCommand()
{
	self endon( "disconnect" );
	self endon( "death" );

	self notifyOnPlayerCommand( "[{+melee}]", "+melee" );

	for ( ;; )
	{
		self waittill( "[{+melee}]" );
		self LinkWaypoint( self.nearest );
	}
}

watchUnlinkWaypointCommand()
{
	self endon( "disconnect" );
	self endon( "death" );

	self notifyOnPlayerCommand( "[{+reload}]", "+reload" );

	for ( ;; )
	{
		self waittill( "[{+reload}]" );
		self UnLinkWaypoint( self.nearest );
	}
}

watchDeleteWaypointCommand()
{
	self endon( "disconnect" );
	self endon( "death" );

	self notifyOnPlayerCommand( "[{+actionslot 3}]", "+actionslot 3" );

	for ( ;; )
	{
		self waittill( "[{+actionslot 3}]" );
		self DeleteWaypoint( self.nearest );
	}
}

watchDeleteAllWaypointsCommand()
{
	self endon( "disconnect" );
	self endon( "death" );

	self notifyOnPlayerCommand( "[{+actionslot 4}]", "+actionslot 4" );

	for ( ;; )
	{
		self waittill( "[{+actionslot 4}]" );
		self DeleteAllWaypoints();
	}
}

watchSaveWaypointsCommand()
{
	self endon( "death" );
	self endon( "disconnect" );

	self notifyOnPlayerCommand( "[{+actionslot 1}]", "+actionslot 1" );

	for ( ;; )
	{
		self waittill( "[{+actionslot 1}]" );

		self checkForWarnings();
		wait 1;

		logprint( "***********ABiliTy's WPDump**************\n\n" );
		logprint( "\n\n\n\n" );
		mpnm = getMapName( getdvar( "mapname" ) );
		logprint( "\n\n" + mpnm + "()\n{\n/*" );
		logprint( "*/waypoints = [];\n/*" );

		for ( i = 0; i < level.waypointCount; i++ )
		{
			logprint( "*/waypoints[" + i + "] = spawnstruct();\n/*" );
			logprint( "*/waypoints[" + i + "].origin = " + level.waypoints[i].origin + ";\n/*" );
			logprint( "*/waypoints[" + i + "].type = \"" + level.waypoints[i].type + "\";\n/*" );

			for ( c = 0; c < level.waypoints[i].children.size; c++ )
			{
				logprint( "*/waypoints[" + i + "].children[" + c + "] = " + level.waypoints[i].children[c] + ";\n/*" );
			}

			if ( isDefined( level.waypoints[i].angles ) && ( level.waypoints[i].type == "claymore" || level.waypoints[i].type == "tube" || ( level.waypoints[i].type == "crouch" && level.waypoints[i].children.size == 1 ) || level.waypoints[i].type == "climb" || level.waypoints[i].type == "grenade" ) )
				logprint( "*/waypoints[" + i + "].angles = " + level.waypoints[i].angles + ";\n/*" );

			if ( isDefined( level.waypoints[i].jav_point ) && level.waypoints[i].type == "javelin" )
				logprint( "*/waypoints[" + i + "].jav_point = " + level.waypoints[i].jav_point + ";\n/*" );
		}

		logprint( "*/return waypoints;\n}\n\n\n\n" );

		filename = "waypoints/" + getdvar( "mapname" ) + "_wp.csv";

		PrintLn( "********* Start Bot Warfare WPDump *********" );
		PrintLn( level.waypointCount );

		fileWrite( filename, level.waypointCount + "\n", "write" );

		for ( i = 0; i < level.waypointCount; i++ )
		{
			str = "";
			wp = level.waypoints[i];

			str += wp.origin[0] + " " + wp.origin[1] + " " + wp.origin[2] + ",";

			for ( h = 0; h < wp.children.size; h++ )
			{
				str += wp.children[h];

				if ( h < wp.children.size - 1 )
					str += " ";
			}

			str += "," + wp.type + ",";

			if ( isDefined( wp.angles ) )
				str += wp.angles[0] + " " + wp.angles[1] + " " + wp.angles[2] + ",";
			else
				str += ",";

			if ( isDefined( wp.jav_point ) )
				str += wp.jav_point[0] + " " + wp.jav_point[1] + " " + wp.jav_point[2] + ",";
			else
				str += ",";

			PrintLn( str );
			fileWrite( filename, str + "\n", "append" );
		}

		PrintLn( "\n\n\n\n\n\n" );

		self iprintln( "Saved!!! to " + filename );
	}
}

LoadWaypoints()
{
	self DeleteAllWaypoints();
	self iPrintlnBold( "Loading WPS..." );
	load_waypoints();

	wait 1;

	self checkForWarnings();
}

checkForWarnings()
{
	if ( level.waypointCount <= 0 )
		self iprintln( "WARNING: waypointCount is " + level.waypointCount );

	if ( level.waypointCount != level.waypoints.size )
		self iprintln( "WARNING: waypointCount is not " + level.waypoints.size );

	for ( i = 0; i < level.waypointCount; i++ )
	{
		if ( !isDefined( level.waypoints[i] ) )
		{
			self iprintln( "WARNING: waypoint " + i + " is undefined" );
			continue;
		}

		if ( level.waypoints[i].children.size <= 0 )
			self iprintln( "WARNING: waypoint " + i + " childCount is " + level.waypoints[i].children.size );
		else
		{
			if ( !isDefined( level.waypoints[i].children ) || !isDefined( level.waypoints[i].children.size ) )
			{
				self iprintln( "WARNING: waypoint " + i + " children is not defined" );
			}
			else
			{
				for ( h = level.waypoints[i].children.size - 1; h >= 0; h-- )
				{
					child = level.waypoints[i].children[h];

					if ( !isDefined( level.waypoints[child] ) )
						self iprintln( "WARNING: waypoint " + i + " child " + child + " is undefined" );
					else if ( child == i )
						self iprintln( "WARNING: waypoint " + i + " child " + child + " is itself" );
				}
			}
		}

		if ( !isDefined( level.waypoints[i].type ) )
		{
			self iprintln( "WARNING: waypoint " + i + " type is undefined" );
			continue;
		}

		if ( level.waypoints[i].type == "javelin" && !isDefined( level.waypoints[i].jav_point ) )
			self iprintln( "WARNING: waypoint " + i + " jav_point is undefined" );

		if ( !isDefined( level.waypoints[i].angles ) && ( level.waypoints[i].type == "claymore" || level.waypoints[i].type == "tube" || ( level.waypoints[i].type == "crouch" && level.waypoints[i].children.size == 1 ) || level.waypoints[i].type == "climb" || level.waypoints[i].type == "grenade" ) )
			self iprintln( "WARNING: waypoint " + i + " angles is undefined" );
	}
}

UnLinkWaypoint( nwp )
{
	if ( nwp == -1 || distance( self.origin, level.waypoints[nwp].origin ) > getDvarFloat( "bots_main_debug_minDist" ) )
	{
		self iprintln( "Waypoint Unlink Cancelled " + level.wpToLink );
		level.wpToLink = -1;
		return;
	}

	if ( level.wpToLink == -1 || nwp == level.wpToLink )
	{
		level.wpToLink = nwp;
		self iprintln( "Waypoint Unlink Started " + nwp );
		return;
	}

	level.waypoints[nwp].children = array_remove( level.waypoints[nwp].children, level.wpToLink );
	level.waypoints[level.wpToLink].children = array_remove( level.waypoints[level.wpToLink].children, nwp );

	self iprintln( "Waypoint " + nwp + " Broken to " + level.wpToLink );
	level.wpToLink = -1;
}

LinkWaypoint( nwp )
{
	if ( nwp == -1 || distance( self.origin, level.waypoints[nwp].origin ) > getDvarFloat( "bots_main_debug_minDist" ) )
	{
		self iprintln( "Waypoint Link Cancelled " + level.wpToLink );
		level.wpToLink = -1;
		return;
	}

	if ( level.wpToLink == -1 || nwp == level.wpToLink )
	{
		level.wpToLink = nwp;
		self iprintln( "Waypoint Link Started " + nwp );
		return;
	}

	weGood = true;

	for ( i = level.waypoints[level.wpToLink].children.size - 1; i >= 0; i-- )
	{
		child = level.waypoints[level.wpToLink].children[i];

		if ( child == nwp )
		{
			weGood = false;
			break;
		}
	}

	if ( weGood )
	{
		for ( i = level.waypoints[nwp].children.size - 1; i >= 0; i-- )
		{
			child = level.waypoints[nwp].children[i];

			if ( child == level.wpToLink )
			{
				weGood = false;
				break;
			}
		}
	}

	if ( !weGood )
	{
		self iprintln( "Waypoint Link Cancelled " + nwp + " and " + level.wpToLink + " already linked." );
		level.wpToLink = -1;
		return;
	}

	level.waypoints[level.wpToLink].children[level.waypoints[level.wpToLink].children.size] = nwp;
	level.waypoints[nwp].children[level.waypoints[nwp].children.size] = level.wpToLink;

	self iprintln( "Waypoint " + nwp + " Linked to " + level.wpToLink );
	level.wpToLink = -1;
}

DeleteWaypoint( nwp )
{
	if ( nwp == -1 || distance( self.origin, level.waypoints[nwp].origin ) > getDvarFloat( "bots_main_debug_minDist" ) )
	{
		self iprintln( "No close enough waypoint to delete." );
		return;
	}

	level.wpToLink = -1;

	for ( i = level.waypoints[nwp].children.size - 1; i >= 0; i-- )
	{
		child = level.waypoints[nwp].children[i];

		level.waypoints[child].children = array_remove( level.waypoints[child].children, nwp );
	}

	for ( i = 0; i < level.waypointCount; i++ )
	{
		for ( h = level.waypoints[i].children.size - 1; h >= 0; h-- )
		{
			if ( level.waypoints[i].children[h] > nwp )
				level.waypoints[i].children[h]--;
		}
	}

	for ( entry = 0; entry < level.waypointCount; entry++ )
	{
		if ( entry == nwp )
		{
			while ( entry < level.waypointCount - 1 )
			{
				level.waypoints[entry] = level.waypoints[entry + 1];
				entry++;
			}

			level.waypoints[entry] = undefined;
			break;
		}
	}

	level.waypointCount--;

	self iprintln( "DelWp " + nwp );
}

AddWaypoint()
{
	level.waypoints[level.waypointCount] = spawnstruct();

	pos = self getOrigin();
	level.waypoints[level.waypointCount].origin = pos;

	if ( isDefined( self.javelinTargetPoint ) )
		level.waypoints[level.waypointCount].type = "javelin";
	else if ( self AdsButtonPressed() )
		level.waypoints[level.waypointCount].type = "climb";
	else if ( self AttackButtonPressed() && self UseButtonPressed() )
		level.waypoints[level.waypointCount].type = "tube";
	else if ( self AttackButtonPressed() )
		level.waypoints[level.waypointCount].type = "grenade";
	else if ( self UseButtonPressed() )
		level.waypoints[level.waypointCount].type = "claymore";
	else
		level.waypoints[level.waypointCount].type = self getStance();

	level.waypoints[level.waypointCount].angles = self getPlayerAngles();

	level.waypoints[level.waypointCount].children = [];

	if ( level.waypoints[level.waypointCount].type == "javelin" )
	{
		level.waypoints[level.waypointCount].jav_point = self.javelinTargetPoint;
	}

	self iprintln( level.waypoints[level.waypointCount].type + " Waypoint " + level.waypointCount + " Added at " + pos );

	if ( level.autoLink )
	{
		if ( level.wpToLink == -1 )
			level.wpToLink = level.waypointCount - 1;

		level.waypointCount++;
		self LinkWaypoint( level.waypointCount - 1 );
	}
	else
	{
		level.waypointCount++;
	}
}

DeleteAllWaypoints()
{
	level.waypoints = [];
	level.waypointCount = 0;

	self iprintln( "DelAllWps" );
}

buildChildCountString ( wp )
{
	if ( wp == -1 )
		return "";

	wpstr = level.waypoints[wp].children.size + "";

	return wpstr;
}

buildChildString( wp )
{
	if ( wp == -1 )
		return "";

	wpstr = "";

	for ( i = 0; i < level.waypoints[wp].children.size; i++ )
	{
		if ( i != 0 )
			wpstr = wpstr + "," + level.waypoints[wp].children[i];
		else
			wpstr = wpstr + level.waypoints[wp].children[i];
	}

	return wpstr;
}

buildTypeString( wp )
{
	if ( wp == -1 )
		return "";

	return level.waypoints[wp].type;
}

destroyOnDeath( hud )
{
	hud endon( "death" );
	self waittill_either( "death", "disconnect" );
	hud destroy();
}

initHudElem( txt, xl, yl )
{
	hud = NewClientHudElem( self );
	hud setText( txt );
	hud.alignX = "left";
	hud.alignY =  "top";
	hud.horzAlign =  "left";
	hud.vertAlign =  "top";
	hud.x = xl;
	hud.y = yl;
	hud.foreground = true;
	hud.fontScale = 1;
	hud.font = "objective";
	hud.alpha = 1;
	hud.glow = 0;
	hud.glowColor = ( 0, 0, 0 );
	hud.glowAlpha = 1;
	hud.color = ( 1.0, 1.0, 1.0 );

	self thread destroyOnDeath( hud );

	return hud;
}

initHudElem2()
{
	infotext = NewHudElem();
	infotext setText( "^1[{+smoke}]-AddWp ^2[{+melee}]-LinkWp ^3[{+reload}]-UnLinkWp ^4[{+actionslot 3}]-DeleteWp ^5[{+actionslot 4}]-DelAllWps ^6[{+actionslot 2}]-LoadWPS ^7[{+actionslot 1}]-SaveWp" );
	infotext.alignX = "center";
	infotext.alignY = "bottom";
	infotext.horzAlign = "center";
	infotext.vertAlign = "bottom";
	infotext.x = -800;
	infotext.y = 25;
	infotext.foreground = true;
	infotext.fontScale = 1.35;
	infotext.font = "objective";
	infotext.alpha = 1;
	infotext.glow = 0;
	infotext.glowColor = ( 0, 0, 0 );
	infotext.glowAlpha = 1;
	infotext.color = ( 1.0, 1.0, 1.0 );

	self thread destroyOnDeath( infotext );

	return infotext;
}

initHudElem3()
{
	bar = level createServerBar( ( 0.5, 0.5, 0.5 ), 1000, 25 );
	bar.alignX = "center";
	bar.alignY = "bottom";
	bar.horzAlign = "center";
	bar.vertAlign = "bottom";
	bar.y = 30;
	bar.foreground = true;

	self thread destroyOnDeath( bar );

	return bar;
}

initHudElem4()
{
	OptionsBG = NewClientHudElem( self );
	OptionsBG.x = 100;
	OptionsBG.y = 2;
	OptionsBG.alignX = "left";
	OptionsBG.alignY = "top";
	OptionsBG.horzAlign = "left";
	OptionsBG.vertAlign = "top";
	OptionsBG setshader( "black", 200, 60 );
	OptionsBG.alpha = 0.4;

	self thread destroyOnDeath( OptionsBG );

	return OptionsBG;
}
