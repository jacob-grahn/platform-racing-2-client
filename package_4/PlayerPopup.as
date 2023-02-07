// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_4.PlayerPopup = package_4.class_148

package package_4
{
    import com.jiggmin.data.CommandHandler;
    import com.jiggmin.data.Data;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.net.navigateToURL;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    import flash.text.TextFormat;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import lobby.LobbyRight;
    import package_6.ExpGain;
    import package_8.Character;
    import package_18.PartInfo.PartInfoPopup;
    import package_18.PartInfo.PartPopup;
    import ui.GuildName;

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
        private var userIdShown:Boolean = false;
        private var expGain:ExpGain;
        private var times:Array;
        private var cm:CommandHandler = CommandHandler.commandHandler;

        private var icons:Object = {
            hof: {
                target: this.m.playerInfo.hofIcon,
                title: 'Hall of Fame',
                desc: 'This player has been inducted into the Hall of Fame for their exceptional talent and dedication to the PR2 and Jiggmin community.',
                link: 'https://jiggmin2.com/forums/showthread.php?tid=4226'
            },
            verified: {
                target: this.m.playerInfo.verifiedIcon,
                title: 'Verified',
                desc: 'This account is verified due to its notability and prominence in the community.',
                link: 'https://jiggmin2.com/forums/showthread.php?tid=4227'
            }
        }

        private var hoverPopup:HoverPopup;
        private var hoverTimer:uint;

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

            // try to get player info from socket first
            this.cm.defineCommand("playerInfo", this.playerInfoFromSocket);
            Main.socket.write("get_player_info`" + name);

            // add privileged menus
            if (Main.group >= 2) {
                this.banMenu = new BanMenu(name, this);
                addChild(this.banMenu);
                this.banMenu.x = (this.banMenu.width / 2) + 39; //(this.banMenu.width / 2) + 3;
                this.m.x = this.m.x - 106; //-(this.m.width / 2) - 3;
                if (Main.group >= 3) {
                    this.m.x = -(this.m.width / 2) - 19.5; //this.m.x - 15;
                    this.banMenu.x = (this.banMenu.width / 2) - 19.5; //this.banMenu.x - 15;
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


        private function playerInfoFromSocket(a:Array)
        {
            this.cm.defineCommand("playerInfo", null);
            try {
                var ret:String = a[0];
                if (ret == 0) {
                    throw new Error();
                }
                var data:Object = JSON.parse(ret);
                this.applyReturnData(data);
            } catch (e:Error) {
                this.superLoader = new SuperLoader(true, SuperLoader.j);
                var vars:URLVariables = new URLVariables();
                vars.name = this.userName;
                var request:URLRequest = new URLRequest(Main.baseURL + "/get_player_info.php");
                request.data = vars;
                this.superLoader.load(request);
                this.superLoader.addEventListener(SuperLoader.d, this.playerInfoFromHTTP, false, 0, true);
                this.superLoader.addEventListener(SuperLoader.e, this.clickClose, false, 0, true);
            }
        }

        private function playerInfoFromHTTP(e:Event)
        {
            this.applyReturnData(SuperLoader(e.target).parsedData);
        }

        /*private function isPlayerTemp(a:Array)
        {
            this.userIsTemp = Boolean(int(a[0]));
            var group = int(a[1]);
            if (!this.userIsTemp && group == 1) {
                this.m.playerInfo.groupBox.text = 'Group: Member';
            }
        }*/

        // _loc2 = ret
        // _loc3 = regDate
        // _loc4 = group
        // _loc5 = groupText
        // method_281 = applyReturnData
        private function applyReturnData(ret:Object)
        {
            this.userId = int(ret.userId);
            var group:int = ret.group;
            if (group == 1) {
                if (ret.ca) {
                    groupText = 'Community Ambassador';
                    var tf:TextFormat = new TextFormat();
                    tf.size = 11;
                    this.m.playerInfo.groupBox.defaultTextFormat = tf;
                } else {
                    groupText = 'Member';
                }
            } else if (group == 2) {
                if (ret.temp_mod != null && ret.temp_mod == true) {
                    groupText = 'Temporary Moderator';
                } else if (ret.trial_mod == true) {
                    groupText = 'Trial Moderator';
                } else {
                    groupText = 'Moderator';
                }
            } else if (group == 3) {
                groupText = 'Admin';
            } else {
                PlayerPopup.instance.startFadeOut();
                new PlayerGuestPopup(this.userName);
                return;
            }
            if (Main.server.server_owner == this.userId) {
                groupText = 'Server Owner';
            }
            this.m.playerInfo.statusBox.text = ret.status;
            this.m.playerInfo.groupBox.text = groupText;
            this.m.playerInfo.verifiedIcon.visible = this.m.playerInfo.hofIcon.visible = false;
            if (ret.verified) {
                this.m.playerInfo.verifiedIcon.visible = this.m.playerInfo.verifiedIcon.buttonMode = this.m.playerInfo.verifiedIcon.useHandCursor = true;
                this.m.playerInfo.verifiedIcon.addEventListener(MouseEvent.CLICK, this.iconEvent, false, 0, true);
                this.m.playerInfo.verifiedIcon.addEventListener(MouseEvent.MOUSE_OVER, this.iconEvent, false, 0, true);
                this.m.playerInfo.verifiedIcon.addEventListener(MouseEvent.MOUSE_OUT, this.outHover, false, 0, true);
            }
            if (ret.hof) {
                this.m.playerInfo.hofIcon.visible = this.m.playerInfo.hofIcon.buttonMode = this.m.playerInfo.hofIcon.useHandCursor = true;
                this.m.playerInfo.hofIcon.addEventListener(MouseEvent.CLICK, this.iconEvent, false, 0, true);
                this.m.playerInfo.hofIcon.addEventListener(MouseEvent.MOUSE_OVER, this.iconEvent, false, 0, true);
                this.m.playerInfo.hofIcon.addEventListener(MouseEvent.MOUSE_OUT, this.outHover, false, 0, true);
                if (!ret.verified) {
                    this.m.playerInfo.hofIcon.x = -6;
                }
            }
            this.m.playerInfo.rankBox.text = ret.rank;
            this.m.playerInfo.rankBox.addEventListener(MouseEvent.MOUSE_OVER, this.mouseOverRankBox, false, 0, true);
            this.m.playerInfo.rankBox.addEventListener(MouseEvent.MOUSE_OUT, this.mouseOutRankBox, false, 0, true);
            this.m.playerInfo.hatBox.text = ret.hats;
            this.m.playerInfo.registerBox.text = ret.registerDate == 0 ? 'Age of Heroes' : Data.getShortDateStr(ret.registerDate);
            if (ret.registerDate != 0) {
                this.m.playerInfo.registerBox.addEventListener(MouseEvent.MOUSE_OVER, this.mouseOverRegisterBox, false, 0, true);
                this.m.playerInfo.registerBox.addEventListener(MouseEvent.MOUSE_OUT, this.mouseOutRegisterBox, false, 0, true);
            }
            this.m.playerInfo.activeBox.text = Data.getShortDateStr(ret.loginDate);
            this.m.playerInfo.activeBox.addEventListener(MouseEvent.MOUSE_OVER, this.mouseOverActiveBox, false, 0, true);
            this.m.playerInfo.activeBox.addEventListener(MouseEvent.MOUSE_OUT, this.mouseOutActiveBox, false, 0, true);
            this.times = [ret.registerDate, ret.loginDate];
            if (ret.guildId == 0) {
                this.m.playerInfo.guildBox.text = /*"Guild: */"none";
            } else {
                /*this.m.playerInfo.guildBox.htmlText = '<a href="event:guild`' + int(ret.guildId) + '">' + Data.cleanHTML(ret.guildName) + '</a>';
                var clickGuild:Function = function(e:MouseEvent) { new GuildPopup(ret.guildId) };
                this.m.playerInfo.guildBox.addEventListener(MouseEvent.CLICK, clickGuild, false, 0, true);*/
                //this.m.playerInfo.guildBox.text = "Guild:";
                this.m.playerInfo.removeChild(this.m.playerInfo.guildBox);
                this.guildName = new GuildName(ret.guildId, ret.guildName, ret.emblem, true, true);
                this.guildName.x = -40;
                this.guildName.y = 64;
                this.m.playerInfo.addChild(this.guildName);
            }
            var c:Character = new Character(ret.hat, ret.head, ret.body, ret.feet);
            this.m.playerInfo.addChild(c);
            c.setHatColors(ret.hatColor, ret.hatColor2);
            c.setHeadColors(ret.headColor, ret.headColor2);
            c.setBodyColors(ret.bodyColor, ret.bodyColor2);
            c.setFeetColors(ret.feetColor, ret.feetColor2);
            c.scaleX = c.scaleY = 2;
            c.x = -75;
            c.y = 135;
            this.m.playerInfo.supplBg.visible = false;
            this.expGain = new ExpGain();
            this.expGain.x = this.m.playerInfo.x;
            this.expGain.y = this.m.playerInfo.supplBg.y + 3;
            this.expGain.start(ret.exp_points, ret.exp_points, ret.exp_to_rank);
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
            this.m.playerInfo.messageButton.addEventListener(MouseEvent.MOUSE_OVER, this.overSendPMBt, false, 0, true);
            this.m.playerInfo.messageButton.addEventListener(MouseEvent.MOUSE_OUT, this.outHover, false, 0, true);
            this.m.playerInfo.messageButton.addEventListener(MouseEvent.CLICK, this.clickSendPM, false, 0, true);
            this.m.playerInfo.levelsButton.addEventListener(MouseEvent.CLICK, this.clickViewLevels, false, 0, true);
            if (ret.following == 1) {
                this.m.playerInfo.followButton.label = "Unfollow";
                this.m.playerInfo.followButton.addEventListener(MouseEvent.CLICK, this.clickUnfollow, false, 0, true);
            } else {
                this.m.playerInfo.followButton.label = "Follow";
                this.m.playerInfo.followButton.addEventListener(MouseEvent.CLICK, this.clickFollow, false, 0, true);
            }
            if (ret.friend == 1) {
                this.m.playerInfo.friendButton.label = "Remove Friend";
                this.m.playerInfo.friendButton.addEventListener(MouseEvent.CLICK, this.clickRemoveFriend, false, 0, true);
            } else {
                this.m.playerInfo.friendButton.label = "Add to Friends";
                this.m.playerInfo.friendButton.addEventListener(MouseEvent.CLICK, this.clickAddFriend, false, 0, true);
            }
            if (ret.ignored == 1) {
                this.m.playerInfo.ignoreButton.label = "Unignore";
                this.m.playerInfo.ignoreButton.addEventListener(MouseEvent.CLICK, this.clickUnignore, false, 0, true);
            } else {
                this.m.playerInfo.ignoreButton.label = "Ignore";
                this.m.playerInfo.ignoreButton.addEventListener(MouseEvent.CLICK, this.clickIgnore, false, 0, true);
            }
            if (Main.group <= 0) {
                this.m.playerInfo.followButton.enabled = false;
                this.m.playerInfo.friendButton.enabled = false;
                this.m.playerInfo.ignoreButton.enabled = false;
            }
            this.m.playerInfo.visible = true;
            this.m.loadingGraphic.visible = false;
            Main.stage.addEventListener(KeyboardEvent.KEY_DOWN, this.toggleUserIdShown, false, 0, true);
            Main.stage.focus = Main.stage;
        }

        private function iconEvent(e:MouseEvent)
        {
            var icon:Object;
            for each (var i:Object in this.icons) {
                if (e.target === i.target) {
                    icon = i;
                }
            }

            if (e.type === MouseEvent.MOUSE_OVER) {
                this.hoverPopup = new HoverPopup(icon.title, icon.desc + ' Click for more information.', icon.target);
            } else if (e.type === MouseEvent.CLICK) {
                navigateToURL(new URLRequest(icon.link), "_blank");
            }
        }

        private function mouseOverRankBox(e:MouseEvent)
        {
            this.m.playerInfo.supplBg.visible = true;
            this.m.playerInfo.addChild(this.expGain);
        }

        private function mouseOutRankBox(e:MouseEvent)
        {
            this.m.playerInfo.supplBg.visible = false;
            this.m.playerInfo.removeChild(this.expGain);
        }

        private function mouseOverRegisterBox(e:MouseEvent)
        {
            this.m.playerInfo.supplBg.visible = true;
            this.m.playerInfo.supplText.text = Data.getDateTimeStr(times[0], ['long', 'medium']);
        }

        private function mouseOutRegisterBox(e:MouseEvent)
        {
            this.m.playerInfo.supplText.text = '';
            this.m.playerInfo.supplBg.visible = false;
        }

        private function mouseOverActiveBox(e:MouseEvent)
        {
            this.m.playerInfo.supplBg.visible = true;
            this.m.playerInfo.supplText.text = Data.getDateTimeStr(times[1], ['long', 'medium']);
        }

        private function mouseOutActiveBox(e:MouseEvent)
        {
            this.m.playerInfo.supplText.text = '';
            this.m.playerInfo.supplBg.visible = false;
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
            startFadeOut();
            new SendMessagePopup(this.userName);
        }

        private function clickFollow(e:MouseEvent)
        {
            this.handleUserListURL('following', 'add');
            Main.socket.write("follow_user`" + this.userName);
        }

        private function clickUnfollow(e:MouseEvent)
        {
            this.handleUserListURL('following', 'remove');
            Main.socket.write("unfollow_user`" + this.userName);
        }

        // method_356 = clickAddFriend
        private function clickAddFriend(e:MouseEvent)
        {
            this.handleUserListURL('friends', 'add');
            Main.socket.write("add_friend`" + this.userName);
        }

        // method_391 = clickRemoveFriend
        private function clickRemoveFriend(e:MouseEvent)
        {
            this.handleUserListURL('friends', 'remove');
            Main.socket.write("remove_friend`" + this.userName);
        }

        // method_257 = clickIgnore
        private function clickIgnore(e:MouseEvent)
        {
            this.handleUserListURL('ignored', 'add');
            Main.socket.write("ignore_user`" + this.userName);
        }

        // method_385 = clickUnignore
        private function clickUnignore(e:MouseEvent)
        {
            this.handleUserListURL('ignored', 'remove');
            Main.socket.write("unignore_user`" + this.userName);
        }

        private function overSendPMBt(e:MouseEvent)
        {
            this.hoverTimer = setTimeout(function() {
                hoverPopup = new HoverPopup('Send PM', 'Send a PM to this player.', m.playerInfo.messageButton);
            }, 500);
        }

        private function outHover(e:MouseEvent = null)
        {
            clearTimeout(this.hoverTimer);
            if (this.hoverPopup != null) {
                this.hoverPopup.remove();
                this.hoverPopup = null;
            }
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
            if (LevelInfoPopup.instance != null) {
                LevelInfoPopup.instance.startFadeOut();
            }
            startFadeOut();
        }

        // method_292 = clickClose
        private function clickClose(e:*)
        {
            startFadeOut();
        }

        private function handleUserListURL(list:String, mode:String)
        {
            var url:String = Main.baseURL + "/user_list_modify.php";
            var vars:URLVariables = new URLVariables();
            vars.target_id = this.userId;
            vars.list = list;
            vars.mode = mode;
            var request:URLRequest = new URLRequest(url);
            request.method = URLRequestMethod.POST;
            request.data = vars;
            new UploadingPopup(request, 'json');
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

        private function toggleUserIdShown(e:KeyboardEvent)
        {
            if (e.keyCode !== 16 || e.type !== KeyboardEvent.KEY_DOWN) {
                return;
            }
            this.m.nameBox.text = !this.userIdShown ? '-- User ID: ' + this.userId + ' --' : '-- ' + this.userName + ' --';
            this.userIdShown = !this.userIdShown;
        }

        override public function remove()
        {
            if (PlayerPopup.instance === this) {
                PlayerPopup.instance = null;
            }
            Main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.toggleUserIdShown);
            this.m.playerInfo.rankBox.removeEventListener(MouseEvent.MOUSE_OVER, this.mouseOverRankBox);
            this.m.playerInfo.rankBox.removeEventListener(MouseEvent.MOUSE_OUT, this.mouseOutRankBox);
            this.m.playerInfo.registerBox.removeEventListener(MouseEvent.MOUSE_OVER, this.mouseOverRegisterBox);
            this.m.playerInfo.registerBox.removeEventListener(MouseEvent.MOUSE_OUT, this.mouseOutRegisterBox);
            this.m.playerInfo.activeBox.removeEventListener(MouseEvent.MOUSE_OVER, this.mouseOverActiveBox);
            this.m.playerInfo.activeBox.removeEventListener(MouseEvent.MOUSE_OUT, this.mouseOutActiveBox);
            this.m.playerInfo.messageButton.removeEventListener(MouseEvent.MOUSE_OVER, this.overSendPMBt);
            this.m.playerInfo.messageButton.removeEventListener(MouseEvent.MOUSE_OUT, this.outHover);
            this.m.playerInfo.messageButton.removeEventListener(MouseEvent.CLICK, this.clickSendPM);
            this.m.playerInfo.levelsButton.removeEventListener(MouseEvent.CLICK, this.clickViewLevels);
            this.m.playerInfo.followButton.removeEventListener(MouseEvent.CLICK, this.clickFollow);
            this.m.playerInfo.followButton.removeEventListener(MouseEvent.CLICK, this.clickUnfollow);
            this.m.playerInfo.friendButton.removeEventListener(MouseEvent.CLICK, this.clickAddFriend);
            this.m.playerInfo.friendButton.removeEventListener(MouseEvent.CLICK, this.clickRemoveFriend);
            this.m.playerInfo.ignoreButton.removeEventListener(MouseEvent.CLICK, this.clickIgnore);
            this.m.playerInfo.ignoreButton.removeEventListener(MouseEvent.CLICK, this.clickUnignore);
            this.m.playerInfo.inviteButton.removeEventListener(MouseEvent.CLICK, this.clickInvite);
            this.m.playerInfo.kickButton.removeEventListener(MouseEvent.CLICK, this.clickKick);
            this.m.close_bt.removeEventListener(MouseEvent.CLICK, this.clickClose);
            clearTimeout(this.hoverTimer);
            this.outHover();
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
            this.cm.defineCommand("playerInfo", null);
            this.cm = null;
            if (this.superLoader != null) {
                this.superLoader.remove();
            }
            super.remove();
        }


    }
}//package package_4

