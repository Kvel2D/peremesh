@:publicFields
class Levels {

	static var tutorial_tiles = [
	Tiles.Left,
	Tiles.Right,
	Tiles.Up,
	Tiles.Down,
	Tiles.T,
	Tiles.R,
	Tiles.Z,
	Tiles.E,
	Tiles.Esc,
	];

	static var world = [
	"################################################################################",
	"################################################################################",
	"################################################################################",
	"################################################################################",
	"################################################################################",
	"################################################################################",
	"################################################################################",
	"################################################################################",
	"##########################..........############################################",
	"##########################..........############################################",
	"##########################...e......############################################",
	"##########################...I......############################################",
	"################################....############################################",
	"#####################...........#......10...............########################",
	"#####################............#.....10.......e.......########################",
	"#####################.......e.......#####.......I.......########################",
	"#####################.......I......#######....###.......########################",
	"#####################..####################..e.....####.########################",
	"#####################.d...##################.I....b.....########################",
	"#######################q#33###########################33########################",
	"##########################22###########################22#######################",
	"###########################..###########################..######################",
	"############################..###########################..#####################",
	"#############################..###########################.10###################",
	"#######......................#.........####################10.##################",
	"######..........3.............#........######################..#################",
	"#...............e..10...e.........#....#######################..################",
	"#.01............I..10...I..........#..e########################..###############",
	"#........21#########################..I#########################..##############",
	"#.p.......########################...############################..#############",
	"#################################...##########...e...#############..############",
	"################################...##########....I....#############..###########",
	"###############################...#....####....#####.......10......#...........#",
	"##############################...#...e.###...e.......e.....10...e...#.......e..#",
	"#############################...b....I.###...I.......I.....10...I...........I..#",
	"############################...########################################..#######",
	"###########################...#######################################...########",
	"##########################...#######################################...#########",
	"#########################...#######################################...##########",
	"########################33.########################################33###########",
	"########################22########################################22############",
	"#######################..#####################........#######......#############",
	"#####################...#.......e..##########..........######.....#.############",
	"#####################e...b......I..#########............#####....b...###########",
	"#####################I#####...#############..............##########...##########",
	"############################.......########..............########..#..........##",
	"#############################..e...########..............########...#.........##",
	"##############################.I...########..............#######.....#.....e..##",
	"#################################...#######..............#######...........I..##",
	"##################################...######..............######........#########",
	"###################################...#####..............######.......#.......##",
	"####################################...###................####.......#........##",
	"#####################################...#..................###......#.........##",
	"######################################.10..................10..e...#......e...##",
	"#######################################10..................10..I..#.......I...##",
	"#########################################..................#####################",
	"##########################################.......##.......######################",
	"###########################################.....####.....#######################",
	"############################################...######...########################",
	"################################################################################",
	];
	

/*
Go through a wall

This level is about teleporting two parts of the level with the intention of doing something
you can't do with the level as it is(go through the wall). This is a temporary alteration in a sense
that it will disappear if you cancel the teleport and that you finish the level with teleports on.
*/
static var wall = [
"####################",
"#.............######",
"#.4.5.6.8.....######",
"#.........#...######",
"#.........#...######",
"#..p......#.o.######",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

/*
Leave teleport at the top, push two boxes at the bottom and teleport back

This level is about a teleportation of player positions through time. Also, it requires
you to be aware of how the current 3x3 segment of the level will be useful to you when teleported to a remote location.
*/
static var elevator = [
"####################",
"####################",
"#######p..##########",
"#####o.b..##########",
"#######b..##########",
"#######b..##########",
"#######b..##########",
"#######b..##########",
"#######b..##########",
"#######b..##########",
"#######b..##########",
"#######b..##########",
"#####..b..##########",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

static var cute = [
"####################",
"####################",
"####################",
"####################",
"######....##....o###",
"######....##.#######",
"######pb.....#######",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

/*
Stand on button and teleport it to beneath the top box

The main idea here is that you teleport a button under the box(which also removes the block from below the button),
or that the final state of the level after teleportation can be different than just a swap of two level segments,
if there are objects like a falling box or a button about to be pushed, that will change the state further.

Player doesn't know that buttons can fall, but that is not relevant yet.
*/
static var air_button = [
"####################",
"####################",
"####################",
"####################",
"#####........#######",
"#####........#######",
"#####...b....#######",
"#####...#....#######",
"#####........#######",
"#####....pb.qdd.o###",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

/*
Drop box to the left
leave teleport at the top on the box
teleport at the bottom

Again you have to understand that you can leave a teleport to come back
Here you also come back with a "stair", which is formed from a box and a line of ground.
*/
static var going_high = [
"####################",
"#######o.....#######",
"########.....#######",
"########..p..#######",
"########..b..#######",
"########.###.#######",
"########.....#######",
"########.....#######",
"########.....#######",
"########.....#######",
"########.....#######",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

/*
Leaven teleport at the start
put a teleport on the bottom
push box off and into teleport
pick up teleport
teleport while standing on the box between two blocks

This can be reduced to the fact that you the only thing you can change about the level is the box,
and that the box itself won't lead to the direct path, but will let you create that path.
*/
static var broken_bridge = [
"####################",
"####################",
"####################",
"####################",
"######.......#######",
"######p..b..o#######",
"########.#.#########",
"######.......#######",
"######.......#######",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

/*
Put teleport on top 
jump right and teleport where you fall
stack two boxes to the side
go down and teleport yourself and the box back up
move box to right, stand to the right of it and teleport up, creating a stair

Here you "reuse" a teleport hanging in space multiple times as you construct 
a segment that will let you get up to to the objective
*/
static var air_stair = [
"####################",
"####################",
"##########....o#####",
"##########....######",
"##########.....#####",
"##########..p..#####",
"##########..b..#####",
"##########..b..#####",
"##########..b..#####",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

/*
Teleport box to the left of the button
use box to teleport button next to the door

A little too hard for starter levels
*/
static var button_box = [
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"###......###########",
"###.p....###########",
"###.q..b.ddo########",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

/*
Leave teleport, so that box is in bottom left corner,
put teleport on hill to drop box

Again, teleports through time, now you have to do it on a box before you push it
which takes a bit extra oompf. Also, first time you drop a thing by teleporting it
*/
static var button_hill = [
"####################",
"####################",
"####################",
"####################",
"####################",
"###.........########",
"###.........########",
"###.........########",
"###.........########",
"###.........########",
"###.##......########",
"###.##.p..b.ddo#####",
"###.################",
"###q################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

/*
Swap button and box to push box on button
*/
static var swap = [
"####################",
"####################",
"####################",
"####################",
"#####........#######",
"#####...........####",
"#####.........q.####",
"#####........#######",
"#####.......########",
"#####....pb..dd..o##",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

/*
Similar to easy version, but differs in that once you get the box in, you realize that there's not enough
space to use teleports to open the objective. So you have to take a completely different approach.

Requires a bunch of advanced stuff like: 
pushing a box into an activated portal and cancelling it
teleporting a box to a falling position
strategically cancelling teleports
*/
static var through_doors = [
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"##########o#...#####",
"##############..####",
"########.....##...##",
"########..p..###..##",
"########..b..dd...##",
"#########q##########",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

/*
Pretty damn hard level
*/
static var button_behind_wall = [
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"##...#..b...########",
"##...#..b...########",
"##.q.#.pb...ddo#####",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

/*
Two confusing mechanics here that must be introduced prior to this level:
1. doors can fall
2. doors can press buttons
*/
static var self_help = [
"####################",
"####################",
"#######.....########",
"#######.....########",
"##odDdD..pb.########",
"####################",
"########...#########",
"########...#########",
"########...#########",
"########Q#q#########",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

/*
solution involves putting 3 boxes in a row
an easier version would have objective be one tile lower
30 turns
*/
static var too_high = [
"####################",
"####################",
"####################",
"####################",
"###...........######",
"###..........o######",
"###....b....########",
"###....#....########",
"###.........########",
"###.b....pb.########",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

/*
Have to drop box and separate it from the wall, then leave a teleport up top(from a box)
then teleport from the bottom together with button below and box in door on the right
Door is not moved, so it might be possible to add something to that too.

The door pushing mechanic can be gleamed from the default state of the level

Passage to the right of the door is a joke about you not being able to reach the objective through it
*/
static var pusher_door = [
"####################",
"######...o...#######",
"######.#####.#######",
"#......#####.#######",
"#..b...#####.#######",
"#p.b...#####.#######",
"######.....#.#######",
"######....d..#######",
"#########q##########",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];


/*
just one higher than normal version. Player needs to teleport the completed elevator one cell to the left
Like it
The smallest amount of doors possible
*/
static var doorevator = [
"####################",
"###............#####",
"###............#####",
"###............#####",
"###............#####",
"###o...........#####",
"#####..........#####",
"###............#####",
"###............#####",
"###....p.......#####",
"###....b.dddd..#####",
"#####.q#############",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];


//------------------------------
// KEY LEVELS
//------------------------------

static var hidden_key = [
"####################",
"####################",
"####################",
"####################",
"###..........#######",
"###..........#######",
"###..........#######",
"###..........#######",
"###...7......#######",
"###.......p..KK.o###",
"###.....############",
"##k#################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

static var door_to_key = [
"####################",
"####################",
"####################",
"####################",
"##...........#######",
"##...........#######",
"##...........#######",
"##...........#######",
"##...........#######",
"##.p....b....KK.o###",
"####################",
"#######k############",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

static var key_to_door = [
"####################",
"####################",
"####################",
"######.kp.KK....o###",
"######.#####d#######",
"######......d#######",
"######......d#######",
"######......D#######",
"######......D#######",
"######..b.b.D#######",
"#######q#Q##########",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
"####################",
];

static var ant_hole = [
"####################",
"####################",
"####################",
"#####.......########",
"#####.......########",
"#####...kk..########",
"#####...##..########",
"#####..p....########",
"#########.##########",
"#########.##########",
"#########.##########",
"#########K##########",
"#########K##########",
"#########.##########",
"#########..o########",
"####################",
"####################",
"####################",
"####################",
"####################",
];


static var level_entrances = [
"16_26" => wall,

"24_26" => elevator,
"37_33" => air_button,
"38_27" => cute,

"21_43" => going_high,
"31_46" => swap,
"32_42" => air_stair,

"28_15" => button_hill,
"29_10" => button_box,

"63_53" => hidden_key,
"74_53" => key_to_door,
"75_47" => door_to_key,

"64_33" => ant_hole,
"76_33" => too_high,

"45_17" => self_help,
"48_14" => doorevator,

"45_33" => pusher_door,
"53_33" => button_behind_wall,
"49_30" => through_doors,
];

static var level_names = [
"16_26" => "wall",

"24_26" => "elevator",
"37_33" => "air_button",
"38_27" => "cute",

"21_43" => "going_high",
"31_46" => "swap",
"32_42" => "air_stair",

"28_15" => "button_hill",
"29_10" => "button_box",

"63_53" => "hidden_key",
"74_53" => "key_to_door",
"75_47" => "door_to_key",

"64_33" => "ant_hole",
"76_33" => "too_high",

"45_17" => "self_help",
"48_14" => "doorevator",

"45_33" => "pusher_door",
"53_33" => "button_behind_wall",
"49_30" => "through_doors",
];

static var completed: Map<String, Bool> = [
"11_26" => false,
];

}