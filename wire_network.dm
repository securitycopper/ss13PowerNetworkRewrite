/datum/wire_network

//Note: with this system, extra supply that isn't spent in load is lost.
	var/setName = "Generic Power Network"

	var/wireNetworkMaxPotentialSupply = 0
	var/wireNetworkCurrentSupply = 0
	var/wireNetworkLoad = 0;

	//var/autoRestartLoad = 0;

	//Linked list because of rolling brownouts
	var/datum/datastructures/LinkedList/brownOutList = new /datum/datastructures/LinkedList()
	var/list/autoRestartListOff = list()
	var/list/autoRestartListOn = list()

	var/datum/datastructures/LinkedList/manualRestartList = new /datum/datastructures/LinkedList()





	var/list/powerNodesThatCanSupplyPower = list()
	var/list/powerNodesThatCanNotSupplyPower = list()

	var/oldwireNetworkMaxPotentialSupply = 0

	var/list/allNonWiresConnected = list()

	var/size = 0;

/datum/wire_network/New()

	powerNetworkControllerProcessingLoopList+=src





/datum/wire_network/proc/debugDebugNetwork()
	world << "[setName] - Current Load([wireNetworkLoad]/[wireNetworkCurrentSupply]) Max Potential Supply = [wireNetworkMaxPotentialSupply], "

	for(var/datum/power/PowerNode/node in powerNodesThatCanSupplyPower)
		world << "--> Supply: [node.setName] - isOn = [node.isOn], Load=[node.setCurrentLoad], Supply([node.setCurrentSupply]/[node.setMaxPotentialSupply]), Battery([node.calculatedBatteryStoredEnergy]/[node.setBatteryMaxCapacity]+[node.setBatteryChargeRate]-[node.calculatedCurrentBatteryDistargeRate])"
	for(var/datum/power/PowerNode/node in powerNodesThatCanNotSupplyPower)
		world << "--> Consumer: [node.setName] - isOn = [node.isOn], Load=[node.setCurrentLoad], Supply([node.setCurrentSupply]/[node.setMaxPotentialSupply]), Battery([node.calculatedBatteryStoredEnergy]/[node.setBatteryMaxCapacity]+[node.setBatteryChargeRate]-[node.calculatedCurrentBatteryDistargeRate])"


/datum/wire_network/proc/process()
	#if defined(DEBUG_WIRENETWORK_PROCESS)
	world<< "DEBUG: [setName] process(): AutoRestartLestSize=[autoRestartListOff.len], load capacity used ([wireNetworkLoad]/[wireNetworkCurrentSupply]) "
	#endif
	//check to see if current supply is enough for load,
	if(wireNetworkCurrentSupply>=wireNetworkLoad && autoRestartListOff.len ==0)
		return

	//1. request more power from supply
	for(var/datum/power/PowerNode/supply in powerNodesThatCanSupplyPower)
		if(wireNetworkCurrentSupply<wireNetworkLoad)
			#if defined(DEBUG_WIRENETWORK_PROCESS)
			world<< "DEBUG: [setName] process(): requesting More power from [supply.setName] "
			#endif
			supply.aditionalPowerRequest(src,wireNetworkLoad-wireNetworkCurrentSupply)
			//Bateries will then increase there output if below max output

	//2. Turn things off
	/*
		2a. If total after all power is requested from supply, then cycle though items that can be automaticly restarted and turn them off
			This will keep non automatic restarting nodes on as long as possible
	*/
	/*
	if(wireNetworkCurrentSupply>wireNetworkLoad)
	var/i =0;
	var/size = brownOutList.size  //This saves a call to .size in loop
	while(wireNetworkCurrentSupply<wireNetworkLoad && i<size)
		i++
		ar/datum/power/PowerNode/powerNode = autoRestartListOff.Cut(I+,2)

	*/

	//TODO: Rewrite this logic

	//2b. Now loop through manual start up itesm and force them to brown out untill power is balanced

	//3 If there is excess power, turn things back on


	//Turns things off

	if(wireNetworkCurrentSupply<wireNetworkLoad)
		var/i =0;
		var/size = brownOutList.size
		while(wireNetworkCurrentSupply<wireNetworkLoad && i<size)
			i++
			//This list contains all elments, just an easy way to cycle throw all machines evenly
			var/datum/power/PowerNode/powerNode = brownOutList.removeFirst();
			if(powerNode==null)
				world<< "ERROR: [setName] process(): null value was detected in brownOutList.removeFirst(), there is a logic bug somewhere"

			brownOutList.add(powerNode)

			//Don't bother turning off if already off
			if(powerNode.isOn ==1)
				//If autoMaticList to turn on and now we are turning off,then we need to move it from on list to off list
				if(powerNode.setCanAutoStartToIdle==1)
					autoRestartListOn-=powerNode
					autoRestartListOff+=powerNode



				powerNode.forceBrownOut()

