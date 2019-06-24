// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_9.class_178

package package_9
{
    public class class_178 extends Effect 
    {

        private var m:class_239 = new class_239();

        public function class_178(_arg_1:Number, _arg_2:Number)
        {
            x = _arg_1;
            y = _arg_2;
            addChild(this.m);
            method_2(15);
        }

        override public function remove()
        {
            this.m = null;
            super.remove();
        }


    }
}//package package_9

