# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/
paintIt = (element, backgroundColor, textColor) ->
	element.style.backgroundColor = backgroundColor
	if textColor?
		element.style.color = textColor

$ ->
	$("a[data-background-color]").click (e) ->
		e.preventDefault()
		
		backgroundColor = $(this).data("background-color")
		textColor = $(this).data("text-color")
		paintIt(this, backgroundColor, textColor)

$ ->
        $("a[data-mybackground-color]").click (e) ->
                e.preventDefault()

                backgroundColor = $(this).data("mybackground-color")
                textColor = $(this).data("text-color")
                paintIt(this, backgroundColor, textColor)

#$ ->
#	$("a[data-remote]").on("ajax:success", (e, data, status, xhr) ->
#		alert "The target was deleted."
#	).on "ajax:error", (e, xhr, status, error) ->
#		alert "There was an ajax error."

$ ->
	$("a[data-mytest]").on("ajax:success", (e, data, status, xhr) ->
		alert "The target was deleted."
	).on "ajax:error", (e, xhr, status, error) ->
		alert "There was an ajax error. e=#{e.inspect}"

#$ ->
#        $("a[data-mytest]").on "ajax:before", (e, data, status, xhr) ->
#                alert "ajax was started."
#        
#$ ->
#        $("a[data-mytest]").on("ajax:complete", (e, data, status, xhr) ->
#                alert "ajax was completed."
#        )

