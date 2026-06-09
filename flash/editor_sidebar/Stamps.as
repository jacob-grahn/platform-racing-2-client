
package editor_sidebar
{
    import editor_tools.StampButton;
    import editor_tools.BrushButton;
    import editor_tools.ObjectDeleterButton;
    import editor_tools.TextToolButton;

    public class Stamps extends SideBar 
    {

        // _loc3 = i
        public function Stamps()
        {
            super();
            addItem(new BrushButton(), "Draw Menu", "Switch to the draw menu to draw custom backgrounds.");
            addItem(new ObjectDeleterButton(), "Delete Tool", "Click and drag the mouse to delete things with remarkable speed!");
            addItem(new TextToolButton(), "Text", "Compose prose with style.");
            var i:int = 0;
            while (i < 10) {
                addItem(new StampButton(i++));
            }
        }

    }
}
