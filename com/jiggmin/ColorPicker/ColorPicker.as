// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// com.jiggmin.ColorPicker.ColorPicker = package_16.class_182

package com.jiggmin.ColorPicker
{
    import flash.events.MouseEvent;
    import flash.geom.ColorTransform;
    import flash.events.Event;
    import flash.geom.Point;

    public class ColorPicker extends Removable
    {

        public static const RIGHT:String = "right";
        public static const LEFT:String = "left";
        internal static var recentColors:Array = new Array(0x888888, 0x555555, 0x888888, 0x555555, 0x888888, 0x555555, 0x888888, 0x555555, 0x888888, 0x555555, 0x888888, 0x555555); // var_265

        public var direction:String = "right"; // var_419
        protected var color:int;
        private var popup:ColorPickerPopup;
        private var m:ColorPickerGraphic;

        public function ColorPicker()
        {
            this.m = new ColorPickerGraphic();
            addChild(this.m);
            this.setColor(0xFF);
            mouseChildren = false;
            addEventListener(MouseEvent.CLICK, this.clickHandler, false, 0, true);
        }

        public function getColor():int
        {
            return this.color;
        }

        // _loc2 = ct
        public function setColor(c:* = null)
        {
            c = c is Number ? c : this.popup.getColor();
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
            (this.popup != null && !this.popup.isRemoved() ? this.closePopup() : this.openPopup());
        }

        private function openPopup()
        {
            this.closePopup();
            var origin:Point = this.localToGlobal(new Point(0, 0));
            this.popup = new ColorPickerPopup(this.color);
            this.popup.x = this.direction == RIGHT ? origin.x + width + 5 : origin.x - this.popup.width - 5;
            this.popup.addEventListener(Event.CHANGE, this.setColor, false, 0, true);
            this.popup.addEventListener(Removable.REMOVE, this.closePopup, false, 0, true);
            stage.addChild(this.popup);
            this.popup.init();
            this.popup.addExclusion(this);
            this.popup.y = origin.y;
            if (this.popup.y > Main.clientHeight - this.popup.height) {
                this.popup.y = Main.clientHeight - this.popup.height;
            }
            this.popup.x = Math.round(this.popup.x);
            this.popup.y = Math.round(this.popup.y);
            dispatchEvent(new Event(Event.OPEN));
        }

        public function closePopup(e:* = null)
        {
            if (this.popup != null) {
                this.setColor(this.popup.getColor());
                this.popup.removeEventListener(Event.CHANGE, this.setColor);
                this.popup.removeEventListener(Removable.REMOVE, this.closePopup);
                this.popup.safeRemove();
                this.popup = null;
                if (recentColors.indexOf(this.color) == -1) {
                    recentColors.unshift(this.color);
                    recentColors.pop();
                }
                dispatchEvent(new Event(Event.CLOSE));
            }
        }

        override public function remove()
        {
            removeEventListener(MouseEvent.CLICK, this.clickHandler);
            this.closePopup();
            super.remove();
        }


    }
}
