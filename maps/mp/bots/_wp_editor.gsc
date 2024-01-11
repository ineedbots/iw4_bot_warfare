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
	if ( getdvar( "bots_main_debug" ) == "" )
	{
		setdvar( "bots_main_debug", 0 );
	}

	if ( !getdvarint( "bots_main_debug" ) )
	{
		return;
	}

	if ( !getdvarint( "developer" ) )
	{
		setdvar( "developer_script", 1 );
		setdvar( "developer", 1 );

		setdvar( "sv_mapRotation", "map " + getdvar( "mapname" ) );
		exitlevel( false );
	}

	setdvar( "bots_main", 0 );
	setdvar( "bots_main_menu", 0 );
	setdvar( "bots_manage_fill_mode", 0 );
	setdvar( "bots_manage_fill", 0 );
	setdvar( "bots_manage_add", 0 );
	setdvar( "bots_manage_fill_kick", 1 );
	setdvar( "bots_manage_fill_spec", 1 );

	if ( getdvar( "bots_main_debug_distance" ) == "" )
	{
		setdvar( "bots_main_debug_distance", 512.0 );
	}

	if ( getdvar( "bots_main_debug_cone" ) == "" )
	{
		setdvar( "bots_main_debug_cone", 0.65 );
	}

	if ( getdvar( "bots_main_debug_minDist" ) == "" )
	{
		setdvar( "bots_main_debug_minDist", 32.0 );
	}

	if ( getdvar( "bots_main_debug_drawThrough" ) == "" )
	{
		setdvar( "bots_main_debug_drawThrough", false );
	}

	setdvar( "player_sustainAmmo", 1 );

	level.waypoints = [];
	level.waypointcount = 0;

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

startDev()
{
	self endon( "disconnect" );
	self endon( "death" );

	level.wptolink = -1;
	level.autolink = false;
	self.nearest = -1;

	self takeallweapons();
	self giveweapon( "m16_gl_mp" ); // to knife windows
	self giveweapon( "javelin_mp" ); // to mark jav spots
	self setoffhandprimaryclass( "other" );
	self giveweapon( "semtex_mp" );
	self _clearperks();
	self.specialty = [];
	self maps\mp\perks\_perks::giveperk( "specialty_fastmantle" );
	self maps\mp\perks\_perks::giveperk( "specialty_falldamage" );
	self maps\mp\perks\_perks::giveperk( "specialty_marathon" );
	self maps\mp\perks\_perks::giveperk( "specialty_lightweight" );
	self freezecontrols( false );

	self thread watchAddWaypointCommand();
	self thread watchDeleteAllWaypointsCommand();
	self thread watchDeleteWaypointCommand();
	self thread watchLinkWaypointCommand();
	self thread watchLoadWaypointsCommand();
	self thread watchSaveWaypointsCommand();
	self thread watchunlinkWaypointCommand();
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

	self notifyonplayercommand( "astar", "+gostand" );

	for ( ;; )
	{
		self waittill( "astar" );

		if ( 1 )
		{
			continue;
		}

		self iprintln( "Start AStar" );
		self.astar = undefined;
		astar = spawnstruct();
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

		totalWpsHud settext( level.waypointcount );

		closest = -1;
		myEye = self geteye();
		myAngles = self getplayerangles();

		for ( i = 0; i < level.waypointcount; i++ )
		{
			if ( closest == -1 || closer( self.origin, level.waypoints[ i ].origin, level.waypoints[ closest ].origin ) )
			{
				closest = i;
			}

			wpOrg = level.waypoints[ i ].origin + ( 0, 0, 25 );

			if ( distance( level.waypoints[ i ].origin, self.origin ) < getdvarfloat( "bots_main_debug_distance" ) && ( bullettracepassed( myEye, wpOrg, false, self ) || getdvarint( "bots_main_debug_drawThrough" ) ) )
			{
				for ( h = level.waypoints[ i ].children.size - 1; h >= 0; h-- )
				{
					line( wpOrg, level.waypoints[ level.waypoints[ i ].children[ h ] ].origin + ( 0, 0, 25 ), ( 1, 0, 1 ) );
				}

				if ( getConeDot( wpOrg, myEye, myAngles ) > getdvarfloat( "bots_main_debug_cone" ) )
				{
					print3d( wpOrg, i, ( 1, 0, 0 ), 2 );
				}

				if ( isdefined( level.waypoints[ i ].angles ) && level.waypoints[ i ].type != "stand" )
				{
					line( wpOrg, wpOrg + anglestoforward( level.waypoints[ i ].angles ) * 64, ( 1, 1, 1 ) );
				}

				if ( isdefined( level.waypoints[ i ].jav_point ) )
				{
					line( wpOrg, level.waypoints[ i ].jav_point, ( 0, 0, 0 ) );
				}
			}
		}

		self.nearest = closest;

		nearestWP settext( self.nearest );

		children settext( buildChildCountString( self.nearest ) );

		type settext( buildTypeString( self.nearest ) );

		wpToLink settext( level.wptolink );

		infotext.x = infotext.x - 2;

		if ( infotext.x <= -800 )
		{
			infotext.x = 800;
		}

		if ( self usebuttonpressed() && time > 2 )
		{
			time = 0;
			self iprintlnbold( self.nearest + " children:  " + buildChildString( self.nearest ) );
		}

		if ( isdefined( self.astar ) )
		{
			print3d( self.astar.start + ( 0, 0, 35 ), "start", ( 0, 0, 1 ), 2 );
			print3d( self.astar.goal + ( 0, 0, 35 ), "goal", ( 0, 0, 1 ), 2 );

			prev = self.astar.start + ( 0, 0, 35 );

			for ( i = self.astar.nodes.size - 1; i >= 0; i-- )
			{
				node = self.astar.nodes[ i ];

				line( prev, level.waypoints[ node ].origin + ( 0, 0, 35 ), ( 0, 1, 1 ) );

				prev = level.waypoints[ node ].origin + ( 0, 0, 35 );
			}

			line( prev, self.astar.goal + ( 0, 0, 35 ), ( 0, 1, 1 ) );
		}
	}
}

