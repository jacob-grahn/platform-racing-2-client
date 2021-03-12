// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//items.JetPack

package items
{
    import com.jiggmin.data.class_33;
    import package_8.LocalCharacter;

    public class JetPack extends Item 
    {

        private var var_592:Boolean = false;

        public function JetPack(lc:LocalCharacter)
        {
            super(lc);
            class_33.setNumber("totFuel", 200);
            class_33.setNumber("fuel", 200);
            lc.setAmmo(3);
        }

        // _loc2 = totFuel
        // _loc3 = remainingFuel
        override public function setSpace(_arg_1:Boolean)
        {
            super.setSpace(space);
            if (_arg_1) {
                if (!character.crouching) {
                    if (character.velY > -5) {
                        character.velY = character.velY - 1.25;
                    } else {
                        character.velY = character.velY - 0.5;
                    }
                }
                var totFuel:Number = class_33.getNumber("totFuel");
                var remainingFuel:Number = class_33.getNumber("fuel");
                remainingFuel--;
                class_33.setNumber("fuel", remainingFuel);
                character.setAmmo(Math.ceil((remainingFuel / totFuel) * 3));
                if (remainingFuel <= 0) {
                    super.useItem();
                }
            }
            if (_arg_1 != this.var_592) {
                this.var_592 = _arg_1;
                if (character != null) {
                    if (_arg_1) {
                        character.beginJet();
                    } else {
                        character.endJet();
                    }
                }
            }
        }

        override public function useItem()
        {
        }

        override public function remove()
        {
            character.endJet();
            super.remove();
        }


    }
}//package items

