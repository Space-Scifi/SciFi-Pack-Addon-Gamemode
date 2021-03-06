AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include('shared.lua')

function ENT:SpawnFunction( ply,tr )

	local ent = ents.Create("halo_covcapship") --SpaceShip entity
	ent:SetPos( tr.HitPos + Vector(0,0,10))
	ent:Spawn()
	ent:Activate()
	return ent

end

function ENT:Initialize()

	self.MaxHealth = 10000
	self.Pilot = nil
	self.Piloting = false
	self.WeaponsTable = {}

	self.Entity:SetNetworkedInt("health",self.MaxHealth)
	
	self.Entity:SetModel("models/covcapship.mdl")
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

	if self.Piloting and self.Pilot and self.Pilot:IsValid() and IsValid(self.Pilot)then
	
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
			
			for _,v in pairs(self.WeaponsTable) do
			self.Pilot:Give(tostring(v));
			end

			table.Empty(self.WeaponsTable);
		
			self.Pilot=nil
		end
		
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

	if self.Piloting and IsValid(self.Pilot) then
	
		local speedvalue=0
		
				if self.Pilot:KeyDown(IN_MOVELEFT) then
					speedvalue=500
				elseif self.Pilot:KeyDown(IN_MOVERIGHT) then
					speedvalue=-500
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
                elseif self.Pilot:KeyDown( IN_FORWARD ) then
					move.pos = move.pos+self.Entity:GetRight()*1000
				elseif self.Pilot:KeyDown( IN_BACK ) then
					move.pos = move.pos+self.Entity:GetRight()*-1000
				end
		
			move.maxangular		= 5000
			move.maxangulardamp	= 10000
			move.maxspeed			= 1000000
			move.maxspeeddamp		= 10000
			move.dampfactor		= 0.8
			move.teleportdistance	= 5000
			local ang = self.Pilot:GetAimVector():Angle() + Angle(0,90,0) + Angle(-self.Pilot:GetAimVector():Angle().p,0,self.Pilot:GetAimVector():Angle().p) --Fix models and Fix angle problems
			move.angle			= ang
			move.deltatime		= deltatime
		phys:ComputeShadowControl(move)
		
		self.Pilot:SetPos(self.Entity:GetPos())
	end
end

function ENT:PrimaryFire()
-- When we Push MOUSE_1

end

function ENT:SecondaryFire()
-- When we Push MOUSE_2

end