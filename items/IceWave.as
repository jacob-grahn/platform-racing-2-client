// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//items.IceWave

package items
{
    import package_8.LocalCharacter;
    import flash.geom.Point;
    import package_6.Course;
    import background.class_87;

    public class IceWave extends Item 
    {

        public function IceWave(r:LocalCharacter)
        {
            super(r);
            method_48(3);
            method_45(1000);
        }

        // _loc6 = rot
        // _loc7 = sendStr
        override public function useItem()
        {
            racer.curWeapon.freezeWave.gotoAndPlay("fire");
            var _local_1:Point = method_37();
            var _local_2:Number = 20;
            var _local_3:Number = 0;
            if (racer.scaleX < 0) {
                _local_3 = 180;
                _local_2 = -_local_2;
            }
            var _local_4:int = _local_1.x + _local_2;
            var _local_5:int = _local_1.y;
            var rot:int = Course.course.blockBackground.rotation;
            var sendStr:String = "IceWave`" + _local_4 + "`" + _local_5 + "`" + _local_3 + "`" + rot + "`" + racer.tempID;
            class_87.var_276.addEffect(sendStr.split("`"));
            Main.socket.write("add_effect`" + sendStr);
            super.useItem();
        }


    }
}//package items

