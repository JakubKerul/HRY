extends Node2D
## ECHO RUN 2.0 (povodne "Ozvena")
## Kazde kolo trva 8 sekund a treba v nom zobrat 3 energie. Kazde prezite kolo
## sa potom prehrava ako ozvena, ktorej sa nesmies dotknut. Po kazdom kole si
## vyberas vylepsenie. Vsetko sa kresli v kode (ziadne obrazky), data su v data.gd.

const D = preload("res://data.gd")
const Ads = preload("res://ads.gd")

enum S { MENU, SHOP, PROFILE, SETTINGS, BASE, TREE, SCORES, INTRO, PLAY, PICK, BOSS, MERCHANT, DYING, REVIVE, OVER }

const VERSION := "2.7.1"
const VIEW := Vector2(720, 1280)
const ARENA := Rect2(30, 200, 660, 1000)
const ROUND_TIME := 8.0
const GRACE_TIME := 1.0
const PLAYER_R := 18.0
const GHOST_R := 15.0
const ORB_R := 16.0
const ORBS_NEEDED := 3
const NEAR_DIST := 24.0
const KEY_SPEED := 470.0
const TRAIL_LEN := 14
const COMBO_TIME := 2.2
const REVIVE_COST := 30
const MOUSE_SPEED := 2000.0
const DLG_LEN := 4.5
const PREVIEW_TIME := 20.0
const SENS := [1.0, 1.3, 1.65]
const SAVE_PATH := "user://ozvena_save.cfg"

const COL_ORB := Color("ffd23f")
const COL_TEXT := Color("eef1ff")
const COL_DIM := Color("8a93bd")
const COL_DANGER := Color("ff4d6d")
const COL_SHIELD := Color("6fb7ff")
const COL_COIN := Color("7df9ff")
const COL_DARK := Color("070912")
const COL_CORE := Color("ff6bf0")

# ---------------------------------------------------------------- stav
var screen: int = S.MENU
var screen_t := 0.0
var fade := 0.0
var paused := false
var daily := false
var autoplay := false
var dbg_revive := false

# kampan
var camp := false
var camp_pending := false
var camp_won := false
var auto_camp := false
var god := false
var loc := 0
var loc_round := 0
var hull := 3
var hull_max := 3
var g_cores := 0
var boss_next := false
var praise_n := 0
var sk_grace := 0.0
var sk_thin := 1.0
var sk_slow := 1.0
var sk_pts := 1.0
var sk_near := 1
var sk_combo := 0.0
var sk_inv := 0.0
var rar_w: Array = [60, 30, 10]
var b_id := 0
var b_hp := 0
var b_max := 1
var b_pos := Vector2(360, 430)
var b_from := Vector2.ZERO
var b_target := Vector2.ZERO
var b_t := 0.0
var b_cd1 := 0.0
var b_cd3 := 0.0
var b_ang := 0.0
var b_spiral := 0.0
var b_state := 0
var b_st_t := 0.0
var b_hit := 0.0
var b_dead_t := -1.0
var bullets: Array = []          # [pos, vel]
var gun_fx: Array = []           # [from, to, life]
var dlg_who := -1
var dlg_text := ""
var dlg_t := 0.0
var base_who := 0
var base_line := ""
var base_talk_t := 0.0
var m_sold: Array = [false, false, false, false]
var m_card := -1
var tree_sel := -1
var name_edit := false
var auth_field := 0
var auth_name := ""
var auth_pass := ""
var auth_msg := ""
var auth_busy := false
var auth_upper := false
var send_queue: Array = []
var http_auth: HTTPRequest
var board_url := ""
var in_discord := false
var dbg_ov := false
var dbg_n := [0, 0, 0, 0]  # snimky, dotyky, kliky mysou, pohyby
var dbg_last := Vector2(-1, -1)
var dc_wait := 0.0
var dc_poll := 0.0
var dc_auto := false
var board: Array = []
var board_state := 0             # 0 nic, 1 nacitava sa, 2 hotovo, 3 chyba
var scores_tab := 0              # 0 svet, 1 moje
var rate_mode := 0               # 0 kampan, 1 endless (vratane dennej vyzvy)
var rate_day := 0                # 0 celkovo, 1 dnes
var board_key := ""
var http_get: HTTPRequest
var http_post: HTTPRequest
var round_hits := 0
var mouse_pos := Vector2.ZERO
var mouse_live := false

# hra
var ghosts: Array[PackedVector2Array] = []
var ghost_off: Array[bool] = []
var near_done: Array[bool] = []
var recording := PackedVector2Array()
var player := Vector2.ZERO
var p_dir := Vector2.UP
var ptrail: Array[Vector2] = []
var orb := Vector2.ZERO
var orb_born := 0.0
var orbs_got := 0
var round_num := 0
var score := 0
var score_shown := 0.0
var t := 0.0
var frame := 0
var intro_t := 0.0
var intro_len := 1.3
var mod := -1
var combo := 0
var combo_t := 0.0
var invuln_t := 0.0
var spark_at := -1.0
var spark_pos := Vector2.ZERO
var spark_t := 0.0
var last_tick := 0
var up := {}
var rerolls := 0
var rerolls_used := 0
var cards: Array[int] = []
var second_used := false
var revived := false
var killer := -1
var death_reason := ""
var base_seed := 0
var record_said := false
var game_active := false
var games_since_ad := 0

# statistiky jednej hry
var g_orbs := 0
var g_near := 0
var g_combo := 0
var g_blocks := 0
var g_special := 0
var g_sparks := 0
var g_coins := 0
var g_streak_bonus := 0

# vysledky (obrazovka konca)
var over_new_best := false
var over_coins := 0
var over_lines: Array = []       # [text, farba]
var over_xp_from := 0.0
var over_xp_to := 0.0
var over_level := 1

# efekty a UI
var shake := 0.0
var flash := 0.0
var flash_col := COL_DANGER
var popups: Array = []           # [pos, text, life, col, size]
var particles: Array = []        # [pos, vel, life, col, size]
var buttons: Array = []          # [rect, id]
var pressed_id := ""
var pressed_t := 0.0
var toast := ""
var toast_t := 0.0
var shop_tab := 0
var reset_armed := 0.0
var origin := Vector2.ZERO
var vp := VIEW
var now := 0.0

var rng := RandomNumberGenerator.new()
var rng_cards := RandomNumberGenerator.new()
var sv := {}
var lang := 0
var TH: Dictionary = D.THEMES[0]

var font_b: Font
var font_m: Font
var sbox := StyleBoxFlat.new()
var sfx := {}
var players: Array[AudioStreamPlayer] = []
var next_player := 0
var music_a: AudioStreamPlayer
var music_b: AudioStreamPlayer
var music_mix := 0.0
var track_cache := {}
var cur_track := -1
var preview_i := -1
var preview_t := 0.0


func _ready() -> void:
	randomize()
	font_b = load("res://fonts/ChakraPetch-Bold.ttf")
	font_m = load("res://fonts/ChakraPetch-Medium.ttf")
	var args := OS.get_cmdline_user_args()
	autoplay = "--autoplay" in args
	auto_camp = "--camp" in args
	god = "--god" in args
	_load()
	board_url = D.BOARD_URL
	http_get = HTTPRequest.new()
	http_get.timeout = 12.0
	http_get.accept_gzip = false  # prehliadac uz rozbali sam (Discord proxy posiela gzip)
	add_child(http_get)
	http_get.request_completed.connect(_on_board)
	http_post = HTTPRequest.new()
	http_post.timeout = 12.0
	http_post.accept_gzip = false  # prehliadac uz rozbali sam (Discord proxy posiela gzip)
	add_child(http_post)
	http_post.request_completed.connect(_on_board_sent)
	http_auth = HTTPRequest.new()
	http_auth.timeout = 15.0
	http_auth.accept_gzip = false  # prehliadac uz rozbali sam (Discord proxy posiela gzip)
	add_child(http_auth)
	http_auth.request_completed.connect(_on_auth)
	if OS.has_feature("web"):
		# Discord Activity: siet ide len cez Discord proxy (/.proxy/gas -> script.google.com)
		in_discord = bool(JavaScriptBridge.eval("!!window.__inDiscord", true))
		if in_discord and board_url.begins_with("https://script.google.com"):
			board_url = str(JavaScriptBridge.eval("location.origin", true)) + "/.proxy/gas" + board_url.substr("https://script.google.com".length())
		if in_discord and not _logged_in() and not bool(sv.get("dc_skip", false)):
			_dc_login(true)
		dbg_ov = bool(JavaScriptBridge.eval("location.search.indexOf('dbg') >= 0", true))
		autoplay = autoplay or bool(JavaScriptBridge.eval("location.search.indexOf('autoplay') >= 0", true))
		if OS.is_debug_build() and bool(JavaScriptBridge.eval("location.search.indexOf('coins') >= 0", true)):
			sv.coins = 5000
			sv.cores = 60
			if bool(JavaScriptBridge.eval("location.search.indexOf('mock') >= 0", true)):
				board_url = "http://localhost:8766/"
			dbg_revive = true
		auto_camp = bool(JavaScriptBridge.eval("location.search.indexOf('camp') >= 0", true))
		if OS.is_debug_build() and bool(JavaScriptBridge.eval("location.search.indexOf('god') >= 0", true)):
			god = true
		if bool(JavaScriptBridge.eval("location.search.indexOf('lang=en') >= 0", true)):
			lang = 1
	if "--en" in args:
		lang = 1
	_apply_theme()
	_make_sounds()
	_refresh_music()
	_fill_missions()
	if autoplay:
		if auto_camp:
			_start_campaign()
		else:
			start_game("--daily" in args)


# ================================================================ HRA

func start_game(is_daily: bool) -> void:
	daily = is_daily
	g_streak_bonus = 0
	if daily:
		base_seed = hash("ozvena-" + _today())
		_touch_daily()
	else:
		base_seed = randi()
	ghosts.clear()
	round_num = 0
	score = 0
	score_shown = 0.0
	up = {}
	rerolls = 1
	rerolls_used = 0
	second_used = false
	revived = false
	combo = 0
	combo_t = 0.0
	invuln_t = 0.0
	record_said = false
	g_orbs = 0
	g_near = 0
	g_combo = 0
	g_blocks = 0
	g_special = 0
	g_sparks = 0
	g_coins = 0
	popups.clear()
	particles.clear()
	paused = false
	game_active = true
	fade = 0.6
	camp = camp_pending
	camp_pending = false
	hull = 1
	hull_max = 1
	_reset_skills()
	boss_next = false
	bullets.clear()
	gun_fx.clear()
	dlg_t = 0.0
	if camp:
		_camp_setup()
	else:
		_apply_theme()
	_play("start")
	Ads.gameplay_start()
	_start_intro(false)


func _start_intro(repeat: bool) -> void:
	if not repeat:
		round_num += 1
		if camp:
			loc_round += 1
	rng.seed = hash([base_seed, round_num])
	mod = -1
	if camp:
		mod = _loc_mod()
	elif round_num >= 5 and round_num % 5 == 0:
		mod = rng.randi_range(0, D.MODS.size() - 1)
	screen = S.INTRO
	screen_t = 0.0
	intro_t = 0.0
	intro_len = 1.3
	if (mod >= 0 and not camp) or (camp and loc_round == 1 and not repeat):
		intro_len = 2.6
	elif not bool(sv.tut) and round_num <= 3:
		intro_len = 2.8
	ghost_off.resize(ghosts.size())
	ghost_off.fill(false)
	near_done.resize(ghosts.size())
	near_done.fill(false)
	player = _spawn_point()
	ptrail.clear()
	recording = PackedVector2Array()
	orbs_got = 0
	invuln_t = 0.0
	spark_at = rng.randf_range(1.5, 5.0) if rng.randf() < (1.0 if camp and _sk("spark") else 0.6) else -1.0
	spark_t = 0.0
	if mod >= 0 and (not camp or loc_round == 1):
		_play("special")
	boss_next = false
	round_hits = 0
	if camp and int(sv.camp_runs) == 0 and loc == 0 and not repeat:
		if loc_round == 1:
			_say(0, "vex_r1")
		elif loc_round == 2:
			_say(0, "vex_r2")


func _start_round() -> void:
	screen = S.PLAY
	mouse_live = false
	t = 0.0
	frame = 0
	last_tick = 0
	combo = 0
	combo_t = 0.0
	orb = _next_orb(player)
	orb_born = now


func _end_round() -> void:
	if orbs_got < ORBS_NEEDED:
		if camp:
			# v kampani nedostatok energie stoji trup, nie cely zivot
			invuln_t = 0.0
			_hull_hit(L("need_energy") % [orbs_got, ORBS_NEEDED], -1)
			if screen == S.DYING:
				return
		else:
			_die(L("need_energy") % [orbs_got, ORBS_NEEDED], -1)
			return
	var bonus := round_num * 2 * (2 if _mod_id() == "gold" else 1)
	score += bonus
	_popup(player + Vector2(0, -46), L("round_bonus") % bonus, _pcol(), 34)
	if mod >= 0:
		g_special += 1
	g_coins += _up("coins")
	if round_num % 5 == 0:
		g_coins += 10
		_popup(ARENA.get_center(), L("milestone") % round_num, COL_ORB, 46)
		_burst(ARENA.get_center(), COL_ORB, 40, 520.0)
		_play("level")
	else:
		_play("round")
	if camp:
		g_cores += 1
		praise_n += 1
	ghosts.append(recording)
	_log("kolo %d prezite, skore %d, ozvien %d%s" % [round_num, score, ghosts.size(), (" [" + _mod_id() + "]") if mod >= 0 else ""])
	_start_pick()


func _start_pick() -> void:
	screen = S.PICK
	screen_t = 0.0
	if camp:
		# po kazdom kole sa jedna z radkyn ozve (vyskoci vpravo dole, titulky su dole)
		if int(sv.camp_runs) == 0 and round_num == 1:
			_say(0, "vex_pick")
		elif round_hits > 0:
			_say(2, "riot_after", hull)
		elif combo >= 5:
			_say(1, "nova_combo")
		elif praise_n % 2 == 0:
			_say(1, "nova_%d" % (1 + randi() % 5))
		else:
			_say(0, "vex_tip%d" % (1 + randi() % 4))
	_roll_cards()


func _roll_cards() -> void:
	rng_cards.seed = hash([base_seed, round_num, rerolls_used, "cards"])
	var pool: Array[int] = []
	for i in D.UPG.size():
		var u: Dictionary = D.UPG[i]
		var id: String = u.id
		if _up(id) >= int(u.max):
			continue
		if id == "erase" and ghosts.size() < 3:
			continue
		if id == "second" and second_used:
			continue
		pool.append(i)
	cards.clear()
	while cards.size() < 3 and not pool.is_empty():
		var total := 0
		for i in pool:
			total += int(rar_w[int(D.UPG[i].r)])
		var roll := rng_cards.randi_range(0, total - 1)
		for i in pool:
			roll -= int(rar_w[int(D.UPG[i].r)])
			if roll < 0:
				cards.append(i)
				pool.erase(i)
				break


func _apply_pick(slot: int) -> void:
	if slot >= cards.size():
		return
	var u: Dictionary = D.UPG[cards[slot]]
	var id: String = u.id
	match id:
		"erase":
			if not ghosts.is_empty():
				ghosts.pop_front()
		"reroll":
			rerolls += 2
			up[id] = _up(id) + 1
		_:
			up[id] = _up(id) + 1
	_log("vylepsenie: %s" % str(u.n[0]))
	_play("pick")
	_vibrate(20)
	if camp and loc_round >= int(D.LOCS[loc].rounds):
		_start_boss_intro(mini(loc, D.BOSSES.size() - 1))
	elif not camp and round_num % 5 == 0:
		# endless a denna vyzva: po kazdom 5. kole nahodny boss (v dennej vyzve rovnaky pre vsetkych)
		var br := RandomNumberGenerator.new()
		br.seed = hash([base_seed, round_num, "boss"])
		_start_boss_intro(br.randi_range(0, D.BOSSES.size() - 1))
	else:
		_start_intro(false)


func _die(reason: String, by: int) -> void:
	if _up("second") > 0 and not second_used:
		second_used = true
		up["second"] = 0
		flash = 0.8
		flash_col = COL_ORB
		_burst(player, COL_ORB, 30, 420.0)
		_popup(ARENA.get_center(), L("second_pop"), COL_ORB, 52)
		_play("revive")
		_log("druhy dych")
		hull = maxi(hull, 1)
		if screen == S.BOSS:
			_start_boss_intro(b_id)
		else:
			_start_intro(true)
		return
	screen = S.DYING
	screen_t = 0.0
	death_reason = reason
	killer = by
	combo = 0
	shake = 26.0
	flash = 1.0
	flash_col = COL_DANGER
	_burst(player, COL_DANGER, 36, 460.0)
	_burst(player, _pcol(), 18, 300.0)
	_play("die")
	_vibrate(180)
	if camp:
		_say(2, "riot_dead")
	_log("SMRT: %s | kolo %d, skore %d" % [reason, round_num, score])


func _revive() -> void:
	revived = true
	hull = maxi(hull, 1)
	flash = 0.7
	flash_col = _pcol()
	_play("revive")
	_start_intro(true)


func _finish_game() -> void:
	if not game_active:
		return
	game_active = false
	Ads.gameplay_stop()
	games_since_ad += 1
	var rounds := round_num - 1
	over_lines.clear()
	over_new_best = false
	if camp:
		_camp_finish()
	elif daily:
		if score > int(sv.daily_best):
			sv.daily_best = score
			over_new_best = score > 0
		sv.history[_today()] = int(sv.daily_best)
	elif score > int(sv.best):
		sv.best = score
		over_new_best = true
	# statistiky
	var st: Dictionary = sv.st
	st.games = int(st.games) + 1
	st.rounds = int(st.rounds) + rounds
	st.best_round = maxi(int(st.best_round), rounds)
	st.orbs = int(st.orbs) + g_orbs
	st.near = int(st.near) + g_near
	st.combo = maxi(int(st.combo), g_combo)
	st.best_any = maxi(int(st.get("best_any", 0)), score)
	# iskry
	over_coins = g_coins + rounds + int(score / 60.0)
	if camp:
		over_coins = int(over_coins * (1.0 + 0.2 * int(_sk("sp1")) + 0.2 * int(_sk("sp2"))))
	if g_streak_bonus > 0:
		over_coins += g_streak_bonus
		over_lines.append([L("streak_bonus") % [int(sv.streak), g_streak_bonus], COL_ORB])
	# misie
	var vals := {"rounds": rounds, "score": score, "orbs": g_orbs, "near": g_near, "combo": g_combo,
		"games": 1, "daily": 1 if daily else 0, "blocks": g_blocks, "special": g_special, "sparks": g_sparks}
	var missions: Array = sv.missions
	var kept: Array = []
	for i in missions.size():
		var m: Dictionary = missions[i]
		var v: int = int(vals.get(m.t, 0))
		if bool(m.cum):
			m.prog = int(m.prog) + v
		else:
			m.prog = maxi(int(m.prog), v)
		if int(m.prog) >= int(m.target):
			over_coins += int(m.rew)
			over_lines.append([L("mission_done") % int(m.rew), _acc()])
			sv.tiers[m.t] = int(sv.tiers.get(m.t, 0)) + 1
		else:
			kept.append(m)
	sv.missions = kept
	_fill_missions()
	# skusenosti
	var xp_gain := int(score / 4.0) + rounds * 5
	over_xp_from = float(sv.xp) / _xp_need(int(sv.level))
	sv.xp = int(sv.xp) + xp_gain
	while int(sv.xp) >= _xp_need(int(sv.level)):
		sv.xp = int(sv.xp) - _xp_need(int(sv.level))
		sv.level = int(sv.level) + 1
		var rew := 15 + 5 * int(sv.level)
		over_coins += rew
		over_lines.append([L("level_up") % [int(sv.level), rew], COL_ORB])
		over_xp_from = 0.0
	over_xp_to = float(sv.xp) / _xp_need(int(sv.level))
	over_level = int(sv.level)
	sv.coins = int(sv.coins) + over_coins
	if rounds >= 2:
		sv.tut = true
	_log_score()
	_save()
	_log("KONIEC: kolo %d, skore %d, iskry +%d, uroven %d%s" % [round_num, score, over_coins, int(sv.level), (" | kampan lok %d, jadra %d, vyhra %s" % [loc + 1, int(sv.cores), str(camp_won)]) if camp else ""])


func _physics_process(delta: float) -> void:
	if paused:
		return
	screen_t += delta
	match screen:
		S.INTRO:
			intro_t += delta
			if intro_t >= intro_len:
				if boss_next:
					_start_boss()
				else:
					_start_round()
		S.PLAY:
			_tick_play(delta)
		S.PICK:
			if autoplay and screen_t > (1.6 if OS.has_feature("web") else 0.3):
				_apply_pick(randi() % maxi(cards.size(), 1))
		S.BOSS:
			_tick_boss(delta)
		S.MERCHANT:
			if autoplay and screen_t > (2.5 if OS.has_feature("web") else 0.3):
				if screen_t < 50.0 and not m_sold[0] and hull < hull_max and int(sv.coins) >= _m_price(0):
					_merchant_buy(0)
				_merchant_continue()
		S.DYING:
			if screen_t > 1.1:
				var can_pay := int(sv.coins) >= REVIVE_COST or Ads.rewarded_available()
				if not camp and not revived and can_pay and round_num >= 3 and (not autoplay or dbg_revive):
					screen = S.REVIVE
					screen_t = 0.0
				else:
					_to_over()
		S.REVIVE:
			if autoplay and screen_t > 2.5:
				_click("revive")
			elif screen_t > 6.0:
				_to_over()
		S.OVER:
			if autoplay and screen_t > 4.0 and OS.has_feature("web"):
				if camp:
					_start_campaign()
				else:
					start_game(daily)


func _to_over() -> void:
	_finish_game()
	screen = S.OVER
	screen_t = 0.0
	fade = 0.5
	if over_new_best:
		_play("level")


