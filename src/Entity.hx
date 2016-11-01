import haxegon.*;
import haxegon.MathUtils.IntVector2;
import haxe.ds.ObjectMap;


enum DoorColor {
	DoorColor_White;
	DoorColor_Black;
}


@:publicFields
class Entity {
	static var entities = new ObjectMap<Dynamic, Array<Dynamic>>();

	static function get(type: Dynamic): Array<Dynamic> {
		if (!entities.exists(type)) {
			entities.set(type, new Array<Dynamic>());
		}
		return entities.get(type);
	}

	static var id_max = 0;
	var id = 0;

	function new() {
		var type = Type.getClass(this);
		if (!entities.exists(type)) {
			entities.set(type, new Array<Dynamic>());
		}
		entities.get(type).push(this);

		id = id_max;
		id_max++;
	}
}

class Player extends Entity {
	var x = 0;
	var y = 0;
	var history = new Array<IntVector2>();
	var dx = 0;
	var dy = 0;
}

class Box extends Entity {
	var x = 0;
	var y = 0;
	var history = new Array<IntVector2>();
	var dx = 0;
	var dy = 0;
}

class Objective extends Entity {
	var x = 0;
	var y = 0;
}

class Door extends Entity {
	var x = 0;
	var y = 0;
	var color: DoorColor;
	var closed = true;
	var history = new Array<IntVector2>();
}

class DoorButton extends Entity {
	var x = 0;
	var y = 0;
	var color = DoorColor_White;
	var pressed = false;
	var history = new Array<IntVector2>();
}

class Entrance extends Entity {
	var x = 0;
	var y = 0;
	var completed = false;
}

class DoorKey extends Entity {
	var x = 0;
	var y = 0;
	var carried = false;
	var history = new Array<IntVector2>();
	var carried_history = new Array<Bool>();
}

class DoorLocked extends Entity {
	var x = 0;
	var y = 0;
	var locked = true;
	var history = new Array<IntVector2>();
	var locked_history = new Array<Bool>();
}
