// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_21.ReplyMessageButton = package_21.class_304

package package_21
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
}//package package_21

