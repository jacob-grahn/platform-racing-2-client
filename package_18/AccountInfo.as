// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_18.AccountInfo = package_18.class_260

package package_18
{
    import page.Page;
    import package_8.Character;
    import ui.StatsSelect;
    import flash.display.Stage;
    import ui.GuildName;
    import data.CommandHandler;
    import data.class_28;
    import flash.events.KeyboardEvent;
    import flash.display.Sprite;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldType;
    import flash.events.Event;

    public class AccountInfo extends Page
    {

        public static var currentHat:int;

        private var character:Character; // var_5
        private var statsSelect:StatsSelect; // var_158
        private var var_190:CharacterDisplay;
        private var stageRef:Stage = Main.stage;
        private var m:AccountInfoGraphic = new AccountInfoGraphic();
        private var rankTokensUsed:int = 0; // var_117
        private var rankTokensAvailable:int = 0; // var_439
        private var rank:int = 0;
        private var guildName:GuildName; // guildName
        private var var_510:int = 65;
        private var var_635:int = 95;
        private var customizeInfo:String; // var_566

        public function AccountInfo()
        {
            CommandHandler.commandHandler.defineCommand("setCustomizeInfo", this.setCustomizeInfo);
            Main.socket.write("get_customize_info`");
            Main.instance.addEventListener(Main.accountChange, this.getCustomizeInfo, false, 0, true);
            Main.stage.addEventListener(KeyboardEvent.KEY_DOWN, this.keyDownHandler, false, 0, true);
            Main.stage.focus = Main.stage;
        }

        // _loc2 = hatColor
        // _loc3 = headColor
        // _loc4 = bodyColor
        // _loc5 = feetColor
        // _loc6 = hat
        // _loc7 = head
        // _loc8 = body
        // _loc9 = feet
        // _loc10 = hatArray
        // _loc11 = headArray
        // _loc12 = bodyArray
        // _loc13 = feetArray
        // _loc14 = speed
        // _loc15 = accel
        // _loc16 = jumpn
        // _loc17 = hatColor2
        // _loc18 = headColor2
        // _loc19 = bodyColor2
        // _loc20 = feetColor2
        // _loc21 = epicHats
        // _loc22 = epicHeads
        // _loc23 = epicBodies
        // _loc24 = epicFeet
        public function setCustomizeInfo(a:Array)
        {
            var hatColor:int = int(a[0]);
            var headColor:int = int(a[1]);
            var bodyColor:int = int(a[2]);
            var feetColor:int = int(a[3]);
            var hat:int = int(a[4]);
            var head:int = int(a[5]);
            var body:int = int(a[6]);
            var feet:int = int(a[7]);
            var hatArray:Array = this.parsePartArray(a[8]);
            var headArray:Array = this.parsePartArray(a[9]);
            var bodyArray:Array = this.parsePartArray(a[10]);
            var feetArray:Array = this.parsePartArray(a[11]);
            var speed:int = int(a[12]);
            var accel:int = int(a[13]);
            var jumpn:int = int(a[14]);
            this.rank = int(a[15]);
            this.rankTokensUsed = int(a[16]);
            this.rankTokensAvailable = int(a[17]);
            var hatColor2:int = int(a[18]);
            var headColor2:int = int(a[19]);
            var bodyColor2:int = int(a[20]);
            var feetColor2:int = int(a[21]);
            var epicHats:Array = this.parsePartArray(a[22]);
            var epicHeads:Array = this.parsePartArray(a[23]);
            var epicBodies:Array = this.parsePartArray(a[24]);
            var epicFeet:Array = this.parsePartArray(a[25]);
            var isHappyHour:Boolean = Boolean(int(a[26]));
            this.m.nameBox.htmlText = "Welcome, <b>" + class_28.escapeString(Main.loggedInAs) + "</b>";
            this.m.hatBox.htmlText = "Hats: <b>" + (hatArray.length - 1) + "</b>";
            this.updateRankText();
            this.reset();
            if (Main.guild == 0) {
                this.m.guildBox.htmlText = "Guild: <b>none</b>";
            } else {
                this.m.guildBox.htmlText = "Guild: ";
                this.guildName = new GuildName(Main.guild, Main.guildName, Main.emblem, true);
                this.guildName.makeWidth(145);
                this.guildName.x = 40;
                this.guildName.y = 54;
                this.m.addChild(this.guildName);
            }
            this.character = new Character(hat, head, body, feet);
            var _local_25:Sprite = new Sprite();
            _local_25.addChild(this.character);
            _local_25.x = 80;
            _local_25.y = (140 + 42);
            _local_25.scaleX = (_local_25.scaleY = 1.5);
            addChild(_local_25);
            var availableStats:int = isHappyHour ? 300 : 150 + this.rank;
            this.statsSelect = new StatsSelect(availableStats, speed, accel, jumpn, null);
            this.statsSelect.x = 20;
            this.statsSelect.y = 207;
            addChild(this.statsSelect);
            this.var_190 = new CharacterDisplay(this.character, hatArray, headArray, bodyArray, feetArray, hat, head, body, feet, hatColor, headColor, bodyColor, feetColor, epicHats, epicHeads, epicBodies, epicFeet, hatColor2, headColor2, bodyColor2, feetColor2);
            this.var_190.x = 23;
            this.var_190.y = (58 + 37);
            addChild(this.var_190);
            this.m.rankTokenUp_bt.buttonMode = true;
            this.m.rankTokenUp_bt.useHandCursor = true;
            this.m.rankTokenUp_bt.addEventListener(MouseEvent.CLICK, this.clickRankTokenUp, false, 0, true); // this.m.var_159
            this.m.rankTokenDown_bt.buttonMode = true;
            this.m.rankTokenDown_bt.useHandCursor = true;
            this.m.rankTokenDown_bt.addEventListener(MouseEvent.CLICK, this.clickRankTokenDown, false, 0, true); // this.m.var_115
            this.m.loadouts_bt.addEventListener(MouseEvent.CLICK, this.clickLoadouts, false, 0, true); // this.m.var_533
            this.updatePosRankTokenButtons();
            this.stageRef.addEventListener(MouseEvent.MOUSE_UP, this.update, false, 0, true);
            addChild(this.m);
        }

        // removed _loc2 (originally was an if/else w/ _loc2 being declared as an array type beforehand, simplified to if and returns)
        // method_34 = parsePartArray
        private function parsePartArray(s:String):Array
        {
            if (s != null && s != "") {
                return s.split(",");
            }
            return new Array();
        }

        // _loc1 = unusedTokens
        // method_148 = updatePosRankTokenButtons
        private function updatePosRankTokenButtons()
        {
            var unusedTokens:int = this.rankTokensAvailable - this.rankTokensUsed;
            this.m.rankTokenUp_bt.visible = false;
            this.m.rankTokenDown_bt.visible = false;
            if (unusedTokens > 0) {
                this.m.rankTokenUp_bt.visible = true;
                this.m.rankTokenUp_bt.textBox.text = unusedTokens.toString();
                this.m.rankTokenUp_bt.x = this.var_510;
            }
            if (this.rankTokensUsed > 0) {
                this.m.rankTokenDown_bt.visible = true;
                this.m.rankTokenDown_bt.arrow.rotation = 180;
                this.m.rankTokenDown_bt.textBox.text = this.rankTokensUsed.toString();
                if (this.m.rankTokenUp_bt.visible) {
                    this.m.rankTokenDown_bt.x = this.var_635;
                } else {
                    this.m.rankTokenDown_bt.x = this.var_510;
                }
            }
        }

        // method_194 = updateRankText
        private function updateRankText()
        {
            this.m.rankBox.htmlText = "Rank: <b>" + this.rank + "</b>";
        }

        // _loc2 = c
        // _loc3 = partInfo
        // _loc4 = sendStr
        private function update(_arg_1:MouseEvent)
        {
            var c:Character = this.character;
            var partInfo:String = c.hat1Color + "`" + c.headColor + "`" + c.bodyColor + "`" + c.feetColor + "`" + c.hat1Color2 + "`" + c.headColor2 + "`" + c.bodyColor2 + "`" + c.feetColor2 + "`" + c.hat1 + "`" + c.head + "`" + c.body + "`" + c.feet;
            var sendStr:String = "set_customize_info`" + partInfo + "`" + this.statsSelect.getInfoStr();
            if (sendStr != this.customizeInfo) {
                Main.socket.write(sendStr);
                this.customizeInfo = sendStr;
            }
        }

        // method_298 = clickRankTokenUp
        private function clickRankTokenUp(e:MouseEvent)
        {
            if (this.rankTokensUsed < this.rankTokensAvailable) {
                this.rankTokensUsed++;
                this.rank++;
                Main.socket.write("use_rank_token`");
                Main.socket.write("get_customize_info`");
            }
            this.updateRankText();
            this.updatePosRankTokenButtons();
        }

        // method_221 = clickRankTokenDown
        private function clickRankTokenDown(e:MouseEvent)
        {
            if (this.rankTokensUsed > 0) {
                this.rankTokensUsed--;
                this.rank--;
                Main.socket.write("unuse_rank_token`");
                Main.socket.write("get_customize_info`");
            }
            this.updateRankText();
            this.updatePosRankTokenButtons();
        }

        // _loc2 = e.keyCode
        // _loc3 = presetNum
        // _loc4 = applyPreset
        // _loc5 = textBox
        // _loc6 = preset
        private function keyDownHandler(e:KeyboardEvent)
        {
            var presetNum:int = -1;
            var applyPreset:Boolean = true;
            if (e.keyCode == 49 || e.keyCode == 97) {
                presetNum = 1;
            } else if (e.keyCode == 50 || e.keyCode == 98) {
                presetNum = 2;
            } else if (e.keyCode == 51 || e.keyCode == 99) {
                presetNum = 3;
            }
            if (e.target is TextField) {
                var textBox:TextField = e.target as TextField;
                if (textBox.type === TextFieldType.INPUT) {
                    applyPreset = false; // preserve manually typing stats in textboxes (instead of using slider)
                }
            }
            if (presetNum != -1 && applyPreset) {
                var preset:Preset = Presets.getPreset(presetNum);
                Presets.apply(preset, this.character, this.statsSelect, this.var_190);
            }
        }

        // method_331 = clickLoadouts
        private function clickLoadouts(e:MouseEvent)
        {
            new LoadoutsPopup(this.character, this.statsSelect, this.var_190);
        }

        private function reset()
        {
            if (this.character != null) {
                this.statsSelect.remove();
                this.var_190.remove();
                this.character.remove();
                this.character = null;
                this.var_190 = null;
                this.statsSelect = null;
            }
            if (this.guildName != null) {
                this.guildName.remove();
                this.guildName = null;
            }
        }

        // method_284 = getCustomizeInfo
        private function getCustomizeInfo(e:Event)
        {
            this.reset();
            Main.socket.write("get_customize_info`");
        }

        override public function remove()
        {
            Main.instance.removeEventListener(Main.accountChange, this.getCustomizeInfo);
            Main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.keyDownHandler);
            this.m.rankTokenUp_bt.removeEventListener(MouseEvent.CLICK, this.clickRankTokenUp);
            this.m.rankTokenDown_bt.removeEventListener(MouseEvent.CLICK, this.clickRankTokenDown);
            this.m.loadouts_bt.removeEventListener(MouseEvent.CLICK, this.clickLoadouts);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.update);
            CommandHandler.commandHandler.defineCommand("setCustomizeInfo", null);
            this.reset();
            super.remove();
        }


    }
}//package package_18
