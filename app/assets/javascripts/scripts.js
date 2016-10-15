
function scroll_to(clicked_link, nav_height) {
	var element_class = clicked_link.attr('href').replace('#', '.');
	var scroll_to = 0;
	if(element_class != '.top-content') {
		element_class += '-container';
		scroll_to = $(element_class).offset().top - nav_height;
	}
	if($(window).scrollTop() != scroll_to) {
		$('html, body').stop().animate({scrollTop: scroll_to}, 1000);
	}
}


jQuery(document).ready(function() {
	
	/*
	    Navigation
	*/
	$('a.scroll-link').on('click', function(e) {
		e.preventDefault();
		scroll_to($(this), $('nav').height());
	});
	// show/hide menu
	$('.show-menu a').on('click', function(e) {
		e.preventDefault();
		$(this).fadeOut(100, function(){ $('nav').slideDown(); });
	});
	$('.hide-menu a').on('click', function(e) {
		e.preventDefault();
		$('nav').slideUp(function(){ $('.show-menu a').fadeIn(); });
	});	
	
    /*
        Fullscreen background
    */
	$('.top-content').backstretch("/assets/img/backgrounds/1.jpg");
	$('.video-container').backstretch("/assets/img/backgrounds/1.jpg");
	$('.about-us-container').backstretch("/assets/img/backgrounds/1.jpg");
	$('.contact-container').backstretch("/assets/img/backgrounds/2.jpg");
    
    /*
        Wow
    */
    new WOW().init();
    
    /*
        Screenshots
    */
    var img_index = 1;
    $('.screenshots-box img').each(function(){
    	$(this).addClass('screenshot-img-' + img_index);
    	$('.screenshots-nav').append('<span class="screenshots-nav-item-' + img_index + '"></span>');
    	if($(this).hasClass('screenshot-img-active')) {
    		$('.screenshots-nav-item-' + img_index).addClass('screenshots-nav-item-active');
    	}
    	img_index++;
    });
    // change screenshot
    $(document).on('click', '.screenshots-nav span', function(){
    	if(!($(this).hasClass('screenshots-nav-item-active'))) {
    		$('.screenshots-nav span').removeClass('screenshots-nav-item-active');
    		var clicked_nav_index = $(this).attr('class').replace('screenshots-nav-item-', '');
    		$(this).addClass('screenshots-nav-item-active');
    		$('.screenshots-box img.screenshot-img-active').fadeOut(300, function(){
    			$(this).removeClass('screenshot-img-active');
    			$('.screenshots-box img.screenshot-img-' + clicked_nav_index).fadeIn(400, function(){
    				$(this).addClass('screenshot-img-active');
    			});
    		});
    	}
    });
	
	/*
	    Testimonials
	*/
	$('.testimonial-active').html('<p>' + $('.testimonial-single:first p').html() + '</p>');
	$('.testimonial-single:first .testimonial-single-image img').css('opacity', '1');
	
	$('.testimonial-single-image img').on('click', function() {
		$('.testimonial-single-image img').css('opacity', '0.5');
		$(this).css('opacity', '1');
		var new_testimonial_text = $(this).parent('.testimonial-single-image').siblings('p').html();
		$('.testimonial-active p').fadeOut(300, function() {
			$(this).html(new_testimonial_text);
			$(this).fadeIn(400);
		});
	});
	
	/*
	    Subscription form
	*/
	$('.success-message').hide();
	$('.error-message').hide();
	
	$('.subscribe form').submit(function(e) {
		e.preventDefault();
	    var postdata = $('.subscribe form').serialize();
	    $.ajax({
	        type: 'POST',
	        url: 'assets/subscribe.php',
	        data: postdata,
	        dataType: 'json',
	        success: function(json) {
	            if(json.valid == 0) {
	                $('.success-message').hide();
	                $('.error-message').hide();
	                $('.error-message').html(json.message);
	                $('.error-message').fadeIn();
	            }
	            else {
	                $('.error-message').hide();
	                $('.success-message').hide();
	                $('.subscribe form').hide();
	                $('.success-message').html(json.message);
	                $('.success-message').fadeIn();
	            }
	        }
	    });
	});
	
	/*
	    Contact form
	*/
	$('.contact-form form input[type="text"], .contact-form form textarea').on('focus', function() {
		$('.contact-form form input[type="text"], .contact-form form textarea').removeClass('contact-error');
	});
	$('.contact-form form').submit(function(e) {
		e.preventDefault();
	    $('.contact-form form input[type="text"], .contact-form form textarea').removeClass('contact-error');
	    var postdata = $('.contact-form form').serialize();
	    $.ajax({
	        type: 'POST',
	        url: 'assets/contact.php',
	        data: postdata,
	        dataType: 'json',
	        success: function(json) {
	            if(json.emailMessage != '') {
	                $('.contact-form form .contact-email').addClass('contact-error');
	            }
	            if(json.subjectMessage != '') {
	                $('.contact-form form .contact-subject').addClass('contact-error');
	            }
	            if(json.messageMessage != '') {
	                $('.contact-form form textarea').addClass('contact-error');
	            }
	            if(json.emailMessage == '' && json.subjectMessage == '' && json.messageMessage == '') {
	                $('.contact-form form').fadeOut('fast', function() {
	                    $('.contact-form').append('<p>Thanks for contacting us! We will get back to you very soon.</p>');
	                    // reload background
	    				$('.contact-container').backstretch("resize");
	                });
	            }
	        }
	    });
	});
    
});



jQuery(window).load(function() {
	
	/*
	    Loader
	*/
    $('.loader-img').fadeOut();
    $('.loader').delay(1000).fadeOut('slow');
    
    /*
		Screenshots
	*/
	$(".screenshots-box img").attr("style", "width: auto !important; height: auto !important;");
    
});

