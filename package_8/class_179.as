// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_8.class_179

package package_8
{
    import flash.display.DisplayObjectContainer;
    import flash.display.DisplayObject;
    import flash.geom.Point;

    public class class_179 extends class_125 
    {

        private var var_128:Object;
        private var var_567:Number;
        private var var_608:Number;
        private var holder:DisplayObjectContainer;

        public function class_179(_arg_1:int, _arg_2:int, _arg_3:DisplayObject, _arg_4:DisplayObjectContainer, _arg_5:Object, _arg_6:Number=0, _arg_7:Number=0)
        {
            super(_arg_1, _arg_2, _arg_3);
            this.var_128 = _arg_5;
            this.holder = _arg_4;
            this.var_567 = _arg_6;
            this.var_608 = _arg_7;
        }

        override protected function createParticle(_arg_1:Number, _arg_2:Number):DisplayObject
        {
            if (!target.parent) {
                return null;
            }
            this.var_128.minX = _arg_1 + this.var_128.minOffsetX;
            this.var_128.maxX = _arg_1 + this.var_128.maxOffsetX;
            this.var_128.minY = _arg_2 + this.var_128.minOffsetY;
            this.var_128.maxY = _arg_2 + this.var_128.maxOffsetY;
            var _local_3:class_240 = new class_240(this.var_128);
            this.holder.addChild(_local_3);
            return _local_3;
        }

        override protected function makeX():Number
        {
            return this.method_470().x;
        }

        override protected function makeY():Number
        {
            return this.method_470().y;
        }

        // _loc1 = point
        private function method_470():Object
        {
            if (!this.holder || !target || !target.parent) {
                return (new Point(0, 0));
            }
            var point:Point = new Point(target.x - this.var_567, target.y - this.var_608);
            point = target.parent.localToGlobal(point);
            return this.holder.globalToLocal(point);
        }


    }
}//package package_8

