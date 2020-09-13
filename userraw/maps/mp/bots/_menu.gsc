#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;
#include maps\mp\bots\_bot_utility;

init()
{
  if (getDvar("bots_main_fun") == "")
    setDvar("bots_main_fun", false);

  if (getDvar("bots_main_menu") == "")
    setDvar("bots_main_menu", true);
  
  thread watchPlayers();
}

watchPlayers()
{
  for (;;)
  {
    wait 1;

    for (i = level.players.size - 1; i >= 0; i--)
    {
      player = level.players[i];

      if (!getDvarInt("bots_main_menu"))
        continue;

      if (!player is_host())
        continue;

      if (isDefined(player.menuInit) && player.menuInit)
        continue;

      player thread init_menu();
    }
  }
}

kill_menu()
{
  self notify("bots_kill_menu");
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
	self waittill_either("disconnect", "bots_kill_menu");
	
	if(self.menuOpen)
	{
		if(isDefined(self.MenuTextY))
			for(i = 0; i < self.MenuTextY.size; i++)
				if(isDefined(self.MenuTextY[i]))
					self.MenuTextY[i] destroy();
		
		if(isDefined(self.MenuText))
			for(i = 0; i < self.MenuText.size; i++)
				if(isDefined(self.MenuText[i]))
					self.MenuText[i] destroy();
		
		if(isDefined(self.Menu) && isDefined(self.Menu["X"]))
		{
			if(isDefined(self.Menu["X"]["Shader"]))
				self.Menu["X"]["Shader"] destroy();
			
			if(isDefined(self.Menu["X"]["Scroller"]))
				self.Menu["X"]["Scroller"] destroy();
		}
	}
}

doGreetings()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );
	wait 1;
	self iPrintln("Welcome to Bot Warfare "+self.name+"!");
	wait 5;
	if(getDvarInt("bots_main_menu"))
		self iPrintln("Press [{+actionslot 2}] to open menu!");
}

watchPlayerOpenMenu()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );
	
	self notifyOnPlayerCommand( "bots_open_menu", "+actionslot 2" );
	for(;;)
	{
		self waittill( "bots_open_menu" );
		if(!self.menuOpen)
		{
			if(getdvarint("bots_main_menu"))
			{
				self playLocalSound( "mouse_click" );
				self thread OpenSub(self.SubMenu);
			}
		}
		else
		{
			self playLocalSound( "mouse_click" );
			if(self.SubMenu != "Main")
				self ExitSub();
			else
			{
				self ExitMenu();
				if((!gameFlag( "prematch_done" ) || level.gameEnded) && !getDvarInt("bots_main_fun"))
					self freezeControls(true);
				else
					self freezecontrols(false);
			}
		}
	}
}

MenuSelect()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );
	
	self notifyOnPlayerCommand("bots_select", "+gostand");
	for(;;)
	{
		self waittill( "bots_select" );
		if(self.MenuOpen && getdvarint("bots_main_menu"))
		{
			self playLocalSound( "mouse_click" );
			if(self.SubMenu == "Main")
				self thread [[self.Option["Function"][self.SubMenu][self.Curs["Main"]["X"]]]](self.Option["Arg1"][self.SubMenu][self.Curs["Main"]["X"]],self.Option["Arg2"][self.SubMenu][self.Curs["Main"]["X"]]);
			else
				self thread [[self.Option["Function"][self.SubMenu][self.Curs[self.SubMenu]["Y"]]]](self.Option["Arg1"][self.SubMenu][self.Curs[self.SubMenu]["Y"]],self.Option["Arg2"][self.SubMenu][self.Curs[self.SubMenu]["Y"]]);
		}
	}
}

LeftMenu()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );

	self notifyOnPlayerCommand( "bots_left", "+moveleft" ); 
	for(;;)
	{
		self waittill( "bots_left" );
		if(self.MenuOpen && self.SubMenu == "Main")
		{
			self playLocalSound("mouse_over");
			self.Curs["Main"]["X"]--;

			if(self.Curs["Main"]["X"] < 0)
				self.Curs["Main"]["X"] = self.Option["Name"][self.SubMenu].size -1;

			self CursMove("X");
		}
	}
}

RightMenu()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );

	self notifyOnPlayerCommand("bots_right", "+moveright");
	for(;;)
	{
		self waittill( "bots_right" );
		if(self.MenuOpen && self.SubMenu == "Main")
		{
			self playLocalSound("mouse_over");
			self.Curs["Main"]["X"]++;

			if(self.Curs["Main"]["X"] > self.Option["Name"][self.SubMenu].size -1)
				self.Curs["Main"]["X"] = 0;

			self CursMove("X");
		}
	}
}

