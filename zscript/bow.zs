// The player's bow: draw, release, arrows that arc a little, trail sparkles and stick into the blocks they hit.
class SicBow : DoomWeapon
{
	Default
	{
		Weapon.SelectionOrder 100;
		Weapon.AmmoUse 0;
		Weapon.SlotNumber 2;
		Weapon.BobStyle "InverseSmooth";
		Weapon.BobRangeX 0.6;
		Weapon.BobRangeY 0.5;
		+WEAPON.NOALERT;
		+WEAPON.AMMO_OPTIONAL;
		Inventory.PickupMessage "You got the Bow!";
		Obituary "%o was out-aimed by %k's bow.";
		Tag "Bow";
	}

	States
	{
	Ready:
		BOWG A 1 A_WeaponReady;
		Loop;
	Deselect:
		BOWG A 1 A_Lower(12);
		Loop;
	Select:
		BOWG A 1 A_Raise(12);
		Loop;
	Fire:
		BOWG B 3;
		BOWG C 3;
		BOWG D 2
		{
			A_StartSound("sic/bowshot", CHAN_WEAPON);
			A_FireProjectile("SicArrow", frandom(-1, 1), false, 6, -4, 0, frandom(-0.6, 0.6));
			A_AlertMonsters(900);
		}
		BOWG D 4;
		BOWG A 3 A_ReFire;
		Goto Ready;
	Spawn:
		BOWG A -1;
		Stop;
	}
}

class SicArrow : Actor
{
	Default
	{
		Radius 4;
		Height 6;
		Speed 44;
		DamageFunction (random(22, 30));
		Projectile;
		-NOGRAVITY;
		Gravity 0.04;
		Scale 0.5;
		+BLOODSPLATTER;
		+HITTRACER;
		DeathSound "sic/arrowhit";
		Obituary "%o took an arrow to the knee.";
	}

	override void Tick()
	{
		Super.Tick();
		if (bMissile && !bNoSector)
		{
			// Pastel sparkle trail, pink and white like the mountain's crystals.
			SicFX.Quad(pos - vel * 0.3, random(0, 2) ? Color(255, 170, 210) : Color(255, 255, 255), frandom(2.5, 4), (0, 0, 0.1), (0, 0, 0), 12);
		}
	}

	States
	{
	Spawn:
		MARW A -1;
		Stop;
	Death:
		// Stuck in the block it hit, then gone.
		MARW B 0
		{
			Color c = SicFX.BlockColorAt(self);
			SicFX.Debris(pos, c, Color(90, 90, 95), 8, 2.5, 4);
			A_StartSound("sic/blockbreak", CHAN_BODY, CHANF_DEFAULT, 0.6);
		}
		MARW B 140;
		MARW B 1 A_FadeOut(0.1);
		Wait;
	XDeath:
		TNT1 A 0
		{
			if (tracer) SicFX.Debris(pos, Color(220, 30, 30), Color(140, 10, 10), 10, 3, 4);
		}
		Stop;
	Crash:
		TNT1 A 0 { SicFX.Sparkle(pos, Color(255, 255, 255), 6, 6); }
		Stop;
	}
}

// Doom's guns are gone from the mountain: their pickups are strawberries now (one bow is all a climber needs).
class SicNoShotgun : Shotgun replaces Shotgun { override void PostBeginPlay() { Spawn("SicStrawberry", pos, ALLOW_REPLACE); Destroy(); } }
class SicNoSSG : SuperShotgun replaces SuperShotgun { override void PostBeginPlay() { Spawn("SicStrawberry", pos, ALLOW_REPLACE); Destroy(); } }
class SicNoChaingun : Chaingun replaces Chaingun { override void PostBeginPlay() { Spawn("SicDashCrystal", pos + (0, 0, 8), ALLOW_REPLACE); Destroy(); } }
class SicNoChainsaw : Chainsaw replaces Chainsaw { override void PostBeginPlay() { Spawn("SicDashCrystal", pos + (0, 0, 8), ALLOW_REPLACE); Destroy(); } }
