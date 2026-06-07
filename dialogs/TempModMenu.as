// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// dialogs.TempModMenu = dialogs.class_195

package dialogs
{
    import com.jiggmin.data.Data;
    import flash.events.MouseEvent;

    public class TempModMenu extends Removable 
    {

        private var m:TempModMenuGraphic = new TempModMenuGraphic();
        private var target:Popup;
        private var userName:String;

        public function TempModMenu(name:String, popup:Popup)
        {
            this.userName = name;
            this.target = popup;
            this.m.warning1Button.addEventListener(MouseEvent.CLICK, this.clickWarning1, false, 0, true);
            this.m.warning2Button.addEventListener(MouseEvent.CLICK, this.clickWarning2, false, 0, true);
            this.m.warning3Button.addEventListener(MouseEvent.CLICK, this.clickWarning3, false, 0, true);
            this.m.kickButton.addEventListener(MouseEvent.CLICK, this.clickKick, false, 0, true); // method_442
            addChild(this.m);
        }

        private function clickWarning1(e:MouseEvent)
        {
            this.warnUser(1);
        }

        private function clickWarning2(e:MouseEvent)
        {
            this.warnUser(2);
        }

        private function clickWarning3(e:MouseEvent)
        {
            this.warnUser(3);
        }

        // method_145 = warnUser
        private function warnUser(warnLevel:int)
        {
            Main.socket.write("warn`" + this.userName + "`" + warnLevel);
            this.target.startFadeOut();
        }

        private function clickKick(e:MouseEvent)
        {
            new ConfirmPopup(this.kickUser, "Are you sure you want to kick " + Data.escapeString(this.userName) + "? They will not be able to re-enter this server for 30 minutes.");
        }

        private function kickUser()
        {
            Main.socket.write("kick`" + this.userName);
            this.target.startFadeOut();
        }

        override public function remove()
        {
            this.m.warning1Button.removeEventListener(MouseEvent.CLICK, this.clickWarning1);
            this.m.warning2Button.removeEventListener(MouseEvent.CLICK, this.clickWarning2);
            this.m.warning3Button.removeEventListener(MouseEvent.CLICK, this.clickWarning3);
            this.m.kickButton.removeEventListener(MouseEvent.CLICK, this.clickKick);
            this.target = null;
            super.remove();
        }


    }
}//package dialogs

