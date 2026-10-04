// Blockification: every map becomes Minecraft-style blocks under a Celeste night sky.
// Each original texture maps to one block type (hashed by name), so a level keeps its look and landmarks.
class SicWorld : EventHandler
{
	const BLOCK_SCALE = 8.0; // 256 px textures (16 px art x16) drawn as 32-unit blocks: crisp pixels, the player stands about two blocks tall

	static const String WALL_STONE[] = { "MCSTONE", "MCCOBBLE", "MCSTBRK", "MCMOSSY", "MCCOBBLE", "MCSTONE" };
	static const String WALL_ORE[]   = { "MCCOALO", "MCIRONO", "MCGOLDO", "MCDIAMO", "MCMESEO", "MCCOALO", "MCIRONO" };
	static const String WALL_WOOD[]  = { "MCPLANK", "MCLOG", "MCPLANK2", "MCBOOKS", "MCPLANK3" };
	static const String WALL_TECH[]  = { "MCFURN", "MCBOOKS", "MCCHEST", "MCFURNON", "MCOBSID", "MCSTBRK" };
	static const String WALL_MISC[]  = { "MCBRICK", "MCSTBRK", "MCSANDST", "MCCOBBLE", "MCPLANK", "MCMOSSY", "MCSTONE", "MCLOG", "MCBOOKS" };
	static const String FLOOR_IN[]   = { "MCPLANK", "MCPLANK2", "MCCOBBLE", "MCSTBRK", "MCSTONE", "MCSANDST", "MCGRAVEL", "MCPLANK3" };
	static const String CEIL_IN[]    = { "MCPLANK", "MCSTONE", "MCLOGTOP", "MCSTBRK", "MCPLANK2", "MCCOBBLE" };

	TextureID sky, skyFlat;

	override void WorldLoaded(WorldEvent e)
	{
		skyFlat = TexMan.CheckForTexture("F_SKY1", TexMan.Type_Any);
		TextureID cs = TexMan.CheckForTexture("CELSKY", TexMan.Type_Any);
		if (cs.IsValid()) level.ChangeSky(cs, cs);

		for (int i = 0; i < level.sectors.Size(); i++) Blockify(level.sectors[i]);

		for (int i = 0; i < level.sides.Size(); i++) BlockifySide(level.sides[i]);
	}

	static int Hash(String s)
	{
		int h = 7;
		for (int i = 0; i < s.Length(); i++) h = (h * 31 + s.ByteAt(i)) & 0xFFFFFF;
		return h;
	}

	static TextureID Tex(String name) { return TexMan.CheckForTexture(name, TexMan.Type_Any); }

	bool IsSky(TextureID t) { return t == skyFlat; }

	bool Outdoors(Sector s) { return s && IsSky(s.GetTexture(Sector.ceiling)); }

	void Blockify(Sector s)
	{
		// Readable on stream: no pitch-black rooms, Minecraft daylight feel under the night sky.
		if (s.lightlevel < 150) s.SetLightLevel(150 + (s.lightlevel / 6));
		String fl = TexMan.GetName(s.GetTexture(Sector.floor)).MakeUpper();
		String cl = TexMan.GetName(s.GetTexture(Sector.ceiling)).MakeUpper();
		SetFlat(s, Sector.floor, FloorFor(fl, s));
		if (!Outdoors(s)) SetFlat(s, Sector.ceiling, CeilFor(cl));
	}

	String FloorFor(String n, Sector s)
	{
		if (n.IndexOf("NUKAGE") >= 0 || n.IndexOf("SLIME") >= 0 || n.IndexOf("WATER") >= 0) return "MCWATER";
		if (n.IndexOf("LAVA") >= 0 || n.IndexOf("BLOOD") >= 0) return "MCLAVA";
		if (n.IndexOf("GRASS") >= 0 || n.IndexOf("GRNROCK") >= 0) return "MCGRASS";
		if (n.IndexOf("LIGHT") >= 0 || n.IndexOf("TLITE") >= 0) return "MCLAMP";
		if (Outdoors(s)) return (Hash(n) % 5) < 3 ? "MCGRASS" : "MCSNOW";
		if (n.IndexOf("RROCK") >= 0 || n.IndexOf("ROCK") >= 0 || n.IndexOf("MFLR") >= 0) return "MCGRAVEL";
		return FLOOR_IN[Hash(n) % FLOOR_IN.Size()];
	}

