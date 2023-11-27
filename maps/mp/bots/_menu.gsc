/*
	_menu
	Author: INeedGames
	Date: 09/26/2020
	The ingame menu.
*/

#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

init()
{
	if ( getDvar( "bots_main_menu" ) == "" )
		setDvar( "bots_main_menu", true );

	if ( !getDvarInt( "bots_main_menu" ) )
		return;

	thread watchPlayers();
}

watchPlayers()
{
	for ( ;; )
	{
		wait 1;

		if ( !getDvarInt( "bots_main_menu" ) )
			return;

		for ( i = level.players.size - 1; i >= 0; i-- )
		{
			player = level.players[i];

			if ( !player is_host() )
				continue;

			if ( isDefined( player.menuInit ) && player.menuInit )
				continue;

			player thread init_menu();
		}
	}
}

kill_menu()
{
	self notify( "bots_kill_menu" );
	self.menuInit = undefined;
}

init_menu()
{
	self.menuInit = true;

	self.menuOpen = false;
	self.menu_player = undefined;
	self.SubMenu = "Main";
	self.Curs["Main"]["X"] = 0;
	self AddOptions();

	self thread watchPlayerOpenMenu();
	self thread MenuSelect();
	self thread RightMenu();
	self thread LeftMenu();
	self thread UpMenu();
	self thread DownMenu();

	self thread watchDisconnect();

	self thread doGreetings();
}

watchDisconnect()
{
	self waittill_either( "disconnect", "bots_kill_menu" );

	if ( self.menuOpen )
	{
		if ( isDefined( self.MenuTextY ) )
			for ( i = 0; i < self.MenuTextY.size; i++ )
				if ( isDefined( self.MenuTextY[i] ) )
					self.MenuTextY[i] destroy();

		if ( isDefined( self.MenuText ) )
			for ( i = 0; i < self.MenuText.size; i++ )
				if ( isDefined( self.MenuText[i] ) )
					self.MenuText[i] destroy();

		if ( isDefined( self.Menu ) && isDefined( self.Menu["X"] ) )
		{
			if ( isDefined( self.Menu["X"]["Shader"] ) )
				self.Menu["X"]["Shader"] destroy();

			if ( isDefined( self.Menu["X"]["Scroller"] ) )
				self.Menu["X"]["Scroller"] destroy();
		}

		if ( isDefined( self.menuVersionHud ) )
			self.menuVersionHud destroy();
	}
}

doGreetings()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );
	wait 1;
	self iPrintln( "Welcome to Bot Warfare " + self.name + "!" );
	wait 5;
	self iPrintln( "Press [{+actionslot 2}] to open menu!" );
}

watchPlayerOpenMenu()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );

	self notifyOnPlayerCommand( "bots_open_menu", "+actionslot 2" );

	for ( ;; )
	{
		self waittill( "bots_open_menu" );

		if ( !self.menuOpen )
		{
			self playLocalSound( "mouse_click" );
			self thread OpenSub( self.SubMenu );
		}
		else
		{
			self playLocalSound( "mouse_click" );

			if ( self.SubMenu != "Main" )
				self ExitSub();
			else
			{
				self ExitMenu();

				if ( !gameFlag( "prematch_done" ) || level.gameEnded )
					self freezeControls( true );
				else
					self freezecontrols( false );
			}
		}
	}
}

MenuSelect()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );

	self notifyOnPlayerCommand( "bots_select", "+gostand" );

	for ( ;; )
	{
		self waittill( "bots_select" );

		if ( self.MenuOpen )
		{
			self playLocalSound( "mouse_click" );

			if ( self.SubMenu == "Main" )
				self thread [[self.Option["Function"][self.SubMenu][self.Curs["Main"]["X"]]]]( self.Option["Arg1"][self.SubMenu][self.Curs["Main"]["X"]], self.Option["Arg2"][self.SubMenu][self.Curs["Main"]["X"]] );
			else
				self thread [[self.Option["Function"][self.SubMenu][self.Curs[self.SubMenu]["Y"]]]]( self.Option["Arg1"][self.SubMenu][self.Curs[self.SubMenu]["Y"]], self.Option["Arg2"][self.SubMenu][self.Curs[self.SubMenu]["Y"]] );
		}
	}
}

