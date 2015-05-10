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
module BSCTPTestC{
	provides {
		interface Msp430UartConfigure as UartConfigure;
	}
	uses{
		interface Boot;
		interface SplitControl as RadioControl;
		interface StdControl as RoutingControl;
		interface Send;
		interface Leds;
		interface RootControl;
		interface Receive;
		interface TelosbTimeSyncBS;
		
		interface Resource;
		interface UartStream;
	}
}
implementation{
	
	uint8_t ecolStationData[DATASIZE];
	uint8_t AMrecvdataTemp[DATASIZE - 2 ];

	
	uint32_t realtime = 0;
	
	task void requestUART();
	task void releaseUART();
	
	event void Boot.booted(){
		call TelosbTimeSyncBS.Sync();
		call RadioControl.start();	
		post requestUART();				//可以向传感器们发送指令
	}
	
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
	}

	
	event void Send.sendDone(message_t* m, error_t err){
	}
	
	event message_t* Receive.receive(message_t* msg, void* payload, uint8_t len){
		CTPMsg* ctpmsg = (CTPMsg*)payload;
		int i;
		memset(AMrecvdataTemp,DATASIZE-2,0);
		memset(ecolStationData,DATASIZE,0);

		
		if(len == DATASIZE-2) 
		{
			call Leds.led1Toggle();
			memcpy(AMrecvdataTemp, ctpmsg, DATASIZE-2);
			ecolStationData[0] = 0x56;
			ecolStationData[DATASIZE-1] = 0xAA;
			
			for (i = 1;i < DATASIZE-1; i++)
				ecolStationData[i] = AMrecvdataTemp[i - 1];
			call Leds.led0On();
			call UartStream.send(ecolStationData, DATASIZE);
		}
		return msg;	
	}
	

	event void TelosbTimeSyncBS.SyncDone(uint32_t RealTime){
		realtime = RealTime;
	}
}