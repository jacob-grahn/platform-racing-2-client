// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_16.ColorPicker = class_182

package package_16
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
        private var package_4:class_241;
        private var m:ColorPickerGraphic;

        public function ColorPicker()
        {
            this.m = new ColorPickerGraphic();
            addChild(this.m);
            this.setColor(0xFF);
            mouseChildren = false;
            addEventListener(MouseEvent.CLICK, this.clickHandler, false, 0, true);
        }

        public function method_12():int
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
            if (this.package_4 != null && !this.package_4.method_20()) {
                this.method_71();
            } else {
                this.method_740();
            }
        }

        private function method_290(e:Event)
        {
            this.setColor(this.package_4.method_12());
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
            this.package_4 = new class_241(this.color);
            if (this.var_419 == RIGHT) {
                this.package_4.x = _local_2.x + width + 5;
            } else {
                this.package_4.x = _local_2.x - this.package_4.width - 5;
            }
            this.package_4.addEventListener(Event.CHANGE, this.method_290, false, 0, true);
            this.package_4.addEventListener(class_7.REMOVE, this.method_242, false, 0, true);
            stage.addChild(this.package_4);
            this.package_4.init();
            this.package_4.method_101(this);
            this.package_4.y = _local_2.y;
            if (this.package_4.y > Main.clientHeight - this.package_4.height) {
                this.package_4.y = Main.clientHeight - this.package_4.height;
            }
            this.package_4.x = Math.round(this.package_4.x);
            this.package_4.y = Math.round(this.package_4.y);
            dispatchEvent(new Event(Event.OPEN));
        }

        public function method_71()
        {
            if (this.package_4 != null) {
                this.setColor(this.package_4.method_12());
                this.package_4.removeEventListener(Event.CHANGE, this.method_290);
                this.package_4.removeEventListener(class_7.REMOVE, this.method_242);
                this.package_4.method_136();
                this.package_4 = null;
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
