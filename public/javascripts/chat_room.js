function clearInputText() {
  jQuery('#new_message_input').val('');
}

jQuery(function() {
    if (jQuery('#message_list li:last-child').length != 0)
    {
      jQuery('#message_list_container').scrollTo(jQuery('#message_list > li:last-child'));
    }
    jQuery('#new_message_input').focus();
    jQuery('#new_message_input').keydown(function(e){if (e.which == 13) {jQuery('#send_message_button').click();return false;}});
    jQuery('#send_message_button').click(function(){jQuery('#loading_icon').show()});
    jQuery('#add_keyword_link').click(function(){jQuery('form[name=keyword_form]').slideDown(300);jQuery('#new_keyword_input').focus()});
    jQuery('#cancel_add_keyword').click(function(){jQuery('form[name=keyword_form]').slideUp(300);jQuery('#new_keyword_input').val('')});
  });
