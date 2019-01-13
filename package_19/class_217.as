// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//package_19.class_217

package package_19
{
    import flash.events.MouseEvent;

    public class class_217 extends class_215 
    {

        private var value:String;
        private var title:String;
        private var description:String;
        private var defineCommand:Function;
        private var maxChars:Number;
        private var var_553:String;
        private var var_537:String;
        private var displayAsPassword:Boolean;
        private var m:ValueButtonGraphic = new ValueButtonGraphic();

        public function class_217(_arg_1:String, _arg_2:String, _arg_3:String, _arg_4:String, _arg_5:Function, _arg_6:Number=9, _arg_7:String="0123456789", _arg_8:String="0", _arg_9:Boolean=false)
        {
            this.value = _arg_4;
            this.title = _arg_2;
            this.description = _arg_3;
            this.defineCommand = _arg_5;
            this.maxChars = _arg_6;
            this.var_553 = _arg_7;
            this.var_537 = _arg_8;
            this.displayAsPassword = _arg_9;
            this.m.titleBox.text = _arg_1;
            this.m.var_18.text = _arg_4;
            this.m.var_18.displayAsPassword = _arg_9;
            addChild(this.m);
        }

        public function setValue(_arg_1:String)
        {
            this.value = _arg_1;
            this.m.var_18.text = _arg_1;
        }

        override protected function onClick(_arg_1:MouseEvent)
        {
            _arg_1.stopImmediatePropagation();
            new class_266(this, this.title, this.description, this.value, this.defineCommand, this.maxChars, this.var_553, this.var_537, this.displayAsPassword);
        }


    }
}//package package_19

