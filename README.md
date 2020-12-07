# IW4x Bot Warfare
Bot Warfare is a GSC mod for the [IW4x project](https://github.com/XLabsProject/iw4x-client).

It aims to add playable AI to the multiplayer games of Modern Warfare 2.

You can find the ModDB release post [here](https://www.moddb.com/mods/bot-warfare/downloads/iw4x-bot-warfare-latest).

## Contents
- [Features](#Features)
- [Installation](#Installation)
- [Documentation](#Documentation)
- [Changelog](#Changelog)
- [Credits](#Credits)

## Features
Mod is completely compatible with no internet, good for LAN with friends or just playing alone. (only if your client supports offline/lan)

Also mod is compatible with every game client, as long as the client's testclient handling works properly.

A clean and nice menu, you can edit every bot DVAR within in-game.

Everything can be customized, ideal for both personal use and dedicated servers. Have a look at '3: Documentation' to see whats possible!

This mod does not edit ANY stock .gsc files, meaning EVERY other mod is compatible with this mod. Mod doesn't add anything unnecessary, what you see is what you get.

Adds AI clients to multiplayer games to simulate playing real players. (essentially Combat Training for MW2)
	-Bots move around the maps. (all normal maps, most to all custom maps)
	-Bots play all gamemodes/objectives, they caputure flags, plant, defuse bombs, etc. (all normal modes, most custom modes)
	-Bots have animations, move their legs and don't slide.
	-Bots use all killstreaks. Including AC130 and chopper gunner.
	-Bots target killstreaks, use stingers and other weapons to take out all killstreaks. (even sentry guns)
	-Bots can capture and steal care packages.
	-Bots target equipment, and can even camp TIs.
	-Bots can camp randomly or when about to use the laptop.
	-Bots can follow others on own will.
	-Bots have smooth and realistic aim.
	-Bots respond smartly to their surroundings, they will go to you if you shoot, uav, etc.
	-Bots use all deathstreaks, perks and weapons, also perks do something and bots use guns tactically (use shotgun upclose, etc).
	-Bots difficulty level can be customized and are accurate. (hard is hard, easy is easy, etc.)
	-Bots each all have different classes, traits, and difficulty and remember it all.
	-Bots switch from between primaries and secondaries.
	-Bots can grenade, place claymores and TIs, they even use grenades and tubes in preset map locations.
	-Bots use grenade launchers and shotgun attachments.
	-Bots trip claymores indefinitely.
	-Bots can melee people and sentry guns.
	-Bots can run!
	-Bots can climb ladders!
	-Bots have foot sounds!!
	-Bots detect smoke grenades, stun grenades, flashed and airstrike slows.
	-Bots can watch killcams.
	-Bots talk, react to anything that they are doing or what happened to them, etc.
	-Bots will remember their class, killstreak, skill and traits, even on multiround based gametypes.
	-Bots can rage quit.
	-Bots can throwback grenades.

## Installation
Installation for PC (requires you to have a client/server that can load mods):
1. Locate your MW2 game folder.
2. Find and open the 'mods' folder. (if none, create one)
3. Move the files/folders found in 'Move to mods folder' to the 'mods' folder.
4. The folder/file structure should follow as '.MW2 game folder\mods\bots\z_svr_bots.iwd'.
5. Run your game/server. If you are not using a dedicated server, go to private match.
6. You must set the 'fs_game' dvar to 'mods/bots' before you load the map. Use the console (use ~ or alt-tab) to change dvars.
7. Once in-game, press your actionSlot2 (secondary inv) button, default '5', to open the menu. Use the movement keys to navigate the menu, use the jump button to select menus and options and press the menu button to close options and menus, or use the console to change the bot dvars found at 3: Documentation.
8. If the mod didn't load, try inserting the 'z_svr_bots_loadM1.iwd' with the 'z_svr_bots.iwd' file in the same folder and reload the map.
Enjoy!

## Documentation
DVAR list:
bots_manage_add (0 to maxClients) - amount of bots to add to the game, resets to 0 once bots are added
bots_manage_fill (0 to maxClients) - amount of bots to have server maintain
bots_manage_fill_mode (0 to 4) - determines whether or not the bot_fill takes bots or everyone into account and if it autoadjusts amount of bots to map, or use bots as balance
bots_manage_fill_kick (0 to 1) - allows to kick bots if bot_fill is exceeded
bots_manage_fill_spec (0 to 1) - if to count players who are on the spec team
bots_manage_reset (0 to 1) - used for resetting bots, resets to 0 once bots are resetted

bots_team ("autoassign", "axis", "allies", "custom") - determines what team to have bots join
bots_team_amount (0 to teamLimit) - when bot_team is on custom, how many bots to have on axis team, rest is sent to allies team
bots_team_force (0 to 1) - when bot_team isn't on custom, forces bots to the team
bots_team_mode (0 to 1) - determines whether or not the bot_team takes bots or everyone into account
	
bots_skill (0 to 9) - determines bots difficulty, 0 is random for all, 1 to 7 is easy to hard, 8 is custom and 9 is completely random
bots_skill_axis_hard (0 to teamLimit) - when bot_skill is on 8, how many hard bots on axis team
bots_skill_axis_med (0 to teamLimit) - when bot_skill is on 8, how many medium bots on axis team, remaining bots are set to easy
bots_skill_allies_hard (0 to teamLimit) - when bot_skill is on 8, how many hard bots on allies team
bots_skill_allies_med (0 to teamLimit) - when bot_skill is on 8, how many medium bots on allies team, remaining bots are set to easy
	
bots_play_talk (0 to 50)(float) - bot talk scaler, 0 to turn off bot talk
bots_play_watchKillcam (0 to 2) - toggle of bots chance of watching killcams, 0 is off, 2 is always
bots_play_rageQuit (0 to 1) - toggle of bots chance of quitting the game, 0 is off
bots_play_camp (0 to 1) - toggle of bots camping, 0 is off
bots_play_obj (0 to 1) - toggle of bots playing the obj, 0 is off
bots_play_run (0 to 1) - toggle of bots running, 0 is off
bots_play_tdks (0 to 1) - toggle of bots taking down killstreaks, 0 is off
bots_play_takeCare (0 to 1) - toggle of bots taking carepackages, 0 is off
bots_play_outOfMyWay (0 to 1) - toggle of bots moving of the way, 0 is off
bots_play_attack (0 to 1) - toggle of bots attacking, 0 is off
bots_play_move (0 to 1) - toggle of bots moving, 0 is off
bots_play_doStuck (0 to 1) - toggle of the antiStuck thread, 0 is off
bots_play_destroyEq (0 to 1) - toggle of bots targeting equipment, 0 is off
bots_play_fakeAnims (0 to 1) - toggle of bots using fake animations to simulate walking, 0 is off, 2 is alternative
bots_play_throwback (0 to 1) - toggle of bots throwing back frags, 0 is off
bots_play_footsounds (0 to 1) - toggle of bots emulating foot sounds, 0 if off

bots_loadout ("default", "random", "mod", "none", "snipe", "knife", "tube", "level") - is bot's class setup mode
bots_loadout_deathstreak (0 to 1) - toggle of bots using deathstreaks, 0 is off
bots_loadout_secondary (0 to 1) - toggle of bots using secondaries, 0 is off
bots_loadout_nuke (0 to 1) - toggle of bots using nukes, 0 is off
bots_loadout_riot (0 to 1) - toggle of bots using riot shields, 0 is off
bots_loadout_lastStand (0 to 1) - toggle of bots using the laststand perk, 0 is off
bots_loadout_killstreak ("default", "random", "none", "level") - is bot's killstreak mode
bots_loadout_tube (0 to 1) - toggle of bots using explosives, 0 is off
bots_loadout_shotgun (0 to 1) - toggle of bots using shotguns, 0 is off
bots_loadout_sniper (0 to 1) - toggle of bots using snipers, 0 is off
bots_loadout_knife (0 to 1) - toggle of bots using knifes, 0 is off
bots_loadout_nade (0 to 1) - toggle of bots using grenades, 0 is off
bots_loadout_remember (0 to 1) - toggle of remember their class setup, 0 is off
bots_loadout_change (0 to 1) - toggle of bots chance of forgetting their class setup, 0 is off
bots_loadout_akimbo (0 to 1) - toggle of bots using akimbo weapons

bots_main (0 to 1) - toggle of the entire bot mod
bots_main_debug (0 to 1) - toggle of dev mode for bots
bots_main_menu (0 to 1) - toggle of menu, 0 is off
bots_main_Names (player exact name or "") - extra check to see host for menu operation, seperate with ',' for multiple names, set to "" to disable
bots_main_GUIDs (player GUIDs or "") - list of 'host' GUIDs used for opening the menu, use a ',' to seperate multiple GUIDs, set to "" to disable
bots_main_target (isSubStr of player name or "") - bots will always target this player's name, set as "" to disable (good for antiCheat or just for fun)	
bots_main_prestige (-2 to 11) - -1 for random, -2 same as host, set all bot's prestige
bots_main_experience (-2 to 2516000) - -1 for random, -2 for around host, set all bot's experience level
bots_main_title (title string or "") - "" for random, set all bot's title
bots_main_emblem (emblem string or "") - "" for random, set all bot's emblem
bots_main_target_host (0 to 1) - when 0, bots will not target host players
bots_main_fun (0 to 1) - toggle use of fun options in menu

## Changelog
- v2.0.0
  - Initial reboot release

## Credits
- IW4x Team
- CoD4x Team
- INeedGames(me) - for completely writing and compiling the mod into what it is now: http://www.moddb.com/mods/bot-warfare
- tinkie101 - for RSE v1 to v10, mod was based off of this: https://web.archive.org/web/20120326060712/http://alteriw.net/viewtopic.php?f=72&t=4869
- PeZBot team - tinkie101 used PeZBot's code as a base for RSE v1 to v10: http://www.moddb.com/mods/pezbot
- apdonato - for RSE v11+ development, much of their ideas was used: http://rsebots.blogspot.ca/
- Ability - for their waypoint mod used in this mod (found in bots\dev.gsc)
- Salvation - for their menu base used in this mod (found in bots\menu.gsc)

Feel free to use code, host on other sites, host on servers, mod it and merge mods with it, just give credit where credit is due!
	-INeedGames/INeedBot(s) @ ineedbots@outlook.com