	String CeilFor(String n)
	{
		if (n.IndexOf("LIGHT") >= 0 || n.IndexOf("TLITE") >= 0 || n.IndexOf("CEIL1_2") >= 0 || n.IndexOf("CEIL1_3") >= 0
			|| n.IndexOf("GRNLITE") >= 0 || n.IndexOf("FLAT2") >= 0 || n.IndexOf("FLAT17") >= 0) return "MCLAMP";
		return CEIL_IN[Hash(n) % CEIL_IN.Size()];
	}

	void SetFlat(Sector s, int pos, String name)
	{
		TextureID t = Tex(name);
		if (!t.IsValid()) return;
		s.SetTexture(pos, t);
		s.SetXScale(pos, BLOCK_SCALE);
		s.SetYScale(pos, BLOCK_SCALE);
		s.SetXOffset(pos, 0);
		s.SetYOffset(pos, 0);
	}

	void BlockifySide(Side sd)
	{
		for (int part = Side.top; part <= Side.bottom; part++)
		{
			TextureID old = sd.GetTexture(part);
			if (!old.IsValid() || old.isNull()) continue;
			String n = TexMan.GetName(old).MakeUpper();
			if (n.IndexOf("SKY") >= 0) continue;
			// Switches keep their own picture: the game swaps it by name when pressed.
			if (n.Left(3) == "SW1" || n.Left(3) == "SW2") continue;
			bool twoSidedMid = part == Side.mid && sd.linedef && sd.linedef.sidedef[1];
			String b = twoSidedMid ? MidFor(n) : WallFor(n, sd, part);
			if (b == "") continue;
			TextureID t = Tex(b);
			if (!t.IsValid()) continue;
			sd.SetTexture(part, t);
			sd.SetTextureXScale(part, b.Left(6) == "MCDOOR" ? 4.0 : BLOCK_SCALE);
			sd.SetTextureYScale(part, b.Left(6) == "MCDOOR" ? 4.0 : BLOCK_SCALE);
			sd.SetTextureXOffset(part, 0);
			sd.SetTextureYOffset(part, 0);
		}
	}

	String MidFor(String n)
	{
		if (n.IndexOf("MID") >= 0 || n.IndexOf("GRATE") >= 0 || n.IndexOf("BARS") >= 0) return "MCGLASS";
		return "";
	}

	String WallFor(String n, Side sd, int part)
	{
		if (n.IndexOf("EXIT") >= 0) return "MCTNT";
		if (n.Left(7) == "BIGDOOR" || n.IndexOf("DOOR") >= 0) return (Hash(n) & 1) ? "MCDOOR" : "MCDOOR2";
		if (n.IndexOf("LITE") >= 0 || n.IndexOf("LIGHT") >= 0) return "MCLAMP";
		if (n.IndexOf("WOOD") >= 0 || n.IndexOf("PANEL") >= 0) return WALL_WOOD[Hash(n) % WALL_WOOD.Size()];
		if (n.IndexOf("COMP") >= 0 || n.IndexOf("TEK") >= 0 || n.IndexOf("SPACE") >= 0 || n.IndexOf("PLAT") >= 0)
			return WALL_TECH[Hash(n) % WALL_TECH.Size()];
		if (n.IndexOf("BRICK") >= 0) return (Hash(n) & 1) ? "MCBRICK" : "MCSTBRK";
		if (n.IndexOf("MARB") >= 0 || n.IndexOf("SKIN") >= 0 || n.IndexOf("FIRE") >= 0 || n.IndexOf("GST") >= 0) return "MCOBSID";
		// Walls facing the open air: grass-topped dirt, like a Minecraft hillside.
		Sector front = sd.sector;
		if (front && Outdoors(front) && part != Side.top) return (Hash(n) % 4) ? "MCGRSID2" : "MCSNOWSD";
		if (n.IndexOf("STONE") >= 0 || n.IndexOf("ROCK") >= 0 || n.IndexOf("ASH") >= 0 || n.IndexOf("CAVE") >= 0 || n.IndexOf("GRAY") >= 0)
		{
			// Ore veins scattered through the rock, never the same twice along a corridor.
			int r = Hash(String.Format("%s%d", n, sd.Index())) % 100;
			if (r < 14) return WALL_ORE[r % WALL_ORE.Size()];
			return WALL_STONE[Hash(n) % WALL_STONE.Size()];
		}
		int r = Hash(String.Format("%s%d", n, sd.Index())) % 100;
		if (r < 6) return WALL_ORE[r % WALL_ORE.Size()];
		return WALL_MISC[Hash(n) % WALL_MISC.Size()];
	}
}
