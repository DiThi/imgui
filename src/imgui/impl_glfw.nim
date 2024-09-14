# Copyright 2018, NimGL contributors.

## ImGUI GLFW Implementation
## ====
## Implementation based on the imgui examples implementations.
## Feel free to use and modify this implementation.
## This needs to be used along with a Renderer.

import ../imgui
import nglfw
# import nimgl/glfw

# when defined(windows):
#   import nimgl/glfw/native

type
  GlfwClientApi = enum
    igGlfwClientApiUnkown
    igGlfwClientApiOpenGl
    igGlfwClientApiVulkan

var
  gWindow: nglfw.Window
  gClientApi = igGlfwClientApiUnkown
  gTime: float64 = 0.0f
  gMouseJustPressed: array[5, bool]
  gMouseCursors: array[ImGuiMouseCursor.high.int32 + 1, nglfw.CursorHandle]

  # Store previous callbacks so they can be chained
  gPrevMouseButtonCallback: nglfw.MouseButtonFun = nil
  gPrevScrollCallback: nglfw.ScrollFun = nil
  gPrevKeyCallback: nglfw.KeyFun = nil
  gPrevCharCallback: nglfw.CharFun = nil

proc igGlfwGetClipboardText(userData: pointer): constCstring {.cdecl.} =
  cast[nglfw.Window](userData).getClipboardString()

proc igGlfwSetClipboardText(userData: pointer, text: constCstring): void {.cdecl.} =
  cast[nglfw.Window](userData).setClipboardString(text)

proc igGlfwMouseCallback*(window: nglfw.Window, button: int32, action: int32, mods: int32): void {.cdecl.} =
  if gPrevMouseButtonCallback != nil:
    gPrevMouseButtonCallback(window, button, action, mods)

  if action == nglfw.PRESS and button.ord >= 0 and button.ord < gMouseJustPressed.len:
    gMouseJustPressed[button.ord] = true

proc igGlfwScrollCallback*(window: nglfw.Window, xoff: float64, yoff: float64): void {.cdecl.} =
  if gPrevScrollCallback != nil:
    gPrevScrollCallback(window, xoff, yoff)

  let io = igGetIO()
  io.mouseWheelH += xoff.float32
  io.mouseWheel += yoff.float32

proc igGlfwKeyCallback*(window: nglfw.Window, key: int32, scancode: int32, action: int32, mods: int32): void {.cdecl.} =
  if gPrevKeyCallback != nil:
    gPrevKeyCallback(window, key, scancode, action, mods)

  let io = igGetIO()
  if key.ord < 511 and key.ord >= 0:
    if action == nglfw.PRESS:
      io.keysDown[key.ord] = true
    elif action == nglfw.RELEASE:
      io.keysDown[key.ord] = false

  io.keyCtrl = io.keysDown[nglfw.KEY_LEFT_CONTROL.ord] or io.keysDown[nglfw.KEY_RIGHT_CONTROL.ord]
  io.keyShift = io.keysDown[nglfw.KEY_LEFT_SHIFT.ord] or io.keysDown[nglfw.KEY_RIGHT_SHIFT.ord]
  io.keyAlt = io.keysDown[nglfw.KEY_LEFT_ALT.ord] or io.keysDown[nglfw.KEY_LEFT_ALT.ord]
  io.keySuper = io.keysDown[nglfw.KEY_LEFT_SUPER.ord] or io.keysDown[nglfw.KEY_LEFT_SUPER.ord]

proc igGlfwCharCallback*(window: nglfw.Window, code: uint32): void {.cdecl.} =
  if gPrevCharCallback != nil:
    gPrevCharCallback(window, code)

  let io = igGetIO()
  if code > 0'u32 and code < 0x10000'u32:
    io.addInputCharacter(cast[ImWchar](code))

proc igGlfwInstallCallbacks(window: nglfw.Window) =
  # The already set callback proc should be returned. Store these and and chain callbacks.
  gPrevMouseButtonCallback = gWindow.setMouseButtonCallback(igGlfwMouseCallback)
  gPrevScrollCallback = gWindow.setScrollCallback(igGlfwScrollCallback)
  gPrevKeyCallback = gWindow.setKeyCallback(igGlfwKeyCallback)
  gPrevCharCallback = gWindow.setCharCallback(igGlfwCharCallback)

