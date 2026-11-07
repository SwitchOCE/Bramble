extends GutTest
## The fight's log note stays on screen however long one attack's sentence gets.

const LogNote := preload("res://src/ui/widgets/log_note.gd")


func test_a_very_long_sentence_stays_inside_the_note() -> void:
	var note: LogNote = LogNote.new()
	add_child_autofree(note)
	note.size = Vector2(437, 436)
	await wait_process_frames(1)
	note.push("Start of a long attack.", true)
	for i: int in range(200):
		note.push("Another trigger joins the same sentence, number %d." % i, false)
	await wait_process_frames(2)
	for child: Node in note.get_children():
		var box: RichTextLabel = child as RichTextLabel
		if box == null:
			continue
		assert_true(box.position.y >= 0.0, "text box starts inside the note")
		assert_true(
			box.position.y + box.size.y <= note.size.y + 1.0,
			"text box ends inside the note: %s" % box.get_rect()
		)
