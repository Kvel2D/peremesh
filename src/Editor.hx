import haxegon.*;
import haxe.ds.Vector;
#if (flash||html5)
import flash.net.SharedObject;
#elseif cpp
import sys.io.File;
import sys.FileSystem;
#end

using Lambda;

enum EditorState {
    EditorState_DragDrop;
    EditorState_TilePlacement;
    EditorState_Load;
}


@:publicFields
class Editor {
    var state = EditorState_DragDrop;

    var level: Array<String>;
    var level_history = new Array<Array<String>>();

    var dragged_tile: String = null;
    var dragged_from = {x: 0, y: 0};
    var current_tile: String = null;
    var current_room = {x: 0, y: 0};

    function new() {
        #if flash
        var file = SharedObject.getLocal("temp");
        if (file.data.temp == null) {
            file.data.temp = Levels.wall.copy();
        }
        level = file.data.temp.copy();
        #elseif cpp
        if (FileSystem.exists("./temp.txt")) {
            var level_in_file = File.getContent("./temp.txt").split('\n');
            while (level_in_file.length % 20 != 0) {
                level_in_file.pop(); // pop last '\n'
            }
            for (line in level_in_file) {
                while (line.length % 20 != 0) {
                    level_in_file.pop(); // pop last '\n'
                }
            }
            level = level_in_file;
        } else {
            var level_string = "";
            for (line in Levels.wall) {
                level_string += line;
                level_string += '\n';
            }
            File.saveContent("./temp.txt", level_string);
            level = Levels.wall.copy();
        }
        #else
        level = Levels.wall.copy();
        #end

        level_history.push(level.copy());
    }

    function load_level() {
        state = EditorState_Load;
        Text.reset_text_input();
    }
    function drag_drop() {
        state = EditorState_DragDrop;
        dragged_tile = null;
        current_tile = null;
    }
    function start_placing_tile(tile: String) {
        state = EditorState_TilePlacement;
        if (dragged_tile != null) {
            set_tile(dragged_from.x, dragged_from.y, dragged_tile);
            dragged_tile = null;
        }
        current_tile = tile;
    }
    function print_level() {
        var out = "";
        for (i in 0...level.length) {
            out += '\n\"' + level[i] + '\",';
        }
        trace(out);
    }
    function solve() {
        Main.state = MainState_Solver;
        state = EditorState_DragDrop;
        Main.game.level = level.copy();
        Main.game.restart();
        Main.solver.solve();
    }

    function out_of_bounds(x: Int, y: Int) {
        var x_min = current_room.x * Game.view_width;
        var y_min = current_room.y * Game.view_height;
        var x_max = (current_room.x + 1) * Game.view_width;
        var y_max = (current_room.y + 1) * Game.view_height;
        return x < x_min || x >= x_max || y < y_min || y >= y_max;
    }

    function set_tile(x: Int, y: Int, tile: String) {
        level[y] = level[y].substring(0, x) + tile + level[y].substring(x + 1);
    }

    function update_dragdrop() {
        var x = Std.int(Mouse.x / Game.tilesize) + current_room.x * Game.view_width;
        var y = Std.int(Mouse.y / Game.tilesize) + current_room.y * Game.view_height;
        if (Mouse.left_click() && !out_of_bounds(x, y)) {
            dragged_tile = level[y].charAt(x);
            if (dragged_tile != '#' && dragged_tile != '.') {
                set_tile(x, y, '.');
                dragged_from.x = x;
                dragged_from.y = y;
            } else {
                dragged_tile = null;
            }
        } else if (Mouse.left_released() && dragged_tile != null) {
            if (out_of_bounds(x, y)) {
                set_tile(dragged_from.x, dragged_from.y, dragged_tile);
            } else {
                set_tile(x, y, dragged_tile);
            }
            dragged_tile = null;
        } else if (Mouse.right_click() || Mouse.right_held()) {
            if (!out_of_bounds(x, y)) {
                set_tile(x, y, '#');
            }
        }
    }

