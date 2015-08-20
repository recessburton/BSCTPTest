/**
 Copyright (C),2014-2015, YTC, www.bjfulinux.cn
 Copyright (C),2014-2015, ENS Group, ens.bjfu.edu.cn
 Created on  2015-04-27 16:21
 
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

 
#include "TimeSyncTree.h"

generic configuration TimeSyncTreeC( uint32_t period ) {

	provides interface TimeSyncTree;
}

implementation {

	components new TimeSyncTreeP(period);

	TimeSyncTree = TimeSyncTreeP.TimeSyncTree;

	components new TimerMilliC() as SyncTimer;
	TimeSyncTreeP.PeriodicSyncTimer     -> SyncTimer;
	TimeSyncTreeP.DelayedBroadcastTimer -> SyncTimer;

	components HilTimerMilliC as LocalTimer;
	TimeSyncTreeP.LocalTime -> LocalTimer;
			
	components new AMSenderC(AM_TIME_SYNC_MSG);
	components new AMReceiverC(AM_TIME_SYNC_MSG);

	TimeSyncTreeP.Packet   -> AMSenderC;
	TimeSyncTreeP.AMSend   -> AMSenderC;
	TimeSyncTreeP.Receive  -> AMReceiverC;

	components RandomC;
	TimeSyncTreeP.Random -> RandomC;
}