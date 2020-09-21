init()
{
	level thread onBotConnected();
}

onBotConnected()
{
	for (;;)
	{
		level waittill("bot_connected", bot);

		bot thread setBotPing();
	}
}

setBotPing()
{
	self endon("disconnect");

	for (;;)
	{
		wait 0.05;

		// self SetPing(randomIntRange(40, 60));
	}
}
