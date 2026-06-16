//items.JetPack

package items
{
    import com.jiggmin.data.SecureData;
    import character.LocalCharacter;

    public class JetPack extends Item 
    {

        private var spaceDown:Boolean = false;

        public function JetPack(lc:LocalCharacter)
        {
            super(lc);
            SecureData.setNumber("totFuel", 200);
            SecureData.setNumber("fuel", 200);
            lc.setAmmo(3);
        }

        // _loc2 = totFuel
        // _loc3 = remainingFuel
        override public function setSpace(pressed:Boolean)
        {
            if (pressed && !this.localChar.crouching) {
                super.setSpace(space);
                this.localChar.velY -= this.localChar.velY > -5 ? 1.25 : 0.5;
                var totFuel:Number = SecureData.getNumber("totFuel");
                var remainingFuel:Number = SecureData.getNumber("fuel");
                remainingFuel--;
                SecureData.setNumber("fuel", remainingFuel);
                this.localChar.setAmmo(Math.ceil((remainingFuel / totFuel) * 3));
                if (remainingFuel <= 0) {
                    super.useItem();
                }
            }
            if (pressed != this.spaceDown) {
                this.spaceDown = pressed;
                if (this.localChar != null) {
                    pressed ? this.localChar.beginJet() : this.localChar.endJet();
                }
            }
        }

        override public function useItem()
        {
        }

        public function replenishFuel(lc:LocalCharacter)
        {
            SecureData.setNumber("totFuel", 200);
            SecureData.setNumber("fuel", 200);
            lc.setAmmo(3);
        }

        override public function remove()
        {
            this.localChar.endJet();
            super.remove();
        }


    }
}//package items