LeftMenu()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );

	self notifyOnPlayerCommand( "bots_left", "+moveleft" );

	for ( ;; )
	{
		self waittill( "bots_left" );

		if ( self.MenuOpen && self.SubMenu == "Main" )
		{
			self playLocalSound( "mouse_over" );
			self.Curs["Main"]["X"]--;

			if ( self.Curs["Main"]["X"] < 0 )
				self.Curs["Main"]["X"] = self.Option["Name"][self.SubMenu].size - 1;

			self CursMove( "X" );
		}
	}
}

RightMenu()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );

	self notifyOnPlayerCommand( "bots_right", "+moveright" );

	for ( ;; )
	{
		self waittill( "bots_right" );

		if ( self.MenuOpen && self.SubMenu == "Main" )
		{
			self playLocalSound( "mouse_over" );
			self.Curs["Main"]["X"]++;

			if ( self.Curs["Main"]["X"] > self.Option["Name"][self.SubMenu].size - 1 )
				self.Curs["Main"]["X"] = 0;

			self CursMove( "X" );
		}
	}
}

UpMenu()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );

	self notifyOnPlayerCommand( "bots_up", "+forward" );

	for ( ;; )
	{
		self waittill( "bots_up" );

		if ( self.MenuOpen && self.SubMenu != "Main" )
		{
			self playLocalSound( "mouse_over" );
			self.Curs[self.SubMenu]["Y"]--;

			if ( self.Curs[self.SubMenu]["Y"] < 0 )
				self.Curs[self.SubMenu]["Y"] = self.Option["Name"][self.SubMenu].size - 1;

			self CursMove( "Y" );
		}
	}
}

DownMenu()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );

	self notifyOnPlayerCommand( "bots_down", "+back" );

	for ( ;; )
	{
		self waittill( "bots_down" );

		if ( self.MenuOpen && self.SubMenu != "Main" )
		{
			self playLocalSound( "mouse_over" );
			self.Curs[self.SubMenu]["Y"]++;

			if ( self.Curs[self.SubMenu]["Y"] > self.Option["Name"][self.SubMenu].size - 1 )
				self.Curs[self.SubMenu]["Y"] = 0;

			self CursMove( "Y" );
		}
	}
}

OpenSub( menu, menu2 )
{
	if ( menu != "Main" && ( !isDefined( self.Menu[menu] ) || !!isDefined( self.Menu[menu]["FirstOpen"] ) ) )
	{
		self.Curs[menu]["Y"] = 0;
		self.Menu[menu]["FirstOpen"] = true;
	}

	logoldi = true;
	self.SubMenu = menu;

	if ( self.SubMenu == "Main" )
	{
		if ( isDefined( self.MenuText ) )
			for ( i = 0; i < self.MenuText.size; i++ )
				if ( isDefined( self.MenuText[i] ) )
					self.MenuText[i] destroy();

		if ( isDefined( self.Menu ) && isDefined( self.Menu["X"] ) )
		{
			if ( isDefined( self.Menu["X"]["Shader"] ) )
				self.Menu["X"]["Shader"] destroy();

			if ( isDefined( self.Menu["X"]["Scroller"] ) )
				self.Menu["X"]["Scroller"] destroy();
		}

		if ( isDefined( self.menuVersionHud ) )
			self.menuVersionHud destroy();

		for ( i = 0 ; i < self.Option["Name"][self.SubMenu].size ; i++ )
		{
			self.MenuText[i] = self createfontstring( "default", 1.6 );
			self.MenuText[i] setpoint( "CENTER", "CENTER", -300 + ( i * 100 ), -226 );
			self.MenuText[i] settext( self.Option["Name"][self.SubMenu][i] );

			if ( logOldi )
				self.oldi = i;

			if ( self.MenuText[i].x > 300 )
			{
				logOldi = false;
				x = i - self.oldi;
				self.MenuText[i] setpoint( "CENTER", "CENTER", ( ( ( -300 ) - ( i * 100 ) ) + ( i * 100 ) ) + ( x * 100 ), -196 );
			}

			self.MenuText[i].alpha = 1;
			self.MenuText[i].sort = 999;
		}

		if ( !logOldi )
			self.Menu["X"]["Shader"] = self createRectangle( "CENTER", "CENTER", 0, -225, 1000, 90, ( 0, 0, 0 ), -2, 1, "white" );
		else
			self.Menu["X"]["Shader"] = self createRectangle( "CENTER", "CENTER", 0, -225, 1000, 30, ( 0, 0, 0 ), -2, 1, "white" );

		self.Menu["X"]["Scroller"] = self createRectangle( "CENTER", "CENTER", self.MenuText[self.Curs["Main"]["X"]].x, -225, 105, 22, ( 1, 0, 0 ), -1, 1, "white" );

		self CursMove( "X" );

		self.menuVersionHud = initHudElem( "Bot Warfare " + level.bw_VERSION, 0, 0 );

		self.MenuOpen = true;
	}
	else
	{
		if ( isDefined( self.MenuTextY ) )
			for ( i = 0 ; i < self.MenuTextY.size ; i++ )
				if ( isDefined( self.MenuTextY[i] ) )
					self.MenuTextY[i] destroy();

		for ( i = 0 ; i < self.Option["Name"][self.SubMenu].size ; i++ )
		{
			self.MenuTextY[i] = self createfontstring( "default", 1.6 );
			self.MenuTextY[i] setpoint( "CENTER", "CENTER", self.MenuText[self.Curs["Main"]["X"]].x, -160 + ( i * 20 ) );
			self.MenuTextY[i] settext( self.Option["Name"][self.SubMenu][i] );
			self.MenuTextY[i].alpha = 1;
			self.MenuTextY[i].sort = 999;
		}

		self CursMove( "Y" );
	}
}

