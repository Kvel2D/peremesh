import haxegon.*;
import haxegon.MathUtils.IntVector2;
import Entity;
import Main.MainState;
#if (flash||html5)
import flash.net.SharedObject;
#end

using Lambda;

enum GameState {
    GameState_Turn;
    GameState_Fall;
    GameState_Result;
    GameState_LevelTransition;
    GameState_End;
}

enum PlayerMove {
    PlayerMove_None;
    PlayerMove_Left;
    PlayerMove_Right;
    PlayerMove_UpLeft;
    PlayerMove_UpRight;
    PlayerMove_Teleport;
    PlayerMove_Undo;
}

@:publicFields
class Teleport {
    var x:Int;
    var y:Int;
    var active:Bool;

    function new(x:Int, y:Int, active:Bool) {
        this.x = x;
        this.y = y;
        this.active = active;
    }
}

@:publicFields
class Game {
    static inline var RELEASE = false;
    static inline var DRAW_LEVEL_NAMES = false;
    static inline var RESET_SAVE = false;

    static inline var tilesize = 16;
    static inline var key_delay = 5;
    static inline var teleport_radius = 1;
    static inline var view_width = 20;
    static inline var view_height = 20;

    static var level_width = 20;
    static var level_height = 20;

    var state = GameState_Result;
    var fall_timer = 0;
    static inline var fall_timer_max = 5;
    static var t = 0;
    var completed_levels = 0;
    var world_position = {x: 0, y: 0};
    var in_world = true;

    var transition_level:Array<String>;
    var transition_timer = 0;
    static inline var transition_timer_max = 30;
    var transition_first_half = true;
    var transition_to_world = false;
    var transition_because_level_completed = false;

    static var ground:Array<Array<Bool>>;
    var tiles:Array<Array<Int>>;
    var level:Array<String>;
    var level_name = "";
    var last_room_x = 0;
    var last_room_y = 0;

    static var teleports = [for (i in 0...2) new Teleport(0, 0, false)];
    var teleports_history = new Array<Array<Teleport>>();

    // Some types have exceptions and need to have their own loop
    var vertical_solids:Array<Dynamic> = [Player, Box, DoorButton];
    var horizontal_solids:Array<Dynamic> = [Player, DoorButton];
    var falling_solids:Array<Dynamic> = [Box, DoorButton];

    var button_pressers:Array<Dynamic> = [Player, Box, Door, DoorButton];
    var entities_pushed_by_doors:Array<Dynamic> = [Player, Box, DoorButton, DoorKey];
    var falling_entities:Array<Dynamic> = [Door, Player, Box, DoorButton];
    var teleportable_entities:Array<Dynamic> = [Player, Box, Door, DoorButton, DoorKey, DoorLocked];
    var entities_with_a_history:Array<Dynamic> = [Player, Box, Door, DoorButton, DoorKey, DoorLocked];

    function new() {
        if (RESET_SAVE) {
            level = Levels.world;
            restart();
            var player = Entity.get(Player)[0];
            world_position.x = player.x;
            world_position.y = player.y;
            save_progress();
        }

        #if (flash||html5)
        var file = SharedObject.getLocal("save");
        if (file.data.keys == null 
            || file.data.values == null 
            || file.data.world_position_x == null
            || file.data.world_position_y == null) 
        {
            save_progress();
        } else {
            for (i in 0...file.data.keys.length) {
                Levels.completed.set(file.data.keys[i], file.data.values[i]);
                if (file.data.values[i]) {
                    completed_levels++;
                }
            }
            world_position.x = file.data.world_position_x;
            world_position.y = file.data.world_position_y;
        }
        #end


        if (RELEASE) {
            level = Levels.world;
        } else {
            level = Main.editor.level.copy();
            // level = Levels.world;
        }
        restart();

        if (RELEASE) {
            if (world_position.x != 0 || world_position.y != 0) {
                var player = Entity.get(Player)[0];
                player.x = world_position.x;
                player.y = world_position.y;
            }
        }
    }

    #if (flash||html5)
    function save_progress() {
        var file = SharedObject.getLocal("save");
        var keys = new Array<String>();
        var values = new Array<Bool>();
        for (key in Levels.completed.keys()) {
            keys.push(key);
            values.push(Levels.completed[key]);
        }
        file.data.keys = keys;
        file.data.values = values;
        file.data.world_position_x = world_position.x;
        file.data.world_position_y = world_position.y;
        file.flush();
    }
    #else
    function save_progress() {
    }
    #end

