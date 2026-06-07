
package editor_tools
{
    import flash.events.MouseEvent;

    public class ValueButton extends MenuButton 
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

        public function ValueButton(key:String, title:String, desc:String, value:String, command:Function, maxChars:Number=9, restrict:String="0123456789", defaultVal:String="0", displayAsPassword:Boolean=false)
        {
            this.value = value;
            this.title = title;
            this.description = desc;
            this.defineCommand = command;
            this.maxChars = maxChars;
            this.restrictTo = restrict;
            this.defaultVal = defaultVal;
            this.displayAsPassword = displayAsPassword;
            this.m.titleBox.text = key;
            this.m.valueBox.text = value;
            this.m.valueBox.displayAsPassword = displayAsPassword;
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
