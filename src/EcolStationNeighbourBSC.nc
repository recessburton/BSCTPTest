/**
 Copyright (C),2014-2015, YTC, www.bjfulinux.cn
 Copyright (C),2014-2015, ENS Group, ens.bjfu.edu.cn
 Created on  2015-06-04 15:27
 
 @author: ytc recessburton@gmail.com
 @version: 1.0
 
 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>
 **/

#include <Timer.h>
#include "EcolStationNeighbourBS.h"

configuration EcolStationNeighbourBSC {
	provides {
		interface EcolStationNeighbourBS;
	}
}

implementation {
	components MainC;
	components LedsC;
	components EcolStationNeighbourBSP as App;
	components new TimerMilliC() as Timer0;
	components new TimerMilliC() as Timer1;
	components new AMSenderC(ORWNEIGHBOUR);
	components new AMReceiverC(ORWNEIGHBOUR);
	components CollectionC as Collector;
	components ActiveMessageC as CTPAM;
	components new CollectionSenderC(0xe1);
	components new TelosbSensorC(100) as TBS;
	components CC2420ActiveMessageC;
	
	EcolStationNeighbourBS = App.EcolStationNeighbourBS;

	App.Leds -> LedsC;
	App.Timer0 -> Timer0;
	App.Timer1 -> Timer1;
	App.Packet -> AMSenderC;
	App.AMPacket -> AMSenderC;
	App.AMSend -> AMSenderC;
	App.Receive -> AMReceiverC;
	
	App.Send -> CollectionSenderC;
	App.RadioControl -> CTPAM;
	App.RoutingControl -> Collector;
	App.RootControl -> Collector;
	App.CTPReceive -> Collector.Receive[0xe1];
	
	App.TelosbBuiltinSensors->TBS;
	
	App.CC2420Packet -> CC2420ActiveMessageC;
}
