// Decompiled by AS3 Sorcerer 5.98
// www.as3sorcerer.com

// data.Time = data.class_10

package com.jiggmin.data
{
    public class Time 
    {

        private var offsetMS:Number = 0;
        private var startMS:Number = 0;


        public function setTime(n:Number)
        {
            this.offsetMS = n * 1000;
            this.startMS = Data.getMS();
        }

        public function getMS():Number
        {
            return Data.getMS() - this.startMS + this.offsetMS;
        }

        public function getTimestamp():Number
        {
            return this.getMS() / 1000;
        }

        public function getDay():Number
        {
            var ms:Number = this.getTimestamp();
            return Math.round((ms / 24) / 60) / 60;
        }


    }
}
