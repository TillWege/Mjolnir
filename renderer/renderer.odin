package renderer

import "base:runtime"
import "core:fmt"
import "core:reflect"
import "core:time"
import "vendor:sdl3"
import "vendor:wgpu"
import "vendor:wgpu/sdl3glue"

Renderer :: struct {
	window:     ^sdl3.Window,
	surface:    wgpu.Surface,
	device:     wgpu.Device,
	queue:      wgpu.Queue,
	queue_data: ^Queue_User_Data,
}

@(private = "file")
request_adapter_sync :: proc(instance: wgpu.Instance) -> wgpu.Adapter {

	Queue_User_Data :: struct {
		result:          wgpu.Adapter,
		requestFinished: bool,
	}

	data: Queue_User_Data = {nil, false}


	on_adapter :: proc "c" (
		status: wgpu.RequestAdapterStatus,
		adapter: wgpu.Adapter,
		message: string,
		userdata1, userdata2: rawptr,
	) {
		context = runtime.default_context()
		data := transmute(^Queue_User_Data)userdata1

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

@(private = "file")
print_adapter_info :: proc(adapter: wgpu.Adapter) {
	limits, limit_status := wgpu.AdapterGetLimits(adapter)
	if limit_status == wgpu.Status.Success {
		fmt.println("Adpater Limits:")

		id := typeid_of(wgpu.Limits)
		names := reflect.struct_field_names(id)
		types := reflect.struct_field_types(id)
		tags := reflect.struct_field_tags(id)
		for tag, i in tags {
			name, type := names[i], types[i]
			val := reflect.struct_field_value_by_name(limits, name)

			if tag != "" {
				fmt.printf("\t%s: %v (%T) `%s`\n", name, val, type, tag)
			} else {
				fmt.printf("\t%s: %v (%T)\n", name, val, type)
			}
		}

	} else {
		fmt.println("Couldnt get limits")
	}

	features := wgpu.AdapterGetFeatures(adapter)

	fmt.println("Adapter Features:")
	for i in 0 ..< features.featureCount {
		fmt.printf("\t%s\n", features.features[i])
	}

	properties, info_status := wgpu.AdapterGetInfo(adapter)
	if info_status == wgpu.Status.Success {
		fmt.println("Adapter Properties:")
		id := typeid_of(wgpu.AdapterInfo)
		names := reflect.struct_field_names(id)
		types := reflect.struct_field_types(id)
		tags := reflect.struct_field_tags(id)
		for tag, i in tags {
			name, type := names[i], types[i]
			val := reflect.struct_field_value_by_name(properties, name)

			if tag != "" {
				fmt.printf("\t%s: %v (%T) `%s`\n", name, val, type, tag)
			} else {
				fmt.printf("\t%s: %v (%T)\n", name, val, type)
			}
		}
	}
}

@(private = "file")
on_device_lost :: proc "c" (
	device: ^wgpu.Device,
	reason: wgpu.DeviceLostReason,
	message: wgpu.StringView,
	userdata1: rawptr,
	userdata2: rawptr,
) {
	context = runtime.default_context()
	str := fmt.tprintf("Device Lost | Reason: %v | Message: %s", reason, message)
	panic(str)
}

@(private = "file")
on_device_error :: proc "c" (
	device: ^wgpu.Device,
	type: wgpu.ErrorType,
	message: wgpu.StringView,
	userdata1: rawptr,
	userdata2: rawptr,
) {
	context = runtime.default_context()
	str := fmt.tprintf("Device Error | Type: %v | Message: %s", type, message)
	panic(str)

}

@(private = "file")
request_device_sync :: proc(adapter: wgpu.Adapter) -> wgpu.Device {
	Queue_User_Data :: struct {
		result:          wgpu.Device,
		requestFinished: bool,
	}

	data: Queue_User_Data = {nil, false}

	on_device :: proc "c" (
		status: wgpu.RequestDeviceStatus,
		device: wgpu.Device,
		message: string,
		userdata1, userdata2: rawptr,
	) {
		context = runtime.default_context()
		data := transmute(^Queue_User_Data)userdata1

		if device == nil {
			fmt.println("Error getting Device: ", message)
		} else {
			data.result = device
		}
		data.requestFinished = true
	}

	callbackInfo: wgpu.RequestDeviceCallbackInfo = {}
	callbackInfo.callback = on_device
	callbackInfo.userdata1 = &data

	options: wgpu.DeviceDescriptor = {
		label = "Mjolnir Device",
		requiredFeatures = {},
		requiredFeatureCount = 0,
		requiredLimits = {},
		defaultQueue = {label = "Mjolnir Queue", nextInChain = nil},
		deviceLostCallbackInfo = {callback = on_device_lost},
		uncapturedErrorCallbackInfo = {callback = on_device_error},
	}

	wgpu.AdapterRequestDevice(adapter, &options, callbackInfo)

	for !data.requestFinished {
		time.sleep(time.Millisecond)
	}

	return data.result
}

@(private = "file")
print_device_info :: proc(device: wgpu.Device) {
	features := wgpu.DeviceGetFeatures(device)
	fmt.printf("Got %d Features", features.featureCount)

	fmt.println("Device Features:")
	for i in 0 ..< features.featureCount {
		fmt.printf("%s", features.features[i])
	}

	limits, status := wgpu.DeviceGetLimits(device)
	if status == wgpu.Status.Success {
		fmt.println("Device Limits:")
		id := typeid_of(wgpu.Limits)
		names := reflect.struct_field_names(id)
		types := reflect.struct_field_types(id)
		tags := reflect.struct_field_tags(id)
		for tag, i in tags {
			name, type := names[i], types[i]
			val := reflect.struct_field_value_by_name(limits, name)

			if tag != "" {
				fmt.printf("	%s: %v (%T) `%s`", name, val, type, tag)
			} else {
				fmt.printf("	%s: %v (%T)", name, val, type)
			}
			fmt.print("")
		}
	}
}

Queue_User_Data :: struct {
	done:    bool,
	success: bool,
}

@(private = "file")
on_queue_done := proc "c" (status: wgpu.QueueWorkDoneStatus, userData: rawptr, userData2: rawptr) {
	context = runtime.default_context()
	fmt.printfln("Queue work done with status: %v", status)


	fmt.printfln("Userdata pointer: %v", userData)
	data := transmute(^Queue_User_Data)userData
	data.done = true
	data.success = true
}

init_renderer :: proc() -> (Renderer, bool) {
	wgpu_instance := wgpu.CreateInstance(nil)
	defer wgpu.InstanceRelease(wgpu_instance)

	if wgpu_instance == nil {
		fmt.println("WGPU instance creation failed")
		return {}, false
	} else {
		fmt.println("WGPU instance created successfully")
	}

	adapter := request_adapter_sync(wgpu_instance)
	defer wgpu.AdapterRelease(adapter)

	if adapter == nil {
		fmt.println("WGPU Adapter creation failed")
		return {}, false
	} else {
		fmt.println("WGPU Adapter creation successfully")
	}

	device := request_device_sync(adapter)

	if device == nil {
		fmt.println("WGPU Device creation failed")
		return {}, false
	} else {
		fmt.println("WGPU Device creation successfully")
	}

	queue := wgpu.DeviceGetQueue(device)
	queue_user_data := new(Queue_User_Data)

	wgpu.QueueOnSubmittedWorkDone(
		queue,
		wgpu.QueueWorkDoneCallbackInfo{callback = on_queue_done, userdata1 = &queue_user_data},
	)

	window := sdl3.CreateWindow("Mjolnir", 800, 600, nil)

	if window == nil {
		fmt.println("Window creation failed")
		return {}, false
	} else {
		fmt.println("Window created successfully")
	}

	surface := sdl3glue.GetSurface(wgpu_instance, window)

	if surface == nil {
		fmt.println("Surface creation failed")
		return {}, false
	} else {
		fmt.println("Surface created successfully")
	}

	surfaceConfig := wgpu.SurfaceConfiguration {
		width           = 800,
		height          = 800,
		viewFormatCount = 0,
		format          = .BGRA8Unorm,
		usage           = {wgpu.TextureUsage.RenderAttachment},
		device          = device,
		presentMode     = .Fifo,
		alphaMode       = .Auto,
	}

	wgpu.SurfaceConfigure(surface, &surfaceConfig)

	return {
			window = window,
			surface = surface,
			device = device,
			queue = queue,
			queue_data = queue_user_data,
		},
		true
}

renderer_test_command_queue :: proc(renderer: ^Renderer) -> bool {

	renderer.queue_data.done = false
	renderer.queue_data.success = false

	encoderDesc := wgpu.CommandEncoderDescriptor {
		label = "Testing command encoder",
	}

	encoder := wgpu.DeviceCreateCommandEncoder(renderer.device, &encoderDesc)

	wgpu.CommandEncoderInsertDebugMarker(encoder, "Testing Marker")

	cmdBufferDesc := wgpu.CommandBufferDescriptor {
		label = "Testing command buffer",
	}

	cmdBuffer := wgpu.CommandEncoderFinish(encoder, &cmdBufferDesc)

	bufferArr := []wgpu.CommandBuffer{cmdBuffer}
	wgpu.QueueSubmit(renderer.queue, bufferArr)

	wgpu.QueueOnSubmittedWorkDone(
		renderer.queue,
		wgpu.QueueWorkDoneCallbackInfo{callback = on_queue_done, userdata1 = renderer.queue_data},
	)

	wgpu.CommandBufferRelease(cmdBuffer)
	wgpu.CommandEncoderRelease(encoder)

	for !renderer.queue_data.done {
		wgpu.DevicePoll(renderer.device, true, nil)
	}

	return renderer.queue_data.success
}

deinit_renderer :: proc(renderer: Renderer) {
	wgpu.SurfaceRelease(renderer.surface)
	sdl3.DestroyWindow(renderer.window)
	wgpu.QueueRelease(renderer.queue)
	free(renderer.queue_data)
	wgpu.DeviceRelease(renderer.device)
}