watchLoadWaypointsCommand()
{
	self endon( "disconnect" );
	self endon( "death" );

	self notifyonplayercommand( "[{+actionslot 2}]", "+actionslot 2" );

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

	self notifyonplayercommand( "[{+smoke}]", "+smoke" );

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

	self notifyonplayercommand( "[{+frag}]", "+frag" );

	for ( ;; )
	{
		self waittill( "[{+frag}]" );

		if ( level.autolink )
		{
			self iprintlnbold( "Auto link disabled" );
			level.autolink = false;
			level.wptolink = -1;
		}
		else
		{
			self iprintlnbold( "Auto link enabled" );
			level.autolink = true;
			level.wptolink = self.nearest;
		}
	}
}

watchLinkWaypointCommand()
{
	self endon( "disconnect" );
	self endon( "death" );

	self notifyonplayercommand( "[{+melee}]", "+melee" );

	for ( ;; )
	{
		self waittill( "[{+melee}]" );
		self LinkWaypoint( self.nearest );
	}
}

watchunlinkWaypointCommand()
{
	self endon( "disconnect" );
	self endon( "death" );

	self notifyonplayercommand( "[{+reload}]", "+reload" );

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

	self notifyonplayercommand( "[{+actionslot 3}]", "+actionslot 3" );

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

	self notifyonplayercommand( "[{+actionslot 4}]", "+actionslot 4" );

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

	self notifyonplayercommand( "[{+actionslot 1}]", "+actionslot 1" );

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

		for ( i = 0; i < level.waypointcount; i++ )
		{
			logprint( "*/waypoints[ " + i + " ] = spawnstruct();\n/*" );
			logprint( "*/waypoints[ " + i + " ].origin = " + level.waypoints[ i ].origin + ";\n/*" );
			logprint( "*/waypoints[ " + i + " ].type = \"" + level.waypoints[ i ].type + "\";\n/*" );

			for ( c = 0; c < level.waypoints[ i ].children.size; c++ )
			{
				logprint( "*/waypoints[ " + i + " ].children[ " + c + " ] = " + level.waypoints[ i ].children[ c ] + ";\n/*" );
			}

			if ( isdefined( level.waypoints[ i ].angles ) && ( level.waypoints[ i ].type == "claymore" || level.waypoints[ i ].type == "tube" || ( level.waypoints[ i ].type == "crouch" && level.waypoints[ i ].children.size == 1 ) || level.waypoints[ i ].type == "climb" || level.waypoints[ i ].type == "grenade" ) )
			{
				logprint( "*/waypoints[ " + i + " ].angles = " + level.waypoints[ i ].angles + ";\n/*" );
			}

			if ( isdefined( level.waypoints[ i ].jav_point ) && level.waypoints[ i ].type == "javelin" )
			{
				logprint( "*/waypoints[ " + i + " ].jav_point = " + level.waypoints[ i ].jav_point + ";\n/*" );
			}
		}

		logprint( "*/return waypoints;\n}\n\n\n\n" );

		filename = "waypoints/" + getdvar( "mapname" ) + "_wp.csv";

		println( "********* Start Bot Warfare WPDump *********" );
		println( level.waypointcount );

		BotBuiltinFileWrite( filename, level.waypointcount + "\n", "write" );

		for ( i = 0; i < level.waypointcount; i++ )
		{
			str = "";
			wp = level.waypoints[ i ];

			str += wp.origin[ 0 ] + " " + wp.origin[ 1 ] + " " + wp.origin[ 2 ] + ",";

			for ( h = 0; h < wp.children.size; h++ )
			{
				str += wp.children[ h ];

				if ( h < wp.children.size - 1 )
				{
					str += " ";
				}
			}

			str += "," + wp.type + ",";

			if ( isdefined( wp.angles ) )
			{
				str += wp.angles[ 0 ] + " " + wp.angles[ 1 ] + " " + wp.angles[ 2 ] + ",";
			}
			else
			{
				str += ",";
			}

			if ( isdefined( wp.jav_point ) )
			{
				str += wp.jav_point[ 0 ] + " " + wp.jav_point[ 1 ] + " " + wp.jav_point[ 2 ] + ",";
			}
			else
			{
				str += ",";
			}

			println( str );
			BotBuiltinFileWrite( filename, str + "\n", "append" );
		}

		println( "\n\n\n\n\n\n" );

		self iprintln( "Saved!!! to " + filename );
	}
}

