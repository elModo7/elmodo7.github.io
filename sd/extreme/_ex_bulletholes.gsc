
bullethole()
{
	self endon("kill_thread");

	if(!isDefined(self.ex_bulletholes)) self.ex_bulletholes = [];

	hole = self.ex_bulletholes.size;
	
	self.ex_bulletholes[hole] = newClientHudElem(self);
	self.ex_bulletholes[hole].archived = false;
	self.ex_bulletholes[hole].horzAlign = "fullscreen";
	self.ex_bulletholes[hole].vertAlign = "fullscreen";
	self.ex_bulletholes[hole].alignX = "center";
	self.ex_bulletholes[hole].alignY = "middle";
	self.ex_bulletholes[hole].x = 48 + randomInt(544);
	self.ex_bulletholes[hole].y = 48 + randomInt(304);
	self.ex_bulletholes[hole].color = (1,1,1);
	self.ex_bulletholes[hole].alpha = 0.8 + randomFloat(0.2);

	xsize = 64 + randomInt(32);
	ysize = 64 + randomInt(32);

	if(randomInt(2)) self.ex_bulletholes[hole] setShader("gfx/custom/bullethit_glass.tga", xsize, ysize);
	else self.ex_bulletholes[hole] setShader("gfx/custom/bullethit_glass2.tga", xsize, ysize);

	self playLocalSound("glassbreak");

	if(level.ex_bulletholes != 2) return;

	self thread fadeBullethole(hole);
}

fadeBullethole(hole)
{
	wait( [[level.ex_fpstime]](5) );

	if(isPlayer(self))
	{
		if(isDefined(self.ex_bulletholes))
		{
			if(isDefined(self.ex_bulletholes[hole]))
			{
				self.ex_bulletholes[hole] fadeOverTime(1);
				self.ex_bulletholes[hole].alpha = 0;
				wait( [[level.ex_fpstime]](1) );
				if(isPlayer(self) && isDefined(self.ex_bulletholes[hole])) self.ex_bulletholes[hole] destroy();
			}
		}
	}
}
