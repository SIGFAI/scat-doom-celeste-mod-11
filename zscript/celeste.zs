// Celeste pieces dropped into Doom: strawberries, winged strawberries, dash crystals, springs, the crystal heart.

class SicStrawberry : Inventory
{
	Default
	{
		Radius 14;
		Height 24;
		Scale 0.6;
		+FLOATBOB;
		+INVENTORY.ALWAYSPICKUP;
		+NOGRAVITY;
		Inventory.PickupSound "sic/berry";
		Tag "Strawberry";
	}

	override String PickupMessage()
	{
		let g = SicGame.Get();
		return g ? String.Format("Strawberry! (%d/%d)", g.berries, g.berryGoal) : "Strawberry!";
	}

	override bool TryPickup(in out Actor toucher)
	{
		if (!toucher || !toucher.player) return false;
		toucher.GiveBody(10, 200);
		let g = SicGame.Get();
		if (g) g.BerryGot(toucher, self, bWinged());
		SicFX.Ring(pos + (0, 0, 12), Color(255, 70, 80), 14, 4, 6);
		SicFX.Ring(pos + (0, 0, 12), Color(255, 230, 90), 10, 2.5, 5);
		GoAwayAndDie();
		return true;
	}

	virtual bool bWinged() { return false; }

	override void Tick()
	{
		Super.Tick();
		if (!(level.maptime % 5) && !bNoSector) SicFX.Sparkle(pos + (0, 0, 14), Color(255, 240, 160), 1, 10);
	}

	States
	{
	Spawn:
		SBRY A -1;
		Stop;
	}
}

// A winged strawberry: dash near it and it flies off laughing (Celeste rule); shoot it down with an arrow and it
// drops as a plain strawberry; walk up to it calmly to catch it.
class SicWingBerry : SicStrawberry
{
	int fleeTics, flees;
	double homeZ;

	Default
	{
		Health 1;
		Radius 16;
		Height 26;
		Scale 0.62;
		-FLOATBOB;
		+SHOOTABLE;
		+NOBLOOD;
		+NOTAUTOAIMED;
		+DONTTHRUST;
		Tag "Winged Strawberry";
	}

	override bool bWinged() { return true; }

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		homeZ = pos.z + 24;
		SetOrigin((pos.xy, homeZ), false);
	}

	override void Tick()
	{
		Super.Tick();
		if (bNoSector || health <= 0) return;
		let mo = players[consoleplayer].mo;
		if (fleeTics > 0)
		{
			fleeTics--;
			if (fleeTics == 0) vel = (0, 0, 0);
			return;
		}
		// Bob gently around its perch.
		vel.z = (homeZ + sin(level.maptime * 6) * 6 - pos.z) * 0.2;
		if (!mo || flees >= 3) return;
		// A dashing player (fast, airborne) scares it away.
		if (Distance3D(mo) < 260 && mo.vel.Length() > 13)
		{
			flees++;
			fleeTics = 45;
			double away = mo.AngleTo(self) + frandom(-35, 35);
			vel = (AngleToVector(away, 9), 5);
			homeZ = min(ceilingz - height - 4, homeZ + 40);
			A_StartSound("sic/spring", CHAN_VOICE, CHANF_DEFAULT, 0.5, ATTN_NORM, 1.6);
			SicFX.Sparkle(pos + (0, 0, 12), Color(255, 255, 255), 8, 12);
			let g = SicGame.Get();
			if (g) g.Say("The strawberry saw you dash. It is gone. Classic.", 70, false);
		}
	}

	States
	{
	Spawn:
		SBRW AB 5;
		Loop;
	Death:
		TNT1 A 0
		{
			// Shot down: the wings pop off, a plain strawberry falls to the ground.
			SicFX.Sparkle(pos + (0, 0, 12), Color(255, 255, 255), 14, 14);
			A_StartSound("sic/poof", CHAN_BODY);
			let b = Spawn("SicFallenBerry", pos, ALLOW_REPLACE);
			if (b) b.vel = (0, 0, 2);
		}
		Stop;
	}
}

class SicFallenBerry : SicStrawberry
{
	Default { -NOGRAVITY; -FLOATBOB; }
}

// Dash crystal: touch it and you dash forward through the air, hurting whatever you plough into.
// It turns into a hollow outline and grows back 2.5 s later, like the refill crystals of the mountain.
class SicDashCrystal : Actor
{
	int regrow;

	Default
	{
		Radius 14;
		Height 30;
		Scale 0.55;
		+NOGRAVITY;
		+FLOATBOB;
		+NOBLOCKMONST;
		RenderStyle "Normal";
		Tag "Dash Crystal";
	}

	override void Tick()
	{
		Super.Tick();
		if (bNoSector) return;
		if (regrow > 0)
		{
			if (--regrow == 0)
			{
				SetStateLabel("Spawn");
				A_StartSound("sic/crystal", CHAN_BODY, CHANF_DEFAULT, 0.5, ATTN_NORM, 1.5);
				SicFX.Sparkle(pos + (0, 0, 16), Color(120, 255, 170), 10, 12);
			}
			return;
		}
		if (!(level.maptime % 4)) SicFX.Sparkle(pos + (0, 0, 16), Color(150, 255, 190), 1, 12);
		for (int i = 0; i < MAXPLAYERS; i++)
		{
			if (!playeringame[i] || !players[i].mo) continue;
			let mo = players[i].mo;
			if (Distance2D(mo) < radius + mo.radius + 8 && abs(mo.pos.z + mo.height * 0.5 - (pos.z + height * 0.5)) < 48)
			{
				let g = SicGame.Get();
				if (g) g.Dash(mo, true);
				A_StartSound("sic/crystal", CHAN_BODY);
				SicFX.Ring(pos + (0, 0, 16), Color(120, 255, 170), 12, 4, 6);
				regrow = 88;
				SetStateLabel("Used");
				break;
			}
		}
	}