LoadWaypoints()
{
	self DeleteAllWaypoints();
	self iprintlnbold( "Loading WPS..." );
	load_waypoints();

	wait 1;

	self checkForWarnings();
}

checkForWarnings()
{
	if ( level.waypointcount <= 0 )
	{
		self iprintln( "WARNING: waypointCount is " + level.waypointcount );
	}

	if ( level.waypointcount != level.waypoints.size )
	{
		self iprintln( "WARNING: waypointCount is not " + level.waypoints.size );
	}

	for ( i = 0; i < level.waypointcount; i++ )
	{
		if ( !isdefined( level.waypoints[ i ] ) )
		{
			self iprintln( "WARNING: waypoint " + i + " is undefined" );
			continue;
		}

		if ( level.waypoints[ i ].children.size <= 0 )
		{
			self iprintln( "WARNING: waypoint " + i + " childCount is " + level.waypoints[ i ].children.size );
		}
		else
		{
			if ( !isdefined( level.waypoints[ i ].children ) || !isdefined( level.waypoints[ i ].children.size ) )
			{
				self iprintln( "WARNING: waypoint " + i + " children is not defined" );
			}
			else
			{
				for ( h = level.waypoints[ i ].children.size - 1; h >= 0; h-- )
				{
					child = level.waypoints[ i ].children[ h ];

					if ( !isdefined( level.waypoints[ child ] ) )
					{
						self iprintln( "WARNING: waypoint " + i + " child " + child + " is undefined" );
					}
					else if ( child == i )
					{
						self iprintln( "WARNING: waypoint " + i + " child " + child + " is itself" );
					}
				}
			}
		}

		if ( !isdefined( level.waypoints[ i ].type ) )
		{
			self iprintln( "WARNING: waypoint " + i + " type is undefined" );
			continue;
		}

		if ( level.waypoints[ i ].type == "javelin" && !isdefined( level.waypoints[ i ].jav_point ) )
		{
			self iprintln( "WARNING: waypoint " + i + " jav_point is undefined" );
		}

		if ( !isdefined( level.waypoints[ i ].angles ) && ( level.waypoints[ i ].type == "claymore" || level.waypoints[ i ].type == "tube" || ( level.waypoints[ i ].type == "crouch" && level.waypoints[ i ].children.size == 1 ) || level.waypoints[ i ].type == "climb" || level.waypoints[ i ].type == "grenade" ) )
		{
			self iprintln( "WARNING: waypoint " + i + " angles is undefined" );
		}
	}

	// check reachability, assume bidirectional graph

	wpIdx = randomint( level.waypointcount );

	for ( i = 0; i < level.waypointcount; i++ )
	{
		if ( i % 5 == 0 )
		{
			wait 0.05;
		}

		astar = AStarSearch( level.waypoints[ wpIdx ].origin, level.waypoints[ i ].origin, undefined, true );

		if ( astar.size <= 0 )
		{
			self iprintln( "WARNING: waypoint " + wpIdx + " has no path to waypoint " + i );
		}
	}

	self iprintln( "Waypoint warnings check completed." );
}

