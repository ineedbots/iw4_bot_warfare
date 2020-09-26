#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	setDvarIfUninitialized( "scr_showHP", false );
	level.showHP = getDvarInt("scr_showHP");

	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player);
		player thread onPlayerSpawned();
	}
}

onPlayerSpawned()
{
   self endon("disconnect");
   for(;;)
   {
      self waittill("spawned_player");

	  	if(level.showHP)
				self thread drawHP();
   }
}

destoryHPdraw()
{
	self waittill_either("disconnect", "death");
	self.drawHP destroy();
}

initHPdraw()
{
	self.drawHP = self createFontString("default", 1.2);
	self.drawHP setPoint("BOTTOMRIGHT", "BOTTOMRIGHT", -150, -20);
	self thread destoryHPdraw();
}

drawHP()
{
	self endon( "disconnect" );
	self endon( "death" );
	self initHPdraw();
	for(;;)
	{
		//self.drawHP setText("HP: "+self.health+"  KS: "+self.pers["cur_kill_streak"]);
		self.drawHP setText(self.health);
		wait 0.05;
	}
}