	States
	{
	Spawn:
		DCRY AAAAAAC 4 Bright;
		Loop;
	Used:
		DCRY B -1;
		Stop;
	}
}

// Spring: anything that steps on it (player or monster) is flung into the air.
class SicSpring : Actor
{
	int cool;

	Default
	{
		Radius 16;
		Height 14;
		Scale 0.55;
		+SOLID;
		+ACTLIKEBRIDGE;
		+NOBLOCKMONST;
		Tag "Spring";
	}

	override void Tick()
	{
		Super.Tick();
		if (bNoSector) return;
		if (cool > 0) { cool--; return; }
		let it = BlockThingsIterator.Create(self, 40);
		while (it.Next())
		{
			let t = it.thing;
			if (!t || t == self || t.health <= 0 || !(t.player || t.bIsMonster)) continue;
			if (Distance2D(t) > radius + t.radius) continue;
			double top = pos.z + height;
			if (t.pos.z < top - 2 || t.pos.z > top + 6 || t.vel.z > 2) continue;
			t.vel.z = t.player ? 21 : 17;
			if (!t.player) t.vel.xy *= 1.5;
			A_StartSound("sic/spring", CHAN_BODY);
			SicFX.Sparkle(pos + (0, 0, 14), Color(255, 220, 80), 8, 10);
			SetStateLabel("Boing");
			cool = 12;
			if (t.player) { let g = SicGame.Get(); if (g) g.Sproing(t); }
		}
	}

	States
	{
	Spawn:
		SPRG A -1;
		Stop;
	Boing:
		SPRG B 3;
		SPRG C 5;
		SPRG A 2;
		Goto Spawn;
	}
}

// The crystal heart the cat drops: the end of the chapter.
class SicCrystalHeart : Inventory
{
	Default
	{
		Radius 18;
		Height 28;
		Scale 0.7;
		+FLOATBOB;
		+NOGRAVITY;
		+INVENTORY.ALWAYSPICKUP;
		Inventory.PickupSound "sic/heart";
		Inventory.PickupMessage "You got the Crystal Heart!";
		Tag "Crystal Heart";
	}

	override bool TryPickup(in out Actor toucher)
	{
		if (!toucher || !toucher.player) return false;
		toucher.GiveBody(100, 200);
		SicFX.Ring(pos + (0, 0, 14), Color(80, 170, 255), 20, 6, 8);
		SicFX.Ring(pos + (0, 0, 14), Color(200, 240, 255), 14, 3.5, 6);
		let g = SicGame.Get();
		if (g) g.HeartGot(toucher);
		GoAwayAndDie();
		return true;
	}

	override void Tick()
	{
		Super.Tick();
		if (bNoSector) return;
		if (!(level.maptime % 2)) SicFX.Sparkle(pos + (0, 0, 14), Color(140, 210, 255), 1, 16);
		// After a moment of glory it drifts to the climber, like it wants to be found.
		let mo = players[consoleplayer].mo;
		if (mo && GetAge() > 30)
		{
			Vector3 to = mo.pos + (0, 0, 24) - pos;
			double d = to.Length();
			if (d > 1) SetOrigin(pos + to / d * min(d, 9.), true);
		}
	}

	States
	{
	Spawn:
		CHRT A -1 Bright;
		Stop;
	}
}

// The golden strawberry: the rare one. Big heal, counts double.
class SicGoldBerry : SicStrawberry
{
	Default { Scale 0.75; Tag "Golden Strawberry"; }

	override String PickupMessage() { return "GOLDEN STRAWBERRY!"; }

	override bool TryPickup(in out Actor toucher)
	{
		if (!toucher || !toucher.player) return false;
		toucher.GiveBody(100, 200);
		let g = SicGame.Get();
		if (g) { g.BerryGot(toucher, self, false); g.BerryGot(toucher, self, false); }
		SicFX.Ring(pos + (0, 0, 14), Color(255, 210, 60), 20, 5, 7);
		SicFX.Ring(pos + (0, 0, 14), Color(255, 255, 200), 14, 3, 5);
		GoAwayAndDie();
		return true;
	}

	override void Tick()
	{
		Super.Tick();
		if (!bNoSector && !(level.maptime % 2)) SicFX.Sparkle(pos + (0, 0, 16), Color(255, 220, 90), 1, 14);
	}

	States
	{
	Spawn:
		GBRY A -1 Bright;
		Stop;
	}
}

class SicGoldSpot : Soulsphere replaces Soulsphere
{
	override void PostBeginPlay() { Spawn("SicGoldBerry", pos, ALLOW_REPLACE); Destroy(); }
}

// Map items become mountain collectibles.
class SicBerrySpot : HealthBonus replaces HealthBonus
{
	override void PostBeginPlay()
	{
		// One strawberry in four has wings.
		Spawn(random(0, 3) ? "SicStrawberry" : "SicWingBerry", pos, ALLOW_REPLACE);
		Destroy();
	}
}

class SicCrystalSpot : ArmorBonus replaces ArmorBonus
{
	override void PostBeginPlay()
	{
		// Armour bonuses come in lines: a crystal every third one, strawberries between them.
		Spawn((Hash() % 3) ? "SicStrawberry" : "SicDashCrystal", pos + (0, 0, (Hash() % 3) ? 0 : 8), ALLOW_REPLACE);
		Destroy();
	}

	int Hash() { return (int(pos.x) * 7 + int(pos.y) * 13) & 0xFFFF; }
}