    static inline function out_of_bounds(x:Int, y:Int):Bool {
        return x < 0 || x >= level_width || y < 0 || y >= level_height;
    }

    static inline function screenx(x: Float):Float {
        return (x % view_width) * tilesize;
    }

    static inline function screeny(y: Float):Float {
        return (y % view_height) * tilesize;
    }

    function restart() {
        state = GameState_Result; // first state is Result to correctly save histories at t = 0
        t = -1; // because t is incremented at the start of update_result()

        level_width = level[0].length;
        level_height = level.length;

        ground = [for (i in 0...level_width) [for (i in 0...level_height) false]];
        tiles = [for (i in 0...level_width) [for (i in 0...level_height) Tiles.Empty]];

        for (teleport in teleports) {
            teleport.active = false;
        }
        teleports_history.splice(0, teleports_history.length);

        for (array in Entity.entities) {
            array.splice(0, array.length);
        }

        for (i in 0...level_width) {
            for (j in 0...level_height) {
                if (j < level.length && i < level[j].length) {
                    switch (level[j].charAt(i)) {
                        case '#': {
                            ground[i][j] = false;
                            tiles[i][j] = Tiles.Empty;
                        }
                        case '.': {
                            ground[i][j] = true;
                            tiles[i][j] = Tiles.Ground;
                        }
                        case 'p': {
                            ground[i][j] = true;
                            tiles[i][j] = Tiles.Ground;
                            var player = new Player();
                            player.x = i;
                            player.y = j;
                        }
                        case 'b': {
                            ground[i][j] = true;
                            tiles[i][j] = Tiles.Ground;
                            var box = new Box();
                            box.x = i;
                            box.y = j;
                        }
                        case 'o': {
                            ground[i][j] = true;
                            tiles[i][j] = Tiles.Ground;
                            var object = new Objective();
                            object.x = i;
                            object.y = j;
                        }
                        case 'd': {
                            ground[i][j] = true;
                            tiles[i][j] = Tiles.Ground;
                            var door = new Door();
                            door.x = i;
                            door.y = j;
                            door.color = DoorColor_White;
                        }
                        case 'q': {
                            ground[i][j] = true;
                            tiles[i][j] = Tiles.Ground;
                            var button = new DoorButton();
                            button.x = i;
                            button.y = j;
                            button.color = DoorColor_White;
                        }
                        case 'D': {
                            ground[i][j] = true;
                            tiles[i][j] = Tiles.Ground;
                            var door = new Door();
                            door.x = i;
                            door.y = j;
                            door.color = DoorColor_Black;
                        }
                        case 'Q': {
                            ground[i][j] = true;
                            tiles[i][j] = Tiles.Ground;
                            var button = new DoorButton();
                            button.x = i;
                            button.y = j;
                            button.color = DoorColor_Black;
                        }
                        case 'e': {
                            ground[i][j] = true;
                            tiles[i][j] = Tiles.Ground;
                            var entrance = new Entrance();
                            entrance.x = i;
                            entrance.y = j;
                        }
                        case 'I': {
                            ground[i][j] = false;
                            tiles[i][j] = Tiles.Pedestal;
                        }
                        case 'k': {
                            ground[i][j] = true;
                            tiles[i][j] = Tiles.Ground;
                            var key = new DoorKey();
                            key.x = i;
                            key.y = j;
                        }
                        case 'K': {
                            ground[i][j] = true;
                            tiles[i][j] = Tiles.Ground;
                            var door = new DoorLocked();
                            door.x = i;
                            door.y = j;
                        }
                        default: {
                            var tile_int = Std.parseInt(level[j].charAt(i));
                            if (tile_int != null && tile_int >= 0 && tile_int <= Levels.tutorial_tiles.length - 1) {
                                ground[i][j] = true;
                                tiles[i][j] = Levels.tutorial_tiles[tile_int];
                            } else {
                                ground[i][j] = true;
                                tiles[i][j] = Tiles.Question;
                            }
                        }
                    }
                }
            }
        }

        var player = Entity.get(Player)[0];
        last_room_x = Math.floor(player.x / view_width);
        last_room_y = Math.floor(player.y / view_height);

        update_entrance_state();
    }