CursMove( direction )
{
	self notify( "scrolled" );

	if ( self.SubMenu == "Main" )
	{
		self.Menu["X"]["Scroller"].x = self.MenuText[self.Curs["Main"]["X"]].x;
		self.Menu["X"]["Scroller"].y = self.MenuText[self.Curs["Main"]["X"]].y;

		if ( isDefined( self.MenuText ) )
		{
			for ( i = 0; i < self.MenuText.size; i++ )
			{
				if ( isDefined( self.MenuText[i] ) )
				{
					self.MenuText[i].fontscale = 1.5;
					self.MenuText[i].color = ( 1, 1, 1 );
					self.MenuText[i].glowAlpha = 0;
				}
			}
		}

		self thread ShowOptionOn( direction );
	}
	else
	{
		if ( isDefined( self.MenuTextY ) )
		{
			for ( i = 0; i < self.MenuTextY.size; i++ )
			{
				if ( isDefined( self.MenuTextY[i] ) )
				{
					self.MenuTextY[i].fontscale = 1.5;
					self.MenuTextY[i].color = ( 1, 1, 1 );
					self.MenuTextY[i].glowAlpha = 0;
				}
			}
		}

		if ( isDefined( self.MenuText ) )
		{
			for ( i = 0; i < self.MenuText.size; i++ )
			{
				if ( isDefined( self.MenuText[i] ) )
				{
					self.MenuText[i].fontscale = 1.5;
					self.MenuText[i].color = ( 1, 1, 1 );
					self.MenuText[i].glowAlpha = 0;
				}
			}
		}

		self thread ShowOptionOn( direction );
	}
}

ShowOptionOn( variable )
{
	self endon( "scrolled" );
	self endon( "disconnect" );
	self endon( "exit" );
	self endon( "bots_kill_menu" );

	for ( time = 0;; time += 0.05 )
	{
		if ( !self isOnGround() && isAlive( self ) && gameFlag( "prematch_done" ) && !level.gameEnded )
			self freezecontrols( false );
		else
			self freezecontrols( true );

		self setClientDvar( "r_blur", "5" );
		self setClientDvar( "sc_blur", "15" );
		self addOptions();

		if ( self.SubMenu == "Main" )
		{
			if ( isDefined( self.Curs[self.SubMenu][variable] ) && isDefined( self.MenuText ) && isDefined( self.MenuText[self.Curs[self.SubMenu][variable]] ) )
			{
				self.MenuText[self.Curs[self.SubMenu][variable]].fontscale = 2.0;
				//self.MenuText[self.Curs[self.SubMenu][variable]].color = (randomInt(256)/255, randomInt(256)/255, randomInt(256)/255);
				color = ( 6 / 255, 69 / 255, 173 + randomIntRange( -5, 5 ) / 255 );

				if ( int( time * 4 ) % 2 )
					color = ( 11 / 255, 0 / 255, 128 + randomIntRange( -10, 10 ) / 255 );

				self.MenuText[self.Curs[self.SubMenu][variable]].color = color;
			}

			if ( isDefined( self.MenuText ) )
			{
				for ( i = 0; i < self.Option["Name"][self.SubMenu].size; i++ )
				{
					if ( isDefined( self.MenuText[i] ) )
						self.MenuText[i] settext( self.Option["Name"][self.SubMenu][i] );
				}
			}
		}
		else
		{
			if ( isDefined( self.Curs[self.SubMenu][variable] ) && isDefined( self.MenuTextY ) && isDefined( self.MenuTextY[self.Curs[self.SubMenu][variable]] ) )
			{
				self.MenuTextY[self.Curs[self.SubMenu][variable]].fontscale = 2.0;
				//self.MenuTextY[self.Curs[self.SubMenu][variable]].color = (randomInt(256)/255, randomInt(256)/255, randomInt(256)/255);
				color = ( 6 / 255, 69 / 255, 173 + randomIntRange( -5, 5 ) / 255 );

				if ( int( time * 4 ) % 2 )
					color = ( 11 / 255, 0 / 255, 128 + randomIntRange( -10, 10 ) / 255 );

				self.MenuTextY[self.Curs[self.SubMenu][variable]].color = color;
			}

			if ( isDefined( self.MenuTextY ) )
			{
				for ( i = 0; i < self.Option["Name"][self.SubMenu].size; i++ )
				{
					if ( isDefined( self.MenuTextY[i] ) )
						self.MenuTextY[i] settext( self.Option["Name"][self.SubMenu][i] );
				}
			}
		}

		wait 0.05;
	}
}

