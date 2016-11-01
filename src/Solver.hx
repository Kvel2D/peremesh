import haxegon.*;
import haxegon.MathUtils.IntVector2;
import haxe.Timer;
import Entity;
import Game.PlayerMove;

enum SolverState {
    SolverState_Normal;
    SolverState_Replay;
    SolverState_Solving;
    SolverState_SetDepth;
}

typedef SolutionNode = {
    state: String,
    current_branch: Int,
    previous: SolutionNode,
    depth: Int,
}

@:publicFields
class Solver {
    var state = SolverState_Normal;
    var replay_speed = 5;
    #if cpp
    var steps_per_frame = 1000000;
    #else
    var steps_per_frame = 500;
    #end
    var steps_counter = 0;

    var selected_replay = 0;
    var current_replay_step = 0;

    var current_path = new Array<SolutionNode>();
    var current_node: SolutionNode;
    var states: Map<String, Int>;
    var solutions = new Array<Array<PlayerMove>>();
    static inline var max_solutions = 5;
    var move = PlayerMove_None;
    var next_move = true;

    var game = Main.game;


    var t = 0;
    var max_depth_default = 42;
    var max_depth = 42;

    var player:Player;
    var objective:Objective;

    var moves = [
    PlayerMove_Left,
    PlayerMove_Right,
    PlayerMove_UpLeft,
    PlayerMove_UpRight,
    PlayerMove_Teleport
    ];

    var start_time: Float;

    function new() {

    }

    function solve() {
        state = SolverState_Solving;
        max_depth = max_depth_default;
        t = 0;
        Main.game.restart();
        states = new Map<String, Int>();
        current_path = new Array<SolutionNode>();
        solutions = new Array<Array<PlayerMove>>();

        current_node = {
            state: get_game_state(),
            current_branch: 0,
            previous: null,
            depth: 0,
        };
        current_path.push(current_node);
        next_move = true;

        player = Entity.get(Player)[0];
        objective = Entity.get(Objective)[0];

        start_time = Timer.stamp();
    }

    function get_game_state(): String {
        var state = "";

        function add_state(identifier: Int, entity) {
            state += String.fromCharCode(identifier);
            state += String.fromCharCode(entity.x);
            state += String.fromCharCode(entity.y);
        }

        for (player in Entity.get(Player)) {
            add_state(Tiles.Player, player);
        }
        for (box in Entity.get(Box)) {
            add_state(Tiles.Box, box);
        }
        for (objective in Entity.get(Objective)) {
            add_state(Tiles.SpiralPurple, objective);
            
        }
        for (teleport in Game.teleports) {
            if (teleport.active) {
                add_state(Tiles.Teleport, teleport);
            }
        }
        for (button in Entity.get(DoorButton)) {
            if (button.color == DoorColor_White) {
                if (button.pressed) {
                    add_state(Tiles.ButtonWhiteOn, button);
                } else {
                    add_state(Tiles.ButtonWhiteOff, button);
                }
            } else {
                if (button.pressed) {
                    add_state(Tiles.ButtonBlackOn, button);
                } else {
                    add_state(Tiles.ButtonBlackOff, button);
                }
            }
        }
        for (door in Entity.get(Door)) {
            if (door.color == DoorColor_White) {
                if (door.closed) {
                    add_state(Tiles.DoorWhiteOpen, door);
                } else {
                    add_state(Tiles.DoorWhiteClosed, door);
                }
            } else {
                if (door.closed) {
                    add_state(Tiles.DoorWhiteOpen, door);
                } else {
                    add_state(Tiles.DoorWhiteClosed, door);
                }
            }
        }

        return state;
    }

    function update_replay() {
        if (next_move && Input.delay_pressed(Key.ENTER, replay_speed)) {
            next_move = false;
            move = solutions[selected_replay][current_replay_step];
            t++;
        } else if (move != PlayerMove_None) {
            if (t > Game.t) {
                Main.game.update(move);
            } else {
                next_move = true;
                move = PlayerMove_None;
                current_replay_step++;
                if (current_replay_step > solutions[selected_replay].length - 1) {
                    state = SolverState_Normal;
                }
            }
        }
    }

