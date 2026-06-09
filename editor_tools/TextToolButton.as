
package editor_tools
{
    import ui.CustomCursor;
    import drawing_tools.TextTool;
    import flash.events.MouseEvent;

    public class TextToolButton extends MenuButton 
    {

        private var m:TextToolButtonGraphic = new TextToolButtonGraphic();

        public function TextToolButton()
        {
            addChild(this.m);
        }

        override protected function onClick(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            CustomCursor.change(new TextTool());
        }

        override public function remove()
        {
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}
