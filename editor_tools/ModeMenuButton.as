

package editor_tools
{
    import flash.events.MouseEvent;

    public class ModeMenuButton extends MenuButton 
    {

        private var m:ValueButtonGraphic = new ValueButtonGraphic();
        private var value:String;

        public function ModeMenuButton()
        {
            addChild(this.m);
            this.m.titleBox.text = "mode";
            this.setValue("race");
        }

        public function setValue(mode:String)
        {
            this.value = mode;
            this.m.valueBox.text = mode;
        }

        override protected function onClick(e:MouseEvent)
        {
            new ModeMenu(this);
        }


    }
}

