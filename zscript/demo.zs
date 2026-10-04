// Showcase timeline for the stream demo (sic_demo 1 in demo.cfg): each beat spawns its things in view of the
// player, on the floor, at a readable distance, so the whole idea plays out in under a minute.
class SicDemo : EventHandler
{
	int beat, beatAt;
	Array<Actor> cast;   // the monsters the show spawned, to know when a fight is over

	override void WorldTick()
	{
		if (!sic_demo) return;
		let mo = players[consoleplayer].mo;
		if (!mo) return;
		mo.player.cheats |= CF_GODMODE; // the stream player shows off the mod, it never dies
		int t = level.maptime;
		if (t == 1) { ClearStage(mo); FaceOpen(mo); }
		int alive = Alive();
		// Each beat: not before its time, and only once the previous fight is over (or its time is up).
		static const int EARLIEST[] = { 3, 6, 7, 10, 12, 0, 16, 0 };
		static const int LATEST[]   = { 3, 6, 10, 14, 16, 0, 21, 0 };
		if (beat < 8)
		{
			double sec = t / 35.;
			bool go;
			if (beat == 5) go = t >= beatAt + 45;              // the crystal, right after the Shadow Self shows up
			else if (beat == 7) go = alive == 0 || sec >= 46;  // after the cat: waves again
			else go = sec >= EARLIEST[beat] && (alive == 0 || sec >= LATEST[beat] || beat == 1);
			if (!go) return;
			PlayBeat(mo, beat);
			beat++;
			beatAt = t;
			return;
		}
		// Encore: a new small wave whenever the field is clear, at most every 6 s.
		if (alive == 0 && t - beatAt > 35 * 6)
		{
			switch (random(0, 3))
			{
			case 0: Ahead(mo, "SicBlockZombie", 340, -15); Ahead(mo, "SicHisser", 400, 20); break;
			case 1: Ahead(mo, "SicShadowSelf", 380, 0); Ahead(mo, "SicDashCrystal", 30, 0, 16); break;
			case 2: Ahead(mo, "SicBlockZombie", 320, 10); Ahead(mo, "SicBlockZombie", 380, -20); Ahead(mo, "SicWingBerry", 150, 25); break;
			case 3: TntTrap(mo); break;
			}
			beatAt = t;
		}
	}

	void PlayBeat(PlayerPawn mo, int b)
	{
		switch (b)
		{
		case 0: Ahead(mo, "SicBlockZombie", 290, 0); Ahead(mo, "SicBlockZombie", 330, 22); break;
		case 1: Ahead(mo, "SicWingBerry", 150, -20); break;
		case 2: TntTrap(mo); break;
		case 3: SpringTrap(mo); break;
		case 4: Ahead(mo, "SicShadowSelf", 380, 0); break;
		case 5: Ahead(mo, "SicDashCrystal", 30, 0, 16); break;
		case 6: Ahead(mo, "SicGeniusCat", 330, 0, 30); break;
		case 7: Ahead(mo, "SicShadowSelf", 380, 20); Ahead(mo, "SicDashCrystal", 30, 0, 16); break;
		}
	}

	int Alive()
	{
		int n = 0;
		for (int i = cast.Size() - 1; i >= 0; i--)
		{
			if (!cast[i] || cast[i].health <= 0) cast.Delete(i);
			else n++;
		}
		return n;
	}

	// The arena: no trees right around the start, so the camera sees the fights instead of leaves.
	void ClearStage(PlayerPawn mo)
	{
		let it = ThinkerIterator.Create("Actor");
		Actor a;
		while (a = Actor(it.Next()))
		{
			if ((a is "SicOakTree" || a is "SicPineTree" || a is "SicPineStump") && mo.Distance2D(a) < 800) a.Destroy();
			// The map's own monsters wait elsewhere: the show runs its scripted beats one at a time.
			else if (a.bIsMonster && !a.player && a.health > 0 && mo.Distance2D(a) < 2400) a.Destroy();
		}
	}

	// Start the show looking at the widest open space (the garden, not the house wall).
	void FaceOpen(PlayerPawn mo)
	{
		double best = mo.angle, bestFree = -1;
		for (int i = 0; i < 16; i++)
		{
			double yaw = i * 22.5;
			double f = Free(mo, mo.pos.xy, yaw, 1200);
			if (f > bestFree) { bestFree = f; best = yaw; }
		}
		mo.A_SetAngle(best);
	}

