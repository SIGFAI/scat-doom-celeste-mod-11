// Minecraft-style mobs. Every hit flashes them red with a little hop, they topple over when they die,
// then vanish in a puff of smoke and drop experience orbs that fly to the player.
class SicMob : Actor
{
	int xpDrop;
	property XPDrop : xpDrop;

	Default
	{
		Monster;
		+FLOORCLIP;
		Mass 100;
		Scale 0.5;
		SicMob.XPDrop 3;
		PainSound "sic/hurt";
		BloodColor "B01818";
	}

	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle)
	{
		int r = Super.DamageMobj(inflictor, source, damage, mod, flags, angle);
		// Every hit shows: red squares fly off and the mob hops back a little, like a Minecraft knockback.
		if (r > 0)
		{
			SicFX.Debris(pos + (0, 0, height * 0.6), Color(230, 40, 40), Color(150, 15, 15), 6, 2.5, 4);
			if (health > 0 && pos.z <= floorz + 1 && !bNoGravity) vel.z += 3.5;
			if (health > 0) A_StartSound("sic/hurt", CHAN_6, CHANF_DEFAULT, 0.8);
		}
		return r;
	}

	// The end of a Minecraft death: smoke puff, a pop, the orbs, and the body is gone.
	void A_McPoof(int puffs = 20)
	{
		SicFX.Poof(self, puffs);
		A_StartSound("sic/poof", CHAN_BODY);
		for (int i = 0; i < xpDrop; i++)
		{
			let o = Spawn("SicXPOrb", pos + (0, 0, max(8, height * 0.4)), ALLOW_REPLACE);
			if (o) o.vel = (frandom(-3, 3), frandom(-3, 3), frandom(3, 6));
		}
	}
}

// ---- Block Zombie: shambles at you with its arms out and smacks you. ------------------------------------
class SicBlockZombie : SicMob replaces ZombieMan
{
	Default
	{
		Health 50;
		Radius 16;
		Height 56;
		Speed 7;
		PainChance 200;
		MeleeRange 52;
		SeeSound "sic/zombie";
		ActiveSound "sic/zombie";
		DeathSound "sic/zombie";
		Obituary "%o was hugged too hard by a Block Zombie.";
		Tag "Block Zombie";
		DropItem "None";
	}

	States
	{
	Spawn:
		BZOM A 10 A_Look;
		Loop;
	See:
		BZOM ABCD 5 A_Chase;
		Loop;
	Melee:
		BZOM E 7 A_FaceTarget;
		BZOM F 6 A_CustomMeleeAttack(random(3, 5) * 3, "sic/hurt", "", 'Melee', true);
		BZOM E 5;
		Goto See;
	Pain:
		BZOM G 6 A_Pain;
		Goto See;
	Death:
		BZOM H 5 A_Scream;
		BZOM I 5 A_NoBlocking;
		BZOM J 5;
		BZOM K 12;
		TNT1 A 0 A_McPoof;
		Stop;
	}
}

// Doom's shotgunners and chaingunners become tougher zombies.
class SicBlockZombieB : SicBlockZombie replaces ShotgunGuy
{
	Default { Health 60; Speed 8; }

	States
	{
	Spawn:
		BZOM A 10 A_Look;
		Loop;
	See:
		BZOM ABCD 5 A_Chase;
		Loop;
	Melee:
		BZOM E 7 A_FaceTarget;
		BZOM F 6 A_CustomMeleeAttack(random(3, 5) * 3, "sic/hurt", "", 'Melee', true);
		BZOM E 5;
		Goto See;
	Pain:
		BZOM G 6 A_Pain;
		Goto See;
	Death:
		BZOM H 5 A_Scream;
		BZOM I 5 A_NoBlocking;
		BZOM J 5;
		BZOM K 12;
		TNT1 A 0 A_McPoof;
		Stop;
	}
}
class SicBlockZombieC : SicBlockZombie replaces ChaingunGuy
{
	Default { Health 80; Speed 8; SicMob.XPDrop 5; }

	States
	{
	Spawn:
		BZOM A 10 A_Look;
		Loop;
	See:
		BZOM ABCD 5 A_Chase;
		Loop;
	Melee:
		BZOM E 7 A_FaceTarget;
		BZOM F 6 A_CustomMeleeAttack(random(3, 5) * 3, "sic/hurt", "", 'Melee', true);
		BZOM E 5;
		Goto See;
	Pain:
		BZOM G 6 A_Pain;
		Goto See;
	Death:
		BZOM H 5 A_Scream;
		BZOM I 5 A_NoBlocking;
		BZOM J 5;
		BZOM K 12;
		TNT1 A 0 A_McPoof;
		Stop;
	}
}

