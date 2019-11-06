// package_19.ObjectDeleterButton = package_19.class_227

package package_19
{
    import flash.events.MouseEvent;
    import ui.CustomCursor;
    import package_20.ObjectDeleter;

    public class ObjectDeleterButton extends Removable 
    {

        private var m:ObjectDeleterButtonGraphic = new ObjectDeleterButtonGraphic();

        public function ObjectDeleterButton()
        {
            addChild(this.m);
            addEventListener(MouseEvent.MOUSE_DOWN, this.select);
        }

        protected function select(e:MouseEvent)
        {
            e.stopImmediatePropagation();
            CustomCursor.change(new ObjectDeleter());
        }

        override public function remove()
        {
            removeEventListener(MouseEvent.MOUSE_DOWN, this.select);
            super.remove();
        }


    }
}
