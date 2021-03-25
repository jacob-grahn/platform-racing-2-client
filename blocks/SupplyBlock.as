// blocks.SupplyBlock = blocks.class_39

package blocks
{
    import package_8.LocalCharacter;
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

        protected function method_789()
        {
            var _local_1:ColorTransform = new ColorTransform(0.5, 0.5, 0.5);
            transform.colorTransform = _local_1;
        }


    }
}