    function update_entrance_state() {
        for (key in Levels.completed.keys()) {
            if (Levels.completed[key]) {
                var x = key.split('_')[0];
                var y = key.split('_')[1];
                for (entrance in Entity.get(Entrance)) {
                    if (entrance.x == x && entrance.y == y) {
                        entrance.completed = true;
                        break;
                    }
                }
            }
        }
    }

    function update_door_and_button_state() {
        for (button in Entity.get(DoorButton)) {
            button.pressed = function() {
                for (type in button_pressers) {
                    for (entity in Entity.get(type)) {
                        if (entity.x == button.x && entity.y == button.y - 1) {
                            return true;
                        }
                    }
                }
                return false;
            } ();
        }

        for (door in Entity.get(Door)) {
            var any_button_pressed = false;
            for (button in Entity.get(DoorButton)) {
                if (door.color == button.color && button.pressed) {
                    any_button_pressed = true;
                    break;
                }
            }
            door.closed = !any_button_pressed;
        }
    }

    function undo() {
        if (t > 0) {
            t--;

            // Undoing teleport state
            var teleports_previous = teleports_history[t];
            var active_teleports_previous = 0;
            for (teleport in teleports_previous) {
                if (teleport.active) {
                    active_teleports_previous++;
                }
            }
            var active_teleports = 0;
            for (teleport in teleports) {
                if (teleport.active) {
                    active_teleports++;
                }
            }
            if (active_teleports != active_teleports_previous) {
                if (active_teleports != 2 && active_teleports_previous != 2) {
                    // Changes to single teleport, nothing special
                    teleports[0].active = teleports_previous[0].active;
                    teleports[0].x = teleports_previous[0].x;
                    teleports[0].y = teleports_previous[0].y;
                    teleports[1].active = teleports_previous[1].active;
                    teleports[1].x = teleports_previous[1].x;
                    teleports[1].y = teleports_previous[1].y;
                } else if ((active_teleports == 1 && active_teleports_previous == 2) || (active_teleports == 2 && active_teleports_previous == 1)) {
                    // Undo or redo teleport(same thing, since it's a swap operation)
                    teleports[0].active = true;
                    teleports[1].active = true;
                    teleport();
                    teleports[0].active = teleports_previous[0].active;
                    teleports[0].x = teleports_previous[0].x;
                    teleports[0].y = teleports_previous[0].y;
                    teleports[1].active = teleports_previous[1].active;
                    teleports[1].x = teleports_previous[1].x;
                    teleports[1].y = teleports_previous[1].y;
                }
            }

            for (type in entities_with_a_history) {
                for (entity in Entity.get(type)) {
                    entity.x = entity.history[t].x;
                    entity.y = entity.history[t].y;
                }
            }
            for (door in Entity.get(DoorLocked)) {
                door.locked = door.locked_history[t];
            }
            for (key in Entity.get(DoorKey)) {
                key.carried = key.carried_history[t];
            }

            update_door_and_button_state();
        }
    }

    function teleport() {
        for (type in teleportable_entities) {
            for (entity in Entity.get(type)) {
                if (Math.abs(entity.x - teleports[0].x) <= teleport_radius && Math.abs(entity.y - teleports[0].y) <= teleport_radius) {
                    entity.x += teleports[1].x - teleports[0].x;
                    entity.y += teleports[1].y - teleports[0].y;
                } else if (Math.abs(entity.x - teleports[1].x) <= teleport_radius && Math.abs(entity.y - teleports[1].y) <= teleport_radius) {
                    entity.x += teleports[0].x - teleports[1].x;
                    entity.y += teleports[0].y - teleports[1].y;
                }
            }
        }

        var x1:Int;
        var x2:Int;
        var y1:Int;
        var y2:Int;
        var ground_temp:Bool;
        var tiles_temp:Int;
        for (dx in -teleport_radius...teleport_radius + 1) {
            for (dy in -teleport_radius...teleport_radius + 1) {
                x1 = teleports[0].x + dx;
                y1 = teleports[0].y + dy;
                x2 = teleports[1].x + dx;
                y2 = teleports[1].y + dy;
                if (!out_of_bounds(x1, y1) && !out_of_bounds(x2, y2)) {
                    ground_temp = ground[x1][y1];
                    ground[x1][y1] = ground[x2][y2];
                    ground[x2][y2] = ground_temp;

                    tiles_temp = tiles[x1][y1];
                    tiles[x1][y1] = tiles[x2][y2];
                    tiles[x2][y2] = tiles_temp;
                }
            }
        }
    }

