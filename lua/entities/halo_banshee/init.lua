AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

function ENT:SpawnFunction( ply,tr )

	local ent = ents.Create("halo_banshee") --SpaceShip entity
	ent:SetPos( tr.HitPos + Vector(0,0,40))
	ent:Spawn()
	ent:Activate()
	return ent

end

function ENT:Initialize()

	self.MaxHealth = 1000
	self.Pilot = nil
	self.Piloting = false
	
	self.CanPrimary = true
	self.CanSecondary = true

	self.Entity:SetNetworkedInt("health",self.MaxHealth)
	
	self.Entity:SetModel("models/banshee.mdl")
	self.Entity:PhysicsInit( SOLID_VPHYSICS )
	self.Entity:SetMoveType( MOVETYPE_VPHYSICS )
	self.Entity:SetSolid( SOLID_VPHYSICS )
	
	local phys = self.Entity:GetPhysicsObject()
	
	if (phys:IsValid()) then
		phys:Wake()
		phys:SetMass(10000)
	end
	
	self.Entity:StartMotionController()
	
	self.Speed=0
	
end

function ENT:Think()

	if self.Piloting and self.Pilot and self.Pilot:IsValid() then
	
		if self.Pilot:KeyDown(IN_ATTACK) then
			self:PrimaryFire()
		elseif self.Pilot:KeyDown(IN_ATTACK2) then
			self:SecondaryFire()
		elseif self.Pilot:KeyDown(IN_USE) then
			self.Piloting=false

			self.Pilot:UnSpectate()
			self.Pilot:DrawViewModel(true)
			self.Pilot:DrawWorldModel(true)
			self.Pilot:Spawn()
			self.Entity:SetOwner(nil)
			self.Pilot:SetNetworkedBool("Driving",false)
			self.Pilot:SetPos(self.Entity:GetPos()+self.Entity:GetRight()*150)

			self.Speed = 0 -- Stop the motor
			self.Entity:SetLocalVelocity(Vector(0,0,0)) -- Stop the ship
		
			self.Pilot=nil
		end
	
		self.Pilot:SetPos(self.Entity:GetPos())
		
		self.Entity:NextThink(CurTime())
	else
		self.Entity:NextThink(CurTime()+1)
	end
	
	return true

end

function ENT:OnTakeDamage(dmg)

	local health = self.Entity:GetNetworkedInt("health")
	local damage = dmg:GetDamage()
	self.Entity:SetNetworkedInt("health",health-damage)
	
	if(health<1) then

		self.Entity:Remove()
		
	end
end

function ENT:OnRemove()

	local health = self.Entity:GetNetworkedInt("health")

	if(health<1) then	
		local effect = EffectData()
			effect:SetOrigin(self.Entity:GetPos())
		util.Effect("Explosion", effect, true, true )
	end
	
	if(self.Piloting) then
		self.Pilot:UnSpectate()
		self.Pilot:DrawViewModel(true)
		self.Pilot:DrawWorldModel(true)
		self.Pilot:Spawn()
		self.Pilot:SetNetworkedBool("Driving",false)
		self.Pilot:SetPos(self.Entity:GetPos()+Vector(0,0,100))
	end

end

function ENT:Use(ply,caller)
	if not self.Piloting then
	
		self.Piloting=true
	
		ply:Spectate( OBS_MODE_CHASE )
		ply:SpectateEntity(self.Entity) 
		ply:StripWeapons()
		
		self.Entity:GetPhysicsObject():Wake()
		self.Entity:GetPhysicsObject():EnableMotion(true)
		self.Entity:SetOwner(ply)
		
		ply:DrawViewModel(false)
		ply:DrawWorldModel(false)
		ply:SetNetworkedBool("Driving",true)
		ply:SetNetworkedEntity("Ship",self.Entity)
		self.Pilot=ply
		
	end
end

function ENT:PhysicsSimulate( phys, deltatime )

	if self.Piloting then
	
		local speedvalue=0
		
				if self.Pilot:KeyDown(IN_FORWARD) then
					speedvalue=500
				elseif self.Pilot:KeyDown(IN_BACK) then
					speedvalue=-500
				elseif self.Pilot:KeyDown(IN_SPEED) then
					speedvalue=1000
				end

		 phys:Wake()
		 
		 self.Speed = math.Approach(self.Speed,speedvalue,10)
		 
		 local move = { }
			 move.secondstoarrive = 1
			 move.pos = self.Entity:GetPos()+self.Entity:GetForward()*self.Speed
				
				if self.Pilot:KeyDown( IN_DUCK ) then
                    move.pos = move.pos+self.Entity:GetUp()*-200
                elseif self.Pilot:KeyDown( IN_JUMP ) then
                   move.pos = move.pos+self.Entity:GetUp()*300
                elseif self.Pilot:KeyDown( IN_MOVERIGHT ) then
					move.pos = move.pos+self.Entity:GetRight()*200
				elseif self.Pilot:KeyDown( IN_MOVELEFT ) then
					move.pos = move.pos+self.Entity:GetRight()*-200
				end
		
			move.maxangular		= 5000
			move.maxangulardamp	= 10000
			move.maxspeed			= 1000000
			move.maxspeeddamp		= 10000
			move.dampfactor		= 0.8
			move.teleportdistance	= 5000
			local ang = self.Pilot:GetAimVector():Angle()
			move.angle			= ang
			move.deltatime		= deltatime
		phys:ComputeShadowControl(move)
	end
end

function ENT:PrimaryFire()
-- When we Push MOUSE_1

	if(self.CanPrimary) then
		bullet = {}
		bullet.Num=1
		bullet.Src=self.Entity:GetPos()+Vector( 0, 0, 150 )
		bullet.Dir=self.Pilot:GetAimVector()
		bullet.Spread=Vector(0.04,0.04,0)
		bullet.Tracer=1
		bullet.Force=1
		bullet.Damage=25
		bullet.TracerName = "AirboatGunTracer"

		self.Entity:FireBullets(bullet)

		self.Entity:EmitSound("Weapon_AR2.Single") 
		
		self.CanPrimary = false
				
		timer.Simple(0.1,function() self.CanPrimary = true end)
		
	end
				
end

function ENT:SecondaryFire()
-- When we Push MOUSE_2

	if(self.CanSecondary) then
		local pos = self.Entity:GetPos();
		local vel = self.Entity:GetVelocity();
		local up = self.Entity:GetUp();

		local e = ents.Create("banshee_grenade");

		e.Parent = self.Entity;
		e:SetPos(pos);
		e:SetOwner(self.Pilot);
		e.Owner = self.Entity.Owner;
		e:Spawn();
		e:GetPhysicsObject():SetVelocity(self.Pilot:GetAimVector() * 99999999 + vel);
		
		self.CanSecondary = false
				
		timer.Simple(5,function() self.CanSecondary = true end)
		
	end

end