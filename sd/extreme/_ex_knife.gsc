#include extreme\_ex_weapons;

main()
{
	self endon("kill_thread");

	allowthrow = true;
	for(;;)
	{
		wait( [[level.ex_fpstime]](0.01) );

		// Make sure we're not on a turret
		if(!isdefined(self) || isdefined(self.onturret)) continue;

		// Check if player is holding a knife
		weapon = self getcurrentweapon();
		if(isdefined(weapon) && weapon != "knife_mp") continue;

		// Must release attack button to throw a knife again
		if(isdefined(self) && !self attackbuttonpressed()) allowthrow = true;

		if(allowthrow && isdefined(self) && self attackbuttonpressed() && self isonground())
		{
			// Block throwing until attack button released
			allowthrow = false;

			// Make sure we have ammo in the clip before throwing
			if(weapon == self getWeaponSlotWeapon("primary")) weaponslot = "primary";
				else if(weapon == self getWeaponSlotWeapon("primaryb")) weaponslot = "primaryb";
					else continue;

			clipammo = self getweaponslotclipammo(weaponslot);
			if(clipammo == 0)
			{
				wait( [[level.ex_fpstime]](1) ); // Wait for new clip
				continue;
			}

			// Now animate the throw (new thread allows the knife to be deleted when player dies)
			self thread throwKnife();
			wait( [[level.ex_fpstime]](0.7) );

			// Loop until the attack button is released
			while(isdefined(self) && self attackbuttonpressed()) wait( [[level.ex_fpstime]](0.01) );
		}
	}
}

throwKnife()
{
	knf = spawn("script_model", (0,0,0));
	knf.origin = self.ex_thumbmarker.origin;
	knf setModel("xmodel/weapon_knife");
	knf.angles = self.angles;
	knf show();
	startOrigin = self getEye();
	forward = anglesToForward(self getplayerangles());
	forward = [[level.ex_vectorscale]]( forward, 500 );
	endOrigin = startOrigin + forward;
	knf moveto(endOrigin,.3,0,0);
	knf rotatepitch(360,.7,0,0);
	wait( [[level.ex_fpstime]](0.7) );
	knf delete();
}
