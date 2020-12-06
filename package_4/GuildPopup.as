// package_4.GuildPopup = package_4.class_146

package package_4
{
    import com.jiggmin.data.Data;
    import flash.display.Loader;
    import flash.events.MouseEvent;
    import flash.events.Event;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import ui.CustomScrollBar;

    public class GuildPopup extends Popup 
    {

        public static var instance:GuildPopup;

        private var m:GuildPopupGraphic;
        private var superLoader:SuperLoader; // var_123
        private var loader:Loader; // var_293
        private var guildMembers:Vector.<GuildMemberName> = new Vector.<GuildMemberName>(); // var_309
        private var scroll:CustomScrollBar;
        private var guildName:String;
        private var guildId:int;
        private var ownerId:int; // var_607

        public function GuildPopup(id:int = 0, name:String = "")
        {
            super();
            this.guildId = id;
            if (GuildPopup.instance != null) {
                GuildPopup.instance.startFadeOut();
            }
            GuildPopup.instance = this;
            this.m = new GuildPopupGraphic();
            addChild(this.m);
            if ((this.guildId != 0 && Main.guild == this.guildId) || (name != "" && Main.guildName == name)) {
                this.m.gotoAndStop("member");
                this.m.messageButton.addEventListener(MouseEvent.CLICK, this.clickMessage, false, 0, true);
            } else {
                this.m.gotoAndStop("nonMember");
                this.m.messageButton.visible = false;
            }
            this.m.edit_bt.visible = false;
            this.m.delete_bt.visible = false;
            if (Main.group >= 2 && Main.isTrialMod == false) {
                this.m.edit_bt.visible = true;
                this.m.edit_bt.addEventListener(MouseEvent.CLICK, this.clickEdit, false, 0, true);
                if (Main.group == 3) {
                    this.m.delete_bt.visible = true;
                    this.m.delete_bt.addEventListener(MouseEvent.CLICK, this.clickDelete, false, 0, true);
                }
            }
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose, false, 0, true);
            this.loader = new Loader();
            this.loader.x = -140;
            this.loader.y = -109;
            addChild(this.loader);
            this.scroll = new CustomScrollBar();
            this.scroll.x = 126;
            this.scroll.y = -28;
            var vars:URLVariables = new URLVariables();
            vars.id = id;
            vars.name = name;
            vars.getMembers = "yes";
            var request:URLRequest = new URLRequest(Main.baseURL + "/guild_info.php");
            request.data = vars;
            this.superLoader = new SuperLoader(true, SuperLoader.j);
            this.superLoader.addEventListener(SuperLoader.d, this.parseReturn, false, 0, true);
            this.superLoader.addEventListener(SuperLoader.e, this.clickClose, false, 0, true);
            this.superLoader.load(request);
        }

        // _loc2 = ret
        // _loc3 = members
        // _loc4 = member
        // _loc5 = userName
        // method_228 = parseReturn
        private function parseReturn(e:Event)
        {
            var ret:Object = this.superLoader.parsedData.guild;
            var members:Array = this.superLoader.parsedData.members;
            this.guildId = ret.guild_id;
            this.ownerId = ret.owner_id;
            this.guildName = ret.guild_name;
            this.m.titleBox.text = "-- " + this.guildName + " --";
            this.m.gpTodayBox.text = "GP today: " + Data.formatNumber(ret.gp_today);
            this.m.gpTotalBox.text = "GP total: " + Data.formatNumber(ret.gp_total);
            this.m.membersCount.text = "Members: " + ret.member_count + " (" + ret.active_count + " active)";
            this.m.guildProse.text = ret.note;
            this.loader.load(new URLRequest(Main.baseURL + "/emblems/" + ret.emblem));
            var userName:GuildMemberName;
            for each (var member:Object in members) {
                userName = new GuildMemberName(member.name, member.power + (member.trial_mod == 1 ? ',1' : ''), member.gp_today, member.gp_total, (this.ownerId == member.user_id));
                userName.y = this.guildMembers.length * 16;
                this.m.membersHolder.addChild(userName);
                this.guildMembers.push(userName);
            }
            addChild(this.scroll);
            this.scroll.init(this.m.membersHolder, 100, 100);
        }

        // method_244 = clickMessage
        private function clickMessage(e:MouseEvent)
        {
            new SendMessagePopup("guild", "", true);
        }

        // method_377 = clickClose
        private function clickClose(e:*)
        {
            startFadeOut();
        }

        private function clickEdit(e:MouseEvent)
        {
            startFadeOut();
            new CreateGuildPopup(this.guildId);
        }

        // method_252 = clickDelete
        private function clickDelete(e:MouseEvent)
        {
            var confirmStr:String = "Are you sure you want to delete this guild?";
            if (this.guildName != "") {
                confirmStr = "Are you sure you want to delete " + Data.escapeString(this.guildName) + "?";
            }
            new ConfirmPopup(this.confirmDelete, confirmStr);
        }

        // method_73 = confirmDelete
        public function confirmDelete()
        {
            var deleteGuildSL:SuperLoader = new SuperLoader(true, SuperLoader.j);
            var vars:URLVariables = new URLVariables();
            vars.guild_id = this.guildId;
            var request:URLRequest = new URLRequest(Main.baseURL + "/guild_delete.php");
            request.method = URLRequestMethod.POST;
            request.data = vars;
            deleteGuildSL.load(request);
            startFadeOut();
        }

        // _loc1 = member
        override public function remove()
        {
            var member:GuildMemberName;
            if (GuildPopup.instance === this) {
                GuildPopup.instance = null;
            }
            for each (member in this.guildMembers) {
                member.remove();
            }
            this.guildMembers = null;
            this.superLoader.removeEventListener(SuperLoader.d, this.parseReturn);
            this.superLoader.removeEventListener(SuperLoader.e, this.clickClose);
            this.superLoader.remove();
            this.superLoader = null;
            this.scroll.remove();
            this.scroll = null;
            this.m.messageButton.removeEventListener(MouseEvent.CLICK, this.clickMessage);
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            this.m.edit_bt.removeEventListener(MouseEvent.CLICK, this.clickEdit);
            this.m.delete_bt.removeEventListener(MouseEvent.CLICK, this.clickDelete);
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}
