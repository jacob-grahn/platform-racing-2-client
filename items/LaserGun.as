// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//items.LaserGun

package items
{
    import package_8.LocalCharacter;
    import flash.geom.Point;
    import package_6.Course;
    import package_9.LaserShot;

    public class LaserGun extends Item 
    {

        public function LaserGun(r:LocalCharacter)
        {
            super(r);
            setUses(3);
            setReloadTime(800);
        }

        override public function useItem()
        {
            racer.curWeapon.gun.gotoAndPlay("shoot");
            var _local_1:Point = method_37();
            var _local_2:Number = 20;
            var _local_3:* = "right";
            if (racer.scaleX < 0) {
                _local_2 = -_local_2;
                racer.velX = racer.velX + 15;
                _local_3 = "left";
            } else {
                racer.velX = racer.velX - 15;
            }
            var _local_4:int = _local_1.x + _local_2;
            var _local_5:int = _local_1.y;
            var _local_6:int = Course.course.blockBackground.rotation;
            var _local_7:LaserShot = new LaserShot(_local_4, _local_5, _local_3, _local_6, racer.tempID);
            Main.socket.write("add_effect`Laser`" + _local_4 + "`" + _local_5 + "`" + _local_3 + "`" + _local_6 + "`" + racer.tempID);
            super.useItem();
        }


    }
}//package items

