// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

//background.class_87

package background
{
    import data.CommandHandler;
    import page.GamePage;
    import package_9.LaserShot;
    import package_9.Slash;
    import package_9.MineAppear;
    import package_9.class_143;
    import package_9.class_142;
    import sounds.SoundEffects;

    public class class_87 extends class_75 
    {

        public static var var_276:class_87;

        public function class_87(_arg_1:GamePage)
        {
            class_87.var_276 = this;
            CommandHandler.commandHandler.defineCommand("addEffect", this.addEffect);
            super(_arg_1);
        }

        public function addEffect(_arg_1:Array)
        {
            var _local_5:int;
            var _local_6:String;
            var _local_7:int;
            var _local_8:int;
            var _local_9:int;
            var _local_10:int;
            var _local_11:int;
            var _local_12:int;
            var _local_13:int;
            var _local_2:String = _arg_1[0];
            var _local_3:int = int(_arg_1[1]);
            var _local_4:int = int(_arg_1[2]);
            if (_local_2 == "Laser") {
                _local_6 = _arg_1[3];
                _local_5 = int(_arg_1[4]);
                _local_7 = int(_arg_1[5]);
                new LaserShot(_local_3, _local_4, _local_6, _local_5, _local_7);
            }
            if (_local_2 == "Slash") {
                _local_6 = _arg_1[3];
                _local_7 = int(_arg_1[4]);
                new Slash(_local_3, _local_4, _local_6, _local_7);
            } else {
                if (_local_2 == "Mine") {
                    new MineAppear(_local_3, _local_4);
                } else {
                    if (_local_2 == "Hat") {
                        _local_9 = int(_arg_1[3]);
                        _local_10 = int(_arg_1[4]);
                        _local_11 = int(_arg_1[5]);
                        _local_12 = int(_arg_1[6]);
                        _local_13 = int(_arg_1[7]);
                        new class_143(_local_3, _local_4, _local_9, _local_10, _local_11, _local_12, _local_13);
                    } else {
                        if (_local_2 == "IceWave") {
                            _local_8 = int(_arg_1[3]);
                            _local_5 = int(_arg_1[4]);
                            _local_7 = int(_arg_1[5]);
                            this.method_622(_local_3, _local_4, _local_8, _local_5, _local_7);
                        }
                    }
                }
            }
        }

        public function method_622(_arg_1:int, _arg_2:int, _arg_3:int, _arg_4:int, _arg_5:int)
        {
            new class_142(_arg_1, _arg_2, _arg_3, _arg_4, _arg_5, _arg_3);
            new class_142(_arg_1, _arg_2, (_arg_3 + 30), _arg_4, _arg_5, _arg_3);
            new class_142(_arg_1, _arg_2, (_arg_3 - 30), _arg_4, _arg_5, _arg_3);
            SoundEffects.playGameSound(new IceWaveSound(), _arg_1, _arg_2, 1.5);
        }

        override public function clear()
        {
            while (numChildren > 0) {
                class_7(getChildAt((numChildren - 1))).remove();
            }
        }

        override public function remove()
        {
            this.clear();
            class_87.var_276 = null;
            CommandHandler.commandHandler.defineCommand("addEffect", null);
            super.remove();
        }


    }
}//package background