func _tick_play(delta: float) -> void:
	_steer(delta)
	t += delta
	recording.append(player)
	var moved := Vector2.ZERO
	if not ptrail.is_empty():
		moved = player - ptrail[0]
	if moved.length() > 2.0:
		p_dir = p_dir.lerp(moved.normalized(), 0.35).normalized()
		if p_dir == Vector2.ZERO:
			p_dir = Vector2.UP
	ptrail.push_front(player)
	if ptrail.size() > 26:
		ptrail.pop_back()
	if int(sv.trail) == 2 and frame % 3 == 0 and moved.length() > 3.0:
		particles.append([player, Vector2(randf_range(-60, 60), randf_range(-60, 60)), 0.5, _pcol(), 4.0])

	if combo_t > 0.0:
		combo_t -= delta
		if combo_t <= 0.0:
			combo = 0
	invuln_t = maxf(0.0, invuln_t - delta)

	# magnet
	var mg := _up("magnet")
	if mg > 0:
		var d := orb.distance_to(player)
		var reach := 110.0 + 50.0 * mg
		if d < reach and d > 1.0:
			orb += (player - orb).normalized() * (140.0 + 60.0 * mg) * delta
	if player.distance_to(orb) < _player_r() + ORB_R + 4.0 * mg:
		_take_orb()

	# iskra (mena) v arene
	if spark_at >= 0.0 and t >= spark_at and spark_t == 0.0:
		spark_pos = _random_point()
		spark_t = 3.0
		spark_at = -1.0
		_play("spark_in")
	if spark_t > 0.0:
		spark_t = maxf(0.0, spark_t - delta)
		if player.distance_to(spark_pos) < _player_r() + 20.0:
			spark_t = 0.0
			g_sparks += 1
			g_coins += 2
			_popup(spark_pos, "+2", COL_COIN, 34)
			_burst(spark_pos, COL_COIN, 14, 280.0)
			_play("coin")
			_vibrate(15)

	if t > _grace():
		_check_ghosts()
		if screen != S.PLAY:
			return
	frame += 1

	var left := ROUND_TIME - t
	var tick := int(ceil(left))
	if tick != last_tick and tick <= 3 and tick >= 1:
		_play("tick", 1.0 + 0.12 * (3 - tick))
	last_tick = tick
	if not record_said and not daily and int(sv.best) > 0 and score > int(sv.best):
		record_said = true
		_popup(ARENA.get_center() + Vector2(0, -120), L("record_pop"), COL_ORB, 50)
		_play("level")
	if t >= ROUND_TIME:
		_end_round()


## Pohyb lode: klavesnica (WASD / sipky) funguje vzdy, mys len ked je zvolena v nastaveniach.
## Dotyk sa riesi v _input (tahanie prstom) a funguje vzdy.
func _steer(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	if Input.is_key_pressed(KEY_A):
		dir.x -= 1.0
	if Input.is_key_pressed(KEY_D):
		dir.x += 1.0
	if Input.is_key_pressed(KEY_W):
		dir.y -= 1.0
	if Input.is_key_pressed(KEY_S):
		dir.y += 1.0
	dir = dir.limit_length(1.0)
	if autoplay:
		dir = _autoplay_dir()
	if dir != Vector2.ZERO:
		player = _clamp_arena(player + dir * KEY_SPEED * delta)
	elif int(sv.ctrl) == 0 and mouse_live and not autoplay:
		# lod leti za kurzorom; kym sa mys v kole nepohne, ostava na mieste startu
		var to := _clamp_arena(mouse_pos) - player
		player = _clamp_arena(player + to.limit_length(MOUSE_SPEED * delta))


func _take_orb() -> void:
	orbs_got += 1
	g_orbs += 1
	if combo_t > 0.0:
		combo += 1
	else:
		combo = 1
	combo_t = COMBO_TIME + 1.0 * _up("combo") + sk_combo
	g_combo = maxi(g_combo, combo)
	var mult := 1.0 + 0.25 * (mini(combo, 9) - 1)
	var value := int(round((1 + ghosts.size()) * (1.0 + 0.5 * _up("bonus")) * mult * sk_pts))
	if _mod_id() == "gold":
		value *= 2
	score += value
	_popup(orb, "+%d" % value, COL_ORB, 34 + mini(combo, 6) * 3)
	_burst(orb, COL_ORB, 12 + mini(combo, 8) * 2, 280.0)
	_play("orb3" if orbs_got == ORBS_NEEDED else "orb", 1.0 + 0.07 * mini(combo - 1, 10))
	_vibrate(12)
	if _up("blink") > 0:
		invuln_t = 0.5 * _up("blink")
	if orbs_got == ORBS_NEEDED and _up("shock") > 0:
		for n in _up("shock"):
			var bi := -1
			var bd := 99999.0
			for i in ghosts.size():
				if ghost_off[i]:
					continue
				var d := player.distance_to(_gpos(i, frame))
				if d < bd:
					bd = d
					bi = i
			if bi >= 0:
				ghost_off[bi] = true
				_burst(_gpos(bi, frame), COL_SHIELD, 18, 300.0)
				_popup(_gpos(bi, frame), L("shock_pop"), COL_SHIELD, 30)
		_play("shield")
	orb = _next_orb(orb)
	orb_born = now


func _check_ghosts() -> void:
	var pr := _player_r()
	var gr := _ghost_r()
	for i in ghosts.size():
		if ghost_off[i]:
			continue
		var d := player.distance_to(_gpos(i, frame))
		if d < pr + gr - 2.0:
			if invuln_t > 0.0:
				continue
			if camp:
				ghost_off[i] = true
				_hull_hit(L("hit_echo"), i)
				if screen == S.DYING:
					return
				continue
			if _up("shield") > 0:
				up["shield"] = _up("shield") - 1
				ghost_off[i] = true
				g_blocks += 1
				flash = 0.7
				flash_col = COL_SHIELD
				shake = 12.0
				_burst(player, COL_SHIELD, 24, 360.0)
				_popup(player + Vector2(0, -46), L("shield_pop"), COL_SHIELD, 38)
				_play("shield")
				_vibrate(60)
			else:
				_die(L("hit_echo"), i)
				return
		elif d < pr + gr + NEAR_DIST and not near_done[i]:
			near_done[i] = true
			g_near += 1
			var value := (2 + int(round_num / 3.0)) * sk_near
			if _mod_id() == "gold":
				value *= 2
			score += value
			_popup(player + Vector2(0, -48), L("near") % value, COL_TEXT, 30)
			_play("near")


# ---------------------------------------------------------------- pomocne (hra)

func _up(id: String) -> int:
	return int(up.get(id, 0))


func _mod_id() -> String:
	return str(D.MODS[mod].id) if mod >= 0 else ""


func _player_r() -> float:
	return PLAYER_R * pow(0.88, _up("small"))


func _ghost_r() -> float:
	return GHOST_R * pow(0.88, _up("thin")) * sk_thin


func _grace() -> float:
	return GRACE_TIME + 0.5 * _up("grace") + sk_grace


func _gpos(i: int, f: int) -> Vector2:
	var g := ghosts[i]
	var speed := sk_slow * pow(0.9, _up("slow")) * (1.25 if _mod_id() == "fast" else 1.0)
	var p := g[clampi(int(f * speed), 0, g.size() - 1)]
	if _mod_id() == "mirror":
		p.x = ARENA.position.x + ARENA.end.x - p.x
	return p


func _clamp_arena(p: Vector2) -> Vector2:
	var r := _player_r()
	return Vector2(
		clampf(p.x, ARENA.position.x + r, ARENA.end.x - r),
		clampf(p.y, ARENA.position.y + r, ARENA.end.y - r))


func _random_point() -> Vector2:
	var m := 60.0
	return Vector2(
		rng.randf_range(ARENA.position.x + m, ARENA.end.x - m),
		rng.randf_range(ARENA.position.y + m, ARENA.end.y - m))


func _next_orb(from: Vector2) -> Vector2:
	# zavisi len od rng a predchadzajucej pozicie -> v dennej vyzve rovnake pre vsetkych
	var p := Vector2.ZERO
	for i in 40:
		p = _random_point()
		if p.distance_to(from) >= 240.0:
			break
	return p


func _spawn_point() -> Vector2:
	# miesto co najdalej od zaciatkov ozvien
	var best_p := ARENA.get_center()
	var best_d := -1.0
	for i in 30:
		var p := Vector2(
			rng.randf_range(ARENA.position.x + 90, ARENA.end.x - 90),
			rng.randf_range(ARENA.position.y + 90, ARENA.end.y - 90))
		var d := 99999.0
		for gi in ghosts.size():
			for f in [0, 20, 40, 60, 80, 100, 120]:
				d = minf(d, p.distance_to(_gpos(gi, f)))
		if d > best_d:
			best_d = d
			best_p = p
	return best_p


func _autoplay_dir() -> Vector2:
	# jednoduchy bot: ide k energii (a iskre), uhyba ozvenam
	var target := orb
	if spark_t > 0.0 and player.distance_to(spark_pos) < player.distance_to(orb):
		target = spark_pos
	var dir := (target - player).normalized()
	if dbg_revive and ((round_num >= 4 and not revived) or round_num >= 6):
		return dir   # ladenie: bot schvalne neuhyba, aby sa dala otestovat smrt a pokracovanie
	if screen == S.BOSS:
		var from_boss := player - b_pos
		if from_boss.length() < 230.0:
			dir += from_boss.normalized() * (230.0 - from_boss.length()) / 40.0
		for b in bullets:
			var bp: Vector2 = b[0]
			var bv: Vector2 = b[1]
			var off := player - (bp + bv * 0.25)
			var bd := off.length()
			if bd < 95.0 and bd > 0.01:
				dir += off.normalized() * (95.0 - bd) / 18.0
		if b_id == 1 or b_id == 4:
			var arms := 2 if b_id == 1 else 3
			for k in arms:
				var a := b_ang + 0.25 + TAU * k / arms
				var cp := Geometry2D.get_closest_point_to_segment(player, b_pos, b_pos + Vector2(cos(a), sin(a)) * 350.0)
				var ad := player.distance_to(cp)
				if ad < 90.0 and ad > 0.01:
					dir += (player - cp).normalized() * (90.0 - ad) / 14.0
	for i in ghosts.size():
		if ghost_off[i]:
			continue
		var away := player - _gpos(i, frame + 6)
		var d := away.length()
		if d < 115.0 and d > 0.01:
			dir += away.normalized() * (115.0 - d) / 28.0
	return dir.normalized()


func _log(msg: String) -> void:
	if autoplay:
		print(msg)


# ================================================================ VSTUP

func _input(event: InputEvent) -> void:
	if dbg_ov:
		if event is InputEventScreenTouch and event.pressed:
			dbg_n[1] += 1
			dbg_last = event.position - origin
		elif event is InputEventMouseButton and event.pressed:
			dbg_n[2] += 1
			dbg_last = event.position - origin
		elif event is InputEventScreenDrag or event is InputEventMouseMotion:
			dbg_n[3] += 1
	if event is InputEventScreenDrag:
		if (screen == S.PLAY or screen == S.BOSS) and not paused:
			player = _clamp_arena(player + event.relative * float(SENS[int(sv.sens)]))
	elif event is InputEventScreenTouch and event.pressed and event.index == 0:
		_on_tap(event.position - origin)
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_on_tap(event.position - origin)
	elif event is InputEventMouseMotion:
		mouse_pos = event.position - origin
		mouse_live = true
	elif event is InputEventKey and event.pressed:
		if name_edit:
			if event.keycode == KEY_BACKSPACE:
				_auth_backspace()
			elif event.keycode == KEY_TAB:
				auth_field = 1 - auth_field
			elif event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
				_auth_send("login")
			elif event.keycode == KEY_ESCAPE:
				name_edit = false
			elif event.unicode >= 32:
				_auth_type_raw(char(event.unicode))
		elif not event.echo:
			_on_key(event.keycode)


func _on_tap(pos: Vector2) -> void:
	for i in range(buttons.size() - 1, -1, -1):
		var r: Rect2 = buttons[i][0]
		if r.has_point(pos):
			pressed_id = buttons[i][1]
			pressed_t = 0.15
			_click(pressed_id)
			return


func _on_key(key: int) -> void:
	if dbg_revive and key == KEY_F9:
		score = 777 + randi() % 500   # ladenie: zapis skusobneho skore do tabulky
		camp = true
		_log_score()
		camp = false
		return
	match key:
		KEY_SPACE, KEY_ENTER:
			if paused:
				paused = false
			elif screen == S.MENU:
				_click("play")
			elif screen == S.OVER and screen_t > 0.8:
				_click("again")
			elif screen == S.REVIVE:
				_click("skip")
		KEY_D:
			if screen == S.MENU:
				_click("daily")
		KEY_1, KEY_2, KEY_3:
			if screen == S.PICK and screen_t > 0.35:
				_apply_pick(key - KEY_1)
		KEY_R:
			if screen == S.PICK:
				_click("reroll")
		KEY_ESCAPE, KEY_P, KEY_BACK:
			if screen == S.PLAY or screen == S.INTRO:
				paused = not paused
			elif screen == S.SHOP or screen == S.PROFILE or screen == S.SETTINGS:
				_click("back")


func _click(id: String) -> void:
	var parts := id.split(":")
	match parts[0]:
		"play":
			_begin(false)
		"daily":
			_begin(true)
		"again":
			if screen_t > 0.6:
				if camp:
					_open_base()
				else:
					_begin(daily)
		"campaign":
			_open_base()
		"launch":
			_start_campaign()
		"tree":
			tree_sel = -1
			_go(S.TREE)
		"adv":
			base_who = int(parts[1])
			var keys := ["vex_base", "nova_base", "riot_base"]
			var line := L(keys[base_who])
			base_line = L("story") if (base_who == 0 and base_line == line) else line
			base_talk_t = 3.0
			_play("card")
		"acct":
			if _logged_in():
				_logout()
			else:
				_open_auth()
		"afield":
			auth_field = int(parts[1])
			_play("tap")
		"ak":
			_auth_type(parts[1])
		"ashift":
			auth_upper = not auth_upper
			_play("tap")
		"aspace":
			if auth_field == 0:
				_auth_type(" ")
		"adel":
			_auth_backspace()
		"alogin":
			_auth_send("login")
		"adc":
			sv.dc_skip = false
			_dc_login(false)
		"areg":
			_auth_send("register")
		"acancel":
			name_edit = false
			_play("tap")
		"scores":
			_go(S.SCORES)
			scores_tab = 0 if board_url != "" else 1
			_board_fetch()
		"stab":
			scores_tab = int(parts[1])
			_play("tap")
			_board_fetch()
		"rmode":
			rate_mode = int(parts[1])
			_play("tap")
			_board_fetch()
		"rday":
			rate_day = int(parts[1])
			_play("tap")
			_board_fetch()
		"node":
			tree_sel = int(parts[1])
			_play("tap")
		"buysk":
			_buy_skill()
		"mbuy":
			_merchant_buy(int(parts[1]))
		"mcont":
			_merchant_continue()
		"shop":
			_go(S.SHOP)
		"profile":
			_go(S.PROFILE)
		"settings":
			_go(S.SETTINGS)
		"back", "menu":
			if screen == S.TREE:
				_open_base()
				return

			if game_active:
				_finish_game()
			paused = false
			_go(S.MENU)
		"tab":
			shop_tab = int(parts[1])
			_play("tap")
		"item":
			_shop_click(int(parts[1]))
		"prev":
			var which := int(parts[1])
			if preview_i == which:
				preview_i = -1
			else:
				preview_i = which
				preview_t = PREVIEW_TIME
			_refresh_music()
		"set":
			_setting(parts[1])
		"pick":
			if screen_t > 0.35:
				_apply_pick(int(parts[1]))
		"reroll":
			if rerolls > 0 and screen_t > 0.2:
				rerolls -= 1
				rerolls_used += 1
				screen_t = 0.0
				_roll_cards()
				_play("card")
		"pause":
			paused = true
			_play("tap")
		"resume":
			paused = false
			_play("tap")
		"restart":
			var was_camp := camp
			_finish_game()
			if was_camp:
				_start_campaign()
			else:
				_begin(daily)
		"revive":
			if int(sv.coins) >= REVIVE_COST:
				sv.coins = int(sv.coins) - REVIVE_COST
				_save()
				_revive()
		"revive_ad":
			Ads.rewarded(_on_rewarded)
		"skip":
			_to_over()
		"share":
			_share()


func _on_rewarded(ok: bool) -> void:
	if ok:
		_revive()
	else:
		_to_over()


func _begin(is_daily: bool) -> void:
	if games_since_ad >= 3:
		games_since_ad = 0
		Ads.interstitial(start_game.bind(is_daily))
	else:
		start_game(is_daily)


func _go(s: int) -> void:
	screen = s
	screen_t = 0.0
	fade = 1.0
	reset_armed = 0.0
	name_edit = false
	if preview_i >= 0:
		preview_i = -1
		_refresh_music()
	_play("tap")


func _shop_click(i: int) -> void:
	var list: Array = [D.SKINS, D.TRAILS, D.THEMES, D.MUSIC][shop_tab]
	var own_key: String = ["own_skin", "own_trail", "own_theme", "own_track"][shop_tab]
	var use_key: String = ["skin", "trail", "theme", "track"][shop_tab]
	var owned: Array = sv[own_key]
	if shop_tab == 0 and list[i].has("loc") and int(sv.cleared) < int(list[i].loc):
		_toast(L("loc_locked") % int(list[i].loc))
		_play("error")
		return
	if shop_tab == 3 and not _track_available(i):
		_toast(L("soon"))
		return
	if i in owned:
		sv[use_key] = i
		_play("tap")
	elif int(sv.coins) >= int(list[i].price):
		sv.coins = int(sv.coins) - int(list[i].price)
		owned.append(i)
		sv[use_key] = i
		_toast(L("bought"))
		_play("level")
		_burst(VIEW / 2.0, _acc(), 40, 600.0)
		_vibrate(40)
	else:
		_toast(L("no_coins"))
		_play("error")
		return
	_apply_theme()
	if shop_tab == 3:
		preview_i = -1
		_refresh_music()
	_save()


func _setting(key: String) -> void:
	match key:
		"sound", "vibra", "shake":
			sv[key] = not bool(sv[key])
		"music":
			sv.music = not bool(sv.music)
			_refresh_music()
		"sens":
			sv.sens = (int(sv.sens) + 1) % 3
		"ctrl":
			sv.ctrl = 1 - int(sv.ctrl)
		"lang":
			lang = 1 - lang
			sv.lang = lang
		"reset":
			if reset_armed > 0.0:
				var keep_lang := lang
				sv = _defaults()
				sv.lang = keep_lang
				_apply_theme()
				_refresh_music()
				_fill_missions()
				_toast(L("reset_done"))
				reset_armed = 0.0
			else:
				reset_armed = 3.0
	_play("tap")
	_save()


func _share() -> void:
	var text := ""
	if daily:
		text = L("share_daily") % [_today(), score, round_num]
	else:
		text = L("share_text") % [score, round_num]
	if OS.has_feature("web"):
		var js := "(function(t){if(navigator.share){navigator.share({text:t}).catch(function(){});}else if(navigator.clipboard){navigator.clipboard.writeText(t);}})(%s)" % JSON.stringify(text)
		JavaScriptBridge.eval(js, true)
	else:
		DisplayServer.clipboard_set(text)
	_toast(L("copied"))
	_play("tap")


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or what == NOTIFICATION_APPLICATION_PAUSED:
		if (screen == S.PLAY or screen == S.INTRO) and not autoplay:
			paused = true


# ================================================================ POSTUP A UKLADANIE

func L(key: String) -> String:
	if not D.TXT.has(key):
		return key
	return D.TXT[key][lang]


func _defaults() -> Dictionary:
	return {
		"best": 0, "coins": 0, "xp": 0, "level": 1,
		"skin": 0, "trail": 0, "theme": 0, "track": 0,
		"own_skin": [0], "own_trail": [0], "own_theme": [0], "own_track": [0],
		"sound": true, "music": true, "vibra": true, "shake": true, "sens": 1, "ctrl": 0, "lang": -1,
		"daily_date": "", "daily_best": 0, "streak": 0, "best_streak": 0, "history": {},
		"missions": [], "tiers": {}, "tut": false,
		"cores": 0, "skills": [], "cleared": 0, "camp_wins": 0, "camp_runs": 0,
		"acc_name": "", "acc_token": "", "dc_skip": false, "scores": [], "best_camp": 0, "day_best": {},
		"st": {"games": 0, "rounds": 0, "best_round": 0, "orbs": 0, "near": 0, "combo": 0, "best_any": 0},
	}


func _load() -> void:
	sv = _defaults()
	var c := ConfigFile.new()
	if c.load(SAVE_PATH) == OK:
		var d: Variant = c.get_value("save", "data", {})
		if d is Dictionary:
			for k in d:
				if sv.has(k) and typeof(sv[k]) == typeof(d[k]):
					sv[k] = d[k]
	if int(sv.lang) < 0:
		lang = 1   # anglictina je predvolena; slovencina sa da zapnut v nastaveniach
	else:
		lang = clampi(int(sv.lang), 0, 1)
	sv.skin = clampi(int(sv.skin), 0, D.SKINS.size() - 1)
	sv.trail = clampi(int(sv.trail), 0, D.TRAILS.size() - 1)
	sv.theme = clampi(int(sv.theme), 0, D.THEMES.size() - 1)
	sv.track = clampi(int(sv.track), 0, D.MUSIC.size() - 1)
	sv.sens = clampi(int(sv.sens), 0, 2)
	sv.ctrl = clampi(int(sv.ctrl), 0, 1)


func _save() -> void:
	if autoplay:
		return
	var c := ConfigFile.new()
	c.set_value("save", "data", sv)
	c.save(SAVE_PATH)


func _apply_theme() -> void:
	TH = D.THEMES[int(sv.theme)]


func _acc() -> Color:
	return TH.accent


func _pcol() -> Color:
	return D.SKINS[int(sv.skin)].col


func _xp_need(level: int) -> int:
	return 150 + 100 * level


func _rank() -> String:
	var i := mini(int((int(sv.level) - 1) / 3.0), D.RANKS.size() - 1)
	return D.RANKS[i][lang]


func _fill_missions() -> void:
	var missions: Array = sv.missions
	var guard := 0
	while missions.size() < 3 and guard < 80:
		guard += 1
		var def: Dictionary = D.MISSIONS[randi() % D.MISSIONS.size()]
		var used := false
		for m in missions:
			if m.t == def.t:
				used = true
		if used:
			continue
		var targets: Array = def.targets
		var tier := mini(int(sv.tiers.get(def.t, 0)), targets.size() - 1)
		missions.append({"t": def.t, "cum": def.cum, "target": targets[tier], "rew": def.rew[tier], "prog": 0})
	sv.missions = missions


func _mission_text(m: Dictionary) -> String:
	for def in D.MISSIONS:
		if def.t == m.t:
			var s: String = def.n[lang]
			return (s % int(m.target)) if "%d" in s else s
	return "?"


func _today() -> String:
	return Time.get_date_string_from_system()


func _day_number(date: String) -> int:
	return int(Time.get_unix_time_from_datetime_string(date + "T00:00:00") / 86400.0)


func _touch_daily() -> void:
	var today := _today()
	if str(sv.daily_date) == today:
		return
	if str(sv.daily_date) != "" and _day_number(today) - _day_number(str(sv.daily_date)) == 1:
		sv.streak = int(sv.streak) + 1
	else:
		sv.streak = 1
	sv.best_streak = maxi(int(sv.best_streak), int(sv.streak))
	sv.daily_date = today
	sv.daily_best = 0
	g_streak_bonus = 5 * mini(int(sv.streak), 7)
	# historia: nechaj len poslednych 14 dni
	var hist: Dictionary = sv.history
	for k in hist.keys():
		if _day_number(today) - _day_number(str(k)) > 14:
			hist.erase(k)
	_save()


func _daily_best_today() -> int:
	return int(sv.daily_best) if str(sv.daily_date) == _today() else 0


func _streak_alive() -> int:
	if str(sv.daily_date) == "":
		return 0
	return int(sv.streak) if _day_number(_today()) - _day_number(str(sv.daily_date)) <= 1 else 0


# ================================================================ ZVUK

func _make_sounds() -> void:
	sfx["orb"] = _tone(660, 990, 0.09, 0.35)
	sfx["orb3"] = _tone(880, 1760, 0.2, 0.4)
	sfx["near"] = _tone(1400, 1900, 0.06, 0.22)
	sfx["round"] = _tone(440, 880, 0.25, 0.35)
	sfx["die"] = _tone(300, 50, 0.5, 0.55, true)
	sfx["shield"] = _tone(520, 180, 0.28, 0.4, true)
	sfx["pick"] = _tone(520, 1040, 0.2, 0.35)
	sfx["card"] = _tone(900, 600, 0.07, 0.25)
	sfx["tap"] = _tone(700, 760, 0.04, 0.22)
	sfx["tick"] = _tone(1000, 1000, 0.05, 0.25)
	sfx["coin"] = _tone(1200, 2000, 0.12, 0.3)
	sfx["spark_in"] = _tone(1600, 1200, 0.08, 0.15)
	sfx["level"] = _tone(520, 1560, 0.45, 0.4)
	sfx["error"] = _tone(220, 160, 0.16, 0.35)
	sfx["start"] = _tone(330, 660, 0.18, 0.3)
	sfx["special"] = _tone(200, 800, 0.5, 0.35)
	sfx["revive"] = _tone(300, 1200, 0.4, 0.4)
	for i in 6:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)


