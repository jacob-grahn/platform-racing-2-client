// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// data.Time = data.class_10

package com.jiggmin.data
{
    public class Time 
    {

        private var var_624:Number = 0;
        private var var_568:Number = 0;


        public function setTime(n:Number)
        {
            this.var_624 = n * 1000;
            this.var_568 = Data.getTime();
        }

        // method_26 = getTime
        public function getTime():Number
        {
            return Data.getTime() - this.var_568 + this.var_624;
        }

        // method_79 = getMS
        public function getMS():Number
        {
            return this.getTime() / 1000;
        }

        // _loc1 = ms
        public function getDay():Number
        {
            var ms:Number = this.getMS();
            return Math.round((ms / 24) / 60) / 60;
        }


    }
}
