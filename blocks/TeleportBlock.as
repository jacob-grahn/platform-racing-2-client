package blocks
{
    import blocks.options.TeleportBlockOptions;
    import com.jiggmin.data.Objects;
    import flash.display.Bitmap;
    import flash.display.BitmapData;
    import flash.geom.Point;
    import flash.geom.Rectangle;
    import flash.utils.setTimeout;
    import package_6.Course;
    import package_8.LocalCharacter;
    import package_9.TeleportPop;

    public class TeleportBlock extends SupplyBlock 
    {
        public static const DEFAULT_COLOR:int = 0xFF7F50;

        private var blockBG:Bitmap = new Bitmap();

        public function TeleportBlock()
        {
            optionsMenu = TeleportBlockOptions;
            addChild(this.blockBG);
            this.setColor();
            super(Objects.BLOCK_TELEPORT);
        }

        public function getColor()
        {
            return options != '' ? int(options) : DEFAULT_COLOR;
        }

        public function setColor(color:int = DEFAULT_COLOR)
        {
            this.blockBG.bitmapData = new BitmapData(30, 30, false, color);
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
            setTimeout(function () {
                resetSupply();
            }, 3000);
        }

        override protected function useSupply(player:LocalCharacter)
        {
            super.useSupply(player);
            var destBlock:TeleportBlock = this;
            var blocksOfThisColor:Array = Course.course.teleportBlocks[this.getColor()];
            if (blocksOfThisColor != null && blocksOfThisColor.length > 1) {
                while (true) {
                    destBlock = blocksOfThisColor[Math.floor(Math.random() * blocksOfThisColor.length)];
                    if (destBlock == this) {
                        continue;
                    }
                    break;
                }
            }
            for (var i:int = 0; i < blocksOfThisColor.length; i++) {
                if (blocksOfThisColor[i] != this) {
                    blocksOfThisColor[i].disable();
                }
            }
            new TeleportPop(player.x, player.y);
            Main.socket.write("add_effect`Teleport`" + player.x + "`" + player.y);
            var newPos:Point = destBlock.method_18();
            newPos.x += 15;
            newPos.y += 80;
            player.setPos(newPos.x, newPos.y);
            new TeleportPop(player.x, player.y);
            Main.socket.write("add_effect`Teleport`" + player.x + "`" + player.y);
            setTimeout(function () {
                resetSupply();
            }, 3000);
        }

        override public function remove()
        {
            removeChild(this.blockBG);
            super.remove();
        }

    }
}