UnLinkWaypoint( nwp )
{
	if ( nwp == -1 || distance( self.origin, level.waypoints[ nwp ].origin ) > getdvarfloat( "bots_main_debug_minDist" ) )
	{
		self iprintln( "Waypoint unlink Cancelled " + level.wptolink );
		level.wptolink = -1;
		return;
	}

	if ( level.wptolink == -1 || nwp == level.wptolink )
	{
		level.wptolink = nwp;
		self iprintln( "Waypoint unlink Started " + nwp );
		return;
	}

	level.waypoints[ nwp ].children = array_remove( level.waypoints[ nwp ].children, level.wptolink );
	level.waypoints[ level.wptolink ].children = array_remove( level.waypoints[ level.wptolink ].children, nwp );

	self iprintln( "Waypoint " + nwp + " Broken to " + level.wptolink );
	level.wptolink = -1;
}

LinkWaypoint( nwp )
{
	if ( nwp == -1 || distance( self.origin, level.waypoints[ nwp ].origin ) > getdvarfloat( "bots_main_debug_minDist" ) )
	{
		self iprintln( "Waypoint Link Cancelled " + level.wptolink );
		level.wptolink = -1;
		return;
	}

	if ( level.wptolink == -1 || nwp == level.wptolink )
	{
		level.wptolink = nwp;
		self iprintln( "Waypoint Link Started " + nwp );
		return;
	}

	weGood = true;

	for ( i = level.waypoints[ level.wptolink ].children.size - 1; i >= 0; i-- )
	{
		child = level.waypoints[ level.wptolink ].children[ i ];

		if ( child == nwp )
		{
			weGood = false;
			break;
		}
	}

	if ( weGood )
	{
		for ( i = level.waypoints[ nwp ].children.size - 1; i >= 0; i-- )
		{
			child = level.waypoints[ nwp ].children[ i ];

			if ( child == level.wptolink )
			{
				weGood = false;
				break;
			}
		}
	}

	if ( !weGood )
	{
		self iprintln( "Waypoint Link Cancelled " + nwp + " and " + level.wptolink + " already linked." );
		level.wptolink = -1;
		return;
	}

	level.waypoints[ level.wptolink ].children[ level.waypoints[ level.wptolink ].children.size ] = nwp;
	level.waypoints[ nwp ].children[ level.waypoints[ nwp ].children.size ] = level.wptolink;

	self iprintln( "Waypoint " + nwp + " Linked to " + level.wptolink );
	level.wptolink = -1;
}

DeleteWaypoint( nwp )
{
	if ( nwp == -1 || distance( self.origin, level.waypoints[ nwp ].origin ) > getdvarfloat( "bots_main_debug_minDist" ) )
	{
		self iprintln( "No close enough waypoint to delete." );
		return;
	}

	level.wptolink = -1;

	for ( i = level.waypoints[ nwp ].children.size - 1; i >= 0; i-- )
	{
		child = level.waypoints[ nwp ].children[ i ];

		level.waypoints[ child ].children = array_remove( level.waypoints[ child ].children, nwp );
	}

	for ( i = 0; i < level.waypointcount; i++ )
	{
		for ( h = level.waypoints[ i ].children.size - 1; h >= 0; h-- )
		{
			if ( level.waypoints[ i ].children[ h ] > nwp )
			{
				level.waypoints[ i ].children[ h ]--;
			}
		}
	}

	for ( entry = 0; entry < level.waypointcount; entry++ )
	{
		if ( entry == nwp )
		{
			while ( entry < level.waypointcount - 1 )
			{
				level.waypoints[ entry ] = level.waypoints[ entry + 1 ];
				entry++;
			}

			level.waypoints[ entry ] = undefined;
			break;
		}
	}

	level.waypointcount--;

	self iprintln( "DelWp " + nwp );
}

