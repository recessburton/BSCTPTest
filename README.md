Author:YTC 
Mail:recessburton@gmail.com
Created Time: 2015.5.9

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

Description：
	Telosb 带有CTP协议的基站测试程序.
	
Logs：
	V2.4 更新邻居发现组件为V0.8版本,修正快速排序中的错误。
	V2.3 更新邻居发现组件为V0.7版本,邻居关系数据中加入温湿度光强数据，去除LPL，发射功率调整为？？
	V2.2 重启前先关闭radio
	V2.1 链路质量评估包发送周期调整为555ms.采用最新时间同步组件，同步间隔调整为30s
	V2.0 加入了重启机制，每2小时重启一次
	V1.9 更新邻居发现组件为V0.6版本,调整链路质量计算方法
	V1.8 更新邻居发现组件为V0.5版本,修正邻居关系无法报告的问题
	V1.7 更新邻居发现组件为V0.4版本
	V1.6 发射功率调至最大，无线payload增大至35字节，在makefile中设置
	V1.5 加入了邻居节点信息的收集功能，BS通过CTP收集各个节点的邻居关系集(EcolStationNeighbourBS接口)，并通过UART发送给PC.
	V1.4 重新定义计时方式，BS发给PC的时间值改为传感器包产生时间与当前时间差。我们认为BS和PC通信没有时间差，
	     则这个时间差和PC时间进行运算，即可得到传感器包产生的正确时间
	V1.2 加入了时钟进位功能，32位时钟溢出后，向PC发送时间进位包0x00型
	V1.1 完善了时间获取机制，在PC数据包中加入了BS时间字段
	V1.0 全功能版本，将收到的数据包按照DataFormat重新格式化，发送给USB串口.
	V0.3 带有CTP和时间同步功能的数据接收
	
Known Bugs: 
		none.

