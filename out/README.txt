# IW4x Bot Warfare v2.3.0
Bot Warfare is a GSC mod for the IW4x project.

It aims to add playable AI to the multiplayer games of Modern Warfare 2.

You can find the GitHub containing more info at https://github.com/ineedbots/iw4x_bot_warfare

## Installation
0. Make sure that IW4x is installed, updated and working properly. (IW4x v0.7.9+)
1. Locate your IW4x install folder.
2. Move the files/folders found in 'Move files to root of IW4x folder' from the Bot Warfare release archive you downloaded into the root of your IW4x install folder.
    - The folder/file structure should follow as '.IW4x game folder\mods\bots\z_svr_bots.iwd'.
4. The mod is now installed, now run your game.
    - If you are a dedicated server, you will need to set the DVAR 'fs_game' to 'mods/bots'
    - If you are not a dedicated server, open the 'Mods' option from the main menu of the game and select 'bots' and then 'Launch'.
5. The mod should be loaded! Now go start a map and play!

## Menu Usage
- You can open the menu by pressing the Action Slot 2 key (default '5').

- You can navigate the options by pressing your movement keys (default WASD), and you can select options by pressing your jump key (default SPACE).

- Pressing the menu button again closes menus.

- TODOs
  - A variable leak in _menu (script)
  - Recoil for bots (engine, maybe script)
  - Use proper activate button for bombs, carepackages, etc (script, use +activate)
  - Proper weapon swaps, including altmode (engine, then script)
  - Use static turrets in maps (script)
  - Proper use of pred missile (script and engine)

## Credits
- IW4x Team - https://github.com/XLabsProject/iw4x-client
- CoD4x Team - https://github.com/callofduty4x/CoD4x_Server
- INeedGames(me) - http://www.moddb.com/mods/bot-warfare
- tinkie101 - https://web.archive.org/web/20120326060712/http://alteriw.net/viewtopic.php?f=72&t=4869
- PeZBot team - http://www.moddb.com/mods/pezbot
- apdonato - http://rsebots.blogspot.ca/
- Ability
- Salvation
- VicRattlehead - https://www.moddb.com/members/vicrattlehead

Feel free to use code, host on other sites, host on servers, mod it and merge mods with it, just give credit where credit is due!
	-INeedGames/INeedBot(s) @ ineedbots@outlook.com
