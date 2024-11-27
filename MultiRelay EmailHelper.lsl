integer EMAIL1=70;
integer length;
string protocol="ORG encapsulated RLVR protocol,005,";

default
{
    state_entry()
    {
        length = llStringLength((string)NULL_KEY+"@lsl.secondlife.com");
    }
    
    link_message(integer l, integer n, string m, key i)
    {
        if (n==EMAIL1)
        {
            string address=llGetSubString(m,0,length-1);
            string msg=llGetSubString(m,length,-1);
            llEmail(address,protocol+(string)i,msg);
        }
    }
}
