/**
 Copyright (C),2014-2015, YTC, www.bjfulinux.cn
 Copyright (C),2014-2015, ENS Group, ens.bjfu.edu.cn
 Created on  2015-04-28 10:59
 
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

module TelosbTimeSyncBSP {

	provides interface TelosbTimeSyncBS;

	uses interface Timer<TMilli> as Timer0;
	uses interface Packet;
	uses interface AMSend;
	uses interface LocalTime<TMilli> as BaseTime;

}
implementation {

	volatile bool busy = FALSE;

	message_t pkt;

	uint16_t Depth = 0;	//生成树深度
	uint32_t SyncTime = 0; //基站的时间,4字节  

	typedef nx_struct TimeSyncMsg {
		nx_uint16_t nodeid;
		nx_uint16_t index;
		nx_uint32_t realtime;
	} TimeSyncMsg;

	event void Timer0.fired() {
		if( ! busy) {
			TimeSyncMsg * btrpkt = (TimeSyncMsg * )(call Packet.getPayload(&pkt, NULL));
			btrpkt->nodeid = TOS_NODE_ID;
			btrpkt->index = Depth;	//树深度:基站为0
			SyncTime = call BaseTime.get();	//获取当前时间
			btrpkt->realtime = SyncTime;
			if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(TimeSyncMsg)) == SUCCESS) {
				busy = TRUE;
			}
		}
	}

	event void AMSend.sendDone(message_t * msg, error_t error) {
		if(&pkt == msg) {
			busy = FALSE;
			signal TelosbTimeSyncBS.SyncDone(call BaseTime.get());	//在使用本接口的模块中需要实现的触发事件
		}
	}

	command error_t TelosbTimeSyncBS.Sync(){	//本接口提供的可调用的命令
		signal Timer0.fired();			//启动后马上发布一次时间信息
		call Timer0.startPeriodic(1024 * 30);
		return TRUE;
	}
	
	command uint32_t TelosbTimeSyncBS.getTime(){
		uint32_t time = call BaseTime.get();
		return  time;
	}

}