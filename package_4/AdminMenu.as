// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_4.AdminMenu = package_4.class_194

package package_4
{
    import flash.events.MouseEvent;

    public class AdminMenu extends class_7 
    {

        private var m:AdminMenuGraphic = new AdminMenuGraphic();
        private var target:Popup;
        private var userName:String;
        private var mode:String;

        public function AdminMenu(name:String, _arg_2:Popup)
        {
            this.userName = name;
            this.target = _arg_2;
            this.m.tempMod_bt.addEventListener(MouseEvent.CLICK, this.clickTemp, false, 0, true); // method_215
            this.m.trialMod_bt.addEventListener(MouseEvent.CLICK, this.clickTrial, false, 0, true); // method_271
            this.m.permaMod_bt.addEventListener(MouseEvent.CLICK, this.clickPerma, false, 0, true); // method_300
            this.m.demote_bt.addEventListener(MouseEvent.CLICK, this.clickDemote, false, 0, true); // method_225
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
            new ConfirmPopup(this.promoteModerator, "Are you sure you want to promote " + this.userName + " to a trial moderator? They will be able to ban for up to a day and see IP addresses.");
        }

        private function clickPerma(e:MouseEvent)
        {
            this.mode = "permanent";
            new ConfirmPopup(this.promoteModerator, "Are you sure you want to promote " + this.userName + " to a permanent moderator? They will be able to ban for up to a year, see IP addresses, unpublish levels, and edit guilds.");
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
}//package package_4

