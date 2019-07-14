// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_4.PlayerPopup = package_4.class_148

package package_4
{
    import ui.GuildName;
    import flash.events.MouseEvent;
    import flash.net.URLVariables;
    import flash.net.URLRequest;
    import package_8.Character;
    import package_18.PartInfo.PartInfoPopup;
    import package_18.PartInfo.PartPopup;
    import flash.events.Event;
    import lobby.LobbyRight;
    import flash.net.URLRequestMethod;

    public class PlayerPopup extends Popup 
    {

        private static var instance:PlayerPopup;

        private var superLoader:SuperLoader;
        private var m:PlayerPopupGraphic = new PlayerPopupGraphic();
        private var banMenu:BanMenu; // var_200
        private var adminMenu:AdminMenu; // adminMenu
        private var tempModMenu:TempModMenu; // tempModMenu
        private var guildName:GuildName;
        private var userId:int;
        private var userName:String;

        public function PlayerPopup(name:String)
        {
            if (PlayerPopup.instance != null) {
                PlayerPopup.instance.startFadeOut();
            }
            PlayerPopup.instance = this;
            this.userName = name;
            this.m.nameBox.text = "-- " + name + " --";
            this.m.close_bt.addEventListener(MouseEvent.CLICK, this.clickClose, false, 0, true);
            this.m.playerInfo.visible = false;
            addChild(this.m);
            this.superLoader = new SuperLoader(true, SuperLoader.j);
            var vars:URLVariables = new URLVariables();
            vars.name = name;
            var request:URLRequest = new URLRequest(Main.baseURL + "/get_player_info.php");
            request.data = vars;
            this.superLoader.load(request);
            this.superLoader.addEventListener(SuperLoader.d, this.applyReturnData, false, 0, true);
            this.superLoader.addEventListener(SuperLoader.e, this.clickClose, false, 0, true);
            if (Main.group >= 2) {
                this.banMenu = new BanMenu(name, this);
                addChild(this.banMenu);
                this.banMenu.x = (this.banMenu.width / 2) + 45; //(this.banMenu.width / 2) + 3;
                this.m.x = this.m.x - 106; //-(this.m.width / 2) - 3;
                if (Main.group >= 3) {
                    this.m.x = -(this.m.width / 2) - 19.5; //this.m.x - 15;
                    this.banMenu.x = (this.banMenu.width / 2) - 13.5; //this.banMenu.x - 15;
                    this.adminMenu = new AdminMenu(name, this);
                    this.adminMenu.x = 216.5;
                    addChild(this.adminMenu);
                }
            } else if (Main.group == 1 && Main.isTempMod) {
                this.tempModMenu = new TempModMenu(name, this);
                addChild(this.tempModMenu);
                this.tempModMenu.x = (this.tempModMenu.width / 2) + 48;
                this.m.x = this.m.x - 102;
            } 
        }

        // _loc2 = ret
        // _loc3 = regDate
        // _loc4 = group
        // _loc5 = groupText
        // method_281 = applyReturnData
        private function applyReturnData(e:Event)
        {
            var ret:Object = SuperLoader(e.target).parsedData;
            this.userId = int(ret.userId);
            var regDate:String = ret.registerDate;
            if (regDate == '1/Jan/1970') {
                regDate = "Age of Heroes";
            }
            var group:int = ret.group;
            if (group == 1) {
                groupText = 'Member';
            } else if (group == 2) {
                groupText = 'Moderator';
            } else if (group == 3) {
                groupText = 'Admin';
            } else {
                PlayerPopup.instance.startFadeOut();
                new PlayerGuestPopup(this.userName);
                return;
            }
            this.m.playerInfo.statusBox.text = "" + ret.status;
            this.m.playerInfo.hatBox.text = "Hats: " + ret.hats;
            this.m.playerInfo.rankBox.text = "Rank: " + ret.rank;
            this.m.playerInfo.dateBox.text = "Joined: " + regDate;
            this.m.playerInfo.lastLoginBox.text = "Active: " + ret.loginDate;
            this.m.playerInfo.groupBox.text = "Group: " + groupText;
            if (ret.guildId == 0) {
                this.m.playerInfo.guildBox.text = "Guild: none";
            } else {
                this.m.playerInfo.guildBox.text = "Guild:";
                this.guildName = new GuildName(ret.guildId, ret.guildName, ret.emblem, true);
                this.guildName.x = 0;
                this.guildName.y = 42;
                this.m.playerInfo.addChild(this.guildName);
            }
            var c:Character = new Character(ret.hat, ret.head, ret.body, ret.feet);
            this.m.playerInfo.addChild(c);
            c.method_133(ret.hatColor, ret.hatColor2);
            c.method_132(ret.headColor, ret.headColor2);
            c.method_134(ret.bodyColor, ret.bodyColor2);
            c.method_90(ret.feetColor, ret.feetColor2);
            c.scaleX = c.scaleY = 2;
            c.x = -75;
            c.y = 135;
            this.m.playerInfo.inviteButton.visible = false;
            this.m.playerInfo.kickButton.visible = false;
            this.m.playerInfo.kickBg.visible = false;
            if (Main.guildOwner == 1) {
                if (ret.guildId == 0) {
                    this.m.playerInfo.inviteButton.visible = true;
                    this.m.playerInfo.inviteButton.addEventListener(MouseEvent.CLICK, this.clickInvite, false, 0, true);
                }
                if (ret.guildId == Main.guild) {
                    this.m.playerInfo.kickButton.visible = true;
                    this.m.playerInfo.kickBg.visible = true;
                    this.m.playerInfo.kickButton.addEventListener(MouseEvent.CLICK, this.clickKick, false, 0, true);
                }
            }
            this.m.playerInfo.messageButton.addEventListener(MouseEvent.CLICK, this.clickSendPM, false, 0, true);
            this.m.playerInfo.levelsButton.addEventListener(MouseEvent.CLICK, this.clickViewLevels, false, 0, true);
            if (ret.friend == 1) {
                this.m.playerInfo.friendButton.label = "Remove Friend";
                this.m.playerInfo.friendButton.addEventListener(MouseEvent.CLICK, this.clickRemoveFriend, false, 0, true);
            } else {
                this.m.playerInfo.friendButton.label = "Add to Friends";
                this.m.playerInfo.friendButton.addEventListener(MouseEvent.CLICK, this.clickAddFriend, false, 0, true);
            }
            if (ret.ignored == 1) {
                this.m.playerInfo.ignoreButton.label = "Un-Ignore";
                this.m.playerInfo.ignoreButton.addEventListener(MouseEvent.CLICK, this.clickUnIgnore, false, 0, true);
            } else {
                this.m.playerInfo.ignoreButton.label = "Ignore";
                this.m.playerInfo.ignoreButton.addEventListener(MouseEvent.CLICK, this.clickIgnore, false, 0, true);
            }
            if (Main.group <= 0) {
                this.m.playerInfo.friendButton.enabled = false;
                this.m.playerInfo.ignoreButton.enabled = false;
                this.m.playerInfo.messageButton.enabled = false;
            }
            this.m.playerInfo.visible = true;
            this.m.loadingGraphic.visible = false;
        }

        // method_419 = clickInvite
        private function clickInvite(e:MouseEvent)
        {
            this.handleURL(Main.baseURL + "/guild_invite.php");
        }

        // method_231 = clickKick
        private function clickKick(e:MouseEvent)
        {
            this.handleURL(Main.baseURL + "/guild_kick.php");
        }

        // method_288 = clickSendPM
        private function clickSendPM(e:MouseEvent)
        {
            new SendMessagePopup(this.userName);
            startFadeOut();
        }

        // method_356 = clickAddFriend
        private function clickAddFriend(e:MouseEvent)
        {
            this.handleURL(Main.baseURL + "/add_friend.php");
        }

        // method_391 = clickRemoveFriend
        private function clickRemoveFriend(e:MouseEvent)
        {
            this.handleURL(Main.baseURL + "/remove_friend.php");
        }

        // method_257 = clickIgnore
        private function clickIgnore(e:MouseEvent)
        {
            this.handleURL(Main.baseURL + "/ignore_user.php");
            Main.socket.write("ignore_user`" + this.userName);
        }

        // method_385 = clickUnIgnore
        private function clickUnIgnore(e:MouseEvent)
        {
            this.handleURL(Main.baseURL + "/un_ignore_user.php");
            Main.socket.write("un_ignore_user`" + this.userName);
        }

        // method_404 = clickViewLevels
        private function clickViewLevels(e:MouseEvent)
        {
			if (LobbyRight.lobbyRight != null) {
                LobbyRight.lobbyRight.lookupUser(this.userName);
			}
			if (GuildPopup.instance != null) {
			    GuildPopup.instance.startFadeOut();
			}
            if (PartPopup.instance != null) {
                PartPopup.instance.startFadeOut();
            }
            if (PartInfoPopup.instance != null) {
                PartInfoPopup.instance.startFadeOut();
            }
            startFadeOut();
        }

        // method_292 = clickClose
        private function clickClose(e:*)
        {
            startFadeOut();
        }

        // _loc3 = vars
        // _loc4 = request
        // method_56 = handleURL
        private function handleURL(url:String)
        {
            var vars:URLVariables = new URLVariables();
            vars.target_name = this.userName;
            vars.user_id = this.userId;
            var request:URLRequest = new URLRequest(url);
            request.method = URLRequestMethod.POST;
            request.data = vars;
            new UploadingPopup(request, 'json');
            startFadeOut();
        }

        override public function remove()
        {
            if (PlayerPopup.instance === this) {
                PlayerPopup.instance = null;
            }
            this.m.playerInfo.messageButton.removeEventListener(MouseEvent.CLICK, this.clickSendPM);
            this.m.playerInfo.levelsButton.removeEventListener(MouseEvent.CLICK, this.clickViewLevels);
            this.m.playerInfo.friendButton.removeEventListener(MouseEvent.CLICK, this.clickAddFriend);
            this.m.playerInfo.friendButton.removeEventListener(MouseEvent.CLICK, this.clickRemoveFriend);
            this.m.playerInfo.ignoreButton.removeEventListener(MouseEvent.CLICK, this.clickIgnore);
            this.m.playerInfo.ignoreButton.removeEventListener(MouseEvent.CLICK, this.clickUnIgnore);
            this.m.playerInfo.inviteButton.removeEventListener(MouseEvent.CLICK, this.clickInvite);
            this.m.playerInfo.kickButton.removeEventListener(MouseEvent.CLICK, this.clickKick);
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            if (this.banMenu != null) {
                this.banMenu.remove();
                this.banMenu = null;
            }
            if (this.adminMenu != null) {
                this.adminMenu.remove();
                this.adminMenu = null;
            }
            if (this.tempModMenu != null) {
                this.tempModMenu.remove();
                this.tempModMenu = null;
            }
            if (this.guildName != null) {
                this.guildName.remove();
                this.guildName = null;
            }
            removeChild(this.m);
            this.m = null;
            this.superLoader.remove();
            super.remove();
        }


    }
}//package package_4