// ---- Shadow Self: your dark reflection. Blinks around in purple smoke and throws dark orbs. -------------
class SicShadowSelf : SicMob replaces DoomImp
{
	int blinkAt;

	Default
	{
		Health 60;
		Radius 16;
		Height 56;
		Speed 9;
		PainChance 200;
		SeeSound "sic/orbcast";
		DeathSound "sic/poof";
		Obituary "%o could not outrun their Shadow Self.";
		Tag "Shadow Self";
		SicMob.XPDrop 4;
	}

	// Celeste's dark reflection never stays put: a short teleport sideways, in a purple ring.
	void A_ShadowChase()
	{
		A_Chase();
		if (!target || level.maptime < blinkAt || random(0, 99) > 3) return;
		blinkAt = level.maptime + 70;
		Vector3 from = pos;
		for (int i = 0; i < 6; i++)
		{
			Vector2 xy = Vec2Angle(frandom(96, 192), AngleTo(target) + (random(0, 1) ? 90 : -90) + frandom(-30, 30));
			double z = level.PointInSector(xy).floorplane.ZatPoint(xy);
			if (abs(z - pos.z) > 32) continue;
			Vector3 old = pos;
			SetOrigin((xy, z), false);
			if (!TestMobjLocation() || !CheckSight(target)) { SetOrigin(old, false); continue; }
			SicFX.Ring(from + (0, 0, 28), Color(190, 60, 220), 12, 4, 7);
			SicFX.Ring(pos + (0, 0, 28), Color(255, 120, 230), 12, 3, 6);
			A_StartSound("sic/orbcast", CHAN_BODY, CHANF_DEFAULT, 0.7, ATTN_NORM, 1.3);
			ClearInterpolation();
			break;
		}
	}

	override void Tick()
	{
		Super.Tick();
		// Wisps of purple rising from it, so you always know it is not you.
		if (health > 0 && !bNoSector && !(level.maptime % 3))
			SicFX.Quad(pos + (frandom(-12, 12), frandom(-12, 12), frandom(30, 56)), Color(170, 50, 210), frandom(3, 6), (0, 0, 0.8), (0, 0, 0), 18);
	}

	States
	{
	Spawn:
		SHDW A 10 A_Look;
		Loop;
	See:
		SHDW ABCD 5 A_ShadowChase;
		Loop;
	Missile:
		SHDW E 8 A_FaceTarget;
		SHDW F 6 A_SpawnProjectile("SicShadowOrb", 38, 6);
		SHDW E 4;
		Goto See;
	Pain:
		SHDW G 6 A_Pain;
		Goto See;
	Death:
		SHDW H 5 A_Scream;
		SHDW I 5 A_NoBlocking;
		SHDW J 5;
		SHDW K 12;
		TNT1 A 0 { SicFX.Ring(pos + (0, 0, 20), Color(190, 60, 220), 16, 5, 8); A_McPoof(); }
		Stop;
	}
}

class SicShadowOrb : Actor
{
	Default
	{
		Radius 8;
		Height 12;
		Speed 13;
		FastSpeed 20;
		DamageFunction (random(1, 8) * 3);
		Projectile;
		+BRIGHT;
		RenderStyle "Add";
		SeeSound "sic/orbcast";
		DeathSound "sic/poof";
	}

	override void Tick()
	{
		Super.Tick();
		if (bNoSector) return;
		// A dark core with a magenta rim, trailing purple squares.
		SicFX.Quad(pos + (0, 0, 6), Color(255, 110, 235), 15, (0, 0, 0), (0, 0, 0), 2);
		SicFX.Quad(pos + (0, 0, 6), Color(90, 10, 120), 10, (0, 0, 0), (0, 0, 0), 2, -1, false);
		SicFX.Quad(pos + (frandom(-4, 4), frandom(-4, 4), frandom(2, 10)), Color(170, 50, 210), frandom(4, 7), -vel * 0.05, (0, 0, 0), 14);
	}

	States
	{
	Spawn:
		TNT1 A -1;
		Stop;
	Death:
		TNT1 A 1 { SicFX.Ring(pos + (0, 0, 6), Color(200, 70, 230), 10, 3, 6); }
		Stop;
	}
}

// ---- Hisser: a cat that is secretly a creeper. Sneaks up, hisses, swells, explodes. ------------------------
class SicHisser : SicMob replaces Demon
{
	int fuse;
	bool lit;   // fuse already burning: nothing calms it down any more

