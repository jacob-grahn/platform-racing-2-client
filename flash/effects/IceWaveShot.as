// effects.IceWaveShot = effects.class_142

package effects
{
    import com.jiggmin.data.Data;
    import com.jiggmin.data.Objects;
    import blocks.IceBlock;
    import blocks.Block;
    import character.LocalCharacter;
    import character.Character;

    public class IceWaveShot extends ShotEffect 
    {

        private static var activeCount:int = 0;

        private var m:IceWaveGraphic = new IceWaveGraphic();
        private var baseAngle:Number;
        private var initialAngle:Number;

        public function IceWaveShot(startX:Number, startY:Number, startAngle:Number, startRot:int, tempID:int, base:Number, startLife:int=75)
        {
            activeCount++;
            super(startX, startY, startAngle, startRot, tempID, 'ice');
            hitInactiveBlocks = true;
            this.life = startLife;
            this.initialAngle = startAngle;
            this.baseAngle = base;
            addChild(this.m);
            this.skipPastSpawn();
        }

        private function skipPastSpawn()
        {
            if (!isRemoved()) {
                setSpeed(30);
                this.move();
                setSpeed(5);
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
                if (activeCount < 10 && life > 10) {
                    var _local_2:Number = this.baseAngle - 60;
                    var _local_3:Number = this.baseAngle + 60;
                    var _local_4:Number = Data.numLimit(this.initialAngle + 30, _local_2, _local_3);
                    var _local_5:Number = Data.numLimit(this.initialAngle - 30, _local_2, _local_3);
                    if (_local_4 != this.initialAngle) {
                        new IceWaveShot(x, y, _local_4, rot, shooterID, this.baseAngle, life / 2);
                    }
                    if (_local_5 != this.initialAngle) {
                        new IceWaveShot(x, y, _local_5, rot, shooterID, this.baseAngle, life / 2);
                    }
                    life -= 5;
                    this.skipPastSpawn();
                }
            }
        }

        // _loc2 = player
        override protected function hitPlayer(p:Character)
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
            activeCount--;
            removeChild(this.m);
            this.m = null;
            super.remove();
        }


    }
}//package effects