    function update_placement() {
        if (Mouse.x > Buttons.x) {
            // ignore ui button input
            return;
        }

        var x = Std.int(Mouse.x / Game.tilesize) + current_room.x * Game.view_width;
        var y = Std.int(Mouse.y / Game.tilesize) + current_room.y * Game.view_height;
        if (!out_of_bounds(x, y)) {
            if (Mouse.left_click() || Mouse.left_held()) {
                set_tile(x, y, current_tile);
            } else if (Mouse.right_click() || Mouse.right_held()) {
                set_tile(x, y, '#');
            }
        }
    }

    function update_load() {
        if (Text.input(0, 0, "level:\n")) {
            var level_text = Text.get_input().split(",");
            level_text = level_text.map(function(line) return line.split('\"')[1]);
            level_text = level_text.filter(function(line) return line != null && line.length != 0);

            if (level_text.length % 20 != 0) {
                trace("level height is not a multiple of 20");
                return;
            }
            for (line in level_text) {
                if (line.length % 20 != 0) {
                    trace(line.length);
                    trace('width of level line number ${level_text.indexOf(line)} is not a multiple of 20');
                    return;
                }
            }

            level = level_text.copy();
        }
    }

    function draw_level_tile(x: Float, y: Float, tile: String) {
        switch (tile) {
            case '#': {

            }
            case '.': {
                Gfx.draw_tile(x, y, Tiles.Ground);
            }
            case 'p': {
                Gfx.draw_tile(x, y, Tiles.Ground);
                Gfx.draw_tile(x, y, Tiles.Player);
            }
            case 'b': {
                Gfx.draw_tile(x, y, Tiles.Ground);
                Gfx.draw_tile(x, y, Tiles.Box);
            }
            case 'o': {
                Gfx.draw_tile(x, y, Tiles.Ground);
                Gfx.draw_tile(x, y, Tiles.SpiralPurple);
            }
            case 'd': {
                Gfx.draw_tile(x, y, Tiles.Ground);
                Gfx.draw_tile(x, y, Tiles.DoorWhiteClosed);
            }
            case 'q': {
                Gfx.draw_tile(x, y, Tiles.Ground);
                Gfx.draw_tile(x, y, Tiles.ButtonWhiteOff);
            }
            case 'D': {
                Gfx.draw_tile(x, y, Tiles.Ground);
                Gfx.draw_tile(x, y, Tiles.DoorBlackClosed);
            }
            case 'Q': {
                Gfx.draw_tile(x, y, Tiles.Ground);
                Gfx.draw_tile(x, y, Tiles.ButtonBlackOff);
            }
            case 'e': {
                Gfx.draw_tile(x, y, Tiles.Ground);
                Gfx.draw_tile(x, y, Tiles.SpiralGray);
            }
            case 'I': {
                Gfx.draw_tile(x, y, Tiles.Pedestal);
            }
            case 'k': {
                Gfx.draw_tile(x, y, Tiles.Ground);
                Gfx.draw_tile(x, y, Tiles.Key);
            }
            case 'K': {
                Gfx.draw_tile(x, y, Tiles.Ground);
                Gfx.draw_tile(x, y, Tiles.DoorLocked);
            }
            default: {
                var tile_int = Std.parseInt(tile);
                if (tile_int != null && tile_int >= 0 && tile_int <= Levels.tutorial_tiles.length - 1) {
                    Gfx.draw_tile(x, y, Levels.tutorial_tiles[tile_int]);
                } else {
                    Gfx.draw_tile(x, y, Tiles.Question);
                }
            }
        }
    }

