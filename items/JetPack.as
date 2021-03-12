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

        public function JetPack(p:LocalCharacter)
        {
            super(p);
            class_33.setNumber("totFuel", 200);
            class_33.setNumber("fuel", 200);
            p.setAmmo(3);
        }

        // _loc2 = totFuel
        // _loc3 = remainingFuel
        override public function setSpace(_arg_1:Boolean)
        {
            super.setSpace(space);
            if (_arg_1) {
                if (!player.crouching) {
                    if (player.velY > -5) {
                        player.velY = player.velY - 1.25;
                    } else {
                        player.velY = player.velY - 0.5;
                    }
                }
                var totFuel:Number = class_33.getNumber("totFuel");
                var remainingFuel:Number = class_33.getNumber("fuel");
                remainingFuel--;
                class_33.setNumber("fuel", remainingFuel);
                player.setAmmo(Math.ceil((remainingFuel / totFuel) * 3));
                if (remainingFuel <= 0) {
                    super.useItem();
                }
            }
            if (_arg_1 != this.var_592) {
                this.var_592 = _arg_1;
                if (player != null) {
                    if (_arg_1) {
                        player.beginJet();
                    } else {
                        player.endJet();
                    }
                }
            }
        }

        override public function useItem()
        {
        }

        override public function remove()
        {
            player.endJet();
            super.remove();
        }


    }
}//package items

