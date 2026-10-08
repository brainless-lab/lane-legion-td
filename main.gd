extends Node2D

const W := 720.0
const H := 1280.0
const FIELD_TOP := 185.0
const FIELD_BOTTOM := 1010.0
const COLS := 5
const ROWS := 7
const CELL := 105.0
const GRID_LEFT := 42.0
const GRID_TOP := 230.0

var gold := 220
var lives := 20
var wave := 0
var income := 12
var phase := "BUILD"
var build_time := 15.0
var selected_type := 0
var towers:Array = []
var enemies:Array = []
var projectiles:Array = []
var spawn_left := 0
var spawn_timer := 0.0
var wave_clear_timer := 0.0

var tower_types = [
    {"name":"Guard", "cost":60, "damage":15.0, "range":150.0, "rate":0.75, "color":Color("58b7ff")},
    {"name":"Gunner", "cost":90, "damage":9.0, "range":225.0, "rate":0.32, "color":Color("ffd166")},
    {"name":"Crusher", "cost":130, "damage":36.0, "range":125.0, "rate":1.15, "color":Color("ef6f6c")}
]

func _ready():
    set_process(true)
    queue_redraw()

func _process(delta):
    if lives <= 0:
        queue_redraw(); return
    if phase == "BUILD":
        build_time -= delta
        if build_time <= 0:
            start_wave()
    else:
        spawn_timer -= delta
        if spawn_left > 0 and spawn_timer <= 0:
            spawn_enemy()
            spawn_left -= 1
            spawn_timer = max(0.34, 0.78 - wave * 0.012)
        update_towers(delta)
        update_enemies(delta)
        update_projectiles(delta)
        if spawn_left == 0 and enemies.is_empty():
            wave_clear_timer += delta
            if wave_clear_timer > 1.0:
                phase = "BUILD"
                gold += income
                income += 2
                build_time = 13.0
                wave_clear_timer = 0.0
    queue_redraw()

func start_wave():
    phase = "WAVE"
    wave += 1
    spawn_left = 6 + wave * 2
    spawn_timer = 0.1

func spawn_enemy():
    var hp = 55.0 * pow(1.17, wave - 1)
    enemies.append({"pos":Vector2(W/2, FIELD_TOP+5), "hp":hp, "max_hp":hp, "speed":52.0 + wave*1.7, "r":20.0})

func update_towers(delta):
    for t in towers:
        t.cool -= delta
        if t.cool > 0: continue
        var best = null
        var best_y = -1.0
        for e in enemies:
            if t.pos.distance_to(e.pos) <= t.range and e.pos.y > best_y:
                best = e; best_y = e.pos.y
        if best != null:
            best.hp -= t.damage
            projectiles.append({"a":t.pos, "b":best.pos, "life":0.10, "color":t.color})
            t.cool = t.rate

func update_enemies(delta):
    var dead=[]
    for e in enemies:
        if e.hp <= 0:
            dead.append(e); gold += 5 + int(wave/3); continue
        e.pos.y += e.speed * delta
        if e.pos.y >= FIELD_BOTTOM:
            dead.append(e); lives -= 1
    for e in dead: enemies.erase(e)

func update_projectiles(delta):
    var dead=[]
    for p in projectiles:
        p.life -= delta
        if p.life <= 0: dead.append(p)
    for p in dead: projectiles.erase(p)

func grid_pos_from_touch(p:Vector2):
    var c = int(floor((p.x-GRID_LEFT)/CELL))
    var r = int(floor((p.y-GRID_TOP)/CELL))
    if c < 0 or c >= COLS or r < 0 or r >= ROWS: return null
    return Vector2i(c,r)

func occupied(cell:Vector2i)->bool:
    for t in towers:
        if t.cell == cell: return true
    return false

func _input(event):
    if event is InputEventScreenTouch and event.pressed:
        handle_touch(event.position)
    elif event is InputEventMouseButton and event.pressed:
        handle_touch(event.position)

func handle_touch(p:Vector2):
    if lives <= 0:
        if Rect2(210,710,300,80).has_point(p): reset_game()
        return
    for i in range(3):
        if Rect2(28+i*225,1090,210,125).has_point(p):
            selected_type=i; return
    if phase == "BUILD" and Rect2(530,120,160,55).has_point(p):
        start_wave(); return
    if phase != "BUILD": return
    var cell = grid_pos_from_touch(p)
    if cell == null or occupied(cell): return
    var d=tower_types[selected_type]
    if gold < d.cost: return
    gold -= d.cost
    towers.append({"cell":cell, "pos":Vector2(GRID_LEFT+cell.x*CELL+CELL/2,GRID_TOP+cell.y*CELL+CELL/2), "damage":d.damage,"range":d.range,"rate":d.rate,"cool":0.0,"color":d.color,"name":d.name})