    function entity_can_move(entity, dx:Int, dy:Int, can_push_boxes:Bool = false):Bool {
        var x = entity.x + dx;
        var y = entity.y + dy;

        if (out_of_bounds(x, y)) {
            return false;
        }


        // for player's diagonal movement
        if (dy != 0) {
            var x = entity.x;
            var y = entity.y + dy;

            if (!ground[x][y]) {
                return false;
            }
            for (type in vertical_solids) {
                for (entity in Entity.get(type)) {
                    if (x == entity.x && y == entity.y) {
                        return false;
                    }
                }
            }
            for (door in Entity.get(Door)) {
                if (door.closed && x == door.x && y == door.y) {
                    return false;
                }
            }
            for (door in Entity.get(DoorLocked)) {
                if (door.locked && x == door.x && y == door.y) {
                    return false;
                }
            }
        }


        if (!ground[x][y]) {
            return false;
        }
        for (type in horizontal_solids) {
            for (entity in Entity.get(type)) {
                if (x == entity.x && y == entity.y) {
                    return false;
                }
            }
        }
        for (door in Entity.get(Door)) {
            if (door.closed && x == door.x && y == door.y) {
                return false;
            }
        }
        for (door in Entity.get(DoorLocked)) {
            if (door.locked && x == door.x && y == door.y) {
                return false;
            }
        }

        if (can_push_boxes) {
            for (box in Entity.get(Box)) {
                if (x == box.x && y == box.y) {
                    return entity_can_move(box, dx, 0);
                }
            }
        } else {
            for (box in Entity.get(Box)) {
                if (box != entity && x == box.x && y == box.y) {
                    return false;
                }
            }
        }

        return true;
    }

    function update_turn(move:PlayerMove) {
        var player = Entity.get(Player)[0];

        if (Input.delay_pressed(Key.Z, key_delay) || move == PlayerMove_Undo) {
            undo();
            return;
        }

        if (Input.just_pressed(Key.E)) {
            var already_carrying_key = false;
            for (key in Entity.get(DoorKey)) {
                if (key.carried) {
                    already_carrying_key = true;
                    key.carried = false;
                    break;
                }
            }
            if (!already_carrying_key) {
                for (key in Entity.get(DoorKey)) {
                    if (key.x == player.x && key.y == player.y) {
                        key.carried = true;
                        return;
                    }
                }
            }
        }

        if (Input.just_pressed(Key.DOWN)) {
            for (entrance in Entity.get(Entrance)) {
                if (entrance.x == player.x && entrance.y == player.y) {
                    var entrance_position = '${entrance.x}_${entrance.y}';
                    if (Levels.level_entrances.exists(entrance_position)) {
                        state = GameState_LevelTransition;
                        transition_to_world = false;

                        transition_level = Levels.level_entrances[entrance_position].copy();
                        level_name = Levels.level_names[entrance_position];
                        return;
                    } else {
                        trace('No entry found in level_entrances map for entrance at ${entrance_position}');
                        break;
                    }
                }
            }
        }

        if ((Input.just_pressed(Key.T) || move == PlayerMove_Teleport) 
            && player.x % view_width != 0 && player.x % view_width != view_width - 1
            && player.y % view_height != 0 && player.y % view_height != view_height - 1) 
        {

            var active_teleports = 0;
            for (teleport in teleports) {
                if (teleport.active) {
                    active_teleports++;
                }
            }

            if (active_teleports == 0) {
                // Drop first teleport
                teleports[0].active = true;
                teleports[0].x = player.x;
                teleports[0].y = player.y;

                state = GameState_Result;
                return;
            } else if (active_teleports == 1) {
                var a:Int;
                var b:Int;
                if (teleports[0].active) {
                    a = 0;
                    b = 1;
                } else {
                    a = 1;
                    b = 0;
                }

                if (teleports[a].x == player.x && teleports[a].y == player.y) {
                    // pick up first one
                    teleports[a].active = false;

                    state = GameState_Result;
                    return;
                } else if (Math.abs(player.x - teleports[a].x) > 2 * teleport_radius || Math.abs(player.y - teleports[a].y) > 2 * teleport_radius) {
                    // Teleports can't intersect
                    teleports[b].active = true;
                    teleports[b].x = player.x;
                    teleports[b].y = player.y;

                    teleport();

                    state = GameState_Result;
                    return;
                }
            } else if (active_teleports == 2) {
                // To undo teleport, teleport again
                if (teleports[0].x == player.x && teleports[0].y == player.y) {
                    teleport();
                    teleports[0].active = false;

                    state = GameState_Result;
                    return;
                } else if (teleports[1].x == player.x && teleports[1].y == player.y) {
                    teleport();
                    teleports[1].active = false;

                    state = GameState_Result;
                    return;
                }
            }
        }

        var dx = 0;
        var dy = 0;
        var left = Input.delay_pressed(Key.A, key_delay) || Input.delay_pressed(Key.LEFT, key_delay);
        var right = Input.delay_pressed(Key.D, key_delay) || Input.delay_pressed(Key.RIGHT, key_delay);
        var up = Input.pressed(Key.W) || Input.pressed(Key.UP);
        // Movement
        if (left && !right) {
            dx = -1;
            dy = 0;
        } else if (right && !left) {
            dx = 1;
            dy = 0;
        }
        if (up) {
            if (dx != 0) {
                dy = -1;
            }
        }

        if (move == PlayerMove_Left) {
            dx = -1;
            dy = 0;
        } else if (move == PlayerMove_Right) {
            dx = 1;
            dy = 0;
        } else if (move == PlayerMove_UpLeft) {
            dx = -1;
            dy = -1;
        } else if (move == PlayerMove_UpRight) {
            dx = 1;
            dy = -1;
        }


        if (dx != 0 || dy != 0) {
            if (entity_can_move(player, dx, dy, true)) {
                // push box
                for (box in Entity.get(Box)) {
                    if (player.x + dx == box.x && player.y + dy == box.y) {
                        box.dx = dx;
                        break;
                    }
                }
                player.dx = dx;
                player.dy = dy;

                state = GameState_Result;
                return;
            } else {
                player.dx = 0;
                player.dy = 0;
            }
        }


        if (Main.state == MainState_Solver) {
            state = GameState_Result; // for solver, save positions even if player didn't move
        }
    }

