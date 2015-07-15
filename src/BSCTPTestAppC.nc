/**
 Copyright (C),2014-2015, YTC, www.bjfulinux.cn
 Copyright (C),2014-2015, ENS Group, ens.bjfu.edu.cn
 Created on  2015-05-09 15:18
 
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


configuration BSCTPTestAppC{
}
implementation{
	components BSCTPTestC as App, MainC, LedsC, ActiveMessageC;
	components CollectionC as Collector;
	components new CollectionSenderC(0xee);
	components TelosbTimeSyncBSC;
	components EcolStationNeighbourBSC;
	components new TimerMilliC() as Timer;
	
	components new Msp430Uart1C() as UartC;
	
	components ResetC;
	
	App.Boot                             -> MainC;
	App.RadioControl            -> ActiveMessageC;
	App.RoutingControl        -> Collector;
	App.Leds                             -> LedsC;
	App.Send                            -> CollectionSenderC;
	App.RootControl             -> Collector;
	App.Receive                       -> Collector.Receive[0xee];
	App.TelosbTimeSyncBS -> TelosbTimeSyncBSC;
	
	App.Resource                   -> UartC.Resource;
	App.UartStream              -> UartC.UartStream;
	App.UartConfigure         <- UartC.Msp430UartConfigure;
	
	App.EcolStationNeighbourBS -> EcolStationNeighbourBSC;
	
	App.Timer -> Timer;
	App.Reset -> ResetC;
	
}