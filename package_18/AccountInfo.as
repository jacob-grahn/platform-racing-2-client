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

        private var var_5:Character;
        private var var_158:StatsSelect;
        private var var_190:class_262;
        private var stageRef:Stage = Main.stage;
        private var m:AccountInfoGraphic = new AccountInfoGraphic();
        private var rankTokensUsed:int = 0; // var_117
        private var rankTokensAvailable:int = 0; // var_439
        private var rank:int = 0;
        private var guildName:GuildName; // guildName
        private var var_510:int = 65;
        private var var_635:int = 95;
        private var var_566:String;

        public function AccountInfo()
        {
            CommandHandler.commandHandler.defineCommand("setCustomizeInfo", this.setCustomizeInfo);
            Main.socket.write("get_customize_info`");
            Main.instance.addEventListener(Main.accountChange, this.method_284, false, 0, true);
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
            var hatArray:Array = this.method_34(a[8]);
            var headArray:Array = this.method_34(a[9]);
            var bodyArray:Array = this.method_34(a[10]);
            var feetArray:Array = this.method_34(a[11]);
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
            var epicHats:Array = this.method_34(a[22]);
            var epicHeads:Array = this.method_34(a[23]);
            var epicBodies:Array = this.method_34(a[24]);
            var epicFeet:Array = this.method_34(a[25]);
            var isHappyHour:Boolean = Boolean(int(a[26]));
            this.m.nameBox.htmlText = "Welcome, <b>" + class_28.escapeString(Main.loggedInAs) + "</b>";
            this.m.hatBox.htmlText = "Hats: <b>" + (hatArray.length - 1) + "</b>";
            this.method_194();
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
            this.var_5 = new Character(hat, head, body, feet);
            var _local_25:Sprite = new Sprite();
            _local_25.addChild(this.var_5);
            _local_25.x = 80;
            _local_25.y = (140 + 42);
            _local_25.scaleX = (_local_25.scaleY = 1.5);
            addChild(_local_25);
            var availableStats:int = isHappyHour ? 300 : 150 + this.rank;
            this.var_158 = new StatsSelect(availableStats, speed, accel, jumpn, null);
            this.var_158.x = 20;
            this.var_158.y = 207;
            addChild(this.var_158);
            this.var_190 = new class_262(this.var_5, hatArray, headArray, bodyArray, feetArray, hat, head, body, feet, hatColor, headColor, bodyColor, feetColor, epicHats, epicHeads, epicBodies, epicFeet, hatColor2, headColor2, bodyColor2, feetColor2);
            this.var_190.x = 23;
            this.var_190.y = (58 + 37);
            addChild(this.var_190);
            this.m.var_159.buttonMode = true;
            this.m.var_159.useHandCursor = true;
            this.m.var_159.addEventListener(MouseEvent.CLICK, this.method_298, false, 0, true);
            this.m.var_115.buttonMode = true;
            this.m.var_115.useHandCursor = true;
            this.m.var_115.addEventListener(MouseEvent.CLICK, this.method_221, false, 0, true);
            this.m.var_533.addEventListener(MouseEvent.CLICK, this.method_331, false, 0, true);
            this.method_148();
            this.stageRef.addEventListener(MouseEvent.MOUSE_UP, this.update, false, 0, true);
            addChild(this.m);
        }

        private function method_34(_arg_1:String):Array
        {
            var _local_2:Array;
            if (_arg_1 != null && _arg_1 != "") {
                _local_2 = _arg_1.split(",");
            } else {
                _local_2 = new Array();
            }
            return (_local_2);
        }

        private function method_148()
        {
            var _local_1:int = (this.rankTokensAvailable - this.rankTokensUsed);
            this.m.var_159.visible = false;
            this.m.var_115.visible = false;
            if (_local_1 > 0) {
                this.m.var_159.visible = true;
                this.m.var_159.textBox.text = _local_1.toString();
                this.m.var_159.x = this.var_510;
            }
            if (this.rankTokensUsed > 0) {
                this.m.var_115.visible = true;
                this.m.var_115.arrow.rotation = 180;
                this.m.var_115.textBox.text = this.rankTokensUsed.toString();
                if (this.m.var_159.visible) {
                    this.m.var_115.x = this.var_635;
                } else {
                    this.m.var_115.x = this.var_510;
                }
            }
        }

        private function method_194()
        {
            this.m.rankBox.htmlText = "Rank: <b>" + this.rank + "</b>";
        }

        private function update(_arg_1:MouseEvent)
        {
            var _local_2:Character = this.var_5;
            var _local_3:String = _local_2.hat1Color + "`" + _local_2.headColor + "`" + _local_2.bodyColor + "`" + _local_2.feetColor + "`" + _local_2.hat1Color2 + "`" + _local_2.headColor2 + "`" + _local_2.bodyColor2 + "`" + _local_2.feetColor2 + "`" + _local_2.hat1 + "`" + _local_2.head + "`" + _local_2.body + "`" + _local_2.feet;
            var _local_4:String = "set_customize_info`" + _local_3 + "`" + this.var_158.getInfoStr();
            if (_local_4 != this.var_566) {
                Main.socket.write(_local_4);
                this.var_566 = _local_4;
            }
        }

        private function method_298(_arg_1:MouseEvent)
        {
            if (this.rankTokensUsed < this.rankTokensAvailable) {
                this.rankTokensUsed++;
                this.rank++;
                Main.socket.write("use_rank_token`");
                Main.socket.write("get_customize_info`");
            }
            this.method_194();
            this.method_148();
        }

        private function method_221(_arg_1:MouseEvent)
        {
            if (this.rankTokensUsed > 0) {
                this.rankTokensUsed--;
                this.rank--;
                Main.socket.write("unuse_rank_token`");
                Main.socket.write("get_customize_info`");
            }
            this.method_194();
            this.method_148();
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
                Presets.apply(preset, this.var_5, this.var_158, this.var_190);
            }
        }

        private function method_331(_arg_1:MouseEvent)
        {
            new LoadoutsPopup(this.var_5, this.var_158, this.var_190);
        }

        private function reset()
        {
            if (this.var_5 != null) {
                this.var_158.remove();
                this.var_190.remove();
                this.var_5.remove();
                this.var_5 = null;
                this.var_190 = null;
                this.var_158 = null;
            }
            if (this.guildName != null) {
                this.guildName.remove();
                this.guildName = null;
            }
        }

        private function method_284(_arg_1:Event)
        {
            this.reset();
            Main.socket.write("get_customize_info`");
        }

        override public function remove()
        {
            Main.instance.removeEventListener(Main.accountChange, this.method_284);
            Main.stage.removeEventListener(KeyboardEvent.KEY_DOWN, this.keyDownHandler);
            this.m.var_159.removeEventListener(MouseEvent.CLICK, this.method_298);
            this.m.var_115.removeEventListener(MouseEvent.CLICK, this.method_221);
            this.m.var_533.removeEventListener(MouseEvent.CLICK, this.method_331);
            this.stageRef.removeEventListener(MouseEvent.MOUSE_UP, this.update);
            CommandHandler.commandHandler.defineCommand("setCustomizeInfo", null);
            this.reset();
            super.remove();
        }


    }
}//package package_18
