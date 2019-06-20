// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_9.class_80

package package_9
{
    import background.class_87;
    import flash.utils.setTimeout;
    import flash.utils.clearTimeout;

    public class class_80 extends Removable 
    {

        private var var_529:uint;

        public function class_80(_arg_1:Number=0, _arg_2:Number=0)
        {
            x = _arg_1;
            y = _arg_2;
            class_87.var_276.addChild(this);
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