/*

	var/i =0;
	var/size = brownOutList.size
	while(wireNetworkCurrentSupply>wireNetworkLoad && i<size)
		i++
		//This list contains all elments, just an easy way to cycle throw all machines evenly
		var/datum/power/PowerNode/powerNode = brownOutList.removeFirst();
		if(powerNode==null)
			world<< "ERROR: [setName] process(): null value was detected in brownOutList.removeFirst(), there is a logic bug somewhere"

		brownOutList.add(powerNode)

		//Don't bother turning on if already on
		if(powerNode.isOn ==1)
			continue

		//If autoMaticList to turn on and now we are turning off,then we need to move it from on list to off list

		if(powerNode.setCanAutoStartToIdle==1 && powerNode.parentNetwork == src )
			powerNode.requestPowerOn()
			autoRestartListOff-=powerNode
			autoRestartListOn+=powerNode
*/
	for(var/datum/power/PowerNode/powerNode in autoRestartListOff)
		if(powerNode.setCanAutoStartToIdle==1 && powerNode.parentNetwork == src ) //&& powerNode.calculatedTotalLoad + wireNetworkLoad <=wireNetworkMaxPotentialSupply
			powerNode.requestPowerOn()
			if(powerNode.isOn==1)
				autoRestartListOff-=powerNode
				autoRestartListOn+=powerNode

/* TODO This should be faster but has a null pointer bug so going to go with above logic
	//3. Attempt to start auto start if there is power
	if(wireNetworkCurrentSupply>wireNetworkLoad)
		#if defined(DEBUG_WIRENETWORK_PROCESS)
		world<< "DEBUG: [setName] process(): There is power, starting auto restarts if able "
		#endif
		var/i =0;
		var/size = autoRestartListOff.len
		while(wireNetworkMaxPotentialSupply>=wireNetworkLoad && i<size)
			i++
			//pop
			var/datum/power/PowerNode/powerNode = autoRestartListOff.Cut(1,2)
//			if(powerNode==null)
//				world<< "ERROR: [setName] process(): null value was detected in autoRestartListOff, there is a logic bug somewhere"
//				continue
			//Check to see if power node is already on
			if (powerNode.isOn==1)
				autoRestartListOn.Add(powerNode)
			else
				if(powerNode.calculatedTotalLoad+wireNetworkLoad<=wireNetworkMaxPotentialSupply)
					powerNode.requestPowerOn()
					autoRestartListOn.Add(powerNode)
				else
					autoRestartListOff.Add(powerNode)

			//if (powerNode.isOn==1)
			//If there isn't enough power

			//else
				//autoRestartListOff.Add(powerNode)
*/
/*

	//TODO: There is redundent logic in this method
	if(oldwireNetworkMaxPotentialSupply!=wireNetworkMaxPotentialSupply)
		oldwireNetworkMaxPotentialSupply=wireNetworkMaxPotentialSupply
		for(var/datum/power/PowerNode/offNode in autoRestartListOff)
			offNode.requestPowerOn()
			if(offNode.isOn==1)
				autoRestartListOff-=offNode
				autoRestartListOn+=offNode
*/


/datum/wire_network/proc/add(var/datum/power/PowerNode/powerNode)



	//If the powerNode child node is this network, it goes in supply list
	//Example its an aps
	if(powerNode.childNetwork == src)
		powerNodesThatCanSupplyPower.Add(powerNode)
		#if defined(DEBUG_WIRENETWORK_ADD)
		world<< "DEBUG: [setName] add(): ChildNetworkCanSupplyPower"
		#endif

	if(powerNode.parentNetwork==src)
		#if defined(DEBUG_WIRENETWORK_ADD)
		world<< "DEBUG: [setName] add(): ParentNetwork = src"
		#endif

		if(powerNode.setMaxPotentialSupply>0)
			powerNodesThatCanSupplyPower.Add(powerNode)
			//Supply nodes where they contribute to parent will atempt to go on now if able
			#if defined(DEBUG_WIRENETWORK_ADD)
			world<< "DEBUG: [setName] add(): Starting supply: [powerNode.setName]"
			#endif
			powerNode.requestPowerOn()

		else
			powerNodesThatCanNotSupplyPower.Add(powerNode)
			brownOutList.add(powerNode)


		if(powerNode.setCanAutoStartToIdle == 1 )

			if(powerNode.isOn == 1)
				autoRestartListOn+=powerNode
			else
				autoRestartListOff+=powerNode
		else
			manualRestartList.add(powerNode)







	allNonWiresConnected.Add(powerNode)

/*
/datum/wire_network/proc/get_electrocute_damage()
	switch(wireNetworkSupply - wireNetworkLoad)/*
		if (1300000 to INFINITY)
			return min(rand(70,150),rand(70,150))
		if (750000 to 1300000)
			return min(rand(50,115),rand(50,115))
		if (100000 to 750000-1)
			return min(rand(35,101),rand(35,101))
		if (75000 to 100000-1)
			return min(rand(30,95),rand(30,95))
		if (50000 to 75000-1)
			return min(rand(25,80),rand(25,80))
		if (25000 to 50000-1)
			return min(rand(20,70),rand(20,70))
		if (10000 to 25000-1)
			return min(rand(20,65),rand(20,65))
		if (1000 to 10000-1)
			return min(rand(10,20),rand(10,20))*/
		if (1000000 to INFINITY)
			return min(rand(50,160),rand(50,160))
		if (200000 to 1000000)
			return min(rand(25,80),rand(25,80))
		if (100000 to 200000)//Ave powernet
			return min(rand(20,60),rand(20,60))
		if (50000 to 100000)
			return min(rand(15,40),rand(15,40))
		if (1000 to 50000)
			return min(rand(10,20),rand(10,20))
		else
			return 0

		*/