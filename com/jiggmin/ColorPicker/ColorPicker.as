// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// com.jiggmin.ColorPicker.ColorPicker = package_16.class_182

package com.jiggmin.ColorPicker
{
    import flash.events.MouseEvent;
    import flash.geom.ColorTransform;
    import flash.events.Event;
    import flash.geom.Point;

    public class ColorPicker extends class_7
    {

        public static const RIGHT:String = "right";
        public static const LEFT:String = "left";
        internal static var var_265:Array = new Array(0x888888, 0x555555, 0x888888, 0x555555, 0x888888, 0x555555, 0x888888, 0x555555, 0x888888, 0x555555, 0x888888, 0x555555);

        public var var_419:String = "right";
        protected var color:int;
        private var mPop:ColorPickerPopup;
        private var m:ColorPickerGraphic;

        public function ColorPicker()
        {
            this.m = new ColorPickerGraphic();
            addChild(this.m);
            this.setColor(0xFF);
            mouseChildren = false;
            addEventListener(MouseEvent.CLICK, this.clickHandler, false, 0, true);
        }

        // method_12 = getColor
        public function getColor():int
        {
            return this.color;
        }

        // _loc2 = ct
        public function setColor(c:int)
        {
            if (this.color != c) {
                this.color = c;
                var ct:ColorTransform = new ColorTransform();
                ct.color = this.color;
                this.m.colorMC.transform.colorTransform = ct;
                dispatchEvent(new Event(Event.CHANGE));
            }
        }

        private function clickHandler(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            if (this.mPop != null && !this.mPop.method_20()) {
                this.method_71();
            } else {
                this.method_740();
            }
        }

        private function method_290(e:Event)
        {
            this.setColor(this.mPop.getColor());
        }

        private function method_242(e:Event)
        {
            this.method_71();
        }

        private function method_740()
        {
            this.method_71();
            var _local_1:Point = new Point(0, 0);
            var _local_2:Point = this.localToGlobal(_local_1);
            this.mPop = new ColorPickerPopup(this.color);
            if (this.var_419 == RIGHT) {
                this.mPop.x = _local_2.x + width + 5;
            } else {
                this.mPop.x = _local_2.x - this.mPop.width - 5;
            }
            this.mPop.addEventListener(Event.CHANGE, this.method_290, false, 0, true);
            this.mPop.addEventListener(class_7.REMOVE, this.method_242, false, 0, true);
            stage.addChild(this.mPop);
            this.mPop.init();
            this.mPop.method_101(this);
            this.mPop.y = _local_2.y;
            if (this.mPop.y > Main.clientHeight - this.mPop.height) {
                this.mPop.y = Main.clientHeight - this.mPop.height;
            }
            this.mPop.x = Math.round(this.mPop.x);
            this.mPop.y = Math.round(this.mPop.y);
            dispatchEvent(new Event(Event.OPEN));
        }

        public function method_71()
        {
            if (this.mPop != null) {
                this.setColor(this.mPop.getColor());
                this.mPop.removeEventListener(Event.CHANGE, this.method_290);
                this.mPop.removeEventListener(class_7.REMOVE, this.method_242);
                this.mPop.method_136();
                this.mPop = null;
                if (var_265.indexOf(this.color) == -1) {
                    var_265.unshift(this.color);
                    var_265.pop();
                }
                dispatchEvent(new Event(Event.CLOSE));
            }
        }

        override public function remove()
        {
            removeEventListener(MouseEvent.CLICK, this.clickHandler);
            this.method_71();
            super.remove();
        }


    }
}
