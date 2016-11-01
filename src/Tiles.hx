
@:publicFields
class Tiles {
    static inline var tileset_width = 10;
    static inline function tilenum(x: Int, y: Int): Int {
        return y * tileset_width + x;
    }

    static inline var Empty = 9999;
    static inline var Ground = tilenum(0, 0);
    static inline var Player = tilenum(1, 0);
    static inline var Box = tilenum(2, 0);
    static inline var Teleport = tilenum(2, 1);
    static inline var Entrance = tilenum(1, 6);
    static inline var SpiralPurple = tilenum(0, 1);
    static inline var SpiralGray = tilenum(1, 1);
    static inline var Pedestal = tilenum(4, 2);    
    static inline var Key = tilenum(5, 2);    
    static inline var DoorLocked = tilenum(4, 3);    
    static inline var DoorUnlocked = tilenum(5, 3);    

    static inline var DoorWhiteClosed = tilenum(0, 2);
    static inline var DoorWhiteOpen = tilenum(1, 2);
    static inline var DoorBlackClosed = tilenum(2, 2);
    static inline var DoorBlackOpen = tilenum(3, 2);

    static inline var ButtonWhiteOff = tilenum(0, 3);
    static inline var ButtonWhiteOn = tilenum(1, 3);
    static inline var ButtonBlackOff = tilenum(2, 3);
    static inline var ButtonBlackOn = tilenum(3, 3);

    static inline var Left = tilenum(3, 0);
    static inline var Right = tilenum(4, 0);
    static inline var Up = tilenum(5, 0);
    static inline var Down = tilenum(6, 0);
    static inline var T = tilenum(3, 1);
    static inline var R = tilenum(4, 1);
    static inline var Z = tilenum(5, 1);
    static inline var E = tilenum(6, 2);    
    static inline var Esc = tilenum(6, 3);    
    static inline var Question = tilenum(6, 1);
}