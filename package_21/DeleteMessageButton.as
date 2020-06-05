// package_21.DeleteMessageButton = package_21.class_303

package package_21
{
    public class DeleteMessageButton extends HoverDelayPopup 
    {

        private var m:DeleteMessageButtonGraphic = new DeleteMessageButtonGraphic();

        public function DeleteMessageButton()
        {
            addChild(this.m);
            super("Delete Message", 'Erase this flimsy correspondence from existence.');
        }

    }
}
