// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_8.class_125

package package_8
{
    import flash.display.DisplayObject;
    import flash.utils.setInterval;
    import effects.StarEffect;
    import flash.utils.clearInterval;

    public class class_125 
    {

        private var var_416:uint;
        private var var_444:int;
        private var duration:int;
        private var life:int;
        protected var target:DisplayObject;

        public function class_125(_arg_1:int, _arg_2:int, _arg_3:DisplayObject)
        {
            this.var_444 = _arg_1;
            this.duration = _arg_2;
            this.target = _arg_3;
            this.life = Math.floor((_arg_2 / _arg_1));
            this.var_416 = setInterval(this.method_571, _arg_1);
        }

        protected function method_571()
        {
            var _local_1:Number = this.makeX();
            var _local_2:Number = this.makeY();
            var _local_3:DisplayObject = this.createParticle(_local_1, _local_2);
            this.life--;
            if (this.life <= 0) {
                this.remove();
            }
        }

        protected function makeX():Number
        {
            return ((this.target.x + (Math.random() * 20)) - 10);
        }

        protected function makeY():Number
        {
            return (this.target.y - (Math.random() * 55));
        }

        protected function createParticle(_arg_1:Number, _arg_2:Number):DisplayObject
        {
            return (new StarEffect(_arg_1, _arg_2));
        }

        public function remove()
        {
            this.target = null;
            clearInterval(this.var_416);
        }


    }
}//package package_8

