ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName	= "Asimov"
ENT.Author	= "Elanis"
ENT.Contact	= ""
ENT.Purpose	= ""
ENT.Instructions= ""
ENT.Spawnable	= true
ENT.AdminSpawnable = true

list.Set("B5.Ent", ENT.PrintName, ENT);

if(gmod.GetGamemode().Name=="SciFiPack") then 
ENT.Category = "SpaceShips"
else
ENT.Category = "Babylon 5"
end