// Square, pixel-like particles (Minecraft poofs, block debris, Celeste sparkles).
// A white wool block as the particle texture keeps them square whatever the player's particle style is;
// the colour tints it.
class SicFX play
{
	static void Quad(Vector3 pos, Color c, double size, Vector3 vel, Vector3 accel = (0, 0, 0), int life = 20, double fade = -1, bool bright = true)
	{
		FSpawnParticleParams p;
		p.texture = TexMan.CheckForTexture("MCWOOLW", TexMan.Type_Any);
		p.color1 = c;
		p.style = STYLE_Normal;
		p.flags = bright ? SPF_FULLBRIGHT : 0;
		p.lifetime = life;
		p.size = size;
		p.sizestep = -size / (life * 1.5);
		p.pos = pos;
		p.vel = vel;
		p.accel = accel;
		p.startalpha = 1.0;
		p.fadestep = fade < 0 ? 1.0 / life : fade;
		level.SpawnParticle(p);
	}

	// Minecraft death: a puff of grey-white smoke squares rising from the body.
	static void Poof(Actor a, int n = 18)
	{
		for (int i = 0; i < n; i++)
		{
			int g = random(185, 255);
			Vector3 at = a.pos + (frandom(-a.radius, a.radius), frandom(-a.radius, a.radius), frandom(4, a.height * 0.8));
			Quad(at, Color(g, g, g), frandom(8, 14), (frandom(-1.2, 1.2), frandom(-1.2, 1.2), frandom(0.6, 2.2)), (0, 0, 0.03), random(20, 32), -1, false);
		}
	}

	// Chunks of a block flying apart (arrow hits, explosions).
	static void Debris(Vector3 pos, Color c1, Color c2, int n = 10, double speed = 4, double size = 5)
	{
		for (int i = 0; i < n; i++)
		{
			Color c = random(0, 1) ? c1 : c2;
			Quad(pos, c, frandom(size * 0.6, size * 1.3), (frandom(-speed, speed), frandom(-speed, speed), frandom(0.5, speed * 1.2)), (0, 0, -0.35), random(18, 30), 0.02, false);
		}
	}

	// Celeste sparkle: little bright squares drifting up.
	static void Sparkle(Vector3 pos, Color c, int n = 1, double spread = 8)
	{
		for (int i = 0; i < n; i++)
			Quad(pos + (frandom(-spread, spread), frandom(-spread, spread), frandom(-spread, spread)), c, frandom(2, 4), (0, 0, frandom(0.2, 0.8)), (0, 0, 0), random(12, 22));
	}

	// Celeste death-style ring: orbs flying out in a circle.
	static void Ring(Vector3 pos, Color c, int n = 12, double speed = 5, double size = 8)
	{
		for (int i = 0; i < n; i++)
		{
			double ang = i * 360. / n;
			Quad(pos, c, size, (cos(ang) * speed, sin(ang) * speed, 0), (cos(ang) * -0.12, sin(ang) * -0.12, 0), 26);
		}
	}

	static Color BlockColorAt(Actor a)
	{
		// The colour of the block an impact hit: by the sector's floor, near enough for a debris puff.
		String n = TexMan.GetName(a.floorpic);
		if (n == "MCGRASS") return Color(96, 168, 60);
		if (n == "MCSNOW") return Color(235, 240, 250);
		if (n.IndexOf("PLANK") >= 0) return Color(160, 120, 70);
		if (n == "MCSAND" || n == "MCSANDST") return Color(220, 205, 150);
		return Color(130, 130, 135);
	}
}
