// blocks.SupplyBlock = blocks.class_39

package blocks
{
    import character.LocalCharacter;
    import flash.geom.ColorTransform;

    public class SupplyBlock extends Block 
    {

        protected var uses:int = 1; // var_243

        public function SupplyBlock(_arg_1:int)
        {
            super(_arg_1);
        }

        override public function onBump(player:LocalCharacter)
        {
            super.onBump(player);
            if (!(this is TeleportBlock)) {
                this.maybeUseSupply(player);
            }
        }

        protected function maybeUseSupply(player:LocalCharacter)
        {
            if (!frozen) {
                if (this.uses > 0) {
                    this.uses--;
                    this.useSupply(player);
                }
                if (this.uses <= 0) {
                    this.method_789();
                }
            }
        }

        protected function useSupply(player:LocalCharacter)
        {
        }

        protected function resetSupply(uses:int = 1)
        {
            this.uses = uses;
            transform.colorTransform = new ColorTransform();
        }

        protected function method_789()
        {
            transform.colorTransform = new ColorTransform(0.5, 0.5, 0.5);
        }


    }
}