AddMenu( menu, num, text, function, arg1, arg2 )
{
	self.Option["Name"][menu][num] = text;
	self.Option["Function"][menu][num] = function;
	self.Option["Arg1"][menu][num] = arg1;
	self.Option["Arg2"][menu][num] = arg2;
}

AddBack( menu, back )
{
	self.Menu["Back"][menu] = back;
}

ExitSub()
{
	if ( isDefined( self.MenuTextY ) )
		for ( i = 0; i < self.MenuTextY.size; i++ )
			if ( isDefined( self.MenuTextY[i] ) )
				self.MenuTextY[i] destroy();

	self.SubMenu = self.Menu["Back"][self.Submenu];

	if ( self.SubMenu == "Main" )
		self CursMove( "X" );
	else
		self CursMove( "Y" );
}

ExitMenu()
{
	if ( isDefined( self.MenuText ) )
		for ( i = 0; i < self.MenuText.size; i++ )
			if ( isDefined( self.MenuText[i] ) )
				self.MenuText[i] destroy();

	if ( isDefined( self.Menu ) && isDefined( self.Menu["X"] ) )
	{
		if ( isDefined( self.Menu["X"]["Shader"] ) )
			self.Menu["X"]["Shader"] destroy();

		if ( isDefined( self.Menu["X"]["Scroller"] ) )
			self.Menu["X"]["Scroller"] destroy();
	}

	if ( isDefined( self.menuVersionHud ) )
		self.menuVersionHud destroy();

	self.MenuOpen = false;
	self notify( "exit" );

	self setClientDvar( "r_blur", "0" );
	self setClientDvar( "sc_blur", "2" );
}

initHudElem( txt, xl, yl )
{
	hud = NewClientHudElem( self );
	hud setText( txt );
	hud.alignX = "center";
	hud.alignY = "bottom";
	hud.horzAlign = "center";
	hud.vertAlign = "bottom";
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

	return hud;
}

createRectangle( align, relative, x, y, width, height, color, sort, alpha, shader )
{
	barElemBG = newClientHudElem( self );
	barElemBG.elemType = "bar_";
	barElemBG.width = width;
	barElemBG.height = height;
	barElemBG.align = align;
	barElemBG.relative = relative;
	barElemBG.xOffset = 0;
	barElemBG.yOffset = 0;
	barElemBG.children = [];
	barElemBG.sort = sort;
	barElemBG.color = color;
	barElemBG.alpha = alpha;
	barElemBG setParent( level.uiParent );
	barElemBG setShader( shader, width, height );
	barElemBG.hidden = false;
	barElemBG setPoint( align, relative, x, y );
	return barElemBG;
}