    function is_falling(entity, is_key = false):Bool {
        if (out_of_bounds(entity.x, entity.y + 1)) {
            return false;
        }

        if (!ground[entity.x][entity.y + 1]) {
            return false;
        }

        for (type in falling_solids) {
            for (other_entity in Entity.get(type)) {
                if (other_entity.x == entity.x && other_entity.y == entity.y + 1) {
                    return false;
                }
            }
        }
        if (!is_key) {
            for (player in Entity.get(Player)) {
                if (player.x == entity.x && player.y == entity.y + 1) {
                    return false;
                }
            }
        }
        for (door in Entity.get(Door)) {
            if (door.closed && door.x == entity.x && door.y == entity.y + 1) {
                return false;
            }
        }
        for (door in Entity.get(DoorLocked)) {
            if (door.locked && door.x == entity.x && door.y == entity.y + 1) {
                return false;
            }
        }

        return true;
    }

    function any_entity_falling():Bool {
        for (type in falling_entities) {
            for (entity in Entity.get(type)) {
                if (is_falling(entity)) {
                    return true;
                }
            }
        }
        for (entity in Entity.get(DoorKey)) {
            if (!entity.carried && is_falling(entity, true)) {
                return true;
            }
        }
        return false;
    }

    function update_fall() {
        fall_timer++;

        if (fall_timer > fall_timer_max || Main.state == MainState_Solver) {
            fall_timer = 0;

            for (type in falling_entities) {
                for (entity in Entity.get(type)) {
                    if (is_falling(entity)) {
                        entity.y++;
                    }
                }
            }
            for (entity in Entity.get(DoorKey)) {
                if (entity.carried) {
                    var player = Entity.get(Player)[0];
                    entity.x = player.x;
                    entity.y = player.y;
                } else {
                    if (is_falling(entity, true)) {
                        entity.y++;
                    }
                }
            }

            if (any_entity_falling()) {
                state = GameState_Fall;
            } else {
                state = GameState_Result;
            }
        }
    }

