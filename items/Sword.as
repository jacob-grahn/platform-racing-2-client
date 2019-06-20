// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//items.Sword

package items
{
    import package_8.LocalCharacter;
    import flash.geom.Point;
    import package_9.Slash;

    public class Sword extends Item 
    {

        public function Sword(r:LocalCharacter)
        {
            super(r);
            setUses(3);
            setReloadTime(800);
        }

        // _loc1 = direction
        override public function useItem()
        {
            var direction:String = "left";
            if (racer.scaleX > 0) {
                direction = "right";
                racer.velX = racer.velX + 8;
            } else {
                racer.velX = racer.velX - 8;
            }
            racer.curWeapon.sword.gotoAndPlay("swing");
            var _local_2:Point = method_37();
            var _local_3:int = _local_2.x;
            var _local_4:int = _local_2.y;
            var _local_5:Slash = new Slash(_local_3, _local_4, direction, racer.tempID);
            Main.socket.write("add_effect`Slash`" + _local_3 + "`" + _local_4 + "`" + direction + "`" + racer.tempID);
            super.useItem();
        }


    }
}//package items