AddOptions()
{
	self AddMenu( "Main", 0, "Manage bots", ::OpenSub, "man_bots", "" );
	self AddBack( "man_bots", "Main" );

	_temp = "";
	_tempDvar = getDvarInt( "bots_manage_add" );
	self AddMenu( "man_bots", 0, "Add 1 bot", ::man_bots, "add", 1 + _tempDvar );
	self AddMenu( "man_bots", 1, "Add 3 bot", ::man_bots, "add", 3 + _tempDvar );
	self AddMenu( "man_bots", 2, "Add 7 bot", ::man_bots, "add", 7 + _tempDvar );
	self AddMenu( "man_bots", 3, "Add 11 bot", ::man_bots, "add", 11 + _tempDvar );
	self AddMenu( "man_bots", 4, "Add 17 bot", ::man_bots, "add", 17 + _tempDvar );
	self AddMenu( "man_bots", 5, "Kick a bot", ::man_bots, "kick", 1 );
	self AddMenu( "man_bots", 6, "Kick all bots", ::man_bots, "kick", getBotArray().size );

	_tempDvar = getDvarInt( "bots_manage_fill_kick" );

	if ( _tempDvar )
		_temp = "true";
	else
		_temp = "false";

	self AddMenu( "man_bots", 7, "Toggle auto bot kicking: " + _temp, ::man_bots, "autokick", _tempDvar );

	_tempDvar = getDvarInt( "bots_manage_fill_mode" );

	switch ( _tempDvar )
	{
		case 0:
			_temp = "everyone";
			break;

		case 1:
			_temp = "just bots";
			break;

		case 2:
			_temp = "everyone, adjust to map";
			break;

		case 3:
			_temp = "just bots, adjust to map";
			break;

		case 4:
			_temp = "bots used as team balance";
			break;

		default:
			_temp = "out of range";
			break;
	}

	self AddMenu( "man_bots", 8, "Change bot_fill_mode: " + _temp, ::man_bots, "fillmode", _tempDvar );

	_tempDvar = getDvarInt( "bots_manage_fill" );
	self AddMenu( "man_bots", 9, "Increase bots to keep in-game: " + _tempDvar, ::man_bots, "fillup", _tempDvar );
	self AddMenu( "man_bots", 10, "Decrease bots to keep in-game: " + _tempDvar, ::man_bots, "filldown", _tempDvar );

	_tempDvar = getDvarInt( "bots_manage_fill_spec" );

	if ( _tempDvar )
		_temp = "true";
	else
		_temp = "false";

	self AddMenu( "man_bots", 11, "Count players for fill on spectator: " + _temp, ::man_bots, "fillspec", _tempDvar );

	//

	self AddMenu( "Main", 1, "Teams and difficulty", ::OpenSub, "man_team", "" );
	self AddBack( "man_team", "Main" );

	_tempDvar = getdvar( "bots_team" );
	self AddMenu( "man_team", 0, "Change bot team: " + _tempDvar, ::bot_teams, "team", _tempDvar );

	_tempDvar = getDvarInt( "bots_team_amount" );
	self AddMenu( "man_team", 1, "Increase bots to be on axis team: " + _tempDvar, ::bot_teams, "teamup", _tempDvar );
	self AddMenu( "man_team", 2, "Decrease bots to be on axis team: " + _tempDvar, ::bot_teams, "teamdown", _tempDvar );

	_tempDvar = getDvarInt( "bots_team_force" );

	if ( _tempDvar )
		_temp = "true";
	else
		_temp = "false";

	self AddMenu( "man_team", 3, "Toggle forcing bots on team: " + _temp, ::bot_teams, "teamforce", _tempDvar );

	_tempDvar = getDvarInt( "bots_team_mode" );

	if ( _tempDvar )
		_temp = "only bots";
	else
		_temp = "everyone";

	self AddMenu( "man_team", 4, "Toggle bot_team_bot: " + _temp, ::bot_teams, "teammode", _tempDvar );

	_tempDvar = getdvarint( "bots_skill" );

	switch ( _tempDvar )
	{
		case 0:
			_temp = "random for all";
			break;

		case 1:
			_temp = "too easy";
			break;

		case 2:
			_temp = "easy";
			break;

		case 3:
			_temp = "easy-medium";
			break;

		case 4:
			_temp = "medium";
			break;

		case 5:
			_temp = "hard";
			break;

		case 6:
			_temp = "very hard";
			break;

		case 7:
			_temp = "hardest";
			break;

		case 8:
			_temp = "custom";
			break;

		case 9:
			_temp = "complete random";
			break;

		default:
			_temp = "out of range";
			break;
	}

	self AddMenu( "man_team", 5, "Change bot difficulty: " + _temp, ::bot_teams, "skill", _tempDvar );

	_tempDvar = getDvarInt( "bots_skill_axis_hard" );
	self AddMenu( "man_team", 6, "Increase amount of hard bots on axis team: " + _tempDvar, ::bot_teams, "axishardup", _tempDvar );
	self AddMenu( "man_team", 7, "Decrease amount of hard bots on axis team: " + _tempDvar, ::bot_teams, "axisharddown", _tempDvar );

	_tempDvar = getDvarInt( "bots_skill_axis_med" );
	self AddMenu( "man_team", 8, "Increase amount of med bots on axis team: " + _tempDvar, ::bot_teams, "axismedup", _tempDvar );
	self AddMenu( "man_team", 9, "Decrease amount of med bots on axis team: " + _tempDvar, ::bot_teams, "axismeddown", _tempDvar );

	_tempDvar = getDvarInt( "bots_skill_allies_hard" );
	self AddMenu( "man_team", 10, "Increase amount of hard bots on allies team: " + _tempDvar, ::bot_teams, "allieshardup", _tempDvar );
	self AddMenu( "man_team", 11, "Decrease amount of hard bots on allies team: " + _tempDvar, ::bot_teams, "alliesharddown", _tempDvar );

	_tempDvar = getDvarInt( "bots_skill_allies_med" );
	self AddMenu( "man_team", 12, "Increase amount of med bots on allies team: " + _tempDvar, ::bot_teams, "alliesmedup", _tempDvar );
	self AddMenu( "man_team", 13, "Decrease amount of med bots on allies team: " + _tempDvar, ::bot_teams, "alliesmeddown", _tempDvar );

	//

	self AddMenu( "Main", 2, "Bot settings", ::OpenSub, "set1", "" );
	self AddBack( "set1", "Main" );

	_tempDvar = getDvarInt( "bots_loadout_reasonable" );

	if ( _tempDvar )
		_temp = "true";
	else
		_temp = "false";

	self AddMenu( "set1", 0, "Bots use only good class setups: " + _temp, ::bot_func, "reasonable", _tempDvar );

	_tempDvar = getDvarInt( "bots_loadout_allow_op" );

	if ( _tempDvar )
		_temp = "true";
	else
		_temp = "false";

	self AddMenu( "set1", 1, "Bots can use op and annoying class setups: " + _temp, ::bot_func, "op", _tempDvar );

	_tempDvar = getDvarInt( "bots_play_move" );

	if ( _tempDvar )
		_temp = "true";
	else
		_temp = "false";

	self AddMenu( "set1", 2, "Bots can move: " + _temp, ::bot_func, "move", _tempDvar );

	_tempDvar = getDvarInt( "bots_play_knife" );

	if ( _tempDvar )
		_temp = "true";
	else
		_temp = "false";

	self AddMenu( "set1", 3, "Bots can knife: " + _temp, ::bot_func, "knife", _tempDvar );

	_tempDvar = getDvarInt( "bots_play_fire" );

	if ( _tempDvar )
		_temp = "true";
	else
		_temp = "false";

	self AddMenu( "set1", 4, "Bots can fire: " + _temp, ::bot_func, "fire", _tempDvar );

	_tempDvar = getDvarInt( "bots_play_nade" );

	if ( _tempDvar )
		_temp = "true";
	else
		_temp = "false";

	self AddMenu( "set1", 5, "Bots can nade: " + _temp, ::bot_func, "nade", _tempDvar );

	_tempDvar = getDvarInt( "bots_play_take_carepackages" );

	if ( _tempDvar )
		_temp = "true";
	else
		_temp = "false";

	self AddMenu( "set1", 6, "Bots can take carepackages: " + _temp, ::bot_func, "care", _tempDvar );

	_tempDvar = getDvarInt( "bots_play_obj" );

	if ( _tempDvar )
		_temp = "true";
	else
		_temp = "false";

	self AddMenu( "set1", 7, "Bots play the objective: " + _temp, ::bot_func, "obj", _tempDvar );

	_tempDvar = getDvarInt( "bots_play_camp" );

	if ( _tempDvar )
		_temp = "true";
	else
		_temp = "false";

	self AddMenu( "set1", 8, "Bots can camp: " + _temp, ::bot_func, "camp", _tempDvar );

	_tempDvar = getDvarInt( "bots_play_jumpdrop" );

	if ( _tempDvar )
		_temp = "true";
	else
		_temp = "false";

	self AddMenu( "set1", 9, "Bots can jump and dropshot: " + _temp, ::bot_func, "jump", _tempDvar );

	_tempDvar = getDvarInt( "bots_play_target_other" );

	if ( _tempDvar )
		_temp = "true";
	else
		_temp = "false";

	self AddMenu( "set1", 10, "Bots can target other script objects: " + _temp, ::bot_func, "targetother", _tempDvar );

	_tempDvar = getDvarInt( "bots_play_killstreak" );

	if ( _tempDvar )
		_temp = "true";
	else
		_temp = "false";

	self AddMenu( "set1", 11, "Bots can use killstreaks: " + _temp, ::bot_func, "killstreak", _tempDvar );

	_tempDvar = getDvarInt( "bots_play_ads" );

	if ( _tempDvar )
		_temp = "true";
	else
		_temp = "false";

	self AddMenu( "set1", 12, "Bots can ads: " + _temp, ::bot_func, "ads", _tempDvar );
}

