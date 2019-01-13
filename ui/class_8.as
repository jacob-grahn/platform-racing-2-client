// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//ui.class_8

package ui
{
    import flash.display.Stage;
    import flash.events.MouseEvent;
    import flash.ui.Mouse;
    import flash.display.DisplayObject;

    public class class_8 extends class_7 
    {

        public static var stageRef:Stage;
        public static var instance:class_8;

        private var var_71:Boolean = false;
        private var me:MouseEvent;
        private var var_487:Boolean;
        private var var_371:Boolean = false;
        public var var_411:Boolean = true;

        public function class_8()
        {
            mouseEnabled = false;
            mouseChildren = false;
            x = stageRef.mouseX;
            y = stageRef.mouseY;
        }

        public static function method_28(_arg_1:class_8)
        {
            method_112();
            instance = _arg_1;
            stageRef.addChild(_arg_1);
            if (!_arg_1.method_23()) {
                _arg_1.init();
            }
        }

        public static function method_112()
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
            this.var_71 = true;
            visible = true;
            if (this.var_371) {
                Mouse.hide();
            }
            stageRef.addEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveHandler, false, 0, true);
            stageRef.addEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler, true, 0, true);
            stageRef.addEventListener(MouseEvent.MOUSE_UP, this.mouseUpHandler, false, 0, true);
            stageRef.addEventListener(MouseEvent.MOUSE_OVER, this.method_269, false, 0, true);
            stageRef.addEventListener(MouseEvent.MOUSE_OUT, this.method_378, false, 0, true);
        }

        public function pause()
        {
            this.var_71 = false;
            visible = false;
            if (this.var_371) {
                Mouse.show();
            }
            stageRef.removeEventListener(MouseEvent.MOUSE_MOVE, this.mouseMoveHandler);
            stageRef.removeEventListener(MouseEvent.MOUSE_DOWN, this.mouseDownHandler, true);
            stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.mouseUpHandler);
            stageRef.removeEventListener(MouseEvent.MOUSE_OVER, this.method_269);
            stageRef.removeEventListener(MouseEvent.MOUSE_OUT, this.method_378);
        }

        public function method_23():Boolean
        {
            return (this.var_71);
        }

        public function method_92():MouseEvent
        {
            return (this.me);
        }

        public function method_131():Boolean
        {
            return (this.var_487);
        }

        protected function method_332()
        {
            this.var_371 = true;
            Mouse.hide();
        }

        protected function method_843()
        {
            this.var_371 = false;
            Mouse.show();
        }

        protected function mouseMoveHandler(_arg_1:MouseEvent)
        {
            this.me = _arg_1;
            this.x = _arg_1.stageX;
            this.y = _arg_1.stageY;
        }

        protected function mouseDownHandler(_arg_1:MouseEvent)
        {
            this.me = _arg_1;
            this.var_487 = true;
        }

        protected function mouseUpHandler(_arg_1:MouseEvent)
        {
            this.me = _arg_1;
            this.var_487 = false;
        }

        protected function method_269(_arg_1:MouseEvent)
        {
            this.me = _arg_1;
        }

        protected function method_378(_arg_1:MouseEvent)
        {
            this.me = _arg_1;
        }

        protected function method_63(_arg_1:DisplayObject)
        {
            _arg_1.x = -(_arg_1.width / 2);
            _arg_1.y = -(_arg_1.height / 2);
            addChild(_arg_1);
        }

        override public function remove()
        {
            this.pause();
            class_8.instance = null;
            this.me = null;
            super.remove();
        }


    }
}//package ui

