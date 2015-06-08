include('shared.lua')


function ViewPoint( ply, origin, angles, fov )

	local jump=LocalPlayer():GetNetworkedEntity("Jumper",LocalPlayer())
	local dist= -300

	if LocalPlayer():GetNetworkedBool("isDriveJumper",false) and jump~=LocalPlayer() and jump:IsValid() then
		local view = {}
			view.origin = jump:GetPos()+Vector( 0, 0, 150 )+ply:GetAimVector():GetNormal()*dist
			view.angles = angles
		return view
	end
end
hook.Add("CalcView", "JumperView", ViewPoint)


function CalcViewThing( pl, origin, angle, fov )

	local ang = pl:GetAimVector();
	//local ang = aim:Angle():Right() * -1;
	
	local pos = self.Entity:GetPos() + Vector( 0, 0, 64 ) - ( ang * 2000 );
	local speed = self.Entity:GetVelocity():Length() - 500;

	// the direction to face
	local face = ( ( self.Entity:GetPos() + Vector( 0, 0, 40 ) ) - pos ):Angle();

	// trace to keep it out of the walls
	local trace = {
		start = self.Entity:GetPos() + Vector( 0, 0, 64 ),
		endpos = self.Entity:GetPos() + Vector( 0, 0, 64 ) + face:Forward() * ( 2000 * -1 );
		mask = MASK_NPCWORLDSTATIC,

	};
	local tr = util.TraceLine( trace );

	// setup view
	local view = {
		origin = tr.HitPos + tr.HitNormal,
		angles = face,
		fov = 90,

	};

	return view;

end