    function update_result() {
        t++;

        // Save teleports history
        if (t >= teleports_history.length) {
            teleports_history.push([for (i in 0...2) new Teleport(teleports[i].x, teleports[i].y, teleports[i].active)]);
        } else {
            for (i in 0...teleports.length) {
                teleports_history[t][i].active = teleports[i].active;
                teleports_history[t][i].x = teleports[i].x;
                teleports_history[t][i].y = teleports[i].y;
            }
        }

        for (player in Entity.get(Player)) {
            player.x += player.dx;
            player.y += player.dy;
            player.dx = 0;
            player.dy = 0;
        }

        var player = Entity.get(Player)[0];
        var room_x = Math.floor(player.x / view_width);
        var room_y = Math.floor(player.y / view_height);
        if ((room_x != last_room_x || room_y != last_room_y))
        {
            if (teleports[0].active && teleports[1].active) {
                teleport();
            }
            for (teleport in teleports) {
                teleport.active = false;
            }
        }
        last_room_x = room_x;
        last_room_y = room_y;


        for (box in Entity.get(Box)) {
            box.x += box.dx;
            box.y += box.dy;
            box.dx = 0;
            box.dy = 0;
        }

        for (key in Entity.get(DoorKey)) {
            if (key.carried) {
                key.x = player.x;
                key.y = player.y;
                break;
            }
        }

        update_door_and_button_state();

        // door push
        for (door in Entity.get(Door)) {
            if (door.closed) {
                var pushable = function() {
                    for (type in entities_pushed_by_doors) {
                        for (entity in Entity.get(type)) {
                            if (entity != door && entity.x == door.x && entity.y == door.y) {
                                return entity;
                            }
                        }
                    }
                    for (entity in Entity.get(Door)) {
                        if (entity != door && entity.closed && entity.x == door.x && entity.y == door.y) {
                            return entity;
                        }
                    }
                    return null;
                } ();

                if (pushable != null) {
                    function entity_can_be_pushed(entity) {
                        var x = entity.x;
                        var y = entity.y - 1;

                        if (out_of_bounds(x, y)) {
                            return false;
                        }
                        if (!ground[x][y]) {
                            return false;
                        }
                        for (player in Entity.get(Player)) {
                            if (x == player.x && y == player.y) {
                                return false;
                            }
                        }
                        for (button in Entity.get(DoorButton)) {
                            if (x == button.x && y == button.y) {
                                return false;
                            }
                        }
                        for (box in Entity.get(Box)) {
                            if (x == box.x && y == box.y) {
                                return false;
                            }
                        }
                        for (door in Entity.get(Door)) {
                            if (x == door.x && y == door.y) {
                                return false;
                            }
                        }
                        for (door in Entity.get(DoorLocked)) {
                            if (door.locked && x == door.x && y == door.y) {
                                return false;
                            }
                        }
                        for (key in Entity.get(DoorKey)) {
                            if (x == key.x && y == key.y) {
                                return false;
                            }
                        }

                        return true;
                    }

                    function push(pushed_entity:Dynamic) {
                        if (entity_can_be_pushed(pushed_entity)) {
                            pushed_entity.y--;
                            return true;
                        } else {
                            var entatel = cast(pushable, Entity);
                            pushable = function() {
                                for (type in entities_pushed_by_doors) {
                                    for (entity in Entity.get(type)) {
                                        if (entity.x == pushable.x && entity.y == pushable.y - 1) {
                                            return entity;
                                        }
                                    }
                                }
                                for (entity in Entity.get(Door)) {
                                    if (entity != pushable && entity.x == pushable.x && entity.y == pushable.y - 1) {
                                        return entity;
                                    }
                                }
                                return null;
                            } ();

                            if (pushable != null) {
                                if (push(pushable)) {
                                    pushed_entity.y--;
                                    return true;
                                } else {
                                    return false;
                                }
                            }
                            return false;
                        }
                    }

                    var push_succesful = push(pushable);
                    if (!push_succesful) {
                        door.closed = false;
                    }
                }
            }
        }

        for (door in Entity.get(DoorLocked)) {
            if (door.locked) {
                for (key in Entity.get(DoorKey)) {
                    if (Math.abs(key.x - door.x) <= 1 && Math.abs(key.y - door.y) <= 1 
                        && (key.x == door.x || key.y == door.y))
                    {
                        door.locked = false;
                        key.carried = false;
                        key.x = 22;
                        key.y = 22;
                        break;
                    }
                }
            }
        }

        for (type in entities_with_a_history) {
            for (entity in Entity.get(type)) {
                var history:Array<IntVector2> = entity.history;
                if (t >= history.length) {
                    history.push({x: entity.x, y: entity.y});
                } else {
                    history[t].x = entity.x;
                    history[t].y = entity.y;
                }
            }
        }
        for (door in Entity.get(DoorLocked)) {
            var history:Array<Bool> = door.locked_history;
            if (t >= history.length) {
                history.push(door.locked);
            } else {
                history[t] = door.locked;
            }
        }
        for (key in Entity.get(DoorKey)) {
            var history:Array<Bool> = key.carried_history;
            if (t >= history.length) {
                history.push(key.carried);
            } else {
                history[t] = key.carried;
            }
        }

        if (Main.state != MainState_Solver) {
            var player = Entity.get(Player)[0];
            for (objective in Entity.get(Objective)) {
                if (player.x == objective.x && player.y == objective.y) {
                    state = GameState_LevelTransition;
                    transition_level = Levels.world.copy();
                    level_name = "";
                    transition_to_world = true;
                    transition_because_level_completed = true;
                    return;
                }
            }
        }

        var ending = (completed_levels >= Levels.level_entrances.count()) && (player.y == 55) 
        && (player.x == 49 || player.y == 50);


        if (ending) {
            state = GameState_End;
        } else if (any_entity_falling()) {
            state = GameState_Fall;
            t--; // THIS MIGHT BREAK!! "undo" history recording before falling to not save floating states
        } else {
            state = GameState_Turn;
        }
    }

