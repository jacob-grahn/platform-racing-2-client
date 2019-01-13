// package_19.ObjectDeleterButton = package_19.class_227

package package_19
{
    import flash.events.MouseEvent;
    import ui.class_8;
    import package_20.ObjectDeleter;

    public class ObjectDeleterButton extends class_7 
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
            class_8.method_28(new ObjectDeleter());
        }

        override public function remove()
        {
            removeEventListener(MouseEvent.MOUSE_DOWN, this.select);
            super.remove();
        }


    }
}
