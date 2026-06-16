//items.Sword

package items
{
    import character.LocalCharacter;
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

        override public function useItem()
        {
            var direction:String = "left";
            if (this.localChar.scaleX > 0) {
                direction = "right";
                this.localChar.velX += 8;
            } else {
                this.localChar.velX -= 8;
            }
            this.localChar.curWeapon.sword.gotoAndPlay("swing");
            var _local_2:Point = getWeaponEffectPos();
            var _local_3:int = _local_2.x;
            var _local_4:int = _local_2.y;
            var _local_5:Slash = new Slash(_local_3, _local_4, direction, this.localChar.tempID);
            Main.socket.write("add_effect`Slash`" + _local_3 + "`" + _local_4 + "`" + direction + "`" + this.localChar.tempID);
            super.useItem();
        }


    }
}//package items

