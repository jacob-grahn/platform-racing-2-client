// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//character.PositionedParticleEmitter

package character
{
    import flash.display.DisplayObjectContainer;
    import flash.display.DisplayObject;
    import flash.geom.Point;

    public class PositionedParticleEmitter extends ParticleEmitter 
    {

        private var params:Object;
        private var offsetX:Number;
        private var offsetY:Number;
        private var holder:DisplayObjectContainer;

        public function PositionedParticleEmitter(_arg_1:int, _arg_2:int, _arg_3:DisplayObject, _arg_4:DisplayObjectContainer, _arg_5:Object, _arg_6:Number=0, _arg_7:Number=0)
        {
            super(_arg_1, _arg_2, _arg_3);
            this.params = _arg_5;
            this.holder = _arg_4;
            this.offsetX = _arg_6;
            this.offsetY = _arg_7;
        }

        override protected function createParticle(_arg_1:Number, _arg_2:Number):DisplayObject
        {
            if (!target.parent) {
                return null;
            }
            this.params.minX = _arg_1 + this.params.minOffsetX;
            this.params.maxX = _arg_1 + this.params.maxOffsetX;
            this.params.minY = _arg_2 + this.params.minOffsetY;
            this.params.maxY = _arg_2 + this.params.maxOffsetY;
            var _local_3:PhysicsParticle = new PhysicsParticle(this.params);
            this.holder.addChild(_local_3);
            return _local_3;
        }

        override protected function makeX():Number
        {
            return this.getTargetPoint().x;
        }

        override protected function makeY():Number
        {
            return this.getTargetPoint().y;
        }

        // _loc1 = point
        private function getTargetPoint():Object
        {
            if (!this.holder || !target || !target.parent) {
                return (new Point(0, 0));
            }
            var point:Point = new Point(target.x - this.offsetX, target.y - this.offsetY);
            point = target.parent.localToGlobal(point);
            return this.holder.globalToLocal(point);
        }


    }
}//package character