	// Distance a knee-high line travels from xy toward yaw: low walls and window sills stop it.
	double Free(Actor mo, Vector2 xy, double yaw, double maxd)
	{
		FLineTraceData d;
		if (!mo.LineTrace(yaw, maxd, 0, TRF_THRUACTORS, 34, data: d)) return maxd;
		return d.Distance;
	}

	// A spring on the straight line between the player and a charging zombie: the zombie goes flying.
	void SpringTrap(PlayerPawn mo)
	{
		let z = Ahead(mo, "SicBlockZombie", 340, -10);
		if (!z) return;
		Vector2 mid = mo.pos.xy + (z.pos.xy - mo.pos.xy) * 0.5;
		if (!Place(mo, "SicSpring", mid, 0)) Place(mo, "SicSpring", mo.pos.xy + (z.pos.xy - mo.pos.xy) * 0.35, 0);
	}

	// A TNT block with two zombies huddled around it; a Hisser walks in a moment later. Kaboom, chain reaction.
	void TntTrap(PlayerPawn mo)
	{
		let tnt = Ahead(mo, "SicTNT", 320, 0);
		if (!tnt)
		{
			Ahead(mo, "SicHisser", 380, 0);
			return;
		}
		Near(tnt, "SicBlockZombie", 52, 70);
		Near(tnt, "SicBlockZombie", 52, -70);
		// Already hissing when it appears next to the TNT: a second later, boom, and the TNT goes too.
		let h = SicHisser(Near(tnt, "SicHisser", 46, 180));
		if (!h) h = SicHisser(Near(tnt, "SicHisser", 46, 120));
		if (!h) h = SicHisser(Near(tnt, "SicHisser", 46, -120));
		if (h) { h.lit = true; h.SetStateLabel("Melee"); }
	}

	// Spawn in front of the player (trying angles around the view), on the floor, seen by the player.
	Actor Ahead(PlayerPawn mo, Class<Actor> cls, double dist, double side, double lift = 0)
	{
		for (int i = 0; i < 14; i++)
		{
			double ang = mo.angle + side + (i % 2 ? 1 : -1) * ((i + 1) / 2) * 12;
			double d = dist * (1 - (i / 2) * 0.09);
			Actor a = Place(mo, cls, mo.Vec2Angle(d, ang), lift);
			if (a) return a;
		}
		return null;
	}

	Actor Near(Actor at, Class<Actor> cls, double dist, double ang)
	{
		let mo = players[consoleplayer].mo;
		for (int i = 0; i < 6; i++)
		{
			Actor a = Place(mo, cls, at.Vec2Angle(dist + i * 8, at.AngleTo(mo) + ang + (i % 2 ? 1 : -1) * i * 12), 0, false);
			if (a) return a;
		}
		return null;
	}

	Actor Place(PlayerPawn mo, Class<Actor> cls, Vector2 xy, double lift, bool needSight = true)
	{
		let s = level.PointInSector(xy);
		double z = s.floorplane.ZatPoint(xy);
		if (abs(z - mo.pos.z) > 64) return null;
		// Only where it can walk straight to the player: nothing spawns behind a window or a fence.
		double dist = (xy - mo.pos.xy).Length();
		if (needSight && Free(mo, mo.pos.xy, VectorAngle(xy.x - mo.pos.x, xy.y - mo.pos.y), dist + 8) < dist - 4) return null;
		let a = Actor.Spawn(cls, (xy, z + lift), ALLOW_REPLACE);
		if (!a) return null;
		if (!a.TestMobjLocation() || (needSight && !mo.CheckSight(a, SF_IGNOREVISIBILITY)))
		{
			a.Destroy();
			return null;
		}
		if (a.bIsMonster)
		{
			cast.Push(a);
			SicFX.Poof(a, 22);
			a.A_StartSound("sic/poof", CHAN_BODY, CHANF_DEFAULT, 0.6);
			a.target = mo;
			a.angle = a.AngleTo(mo);
			if (a.SeeState) a.SetState(a.SeeState);
		}
		return a;
	}
}
