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

module EcolStationNeighbourBSP {
	provides interface Msp430UartConfigure as UartConfigure;
	provides interface EcolStationNeighbourBS;

	uses interface Leds;
	uses interface Timer<TMilli> as Timer0;
	uses interface Timer<TMilli> as Timer1;
	uses interface Packet;
	uses interface AMPacket;
	uses interface AMSend;
	uses interface Receive;
	uses interface SplitControl as AMControl;
	uses interface SplitControl as RadioControl;
	uses interface StdControl as RoutingControl;
	uses interface Send;
	uses interface RootControl;
	uses interface Receive as CTPReceive;
	
	uses interface Resource;
	uses interface UartStream;
	
	uses interface TelosbBuiltinSensors;  
}

implementation {
	uint8_t ctpdata[CTPDATASIZE];
	NeighbourUnit neighbourSet[10*MAX_NEIGHBOUR_NUM];
	nx_NeighbourUnit nx_neighbourSet[MAX_NEIGHBOUR_NUM];
	message_t pkt,packet;
	volatile bool busy = FALSE;
	uint8_t helloMsgCount = 0;
	uint8_t neighbourNumIndex = 0;//邻居数目，>从0开始!<<<<<<
	int tempIndex;
	uint16_t battery = 0;
	
	task void requestUART();
	task void releaseUART();
	
	msp430_uart_union_config_t msp430_uart_config = {{ ubr : UBR_1MHZ_115200, // Baud rate (use enum msp430_uart_rate_t in msp430usart.h for predefined rates)
			umctl : UMCTL_1MHZ_115200, // Modulation (use enum msp430_uart_rate_t in msp430usart.h for predefined rates)
			ssel : 0x02, // Clock source (00=UCLKI; 01=ACLK; 10=SMCLK; 11=SMCLK)
			pena : 0, // Parity enable (0=disabled; 1=enabled)
			pev : 0, // Parity select (0=odd; 1=even)
			spb : 0, // Stop bits (0=one stop bit; 1=two stop bits)
			clen : 1, // Character length (0=7-bit data; 1=8-bit data)
			listen : 0, // Listen enable (0=disabled; 1=enabled, feed tx back to receiver)
			mm : 0, // Multiprocessor mode (0=idle-line protocol; 1=address-bit protocol)
			ckpl : 0, // Clock polarity (0=normal; 1=inverted)
			urxse : 0, // Receive start-edge detection (0=disabled; 1=enabled)
			urxeie : 1, // Erroneous-character receive (0=rejected; 1=recieved and URXIFGx set)
			urxwie : 0, // Wake-up interrupt-enable (0=all characters set URXIFGx; 1=only address sets URXIFGx)
			utxe : 1, // 1:enable tx module
			urxe : 1	// 1:enable rx module      

	}};

	async command msp430_uart_union_config_t * UartConfigure.getConfig() {
		return & msp430_uart_config;
	}

	task void requestUART() {
		call Resource.request();	
	}

	task void releaseUART() {
		call Resource.release();
	}

	event void Resource.granted() {
	}

	async event void UartStream.sendDone(uint8_t * buf, uint16_t len,error_t error) {
		if(error == SUCCESS) {
			call Leds.led0Off();
		}
		else {
		}
	}

	async event void UartStream.receivedByte(uint8_t byte) {
	}

	async event void UartStream.receiveDone(uint8_t * buf, uint16_t len, error_t error) {
		//接收到控制命令
	}

	event void AMControl.startDone(error_t err) {
		if(err == SUCCESS) {
			call Timer0.startPeriodic(TIMER_PERIOD_MILLI);
		}
		else {
			call AMControl.start();
		}
	}

	event void AMControl.stopDone(error_t err) {
	}

	void helloMsgSend() {
		if( ! busy) {
			NeighbourMsg * btrpkt = (NeighbourMsg * )(call Packet.getPayload(&pkt, sizeof(NeighbourMsg)));
			if(btrpkt == NULL) {
				return;
			}
			btrpkt->dstid = 0xFF;
			btrpkt->sourceid = (nx_int8_t)TOS_NODE_ID;
			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(NeighbourMsg)) == SUCCESS) {
				busy = TRUE;
			}
		}
	}

	event void Timer0.fired() {
		if (helloMsgCount > 10 && helloMsgCount < 15){
			helloMsgSend();
			helloMsgCount ++;
		}
		else if(helloMsgCount <= 10)
			helloMsgCount ++;
		else{
			call Timer0.stop();
			call Timer1.startPeriodic(NEIGHBOUR_PERIOD_MILLI);
		}
	}

	event void AMSend.sendDone(message_t * msg, error_t err) {
		if(&pkt == msg) {
			busy = FALSE;
		}
	}
	
	void ackMsgSend(uint16_t sourceid) {
		if( ! busy) {
			NeighbourMsg * btrpkt1 = (NeighbourMsg * )(call Packet.getPayload(&pkt,sizeof(NeighbourMsg)));
			if(btrpkt1 == NULL) {
				return;
			}
			btrpkt1->dstid = (nx_int8_t)sourceid;
			btrpkt1->sourceid = (nx_int8_t)TOS_NODE_ID;
			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(NeighbourMsg)) == SUCCESS) {
				busy = TRUE;
			}
		}
	}
	
	void addSet(uint16_t sourceid){
		int i;
		for(i = 0 ; i <= neighbourNumIndex; i++ ){
			if(neighbourSet[i].nodeid == sourceid){
				return;
			}else{
				continue;
			}
		}
		//如果执行到此处，表明该节点不在邻居集合中
		neighbourSet[neighbourNumIndex].nodeid = sourceid;
		neighbourSet[neighbourNumIndex].linkquality = 0.0f;
		neighbourSet[neighbourNumIndex].recvCount = 0;
		neighbourNumIndex ++;
	}
	
	void sortNodes(int left, int right){
		//邻居节点集中按照链路质量快速排序
		int i, j;
		NeighbourUnit temp, t;
		
		if(left > right) 
			return;	
		
		memcpy(&temp, &neighbourSet[left], sizeof(NeighbourUnit));
		i = left;
		j = right;
		
		while(i != j) {
			while(neighbourSet[j].linkquality <= temp.linkquality && i < j)
				j --;
			while(neighbourSet[i].linkquality <= temp.linkquality && i < j)
				i ++;	
				
			if(j < j) {
				memcpy(&t, &neighbourSet[i], sizeof(NeighbourUnit));
				memcpy(&neighbourSet[i], &neighbourSet[j],  sizeof(NeighbourUnit));
				memcpy(&neighbourSet[j], &t,   sizeof(NeighbourUnit));	
			}
		}
		
		memcpy(&neighbourSet[left], &neighbourSet[i], sizeof(NeighbourUnit));
		memcpy(&neighbourSet[i], &temp, sizeof(NeighbourUnit));
		
		sortNodes(left, i-1);
		sortNodes(i+1, right);

	}
	
	void estLinkQuality(uint16_t sourceid){
		int i = 0;
		for( ; i <= neighbourNumIndex; i++ ){
			if(neighbourSet[i].nodeid == sourceid){
				neighbourSet[i].recvCount ++;
				neighbourSet[i].linkquality = (float) (neighbourSet[i].recvCount / (helloMsgCount * 1.0));
			}else{
				continue;
			}
		}
		sortNodes(0, neighbourNumIndex);
	}
	
		
	void convertNX(){			//将邻居集转换为网络类型
		int i;
		for(i = 0; i<(MAX_NEIGHBOUR_NUM < neighbourNumIndex ? MAX_NEIGHBOUR_NUM : neighbourNumIndex); i++ ){
			nx_neighbourSet[i].nodeid = (nx_uint8_t)neighbourSet[i].nodeid;
			nx_neighbourSet[i].linkquality = (nx_uint8_t)(neighbourSet[i].linkquality*100);
		}
	}
	
	void sendMessage(){
		NeiCTPMsg* ctpmsg = (NeiCTPMsg*)call Send.getPayload(&packet, sizeof(NeiCTPMsg));
		convertNX();	
		ctpmsg -> neighbourNum = neighbourNumIndex;
		ctpmsg -> nodeid = (nx_uint8_t)TOS_NODE_ID;
		ctpmsg -> power = battery;
		memcpy(ctpmsg -> neighbourSet, nx_neighbourSet, sizeof(nx_neighbourSet));
		call Send.send(&packet, sizeof(NeiCTPMsg));
		busy = TRUE;	
	}

	event message_t * Receive.receive(message_t * msg, void * payload,uint8_t len) {
		int i;
		if(len == sizeof(NeighbourMsg)) {
			NeighbourMsg * btrpkt = (NeighbourMsg * ) payload;
			if(btrpkt->dstid == 0xFF){	//接到其它节点发的hello包，回ack包
				ackMsgSend(btrpkt->sourceid);
			}
			else if ( (btrpkt->dstid - TOS_NODE_ID) == 0) {	//接到的是自己的回包，计算链路质量，判断邻居资格
				addSet(btrpkt->sourceid);
				estLinkQuality(btrpkt->sourceid);
			}else{	//其它包，丢弃
			}
		}
		return msg;
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

	event void RadioControl.stopDone(error_t error){
	}

	event void Send.sendDone(message_t *msg, error_t error){
		busy = FALSE;
	}

	void sendUART(NeiCTPMsg * btrpkt){
		memset(ctpdata,CTPDATASIZE,0);
		ctpdata[0] = 0x57;
		ctpdata[CTPDATASIZE-1] = 0xAA;
		memcpy(ctpdata + 1, btrpkt, CTPDATASIZE-2);
		call Leds.led0On();
		call UartStream.send(ctpdata, CTPDATASIZE);
	}

	event message_t * CTPReceive.receive(message_t *msg, void *payload, uint8_t len){
		int i;
		if(len == sizeof(NeiCTPMsg)) {
			NeiCTPMsg * btrpkt = (NeiCTPMsg * ) payload;
			sendUART(btrpkt);
		}
		return msg;
	}

	event void Timer1.fired(){
		NeiCTPMsg* ctpmsg = (NeiCTPMsg*)malloc(sizeof(NeiCTPMsg));
		convertNX();
		ctpmsg -> neighbourNum = neighbourNumIndex;
		ctpmsg -> nodeid = (nx_uint8_t)TOS_NODE_ID;
		ctpmsg -> power = battery;
		memcpy(ctpmsg -> neighbourSet, nx_neighbourSet, sizeof(nx_neighbourSet));
		sendUART(ctpmsg);
	}

	event void TelosbBuiltinSensors.readAllDone(error_t errT, uint16_t temp, error_t errH, uint16_t humi, error_t errL, uint16_t ligh, error_t errB, uint16_t batt){
		// TODO Auto-generated method stub
	}

	event void TelosbBuiltinSensors.readBatteryDone(error_t err, uint16_t data){
		battery = data;
	}

	event void TelosbBuiltinSensors.readTemperatureDone(error_t err, uint16_t data){
		// TODO Auto-generated method stub
	}

	event void TelosbBuiltinSensors.readHumidityDone(error_t err, uint16_t data){
		// TODO Auto-generated method stub
	}

	event void TelosbBuiltinSensors.readLightDone(error_t err, uint16_t data){
		// TODO Auto-generated method stub
	}

	command error_t EcolStationNeighbourBS.startNei(){
		call AMControl.start();
		call RadioControl.start();
		post requestUART();
		call TelosbBuiltinSensors.readBattery();
		return TRUE;
	}
}