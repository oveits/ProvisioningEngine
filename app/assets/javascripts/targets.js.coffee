# Place all the behaviors and hooks related to the matching controller here.
# All this logic will automatically be available in application.js.
# You can use CoffeeScript in this file: http://coffeescript.org/

$ ->
	$("a[data-mytest]").on("ajax:success", (e, data, status, xhr) ->
		alert "The target was deleted."
	).on "ajax:error", (e, xhr, status, error) ->
		alert "There was an ajax error. e=#{e.inspect}"

