

package editor_tools
{
    import flash.display.DisplayObject;
    import ui.CustomCursor;
    import drawing_tools.BlockObjectPlacer;
    import flash.events.MouseEvent;

    public class BlockPlacerButton extends StampButton 
    {

        public function BlockPlacerButton(code:int)
        {
            super(code);
        }

        override protected function fit(item:DisplayObject)
        {
        }

        override protected function select(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            CustomCursor.change(new BlockObjectPlacer(displayCode));
        }


    }
}

