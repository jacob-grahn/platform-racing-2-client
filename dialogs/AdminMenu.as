// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// dialogs.AdminMenu = dialogs.class_194

package dialogs
{
    import flash.events.MouseEvent;

    public class AdminMenu extends Removable 
    {

        private var m:AdminMenuGraphic = new AdminMenuGraphic();
        private var target:Popup;
        private var userName:String;
        private var mode:String;

        public function AdminMenu(name:String, popup:Popup)
        {
            this.userName = name;
            this.target = popup;
            this.m.tempMod_bt.addEventListener(MouseEvent.CLICK, this.clickTemp, false, 0, true);
            this.m.trialMod_bt.addEventListener(MouseEvent.CLICK, this.clickTrial, false, 0, true);
            this.m.permaMod_bt.addEventListener(MouseEvent.CLICK, this.clickPerma, false, 0, true);
            this.m.demote_bt.addEventListener(MouseEvent.CLICK, this.clickDemote, false, 0, true);
            addChild(this.m);
        }

        private function clickTemp(e:MouseEvent)
        {
            this.mode = "temporary";
            new ConfirmPopup(this.promoteModerator, "Are you sure you want to promote " + this.userName + " to a temporary moderator? They will be a moderator on this server until they log off. They will be able to administer 30 minute server kicks.");
        }

        private function clickTrial(e:MouseEvent)
        {
            this.mode = "trial";
            new ConfirmPopup(this.promoteModerator, "Are you sure you want to promote " + this.userName + " to a trial moderator? They will only be able to ban for up to a day.");
        }

        private function clickPerma(e:MouseEvent)
        {
            this.mode = "permanent";
            new ConfirmPopup(this.promoteModerator, "Are you sure you want to promote " + this.userName + " to a permanent moderator? They will be able to ban for up to a year, see IP addresses, unpublish levels, edit guilds, and use the PR2 Hub moderation tools.");
        }

        private function clickDemote(e:MouseEvent)
        {
            this.mode = null;
            new ConfirmPopup(this.demoteModerator, "Are you sure you want to demote " + this.userName + "?");
        }

        private function promoteModerator()
        {
            Main.socket.write("promote_to_moderator`" + this.userName + "`" + this.mode);
            this.target.startFadeOut();
        }

        private function demoteModerator()
        {
            Main.socket.write("demote_moderator`" + this.userName);
            this.target.startFadeOut();
        }

        override public function remove()
        {
            this.m.tempMod_bt.removeEventListener(MouseEvent.CLICK, this.clickTemp);
            this.m.trialMod_bt.removeEventListener(MouseEvent.CLICK, this.clickTrial);
            this.m.permaMod_bt.removeEventListener(MouseEvent.CLICK, this.clickPerma);
            this.m.demote_bt.removeEventListener(MouseEvent.CLICK, this.clickDemote);
            this.target = null;
            super.remove();
        }


    }
}//package dialogs