proc igGlfwInit(window: nglfw.Window, installCallbacks: bool, clientApi: GlfwClientApi): bool =
  gWindow = window
  gTime = 0.0f

  let io = igGetIO()
  io.backendFlags = (io.backendFlags.int32 or ImGuiBackendFlags.HasMouseCursors.int32).ImGuiBackendFlags
  io.backendFlags = (io.backendFlags.int32 or ImGuiBackendFlags.HasSetMousePos.int32).ImGuiBackendFlags

  io.keyMap[ImGuiKey.Tab.int32] = nglfw.KEY_TAB
  io.keyMap[ImGuiKey.LeftArrow.int32] = nglfw.KEY_LEFT
  io.keyMap[ImGuiKey.RightArrow.int32] = nglfw.KEY_RIGHT
  io.keyMap[ImGuiKey.UpArrow.int32] = nglfw.KEY_UP
  io.keyMap[ImGuiKey.DownArrow.int32] = nglfw.KEY_DOWN
  io.keyMap[ImGuiKey.PageUp.int32] = nglfw.KEY_PAGE_UP
  io.keyMap[ImGuiKey.PageDown.int32] = nglfw.KEY_PAGE_DOWN
  io.keyMap[ImGuiKey.Home.int32] = nglfw.KEY_HOME
  io.keyMap[ImGuiKey.End.int32] = nglfw.KEY_END
  io.keyMap[ImGuiKey.Insert.int32] = nglfw.KEY_INSERT
  io.keyMap[ImGuiKey.Delete.int32] = nglfw.KEY_DELETE
  io.keyMap[ImGuiKey.Backspace.int32] = nglfw.KEY_BACKSPACE
  io.keyMap[ImGuiKey.Space.int32] = nglfw.KEY_SPACE
  io.keyMap[ImGuiKey.Enter.int32] = nglfw.KEY_ENTER
  io.keyMap[ImGuiKey.Escape.int32] = nglfw.KEY_ESCAPE
  io.keyMap[ImGuiKey.A.int32] = nglfw.KEY_A
  io.keyMap[ImGuiKey.C.int32] = nglfw.KEY_C
  io.keyMap[ImGuiKey.V.int32] = nglfw.KEY_V
  io.keyMap[ImGuiKey.X.int32] = nglfw.KEY_X
  io.keyMap[ImGuiKey.Y.int32] = nglfw.KEY_Y
  io.keyMap[ImGuiKey.Z.int32] = nglfw.KEY_Z

  # HELP: If you know how to convert char * to const char * through Nim pragmas
  # and types, I would love to know.
  when not defined(cpp):
    io.setClipboardTextFn = igGlfwSetClipboardText
    io.getClipboardTextFn = igGlfwGetClipboardText
  io.clipboardUserData = gWindow
  when defined windows:
    io.imeWindowHandle = gWindow.getWin32Window()

  gMouseCursors[ImGuiMouseCursor.Arrow.int32] = createStandardCursor(nglfw.ARROW_CURSOR)
  gMouseCursors[ImGuiMouseCursor.TextInput.int32] = createStandardCursor(nglfw.IBEAM_CURSOR)
  gMouseCursors[ImGuiMouseCursor.ResizeAll.int32] = createStandardCursor(nglfw.ARROW_CURSOR)
  gMouseCursors[ImGuiMouseCursor.ResizeNS.int32] = createStandardCursor(nglfw.VRESIZE_CURSOR)
  gMouseCursors[ImGuiMouseCursor.ResizeEW.int32] = createStandardCursor(nglfw.HRESIZE_CURSOR)
  gMouseCursors[ImGuiMouseCursor.ResizeNESW.int32] = createStandardCursor(nglfw.ARROW_CURSOR)
  gMouseCursors[ImGuiMouseCursor.ResizeNWSE.int32] = createStandardCursor(nglfw.ARROW_CURSOR)
  gMouseCursors[ImGuiMouseCursor.Hand.int32] = createStandardCursor(nglfw.HAND_CURSOR)

  if installCallbacks:
    igGlfwInstallCallbacks(window)

  gClientApi = clientApi
  return true

proc igGlfwInitForOpenGL*(window: nglfw.Window, installCallbacks: bool): bool =
  igGlfwInit(window, installCallbacks, igGlfwClientApiOpenGL)

# @TODO: Vulkan support

proc igGlfwUpdateMousePosAndButtons() =
  let io = igGetIO()
  for i in 0 ..< io.mouseDown.len:
    io.mouseDown[i] = gMouseJustPressed[i] or gWindow.getMouseButton(i.int32) != 0
    gMouseJustPressed[i] = false

  let mousePosBackup = io.mousePos
  io.mousePos = ImVec2(x: -high(float32), y: -high(float32))

  when defined(emscripten): # TODO: actually add support for all the library with emscripten
    let focused = true
  else:
    let focused = gWindow.getWindowAttrib(nglfw.FOCUSED) != 0

  if focused:
    if io.wantSetMousePos:
      gWindow.setCursorPos(mousePosBackup.x, mousePosBackup.y)
    else:
      var mouseX: float64
      var mouseY: float64
      gWindow.getCursorPos(mouseX.addr, mouseY.addr)
      io.mousePos = ImVec2(x: mouseX.float32, y: mouseY.float32)

proc igGlfwUpdateMouseCursor() =
  let io = igGetIO()
  if ((io.configFlags.int32 and ImGuiConfigFlags.NoMouseCursorChange.int32) == 1) or (gWindow.getInputMode(nglfw.CURSOR) == nglfw.CURSOR_DISABLED):
    return

  var igCursor: ImGuiMouseCursor = igGetMouseCursor()
  if igCursor == ImGuiMouseCursor.None or io.mouseDrawCursor:
    gWindow.setInputMode(nglfw.CURSOR, nglfw.CURSOR_HIDDEN)
  else:
    gWindow.setCursor(gMouseCursors[igCursor.int32])
    gWindow.setInputMode(nglfw.CURSOR, nglfw.CURSOR_NORMAL)

proc igGlfwNewFrame*() =
  let io = igGetIO()
  assert io.fonts.isBuilt()

  var w: int32
  var h: int32
  var displayW: int32
  var displayH: int32

  gWindow.getWindowSize(w.addr, h.addr)
  gWindow.getFramebufferSize(displayW.addr, displayH.addr)
  io.displaySize = ImVec2(x: w.float32, y: h.float32)
  io.displayFramebufferScale = ImVec2(x: if w > 0: displayW.float32 / w.float32 else: 0.0f, y: if h > 0: displayH.float32 / h.float32 else: 0.0f)

  let currentTime = nglfw.getTime()
  io.deltaTime = if gTime > 0.0f: (currentTime - gTime).float32 else: (1.0f / 60.0f).float32
  gTime = currentTime

  igGlfwUpdateMousePosAndButtons()
  igGlfwUpdateMouseCursor()

  # @TODO: gamepad mapping

proc igGlfwShutdown*() =
  for i in 0 ..< ImGuiMouseCursor.high.int32 + 1:
    gMouseCursors[i].destroyCursor()
    gMouseCursors[i] = nil
  gClientApi = igGlfwClientApiUnkown
