// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//blocks.class_39

package blocks
{
    import package_8.LocalCharacter;
    import flash.geom.ColorTransform;

    public class class_39 extends Block 
    {

        protected var var_243:int = 1;

        public function class_39(_arg_1:int)
        {
            super(_arg_1);
        }

        override public function onBump(_arg_1:LocalCharacter)
        {
            super.onBump(_arg_1);
            if (!var_37) {
                if (this.var_243 > 0) {
                    this.var_243--;
                    this.useSupply(_arg_1);
                }
                if (this.var_243 <= 0) {
                    this.method_789();
                }
            }
        }

        protected function useSupply(_arg_1:LocalCharacter)
        {
        }

        protected function method_789()
        {
            var _local_1:ColorTransform = new ColorTransform(0.5, 0.5, 0.5);
            transform.colorTransform = _local_1;
        }


    }
}//package blocks

