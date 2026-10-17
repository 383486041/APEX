class_name ApexLobbyArt
extends RefCounted
## Procedural Graphic Texture & Banner Generator for Apex Outlands Lobby.
## Replaces amateur text ribbons with authentic AAA illustrated cards,
## map banners, vector icons, and seasonal graphic art.

static func create_kings_canyon_banner(w: int = 380, h: int = 140) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var col_sky_top := Color("#0f172a")
	var col_sky_mid := Color("#7c2d12")
	var col_sky_bot := Color("#ea580c")
	var col_horizon := Color("#fde047")

	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)
			# Sky gradient
			var sky: Color
			if v < 0.45:
				sky = col_sky_top.lerp(col_sky_mid, v / 0.45)
			elif v < 0.70:
				sky = col_sky_mid.lerp(col_sky_bot, (v - 0.45) / 0.25)
			else:
				sky = col_sky_bot.lerp(col_horizon, (v - 0.70) / 0.30)

			# Sun / Repulsor energy glow at (0.75, 0.40)
			var dx: float = u - 0.75
			var dy: float = (v - 0.38) * (float(h) / float(w))
			var sun_dist: float = sqrt(dx * dx + dy * dy)
			if sun_dist < 0.28:
				var s_int: float = clampf(1.0 - (sun_dist / 0.28), 0.0, 1.0)
				sky = sky.lerp(Color(1.0, 0.95, 0.75, 1.0), s_int * 0.75)

			# Mountain ridges (Distance layer)
			var mtn1_h: float = 0.48 + sin(u * 7.5 + 1.2) * 0.08 + sin(u * 14.0) * 0.04
			if v > mtn1_h:
				sky = Color("#431407").lerp(Color("#1e1b4b"), 0.3)

			# Midground Kings Canyon Sandstone Mesas
			var mtn2_h: float = 0.58 + sin(u * 4.8) * 0.12 + cos(u * 11.2) * 0.05
			# Notch / canyon cleft at u ~ 0.45
			if absf(u - 0.42) < 0.10:
				mtn2_h += 0.16 * (1.0 - absf(u - 0.42) / 0.10)
			if v > mtn2_h:
				var rock_fac: float = clampf((v - mtn2_h) * 4.0, 0.0, 1.0)
				var strata: float = sin(v * 45.0) * 0.08
				var rock_col := Color("#7c2d12").lerp(Color("#9a3412"), strata + 0.1)
				sky = rock_col

			# Foreground canyon cliff on the right
			var cliff_edge: float = 0.65 + (u - 0.5) * 0.45 + sin(u * 20.0) * 0.02
			if u > 0.55 and v > cliff_edge:
				sky = Color("#27120a")

			# Repulsor Antenna Tower Silhouette at u = 0.28
			if absf(u - 0.28) < 0.012 and v > 0.25 and v < 0.70:
				sky = Color("#0f172a") # Tower spire
			if absf(u - 0.28) < 0.038 and absf(v - 0.35) < 0.012:
				sky = Color("#0f172a") # Cross strut 1
			if absf(u - 0.28) < 0.055 and absf(v - 0.48) < 0.015:
				sky = Color("#0f172a") # Cross strut 2

			# Dropship Jet Contrail in sky
			var trail_y: float = 0.22 + (u - 0.1) * 0.12
			var d_trail: float = absf(v - trail_y)
			if u > 0.10 and u < 0.65 and d_trail < 0.018:
				var t_fade: float = (u - 0.10) / 0.55
				sky = sky.lerp(Color(1.0, 0.6, 0.2, 0.9), (1.0 - d_trail / 0.018) * t_fade * 0.8)

			# Bottom dark vignette gradient (gives UI text clear contrast)
			var bottom_fade: float = clampf((v - 0.55) / 0.45, 0.0, 1.0)
			sky = sky.lerp(Color(0.02, 0.04, 0.08, 0.96), bottom_fade * 0.85)

			# Subtle sci-fi scanline overlay
			if y % 3 == 0:
				sky = sky.darkened(0.08)

			img.set_pixel(x, y, sky)

	return ImageTexture.create_from_image(img)

