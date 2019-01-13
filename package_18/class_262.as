// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_18.class_262

package package_18
{
    import package_8.Character;
    import flash.events.Event;

    public class class_262 extends class_7 
    {

        private var var_5:Character;
        private var var_388:Number = 24;
        public var var_130:class_294;
        public var var_119:class_294;
        public var var_113:class_294;
        public var var_129:class_294;

        public function class_262(_arg_1:Character, _arg_2:Array, _arg_3:Array, _arg_4:Array, _arg_5:Array, _arg_6:int, _arg_7:int, _arg_8:int, _arg_9:int, _arg_10:int, _arg_11:int, _arg_12:int, _arg_13:int, _arg_14:Array, _arg_15:Array, _arg_16:Array, _arg_17:Array, _arg_18:int, _arg_19:int, _arg_20:int, _arg_21:int)
        {
            this.var_5 = _arg_1;
            this.var_130 = new class_294(_arg_2, _arg_6, _arg_10, _arg_14, _arg_18);
            this.var_119 = new class_294(_arg_3, _arg_7, _arg_11, _arg_15, _arg_19);
            this.var_113 = new class_294(_arg_4, _arg_8, _arg_12, _arg_16, _arg_20);
            this.var_129 = new class_294(_arg_5, _arg_9, _arg_13, _arg_17, _arg_21);
            this.var_130.y = (this.var_388 * 0);
            this.var_119.y = (this.var_388 * 1);
            this.var_113.y = (this.var_388 * 2);
            this.var_129.y = (this.var_388 * 3);
            this.var_130.addEventListener(Event.CHANGE, this.method_65, false, 0, true);
            this.var_119.addEventListener(Event.CHANGE, this.method_65, false, 0, true);
            this.var_113.addEventListener(Event.CHANGE, this.method_65, false, 0, true);
            this.var_129.addEventListener(Event.CHANGE, this.method_65, false, 0, true);
            if (_arg_2.length > 1) {
                addChild(this.var_130);
            }
            addChild(this.var_119);
            addChild(this.var_113);
            addChild(this.var_129);
            this.method_65(new Event(Event.CHANGE));
        }

        private function method_65(_arg_1:Event)
        {
            this.var_5.method_395(this.var_130.getValue());
            this.var_5.method_250(this.var_119.getValue());
            this.var_5.method_217(this.var_113.getValue());
            this.var_5.method_326(this.var_129.getValue());
            this.var_5.method_133(this.var_130.method_12(), this.var_130.getColor2());
            this.var_5.method_132(this.var_119.method_12(), this.var_119.getColor2());
            this.var_5.method_134(this.var_113.method_12(), this.var_113.getColor2());
            this.var_5.method_90(this.var_129.method_12(), this.var_129.getColor2());
        }

        private function method_111(_arg_1:class_294)
        {
            _arg_1.removeEventListener(Event.CHANGE, this.method_65);
            _arg_1.remove();
            _arg_1 = null;
        }

        override public function remove()
        {
            this.var_5 = null;
            this.method_111(this.var_130);
            this.method_111(this.var_119);
            this.method_111(this.var_113);
            this.method_111(this.var_129);
            super.remove();
        }


    }
}//package package_18

