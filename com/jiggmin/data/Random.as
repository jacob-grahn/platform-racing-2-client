// data.Random = data.class_133

package com.jiggmin.data
{
    import flash.utils.ByteArray;

    public class Random 
    {

        private var _inext:int; // var_464
        private var _inextp:int; // var_471
        private const MBIG:int = 0x7fffffff; // const_96
        private const MSEED:int = 0x9a4ec86; // const_97
        private const MZ:int = 0; // const_95
        private var _seed:int; // var_520
        private var _seedArray:Vector.<int>; // var_53

        // _loc2 = num2
        // _loc3 = num3
        // _loc4 = i
        // _loc5 = j
        // _loc6 = index
        // _loc7 = k
        public function Random(seed:int)
        {
			this._seed = seed;
			this._seedArray = new Vector.<int>(0x38, true);
			var num2:int = 0x9a4ec86 - Math.abs(seed);
			this._seedArray[0x37] = num2;
			var num3:int = 1;
			for (var i:int = 1; i < 0x37; i++) {
				var index:int = (0x15 * i) % 0x37;
				this._seedArray[index] = num3;
				num3 = num2 - num3;
				if (num3 < 0) {
					num3 += 0x7fffffff;
				}
				num2 = this._seedArray[index];
			}
			for (var j:int = 1; j < 5; j++) {
				for (var k:int = 1; k < 0x38; k++) {
					this._seedArray[k] -= this._seedArray[1 + ((k + 30) % 0x37)];
					if (this._seedArray[k] < 0) {
						this._seedArray[k] += 0x7fffffff;
					}
				}
			}
			this._inext = 0;
			this._inextp = 0x15;
			seed = 1;
        }

        public function get seed():int
        {
            return this._seed;
        }

        // getSampleForLargeRange = getSampleForLargeRange
        private function getSampleForLargeRange():Number
        {
			var num:int = this.internalSample();
			if ((this.internalSample() % 2) == 0) {
				num = -num;
			}
			var num2:Number = num;
			num2 += 2147483646.0;
			return (num2 / 4294967293);
        }

        // _loc1 = inext
        // _loc2 = inextp
        // _loc3 = num
        private function internalSample():int
        {
			var inext:int = this._inext;
			var inextp:int = this._inextp;
			if (++inext >= 0x38) {
				inext = 1;
			}
			if (++inextp >= 0x38) {
				inextp = 1;
			}
			var num:int = this._seedArray[inext] - this._seedArray[inextp];
			if (num < 0) {
				num += 0x7fffffff;
			}
			this._seedArray[inext] = num;
			this._inext = inext;
			this._inextp = inextp;
			return num;
        }

        public function nextInt():int
        {
            return this.internalSample();
        }

        public function nextMax(maxValue:int):int
        {
			if (maxValue < 0) {
				throw new ArgumentError("Argument \"maxValue\" must be positive.");
			}
			return int(this.sample() * maxValue);
        }

        // _loc3 = num
        public function nextMinMax(minValue:int, maxValue:int):int
        {
			if (minValue > maxValue) {
				throw new ArgumentError("Argument \"minValue\" must be less than or equal to \"maxValue\".");
			}
			var num:Number = maxValue - minValue;
			if (num <= 0x7fffffff) {
				return (((int) (this.sample() * num)) + minValue);
			}
			return (((int) (Number(this.getSampleForLargeRange() * num))) + minValue);
        }

        // _loc3 = i
        public function nextBytes(buffer:ByteArray, length:int)
        {
			if (buffer == null) {
				throw new ArgumentError("Argument \"buffer\" cannot be null.");
			}
			for (var i:int = 0; i < length; i++) {
				buffer.writeByte(this.internalSample() % 0x100);
			}
        }

        public function nextNumber():Number
        {
            return this.sample();
        }

        protected function sample():Number
        {
            return (this.internalSample() * 4.6566128752457969E-10);
        }


    }
}
