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
    import flash.events.Event;

    public class CursorEyedropper extends CustomCursor
    {

        public var color:int;
        private var var_352:Array = new Array();
        /** Area where the custom cursor graphic can be shown. */
        private var cursorContainer:BitmapData; // var_331
        // private var var_266:Timer; // switched to ENTER_FRAME instead
        // private var var_248:Timer;

        public function CursorEyedropper()
        {
            visible = false;
            addChild(new CursorEyedropperGraphic());
            this.cursorContainer = new BitmapData(stageRef.stageWidth, stageRef.stageHeight);
        }

        override public function init()
        {
            super.init();
            visible = false;
            addEventListener(Event.ENTER_FRAME, this.maybeUpdate, false, 0, true);
        }

        override public function pause()
        {
            super.pause();
            removeEventListener(Event.ENTER_FRAME, this.maybeUpdate);
        }

        public function addExclusion(d:DisplayObject)
        {
            this.var_352.push(d);
        }

        private function maybeUpdate(e:Event)
        {
            var me:MouseEvent = getMouse();
            var targetObj:DisplayObject = me != null ? DisplayObject(me.target) : null;
            if (targetObj != null) {
                var useEyedropper:Boolean = true;
                while (targetObj.parent != null) {
                    if (this.isExcluded(targetObj)) {
                        useEyedropper = false;
                        break;
                    }
                    targetObj = targetObj.parent;
                }
                if (useEyedropper) {
                    if (!visible) {
                        visible = true;
                        hideMouse();
                        this.drawEyedropper();
                    }
                    this.updateColor();
                    dispatchEvent(new Event(Event.CHANGE));
                } else if (visible) {
                    visible = false;
                    showMouse();
                    this.color = -1;
                    dispatchEvent(new Event(Event.CHANGE));
                }
            }
        }

        override protected function mouseDownHandler(e:MouseEvent)
        {
            if (visible) {
                e.stopImmediatePropagation();
                this.drawEyedropper();
                this.updateColor();
                dispatchEvent(new Event(Event.COMPLETE));
            }
            super.mouseDownHandler(e);
        }

        private function drawEyedropper(e:TimerEvent = null)
        {
            if (visible) {
                visible = false;
                this.cursorContainer.draw(stageRef);
                visible = true;
            }
        }

        private function isExcluded(d:DisplayObject):Boolean
        {
            return this.var_352.indexOf(d) != -1;
        }

        private function updateColor()
        {
            var me:MouseEvent = getMouse();
            this.color = this.cursorContainer.getPixel(Math.floor(me.stageX), Math.floor(me.stageY));
        }

        override public function remove()
        {
            showMouse();
            super.remove();
            this.cursorContainer.dispose();
            this.cursorContainer = null;
            this.var_352 = null;
        }


    }
}//package package_16
