import haxegon.*;
import haxe.ds.Vector;

enum MainState {
    MainState_Game;
    MainState_Editor;
    MainState_Solver;
}


@:publicFields
class Main {
    static inline var screen_width = 640;
    static inline var screen_height = 400;
    static var state = MainState_Game;
    static var game: Game;
    static var solver: Solver;
    static var editor: Editor;

    static var vectors = new Array<Vector<Int>>();
    static var strings = new Array<String>();

    function new() {
        Text.setfont("pixelFJ8", 8);
        Text.inputmaxlength = 600; // for loading long level strings

        if (Game.RELEASE) {
            #if !html5
            Gfx.resize_screen(Game.tilesize * Game.view_width, Game.tilesize * Game.view_height, 3);
            #else
            Gfx.resize_screen(Game.tilesize * Game.view_width, Game.tilesize * Game.view_height, 1);
            #end
        } else {
            #if !html5
            Gfx.resize_screen(screen_width, screen_height, 3);
            #else
            Gfx.resize_screen(screen_width, screen_height, 1);
            #end
        }

        Gfx.load_tiles("tiles", Game.tilesize, Game.tilesize);
        Gfx.load_tiles("face", 160, 160);

        editor = new Editor();
        game = new Game();
        solver = new Solver();
    }


    function update() {
        switch (state) {
            case MainState_Game: game.update();
            case MainState_Editor: editor.update();
            case MainState_Solver: solver.update();
        }
    }
}
