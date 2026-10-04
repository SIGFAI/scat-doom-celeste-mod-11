// Doom's props rebuilt as blocks. Same collision as the things they replace.

// Exploding barrel -> TNT: shoot it, it flashes white for a second, then blows up (and sets off its neighbours).
class SicTNT : ExplosiveBarrel replaces ExplosiveBarrel
{
	Default
	{
		Radius 14;
		Height 30;
		Scale 0.5;
		DeathSound "";
		Obituary "%o played with TNT.";
		Tag "TNT";
	}

	States
	{
	Spawn:
		MTNT A -1;
		Stop;
	Death:
		MTNT B 3 A_StartSound("sic/hiss", CHAN_VOICE, CHANF_DEFAULT, 0.7, ATTN_NORM, 1.4);
		MTNT ABABABABAB 3;
		TNT1 A 0
		{
			A_NoBlocking();
			SicBoom.Blast(self, 128, 176, Color(220, 40, 40), Color(240, 240, 240));
		}
		TNT1 A 30;
		Stop;
	}
}

class SicOakTree : BigTree replaces BigTree
{
	Default { Scale 0.22; Radius 22; Height 88; }
	States { Spawn: MTRE A -1; Stop; }
}

class SicPineTree : TorchTree replaces TorchTree
{
	Default { Scale 0.21; Radius 22; Height 96; }
	States { Spawn: MPIN A -1; Stop; }
}

class SicPineStump : Stalagtite replaces Stalagtite
{
	Default { Scale 0.19; Radius 20; Height 84; }
	States { Spawn: MPIN A -1; Stop; }
}

// Columns and pillars -> stone-brick pillars.
class SicPillar : Column replaces Column { Default { Scale 0.5; Height 64; } States { Spawn: MCOL A -1; Stop; } }
class SicPillar2 : TechPillar replaces TechPillar { Default { Scale 0.5; Height 64; } States { Spawn: MCOL A -1; Stop; } }
class SicPillar3 : TallGreenColumn replaces TallGreenColumn { Default { Scale 0.5; Height 64; } States { Spawn: MCOL A -1; Stop; } }
class SicPillar4 : ShortGreenColumn replaces ShortGreenColumn { Default { Scale 0.5; Height 64; } States { Spawn: MCOL A -1; Stop; } }
class SicPillar5 : TallRedColumn replaces TallRedColumn { Default { Scale 0.5; Height 64; } States { Spawn: MCOL A -1; Stop; } }
class SicPillar6 : ShortRedColumn replaces ShortRedColumn { Default { Scale 0.5; Height 64; } States { Spawn: MCOL A -1; Stop; } }

// Lamps -> lamp posts topped with a glowing block.
class SicLampPost : TechLamp replaces TechLamp { Default { Scale 0.5; Height 96; } States { Spawn: MLMP A -1 Bright; Stop; } }
class SicLampPost2 : TechLamp2 replaces TechLamp2 { Default { Scale 0.5; Height 96; } States { Spawn: MLMP A -1 Bright; Stop; } }
class SicLampPost3 : Candelabra replaces Candelabra { Default { Scale 0.5; Height 96; } States { Spawn: MLMP A -1 Bright; Stop; } }

// Torches -> Minecraft torches on fence posts, flickering.
class SicTorch : RedTorch replaces RedTorch { Default { Scale 0.5; } States { Spawn: MTOR ABC 4 Bright; Loop; } }
class SicTorch2 : GreenTorch replaces GreenTorch { Default { Scale 0.5; } States { Spawn: MTOR BCA 4 Bright; Loop; } }
class SicTorch3 : BlueTorch replaces BlueTorch { Default { Scale 0.5; } States { Spawn: MTOR CAB 4 Bright; Loop; } }
class SicTorch4 : ShortRedTorch replaces ShortRedTorch { Default { Scale 0.5; } States { Spawn: MTOR ABC 4 Bright; Loop; } }
class SicTorch5 : ShortGreenTorch replaces ShortGreenTorch { Default { Scale 0.5; } States { Spawn: MTOR BCA 4 Bright; Loop; } }
class SicTorch6 : ShortBlueTorch replaces ShortBlueTorch { Default { Scale 0.5; } States { Spawn: MTOR CAB 4 Bright; Loop; } }
class SicTorch7 : BurningBarrel replaces BurningBarrel { Default { Scale 0.5; } States { Spawn: MTOR ABC 4 Bright; Loop; } }
