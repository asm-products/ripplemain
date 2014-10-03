// jQuery for page scrolling feature - requires jQuery Easing plugin
$(function() {
    $('.page-scroll a').bind('click', function(event) {
        var $anchor = $(this);
        $('html, body').stop().animate({
            scrollTop: $($anchor.attr('href')).offset().top
        }, 1500, 'easeInOutExpo');
        event.preventDefault();
    });
});

// Floating label headings for the contact form
$(function() {
    $("body").on("input propertychange", ".floating-label-form-group", function(e) {
        $(this).toggleClass("floating-label-form-group-with-value", !! $(e.target).val());
    }).on("focus", ".floating-label-form-group", function() {
        $(this).addClass("floating-label-form-group-with-focus");
    }).on("blur", ".floating-label-form-group", function() {
        $(this).removeClass("floating-label-form-group-with-focus");
    });
});

// Highlight the top nav as scrolling occurs
$('body').scrollspy({
    target: '.navbar-fixed-top'
})

// $('#register')
//     .ajaxForm({
//         url : 'http://testcoffeeclub.bundll.co.uk/submit.php',
//         dataType : 'xml',
//         success : function (response) {
//             alert("The server says: " + response);
//         }
//     }
// );

$(document).ready(function() {
    $('#register').bootstrapValidator({
        message: "Keep typing...",
        feedbackIcons: {
            valid: 'glyphicon glyphicon-ok',
            invalid: 'glyphicon glyphicon-remove',
            validating: 'glyphicon glyphicon-refresh'
        },
        fields: {
            first_name: {
                message: 'Your first name is not valid',
                validators: {
                    notEmpty: {
                        message: 'Your first name is required and cannot be empty'
                    },
                    stringLength: {
                        max: 30,
                        message: 'The first name must be less than 30 characters long'
                    },
                    regexp: {
                        regexp: /^[a-zA-Z0-9_]+$/,
                        message: 'The username can only consist of alphabetical, number and underscore'
                    }
                }
            },
            last_name: {
                message: 'Your last name is not valid',
                validators: {
                    notEmpty: {
                        message: 'Your last name is required and cannot be empty'
                    },
                    stringLength: {
                        max: 30,
                        message: 'The last name must be less than 30 characters long'
                    },
                    regexp: {
                        regexp: /^[a-zA-Z0-9_]+$/,
                        message: 'The username can only consist of alphabetical, number and underscore'
                    }
                }
            },
            company_name: {
                message: 'Your company name is not valid',
                validators: {
                    stringLength: {
                        max: 50,
                        message: 'Your company name must be less than 50 characters'
                    },
                }
            },
            job_role: {
                message: 'Your job role is not valid',
                validators: {
                    stringLength: {
                        max: 50,
                        message: 'Your job role must be less than 50 characters'
                    },
                }
            },
            
            email_address: {
                message: 'Your email address is invalid',
                validators: {
                    notEmpty: {
                        message: 'Your email is required and cannot be empty'
                    },
                    emailAddress: {
                        message: 'Not yet a valid email address...'
                    }
                }
            }
        }
    });
});