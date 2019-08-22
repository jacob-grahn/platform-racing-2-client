// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_18.class_263 = package_18.Preset

package package_18
{
    public class Preset 
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

        public function Preset(_arg_1:Object)
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

        // _loc1 = data
        // method_558 = getPresetData
        public function getPresetData():Object
        {
            var data:Object = new Object();
            data.num = this.num;
            data.speed = this.speed;
            data.acceleration = this.acceleration;
            data.jumping = this.jumping;
            data.hat = this.hat;
            data.head = this.head;
            data.body = this.body;
            data.feet = this.feet;
            data.hatColor = this.hatColor;
            data.headColor = this.headColor;
            data.bodyColor = this.bodyColor;
            data.feetColor = this.feetColor;
            data.hatColor2 = this.hatColor2;
            data.headColor2 = this.headColor2;
            data.bodyColor2 = this.bodyColor2;
            data.feetColor2 = this.feetColor2;
            return data;
        }


    }
}
