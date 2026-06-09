
package chat
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
