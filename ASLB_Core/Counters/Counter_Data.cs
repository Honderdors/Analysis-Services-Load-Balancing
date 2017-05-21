using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ASLB_Core.Counters.Counters
{
    public class Counter_Data
    {
        private string _tab = "\t";

        private string[] _CounterData;
        public Counter_Data(string CounterData,char split)
        {
            _CounterData = CounterData.Split(split);
        }
        public Counter_Data(string CounterData)
        {
            _CounterData = CounterData.Split('|');
        }

        public string Spacer(string key)
        {
            string result = string.Empty;
            for (int i = 0; i < _CounterData.Length; i++)
            {
                if (_CounterData[i] == key)
                {
                    result= Spacer(i);
                }
            }
            return result;
        }
        public string Spacer(int ListNumber)
        {

            string result = string.Empty;
            int maxlength=0;
            foreach (string k in _CounterData)
            {
                if (maxlength < k.Length)
                {
                    maxlength = k.Length;
                }
            }

            for (int i = 0; i <= (maxlength / 4); i++)
            {
                result = result + _tab;
            }

            return result;

        }

        public int GetNumberOfCounters
        {
            get
            {
                return _CounterData.Length;
            }
        }

        public string CounterKey(int ListNumber)
        {
            try
            {
                return _CounterData[ListNumber];
            }
            catch
            {
                return "";
            }
        }


        //CategoryName, CounterName, InstanceName
        public string CategoryName(int ListNumber)
        {
            try
            {
                return _CounterData[ListNumber].Split(';')[0];
            }
            catch
            {
                return "";
            }
        }
        public string CounterName(int ListNumber)
        {
            try
            {
                if (_CounterData[ListNumber].Split(';').Length >=2)
                {
                    return _CounterData[ListNumber].Split(';')[1];
                }
                else
                {
                    return "";
                }
            }
            catch
            {
                return "";
            }
        }
        public string InstanceName(int ListNumber)
        {
            try
            {
                if (_CounterData[ListNumber].Split(';').Length >=3)
                {
                    return _CounterData[ListNumber].Split(';')[2];
                }
                else
                {
                    return "";
                }
            }
            catch
            {
                return "";
            }
        }
    }
}
