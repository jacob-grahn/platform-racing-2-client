package blocks
{
    import blocks.options.TeleportBlockOptions;
    import com.jiggmin.data.Objects;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.clearTimeout;
    import flash.utils.setTimeout;
    import package_6.Course;
    import package_8.LocalCharacter;
    import package_9.TeleportPop;

    public dynamic class TeleportBlock extends SupplyBlock 
    {
        public static const DEFAULT_COLOR:int = 0xFF7F50;
        
        // public static variables created for each color of teleport block in the level, with the name DISABLED_*colordecvalue*

        public var blockNum:int;
        private var color:int = DEFAULT_COLOR;
        private var blockBG:Bitmap = new Bitmap();
        private var resetTimeout:uint;

        public function TeleportBlock()
        {
            optionsMenu = TeleportBlockOptions;
            addChild(this.blockBG);
            this.setColor();
            super(Objects.BLOCK_TELEPORT);
            safeStand = false;
        }

        public function getColor()
        {
            return options != '' ? int(options) : DEFAULT_COLOR;
        }

        public function setColor(color:int = DEFAULT_COLOR)
        {
            this.color = color;
            this.blockBG.bitmapData = new BitmapData(30, 30, false, this.color);
        }

        public function applyOptions(optStr:String)
        {
            this.setColor(optStr);
            options = int(optStr) != DEFAULT_COLOR ? optStr : '';
        }

        protected function disable()
        {
            uses = 0;
            method_789();
        }

        override public function onStand(player:LocalCharacter)
        {
            super.onStand(player);
            this.maybeTeleport(player);
        }

        override public function onLeftHit(player:LocalCharacter)
        {
            super.onLeftHit(player);
            this.maybeTeleport(player);
        }

        override public function onRightHit(player:LocalCharacter)
        {
            super.onRightHit(player);
            this.maybeTeleport(player);
        }

        override public function onBump(player:LocalCharacter)
        {
            super.onBump(player);
            this.maybeTeleport(player);
        }

        private function maybeTeleport(player:LocalCharacter)
        {
            if (!frozen && TeleportBlock['DISABLED_' + this.color] !== true) {
                TeleportBlock['DISABLED_' + this.color] = true;
                super.maybeUseSupply(player);
            }
        }

        override protected function useSupply(player:LocalCharacter)
        {
            super.useSupply(player);
            var blocksOfThisColor:Array = Course.course.teleportBlocks[this.color];
            var destBlock:TeleportBlock = blocksOfThisColor != null && blocksOfThisColor.length > 1 ? blocksOfThisColor[this.blockNum + 1 >= blocksOfThisColor.length ? 0 : this.blockNum + 1] : this;
            for (var i:int = 0; i < blocksOfThisColor.length; i++) {
                if (blocksOfThisColor[i] != this) {
                    blocksOfThisColor[i].disable();
                }
            }
            new TeleportPop(player.x, player.y - 25);
            Main.socket.write("add_effect`Teleport`" + player.x + "`" + (player.y - 25));
            var blockPos:Point = method_18();
            var newBlockPos:Point = destBlock.method_18();
            var charPos:Object = player.getPos();
            var relCharPos:Point = new Point(charPos.x - blockPos.x, charPos.y - blockPos.y);
            player.x = newBlockPos.x + relCharPos.x;
            player.y = newBlockPos.y + relCharPos.y;
            new TeleportPop(player.x, player.y - 25);
            Main.socket.write("add_effect`Teleport`" + player.x + "`" + (player.y - 25));
            this.resetTimeout = setTimeout(function () {
                resetAllOfColor();
            }, 3000);
        }

        public function clearResetTimeout()
        {
            clearTimeout(this.resetTimeout);
        }

        private function resetAllOfColor()
        {
            this.clearResetTimeout();
            var blocksOfThisColor:Array = Course.course.teleportBlocks[this.color];
            for (var i:int = 0; i < blocksOfThisColor.length; i++) {
                blocksOfThisColor[i].resetSupply();
            }
            TeleportBlock['DISABLED_' + this.color] = false;
        }

        public static function resetAll()
        {
            for each (var blocksOfColor:Array in Course.course.teleportBlocks) {
                for each (var block:TeleportBlock in blocksOfColor) {
                    block.clearResetTimeout();
                    block.resetSupply();
                    TeleportBlock['DISABLED_' + block.getColor()] = false;
                }
            }
            Course.course.teleportBlocks = {};
        }

        override public function remove()
        {
            this.clearResetTimeout();
            delete TeleportBlock['DISABLED_' + this.color];
            removeChild(this.blockBG);
            super.remove();
        }

    }
}
