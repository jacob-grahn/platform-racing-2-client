// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_18.AccountInfo = package_18.class_260

package package_18
{
    import com.jiggmin.data.Data;
    import com.jiggmin.data.class_33;
    import com.jiggmin.data.CommandHandler;
    import flash.display.Sprite;
    import flash.display.Stage;
    import flash.events.Event;
    import flash.events.KeyboardEvent;
    import flash.events.MouseEvent;
    import flash.text.TextField;
    import flash.text.TextFieldType;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import package_4.ConfirmPopup;
    import package_4.HoverPopup;
    import package_4.OutfitPopup;
    import package_4.Popup;
    import package_8.Character;
    import package_22.LevelListing;
    import page.Page;
    import ui.GuildName;
    import ui.StatsSelect;

    public class AccountInfo extends Page
    {

        public static const SET_MANUAL_PART:String = 'manualPart';

        public static var currentHat:int;
        public static var partToSet:Array;

        private var character:Character; // var_5
        private var statsSelect:StatsSelect; // var_158
        private var playerDisplay:PlayerDisplay; // var_190
        private var stageRef:Stage = Main.stage;
        private var m:AccountInfoGraphic = new AccountInfoGraphic();
        private var rankTokensUsed:int = 0; // var_117
        private var rankTokensAvailable:int = 0; // var_439
        private var rank:int = 0;
        private var guildName:GuildName; // guildName
        private var var_510:int = 65;
        private var var_635:int = 95;
        private var customizeInfo:String; // var_566
        private var loadoutsHover:HoverPopup;
        private var loadoutsHoverTimer:uint;

        public function AccountInfo()
        {
            CommandHandler.commandHandler.defineCommand("setCustomizeInfo", this.setCustomizeInfo);
            Main.socket.write("get_customize_info`");
            Main.instance.addEventListener(Main.accountChange, this.getCustomizeInfo, false, 0, true);
            Main.instance.addEventListener(SET_MANUAL_PART, this.update, false, 0, true);
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
            this.m.nameBox.htmlText = "Welcome, <b>" + Data.escapeString(Main.loggedInAs) + "</b>";
            this.m.hatBox.htmlText = "Hats: <b>" + (hatArray.length - 1) + "</b>";
            class_33.setNumber("userRank", this.rank);
            LevelListing.levelListing.dispatchEvent(new Event('testLevelAccess'));
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
            this.playerDisplay = new PlayerDisplay(this.character, hatArray, headArray, bodyArray, feetArray, hat, head, body, feet, hatColor, headColor, bodyColor, feetColor, epicHats, epicHeads, epicBodies, epicFeet, hatColor2, headColor2, bodyColor2, feetColor2);
            this.playerDisplay.x = 23;
            this.playerDisplay.y = (58 + 37);
            addChild(this.playerDisplay);
            this.m.rankTokenUp_bt.buttonMode = true;
            this.m.rankTokenUp_bt.useHandCursor = true;
            this.m.rankTokenUp_bt.addEventListener(MouseEvent.CLICK, this.clickRankTokenUp, false, 0, true); // this.m.var_159
            this.m.rankTokenDown_bt.buttonMode = true;
            this.m.rankTokenDown_bt.useHandCursor = true;
            this.m.rankTokenDown_bt.addEventListener(MouseEvent.CLICK, this.clickRankTokenDown, false, 0, true); // this.m.var_115
            this.m.loadouts_bt.addEventListener(MouseEvent.CLICK, this.loadoutsMouseEvent, false, 0, true); // this.m.var_533
            this.m.loadouts_bt.addEventListener(MouseEvent.MOUSE_OVER, this.loadoutsMouseEvent, false, 0, true);
            this.m.loadouts_bt.addEventListener(MouseEvent.MOUSE_OUT, this.loadoutsMouseEvent, false, 0, true);
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
        private function update(e:Event)
        {
            var c:Character = this.character;
            var hat:int = partToSet.length == 2 && partToSet[0] == 'hat' ? partToSet[1] : c.hat1;
            var head:int = partToSet.length == 2 && partToSet[0] == 'head' ? partToSet[1] : c.head;
            var body:int = partToSet.length == 2 && partToSet[0] == 'body' ? partToSet[1] : c.body;
            var feet:int = partToSet.length == 2 && partToSet[0] == 'feet' ? partToSet[1] : c.feet;
            var partInfo:String = c.hat1Color + "`" + c.headColor + "`" + c.bodyColor + "`" + c.feetColor + "`" + c.hat1Color2 + "`" + c.headColor2 + "`" + c.bodyColor2 + "`" + c.feetColor2 + "`" + hat + "`" + head + "`" + body + "`" + feet;
            var sendStr:String = "set_customize_info`" + partInfo + "`" + this.statsSelect.getInfoStr();
            if (sendStr != this.customizeInfo) {
                Main.socket.write(sendStr);
                this.customizeInfo = sendStr;
            }
            if (e.type == SET_MANUAL_PART) {
                this.getCustomizeInfo(e);
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
        private function keyDownHandler(e:KeyboardEvent, confirmed:Boolean = false)
        {
            if (Popup.getOpen().length > 0 || e.target is TextField) {
                e.preventDefault();
                return;
            }
            var presetNum:int = -1, preset:Preset;
            var applyPreset:Boolean = true;
            if ((e.keyCode >= 48 && e.keyCode <= 57) || (e.keyCode >= 96 && e.keyCode <= 105)) {
                presetNum = e.keyCode % 48;
                presetNum = presetNum == 0 ? 10 : presetNum;
                if (!confirmed) {
                    preset = Presets.getPreset(presetNum);
                    new OutfitPopup(function () {
                        keyDownHandler(e, true);
                    }, preset.getOutfitFormat(), 'Are you sure you want to apply this loadout? This will clear your current stats and character style.');
                    return;
                }
            }
            if (presetNum != -1 && applyPreset) {
                preset = Presets.getPreset(presetNum);
                Presets.apply(preset, this.character, this.statsSelect, this.playerDisplay);
            }
        }

        // method_331 = clickLoadouts -- changed to loadoutsMouseEvent in 161
        private function loadoutsMouseEvent(e:MouseEvent = null)
        {
            // remove popup if already exists
            if (this.loadoutsHover != null) {
                this.loadoutsHover.remove();
                this.loadoutsHover = null;
            }

            // if null, it's our trusty timeout cashing in
            clearTimeout(this.loadoutsHoverTimer); // clear timeout regardless
            if (e == null) {
                this.loadoutsHover = new HoverPopup('Loadouts', 'Save up to ' + Presets.NUM_PRESETS + ' of your favorite styles. Use the numbers on your keyboard for quick switching.', this.m.loadouts_bt);
                this.loadoutsHover.x += this.loadoutsHover.width + 27.5;
            }

            // stop here if from clearTimeout or mouseout
            if (e == null || e.type == MouseEvent.MOUSE_OUT) {
                return;
            }

            if (e.type == MouseEvent.CLICK) {
                new LoadoutsPopup(this.character, this.statsSelect, this.playerDisplay);
            } else if (e.type == MouseEvent.MOUSE_OVER) {
                this.loadoutsHoverTimer = setTimeout(this.loadoutsMouseEvent, 500);
            }
        }

        private function reset()
        {
            partToSet = [];
            if (this.character != null) {
                this.statsSelect.remove();
                this.playerDisplay.remove();
                this.character.remove();
                this.character = null;
                this.playerDisplay = null;
                this.statsSelect = null;
            }
            if (this.guildName != null) {
                this.guildName.remove();
                this.guildName = null;
            }
            this.loadoutsMouseEvent(new MouseEvent(MouseEvent.MOUSE_OUT));
        }

        // method_284 = getCustomizeInfo
        private function getCustomizeInfo(e:Event)
        {
            this.reset();
            Main.socket.write("get_customize_info`");
        }

        override public function remove()
        {
            clearTimeout(this.loadoutsHoverTimer);
            Main.instance.removeEventListener(Main.accountChange, this.getCustomizeInfo);
            Main.instance.removeEventListener(SET_MANUAL_PART, this.update);
            Main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.keyDownHandler);
            this.m.rankTokenUp_bt.removeEventListener(MouseEvent.CLICK, this.clickRankTokenUp);
            this.m.rankTokenDown_bt.removeEventListener(MouseEvent.CLICK, this.clickRankTokenDown);
            this.m.loadouts_bt.removeEventListener(MouseEvent.CLICK, this.loadoutsMouseEvent);
            this.m.loadouts_bt.removeEventListener(MouseEvent.MOUSE_OVER, this.loadoutsMouseEvent);
            this.m.loadouts_bt.removeEventListener(MouseEvent.MOUSE_OUT, this.loadoutsMouseEvent);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.update);
            CommandHandler.commandHandler.defineCommand("setCustomizeInfo", null);
            this.reset();
            super.remove();
        }


    }
}//package package_18
