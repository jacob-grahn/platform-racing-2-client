// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//data.class_153

package com.jiggmin.data
{
    import flash.display.DisplayObject;
    import flash.utils.clearInterval;
    import flash.utils.setInterval;
    import flash.geom.ColorTransform;

    public class class_153 
    {

        private var items:Vector.<DisplayObject> = new Vector.<DisplayObject>();
        private var var_416:int;
        private var var_444:int;
        private var active:Boolean = false; // var_71

        public function class_153(_arg_1:int=500)
        {
            this.var_444 = _arg_1;
        }

        public function start()
        {
            clearInterval(this.var_416);
            this.var_416 = setInterval(this.method_554, this.var_444);
            this.active = true;
        }

        public function stop()
        {
            clearInterval(this.var_416);
            this.active = false;
        }

        public function method_580(_arg_1:int)
        {
            this.var_444 = _arg_1;
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

        public function addItem(_arg_1:DisplayObject)
        {
            this.items.push(_arg_1);
        }

        private function method_554()
        {
            var _local_2:DisplayObject;
            var _local_1:ColorTransform = new ColorTransform();
            _local_1.color = Math.round(Math.random() * 0xFFFFFF);
            for each (_local_2 in this.items) {
                _local_2.transform.colorTransform = _local_1;
            }
        }

        public function remove()
        {
            this.items = null;
        }


    }
}//package com.jiggmin.data

