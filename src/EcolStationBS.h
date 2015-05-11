#ifndef ECOL_STATION_BS_H
#define ECOL_STATION_BS_H

typedef nx_struct CTPMsg{
	nx_uint8_t datatype;			//数据类型0x01土壤湿度，0x02雨量筒中断. (后续可扩展)
	nx_uint32_t id;						//数据包id，自增
	nx_uint16_t nodeid;				//节点编号
	nx_uint16_t data1;  				//	数据1（0x02类型数据填充温度值，0x01类型数据用1填充）
	nx_uint16_t data2;			    //	数据2（0x02类型数据填充空气湿度，0x01类型数据填充土壤湿度）
	nx_uint32_t eventtime;		//	包产生时间
}CTPMsg;										//共120bit，15字节

#define DATASIZE (sizeof(CTPMsg)+6)

#endif /* ECOL_STATION_BS_H */
