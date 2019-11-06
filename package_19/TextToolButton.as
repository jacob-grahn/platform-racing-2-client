// package_19.TextToolButton = package_19.class_225

package package_19
{
    import ui.CustomCursor;
    import package_20.TextTool;
    import flash.events.MouseEvent;

    public class TextToolButton extends class_215 
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