bot_func( a, b )
{
	switch ( a )
	{
		case "reasonable":
			setDvar( "bots_loadout_reasonable", !b );
			self iPrintln( "Bots using reasonable setups: " + !b );
			break;

		case "op":
			setDvar( "bots_loadout_allow_op", !b );
			self iPrintln( "Bots using op setups: " + !b );
			break;

		case "move":
			setDvar( "bots_play_move", !b );
			self iPrintln( "Bots move: " + !b );
			break;

		case "knife":
			setDvar( "bots_play_knife", !b );
			self iPrintln( "Bots knife: " + !b );
			break;

		case "fire":
			setDvar( "bots_play_fire", !b );
			self iPrintln( "Bots fire: " + !b );
			break;

		case "nade":
			setDvar( "bots_play_nade", !b );
			self iPrintln( "Bots nade: " + !b );
			break;

		case "care":
			setDvar( "bots_play_take_carepackages", !b );
			self iPrintln( "Bots take carepackages: " + !b );
			break;

		case "obj":
			setDvar( "bots_play_obj", !b );
			self iPrintln( "Bots play the obj: " + !b );
			break;

		case "camp":
			setDvar( "bots_play_camp", !b );
			self iPrintln( "Bots camp: " + !b );
			break;

		case "jump":
			setDvar( "bots_play_jumpdrop", !b );
			self iPrintln( "Bots jump: " + !b );
			break;

		case "targetother":
			setDvar( "bots_play_target_other", !b );
			self iPrintln( "Bots target other: " + !b );
			break;

		case "killstreak":
			setDvar( "bots_play_killstreak", !b );
			self iPrintln( "Bots use killstreaks: " + !b );
			break;

		case "ads":
			setDvar( "bots_play_ads", !b );
			self iPrintln( "Bots ads: " + !b );
			break;
	}
}

