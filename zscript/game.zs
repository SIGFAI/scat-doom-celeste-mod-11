// The chapter: collect strawberries, the SuperIntelligent Cat shows up, beat it, grab the crystal heart.
// Also the player's Celeste dash, the snow, the bow at spawn, XP and the HUD.
class SicGame : EventHandler
{
	const DASH_TICS = 12;
	const DASH_SPEED = 21.;

	int berries, berryGoal, winged, xp, kills;
	bool counted, bossSpawned, bossDead, chapterDone;
	int dashTics, dashCool;
	bool hasDash;
	Array<Actor> dashHit;
	Vector3 dashDir;
	String sayText;
	int sayTics, sayLen, sayAt;
	bool sayCat;
	int titleTics, flashTics, heartTics;
	Color flashColor;
	Actor boss;

	static SicGame Get() { return SicGame(EventHandler.Find("SicGame")); }

	override void WorldLoaded(WorldEvent e)
	{
		titleTics = 35 * 5;
		hasDash = true;
	}

	override void PlayerEntered(PlayerEvent e)
	{
		let mo = players[e.PlayerNumber].mo;
		if (!mo) return;
		mo.GiveInventory("SicBow", 1);
		mo.A_SelectWeapon("SicBow");
	}

	override void NetworkProcess(ConsoleEvent e)
	{
		if (e.Name ~== "sic_dash" && players[e.Player].mo) Dash(players[e.Player].mo, false);
	}

	override void WorldThingSpawned(WorldEvent e)
	{
		if (e.Thing is "SicGeniusCat") { bossSpawned = true; boss = e.Thing; }
	}

	override void WorldThingDied(WorldEvent e)
	{
		if (!e.Thing || !e.Thing.bIsMonster) return;
		kills++;
		if (e.Thing is "SicGeniusCat") bossDead = true;
	}

	// ---- Celeste dash ------------------------------------------------------------------------------

	void Dash(Actor mo, bool crystal)
	{
		if (!mo || !mo.player) return;
		if (!crystal && (!hasDash || dashTics > 0 || dashCool > 0)) return;
		if (!crystal) hasDash = false;
		double p = clamp(mo.pitch, -40., 15.) - 14.;
		dashDir = (cos(mo.angle) * cos(p), sin(mo.angle) * cos(p), -sin(p));
		mo.vel = dashDir * DASH_SPEED;
		mo.vel.z = max(mo.vel.z, 6.5);
		mo.SetOrigin(mo.pos + (0, 0, 3), true);
		dashTics = DASH_TICS;
		dashCool = DASH_TICS + 8;
		dashHit.Clear();
		mo.A_StartSound("sic/dash", CHAN_7);
		Zoom(mo, 1.18);
		Flash(Color(110, 200, 255), 10);
	}