    var k = 0;
    function update_solving() {
        if (next_move) {
            // CAREFUL HERE this will fail if Teleport is not last in moves array
            // because a node will run out of branches, and this is not dealt with here
            // (fine, as long as some other move is there)
            while (next_move) {
                move = moves[current_node.current_branch];

                // Check for redundant moves, better than a lookup later
                var redundant_move = false;
                function no_landing_place(x, y) {
                    if (!Game.out_of_bounds(x, y) && !Game.ground[x][y]) {
                        return false;
                    }
                    for (box in Entity.get(Box)) {
                        if (box.x == x && box.y == y) {
                            return false;
                        }
                    }
                    for (door in Entity.get(Door)) {
                        if (door.x == x && door.y == y) {
                            return false;
                        }
                    }
                    for (button in Entity.get(DoorButton)) {
                        if (button.x == x && button.y == y) {
                            return false;
                        }
                    }
                    return true;
                }
                if (move == PlayerMove_Left) {
                    if (!Game.out_of_bounds(player.x - 1, player.y) && !Game.ground[player.x - 1][player.y]) {
                        redundant_move = true;
                    }
                } else if (move == PlayerMove_Right) {
                    if (!Game.out_of_bounds(player.x + 1, player.y) && !Game.ground[player.x + 1][player.y]) {
                        redundant_move = true;
                    }
                } else if (move == PlayerMove_UpLeft) {
                    if (no_landing_place(player.x - 1, player.y)) {
                        redundant_move = true;
                    }
                } else if (move == PlayerMove_UpRight) {
                    if (no_landing_place(player.x + 1, player.y)) {
                        redundant_move = true;
                    }
                }

                if (redundant_move) {
                    current_node.current_branch++;
                } else {
                    next_move = false;
                }
            }
            current_node.current_branch++;
            t++;
        } else if (move != PlayerMove_None) {
            if (t > Game.t) {
                k++;
                if (k == 34) {
                    var a = 0;
                }
                Main.game.update(move);
            } else {
                next_move = true;
                move = PlayerMove_None;

                var new_node = {
                    state: get_game_state(),
                    current_branch: 0,
                    previous: current_node,
                    depth: current_node.depth + 1,
                };

                var bad_node = false;
                if (new_node.depth > max_depth) {
                    bad_node = true;
                }
                if (!bad_node) {
                    var current_previous = new_node.previous;
                    while (current_previous.previous != null) {
                        if (new_node.state == current_previous.state) {
                            bad_node = true;
                            break;
                        } else {
                            current_previous = current_previous.previous;
                        }
                    }
                }
                if (!bad_node) {
                    var depth = states[new_node.state];
                    if (depth != null && depth < new_node.depth) {
                        bad_node = true;
                    }
                }
                

                if (bad_node) {
                    Main.game.undo();
                    t--;
                    while (current_node.current_branch > moves.length - 1) {
                        if (current_node.previous == null) {
                            // Start node complete, end solver
                            state = SolverState_Normal;
                            trace('${Std.int(Timer.stamp() - start_time)}');
                            return;
                        } else {
                            current_path.remove(current_node);
                            current_node = current_node.previous;
                            Main.game.undo();
                            t--;
                        }
                    }
                } else {
                    current_node = new_node;
                    current_path.push(new_node);
                    states.set(new_node.state, new_node.depth);

                    if (player.x == objective.x && player.y == objective.y) {
                        // Solution get!
                        var current = current_node;
                        var solution = new Array<PlayerMove>();
                        while (current.previous != null) {
                            solution.push(moves[current.previous.current_branch - 1]);
                            current = current.previous;
                        }
                        solution.reverse();

                        if (solution.length < max_depth) {
                            max_depth = solution.length - 1;
                        }

                        solutions.push(solution);
                        if (solutions.length > max_solutions) {
                            var max = solutions[0];
                            for (i in 0...solutions.length) {
                                if (solutions[i].length > max.length) {
                                    max = solutions[i];
                                }
                            }
                            solutions.remove(max);
                        }


                        current_node = current_node.previous;
                        current_node.current_branch = moves.length;
                        Main.game.undo();
                        t--;
                    }
                }
            }
        }
    }

    function update_set_depth() {
        if (Text.input(0, 40, "Set depth:")) {
            max_depth_default = Std.parseInt(Text.get_input());
            state = SolverState_Normal;
        }
    }

    function update() {
        if (Input.just_pressed(Key.F) || Input.just_pressed(Key.ESCAPE)) {
            Main.state = MainState_Game;
            state = SolverState_Normal;
            return;
        }

        switch (state) {
            case SolverState_Solving: {
                while (steps_counter < steps_per_frame && state == SolverState_Solving) {
                    steps_counter++;
                    update_solving();
                }
                steps_counter = 0;
            }
            case SolverState_Replay: update_replay();
            case SolverState_SetDepth: update_set_depth();
            default:
        }

        Main.game.render();
        Text.display(0, 0, '${state}');

        switch (state) {
            case SolverState_Solving: {
                if (current_node != null) {
                    Text.display(0, 10, 'Depth: ${current_node.depth}');
                    Text.display(0, 20, 'Max depth: ${max_depth}');
                    Text.display(0, 30, 'Running time: ${Std.int(Timer.stamp() - start_time)}');
                }
            }
            case SolverState_Replay: {
                function move_string(move: PlayerMove) return '$move'.substring('$move'.indexOf('_') + 1);
                for (i in 1...5) {
                    if (current_replay_step - i >= 0) {
                        Text.display(0, 60 - i * 10, '${current_replay_step - i}: ${move_string(solutions[selected_replay][current_replay_step - i])}');
                    }
                    if (current_replay_step + i <= solutions[selected_replay].length - 1) {
                        Text.display(0, 60 + i * 10, '${current_replay_step + i}: ${move_string(solutions[selected_replay][current_replay_step + i])}');
                    }
                }
                Text.display(0, 60, '$current_replay_step: ${move_string(solutions[selected_replay][current_replay_step])}', Col.PINK);
            }
            default:
        }


        Buttons.x = 320;
        Buttons.y = 0;
        Buttons.button("Set max depth", function() {state = SolverState_SetDepth; Text.reset_text_input();});
        Buttons.button("Solve", solve);

        Buttons.button("Slow", function() replay_speed = 10, 1);
        Buttons.button("Medium", function() replay_speed = 5);
        Buttons.button("Fast", function() replay_speed = 0);

        for (i in 0...solutions.length) {
            var skip: Int;
            if (i == 0) {
                skip = 1;
            } else {
                skip = 0;
            }
            Buttons.button('${solutions[i].length} steps',
                function() {
                    state = SolverState_Replay;
                    selected_replay = i; 
                    current_replay_step = 0;
                    next_move = true;
                    t = 0;
                    Main.game.restart();
                }, 
                skip);
        }
    }
}
