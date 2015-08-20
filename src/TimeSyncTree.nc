/**
modified :  Guodong, 2015/06/10
			Guodong, 2015/08/19
**/

interface TimeSyncTree{
	/**
	* Start the task of time synchronization
	* Only be invoked by the sink
	* @return: SUCCESS if this command is invoked by the sink; otherwise, FAIL.
	**/
	command error_t startTimeSync();

	/**
	* Signal in the completion of time synchronization
	* @param globalTime : the global unified clock
	*
	* NOT useful, because it is hard for the sink to know
	* the whole network is time synchronized.
	**/
	event error_t startTimeSyncDone( uint32_t globalTime );	


	/**
	* Return the current synchronized local clock
	**/
	command uint32_t getNow();

	/**
	* Return the number of time sync experienced by the current node
	**/
	command uint32_t getTimeSyncNum();

}

