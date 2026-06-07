// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//items.Sword

package items
{
    import package_8.LocalCharacter;
    import flash.geom.Point;
    import effects.Slash;

    public class Sword extends Item 
    {

        public function Sword(lc:LocalCharacter)
        {
            super(lc);
            setUses(3);
            setReloadTime(800);
        }

        // _loc1 = direction
        override public function useItem()
        {
            var direction:String = "left";
            if (character.scaleX > 0) {
                direction = "right";
                character.velX += 8;
            } else {
                character.velX -= 8;
            }
            character.curWeapon.sword.gotoAndPlay("swing");
            var _local_2:Point = method_37();
            var _local_3:int = _local_2.x;
            var _local_4:int = _local_2.y;
            var _local_5:Slash = new Slash(_local_3, _local_4, direction, character.tempID);
            Main.socket.write("add_effect`Slash`" + _local_3 + "`" + _local_4 + "`" + direction + "`" + character.tempID);
            super.useItem();
        }


    }
}//package items