static func create_firing_range_banner(w: int = 380, h: int = 140) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var col_bg_top := Color("#030712")
	var col_bg_bot := Color("#0f172a")
	var col_grid := Color("#06b6d4")
	var col_accent := Color("#10b981")

	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)
			var base_col: Color = col_bg_top.lerp(col_bg_bot, v)

			# Perspective 3D Grid lines at bottom
			if v > 0.48:
				var g_v: float = (v - 0.48) / 0.52
				# Radial perspective lines originating from (0.50, 0.48)
				var rad_dx: float = (u - 0.50) / maxf(0.01, g_v)
				if absf(fmod(absf(rad_dx * 3.5), 1.0)) < 0.08:
					base_col = base_col.lerp(col_grid, 0.45 * g_v)
				# Horizontal depth lines
				var exp_y: float = pow(g_v, 0.65) * 8.0
				if absf(fmod(exp_y, 1.0)) < 0.12:
					base_col = base_col.lerp(col_grid, 0.40 * g_v)

			# Holographic Bullseye Target in Center (0.50, 0.38)
			var t_dx: float = (u - 0.50) * (float(w) / float(h))
			var t_dy: float = v - 0.36
			var t_dist: float = sqrt(t_dx * t_dx + t_dy * t_dy)
			# Outer ring
			if absf(t_dist - 0.22) < 0.015:
				base_col = base_col.lerp(col_accent, 0.85)
			# Mid ring
			elif absf(t_dist - 0.14) < 0.014:
				base_col = base_col.lerp(col_grid, 0.90)
			# Bullseye dot
			elif t_dist < 0.045:
				base_col = base_col.lerp(Color("#ef4444"), 0.95)
			# Crosshair lines
			if (absf(t_dx) < 0.006 and absf(t_dy) < 0.26) or (absf(t_dy) < 0.006 and absf(t_dx) < 0.26):
				base_col = base_col.lerp(col_grid, 0.75)

			# Holographic Dummy Combat Silhouettes on Left & Right
			var d1_dx: float = absf(u - 0.22)
			var d2_dx: float = absf(u - 0.78)
			if (d1_dx < 0.025 or d2_dx < 0.025) and v > 0.28 and v < 0.65:
				base_col = base_col.lerp(Color(0.2, 0.8, 1.0, 0.7), 0.55)

			# Bottom dark vignette
			var bottom_fade: float = clampf((v - 0.55) / 0.45, 0.0, 1.0)
			base_col = base_col.lerp(Color(0.02, 0.04, 0.08, 0.96), bottom_fade * 0.85)

			if y % 3 == 0:
				base_col = base_col.darkened(0.08)

			img.set_pixel(x, y, base_col)

	return ImageTexture.create_from_image(img)

static func create_season_hub_banner(w: int = 340, h: int = 150) -> ImageTexture:
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	var col_dark := Color("#090d16")
	var col_amber := Color("#d97706")
	var col_gold := Color("#fbbf24")
	var col_crimson := Color("#b91c1c")

	for y in range(h):
		var v: float = float(y) / float(h)
		for x in range(w):
			var u: float = float(x) / float(w)
			var c: Color = col_dark

			# Dynamic diagonal speed bands (Season 20 Breakthrough theme)
			var diag: float = u * 1.5 - v * 0.8
			var band: float = fmod(absf(diag * 4.0), 1.0)
			if band < 0.35:
				c = c.lerp(Color("#1e1b4b"), 0.5)

			# Glowing golden chevron slash across top right
			var slash_dist: float = absf((u * 1.2 + v * 0.6) - 1.0)
			if slash_dist < 0.06:
				c = c.lerp(col_gold, (1.0 - slash_dist / 0.06) * 0.85)
			elif slash_dist < 0.14:
				c = c.lerp(col_amber, (1.0 - slash_dist / 0.14) * 0.45)

			# Apex Flame / Breakthrough Crest in Center Right (u ~ 0.75, v ~ 0.45)
			var c_dx: float = (u - 0.72) * (float(w) / float(h))
			var c_dy: float = v - 0.45
			var c_dist: float = sqrt(c_dx * c_dx + c_dy * c_dy)
			if c_dist < 0.30:
				var glow: float = (1.0 - c_dist / 0.30)
				c = c.lerp(col_crimson, glow * 0.6)

			# Vignette on edges
			var edge_v: float = maxf(absf(u - 0.5) * 2.0, absf(v - 0.5) * 2.0)
			if edge_v > 0.7:
				c = c.lerp(Color("#030712"), (edge_v - 0.7) / 0.3 * 0.75)

			img.set_pixel(x, y, c)

	return ImageTexture.create_from_image(img)