AddWaypoint()
{
	level.waypoints[ level.waypointcount ] = spawnstruct();

	pos = self getorigin();
	level.waypoints[ level.waypointcount ].origin = pos;

	if ( isdefined( self.javelintargetpoint ) )
	{
		level.waypoints[ level.waypointcount ].type = "javelin";
	}
	else if ( self adsbuttonpressed() )
	{
		level.waypoints[ level.waypointcount ].type = "climb";
	}
	else if ( self attackbuttonpressed() && self usebuttonpressed() )
	{
		level.waypoints[ level.waypointcount ].type = "tube";
	}
	else if ( self attackbuttonpressed() )
	{
		level.waypoints[ level.waypointcount ].type = "grenade";
	}
	else if ( self usebuttonpressed() )
	{
		level.waypoints[ level.waypointcount ].type = "claymore";
	}
	else
	{
		level.waypoints[ level.waypointcount ].type = self getstance();
	}

	level.waypoints[ level.waypointcount ].angles = self getplayerangles();

	level.waypoints[ level.waypointcount ].children = [];

	if ( level.waypoints[ level.waypointcount ].type == "javelin" )
	{
		level.waypoints[ level.waypointcount ].jav_point = self.javelintargetpoint;
	}

	self iprintln( level.waypoints[ level.waypointcount ].type + " Waypoint " + level.waypointcount + " Added at " + pos );

	if ( level.autolink )
	{
		if ( level.wptolink == -1 )
		{
			level.wptolink = level.waypointcount - 1;
		}

		level.waypointcount++;
		self LinkWaypoint( level.waypointcount - 1 );
	}
	else
	{
		level.waypointcount++;
	}
}

DeleteAllWaypoints()
{
	level.waypoints = [];
	level.waypointcount = 0;

	self iprintln( "DelAllWps" );
}

buildChildCountString ( wp )
{
	if ( wp == -1 )
	{
		return "";
	}

	wpstr = level.waypoints[ wp ].children.size + "";

	return wpstr;
}

buildChildString( wp )
{
	if ( wp == -1 )
	{
		return "";
	}

	wpstr = "";

	for ( i = 0; i < level.waypoints[ wp ].children.size; i++ )
	{
		if ( i != 0 )
		{
			wpstr = wpstr + "," + level.waypoints[ wp ].children[ i ];
		}
		else
		{
			wpstr = wpstr + level.waypoints[ wp ].children[ i ];
		}
	}

	return wpstr;
}

buildTypeString( wp )
{
	if ( wp == -1 )
	{
		return "";
	}

	return level.waypoints[ wp ].type;
}

destroyOnDeath( hud )
{
	hud endon( "death" );
	self waittill_either( "death", "disconnect" );
	hud destroy();
}

initHudElem( txt, xl, yl )
{
	hud = newclienthudelem( self );
	hud settext( txt );
	hud.alignx = "left";
	hud.aligny = "top";
	hud.horzalign = "left";
	hud.vertalign = "top";
	hud.x = xl;
	hud.y = yl;
	hud.foreground = true;
	hud.fontscale = 1;
	hud.font = "objective";
	hud.alpha = 1;
	hud.glow = 0;
	hud.glowcolor = ( 0, 0, 0 );
	hud.glowalpha = 1;
	hud.color = ( 1.0, 1.0, 1.0 );

	self thread destroyOnDeath( hud );

	return hud;
}

initHudElem2()
{
	infotext = newhudelem();
	infotext settext( "^1[{+smoke}]-AddWp ^2[{+melee}]-LinkWp ^3[{+reload}]-UnLinkWp ^4[{+actionslot 3}]-DeleteWp ^5[{+actionslot 4}]-DelAllWps ^6[{+actionslot 2}]-LoadWPS ^7[{+actionslot 1}]-SaveWp" );
	infotext.alignx = "center";
	infotext.aligny = "bottom";
	infotext.horzalign = "center";
	infotext.vertalign = "bottom";
	infotext.x = -800;
	infotext.y = 25;
	infotext.foreground = true;
	infotext.fontscale = 1.35;
	infotext.font = "objective";
	infotext.alpha = 1;
	infotext.glow = 0;
	infotext.glowcolor = ( 0, 0, 0 );
	infotext.glowalpha = 1;
	infotext.color = ( 1.0, 1.0, 1.0 );

	self thread destroyOnDeath( infotext );

	return infotext;
}

initHudElem3()
{
	bar = level createserverbar( ( 0.5, 0.5, 0.5 ), 1000, 25 );
	bar.alignx = "center";
	bar.aligny = "bottom";
	bar.horzalign = "center";
	bar.vertalign = "bottom";
	bar.y = 30;
	bar.foreground = true;

	self thread destroyOnDeath( bar );

	return bar;
}

initHudElem4()
{
	OptionsBG = newclienthudelem( self );
	OptionsBG.x = 100;
	OptionsBG.y = 2;
	OptionsBG.alignx = "left";
	OptionsBG.aligny = "top";
	OptionsBG.horzalign = "left";
	OptionsBG.vertalign = "top";
	OptionsBG setshader( "black", 200, 60 );
	OptionsBG.alpha = 0.4;

	self thread destroyOnDeath( OptionsBG );

	return OptionsBG;
}
