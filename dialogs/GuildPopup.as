// dialogs.GuildPopup = dialogs.class_146

package dialogs
{
    import com.jiggmin.data.Data;
    import flash.display.Loader;
    import flash.events.MouseEvent;
    import flash.events.Event;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import ui.CustomScrollBar;
    import flash.events.KeyboardEvent;

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
        private var guildIdShown:Boolean = false;
        private var ownerId:int; // var_607

        public function GuildPopup(id:int = 0, name:String = "")
        {
            super();
            this.guildId = id;
            this.guildName = '';
            if (GuildPopup.instance != null) {
                GuildPopup.instance.startFadeOut();
            }
            GuildPopup.instance = this;
            this.m = new GuildPopupGraphic();
            this.m.gotoAndStop('loading');
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose, false, 0, true);
            addChild(this.m);
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

        private function determineVisuals()
        {
            this.m.gotoAndStop('nonMember');
            this.m.edit_bt.visible = this.m.delete_bt.visible = false;
            if (Main.group >= 2 && Main.isTrialMod == false) {
                this.m.edit_bt.visible = true;
                this.m.edit_bt.addEventListener(MouseEvent.CLICK, this.clickEdit, false, 0, true);
                if (Main.group == 3) {
                    this.m.delete_bt.visible = true;
                    this.m.delete_bt.addEventListener(MouseEvent.CLICK, this.clickDelete, false, 0, true);
                }
            }
            this.loader = new Loader();
            this.loader.x = -140;
            this.loader.y = -109;
            addChild(this.loader);
            this.scroll = new CustomScrollBar();
            this.scroll.x = 126;
            this.scroll.y = -28;
        }

        // _loc2 = ret
        // _loc3 = members
        // _loc4 = member
        // _loc5 = userName
        private function parseReturn(e:Event)
        {
            this.determineVisuals();
            var ret:Object = this.superLoader.parsedData.guild;
            var members:Array = this.superLoader.parsedData.members;
            this.guildId = ret.guild_id;
            this.ownerId = ret.owner_id;
            this.guildName = ret.guild_name;
            this.m.titleBox.text = "-- " + this.guildName + " --";
            this.m.gpTodayBox.text = "GP Today: " + Data.formatNumber(ret.gp_today);
            this.m.gpTotalBox.text = "GP Total: " + Data.formatNumber(ret.gp_total);
            this.m.membersCount.text = "Members: " + ret.member_count + " (" + ret.active_count + " active)";
            this.m.guildProse.text = ret.note;
            this.loader.load(new URLRequest(Main.baseURL + "/emblems/" + ret.emblem));
            for each (var member:Object in members) {
                var userName:GuildMemberName = new GuildMemberName(member, (this.ownerId == member.user_id));
                userName.y = this.guildMembers.length * 16;
                this.m.membersHolder.addChild(userName);
                this.guildMembers.push(userName);
            }
            if (this.guildId != 0 && Main.guild == this.guildId) {
                this.m.gotoAndStop("member");
                this.m.close_bt.x = 8;
                this.m.close_bt.width = 85;
                this.m.messageButton.addEventListener(MouseEvent.CLICK, this.clickMessage, false, 0, true);
            }
            addChild(this.scroll);
            this.scroll.init(this.m.membersHolder, 100, 100);
            this.m.loadingGraphic.visible = false;
            Main.stage.addEventListener(KeyboardEvent.KEY_DOWN, this.toggleGuildIdShown, false, 0, true);
            Main.stage.focus = Main.stage;
        }

        private function clickMessage(e:MouseEvent)
        {
            new SendMessagePopup("guild", "", true);
        }

        private function clickClose(e:*)
        {
            startFadeOut();
        }

        private function clickEdit(e:MouseEvent)
        {
            startFadeOut();
            new CreateGuildPopup(this.guildId);
        }

        private function clickDelete(e:MouseEvent)
        {
            var confirmStr:String = "Are you sure you want to delete this guild?";
            if (this.guildName != "") {
                confirmStr = "Are you sure you want to delete " + Data.escapeString(this.guildName) + "?";
            }
            new ConfirmPopup(this.confirmDelete, confirmStr);
        }

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

        private function toggleGuildIdShown(e:KeyboardEvent)
        {
            if (e.keyCode !== 16 || e.type !== KeyboardEvent.KEY_DOWN) {
                return;
            }
            this.m.titleBox.text = !this.guildIdShown ? '-- Guild ID: ' + this.guildId + ' --' : '-- ' + this.guildName + ' --';
            this.guildIdShown = !this.guildIdShown;
        }

        // _loc1 = member
        override public function remove()
        {
            if (GuildPopup.instance === this) {
                GuildPopup.instance = null;
            }
            Main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.toggleGuildIdShown);
            for each (var member:GuildMemberName in this.guildMembers) {
                member.remove();
            }
            this.guildMembers = null;
            this.superLoader.removeEventListener(SuperLoader.d, this.parseReturn);
            this.superLoader.removeEventListener(SuperLoader.e, this.clickClose);
            this.superLoader.remove();
            this.superLoader = null;
            if (this.scroll != null) {
                this.scroll.remove();
                this.scroll = null;
            }
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}
