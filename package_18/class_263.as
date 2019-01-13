// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_18.class_263

package package_18
{
    public class class_263 
    {

        public var num:int = 1;
        public var speed:int = 50;
        public var acceleration:int = 50;
        public var jumping:int = 50;
        public var hat:int = 1;
        public var head:int = 1;
        public var body:int = 1;
        public var feet:int = 1;
        public var hatColor:int = 0;
        public var headColor:int = 0;
        public var bodyColor:int = 0;
        public var feetColor:int = 0;
        public var hatColor2:int = -1;
        public var headColor2:int = -1;
        public var bodyColor2:int = -1;
        public var feetColor2:int = -1;

        public function class_263(_arg_1:Object)
        {
            this.method_529(_arg_1);
        }

        public function method_529(_arg_1:Object)
        {
            var _local_2:String;
            if (_arg_1 != null) {
                for (_local_2 in _arg_1) {
                    if (this[_local_2] != null) {
                        this[_local_2] = _arg_1[_local_2];
                    }
                }
            }
        }

        public function method_558():Object
        {
            var _local_1:Object = new Object();
            _local_1.num = this.num;
            _local_1.speed = this.speed;
            _local_1.acceleration = this.acceleration;
            _local_1.jumping = this.jumping;
            _local_1.hat = this.hat;
            _local_1.head = this.head;
            _local_1.body = this.body;
            _local_1.feet = this.feet;
            _local_1.hatColor = this.hatColor;
            _local_1.headColor = this.headColor;
            _local_1.bodyColor = this.bodyColor;
            _local_1.feetColor = this.feetColor;
            _local_1.hatColor2 = this.hatColor2;
            _local_1.headColor2 = this.headColor2;
            _local_1.bodyColor2 = this.bodyColor2;
            _local_1.feetColor2 = this.feetColor2;
            return (_local_1);
        }


    }
}//package package_18

