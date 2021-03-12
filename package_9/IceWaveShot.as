// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// package_9.IceWaveShot = package_9.class_142

package package_9
{
    import com.jiggmin.data.Objects;
    import blocks.IceBlock;
    import blocks.Block;
    import package_8.LocalCharacter;
    import package_8.Player;

    public class IceWaveShot extends ShotEffect 
    {

        private static var var_168:int = 0;

        private var m:IceWaveGraphic = new IceWaveGraphic();
        private var var_322:Number;
        private var var_278:Number;

        public function IceWaveShot(_arg_1:Number, _arg_2:Number, _arg_3:Number, _arg_4:int, tempID:int, _arg_6:Number, _arg_7:int=75)
        {
            var_168++;
            super(_arg_1, _arg_2, _arg_3, _arg_4, tempID, 'ice');
            var_493 = true;
            this.life = _arg_7;
            this.var_278 = _arg_3;
            this.var_322 = _arg_6;
            addChild(this.m);
            this.method_219();
        }

        private function method_219()
        {
            if (!method_20()) {
                method_62(30);
                this.move();
                method_62(5);
            }
        }

        override protected function move()
        {
            super.move();
            alpha = (Math.random() * life / 100) + 0.25;
        }

        override protected function hitBlock(_arg_1:Block)
        {
            if (!(_arg_1 is IceBlock) && _arg_1.getCode() != Objects.BLOCK_ICE) {
                _arg_1.freeze(true);
                if (var_168 < 10 && life > 10) {
                    var _local_2:Number = this.var_322 - 60;
                    var _local_3:Number = this.var_322 + 60;
                    var _local_4:Number = class_74.numLimit(this.var_278 + 30, _local_2, _local_3);
                    var _local_5:Number = class_74.numLimit(this.var_278 - 30, _local_2, _local_3);
                    if (_local_4 != this.var_278) {
                        new IceWaveShot(x, y, _local_4, var_377, shooterID, this.var_322, life / 2);
                    }
                    if (_local_5 != this.var_278) {
                        new IceWaveShot(x, y, _local_5, var_377, shooterID, this.var_322, life / 2);
                    }
                    life -= 5;
                    this.method_219();
                }
            }
        }

        // _loc2 = player
        override protected function hitPlayer(p:Player)
        {
            if (p is LocalCharacter) {
                var player:LocalCharacter = LocalCharacter(p);
                if (!player.isFrozen()) {
                    player.freeze();
                }
            }
        }

        override public function remove()
        {
            var_168--;
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}//package package_9

