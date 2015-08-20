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

#include "EcolStationBS.h"
#include "EcolStationNeighbourBS.h"
#include <stdio.h>
#include "Leds.h"
module BSCTPTestC{
	uses{
		interface Boot;
		interface SplitControl as RadioControl;
		interface StdControl as RoutingControl;
		interface Send;
		interface Leds;
		interface RootControl;
		interface Receive;
		interface TimeSyncTree;
		interface EcolStationNeighbourBS;
		
		interface Packet as UARTPacket;
		interface AMPacket as UARTAMPacket;
		interface AMSend as UARTAMSend;
		interface SplitControl as UARTAMControl;
		
		interface Reset;
		interface Timer<TMilli>;
	}
}
implementation{
	
	uint8_t ecolStationData[DATASIZE];
	uint8_t timeTriggerData[DATASIZE];
	uint8_t AMrecvdataTemp[DATASIZE - 2 ];
	uint32_t timeInterval = 0;
	message_t pkt;
	
	event void Boot.booted(){
		call Timer.startOneShot(3686400);	//一小时重启一次
		call TimeSyncTree.startTimeSync();
		call RadioControl.start();	
		call EcolStationNeighbourBS.startNei();
		call UARTAMControl.start();
	}
	
	event void UARTAMControl.startDone(error_t error){
	}
	
	event void UARTAMControl.stopDone(error_t error){
		call UARTAMControl.start();
	}

	event void UARTAMSend.sendDone(message_t *msg, error_t error){
		call Leds.led0Off();
	}
	
	event void RadioControl.startDone(error_t err){
		if(err != SUCCESS){
			call RadioControl.start();
		}else{
			call RoutingControl.start();
			if(TOS_NODE_ID == 1)
				call RootControl.setRoot();
		}
	}
	
	event void RadioControl.stopDone(error_t err){	
		if(err != SUCCESS){
			call RadioControl.stop();	
		}else{
			call Reset.reset();
		}
	}

	
	event void Send.sendDone(message_t* m, error_t err){
	}
	
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		CTPMsg* ctpmsg = (CTPMsg*)payload;
		int i;
		uint32_t realtime = 0;
		uint8_t *ecolStationDataBtrpkt;
		
		if(call Leds.get() & LEDS_LED0)
			call UARTAMControl.stop();
		
		memset(AMrecvdataTemp,DATASIZE-2,0);
		memset(ecolStationData,DATASIZE,0);
		
		if(len == DATASIZE-2) 
		{
			atomic{
				memcpy(AMrecvdataTemp, ctpmsg, DATASIZE-2);
				ecolStationData[0] = 0x56;
				ecolStationData[DATASIZE-1] = 0xAA;
				for (i = 1;i < DATASIZE-1; i++)
					ecolStationData[i] = AMrecvdataTemp[i - 1];
			}
			call Leds.led0On();
			realtime = call TimeSyncTree.getNow();
			atomic{
				timeInterval = realtime - ctpmsg ->time;	
				ecolStationData[DATASIZE-5] =(unsigned char) (timeInterval >>24); //替换时间值为时间差，4字节
				ecolStationData[DATASIZE-4] =(unsigned char) ((timeInterval&0xff0000) >>16);
				ecolStationData[DATASIZE-3] =(unsigned char) ((timeInterval&0xff00) >>8);
				ecolStationData[DATASIZE-2] =(unsigned char) (timeInterval&0xff);
			}
			ecolStationDataBtrpkt = (uint8_t*)(call UARTPacket.getPayload(&pkt, DATASIZE));
			if(ecolStationDataBtrpkt == NULL){
				while(call TimeSyncTree.getNow() % 10000 != 0){;;}
				signal Receive.receive(msg, payload, len); 
				return msg;
			}
			memcpy(ecolStationDataBtrpkt, ecolStationData, DATASIZE);
			call UARTAMSend.send(AM_UART, &pkt, DATASIZE);
		}
		return msg;	
	}
	

	event error_t TimeSyncTree.startTimeSyncDone(uint32_t RealTime){
		return TRUE;
	}

	event void EcolStationNeighbourBS.neighbourDone(uint8_t *ctpmsg){
		uint8_t* btrpkt = (uint8_t*)(call UARTPacket.getPayload(&pkt, CTPDATASIZE));
		memcpy(btrpkt, ctpmsg, CTPDATASIZE);
		call UARTAMSend.send(AM_UART, &pkt, CTPDATASIZE);
	}

	event void Timer.fired(){
		call RootControl.unsetRoot();
		call RoutingControl.stop();
		call RadioControl.stop();
	}
}