// levelEditor.DrawingPopup = levelEditor.class_167

package levelEditor
{
    import dialogs.Popup;

    public class DrawingPopup extends Popup 
    {

        private var m:DrawingPopupGraphic = new DrawingPopupGraphic();

        public function DrawingPopup()
        {
            super(false);
            addChild(this.m);
        }

    }
}//package levelEditor