func _tone(f0: float, f1: float, dur: float, vol: float, noisy := false) -> AudioStreamWAV:
	var rate := 22050
	var n := int(dur * rate)
	var data := PackedByteArray()
	data.resize(n * 2)
	var phase := 0.0
	for i in n:
		var k := float(i) / n
		phase += TAU * lerpf(f0, f1, k) / rate
		var s := sin(phase) + 0.25 * sin(phase * 2.0)
		if noisy:
			s = s * 0.6 + randf_range(-0.4, 0.4)
		var env := minf(1.0, k * 40.0) * pow(1.0 - k, 1.5)
		data.encode_s16(i * 2, int(clampf(s * env * vol, -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = rate
	w.stereo = false
	w.data = data
	return w


func _play(sound: String, pitch := 1.0) -> void:
	if not bool(sv.sound) or players.is_empty() or not sfx.has(sound):
		return
	var p := players[next_player]
	next_player = (next_player + 1) % players.size()
	p.stream = sfx[sound]
	p.pitch_scale = pitch
	p.play()


func _vibrate(ms: int) -> void:
	if bool(sv.vibra) and not autoplay:
		Input.vibrate_handheld(ms)


func _track_path(base: String) -> String:
	if base == "":
		return ""
	if ResourceLoader.exists(base):
		return base
	for ext in [".ogg", ".mp3", ".wav"]:
		if ResourceLoader.exists(base + ext):
			return base + ext
	return ""


func _track_available(i: int) -> bool:
	return _track_path(str(D.MUSIC[i].a)) != ""


func _load_stream(base: String) -> AudioStream:
	var path := _track_path(base)
	if path == "":
		return null
	if track_cache.has(path):
		return track_cache[path]
	var st := load(path) as AudioStream
	var w := st as AudioStreamWAV
	if w != null:
		# slucka je nastavena v importe (audio/*.import: edit/loop_mode=2); toto je len poistka
		if w.loop_mode == AudioStreamWAV.LOOP_DISABLED and w.format == AudioStreamWAV.FORMAT_16_BITS:
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = int(w.data.size() / (4.0 if w.stereo else 2.0))
	elif st != null and "loop" in st:
		st.set("loop", true)
	track_cache[path] = st
	return st


## Nastavi spravnu skladbu (ukazka z obchodu ma prednost) a pusti alebo zastavi hudbu.
func _refresh_music() -> void:
	if music_a == null:
		music_a = AudioStreamPlayer.new()
		add_child(music_a)
		music_b = AudioStreamPlayer.new()
		music_b.volume_db = -60.0
		add_child(music_b)
	var want := preview_i if preview_i >= 0 else int(sv.track)
	if not _track_available(want):
		want = 0
	if want != cur_track:
		cur_track = want
		var m: Dictionary = D.MUSIC[want]
		music_a.stop()
		music_b.stop()
		music_a.stream = _load_stream(str(m.a))
		music_b.stream = _load_stream(str(m.get("b", "")))
	if bool(sv.music) or preview_i >= 0:
		if music_a.stream != null and not music_a.playing:
			music_a.play()
		if music_b.stream != null and not music_b.playing:
			music_b.play()
	else:
		music_a.stop()
		music_b.stop()


func _update_music(delta: float) -> void:
	if music_a == null or music_b == null:
		return
	if preview_i >= 0:
		preview_t -= delta
		if preview_t <= 0.0:
			preview_i = -1
			_refresh_music()
	var in_game := screen == S.INTRO or screen == S.PLAY or screen == S.PICK or screen == S.BOSS or screen == S.MERCHANT
	var target := clampf(0.15 + (round_num - 1) / 9.0, 0.15, 1.0) if in_game else 0.0
	if screen == S.BOSS:
		target = 1.0
	if paused:
		target = 0.0
	if preview_i >= 0:
		target = 0.8   # ukazka hra naplno, aby bolo pocut celu skladbu
	music_mix = move_toward(music_mix, target, delta * 0.8)
	var vol := float(D.MUSIC[maxi(cur_track, 0)].get("vol", 0.0))
	music_a.volume_db = (-16.0 if paused else -9.0) + vol
	if dbg_revive and Engine.get_process_frames() % 180 == 0:
		print("MUSIC track=%d playing=%s pos=%.1f preview=%d" % [cur_track, str(music_a.playing), music_a.get_playback_position(), preview_i])
	music_b.volume_db = linear_to_db(maxf(0.0005, music_mix * 0.55)) + vol


# ================================================================ EFEKTY

func _popup(pos: Vector2, text: String, col: Color, size := 34) -> void:
	popups.append([pos, text, 1.0, col, size])


func _burst(pos: Vector2, col: Color, n: int, speed: float) -> void:
	for i in n:
		var a := randf() * TAU
		particles.append([pos, Vector2(cos(a), sin(a)) * randf_range(0.25, 1.0) * speed, randf_range(0.4, 0.95), col, randf_range(3.0, 6.5)])


func _toast(text: String) -> void:
	toast = text
	toast_t = 2.2


func _process(delta: float) -> void:
	now = Time.get_ticks_msec() / 1000.0
	vp = get_viewport_rect().size
	origin = ((vp - VIEW) / 2.0).floor()
	shake = maxf(0.0, shake - delta * 70.0)
	flash = maxf(0.0, flash - delta * 2.5)
	fade = maxf(0.0, fade - delta * 4.0)
	pressed_t = maxf(0.0, pressed_t - delta)
	toast_t = maxf(0.0, toast_t - delta)
	reset_armed = maxf(0.0, reset_armed - delta)
	dlg_t = maxf(0.0, dlg_t - delta)
	base_talk_t = maxf(0.0, base_talk_t - delta)
	if dc_wait > 0.0:
		_dc_poll(delta)
	score_shown = lerpf(score_shown, float(score), minf(1.0, delta * 12.0))
	for p in popups:
		p[2] -= delta * 1.1
		p[0] += Vector2(0, -55) * delta
	popups = popups.filter(func(p): return p[2] > 0.0)
	for p in particles:
		p[2] -= delta
		p[0] += p[1] * delta
		p[1] *= maxf(0.0, 1.0 - 3.0 * delta)
	particles = particles.filter(func(p): return p[2] > 0.0)
	_update_music(delta)
	queue_redraw()


# ================================================================ KRESLENIE

func _draw() -> void:
	buttons.clear()
	_draw_background()

	var sh := Vector2.ZERO
	if bool(sv.shake) and shake > 0.0:
		sh = Vector2(randf_range(-shake, shake), randf_range(-shake, shake))
	var in_game := screen >= S.INTRO
	if in_game:
		draw_set_transform(origin + sh)
		_draw_arena()
		_draw_entities()
	draw_set_transform(origin + sh)
	for p in particles:
		var a: float = clampf(p[2] * 2.2, 0.0, 1.0)
		draw_circle(p[0], float(p[4]) * a, Color(p[3], a))
	for p in popups:
		var life: float = p[2]
		var sz := int(float(p[4]) * (1.0 + 0.5 * maxf(0.0, life - 0.85) / 0.15))
		_txt(p[0], p[1], sz, Color(p[3], clampf(life * 1.6, 0.0, 1.0)), 0, true, true)

	if (screen == S.PLAY or screen == S.BOSS) and int(sv.ctrl) == 0 and mouse_live and not autoplay:
		draw_arc(_clamp_arena(mouse_pos), 12.0, 0, TAU, 20, Color(COL_TEXT, 0.3), 2.0)
	draw_set_transform(origin)
	match screen:
		S.MENU: _draw_menu()
		S.SHOP: _draw_shop()
		S.PROFILE: _draw_profile()
		S.SETTINGS: _draw_settings()
		S.BASE: _draw_base()
		S.TREE: _draw_tree()
		S.SCORES: _draw_scores()
		S.BOSS: _draw_hud()
		S.MERCHANT:
			_draw_hud()
			_draw_merchant()
		S.INTRO:
			_draw_hud()
			_draw_intro()
		S.PLAY: _draw_hud()
		S.PICK:
			_draw_hud()
			_draw_pick()
		S.DYING: _draw_hud()
		S.REVIVE:
			_draw_hud()
			_draw_revive()
		S.OVER: _draw_over()
	if (camp or boss_next) and screen >= S.INTRO and screen != S.OVER:
		_draw_hud_camp()
	if camp and screen >= S.INTRO and screen != S.OVER:
		_draw_dialog()
	if paused:
		_draw_pause()
	if name_edit and screen == S.PROFILE:
		_draw_auth()
	if toast_t > 0.0:
		var a2 := clampf(toast_t * 3.0, 0.0, 1.0)
		var w := _tw(toast, 26, true) + 60.0
		_panel(Rect2(360 - w / 2.0, 1196, w, 56), Color(COL_DARK, 0.92 * a2), Color(_acc(), a2), 2, 28)
		_txt(Vector2(360, 1233), toast, 26, Color(COL_TEXT, a2))

	draw_set_transform(Vector2.ZERO)
	if flash > 0.0 and bool(sv.shake):
		draw_rect(Rect2(Vector2.ZERO, vp), Color(flash_col, flash * 0.3))
	if fade > 0.0:
		draw_rect(Rect2(Vector2.ZERO, vp), Color(TH.bg0, fade))
	if dbg_ov:
		# diagnostika vstupu (?dbg v adrese): snimky, dotyky, kliky, pohyby, posledny dotyk
		dbg_n[0] += 1
		var t := "f%d t%d m%d mv%d  last %d,%d  vp %dx%d  scr %d  btn %d" % [dbg_n[0], dbg_n[1], dbg_n[2], dbg_n[3], int(dbg_last.x), int(dbg_last.y), int(vp.x), int(vp.y), screen, buttons.size()]
		draw_rect(Rect2(0, 0, vp.x, 34), Color(0, 0, 0, 0.8))
		draw_string(font_m if font_m else ThemeDB.fallback_font, Vector2(8, 24), t, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color.YELLOW)
		if dbg_last.x >= 0:
			draw_circle(dbg_last + origin, 14.0, Color(1, 1, 0, 0.6))


func _draw_background() -> void:
	var c0: Color = TH.bg0
	var c1: Color = TH.bg1
	draw_polygon(
		PackedVector2Array([Vector2.ZERO, Vector2(vp.x, 0), vp, Vector2(0, vp.y)]),
		PackedColorArray([c0, c0, c1, c1]))
	# pomaly sa posuvajuca mriezka
	var line := Color(TH.line, 0.22)
	var off := fmod(now * 12.0, 80.0)
	var x := -80.0 + off
	while x < vp.x + 200.0:
		draw_line(Vector2(x, 0), Vector2(x - 120.0, vp.y), line, 1.0)
		x += 80.0
	var y := -80.0 + off
	while y < vp.y + 80.0:
		draw_line(Vector2(0, y), Vector2(vp.x, y), line, 1.0)
		y += 80.0
	# prach
	var dust: Color = TH.accent
	for i in 36:
		var px := fposmod(sin(i * 12.9898) * 43758.5453, 1.0) * vp.x
		var sp := 14.0 + fposmod(i * 7.13, 22.0)
		var py := fposmod(fposmod(i * 0.6180339, 1.0) * vp.y - now * sp, vp.y)
		draw_circle(Vector2(px, py), 1.5 + fposmod(i * 0.37, 1.8), Color(dust, 0.10 + 0.08 * sin(now * 0.8 + i)))


func _draw_arena() -> void:
	var border: Color = TH.line
	var glow_a := 0.0
	if screen == S.PLAY:
		var left := ROUND_TIME - t
		if left < 2.5 and orbs_got < ORBS_NEEDED:
			var k := 0.5 + 0.5 * sin(now * 14.0)
			border = border.lerp(COL_DANGER, 0.5 + 0.5 * k)
			glow_a = 0.3 * k
		elif orbs_got >= ORBS_NEEDED:
			border = border.lerp(_acc(), 0.6)
	if mod >= 0 and screen != S.PICK:
		var mc: Color = D.MODS[mod].col
		border = border.lerp(mc, 0.5)
	var fill: Color = TH.arena
	_panel(ARENA, Color(fill, 0.92), border, 3, 26, Color(border, 0.25 + glow_a), 16)
	# velke odpocitavanie v pozadi
	if screen == S.PLAY:
		var left2 := ROUND_TIME - t
		if left2 <= 3.0:
			var n := int(ceil(left2))
			var frac := left2 - floorf(left2)
			_txt(ARENA.get_center() + Vector2(0, 110), str(n), 320, Color(COL_TEXT, 0.05 + 0.07 * frac))


func _draw_entities() -> void:
	var show_frame := frame if (screen == S.PLAY or screen == S.BOSS or screen >= S.DYING) else 0
	var harmless := (screen != S.PLAY and screen != S.BOSS) or t <= _grace()
	var gr := _ghost_r()
	var dark := _mod_id() == "dark" and screen != S.PICK
	var hole: Color = TH.arena

	# nahlad drah ozvien pocas uvodu kola
	if screen == S.INTRO:
		var lim := int(_grace() * 60.0) + 50
		for i in ghosts.size():
			var col := _gcol(i)
			var f := 6
			while f < lim:
				draw_circle(_gpos(i, f), 2.5, Color(col, 0.35 * (1.0 - float(f) / lim)))
				f += 6

	for i in ghosts.size():
		var col := _gcol(i)
		var a := 0.9
		if harmless and screen < S.DYING:
			a = 0.32 + (0.12 * sin(now * 16.0) if screen == S.PLAY else 0.0)
		if i < ghost_off.size() and ghost_off[i]:
			a = 0.1
		var gp := _gpos(i, show_frame)
		if dark and screen == S.PLAY:
			a *= clampf(1.0 - (gp.distance_to(player) - 190.0) / 130.0, 0.04, 1.0)
		for k in range(TRAIL_LEN, 0, -1):
			var tp := _gpos(i, show_frame - k * 2)
			var ta := a * 0.4 * (1.0 - float(k) / TRAIL_LEN)
			draw_circle(tp, gr * (1.0 - float(k) / (TRAIL_LEN * 1.5)), Color(col, ta))
		draw_circle(gp, gr * 1.9, Color(col, a * 0.14))
		draw_circle(gp, gr, Color(col, a))
		draw_circle(gp, gr * 0.5, Color(hole, a))
		if screen >= S.DYING and i == killer:
			var pulse := fposmod(now * 1.6, 1.0)
			draw_arc(gp, gr + 8.0 + pulse * 40.0, 0, TAU, 40, Color(COL_DANGER, 1.0 - pulse), 4.0)
			draw_arc(gp, gr + 5.0, 0, TAU, 32, COL_DANGER, 3.0)

	if boss_next and screen != S.PICK and screen != S.MERCHANT:
		_draw_boss()

	if screen == S.PLAY or (screen == S.BOSS and b_dead_t < 0.0):
		# energia
		var born := clampf((now - orb_born) / 0.18, 0.0, 1.0)
		var pulse2 := (1.0 + 0.12 * sin(now * 8.0)) * born
		if _up("magnet") > 0:
			draw_arc(orb, 110.0 + 50.0 * _up("magnet"), 0, TAU, 48, Color(COL_ORB, 0.08), 2.0)
		draw_circle(orb, ORB_R * 2.6 * pulse2, Color(COL_ORB, 0.08))
		draw_circle(orb, ORB_R * 1.7 * pulse2, Color(COL_ORB, 0.16))
		if pulse2 > 0.05:
			_poly(orb, ORB_R * 1.25 * pulse2, 4, now * 1.5, COL_ORB)
			_poly(orb, ORB_R * 0.6 * pulse2, 4, now * 1.5, Color(1, 1, 1, 0.85))
		var ring := fposmod(now * 1.2, 1.0)
		draw_arc(orb, ORB_R * (1.2 + ring * 1.6), 0, TAU, 32, Color(COL_ORB, 0.5 * (1.0 - ring)), 2.0)
		# iskra
		if spark_t > 0.0:
			var sa := 1.0 if spark_t > 1.0 else (0.4 + 0.6 * absf(sin(now * 18.0)))
			draw_circle(spark_pos, 26.0, Color(COL_COIN, 0.12 * sa))
			_coin(spark_pos, 13.0 + 2.0 * sin(now * 6.0), sa)

	# hrac
	if screen == S.INTRO or screen == S.PLAY or screen == S.BOSS:
		var pr := _player_r()
		var pc := _pcol()
		_draw_trail(pr, pc)
		var blink := 1.0
		if invuln_t > 0.0:
			blink = 0.45 + 0.55 * absf(sin(now * 30.0))
		draw_circle(player, pr * 2.6, Color(pc, 0.07))
		draw_circle(player, pr * 1.8, Color(pc, 0.14))
		_shape(player, pr, int(D.SKINS[int(sv.skin)].shape), Color(pc, blink), p_dir.angle() + PI / 2.0)
		for s in _up("shield"):
			var a0 := now * 2.0 + s * TAU / 3.0
			draw_arc(player, pr + 9.0 + s * 5.0, a0, a0 + TAU * 0.7, 28, COL_SHIELD, 3.0)
		if screen == S.INTRO:
			var k2 := fposmod(intro_t * 1.5, 1.0)
			draw_arc(player, pr + 10.0 + k2 * 50.0, 0, TAU, 40, Color(pc, 0.7 * (1.0 - k2)), 3.0)


func _draw_trail(pr: float, pc: Color) -> void:
	var style := int(sv.trail)
	var lens := [9, 24, 8, 22, 16]
	var n := mini(ptrail.size(), int(lens[style]))
	for k in range(n - 1, 0, -1):
		var f := 1.0 - float(k) / n
		var p := ptrail[k]
		match style:
			1:
				draw_circle(p, pr * (0.25 + 0.7 * f), Color(pc, 0.5 * f))
			3:
				draw_circle(p, pr * (0.3 + 0.6 * f), Color.from_hsv(fposmod(now * 0.4 + k * 0.045, 1.0), 0.75, 1.0, 0.55 * f))
			4:
				if k % 2 == 0:
					var s := pr * (0.5 + 0.9 * f)
					draw_rect(Rect2((p - Vector2(s, s) / 2.0).snapped(Vector2(6, 6)), Vector2(s, s)), Color(pc, 0.6 * f))
			_:
				draw_circle(p, pr * (0.3 + 0.6 * f), Color(pc, 0.35 * f))


func _gcol(i: int) -> Color:
	# len fialova - ruzova - cervena - oranzova, aby sa ozveny neplietli s hracom
	return Color.from_hsv(fposmod(0.70 + fposmod(i * 0.085, 0.42), 1.0), 0.62, 1.0)


# ---------------------------------------------------------------- HUD

func _draw_hud() -> void:
	_txt(Vector2(34, 52), L("score"), 20, COL_DIM, -1, false)
	_txt(Vector2(34, 108), str(int(round(score_shown))), 58, COL_TEXT, -1)
	var sub := (L("today") % _daily_best_today()) if daily else (L("best") % int(sv.best))
	if camp:
		sub = "%d · %s" % [loc + 1, str(D.LOCS[loc].n[lang])]
	_txt(Vector2(34, 140), sub, 20, COL_DIM, -1, false)

	var rlabel := L("round_n") % maxi(round_num, 1)
	if boss_next:
		rlabel = str(D.BOSSES[b_id].n)
	elif camp:
		rlabel = L("round_of") % [loc_round, int(D.LOCS[loc].rounds)]
	_txt(Vector2(360, 62), rlabel, 34, COL_TEXT)
	for i in (0 if boss_next else ORBS_NEEDED):
		var c := Vector2(360 - 34 + i * 34, 96)
		if i < mini(orbs_got, ORBS_NEEDED):
			_poly(c, 11, 4, 0.0, COL_ORB)
		else:
			_poly(c, 11, 4, 0.0, Color(COL_DIM, 0.35))
	if orbs_got > ORBS_NEEDED and screen == S.PLAY:
		_txt(Vector2(360 + 62, 104), "+%d" % (orbs_got - ORBS_NEEDED), 22, COL_ORB, -1)
	if mod >= 0 and screen != S.PICK:
		var m: Dictionary = D.MODS[mod]
		_txt(Vector2(360, 146), str(m.n[lang]), 22, m.col)

	if screen == S.PLAY or screen == S.INTRO or screen == S.BOSS:
		_btn("pause", Rect2(622, 30, 68, 68), "", COL_DIM, "", 30)
		draw_rect(Rect2(645, 50, 8, 28), COL_TEXT)
		draw_rect(Rect2(660, 50, 8, 28), COL_TEXT)

	# casovac
	var bar := Rect2(ARENA.position.x, 170, ARENA.size.x, 12)
	var line: Color = TH.line
	_panel(bar, Color(line, 0.5), Color(0, 0, 0, 0), 0, 6)
	if screen == S.PLAY:
		var frac := clampf(1.0 - t / ROUND_TIME, 0.0, 1.0)
		var bc := _acc() if orbs_got >= ORBS_NEEDED else COL_ORB
		if frac < 0.3 and orbs_got < ORBS_NEEDED:
			bc = COL_DANGER
		if frac > 0.01:
			_panel(Rect2(bar.position, Vector2(maxf(12.0, bar.size.x * frac), bar.size.y)), bc, Color(0, 0, 0, 0), 0, 6, Color(bc, 0.4), 8)

	# kombo
	if combo >= 2 and screen == S.PLAY:
		var k := clampf(combo_t / (COMBO_TIME + _up("combo")), 0.0, 1.0)
		var cc := COL_ORB.lerp(COL_DANGER, clampf((combo - 2) / 6.0, 0.0, 1.0))
		_txt(Vector2(360, 262), L("combo") % combo, 30 + mini(combo, 8) * 2, Color(cc, 0.9), 0, true, true)
		draw_rect(Rect2(360 - 70, 274, 140 * k, 5), Color(cc, 0.8))

	# aktivne vylepsenia
	var x := ARENA.position.x + 4.0
	var y := 1232.0
	for u in D.UPG:
		var lv := _up(u.id)
		if lv <= 0 or u.id == "reroll":
			continue
		var uname: String = u.n[lang]
		var s := uname.split(" ")[0].left(6) + ((" %d" % lv) if lv > 1 else "")
		var w := _tw(s, 17, true) + 20.0
		if x + w > ARENA.end.x:
			x = ARENA.position.x + 4.0
			y += 30.0
		var rc: Color = D.RARITY_COL[int(u.r)]
		_panel(Rect2(x, y - 20, w, 26), Color(rc, 0.14), Color(rc, 0.7), 1, 8)
		_txt(Vector2(x + w / 2.0, y), s, 17, rc)
		x += w + 8.0

	# napoveda pre prvu hru
	if not bool(sv.tut) and screen == S.PLAY and t < 4.5:
		var hint := ""
		if round_num == 1:
			hint = L("tut1") if t < 2.5 else L("tut2")
		elif round_num == 2:
			hint = L("tut4")
		if hint != "":
			var w2 := _tw(hint, 26, false) + 50.0
			_panel(Rect2(360 - w2 / 2.0, 1110, w2, 54), Color(COL_DARK, 0.8), Color(_acc(), 0.6), 2, 27)
			_txt(Vector2(360, 1146), hint, 26, COL_TEXT, 0, false)


func _draw_intro() -> void:
	var k := clampf(intro_t / 0.25, 0.0, 1.0)
	var out := clampf((intro_len - intro_t) / 0.25, 0.0, 1.0)
	var a := k * out
	var cy := 560.0
	if boss_next:
		var bc: Color = D.BOSSES[b_id].col
		_txt(Vector2(360, cy + 120), L("boss"), 30, Color(bc, a))
		_txt(Vector2(360, cy + 210), str(D.BOSSES[b_id].n), int(92 * (0.8 + 0.2 * k)), Color(bc, a), 0, true, true)
		_txt(Vector2(360, cy + 262), L("boss_hint"), 26, Color(COL_TEXT, a), 0, false)
		return
	if camp and loc_round == 1:
		_txt(Vector2(360, cy - 90), L("loc_n") % (loc + 1), 30, Color(_acc(), a))
		_txt(Vector2(360, cy), str(D.LOCS[loc].n[lang]).to_upper(), 60, Color(COL_TEXT, a), 0, true, true)
		if mod >= 0:
			_txt(Vector2(360, cy + 54), str(D.MODS[mod].d[lang]), 26, Color(COL_ORB, a), 0, false)
		_txt(Vector2(360, cy + 104), L("round_of") % [loc_round, int(D.LOCS[loc].rounds)], 28, Color(COL_DIM, a))
		return
	if mod >= 0 and not camp:
		var m: Dictionary = D.MODS[mod]
		var mc: Color = m.col
		_txt(Vector2(360, cy - 90), L("special"), 30, Color(mc, a))
		_txt(Vector2(360, cy), str(m.n[lang]), int(84 * (0.8 + 0.2 * k)), Color(mc, a), 0, true, true)
		_txt(Vector2(360, cy + 56), str(m.d[lang]), 28, Color(COL_TEXT, a), 0, false)
		_txt(Vector2(360, cy + 110), L("round_n") % round_num, 30, Color(COL_DIM, a))
		return
	_txt(Vector2(360, cy), L("round_n") % round_num, int(84 * (0.8 + 0.2 * k)), Color(COL_TEXT, a), 0, true, true)
	var n := ghosts.size()
	var s := L("echo0")
	if n == 1:
		s = L("echo1")
	elif n >= 2 and n < 5:
		s = L("echo2") % n
	elif n >= 5:
		s = L("echo5") % n
	_txt(Vector2(360, cy + 52), s, 30, Color(COL_DIM, a), 0, false)
	if daily and round_num == 1:
		_txt(Vector2(360, cy + 100), L("daily") + " " + _today(), 24, Color(COL_ORB, a))
	if not bool(sv.tut):
		var l1 := ""
		var l2 := ""
		if round_num == 1:
			l1 = L("tut1")
			l2 = L("tut2")
		elif round_num == 2:
			l1 = L("tut3")
			l2 = L("tut4")
		elif round_num == 3:
			l1 = L("tut5")
		if l1 != "":
			_panel(Rect2(70, cy + 130, 580, 120 if l2 != "" else 76), Color(COL_DARK, 0.8 * a), Color(_acc(), 0.6 * a), 2, 20)
			_txt(Vector2(360, cy + 178), l1, 26, Color(COL_TEXT, a), 0, false)
			if l2 != "":
				_txt(Vector2(360, cy + 222), l2, 26, Color(COL_DANGER if round_num == 2 else COL_ORB, a))


# ---------------------------------------------------------------- vyber vylepsenia

func _draw_pick() -> void:
	draw_rect(Rect2(-origin, vp), Color(COL_DARK, 0.72))
	_txt(Vector2(360, 262), L("pick_title"), 44, COL_TEXT, 0, true, true)
	_txt(Vector2(360, 302), L("pick_sub") % round_num, 26, COL_DIM, 0, false)
	var fill: Color = TH.arena
	for i in cards.size():
		var u: Dictionary = D.UPG[cards[i]]
		var k := clampf((screen_t - i * 0.07) / 0.22, 0.0, 1.0)
		var ease_k := 1.0 - pow(1.0 - k, 3.0)
		var r := Rect2(70 + (1.0 - ease_k) * 500.0, 330 + i * 206, 580, 190)
		var rc: Color = D.RARITY_COL[int(u.r)]
		var rr := r
		if pressed_id == "pick:%d" % i and pressed_t > 0.0:
			rr = r.grow(-5.0)
		_panel(rr, Color(fill.lightened(0.05), 0.98 * ease_k), Color(rc, ease_k), 3, 22, Color(rc, 0.25 * ease_k), 14)
		_panel(Rect2(rr.position + Vector2(18, 18), Vector2(8, rr.size.y - 36)), Color(rc, ease_k), Color(0, 0, 0, 0), 0, 4)
		_txt(rr.position + Vector2(48, 62), str(u.n[lang]), 40, Color(rc, ease_k), -1)
		var lv := _up(u.id)
		var tag := L("new")
		if u.id == "erase" or u.id == "reroll":
			tag = L("once")
		elif lv > 0:
			tag = L("lvl") % [lv, lv + 1]
		_txt(Vector2(rr.end.x - 26, rr.position.y + 44), tag, 20, Color(COL_DIM, ease_k), 1, false)
		draw_multiline_string(font_m, rr.position + Vector2(48, 106), str(u.d[lang]), HORIZONTAL_ALIGNMENT_LEFT, 500, 25, 3, Color(COL_TEXT, ease_k))
		buttons.append([r, "pick:%d" % i])
	if rerolls > 0:
		_btn("reroll", Rect2(70, 962, 260, 70), L("reroll") % rerolls, COL_DIM, "", 26)


# ---------------------------------------------------------------- pauza, pokracovanie, koniec

func _draw_pause() -> void:
	draw_rect(Rect2(-origin, vp), Color(COL_DARK, 0.85))
	buttons.clear()
	_txt(Vector2(360, 420), L("paused"), 80, COL_TEXT, 0, true, true)
	_btn("resume", Rect2(160, 520, 400, 110), L("resume"), _acc(), "", 38, true)
	_btn("restart", Rect2(160, 660, 400, 90), L("restart"), COL_TEXT, "", 30)
	_btn("menu", Rect2(160, 780, 400, 90), L("menu"), COL_DIM, "", 30)


func _draw_revive() -> void:
	draw_rect(Rect2(-origin, vp), Color(COL_DARK, 0.85))
	_txt(Vector2(360, 380), L("revive_title"), 64, COL_TEXT, 0, true, true)
	draw_multiline_string(font_m, Vector2(110, 440), L("revive_sub") % round_num, HORIZONTAL_ALIGNMENT_CENTER, 500, 26, 3, COL_DIM)
	var left := clampf(1.0 - screen_t / 6.0, 0.0, 1.0)
	draw_arc(Vector2(360, 610), 60, -PI / 2.0, -PI / 2.0 + TAU * left, 48, _acc(), 8.0)
	_txt(Vector2(360, 630), str(int(ceil(6.0 - screen_t))), 56, COL_TEXT)
	var can := int(sv.coins) >= REVIVE_COST
	if Ads.rewarded_available():
		_btn("revive_ad", Rect2(110, 730, 500, 110), L("revive_ad"), _acc(), "", 32, true)
		if can:
			_btn("revive", Rect2(110, 860, 500, 90), L("revive_coins") % REVIVE_COST, COL_COIN, "", 30)
	elif can:
		_btn("revive", Rect2(110, 730, 500, 110), L("revive_coins") % REVIVE_COST, COL_COIN, "", 34, true)
	_coins_pill(Vector2(690, 76))
	_btn("skip", Rect2(210, 980, 300, 70), L("skip"), COL_DIM, "", 24)


func _draw_over() -> void:
	draw_rect(Rect2(-origin, vp), Color(COL_DARK, 0.8))
	var tt := screen_t
	var fill: Color = TH.arena
	var line: Color = TH.line
	var otitle := L("over_best") if over_new_best else L("over")
	if camp:
		otitle = L("camp_won") if camp_won else L("camp_dead")
	_txt(Vector2(360, 150), otitle, 50 if camp else 56, COL_ORB if over_new_best else COL_DANGER, 0, true, true)
	_txt(Vector2(360, 196), death_reason, 26, COL_DIM, 0, false)
	var shown := int(round(score * clampf(tt / 0.7, 0.0, 1.0)))
	_txt(Vector2(360, 340), str(shown), 140, COL_TEXT, 0, true, true)
	var sub := (L("today") % int(sv.daily_best)) if daily else (L("best") % int(sv.best))
	if camp:
		sub = "%s · %s" % [L("loc_n") % (loc + 1), str(D.LOCS[loc].n[lang])]
	_txt(Vector2(360, 386), sub, 26, COL_ORB if over_new_best else COL_DIM, 0, false)
	if daily:
		_txt(Vector2(360, 422), L("streak") % int(sv.streak), 24, COL_ORB)

	# styri stvorceky so statistikami
	var names := [L("rounds_done"), L("energy"), L("close_calls"), L("max_combo")]
	var nums := [round_num - 1, g_orbs, g_near, g_combo]
	for i in 4:
		var r := Rect2(48 + i * 158, 450, 150, 110)
		_panel(r, Color(fill.lightened(0.04), 0.95), Color(line, 0.9), 2, 16)
		_txt(Vector2(r.get_center().x, r.position.y + 56), str(nums[i]), 44, COL_TEXT)
		_txt(Vector2(r.get_center().x, r.position.y + 90), str(names[i]), 16, COL_DIM, 0, false)

	# odmeny
	var box := Rect2(48, 580, 624, 330)
	_panel(box, Color(fill.lightened(0.04), 0.95), Color(line, 0.9), 2, 20)
	_txt(Vector2(80, 632), L("earned"), 24, COL_DIM, -1, false)
	var coin_k := clampf((tt - 0.5) / 0.6, 0.0, 1.0)
	_txt(Vector2(616, 638), "+%d" % int(round(over_coins * coin_k)), 40, COL_COIN, 1)
	_coin(Vector2(636, 624), 12.0, 1.0)
	_level_bar(Rect2(80, 664, 560, 22), lerpf(over_xp_from, over_xp_to, clampf((tt - 0.6) / 0.8, 0.0, 1.0)))
	_txt(Vector2(80, 716), L("level") % over_level, 20, COL_DIM, -1)
	_txt(Vector2(640, 716), _rank(), 20, COL_DIM, 1, false)
	var y := 762.0
	for i in mini(over_lines.size(), 4):
		var a := clampf((tt - 0.8 - i * 0.2) / 0.25, 0.0, 1.0)
		var lc: Color = over_lines[i][1]
		_txt(Vector2(80 + (1.0 - a) * 40.0, y), str(over_lines[i][0]), 24, Color(lc, a), -1)
		y += 36.0
	if over_lines.is_empty():
		# ukaz rozpracovane misie ako ciel na dalsiu hru
		var missions: Array = sv.missions
		for i in mini(missions.size(), 3):
			var m: Dictionary = missions[i]
			_txt(Vector2(80, y), _mission_text(m), 22, COL_DIM, -1, false)
			_txt(Vector2(640, y), "%d/%d" % [mini(int(m.prog), int(m.target)), int(m.target)], 22, COL_DIM, 1)
			y += 40.0

	_btn("again", Rect2(110, 940, 500, 120), L("to_base") if camp else L("again"), _acc(), "", 42, true)
	_btn("menu", Rect2(110, 1084, 240, 84), L("menu"), COL_DIM, "", 28)
	_btn("share", Rect2(370, 1084, 240, 84), L("share"), COL_TEXT, "", 28)


# ---------------------------------------------------------------- menu

func _draw_menu() -> void:
	var fill: Color = TH.arena
	var line: Color = TH.line
	# ozdobne ozveny v pozadi
	for i in 5:
		var col := _gcol(i)
		for k in range(12, -1, -1):
			var tt := now * (0.35 + i * 0.05) - k * 0.035
			var p := Vector2(360 + sin(tt * 1.3 + i * 2.1) * 300.0, 640 + sin(tt * 0.9 + i * 1.3) * 520.0)
			draw_circle(p, 12.0 * (1.0 - k / 16.0), Color(col, 0.13 * (1.0 - k / 13.0)))

	_level_badge(Vector2(66, 76))
	_txt(Vector2(112, 66), _rank(), 22, COL_TEXT, -1)
	_level_bar(Rect2(112, 80, 190, 12), float(sv.xp) / _xp_need(int(sv.level)))
	_coins_pill(Vector2(690, 76))

	var title := "ECHO RUN"
	var ts := 104
	for k in range(3, 0, -1):
		var o := Vector2(sin(now * 1.1 + k * 1.7) * 9.0 * k, cos(now * 0.9 + k) * 5.0 * k)
		_txt(Vector2(360, 330) + o, title, ts, Color(_gcol(k * 2), 0.22))
	_txt(Vector2(360, 330), title, ts, _acc(), 0, true, true)
	_txt(Vector2(360, 386), L("tagline"), 28, COL_TEXT, 0, false)

	_btn("campaign", Rect2(110, 436, 500, 128), L("campaign"), _acc(), "%s · %s" % [L("best") % int(sv.best_camp), str(D.LOCS[mini(int(sv.cleared), D.LOCS.size() - 1)].n[lang])], 50, true)
	_btn("play", Rect2(110, 584, 244, 104), L("endless"), COL_TEXT, L("best") % int(sv.best), 28)
	var st := _streak_alive()
	var sub := L("today") % _daily_best_today()
	if st > 0:
		sub += " · " + (L("streak") % st)
	_btn("daily", Rect2(366, 584, 244, 104), L("daily").split(" ")[0], COL_ORB, sub, 28)
	if str(sv.daily_date) != _today():
		var bp := Vector2(598, 594)
		draw_circle(bp, 13.0 + 2.0 * sin(now * 5.0), COL_DANGER)
		_txt(bp + Vector2(0, 8), "!", 22, COL_TEXT)

	# misie
	var box := Rect2(60, 712, 600, 268)
	_panel(box, Color(fill, 0.88), Color(line, 0.9), 2, 22)
	_txt(Vector2(88, 752), L("missions"), 22, COL_DIM, -1)
	var missions: Array = sv.missions
	for i in missions.size():
		var m: Dictionary = missions[i]
		var y := 800.0 + i * 60.0
		_txt(Vector2(88, y), _mission_text(m), 23, COL_TEXT, -1, false)
		_txt(Vector2(612, y), "+%d" % int(m.rew), 23, COL_COIN, 1)
		_coin(Vector2(628, y - 8), 8.0, 1.0)
		var frac := clampf(float(m.prog) / float(m.target), 0.0, 1.0)
		_panel(Rect2(88, y + 12, 548, 8), Color(line, 0.6), Color(0, 0, 0, 0), 0, 4)
		if frac > 0.0:
			_panel(Rect2(88, y + 12, maxf(8.0, 548 * frac), 8), _acc(), Color(0, 0, 0, 0), 0, 4)

	_btn("shop", Rect2(60, 1004, 141, 96), L("shop"), COL_COIN, "", 22)
	_btn("scores", Rect2(213, 1004, 141, 96), L("scores"), COL_ORB, "", 20)
	_btn("profile", Rect2(366, 1004, 141, 96), L("profile"), COL_TEXT, "", 20)
	_btn("settings", Rect2(519, 1004, 141, 96), L("settings"), COL_DIM, "", 17)
	_txt(Vector2(360, 1236), "v" + VERSION, 18, Color(COL_DIM, 0.6), 0, false)
	_btn("set:lang", Rect2(60, 1130, 96, 54), "EN" if lang == 1 else "SK", COL_DIM, "", 22)
	_cores_pill(Vector2(660, 1158))


func _header(title: String) -> void:
	_btn("back", Rect2(30, 36, 150, 72), L("back"), COL_DIM, "", 24)
	_txt(Vector2(360, 88), title, 40, COL_TEXT)
	_coins_pill(Vector2(690, 72))


func _draw_shop() -> void:
	_header(L("shop"))
	var fill: Color = TH.arena
	var line: Color = TH.line
	var tabs := [L("skins"), L("trails"), L("themes"), L("music_tab")]
	for i in 4:
		var r := Rect2(48 + i * 158, 140, 150, 66)
		_btn("tab:%d" % i, r, str(tabs[i]), _acc() if i == shop_tab else COL_DIM, "", 22, i == shop_tab)
	if shop_tab == 3:
		_draw_music_shop()
		return
	var list: Array = [D.SKINS, D.TRAILS, D.THEMES][shop_tab]
	var owned: Array = sv[["own_skin", "own_trail", "own_theme"][shop_tab]]
	var used := int(sv[["skin", "trail", "theme"][shop_tab]])
	var cols := 3 if list.size() > 8 else 2
	var cw := 200.0 if cols == 3 else 304.0
	var chh := 176.0 if cols == 3 else 220.0
	var kk := 0.78 if cols == 3 else 1.0
	for i in list.size():
		var it: Dictionary = list[i]
		var r := Rect2(48 + (i % cols) * (cw + (12.0 if cols == 3 else 16.0)), 236 + int(i / float(cols)) * (chh + (14.0 if cols == 3 else 16.0)), cw, chh)
		var is_owned := i in owned
		var is_used := i == used
		var locked: bool = shop_tab == 0 and it.has("loc") and int(sv.cleared) < int(it.loc)
		var bc: Color = _acc() if is_used else (line if is_owned else Color(COL_DIM, 0.5))
		var rr := r.grow(-4.0) if (pressed_id == "item:%d" % i and pressed_t > 0.0) else r
		_panel(rr, Color(fill.lightened(0.04), 0.96), bc, 3 if is_used else 2, 20, Color(bc, 0.25 if is_used else 0.0), 12)
		var c := rr.position + Vector2(rr.size.x / 2.0, 82 * kk)
		match shop_tab:
			0:
				var col: Color = it.col
				if locked:
					_txt(c + Vector2(0, 18), "?", 54, Color(COL_DIM, 0.6))
				else:
					draw_circle(c, 52.0 * kk, Color(col, 0.10))
					_shape(c, 30.0 * kk, int(it.shape), col, sin(now * 1.5 + i) * 0.4)
			1:
				_trail_preview(c, i)
			2:
				var ia: Color = it.arena
				var il: Color = it.line
				var iacc: Color = it.accent
				_panel(Rect2(c - Vector2(90, 54), Vector2(180, 108)), ia, il, 3, 12)
				draw_circle(c + Vector2(-40, 10), 10, iacc)
				draw_circle(c + Vector2(30, -14), 9, Color(_gcol(1), 0.9))
				draw_circle(c + Vector2(30, -14), 4, ia)
				_poly(c + Vector2(50, 26), 9, 4, 0.0, COL_ORB)
		_txt(Vector2(rr.get_center().x, rr.position.y + chh - 54), "???" if locked else str(it.n[lang]), 21 if cols == 3 else 26, COL_TEXT)
		if locked:
			_txt(Vector2(rr.get_center().x, rr.position.y + chh - 24), L("loc_locked") % int(it.loc), 15, COL_DIM, 0, false)
		elif is_used:
			_txt(Vector2(rr.get_center().x, rr.position.y + chh - 22), L("equipped"), 20, _acc())
		elif is_owned:
			_txt(Vector2(rr.get_center().x, rr.position.y + chh - 22), L("owned"), 20, COL_DIM, 0, false)
		else:
			var can := int(sv.coins) >= int(it.price)
			var ps := str(int(it.price))
			var w := _tw(ps, 24, true)
			_txt(Vector2(rr.get_center().x - 10, rr.position.y + chh - 20), ps, 24, COL_COIN if can else COL_DIM)
			_coin(Vector2(rr.get_center().x + w / 2.0 + 6, rr.position.y + chh - 28), 9.0, 1.0 if can else 0.5)
		buttons.append([r, "item:%d" % i])


func _draw_music_shop() -> void:
	var fill: Color = TH.arena
	var line: Color = TH.line
	var owned: Array = sv.own_track
	var used := int(sv.track)
	for i in D.MUSIC.size():
		var m: Dictionary = D.MUSIC[i]
		var r := Rect2(48, 236 + i * 176, 624, 160)
		var is_owned := i in owned
		var is_used := i == used
		var avail := _track_available(i)
		var playing := preview_i == i
		var bc: Color = _acc() if is_used else (line if is_owned else Color(COL_DIM, 0.5))
		_panel(r, Color(fill.lightened(0.04), 0.96), bc, 3 if is_used else 2, 20, Color(bc, 0.25 if is_used else 0.0), 12)
		# tlacidlo ukazky: skladbu si mozes vypocut pred kupou
		var pc := Vector2(r.position.x + 76, r.get_center().y)
		var pcol := COL_ORB if playing else (COL_TEXT if avail else Color(COL_DIM, 0.4))
		draw_circle(pc, 46.0, Color(pcol, 0.12))
		draw_arc(pc, 46.0, 0, TAU, 48, Color(pcol, 0.9), 3.0)
		if playing:
			draw_arc(pc, 54.0, -PI / 2.0, -PI / 2.0 + TAU * clampf(preview_t / PREVIEW_TIME, 0.0, 1.0), 48, COL_ORB, 4.0)
			draw_rect(Rect2(pc - Vector2(14, 14), Vector2(28, 28)), pcol)
		else:
			draw_colored_polygon(PackedVector2Array([pc + Vector2(-12, -19), pc + Vector2(21, 0), pc + Vector2(-12, 19)]), pcol)
		if avail:
			buttons.append([Rect2(pc - Vector2(58, 58), Vector2(116, 116)), "prev:%d" % i])
		# nazov, autor, kredit
		var tx := r.position.x + 150.0
		_txt(Vector2(tx, r.position.y + 64), str(m.n), 30, COL_TEXT if avail else COL_DIM, -1)
		_txt(Vector2(tx, r.position.y + 98), str(m.by), 21, COL_DIM, -1, false)
		if str(m.get("credit", "")) != "":
			_txt(Vector2(tx, r.position.y + 126), str(m.credit), 16, Color(COL_DIM, 0.75), -1, false)
		if playing or (is_used and bool(sv.music) and preview_i < 0):
			var ex := tx + _tw(str(m.n), 30, true) + 16.0
			for k in 4:
				var h := 8.0 + 18.0 * absf(sin(now * (5.0 + k * 1.7) + k))
				draw_rect(Rect2(ex + k * 9.0, r.position.y + 64 - h, 6, h), COL_ORB if playing else _acc())
		# vpravo: pouzivas / pouzit / cena
		var br := Rect2(r.end.x - 200, r.get_center().y - 34, 180, 68)
		var bcen := br.get_center()
		if not avail:
			_txt(bcen + Vector2(0, 8), L("soon"), 22, COL_DIM)
		elif is_used:
			_txt(bcen + Vector2(0, 8), L("equipped"), 22, _acc())
		elif is_owned:
			_btn("item:%d" % i, br, L("use"), COL_TEXT, "", 24)
		else:
			var can := int(sv.coins) >= int(m.price)
			_btn("item:%d" % i, br, "", COL_COIN if can else COL_DIM, "", 24)
			var ps := str(int(m.price))
			var w := _tw(ps, 26, true)
			_txt(Vector2(bcen.x - 12, bcen.y + 10), ps, 26, COL_COIN if can else COL_DIM)
			_coin(Vector2(bcen.x + w / 2.0 + 6, bcen.y), 9.0, 1.0 if can else 0.5)


func _trail_preview(c: Vector2, style: int) -> void:
	var pc := _pcol()
	var lens := [9, 24, 8, 22, 16]
	var n := int(lens[style])
	for k in range(n - 1, -1, -1):
		var f := 1.0 - float(k) / n
		var tt := now * 3.0 - k * 0.09
		var p := c + Vector2(cos(tt) * 62.0, sin(tt * 2.0) * 26.0)
		match style:
			1:
				draw_circle(p, 14.0 * (0.25 + 0.7 * f), Color(pc, 0.5 * f))
			2:
				draw_circle(p, 14.0 * (0.3 + 0.6 * f), Color(pc, 0.35 * f))
				if k % 3 == 0:
					draw_circle(p + Vector2(sin(k * 9.1) * 14.0, cos(k * 5.3) * 14.0), 3.0, Color(pc, f))
			3:
				draw_circle(p, 14.0 * (0.3 + 0.6 * f), Color.from_hsv(fposmod(now * 0.4 + k * 0.045, 1.0), 0.75, 1.0, 0.55 * f))
			4:
				if k % 2 == 0:
					var s := 14.0 * (0.5 + 0.9 * f)
					draw_rect(Rect2((p - Vector2(s, s) / 2.0).snapped(Vector2(6, 6)), Vector2(s, s)), Color(pc, 0.6 * f))
			_:
				draw_circle(p, 14.0 * (0.3 + 0.6 * f), Color(pc, 0.35 * f))
		if k == 0:
			draw_circle(p, 14.0, pc)


func _draw_profile() -> void:
	_header(L("profile"))
	var fill: Color = TH.arena
	var line: Color = TH.line
	_panel(Rect2(48, 140, 624, 150), Color(fill, 0.9), Color(line, 0.9), 2, 22)
	_level_badge(Vector2(118, 214), 46.0)
	_txt(Vector2(190, 200), _player_name(), 34, COL_TEXT, -1)
	_txt(Vector2(190, 232), "%s · %s" % [L("level") % int(sv.level), _rank() if _logged_in() else L("not_logged")], 20, COL_DIM, -1, false)
	_btn("acct", Rect2(476, 154, 180, 52), L("logout") if _logged_in() else L("login_btn"), COL_DIM if _logged_in() else _acc(), "", 20, not _logged_in())

	_level_bar(Rect2(190, 246, 440, 16), float(sv.xp) / _xp_need(int(sv.level)))
	_txt(Vector2(630, 232), "%d / %d" % [int(sv.xp), _xp_need(int(sv.level))], 18, COL_DIM, 1, false)

	_txt(Vector2(60, 344), L("stats"), 24, COL_DIM, -1)
	var st: Dictionary = sv.st
	var names := [L("st_best"), L("st_round"), L("st_games"), L("st_orbs"), L("st_near"), L("st_combo"), L("st_streak")]
	var nums := [int(sv.best), int(st.best_round), int(st.games), int(st.orbs), int(st.near), int(st.combo), int(sv.best_streak)]
	for i in names.size():
		var y := 392.0 + i * 54.0
		_panel(Rect2(48, y - 34, 624, 46), Color(fill, 0.7 if i % 2 == 0 else 0.4), Color(0, 0, 0, 0), 0, 10)
		_txt(Vector2(72, y), str(names[i]), 24, COL_TEXT, -1, false)
		_txt(Vector2(648, y), str(nums[i]), 26, _acc(), 1)

	# denna vyzva - poslednych 7 dni
	_txt(Vector2(60, 810), L("week"), 22, COL_DIM, -1)
	_panel(Rect2(48, 830, 624, 300), Color(fill, 0.9), Color(line, 0.9), 2, 22)
	var hist: Dictionary = sv.history
	var base := int(Time.get_unix_time_from_datetime_string(_today() + "T00:00:00"))
	var mx := 1
	var vals: Array[int] = []
	var labels: Array[String] = []
	for k in range(6, -1, -1):
		var u := base - k * 86400
		var v := int(hist.get(Time.get_date_string_from_unix_time(u), 0))
		vals.append(v)
		mx = maxi(mx, v)
		var wd := (int(Time.get_date_dict_from_unix_time(u).weekday) + 6) % 7
		labels.append(L("days").substr(wd * 2, 2))
	for i in 7:
		var cx := 104.0 + i * 85.0
		var h := 170.0 * float(vals[i]) / mx
		var col := COL_ORB if i == 6 else _acc()
		_panel(Rect2(cx - 24, 1060 - maxf(h, 6.0), 48, maxf(h, 6.0)), Color(col, 0.9 if vals[i] > 0 else 0.2), Color(0, 0, 0, 0), 0, 3)
		if vals[i] > 0:
			_txt(Vector2(cx, 1050 - h), str(vals[i]), 20, COL_TEXT)
		_txt(Vector2(cx, 1100), labels[i], 20, COL_ORB if i == 6 else COL_DIM, 0, false)


func _draw_settings() -> void:
	_header(L("settings"))
	var fill: Color = TH.arena
	var line: Color = TH.line
	var keys := ["sound", "music", "vibra", "shake", "ctrl", "sens", "lang"]
	for i in keys.size():
		var key: String = keys[i]
		var y := 160.0 + i * 104.0
		var val := ""
		var active := true
		match key:
			"sens":
				val = L("sens%d" % int(sv.sens))
			"ctrl":
				val = L("ctrl%d" % int(sv.ctrl))
			"lang":
				val = "SLOVENSKY" if lang == 0 else "ENGLISH"
			_:
				active = bool(sv[key])
				val = L("on") if active else L("off")
		_panel(Rect2(48, y, 624, 90), Color(fill, 0.9), Color(line, 0.9), 2, 20)
		_txt(Vector2(80, y + 56), L(key), 27, COL_TEXT, -1, false)
		_btn("set:" + key, Rect2(436, y + 12, 216, 66), val, _acc() if active else COL_DIM, "", 24, active)
	var ry := 160.0 + keys.size() * 104.0 + 30.0
	_btn("set:reset", Rect2(160, ry, 400, 76), L("reset2") if reset_armed > 0.0 else L("reset"), COL_DANGER, "", 24, reset_armed > 0.0)
	_txt(Vector2(360, 1210), "Echo Run v%s  ·  a game by shadyyk" % VERSION, 18, Color(COL_DIM, 0.6), 0, false)
	_txt(Vector2(360, 1238), "music: shadyyk, loop by Prodambien  ·  font: Chakra Petch (OFL)", 16, Color(COL_DIM, 0.5), 0, false)


# ---------------------------------------------------------------- stavebne prvky UI

func _panel(r: Rect2, fill: Color, border: Color, bw: int, rad: int, glow := Color(0, 0, 0, 0), glow_size := 0) -> void:
	sbox.bg_color = fill
	sbox.border_color = border
	sbox.set_border_width_all(bw)
	sbox.set_corner_radius_all(rad)
	sbox.shadow_color = glow
	sbox.shadow_size = glow_size
	draw_style_box(sbox, r)


func _btn(id: String, r: Rect2, label: String, col: Color, sub := "", fsize := 36, filled := false) -> void:
	var rr := r
	if pressed_id == id and pressed_t > 0.0:
		rr = r.grow(-5.0 * pressed_t / 0.15)
	var tc := col
	var fill: Color = TH.arena
	if filled:
		_panel(rr, col, Color(1, 1, 1, 0.25), 2, 22, Color(col, 0.35), 18)
		tc = COL_DARK
	else:
		_panel(rr, Color(fill.lightened(0.05), 0.95), Color(col, 0.9), 3, 22)
	var c := rr.get_center()
	if label != "":
		if sub == "":
			_txt(Vector2(c.x, c.y + fsize * 0.36), label, fsize, tc)
		else:
			_txt(Vector2(c.x, c.y + fsize * 0.18), label, fsize, tc)
			_txt(Vector2(c.x, c.y + fsize * 0.18 + 32), sub, 21, Color(tc, 0.75) if filled else COL_DIM, 0, false)
	buttons.append([r, id])


func _tw(s: String, size: int, bold: bool) -> float:
	return (font_b if bold else font_m).get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


## align: -1 vlavo, 0 stred, 1 vpravo
func _txt(pos: Vector2, s: String, size: int, col: Color, align := 0, bold := true, outline := false) -> void:
	var f := font_b if bold else font_m
	var x := pos.x
	if align != -1:
		var w := f.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		x -= (w / 2.0) if align == 0 else w
	if outline:
		draw_string_outline(f, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, maxi(4, int(size / 7.0)), Color(COL_DARK, col.a * 0.85))
	draw_string(f, Vector2(x, pos.y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, size, col)


func _poly(c: Vector2, r: float, sides: int, rot: float, col: Color) -> void:
	if r < 0.5:
		return
	var pts := PackedVector2Array()
	for i in sides:
		var a := rot + TAU * i / sides - PI / 2.0
		pts.append(c + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(pts, col)


func _shape(c: Vector2, r: float, shape: int, col: Color, rot: float) -> void:
	match shape:
		1:
			_poly(c, r * 1.25, 4, rot + PI / 4.0, col)
		2:
			var pts := PackedVector2Array()
			for v in [Vector2(0, -1.45), Vector2(0.95, 0), Vector2(0, 1.45), Vector2(-0.95, 0)]:
				pts.append(c + (v * r).rotated(rot))
			draw_colored_polygon(pts, col)
		3:
			_poly(c, r * 1.4, 3, rot, col)
		4:
			var pts2 := PackedVector2Array()
			for i in 10:
				var a := rot + TAU * i / 10.0 - PI / 2.0
				pts2.append(c + Vector2(cos(a), sin(a)) * r * (1.5 if i % 2 == 0 else 0.7))
			draw_colored_polygon(pts2, col)
		5:
			_poly(c, r * 1.2, 6, rot, col)
		6:
			var hole: Color = TH.arena
			draw_circle(c, r * 1.1, col)
			draw_circle(c, r * 0.68, Color(hole, col.a))
			draw_circle(c, r * 0.3, col)
		7:
			draw_circle(c, r * 1.1, col)
			var look := Vector2(0, -1).rotated(rot) * r * 0.35
			draw_circle(c + look, r * 0.55, Color(COL_DARK, col.a))
			draw_circle(c + look * 1.3 + Vector2(-r * 0.15, -r * 0.15), r * 0.16, Color(1, 1, 1, col.a))
		_:
			draw_circle(c, r, col)
			draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.28, Color(1, 1, 1, 0.35 * col.a))


func _coin(c: Vector2, r: float, a := 1.0) -> void:
	_poly(c, r * 1.25, 4, 0.0, Color(COL_COIN, a))
	_poly(c, r * 0.55, 4, 0.0, Color(1, 1, 1, 0.7 * a))


func _coins_pill(right: Vector2) -> void:
	var s := str(int(sv.coins))
	var w := _tw(s, 28, true) + 70.0
	var r := Rect2(right.x - w, right.y - 30, w, 56)
	var fill: Color = TH.arena
	_panel(r, Color(fill.lightened(0.05), 0.95), Color(COL_COIN, 0.7), 2, 28)
	_coin(Vector2(r.position.x + 28, r.get_center().y), 11.0)
	_txt(Vector2(r.end.x - 20, r.get_center().y + 10), s, 28, COL_TEXT, 1)


func _level_badge(c: Vector2, r := 34.0) -> void:
	var fill: Color = TH.arena
	draw_circle(c, r + 6.0, Color(_acc(), 0.18))
	_poly(c, r, 6, now * 0.2, _acc())
	_poly(c, r - 5.0, 6, now * 0.2, fill)
	_txt(c + Vector2(0, r * 0.3), str(int(sv.level)), int(r * 0.85), COL_TEXT)


func _level_bar(r: Rect2, frac: float) -> void:
	var line: Color = TH.line
	_panel(r, Color(line, 0.6), Color(0, 0, 0, 0), 0, int(r.size.y / 2.0))
	var f := clampf(frac, 0.0, 1.0)
	if f > 0.0:
		_panel(Rect2(r.position, Vector2(maxf(r.size.y, r.size.x * f), r.size.y)), _acc(), Color(0, 0, 0, 0), 0, int(r.size.y / 2.0), Color(_acc(), 0.35), 6)


# ================================================================ KAMPAN
# Rogue-like vyprava cez lokality. Kazda lokalita = par kol povodnej hry + boss.
# Lod ma trup (zivoty); ked sa minie, casove zariadenie ta vrati na zakladnu.
# Za jadra sa na zakladni kupuju trvale schopnosti (strom schopnosti).

func _sk(id: String) -> bool:
	var skills: Array = sv.skills
	return id in skills


func _reset_skills() -> void:
	sk_grace = 0.0
	sk_thin = 1.0
	sk_slow = 1.0
	sk_pts = 1.0
	sk_near = 1
	sk_combo = 0.0
	sk_inv = 0.0
	rar_w = [60, 30, 10]


func _open_base() -> void:
	paused = false
	base_who = 0
	base_line = L("story")
	base_talk_t = 3.0
	_go(S.BASE)


func _start_campaign() -> void:
	camp_pending = true
	start_game(false)


func _camp_setup() -> void:
	camp_won = false
	loc = 0
	loc_round = 0
	g_cores = 0
	praise_n = 0
	hull_max = 3 + int(_sk("hull1")) + int(_sk("hull2")) + int(_sk("hull3"))
	hull = hull_max
	sk_grace = 0.3 if _sk("grace") else 0.0
	sk_thin = 0.92 if _sk("thin") else 1.0
	sk_slow = 0.92 if _sk("slow") else 1.0
	sk_pts = 1.0 + 0.25 * int(_sk("pts1")) + 0.25 * int(_sk("pts2"))
	sk_near = 2 if _sk("near") else 1
	sk_combo = 1.0 if _sk("combo") else 0.0
	sk_inv = 0.5 if _sk("inv") else 0.0
	rerolls = 1 + int(_sk("rr1")) + int(_sk("rr2"))
	rar_w = [60, 30, 10]
	if _sk("rare"):
		rar_w = [50, 38, 12]
	if _sk("epic"):
		rar_w[2] = int(rar_w[2]) + 8
	if _sk("shield"):
		up["shield"] = 1
	if _sk("mag"):
		up["magnet"] = 1
	if _sk("blink"):
		up["blink"] = 1
	if _sk("last"):
		up["second"] = 1
	if _sk("card"):
		var opts := ["small", "bonus", "grace", "combo", "coins"]
		var pick: String = opts[randi() % opts.size()]
		up[pick] = _up(pick) + 1
	TH = D.THEMES[int(D.LOCS[0].theme)]


func _loc_mod() -> int:
	var m: String = D.LOCS[loc].mod
	if m == "":
		return -1
	if m == "random":
		return rng.randi_range(0, D.MODS.size() - 1)
	for i in D.MODS.size():
		if str(D.MODS[i].id) == m:
			return i
	return -1


func _say(who: int, key: String, arg := -1) -> void:
	var text := L(key)
	if arg >= 0:
		text = text % arg
	dlg_who = who
	dlg_text = text
	dlg_t = DLG_LEN
	_play("card", 0.8 + 0.15 * who)


func _hull_hit(reason: String, by: int) -> void:
	if invuln_t > 0.0:
		return
	if _up("shield") > 0:
		up["shield"] = _up("shield") - 1
		g_blocks += 1
		invuln_t = 0.7
		flash = 0.7
		flash_col = COL_SHIELD
		shake = 12.0
		_burst(player, COL_SHIELD, 24, 360.0)
		_popup(player + Vector2(0, -46), L("shield_pop"), COL_SHIELD, 38)
		_play("shield")
		_vibrate(60)
		return
	if not god:
		hull -= 1
	round_hits += 1
	invuln_t = 1.2 + sk_inv
	flash = 0.8
	flash_col = COL_DANGER
	shake = 18.0
	_burst(player, COL_DANGER, 26, 400.0)
	_popup(player + Vector2(0, -46), L("hull_pop"), COL_DANGER, 38)
	_play("shield", 0.7)
	_vibrate(100)
	if hull <= 0:
		_die(reason, by)
	elif not camp:
		pass
	elif hull == 1:
		_say(2, "riot_last")
	else:
		_say(2, "riot_hit%d" % (1 + randi() % 2), hull)


func _camp_finish() -> void:
	var cores := int(g_cores * (1.25 if _sk("core2") else 1.0))
	sv.cores = int(sv.cores) + cores
	sv.camp_runs = int(sv.camp_runs) + 1
	if camp_won:
		sv.camp_wins = int(sv.camp_wins) + 1
	over_new_best = camp_won
	over_lines.append([L("cores_gain") % cores, COL_CORE])
	_apply_theme()


# ---------------------------------------------------------------- boss

func _start_boss_intro(which: int) -> void:
	boss_next = true
	b_id = which
	mod = -1
	screen = S.INTRO
	screen_t = 0.0
	intro_t = 0.0
	intro_len = 2.8
	ghost_off.resize(ghosts.size())
	ghost_off.fill(false)
	near_done.resize(ghosts.size())
	near_done.fill(false)
	if _sk("few") and camp:
		for i in maxi(0, ghosts.size() - 3):
			ghost_off[i] = true
	if not camp:
		# v endless by vsetky ozveny naraz boli pri bossovi nehratelne: ostavaju 4 najnovsie
		for i in maxi(0, ghosts.size() - 4):
			ghost_off[i] = true
	player = Vector2(360, 1040)
	ptrail.clear()
	recording = PackedVector2Array()
	orbs_got = 0
	invuln_t = 0.0
	spark_t = 0.0
	spark_at = -1.0
	bullets.clear()
	gun_fx.clear()
	b_max = int(D.BOSSES[b_id].hp)
	if not camp:
		b_max = int(b_max * 0.6) + int(round_num / 5.0)
	b_hp = b_max
	b_pos = Vector2(360, 430)
	b_dead_t = -1.0
	b_hit = 0.0
	b_state = 0
	_play("special")
	if camp:
		_say(0, "vex_boss")
	_log("BOSS %s (lokalita %d), trup %d/%d" % [str(D.BOSSES[b_id].n), loc + 1, hull, hull_max])


func _start_boss() -> void:
	screen = S.BOSS
	mouse_live = false
	screen_t = 0.0
	t = 0.0
	frame = 0
	combo = 0
	combo_t = 0.0
	b_t = 0.0
	b_cd1 = 1.0
	b_cd3 = 0.0
	b_ang = -PI / 2.0
	b_spiral = 0.0
	b_state = 0
	b_st_t = 0.0
	orb = _boss_orb_point(player)
	orb_born = now


func _boss_orb_point(from: Vector2) -> Vector2:
	var p := _next_orb(from)
	for i in 12:
		if p.distance_to(b_pos) > 190.0:
			break
		p = _next_orb(from)
	return p


func _tick_boss(delta: float) -> void:
	_steer(delta)
	var moved := Vector2.ZERO
	if not ptrail.is_empty():
		moved = player - ptrail[0]
	if moved.length() > 2.0:
		p_dir = p_dir.lerp(moved.normalized(), 0.35).normalized()
		if p_dir == Vector2.ZERO:
			p_dir = Vector2.UP
	ptrail.push_front(player)
	if ptrail.size() > 26:
		ptrail.pop_back()
	if combo_t > 0.0:
		combo_t -= delta
		if combo_t <= 0.0:
			combo = 0
	invuln_t = maxf(0.0, invuln_t - delta)
	b_hit = maxf(0.0, b_hit - delta)
	for g in gun_fx:
		g[2] -= delta * 3.0
	gun_fx = gun_fx.filter(func(g): return g[2] > 0.0)

	# boss je zniceny: chvilu vybuchuje, potom obchodnik alebo koniec kampane
	if b_dead_t >= 0.0:
		var before := int(b_dead_t * 8.0)
		b_dead_t += delta
		if int(b_dead_t * 8.0) != before:
			var bc: Color = D.BOSSES[b_id].col
			_burst(b_pos + Vector2(randf_range(-60, 60), randf_range(-60, 60)), bc, 14, 420.0)
			shake = maxf(shake, 10.0)
		if b_dead_t > 1.8:
			_boss_done()
		return

	# energia = strela z hlavneho dela
	var mg := _up("magnet")
	if mg > 0:
		var d := orb.distance_to(player)
		if d < 110.0 + 50.0 * mg and d > 1.0:
			orb += (player - orb).normalized() * (140.0 + 60.0 * mg) * delta
	if player.distance_to(orb) < _player_r() + ORB_R + 4.0 * mg:
		_boss_take_orb()
		if b_dead_t >= 0.0:
			return

	# ozveny z tejto lokality sa prehravaju v 8-sekundovej slucke
	t = frame / 60.0
	if t > _grace():
		_check_ghosts()
		if screen != S.BOSS:
			return
	frame += 1
	if frame >= 480:
		frame = 0
		near_done.fill(false)

	b_t += delta
	_boss_ai(delta)
	if screen != S.BOSS:
		return

	var pr := _player_r()
	var area := ARENA.grow(24.0)
	var keep: Array = []
	for b in bullets:
		var vel: Vector2 = b[1]
		var p: Vector2 = b[0]
		p += vel * delta
		b[0] = p
		if not area.has_point(p):
			continue
		if invuln_t <= 0.0 and p.distance_to(player) < pr + 7.0:
			_hull_hit(L("hull_gone"), -1)
			if screen != S.BOSS:
				return
			continue
		keep.append(b)
	bullets = keep


func _boss_ai(delta: float) -> void:
	var enr := 1.35 if b_hp * 2 <= b_max else 1.0
	var pr := _player_r()
	if b_id != 3:
		var home := Vector2(360 + sin(b_t * 0.6) * 190.0, 430 + sin(b_t * 0.9) * 90.0)
		b_pos = b_pos.lerp(home, minf(1.0, delta * 1.5))
	elif b_state == 0:
		var roam := Vector2(360 + sin(b_t * 0.8) * 220.0, 520 + sin(b_t * 1.1) * 190.0)
		b_pos = b_pos.lerp(roam, minf(1.0, delta * 1.2))
	if b_t < 1.5:
		return
	b_cd1 -= delta * enr
	b_cd3 -= delta * enr
	match b_id:
		0:
			if b_cd1 <= 0.0:
				b_cd1 = 2.2
				_volley(10, 215.0, b_t)
		1:
			b_ang += 0.85 * enr * delta
			_arms_hit(2, 340.0, pr)
			if b_cd1 <= 0.0:
				b_cd1 = 2.8
				_aimed(3, 240.0)
		2:
			if b_cd3 <= 0.0:
				b_cd3 = 0.17
				b_spiral += 0.37
				_shoot(b_spiral, 165.0)
				_shoot(b_spiral + PI, 165.0)
			if b_cd1 <= 0.0:
				b_cd1 = 4.2
				_volley(8, 190.0, b_t)
		3:
			b_st_t += delta
			match b_state:
				0:
					if b_st_t > 1.5 / enr:
						b_state = 1
						b_st_t = 0.0
				1:
					if b_st_t < 0.6:
						b_target = player
					if b_st_t > 0.85:
						b_state = 2
						b_st_t = 0.0
						b_from = b_pos
						var d := (b_target - b_pos)
						b_target = _clamp_arena(b_pos + d.normalized() * (d.length() + 130.0))
				2:
					var k := minf(1.0, b_st_t / 0.38)
					b_pos = b_from.lerp(b_target, k)
					if k >= 1.0:
						b_state = 0
						b_st_t = 0.0
						_aimed(5, 230.0)
		_:
			b_ang += 0.6 * enr * delta
			_arms_hit(3, 300.0, pr)
			if screen != S.BOSS:
				return
			if b_cd3 <= 0.0:
				b_cd3 = 0.32
				b_spiral += 0.5
				_shoot(b_spiral, 170.0)
			if b_cd1 <= 0.0:
				b_cd1 = 3.6
				_volley(12, 200.0, b_t)
	if screen == S.BOSS and invuln_t <= 0.0 and player.distance_to(b_pos) < 44.0 + pr:
		_hull_hit(L("hull_gone"), -1)


func _shoot(angle: float, speed: float) -> void:
	if bullets.size() >= 240:
		return
	var d := Vector2(cos(angle), sin(angle))
	bullets.append([b_pos + d * 46.0, d * speed])


func _volley(n: int, speed: float, offset: float) -> void:
	for k in n:
		_shoot(offset + TAU * k / n, speed)
	_play("tick", 0.6)


func _aimed(n: int, speed: float) -> void:
	var base := (player - b_pos).angle()
	for k in n:
		_shoot(base + (k - (n - 1) / 2.0) * 0.22, speed)
	_play("tick", 0.8)


func _arms_hit(n: int, length: float, pr: float) -> void:
	if invuln_t > 0.0:
		return
	for k in n:
		var a := b_ang + TAU * k / n
		var d := Vector2(cos(a), sin(a))
		var cp := Geometry2D.get_closest_point_to_segment(player, b_pos + d * 50.0, b_pos + d * length)
		if player.distance_to(cp) < 11.0 + pr:
			_hull_hit(L("hull_gone"), -1)
			return


func _boss_take_orb() -> void:
	g_orbs += 1
	if combo_t > 0.0:
		combo += 1
	else:
		combo = 1
	combo_t = COMBO_TIME + 1.0 * _up("combo") + sk_combo
	g_combo = maxi(g_combo, combo)
	var value := int(round((2 + ghosts.size()) * (1.0 + 0.5 * _up("bonus")) * sk_pts * 2.0))
	score += value
	_popup(orb, "+%d" % value, COL_ORB, 36)
	_burst(orb, COL_ORB, 14, 280.0)
	_play("orb", 1.0 + 0.07 * mini(combo - 1, 10))
	_vibrate(15)
	if _up("blink") > 0:
		invuln_t = maxf(invuln_t, 0.5 * _up("blink"))
	b_hp -= 1 + int(_sk("gun"))
	b_hit = 0.25
	shake = maxf(shake, 8.0)
	gun_fx.append([player, b_pos, 1.0])
	var bc: Color = D.BOSSES[b_id].col
	_burst(b_pos, bc, 16, 340.0)
	_play("shield", 1.3)
	if b_hp <= 0:
		b_hp = 0
		b_dead_t = 0.0
		bullets.clear()
		shake = 26.0
		flash = 0.8
		flash_col = bc
		_popup(ARENA.get_center(), L("boss_down") % str(D.BOSSES[b_id].n), bc, 46)
		_play("die")
		_vibrate(200)
	else:
		orb = _boss_orb_point(orb)
		orb_born = now


func _boss_done() -> void:
	if not camp:
		score += 40 + 4 * round_num
		g_coins += 10
		g_special += 1
		_log("boss %s porazeny v endless, kolo %d, skore %d" % [str(D.BOSSES[b_id].n), round_num, score])
		_start_intro(false)
		return
	score += 60 * (loc + 1)
	g_coins += 10 + (15 if _sk("loot") else 0)
	g_cores += 3 * (loc + 1) + int(_sk("core1"))
	g_special += 1
	if _sk("rep") and hull < hull_max:
		hull += 1
	if loc + 1 > int(sv.cleared):
		sv.cleared = loc + 1
		g_cores += 5
		_save()
	_log("boss %s porazeny, trup %d/%d, skore %d" % [str(D.BOSSES[b_id].n), hull, hull_max, score])
	if loc >= D.LOCS.size() - 1:
		camp_won = true
		death_reason = ""
		_to_over()
		return
	_say(1, "nova_boss")
	_open_merchant()


# ---------------------------------------------------------------- obchodnik

func _open_merchant() -> void:
	screen = S.MERCHANT
	screen_t = 0.0
	fade = 0.5
	m_sold = [false, false, false, false]
	var pool: Array[int] = []
	for i in D.UPG.size():
		var u: Dictionary = D.UPG[i]
		if int(u.r) >= 1 and u.id != "erase" and u.id != "reroll" and _up(u.id) < int(u.max):
			if u.id == "second" and second_used:
				continue
			pool.append(i)
	m_card = pool[randi() % pool.size()] if not pool.is_empty() else -1
	_play("special", 1.4)


func _m_skin() -> int:
	# skin, ktory sa da najst len v prave vycistenej lokalite
	var owned: Array = sv.own_skin
	for i in D.SKINS.size():
		var it: Dictionary = D.SKINS[i]
		if it.has("loc") and int(it.loc) == loc + 1 and not (i in owned):
			return i
	return -1


func _m_price(i: int) -> int:
	var base := 0
	match i:
		0: base = 30
		1: base = 90
		2: base = 50
		_:
			var si := _m_skin()
			base = int(D.SKINS[si].price) if si >= 0 else 0
	return int(base * (0.75 if _sk("deal") else 1.0))


func _merchant_buy(i: int) -> void:
	if screen_t < 0.3 or bool(m_sold[i]):
		return
	if i == 0 and hull >= hull_max:
		_play("error")
		return
	if i == 2 and m_card < 0:
		return
	var price := _m_price(i)
	if int(sv.coins) < price:
		_toast(L("no_coins"))
		_play("error")
		return
	sv.coins = int(sv.coins) - price
	m_sold[i] = true
	match i:
		0:
			hull += 1
			_say(2, "riot_fix")
		1:
			hull_max += 1
			hull += 1
		2:
			var u: Dictionary = D.UPG[m_card]
			up[u.id] = _up(u.id) + 1
			_toast(str(u.n[lang]))
		_:
			var si := _m_skin()
			if si >= 0:
				var owned: Array = sv.own_skin
				owned.append(si)
				sv.skin = si
				_toast(L("bought"))
	_play("level")
	_vibrate(30)
	_save()


func _merchant_continue() -> void:
	if screen_t < 0.3:
		return
	loc += 1
	loc_round = 0
	ghosts.clear()
	TH = D.THEMES[int(D.LOCS[loc].theme)]
	fade = 0.8
	_start_intro(false)
	_say(1, "nova_loc")
	_log("lokalita %d: %s" % [loc + 1, str(D.LOCS[loc].n[1])])


# ---------------------------------------------------------------- strom schopnosti

func _skill_ok(i: int) -> bool:
	# uzol je dostupny, ak je prvy vo vetve alebo je kupeny uzol nad nim
	var sk: Array = D.SKILLS[i]
	return int(sk[2]) == 0 or _sk(str(D.SKILLS[i - 1][0]))


func _buy_skill() -> void:
	if tree_sel < 0:
		return
	var sk: Array = D.SKILLS[tree_sel]
	var id := str(sk[0])
	if _sk(id):
		return
	if not _skill_ok(tree_sel):
		_toast(L("tree_locked"))
		_play("error")
		return
	var cost := int(D.SKILL_COST[int(sk[2])])
	if int(sv.cores) < cost:
		_toast(L("need_cores"))
		_play("error")
		return
	sv.cores = int(sv.cores) - cost
	var skills: Array = sv.skills
	skills.append(id)
	_save()
	_toast(L("bought"))
	_play("level")
	_vibrate(40)
	var bc: Color = D.BRANCH_COL[int(sk[1])]
	_burst(Vector2(104 + int(sk[1]) * 128, 250 + int(sk[2]) * 124), bc, 30, 420.0)


# ================================================================ KRESLENIE KAMPANE

func _cores_pill(right: Vector2) -> void:
	var s := str(int(sv.cores))
	var w := _tw(s, 28, true) + 70.0
	var r := Rect2(right.x - w, right.y - 30, w, 56)
	var fill: Color = TH.arena
	_panel(r, Color(fill.lightened(0.05), 0.95), Color(COL_CORE, 0.7), 2, 28)
	_core_icon(Vector2(r.position.x + 28, r.get_center().y), 11.0)
	_txt(Vector2(r.end.x - 20, r.get_center().y + 10), s, 28, COL_TEXT, 1)


func _core_icon(c: Vector2, r: float, a := 1.0) -> void:
	_poly(c, r * 1.2, 6, 0.0, Color(COL_CORE, a))
	_poly(c, r * 0.55, 6, PI / 6.0, Color(1, 1, 1, 0.75 * a))


func _draw_hud_camp() -> void:
	# trup lode (len v kampani)
	for i in (hull_max if camp else 0):
		var x := 690.0 - (hull_max - i) * 26.0
		var on := i < hull
		_panel(Rect2(x, 118, 20, 26), Color(_acc(), 0.95) if on else Color(COL_DIM, 0.15), Color(_acc() if on else COL_DIM, 0.9), 2, 6)
	# zivot bossa namiesto casovaca
	if boss_next and screen != S.INTRO and screen != S.PICK and screen != S.MERCHANT:
		var bc: Color = D.BOSSES[b_id].col
		var bar := Rect2(ARENA.position.x, 166, ARENA.size.x, 20)
		var line: Color = TH.line
		_panel(bar, Color(line, 0.8), Color(bc, 0.9), 2, 10)
		var frac := clampf(float(b_hp) / float(b_max), 0.0, 1.0)
		if frac > 0.0:
			_panel(Rect2(bar.position, Vector2(maxf(20.0, bar.size.x * frac), bar.size.y)), Color(1, 1, 1, 1) if b_hit > 0.0 else bc, Color(0, 0, 0, 0), 0, 10, Color(bc, 0.5), 10)


func _draw_boss() -> void:
	var bc: Color = D.BOSSES[b_id].col
	var a := 1.0
	var sc := 1.0
	if screen == S.INTRO:
		a = clampf(intro_t / 1.0, 0.0, 1.0)
		sc = 0.6 + 0.4 * a
	if b_dead_t >= 0.0:
		a = clampf(1.0 - b_dead_t / 1.8, 0.0, 1.0)
		sc = 1.0 + b_dead_t * 0.3
	var col := Color(1, 1, 1, a) if b_hit > 0.0 else Color(bc, a)
	var hole: Color = TH.arena
	var fighting := screen == S.BOSS and b_dead_t < 0.0

	# ramena (pily) - nebezpecne po celej dlzke
	if (b_id == 1 or b_id == 4) and screen != S.INTRO and b_dead_t < 0.0:
		var arms := 2 if b_id == 1 else 3
		var length := 340.0 if b_id == 1 else 300.0
		for k in arms:
			var ang := b_ang + TAU * k / arms
			var d := Vector2(cos(ang), sin(ang))
			var n := Vector2(-d.y, d.x)
			draw_line(b_pos + d * 50.0, b_pos + d * length, Color(bc, 0.18 * a), 30.0)
			draw_line(b_pos + d * 50.0, b_pos + d * length, Color(bc, a), 9.0)
			var q := 70.0
			while q < length:
				var side := 1.0 if int(q / 26.0) % 2 == 0 else -1.0
				var base := b_pos + d * q
				draw_colored_polygon(PackedVector2Array([base - d * 9.0, base + d * 9.0, base + n * 15.0 * side]), Color(bc, a))
				q += 26.0
	# stopar: ciara, kam sa chysta skocit
	if b_id == 3 and fighting and b_state == 1:
		var blink := 0.35 + 0.35 * sin(now * 30.0)
		draw_line(b_pos, b_target, Color(bc, blink), 4.0)
		draw_arc(b_target, 26.0, 0, TAU, 24, Color(bc, blink), 3.0)

	draw_circle(b_pos, 96.0 * sc, Color(bc, 0.06 * a))
	draw_circle(b_pos, 70.0 * sc, Color(bc, 0.10 * a))
	match b_id:
		0:
			_poly(b_pos, 50.0 * sc, 6, now * 0.6, col)
			_poly(b_pos, 34.0 * sc, 6, now * 0.6, Color(hole, a))
			_poly(b_pos, 18.0 * sc, 6, -now * 1.2, col)
			for k in 6:
				var ang2 := -now * 0.9 + TAU * k / 6.0
				_poly(b_pos + Vector2(cos(ang2), sin(ang2)) * 68.0 * sc, 12.0 * sc, 3, ang2 + PI / 2.0, col)
		1:
			_poly(b_pos, 52.0 * sc, 4, b_ang, col)
			_poly(b_pos, 36.0 * sc, 4, b_ang, Color(hole, a))
			_poly(b_pos, 20.0 * sc, 8, -b_ang * 2.0, col)
		2:
			for k in 7:
				var ang3 := now * 0.5 + TAU * k / 6.0
				var o := Vector2.ZERO if k == 6 else Vector2(cos(ang3), sin(ang3)) * 36.0 * sc
				var rr := (22.0 + 4.0 * sin(now * 3.0 + k)) * sc
				draw_circle(b_pos + o, rr, col)
				draw_circle(b_pos + o, rr * 0.5, Color(hole, a))
		3:
			var look := (b_target - b_pos).angle() if b_state != 0 else (player - b_pos).angle()
			_poly(b_pos, 58.0 * sc, 3, look + PI / 2.0, col)
			_poly(b_pos, 30.0 * sc, 3, look + PI / 2.0, Color(hole, a))
			draw_circle(b_pos, 9.0 * sc, col)
		_:
			draw_arc(b_pos, 56.0 * sc, 0, TAU, 48, col, 8.0)
			for k in 12:
				var ang4 := TAU * k / 12.0
				var dd := Vector2(cos(ang4), sin(ang4))
				draw_line(b_pos + dd * 40.0 * sc, b_pos + dd * 50.0 * sc, col, 4.0)
			draw_circle(b_pos, 14.0 * sc, col)
			draw_line(b_pos, b_pos + Vector2(cos(now * 2.0), sin(now * 2.0)) * 38.0 * sc, col, 5.0)
			draw_line(b_pos, b_pos + Vector2(cos(-now * 0.5), sin(-now * 0.5)) * 26.0 * sc, col, 7.0)

	for b in bullets:
		var p: Vector2 = b[0]
		draw_circle(p, 14.0, Color(bc, 0.18))
		draw_circle(p, 8.0, bc)
		draw_circle(p, 3.5, Color(1, 1, 1, 0.9))
	for g in gun_fx:
		var life: float = g[2]
		draw_line(g[0], g[1], Color(COL_ORB, life), 3.0 + 9.0 * life)
		draw_line(g[0], g[1], Color(1, 1, 1, life), 2.0)


func _draw_dialog() -> void:
	# Radkyna vyskoci spoza praveho dolneho rohu (polovica postavy), titulky su dole.
	# Nezasahuje do kariet ani do areny; pocas hrania je mensia a priesvitna.
	if dlg_t <= 0.0 or dlg_who < 0:
		return
	var age := DLG_LEN - dlg_t
	var kin := clampf(age / 0.35, 0.0, 1.0)
	var pop := 1.0 + 2.70158 * pow(kin - 1.0, 3.0) + 1.70158 * pow(kin - 1.0, 2.0)   # dojazd s prekmitom
	var kout := clampf(dlg_t / 0.3, 0.0, 1.0)
	var playing := screen == S.PLAY or screen == S.BOSS
	var bottom := VIEW.y + origin.y            # skutocny spodok obrazovky (vysoke telefony maju miesto navyse)
	# mimo hrania: postava od y=965 az po spodok, vidno ju po boky; pocas hrania len vykukne z rohu
	var s := 0.8 if playing else clampf((bottom - 965.0) / 300.0, 1.0, 1.45)
	var a := (0.55 if playing else 1.0) * kout
	var base := Vector2(644, bottom - 58.0) if playing else Vector2(600, 965.0 + 76.0 * s)
	var c := base + Vector2(0, (1.0 - pop * kout) * 420.0)
	var col: Color = D.ADVISORS[dlg_who].col
	_portrait(c, s, dlg_who, age > 0.3 and dlg_t > 0.8, a, true)
	if age < 0.7:
		# ciarky "vykriku" pri vyskoceni
		for k in 3:
			var ang := PI + 0.35 + k * 0.38
			var d := Vector2(cos(ang), sin(ang))
			var r0 := (62.0 + age * 60.0) * s
			draw_line(c + d * r0, c + d * (r0 + 18.0 * s), Color(col, a * (1.0 - age / 0.7)), 4.0)
	var box := Rect2(36, bottom - 92.0, 470, 84)
	_panel(box, Color(COL_DARK, 0.86 * kout), Color(col, 0.85 * kout), 2, 14)
	_txt(Vector2(box.position.x + 18, box.position.y + 24), str(D.ADVISORS[dlg_who].n), 16, Color(col, kout), -1)
	draw_multiline_string(font_m, Vector2(box.position.x + 18, box.position.y + 46), dlg_text, HORIZONTAL_ALIGNMENT_CENTER, 434, 18, 2, Color(COL_TEXT, kout))


func _pp(pts: Array, c: Vector2, s: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in pts:
		var v: Vector2 = p
		out.append(c + v * s)
	return out


func _fill_line(pts: PackedVector2Array, col: Color, w: float, fill_a := 0.16) -> void:
	draw_colored_polygon(pts, Color(col, fill_a * col.a))
	var closed := pts.duplicate()
	closed.append(pts[0])
	draw_polyline(closed, col, w, true)


func _ell(c: Vector2, rx: float, ry: float, n := 22, a0 := 0.0, a1 := TAU) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in n:
		var a := a0 + (a1 - a0) * i / float(n - (0 if is_equal_approx(a1 - a0, TAU) else 1))
		out.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	return out


## Hladka krivka cez body (Catmull-Rom). Pouziva sa na obrysy postav.
func _smooth(pts: Array, c: Vector2, s: float, closed := true, seg := 5) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pts.size()
	var last := n if closed else n - 1
	for i in last:
		var p0: Vector2 = pts[(i - 1 + n) % n] if closed else pts[maxi(i - 1, 0)]
		var p1: Vector2 = pts[i]
		var p2: Vector2 = pts[(i + 1) % n]
		var p3: Vector2 = pts[(i + 2) % n] if closed else pts[mini(i + 2, n - 1)]
		for k in seg:
			var t := float(k) / seg
			var t2 := t * t
			var t3 := t2 * t
			var v := 0.5 * ((2.0 * p1) + (p2 - p0) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (3.0 * p1 - p0 - 3.0 * p2 + p3) * t3)
			out.append(c + v * s)
	if not closed:
		var e: Vector2 = pts[n - 1]
		out.append(c + e * s)
	return out


func _mirror(pts: Array) -> Array:
	var out: Array = []
	for p in pts:
		var v: Vector2 = p
		out.append(Vector2(-v.x, v.y))
	return out


func _stroke(pts: Array, c: Vector2, s: float, col: Color, w: float) -> void:
	draw_polyline(_smooth(pts, c, s, false), col, w, true)


func _eye(c: Vector2, s: float, side: float, col: Color, w: float, iris_r: float, lid: float, talking: bool) -> void:
	# side: -1 lave oko, +1 prave. lid: o kolko je viecko privrete (0 = otvorene)
	var e := c + Vector2(12.5 * side, -2.0) * s
	draw_circle(e + Vector2(0, 0.5 + lid * 0.5) * s, iris_r * s, col)
	draw_circle(e + Vector2(-1.2, -1.0 + lid * 0.5) * s, iris_r * 0.32 * s, Color(1, 1, 1, col.a))
	var blink := 0.0
	if not talking and fposmod(now * 0.31 + side * 0.01, 1.0) < 0.03:
		blink = 3.0
	_stroke([Vector2(-7.5 * side, 1.0), Vector2(-3.0 * side, -4.5 + lid + blink), Vector2(3.5 * side, -4.5 + lid + blink), Vector2(8.0 * side, -1.0 + blink * 0.3)], e, s, col, w * 1.25)
	draw_line(e + Vector2(8.0 * side, -1.0) * s, e + Vector2(11.5 * side, -4.5) * s, col, w)
	_stroke([Vector2(-5.0 * side, 4.0), Vector2(0, 5.2), Vector2(6.0 * side, 3.2)], e, s, Color(col, col.a * 0.55), maxf(1.0, w * 0.6))


## Radkyna: jedna farba (slaba vypln) + obrys. who: 0 VEX, 1 NOVA, 2 RIOT.
## half = polovica postavy (trup, pas, boky, ruka s gestom); inak len busta.
## Kazda ma iny uces, vyraz a inu animaciu pri hovoreni.
func _portrait(c: Vector2, s: float, who: int, talking: bool, alpha := 1.0, half := false) -> void:
	var base: Color = D.ADVISORS[who].col
	var col := Color(base, alpha)
	var soft := Color(base, alpha * 0.55)
	var w := maxf(1.4, 2.6 * s)
	var cc := c
	var sway := sin(now * 1.3 + who * 2.0) * 1.5 * s      # jemne dychanie / pohupovanie
	cc.y += sway
	if talking:
		match who:
			0:
				if fposmod(now * 5.0, 1.0) < 0.14:
					cc.x += 5.0 * s * sin(now * 80.0)
			1:
				cc.y += sin(now * 9.0) * 3.0 * s
			_:
				cc += Vector2(randf_range(-1.4, 1.4), randf_range(-1.4, 1.4)) * s

	# --- vlasy vzadu
	match who:
		0:
			_fill_line(_smooth([Vector2(-30, -30), Vector2(-40, 0), Vector2(-44, 44), Vector2(-36, 84), Vector2(-22, 70), Vector2(-24, 30),
				Vector2(24, 30), Vector2(26, 76), Vector2(42, 92), Vector2(48, 46), Vector2(42, -2), Vector2(30, -32), Vector2(0, -46)], cc, s), col, w, 0.2)
		1:
			var sw := sin(now * 2.2) * 4.0
			_fill_line(_smooth([Vector2(22, -42), Vector2(40, -72), Vector2(64, -68), Vector2(78 + sw, -28), Vector2(74 + sw, 26), Vector2(60 + sw, 62),
				Vector2(52 + sw, 52), Vector2(60, 12), Vector2(56, -24), Vector2(40, -40)], cc, s), col, w, 0.24)

	# --- telo
	if half:
		var torso := [Vector2(11, 58), Vector2(34, 66), Vector2(56, 78), Vector2(50, 108), Vector2(50, 132), Vector2(43, 158),
			Vector2(33, 194), Vector2(40, 226), Vector2(54, 264), Vector2(60, 310), Vector2(58, 352)]
		var all: Array = torso.duplicate()
		var left := _mirror(torso)
		left.reverse()
		all.append_array(left)
		_fill_line(_smooth(all, cc, s), col, w, 0.18)
		# ruky
		var arm_r := [Vector2(56, 80), Vector2(68, 104), Vector2(72, 160), Vector2(66, 222), Vector2(54, 224), Vector2(54, 160), Vector2(48, 116)]
		match who:
			0:
				_fill_line(_smooth(arm_r, cc, s), col, w, 0.16)
				_fill_line(_smooth([Vector2(-56, 80), Vector2(-70, 102), Vector2(-92, 168), Vector2(-64, 236), Vector2(-46, 232), Vector2(-52, 214),
					Vector2(-72, 172), Vector2(-48, 118)], cc, s), col, w, 0.16)
			1:
				_fill_line(_smooth(_mirror(arm_r), cc, s), col, w, 0.16)
				var wave := sin(now * 7.0) * 9.0 if talking else sin(now * 1.5) * 3.0
				_fill_line(_pp([Vector2(54, 86), Vector2(74, 100), Vector2(114 + wave, 28), Vector2(98 + wave, 20)], cc, s), col, w, 0.16)
				_fill_line(_ell(cc + Vector2(108 + wave, 12) * s, 11.0 * s, 13.0 * s, 14), col, w, 0.28)
				for f in 3:
					var fx := 100.0 + wave + f * 7.0
					draw_line(cc + Vector2(fx, 2) * s, cc + Vector2(fx - 1.0 + f, -10) * s, col, w)
			_:
				_fill_line(_smooth(arm_r, cc, s), col, w, 0.16)
				var punch := absf(sin(now * 9.0)) * 10.0 if talking else 0.0
				_fill_line(_pp([Vector2(-54, 86), Vector2(-74, 100), Vector2(-112, 30 - punch), Vector2(-96, 22 - punch)], cc, s), col, w, 0.16)
				_fill_line(_ell(cc + Vector2(-103, 14 - punch) * s, 14.0 * s, 14.0 * s, 14), col, w, 0.3)
		# oblecenie: vystrih, linia hrudnika, pas
		_stroke([Vector2(-13, 62), Vector2(-6, 82), Vector2(0, 98), Vector2(6, 82), Vector2(13, 62)], cc, s, col, w)
		_stroke([Vector2(-44, 118), Vector2(-34, 142), Vector2(-18, 148), Vector2(-4, 134)], cc, s, soft, w)
		_stroke([Vector2(44, 118), Vector2(34, 142), Vector2(18, 148), Vector2(4, 134)], cc, s, soft, w)
		match who:
			0:
				draw_line(cc + Vector2(0, 98) * s, cc + Vector2(0, 350) * s, soft, w)
				_stroke([Vector2(-34, 198), Vector2(0, 204), Vector2(34, 198)], cc, s, col, w)
				_stroke([Vector2(-33, 208), Vector2(0, 214), Vector2(33, 208)], cc, s, col, w)
			1:
				_stroke([Vector2(-42, 164), Vector2(-20, 174), Vector2(0, 170), Vector2(20, 174), Vector2(42, 164)], cc, s, col, w)
				_stroke([Vector2(-40, 232), Vector2(0, 244), Vector2(40, 232)], cc, s, soft, w)
				draw_line(cc + Vector2(-30, 70) * s, cc + Vector2(-38, 110) * s, soft, w)
				draw_line(cc + Vector2(30, 70) * s, cc + Vector2(38, 110) * s, soft, w)
			_:
				_stroke([Vector2(-34, 196), Vector2(0, 202), Vector2(34, 196)], cc, s, col, w * 1.4)
				draw_rect(Rect2(cc + Vector2(-7, 194) * s, Vector2(14, 12) * s), col)
				_stroke([Vector2(-46, 96), Vector2(-20, 108), Vector2(0, 104), Vector2(20, 108), Vector2(46, 96)], cc, s, soft, w)
				_fill_line(_pp([Vector2(48, 70), Vector2(76, 62), Vector2(70, 90), Vector2(52, 92)], cc, s), col, w, 0.3)
				_fill_line(_pp([Vector2(-48, 70), Vector2(-76, 62), Vector2(-70, 90), Vector2(-52, 92)], cc, s), col, w, 0.3)
	else:
		_fill_line(_smooth([Vector2(11, 58), Vector2(34, 66), Vector2(58, 80), Vector2(66, 112), Vector2(-66, 112), Vector2(-58, 80), Vector2(-34, 66), Vector2(-11, 58)], cc, s), col, w, 0.18)
		_stroke([Vector2(-13, 62), Vector2(-6, 82), Vector2(0, 98), Vector2(6, 82), Vector2(13, 62)], cc, s, col, w)

	# --- krk a hlava (brada sa zuzuje)
	_fill_line(_pp([Vector2(-9, 34), Vector2(9, 34), Vector2(11, 60), Vector2(-11, 60)], cc, s), col, w, 0.2)
	_fill_line(_smooth([Vector2(0, -40), Vector2(19, -36), Vector2(29, -18), Vector2(29, 4), Vector2(24, 22), Vector2(13, 36), Vector2(0, 42),
		Vector2(-13, 36), Vector2(-24, 22), Vector2(-29, 4), Vector2(-29, -18), Vector2(-19, -36)], cc, s), col, w, 0.24)

	# --- tvar
	var lid := 1.6 if who == 0 else 0.0
	var iris := 4.4 if who == 1 else 3.8
	if who == 0:
		_eye(cc, s, 1.0, col, w, iris, lid, talking)        # lave oko schovane pod ofinou
	else:
		_eye(cc, s, -1.0, col, w, iris, lid, talking)
		_eye(cc, s, 1.0, col, w, iris, lid, talking)
	match who:
		0:
			_stroke([Vector2(5, -13), Vector2(13, -17), Vector2(22, -13)], cc, s, col, w)
		1:
			_stroke([Vector2(5, -14), Vector2(13, -16), Vector2(21, -14)], cc, s, col, w)
			_stroke([Vector2(-5, -14), Vector2(-13, -16), Vector2(-21, -14)], cc, s, col, w)
		_:
			draw_line(cc + Vector2(21, -16) * s, cc + Vector2(6, -10) * s, col, w * 1.3)
			draw_line(cc + Vector2(-21, -16) * s, cc + Vector2(-6, -10) * s, col, w * 1.3)
			draw_line(cc + Vector2(15, -22) * s, cc + Vector2(20, 12) * s, soft, maxf(1.0, w * 0.7))
	_stroke([Vector2(1, 6), Vector2(3, 13), Vector2(0, 15)], cc, s, soft, maxf(1.0, w * 0.7))
	# pery
	var mc := cc + Vector2(0, 25) * s
	if talking:
		var open := (2.0 + 5.5 * absf(sin(now * 14.0 + who * 1.7))) * s
		var mouth := _ell(mc, 6.5 * s, open, 14)
		draw_colored_polygon(mouth, Color(base, alpha * 0.55))
		mouth.append(mouth[0])
		draw_polyline(mouth, col, w, true)
	else:
		var smile := 2.0 if who == 1 else (0.5 if who == 0 else -0.5)
		var tilt := 1.5 if who == 0 else 0.0
		var lips := _smooth([Vector2(-8, -1 - smile + tilt), Vector2(-3, -3), Vector2(0, -2), Vector2(3, -3), Vector2(8, -1 - smile - tilt),
			Vector2(4, 2.6), Vector2(0, 3.6), Vector2(-4, 2.6)], mc, s)
		draw_colored_polygon(lips, Color(base, alpha * 0.6))
		lips.append(lips[0])
		draw_polyline(lips, col, maxf(1.0, w * 0.7), true)

	# --- vlasy vpredu a doplnky
	match who:
		0:
			# dlhe vlasy s ofinou cez oko, obojok
			_fill_line(_smooth([Vector2(-32, 26), Vector2(-36, -8), Vector2(-28, -36), Vector2(-8, -49), Vector2(14, -48), Vector2(31, -34),
				Vector2(35, -8), Vector2(31, 20), Vector2(28, -4), Vector2(20, -24), Vector2(6, -30), Vector2(-2, -14), Vector2(-10, 2),
				Vector2(-22, 10), Vector2(-27, -4)], cc, s), col, w, 0.34)
			_stroke([Vector2(-6, -44), Vector2(-14, -20), Vector2(-18, 6)], cc, s, soft, maxf(1.0, w * 0.7))
			draw_line(cc + Vector2(-10, 47) * s, cc + Vector2(10, 47) * s, col, w * 1.6)
			draw_arc(cc + Vector2(29, 22) * s, 3.5 * s, 0, TAU, 10, col, maxf(1.0, w * 0.7))
		1:
			# ofina nabok, pramene pri tvari, sluchadlo
			_fill_line(_smooth([Vector2(-32, 12), Vector2(-36, -12), Vector2(-29, -36), Vector2(-9, -50), Vector2(14, -49), Vector2(31, -34),
				Vector2(36, -10), Vector2(32, 12), Vector2(28, -8), Vector2(17, -22), Vector2(2, -17), Vector2(-10, -25), Vector2(-22, -13),
				Vector2(-28, -2)], cc, s), col, w, 0.34)
			_stroke([Vector2(-30, 4), Vector2(-33, 26), Vector2(-28, 44)], cc, s, col, w)
			_stroke([Vector2(30, 4), Vector2(33, 24), Vector2(29, 40)], cc, s, col, w)
			draw_circle(cc + Vector2(-31, 4) * s, 5.0 * s, col)
			_stroke([Vector2(-31, 8), Vector2(-28, 22), Vector2(-17, 28)], cc, s, col, w)
			draw_circle(cc + Vector2(-15, 28) * s, 3.0 * s, col)
		_:
			# vycesany cirok, vyholene boky, naramenniky
			_fill_line(_pp([Vector2(-32, -6), Vector2(-33, -28), Vector2(-27, -56), Vector2(-17, -40), Vector2(-6, -70), Vector2(4, -44),
				Vector2(15, -72), Vector2(22, -44), Vector2(33, -58), Vector2(34, -28), Vector2(32, -6), Vector2(21, -24), Vector2(0, -30),
				Vector2(-21, -24)], cc, s), col, w, 0.34)
			for k in 3:
				draw_line(cc + Vector2(-30 + k * 1.5, -2 + k * 6) * s, cc + Vector2(-24, -6 + k * 6) * s, soft, maxf(1.0, w * 0.6))
				draw_line(cc + Vector2(30 - k * 1.5, -2 + k * 6) * s, cc + Vector2(24, -6 + k * 6) * s, soft, maxf(1.0, w * 0.6))

	# --- efekt pri hovoreni
	if talking and who == 1 and not half:
		for k in 4:
			var h := (6.0 + 16.0 * absf(sin(now * (7.0 + k * 2.1) + k))) * s
			draw_rect(Rect2(cc.x + (84 + k * 9) * s, cc.y + 10 * s - h / 2.0, 5 * s, h), col)
	if talking and who == 2:
		var pulse := fposmod(now * 2.0, 1.0)
		draw_arc(cc + Vector2(0, 10) * s, (70.0 + 30.0 * pulse) * s, 0, TAU, 40, Color(base, alpha * 0.5 * (1.0 - pulse)), w)


# ---------------------------------------------------------------- meno a tabulka skore
# "Prihlasenie" je len meno v profile. Kazda dohrana hra sa zapise do tabulky skore.
# Tabulka je ulozena v zariadeni; pre spolocnu tabulku medzi hracmi treba server
# (jedine miesto na napojenie je _log_score).

func _log_score() -> void:
	if score <= 0:
		return
	var table: Array = sv.scores
	var entry := {"n": _player_name(), "s": score, "r": maxi(round_num - 1, 0), "m": 2 if camp else (1 if daily else 0), "d": _today()}
	table.append(entry)
	if _logged_in() and not autoplay:
		send_queue.append({"s": score, "r": entry.r, "m": entry.m, "d": entry.d})
		_flush_queue()
	table.sort_custom(func(a, b): return int(a.s) > int(b.s))
	if table.size() > 300:
		table.resize(300)
	# rekordy: celkove maximum kampane a denne maxima (kampan "c", endless "e") pre kazdy den
	if camp:
		sv.best_camp = maxi(int(sv.best_camp), score)
	var days: Dictionary = sv.day_best
	var today := _today()
	var rec: Dictionary = days.get(today, {"c": 0, "e": 0})
	var key := "c" if camp else "e"
	rec[key] = maxi(int(rec.get(key, 0)), score)
	days[today] = rec
	for k in days.keys():
		if _day_number(today) - _day_number(str(k)) > 90:
			days.erase(k)
	sv.scores = table
	_log("tabulka skore: %d zaznamov, prvy %s %d" % [table.size(), str(table[0].n), int(table[0].s)])


func _board_fetch() -> void:
	if board_url == "" or scores_tab != 0:
		return
	# m = rezimy ("2" kampan, "01" endless + denna vyzva), d = den (prazdne = celkovo)
	var key := "%d|%d" % [rate_mode, rate_day]
	if key != board_key:
		board = []
		board_key = key
	board_state = 1
	http_get.cancel_request()
	var url := "%s?top=50&m=%s&d=%s" % [board_url, "2" if rate_mode == 0 else "01", _today() if rate_day == 1 else ""]
	if _logged_in():
		# server prida aj tvoj riadok s poradim, ked nie si v top 50
		url += "&me=" + str(sv.acc_name).uri_encode()
	if http_get.request(url) != OK:
		board_state = 3


func _on_board(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		board_state = 3
		return
	var data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if data is Array:
		board = data
		board_state = 2
	else:
		board_state = 3


func _flush_queue() -> void:
	if board_url == "" or send_queue.is_empty() or not _logged_in():
		return
	if http_post.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return
	var e: Dictionary = send_queue[0].duplicate()
	e["a"] = "score"
	e["t"] = str(sv.acc_token)
	# text/plain = prehliadac neposiela "preflight", takze to prejde aj cez Google Apps Script
	http_post.request(board_url, ["Content-Type: text/plain"], HTTPClient.METHOD_POST, JSON.stringify(e))


func _on_board_sent(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and code == 200:
		var data: Variant = JSON.parse_string(body.get_string_from_utf8())
		if data is Dictionary and str(data.get("err", "")) == "auth":
			# token uz neplati (ucet zmazany): odhlas, skore ostava v zariadeni
			send_queue.clear()
			sv.acc_name = ""
			sv.acc_token = ""
			_save()
			return
		if not send_queue.is_empty():
			send_queue.pop_front()
		_flush_queue()
	if screen == S.SCORES and scores_tab == 0:
		_board_fetch()


# ---------------------------------------------------------------- ucet (login / registracia)
# Ucty su na serveri (Google tabulka, list "players"): meno + heslo (ulozene ako hash).
# Hra si pamata len meno a token, heslo sa nikde neuklada.
# Do spolocneho rebricka sa zapisuje len prihlaseny hrac, takze cudzie meno si nikto neda.

const AUTH_KB := ["1234567890", "qwertyuiop", "asdfghjkl", "zxcvbnm", "áäčďéíĺľňó", "ôŕšťúýž"]

func _logged_in() -> bool:
	return str(sv.acc_token) != "" and str(sv.acc_name) != ""


func _player_name() -> String:
	return str(sv.acc_name) if _logged_in() else L("player")


func _open_auth() -> void:
	name_edit = true
	auth_field = 0
	auth_name = ""
	auth_pass = ""
	auth_msg = ""
	auth_busy = false
	_play("tap")


func _auth_type(ch: String) -> void:
	if auth_busy:
		return
	if auth_upper:
		ch = ch.to_upper()
	if auth_field == 0:
		if auth_name.length() < 16:
			auth_name += ch
	elif auth_pass.length() < 32:
		auth_pass += ch
	auth_msg = ""
	_play("tap")


func _auth_backspace() -> void:
	if auth_field == 0:
		auth_name = auth_name.left(maxi(auth_name.length() - 1, 0))
	else:
		auth_pass = auth_pass.left(maxi(auth_pass.length() - 1, 0))
	_play("card")


func _auth_send(action: String) -> void:
	if auth_busy:
		return
	var n := auth_name.strip_edges()
	if n.length() < 2:
		auth_msg = L("err_name")
		auth_field = 0
		_play("error")
		return
	if auth_pass.length() < 4:
		auth_msg = L("err_pass")
		auth_field = 1
		_play("error")
		return
	if board_url == "":
		auth_msg = L("err_net")
		return
	auth_busy = true
	auth_msg = L("loading")
	http_auth.cancel_request()
	http_auth.request(board_url, ["Content-Type: text/plain"], HTTPClient.METHOD_POST,
		JSON.stringify({"a": action, "n": n, "p": auth_pass}))


func _on_auth(result: int, code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	auth_busy = false
	if result != HTTPRequest.RESULT_SUCCESS or code != 200:
		auth_msg = L("err_net")
		_play("error")
		return
	var data: Variant = JSON.parse_string(body.get_string_from_utf8())
	if not (data is Dictionary):
		auth_msg = L("err_net")
		return
	if bool(data.get("ok", false)):
		sv.acc_name = str(data.get("n", auth_name))
		sv.acc_token = str(data.get("t", ""))
		auth_pass = ""
		name_edit = false
		_save()
		_toast(L("welcome") % str(sv.acc_name))
		_play("level")
		# skore z tohto zariadenia sa nahra pod novy ucet (server si necha len maximum)
		_upload_local_best()
	else:
		var err := str(data.get("err", ""))
		auth_msg = L("err_" + err) if D.TXT.has("err_" + err) else L("err_net")
		if dc_auto:
			_toast(auth_msg)
		_play("error")
	dc_auto = false


func _logout() -> void:
	if in_discord:
		sv.dc_skip = true  # po odhlaseni sa uz automaticky neprihlasi cez Discord
	sv.acc_name = ""
	sv.acc_token = ""
	_save()
	_toast(L("logged_out"))
	_play("tap")


func _upload_local_best() -> void:
	# po prihlaseni posli najlepsie skore kampane a endless z tohto zariadenia
	var best_c := {}
	var best_e := {}
	for e in sv.scores:
		if not (e is Dictionary):
			continue
		if int(e.get("m", 0)) == 2:
			if best_c.is_empty() or int(e.s) > int(best_c.s):
				best_c = e
		elif best_e.is_empty() or int(e.s) > int(best_e.s):
			best_e = e
	for e in [best_c, best_e]:
		if not e.is_empty():
			send_queue.append({"s": int(e.s), "r": int(e.get("r", 0)), "m": int(e.get("m", 0)), "d": str(e.get("d", _today()))})
	_flush_queue()


func _draw_auth() -> void:
	draw_rect(Rect2(-origin, vp), Color(COL_DARK, 0.94))
	buttons.clear()
	var fill: Color = TH.arena
	_txt(Vector2(360, 150), L("account"), 40, COL_TEXT, 0, true, true)
	_txt(Vector2(360, 186), L("account_hint"), 19, COL_DIM, 0, false)
	var labels := [L("name"), L("password")]
	var vals := [auth_name, "•".repeat(auth_pass.length())]
	var cursor := "|" if fposmod(now, 1.0) < 0.5 else " "
	for i in 2:
		var r := Rect2(90, 210 + i * 102, 540, 86)
		var sel := auth_field == i
		_panel(r, Color(fill.lightened(0.05), 0.98), _acc() if sel else Color(COL_DIM, 0.5), 3 if sel else 2, 18)
		_txt(r.position + Vector2(22, 28), str(labels[i]), 17, _acc() if sel else COL_DIM, -1)
		_txt(r.position + Vector2(22, 70), str(vals[i]) + (cursor if sel else ""), 32, COL_TEXT, -1, false)
		buttons.append([r, "afield:%d" % i])
	var mcol := COL_DANGER if auth_msg != L("loading") else COL_DIM
	_txt(Vector2(360, 440), auth_msg, 21, mcol, 0, false)
	# klavesnica
	for row_i in AUTH_KB.size():
		var row: String = AUTH_KB[row_i]
		var x0 := 360.0 - row.length() * 34.0
		for k in row.length():
			var ch := row[k]
			var shown := ch.to_upper() if auth_upper else ch
			_btn("ak:" + ch, Rect2(x0 + k * 68.0 + 3.0, 462 + row_i * 76, 62, 68), shown, COL_TEXT, "", 26)
	var by := 462.0 + AUTH_KB.size() * 76.0 + 8.0
	_btn("ashift", Rect2(48, by, 130, 70), "Aa", _acc() if auth_upper else COL_DIM, "", 26, auth_upper)
	_btn("aspace", Rect2(190, by, 300, 70), L("space"), COL_DIM, "", 22)
	_btn("adel", Rect2(502, by, 170, 70), L("del"), COL_DIM, "", 22)
	_btn("alogin", Rect2(48, by + 86, 304, 84), L("login"), _acc(), "", 30, true)
	_btn("areg", Rect2(368, by + 86, 304, 84), L("register"), COL_ORB, "", 28)
	if in_discord:
		_btn("adc", Rect2(48, by + 184, 304, 60), L("dc_login"), Color("#8c9eff"), "", 22, true)
		_btn("acancel", Rect2(368, by + 184, 304, 60), L("back"), COL_DIM, "", 22)
	else:
		_btn("acancel", Rect2(210, by + 184, 300, 60), L("back"), COL_DIM, "", 22)


func _auth_type_raw(ch: String) -> void:
	# fyzicka klavesnica: pismena aj s diakritikou, cislice, medzera, bodka, pomlcka, podciarnik
	var ok := ch == " " or ch == "." or ch == "-" or ch == "_" or ch.to_upper() != ch.to_lower() or (ch >= "0" and ch <= "9")
	if auth_field == 1:
		ok = true
	if ok:
		var was := auth_upper
		auth_upper = false
		_auth_type(ch)
		auth_upper = was


func _draw_scores() -> void:
	_header(L("scores"))
	var fill: Color = TH.arena
	var line: Color = TH.line
	# rezim a obdobie
	_btn("rmode:0", Rect2(48, 136, 304, 60), L("campaign"), _acc() if rate_mode == 0 else COL_DIM, "", 24, rate_mode == 0)
	_btn("rmode:1", Rect2(368, 136, 304, 60), L("endless"), _acc() if rate_mode == 1 else COL_DIM, "", 24, rate_mode == 1)
	_btn("rday:0", Rect2(48, 206, 304, 54), L("all_time"), COL_ORB if rate_day == 0 else COL_DIM, "", 22, rate_day == 0)
	_btn("rday:1", Rect2(368, 206, 304, 54), L("today_tab"), COL_ORB if rate_day == 1 else COL_DIM, "", 22, rate_day == 1)
	var top := 316.0
	if board_url != "":
		_btn("stab:0", Rect2(48, 270, 304, 50), L("world"), COL_TEXT if scores_tab == 0 else COL_DIM, "", 20, scores_tab == 0)
		_btn("stab:1", Rect2(368, 270, 304, 50), L("mine"), COL_TEXT if scores_tab == 1 else COL_DIM, "", 20, scores_tab == 1)
		top = 372.0
	# tvoje ulozene rekordy pre zvoleny rezim
	var days: Dictionary = sv.day_best
	var rec: Dictionary = days.get(_today(), {})
	var my_all := int(sv.best_camp) if rate_mode == 0 else int(sv.best)
	var my_day := int(rec.get("c" if rate_mode == 0 else "e", 0))
	_txt(Vector2(360, top - 22), L("my_best") % [my_all, my_day], 20, COL_DIM, 0, false)

	var table: Array = []
	if board_url != "" and scores_tab == 0 and not _logged_in():
		_txt(Vector2(360, 1236), L("login_to_rank"), 19, COL_ORB, 0, false)
	if board_url != "" and scores_tab == 0:
		table = board
		if board_state == 1 and board.is_empty():
			_txt(Vector2(360, top + 160), L("loading"), 24, COL_DIM, 0, false)
			return
		if board_state == 3 and board.is_empty():
			_txt(Vector2(360, top + 160), L("board_err"), 24, COL_DANGER, 0, false)
			return
	else:
		var today := _today()
		for e in sv.scores:
			if not (e is Dictionary):
				continue
			var is_camp := int(e.get("m", 0)) == 2
			if is_camp != (rate_mode == 0):
				continue
			if rate_day == 1 and str(e.get("d", "")) != today:
				continue
			table.append(e)
	if table.is_empty():
		_txt(Vector2(360, top + 160), L("no_scores"), 24, COL_DIM, 0, false)
		return
	var modes := [L("endless"), L("daily").split(" ")[0], L("campaign")]
	var mcols := [COL_TEXT, COL_ORB, _acc()]
	var me := _player_name()
	var world := board_url != "" and scores_tab == 0
	# tvoje miesto v svetovom rebricku je vzdy pripnute hore
	var my_i := -1
	if world and _logged_in():
		for i in table.size():
			if table[i] is Dictionary and str(table[i].get("n", "")).to_lower() == me.to_lower():
				my_i = i
				break
		var pr := Rect2(48, top, 624, 74)
		_panel(pr, Color(_acc(), 0.16), _acc(), 3, 18, Color(_acc(), 0.25), 10)
		_txt(Vector2(78, top + 30), L("you_rank"), 16, _acc(), -1)
		if my_i >= 0:
			var me_e: Dictionary = table[my_i]
			var rk := int(me_e.get("k", my_i + 1))
			_txt(Vector2(78, top + 62), "#%d" % rk, 32, COL_ORB if rk <= 3 else COL_TEXT, -1)
			_txt(Vector2(200, top + 47), me.left(12), 27, COL_TEXT, -1)
			_txt(Vector2(648, top + 49), str(int(me_e.get("s", 0))), 36, _acc(), 1)
		else:
			_txt(Vector2(200, top + 47), L("not_ranked"), 20, COL_DIM, -1, false)
		top += 90.0
	var rows := int((1222.0 - top) / 78.0)
	# ktore riadky ukazat: zaciatok rebricka; ked si nizsie, posledne miesto patri tebe
	var show: Array = []
	for i in mini(table.size(), rows):
		show.append(i)
	if my_i >= rows and rows >= 3:
		show.resize(rows - 2)
		show.append(-1)
		show.append(my_i)
	for j in show.size():
		var i: int = show[j]
		var y := top + j * 78.0
		if i < 0:
			_txt(Vector2(360, y + 44), "· · ·", 28, COL_DIM, 0, false)
			continue
		if not (table[i] is Dictionary):
			continue
		var e2: Dictionary = table[i]
		var rk2 := int(e2.get("k", i + 1)) if world else i + 1
		var mine := str(e2.get("n", "")).to_lower() == me.to_lower()
		_panel(Rect2(48, y, 624, 68), Color(_acc(), 0.14) if mine else Color(fill, 0.9 if j % 2 == 0 else 0.6), Color(_acc(), 0.9) if mine else Color(line, 0.9 if rk2 <= 3 else 0.3), 3 if mine else 2, 16)
		_txt(Vector2(86, y + 45), str(rk2), 28 if rk2 < 100 else 22, COL_ORB if rk2 <= 3 else COL_DIM)
		_txt(Vector2(126, y + 33), str(e2.get("n", "?")).left(12), 25, COL_TEXT, -1)
		var mi := clampi(int(e2.get("m", 0)), 0, 2)
		var mc: Color = mcols[mi]
		_txt(Vector2(126, y + 57), "%s · %s · %s" % [str(modes[mi]), L("round_s") % int(e2.get("r", 0)), str(e2.get("d", "")).left(10)], 16, Color(mc, 0.8), -1, false)
		_txt(Vector2(648, y + 47), str(int(e2.get("s", 0))), 34, _acc() if rk2 <= 3 else COL_TEXT, 1)


func _draw_base() -> void:
	var fill: Color = TH.arena
	var line: Color = TH.line
	_btn("back", Rect2(30, 36, 150, 72), L("back"), COL_DIM, "", 24)
	_txt(Vector2(360, 88), L("base_title"), 40, COL_TEXT)
	_cores_pill(Vector2(690, 72))

	# mapa lokalit
	var cleared := int(sv.cleared)
	for i in D.LOCS.size():
		var x := 104.0 + i * 128.0
		var th: Dictionary = D.THEMES[int(D.LOCS[i].theme)]
		var ac: Color = th.accent
		var found := i <= cleared
		if i > 0:
			draw_line(Vector2(x - 128 + 30, 178), Vector2(x - 30, 178), Color(ac if found else COL_DIM, 0.8 if found else 0.3), 3.0)
		draw_circle(Vector2(x, 178), 30.0, Color(ac, 0.18) if found else Color(COL_DIM, 0.08))
		draw_arc(Vector2(x, 178), 30.0, 0, TAU, 32, ac if found else Color(COL_DIM, 0.4), 3.0)
		if i < cleared:
			draw_circle(Vector2(x, 178), 20.0, Color(ac, 0.85))
		_txt(Vector2(x, 188), str(i + 1) if found else "?", 26, COL_DARK if i < cleared else (COL_TEXT if found else COL_DIM))
	_txt(Vector2(360, 246), L("furthest") % str(D.LOCS[mini(cleared, D.LOCS.size() - 1)].n[lang]), 22, COL_DIM, 0, false)

	# radkyne
	for i in 3:
		var adv: Dictionary = D.ADVISORS[i]
		var ac2: Color = adv.col
		var r := Rect2(48 + i * 212, 276, 200, 310)
		var sel := base_who == i
		_panel(r, Color(fill, 0.9), Color(ac2, 0.95 if sel else 0.35), 3 if sel else 2, 20, Color(ac2, 0.2 if sel else 0.0), 12)
		_portrait(Vector2(r.get_center().x, r.position.y + 112), 1.2, i, sel and base_talk_t > 0.0)
		_txt(Vector2(r.get_center().x, r.position.y + 268), str(adv.n), 26, ac2)
		_txt(Vector2(r.get_center().x, r.position.y + 294), str(adv.role[lang]), 16, COL_DIM, 0, false)
		buttons.append([r, "adv:%d" % i])

	# co prave hovori
	var dc: Color = D.ADVISORS[base_who].col
	_panel(Rect2(48, 606, 624, 164), Color(COL_DARK, 0.75), Color(dc, 0.8), 2, 20)
	_txt(Vector2(76, 644), str(D.ADVISORS[base_who].n), 20, dc, -1)
	draw_multiline_string(font_m, Vector2(76, 676), base_line, HORIZONTAL_ALIGNMENT_LEFT, 572, 22, 4, COL_TEXT)

	_btn("launch", Rect2(110, 800, 500, 136), L("launch"), _acc(), L("launch_sub"), 50, true)
	var skills: Array = sv.skills
	_btn("tree", Rect2(110, 960, 500, 104), L("tree"), COL_CORE, L("tree_sub") % [skills.size(), D.SKILLS.size()], 32)
	_txt(Vector2(360, 1118), L("wins") % int(sv.camp_wins), 22, COL_DIM, 0, false)
	_coins_pill(Vector2(690, 1180))
	var _unused := line


func _draw_tree() -> void:
	var fill: Color = TH.arena
	var line: Color = TH.line
	_btn("back", Rect2(30, 36, 150, 72), L("back"), COL_DIM, "", 24)
	_txt(Vector2(388, 86), L("tree"), 30, COL_TEXT)
	_cores_pill(Vector2(690, 72))
	for b in D.BRANCHES.size():
		var bc0: Color = D.BRANCH_COL[b]
		_txt(Vector2(104 + b * 128, 176), str(D.BRANCHES[b][lang]), 17, bc0)
	for i in D.SKILLS.size():
		var sk: Array = D.SKILLS[i]
		var bc: Color = D.BRANCH_COL[int(sk[1])]
		var c := Vector2(104 + int(sk[1]) * 128, 250 + int(sk[2]) * 124)
		var own := _sk(str(sk[0]))
		var ok := _skill_ok(i)
		if int(sk[2]) > 0:
			draw_line(c + Vector2(0, -124 + 42), c + Vector2(0, -42), Color(bc, 0.9) if own else Color(COL_DIM, 0.35 if not ok else 0.7), 4.0)
		if own:
			draw_circle(c, 46.0, Color(bc, 0.18))
			draw_circle(c, 38.0, bc)
			_txt(c + Vector2(0, 8), str(sk[3]), 21, COL_DARK)
		else:
			draw_circle(c, 38.0, Color(fill.lightened(0.05), 0.95))
			draw_arc(c, 38.0, 0, TAU, 36, Color(bc, 0.95) if ok else Color(COL_DIM, 0.35), 3.0)
			_txt(c + Vector2(0, 8), str(sk[3]), 21, bc if ok else Color(COL_DIM, 0.5))
			if ok and int(sv.cores) >= int(D.SKILL_COST[int(sk[2])]):
				draw_arc(c, 44.0 + 2.0 * sin(now * 5.0), 0, TAU, 36, Color(bc, 0.4), 2.0)
		if i == tree_sel:
			draw_arc(c, 48.0, 0, TAU, 40, COL_TEXT, 3.0)
		buttons.append([Rect2(c - Vector2(52, 52), Vector2(104, 104)), "node:%d" % i])

	var box := Rect2(48, 962, 624, 250)
	_panel(box, Color(fill, 0.95), Color(line, 0.9), 2, 22)
	if tree_sel < 0:
		draw_multiline_string(font_m, Vector2(80, 1078), L("tree_hint"), HORIZONTAL_ALIGNMENT_CENTER, 560, 24, 3, COL_DIM)
		return
	var s: Array = D.SKILLS[tree_sel]
	var sc: Color = D.BRANCH_COL[int(s[1])]
	var cost := int(D.SKILL_COST[int(s[2])])
	_txt(Vector2(80, 1014), str(s[4 + lang]), 30, sc, -1)
	draw_multiline_string(font_m, Vector2(80, 1052), str(s[6 + lang]), HORIZONTAL_ALIGNMENT_LEFT, 560, 22, 3, COL_TEXT)
	if _sk(str(s[0])):
		_txt(Vector2(360, 1176), L("bought_sk"), 26, sc)
	else:
		var can := _skill_ok(tree_sel) and int(sv.cores) >= cost
		_btn("buysk", Rect2(210, 1126, 300, 72), "", COL_CORE if can else COL_DIM, "", 26, can)
		var label := "%s  %d" % [L("buy"), cost]
		var w := _tw(label, 26, true)
		_txt(Vector2(360 - 14, 1172), label, 26, COL_DARK if can else COL_DIM)
		_core_icon(Vector2(360 + w / 2.0 + 4, 1162), 9.0, 1.0 if not can else 0.0)
		if can:
			_poly(Vector2(360 + w / 2.0 + 4, 1162), 11.0, 6, 0.0, COL_DARK)


func _draw_merchant() -> void:
	draw_rect(Rect2(-origin, vp), Color(COL_DARK, 0.8))
	var fill: Color = TH.arena
	var mc := Color("b68cff")
	# postava obchodnika: plast, kapucna, dve svietiace oci
	var c := Vector2(360, 330 + sin(now * 1.6) * 6.0)
	for k in 5:
		var ang := now * 0.8 + TAU * k / 5.0
		_poly(c + Vector2(cos(ang) * 110.0, sin(ang) * 34.0 - 10.0), 8.0, 4, ang, Color(mc, 0.5))
	_fill_line(_pp([Vector2(-76, 64), Vector2(-46, -14), Vector2(-24, -50), Vector2(0, -62), Vector2(24, -50), Vector2(46, -14), Vector2(76, 64)], c, 1.0), mc, 3.0, 0.22)
	_fill_line(_ell(c + Vector2(0, -14), 24.0, 28.0), mc, 3.0, 0.5)
	draw_circle(c + Vector2(-9, -16), 4.0 + sin(now * 4.0), COL_ORB)
	draw_circle(c + Vector2(9, -16), 4.0 + sin(now * 4.0), COL_ORB)
	_txt(Vector2(360, 444), L("merchant"), 32, mc, 0, true, true)
	_txt(Vector2(360, 478), L("merchant_say"), 19, COL_DIM, 0, false)
	_coins_pill(Vector2(690, 250))

	var names := [L("m_repair"), L("m_reinf"), L("m_card"), ""]
	var descs := [L("m_repair_d"), L("m_reinf_d"), L("m_card_d"), L("m_skin_d")]
	if m_card >= 0:
		names[2] = "%s: %s" % [L("m_card"), "?"]
	var si := _m_skin()
	var rows := 4 if (si >= 0 or bool(m_sold[3])) else 3
	if si >= 0:
		names[3] = str(D.SKINS[si].n[lang])
	for i in rows:
		var r := Rect2(60, 506 + i * 122, 600, 108)
		var sold := bool(m_sold[i])
		var price := _m_price(i)
		var blocked := (i == 0 and hull >= hull_max) or (i == 2 and m_card < 0)
		var can := not sold and not blocked and int(sv.coins) >= price
		_panel(r, Color(fill.lightened(0.05), 0.96), Color(mc, 0.9 if can else 0.3), 2, 18)
		_txt(Vector2(r.position.x + 28, r.position.y + 46), str(names[i]), 26, COL_TEXT if not sold else COL_DIM, -1)
		_txt(Vector2(r.position.x + 28, r.position.y + 80), str(descs[i]), 18, COL_DIM, -1, false)
		if i == 3 and si >= 0:
			var skc: Color = D.SKINS[si].col
			_shape(Vector2(r.end.x - 240, r.get_center().y), 20.0, int(D.SKINS[si].shape), skc, sin(now * 1.5) * 0.4)
		var br := Rect2(r.end.x - 176, r.position.y + 22, 156, 64)
		if sold:
			_txt(br.get_center() + Vector2(0, 8), L("sold"), 22, COL_DIM, 0, false)
		else:
			_btn("mbuy:%d" % i, br, "", COL_COIN if can else COL_DIM, "", 24)
			var ps := str(price)
			var w := _tw(ps, 26, true)
			_txt(Vector2(br.get_center().x - 12, br.get_center().y + 10), ps, 26, COL_COIN if can else COL_DIM)
			_coin(Vector2(br.get_center().x + w / 2.0 + 6, br.get_center().y), 9.0, 1.0 if can else 0.5)
	_btn("mcont", Rect2(70, 1010, 380, 96), L("continue"), _acc(), "", 36, true)


# ------------------------------------------------------------------ Discord prihlasenie
# V Discord Activity si hra vypyta od Discordu jednorazovy kod (okno "Authorize" v Discorde),
# server ho vymeni za meno hraca a vrati token uctu. Heslo sa nikde nezadava.
func _dc_login(auto: bool) -> void:
	if not in_discord or board_url == "" or auth_busy:
		return
	dc_auto = auto
	auth_msg = L("loading")
	JavaScriptBridge.eval("window.__dcLogin && window.__dcLogin()", true)
	dc_wait = 900.0  # Discord okno moze byt otvorene dlho; zrusenie vrati chybu hned
	dc_poll = 0.0


func _dc_poll(delta: float) -> void:
	dc_wait -= delta
	dc_poll -= delta
	if dc_poll > 0.0:
		return
	dc_poll = 0.25
	var code := str(JavaScriptBridge.eval("window.__dcCode || ''", true))
	var err := str(JavaScriptBridge.eval("window.__dcErr || ''", true))
	if code != "":
		dc_wait = 0.0
		JavaScriptBridge.eval("window.__dcCode = ''", true)
		auth_busy = true
		http_auth.cancel_request()
		http_auth.request(board_url, ["Content-Type: text/plain"], HTTPClient.METHOD_POST,
			JSON.stringify({"a": "discord", "c": code}))
	elif err != "" or dc_wait <= 0.0:
		dc_wait = 0.0
		auth_msg = L("err_discord")
		if not dc_auto:
			_play("error")
		dc_auto = false
