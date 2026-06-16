

package editor_tools
{
    import dialogs.AutoDismissPopup;
    import flash.events.Event;

    public class ValueMenu extends AutoDismissPopup 
    {

        private var m:ValueMenuGraphic = new ValueMenuGraphic();
        private var defineCommand:Function;
        private var defaultVal:String;

        public function ValueMenu(vb:ValueButton, title:String, desc:String, value:String, command:Function, maxChars:Number=9, restrict:String="0123456789", defaultVal:String="0", displayAsPassword:Boolean=false)
        {
            this.defineCommand = command;
            this.defaultVal = defaultVal;
            this.m.titleBox.htmlText = "<b>-- " + title + " --</b>";
            this.m.descBox.htmlText = desc;
            this.m.valueBox.text = value;
            this.m.valueBox.maxChars = maxChars;
            this.m.valueBox.restrict = restrict;
            this.m.valueBox.displayAsPassword = displayAsPassword;
            addChild(this.m);
            this.m.valueBox.addEventListener(Event.CHANGE, this.onValueChange);
            super(vb);
        }

        private function onValueChange(key:Event)
        {
            var text:String = key.target.text;
            if (text == "") {
                text = this.defaultVal;
            }
            this.defineCommand(text);
        }

        override public function remove()
        {
            this.m.valueBox.removeEventListener(Event.CHANGE, this.onValueChange);
            Main.stage.focus = Main.stage;
            super.remove();
        }


    }
}

