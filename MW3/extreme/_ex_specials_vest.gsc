#include extreme\_ex_specials;

vestPerk(delay)
{
	self endon("kill_thread");

	wait( [[level.ex_fpstime]](delay) );

	if(!isDefined(self.ex_vest)) self.ex_vest = false;
	if(self.ex_vest) return;
	self.ex_vest = true;

		if(level.ex_arcade_shaders) self thread extreme\_ex_arcade::showArcadeShader("x2_vestunlock", level.ex_arcade_shaders_perk);
			else self iprintlnbold(&"SPECIALS_VEST_READY");

      self playlocalsound("vest_ready");


	self thread hudNotifySpecial("vest");
	// moved playerStartUsingPerk("vest") to timer, so player will keep the vest
	// if he dies within 5 seconds after buying it (if keep feature is enabled)
	self.health = 100;
	if(!checkVest()) self attach("xmodel/bulletproofvest", "J_Spine4", false);
	vestTimer();
	if(checkVest()) self detach("xmodel/bulletproofvest", "J_Spine4");
	self thread playerStopUsingPerk("vest");
	self.ex_vest = false;
}

checkVest()
{
	vest_attached = false;
	attachedSize = self getAttachSize();
	for(i = 0; i < attachedSize; i++)
	{
		attachedModel = self getAttachModelName(i);
		if(attachedModel == "xmodel/bulletproofvest") vest_attached = true;
	}

	return(vest_attached);
}

vestTimer()
{
	self endon("kill_thread");

	self.ex_vest_protected = true;

	timer = 0;
	while(timer < level.ex_vest_timer)
	{
		self thread hudNotifyProtected();
		wait( [[level.ex_fpstime]](1) );
		timer++;
		if(timer == 5)
		{
			self thread hudNotifySpecialRemove("vest");
			self thread playerStartUsingPerk("vest");
		}
	}

	self thread hudNotifyProtectedRemove();
	self.ex_vest_protected = undefined;
}