	void DashTick(PlayerPawn mo)
	{
		if (dashCool > 0) dashCool--;
		// Celeste: the dash comes back when your feet touch the ground.
		if (dashTics <= 0)
		{
			if (!hasDash && mo.pos.z <= mo.floorz + 1 && dashCool <= 0) hasDash = true;
			return;
		}
		dashTics--;
		mo.vel.xy = dashDir.xy * DASH_SPEED;
		if (dashTics == 0) Zoom(mo, 1.0);
		// Speed streaks: pink, blue and white squares rushing past the camera, like the climber's dash.
		Vector3 side = (-dashDir.y, dashDir.x, 0);
		for (int i = 0; i < 7; i++)
		{
			double sx = frandom(-70, 70), sz = frandom(-30, 45);
			if (abs(sx) < 18 && abs(sz) < 14) sx += sx < 0 ? -24 : 24;
			Vector3 at = mo.pos + (0, 0, 40) + dashDir * frandom(90, 160) + side * sx + (0, 0, sz);
			int k = random(0, 2);
			Color c = k == 0 ? Color(255, 110, 170) : (k == 1 ? Color(110, 200, 255) : Color(255, 255, 255));
			SicFX.Quad(at, c, frandom(3, 6), -dashDir * 16, (0, 0, 0), 9);
		}
		// Afterimage left behind for anyone watching from the side.
		SicFX.Quad(mo.pos + (frandom(-10, 10), frandom(-10, 10), frandom(10, 50)), random(0, 1) ? Color(255, 110, 170) : Color(110, 200, 255), frandom(6, 10), (0, 0, 0.2), (0, 0, 0), 20);
		// Plough through monsters: a dash hit, once per monster per dash.
		let it = BlockThingsIterator.Create(mo, 80);
		while (it.Next())
		{
			let t = it.thing;
			if (!t || !t.bIsMonster || t.health <= 0 || dashHit.Find(t) != dashHit.Size()) continue;
			if (mo.Distance3D(t) > 64 + t.radius) continue;
			dashHit.Push(t);
			t.DamageMobj(mo, mo, 30, 'Melee');
			if (t && t.health > 0)
			{
				t.vel += (dashDir.xy * 12, 6);
			}
			SicFX.Ring(t.pos + (0, 0, t.height * 0.5), Color(255, 255, 255), 10, 5, 6);
			mo.A_StartSound("sic/hurt", CHAN_6);
		}
	}

	// FOV kick while dashing: the view widens for a burst of speed, then settles back.
	void Zoom(Actor mo, double f)
	{
		let w = mo.player ? mo.player.ReadyWeapon : null;
		if (w) w.FOVScale = f;
	}

	void Sproing(Actor mo) { Flash(Color(255, 220, 80), 8); if (!random(0, 2)) Say("Boing. Physics: still undefeated.", 60, false); }

	void Flash(Color c, int tics) { flashColor = c; flashTics = tics; }

	// ---- Quest ---------------------------------------------------------------------------------------

	void BerryGot(Actor who, Actor berry, bool wing)
	{
		berries++;
		if (wing) winged++;
		xp += 3;
		Flash(Color(255, 90, 110), 8);
		if (berries == berryGoal && !bossSpawned)
			Say("Five strawberries? Statistically, I must now intervene.", 120, true);
	}

	void HeartGot(Actor who)
	{
		chapterDone = true;
		heartTics = 35 * 8;
		Flash(Color(90, 170, 255), 20);
		Say("Fine. Keep your heart. I will compute my revenge in the next chapter.", 160, true);
	}

	void Say(String text, int tics, bool cat)
	{
		// The cat always gets the last word: a passing remark never cuts off its lines.
		if (sayTics > 0 && sayCat && !cat) return;
		sayText = text;
		sayTics = tics + text.Length();
		sayLen = text.Length();
		sayAt = level.maptime;
		sayCat = cat;
		if (cat)
		{
			let mo = players[consoleplayer].mo;
			if (mo) mo.A_StartSound("sic/meow", CHAN_VOICE, CHANF_UI | CHANF_NOPAUSE, 0.9, ATTN_NONE);
		}
	}

	void CountBerries()
	{
		counted = true;
		int n = 0;
		let it = ThinkerIterator.Create("SicStrawberry");
		while (it.Next()) n++;
		berryGoal = clamp(n, 0, 5);
		if (berryGoal < 3) berryGoal = n;
		PlaceSprings();
	}

