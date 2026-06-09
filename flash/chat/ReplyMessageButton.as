

package chat
{
    public class ReplyMessageButton extends HoverDelayPopup 
    {

        private var m:ReplyMessageButtonGraphic = new ReplyMessageButtonGraphic();

        public function ReplyMessageButton()
        {
            addChild(this.m);
            super("Reply to Message", 'You\'ve got something to say, and someone\'s gonna hear it.');
        }

    }
}//package chat