	Default
	{
		Health 80;
		Radius 20;
		Height 38;
		Speed 12;
		PainChance 160;
		MeleeRange 72;
		Mass 120;
		DeathSound "sic/poof";
		Obituary "%o got hissed at. Then exploded.";
		Tag "Hisser";
		SicMob.XPDrop 5;
	}

	void A_FuseTick()
	{
		fuse++;
		A_SetScale(0.5 + fuse * 0.012);
		// Too far away again: it calms down, like a creeper does.
		if (!lit && target && Distance2D(target) > 260) { fuse = 0; A_SetScale(0.5); SetStateLabel("See"); return; }
		if (fuse >= 14) SetStateLabel("Kaboom");
	}

	States
	{
	Spawn:
		HISS A 10 A_Look;
		Loop;
	See:
		HISS ABCD 4 A_Chase;
		Loop;
	Melee:
		HISS E 0 { fuse = 0; A_StartSound("sic/hiss", CHAN_VOICE); A_Stop(); }
	Fuse:
		HISS E 3 A_FuseTick;
		HISS F 3 A_FuseTick;
		Loop;
	Kaboom:
		TNT1 A 0 A_Die('Explode');
		Stop;
	Pain:
		HISS G 6 A_Pain;
		TNT1 A 0 A_JumpIf(lit, "Fuse");
		TNT1 A 0 { fuse = 0; A_SetScale(0.5); }
		Goto See;
	Death:
		HISS H 5 A_SetScale(0.5);
		HISS I 5 A_NoBlocking;
		HISS J 5;
		HISS K 12;
		TNT1 A 0 A_McPoof;
		Stop;
	Death.Explode:
		TNT1 A 0
		{
			A_NoBlocking();
			SicBoom.Blast(self, 100, 160, Color(80, 200, 80), Color(110, 80, 50));
		}
		TNT1 A 20;
		Stop;
	}
}

// The spectre's version: a half-invisible Hisser.
class SicHisserB : SicHisser replaces Spectre
{
	Default { RenderStyle "Translucent"; Alpha 0.6; }

	States
	{
	Spawn:
		HISS A 10 A_Look;
		Loop;
	See:
		HISS ABCD 4 A_Chase;
		Loop;
	Melee:
		HISS E 0 { fuse = 0; A_StartSound("sic/hiss", CHAN_VOICE); A_Stop(); }
	Fuse:
		HISS E 3 A_FuseTick;
		HISS F 3 A_FuseTick;
		Loop;
	Kaboom:
		TNT1 A 0 A_Die('Explode');
		Stop;
	Pain:
		HISS G 6 A_Pain;
		TNT1 A 0 A_JumpIf(lit, "Fuse");
		TNT1 A 0 { fuse = 0; A_SetScale(0.5); }
		Goto See;
	Death:
		HISS H 5 A_SetScale(0.5);
		HISS I 5 A_NoBlocking;
		HISS J 5;
		HISS K 12;
		TNT1 A 0 A_McPoof;
		Stop;
	Death.Explode:
		TNT1 A 0
		{
			A_NoBlocking();
			SicBoom.Blast(self, 100, 160, Color(80, 200, 80), Color(110, 80, 50));
		}
		TNT1 A 20;
		Stop;
	}
}

// A Minecraft explosion: damage, a shake, a cloud of grey squares and flying blocks of the given colours.
class SicBoom play
{
	static void Blast(Actor a, int damage, double radius, Color c1, Color c2)
	{
		a.A_Explode(damage, int(radius), XF_HURTSOURCE, false, int(radius * 0.4));
		a.A_StartSound("sic/boom", CHAN_AUTO, CHANF_DEFAULT, 1.0, ATTN_NORM * 0.6);
		a.A_QuakeEx(3, 3, 2, 16, 0, 600, "", QF_SCALEDOWN);
		Vector3 c = a.pos + (0, 0, 20);
		// The cloud: big grey cubes billowing up, the Minecraft explosion look.
		for (int i = 0; i < 44; i++)
		{
			int g = random(160, 245);
			SicFX.Quad(c + (frandom(-44, 44), frandom(-44, 44), frandom(-10, 56)), Color(g, g, g), frandom(18, 34), (frandom(-2.5, 2.5), frandom(-2.5, 2.5), frandom(0.6, 3)), (0, 0, 0.02), random(30, 50), -1, false);
		}
		// The fireball: a short white-orange flash in the middle.
		for (int i = 0; i < 18; i++)
			SicFX.Quad(c + (frandom(-20, 20), frandom(-20, 20), frandom(-6, 30)), Color(255, random(150, 240), random(40, 120)), frandom(22, 36), (frandom(-5, 5), frandom(-5, 5), frandom(-1, 5)), (0, 0, 0), random(8, 14));
		SicFX.Debris(c, c1, c2, 30, 8, 8);
		Actor.Spawn("SicBoomFlash", c, ALLOW_REPLACE);
		a.A_SprayDecal("Scorch", 64);
	}
}

