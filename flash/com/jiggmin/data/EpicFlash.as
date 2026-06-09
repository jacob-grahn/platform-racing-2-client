// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// data.EpicFlash = data.class_153

package com.jiggmin.data
{
    import flash.display.DisplayObject;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import flash.geom.ColorTransform;

    public class EpicFlash 
    {

        private var items:Vector.<DisplayObject> = new Vector.<DisplayObject>();
        private var intervalId:int;
        private var intervalDelay:int;
        private var active:Boolean = false;

        public function EpicFlash(delay:int=500)
        {
            this.intervalDelay = delay;
        }

        public function start()
        {
            clearInterval(this.intervalId);
            this.intervalId = setInterval(this.colorTick, this.intervalDelay);
            this.active = true;
        }

        public function stop()
        {
            clearInterval(this.intervalId);
            this.active = false;
        }

        public function setDelay(delay:int)
        {
            this.intervalDelay = delay;
            if (this.active) {
                this.start();
            }
        }

        public function isEmpty() : Boolean
        {
            if (this.items.length <= 0) {
                return true;
            }
            return false;
        }

        public function addItem(item:DisplayObject)
        {
            this.items.push(item);
        }

        private function colorTick()
        {
            var colorTransform:ColorTransform = new ColorTransform();
            colorTransform.color = Math.round(Math.random() * 0xFFFFFF);
            for each (var item:DisplayObject in this.items) {
                item.transform.colorTransform = colorTransform;
            }
        }

        public function remove()
        {
            this.items = null;
        }


    }
}
