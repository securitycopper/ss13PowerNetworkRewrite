/*
	These are simple defaults for your project.
 */

world
	fps = 25		// 25 frames per second
	icon_size = 32	// 32x32 icon size by default

	view = 6		// show up to 6 tiles outward from center (13x13 view)


// Make objects move 8 pixels per tick when walking

mob
	step_size = 8

obj
	step_size = 8

var/global/datum/power/PowerNode/apsForLighting
#define DEBUG_POWERNODE_BATTERY 1
#define DEBUG_WIRENETWORK_PROCESS 1
#define DEBUG_WIRENETWORK_ADD 1
#define DEBUG_WIRENETWORK_PRINT_TREE 1
client/verb
	TestBuiltInPowerNetwork()

		var/datum/wire_network/powerNetworkOne = new /datum/wire_network()
		powerNetworkOne.setName = "PowerNetwork1"


		//############## Generator 1 ##################//
		//Create Generator
		var/datum/power/PowerNode/constantGeneratorOne = new /datum/power/PowerNode()
		//parent network

		//Power Node Behavior
		constantGeneratorOne.setName = "Constant Output Generator 1"
		constantGeneratorOne.setCanAutoStartToIdle = 1
		constantGeneratorOne.setIdleLoad = 0
		constantGeneratorOne.setCurrentLoad = 0
		constantGeneratorOne.setMaxPotentialSupply = 400
		constantGeneratorOne.setCurrentSupply = 400

		//Battery options
		constantGeneratorOne.setHasBattery=0
		constantGeneratorOne.setBatteryMaxCapacity=0
		constantGeneratorOne.setBatteryChargeRate=0
		//constantGeneratorOne.setBatteryMaxDischargeRate=0

		//Attach Parent Network
		constantGeneratorOne.parentNetwork = powerNetworkOne

		constantGeneratorOne.update()

		powerNetworkOne.add(constantGeneratorOne)

		//############## Machine 1 ##################//
		var/datum/power/PowerNode/vendingMachineNode = new /datum/power/PowerNode()
		//Power Node Behavior
		vendingMachineNode.setName = "Vending Machine 1"
		vendingMachineNode.setCanAutoStartToIdle = 1
		vendingMachineNode.setIdleLoad = 50
		vendingMachineNode.setCurrentLoad = 0
		vendingMachineNode.setMaxPotentialSupply = 0
		vendingMachineNode.setCurrentSupply = 0

		//Battery options
		vendingMachineNode.setHasBattery=0
		vendingMachineNode.setBatteryMaxCapacity=0
		vendingMachineNode.setBatteryChargeRate=0
		//vendingMachineNode.setBatteryMaxDischargeRate=0

		//Attach to parent network
		vendingMachineNode.parentNetwork = powerNetworkOne
		vendingMachineNode.update()
		powerNetworkOne.add(vendingMachineNode)


		//############## APS 1 ##################//
		apsForLighting = new /datum/power/PowerNode()

		//Power Node Behavior
		apsForLighting.setName = "APS 1"
		apsForLighting.setCanAutoStartToIdle = 1
		apsForLighting.setIdleLoad = 50
		apsForLighting.setCurrentLoad = 0
		apsForLighting.setMaxPotentialSupply = 0
		apsForLighting.setCurrentSupply = 0

		//Battery options
		apsForLighting.setHasBattery=1
		apsForLighting.setBatteryMaxCapacity=50000
		apsForLighting.setBatteryChargeRate=100
		//apsForLighting.setBatteryMaxDischargeRate=400

		//Attach to parent network
		apsForLighting.parentNetwork = powerNetworkOne
		apsForLighting.update()
		powerNetworkOne.add(apsForLighting)




		world << "Built wire network, don't run this again as it will keep adding to the master lists new networks"


	TestBuiltInPowerNetwork_AddLightToAPS()
		if(apsForLighting==null)
			return

		if(apsForLighting.childNetwork == null)
			//Create new child network
			var/datum/wire_network/powerNetworkAPS = new /datum/wire_network()
			powerNetworkAPS.setName = "Aps lighting network"
			apsForLighting.childNetwork =powerNetworkAPS
			powerNetworkAPS.add(apsForLighting)

		//############## Generic Light ##################//
		var/datum/power/PowerNode/light = new /datum/power/PowerNode()

		//Power Node Behavior
		light.setName = "Light"
		light.setCanAutoStartToIdle = 1
		light.setIdleLoad = 10
		light.setCurrentLoad = 0
		light.setMaxPotentialSupply = 0
		light.setCurrentSupply = 0

		//Battery options
		light.setHasBattery=0
		light.setBatteryMaxCapacity=0
		light.setBatteryChargeRate=0
		//light.setBatteryMaxDischargeRate=0

		//Attach to parent network
		light.parentNetwork = apsForLighting.childNetwork
		light.update()
		apsForLighting.childNetwork.add(light)

/*

TODO: i need to have a calculated battery discharge rate
battery discharge rate is child network load even if powerd by grid
max potentioal child supply is the min of maxDischarge rate and calculated stored energy

no reason to have a max discharge rate so i'll comment that out for now.

*/



	TestBuiltInPowerNetwork_SimulateTick()

		//Simulate an iteration
		for(var/datum/power/PowerNode/powerNodeWithBattery in powerNetworkControllerPowerNodeOnBatteryProcessingLoopList)
			powerNodeWithBattery.prcessBattery()

		for(var/datum/wire_network/wireNetwork in powerNetworkControllerProcessingLoopList)
			wireNetwork.process()
			#if defined(DEBUG_WIRENETWORK_PRINT_TREE)
			wireNetwork.debugDebugNetwork()
			#endif