UpMenu()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );
	
	self notifyOnPlayerCommand( "bots_up", "+forward" );
	for(;;)
	{
		self waittill( "bots_up" );
		if(self.MenuOpen && self.SubMenu != "Main")
		{
			self playLocalSound("mouse_over");
			self.Curs[self.SubMenu]["Y"]--;

			if(self.Curs[self.SubMenu]["Y"] < 0)
				self.Curs[self.SubMenu]["Y"] = self.Option["Name"][self.SubMenu].size -1;

			self CursMove("Y");
		}
	}
}

DownMenu()
{
	self endon ( "disconnect" );
	self endon ( "bots_kill_menu" );

	self notifyOnPlayerCommand( "bots_down", "+back" );
	for(;;)
	{
		self waittill( "bots_down" );
		if(self.MenuOpen && self.SubMenu != "Main")
		{
			self playLocalSound("mouse_over");
			self.Curs[self.SubMenu]["Y"]++;

			if(self.Curs[self.SubMenu]["Y"] > self.Option["Name"][self.SubMenu].size -1)
				self.Curs[self.SubMenu]["Y"] = 0;

			self CursMove("Y");
		}
	}
}

OpenSub(menu, menu2)
{
	if(menu != "Main" && (!isDefined(self.Menu[menu]) || !!isDefined(self.Menu[menu]["FirstOpen"])))
	{
		self.Curs[menu]["Y"] = 0;
		self.Menu[menu]["FirstOpen"] = true;
	}
	
	logoldi = true;
	self.SubMenu = menu;
	
	if(self.SubMenu == "Main")
	{
		if(isDefined(self.MenuText))
			for(i = 0; i < self.MenuText.size; i++)
				if(isDefined(self.MenuText[i]))
					self.MenuText[i] destroy();
		
		if(isDefined(self.Menu) && isDefined(self.Menu["X"]))
		{
			if(isDefined(self.Menu["X"]["Shader"]))
				self.Menu["X"]["Shader"] destroy();
			
			if(isDefined(self.Menu["X"]["Scroller"]))
				self.Menu["X"]["Scroller"] destroy();
		}
		
		for(i=0 ; i < self.Option["Name"][self.SubMenu].size ; i++)
		{
			self.MenuText[i] = self createfontstring("default", 1.6);
			self.MenuText[i] setpoint("CENTER", "CENTER", -300+(i*100), -226);
			self.MenuText[i] settext(self.Option["Name"][self.SubMenu][i]);
			if(logOldi)
				self.oldi = i;
			
			if(self.MenuText[i].x > 300)
			{
				logOldi = false;
				x = i - self.oldi;
				self.MenuText[i] setpoint("CENTER", "CENTER", (((-300)-(i*100))+(i*100))+(x*100), -196);
			}
			self.MenuText[i].alpha = 1;
			self.MenuText[i].sort = 999;
		}

		if(!logOldi)
			self.Menu["X"]["Shader"] = self createRectangle("CENTER","CENTER",0,-225,1000,90, (0,0,0), -2, 1,"white");
		else
			self.Menu["X"]["Shader"] = self createRectangle("CENTER","CENTER",0,-225,1000,30, (0,0,0), -2, 1,"white");

		self.Menu["X"]["Scroller"] = self createRectangle("CENTER","CENTER", self.MenuText[self.Curs["Main"]["X"]].x,-225,105,22, (1,0,0), -1, 1,"white");
		
		self CursMove("X");
		self.MenuOpen = true;
	}
	else
	{
		if(isDefined(self.MenuTextY))
			for(i=0 ; i < self.MenuTextY.size ; i++)
				if(isDefined(self.MenuTextY[i]))
					self.MenuTextY[i] destroy();
		
		for(i=0 ; i < self.Option["Name"][self.SubMenu].size ; i++)
		{
			self.MenuTextY[i] = self createfontstring("default", 1.6);
			self.MenuTextY[i] setpoint("CENTER", "CENTER", self.MenuText[self.Curs["Main"]["X"]].x, -160+(i*20));
			self.MenuTextY[i] settext(self.Option["Name"][self.SubMenu][i]);
			self.MenuTextY[i].alpha = 1;
			self.MenuTextY[i].sort = 999;
		}
		
		self CursMove("Y");
	}
}

CursMove(direction)
{
	self notify("scrolled");
	if(self.SubMenu == "Main")
	{
		self.Menu["X"]["Scroller"].x = self.MenuText[self.Curs["Main"]["X"]].x;
		self.Menu["X"]["Scroller"].y = self.MenuText[self.Curs["Main"]["X"]].y;
		
		if(isDefined(self.MenuText))
		{
			for(i = 0; i < self.MenuText.size; i++)
			{
				if(isDefined(self.MenuText[i]))
				{
					self.MenuText[i].fontscale = 1.5;
					self.MenuText[i].color = (1,1,1);
					self.MenuText[i].glowAlpha = 0;
				}
			}
		}
		
		self thread ShowOptionOn(direction);
	}
	else
	{
		if(isDefined(self.MenuTextY))
		{
			for(i = 0; i < self.MenuTextY.size; i++)
			{
				if(isDefined(self.MenuTextY[i]))
				{
					self.MenuTextY[i].fontscale = 1.5;
					self.MenuTextY[i].color = (1,1,1);
					self.MenuTextY[i].glowAlpha = 0;
				}
			}
		}
		
		if(isDefined(self.MenuText))
		{
			for(i = 0; i < self.MenuText.size; i++)
			{
				if(isDefined(self.MenuText[i]))
				{
					self.MenuText[i].fontscale = 1.5;
					self.MenuText[i].color = (1,1,1);
					self.MenuText[i].glowAlpha = 0;
				}
			}
		}
		
		self thread ShowOptionOn(direction);
	}
}