func reset_game():
    gold=220; lives=20; wave=0; income=12; phase="BUILD"; build_time=15.0
    towers.clear(); enemies.clear(); projectiles.clear(); spawn_left=0

func _draw():
    draw_rect(Rect2(0,0,W,H),Color("09101c"))
    draw_string(ThemeDB.fallback_font,Vector2(28,52),"LANE LEGION TD",HORIZONTAL_ALIGNMENT_LEFT,400,32,Color("eaf2ff"))
    draw_string(ThemeDB.fallback_font,Vector2(28,98),"Gold: %d   Lives: %d   Wave: %d   Income: +%d" % [gold,lives,wave,income],HORIZONTAL_ALIGNMENT_LEFT,-1,22,Color("c6d4ea"))
    var status = "BUILD %.0fs" % max(build_time,0) if phase=="BUILD" else "WAVE %d" % wave
    draw_string(ThemeDB.fallback_font,Vector2(28,145),status,HORIZONTAL_ALIGNMENT_LEFT,-1,25,Color("8de2b8"))
    if phase=="BUILD":
        draw_rect(Rect2(530,112,160,55),Color("1d7550"),true)
        draw_string(ThemeDB.fallback_font,Vector2(550,148),"START",HORIZONTAL_ALIGNMENT_LEFT,-1,23,Color.WHITE)
    draw_rect(Rect2(22,FIELD_TOP,W-44,FIELD_BOTTOM-FIELD_TOP),Color("101b2c"),true)
    draw_line(Vector2(W/2,FIELD_TOP),Vector2(W/2,FIELD_BOTTOM),Color("263b58"),3)
    for r in range(ROWS):
        for c in range(COLS):
            var rect=Rect2(GRID_LEFT+c*CELL,GRID_TOP+r*CELL,CELL-7,CELL-7)
            draw_rect(rect,Color(0.12,0.19,0.29,0.46),true)
            draw_rect(rect,Color("29405e"),false,2)
    for t in towers:
        draw_circle(t.pos,28,t.color)
        draw_circle(t.pos,12,Color("172235"))
        draw_string(ThemeDB.fallback_font,t.pos+Vector2(-22,48),t.name,HORIZONTAL_ALIGNMENT_CENTER,44,13,Color("dbe7f7"))
    for e in enemies:
        draw_circle(e.pos,e.r,Color("bc4b67"))
        draw_rect(Rect2(e.pos.x-24,e.pos.y-32,48,5),Color("3b1722"),true)
        draw_rect(Rect2(e.pos.x-24,e.pos.y-32,48*(e.hp/e.max_hp),5),Color("71d99e"),true)
    for p in projectiles: draw_line(p.a,p.b,p.color,5)
    for i in range(3):
        var d=tower_types[i]; var rect=Rect2(28+i*225,1090,210,125)
        draw_rect(rect,Color("263e5d") if i==selected_type else Color("16253a"),true)
        draw_rect(rect,d.color,false,4 if i==selected_type else 2)
        draw_circle(Vector2(rect.position.x+36,rect.position.y+39),20,d.color)
        draw_string(ThemeDB.fallback_font,rect.position+Vector2(68,38),d.name,HORIZONTAL_ALIGNMENT_LEFT,130,20,Color.WHITE)
        draw_string(ThemeDB.fallback_font,rect.position+Vector2(68,72),"%d Gold"%d.cost,HORIZONTAL_ALIGNMENT_LEFT,130,17,Color("c6d4ea"))
        draw_string(ThemeDB.fallback_font,rect.position+Vector2(16,105),"DMG %.0f  RNG %.0f"%[d.damage,d.range],HORIZONTAL_ALIGNMENT_LEFT,180,14,Color("9fb1c9"))
    if lives<=0:
        draw_rect(Rect2(90,500,540,340),Color(0.02,0.03,0.05,0.94),true)
        draw_string(ThemeDB.fallback_font,Vector2(190,610),"DEFEAT",HORIZONTAL_ALIGNMENT_CENTER,340,48,Color("ff6b6b"))
        draw_string(ThemeDB.fallback_font,Vector2(190,665),"Reached wave %d"%wave,HORIZONTAL_ALIGNMENT_CENTER,340,24,Color.WHITE)
        draw_rect(Rect2(210,710,300,80),Color("1d7550"),true)
        draw_string(ThemeDB.fallback_font,Vector2(270,762),"RESTART",HORIZONTAL_ALIGNMENT_LEFT,-1,26,Color.WHITE)
