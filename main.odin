package main

import "base:runtime"
import "core:fmt"
import "core:os"
import "core:reflect"
import "core:time"
import "vendor:sdl3"
import "vendor:wgpu"
import "vendor:wgpu/sdl3glue"


wgpu_struc :: struct {
	device: wgpu.Device,
}

RequestAdapterSync :: proc(instance: wgpu.Instance) -> wgpu.Adapter {

	UserData :: struct {
		result:          wgpu.Adapter,
		requestFinished: bool,
	}

	data: UserData = {nil, false}


	on_adapter :: proc "c" (
		status: wgpu.RequestAdapterStatus,
		adapter: wgpu.Adapter,
		message: string,
		userdata1, userdata2: rawptr,
	) {
		context = runtime.default_context()
		data := transmute(^UserData)userdata1

		if adapter == nil {
			fmt.println("Error getting Adapter: ", message)
		} else {
			data.result = adapter
		}

		data.requestFinished = true
	}

	callbackInfo: wgpu.RequestAdapterCallbackInfo = {}
	callbackInfo.callback = on_adapter
	callbackInfo.userdata1 = &data

	options: wgpu.RequestAdapterOptions = {}

	wgpu.InstanceRequestAdapter(instance, &options, callbackInfo)

	for !data.requestFinished {
		time.sleep(time.Millisecond)
	}

	return data.result
}

printLimits :: proc(adapter: wgpu.Adapter) {
	limits, status := wgpu.AdapterGetLimits(adapter)
	if status == wgpu.Status.Success {
		fmt.println("Adpater Limits:")

		id := typeid_of(wgpu.Limits)
		names := reflect.struct_field_names(id)
		types := reflect.struct_field_types(id)
		tags := reflect.struct_field_tags(id)
		for tag, i in tags {
			name, type := names[i], types[i]
			val := reflect.struct_field_value_by_name(limits, name)

			if tag != "" {
				fmt.printf("\t%s: %v (%T) `%s`", name, val, type, tag)
			} else {
				fmt.printf("\t%s: %v (%T)", name, val, type)
			}
			fmt.print("\n")
		}

	} else {
		fmt.println("Couldnt get limits")
	}
}

printFeatures :: proc(adapter: wgpu.Adapter) {
	features := wgpu.AdapterGetFeatures(adapter)

	fmt.println("Adapter Features:")
	for i in 0 ..< features.featureCount {
		fmt.printf("\t%s\n", features.features[i])
	}
}

printProperties :: proc(adapter: wgpu.Adapter) {
	properties, status := wgpu.AdapterGetInfo(adapter)
	if status == wgpu.Status.Success {
		fmt.println("Adapter Properties:")
		id := typeid_of(wgpu.AdapterInfo)
		names := reflect.struct_field_names(id)
		types := reflect.struct_field_types(id)
		tags := reflect.struct_field_tags(id)
		for tag, i in tags {
			name, type := names[i], types[i]
			val := reflect.struct_field_value_by_name(properties, name)

			if tag != "" {
				fmt.printf("\t%s: %v (%T) `%s`", name, val, type, tag)
			} else {
				fmt.printf("\t%s: %v (%T)", name, val, type)
			}
			fmt.print("\n")
		}
	}
}

main :: proc() {
	flags := sdl3.InitFlags{.VIDEO, .EVENTS}
	sdlRes := sdl3.Init(flags)

	if sdlRes == false {
		fmt.println("SDL initialization failed")
		os.exit(1)
	} else {
		fmt.println("SDL initialized successfully")
	}


	window := sdl3.CreateWindow("Odin Rendering", 800, 600, nil)

	if window == nil {
		fmt.println("Window creation failed")
		os.exit(1)
	} else {
		fmt.println("Window created successfully")
	}

	wgpu_instance := wgpu.CreateInstance(nil)

	if wgpu_instance == nil {
		fmt.println("WGPU instance creation failed")
		os.exit(1)
	} else {
		fmt.println("WGPU instance created successfully")
	}

	surface := sdl3glue.GetSurface(wgpu_instance, window)

	if surface == nil {
		fmt.println("Surface creation failed")
		os.exit(1)
	} else {
		fmt.println("Surface created successfully")
	}

	adapter := RequestAdapterSync(wgpu_instance)
	wgpu.InstanceRelease(wgpu_instance)

	if adapter == nil {
		fmt.println("Fuck")
		os.exit(1)
	} else {
		fmt.println("Got Adapter")
	}

	printLimits(adapter)
	printFeatures(adapter)
	printProperties(adapter)

	event: sdl3.Event
	running := true

	for running {
		for sdl3.PollEvent(&event) {
			if event.type == sdl3.EventType.QUIT {
				fmt.println("Quitting...")
				running = false
			}
		}
	}

	sdl3.DestroyWindow(window)
	sdl3.Quit()


	os.exit(0)
}