bot_teams( a, b )
{
	switch ( a )
	{
		case "team":
			switch ( b )
			{
				case "autoassign":
					setdvar( "bots_team", "allies" );
					self iPrintlnBold( "Changed bot team to allies." );
					break;

				case "allies":
					setdvar( "bots_team", "axis" );
					self iPrintlnBold( "Changed bot team to axis." );
					break;

				case "axis":
					setdvar( "bots_team", "custom" );
					self iPrintlnBold( "Changed bot team to custom." );
					break;

				default:
					setdvar( "bots_team", "autoassign" );
					self iPrintlnBold( "Changed bot team to autoassign." );
					break;
			}

			break;

		case "teamup":
			setdvar( "bots_team_amount", b + 1 );
			self iPrintln( ( b + 1 ) + " bot(s) will try to be on axis team." );
			break;

		case "teamdown":
			setdvar( "bots_team_amount", b - 1 );
			self iPrintln( ( b - 1 ) + " bot(s) will try to be on axis team." );
			break;

		case "teamforce":
			setDvar( "bots_team_force", !b );
			self iPrintln( "Forcing bots to team: " + !b );
			break;

		case "teammode":
			setDvar( "bots_team_mode", !b );
			self iPrintln( "Only count bots on team: " + !b );
			break;

		case "skill":
			switch ( b )
			{
				case 0:
					self iPrintlnBold( "Changed bot skill to easy." );
					setDvar( "bots_skill", 1 );
					break;

				case 1:
					self iPrintlnBold( "Changed bot skill to easy-med." );
					setDvar( "bots_skill", 2 );
					break;

				case 2:
					self iPrintlnBold( "Changed bot skill to medium." );
					setDvar( "bots_skill", 3 );
					break;

				case 3:
					self iPrintlnBold( "Changed bot skill to med-hard." );
					setDvar( "bots_skill", 4 );
					break;

				case 4:
					self iPrintlnBold( "Changed bot skill to hard." );
					setDvar( "bots_skill", 5 );
					break;

				case 5:
					self iPrintlnBold( "Changed bot skill to very hard." );
					setDvar( "bots_skill", 6 );
					break;

				case 6:
					self iPrintlnBold( "Changed bot skill to hardest." );
					setDvar( "bots_skill", 7 );
					break;

				case 7:
					self iPrintlnBold( "Changed bot skill to custom. Base is easy." );
					setDvar( "bots_skill", 8 );
					break;

				case 8:
					self iPrintlnBold( "Changed bot skill to complete random. Takes effect at restart." );
					setDvar( "bots_skill", 9 );
					break;

				default:
					self iPrintlnBold( "Changed bot skill to random. Takes effect at restart." );
					setDvar( "bots_skill", 0 );
					break;
			}

			break;

		case "axishardup":
			setdvar( "bots_skill_axis_hard", ( b + 1 ) );
			self iPrintln( ( ( b + 1 ) ) + " hard bots will be on axis team." );
			break;

		case "axisharddown":
			setdvar( "bots_skill_axis_hard", ( b - 1 ) );
			self iPrintln( ( ( b - 1 ) ) + " hard bots will be on axis team." );
			break;

		case "axismedup":
			setdvar( "bots_skill_axis_med", ( b + 1 ) );
			self iPrintln( ( ( b + 1 ) ) + " med bots will be on axis team." );
			break;

		case "axismeddown":
			setdvar( "bots_skill_axis_med", ( b - 1 ) );
			self iPrintln( ( ( b - 1 ) ) + " med bots will be on axis team." );
			break;

		case "allieshardup":
			setdvar( "bots_skill_allies_hard", ( b + 1 ) );
			self iPrintln( ( ( b + 1 ) ) + " hard bots will be on allies team." );
			break;

		case "alliesharddown":
			setdvar( "bots_skill_allies_hard", ( b - 1 ) );
			self iPrintln( ( ( b - 1 ) ) + " hard bots will be on allies team." );
			break;

		case "alliesmedup":
			setdvar( "bots_skill_allies_med", ( b + 1 ) );
			self iPrintln( ( ( b + 1 ) ) + " med bots will be on allies team." );
			break;

		case "alliesmeddown":
			setdvar( "bots_skill_allies_med", ( b - 1 ) );
			self iPrintln( ( ( b - 1 ) ) + " med bots will be on allies team." );
			break;
	}
}

