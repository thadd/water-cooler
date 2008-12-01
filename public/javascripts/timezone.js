jQuery(function() {
        var visitortime = new Date();
        var inputTag = '<input type="hidden" name="participant_time_zone" ';
        if(visitortime) {
            inputTag += 'value="' + visitortime.getTimezoneOffset()*(-60) + '" />';
        } else {
            inputTag += 'value="JavaScript not Date() enabled" />';
        }
        jQuery('#ldap_form').append(inputTag);
    });
