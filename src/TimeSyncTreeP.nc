/**
 Copyright (C),2014-2015, YTC, www.bjfulinux.cn
 Copyright (C),2014-2015, ENS Group, ens.bjfu.edu.cn
 Created on  2015-04-27 16:21
 
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

 @author: ytc recessburton@gmail.com
 @version: 1.0
 modified : Guodong, 2015/08/19

 **/


#include "TimeSyncTree.h"

generic module TimeSyncTreeP( uint32_t period ) {

	provides interface TimeSyncTree;

	uses interface Timer<TMilli> as PeriodicSyncTimer; 
	uses interface Timer<TMilli> as DelayedBroadcastTimer;
	uses interface LocalTime<TMilli> as LocalTime;  
	uses interface Packet;
	uses interface AMSend;
	uses interface Receive;	

	uses interface Random;
}
implementation {

	uint32_t timeSyncNum = 0; // the number of the time sychn operations

	volatile int32_t offset = 0;
	volatile bool    radioBusy = FALSE;

	message_t pkt;

	uint16_t  depth  = INITIAL_NODE_DEPTH;	     
	uint16_t  parent = 0; 

	task void broadcastTimeSyncMsg();

	/////////////////////////////////////////////////////////////////////////////////

	/**
	* This command can be invoked only by the sink; if not, invalid.
	**/
	command error_t TimeSyncTree.startTimeSync() {
		if( TOS_NODE_ID == SINK_NODE ) {
			depth  = 1;
			parent = 0;
			call PeriodicSyncTimer.startPeriodic( period );
			timeSyncNum++;
			return SUCCESS; 
		} else {
			return FAIL;
		}
	}

	/**
	* This event will be signaled only at the sink.
	**/
	event void PeriodicSyncTimer.fired() {
		if( !radioBusy ) {
			time_sync_msg_t *btrpkt = (time_sync_msg_t*) (call Packet.getPayload(&pkt,sizeof(time_sync_msg_t)) );
			if( btrpkt != NULL) {
				btrpkt->nid        = TOS_NODE_ID;
				btrpkt->depth      = depth;
				btrpkt->globalTime = call LocalTime.get();

				if(call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(time_sync_msg_t) == SUCCESS)){
					radioBusy = TRUE;
				} else {

				}
			}
		}
	}

	event void AMSend.sendDone( message_t * msg, error_t error ) {
		if( error == SUCCESS && msg == &pkt ) {
			radioBusy = FALSE;
			if( TOS_NODE_ID == SINK_NODE ) {
				signal TimeSyncTree.startTimeSyncDone( call LocalTime.get() );	
			}
		}
	}	

	/**
	* The receive event makes sense only at the non-sink nodes, i.e., the sink 
	* will discard the received time sync messages directly, without any further 
	* processing.
	**/
	event message_t * Receive.receive(message_t * msg, void * playload, uint8_t len){
		time_sync_msg_t * btrpkg = (time_sync_msg_t*) playload;
		if( TOS_NODE_ID != SINK_NODE && len == sizeof(time_sync_msg_t) ) {

			if( parent == btrpkg->nid ) {// receive a packet sent by the parent
				offset = btrpkg->globalTime - (call LocalTime.get() );
				timeSyncNum++;
				post broadcastTimeSyncMsg(); // to broadcast the time updated right now
			} else {
				if( btrpkg->depth + 1 < depth) {
					depth  = btrpkg->depth + 1;
					parent = btrpkg->nid;
					post broadcastTimeSyncMsg();
				}
			}
		}
		return msg;
	}

	/**
	* For each broadcasting message, multiple nodes will possibly receive it and then
	* the broadcasting explosion will ensue after those nodes broadcast their updated 
	* time in neighborhood.
	*
	* To avoid such an event, force each node updating its clock to defer its broadcasting
	* with a randomly chosen time.
	**/
	task void broadcastTimeSyncMsg() {
		uint32_t randDelay = (call Random.rand32()) % MAX_DELAYED_BROADCAST_TIME + 1;
		call DelayedBroadcastTimer.startOneShot( randDelay );
	}

	event void DelayedBroadcastTimer.fired() {
		time_sync_msg_t* btrpkt = (time_sync_msg_t*) call Packet.getPayload(&pkt,sizeof(time_sync_msg_t));
		if( !radioBusy ) {
			if( btrpkt != NULL ) {
				btrpkt->nid   = TOS_NODE_ID;
				btrpkt->depth = depth;
				btrpkt->globalTime = call TimeSyncTree.getNow();
				if( call AMSend.send(AM_BROADCAST_ADDR, &pkt, sizeof(time_sync_msg_t) ) == SUCCESS ) {
					radioBusy = TRUE;
				} else {}
			}
		}
	}

	command uint32_t TimeSyncTree.getTimeSyncNum() {  return timeSyncNum;  }
	
	command uint32_t TimeSyncTree.getNow() { return  (call LocalTime.get()) + offset;	}

}