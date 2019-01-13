// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_14.class_172

package package_14
{
    import package_19.class_221;
    import package_19.BrushButton;
    import package_19.ObjectDeleterButton;
    import package_19.TextToolButton;

    public class class_172 extends SideBar 
    {

        // _loc3 = i
        public function class_172()
        {
            var _local_2:class_221;
            super();
            addItem(new BrushButton(), "Draw Menu", "Switch to the draw menu to draw custom backgrounds.");
            addItem(new ObjectDeleterButton(), "Delete Tool", "Click and drag the mouse to delete things with remarkable speed!");
            addItem(new TextToolButton(), "Text", "Compose prose with style.");
            var i:int = 0;
            while (i < 10) {
                _local_2 = new class_221(i);
                addItem(_local_2);
                i++;
            }
        }

    }
}
