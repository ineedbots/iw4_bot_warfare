# IW4x Bot Warfare Waypoint Editor
First things first, Bot Warfare uses the [AStar search algorithm](https://en.wikipedia.org/wiki/A*_search_algorithm) for creating paths for the bots to find their way through a map. 

The AStar search algorithm requires a [set of waypoints](https://en.wikipedia.org/wiki/Graph_(discrete_mathematics)) defining where all the paths are in the map.

Now if you want to modify existing or create new waypoints for IW4x maps, this is the read for you.

## Contents
- [Setting up the Waypoint Editor](#Setting-up-the-Waypoint-Editor)
- [The Editor](#The-Editor)

## Setting up the Waypoint Editor
The Bot Warfare mod comes with the Waypoint Editor out of the box, so its just a matter of telling the mod you want to use it. Its a matter of setting the 'bots_main_debug' DVAR to '1'.

Start your game, and load up the Bot Warfare mod. Now open your console with tilde(~).
![How tilde](/userraw/bw-assets/how-tilde.png)

In the console, type in ```set bots_main_debug 1```
![Setting the dvar](/userraw/bw-assets/wp-editor-debug-dvar.png)

Now start a match with the map you want to edit.

It should be noted that waypoints load in this following order;
1. check the 'waypoints' folder (FS_Game\waypoints) for a csv file
2. load the waypoints from GSC (maps\mp\bots\waypoints)
3. check online at [this repo](https://github.com/ineedbots/iw4x_waypoints) for the waypoints (if dedicated server, or -scriptablehttp flag)

If all fail to load waypoints, then the bots will not know how to navigate the map.

## The Editor
![The editor](/userraw/bw-assets/wp-editor-0.png)
This is the Waypoint Editor. You can view, edit and create the waypoint graph.
- Each number you see in the world is a waypoint.
- The pink lines show the links between the waypoints, a link defines that a bot can walk from A to B.
- The white lines show the 'angles' that a waypoint has, these are used for grenade, claymore and tube waypoints. It's used to tell the bot where to look at when grenading/claymoring, etc.
- The black lines show the Javelin's lockon location.
- The top left shows information about the nearest waypoint.

---

Pressing any of these buttons will initiate a command to the Waypoint Editor.

- SecondaryOffhand (stun) - Add Waypoint
  - No modifier button - Make a waypoint of your stance
  - ADS, climbing or mounting - Make a climb waypoint
  - Attack + Use - Make a noobtube waypoint
  - Attack - Make a grenade waypoint
  - Use - Make a claymore waypoint
  - Marking a location with the Javelin - Make a Javelin waypoint

- Melee - Link waypoint

- Reload - Unlink waypoint

- PrimaryOffhand (frag) - Toggle autolink waypoints (links waypoints as you create them)

- ActionSlot3 (switch to alt weapon mode (noobtube)) - Delete Waypoint

- ActionSlot4 (killstreak activate) - Delete all waypoints

- ActionSlot1 (Nightvision) - Save Waypoints

- ActionSlot2 - (Re)Load Waypoints

- Use - Display the nearest waypoint's list of linked waypoints.

---

Okay, now that you know how to control the Editor, lets now goahead and create some waypoints.

Here I added a waypoint.
![Adding a waypoint](/userraw/bw-assets/wp-editor-added.png)

And I added a second waypoint.
![Adding another waypoint](/userraw/bw-assets/wp-editor-added2.png)

There are several types of waypoints, holding a modifier button before pressing the add waypoint button will create a special type of waypoint.
- Types of waypoints:
  - any stance ('stand', 'crouch', 'prone') - bots will have this stance upon reaching this waypoint
  - grenade - bots will look at the angles you were looking at when you made the waypoint and throw a grenade from the waypoint
  - tube - bots will look at the angles you were looking at when you made the waypoint and switch to a launcher and fire
  - claymore - bots will look at the angles you were looking at when you made the waypoint and place a claymore or tactical insertion
  - camp ('crouch' waypoint with only one linked waypoint) - bots will look at the angles you were looking at when you made the waypoint and camp
  - climb - bots will look at the angles you were looking at when you made the waypoint and climb (use this for ladders and mantles)
  - javelin - bots will use the javelin and lockon at the target location

Here I linked the two waypoints together.
![Linking waypoints](/userraw/bw-assets/wp-editor-linked.png)

Linking waypoints are very important, it tells the bots that they can reach waypoint 1 from waypoint 0, and vice versa.

Now go and waypoint the whole map out. This may take awhile and can be pretty tedious.

Once you feel like you are done, press the Save button. This will generate a [CSV](https://en.wikipedia.org/wiki/Comma-separated_values) output to your waypoints folder!

That is it! The waypoints should load next time you start your game!

Your waypoints CSV file will be located at ```FS_Game/waypoints/<mapname>_wp.csv```. (userraw folder if fs_game is blank)
![Location](/userraw/bw-assets/wp_edit_fil_loc.png)

You can share your waypoints publicly (and can be loaded by other users of Bot Warfare remotely) by making a Pull Request to the [IW4x_Waypoints repo](https://github.com/ineedbots/iw4x_waypoints).