// The light of a blast, fading out over a third of a second.
class SicBoomFlash : Actor
{
	Default { +NOBLOCKMAP; +NOGRAVITY; +NOINTERACTION; }

	override void Tick()
	{
		Super.Tick();
		int age = GetAge();
		if (age > 12) { Destroy(); return; }
		A_AttachLight('boom', DynamicLight.PointLight, Color(255, 190, 90), int(280 - age * 20), 0);
	}

	States { Spawn: TNT1 A -1; Stop; }
}

// ---- Experience orb: pops out of a dead mob, then homes in on the player. ---------------------------------
class SicXPOrb : Actor
{
	Default
	{
		Radius 3;
		Height 6;
		+NOBLOCKMAP;
		+DROPOFF;
		+NOTELEPORT;
		+BRIGHT;
		Gravity 0.6;
	}

	override void Tick()
	{
		Super.Tick();
		if (bNoSector) return;
		let mo = players[consoleplayer].mo;
		// Small glowing squares; they shrink as they reach the player so they never flood the camera.
		double near = mo ? clamp(mo.Distance3D(self) / 160., 0.35, 1.) : 1.;
		double pulse = (5 + sin(level.maptime * 24) * 1.2) * near;
		SicFX.Quad(pos + (0, 0, 3), Color(200, 255, 60), pulse, (0, 0, 0), (0, 0, 0), 2);
		SicFX.Quad(pos + (0, 0, 3), Color(255, 255, 200), pulse * 0.45, (0, 0, 0), (0, 0, 0), 2);
		if (!mo || GetAge() < 18) return;
		Vector3 to = mo.pos + (0, 0, 16) - pos;
		double d = to.Length();
		// Collected at arm's length, so it never ends up glowing right in front of the camera.
		if (d < 90)
		{
			let g = SicGame.Get();
			if (g) g.xp++;
			mo.A_StartSound("sic/xporb", CHAN_AUTO, CHANF_DEFAULT, 0.7);
			Destroy();
			return;
		}
		if (d < 1400)
		{
			bNoGravity = true;
			double sp = min(22., 4 + GetAge() * 0.4);
			vel = to / d * sp;
		}
	}

	States
	{
	Spawn:
		TNT1 A -1;
		Stop;
	}
}

// ---- The SuperIntelligent Cat: floats on pure intellect, fires lasers from its glasses, sends Hissers. ------
class SicGeniusCat : SicMob
{
	int nextTaunt, tauntIdx, summons;
	double baseZ;

	static const String TAUNTS[] = {
		"I have calculated 9,000 ways for you to fail. This is way number one.",
		"I turned your mountain into cubes. Cubes are 47% more efficient.",
		"Your climbing technique is deeply suboptimal.",
		"Strawberries are a waste of resources. I have eaten all the math ones.",
		"Meow. That is cat for 'checkmate'.",
		"You cannot dash past PURE INTELLECT."
	};

	Default
	{
		Health 300;
		Radius 36;
		Height 96;
		Scale 0.7;
		Speed 9;
		Mass 800;
		PainChance 50;
		+FLOAT;
		+NOGRAVITY;
		+DONTMORPH;
		+NOINFIGHTING;
		SeeSound "sic/meow";
		PainSound "sic/hurt";
		DeathSound "sic/meow";
		Obituary "%o was outsmarted by the SuperIntelligent Cat.";
		Tag "The SuperIntelligent Cat";
		SicMob.XPDrop 20;
	}

	override void PostBeginPlay()
	{
		Super.PostBeginPlay();
		nextTaunt = level.maptime + 70;
		let g = SicGame.Get();
		if (g) g.Say("Greetings, inferior climber. I am the SuperIntelligent Cat.", 110, true);
	}

	override void Tick()
	{
		Super.Tick();
		if (health <= 0 || bNoSector) return;
		// Hovers on intellect: a slow bob above the floor and a trail of thinking sparkles.
		double want = floorz + 14 + sin(level.maptime * 4) * 8;
		vel.z = clamp((want - pos.z) * 0.1, -3, 3);
		if (!(level.maptime % 3)) SicFX.Sparkle(pos + (0, 0, frandom(0, 12)), Color(140, 220, 255), 1, 24);
		// It lectures from a polite distance: too close and it floats back.
		if (target && Distance2D(target) < 230) vel.xy = vel.xy * 0.8 + AngleToVector(target.AngleTo(self), 3);
		if (target && level.maptime >= nextTaunt)
		{
			nextTaunt = level.maptime + 35 * 9;
			let g = SicGame.Get();
			if (g) g.Say(TAUNTS[tauntIdx++ % TAUNTS.Size()], 100, true);
		}
	}

