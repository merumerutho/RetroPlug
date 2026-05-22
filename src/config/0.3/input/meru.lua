InputConfig({ name = "meru" })

KeyMap({
	[Key.UpArrow] = Button.Up,
	[Key.LeftArrow] = Button.Left,
	[Key.DownArrow] = Button.Down,
	[Key.RightArrow] = Button.Right,

	[Key.Shift] = Button.Select,
	[Key.Enter] = Button.Start,

	[Key.X] = Button.B,
	[Key.Z] = Button.A,
})

GlobalKeyMap({
	[Key.Tab] = Action.RetroPlug.NextInstance
})