	// A few springs in the middle of the largest open-air areas of any map.
	void PlaceSprings()
	{
		int made = 0;
		TextureID sky = TexMan.CheckForTexture("F_SKY1", TexMan.Type_Any);
		for (int i = 0; i < level.sectors.Size() && made < 4; i++)
		{
			let s = level.sectors[i];
			if (s.GetTexture(Sector.ceiling) != sky || s.lines.Size() < 6 || s.damageamount > 0) continue;
			Vector2 lo = (1e9, 1e9), hi = (-1e9, -1e9);
			for (int j = 0; j < s.lines.Size(); j++)
			{
				Vector2 a = s.lines[j].v1.p;
				lo = (min(lo.x, a.x), min(lo.y, a.y));
				hi = (max(hi.x, a.x), max(hi.y, a.y));
			}
			if (hi.x - lo.x < 384 || hi.y - lo.y < 384) continue;
			Vector2 c = s.centerspot;
			if (level.PointInSector(c) != s) continue;
			let sp = Actor.Spawn("SicSpring", (c, s.floorplane.ZatPoint(c)), ALLOW_REPLACE);
			if (sp && !sp.TestMobjLocation()) { sp.Destroy(); continue; }
			made++;
		}
	}

	void SpawnBoss(PlayerPawn mo)
	{
		for (int i = 0; i < 12; i++)
		{
			double ang = mo.angle + (i % 2 ? 1 : -1) * (i / 2) * 30;
			Vector3 at = mo.Vec3Angle(320, ang, 40);
			let c = Actor.Spawn("SicGeniusCat", at, ALLOW_REPLACE);
			if (!c) continue;
			if (!c.TestMobjLocation() || !c.CheckSight(mo)) { c.Destroy(); continue; }
			SicFX.Poof(c, 30);
			SicFX.Ring(c.pos + (0, 0, 40), Color(140, 220, 255), 20, 6, 9);
			c.target = mo;
			return;
		}
	}

	// ---- Every tic -------------------------------------------------------------------------------------

	override void WorldTick()
	{
		let mo = players[consoleplayer].mo;
		if (!mo) return;
		if (!counted && level.maptime >= 2) CountBerries();
		// The climber's bow, in hand from the first second (the map start hands out the pistol after us).
		if (level.maptime == 4 || (level.maptime % 35 == 0 && !mo.FindInventory("SicBow")))
		{
			mo.GiveInventory("SicBow", 1);
			let b = Weapon(mo.FindInventory("SicBow"));
			if (b && mo.player.ReadyWeapon != b) mo.player.PendingWeapon = b;
		}
		DashTick(mo);
		Snow(mo);
		if (sayTics > 0) sayTics--;
		if (titleTics > 0) titleTics--;
		if (flashTics > 0) flashTics--;
		if (heartTics > 0) heartTics--;
		if (berryGoal > 0 && berries >= berryGoal && !bossSpawned && sayTics < 60 && level.maptime > 35 * 15 && !sic_demo) { bossSpawned = true; SpawnBoss(mo); }
		if (bossDead && boss) boss = null;
	}

	// Gentle mountain snow drifting through every open-air area near the player.
	void Snow(PlayerPawn mo)
	{
		TextureID sky = TexMan.CheckForTexture("F_SKY1", TexMan.Type_Any);
		for (int i = 0; i < 5; i++)
		{
			Vector2 xy = mo.pos.xy + (frandom(-900, 900), frandom(-900, 900));
			let s = level.PointInSector(xy);
			if (s.GetTexture(Sector.ceiling) != sky) continue;
			double z = min(s.ceilingplane.ZatPoint(xy) - 8, mo.pos.z + frandom(120, 360));
			if (z < s.floorplane.ZatPoint(xy) + 8) continue;
			double wind = sin(level.maptime * 0.7) * 0.6 + 0.5;
			SicFX.Quad((xy, z), Color(235, 240, 255), frandom(2.5, 4.5), (wind, frandom(-0.3, 0.3), -frandom(1.2, 2.0)), (0, 0, 0), 140, 0.004, false);
		}
	}

	// ---- HUD ---------------------------------------------------------------------------------------------

