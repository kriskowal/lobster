import gui
import texture

def pick(list):
    return list[rnd(length(list))]

def scatter(dst, src, stencils):
    for(stencils) stencil, i:
        for(stencil) j, k:
            dst[i][k] = src[j]

def gather_bids(bids, neighborhoods, ents, headings):
    for(neighborhoods) neighbors, i:
        bids[i] = if(ents[i]):
            let heading = headings[i] % 4
            let neighbor = neighbors[heading]
            if !ents[neighbor]: neighbor
            else: -1
        else: -1

def gather_winners(area, winners, neighborhoods, bid_neighborhoods, weight_neighborhoods):
    for(area) i:
        winners[i] = find_winner(i, neighborhoods[i], bid_neighborhoods[i], weight_neighborhoods[i])

def find_winner(i, neighborhood, bid_neighborhood, weight_neighborhood):
    var best = -1
    var winner = -1
    for(length(neighborhood)) j:
        if bid_neighborhood[j] == i and (best < 0 or weight_neighborhood[j] > best):
            best = weight_neighborhood[j]
            winner = neighborhood[j]
    return winner

def transit(area, dst, src, transitions):
    for(area) i: dst[i] = src[transitions[i]]

def move(area, dst, src):
    for(area) i:
        dst[i] = src[i]

def move(area, dst, src, fun):
    for(area) i:
        dst[i] = fun(src[i])

def center_unit_square():
    let size = float(gl_window_size())
    let major = min(size.x, size.y)
    let scale = xy_1 * major
    gl_translate((size - scale) / 2)
    gl_scale(scale)

def index_of_point(v, size): return v.y * size + v.x
def modxy(v, w): return xy{ (w.x + v.x) % w.x, (w.y + v.y) % w.y }

class world:
    rules:[int]
    size:int
    area:int

    // leading edge
    ents_next:[int]
    weights_next:[int]
    headings_next:[int]
    langtons_next:[int]
    // following edge
    ents:[int]
    weights:[int]
    headings:[int]
    langtons:[int]

    // intermediate
    points:[xy_i]
    neighborhoods:[[int]]
    bids:[int]
    bid_neighborhoods:[[int]]
    weight_neighborhoods:[[int]]
    winners:[int]
    winner_neighborhoods:[[int]]
    transitions:[int]
    directions:[xy_i]
    rotations:[int]
    headings_rotated:[int]

    def tick():
        move(area, ents, ents_next)
        move(area, weights, weights_next)
        move(area, langtons, langtons_next)
        move(area, headings, headings_next) n: (4 + n) % 4

        gather_bids(bids, neighborhoods, ents, headings)
        scatter(bid_neighborhoods, bids, neighborhoods)
        scatter(weight_neighborhoods, weights, neighborhoods)
        gather_winners(area, winners, neighborhoods, bid_neighborhoods, weight_neighborhoods)
        scatter(winner_neighborhoods, winners, neighborhoods)
        gather_transitions()

        transit(area, ents_next, ents, transitions)
        transit(area, weights_next, weights, transitions)
        transit(area, headings_next, headings_rotated, transitions)

    def gather_transitions():
        for(area) i:
            let transition, direction, rotation, langton = find_transition(i, neighborhoods[i], winners[i], winner_neighborhoods[i], langtons[i])
            transitions[i] = transition
            directions[i] = direction
            rotations[i] = rotation
            headings_rotated[i] = headings[i] + rotation
            langtons_next[i] = langton

    def find_transition(i, neighbors, winner, winner_neighbors, langton):
        // A neighbor moves here.
        if winner >= 0:
            return winner, xy_0i, 0, langton
        let found = find(winner_neighbors) j: i == j
        // We move to a neighbor.
        if found >= 0:
            return neighbors[found], cardinal_directions[found], rules[langton], (length(rules) + langton + 1) % length(rules)
        // Rotate in place if cannot proceed.
        return i, xy_0i, 1, langton


def new_world(size, rules):
    let grid = xy_1i * size
    let points = flatten(mapxy(grid) v: v)
    let area = size * size
    let headings = map(area): rnd(4)
    // just one ent:
    // let ents_next = map(area): 0
    // ents_next[length(area)/2] = 1
    let ents_next = map(area): if rnd(6) <= 1: 1 else: 0
    return world{
        rules: rules,
        size: size,
        area: area,
        points: points,
        neighborhoods: map(points) v: map(cardinal_directions) d: index_of_point(modxy(v + d, grid), size),
        weights_next: randomize(map(area) n: n),
        weights: map(area): 0,
        ents_next: ents_next,
        ents: map(area): 0,
        bids: map(points): 0,
        bid_neighborhoods: map(points): map(cardinal_directions): 0,
        weight_neighborhoods: map(points): map(cardinal_directions): 0,
        winners: map(points): 0,
        winner_neighborhoods: map(points): map(cardinal_directions): 0,
        transitions: map(points): 0,
        directions: map(points): pick(cardinal_directions),
        headings: headings,
        headings_next: map(area): headings[_],
        rotations: map(area): 0,
        headings_rotated: map(area): 0,
        langtons: map(area): 0,
        langtons_next: map(area): 0
    }

do():

    let w = new_world(16, [1, -1, 0])

    w.tick()
    var start = gl_time()
    def next():
        let now = gl_time()
        let tween = (now - start) * 3.0
        if tween < 1.0:
            return tween
        start = now
        w.tick()
        return 0.0

    fatal(gl_window("Langtons Ents", 512, 512, 0))

    let tex = gl_load_texture("data/textures/entity.png")
    assert tex

    let first_rule_color = color{ 0.75, 0.75, 0.5, 1 }
    let last_rule_color = color{ 0.5, 0.5, 0.25, 1 }

    while gl_frame():
        let tween = next()

        gl_clear(color_white)
        center_unit_square()

        // draw background color according to langton rule number.
        gl_set_shader("color")
        for(w.area) i:
            let v = float(w.points[i])
            gl_translate v / w.size:
                let r1 = float(w.langtons[i]) / float(length(w.rules))
                let r2 = float(w.langtons_next[i]) / float(length(w.rules))
                let c1 = lerp(first_rule_color, last_rule_color, r1)
                let c2 = lerp(first_rule_color, last_rule_color, r2)
                let c = lerp(c1, c2, tween)
                gl_color(c)
                gl_scale(xy_1 / w.size)
                gl_rect(xy_1, 0)

        // draw foreground according to presence and heading of ents, tweened
        // along their translation and rotation vectors.
        gl_set_shader("textured")
        gl_set_primitive_texture(0, tex)
        for(w.area) i: if w.ents[i]:

            let v1 = float(w.points[i])
            let v2 = float(w.points[i] + w.directions[i])
            let v = lerp(v1, v2, tween)

            let a1 = float(w.headings[i]) * 90.0
            let a2 = float(w.headings_rotated[i]) * 90.0
            let a = lerp(a1, a2, tween)

            gl_translate v / w.size + xy_1 / w.size / 4:
                gl_scale(xy_1 / w.size / 2)
                gl_translate(xy_1 / 2)
                gl_rotate_z(rotate2D(xy_x, a))
                gl_translate(xy_1 / -2)
                gl_rect(xy_1, 0)
