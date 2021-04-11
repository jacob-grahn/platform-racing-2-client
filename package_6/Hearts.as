// package_6.Hearts = package_6.class_89

package package_6
{
    import com.jiggmin.data.Data;
    import flash.display.Sprite;

    public class Hearts extends Sprite 
    {

        private var totalHearts:int = 0; // var_193
        private var yInc:int = 20; // var_454
        private var scale:Number = 0.2;


        public function method_798(numHearts:int)
        {
            numHearts = Data.numLimit(numHearts, 0, 15);
            while (this.totalHearts < numHearts) {
                this.addHeart();
            }
            while (this.totalHearts > numHearts) {
                this.removeHeart();
            }
        }

        public function method_758():int
        {
            return this.totalHearts;
        }

        // _loc1 = m
        // method_695 = addHeart
        private function addHeart()
        {
            var m:HeartGraphic = new HeartGraphic();
            m.scaleX = m.scaleY = this.scale;
            m.x = 0;
            m.y = this.totalHearts * this.yInc;
            addChild(m);
            this.totalHearts++;
        }

        // method_517 = removeHeart
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
