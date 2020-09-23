#include common_scripts\utility;
#include maps\mp\_utility;
#include maps\mp\gametypes\_hud_util;

init()
{
	setDvarIfUninitialized( "scr_allowFPSBooster", false );
	level.allowFPSBooster = getDvarInt("scr_allowFPSBooster");

	level thread onPlayerConnect();
}

onPlayerConnect()
{
	for(;;)
	{
		level waittill( "connected", player);
		player thread onPlayerGiveloadout();
	}
}

onPlayerGiveloadout()
{
	self endon("disconnect");

	self.pers["fpsBooster"] = false;
	_onetime = false;
	for(;;)
	{
		self waittill("giveLoadout");

		if(!_onetime && level.allowFPSBooster)
		{
			self iPrintlnBold("^7Press ^3[{+actionslot 1}] ^7to toggle ^3FPS Booster");
			_onetime = true;
		}
		self thread FPSBooster();
	}
}

FPSBooster()
{
	self endon( "disconnect" );
	self endon( "giveLoadout" );
	self endon( "death" );
	
	self notifyOnPlayerCommand( "toggle_fullbright", "+actionslot 1" );
	self _SetActionSlot( 1, "" );
	for(;;)
	{
		self waittill( "toggle_fullbright" );
		if( level.allowFPSBooster )
		{
			self playLocalSound( "claymore_activated" );
			if(self.pers["fpsBooster"])
			{
				self SetClientDvar("r_fullbright", 0);
				self SetClientDvar("r_fog", 1);
				self SetClientDvar("r_detailMap", 1);
				self iPrintlnBold("^7FPS Booster ^1Disabled");
				self.pers["fpsBooster"] = false;
			}
			else
			{
				self SetClientDvar("r_fullbright", 1);
				self SetClientDvar("r_fog", 0);
				self SetClientDvar("r_detailMap", 0);
				self iPrintlnBold("^7FPS Booster ^1Enabled");
				self.pers["fpsBooster"] = true;
			}
		}
	}
}