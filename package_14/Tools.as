// package_14.Tools = package_14.class_176

package package_14
{
    import flash.display.Stage;
    import com.jiggmin.ColorPicker.ColorPicker;
    import package_20.Brush;
    import package_20.Eraser;
    import package_19.SizePicker;
    import package_19.Landscape;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import ui.class_8;

    public class Tools extends SideBar
    {

        private static var color:Number = 0;
        private static var size:Number = 4;

        private var stageRef:Stage = Main.stage;
        private var colorPicker:ColorPicker = new ColorPicker(); // var_12
        private var brush:Brush = new Brush(); // var_114
        private var eraser:Eraser = new Eraser(); // var_203
        private var sizePicker:SizePicker = new SizePicker(this, Tools.size); // var_571
        private var brushButton:BrushButtonGraphic = new BrushButtonGraphic(); // var_351
        private var eraserButton:EraserButtonGraphic = new EraserButtonGraphic(); // var_354
        private var var_71:Boolean = false;

        public function Tools()
        {
            addItem(new Landscape(), "Landscape Mode", "Switch to the landscape toolbar.");
            addItem(this.brushButton, "Brush", "Draw things, yay!");
            addItem(this.eraserButton, "Eraser", "Erase the things you have drawn, yay!");
            addItem(this.sizePicker, "Size Picker", "Change the size of the brush and eraser.");
            addItem(this.colorPicker, "Color Picker", "Choose your color with wisdom.");
            this.colorPicker.width = this.colorPicker.height = 30;
            this.colorPicker.var_419 = ColorPicker.LEFT;
            this.colorPicker.addEventListener(Event.CLOSE, this.chooseColor);
            this.brushButton.addEventListener(MouseEvent.MOUSE_DOWN, this.onBrushDown);
            this.eraserButton.addEventListener(MouseEvent.MOUSE_DOWN, this.onEraserDown);
            this.brush.setSize(Tools.size);
            this.eraser.setSize(Tools.size);
            this.colorPicker.setColor(Tools.color);
            this.brush.setColor(Tools.color);
        }

        public function setSize(s:Number)
        {
            Tools.size = s;
            this.eraser.setSize(Tools.size);
            this.brush.setSize(Tools.size);
        }

        public function setZoom(z:Number)
        {
            this.eraser.setZoom(z);
            this.brush.setZoom(z);
        }

        // method_249 = onBrushDown
        private function onBrushDown(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            class_8.method_28(this.brush);
        }

        // method_424 = onEraserDown
        private function onEraserDown(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            class_8.method_28(this.eraser);
        }

        // method_280 = chooseColor
        private function chooseColor(e:Event)
        {
            Tools.color = this.colorPicker.method_12();
            this.brush.setColor(Tools.color);
            this.stageRef.focus = this.stageRef;
        }

        override public function init()
        {
            class_8.init();
            class_8.method_28(this.brush);
            this.var_71 = true;
        }

        override public function exit()
        {
            this.colorPicker.method_71();
            class_8.pause();
            super.exit();
            this.var_71 = false;
        }

        override public function remove()
        {
            this.exit();
            class_8.method_112();
            this.colorPicker.removeEventListener(Event.CLOSE, this.chooseColor);
            this.colorPicker.remove();
            this.colorPicker = null;
            this.brushButton.removeEventListener(MouseEvent.MOUSE_DOWN, this.onBrushDown);
            this.eraserButton.removeEventListener(MouseEvent.MOUSE_DOWN, this.onEraserDown);
            this.brush.remove();
            this.brush = null;
            this.eraser.remove();
            this.eraser = null;
            super.remove();
        }


    }
}