    function update_level_transition() {
        if (transition_first_half) {
            transition_timer--;

            if (transition_timer < 0) {
                transition_timer = 0;
                transition_first_half = false;

                level = transition_level;
                Main.editor.level = level.copy();
                var player = Entity.get(Player)[0];

                // Save world position
                if (!transition_to_world) {
                    world_position.x = player.x;
                    world_position.y = player.y;
                }

                restart(); // restart changes state
                state = GameState_LevelTransition;

                if (transition_to_world) {
                    in_world = true;
                } else {
                    in_world = false;
                }

                if (transition_to_world) {
                    var player = Entity.get(Player)[0];
                    player.x = world_position.x;
                    player.y = world_position.y;

                    if (transition_because_level_completed) {
                        for (entrance in Entity.get(Entrance)) {
                            if (entrance.x == player.x && entrance.y == player.y) {
                                var completed_before = Levels.completed.get('${entrance.x}_${entrance.y}');
                                if (!completed_before) {
                                    completed_levels++;
                                    Levels.completed.set('${entrance.x}_${entrance.y}', true);
                                    save_progress();
                                }
                                break;
                            }
                        }
                        update_entrance_state();
                    }
                }
            }
        } else {
            transition_timer++;
            
            if (transition_timer > transition_timer_max) {
                state = GameState_Result;
                transition_first_half = true;
                transition_timer = transition_timer_max;
            }
        }
    }


    var face_y = 54;
    var face_in_front = false;
    var face_end_tile = 0;
    var face_timer = 0;
    var face_timer_max = 5;
    function update_end() {
        if (face_end_tile < 10) {
            if (face_y < 134) {
                face_y++;

                face_timer++;
                if (face_timer > face_timer_max) {
                    face_timer = 0;
                    if (face_end_tile < 5) {
                        face_end_tile++;
                    }
                }
            } else {
                face_in_front = true;

                face_timer++;
                if (face_timer > face_timer_max) {
                    face_timer = 0;
                    if (face_end_tile < 10) {
                        face_end_tile++;
                    }
                }
            }
        } else {
            while (face_y > 54) {
                face_y--;
                return;
            }
        }
    }

