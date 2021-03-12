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

        public function LaserGun(lc:LocalCharacter)
        {
            super(lc);
            setUses(3);
            setReloadTime(800);
        }

        override public function useItem()
        {
            character.curWeapon.gun.gotoAndPlay("shoot");
            var _local_1:Point = method_37();
            var _local_2:Number = 20;
            var _local_3:* = "right";
            if (character.scaleX < 0) {
                _local_2 = -_local_2;
                character.velX = character.velX + 15;
                _local_3 = "left";
            } else {
                character.velX = character.velX - 15;
            }
            var _local_4:int = _local_1.x + _local_2;
            var _local_5:int = _local_1.y;
            var _local_6:int = Course.course.blockBackground.rotation;
            var _local_7:LaserShot = new LaserShot(_local_4, _local_5, _local_3, _local_6, character.tempID);
            Main.socket.write("add_effect`Laser`" + _local_4 + "`" + _local_5 + "`" + _local_3 + "`" + _local_6 + "`" + character.tempID);
            super.useItem();
        }


    }
}//package items

