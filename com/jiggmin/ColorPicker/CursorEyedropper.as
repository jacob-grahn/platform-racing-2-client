// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// com.jiggmin.ColorPicker.CursorEyedropper = package_16.class_279

package com.jiggmin.ColorPicker
{
    import ui.CustomCursor;
    import flash.display.BitmapData;
    import flash.utils.Timer;
    import flash.events.TimerEvent;
    import flash.display.DisplayObject;
    import flash.events.MouseEvent;
    import flash.ui.Mouse;
    import flash.events.Event;

    public class CursorEyedropper extends CustomCursor
    {

        public var color:int;
        private var var_352:Array = new Array();
        private var var_331:BitmapData;
        private var var_266:Timer;
        private var var_248:Timer;

        public function CursorEyedropper()
        {
            visible = false;
            addChild(new CursorEyedropperGraphic());
            this.var_331 = new BitmapData(stageRef.stageWidth, stageRef.stageHeight);
            this.var_266 = new Timer(100, 0);
            this.var_248 = new Timer(1000, 0);
        }

        override public function init()
        {
            super.init();
            visible = false;
            this.var_266.start();
            this.var_248.start();
            this.var_266.addEventListener(TimerEvent.TIMER, this.method_379, false, 0, true);
            this.var_248.addEventListener(TimerEvent.TIMER, this.method_279, false, 0, true);
        }

        override public function pause()
        {
            super.pause();
            this.var_266.stop();
            this.var_248.stop();
            this.var_266.removeEventListener(TimerEvent.TIMER, this.method_379);
            this.var_248.removeEventListener(TimerEvent.TIMER, this.method_279);
        }

        public function method_101(_arg_1:DisplayObject)
        {
            this.var_352.push(_arg_1);
        }

        private function method_379(_arg_1:TimerEvent)
        {
            var _local_3:DisplayObject;
            var _local_2:Boolean = true;
            var _local_4:MouseEvent = getMouse();
            if (_local_4 != null) {
                _local_3 = DisplayObject(_local_4.target);
            }
            if (_local_3 != null) {
                while (_local_3.parent != null) {
                    if (this.method_612(_local_3)) {
                        _local_2 = false;
                        break;
                    }
                    _local_3 = _local_3.parent;
                }
                if (_local_2) {
                    if (!visible) {
                        visible = true;
                        Mouse.hide();
                        this.method_167();
                    }
                    this.method_418();
                    dispatchEvent(new Event(Event.CHANGE));
                } else {
                    if (visible) {
                        visible = false;
                        Mouse.show();
                        this.color = -1;
                        dispatchEvent(new Event(Event.CHANGE));
                    }
                }
            }
        }

        override protected function mouseDownHandler(e:MouseEvent)
        {
            if (visible) {
                e.stopImmediatePropagation();
                this.method_167();
                this.method_418();
                dispatchEvent(new Event(Event.COMPLETE));
            }
            super.mouseDownHandler(_arg_1);
        }

        private function method_279(_arg_1:TimerEvent)
        {
            this.method_167();
        }

        private function method_167()
        {
            if (visible) {
                visible = false;
                this.var_331.draw(stageRef);
                visible = true;
            }
        }

        private function method_612(_arg_1:DisplayObject):Boolean
        {
            var _local_2:int = this.var_352.indexOf(_arg_1);
            if (_local_2 == -1) {
                return (false);
            }
            return (true);
        }

        private function method_418()
        {
            var _local_1:MouseEvent = getMouse();
            var _local_2:int = Math.floor(_local_1.stageX);
            var _local_3:int = Math.floor(_local_1.stageY);
            this.color = this.var_331.getPixel(_local_2, _local_3);
        }

        override public function remove()
        {
            super.remove();
            this.var_331.dispose();
            this.var_331 = null;
            this.var_266 = null;
            this.var_248 = null;
            this.var_352 = null;
            Mouse.show();
        }


    }
}//package package_16
