#ifndef TIME_SYNC_TREE_H
#define TIME_SYNC_TREE_H


#include <Timer.h>

enum {
	AM_TIME_SYNC_MSG= 177, // the typeid of messages used in time synchronization
	INITIAL_NODE_DEPTH = 256, // the initial depth of non-sink nodes before be time-synchronized
	INITIAL_SINK_DEPTH = 1, // the initial depth of the sink node before be time-sychronized

	SINK_NODE = 1, // the default number of the sink node

	MAX_DELAYED_BROADCAST_TIME = 50// in ms, the delayed time before broadcasting new time
};

/**
* The data structure corresponding to the time sync message.
**/
typedef nx_struct TimeSyncMsg {
	nx_uint16_t nid; // the node sending time sync messages
	nx_uint16_t depth;  // the depth of the sending node
	nx_uint32_t globalTime; // the global time in the view of the sending node
} time_sync_msg_t;

#endif
