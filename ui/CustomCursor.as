// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// ui.class_8 = ui.CustomCursor

package ui
{
    import com.jiggmin.ColorPicker.CursorEyedropper;
    import com.jiggmin.data.Memory;
    import levelEditor.LevelEditor;
    import flash.display.DisplayObject;
    import flash.display.Stage;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.ui.Keyboard;
    import flash.ui.Mouse;
    import flash.utils.getDefinitionByName;
    import flash.utils.getQualifiedClassName;
    import package_20.Brush;
    import package_20.class_275;
    import package_20.ObjectDeleter;
    import package_20.TextTool;
    import flash.events.TouchEvent;
    import flash.ui.MouseCursor;

    public class CustomCursor extends Removable 
    {

        public static var stageRef:Stage;
        public static var instance:CustomCursor;

        private var active:Boolean = false; // var_71
        private var me:MouseEvent;
        private var mouseDown:Boolean; // var_487
        private var mouseHidden:Boolean = false; // var_371
        public var var_411:Boolean = true;

        public function CustomCursor()
        {
            mouseEnabled = false;
            mouseChildren = false;
            x = stageRef.mouseX;
            y = stageRef.mouseY;
        }

        // method_28 = change
        public static function change(c:CustomCursor)
        {
            unsetInstance();
            instance = c;
            stageRef.addChild(c);
            if (!c.isActive()) {
                c.init();
            }
        }

        // method_112 = unsetInstance
        public static function unsetInstance()
        {
            if (instance != null) {
                if (instance.var_411 == true) {
                    instance.remove();
                } else {
                    instance.pause();
                }
                instance = null;
            }
        }

        public static function pause()
        {
            if (instance != null) {
                instance.pause();
            }
        }

        public static function init()
        {
            if (instance != null) {
                instance.init();
            }
        }


        public function init()
        {
            this.active = true;
            visible = true;
            if (this.mouseHidden) {
                this.hideMouse();
            }
            stageRef.addEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveHandler, false, 0, true);
            stageRef.addEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler, true, 0, true);
            stageRef.addEventListener(MouseEvent.MOUSE_UP, this.mouseUpHandler, false, 0, true);
            stageRef.addEventListener(MouseEvent.MOUSE_OVER, this.mouseFocusHandler, false, 0, true);
            stageRef.addEventListener(MouseEvent.MOUSE_OUT, this.mouseFocusHandler, false, 0, true);
            stageRef.addEventListener(TouchEvent.TOUCH_MOVE, this.touchHandler);
            stageRef.addEventListener(TouchEvent.TOUCH_BEGIN, this.touchHandler);
            stageRef.addEventListener(TouchEvent.TOUCH_END, this.touchHandler);
            stageRef.addEventListener(TouchEvent.TOUCH_ROLL_OVER, this.touchHandler);
            stageRef.addEventListener(TouchEvent.TOUCH_ROLL_OUT, this.touchHandler);
            stageRef.addEventListener(KeyboardEvent.KEY_DOWN, this.keyDownHandler);
            stageRef.addEventListener(KeyboardEvent.KEY_UP, this.keyUpHandler);
        }

        private function touchHandler(e:TouchEvent)
        {
            var evStr:String = null;
            if (e.type == TouchEvent.TOUCH_MOVE) { // mouseMove
                evStr = MouseEvent.MOUSE_MOVE;
            } else if (e.type == TouchEvent.TOUCH_BEGIN) { // mouseDown
                evStr = MouseEvent.MOUSE_DOWN;
            } else if (e.type == TouchEvent.TOUCH_END) { // mouseUp
                evStr = MouseEvent.MOUSE_UP;
            } else if (e.type == TouchEvent.TOUCH_ROLL_OVER) { // mouseOver
                evStr = MouseEvent.MOUSE_OVER;
            } else if (e.type == TouchEvent.TOUCH_ROLL_OUT) { // mouseOut
                evStr = MouseEvent.MOUSE_OUT;
            }
            if (evStr != null) {
                dispatchEvent(new MouseEvent(evStr));
            }
        }

        public function pause()
        {
            this.active = false;
            visible = false;
            if (this.mouseHidden) {
                this.showMouse();
            }
            stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveHandler);
            stageRef.removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler, true);
            stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.mouseUpHandler);
            stageRef.removeEventListener(MouseEvent.MOUSE_OVER, this.mouseFocusHandler);
            stageRef.removeEventListener(MouseEvent.MOUSE_OUT, this.mouseFocusHandler);
            stageRef.removeEventListener(TouchEvent.TOUCH_MOVE, this.touchHandler);
            stageRef.removeEventListener(TouchEvent.TOUCH_BEGIN, this.touchHandler);
            stageRef.removeEventListener(TouchEvent.TOUCH_END, this.touchHandler);
            stageRef.removeEventListener(TouchEvent.TOUCH_ROLL_OVER, this.touchHandler);
            stageRef.removeEventListener(TouchEvent.TOUCH_ROLL_OUT, this.touchHandler);
            stageRef.removeEventListener(KeyboardEvent.KEY_DOWN, this.keyDownHandler);
            stageRef.removeEventListener(KeyboardEvent.KEY_UP, this.keyUpHandler);
        }

        // method_23 = isActive
        public function isActive():Boolean
        {
            return this.active;
        }

        // method_92 = getMouse
        public function getMouse():MouseEvent
        {
            return this.me;
        }

        // method_131 = isMouseDown
        public function isMouseDown():Boolean
        {
            return this.mouseDown;
        }

        // method_332 = hideMouse
        protected function hideMouse()
        {
            this.mouseHidden = true;
            Mouse.hide();
        }

        // method_843 = showMouse
        protected function showMouse()
        {
            this.mouseHidden = false;
            Mouse.show();
            Mouse.cursor = MouseCursor.ARROW;
            Mouse.cursor = MouseCursor.AUTO;
        }

        protected function mouseMoveHandler(e:MouseEvent)
        {
            this.me = e;
            this.x = e.stageX;
            this.y = e.stageY;
        }

        protected function mouseDownHandler(e:MouseEvent)
        {
            this.me = e;
            this.mouseDown = true;
        }

        protected function mouseUpHandler(e:MouseEvent)
        {
            this.me = e;
            this.mouseDown = false;
        }

        public function keyDownHandler(e:KeyboardEvent)
        {
            if (LevelEditor.editor == null || instance == null || instance is TextTool || instance is Brush || instance is CursorEyedropper) {
                return;
            }
            if ((e.keyCode == Keyboard.COMMAND || e.keyCode == Keyboard.CONTROL) && !(instance is ObjectDeleter)) {
                Memory.memory.leCursorTempInstanceType = getQualifiedClassName(instance);
                Memory.memory.leCursorTempInstanceID = instance.getID();
                change(new ObjectDeleter());
            }
        }

        public function keyUpHandler(e:KeyboardEvent)
        {
            if (LevelEditor.editor == null || instance == null || instance is TextTool || instance is Brush || instance is CursorEyedropper) {
                return;
            }
            if (Memory.memory.leCursorTempInstanceType != null && Memory.memory.leCursorTempInstanceType.indexOf('ObjectDeleter') == -1) {
                var tempItem = getDefinitionByName(Memory.memory.leCursorTempInstanceType) as Class;
                change(new tempItem(Memory.memory.leCursorTempInstanceID));
                Memory.memory.leCursorTempInstanceType = null;
                Memory.memory.leCursorTempInstanceID = null;
            }
        }

        // method_269 = mouseFocusHandler
        protected function mouseFocusHandler(e:MouseEvent)
        {
            this.me = e;
        }

        // consolidated into mouseFocusHandler
        /*protected function method_378(e:MouseEvent)
        {
            this.me = e;
        }*/

        // method_63 = applyCursorGraphic
        protected function applyCursorGraphic(e:DisplayObject)
        {
            e.x = -(e.width / 2);
            e.y = -(e.height / 2);
            addChild(e);
        }

        override public function remove()
        {
            this.pause();
            CustomCursor.instance = null;
            this.me = null;
            super.remove();
        }


    }
}//package ui