    function render() {
        var player = Entity.get(Player)[0];
        var room_x = Math.floor(player.x / view_width);
        var room_y = Math.floor(player.y / view_height);

        Gfx.changetileset("tiles");
        for (i in (room_x * view_width)...((room_x + 1) * view_width)) {
            for (j in (room_y * view_height)...((room_y + 1) * view_height)) {
                if (tiles[i][j] != Tiles.Empty) {
                    Gfx.draw_tile(screenx(i), screeny(j), tiles[i][j]);
                }
            }
        }

        function draw_entity(entity, tile:Int) {
            if (entity.x >= room_x * view_width 
                && entity.x < (room_x + 1) * view_width 
                && (entity.y >= room_y * view_height) 
                && entity.y < (room_y + 1) * view_height) 
            {
                Gfx.draw_tile(screenx(entity.x), screeny(entity.y), tile);
            }
        }

        for (box in Entity.get(Box)) {
            draw_entity(box, Tiles.Box);
        }
        for (button in Entity.get(DoorButton)) {
            if (button.color == DoorColor_White) {
                if (button.pressed) {
                    draw_entity(button, Tiles.ButtonWhiteOn);
                } else {
                    draw_entity(button, Tiles.ButtonWhiteOff);
                }
            } else {
                if (button.pressed) {
                    draw_entity(button, Tiles.ButtonBlackOn);
                } else {
                    draw_entity(button, Tiles.ButtonBlackOff);
                }
            }
        }
        for (door in Entity.get(Door)) {
            if (door.color == DoorColor_White) {
                if (door.closed) {
                    draw_entity(door, Tiles.DoorWhiteClosed);
                } else {
                    draw_entity(door, Tiles.DoorWhiteOpen);
                }
            } else {
                if (door.closed) {
                    draw_entity(door, Tiles.DoorBlackClosed);
                } else {
                    draw_entity(door, Tiles.DoorBlackOpen);
                }
            }
        }
        for (objective in Entity.get(Objective)) {
            draw_entity(objective, Tiles.SpiralPurple);
        }
        for (entrance in Entity.get(Entrance)) {
            if (entrance.completed) {
                draw_entity(entrance, Tiles.SpiralPurple);
            } else {
                draw_entity(entrance, Tiles.SpiralGray);
            }
        }
        for (door in Entity.get(DoorLocked)) {
            if (door.locked) {
                draw_entity(door, Tiles.DoorLocked);
            } else {
                draw_entity(door, Tiles.DoorUnlocked);
            }
        }

        function draw_face() {
            Gfx.changetileset("face");
            if (room_x == 2 && room_y == 2) {
                Gfx.draw_tile(10 * tilesize - Gfx.tilewidth() / 2, 
                    face_y, face_end_tile + Std.int(Math.min(completed_levels / Levels.level_entrances.count() * 4, 4)));
                // all levels complete = eat
            }
            Gfx.changetileset("tiles");
        }
        if (!face_in_front) {
            draw_face();
        }

        if (face_end_tile < 10) {
            for (player in Entity.get(Player)) {
                draw_entity(player, Tiles.Player);
            }
        }

        for (key in Entity.get(DoorKey)) {
            draw_entity(key, Tiles.Key);
        }

        for (teleport in teleports) {
            if (teleport.active) {
                Gfx.fill_box(screenx(teleport.x - teleport_radius), screeny(teleport.y - teleport_radius), 
                    (teleport_radius * 2 + 1) * tilesize, (teleport_radius * 2 + 1) * tilesize, Col.BLUE, 0.2);
                Gfx.draw_tile(screenx(teleport.x), screeny(teleport.y), Tiles.Teleport);
            }
        }


        if (face_in_front) {
            draw_face();
        }


        if (DRAW_LEVEL_NAMES) {
            Text.display(0, 0, level_name);
        }

        if (state == GameState_LevelTransition) {
            Gfx.fill_box(0, 0, Gfx.screen_width, Gfx.screen_height, Col.BLACK, 1 - transition_timer / transition_timer_max);
        }
    }

    function update(?move:PlayerMove) {
        if (move == null) {
            move = PlayerMove_None;
        }

        switch (state) {
            case GameState_Turn: update_turn(move);
            case GameState_Fall: update_fall();
            case GameState_Result: update_result();
            case GameState_LevelTransition: update_level_transition();
            case GameState_End: update_end();
        }

        if (Main.state == MainState_Solver) {
            return;
        }

        render();

        if (!RELEASE) {
            if (Input.just_pressed(Key.F)) {
                Main.state = MainState_Editor;
                return;
            }
        }

        if (!in_world && state != GameState_End && state != GameState_LevelTransition) {
            if (Input.just_pressed(Key.R)) {
                restart();
                return;
            }
            if (Input.just_pressed(Key.ESCAPE)) {
                state = GameState_LevelTransition;
                transition_timer = transition_timer_max;
                transition_level = Levels.world.copy();
                level_name = "";
                transition_to_world = true;
                transition_because_level_completed = false;
                return;
            }
        }
    }
}
