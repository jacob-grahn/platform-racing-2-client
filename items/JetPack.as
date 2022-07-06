// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//items.JetPack

package items
{
    import com.jiggmin.data.class_33;
    import package_8.LocalCharacter;

    public class JetPack extends Item 
    {

        private var spaceDown:Boolean = false; // var_592

        public function JetPack(lc:LocalCharacter)
        {
            super(lc);
            class_33.setNumber("totFuel", 200);
            class_33.setNumber("fuel", 200);
            lc.setAmmo(3);
        }

        // _loc2 = totFuel
        // _loc3 = remainingFuel
        override public function setSpace(pressed:Boolean)
        {
            if (pressed && !character.crouching) {
                super.setSpace(space);
                character.velY -= character.velY > -5 ? 1.25 : 0.5;
                var totFuel:Number = class_33.getNumber("totFuel");
                var remainingFuel:Number = class_33.getNumber("fuel");
                remainingFuel--;
                class_33.setNumber("fuel", remainingFuel);
                character.setAmmo(Math.ceil((remainingFuel / totFuel) * 3));
                if (remainingFuel <= 0) {
                    super.useItem();
                }
            }
            if (pressed != this.spaceDown) {
                this.spaceDown = pressed;
                if (character != null) {
                    pressed ? character.beginJet() : character.endJet();
                }
            }
        }

        override public function useItem()
        {
        }

        public function replenishFuel(lc:LocalCharacter)
        {
            class_33.setNumber("totFuel", 200);
            class_33.setNumber("fuel", 200);
            lc.setAmmo(3);
        }

        override public function remove()
        {
            character.endJet();
            super.remove();
        }


    }
}//package items

