import std
import vec
import color

fatal(gl_window("Shooter Tutorial", 640, 480))

check(gl_set_font_name("data/fonts/US101/US101.TTF") and gl_set_font_size(32), "can\'t load font!")

while gl_frame() and gl_button("escape") != 1:

    gl_clear(color_black)
    gl_color(color_white)

    var highscore ?= 0
    var playing ?= false

    if playing:
        var score ?= 0
        var playerpos ?= xy_0
        let playerspeed = 10
        var playerhealth ?= 100.0
        let worldsize = 20.0

        def renderpointytriangle(pos, dir):
            gl_translate pos:
                gl_rotate_z dir:
                    gl_polygon([ xy { -0.5, 0.5 }, xy_x, xy { -0.5, -0.5 } ])

        gl_text("health: " + ceiling(playerhealth) + " - score: " + score + " - highscore: " + highscore)
        gl_translate(float(gl_window_size()) / 2.0)
        let scale = gl_window_size().y / worldsize
        gl_scale(scale)

        let dir = xy_f { (gl_button("d") >= 1) - (gl_button("a") >= 1),
                      (gl_button("s") >= 1) - (gl_button("w") >= 1) }
        let newpos = playerpos + normalize(dir) * gl_delta_time() * playerspeed
        if !any(abs(newpos) > float(gl_window_size()) / scale / 2):
            playerpos = newpos

        let tomouse = normalize(gl_local_mouse_pos(0) - playerpos)

        class enemy:
            pos:xy_f
            hp:int

        class bullet:
            pos:xy_f
            dir:xy_f

        var enemies ?= []
        var bullets ?= []

        def every_n_seconds(sec, f):
            var last ?= gl_time()
            if last <= gl_time():
                last += sec
                f()

        var enemyrate ?= 1.0
        let enemymaxhp = 5
        every_n_seconds(enemyrate):
            enemies.push(enemy { sincos(rnd(360)) * worldsize * 2, enemymaxhp })
            enemyrate *= 0.999

        let firerate = 0.1
        every_n_seconds(firerate):
            bullets.push(bullet { playerpos, tomouse })

        let enemyspeed = 3
        for(enemies) e:
            let playervec = playerpos - e.pos
            let playerdir = normalize(playervec)
            e.pos += playerdir * gl_delta_time() * enemyspeed
            for(bullets) b:
                if magnitude(b.pos - e.pos) < 1:
                    e.hp--
                    if(e.hp <= 0):
                        e.hp = 0
                        score++
                    b.pos = xy_x * worldsize * 10
            if magnitude(playervec) < 1:
                playerhealth -= gl_delta_time() * 50
                if(playerhealth <= 0):
                    playerhealth = 0
                    highscore = max(highscore, score)
                    playing = false
            gl_color lerp(color_red, color_blue, div(e.hp, enemymaxhp)):
                renderpointytriangle(e.pos, playerdir)

        enemies = filter enemies: _.hp

        let bulletspeed = 15
        for(bullets) b:
            b.pos += b.dir * gl_delta_time() * bulletspeed
            gl_translate(b.pos):
                gl_color(color_yellow):
                    gl_circle(0.2, 20)

        bullets = filter(bullets) b:
            magnitude(b.pos) < worldsize * 2

        gl_translate(gl_local_mouse_pos(0)):
            gl_line_mode(1):
                gl_color(color_grey):
                    gl_circle(0.5, 20)

        renderpointytriangle(playerpos, tomouse)
    else:
        let msg = "press space to play!"
        gl_translate float(gl_window_size() - gl_text_size(msg)) / 2:
            gl_text(msg)
        if gl_button("space") == 1:
            playing = true
        gl_text("highscore: " + highscore)