	override int DamageMobj(Actor inflictor, Actor source, int damage, Name mod, int flags, double angle)
	{
		// Its own minions' explosions barely scratch it (it planned for that, obviously).
		if (source is "SicHisser" || inflictor is "SicHisser")
		{
			damage = max(1, damage / 5);
			if (!random(0, 2)) { let g = SicGame.Get(); if (g) g.Say("Minion. You are demoted.", 60, true); }
		}
		return Super.DamageMobj(inflictor, source, damage, mod, flags, angle);
	}

	void A_CatLaser()
	{
		if (!target) return;
		A_FaceTarget();
		A_StartSound("sic/catlaser", CHAN_WEAPON);
		// One beam from each lens of the glasses.
		A_SpawnProjectile("SicCatLaser", 70, -12, frandom(-2, 2));
		A_SpawnProjectile("SicCatLaser", 70, 12, frandom(-2, 2));
	}

	void A_CatSummon()
	{
		int alive = 0;
		let it = ThinkerIterator.Create("SicHisser");
		Actor h;
		while (h = Actor(it.Next())) if (h.health > 0) alive++;
		if (alive >= 3) { A_CatLaser(); return; }
		summons++;
		let g = SicGame.Get();
		if (g) g.Say("Minions! Explain my brilliance to the human. Loudly.", 90, true);
		for (int side = -1; side <= 1; side += 2)
		{
			Vector2 xy = Vec2Angle(80, angle + side * 70);
			let m = Spawn("SicHisser", (xy, level.PointInSector(xy).floorplane.ZatPoint(xy)), ALLOW_REPLACE);
			if (!m) continue;
			if (!m.TestMobjLocation()) { m.Destroy(); continue; }
			SicFX.Poof(m, 16);
			m.target = target;
			m.SetStateLabel("See");
		}
	}

	States
	{
	Spawn:
		BCAT A 10 A_Look;
		Loop;
	See:
		BCAT ABCD 5 A_Chase;
		Loop;
	Missile:
		TNT1 A 0 A_JumpIf(summons < 1 && GetAge() > 70, "Summon");
		BCAT E 10 A_FaceTarget;
		BCAT F 4 A_CatLaser;
		BCAT E 6 A_FaceTarget;
		BCAT F 4 A_CatLaser;
		BCAT E 10;
		Goto See;
	Summon:
		BCAT F 12 A_FaceTarget;
		BCAT F 8 A_CatSummon;
		BCAT E 10;
		Goto See;
	Pain:
		BCAT G 8 A_Pain;
		Goto See;
	Death:
		BCAT H 6
		{
			A_Scream();
			let g = SicGame.Get();
			if (g) g.Say("Impossible... I forgot to carry the one.", 120, true);
		}
		BCAT I 6 A_NoBlocking;
		BCAT J 6;
		BCAT K 16;
		TNT1 A 0
		{
			A_McPoof(40);
			SicFX.Ring(pos + (0, 0, 30), Color(140, 220, 255), 24, 7, 10);
			let h = Spawn("SicCrystalHeart", pos + (0, 0, 24), ALLOW_REPLACE);
		}
		Stop;
	}
}

class SicCatLaser : Actor
{
	Default
	{
		Radius 5;
		Height 6;
		Speed 30;
		DamageFunction (random(6, 12));
		Projectile;
		+BRIGHT;
		DeathSound "sic/blockbreak";
	}

	override void Tick()
	{
		Vector3 from = pos;
		Super.Tick();
		if (bNoSector) return;
		// A solid beam: bright squares along the whole step it just travelled.
		Vector3 d = pos - from;
		for (int i = 0; i < 6; i++)
		{
			Vector3 at = from + d * (i / 6.);
			SicFX.Quad(at, Color(255, 60, 90), 7, (0, 0, 0), (0, 0, 0), 4);
			SicFX.Quad(at, Color(255, 220, 230), 3, (0, 0, 0), (0, 0, 0), 4);
		}
	}

	States
	{
	Spawn:
		TNT1 A -1;
		Stop;
	Death:
		TNT1 A 1 { SicFX.Debris(pos, Color(255, 80, 100), Color(255, 220, 230), 8, 2.5, 4); }
		Stop;
	}
}