static func create_apex_logo_texture(size: int = 64) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half: float = float(size) * 0.5
	var col_red := Color("#ef4444")
	var col_orange := Color("#f97316")

	for y in range(size):
		for x in range(size):
			var px: float = float(x) - half
			var py: float = float(y) - half
			var u: float = px / half
			var v: float = py / half

			# Stylized Apex Chevron: Triangle with angled cleft
			# Top vertex at (0, -0.75), bottom-left (-0.7, 0.75), bottom-right (0.7, 0.75)
			# Inner cleft cutting from bottom up to (0, -0.1)
			var in_outer_tri: bool = (v <= 0.75) and (v >= -0.75 + absf(u) * 2.1)
			var in_inner_cleft: bool = (v >= -0.10 + absf(u) * 1.6) and (v <= 0.85) and (absf(u) < 0.45)
			# Central horizontal slot
			var in_slot: bool = (absf(v - 0.08) < 0.08) and (absf(u) < 0.55)

			if in_outer_tri and not in_inner_cleft and not in_slot:
				var grad: float = clampf((v + 0.75) / 1.5, 0.0, 1.0)
				var c: Color = col_orange.lerp(col_red, grad)
				img.set_pixel(x, y, c)
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(img)

static func create_currency_icon(type: String, size: int = 24) -> ImageTexture:
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var half: float = float(size) * 0.5

	for y in range(size):
		for x in range(size):
			var dx: float = (float(x) - half) / half
			var dy: float = (float(y) - half) / half
			var dist: float = sqrt(dx * dx + dy * dy)

			if type == "coins":
				# Gold Apex Coin with rim & inner chevron
				if dist <= 0.88:
					if dist > 0.72:
						img.set_pixel(x, y, Color("#f59e0b")) # Outer rim
					elif dist > 0.65:
						img.set_pixel(x, y, Color("#78350f")) # Inset shadow
					else:
						# Coin face with inner embossed 'A'
						var in_a: bool = (absf(dx) < 0.25 and absf(dy) < 0.40) and not (absf(dx) < 0.12 and dy < 0.10 and dy > -0.20)
						img.set_pixel(x, y, Color("#fde047") if in_a else Color("#eab308"))
				else:
					img.set_pixel(x, y, Color(0, 0, 0, 0))

			elif type == "metals":
				# Sky-blue Hexagonal Crafting Nut / Metal
				var angle: float = atan2(dy, dx)
				var hex_radius: float = 0.82 / (cos(fmod(absf(angle), PI / 3.0) - PI / 6.0))
				if dist <= hex_radius:
					if dist < 0.35:
						img.set_pixel(x, y, Color(0, 0, 0, 0)) # Center hole
					elif dist > hex_radius * 0.82:
						img.set_pixel(x, y, Color("#0284c7")) # Bevel rim
					else:
						img.set_pixel(x, y, Color("#38bdf8")) # Blue steel body
				else:
					img.set_pixel(x, y, Color(0, 0, 0, 0))

			elif type == "shards":
				# Ruby Heirloom Crystal Shard (Diamond / Octagon)
				var diamond: float = absf(dx) + absf(dy) * 0.7
				if diamond <= 0.85:
					if diamond > 0.70:
						img.set_pixel(x, y, Color("#ff1e42")) # Glowing edge
					elif dx < 0.0:
						img.set_pixel(x, y, Color("#f43f5e")) # Light facet
					else:
						img.set_pixel(x, y, Color("#be123c")) # Deep facet
				else:
					img.set_pixel(x, y, Color(0, 0, 0, 0))

			elif type == "pack_tick":
				# Triangular Pack Loot Tick silhouette
				var tri_in: bool = (dy <= 0.75) and (dy >= -0.75 + absf(dx) * 1.5)
				if tri_in:
					if absf(dx) < 0.15 and absf(dy - 0.2) < 0.15:
						img.set_pixel(x, y, Color("#ff1e42")) # Red light eye
					else:
						img.set_pixel(x, y, Color("#f8fafc")) # White ceramic armor
				else:
					img.set_pixel(x, y, Color(0, 0, 0, 0))

			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(img)
