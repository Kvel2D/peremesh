package haxegon;

@:publicFields
class Buttons {
	static var x: Float = 0;
	static var y: Float = 0;

	static function button(text: String, button_function: Void->Void, skips: Int = 0) {
        var text_width = Text.width(text);
        var text_height = Text.height();
        var button_width = text_width * 1.1;
        var button_height = text_height * 1.25;
        y += (button_height + 2) * (skips + 1);

        if (MathUtils.point_box_intersect(Mouse.x, Mouse.y, x, y, button_width, button_height)) {
            Gfx.fill_box(x, y, button_width, button_height, Col.PINK);
            if (Mouse.left_click()) {
                button_function();
            }
        } else {
            Gfx.fill_box(x, y, button_width, button_height, Col.GRAY);
        }
        Text.display(x, y, text);
    }


	function new(){}
}