    function update() {
        if (Input.just_pressed(Key.F) || Input.just_pressed(Key.ESCAPE)) {
            Main.state = MainState_Game;
            state = EditorState_DragDrop;
            Main.game.level = level.copy();
            Main.game.restart();
            return;
        }

        if (Input.just_pressed(Key.LEFT)) {
            current_room.x--;
            if (current_room.x < 0) {
                current_room.x = 0;
            }
        } else if (Input.just_pressed(Key.RIGHT)) {
            current_room.x++;
            if (current_room.x > Math.floor(Game.level_width / Game.view_width) - 1) {
                current_room.x = Math.floor(Game.level_width / Game.view_width) - 1;
            }
        } else if (Input.just_pressed(Key.UP)) {
            current_room.y--;
            if (current_room.y < 0) {
                current_room.y = 0;
            }
        } else if (Input.just_pressed(Key.DOWN)) {
            current_room.y++;
            if (current_room.y > Math.floor(Game.level_height / Game.view_height) - 1) {
                current_room.y = Math.floor(Game.level_height / Game.view_height) - 1;
            }
        }

        if (Input.delay_pressed(Key.Z, 7)) {
            if (level_history.length > 1) {
                level_history.pop();
                level.splice(0, level.length);
                for (line in level_history[level_history.length - 1]) {
                    level.push(new String(line));
                }
            }
        }

        if (Input.just_pressed(Key.P)) {
            start_placing_tile('p');
        } else if (Input.just_pressed(Key.G)) {
            start_placing_tile('.');
        } else if (Input.just_pressed(Key.O)) {
            start_placing_tile('o');
        } else if (Input.just_pressed(Key.B)) {
            start_placing_tile('b');
        }

        switch (state) {
            case EditorState_DragDrop: update_dragdrop();
            case EditorState_TilePlacement: update_placement();
            case EditorState_Load: update_load();
        }

        var level_changed = false;
        for (i in 0...level.length) {
            if (level[i] != level_history[level_history.length - 1][i]) {
                level_history.push(level.copy());
                level_changed = true;
            }
        }

        if (level_changed) {
            #if flash
            var file = SharedObject.getLocal("temp");
            file.data.temp = level.copy();
            file.flush();
            #elseif cpp
            var level_string = "";
            for (line in level) {
                level_string += line;
                level_string += '\n';
            }
            File.saveContent("./temp.txt", level_string);
            #end
        }

        Gfx.changetileset("tiles");
        for (x in (current_room.x * Game.view_width)...((current_room.x + 1) * Game.view_width)) {
            for (y in (current_room.y * Game.view_height)...((current_room.y + 1) * Game.view_height)) {
                draw_level_tile(Game.screenx(x), Game.screeny(y), level[y].charAt(x));
            }
        }

        if (dragged_tile != null) {
            var x = Std.int(Mouse.x / Game.tilesize);
            var y = Std.int(Mouse.y / Game.tilesize);
            draw_level_tile(Game.screenx(x), Game.screeny(y), dragged_tile);
        }
        Gfx.draw_box(0, 0, Game.view_width * Game.tilesize, Game.view_height * Game.tilesize, Col.WHITE);

        Buttons.x = 320;
        Buttons.y = 0;
        Buttons.button("Drag drop", drag_drop);
        Buttons.button("Player", function() start_placing_tile('p'));
        Buttons.button("Box", function() start_placing_tile('b'));
        Buttons.button("Objective", function() start_placing_tile('o'));
        Buttons.button("White door", function() start_placing_tile('d'));
        Buttons.button("White button", function() start_placing_tile('q'));
        Buttons.button("Black door", function() start_placing_tile('D'));
        Buttons.button("Black button", function() start_placing_tile('Q'));
        Buttons.button("Ground", function() start_placing_tile('.'));
        Buttons.button("Entrance", function() start_placing_tile('e'));
        Buttons.button("Pedestal", function() start_placing_tile('I'));
        Buttons.button("Key", function() start_placing_tile('k'));
        Buttons.button("Locked door", function() start_placing_tile('K'));

        Buttons.button("Left", function() start_placing_tile('0'), 1);
        Buttons.button("Right", function() start_placing_tile('1'));
        Buttons.button("Up", function() start_placing_tile('2'));
        Buttons.button("Down", function() start_placing_tile('3'));

        Buttons.button("Print level", print_level, 1);
        Buttons.button("Load level", load_level);
        Buttons.button("Solve", solve, 1);


        if (state == EditorState_TilePlacement) {
            Text.display(0, 0, 'placing tile: ${current_tile}');
        } else if (state == EditorState_DragDrop){
            Text.display(0, 0, 'drag drop');
        }
        Text.display(0, 20, 'room: ${current_room.x} ${current_room.y}');
        var x = Std.int(Mouse.x / Game.tilesize) + current_room.x * Game.view_width;
        var y = Std.int(Mouse.y / Game.tilesize) + current_room.y * Game.view_height;
        Text.display(0, 30, '${x} ${y}');
    }
}
