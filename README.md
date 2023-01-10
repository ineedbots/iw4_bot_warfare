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
- [Contact](#Contact)

## Features
- A Waypoint Editor for creating and modifying bot's waypoints of traversing the map. Have a look at [Using the Waypoint editor](/userraw/bw-assets/wpedit.md).

- A clean and nice menu, you can edit every bot DVAR within in-game.

- Everything can be customized, ideal for both personal use and dedicated servers. Have a look at [Documentation](#Documentation) to see whats possible!

- This mod does not edit ANY stock .gsc files, meaning EVERY other mod is compatible with this mod. Mod doesn't add anything unnecessary, what you see is what you get.

- Loading waypoints from CSV files, and if the CSV file is missing, will download the CSV from [this repo](https://github.com/ineedbots/iw4x_waypoints) automatically.

- Adds AI clients to multiplayer games to simulate playing real players. (essentially Combat Training for MW2)
  - Bots move around the maps with native engine input. (all normal maps, most to all custom maps)
  - Bots press all the buttons with native engine input (ads, sprint, jump, etc)
  - Bots play all gamemodes/objectives, they capture flags, plant, defuse bombs, etc. ( all normal modes, most custom modes)
  - Bots use all killstreaks. Including AC130 and chopper gunner.
  - Bots target killstreaks, use stingers and other weapons to take out all killstreaks. ( even sentry guns)
  - Bots can capture and steal care packages.
  - Bots target equipment, and can even camp TIs.
  - Bots can camp randomly or when about to use the laptop.
  - Bots can follow others on own will.
  - Bots have smooth and realistic aim.
  - Bots respond smartly to their surroundings, they will go to you if you shoot, uav, etc.
  - Bots use all deathstreaks, perks and weapons. (including javelin)
  - Bots difficulty level can be customized and are accurate. (hard is hard, easy is easy, etc.)
  - Bots each all have different classes, traits, and difficulty and remember it all.
  - Bots switch from between primaries and secondaries.
  - Bots can grenade, place claymores and TIs, they even use grenades and tubes in preset map locations.
  - Bots use grenade launchers and shotgun attachments.
  - Bots can melee people and sentry guns.
  - Bots can run!
  - Bots can climb ladders!
  - Bots jump shot and drop shot.
  - Bots detect smoke grenades, stun grenades, flashed and airstrike slows.
  - Bots will remember their class, killstreak, skill and traits, even on multiround based gametypes.
  - Bots can throwback grenades.
  - ... And pretty much everything you expect a Combat Training bot to have

## Installation
0. Make sure that [IW4x](https://xlabs.dev/support_iw4x_client.html) is installed, updated and working properly. (IW4x v0.6.1+)
    - Download the [latest release](https://github.com/XLabsProject/iw4x_bot_warfare/releases) of Bot Warfare.
1. Locate your IW4x install folder.
2. Move the files/folders found in 'Move files to root of IW4x folder' from the Bot Warfare release archive you downloaded into the root of your IW4x install folder.
    - The folder/file structure should follow as '.IW4x game folder\mods\bots\z_svr_bots.iwd'.
3. The mod is now installed, now run your game.
    - If you are a dedicated server, you will need to set the DVAR 'fs_game' to 'mods/bots'
    - If you are not a dedicated server, open the 'Mods' option from the main menu of the game and select 'bots' and then 'Launch'.
4. The mod should be loaded! Now go start a map and play!

## Documentation

### Menu Usage
- You can open the menu by pressing the Action Slot 2 key (default '5').

- You can navigate the options by pressing your movement keys (default WASD), and you can select options by pressing your jump key (default SPACE).

- Pressing the menu button again closes menus.

### DVARs
| Dvar                             | Description                                                                                 | Default Value |
|----------------------------------|---------------------------------------------------------------------------------------------|--------------:|
| bots_main                        | Enable this mod.                                                                            | true          |
| bots_main_firstIsHost            | The first player to connect will be given host.                                             | false         |
| bots_main_GUIDs                  | A comma separated list of GUIDs of players who will be given host.                          | ""            |
| bots_main_waitForHostTime        | How many seconds to wait for the host player to connect before adding bots to the match.    | 10            |
| bots_main_menu                   | Enable the in-game menu for hosts.                                                          | true          |
| bots_main_debug                  | Enable the in-game waypoint editor.                                                         | false         |
| bots_main_kickBotsAtEnd          | Kick the bots at the end of a match.                                                        | false         |
| bots_main_chat                   | The rate bots will chat at, set to 0 to disable.                                            | 1.0           |
| bots_manage_add                  | Amount of bots to add to the game, once bots are added, resets back to `0`.                 | 0             |
| bots_manage_fill                 | Amount of players/bots (look at `bots_manage_fill_mode`) to maintain in the match.          | 0             |
| bots_manage_fill_mode            | `bots_manage_fill` players/bots counting method.<ul><li>`0` - counts both players and bots.</li><li>`1` - only counts bots.</li></ul> | 0 |
| bots_manage_fill_kick            | If the amount of players/bots in the match exceeds `bots_manage_fill`, kick bots until no longer exceeds. | false |
| bots_manage_fill_spec            | If when counting players for `bots_manage_fill` should include spectators.                  | true          |
| bots_team                        | One of `autoassign`, `allies`, `axis`, `spectator`, or `custom`. What team the bots should be on. | autoassign |
| bots_team_amount                 | When `bots_team` is set to `custom`. The amount of bots to be placed on the axis team. The remainder will be placed on the allies team. | 0 |
| bots_team_force                  | If the server should force bots' teams according to the `bots_team` value. When `bots_team` is `autoassign`, unbalanced teams will be balanced. This dvar is ignored when `bots_team` is `custom`. | false |
| bots_team_mode                   | When `bots_team_force` is `true` and `bots_team` is `autoassign`, players/bots counting method. <ul><li>`0` - counts both players and bots.</li><li>`1` - only counts bots</li></ul> | 0 |
| bots_skill                       | Bots' difficulty.<ul><li>`0` - Random difficulty for each bot.</li><li>`1` - Easiest difficulty for all bots.</li><li>`2` to `6` - Between easy and hard difficulty for all bots.</li><li>`7` - The hardest difficulty for all bots.</li><li>`8` - custom (look at the `bots_skill_<team>_<difficulty>` dvars</li></ul> | 0 |
| bots_skill_axis_hard             | When `bots_skill` is set to `8`, the amount of hard difficulty bots to set on the axis team. | 0            |
| bots_skill_axis_med              | When `bots_skill` is set to `8`, the amount of medium difficulty bots to set on the axis team. The remaining bots on the team will be set to easy difficulty. | 0 |
| bots_skill_allies_hard           | When `bots_skill` is set to `8`, the amount of hard difficulty bots to set on the allies team. | 0          |
| bots_skill_allies_med            | When `bots_skill` is set to `8`, the amount of medium difficulty bots to set on the allies team. The remaining bots on the team will be set to easy difficulty. | 0 |
| bots_skill_min                   | The minimum difficulty level for the bots.                                                     | 1          |
| bots_skill_max                   | The maximum difficulty level for the bots.                                                     | 7          |
| bots_loadout_reasonable          | If the bots should filter bad performing create-a-class selections.                            | false      |
| bots_loadout_allow_op            | If the bots should be able to use overpowered and annoying create-a-class selections.          | true       |
| bots_loadout_rank                | What rank to set the bots.<ul><li>`-1` - Average of all players in the match.</li><li>`0` - All random.</li><li>`1` or higher - Sets the bots' rank to this.</li></ul> | -1 |
| bots_loadout_prestige            | What prestige to set the bots.<ul><li>`-1` - Same as host player in the match.</li><li>`-2` - All random.</li><li>`0` or higher - Sets the bots' prestige to this.</li></ul> | -1 |
| bots_play_move                   | If the bots can move.                                                                          | true       |
| bots_play_knife                  | If the bots can knife.                                                                         | true       |
| bots_play_fire                   | If the bots can fire.                                                                          | true       |
| bots_play_nade                   | If the bots can grenade.                                                                       | true       |
| bots_play_take_carepackages      | If the bots can take carepackages.                                                             | true       |
| bots_play_obj                    | If the bots can play the objective.                                                            | true       |
| bots_play_camp                   | If the bots can camp.                                                                          | true       |
| bots_play_jumpdrop               | If the bots can jump/drop shot.                                                                | true       |
| bots_play_target_other           | If the bots can target other entities other than players.                                      | true       |
| bots_play_killstreak             | If the bots can call in killstreaks.                                                           | true       |
| bots_play_ads                    | If the bots can aim down sights.                                                               | true       |
| bots_play_aim                    | If the bots can aim.                                                                           | true       |

## Changelog
- v2.1.0
  - Bot chatter system, bots_main_chat
  - Greatly reduce script variable usage
  - Fix bots slowly reacting in remote streaks
  - Improved bots mantling and stuck
  - Improved bots aim
  - Fix some runtime errors
  - Fixed bots aim in third person
  - Bots sprint more
  - Improved bots sight on enemies
  - Bots play hidden gamemodes like one-flag and arena
  - Bots do random actions while waiting at an objective
  - Improved bots from getting stuck
  - Better bot difficulty management, bots_skill_min and bots_skill_max

- v2.0.1
  - Reduced bots crouching
  - Increased bots sprinting
  - Improved bots mantling, crouching and knifing glass when needed
  - Fixed possible script runtime errors
  - Fixed demolition spawn killing
  - Improved domination
  - Bots use explosives more if they have it
  - Fixed bots moving their player when using remote
  - Bots aim slower when ads'ing
  - Fixed bots holding breath
  - Bots are more smart when waiting for carepackages
  - Improved and fixed various waypoints for maps
  - Fixed bots rubberbanding movement when their goal changes
  - Added bots quickscoping with snipers
  - Added bots reload canceling and fast swaps
  - Bots use C4
  - Improved revenge
  - Bots can swap weapons on spawn more likely

- v2.0.0
  - Initial reboot release


- TODOs
  - A variable leak in _menu (script)
  - Recoil for bots (engine, maybe script)
  - Use proper activate button for bombs, carepackages, etc (script, use +activate)
  - Proper weapon swaps, including altmode (engine, then script)
  - Use static turrets in maps (script)
  - Proper use of pred missile (script and engine)
  - Fix testclient view angle clamping (messes with ac130 and chopper gunner) (engine)

## Credits
- IW4x Team - https://github.com/XLabsProject/iw4x-client
- CoD4x Team - https://github.com/callofduty4x/CoD4x_Server
- INeedGames (Original Creator) - http://www.moddb.com/mods/bot-warfare
- tinkie101 - https://web.archive.org/web/20120326060712/http://alteriw.net/viewtopic.php?f=72&t=4869
- PeZBot team - http://www.moddb.com/mods/pezbot
- apdonato - http://rsebots.blogspot.ca/
- Ability
- Salvation
- VicRattlehead - https://www.moddb.com/members/vicrattlehead

Feel free to use code, host on other sites, host on servers, mod it and merge mods with it, just give credit where credit is due!
	-INeedGames/INeedBot(s) @ ineedbots@outlook.com

## Contact
If you need help using this version of bot warfare that is *not* developed by INeedGames, please do *not* attempt to contact him for support queries.

You may find help here: https://discord.gg/sKeVmR3
