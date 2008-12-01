jQuery.noConflict();

function changeStatus() {
    jQuery('#status_box').slideDown(300);
    jQuery('#status_input').focus();
}

jQuery(function() {
        setTimeout(function(){jQuery('.temporary').show("normal")}, 100);
        setTimeout(function(){jQuery('.temporary').hide("normal")}, 5000);
        jQuery('#change_status_link').click(changeStatus);
        jQuery('#cancel_change_status').click(function(){
                jQuery('#status_box').slideUp(300);
                jQuery('#available').attr('checked','');
                jQuery('#status_input').val('');
            });
    });