man_bots( a, b )
{
	switch ( a )
	{
		case "add":
			setdvar( "bots_manage_add", b );

			if ( b == 1 )
			{
				self iPrintln( "Adding " + b + " bot." );
			}
			else
			{
				self iPrintln( "Adding " + b + " bots." );
			}

			break;

		case "kick":
			result = false;

			for ( i = 0; i < b; i++ )
			{
				tempBot = random( getBotArray() );

				if ( isDefined( tempBot ) )
				{
					kick( tempBot getEntityNumber(), "EXE_PLAYERKICKED" );
					result = true;
				}

				wait 0.25;
			}

			if ( !result )
				self iPrintln( "No bots to kick" );

			break;

		case "autokick":
			setDvar( "bots_manage_fill_kick", !b );
			self iPrintln( "Kicking bots when bots_fill is exceeded: " + !b );
			break;

		case "fillmode":
			switch ( b )
			{
				case 0:
					setdvar( "bots_manage_fill_mode", 1 );
					self iPrintln( "bot_fill will now count only bots." );
					break;

				case 1:
					setdvar( "bots_manage_fill_mode", 2 );
					self iPrintln( "bot_fill will now count everyone, adjusting to map." );
					break;

				case 2:
					setdvar( "bots_manage_fill_mode", 3 );
					self iPrintln( "bot_fill will now count only bots, adjusting to map." );
					break;

				case 3:
					setdvar( "bots_manage_fill_mode", 4 );
					self iPrintln( "bot_fill will now use bots as team balance." );
					break;

				default:
					setdvar( "bots_manage_fill_mode", 0 );
					self iPrintln( "bot_fill will now count everyone." );
					break;
			}

			break;

		case "fillup":
			setdvar( "bots_manage_fill", b + 1 );
			self iPrintln( "Increased to maintain " + ( b + 1 ) + " bot(s)." );
			break;

		case "filldown":
			setdvar( "bots_manage_fill", b - 1 );
			self iPrintln( "Decreased to maintain " + ( b - 1 ) + " bot(s)." );
			break;

		case "fillspec":
			setDvar( "bots_manage_fill_spec", !b );
			self iPrintln( "Count players on spectator for bots_fill: " + !b );
			break;
	}
}
