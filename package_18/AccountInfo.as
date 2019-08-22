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
        private var var_117:int = 0;
        private var var_439:int = 0;
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

        public function setCustomizeInfo(_arg_1:Array)
        {
            var _local_2:int;
            var _local_3:int;
            var _local_4:int;
            var _local_5:int;
            var _local_6:int;
            var _local_7:int;
            var _local_8:int;
            var _local_9:int;
            var _local_10:Array;
            var _local_11:Array;
            var _local_12:Array;
            var _local_13:Array;
            var _local_14:int;
            var _local_17:int;
            var _local_18:int;
            var _local_21:Array;
            var _local_23:Array;
            var _local_24:Array;
            var _local_25:Sprite;
            _local_2 = int(_arg_1[0]);
            _local_3 = int(_arg_1[1]);
            _local_4 = int(_arg_1[2]);
            _local_5 = int(_arg_1[3]);
            _local_6 = int(_arg_1[4]);
            _local_7 = int(_arg_1[5]);
            _local_8 = int(_arg_1[6]);
            _local_9 = int(_arg_1[7]);
            _local_10 = this.method_34(_arg_1[8]);
            _local_11 = this.method_34(_arg_1[9]);
            _local_12 = this.method_34(_arg_1[10]);
            _local_13 = this.method_34(_arg_1[11]);
            _local_14 = int(_arg_1[12]);
            var _local_15:int = int(_arg_1[13]);
            var _local_16:int = int(_arg_1[14]);
            this.rank = int(_arg_1[15]);
            this.var_117 = int(_arg_1[16]);
            this.var_439 = int(_arg_1[17]);
            _local_17 = int(_arg_1[18]);
            _local_18 = int(_arg_1[19]);
            var _local_19:int = int(_arg_1[20]);
            var _local_20:int = int(_arg_1[21]);
            _local_21 = this.method_34(_arg_1[22]);
            var _local_22:Array = this.method_34(_arg_1[23]);
            _local_23 = this.method_34(_arg_1[24]);
            _local_24 = this.method_34(_arg_1[25]);
            this.m.nameBox.htmlText = "Welcome, <b>" + class_28.escapeString(Main.loggedInAs) + "</b>";
            this.m.hatBox.htmlText = "Hats: <b>" + (_local_10.length - 1) + "</b>";
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
            this.var_5 = new Character(_local_6, _local_7, _local_8, _local_9);
            _local_25 = new Sprite();
            _local_25.addChild(this.var_5);
            _local_25.x = 80;
            _local_25.y = (140 + 42);
            _local_25.scaleX = (_local_25.scaleY = 1.5);
            addChild(_local_25);
            this.var_158 = new StatsSelect((150 + this.rank), _local_14, _local_15, _local_16, null);
            this.var_158.x = 20;
            this.var_158.y = 207;
            addChild(this.var_158);
            this.var_190 = new class_262(this.var_5, _local_10, _local_11, _local_12, _local_13, _local_6, _local_7, _local_8, _local_9, _local_2, _local_3, _local_4, _local_5, _local_21, _local_22, _local_23, _local_24, _local_17, _local_18, _local_19, _local_20);
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
            var _local_1:int = (this.var_439 - this.var_117);
            this.m.var_159.visible = false;
            this.m.var_115.visible = false;
            if (_local_1 > 0) {
                this.m.var_159.visible = true;
                this.m.var_159.textBox.text = _local_1.toString();
                this.m.var_159.x = this.var_510;
            }
            if (this.var_117 > 0) {
                this.m.var_115.visible = true;
                this.m.var_115.arrow.rotation = 180;
                this.m.var_115.textBox.text = this.var_117.toString();
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
            if (this.var_117 < this.var_439) {
                this.var_117++;
                this.rank++;
                Main.socket.write("use_rank_token`");
                Main.socket.write("get_customize_info`");
            }
            this.method_194();
            this.method_148();
        }

        private function method_221(_arg_1:MouseEvent)
        {
            if (this.var_117 > 0) {
                this.var_117--;
                this.rank--;
                Main.socket.write("unuse_rank_token`");
                Main.socket.write("get_customize_info`");
            }
            this.method_194();
            this.method_148();
        }

        // _loc2 = e.keyCode
        private function keyDownHandler(e:KeyboardEvent)
        {
            var _local_5:TextField;
            var _local_6:Preset;
            var _local_3:int = -1;
            var _local_4:Boolean = true;
            if (e.keyCode == 49 || e.keyCode == 97) {
                _local_3 = 1;
            } else if (e.keyCode == 50 || e.keyCode == 98) {
                _local_3 = 2;
            } else if (e.keyCode == 51 || e.keyCode == 99) {
                _local_3 = 3;
            }
            if (e.target is TextField) {
                _local_5 = e.target as TextField;
                if (_local_5.type === TextFieldType.INPUT) {
                    _local_4 = false;
                }
            }
            if (_local_3 != -1 && _local_4) {
                _local_6 = Presets.getPreset(_local_3);
                Presets.apply(_local_6, this.var_5, this.var_158, this.var_190);
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
