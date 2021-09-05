@echo off
::RemoteCONtrol password, needed for most management tools like IW4MADMIN and B3. Do not skip if you installing IW4MADMIN.
set rcon_password=
::Name of the config file the server should use.
set cfg=pvbvote.cfg
::Name of the server shown in the title of the cmd window. This will NOT bet shown ingame.
set name=IW4x Bot Warfare PvB Vote
::Port used by the server (default: 28960)
set port=28966
::What ip to bind too
set ip=0.0.0.0
::Mod name (default "")
set mod=mods/pvb
::Only change this when you don't want to keep the bat files in the game folder. MOST WON'T NEED TO EDIT THIS!
set gamepath=%cd%

title IW4x MP - %name% - Server restarter
echo Visit plutonium.pw / Join the Discord (a6JM2Tv) for NEWS and Updates!
echo Server "%name%" will load "%cfg%" and listen on port "%port%" UDP with IP "%ip%"!
echo To shut down the server close this window first!
echo (%date%)  -  (%time%) %name% server start.

:server
start /wait /abovenormal "%name%" "%~dp0iw4x.exe" -dedicated +set sv_lanonly "0" +set net_ip "%ip%" +set net_port "%port%" +set rcon_password "%rcon_password%" +set fs_game "%mod%" +exec "%cfg%" +map_rotate
echo (%date%)  -  (%time%) WARNING: %name% server closed or dropped... server restarts.
goto Server
