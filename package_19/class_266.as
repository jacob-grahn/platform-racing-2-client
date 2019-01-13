// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_19.class_266

package package_19
{
    import package_4.class_264;
    import flash.events.Event;

    public class class_266 extends class_264 
    {

        private var m:ValueMenuGraphic = new ValueMenuGraphic();
        private var defineCommand:Function;
        private var var_537:String;

        public function class_266(_arg_1:class_217, _arg_2:String, _arg_3:String, _arg_4:String, _arg_5:Function, _arg_6:Number=9, _arg_7:String="0123456789", _arg_8:String="0", _arg_9:Boolean=false)
        {
            this.defineCommand = _arg_5;
            this.var_537 = _arg_8;
            this.m.titleBox.htmlText = (("<b>-- " + _arg_2) + " --</b>");
            this.m.var_283.htmlText = _arg_3;
            this.m.var_18.text = _arg_4;
            this.m.var_18.maxChars = _arg_6;
            this.m.var_18.restrict = _arg_7;
            this.m.var_18.displayAsPassword = _arg_9;
            addChild(this.m);
            this.m.var_18.addEventListener(Event.CHANGE, this.method_65);
            super(_arg_1);
        }

        private function method_65(_arg_1:Event)
        {
            var _local_2:String = _arg_1.target.text;
            if (_local_2 == "") {
                _local_2 = this.var_537;
            }
            this.defineCommand(_local_2);
        }

        override public function remove()
        {
            this.m.var_18.removeEventListener(Event.CHANGE, this.method_65);
            Main.stage.focus = Main.stage;
            super.remove();
        }


    }
}//package package_19