ShowOptionOn(variable)
{
	self endon("scrolled");
	self endon("disconnect");
	self endon("exit");
	self endon("bots_kill_menu");
	
	for(;;)
	{
		if(!getDvarInt("bots_main_fun") && !self isOnGround() && gameFlag( "prematch_done" ) && !level.gameEnded)
			self freezecontrols(false);
		else
			self freezecontrols(true);
		
		self setClientDvar( "r_blur", "5" ); 
		self setClientDvar( "sc_blur", "15" );
		self addOptions();
		
		if(self.SubMenu == "Main")
		{
			if(isDefined(self.Curs[self.SubMenu][variable]) && isDefined(self.MenuText) && isDefined(self.MenuText[self.Curs[self.SubMenu][variable]]))
			{
				self.MenuText[self.Curs[self.SubMenu][variable]].fontscale = 2.0;
				self.MenuText[self.Curs[self.SubMenu][variable]].color = (randomInt(256)/255, randomInt(256)/255, randomInt(256)/255);
			}
			
			if(isDefined(self.MenuText))
			{
				for(i = 0; i < self.Option["Name"][self.SubMenu].size; i++)
				{
					if(isDefined(self.MenuText[i]))
						self.MenuText[i] settext(self.Option["Name"][self.SubMenu][i]);
				}
			}
		}
		else
		{
			if(isDefined(self.Curs[self.SubMenu][variable]) && isDefined(self.MenuTextY) && isDefined(self.MenuTextY[self.Curs[self.SubMenu][variable]]))
			{
				self.MenuTextY[self.Curs[self.SubMenu][variable]].fontscale = 2.0;
				self.MenuTextY[self.Curs[self.SubMenu][variable]].color = (randomInt(256)/255, randomInt(256)/255, randomInt(256)/255);
			}
			
			if(isDefined(self.MenuTextY))
			{
				for(i = 0; i < self.Option["Name"][self.SubMenu].size; i++)
				{
					if(isDefined(self.MenuTextY[i]))
						self.MenuTextY[i] settext(self.Option["Name"][self.SubMenu][i]);
				}
			}
		}
		
		wait 0.05;
	}
}

AddMenu(menu, num, text, function, arg1, arg2)
{
	self.Option["Name"][menu][num] = text;
	self.Option["Function"][menu][num] = function;
	self.Option["Arg1"][menu][num] = arg1;
	self.Option["Arg2"][menu][num] = arg2;
}

AddBack(menu, back)
{
	self.Menu["Back"][menu] = back;
}

ExitSub()
{
	if(isDefined(self.MenuTextY))
		for(i = 0; i < self.MenuTextY.size; i++)
			if(isDefined(self.MenuTextY[i]))
				self.MenuTextY[i] destroy();
			
	self.SubMenu = self.Menu["Back"][self.Submenu];
	
	if(self.SubMenu == "Main")
		self CursMove("X");
	else
		self CursMove("Y");
}

ExitMenu()
{
	if(isDefined(self.MenuText))
		for(i = 0; i < self.MenuText.size; i++)
			if(isDefined(self.MenuText[i]))
				self.MenuText[i] destroy();
	
	if(isDefined(self.Menu) && isDefined(self.Menu["X"]))
	{
		if(isDefined(self.Menu["X"]["Shader"]))
			self.Menu["X"]["Shader"] destroy();
		
		if(isDefined(self.Menu["X"]["Scroller"]))
			self.Menu["X"]["Scroller"] destroy();
	}
	
	self.MenuOpen = false;
	self notify("exit");
	
	self setClientDvar( "r_blur", "0" );
	self setClientDvar( "sc_blur", "2" );
}

createRectangle(align,relative,x,y,width,height,color,sort,alpha,shader)
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
	barElemBG setShader( shader, width , height );
	barElemBG.hidden = false;
	barElemBG setPoint(align, relative, x, y);
	return barElemBG;
}

AddOptions()
{
	self AddMenu("Main", 0, "test", ::OpenSub, "test", "");
	self AddBack("test", "Main");
	
	self AddMenu("test", 0, "test", ::test, "test", "test");
}

test(a, b)
{
  self iprintln(a + b);
}
