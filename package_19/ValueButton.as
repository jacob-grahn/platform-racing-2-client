// package_19.ValueButton = package_19.class_217

package package_19
{
    import flash.events.MouseEvent;

    public class ValueButton extends class_215 
    {

        private var value:String;
        private var title:String;
        private var description:String;
        private var defineCommand:Function;
        private var maxChars:Number;
        private var restrictTo:String; // var_553
        private var defaultVal:String; // var_537
        private var displayAsPassword:Boolean;
        private var m:ValueButtonGraphic = new ValueButtonGraphic();

        public function ValueButton(_arg_1:String, _arg_2:String, _arg_3:String, _arg_4:String, _arg_5:Function, _arg_6:Number=9, _arg_7:String="0123456789", _arg_8:String="0", _arg_9:Boolean=false)
        {
            this.value = _arg_4;
            this.title = _arg_2;
            this.description = _arg_3;
            this.defineCommand = _arg_5;
            this.maxChars = _arg_6;
            this.restrictTo = _arg_7;
            this.defaultVal = _arg_8;
            this.displayAsPassword = _arg_9;
            this.m.titleBox.text = _arg_1;
            this.m.valueBox.text = _arg_4;
            this.m.valueBox.displayAsPassword = _arg_9;
            addChild(this.m);
        }

        public function setValue(s:String)
        {
            this.value = s;
            this.m.valueBox.text = s;
        }

        override protected function onClick(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            new ValueMenu(this, this.title, this.description, this.value, this.defineCommand, this.maxChars, this.restrictTo, this.defaultVal, this.displayAsPassword);
        }


    }
}
