package editor_tools
{
    import flash.events.MouseEvent;

    public class HatsMenuButton extends MenuButton 
    {

        public function HatsMenuButton()
        {
            var button:HatsButtonGraphic = new HatsButtonGraphic();
            addChild(button);
        }

        override protected function onClick(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            new HatsMenu(this);
        }


    }
}