	override void RenderOverlay(RenderEvent e)
	{
		double w = Screen.GetWidth(), h = Screen.GetHeight();
		double s = h / 400.;
		Font fnt = Font.FindFont("NewSmallFont");
		if (!fnt) fnt = smallfont;
		if (flashTics > 0) Screen.Dim(flashColor, 0.03 * flashTics, 0, 0, int(w), int(h));
		// Dash: speed lines rushing from the edges toward the centre, and the word itself.
		if (dashTics > 0)
		{
			double a = dashTics / double(DASH_TICS);
			for (int i = 0; i < 28; i++)
			{
				double ang = i * (360. / 28) + (level.maptime * 37 + i * 53) % 9;
				double r0 = h * (0.34 + ((i * 7 + level.maptime * 3) % 10) * 0.012);
				double r1 = h * 0.95;
				Screen.DrawThickLine(int(w / 2 + cos(ang) * r0 * 1.6), int(h / 2 + sin(ang) * r0), int(w / 2 + cos(ang) * r1 * 1.6), int(h / 2 + sin(ang) * r1),
					max(2., 4 * s), i % 3 ? Color(255, 255, 255) : Color(255, 140, 200), int(200 * a));
			}
		}

		// Strawberries (top left): the icon, the count, the current goal.
		TextureID berry = TexMan.CheckForTexture("SBRYA0", TexMan.Type_Sprite);
		Screen.Dim(Color(15, 10, 30), 0.55, int(8 * s), int(8 * s), int(250 * s), int(84 * s));
		Screen.DrawTexture(berry, false, 14 * s, 12 * s, DTA_DestWidthF, 34 * s, DTA_DestHeightF, 37 * s, DTA_TopOffset, 0, DTA_LeftOffset, 0);
		Screen.DrawText(fnt, Font.CR_WHITE, 54 * s, 18 * s, String.Format("x %d", berries), DTA_ScaleX, s * 1.6, DTA_ScaleY, s * 1.6);
		String goal = Objective();
		Screen.DrawText(fnt, Font.CR_GOLD, 14 * s, 54 * s, goal, DTA_ScaleX, s * 1.15, DTA_ScaleY, s * 1.15);

		// Dash pip: the climber's hair, red with a dash ready, blue once it is spent.
		Color hair = hasDash ? Color(255, 220, 50, 70) : Color(255, 70, 150, 255);
		Screen.Dim(hair, 1.0, int(14 * s), int(70 * s), int(14 * s), int(14 * s));
		Screen.DrawText(fnt, hasDash ? Font.CR_RED : Font.CR_LIGHTBLUE, 34 * s, 72 * s, hasDash ? "DASH READY  (F)" : "DASH USED - LAND TO RECHARGE", DTA_ScaleX, s, DTA_ScaleY, s);

		// Minecraft XP bar (bottom centre) with the level number above it.
		int lvl = xp / 10;
		double frac = (xp % 10) / 10.;
		double bw = 300 * s, bh = 7 * s, bx = (w - bw) / 2, by = h - 52 * s;
		Screen.Dim(Color(20, 20, 20), 0.85, int(bx - s), int(by - s), int(bw + 2 * s), int(bh + 2 * s));
		Screen.Dim(Color(50, 70, 20), 1.0, int(bx), int(by), int(bw), int(bh));
		if (frac > 0) Screen.Dim(Color(128, 255, 32), 1.0, int(bx), int(by), int(bw * frac), int(bh));
		for (int i = 1; i < 18; i++) Screen.Dim(Color(20, 20, 20), 0.8, int(bx + bw * i / 18.), int(by), int(max(1, s)), int(bh));
		if (lvl > 0)
		{
			String l = String.Format("%d", lvl);
			Screen.DrawText(fnt, Font.CR_GREEN, (w - fnt.StringWidth(l) * s) / 2, by - 18 * s, l, DTA_ScaleX, s, DTA_ScaleY, s);
		}

		// Chapter card at the start of each map.
		if (titleTics > 0)
		{
			double a = min(1., titleTics / 35.) * min(1., (35 * 5 - titleTics) / 15.);
			Screen.Dim(Color(30, 10, 50), 0.55 * a, 0, int(h * 0.11), int(w), int(h * 0.21));
			String t1 = String.Format("CHAPTER %d", max(1, level.levelnum));
			String t2 = "The Cube Mountain";
			String t3 = "The SuperIntelligent Cat turned the mountain into blocks. Collect strawberries. Outsmart the cat.";
			double s2 = s * 2.2;
			Screen.DrawText(fnt, Font.CR_PURPLE, (w - fnt.StringWidth(t1) * s * 1.5) / 2, h * 0.125, t1, DTA_ScaleX, s * 1.5, DTA_ScaleY, s * 1.5, DTA_Alpha, a);
			Screen.DrawText(fnt, Font.CR_WHITE, (w - fnt.StringWidth(t2) * s2) / 2, h * 0.17, t2, DTA_ScaleX, s2, DTA_ScaleY, s2, DTA_Alpha, a);
			Screen.DrawText(fnt, Font.CR_LIGHTBLUE, (w - fnt.StringWidth(t3) * s) / 2, h * 0.27, t3, DTA_ScaleX, s, DTA_ScaleY, s, DTA_Alpha, a);
		}

		if (heartTics > 0)
		{
			String c1 = "CHAPTER COMPLETE";
			double s3 = s * 2.6;
			Screen.DrawText(fnt, Font.CR_LIGHTBLUE, (w - fnt.StringWidth(c1) * s3) / 2, h * 0.30, c1, DTA_ScaleX, s3, DTA_ScaleY, s3);
			String c2 = String.Format("Strawberries %d   Winged %d   Kills %d", berries, winged, kills);
			Screen.DrawText(fnt, Font.CR_WHITE, (w - fnt.StringWidth(c2) * s * 1.4) / 2, h * 0.40, c2, DTA_ScaleX, s * 1.4, DTA_ScaleY, s * 1.4);
		}

		// Subtitles: the cat speaks with its portrait, typewriter style like the mountain's dialogue boxes.
		if (sayTics > 0)
		{
			int shown = min(sayLen, (level.maptime - sayAt) * 2);
			String txt = sayText.Left(shown);
			double bx2 = w * 0.18, by2 = h * 0.70, bw2 = w * 0.64, bh2 = 64 * s;
			Screen.Dim(Color(15, 10, 30), 0.8, int(bx2), int(by2), int(bw2), int(bh2));
			double tx = bx2 + 12 * s;
			if (sayCat)
			{
				TextureID face = TexMan.CheckForTexture("BCATA1", TexMan.Type_Sprite);
				if (face.IsValid()) Screen.DrawTexture(face, false, bx2 + 4 * s, by2 + 8 * s, DTA_DestWidthF, 64 * s, DTA_DestHeightF, 50 * s, DTA_TopOffset, 0, DTA_LeftOffset, 0);
				tx = bx2 + 74 * s;
				Screen.DrawText(fnt, Font.CR_PURPLE, tx, by2 + 8 * s, "THE SUPERINTELLIGENT CAT", DTA_ScaleX, s, DTA_ScaleY, s);
			}
			BrokenLines lines = fnt.BreakLines(txt, int((bw2 - (tx - bx2) - 12 * s) / (s * 1.3)));
			for (int i = 0; i < lines.Count() && i < 3; i++)
				Screen.DrawText(fnt, Font.CR_WHITE, tx, by2 + (sayCat ? 22 : 12) * s + i * 12 * s * 1.3, lines.StringAt(i), DTA_ScaleX, s * 1.3, DTA_ScaleY, s * 1.3);
		}
	}

	ui String Objective()
	{
		if (chapterDone) return "Chapter complete!";
		if (bossDead) return "Grab the Crystal Heart";
		if (bossSpawned) return "Outsmart the SuperIntelligent Cat";
		if (berryGoal > 0) return String.Format("Collect strawberries: %d/%d", min(berries, berryGoal), berryGoal);
		return "Explore the Cube Mountain";
	}
}
