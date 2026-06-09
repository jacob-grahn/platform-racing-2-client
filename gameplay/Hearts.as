// gameplay.Hearts = gameplay.class_89

package gameplay
{
    import com.jiggmin.data.Data;
    import flash.display.Sprite;

    public class Hearts extends Sprite 
    {

        private var totalHearts:int = 0;
        private var yInc:int = 20;
        private var scale:Number = 0.2;


        public function setHearts(numHearts:int)
        {
            numHearts = Data.numLimit(numHearts, 0, 15);
            while (this.totalHearts < numHearts) {
                this.addHeart();
            }
            while (this.totalHearts > numHearts) {
                this.removeHeart();
            }
        }

        public function getHeartCount():int
        {
            return this.totalHearts;
        }

        private function addHeart()
        {
            var m:HeartGraphic = new HeartGraphic();
            m.scaleX = m.scaleY = this.scale;
            m.x = 0;
            m.y = this.totalHearts * this.yInc;
            addChild(m);
            this.totalHearts++;
        }

        private function removeHeart()
        {
            removeChildAt(this.numChildren - 1);
            this.totalHearts--;
        }

        public function remove()
        {
            if (parent != null) {
                parent.removeChild(this);
            }
        }


    }
}
