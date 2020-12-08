![GitHub Logo](/userraw/bw-assets/bw-logo.png)

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
- A clean and nice menu, you can edit every bot DVAR within in-game.

- Everything can be customized, ideal for both personal use and dedicated servers. Have a look at [Documentation](#Documentation) to see whats possible!

- This mod does not edit ANY stock .gsc files, meaning EVERY other mod is compatible with this mod. Mod doesn't add anything unnecessary, what you see is what you get.

- Adds AI clients to multiplayer games to simulate playing real players. (essentially Combat Training for MW2)
  - Bots move around the maps with native engine input. (all normal maps, most to all custom maps)
  - Bots press all the buttons with native engine input (ads, sprint, jump, etc)
  - Bots play all gamemodes/objectives, they caputure flags, plant, defuse bombs, etc. ( all normal modes, most custom modes)
  - Bots use all killstreaks. Including AC130 and chopper gunner.
  - Bots target killstreaks, use stingers and other weapons to take out all killstreaks. ( even sentry guns)
  - Bots can capture and steal care packages.
  - Bots target equipment, and can even camp TIs.
  - Bots can camp randomly or when about to use the laptop.
  - Bots can follow others on own will.
  - Bots have smooth and realistic aim.
  - Bots respond smartly to their surroundings, they will go to you if you shoot, uav, etc.
  - Bots use all deathstreaks, perks and weapons, also perks do something and bots use g uns tactically (use shotgun upclose, etc).
  - Bots difficulty level can be customized and are accurate. (hard is hard, easy is easy, e tc.)
  - Bots each all have different classes, traits, and difficulty and remember it all.
  - Bots switch from between primaries and secondaries.
  - Bots can grenade, place claymores and TIs, they even use grenades and tubes in preset m ap locations.
  - Bots use grenade launchers and shotgun attachments.
  - Bots can melee people and sentry guns.
  - Bots can run!
  - Bots can climb ladders!
  - Bots detect smoke grenades, stun grenades, flashed and airstrike slows.
  - Bots will remember their class, killstreak, skill and traits, even on multiround based gametypes.
  - Bots can throwback grenades.
  - ... And pretty much everything you expect a Combat Training bot to have

## Installation
0. Make sure that [IW4x](https://xlabs.dev/support_iw4x_client.html) is installed, updated and working properly.
    - Download the [latest release](https://github.com/ineedbots/iw4x_bot_warfare/releases) of Bot Warfare.
1. Locate your IW4x install folder.
2. Find and open the 'mods' folder. (if none, create one)
3. Move the files/folders found in 'Move to mods folder' to the 'mods' folder.
    - The folder/file structure should follow as '.MW2 game folder\mods\bots\z_svr_bots.iwd'.

## Documentation

### DVARs
- bots_manage_add - an integer amount of bots to add to the game, resets to 0 once the bots have been added.
    - for example: 'bots_manage_add 10' will add 10 bots to the game.

- bots_manage_fill - an integer amount of players/bots (depends on bots_manage_fill_mode) to retain on the server, it will automatically add bots to fill player space.
    - for example: 'bots_manage_fill 10' will have the server retain 10 players in the server, if there are less than 10, it will add bots until that value is reached.

- bots_manage_fill_mode - a value to indicate if the server should consider only bots or players and bots when filling player space.
    - 0 will consider both players and bots.
    - 1 will only consider bots.

- bots_manage_fill_kick - a boolean value (0 or 1), whether or not if the server should kick bots if the amount of players/bots (depends on bots_manage_fill_mode) exceeds the value of bots_manage_fill.

- bots_manage_fill_spec - a boolean value (0 or 1), whether or not if the server should consider players who are on the spectator team when filling player space.

---

- bots_team - a string, the value indicates what team the bots should join:
    - 'autoassign' will have bots balance the teams
    - 'allies' will have the bots join the allies team
    - 'axis' will have the bots join the axis team
    - 'custom' will have bots_team_amount bots on the axis team, the rest will be on the allies team
    
- bots_team_amount - an integer amount of bots to have on the axis team if bots_team is set to 'custom', the rest of the bots will be placed on the allies team.
    - for example: there are 5 bots on the server and 'bots_team_amount 3', then 3 bots will be placed on the axis team, the other 2 will be placed on the allies team.

- bots_team_force - a boolean value (0 or 1), whether or not if the server should enforce periodically the bot's team instead of just a single team when the bot is added to the game.
    - for example: 'bots_team_force 1' and 'bots_team autoassign' and the teams become to far unbalanced, then the server will change a bot's team to make it balanced again.

- bots_team_mode - a value to indicate if the server should consider only bots or players and bots when counting players on the teams.
    - 0 will consider both players and bots.
    - 1 will only consider bots.

---

- bots_skill - value to indicate how difficult the bots should be.
    - 0 will be mixed difficultly
    - 1 will be the most easy
    - 2-6 will be in between most easy and most hard
    - 7 will be the most hard.
    - 8 will be custom.

- bots_skill_axis_hard - an integer amount of hard bots on the axis team.
- bots_skill_axis_med - an integer amount of medium bots on the axis team.
- bots_skill_allies_hard - an integer amount of hard bots on the allies team.
- bots_skill_allies_med - an integer amount of medium bots on the allies team
    - if bots_skill is 8 (custom). The remaining bots on the team will become easy bots
    - for example: having 5 bots on the allies team, 'bots_skill_allies_hard 2' and 'bots_skill_allies_med 2' will have 2 hard bots, 2 medium bots, and 1 easy bot on the allies team.

---

- bots_loadout_reasonable - a boolean value (0 or 1), whether or not if the bots should filter out bad create a class selections (like no miniuzi bling with acog rapidfire and hardline for example)

- bots_loadout_allow_op - a boolean value (0 or 1), whether or not if the bots are allowed to use deathstreaks, noobtubes, rpg, laststand, etc.

## Changelog
- v2.0.0
  - Initial reboot release

## Credits
- IW4x Team - https://github.com/XLabsProject/iw4x-client
- CoD4x Team - https://github.com/callofduty4x/CoD4x_Server
- INeedGames(me) - http://www.moddb.com/mods/bot-warfare
- tinkie101 - https://web.archive.org/web/20120326060712/http://alteriw.net/viewtopic.php?f=72&t=4869
- PeZBot team - http://www.moddb.com/mods/pezbot
- apdonato - http://rsebots.blogspot.ca/
- Ability
- Salvation

Feel free to use code, host on other sites, host on servers, mod it and merge mods with it, just give credit where credit is due!
	-INeedGames/INeedBot(s) @ ineedbots@outlook.com
