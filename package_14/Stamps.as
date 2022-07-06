// package_14.Stamps = package_14.class_172

package package_14
{
    import package_19.StampButton;
    import package_19.BrushButton;
    import package_19.ObjectDeleterButton;
    import package_19.TextToolButton;

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
