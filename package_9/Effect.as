// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_9.Effect = package_9.class_80

package package_9
{
    import background.EffectBackground;
    import flash.utils.setTimeout;
    import flash.utils.clearTimeout;

    public class Effect extends Removable 
    {

        private var var_529:uint;

        public function Effect(_arg_1:Number=0, _arg_2:Number=0)
        {
            x = _arg_1;
            y = _arg_2;
            EffectBackground.instance.addChild(this);
        }

        protected function method_2(_arg_1:int)
        {
            var _local_2:int = int(((_arg_1 * (1 / 24)) * 1000));
            this.var_529 = setTimeout(this.remove, _local_2);
        }

        override public function remove()
        {
            clearTimeout(this.var_529);
            super.remove();
        }


    }
}//package package_9

